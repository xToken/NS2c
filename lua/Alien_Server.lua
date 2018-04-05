-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Alien_Server.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Changed ability unlock detection, upgrade chamber detection and added redemption and hive teleport

local function GetRelocationHive(usedHive, origin, teamNumber)

    local hives = GetEntitiesForTeam("Hive", teamNumber)
    
    if usedHive then
        table.removevalue(hives, usedHive)
    end
    
    local t = Shared.GetTime()
    local selectedHiveDist = 0
    local selectedHiveAlertTime = 0
	local selectedHive
	
    for i, hive in ipairs(hives) do
        local toTarget = hive:GetOrigin() - origin
        local distanceToHive = toTarget:GetLength()
		if (hive:GetLastAttackedOrWarnedTime() + kHiveUnderAttackTime > t and hive:GetLastAttackedOrWarnedTime() > selectedHiveAlertTime) or 
            (selectedHiveDist < distanceToHive and selectedHiveAlertTime + kHiveUnderAttackTime < t and hive:GetIsBuilt()) then
            selectedHive = hive
            selectedHiveDist = distanceToHive
            selectedHiveAlertTime = hive:GetLastAttackedOrWarnedTime()
        end
	end
	
	return selectedHive

end

function Alien:TeleportToHive(usedHive)

	local selectedHive = GetRelocationHive(usedHive, self:GetOrigin(), self:GetTeamNumber())
    local success = false
    if selectedHive then
        //Success, now teleport the player, try 10 times?
        for i = 1, 10 do
            local position = table.random(selectedHive.eggSpawnPoints)
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

function Alien:OnRedeemed()
end

function Alien:EvolveAllowed()
    return true
end

function Alien:Reset()

    Player.Reset(self)
    
    if self:GetTeamNumber() ~= kNeutralTeamType then
        self.oneHive = false
        self.twoHives = false
        self.threeHives = false
    end
    
end

function Alien:GetIsHealableOverride()
  return self:GetIsAlive() and self:AmountDamaged() > 0
end

function Alien:UpdateAutoHeal()

    PROFILE("Alien:UpdateAutoHeal")
    
    if (self.timeLastAlienAutoHeal + kAlienRegenerationTime <= Shared.GetTime() or self.timeLastAlienAutoHeal + kAlienInnateRegenerationTime <= Shared.GetTime()) and self:GetIsHealable() then
        local hasupg, level = GetHasRegenerationUpgrade(self)
        local isTime = self.timeLastAlienAutoHeal + kAlienInnateRegenerationTime <= Shared.GetTime()
        local heal = math.max(1, self:GetMaxHealth() * kAlienInnateRegenerationPercentage)
        if hasupg and level > 0 then
            isTime = self.timeLastAlienAutoHeal + kAlienRegenerationTime <= Shared.GetTime()
            heal = math.max(1, self:GetMaxHealth() * ((kAlienRegenerationPercentage / 3) * level))
        end
        self:AddHealth(heal, true, (self:GetMaxHealth() - self:GetHealth() ~= 0), true)    
        self.timeLastAlienAutoHeal = Shared.GetTime()
    end
    
    return self:GetIsAlive()
    
end

function Alien:OnHiveConstructed(newHive, activeHiveCount)

    local AbilityData = self:GetTierTechId(activeHiveCount)
    if AbilityData ~= kTechId.None then
        SendPlayersMessage({self}, kTeamMessageTypes.AbilityUnlocked, AbilityData)
    end
    self:UpdateActiveAbilities(activeHiveCount)
    self:UpdateHiveScaledHealthValues()
    
end

function Alien:OnHiveDestroyed(destroyedHive, activeHiveCount)

    local AbilityData = self:GetTierTechId(activeHiveCount + 1)
    if AbilityData ~= kTechId.None then
        SendPlayersMessage({self}, kTeamMessageTypes.AbilityLost, AbilityData)
    end
    self:UpdateActiveAbilities(activeHiveCount)
    self:UpdateHiveScaledHealthValues()
    
end

function Alien:GetDamagedAlertId()
    return kTechId.AlienAlertLifeformUnderAttack
end

