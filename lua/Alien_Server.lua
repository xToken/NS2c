// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Alien_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Changed ability unlock detection, upgrade chamber detection and added redemption and hive teleport

Script.Load("lua/AlienUpgradeManager.lua")

function Alien:TeleportToHive(usedhive)
    local HivesInfo = { }
    local hives = GetEntitiesForTeam("Hive", self:GetTeamNumber())
    local success = false
    for i, hive in ipairs(hives) do
        local hiveinfo = { hive = hive, underattack = false, dist = 0 }
        local toTarget = hive:GetOrigin() - self:GetOrigin()
        local distanceToTarget = toTarget:GetLength()
        hiveinfo.dist = distanceToTarget
        if hive.lastHiveFlinchEffectTime ~= nil and hive.lastHiveFlinchEffectTime + kHiveUnderAttackTime > Shared.GetTime() then
            hiveinfo.underattack = true
        end
        if (hiveinfo.underattack or hive:GetIsBuilt()) and usedhive ~= hive then
            table.insert(HivesInfo, hiveinfo)
        end
     end
     local selectedhive
     local selectedhivedist = 0
     local selectedhiveunderattack = false
     //Print(ToString(#HivesInfo))
     for h = 1, #HivesInfo do
        if HivesInfo[h].underattack or not selectedhiveunderattack and selectedhivedist < HivesInfo[h].dist then
            selectedhive = HivesInfo[h].hive
            selectedhivedist = HivesInfo[h].dist
            selectedhiveunderattack = HivesInfo[h].underattack
        end
     end
     if selectedhive then
        //Success, now teleport the player, try 10 times?
        for i = 1, 10 do
            local position = table.random(selectedhive.eggSpawnPoints)
            local validForPlayer = GetIsPlacementForTechId(position, self:GetTechId())
            local notNearResourcePoint = #GetEntitiesWithinRange("ResourcePoint", position, 2) == 0

            if validForPlayer and notNearResourcePoint then
                StartSoundEffectAtOrigin(Alien.kTeleportSound, self:GetOrigin())
                SpawnPlayerAtPoint(self, position)
                self:OnHiveTeleport()
                success = true
                break
            end
        end
        if not success then
            self:TriggerInvalidSound()
        end
    end

end

function Alien:CheckRedemption()

    local hasupg, level = GetHasRedemptionUpgrade(self)
    if hasupg and level > 0 and (self.lastredemptioncheck == nil or self.lastredemptioncheck + kRedemptionCheckTime < Shared.GetTime()) then
        //local maxhp, maxap
        local chance = math.random(0, 50) / 100
        chance = chance + (math.random(0, 50) / 100)
        //maxhp = LookupTechData(self.gestationTypeTechId, kTechDataMaxHealth)
        //maxap = LookupTechData(self.gestationTypeTechId, kTechDataMaxArmor)
        if self:GetHealthScalar() <= kRedemptionEHPThreshold then
            //Double Random Check to insure its actually random
            if chance <= (kRedemptionChancePerLevel * level) and self.redemed + kRedemptionCooldown < Shared.GetTime() then
                //Redemed
                if self:GetTechId() == kTechId.Onos then
                    local devourWeapon = self:GetWeapon("devour")
                    if devourWeapon and devourWeapon:IsAlreadyEating() then
                        devourWeapon:OnForceUnDevour()
                    end
                end
                self:TeleportToHive()
                self.redemed = Shared.GetTime()
            end
        end
        self.lastredemptioncheck = Shared.GetTime()
    end

end

function Alien:SetPrimalScream(duration)
    self.timeWhenPrimalScreamExpires = Shared.GetTime() + duration
    self:TriggerEffects("enzymed")
end

function Alien:Reset()

    Player.Reset(self)
    
    self.oneHive = true
    self.twoHives = false
    self.threeHives = false
    
end

function Alien:OnProcessMove(input)
    
    Player.OnProcessMove(self, input)
    
	if not self:GetIsDestroyed() then
    	self:CheckRedemption()
    	self.primalScreamBoost = self.timeWhenPrimalScreamExpires > Shared.GetTime()  
    	self:UpdateAutoHeal()
	end
    
