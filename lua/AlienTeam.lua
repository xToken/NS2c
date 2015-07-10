// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\AlienTeam.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// This class is used for teams that are actually playing the game, e.g. Marines or Aliens.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Added in classic tech ids, added in tracking of upgrade structures for alerts

Script.Load("lua/TechData.lua")
Script.Load("lua/Skulk.lua")
Script.Load("lua/PlayingTeam.lua")

class 'AlienTeam' (PlayingTeam)

// Innate alien regeneration
AlienTeam.kAutoHealInterval = 2
AlienTeam.kStructureAutoHealInterval = 0.5
AlienTeam.kAutoHealUpdateNum = 20 // number of structures to update per autoheal update
AlienTeam.kSpawnScanInterval = 2
AlienTeam.kOrganicStructureHealRate = 0.02     // Health per second

AlienTeam.kPingSound = PrecacheAsset("sound/ns2c.fev/ns2c/ui/countdown")
AlienTeam.kNewTraitSound = PrecacheAsset("sound/ns2c.fev/ns2c/ui/alien_newtrait")
AlienTeam.kNeedBuildersSound = PrecacheAsset("sound/ns2c.fev/ns2c/ui/alien_needbuilders")

local kSendUnAssignedHiveMessageRate = 45

function AlienTeam:GetTeamType()
    return kAlienTeamType
end

function AlienTeam:GetIsAlienTeam()
    return true
end

function AlienTeam:ResetTeam()

    local commandStructure = PlayingTeam.ResetTeam(self)

    self.overflowres = 0
    self.clientOwnedStructures = { }
    self.upgradeChambers = { }
    
    return commandStructure

end

function AlienTeam:Initialize(teamName, teamNumber)

    PlayingTeam.Initialize(self, teamName, teamNumber)
    
    self.respawnEntity = Skulk.kMapName

    // List stores all the structures owned by builder player types such as the Gorge.
    // This list stores them based on the player platform ID in order to maintain structure
    // counts even if a player leaves and rejoins a server.
    self.clientOwnedStructures = { }
    self.lastAutoHealIndex = 1
    self.upgradeChambers = { }
    self.timeLastSpawnCheck = 0
    self.overflowres = 0
    self.lastOverflowCheck = 0
    self.lastTimeUnassignedHivesSent = 0
    self.lastPingOfDeathCheck = 0
    
end

function AlienTeam:OnInitialized()

    PlayingTeam.OnInitialized(self) 

    self.lastTimeUnassignedHivesSent = 0
    self.lastPingOfDeathCheck = 0
    self.lastAutoHealIndex = 1
    self.overflowres = 0
    self.clientOwnedStructures = { }
    self.upgradeChambers = { }
    self.lastOverflowCheck = 0

end

function AlienTeam:GetTeamInfoMapName()
    return AlienTeamInfo.kMapName
end

local function RemoveGorgeStructureFromClient(self, techId, clientId)

    local structureTypeTable = self.clientOwnedStructures[clientId]
    
    if structureTypeTable then
    
        if not structureTypeTable[techId] then
        
            structureTypeTable[techId] = { }
            return
            
        end    
        
        local removeIndex = 0
        local structure = nil
        for index, id in ipairs(structureTypeTable[techId])  do
        
            if id then
            
                removeIndex = index
                structure = Shared.GetEntity(id)
                break
                
            end
            
        end
        
        if structure then
            
            Shared.Message(string.format("Removed structure of type %s for clientId %s as limit of %s structures per type per player was exceeded.", EnumToString(kTechId, techId), clientId, kMaxGorgeOwnedStructures))
            
            table.remove(structureTypeTable[techId], removeIndex)
            structure.consumed = true
            if structure:GetCanDie() then
                structure:Kill()
            else
                DestroyEntity(structure)
            end
            
        end
        
    end
    
end

local function ApplyGorgeStructureTheme(structure, player)

    assert(player:isa("Gorge"))
    
    if structure.SetVariant then
        structure:SetVariant(player:GetVariant())
    end
    
