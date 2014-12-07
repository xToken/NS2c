// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PlayingTeam.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// This class is used for teams that are actually playing the game, e.g. Marines or Aliens.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Added concept of overflow pres, added slight scaling to aliens and setup team specific resources
Script.Load("lua/Team.lua")
Script.Load("lua/Entity.lua")
Script.Load("lua/TeamDeathMessageMixin.lua")
Script.Load("lua/bots/TeamBrain.lua")

class 'PlayingTeam' (Team)

PlayingTeam.kObliterateVictoryTeamResourcesNeeded = 500

PlayingTeam.kTooltipHelpInterval = 1

PlayingTeam.kTechTreeUpdateTime = 1

PlayingTeam.kBaseAlertInterval = 15
PlayingTeam.kRepeatAlertInterval = 15

PlayingTeam.kResearchDisplayTime = 40

/**
 * spawnEntity is the name of the map entity that will be created by default
 * when a player is spawned.
 */
function PlayingTeam:Initialize(teamName, teamNumber)

    InitMixin(self, TeamDeathMessageMixin)
    
    Team.Initialize(self, teamName, teamNumber)

    self.respawnEntity = nil
    
    self:OnCreate()
        
    self.timeSinceLastLOSUpdate = Shared.GetTime()
    self.timeSinceLastRTUpdate = Shared.GetTime()
    
    self.ejectCommVoteManager = VoteManager()
    self.ejectCommVoteManager:Initialize()
    
    self.concedeVoteManager = VoteManager()
    self.concedeVoteManager:Initialize()
    self.concedeVoteManager:SetTeamPercentNeeded(kPercentNeededForVoteConcede)
    
    self.selectupgradechamber = VoteManager()
    self.selectupgradechamber:Initialize()
    self.selectupgradechamber:SetTeamPercentNeeded(kPercentNeededForUpgradeChamberVote)
    self.selectupgradechamber:SetDuration(60)
    self.selectupgradechamber:SetMinVotes(1)

    // child classes can specify a custom team info class
    local teamInfoMapName = TeamInfo.kMapName
    if self.GetTeamInfoMapName then
        teamInfoMapName = self:GetTeamInfoMapName()
    end
    
    local teamInfoEntity = Server.CreateEntity(teamInfoMapName)
    
    self.teamInfoEntityId = teamInfoEntity:GetId()
    teamInfoEntity:SetWatchTeam(self)
    
    self.lastCommPingTime = 0
    self.lastCommPingPosition = Vector(0,0,0)
    
    self.entityTechIds = {}
    self.techIdCount = {}

    self.eventListeners = {}

end

function PlayingTeam:AddListener( event, func )

    local listeners = self.eventListeners[event]

    if not listeners then
        listeners = {}
        self.eventListeners[event] = listeners
    end

    table.insert( listeners, func )

    //DebugPrint( 'event %s has %d listeners', event, #self.eventListeners[event] )

end

function PlayingTeam:Uninitialize()

    if self.teamInfoEntityId and Shared.GetEntity(self.teamInfoEntityId) then
    
        DestroyEntity(Shared.GetEntity(self.teamInfoEntityId))
        self.teamInfoEntityId = nil
        
    end
    
    self.entityTechIds = { }
    self.techIdCount = { }
    
    Team.Uninitialize(self)
    
end

function PlayingTeam:AddPlayer(player)

    local added = Team.AddPlayer(self, player)
    
    player.teamResources = self.teamResources
    
    return added
    
end

function PlayingTeam:OnCreate()

    self.entityTechIds = {}
    self.techIdCount = {}
    Team.OnCreate(self)
      
end

function PlayingTeam:OnInitialized()

    self.entityTechIds = {}
    self.techIdCount = {}

    Team.OnInitialized(self)
    
    self.techTree = TechTree()
    self:InitTechTree(self.techTree)
    self.requiredTechIds = self.techTree:GetRequiredTechIds()
    self.timeOfLastTechTreeUpdate = nil
    
    self.lastPlayedTeamAlertName = nil
    self.timeOfLastPlayedTeamAlert = nil
    self.alerts = {}
    
    self.timeSinceLastRTUpdate = Shared.GetTime()
    
    self.teamResources = 0
    self.totalTeamResourcesCollected = 0
    self.totalTeamResFromTowers = 0
    
    self.ejectCommVoteManager:Reset()
    self.concedeVoteManager:Reset()
    self.selectupgradechamber:Reset()
    
    self.conceded = false
    
    self.lastCommPingTime = 0
    self.lastCommPingPosition = Vector(0,0,0)

end

function PlayingTeam:GetStartingResources()
	return 0
end