end

function Alien:UpdateAutoHeal()

    PROFILE("Alien:UpdateAutoHeal")
    
    local hasupg, level = GetHasRegenerationUpgrade(self)
    if hasupg and level > 0 then
        if self:GetIsHealable() and self.timeLastAlienAutoHeal == nil or self.timeLastAlienAutoHeal + kAlienRegenerationTime <= Shared.GetTime() then
            local healRate = ((kAlienRegenerationPercentage / 3) * level)
            self:AddHealth(math.max(1, self:GetMaxHealth() * healRate), false, false, true)    
            self.timeLastAlienAutoHeal = Shared.GetTime()
        end
    else
        if self:GetIsHealable() and self.timeLastAlienAutoHeal == nil or self.timeLastAlienAutoHeal + kAlienInnateRegenerationTime <= Shared.GetTime() then
            local healRate = kAlienInnateRegenerationPercentage
            self:AddHealth(math.max(1, self:GetMaxHealth() * healRate), false, false, true)    
            self.timeLastAlienAutoHeal = Shared.GetTime()
        end
    end

end

function Alien:OnHiveConstructed(newHive, activeHiveCount)
    local AbilityData
    if activeHiveCount == 2 then
        AbilityData = self:GetTierTwoTechId()
    elseif activeHiveCount == 3 then
        AbilityData = self:GetTierThreeTechId()
    end
    if AbilityData ~= nil and AbilityData ~= kTechId.None then
        SendPlayersMessage({self}, kTeamMessageTypes.AbilityUnlocked, AbilityData)
    end
    self:UpdateActiveAbilities(activeHiveCount)
end

function Alien:OnHiveDestroyed(destroyedHive, activeHiveCount)
    local AbilityData
    if activeHiveCount == 1 then
        AbilityData = self:GetTierTwoTechId()
    elseif activeHiveCount == 2 then
        AbilityData = self:GetTierThreeTechId()
    end
    if AbilityData ~= nil and AbilityData ~= kTechId.None then
        SendPlayersMessage({self}, kTeamMessageTypes.AbilityLost, AbilityData)
    end
    self:UpdateActiveAbilities(activeHiveCount)
end

function Alien:GetDamagedAlertId()
    return kTechId.AlienAlertLifeformUnderAttack
end

function Alien:UpdateNumUpgradeStructures(techId, count)
    if techId == kTechId.Crag then
        self.crags = Clamp(count, 0, 3)
    elseif techId == kTechId.Shift then
        self.shifts = Clamp(count, 0, 3)
    elseif techId == kTechId.Shade then
        self.shades = Clamp(count, 0, 3)
    elseif techId == kTechId.Whip then
        self.whips = Clamp(count, 0, 3)
        elseif techId == kTechId.Whip then
        self.whips = Clamp(count, 0, 3)
    end
end

function Alien:ManuallyUpdateNumUpgradeStructures()
    local team = self:GetTeam()
    if team and team.GetIsAlienTeam and team:GetIsAlienTeam() and team.techIdCount then
        for i = 1, #kAlienUpgradeChambers do
            if team.techIdCount[kAlienUpgradeChambers[i]] and team.techIdCount[kAlienUpgradeChambers[i]] ~= nil then
                if kAlienUpgradeChambers[i] == kTechId.Crag then
                    self.crags = math.min(team.techIdCount[kAlienUpgradeChambers[i]], 3)
                elseif kAlienUpgradeChambers[i] == kTechId.Shift then
                    self.shifts = math.min(team.techIdCount[kAlienUpgradeChambers[i]], 3)
                elseif kAlienUpgradeChambers[i] == kTechId.Shade then
                    self.shades = math.min(team.techIdCount[kAlienUpgradeChambers[i]], 3)
                elseif kAlienUpgradeChambers[i] == kTechId.Whip then
                    self.whips = math.min(team.techIdCount[kAlienUpgradeChambers[i]], 3)
                end
            else
                if kAlienUpgradeChambers[i] == kTechId.Crag then
                    self.crags = 0
                elseif kAlienUpgradeChambers[i] == kTechId.Shift then
                    self.shifts = 0
                elseif kAlienUpgradeChambers[i] == kTechId.Shade then
                    self.shades = 0
                elseif kAlienUpgradeChambers[i] == kTechId.Whip then
                    self.whips = 0
                end
            end
        end
    end