end

function AlienTeam:AddGorgeStructure(player, structure)

    if player ~= nil and structure ~= nil then
    
        local clientId = Server.GetOwner(player):GetUserId()
        local structureId = structure:GetId()
        local techId = structure:GetTechId()
        
        if not self.clientOwnedStructures[clientId] then
            self.clientOwnedStructures[clientId] = { }
        end
        
        local structureTypeTable = self.clientOwnedStructures[clientId]
        
        if not structureTypeTable[techId] then
            structureTypeTable[techId] = { }
        end
        
        table.insertunique(structureTypeTable[techId], structureId)
        
		ApplyGorgeStructureTheme(structure, player)

        local numAllowedStructure = LookupTechData(techId, kTechDataMaxAmount, -1)
        if numAllowedStructure <= 0 then
            numAllowedStructure = kMaxGorgeOwnedStructures
        end
        if numAllowedStructure >= 0 and table.count(structureTypeTable[techId]) > numAllowedStructure then
            RemoveGorgeStructureFromClient(self, techId, clientId)
        end
        
    end
    
end

function AlienTeam:GetDroppedGorgeStructures(player, techId)

    local owner = Server.GetOwner(player)

    if owner then
    
        local clientId = owner:GetUserId()
        local structureTypeTable = self.clientOwnedStructures[clientId]
        
        if structureTypeTable then
            return structureTypeTable[techId]
        end
    
    end
    
end

function AlienTeam:GetNumDroppedGorgeStructures(player, techId)

    local structureTypeTable = self:GetDroppedGorgeStructures(player, techId)
    return (not structureTypeTable and 0) or #structureTypeTable
    
end

function AlienTeam:UpdateClientOwnedStructures(oldEntityId)

    if oldEntityId then
    
        for clientId, structureTypeTable in pairs(self.clientOwnedStructures) do
        
            for techId, structureList in pairs(structureTypeTable) do
            
                for i, structureId in ipairs(structureList) do
                
                    if structureId == oldEntityId then
                    
                        table.remove(structureList, i)
                        break
                        
                    end
                    
                end
                
            end
            
        end
        
    end
    
end

function AlienTeam:OnEntityChange(oldEntityId, newEntityId)

    PlayingTeam.OnEntityChange(self, oldEntityId, newEntityId)

    // Check if the oldEntityId matches any client's built structure and
    // handle the change.
    
    self:UpdateClientOwnedStructures(oldEntityId)

end

function AlienTeam:SpawnInitialStructures(techPoint)

    local tower, hive = PlayingTeam.SpawnInitialStructures(self, techPoint)
        
    return tower, hive
    
end

function AlienTeam:GetHasAbilityToRespawn()

    local hives = GetEntitiesForTeam("Hive", self:GetTeamNumber())
    return table.count(hives) > 0
    
end

function AlienTeam:GetOverflowResources()
    return self.overflowres
end

function AlienTeam:GetMaxBioMassLevel()
    return 1
end

function AlienTeam:GetStartingResources()
    if GetServerGameMode() == kGameMode.Classic then
	    return kAlienInitialPersonalRes
	end
    return 0
end

function AlienTeam:GetBioMassLevel()
    return 1
end

function AlienTeam:AddOverflowResources(extraRes)
    if extraRes > 0 then
        self.overflowres = self.overflowres + (math.floor(extraRes * 100) / 100)
    end
end

function AlienTeam:DeductOverflowResources(extraRes)
    if extraRes > 0 then
        self.overflowres = math.max(self.overflowres - extraRes, 0)
    end
end

function AlienTeam:GetWaveSpawnTime()
    return kAlienCombatMinSpawnInterval + (kAlienCombatSpawnIntervalPerPlayer * self:GetNumPlayersInQueue())
end

function AlienTeam:GetRespawnsPerWave()
    return kAlienRespawnsPerWave
end