function PlayingTeam:ResetTeam()

    local initialTechPoint = self:GetInitialTechPoint()
    
    local tower, commandStructure = self:SpawnInitialStructures(initialTechPoint)
    
    self.overflowres = 0
    self.conceded = false
    
    local players = GetEntitiesForTeam("Player", self:GetTeamNumber())
    for p = 1, #players do
        local player = players[p]
        player:OnInitialSpawn(initialTechPoint:GetOrigin())
		player:SetResources(self:GetStartingResources())
    end
    
    return commandStructure
    
end

function PlayingTeam:GetInfoEntity()
    return Shared.GetEntity(self.teamInfoEntityId)
end

function PlayingTeam:OnResetComplete()
end

function PlayingTeam:GetNumCapturedTechPoints()

    local commandStructures = GetEntitiesForTeam("CommandStructure", self:GetTeamNumber())
    local count = 0
    
    for index, cs in ipairs(commandStructures) do
    
        if cs:GetIsBuilt() and cs:GetIsAlive() and cs:GetAttached() then
            count = count + 1
        end
        
    end
    
    return count

end

function PlayingTeam:Reset()

    self:OnInitialized()
    
    Team.Reset(self)

    Server.SendNetworkMessage( "Reset", {}, true )

end

function PlayingTeam:GetHasCommander()
    local commanders = GetEntitiesForTeam("Commander", self:GetTeamNumber())
    return table.count(commanders) > 0
end

// This is the initial tech point for the team
function PlayingTeam:GetInitialTechPoint()
    return Shared.GetEntity(self.initialTechPointId)
end

function PlayingTeam:InitTechTree(techTree)
    
    techTree:Initialize()
    
    techTree:SetTeamNumber(self:GetTeamNumber())
    
    // Menus
    techTree:AddMenu(kTechId.BuildMenu)
    techTree:AddMenu(kTechId.AdvancedMenu)
    techTree:AddMenu(kTechId.AssistMenu)
    
    // Orders
    techTree:AddOrder(kTechId.Default)
    techTree:AddOrder(kTechId.Move)
    techTree:AddOrder(kTechId.Patrol)
    techTree:AddOrder(kTechId.Attack)
    techTree:AddOrder(kTechId.Build)
    techTree:AddOrder(kTechId.Construct)
    techTree:AddOrder(kTechId.AutoConstruct)
    
    techTree:AddAction(kTechId.Cancel)
    
    techTree:AddOrder(kTechId.Weld)   
    
    techTree:AddAction(kTechId.Stop)
    
    techTree:AddOrder(kTechId.SetRally)
    techTree:AddOrder(kTechId.SetTarget)
    
end

// Returns marine or alien type
function PlayingTeam:GetTeamType()
    return self.teamType
end

local relevantResearchIds = nil
local function GetIsResearchRelevant(techId)

    if not relevantResearchIds then
    
        relevantResearchIds = {}
        
        relevantResearchIds[kTechId.Armor1] = 1
        relevantResearchIds[kTechId.Armor2] = 1
        relevantResearchIds[kTechId.Armor3] = 1
        
        relevantResearchIds[kTechId.Weapons1] = 1
        relevantResearchIds[kTechId.Weapons2] = 1
        relevantResearchIds[kTechId.Weapons3] = 1
        
        relevantResearchIds[kTechId.Leap] = 1
        relevantResearchIds[kTechId.BileBomb] = 1
        relevantResearchIds[kTechId.Umbra] = 1
        relevantResearchIds[kTechId.Metabolize] = 1
        relevantResearchIds[kTechId.Stomp] = 1
        
        relevantResearchIds[kTechId.Xenocide] = 1
        relevantResearchIds[kTechId.Web] = 1
        relevantResearchIds[kTechId.PrimalScream] = 1
        relevantResearchIds[kTechId.AcidRocket] = 1
        relevantResearchIds[kTechId.Devour] = 1
    
    end
    
    return relevantResearchIds[techId]

end