end

/**
 * Morph into new class or buy upgrade.
 */

function Alien:ProcessBuyAction(techIds)

    ASSERT(type(techIds) == "table")
    ASSERT(table.count(techIds) > 0)

    local success = false
    local healthScalar = self:GetHealth() / self:GetMaxHealth()
    local armorScalar = self:GetMaxArmor() == 0 and 1 or self:GetArmor() / self:GetMaxArmor()
    local totalCosts = 0
    
    local upgradeIds = {}
    local lifeFormTechId = nil
    for _, techId in ipairs(techIds) do
        
        if LookupTechData(techId, kTechDataGestationName) then
            lifeFormTechId = techId
        else
            table.insertunique(upgradeIds, techId)
        end
        
    end
    
    local upgradesAllowed = true
    local upgradeManager = AlienUpgradeManager()
    upgradeManager:Populate(self)
    // add this first because it will allow switching existing upgrades
    if lifeFormTechId then
        upgradeManager:AddUpgrade(lifeFormTechId)
    end
    for _, newUpgradeId in ipairs(techIds) do

        if newUpgradeId ~= kTechId.None and not upgradeManager:AddUpgrade(newUpgradeId) then
            upgradesAllowed = false 
            break
        end
        
    end
    
    if upgradesAllowed then
    
        // Check for room
        local eggExtents = LookupTechData(kTechId.Embryo, kTechDataMaxExtents)
        local newLifeFormTechId = upgradeManager:GetLifeFormTechId()
        local newAlienExtents = LookupTechData(newLifeFormTechId, kTechDataMaxExtents)
        local physicsMask = PhysicsMask.AllButPCsAndRagdolls
        local position = self:GetOrigin()
        
        local evolveAllowed = self:GetIsOnGround()
        evolveAllowed = evolveAllowed and GetHasRoomForCapsule(eggExtents, position + Vector(0, eggExtents.y + Embryo.kEvolveSpawnOffset, 0), CollisionRep.Default, physicsMask, self)
        evolveAllowed = evolveAllowed and GetHasRoomForCapsule(newAlienExtents, position + Vector(0, newAlienExtents.y + Embryo.kEvolveSpawnOffset, 0), CollisionRep.Default, physicsMask, self)
        
        if self:GetTechId() == kTechId.Onos then
            local devourWeapon = self:GetWeapon("devour")
            if devourWeapon and devourWeapon:IsAlreadyEating() then
                evolveAllowed = false
            end
        end
        
        // If not on the ground for the buy action, attempt to automatically
        // put the player on the ground in an area with enough room for the new Alien.
        if not evolveAllowed then
        
            for index = 1, 100 do
            
                local spawnPoint = GetRandomSpawnForCapsule(newAlienExtents.y, math.max(newAlienExtents.x, newAlienExtents.z), self:GetModelOrigin(), 0.5, 5, EntityFilterOne(self))
                if spawnPoint then
                
                    self:SetOrigin(spawnPoint)
                    position = spawnPoint
                    evolveAllowed = true
                    break
                    
                end
                
            end
            
        end

        if evolveAllowed then

            local newPlayer = self:Replace(Embryo.kMapName)
            position.y = position.y + Embryo.kEvolveSpawnOffset
            newPlayer:SetOrigin(position)
            
            // Clear angles, in case we were wall-walking or doing some crazy alien thing
            local angles = Angles(self:GetViewAngles())
            angles.roll = 0.0
            angles.pitch = 0.0
            newPlayer:SetOriginalAngles(angles)
            
            // Eliminate velocity so that we don't slide or jump as an egg
            newPlayer:SetVelocity(Vector(0, 0, 0))                
            newPlayer:DropToFloor()
            
            newPlayer:SetResources(upgradeManager:GetAvailableResources())
            newPlayer:SetGestationData(upgradeManager:GetUpgrades(), self:GetTechId(), healthScalar, armorScalar)
            
            success = true
            
        end    
        
    end
    
    if not success then
        self:TriggerInvalidSound()
    end    
    
    return success
    