local function CheckUnassignedHives(self)

    if Shared.GetTime() - self.lastTimeUnassignedHivesSent >= kSendUnAssignedHiveMessageRate then
    
        self.lastTimeUnassignedHivesSent = Shared.GetTime()
        if self:GetActiveUnassignedHiveCount() > 0 then
            SendTeamMessage(self, kTeamMessageTypes.UnassignedHive) 
        end
        
    end
    
end

local function UpdateAlienArmor(self)
    for index, alien in ipairs(GetEntitiesForTeam("Alien", self:GetTeamNumber())) do
        alien:UpdateArmorAmount()
    end
end

function AlienTeam:UpgradeVoteAllowed()
    return self:GetActiveUnassignedHiveCount() > 0
end

function AlienTeam:Update(timePassed)

    PROFILE("AlienTeam:Update")
    
    if GetServerGameMode() == kGameMode.Classic then
      	if GetGamerules():GetGameStarted() then  
            CheckUnassignedHives(self)
            self:UpdateTeamAutoHeal(timePassed)
            self:UpdatePingOfDeath()
            self:UpdateOverflowResources()
        end
    end
    
    PlayingTeam.Update(self, timePassed)
    
end

function AlienTeam:UpdateOverflowResources()

    if self.lastOverflowCheck + 1 < Shared.GetTime() and self:GetPresRecipientCount() > 0 then
        if self:GetOverflowResources() > 0 then
            local overflowres = math.min(self:GetOverflowResources(), self:GetPresRecipientCount() * 100)
            self:DeductOverflowResources(overflowres)
            self:SplitPres(overflowres)
        end
    end
    
end

function AlienTeam:UpdatePingOfDeath()

    if not self:GetHasAbilityToRespawn() and (not GetTournamentModeEnabled or not GetTournamentModeEnabled()) and self.lastPingOfDeathCheck + kPingOfDeathDelay < Shared.GetTime() then
        for index, alien in ipairs(GetEntitiesForTeam("Alien", self:GetTeamNumber())) do
            if alien:GetIsAlive() then
                local damage = math.max(0, alien:GetMaxHealth() * (kPingOfDeathDamagePercent / 100))
                alien:TakeDamage(damage, alien, alien, alien:GetOrigin(), nil, 0, damage, kDamageType.Falling, true)
                StartSoundEffectForPlayer(AlienTeam.kPingSound, alien)
            end
        end
        self.lastPingOfDeathCheck = Shared.GetTime()
    end

end

// update every tick but only a small amount of structures
function AlienTeam:UpdateTeamAutoHeal(timePassed)

    PROFILE("AlienTeam:UpdateTeamAutoHeal")

    local time = Shared.GetTime()
    
    if self.timeOfLastAutoHeal == nil then
        self.timeOfLastAutoHeal = Shared.GetTime()
    end
    
    if time > (self.timeOfLastAutoHeal + AlienTeam.kStructureAutoHealInterval) then
        
        local intervalLength = time - self.timeOfLastAutoHeal
        local gameEnts = GetEntitiesWithMixinForTeam("TeamMixin", self:GetTeamNumber())
        local numEnts = table.count(gameEnts)
        local toIndex = self.lastAutoHealIndex + AlienTeam.kAutoHealUpdateNum - 1
        toIndex = ConditionalValue(toIndex <= numEnts , toIndex, numEnts)
        
        for index = self.lastAutoHealIndex, toIndex do

            local entity = gameEnts[index]
            
            // players update the auto heal on their own
            if not entity:isa("Player") then
            
                local isHealable            = entity:GetIsHealable()
                local deltaTime             = 0
                
                if not entity.timeLastAutoHeal then
                    entity.timeLastAutoHeal = Shared.GetTime()
                else
                    deltaTime = Shared.GetTime() - entity.timeLastAutoHeal
                end

                if isHealable and deltaTime > AlienTeam.kAutoHealInterval then
                    entity:AddHealth(math.max(AlienTeam.kOrganicStructureHealRate * entity:GetMaxHealth(), 1), true)
                    entity.timeLastAutoHeal = Shared.GetTime()
                end
            
            end
        
        end
        
        if self.lastAutoHealIndex + AlienTeam.kAutoHealUpdateNum >= numEnts then
            self.lastAutoHealIndex = 1
        else
            self.lastAutoHealIndex = self.lastAutoHealIndex + AlienTeam.kAutoHealUpdateNum
        end 

        self.timeOfLastAutoHeal = Shared.GetTime()

   end
    