function PlayingTeam:OnResearchComplete(structure, researchId)

    // Loop through all entities on our team and tell them research was completed
    local teamEnts = GetEntitiesWithMixinForTeam("Research", self:GetTeamNumber())
    for index, ent in ipairs(teamEnts) do
        ent:TechResearched(structure, researchId)
    end
    
    if structure then
    
        local techNode = self:GetTechTree():GetTechNode(researchId)
        
        if techNode and (techNode:GetIsEnergyManufacture() or techNode:GetIsManufacture() or techNode:GetIsPlasmaManufacture()) then
            self:TriggerAlert(ConditionalValue(self:GetTeamType() == kMarineTeamType, kTechId.MarineAlertManufactureComplete, kTechId.AlienAlertManufactureComplete), structure)  
        else
            self:TriggerAlert(ConditionalValue(self:GetTeamType() == kMarineTeamType, kTechId.MarineAlertResearchComplete, kTechId.AlienAlertResearchComplete), structure)
        end
        
    end
    
    // pass relevant techIds to team info object
    local techPriority = GetIsResearchRelevant(researchId)
    if techPriority ~= nil then
    
        local teamInfoEntity = Shared.GetEntity(self.teamInfoEntityId)
        teamInfoEntity:SetLatestResearchedTech(researchId, Shared.GetTime() + PlayingTeam.kResearchDisplayTime, techPriority) 
        
    end

    // inform listeners

    local listeners = self.eventListeners['OnResearchComplete']

    if listeners then
    
        for _, listener in ipairs(listeners) do
            listener(structure, researchId)
        end

    end

end

function PlayingTeam:OnCommanderAction(techId)

    local listeners = self.eventListeners['OnCommanderAction']

    if listeners then

        for _, listener in ipairs(listeners) do
            listener(techId)
        end

    end

end

function PlayingTeam:OnConstructionComplete(structure)

    local listeners = self.eventListeners['OnConstructionComplete']

    if listeners then

        for _, listener in ipairs(listeners) do
            listener(structure)
        end

    end

end

// Returns sound name of last alert and time last alert played (for testing)
function PlayingTeam:GetLastAlert()
    return self.lastPlayedTeamAlertName, self.timeOfLastPlayedTeamAlert
end

// Play audio alert for all players, but don't trigger them too often. 
// This also allows neat tactics where players can time strikes to prevent the other team from instant notification of an alert, ala RTS.
// Returns true if the alert was played.
function PlayingTeam:TriggerAlert(techId, entity, force)

    local triggeredAlert = false
    
    assert(techId ~= kTechId.None)
    assert(techId ~= nil)
    assert(entity ~= nil)
    
    if GetGamerules():GetGameStarted() then
    
        local location = entity:GetOrigin()
        table.insert(self.alerts, { techId, entity:GetId() })
        
        // Lookup sound name
        local soundName = LookupTechData(techId, kTechDataAlertSound, "")
        if soundName ~= "" then
        
            local isRepeat = (self.lastPlayedTeamAlertName ~= nil and self.lastPlayedTeamAlertName == soundName)
            
            local timeElapsed = math.huge
            if self.timeOfLastPlayedTeamAlert ~= nil then
                timeElapsed = Shared.GetTime() - self.timeOfLastPlayedTeamAlert
            end
            
            // Ignore source players for some alerts
            local ignoreSourcePlayer = ConditionalValue(LookupTechData(techId, kTechDataAlertOthersOnly, false), nil, entity)
            local ignoreInterval = LookupTechData(techId, kTechDataAlertIgnoreInterval, false)
            
            local newAlertPriority = LookupTechData(techId, kTechDataAlertPriority, 0)
            if not self.lastAlertPriority then
                self.lastAlertPriority = 0
            end

            // If time elapsed > kBaseAlertInterval and not a repeat, play it OR
            // If time elapsed > kRepeatAlertInterval then play it no matter what
            if force or ignoreInterval or (timeElapsed >= PlayingTeam.kBaseAlertInterval and not isRepeat) or timeElapsed >= PlayingTeam.kRepeatAlertInterval or newAlertPriority  > self.lastAlertPriority then
            
                // Play for commanders only or for the whole team
                local commandersOnly = not LookupTechData(techId, kTechDataAlertTeam, false)
                
                local ignoreDistance = LookupTechData(techId, kTechDataAlertIgnoreDistance, false)
                
                self:PlayPrivateTeamSound(soundName, location, commandersOnly, ignoreSourcePlayer, ignoreDistance, entity)
                
                if not ignoreInterval then
                
                    self.lastPlayedTeamAlertName = soundName
                    self.lastAlertPriority = newAlertPriority
                    self.timeOfLastPlayedTeamAlert = Shared.GetTime()
                    
                end
                
                triggeredAlert = true
                
                // Check if we should also send out a team message for this alert.
                local sendTeamMessageType = LookupTechData(techId, kTechDataAlertSendTeamMessage)
                if sendTeamMessageType then
                    SendTeamMessage(self, sendTeamMessageType, entity:GetLocationId())
                end
                
                for i, playerId in ipairs(self.playerIds) do
                
                    local player = Shared.GetEntity(playerId)
                    if player then
                        player:TriggerAlert(techId, entity)
                    end
                    
                end
                
            end
            
        end
  
    end
    
    return triggeredAlert
    
end