end

// Increase armor absorption the depending on our defensive upgrade level
function Alien:GetHealthPerArmorOverride(damageType, healthPerArmor)
    
    local newHealthPerArmor = healthPerArmor

    local team = self:GetTeam()
    local numHives = team:GetActiveHiveCount()
    
    // make sure not to ignore damage types
    if numHives >= 3 then
        newHealthPerArmor = kHealthPointsPerArmorScalarHive3
    elseif numHives == 2 then
        newHealthPerArmor = kHealthPointsPerArmorScalarHive2
    elseif numHives == 1 then
        newHealthPerArmor = kHealthPointsPerArmorScalarHive1
    end

    return newHealthPerArmor
    
end

function Alien:GetTierOneTechId()
    return kTechId.None
end

function Alien:GetTierTwoTechId()
    return kTechId.None
end

function Alien:GetTierThreeTechId()
    return kTechId.None
end

local function UnlockAbility(forAlien, techId)

    local mapName = LookupTechData(techId, kTechDataMapName)
    if mapName and forAlien:GetIsAlive() then

        local activeWeapon = forAlien:GetActiveWeapon()

        local tierWeapon = forAlien:GetWeapon(mapName)
        if not tierWeapon then
            forAlien:GiveItem(mapName)
        end
        
        if activeWeapon then
            forAlien:SetActiveWeapon(activeWeapon:GetMapName())
        end
    
    end

end

local function LockAbility(forAlien, techId)

    local mapName = LookupTechData(techId, kTechDataMapName)    
    if mapName and forAlien:GetIsAlive() then
    
        local tierWeapon = forAlien:GetWeapon(mapName)
        local activeWeapon = forAlien:GetActiveWeapon()
        local activeWeaponMapName = nil
        
        if activeWeapon ~= nil then
            activeWeaponMapName = activeWeapon:GetMapName()
        end
        
        if tierWeapon then
            forAlien:RemoveWeapon(tierWeapon)
        end
        
        if activeWeaponMapName == mapName then
            forAlien:SwitchWeapon(1)
        end
        
    end    
    
end

function Alien:UpdateActiveAbilities(hives)

    if hives >= 1 then
        UnlockAbility(self, self:GetTierOneTechId())
        self.oneHive = true
    elseif self.oneHive and hives < 1 then
        LockAbility(self, self:GetTierOneTechId())
        self.oneHive = false
    end

    if hives >= 2 then
        UnlockAbility(self, self:GetTierTwoTechId())
        self.twoHives = true
    elseif self.twoHives and hives < 2 then
        LockAbility(self, self:GetTierTwoTechId())
        self.twoHives = false
    end
    
    if hives >= 3 then
        UnlockAbility(self, self:GetTierThreeTechId())
        self.threeHives = true
    elseif self.threeHives and hives < 3 then
        LockAbility(self, self:GetTierThreeTechId())
        self.threeHives = false
    end
    
end

function Alien:OnKill(attacker, doer, point, direction)
    Player.OnKill(self, attacker, doer, point, direction)
    self.oneHive = false
    self.twoHives = false
    self.threeHives = false    
end

function Alien:CopyPlayerDataFrom(player)

    Player.CopyPlayerDataFrom(self, player)
    
    self.oneHive = player.oneHive
    self.twoHives = player.twoHives
    self.threeHives = player.threeHives
    self.crags = player.crags
    self.shifts = player.shifts
    self.shades = player.shades
	self.whips = player.whips
end