end

function AlienTeam:InitTechTree(techTree)

    PlayingTeam.InitTechTree(self, techTree)
    
    // Gorge specific orders
    techTree:AddOrder(kTechId.AlienMove)
    techTree:AddOrder(kTechId.AlienAttack)
    //techTree:AddOrder(kTechId.AlienDefend)
    techTree:AddOrder(kTechId.AlienConstruct)
    techTree:AddOrder(kTechId.Heal)
        
    // Hive types
    techTree:AddBuildNode(kTechId.Hive,                    kTechId.None,           kTechId.None)
    techTree:AddBuildNode(kTechId.CragHive,                kTechId.Hive,                kTechId.None)
    techTree:AddBuildNode(kTechId.ShadeHive,               kTechId.Hive,                kTechId.None)
    techTree:AddBuildNode(kTechId.ShiftHive,               kTechId.Hive,                kTechId.None)
    techTree:AddBuildNode(kTechId.WhipHive,                kTechId.Hive,                kTechId.None)
    techTree:AddUpgradeNode(kTechId.UpgradeToCragHive,     kTechId.Hive,                kTechId.None)
    techTree:AddUpgradeNode(kTechId.UpgradeToShadeHive,    kTechId.Hive,                kTechId.None)
    techTree:AddUpgradeNode(kTechId.UpgradeToShiftHive,    kTechId.Hive,                kTechId.None)
    techTree:AddUpgradeNode(kTechId.UpgradeToWhipHive,     kTechId.Hive,                kTechId.None)
    
    // Alien Structures
    techTree:AddBuildNode(kTechId.Harvester,                 kTechId.None,               kTechId.None)
    techTree:AddBuildNode(kTechId.Crag,                      kTechId.CragHive,           kTechId.None)
    techTree:AddBuildNode(kTechId.Shift,                     kTechId.ShiftHive,          kTechId.None)
    techTree:AddBuildNode(kTechId.Shade,                     kTechId.ShadeHive,          kTechId.None)
    techTree:AddBuildNode(kTechId.Whip,                      kTechId.WhipHive,           kTechId.None)
    techTree:AddBuildNode(kTechId.Hydra,                     kTechId.None,               kTechId.None)
    
    // Lifeforms
    techTree:AddAction(kTechId.Skulk,                     kTechId.None,                kTechId.None)
    techTree:AddAction(kTechId.Gorge,                     kTechId.None,                kTechId.None)
    techTree:AddAction(kTechId.Lerk,                      kTechId.None,                kTechId.None)
    techTree:AddAction(kTechId.Fade,                      kTechId.None,                kTechId.None)
    techTree:AddAction(kTechId.Onos,                      kTechId.None,                kTechId.None)
    techTree:AddBuyNode(kTechId.Egg,                      kTechId.None,                kTechId.None)
    
    // Tier 2 Abilities
    techTree:AddUpgradeNode(kTechId.Leap,                kTechId.TwoHives,              kTechId.None)
    techTree:AddUpgradeNode(kTechId.Umbra,               kTechId.TwoHives,              kTechId.None)
    techTree:AddUpgradeNode(kTechId.BileBomb,            kTechId.TwoHives,              kTechId.None)
    techTree:AddUpgradeNode(kTechId.Metabolize,          kTechId.TwoHives,              kTechId.None)
    techTree:AddUpgradeNode(kTechId.Stomp,               kTechId.TwoHives,              kTechId.None)

    // Tier 3 Abilities
    techTree:AddUpgradeNode(kTechId.Xenocide,            kTechId.ThreeHives,              kTechId.None)
    techTree:AddUpgradeNode(kTechId.PrimalScream,        kTechId.ThreeHives,              kTechId.None)
    techTree:AddUpgradeNode(kTechId.Web,                 kTechId.ThreeHives,              kTechId.None)
    techTree:AddUpgradeNode(kTechId.AcidRocket,          kTechId.ThreeHives,              kTechId.None)
    techTree:AddUpgradeNode(kTechId.Devour,              kTechId.ThreeHives,              kTechId.None)  
    techTree:AddUpgradeNode(kTechId.Charge,              kTechId.ThreeHives,              kTechId.None)      
    techTree:AddBuildNode(kTechId.BabblerEgg,            kTechId.ThreeHives,              kTechId.None)
        
    // Global alien upgrades. Make sure the first prerequisite is the main tech required for it, as this is 
    // what is used to display research % in the alien evolve menu.
    // The second prerequisite is needed to determine the buy node unlocked when the upgrade is actually researched.
    
    if GetServerGameMode() == kGameMode.Classic then
    
        techTree:AddBuyNode(kTechId.Carapace, kTechId.Crag, kTechId.None, kTechId.AllAliens)    
        techTree:AddBuyNode(kTechId.Regeneration, kTechId.Crag, kTechId.None, kTechId.AllAliens)
        techTree:AddBuyNode(kTechId.Redemption, kTechId.Crag, kTechId.None, kTechId.AllAliens)
        
        techTree:AddBuyNode(kTechId.Celerity, kTechId.Shift, kTechId.None, kTechId.AllAliens)  
        techTree:AddBuyNode(kTechId.Adrenaline, kTechId.Shift, kTechId.None, kTechId.AllAliens)
        techTree:AddBuyNode(kTechId.Redeployment, kTechId.Shift, kTechId.None, kTechId.AllAliens)
        
        techTree:AddBuyNode(kTechId.Silence, kTechId.Shade, kTechId.None, kTechId.AllAliens)
        techTree:AddBuyNode(kTechId.Ghost , kTechId.Shade, kTechId.None, kTechId.AllAliens)
        techTree:AddBuyNode(kTechId.Aura, kTechId.Shade, kTechId.None, kTechId.AllAliens)
        
        techTree:AddBuyNode(kTechId.Focus, kTechId.Whip, kTechId.None, kTechId.AllAliens)
        techTree:AddBuyNode(kTechId.Fury, kTechId.Whip, kTechId.None, kTechId.AllAliens)
        techTree:AddBuyNode(kTechId.Bombard, kTechId.Whip, kTechId.None, kTechId.AllAliens)
        
        techTree:AddSpecial(kTechId.TwoHives)
        techTree:AddSpecial(kTechId.ThreeHives)
        
    end
    
    if GetServerGameMode() == kGameMode.Combat then
    
        techTree:AddBuyNode(kTechId.Carapace, kTechId.None, kTechId.None, kTechId.AllAliens)    
        techTree:AddBuyNode(kTechId.Regeneration, kTechId.None, kTechId.None, kTechId.AllAliens)
        techTree:AddBuyNode(kTechId.Redemption, kTechId.None, kTechId.None, kTechId.AllAliens)
        
        techTree:AddBuyNode(kTechId.Celerity, kTechId.None, kTechId.None, kTechId.AllAliens)  
        techTree:AddBuyNode(kTechId.Adrenaline, kTechId.None, kTechId.None, kTechId.AllAliens)
        techTree:AddBuyNode(kTechId.Redeployment, kTechId.None, kTechId.None, kTechId.AllAliens)
        
        techTree:AddBuyNode(kTechId.Silence, kTechId.None, kTechId.None, kTechId.AllAliens)
        techTree:AddBuyNode(kTechId.Ghost , kTechId.None, kTechId.None, kTechId.AllAliens)
        techTree:AddBuyNode(kTechId.Aura, kTechId.None, kTechId.None, kTechId.AllAliens)
        
        techTree:AddBuyNode(kTechId.Focus, kTechId.None, kTechId.None, kTechId.AllAliens)
        techTree:AddBuyNode(kTechId.Fury, kTechId.None, kTechId.None, kTechId.AllAliens)
        techTree:AddBuyNode(kTechId.Bombard, kTechId.None, kTechId.None, kTechId.AllAliens)

		techTree:AddBuyNode(kTechId.TwoHives, kTechId.None, kTechId.None, kTechId.AllAliens)
    	techTree:AddBuyNode(kTechId.ThreeHives, kTechId.TwoHives, kTechId.None, kTechId.AllAliens)
    	
    end
    
    //Add this incase other mods want to modify tech tree
	if self.ModifyTechTree then
		self:ModifyTechTree(techTree)
	end
    
    techTree:SetComplete()
    
