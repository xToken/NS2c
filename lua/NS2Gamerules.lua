// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\NS2Gamerules.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Gamerules.lua")
Script.Load("lua/dkjson.lua")

if Client then
    Script.Load("lua/NS2ConsoleCommands_Client.lua")
else
    Script.Load("lua/NS2ConsoleCommands_Server.lua")
end

class 'NS2Gamerules' (Gamerules)

NS2Gamerules.kMapName = "ns2_gamerules"

local kGameEndCheckInterval = 0.75
local kPregameLength = 15
local kTimeToReadyRoom = 8
local kPauseToSocializeBeforeMapcycle = 30

// How often to send the "No commander" message to players in seconds.
local kSendNoCommanderMessageRate = 50

// Find team start with team 0 or for specified team. Remove it from the list so other teams don't start there. Return nil if there are none.
function NS2Gamerules:ChooseTechPoint(techPoints, teamNumber)

    local validTechPoints = { }
    local totalTechPointWeight = 0
    
    // Build list of valid starts (marked as "neutral" or for this team in map)
    for _, currentTechPoint in pairs(techPoints) do
    
        // Always include tech points with team 0 and never include team 3 into random selection process
        local teamNum = currentTechPoint:GetTeamNumberAllowed()
        if (teamNum == 0 or teamNum == teamNumber) and teamNum ~= 3 then
        
            table.insert(validTechPoints, currentTechPoint)
            totalTechPointWeight = totalTechPointWeight + currentTechPoint:GetChooseWeight()
            
        end
        
    end
    
    local chosenTechPointWeight = self.techPointRandomizer:random(0, totalTechPointWeight)
    local chosenTechPoint = nil
    local currentWeight = 0
    for _, currentTechPoint in pairs(validTechPoints) do
    
        currentWeight = currentWeight + currentTechPoint:GetChooseWeight()
        if chosenTechPointWeight - currentWeight <= 0 then
        
            chosenTechPoint = currentTechPoint
            break
            
        end
        
    end
    
    // Remove it from the list so it isn't chosen by other team
    if chosenTechPoint ~= nil then
        table.removevalue(techPoints, chosenTechPoint)
    else
        assert(false, "ChooseTechPoint couldn't find a tech point for team " .. teamNumber)
    end
    
    return chosenTechPoint
    
end

