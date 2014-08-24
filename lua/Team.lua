// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Team.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Tracks players on a team.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'Team'

function Team:Initialize(teamName, teamNumber)

    self.teamName = teamName
    self.teamNumber = teamNumber
    self.playerIds = table.array(16)
    self.respawnQueue = table.array(16)
    // This is a special queue to place players in if the
    // teams become unbalanced.
    self.respawnQueueTeamBalance = table.array(16)
    self.kills = 0
    
end

function Team:Uninitialize()
end

function Team:OnCreate()
end

function Team:OnInitialized()
end

function Team:OnEntityKilled(targetEntity, killer, doer, point, direction)

    local killerOnTeam = HasMixin(killer, "Team") and killer:GetTeamNumber() == self.teamNumber
    if killer and targetEntity and killerOnTeam and GetAreEnemies(killer, targetEntity) and killer:isa("Player") and targetEntity:isa("Player") then
        self:AddKills(1)
    end
    
end

/**
 * If a team doesn't support orders then any player changing to the team will have it's
 * orders cleared.
 */
function Team:GetSupportsOrders()
    return true
end

/**
 * Called only by Gamerules.
 */
function Team:AddPlayer(player)

    if player and player:isa("Player") then
    
        local id = player:GetId()
        return table.insertunique(self.playerIds, id)
        
    else
        Print("Team:AddPlayer(): Entity must be player (was %s)", SafeClassName(player))
    end
    
    return false
    
end

local function UpdateRespawnQueueTeamBalance(self)

    // Check if a player needs to be removed from the holding area.
    while #self.respawnQueueTeamBalance > (self.autoTeamBalanceAmount or 0) do
    
        local spawnPlayer = Shared.GetEntity(self.respawnQueueTeamBalance[1])
        table.remove(self.respawnQueueTeamBalance, 1)
        
        spawnPlayer:SetRespawnQueueEntryTime(Shared.GetTime())
        table.insertunique(self.respawnQueue, spawnPlayer:GetId())
        
        spawnPlayer:SetWaitingForTeamBalance(false)
        
        TEST_EVENT("Auto-team balance, out of queue")
        
    end
    
end

function Team:OnEntityChange(oldId, newId)

    // Replace any entities in the respawn queue
    if oldId and table.removevalue(self.respawnQueue, oldId) then
    
        // Keep queue entry time the same
        if newId then
            table.insertunique(self.respawnQueue, newId)
        end
        
    end
    
    if oldId and table.removevalue(self.respawnQueueTeamBalance, oldId) then
    
        if newId then
        
            table.insertunique(self.respawnQueue, newId)
            Shared.GetEntity(newId):SetWaitingForTeamBalance(true)
            
        end
        
    end
    
    UpdateRespawnQueueTeamBalance(self)
    
end

function Team:GetPlayer(playerIndex)

    if (playerIndex >= 1 and playerIndex <= table.count(self.playerIds)) then
        return Shared.GetEntity( self.playerIds[playerIndex] )
    end
    
    Print("Team:GetPlayer(%d): Invalid index specified (1 to %d)", playerIndex, table.count(self.playerIds))
    return nil
    
end

/**
 * Called only by Gamerules.
 */
function Team:RemovePlayer(player)

    assert(player)
    
    if not table.removevalue(self.playerIds, player:GetId()) then
        Print("Player %s with Id %d not in playerId list.", player:GetClassName(), player:GetId())
    end
    
    self:RemovePlayerFromRespawnQueue(player)
    
    player:SetTeamNumber(kTeamInvalid)
    
end

function Team:GetNumPlayers()

    local numPlayers = 0
    local numRookies = 0
    
	local function CountPlayers( player )
		numPlayers = numPlayers + 1
		if player:GetIsRookie() then
			numRookies = numRookies + 1
		end
	end
	self:ForEachPlayer( CountPlayers )
    
    return numPlayers, numRookies
    
end

function Team:GetNumPlayersInQueue()
    return #self.respawnQueue
end

function Team:GetNumDeadPlayers()

    local numPlayers = 0
    
	local function CountDeadPlayer( player )
		if not player:GetIsAlive() then
			 numPlayers = numPlayers + 1
		end
	end
	
	self:ForEachPlayer( CountDeadPlayer )
    
    return numPlayers    
end

function Team:GetPlayers()

	local playerList = {}
	local function CollectPlayers( player )
		table.insert(playerList, player)
	end
	self:ForEachPlayer( CollectPlayers )
	
    return playerList
	
end

function Team:GetTeamNumber()
    return self.teamNumber
end

