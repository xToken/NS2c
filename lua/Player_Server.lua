// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Player_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Gamerules.lua")

// Called when player first connects to server
// TODO: Move this into NS specific player class
function Player:OnClientConnect(client)

    self:SetRequestsScores(true)   
    self.clientIndex = client:GetId()
    self.client = client
    
end

function Player:GetClient()
    return self.client
end

function Player:Reset()

    ScriptActor.Reset(self)
    
    self.kills = 0
    self.deaths = 0
    
    self:SetScoreboardChanged(true)
    
    self:SetCameraDistance(0)
    
end

function Player:ClearEffects()
end

// ESC was hit on client or menu closed
function Player:CloseMenu()
end

function Player:GetName()
    return self.name
end

function Player:SetName(name)

    // If player is just changing the case on their own name, allow it.
    // Otherwise, make sure it's a unique name on the server.
    
    // Strip out surrounding "s
    local newName = string.gsub(name, "\"(.*)\"", "%1")
    
    // Make sure it's not too long
    newName = string.sub(newName, 0, kMaxNameLength)
    
    local currentName = self:GetName()
    if currentName ~= newName or string.lower(newName) ~= string.lower(currentName) then
        newName = GetUniqueNameForPlayer(newName)
    end
    
    if newName ~= self.name then
    
        self.name = newName
        
        self:SetScoreboardChanged(true)
        
    end
    
end

/**
 * Used to add the passed in client index to this player's mute list.
 * This player will either hear or not hear the passed in client's
 * voice chat based on the second parameter.
 */
function Player:SetClientMuted(muteClientIndex, setMuted)

    if not self.mutedClients then self.mutedClients = { } end
    self.mutedClients[muteClientIndex] = setMuted
    
end
AddFunctionContract(Player.SetClientMuted, { Arguments = { "Player", "number", "boolean" }, Returns = { } })

/**
 * Returns true if the passed in client is muted by this Player.
 */
function Player:GetClientMuted(checkClientIndex)

    if not self.mutedClients then self.mutedClients = { } end
    return self.mutedClients[checkClientIndex] == true
    
end
AddFunctionContract(Player.GetClientMuted, { Arguments = { "Player", "number" }, Returns = { "boolean" } })

// Changes the visual appearance of the player to the special edition version.
function Player:MakeSpecialEdition()
    self:SetModel(Player.kSpecialModelName, Marine.kMarineAnimationGraph)
end

// Not authoritative, only visual and information. TeamResources is stored in the team.
function Player:SetTeamResources(teamResources)
    self.teamResources = math.max(math.min(teamResources, kMaxResources), 0)
end

function Player:GetSendTechTreeBase()
    return self.sendTechTreeBase
end

function Player:ClearSendTechTreeBase()
    self.sendTechTreeBase = false
end

function Player:GetRequestsScores()
    return self.requestsScores
end

function Player:SetRequestsScores(state)
    self.requestsScores = state
end

// Call to give player default weapons, abilities, equipment, etc. Usually called after CreateEntity() and OnInitialized()
function Player:InitWeapons()
end

// Add resources for kills and play sound, returns how much resources have been awarded
function Player:AwardResForKill(amount)

    local resReward = self:AddResources(amount)
    
    if resReward > 0 then
        self:TriggerEffects("res_received")
    end
    
    return resReward
    
end

local function DestroyViewModel(self)

    assert(self.viewModelId ~= Entity.invalidId)
    
    DestroyEntity(self:GetViewModelEntity())
    self.viewModelId = Entity.invalidId
    
end

/**
 * Called when the player is killed. Point and direction specify the world
 * space location and direction of the damage that killed the player. These
 * may be nil if the damage wasn't directional.
 */