end

function AlienTeam:GetActiveHiveCount()

    local activeHiveCount = 0
    
    for index, hive in ipairs(GetEntitiesForTeam("Hive", self:GetTeamNumber())) do
    
        if hive:GetIsAlive() and hive:GetIsBuilt() then
            activeHiveCount = activeHiveCount + 1
        end
    
    end

    return activeHiveCount

end

function AlienTeam:GetActiveUnassignedHiveCount()

    local activeHiveCount = 0
    
    for index, hive in ipairs(GetEntitiesForTeam("Hive", self:GetTeamNumber())) do
    
        if hive:GetIsAlive() and hive:GetTechId() == kTechId.Hive then
            activeHiveCount = activeHiveCount + 1
        end
    
    end

    return activeHiveCount

end

function AlienTeam:GetActiveEggCount()

    local activeEggCount = 0
    
    for _, egg in ipairs(GetEntitiesForTeam("Egg", self:GetTeamNumber())) do
    
        if egg:GetIsAlive() and egg:GetIsEmpty() then
            activeEggCount = activeEggCount + 1
        end
    
    end
    
    return activeEggCount

end

/**
 * Inform all alien players about the hive construction (add new abilities).
 */
 
function AlienTeam:OnEggCreated(egg)

    local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())  
    if teamInfo then
        teamInfo:SetEggCount(teamInfo:GetEggCount() + 1)
    end