// Called on game start or end. Reset everything but teamNumber and teamName.
function Team:Reset()

    self.kills = 0
    
    self:ClearRespawnQueue()
    
    // Clear players
    self.playerIds = { }
    
end

function Team:ResetPreservePlayers(techPoint)

    local playersOnTeam = {}
    table.copy(self.playerIds, playersOnTeam)
    
    if Shared.GetCheatsEnabled() and techPoint ~= nil then
        Print("Setting team %d team location: %s", self:GetTeamNumber(), techPoint:GetLocationName())
    end
    
    if techPoint then
        self.initialTechPointId = techPoint:GetId()
    end
    
    self:Reset()
    
    table.copy(playersOnTeam, self.playerIds)    
    
end

/** 
 * Play sound for every player on the team.
 */
function Team:PlayPrivateTeamSound(soundName, origin, commandersOnly, excludePlayer, ignoreDistance, triggeringPlayer)

    ignoreDistance = ignoreDistance or false
    
    local function PlayPrivateSound(player)
    
        if ( not commandersOnly or player:isa("Commander") ) and (not triggeringPlayer or not triggeringPlayer:isa("Player") or GetGamerules():GetCanPlayerHearPlayer(player, triggeringPlayer)) then
            if excludePlayer ~= player then
                // Play alerts for commander at commander origin, so they always hear them
                if not origin or player:isa("Commander") then
                    Server.PlayPrivateSound(player, soundName, player, 1.0, Vector(0, 0, 0), ignoreDistance)
                else
                    Server.PlayPrivateSound(player, soundName, nil, 1.0, origin, ignoreDistance)
                end
            end
        end
        
    end
    
    self:ForEachPlayer(PlayPrivateSound)
    
end

function Team:TriggerEffects(eventName)

    local function TriggerEffects(player)
        player:TriggerEffects(eventName)
    end
    
    self:ForEachPlayer(TriggerEffects)
end

function Team:SetFrozenState(state)

    local function SetFrozen(player)
        player.frozen = state
    end
    
    self:ForEachPlayer(SetFrozen)
    
end

function Team:SetAutoTeamBalanceEnabled(enabled, unbalanceAmount)

    self.autoTeamBalanceEnabled = enabled
    self.autoTeamBalanceAmount = enabled and unbalanceAmount or nil
    
    UpdateRespawnQueueTeamBalance(self)
    
end

/**
 * Queues a player to be spawned.
 */
function Team:PutPlayerInRespawnQueue(player, time)

    assert(player)
    
    // Place player in a "holding area" if auto-team balance is enabled.
    if self.autoTeamBalanceEnabled then
    
        // Place this new player into the holding area.
        table.insert(self.respawnQueueTeamBalance, player:GetId())
        
        player:SetWaitingForTeamBalance(true)
        
        UpdateRespawnQueueTeamBalance(self)
        
        TEST_EVENT("Auto-team balance, in queue")
        
    else
  
        player:SetRespawnQueueEntryTime(time or Shared.GetTime())
        table.insertunique(self.respawnQueue, player:GetId())
        
        if self.OnRespawnQueueChanged then
            self:OnRespawnQueueChanged()
        end
        
    end
    
end

function Team:GetPlayerPositionInRespawnQueue(player)

    local queueSize = #self.respawnQueue
    for i = 1, queueSize do
        
        if player:GetId() == self.respawnQueue[i] then
            return i
        end
        
    end
    
    return -1

end

/**
 * Removes the player from the team's spawn queue (if he's in it, otherwise has
 * no effect).
 */
function Team:RemovePlayerFromRespawnQueue(player)

    table.removevalue(self.respawnQueueTeamBalance, player:GetId())
    table.removevalue(self.respawnQueue, player:GetId())
    
    UpdateRespawnQueueTeamBalance(self)
    
    player:SetWaitingForTeamBalance(false)
    
end

function Team:ClearRespawnQueue()

    for p = 1, #self.respawnQueueTeamBalance do
    
        local player = Shared.GetEntity(self.respawnQueueTeamBalance[p])
        player:SetWaitingForTeamBalance(false)
        
    end
    
    table.clear(self.respawnQueueTeamBalance)
    table.clear(self.respawnQueue)
    
end