function Player:OnKill(killer, doer, point, direction)

    // Determine the killer's player name.
    local killerName = nil
    if killer ~= nil and not killer:isa("Player") then
    
        local realKiller = (killer.GetOwner and killer:GetOwner()) or nil
        if realKiller and realKiller:isa("Player") then
            killerName = realKiller:GetName()
        end
        
    end

    // Save death to server log
    if killer == self then        
        PrintToLog("%s committed suicide", self:GetName())
    elseif killerName ~= nil then
        PrintToLog("%s was killed by %s", self:GetName(), killerName)
    else
        PrintToLog("%s died", self:GetName())
    end

    // Go to third person so we can see ragdoll and avoid HUD effects (but keep short so it's personal)
    if not self:GetAnimateDeathCamera() then
        self:SetIsThirdPerson(4)
    end
    
    local angles = self:GetAngles()
    angles.roll = 0
    self:SetAngles(angles)
    
    // This is a hack, CameraHolderMixin should be doing this.
    self.baseYaw = 0
    
    self:AddDeaths()
    
    // Fade out screen
    self.timeOfDeath = Shared.GetTime()
    
    DestroyViewModel(self)
    
    // Set next think to 0 to disable
    self:SetNextThink(0)
        
end

function Player:SetControllingPlayer(client)

    if client ~= nil then
    
        client:SetControllingPlayer(self)
        self:UpdateClientRelevancyMask()
        
    end
    
end

function Player:UpdateClientRelevancyMask()

    local mask = 0xFFFFFFFF
    
    if self:GetTeamNumber() == 1 then
    
        if self:GetIsCommander() then
            mask = kRelevantToTeam1Commander
        else
            mask = kRelevantToTeam1Unit
        end
        
    elseif self:GetTeamNumber() == 2 then
    
        if self:GetIsCommander() then
            mask = kRelevantToTeam2Commander
        else
            mask = kRelevantToTeam2Unit
        end
        
    // Spectators should see all map blips.
    elseif self:GetTeamNumber() == kSpectatorIndex then
    
        if self:GetIsOverhead() then
            mask = bit.bor(kRelevantToTeam1Commander, kRelevantToTeam2Commander)
        else
            mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
        end
        
    // ReadyRoomPlayers should not see any blips.
    elseif self:GetTeamNumber() == kTeamReadyRoom then
        mask = kRelevantToReadyRoom
    end
    
    local client = Server.GetOwner(self)
    // client may be nil if the server is shutting down.
    if client then
        client:SetRelevancyMask(mask)
    end
    
end

function Player:OnTeamChange()

    self:UpdateIncludeRelevancyMask()
    self:SetScoreboardChanged(true)
    
end

function Player:UpdateIncludeRelevancyMask()

    // Players are always relevant to their commanders.
    local includeMask = 0
    
    if self:GetTeamNumber() == 1 then
        includeMask = kRelevantToTeam1Commander
    elseif self:GetTeamNumber() == 2 then
        includeMask = kRelevantToTeam2Commander
    end
    
    self:SetIncludeRelevancyMask(includeMask)
    
end

function Player:SetResources(amount)

    local oldVisibleResources = math.floor(self.resources)
    
    self.resources = Clamp(amount, 0, kMaxPersonalResources)
    
    local newVisibleResources = math.floor(self.resources)
    
    if oldVisibleResources ~= newVisibleResources then
        self:SetScoreboardChanged(true)
    end
    
end

function Player:GetDeathMapName()
    return Spectator.kMapName
end

local function UpdateChangeToSpectator(self)

    if not self:GetIsAlive() and not self:isa("Spectator") then
    
        local time = Shared.GetTime()
        if self.timeOfDeath ~= nil and (time - self.timeOfDeath > kFadeToBlackTime) then
        
            // Destroy the existing player and create a spectator in their place (but only if it has an owner, ie not a body left behind by Phantom use)
            local owner  = Server.GetOwner(self)
            if owner then
            
                // Queue up the spectator for respawn.
                local spectator = self:Replace(self:GetDeathMapName())
                spectator:GetTeam():PutPlayerInRespawnQueue(spectator, Shared.GetTime())
                
            end
            
        end
        
    end
    
end

function Player:OnUpdatePlayer(deltaTime)

    UpdateChangeToSpectator(self)
    
    local gamerules = GetGamerules()
    self.gameStarted = gamerules:GetGameStarted()
    // TODO: Change this after making NS2Player
    if self:GetTeamNumber() == kTeam1Index or self:GetTeamNumber() == kTeam2Index then
        self.countingDown = gamerules:GetCountingDown()
    else
        self.countingDown = false
    end
    self.teamLastThink = self:GetTeam()
    