end

function AlienTeam:OnEggDestroyed(egg)

    local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())  
    if teamInfo then
        teamInfo:SetEggCount(teamInfo:GetEggCount() - 1)
    end

end
  
function AlienTeam:OnHivePlaced(newHive)

    local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())  
    if teamInfo then
        teamInfo:SetActiveUnassignedHiveCount(self:GetActiveUnassignedHiveCount())
    end

end
  
function AlienTeam:OnHiveConstructed(newHive)

    SendTeamMessage(self, kTeamMessageTypes.HiveConstructed, newHive:GetLocationId())
    
    local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())  
    if teamInfo then
        teamInfo:SetActiveHiveCount(self:GetActiveHiveCount())
    end
    
end

function AlienTeam:OnHiveDelayedConstructed(newHive)

    local activeHiveCount = self:GetActiveHiveCount()
    if newHive:GetIsAlive() then
        for index, alien in ipairs(GetEntitiesForTeam("Alien", self:GetTeamNumber())) do
            if alien:GetIsAlive() and alien.OnHiveConstructed then
                alien:OnHiveConstructed(newHive, activeHiveCount)
            end
        end
    end
    
end

function AlienTeam:SetHiveTechIdChosen(hive, techId)

    for index, alien in ipairs(GetEntitiesForTeam("Alien", self:GetTeamNumber())) do
        if alien:GetIsAlive() and alien.OnHiveUpgraded then
            alien:OnHiveUpgraded(hive, techId)
        end
    end
    
    local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())  
    if teamInfo then
        teamInfo:SetActiveUnassignedHiveCount(self:GetActiveUnassignedHiveCount())
    end
    