function PlayingTeam:SetTeamResources(amount)

    self.teamResources = math.min(kMaxTeamResources, amount)
    
    function PlayerSetTeamResources(player)
        player:SetTeamResources(self.teamResources)
    end
    
    self:ForEachPlayer(PlayerSetTeamResources)
    
end

function PlayingTeam:GetTeamResources()
    return self.teamResources
end

function PlayingTeam:AddTeamResources(amount, isIncome)

    if amount > 0 and isIncome then
        self.totalTeamResourcesCollected = self.totalTeamResourcesCollected + amount
    end
    
    self:SetTeamResources(self.teamResources + amount)
    
end

function PlayingTeam:GetTotalTeamResources()
    return self.totalTeamResourcesCollected
end

function PlayingTeam:GetHasTeamLost()

    PROFILE("PlayingTeam:GetHasTeamLost")

    if GetGamerules():GetGameStarted() and not Shared.GetCheatsEnabled() then
    
        // Team can't respawn or last Command Station or Hive destroyed
        local activePlayers = self:GetHasActivePlayers()
        local abilityToRespawn = self:GetHasAbilityToRespawn()
        local numAliveCommandStructures = self:GetNumAliveCommandStructures()
        
        if GetServerGameMode() == kGameMode.Classic then        
            if not abilityToRespawn and not activePlayers or self:GetNumPlayers() == 0 or self:GetHasConceded() then
                return true
            end
        end
        
        if GetServerGameMode() == kGameMode.Combat then
            return numAliveCommandStructures == 0
        end
        
    end
    
    return false
    
end

local function SpawnResourceTower(self, techPoint)

    local techPointOrigin = Vector(techPoint:GetOrigin())
    
    local closestPoint = nil
    local closestPointDistance = 0
    
    for index, current in ientitylist(Shared.GetEntitiesWithClassname("ResourcePoint")) do
    
        // The resource point and tech point must be in locations that share the same name.
        local sameLocation = techPoint:GetLocationName() == current:GetLocationName()
        if sameLocation then
        
            local pointOrigin = Vector(current:GetOrigin())
            local distance = (pointOrigin - techPointOrigin):GetLength()
            
            if current:GetAttached() == nil and closestPoint == nil or distance < closestPointDistance then
            
                closestPoint = current
                closestPointDistance = distance
                
            end
            
        end
        
    end
    
    // Now spawn appropriate resource tower there
    if closestPoint ~= nil then
    
        local techId = ConditionalValue(self:GetIsAlienTeam(), kTechId.Harvester, kTechId.Extractor)
        return closestPoint:SpawnResourceTowerForTeam(self, techId)
        
    end
    
    return nil
    
end

/**
 * Spawn hive or command station at nearest empty tech point to specified team location.
 * Does nothing if can't find any.
 */
local function SpawnCommandStructure(techPoint, teamNumber)

    local commandStructure = techPoint:SpawnCommandStructure(teamNumber)
    assert(commandStructure ~= nil)
    commandStructure:SetConstructionComplete()
    
    // Use same align as tech point.
    local techPointCoords = techPoint:GetCoords()
    techPointCoords.origin = commandStructure:GetOrigin()
    commandStructure:SetCoords(techPointCoords)
    
    return commandStructure
    
end

function PlayingTeam:SpawnInitialStructures(techPoint)

    assert(techPoint ~= nil)
    
    if GetServerGameMode() == kGameMode.Classic then
        // Spawn tower at nearest unoccupied resource point.
        local tower = SpawnResourceTower(self, techPoint)
        if not tower then
            Print("Warning: Failed to spawn a resource tower for tech point in location: " .. techPoint:GetLocationName())
        end
    
    end
    // Spawn hive/command station at team location.
    local commandStructure = SpawnCommandStructure(techPoint, self:GetTeamNumber())
    
    return tower, commandStructure
    
end

function PlayingTeam:GetHasAbilityToRespawn()
    return true
end

function PlayingTeam:GetIsAlienTeam()
    return false
end

function PlayingTeam:GetIsMarineTeam()
    return false    
end

/**
 * Transform player to appropriate team respawn class and respawn them at an appropriate spot for the team.
 * Pass nil origin/angles to have spawn entity chosen.
 */
function PlayingTeam:ReplaceRespawnPlayer(player, origin, angles, mapName)

    local spawnMapName = self.respawnEntity
    
    if mapName ~= nil then
        spawnMapName = mapName
    end
    
    local newPlayer = player:Replace(spawnMapName, self:GetTeamNumber(), false, origin)
    
    // If we fail to find a place to respawn this player, put them in the Team's
    // respawn queue.
    if not self:RespawnPlayer(newPlayer, origin, angles) then
    
        newPlayer = newPlayer:Replace(newPlayer:GetDeathMapName())
        self:PutPlayerInRespawnQueue(newPlayer)
        
    end
    
    newPlayer:ClearGameEffects()
    if HasMixin(newPlayer, "Upgradable") then
        newPlayer:ClearUpgrades()
    end
    
    return (newPlayer ~= nil), newPlayer
    