// Find player that's been dead and waiting the longest. Return nil if there are none.
function Team:GetOldestQueuedPlayer()

    local playerToSpawn = nil
    local earliestTime = -1
    
    for i = 1, #self.respawnQueue do
		
		local playerid = self.respawnQueue[i]
        local player = Shared.GetEntity(playerid)
        
        if player and player.GetRespawnQueueEntryTime then
        
            local currentPlayerTime = player:GetRespawnQueueEntryTime()
            
            if currentPlayerTime and (earliestTime == -1 or currentPlayerTime < earliestTime) then
            
                playerToSpawn = player
                earliestTime = currentPlayerTime
                
            end
            
        end
        
    end
    
    if playerToSpawn and ( not playerToSpawn.spawnBlockTime or playerToSpawn.spawnBlockTime <= Shared.GetTime() ) then    
        return playerToSpawn
    end
    
end

function Team:GetSortedRespawnQueue()

    local sortedQueue = {}
    
    for i = 1, #self.respawnQueue do
    
        local player = Shared.GetEntity(self.respawnQueue[i])
        if player then
            table.insertunique(sortedQueue, player)
        end
    
    end
    
    local function SortByEntryTime(player1, player2) 

        local time1 = player1.GetRespawnQueueEntryTime and player1:GetRespawnQueueEntryTime() or 0
        local time2 = player2.GetRespawnQueueEntryTime and player2:GetRespawnQueueEntryTime() or 0
        
        return time1 < time2
        
    end
    
    table.sort(sortedQueue, SortByEntryTime)
    
    return sortedQueue

end

function Team:GetKills()
    return self.kills
end

function Team:AddKills(num)
    self.kills = self.kills + num
end

// Structure was created. May or may not be built or active.
function Team:StructureCreated(entity)
end

// Entity that supports the tech tree was just added (it's built/active).
function Team:TechAdded(entity) 
end

// Entity that supports the tech tree was just removed (no longer built/active).
function Team:TechRemoved(entity)    
end

function Team:GetIsPlayerOnTeam(player)
    return table.find(self.playerIds, player:GetId())    
end

// For every player on team, call functor(player)
function Team:ForEachPlayer(functor)

    for _, playerId in ipairs(self.playerIds) do
		
        local player = Shared.GetEntity(playerId)
		--only players with a client are "real" player, this sorts out ragdolls etc.
		local client = player and Server.GetOwner(player)
        if client and player:isa("Player") then
            if functor(player) == false then
                break
            end
        else
            Print("Team:ForEachPlayer(): Couldn't find player for index %d", playerId)
        end
        
    end
    
end

function Team:GetHasActivePlayers()

    local hasActivePlayers = false
    local currentTeam = self

    local function HasActivePlayers(player)
        if player:GetIsAlive() then
            hasActivePlayers = true
            return false
        end
    end

    self:ForEachPlayer(HasActivePlayers)
    return hasActivePlayers

end

function Team:GetHasAbilityToRespawn()
    return true
end

function Team:Update(timePassed)
end

function Team:GetNumCommandStructures()

    local commandStructures = GetEntitiesForTeam("CommandStructure", self:GetTeamNumber())
    return table.maxn(commandStructures)
    
end

function Team:GetNumAliveCommandStructures()

    local commandStructures = GetEntitiesForTeam("CommandStructure", self:GetTeamNumber())
    
    local numAlive = 0
    for c = 1, #commandStructures do
        numAlive = commandStructures[c]:GetIsAlive() and (numAlive + 1) or numAlive
    end
    return numAlive
    
end

function Team:GetHasTeamLost()
    return false    
end

function Team:RespawnPlayer(player, origin, angles)

    assert(self:GetIsPlayerOnTeam(player), "Player isn't on team!")
    
    if origin == nil or angles == nil then
    
        // Randomly choose unobstructed spawn points to respawn the player
        local spawnPoint = nil
        local spawnPoints = Server.readyRoomSpawnList
        local numSpawnPoints = table.maxn(spawnPoints)
        
        if numSpawnPoints > 0 then
        
            local spawnPoint = GetRandomClearSpawnPoint(player, spawnPoints)
            if spawnPoint ~= nil then
            
                origin = spawnPoint:GetOrigin()
                angles = spawnPoint:GetAngles()
                
            end
            
        end
        
    end
    
    // Move origin up and drop it to floor to prevent stuck issues with floating errors or slightly misplaced spawns
    if origin then
    
        SpawnPlayerAtPoint(player, origin, angles)
        
        player:ClearEffects()
        
        return true
        
    else
        DebugPrint("Team:RespawnPlayer(player, %s, %s) - Must specify origin.", ToString(origin), ToString(angles))
    end
    
    return false
    
end

function Team:BroadcastMessage(message)

    local function SendMessage(player)
        Server.Broadcast(player, message)
    end
    
    self:ForEachPlayer(SendMessage)
    
end

function Team:GetSpectatorMapName()
    return Spectator.kMapName
end