end

/**
 * Inform all alien players about the hive destruction (remove abilities).
 */
function AlienTeam:OnHiveDestroyed(destroyedHive)

    local activeHiveCount = self:GetActiveHiveCount()
    
    for index, alien in ipairs(GetEntitiesForTeam("Alien", self:GetTeamNumber())) do
        if alien:GetIsAlive() and alien.OnHiveDestroyed then
            alien:OnHiveDestroyed(destroyedHive, activeHiveCount)
        end
    end
    
    local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())
    if teamInfo then
        teamInfo:SetActiveHiveCount(activeHiveCount)
        if destroyedHive and destroyedHive:GetTechId() == kTechId.Hive then
            teamInfo:SetActiveUnassignedHiveCount(activeHiveCount)
        end
    end
    
end

function AlienTeam:OnUpgradeChamberConstructed(upgradeChamber)

    local techId = upgradeChamber:GetTechId()
    
    if not self.upgradeChambers[techId] then
        self.upgradeChambers[techId] = 0
    end
    
    if self.upgradeChambers[techId] == 0 then
        SendTeamMessage(self, kTeamMessageTypes.ResearchComplete, techId)
        self:PlayPrivateTeamSound(AlienTeam.kNewTraitSound)
    end
    
    self.upgradeChambers[techId] = self.upgradeChambers[techId] + 1
    
    local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())  
    if teamInfo then
        teamInfo:UpdateNumUpgradeStructures(techId, self.upgradeChambers[techId])
    end

    if techId == kTechId.Crag then
        UpdateAlienArmor(self)
    end

    
end

function AlienTeam:OnUpgradeChamberDestroyed(upgradeChamber)
    
    local techId = upgradeChamber:GetTechId()
    //Erm, shouldnt happen
    self.upgradeChambers[techId] = self.upgradeChambers[techId] - 1 or 0
    
    if self.upgradeChambers[techId] <= kChamberLostNotification then
        SendTeamMessage(self, kTeamMessageTypes.ResearchLost, techId)
    end
    
    local teamInfo = GetTeamInfoEntity(self:GetTeamNumber())  
    if teamInfo then
        teamInfo:UpdateNumUpgradeStructures(techId, self.upgradeChambers[techId])
    end

    if techId == kTechId.Crag then
        UpdateAlienArmor(self)
    end
    
end

function AlienTeam:GetSpectatorMapName()
    return AlienSpectator.kMapName
end

function AlienTeam:AwardResources(resAward, pointOwner)

    resAward = resAward - pointOwner:AwardResForKill(resAward)
    
    if resAward > 0 then
        self:SplitPres(resAward)
    end

end