end

// Remember game time player enters queue so they can be spawned in FIFO order
function Player:SetRespawnQueueEntryTime(time)
    self.respawnQueueEntryTime = time
end

function Player:ReplaceRespawn()
    return self:GetTeam():ReplaceRespawnPlayer(self, nil, nil)
end

function Player:GetRespawnQueueEntryTime()

    return self.respawnQueueEntryTime
    
end

// For children classes to override if they need to adjust data
// before the copy happens.
function Player:PreCopyPlayerData()

end

function Player:CopyPlayerDataFrom(player)

    // This is stuff from the former LiveScriptActor.
    self.gameEffectsFlags = player.gameEffectsFlags
    self.timeOfLastDamage = player.timeOfLastDamage
    
    // ScriptActor and Actor fields
    self:SetAngles(player:GetAngles())
    self:SetOrigin(Vector(player:GetOrigin()))
    self:SetViewAngles(player:GetViewAngles())
    
    // Copy camera settings
    if player:GetIsThirdPerson() then
        self.cameraDistance = player.cameraDistance
    end
    
    // for OnProcessMove
    self.fullPrecisionOrigin = player.fullPrecisionOrigin
    
    // This is a hack, CameraHolderMixin should be doing this.
    self.baseYaw = player.baseYaw
    
    // MoveMixin fields.
    self:SetGravityEnabled(player:GetGravityEnabled())
    
    self.name = player.name
    self.clientIndex = player.clientIndex
    self.client = player.client
    
    // Preserve hotkeys when logging in/out of command structures
    if player:GetTeamType() == kMarineTeamType or player:GetTeamType() == kAlienTeamType then
        table.copy(player.hotkeyGroups, self.hotkeyGroups)
    end
    
    // Copy network data over because it won't be necessarily be resent
    self.resources = player.resources
    self.teamResources = player.teamResources
    self.gameStarted = player.gameStarted
    self.countingDown = player.countingDown
    self.frozen = player.frozen
    
    // Don't copy alive, health, maxhealth, armor, maxArmor - they are set in Spawn()
    
    self.showScoreboard = player.showScoreboard
    self.score = player.score or 0
    self.kills = player.kills
    self.deaths = player.deaths
    
    self.timeOfDeath = player.timeOfDeath
    self.timeOfLastUse = player.timeOfLastUse
    self.crouching = player.crouching
    self.timeOfCrouchChange = player.timeOfCrouchChange   
    self.timeOfLastPoseUpdate = player.timeOfLastPoseUpdate

    self.timeLastBuyMenu = player.timeLastBuyMenu
    
    // Include here so it propagates through Spectator
    self.originOnDeath = player.originOnDeath
    
    self.jumpHandled = player.jumpHandled
    self.timeOfLastJump = player.timeOfLastJump
    self.darwinMode = player.darwinMode
    
    self.mode = player.mode
    self.modeTime = player.modeTime
    
    self.requestsScores = player.requestsScores
    self.isRookie = player.isRookie
    self.communicationStatus = player.communicationStatus
    
    // Don't lose purchased upgrades when becoming commander
    
    if self:GetTeamNumber() == kAlienTeamType or self:GetTeamNumber() == kMarineTeamType then
    
        self.upgrade1 = player.upgrade1
        self.upgrade2 = player.upgrade2
        self.upgrade3 = player.upgrade3
        self.upgrade4 = player.upgrade4
        self.upgrade5 = player.upgrade5
        self.upgrade6 = player.upgrade6
        
        self.forbidden1 = player.forbidden1
        self.forbidden2 = player.forbidden2
        self.forbidden3 = player.forbidden3
        self.forbidden4 = player.forbidden4
        self.forbidden5 = player.forbidden5
        self.forbidden6 = player.forbidden6
    
    end
    
    // Remember this player's muted clients.
    self.mutedClients = player.mutedClients
    
end