end

function PlayingTeam:ReplaceRespawnAllPlayers()

    local playerIds = table.duplicate(self.playerIds)

    for i = 1, #playerIds do
		
		local playerId = playerIds[ i ]
        local player = Shared.GetEntity(playerId)
        self:ReplaceRespawnPlayer(player, nil, nil)

    end
    
end

// Call with origin and angles, or pass nil to have them determined from team location and spawn points.
function PlayingTeam:RespawnPlayer(player, origin, angles)

    local success = false
    local initialTechPoint = Shared.GetEntity(self.initialTechPointId)
    
    if origin ~= nil and angles ~= nil then
        success = Team.RespawnPlayer(self, player, origin, angles)
    elseif initialTechPoint ~= nil then
    
        // Compute random spawn location
        local capsuleHeight, capsuleRadius = player:GetTraceCapsule()
        local spawnOrigin = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, initialTechPoint:GetOrigin(), 2, 15, EntityFilterAll())
        
        if not spawnOrigin then
            spawnOrigin = initialTechPoint:GetOrigin() + Vector(2, 0.2, 2)
        end
        
        // Orient player towards tech point
        local lookAtPoint = initialTechPoint:GetOrigin() + Vector(0, 5, 0)
        local toTechPoint = GetNormalizedVector(lookAtPoint - spawnOrigin)
        success = Team.RespawnPlayer(self, player, spawnOrigin, Angles(GetPitchFromVector(toTechPoint), GetYawFromVector(toTechPoint), 0))
        
    else
        Print("PlayingTeam:RespawnPlayer(): No initial tech point.")
    end
    
    return success
    
end

//Up to implementing child classes to override and calculate reutrn value
function PlayingTeam:GetTotalInRespawnQueue()
    return 0
end


function PlayingTeam:TechAdded(entity)

    PROFILE("PlayingTeam:TechAdded")

    // Tell tech tree to recompute availability next think
    local techId = entity:GetTechId()

    if not self.requiredTechIds then
        self.requiredTechIds = { }
    end
    
    // don't do anything if this tech is not prereq of another tech
    if not self.requiredTechIds[techId] then
        return
    end    
    
    table.insertunique(self.entityTechIds, techId)
    
    if self.techIdCount[techId] then
        self.techIdCount[techId] = self.techIdCount[techId] + 1
    else
        self.techIdCount[techId] = 1
    end
    
    //Print("TechAdded %s  id: %s", EnumToString(kTechId, entity:GetTechId()), ToString(entity:GetTechId()))
    if self.techTree then
        self.techTree:SetTechChanged()
    end
end

function PlayingTeam:TechRemoved(entity)

    PROFILE("PlayingTeam:TechRemoved")

    // Tell tech tree to recompute availability next think
    
    local techId = entity:GetTechId()

    // don't do anything if this tech is not prereq of another tech
    if not self.requiredTechIds[techId] then
        return
    end
    
    if self.techIdCount[techId] then    
        self.techIdCount[techId] = self.techIdCount[techId] - 1    
    end
    
    if self.techIdCount[techId] == nil or self.techIdCount[techId] <= 0 then
        table.removevalue(self.entityTechIds, techId)
        self.techIdCount[techId] = nil
    end
    
    //Print(ToString(debug.traceback()))
    //Print("TechRemoved %s  id: %s", EnumToString(kTechId, entity:GetTechId()), ToString(entity:GetTechId()))
    if(self.techTree ~= nil) then
        self.techTree:SetTechChanged()
    end
    
end

function PlayingTeam:GetTeamBrain()

    // we have bots, need a team brain
    // lazily init team brain
    if self.brain == nil then
        self.brain = TeamBrain()
        self.brain:Initialize(self.teamName.."-Brain", self:GetTeamNumber())
    end

    return self.brain
            
end

function PlayingTeam:Update(timePassed)

    PROFILE("PlayingTeam:Update")
    
    self:UpdateTechTree()
    
    self:UpdateVotes()
            
    if GetServerGameMode() == kGameMode.Combat and self:GetHasAbilityToRespawn() then
        self:UpdateWaveRespawn()
    end
    
    if GetGamerules():GetGameStarted() then
        
        if GetServerGameMode() == kGameMode.Classic then
            self:UpdateResourceTowers()
        end

        if #gServerBots > 0 or #GetEntitiesWithMixinForTeam("PlayerHallucination", self:GetTeamNumber()) > 0 then
            self:GetTeamBrain():Update(timePassed)
        elseif self.brain then        
            self.brain = nil        
        end


    else

        // deinit team brain
        if self.brain ~= nil then
            self.brain = nil
        end

    end
    
