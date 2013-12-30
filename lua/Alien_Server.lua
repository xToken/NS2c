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

local function GetRelocationHive(usedhive, origin, teamnumber)
    local hives = GetEntitiesForTeam("Hive", teamnumber)
    local selectedhivedist = 0
	local selectedhive
	
    for i, hive in ipairs(hives) do
        local toTarget = hive:GetOrigin() - origin
        local distancetohive = toTarget:GetLength()
		if hive.lastHiveFlinchEffectTime ~= nil and hive.lastHiveFlinchEffectTime + kHiveUnderAttackTime > Shared.GetTime() then
            return hive
        end
		if selectedhivedist < distancetohive and hive ~= usedhive then
			selectedhive = hive
			selectedhivedist = distancetohive
		end
	end
	
	return selectedhive
end

function Alien:TeleportToHive(usedhive)
	local selectedhive = GetRelocationHive(usedhive, self:GetOrigin(), self:GetTeamNumber())
    local success = false
    if selectedhive and selectedhive ~= usedhive then
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

function Alien:OnRedemed()
end

function Alien:EvolveAllowed()
    return true
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
    
   
    // need to clear this value or spectators would see the hatch effect every time they cycle through players
    if self.hatched and self.creationTime + 3 < Shared.GetTime() then
        self.hatched = false
    end
    
    Player.OnProcessMove(self, input)
    
	if not self:GetIsDestroyed() then
    	self.primalScreamBoost = self.timeWhenPrimalScreamExpires > Shared.GetTime()  
    	self:UpdateAutoHeal()
	end
    
end

function Alien:GetIsHealableOverride()
  return self:GetIsAlive() and (self:GetHealth() < self:GetMaxHealth() or self:GetArmor() < self:GetMaxArmor())
end

function Alien:UpdateAutoHeal()

    PROFILE("Alien:UpdateAutoHeal")
    
    local hasupg, level = GetHasRegenerationUpgrade(self)
    if hasupg and level > 0 then
        if self:GetIsHealable() and self.timeLastAlienAutoHeal + kAlienRegenerationTime <= Shared.GetTime() then
            local healRate = ((kAlienRegenerationPercentage / 3) * level)
            self:AddHealth(math.max(1, self:GetMaxHealth() * healRate), true, (self:GetMaxHealth() - self:GetHealth() ~= 0), true)    
            self.timeLastAlienAutoHeal = Shared.GetTime()
        end
    else
        if self:GetIsHealable() and self.timeLastAlienAutoHeal + kAlienInnateRegenerationTime <= Shared.GetTime() then
            local healRate = kAlienInnateRegenerationPercentage
            self:AddHealth(math.max(1, self:GetMaxHealth() * healRate), false, (self:GetMaxHealth() - self:GetHealth() ~= 0), true)    
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
    self:UpdateHiveScaledHealthValues()
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
    self:UpdateHiveScaledHealthValues()
end

function Alien:GetDamagedAlertId()
    return kTechId.AlienAlertLifeformUnderAttack
end

// Morph into new class or buy upgrade.
function Alien:ProcessBuyAction(techIds)

    ASSERT(type(techIds) == "table")
    ASSERT(table.count(techIds) > 0)

    local success = false
    
    if GetGamerules():GetGameStarted() then

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
	
	    local oldLifeFormTechId = self:GetTechId()
	    
	    local upgradesAllowed = true
	    local upgradeManager = AlienUpgradeManager()
	    upgradeManager:Populate(self)
	    // add this first because it will allow switching existing upgrades
	    if lifeFormTechId then
	        upgradeManager:AddUpgrade(lifeFormTechId)
	    end
	    for _, newUpgradeId in ipairs(techIds) do
	
	        if newUpgradeId ~= kTechId.None and not upgradeManager:AddUpgrade(newUpgradeId, true) then
	            upgradesAllowed = false 
	            break
	        end
	        
	    end
	    
	    upgradesAllowed = upgradesAllowed and self:EvolveAllowed()
	     
	    if upgradesAllowed then
	    
	        // Check for room
	        local eggExtents = LookupTechData(kTechId.Embryo, kTechDataMaxExtents)
	        local newLifeFormTechId = upgradeManager:GetLifeFormTechId()
	        local newAlienExtents = LookupTechData(newLifeFormTechId, kTechDataMaxExtents)
	        local physicsMask = PhysicsMask.Evolve
	        local position = self:GetOrigin()
	        -- Add a bit to the extents when looking for a clear space to spawn.
	        local spawnBufferExtents = Vector(0.1, 0.1, 0.1)
	        
	        local evolveAllowed = self:GetIsOnSurface()
	        evolveAllowed = evolveAllowed and GetHasRoomForCapsule(eggExtents + spawnBufferExtents, position + Vector(0, eggExtents.y + Embryo.kEvolveSpawnOffset, 0), CollisionRep.Default, physicsMask, self)
	        evolveAllowed = evolveAllowed and GetHasRoomForCapsule(newAlienExtents + spawnBufferExtents, position + Vector(0, newAlienExtents.y + Embryo.kEvolveSpawnOffset, 0), CollisionRep.Default, physicsMask, self)
	        
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
    end
    
    if not success then
        self:TriggerInvalidSound()
    end    
    
    return success
    
end

function Alien:UpdateHiveScaledHealthValues()
    local team = self:GetTeam()
    local numHives = team:GetActiveHiveCount()
    local maxHealth = self:GetBaseHealth() + (self:GetBaseArmor() * self:GetHiveHealthScalar(numHives))
    self:AdjustMaxHealth(maxHealth)
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
    
end