/**
 * Replaces the existing player with a new player of the specified map name.
 * Removes old player off its team and adds new player to newTeamNumber parameter
 * if specified. Note this destroys self, so it should be called carefully. Returns 
 * the new player. If preserveWeapons is true, then InitWeapons() isn't called
 * and old ones are kept (including view model).
 */
function Player:Replace(mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues)

    local team = self:GetTeam()
    if team == nil then
        return self
    end
    
    local teamNumber = team:GetTeamNumber()
    local owner = Server.GetOwner(self)
    local teamChanged = newTeamNumber ~= nil and newTeamNumber ~= self:GetTeamNumber()
    
    // Add new player to new team if specified
    // Both nil and -1 are possible invalid team numbers.
    if newTeamNumber ~= nil and newTeamNumber ~= -1 then
        teamNumber = newTeamNumber
    end
    
    local player = CreateEntity(mapName, atOrigin or Vector(self:GetOrigin()), teamNumber, extraValues)
    
    // Save last player map name so we can show player of appropriate form in the ready room if the game ends while spectating
    player.previousMapName = self:GetMapName()
    
    // The class may need to adjust values before copying to the new player (such as gravity).
    self:PreCopyPlayerData()
    
    // If the atOrigin is specified, set self to that origin before
    // the copy happens or else it will be overridden inside player.
    if atOrigin then
        self:SetOrigin(atOrigin)
    end
    // Copy over the relevant fields to the new player, before we delete it
    player:CopyPlayerDataFrom(self)
    
    // Make model look where the player is looking
    player.standingBodyYaw = self:GetAngles().yaw
    
    if not player:GetTeam():GetSupportsOrders() and HasMixin(player, "Orders") then
        player:ClearOrders()
    end
    
    // Remove newly spawned weapons and reparent originals
    if preserveWeapons then
    
        player:DestroyWeapons()
        
        local allWeapons = { }
        local function AllWeapons(weapon) table.insert(allWeapons, weapon) end
        ForEachChildOfType(self, "Weapon", AllWeapons)
        
        for i, weapon in ipairs(allWeapons) do
            player:AddWeapon(weapon)
        end
        
    end
    
    // Notify others of the change     
    self:SendEntityChanged(player:GetId())
    
    // Update scoreboard because of new entity and potentially new team
    player:SetScoreboardChanged(true)
    
    // This player is no longer controlled by a client.
    self.client = nil
    
    // Only destroy the old player if it is not a ragdoll.
    // Ragdolls will eventually destroy themselve.
    if not HasMixin(self, "Ragdoll") or not self:GetIsRagdoll() then
        DestroyEntity(self)
    end
    
    player:SetControllingPlayer(owner)
    
    // Must happen after the owner has been set on the player.
    player:InitializeBadges()
    
    // Set up special armor marines if player owns special edition 
    if owner and Server.GetIsDlcAuthorized(owner, kSpecialEditionProductId) then
        player:MakeSpecialEdition()
    end
    
    // Log player spawning
    if teamNumber ~= 0 then
        PostGameViz(string.format("%s spawned", SafeClassName(self)), self)
    end
    
    return player
    
end

function Player:GetIsAllowedToBuy()
    return self:GetIsAlive()
end

/**
 * A table of tech Ids is passed in.
 */
function Player:ProcessBuyAction(techIds)

    ASSERT(type(techIds) == "table")
    ASSERT(table.count(techIds) > 0)
    
    local techTree = self:GetTechTree()
    local buyAllowed = true
    local totalCost = 0
    local validBuyIds = { }
    
    for i, techId in ipairs(techIds) do
    
        local techNode = techTree:GetTechNode(techId)
        if(techNode ~= nil and techNode.available) and not self:GetHasUpgrade(techId) then
        
            local cost = GetCostForTech(techId)
            if cost ~= nil then
                totalCost = totalCost + cost
                table.insert(validBuyIds, techId)
            end
        
        else
        
            buyAllowed = false
            break
        
        end
        
    end
    
    if totalCost <= self:GetResources() then
    
        if self:AttemptToBuy(validBuyIds) then
            self:AddResources(-totalCost)
            return true
        end
        
    else
        Print("not enough resources sound server")
        Server.PlayPrivateSound(self, self:GetNotEnoughResourcesSound(), self, 1.0, Vector(0, 0, 0))        
    end

    return false
    