function Alien:OnRestoreUpgrades()

    player = Player.OnRestoreUpgrades(self)
    //Refund lifeform costs.
    for i, techId in ipairs(player:GetUpgrades()) do
        if LookupTechData(techId, kTechDataGestateName) then 
            player:AddResources(LookupTechData(techId, kTechDataCombatCost, 0))
            player:RemoveUpgrade(techId)
            StoreCombatPlayersUpgradeTable(player)
            break
        end
    end
    player:SetHatched()
    return player
    
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
	    
	    local newupgradeIds = { }
	    local lifeFormTechId = nil
	    for _, techId in ipairs(techIds) do
	        if LookupTechData(techId, kTechDataGestateName) then
	            lifeFormTechId = techId
	        else
	            table.insertunique(newupgradeIds, techId)
	        end
	    end
	
	    local oldLifeFormTechId = self:GetTechId()
	    local oldUpgrades = self:GetUpgrades()
	    local newresources = self:GetPersonalResources()
	    local approvedUpgrades = { }
	    
	    // add this first because it will allow switching existing upgrades
	    if lifeFormTechId and BuyMenus_GetUpgradeCost(lifeFormTechId) <= newresources then
	        //Shared.Message("Purchasing lifeform " .. EnumToString(kTechId, lifeFormTechId) .. ".")
	        table.insert(approvedUpgrades, lifeFormTechId)
	        newresources = newresources - BuyMenus_GetUpgradeCost(lifeFormTechId)
	    end
	    // add old upgrades back in first.
	    // these are free.
	    for _, UpgradeId in ipairs(oldUpgrades) do
	        //Shared.Message("Checking old upgrade " .. EnumToString(kTechId, UpgradeId) .. " - " .. ToString(GetTechAvailable(UpgradeId, self)) .. " - " .. ToString(GetIsAlienUpgradeAllowed(self, UpgradeId, approvedUpgrades)) .. " - " .. ToString(not table.contains(newupgradeIds, UpgradeId)) .. "." )
	        if UpgradeId ~= kTechId.None and GetTechAvailable(UpgradeId, self) and GetIsAlienUpgradeAllowed(self, UpgradeId, approvedUpgrades) and not table.contains(newupgradeIds, UpgradeId) then
	            //Shared.Message("Adding old upgrade " .. EnumToString(kTechId, UpgradeId) .. ".")
	            table.insert(approvedUpgrades, UpgradeId)
	        end
	    end
	    //Add in new upgrades, these cost money
	    for _, UpgradeId in ipairs(newupgradeIds) do
	        //Shared.Message("Checking new upgrade " .. EnumToString(kTechId, UpgradeId) .. " - " .. ToString(GetTechAvailable(UpgradeId, self)) .. " - " .. ToString(GetIsAlienUpgradeAllowed(self, UpgradeId, approvedUpgrades)) .. "." )
	        if UpgradeId ~= kTechId.None and GetTechAvailable(UpgradeId, self) and GetIsAlienUpgradeAllowed(self, UpgradeId, approvedUpgrades) and BuyMenus_GetUpgradeCost(UpgradeId) <= newresources then
	            //Special case here
	            //We rebuy an upgrade if we already have it and want to unevolve it.
	            if table.contains(oldUpgrades, UpgradeId) then
	                //Shared.Message("Repurchased upgrade " .. EnumToString(kTechId, UpgradeId) .. " , skipping.")
	            else
	                table.insert(approvedUpgrades, UpgradeId)
	                //Shared.Message("Adding new upgrade " .. EnumToString(kTechId, UpgradeId) .. ".")
	                newresources = newresources - BuyMenus_GetUpgradeCost(UpgradeId)
	            end
	        end
	    end
	    
	    if lifeFormTechId == nil then
	        lifeFormTechId = oldLifeFormTechId
	    end

	    if self:EvolveAllowed() then
	    
	        // Check for room
	        local eggExtents = LookupTechData(kTechId.Embryo, kTechDataMaxExtents)
	        local newAlienExtents = LookupTechData(lifeFormTechId, kTechDataMaxExtents)
	        local physicsMask = PhysicsMask.Evolve
	        local position = self:GetOrigin()
	        -- Add a bit to the extents when looking for a clear space to spawn.
	        local spawnBufferExtents = Vector(0.1, 0.1, 0.1)
	        
	        local evolveAllowed = self:GetIsOnGround()
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
	            
	            newPlayer:SetResources(newresources)
	            newPlayer:SetGestationData(approvedUpgrades, self:GetTechId(), healthScalar, armorScalar)
	            
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
    if team then
        local numHives = team:GetActiveHiveCount()
        local maxHealth = self:GetBaseHealth() + (self:GetBaseArmor() * self:GetHiveHealthScalar(numHives))
        self:AdjustMaxHealth(maxHealth)
    end
    
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

function Alien:GetTierTechId(numHives)
    if numHives == 1 then
        return self:GetTierOneTechId()
    elseif numHives == 2 then
        return self:GetTierTwoTechId()
    elseif numHives == 3 then
        return self:GetTierThreeTechId()
    end
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

    if self:GetHasUpgrade(kTechId.ThreeHives) then
        hives = 3
    elseif self:GetHasUpgrade(kTechId.TwoHives) then
        hives = 2
    end
    
    if GetGamerules():GetAllTech() then
        //Meh
        hives = 3
    end
    
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