local function AssignPlayerToEgg(self, player, spawntime, hive)

    local success = false
    local eggs = GetEntitiesForTeam("Egg", self:GetTeamNumber())
    local spawnHive = hive
    
    if not spawnHive then
        local hives = GetEntitiesForTeam("Hive", self:GetTeamNumber())
        spawnHive = hives[math.random(1,#hives)]
    end
    
    if spawnHive then
        Shared.SortEntitiesByDistance(spawnHive:GetOrigin(), eggs)
        
        //Get hives for selected spawn hive.
        local localhiveeggs = { }
        for _, egg in ipairs(eggs) do
            if egg:GetHive() == spawnHive then
                table.insert(localhiveeggs, egg)
            end
        end
        //If hive has eggs, randomly select one
        local hiveeggs = #localhiveeggs
        if hiveeggs ~= nil and hiveeggs >= 1 then
            localhiveeggs[math.random(1, hiveeggs)]:SetQueuedPlayerId(player:GetId(), spawntime)
            success = true
        else
            // Find the closest egg, doesn't matter which Hive owns it.
            for _, egg in ipairs(eggs) do
            
                // Any egg is fine as long as it is free.
                if egg:GetIsFree() then
                    egg:SetQueuedPlayerId(player:GetId(), spawntime)
                    success = true
                    break
                end
                
            end
        end
    end
    
    return success
    
end

local function GetSpawnTime(self)
    return Clamp(kAlienBaseSpawnInterval - (self:GetNumPlayers() * kAlienSpawnIntervalPerPlayer), kAlienMinSpawnInterval, kAlienMaxSpawnInterval)
end

local function RespawnPlayer(self, hive)

    if hive:GetIsAlive() and hive.queuedplayer then
        local alien = Shared.GetEntity(hive.queuedplayer)
        local spawntime = hive.timeWaveEnds
        if alien then
            local egg = nil
            if alien.GetHostEgg then
                egg = alien:GetHostEgg()
            end

            // player has no egg assigned, check for free egg
            if egg == nil then
                local success = AssignPlayerToEgg(self, alien, spawntime, hive)
                if alien.GetHostEgg then
                    egg = alien:GetHostEgg()
                end
                if not success then
                    //Fail spawn, player will automatically re-queue.
                    self:PutPlayerInRespawnQueue(alien, spawntime - GetSpawnTime(self))
                end
            end
            if egg ~= nil then
                //Egg spawn is a go houston
                success, newPlayer = egg:SpawnPlayer()
                if not success or newPlayer == nil then
                    //Not sure how this happens but i think its causing the spawn bug
                    //Requeue the player making sure to post date them correspondingly
                    Shared.Message("Failed to spawn player late in spawn queue cycle - this is a more urgent bugfix!")
                    Shared.Message(Script.CallStack())
                    self:PutPlayerInRespawnQueue(alien, spawntime - GetSpawnTime(self))   
                end
            else
                self:PutPlayerInRespawnQueue(alien, spawntime - GetSpawnTime(self))            
            end
        end
    end
    hive.queuedplayer = nil
    hive.timeWaveEnds = 0
  
end

function AlienTeam:UpdateRespawn()

    if GetServerGameMode() == kGameMode.Combat and self:GetHasAbilityToRespawn() then
        self:UpdateWaveRespawn()
    elseif GetServerGameMode() == kGameMode.Classic then
        self:UpdateHiveRespawn()
    end

end

function AlienTeam:UpdateHiveRespawn()

    local time = Shared.GetTime()

    //Dont check spawn every frame cause thats pretty silly
    if time > (self.timeLastSpawnCheck + AlienTeam.kSpawnScanInterval) then
        local hives = GetEntitiesForTeam("Hive", self:GetTeamNumber())
        for _, hive in ipairs(hives) do
            if hive:GetIsBuilt() and hive:GetIsAlive() then
                // Spawns one player per WaveDuration, loops through each player to ensure player is selected incase of oddities
                // Assigns players to eggs much earlier, also checks when they should actually be respawning incase their egg died
                if hive.timeWaveEnds == 0 and self:GetNumPlayersInQueue() > 0 then 
                    local player = self:GetOldestQueuedPlayer()
                    if player and player:isa("AlienSpectator") then 
                        hive.queuedplayer = player:GetId()
                        self:RemovePlayerFromRespawnQueue(player)
                    end
                    if hive.queuedplayer then    
                        hive.timeWaveEnds = GetSpawnTime(self) + Shared.GetTime()      
                        local player = Shared.GetEntity(hive.queuedplayer)
                        if player then
                            AssignPlayerToEgg(self, player, hive.timeWaveEnds, hive)
                            Server.SendNetworkMessage(Server.GetOwner(player), "SetTimeWaveSpawnEnds", { time = hive.timeWaveEnds }, true)
                        end      
                    end       
                end

                // spawn aliens in a wave, do nothing if the wave time has not passed yet   
                if hive.timeWaveEnds ~= 0 and hive.timeWaveEnds < Shared.GetTime() then
                    RespawnPlayer(self, hive)
                end
            end
        end
    end

end