end

function PlayingTeam:UpdateResourceTowers()

    if self.timeSinceLastRTUpdate + kResourceTowerResourceInterval < Shared.GetTime() then
    
        self.timeSinceLastRTUpdate = Shared.GetTime()
        
        local numRTs = 0

        // update resource towers        
        for index, resourceTower in ipairs(GetEntitiesForTeam("ResourceTower", self:GetTeamNumber())) do
                
            if resourceTower:GetIsCollecting() then
                resourceTower:CollectResources()        
                numRTs = numRTs + 1            
            end
            
        end
        
        // update resources
        local ResGained = numRTs * kResourcePerTick
        
        if self:GetTeamType() == kMarineTeamType then
            self:AddTeamResources(ResGained, true)
        else
            self:SplitPres(self:ApplyResourceScaling(ResGained))
        end 
        
        self.totalTeamResFromTowers = self.totalTeamResFromTowers + ResGained
    
    end

end

function PlayingTeam:UpdateWaveRespawn()

    local time = Shared.GetTime()
    
    if self.timeLastWaveSpawnCheck == nil then
        self.timeLastWaveSpawnCheck = time
        self.lastWaveSpawn = time
        self.spawnsthiswave = 0
    end

    if self.timeLastWaveSpawnCheck + 1 < time then
    
        if self.lastWaveSpawn + self:GetWaveSpawnTime() < time then
        
            //for i = 0, self:GetWaveSpawnCount() do
            local player = self:GetOldestQueuedPlayer()
            local commandStructures = GetEntitiesForTeam("CommandStructure", self:GetTeamNumber())
            if player and #commandStructures > 0 then
                self:RemovePlayerFromRespawnQueue(player)
                local techId = kTechId.Skulk
                if player:GetTeam():GetIsMarineTeam() then
                    techId = kTechId.Marine
                end
                local extents = HasMixin(self, "Extents") and self:GetExtents() or LookupTechData(techId, kTechDataMaxExtents)
                local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
                local spawnPoint = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, commandStructures[1]:GetOrigin(), 2, 15, EntityFilterAll())
                if spawnPoint then
                    local success, newplayer = self:ReplaceRespawnPlayer(player, spawnPoint, player:GetAngles())   
                    if not success then
                        self:PutPlayerInRespawnQueue(player, time - self:GetWaveSpawnTime())
                    else
                        newplayer:SetCameraDistance(0)
                        newplayer = newplayer:OnRestoreUpgrades()
                        self.spawnsthiswave = self.spawnsthiswave + 1
                    end
                end
            end
            //end
            self.lastWaveSpawn = self.lastWaveSpawn + 0.1
            
        else
        
            self.timeLastWaveSpawnCheck = time
            //Update players of their pending doom
            local pcount = 0
            local tmod = 1
            for i, player in ipairs(self:GetSortedRespawnQueue()) do
                if not player.hasbeennotified then
                    Server.SendNetworkMessage(Server.GetOwner(player), "SetTimeWaveSpawnEnds", { time = (self.lastWaveSpawn + 1 + (self:GetWaveSpawnTime() * tmod)) }, true)
                    player.hasbeennotified = true
                end
                pcount = pcount + 1
                if pcount >= self:GetRespawnsPerWave() then
                    tmod = tmod + 1
                    pcount = 0
                end
            end
            
        end
        if self:GetNumPlayersInQueue() == 0 or self.spawnsthiswave >= self:GetRespawnsPerWave() then
        
            //NO MORE YAY!
            self.spawnsthiswave = 0
            self.lastWaveSpawn = time
            self.timeLastWaveSpawnCheck = time
            
        end
    end
    
end

function PlayingTeam:PrintWorldTextForTeamInRange(messageType, data, position, range)

    local playersInRange = GetEntitiesForTeamWithinRange("Player", self:GetTeamNumber(), position, range)
    local message = BuildWorldTextMessage(messageType, data, position)
    
    for _, player in ipairs(playersInRange) do
        Server.SendNetworkMessage(player, "WorldText", message, true)        
    end

end

function PlayingTeam:GetTechTree()
    return self.techTree
end