////////////
// Server //
////////////
if Server then

    Script.Load("lua/PlayingTeam.lua")
    Script.Load("lua/ReadyRoomTeam.lua")
    Script.Load("lua/SpectatingTeam.lua")
    Script.Load("lua/GameViz.lua")
    Script.Load("lua/ObstacleMixin.lua")

    NS2Gamerules.kMarineStartSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/game_start")
    NS2Gamerules.kAlienStartSound = PrecacheAsset("sound/NS2.fev/alien/voiceovers/game_start")
    NS2Gamerules.kCountdownSound = PrecacheAsset("sound/NS2.fev/common/countdown")

    // Allow players to spawn in for free (not using IP or eggs) for this many seconds after the game starts
    local kFreeSpawnTime = 60

    function NS2Gamerules:BuildTeam(teamType)

        if teamType == kAlienTeamType then
            return AlienTeam()
        end
        
        return MarineTeam()
        
    end

    function NS2Gamerules:SetGameState(state)
    
        if state ~= self.gameState then
        
            self.gameState = state
            self.gameInfo:SetState(state)
            self.timeGameStateChanged = Shared.GetTime()
            self.timeSinceGameStateChanged = 0
            
            local frozenState = (state == kGameState.Countdown) and (not Shared.GetDevMode())
            self.team1:SetFrozenState(frozenState)
            self.team2:SetFrozenState(frozenState)
            
            if self.gameState == kGameState.Started then
            
                PostGameViz("Game started")
                self.gameStartTime = Shared.GetTime()
                
                self.gameInfo:SetStartTime(self.gameStartTime)
                
                SendTeamMessage(self.team1, kTeamMessageTypes.GameStarted)
                SendTeamMessage(self.team2, kTeamMessageTypes.GameStarted)
                
                // Reset disconnected player resources when a game starts to prevent shenanigans.
                self.disconnectedPlayerResources = { }
                
            end
            
            // On end game, check for map switch conditions
            if state == kGameState.Team1Won or state == kGameState.Team2Won then
            
                if MapCycle_TestCycleMap() then
                    self.timeToCycleMap = Shared.GetTime() + kPauseToSocializeBeforeMapcycle
                else
                    self.timeToCycleMap = nil
                end
                
                // Reset disconnected player resources when a game starts to prevent shenanigans.
                self.disconnectedPlayerResources = { }
            end
            
        end
        
    end

    function NS2Gamerules:GetGameTimeChanged()
        return self.timeSinceGameStateChanged
    end

    function NS2Gamerules:GetGameState()
        return self.gameState
    end

    function NS2Gamerules:OnCreate()

        // Calls SetGamerules()
        Gamerules.OnCreate(self)
        
        self.techPointRandomizer = Randomizer()
        self.techPointRandomizer:randomseed(Shared.GetSystemTime())
        
        // Create team objects
        self.team1 = self:BuildTeam(kTeam1Type)
        self.team1:Initialize(kTeam1Name, kTeam1Index)
        
        self.team2 = self:BuildTeam(kTeam2Type)
        self.team2:Initialize(kTeam2Name, kTeam2Index)
        
        self.worldTeam = ReadyRoomTeam()
        self.worldTeam:Initialize("World", kTeamReadyRoom)
        
        self.spectatorTeam = SpectatingTeam()
        self.spectatorTeam:Initialize("Spectator", kSpectatorIndex)
        
        self.gameInfo = Server.CreateEntity(GameInfo.kMapName)
        
        self:SetGameState(kGameState.NotStarted)
        
        self.allTech = false
        self.orderSelf = false
        self.autobuild = false
        
        self:SetIsVisible(false)
        self:SetPropagate(Entity.Propagate_Never)
        
        // Used to keep track of the amount of resources a player has when they
        // reconnect so we can award them the res back if they reconnect soon.
        self.disconnectedPlayerResources = { }
        
        self.justCreated = true
        
    end

    function NS2Gamerules:OnDestroy()

        self.team1:Uninitialize()
        self.team1 = nil
        self.team2:Uninitialize()
        self.team2 = nil
        self.worldTeam:Uninitialize()
        self.worldTeam = nil
        self.spectatorTeam:Uninitialize()
        self.spectatorTeam = nil

        Gamerules.OnDestroy(self)

    end
    
    function NS2Gamerules:GetFriendlyFire()
        return false
    end
    
    // All damage is routed through here.
    function NS2Gamerules:CanEntityDoDamageTo(attacker, target)
        return CanEntityDoDamageTo(attacker, target, Shared.GetCheatsEnabled(), Shared.GetDevMode(), self:GetFriendlyFire())
    end
    
    function NS2Gamerules:OnClientDisconnect(client)
    
        local player = client:GetControllingPlayer()
        
        if player ~= nil then
        
            // When a player disconnects remove them from their team
            local team = self:GetTeam(player:GetTeamNumber())
            if team then
                team:RemovePlayer(player)
            end
            
            self.disconnectedPlayerResources[client:GetUserId()] = player:GetResources()
            
        end
        
        Gamerules.OnClientDisconnect(self, client)
        
    end
    
    function NS2Gamerules:OnEntityCreate(entity)

        self:OnEntityChange(nil, entity:GetId())

        if entity.GetTeamNumber then
        
            local team = self:GetTeam(entity:GetTeamNumber())
            
            if team then
            
                if entity:isa("Player") then
            
                    if team:AddPlayer(entity) then

                        // Tell team to send entire tech tree on team change
                        entity.sendTechTreeBase = true

                        // Clear all hotkey groups on team change since old
                        // hotkey groups will be invalid.
                        entity:InitializeHotkeyGroups()                
                        
                    end
                   
                    // Send scoreboard changes to everyone    
                    entity:SetScoreboardChanged(true)
                
                end
                
            end
            
        end
        
    end

    function NS2Gamerules:OnEntityDestroy(entity)
        
        self:OnEntityChange(entity:GetId(), nil)

        if entity.GetTeamNumber then
        
            local team = self:GetTeam(entity:GetTeamNumber())
            if team then
            
                if entity:isa("Player") then
                    team:RemovePlayer(entity)
                end
                
            end
            
        end
       
    end

    // Update player and entity lists
    function NS2Gamerules:OnEntityChange(oldId, newId)

        PROFILE("NS2Gamerules:OnEntityChange")
        
        if self.worldTeam then
            self.worldTeam:OnEntityChange(oldId, newId)
        end
        
        if self.team1 then
            self.team1:OnEntityChange(oldId, newId)
        end
        
        if self.team2 then
            self.team2:OnEntityChange(oldId, newId)
        end
        
        if self.spectatorTeam then
            self.spectatorTeam:OnEntityChange(oldId, newId)
        end
        
        // Keep server map entities up to date
        local index = table.find(Server.mapLoadLiveEntityValues, oldId)
        if index then
        
            table.removevalue(Server.mapLoadLiveEntityValues, oldId)
            if newId then
                table.insert(Server.mapLoadLiveEntityValues, newId)
            end
            
        end
        
        local notifyEntities = Shared.GetEntitiesWithTag("EntityChange")
        
        // Tell notifyEntities this entity has changed ids or has been deleted (changed to nil).
        for index, ent in ientitylist(notifyEntities) do
        
            if ent:GetId() ~= oldId and ent.OnEntityChange then
                ent:OnEntityChange(oldId, newId)
            end
            
        end
        
    end
    
    local function PostKillStat(targetEntity, attacker, doer)

        if not attacker or not targetEntity or not doer then
            return
        end
        
        -- Send End Game statistics
        local url = "/kill" 
        local attackerOrigin = attacker:GetOrigin()
        local targetWeapon = "None"
        local targetOrigin = targetEntity:GetOrigin()
        
        if targetEntity.GetActiveWeapon and targetEntity:GetActiveWeapon() then
            targetWeapon = targetEntity:GetActiveWeapon():GetClassName()
        end

        local params =
        {
            version               = ToString(Shared.GetBuildNumber()),
            map                   = Shared.GetMapName(),
            attacker_type         = attacker:GetClassName(),
            attacker_team         = ((HasMixin(attacker, "Team") and attacker:GetTeamType()) or kNeutralTeamType),
            attacker_weapon       = doer:GetClassName(),
            attackerx             = string.format("%.2f", attackerOrigin.x),
            attackery             = string.format("%.2f", attackerOrigin.y),
            attackerz             = string.format("%.2f", attackerOrigin.z),
            target_type           = targetEntity:GetClassName(),
            target_team           = targetEntity:GetTeamType(),
            target_weapon         = targetWeapon,
            targetx               = string.format("%.2f", targetOrigin.x),
            targety               = string.format("%.2f", targetOrigin.y),
            targetz               = string.format("%.2f", targetOrigin.z),
            target_lifetime       = string.format("%.2f", Shared.GetTime() - targetEntity:GetCreationTime())
        }

        if HasMixin(attacker, "Upgradable") then
            params['attacker_upgrade'] = json.encode( attacker:GetUpgradeListName() )
        elseif HasMixin(targetEntity, "Upgradable") then
            params['target_upgrade'] = json.encode( targetEntity:GetUpgradeListName() )
        end

        if attacker:isa("Marine") then

            params['attacker_weaponlevel'] = attacker:GetWeaponLevel()
            params['attacker_armorlevel']  = attacker:GetArmorLevel()

        elseif targetEntity:isa("Marine") then

            params['target_weaponlevel'] = targetEntity:GetWeaponLevel()
            params['target_armorlevel']  = targetEntity:GetArmorLevel()

        end

        //Shared.SendHTTPRequest(kStatisticsURL .. url, "POST", params)
        
    end



    // Called whenever an entity is killed. Killer could be the same as targetEntity. Called before entity is destroyed.
    function NS2Gamerules:OnEntityKilled(targetEntity, attacker, doer, point, direction)
    
        // Limit how often we send up kill stats.
        self.totalKills = (self.totalKills and self.totalKills + 1) or 1
        if self.totalKills >= 5 then
        
            self.totalKills = 0
            PostKillStat(targetEntity, attacker, doer)
            
        end
        
        // Also output to log if we're recording the game for playback in the game visualizer
        PostGameViz(string.format("%s killed %s", SafeClassName(doer), SafeClassName(targetEntity)), targetEntity)
        
        self.team1:OnEntityKilled(targetEntity, attacker, doer, point, direction)
        self.team2:OnEntityKilled(targetEntity, attacker, doer, point, direction)
        self.worldTeam:OnEntityKilled(targetEntity, attacker, doer, point, direction)
        self.spectatorTeam:OnEntityKilled(targetEntity, attacker, doer, point, direction)

    end

    // logs out any players currently as the commander
    function NS2Gamerules:LogoutCommanders()

        for index, entity in ientitylist(Shared.GetEntitiesWithClassname("CommandStructure")) do
            entity:Logout()
        end
        
    end
     
    /**
     * Starts a new game by resetting the map and all of the players. Keep everyone on current teams (readyroom, playing teams, etc.) but 
     * respawn playing players.
     */
    function NS2Gamerules:ResetGame()
    
        // Cleanup any peeps currently in the commander seat by logging them out
        // have to do this before we start destroying stuff.
        self:LogoutCommanders()
        
        // Destroy any map entities that are still around
        DestroyLiveMapEntities()
        
        // Track which clients have joined teams so we don't 
        // give them starting resources again if they switch teams
        self.userIdsInGame = {}
        
        self:SetGameState(kGameState.NotStarted)
        
        // Reset all players, delete other not map entities that were created during 
        // the game (hives, command structures, initial resource towers, etc)
        // We need to convert the EntityList to a table since we are destroying entities
        // within the EntityList here.
        for index, entity in ientitylist(Shared.GetEntitiesWithClassname("Entity")) do
        
            // Don't reset/delete NS2Gamerules or TeamInfo.
            // NOTE!!!
            // MapBlips are destroyed by their owner which has the MapBlipMixin.
            // There is a problem with how this reset code works currently. A map entity such as a Hive creates
            // it's MapBlip when it is first created. Before the entity:isa("MapBlip") condition was added, all MapBlips
            // would be destroyed on map reset including those owned by map entities. The map entity Hive would still reference
            // it's original MapBlip and this would cause problems as that MapBlip was long destroyed. The right solution
            // is to destroy ALL entities when a game ends and then recreate the map entities fresh from the map data
            // at the start of the next game, including the NS2Gamerules. This is how a map transition would have to work anyway.
            // Do not destroy any entity that has a parent. The entity will be destroyed when the parent is destroyed or
            // when the owner manually destroyes the entity.
            local shieldTypes = { "TeamInfo", "GameInfo", "MapBlip", "NS2Gamerules" }
            local allowDestruction = true
            for i = 1, #shieldTypes do
                allowDestruction = allowDestruction and not entity:isa(shieldTypes[i])
            end
            
            if allowDestruction and entity:GetParent() == nil then
            
                local isMapEntity = entity:GetIsMapEntity()
                local mapName = entity:GetMapName()
                
                // Reset all map entities and all player's that have a valid Client (not ragdolled players for example).
                local resetEntity = entity:GetIsMapEntity() or (entity:isa("Player") and entity:GetClient() ~= nil)
                if resetEntity then
                
                    if entity.Reset then
                        entity:Reset()
                    end
                    
                else
                    DestroyEntity(entity)
                end
                
            end       
            
        end
        
        // Clear out obstacles from the navmesh before we start repopualating the scene
        RemoveAllObstacles()
        
        // Build list of tech points
        local techPoints = EntityListToTable(Shared.GetEntitiesWithClassname("TechPoint"))
        if table.maxn(techPoints) < 2 then
            Print("Warning -- Found only %d %s entities.", table.maxn(techPoints), TechPoint.kMapName)
        end
        
        local resourcePoints = Shared.GetEntitiesWithClassname("ResourcePoint")
        if resourcePoints:GetSize() < 2 then
            Print("Warning -- Found only %d %s entities.", resourcePoints:GetSize(), ResourcePoint.kPointMapName)
        end
        
        // Reset teams (keep players on them)
        local team1TechPoint = self:ChooseTechPoint(techPoints, kTeam1Index)
        self.team1:ResetPreservePlayers(team1TechPoint)
        local team2TechPoint = self:ChooseTechPoint(techPoints, kTeam2Index)
        self.team2:ResetPreservePlayers(team2TechPoint)
        
        assert(self.team1:GetInitialTechPoint() ~= nil)
        assert(self.team2:GetInitialTechPoint() ~= nil)
        
        // Save data for end game stats later.
        self.startingLocationNameTeam1 = team1TechPoint:GetLocationName()
        self.startingLocationNameTeam2 = team2TechPoint:GetLocationName()
        self.startingLocationsPathDistance = GetPathDistance(team1TechPoint:GetOrigin(), team2TechPoint:GetOrigin())
        self.initialHiveTechId = nil
        
        self.worldTeam:ResetPreservePlayers(nil)
        self.spectatorTeam:ResetPreservePlayers(nil)    
        
        // Replace players with their starting classes with default loadouts at spawn locations
        self.team1:ReplaceRespawnAllPlayers()
        self.team2:ReplaceRespawnAllPlayers()
        
        // Create team specific entities
        self.team1:ResetTeam()
        self.team2:ResetTeam()
        
        // Create living map entities fresh
        CreateLiveMapEntities()
        
        self.forceGameStart = false
        self.losingTeam = nil
        self.preventGameEnd = nil
        // Reset banned players for new game
        self.bannedPlayers = {}
        
        // Send scoreboard update, ignoring other scoreboard updates (clearscores resets everything)
        for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
            Server.SendCommand(player, "onresetgame")
            //player:SetScoreboardChanged(false)
        end
        
        self.team1:OnResetComplete()
        self.team2:OnResetComplete()
        
    end
    
    function NS2Gamerules:GetTeam1()
        return self.team1
    end
    
    function NS2Gamerules:GetTeam2()
        return self.team2
    end
    
    function NS2Gamerules:GetWorldTeam()
        return self.worldTeam
    end
    
    function NS2Gamerules:GetSpectatorTeam()
        return self.spectatorTeam
    end
    
    function NS2Gamerules:GetTeams()
        return { self.team1, self.team2, self.worldTeam, self.spectatorTeam }
    end
    
    /**
     * Should be called when the Hive type is chosen.
     */
    function NS2Gamerules:SetHiveTechIdChosen(hive, techId)
    
        if self.initialHiveTechId == nil then
            self.initialHiveTechId = techId
        end
        
    end
    
    function NS2Gamerules:UpdateScores()

        if (self.timeToSendScores == nil or Shared.GetTime() > self.timeToSendScores) then
        
            local allPlayers = Shared.GetEntitiesWithClassname("Player")

            // If any player scoreboard info has changed, send those updates to everyone
            for index, fromPlayer in ientitylist(allPlayers) do
            
                // Send full update if any part of it changed
                if(fromPlayer:GetScoreboardChanged()) then
                
                    // If any value has changed then we also want to update the internal score
                    // so we can update steams player info.
                    local client = Server.GetOwner(fromPlayer)
                    if client ~= nil then
                    
                        local playerScore = 0
                        if HasMixin(fromPlayer, "Scoring") then
                            playerScore = fromPlayer:GetScore()
                        end
                        Server.UpdatePlayerInfo(client, fromPlayer:GetName(), playerScore)
                        
                        if(fromPlayer:GetName() ~= "") then
                        
                            // Now send scoreboard info to everyone, including fromPlayer     
                            for index, sendToPlayer in ientitylist(allPlayers) do
                                // Build the message per player as some info is not synced for players
                                // on the other team.
                                local scoresMessage = BuildScoresMessage(fromPlayer, sendToPlayer)
                                Server.SendNetworkMessage(sendToPlayer, "Scores", scoresMessage, true)
                            end
                            
                            fromPlayer:SetScoreboardChanged(false)
                            
                        else
                            Print("Player name empty, can't send scoreboard update.")
                        end

                    end
                    
                end
                
            end
            
            // When players connect to server, they send up a request for scores (as they 
            // may not have finished connecting when the scores where previously sent)    
            for index, requestingPlayer in ientitylist(allPlayers) do

                // Check for empty name string because player isn't connected yet
                if(requestingPlayer:GetRequestsScores() and requestingPlayer:GetName() ~= "") then
                
                    // Send player all scores
                    for index, fromPlayer in ientitylist(allPlayers) do
                    
                        local scoresMessage = BuildScoresMessage(fromPlayer, requestingPlayer)
                        Server.SendNetworkMessage(requestingPlayer, "Scores", scoresMessage, true)
   
                    end
                    
                    requestingPlayer:SetRequestsScores(false)
                    
                end
                
            end
                
            // Time to send next score
            self.timeToSendScores = Shared.GetTime() + kScoreboardUpdateInterval
            
        end

    end

    // Batch together string with pings of every player to update scoreboard. This is a separate
    // command to keep network utilization down.
    function NS2Gamerules:UpdatePings()
    
        local now = Shared.GetTime()
        
        // Check if the individual player's should be sent their own ping.
        if self.timeToSendIndividualPings == nil or now >= self.timeToSendIndividualPings then
        
            for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
                Server.SendNetworkMessage(player, "Ping", BuildPingMessage(player:GetClientIndex(), player:GetPing()), false)
            end
            
            self.timeToSendIndividualPings =  now + kUpdatePingsIndividual
            
        end
        
        // Check if all player's pings should be sent to everybody.
        if self.timeToSendAllPings == nil or  now >= self.timeToSendAllPings then
        
            for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
                Server.SendNetworkMessage("Ping", BuildPingMessage(player:GetClientIndex(), player:GetPing()), false)
            end
            
            self.timeToSendAllPings =  now + kUpdatePingsAll
            
        end
        
    end
    
    // Sends player health to all spectators
    function NS2Gamerules:UpdateHealth()
    
        if self.timeToSendHealth == nil or Shared.GetTime() > self.timeToSendHealth then
        
            local spectators = Shared.GetEntitiesWithClassname("Spectator")
            if spectators:GetSize() > 0 then
            
                // Send spectator all health
                for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
                
                    for index, spectator in ientitylist(spectators) do
                        Server.SendNetworkMessage(spectator, "Health", BuildHealthMessage(player), false)
                    end
                    
                end
            
            end
            self.timeToSendHealth = Shared.GetTime() + 0.25
            
        end
        
    end
    
    // Send Tech Point info to all spectators
    function NS2Gamerules:UpdateTechPoints()
    
        if self.timeToSendTechPoints == nil or Shared.GetTime() > self.timeToSendTechPoints then
        
            local spectators = Shared.GetEntitiesWithClassname("Spectator")
            if spectators:GetSize() > 0 then
                
                local commandStructures = Shared.GetEntitiesWithClassname("CommandStructure")
                
                for index, techpoint in ientitylist(Shared.GetEntitiesWithClassname("TechPoint")) do
                
                    local message = BuildTechPointsMessage(techpoint, commandStructures)
                    for index, spectator in ientitylist(spectators) do
                        Server.SendNetworkMessage(spectator, "TechPoints", message, false)
                    end
                    
                end
            
            end
            
            self.timeToSendTechPoints = Shared.GetTime() + 0.5
            
        end
        
    end
    
    // Commander ejection functionality
    function NS2Gamerules:CastVoteByPlayer( voteTechId, player )
    
        if voteTechId == kTechId.VoteConcedeRound then
        
            if self.timeSinceGameStateChanged > kTimeGiveupPossible and self:GetGameStarted() then
            
                local team = player:GetTeam()
                team:VoteToGiveUp(player)
                
            end
        
        elseif voteTechId == kTechId.VoteDownCommander1 or voteTechId == kTechId.VoteDownCommander2 or voteTechId == kTechId.VoteDownCommander3 then

            // Get the 1st, 2nd or 3rd commander by entity order (does this on client as well)    
            local playerIndex = (voteTechId - kTechId.VoteDownCommander1 + 1)        
            local commanders = GetEntitiesForTeam("Commander", player:GetTeamNumber())
            
            if playerIndex <= table.count(commanders) then
            
                local targetCommander = commanders[playerIndex]
                local team = player:GetTeam()
                
                if player and team.VoteToEjectCommander then
                    team:VoteToEjectCommander(player, targetCommander)
                end
                
            end
            
        end
        
    end

    function NS2Gamerules:OnMapPostLoad()

        Gamerules.OnMapPostLoad(self)
        
        // Now allow script actors to hook post load
        local allScriptActors = Shared.GetEntitiesWithClassname("ScriptActor")
        for index, scriptActor in ientitylist(allScriptActors) do
            scriptActor:OnMapPostLoad()
        end
        
    end

    function NS2Gamerules:UpdateToReadyRoom()

        local state = self:GetGameState()
        if(state == kGameState.Team1Won or state == kGameState.Team2Won or state == kGameState.Draw) then
        
            if self.timeSinceGameStateChanged >= kTimeToReadyRoom then
            
                // Force the commanders to logout before we spawn people
                // in the ready room
                self:LogoutCommanders()
        
                // Set all players to ready room team
                local function SetReadyRoomTeam(player)
                    player:SetCameraDistance(0)
                    self:JoinTeam(player, kTeamReadyRoom)
					player:SetResources(0)
                end
                Server.ForAllPlayers(SetReadyRoomTeam)

                // Spawn them there and reset teams
                self:ResetGame()

            end
            
        end
        
    end
    
    function NS2Gamerules:UpdateMapCycle()
    
        if self.timeToCycleMap ~= nil and Shared.GetTime() >= self.timeToCycleMap then

            MapCycle_CycleMap()               
            self.timeToCycleMap = nil
            
        end
        
    end
    
    local function CheckForNoCommander(self, onTeam, commanderType)

        self.noCommanderStartTime = self.noCommanderStartTime or { }
        
        if not self:GetGameStarted() then
            self.noCommanderStartTime[commanderType] = nil
        else
        
            local commanderExists = Shared.GetEntitiesWithClassname(commanderType):GetSize() ~= 0
            
            if commanderExists then
                self.noCommanderStartTime[commanderType] = nil
            elseif not self.noCommanderStartTime[commanderType] then
                self.noCommanderStartTime[commanderType] = Shared.GetTime()
            elseif Shared.GetTime() - self.noCommanderStartTime[commanderType] >= kSendNoCommanderMessageRate then
            
                self.noCommanderStartTime[commanderType] = nil
                SendTeamMessage(onTeam, kTeamMessageTypes.NoCommander)
                
            end
            
        end
        
    end
    
    function NS2Gamerules:OnUpdate(timePassed)
    
        PROFILE("NS2Gamerules:OnUpdate")
        
        GetEffectManager():OnUpdate(timePassed)
        
        if Server then
        
            if self.justCreated then
            
                if not self.gameStarted then
                    self:ResetGame()
                end
                
                self.justCreated = false
                
            end
            
            if self:GetMapLoaded() then
            
                self:CheckGameStart()
                self:CheckGameEnd()
                
                self:UpdatePregame(timePassed)
                self:UpdateToReadyRoom()
                self:UpdateMapCycle()
                
                self.timeSinceGameStateChanged = self.timeSinceGameStateChanged + timePassed
                
                self.worldTeam:Update(timePassed)
                self.team1:Update(timePassed)
                self.team2:Update(timePassed)
                self.spectatorTeam:Update(timePassed)
                
                // Send scores every so often
                self:UpdateScores()
                self:UpdatePings()
                self:UpdateHealth()
                self:UpdateTechPoints()
                
                CheckForNoCommander(self, self.team1, "MarineCommander")
                CheckForNoCommander(self, self.team2, "AlienCommander")
                
            end
            
        end
        
    end
    
    /**
     * Ends the current game
     */
    function NS2Gamerules:EndGame(winningTeam)
    
        if self:GetGameState() == kGameState.Started then
        
            // Set losing team        
            local losingTeam = nil
            if winningTeam == self.team1 then
            
                self:SetGameState(kGameState.Team2Won)
                losingTeam = self.team2            
                PostGameViz("Alien win")
                
            else
            
                self:SetGameState(kGameState.Team1Won)
                losingTeam = self.team1            
                PostGameViz("Marine win")
                
            end
            
            winningTeam:ForEachPlayer(function(player) Server.SendNetworkMessage(player, "GameEnd", { win = true }, true) end)
            losingTeam:ForEachPlayer(function(player) Server.SendNetworkMessage(player, "GameEnd", { win = false }, true) end)
            self.spectatorTeam:ForEachPlayer(function(player) Server.SendNetworkMessage(player, "GameEnd", { win = losingTeam:GetTeamType() == kAlienTeamType }, true) end)
            
            self.losingTeam = losingTeam
            
            self.team1:ClearRespawnQueue()
            self.team2:ClearRespawnQueue()
            
            -- Send End Game statistics
            local initialHiveTechIdString = "None"
            local url = "/endgame" 
            
            if self.initialHiveTechId then
                initialHiveTechIdString = EnumToString(kTechId, self.initialHiveTechId)
            end
            
            local params =
            {
                version = ToString(Shared.GetBuildNumber()),
                winner = ToString(winningTeam:GetTeamType()),
                length = string.format("%.2f", Shared.GetTime() - self.gameStartTime),
                map = Shared.GetMapName(),
                start_location1 = self.startingLocationNameTeam1,
                start_location2 = self.startingLocationNameTeam2,
                start_path_distance = self.startingLocationsPathDistance,
                start_hive_tech = initialHiveTechIdString,
            }
            //Shared.SendHTTPRequest(kStatisticsURL .. url, "POST", params)
            
            // Automatically end any performance logging when the round has ended.
            Shared.ConsoleCommand("p_endlog")

        end
        
    end
    
    function NS2Gamerules:DrawGame()

        if self:GetGameState() == kGameState.Started then
        
            self:SetGameState(kGameState.Draw)
            
            // Display "draw" message
            local drawMessage = "The game was a draw!"
            self.team1:BroadcastMessage(drawMessage)
            self.team2:BroadcastMessage(drawMessage)
            
            self.team1:ClearRespawnQueue()
            self.team2:ClearRespawnQueue()  
            
        end
        
    end

    function NS2Gamerules:GetTeam(teamNum)

        local team = nil    
        if(teamNum == kTeamReadyRoom) then
            team = self.worldTeam
        elseif(teamNum == kTeam1Index) then
            team = self.team1
        elseif(teamNum == kTeam2Index) then
            team = self.team2
        elseif(teamNum == kSpectatorIndex) then
            team = self.spectatorTeam
        end
        return team
        
    end

    function NS2Gamerules:GetRandomTeamNumber()

        // Return lesser of two teams, or random one if they are the same
        local team1Players = self.team1:GetNumPlayers()
        local team2Players = self.team2:GetNumPlayers()
        
        if team1Players < team2Players then
            return self.team1:GetTeamNumber()
        elseif team2Players < team1Players then
            return self.team2:GetTeamNumber()
        end
        
        return ConditionalValue(math.random() < .5, kTeam1Index, kTeam2Index)
        
    end

    // Enforce balanced teams
    function NS2Gamerules:GetCanJoinTeamNumber(teamNumber)

        local team1Players = self.team1:GetNumPlayers()
        local team2Players = self.team2:GetNumPlayers()
        
        if (team1Players > team2Players) and (teamNumber == self.team1:GetTeamNumber()) then
            return false
        elseif (team2Players > team1Players) and (teamNumber == self.team2:GetTeamNumber()) then
            return false
        end
        
        return true

    end
    
    function NS2Gamerules:GetCanSpawnImmediately()
        return not self:GetGameStarted() or Shared.GetCheatsEnabled() or (Shared.GetTime() < (self.gameStartTime + kFreeSpawnTime))
    end
    
    // Returns bool for success and bool if we've played in the game already.
    local function GetUserPlayedInGame(self, player)
    
        local success = false
        local played = false
        
        local owner = Server.GetOwner(player)
        if owner then
        
            local userId = tonumber(owner:GetUserId())
            
            // Could be invalid if we're still connecting to Steam
            played = table.find(self.userIdsInGame, userId) ~= nil
            success = true
            
        end
        
        return success, played
        
    end
    
    local function SetUserPlayedInGame(self, player)
    
        local owner = Server.GetOwner(player)
        if owner then
        
            local userId = tonumber(owner:GetUserId())
            
            // Could be invalid if we're still connecting to Steam.
            return table.insertunique(self.userIdsInGame, userId)
            
        end
        
        return false
        
    end
    
    /**
     * Returns two return codes: success and the player on the new team. This player could be a new
     * player (the default respawn type for that team) or it will be the original player if the team 
     * wasn't changed (false, original player returned). Pass force = true to make player change team 
     * no matter what and to respawn immediately.
     */
    function NS2Gamerules:JoinTeam(player, newTeamNumber, force)
    
        local success = false
        
        // Join new team
        if player and player:GetTeamNumber() ~= newTeamNumber or force then
        
            local team = self:GetTeam(newTeamNumber)
            local oldTeam = self:GetTeam(player:GetTeamNumber())
            
            // Remove the player from the old queue if they happen to be in one
            if oldTeam ~= nil then
                oldTeam:RemovePlayerFromRespawnQueue(player)
            end
            
            // Spawn immediately if going to ready room, game hasn't started, cheats on, or game started recently
            if newTeamNumber == kTeamReadyRoom or self:GetCanSpawnImmediately() or force then
            
                success, newPlayer = team:ReplaceRespawnPlayer(player, nil, nil)
                
                local teamTechPoint = team.GetInitialTechPoint and team:GetInitialTechPoint()
                if teamTechPoint then
                    newPlayer:OnInitialSpawn(teamTechPoint:GetOrigin())
                end
                
            else
            
                // Destroy the existing player and create a spectator in their place.
                newPlayer = player:Replace(team:GetSpectatorMapName(), newTeamNumber)
                
                // Queue up the spectator for respawn.
                team:PutPlayerInRespawnQueue(newPlayer)
                
                success = true
                
            end
            
            // Update frozen state of player based on the game state and player team.
            if team == self.team1 or team == self.team2 then
            
                local devMode = Shared.GetDevMode()
                local inCountdown = self:GetGameState() == kGameState.Countdown
                if not devMode and inCountdown then
                    newPlayer.frozen = true
                end
                
            else
            
                // Ready room or spectator players should never be frozen
                newPlayer.frozen = false
                
            end
            
            local client = Server.GetOwner(newPlayer)
            local clientUserId = client and client:GetUserId() or 0
            local disconnectedPlayerRes = self.disconnectedPlayerResources[clientUserId]
            if disconnectedPlayerRes then
            
                newPlayer:SetResources(disconnectedPlayerRes)
                self.disconnectedPlayerResources[clientUserId] = nil
                
            else
            
                // Give new players starting resources. Mark players as "having played" the game (so they don't get starting res if
                // they join a team again, etc.)
                local success, played = GetUserPlayedInGame(self, newPlayer)
                if success and not played and newTeamNumber == kAlienTeamType then
                    newPlayer:SetResources(kAlienTeamInitialRes)
                end
                
            end
            
            if self:GetGameStarted() then
                SetUserPlayedInGame(self, newPlayer)
            end
            
            newPlayer:TriggerEffects("join_team")

			return success, newPlayer
            
        end

        // Return old player
        return success, player
        
    end
    
    /* For test framework only. Prevents game from ending on its own also. */
    function NS2Gamerules:SetGameStarted()

        self:SetGameState(kGameState.Started)
        self.preventGameEnd = true
        
    end

    function NS2Gamerules:SetPreventGameEnd(state)
        self.preventGameEnd = state
    end

    function NS2Gamerules:CheckGameStart()

        if self:GetGameState() == kGameState.NotStarted or self:GetGameState() == kGameState.PreGame then
        
            // Start pre-game when both teams have players or when once side does if cheats are enabled
            local team1Players = self.team1:GetNumPlayers()
            local team2Players = self.team2:GetNumPlayers()
            
            if (team1Players > 0 and team2Players > 0) or (Shared.GetCheatsEnabled() and (team1Players > 0 or team2Players > 0)) then
            
                if self:GetGameState() == kGameState.NotStarted then
                    self:SetGameState(kGameState.PreGame)
                end
                
            elseif self:GetGameState() == kGameState.PreGame then
                self:SetGameState(kGameState.NotStarted)
            end
            
        end
        
    end
    
    function NS2Gamerules:CheckGameEnd()
    
        if self:GetGameStarted() and self.timeGameEnded == nil and not Shared.GetCheatsEnabled() and not self.preventGameEnd then
        
            if self.timeLastGameEndCheck == nil or (Shared.GetTime() > self.timeLastGameEndCheck + kGameEndCheckInterval) then
            
                local team1Lost = self.team1:GetHasTeamLost()
                local team2Lost = self.team2:GetHasTeamLost()
                local team1Won = self.team1:GetHasTeamWon()
                local team2Won = self.team2:GetHasTeamWon()
                
                local team1Players = self.team1:GetNumPlayers()
                local team2Players = self.team2:GetNumPlayers()
                local totalCount = team1Players + team2Players
                
                if (team1Lost and team2Lost) or (team1Won and team2Won) then
                    self:DrawGame()
                elseif team1Lost or team2Won then
                    self:EndGame(self.team2)
                elseif team2Lost or team1Won then
                    self:EndGame(self.team1)
                end
                
                self.timeLastGameEndCheck = Shared.GetTime()
                
            end
            
        end
        
    end
    
    function NS2Gamerules:GetCountingDown()
        return self:GetGameState() == kGameState.Countdown
    end
    
    local function StartCountdown(self)
    
        self:ResetGame()
        
        self:SetGameState(kGameState.Countdown)
        
        self.countdownTime = kCountDownLength
        
        self.lastCountdownPlayed = nil
        
    end
    
    function NS2Gamerules:GetPregameLength()
    
        local preGameTime = kPregameLength
        if Shared.GetCheatsEnabled() then
            preGameTime = 0
        end
        
        return preGameTime
        
    end
    
    function NS2Gamerules:UpdatePregame(timePassed)

        if self:GetGameState() == kGameState.PreGame then
        
            local preGameTime = self:GetPregameLength()
            
            if self.timeSinceGameStateChanged > preGameTime then
            
                StartCountdown(self)
                if Shared.GetCheatsEnabled() then
                    self.countdownTime = 1
                end
                
            end
            
        elseif self:GetGameState() == kGameState.Countdown then
        
            self.countdownTime = self.countdownTime - timePassed
            
            // Play count down sounds for last few seconds of count-down
            local countDownSeconds = math.ceil(self.countdownTime)
            if self.lastCountdownPlayed ~= countDownSeconds and (countDownSeconds < 4) then
            
                self.worldTeam:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
                self.team1:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
                self.team2:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
                self.spectatorTeam:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
                
                self.lastCountdownPlayed = countDownSeconds
                
            end
            
            if self.countdownTime <= 0 then
            
                self.team1:PlayPrivateTeamSound(ConditionalValue(self.team1:GetTeamType() == kAlienTeamType, NS2Gamerules.kAlienStartSound, NS2Gamerules.kMarineStartSound))
                self.team2:PlayPrivateTeamSound(ConditionalValue(self.team2:GetTeamType() == kAlienTeamType, NS2Gamerules.kAlienStartSound, NS2Gamerules.kMarineStartSound))
                
                self:SetGameState(kGameState.Started)
            end
            
        end
        
    end

    function NS2Gamerules:GetLosingTeam()
        return self.losingTeam
    end

    function NS2Gamerules:GetAllTech()
        return self.allTech
    end

    function NS2Gamerules:SetAllTech(state)

        if state ~= self.allTech then
        
            self.allTech = state
            
            self.team1:GetTechTree():SetTechChanged()
            self.team2:GetTechTree():SetTechChanged()
            
        end
        
    end

    function NS2Gamerules:GetAutobuild()
        return self.autobuild
    end

    function NS2Gamerules:SetAutobuild(state)
        self.autobuild = state
    end

    function NS2Gamerules:SetOrderSelf(state)
        self.orderSelf = state
    end

    function NS2Gamerules:GetOrderSelf()
        return self.orderSelf
    end

    function NS2Gamerules:GetIsPlayerFollowingTeamNumber(player, teamNumber)

        local following = false
        
        if player:isa("Spectator") then
        
            local playerId = player:GetFollowingPlayerId()
            
            if playerId ~= Entity.invalidId then
            
                local followedPlayer = Shared.GetEntity(playerId)
                
                if followedPlayer and followedPlayer:GetTeamNumber() == teamNumber then
                
                    following = true
                    
                end
                
            end

        end
        
        return following

    end

    // Function for allowing teams to hear each other's voice chat
    function NS2Gamerules:GetCanPlayerHearPlayer(listenerPlayer, speakerPlayer)

        local canHear = false
        
        // Check if the listerner has the speaker muted.
        if listenerPlayer:GetClientMuted(speakerPlayer:GetClientIndex()) then
            return false
        end
        
        // If both players have the same team number, they can hear each other
        if(listenerPlayer:GetTeamNumber() == speakerPlayer:GetTeamNumber()) then
            canHear = true
        end
            
        // Or if cheats or dev mode is on, they can hear each other
        if(Shared.GetCheatsEnabled() or Shared.GetDevMode()) then
            canHear = true
        end
        
        // If we're spectating a player, we can hear their team (but not in tournamentmode, once that's in)
        if self:GetIsPlayerFollowingTeamNumber(listenerPlayer, speakerPlayer:GetTeamNumber()) then
            canHear = true
        end
        
        return canHear
        
    end

    function NS2Gamerules:RespawnPlayer(player)

        local team = player:GetTeam()
        team:RespawnPlayer(player, nil, nil)
        
    end

    // Add SteamId of player to list of players that can't command again until next game
    function NS2Gamerules:BanPlayerFromCommand(playerId)
        ASSERT(type(playerId) == "number")
        table.insertunique(self.bannedPlayers, playerId)
    end

    function NS2Gamerules:GetPlayerBannedFromCommand(playerId)
        ASSERT(type(playerId) == "number")
        return (table.find(self.bannedPlayers, playerId) ~= nil)
    end

////////////////    
// End Server //
////////////////

end

function NS2Gamerules:GetGameStartTime()
    return ConditionalValue(self:GetGameStarted(), self.gameStartTime, 0)
end

function NS2Gamerules:GetGameStarted()
    return self.gameState == kGameState.Started
end

Shared.LinkClassToMap("NS2Gamerules", NS2Gamerules.kMapName, { })