end

// Creates an item by mapname and spawns it at our feet.
function Player:GiveItem(itemMapName, setActive)

    // Players must be alive in order to give them items.
    assert(self:GetIsAlive())
    
    local newItem = nil
    if setActive == nil then
        setActive = true
    end

    if itemMapName then
    
        newItem = CreateEntity(itemMapName, self:GetEyePos(), self:GetTeamNumber())
        if newItem then

            if newItem:isa("Weapon") then
                self:AddWeapon(newItem, setActive)
            else

                if newItem.OnCollision then
                    newItem:OnCollision(self)
                end
                
            end
            
        else
            Print("Couldn't create entity named %s.", itemMapName)            
        end
        
    end
    
    return newItem
    
end

function Player:GetKills()
    return self.kills
end

function Player:GetDeaths()
    return self.deaths
end

function Player:AddDeaths()

    self.deaths = Clamp(self.deaths + 1, 0, kMaxDeaths)
    self:SetScoreboardChanged(true)
    
end

function Player:GetPing()

    local client = Server.GetOwner(self)
    
    if client ~= nil then
        return client:GetPing()
    else
        return 0
    end
    
end

// To be overridden by children
function Player:AttemptToBuy(techIds)
    return false
end

function Player:UpdateMisc(input)

    // Check if the player wants to go to the ready room.
    if bit.band(input.commands, Move.ReadyRoom) ~= 0 and not self:isa("ReadyRoomPlayer") then
        self:SetCameraDistance(0)
        GetGamerules():JoinTeam(self, kTeamReadyRoom)
    end
    
    if self:GetTeamType() == kMarineTeamType then
    
        self.weaponUpgradeLevel = 0
            
        if GetHasTech(self, kTechId.Weapons3, true) then    
            self.weaponUpgradeLevel = 3
        elseif GetHasTech(self, kTechId.Weapons2, true) then    
            self.weaponUpgradeLevel = 2
        elseif GetHasTech(self, kTechId.Weapons1, true) then    
            self.weaponUpgradeLevel = 1
        end
        
    end
    
end

function Player:GetTechTree()

    local techTree = nil
    
    local team = self:GetTeam()
    if team ~= nil and team:isa("PlayingTeam") then
        techTree = team:GetTechTree()
    end
    
    return techTree

end

function Player:GetPreviousMapName()
    return self.previousMapName
end

function Player:SetDarwinMode(darwinMode)
    self.darwinMode = darwinMode
end

function Player:UpdateArmorAmount()

    // note: some player may have maxArmor == 0
    local armorPercent = self.maxArmor > 0 and self.armor/self.maxArmor or 0
    self.maxArmor = self:GetArmorAmount()
    self:SetArmor(self.maxArmor * armorPercent)
    
end

function Player:GetIsInterestedInAlert(techId)
    return LookupTechData(techId, kTechDataAlertTeam, false)
end

// Send alert to player unless we recently sent the exact same alert. Returns true if it was sent.
function Player:TriggerAlert(techId, entity)

    assert(entity ~= nil)
    
    if self:GetIsInterestedInAlert(techId) then
    
        local entityId = entity:GetId()
        local time = Shared.GetTime()
        
        local location = entity:GetOrigin()
        assert(entity:GetTechId() ~= nil)
        
        local message =
        {
            techId = techId,
            worldX = location.x,
            worldZ = location.z,
            entityId = entity:GetId(),
            entityTechId = entity:GetTechId()
        }
        
        Server.SendNetworkMessage(self, "MinimapAlert", message, true)

        return true
    
    end
    
    return false
    
end

function Player:SetRookieMode(rookieMode)

     if self.isRookie ~= rookieMode then
    
        self.isRookie = rookieMode
        
        // rookie status sent along with scores
        self:SetScoreboardChanged(true)
        
    end
    
end