function PlayingTeam:UpdateTechTree()

    PROFILE("PlayingTeam:UpdateTechTree")
    
    // Compute tech tree availability only so often because it's very slooow
    if self.techTree and (self.timeOfLastTechTreeUpdate == nil or Shared.GetTime() > self.timeOfLastTechTreeUpdate + PlayingTeam.kTechTreeUpdateTime) then

        self.techTree:Update(self.entityTechIds, self.techIdCount)
        
        /*
        local techTreeString = ""        
        for _, techId in ipairs(self.entityTechIds) do            
            techTreeString = techTreeString .. " " .. EnumToString(kTechId, techId) .. "(" .. ToString(self.techIdCount[techId]) .. ")"            
        end        
        Print("-----------team nr %s", ToString(self:GetTeamNumber()))
        Print(techTreeString)
        Print("------------------------")
        */

        // Send tech tree base line to players that just switched teams or joined the game        
        local players = self:GetPlayers()
        
        for index, player in ipairs(players) do
        
            if player:GetSendTechTreeBase() then
            
                self.techTree:SendTechTreeBase(player)
                
                player:ClearSendTechTreeBase()
                
            end
            
        end
        
        // Send research, availability, etc. tech node updates to team players
        self.techTree:SendTechTreeUpdates(players)
        
        self.timeOfLastTechTreeUpdate = Shared.GetTime()
        
        self:OnTechTreeUpdated()
        
    end
    
end

function PlayingTeam:OnTechTreeUpdated()
end

function PlayingTeam:VoteToGiveUp(votingPlayer)

    local votingPlayerSteamId = tonumber(Server.GetOwner(votingPlayer):GetUserId())

    if self.concedeVoteManager:PlayerVotes(votingPlayerSteamId, Shared.GetTime()) then
        PrintToLog("%s cast vote to give up.", votingPlayer:GetName())
        
        // notify all players on this team
        if Server then

            local vote = self.concedeVoteManager    

            local netmsg = {
                voterName = votingPlayer:GetName(),
                votesMoreNeeded = vote:GetNumVotesNeeded()-vote:GetNumVotesCast()
            }

            local players = GetEntitiesForTeam("Player", self:GetTeamNumber())

            for index, player in ipairs(players) do
                Server.SendNetworkMessage(player, "VoteConcedeCast", netmsg, false)
            end

        end
    end

end

function PlayingTeam:VoteForUpgradeStructure(votingPlayer, techId)

    local votingPlayerSteamId = tonumber(Server.GetOwner(votingPlayer):GetUserId())

    if self.selectupgradechamber:PlayerVotesFor(votingPlayerSteamId, techId, Shared.GetTime()) then
        PrintToLog(string.format("%s cast vote for %s upgrade.", votingPlayer:GetName(), EnumToString(kTechId, techId)))
        
        // notify all players on this team
        if Server then

            local vote = self.selectupgradechamber    

            local netmsg = {
                voterName = votingPlayer:GetName(),
                votesMoreNeeded = vote:GetNumVotesNeeded()-vote:GetNumVotesCast(),
                voteId = techId
            }

            if netmsg.votesMoreNeeded > 0 then
                local players = GetEntitiesForTeam("Player", self:GetTeamNumber())

                for index, player in ipairs(players) do
                    Server.SendNetworkMessage(player, "VoteChamberCast", netmsg, false)
                end
            end
        end
    end

end

function PlayingTeam:VoteToEjectCommander(votingPlayer, targetCommander)

    local votingPlayerSteamId = tonumber(Server.GetOwner(votingPlayer):GetUserId())
    local targetSteamId = tonumber(Server.GetOwner(targetCommander):GetUserId())
    
    if self.ejectCommVoteManager:PlayerVotesFor(votingPlayerSteamId, targetSteamId, Shared.GetTime()) then
        PrintToLog("%s cast vote to eject commander %s", votingPlayer:GetName(), targetCommander:GetName())

        // notify all players on this team
        if Server then

            local vote = self.ejectCommVoteManager    

            local netmsg = {
                voterName = votingPlayer:GetName(),
                votesMoreNeeded = (vote:GetNumVotesNeeded() - vote:GetNumVotesCast()) or 0
            }

            local players = GetEntitiesForTeam("Player", self:GetTeamNumber())

            for index, player in ipairs(players) do
                Server.SendNetworkMessage(player, "VoteEjectCast", netmsg, false)
            end

        end
    end
    
end

local function CompleteUpgradeChamberVote(self)
    local techId = self.selectupgradechamber:GetTarget()
    
    if techId ~= nil and UpgradeBaseHivetoChamberSpecific(nil, techId, self) then
        local netmsg = {
                voteId = techId
            }
        local players = GetEntitiesForTeam("Player", self:GetTeamNumber())
        for index, player in ipairs(players) do
            Server.SendNetworkMessage(player, "ChamberSelected", netmsg, false)
        end
    end
end

function PlayingTeam:UpdateVotes()

    PROFILE("PlayingTeam:UpdateVotes")
    
    if GetServerGameMode() == kGameMode.Classic then
        // Update with latest team size
        self.ejectCommVoteManager:SetNumPlayers(self:GetNumPlayers())
        self.concedeVoteManager:SetNumPlayers(self:GetNumPlayers())
        self.selectupgradechamber:SetNumPlayers(self:GetNumPlayers())
        
        // Eject commander if enough votes cast
        if self.ejectCommVoteManager:GetVotePassed() then

            local targetCommander = GetPlayerFromUserId(self.ejectCommVoteManager:GetTarget())
            
            if targetCommander and targetCommander.Eject then
                targetCommander:Eject()
            end
            
            self.ejectCommVoteManager:Reset()
            
        elseif self.ejectCommVoteManager:GetVoteElapsed(Shared.GetTime()) then
            self.ejectCommVoteManager:Reset()
        end
        
        // Upgrade chambers
        if self.selectupgradechamber:GetVotePassed() or self.selectupgradechamber:GetVoteElapsed(Shared.GetTime()) then
            CompleteUpgradeChamberVote(self)
            self.selectupgradechamber:Reset()
        end
        
        -- Give up when enough votes
        if self.concedeVoteManager:GetVotePassed() then
        
            self.concedeVoteManager:Reset()
            self.conceded = true
            Server.SendNetworkMessage("TeamConceded", { teamNumber = self:GetTeamNumber() })
            
        elseif self.concedeVoteManager:GetVoteElapsed(Shared.GetTime()) then
            self.concedeVoteManager:Reset()
        end
    end
    
end

function PlayingTeam:GetHasConceded()
    return self.conceded
end

function PlayingTeam:AddOverflowResources(resAwarded)
end

function PlayingTeam:GetPresRecipientCount()

    local recipientCount = 0
    for i, playerId in ipairs(self.playerIds) do
        
        local player = Shared.GetEntity(playerId)
        if player and player:GetResources() < kMaxPersonalResources then
            recipientCount = recipientCount + 1
        end

    end
    
    return recipientCount

end

function PlayingTeam:ApplyResourceScaling(resAmount)
    local playercount = self:GetNumPlayers()
    if (playercount <= kResourceScalingMinPlayers or playercount >= kResourceScalingMaxPlayers) then
        local playerdiff = Clamp(playercount, kResourceScalingMinPlayers + 1, kResourceScalingMaxPlayers)
        resAmount = resAmount * Clamp((1 + ((playercount - playerdiff) / kResourceScaling)), kResourceScalingMinDelta, kResourceScalingMaxDelta)
        //Print(string.format("Resources adjusted to %s from %s for %s players.", ToString(resAwarded), ToString(oldres), ToString(playercount)))
    end
    return resAmount
end

// split resources to all players until their they either have all reached the maximum or the rewarded res was splitted evenly
function PlayingTeam:SplitPres(resAwarded)

    local recipientCount = self:GetPresRecipientCount()

    for i = 1, recipientCount do 
    
        if resAwarded <= 0.001 or recipientCount <= 0 then
            break;
        end    
    
        local resPerPlayer = resAwarded / recipientCount
        
        for i, playerId in ipairs(self.playerIds) do
            local player = Shared.GetEntity(playerId)
            if player then
                resAwarded = resAwarded - player:AddResources(resPerPlayer)
            end
        end
        
        recipientCount = self:GetPresRecipientCount()

    end

    if resAwarded > 0 then
        self:AddOverflowResources(resAwarded) 
    end

end

function PlayingTeam:GetCommander()

    local commanders = GetEntitiesForTeam("Commander", self:GetTeamNumber())
    if commanders and #commanders > 0 then
        return commanders[1]
    end    

    return nil
end

function PlayingTeam:PlayCommanderSound(soundName)

    local commander = self:GetCommander()
    if commander then
        StartSoundEffectForPlayer(soundName, commander)
    end

end

function PlayingTeam:GetCommanderPingTime()
    return self.lastCommPingTime
end

function PlayingTeam:GetCommanderPingPosition()
    return self.lastCommPingPosition
end

function PlayingTeam:SetCommanderPing(position)

    if self.lastCommPingTime + 3 < Shared.GetTime() then
        self.lastCommPingTime = Shared.GetTime()
        self.lastCommPingPosition = position
    end
    
end

function PlayingTeam:OnEntityChange(oldId, newId)

    Team.OnEntityChange( self, oldId, newId )
    
    if self.brain then
        self.brain:OnEntityChange( oldId, newId )
    end

end