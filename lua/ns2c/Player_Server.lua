-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Player_Server.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Removed destruction of free dropped weapons, removed near death cinematic

Script.Load("lua/Gamerules.lua")

-- Called when player first connects to server
-- TODO: Move this into NS specific player class
function Player:OnClientConnect(client)
    self:SetRequestsScores(true)   
end

function Player:GetSteamId()
    return self.client and self.client:GetUserId() or -1
end

function Player:GetClient()
    return self.client
end

function Player:GetIsSpectator()
    return self.client and self.client:GetIsSpectator()
end

function Player:SetIsSpectator(isSpec)
    if type(isSpec) ~= "boolean" then return end --sanity check of input

    if self:GetIsVirtual() then return end --ignore bots

    assert(self.client ~= nil)

    if not self.client:SetIsSpectator(isSpec) then return end

    --Move spectating player to the spectator team
    if not isSpec then return end

    local gamerules = GetGamerules()
    if gamerules and self:GetTeamNumber() ~= kSpectatorIndex then
        gamerules:JoinTeam(self, kSpectatorIndex, true)
    end
end

function Player:GetIsVirtual()
    return self.isVirtual
end

function Player:GetControllingBot()
    if not self.isVirtual or not self.client then return end

    for _, bot in ipairs(gServerBots) do
        if bot.client == self.client then
            return bot
        end
    end
end

-- Return the current alert queue of the player. Alerts are only queued for virtual players
function Player:GetAlertQueue()
    return self.alertQueue or {}
end

--Clears the current alert queue of the player. Alerts are only queued for virtual players
function Player:SetAlertQueue(alertQueue)
    self.alertQueue = alertQueue
end

function Player:SetPlayerInfo(playerInfo)

    if playerInfo ~= nil then
        self.playerInfo = playerInfo
        self.playerInfo:SetScorePlayer(self)
    end

end

function Player:GetPlayerInfo()
    return self.playerInfo
end

function Player:Reset()

    ScriptActor.Reset(self)
    
    self:SetCameraDistance(0)
    self:ResetLevel()
    
end

function Player:ClearEffects()
end

-- ESC was hit on client or menu closed
function Player:CloseMenu()
end

function Player:GetName()
    return self.name ~= "" and self.name or kDefaultPlayerName
end

function Player:GetNameHasBeenSet()
    return self.name ~= ""
end

function Player:SetName(name)

    -- If player is just changing the case on their own name, allow it.
    -- Otherwise, make sure it's a unique name on the server.
    
    -- Strip out surrounding "s
    local newName = string.gsub(name, "\"(.*)\"", "%1")
    -- Strip out escape characters.
    newName = string.gsub(newName, "[\a\b\f\n\r\t\v]", "")
    
    -- Make sure it's not too long
    newName = string.UTF8Sub(newName, 0, kMaxNameLength)
    
    local currentName = self:GetName()
    if currentName ~= newName or string.lower(newName) ~= string.lower(currentName) then
        newName = GetUniqueNameForPlayer(newName)
    end
    
    if newName ~= self.name then
    
        self.name = newName

    end
    
end

--[[
 * Used to add the passed in client index to this player's mute list.
 * This player will either hear or not hear the passed in client's
 * voice chat based on the second parameter.
]]
function Player:SetClientMuted(muteClientIndex, setMuted)

    if not self.mutedClients then self.mutedClients = { } end
    self.mutedClients[muteClientIndex] = setMuted
    
end

--[[
 * Returns true if the passed in client is muted by this Player.
]]
function Player:GetClientMuted(checkClientIndex)

    if not self.mutedClients then self.mutedClients = { } end
    return self.mutedClients[checkClientIndex] == true
    
end

-- Not authoritative, only visual and information. TeamResources is stored in the team.
function Player:SetTeamResources(teamResources)
    self.teamResources = math.max(math.min(teamResources, kMaxTeamResources), 0)
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

-- Call to give player default weapons, abilities, equipment, etc. Usually called after CreateEntity() and OnInitialized()
function Player:InitWeapons()
end

function Player:InitWeaponsForReadyRoom()
end

-- Add resources for kills and play sound, returns how much resources have been awarded
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

--[[
 * Called when the player is killed. Point and direction specify the world
 * space location and direction of the damage that killed the player. These
 * may be nil if the damage wasn't directional.
]]
function Player:OnKill(killer, doer, point, direction)

    local isSuicide = not doer and not killer -- xenocide is not a suicide
    local killedByDeathTrigger = doer and doer:isa("DeathTrigger") or killer and killer:isa("DeathTrigger")

    -- Determine the killer's player name.
    local killerName
    if killer then
        -- search for a player being/owning the killer
        local realKiller = killer
        while realKiller and not realKiller:isa("Player") and realKiller.GetOwner do
            realKiller = realKiller:GetOwner()
        end
        if realKiller and realKiller:isa("Player") then
            self.killedBy = killer:GetId()
            killerName = realKiller:GetName()
            Log("%s: killed by %s", self, self.killedBy)
        end
    end

    -- Save death to server log unless it's part of the concede sequence
    if not GetConcedeSequenceActive() then
        if isSuicide or killedByDeathTrigger then
            PrintToLog("%s committed suicide", self:GetName())
        elseif killerName ~= nil then
            PrintToLog("%s was killed by %s", self:GetName(), killerName)
        else
            PrintToLog("%s died", self:GetName())
        end
    end

    -- Go to third person so we can see ragdoll and avoid HUD effects (but keep short so it's personal)
    if not self:GetAnimateDeathCamera() then
        self:SetIsThirdPerson(4)
    end
    
    local angles = self:GetAngles()
    angles.roll = 0
    self:SetAngles(angles)
    
    -- This is a hack, CameraHolderMixin should be doing this.
    self.baseYaw = 0
    
    self:AddDeaths()
    
    -- Fade out screen.
    self.timeOfDeath = Shared.GetTime()
    
    DestroyViewModel(self)
    
    -- Save position of last death only if we didn't die to a DeathTrigger
    if not killedByDeathTrigger then
        self.lastDeathPos = self:GetOrigin()
    end
    
    self.lastClass = self:GetMapName()
    
end

function Player:SetControllerClient(client)

    if client ~= nil then
    
        client:SetControllingPlayer(self)
        self.clientIndex = client:GetId()
        self.client = client
        self.isVirtual = client:GetIsVirtual()

        self:UpdateClientRelevancyMask()
        self:OnClientUpdated(client)
        
    end
    
end

function Player:UpdateClientRelevancyMask()

    local mask = 0xFFFFFFFF
    
    if GetConcedeSequenceActive() then
        
        mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit)
        
    elseif self:GetTeamNumber() == 1 then
    
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
        
    -- Spectators should see all map blips.
    elseif self:GetTeamNumber() == kSpectatorIndex then
    
        if self:GetIsOverhead() then
            mask = bit.bor(kRelevantToTeam1Commander, kRelevantToTeam2Commander)
        else
            mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
        end
        
    -- ReadyRoomPlayers should not see any blips.
    elseif self:GetTeamNumber() == kTeamReadyRoom then
        mask = kRelevantToReadyRoom
    end
    
    local client = Server.GetOwner(self)
    -- client may be nil if the server is shutting down.
    if client then
        client:SetRelevancyMask(mask)
    end
    
end

function Player:OnTeamChange()

    self:UpdateIncludeRelevancyMask()

end

function Player:UpdateIncludeRelevancyMask()

    -- Players are always relevant to their commanders.
    local includeMask = 0
    
    if self:GetTeamNumber() == 1 then
        includeMask = kRelevantToTeam1Commander
    elseif self:GetTeamNumber() == 2 then
        includeMask = kRelevantToTeam2Commander
    end
    
    self:SetIncludeRelevancyMask(includeMask)
    
end

function Player:SetResources(amount)
    self.resources = Clamp(amount, 0, kMaxPersonalResources)
end

function Player:AddResources(amount)

    local resReward = 0

    if Shared.GetCheatsEnabled() or ( amount <= 0 or not self.blockPersonalResources ) then

        resReward = math.min(amount, kMaxPersonalResources - self:GetResources())
        self:SetResources(self:GetResources() + resReward)
    
    end
    
    return resReward
    
end

function Player:GetDeathMapName()
    return Spectator.kMapName
end

local function UpdateChangeToSpectator(self)

    if not self:GetIsAlive() and not self:isa("Spectator") then
    
        local time = Shared.GetTime()
        if self.timeOfDeath ~= nil and (time - self.timeOfDeath > kFadeToBlackTime) and (not GetConcedeSequenceActive()) then

            -- Destroy the existing player and create a spectator in their place (but only if it has an owner, ie not a body left behind by Phantom use)
            local owner = Server.GetOwner(self)
            if owner then

                -- Ready room players respawn instantly. Might need an API.
                if self:GetTeamNumber() == kTeamReadyRoom then
                    self:GetTeam():ReplaceRespawnPlayer(self, nil, nil);
                else
                    local spectator = self:Replace(self:GetDeathMapName())
                    spectator:GetTeam():PutPlayerInRespawnQueue(spectator)

                    -- Queue up the spectator for respawn.
                    local killer = self.killedBy and Shared.GetEntity(self.killedBy) or nil
                    if killer then
                        spectator:SetupKillCam(self, killer)
                    end
                end

            end

        end

    end

end

function Player:OnUpdatePlayer(deltaTime)

    UpdateChangeToSpectator(self)
    
    -- Modify relevancy for this entity if the concede sequence is active.
    ConcedeSequence.ModifyRelevancy(self)
    
end

-- Remember game time player enters queue so they can be spawned in FIFO order
function Player:SetRespawnQueueEntryTime(time)
    self.respawnQueueEntryTime = time
end

function Player:GetRespawnQueueEntryTime()
    return self.respawnQueueEntryTime
end

function Player:CheckMinExperience()
    local myExp = self:GetPlayerExperience()
    local teamExp = 0
    local team = self:GetTeam()
    if team then
        local players = team:GetPlayers()
        for index, player in ipairs(players) do
            teamExp = teamExp + player:GetPlayerExperience()
        end
        //Add up total team XP, divide by num of players, then factor by scalar
        teamExp = math.floor((teamExp / #players) * kCombatExperienceTeamAssistScalar)
        if teamExp > myExp and (teamExp - myExp) > kCombatExperienceMinIncreaseAllowed then
            self:AddExperience(teamExp - myExp)
        end
    end
end

function Player:OnRestoreUpgrades()
    //Request upgrades back from tree.
    local gameInfo = GetGameInfoEntity()
    if gameInfo and gameInfo:GetGameMode() == kGameMode.Combat then
        RetrieveCombatPlayersUpgradeTable(self)
        self:UpdateArmorAmount()
        self:CheckMinExperience()
        self:ActivateSpawnProtection()
    end
    return self
end

function Player:OnGiveUpgrade(upgradeId)
    StoreCombatPlayersUpgradeTable(self)
end

-- For children classes to override if they need to adjust data
-- before the copy happens.
function Player:PreCopyPlayerData()

end

function Player:CopyPlayerDataFrom(player)
    
    self.lastDeathPos = player.lastDeathPos
    self.lastWeaponList = player.lastWeaponList
    self.lastClass = player.lastClass
    self.lastExoLayout = player.lastExoLayout

    -- This is stuff from the former LiveScriptActor.
    self.gameEffectsFlags = player.gameEffectsFlags
    self.timeOfLastDamage = player.timeOfLastDamage
    
    -- ScriptActor and Actor fields
    self:SetAngles(player:GetAngles())
    self:SetOrigin(Vector(player:GetOrigin()))
    self:SetViewAngles(player:GetViewAngles())
    
    -- Copy camera settings
    if player:GetIsThirdPerson() then
        self.cameraDistance = player.cameraDistance
    end
    
    -- for OnProcessMove
    self.fullPrecisionOrigin = player.fullPrecisionOrigin
    
    -- This is a hack, CameraHolderMixin should be doing this.
    self.baseYaw = player.baseYaw
    
    self.name = player.name
    self.clientIndex = player.clientIndex
    self.client = player.client
    self.isVirtual = player.isVirtual

    -- Copy network data over because it won't be necessarily be resent
    self.resources = player.resources
    self.teamResources = player.teamResources
    self.frozen = player.frozen
    self.level = player.level
    self.movementmode = player.movementmode
    
    self.timeOfDeath = player.timeOfDeath
    self.timeOfLastUse = player.timeOfLastUse
    self.crouching = player.crouching
    self.timeOfCrouchChange = player.timeOfCrouchChange   
    self.timeOfLastPoseUpdate = player.timeOfLastPoseUpdate

    self.timeLastBuyMenu = player.timeLastBuyMenu
    
    -- Include here so it propagates through Spectator
    self.originOnDeath = player.originOnDeath
    
    self.jumpHandled = player.jumpHandled
    self.timeOfLastJump = player.timeOfLastJump
    self.darwinMode = player.darwinMode
    
    self.requestsScores = player.requestsScores
    self.isRookie = player.isRookie
    self.communicationStatus = player.communicationStatus
    
    -- Don't lose purchased upgrades when becoming commander
    if self:GetTeamNumber() == kAlienTeamType or self:GetTeamNumber() == kMarineTeamType then
        self:CopyUpgradesFromOldPlayer(player)
    end
    
    -- Remember this player's muted clients.
    self.mutedClients = player.mutedClients
    self.hotGroupNumber = player.hotGroupNumber
    
    self.lastUpgradeList = player.lastUpgradeList or {}
    
    self.sendTechTreeBase = player.sendTechTreeBase
    
end

--[[
 * Check if there were any spectators watching them. Make these
 * spectators follow the new player unless the new player is also
 * a spectator (in which case, make the spectating players follow a new target).
]]
function Player:RemoveSpectators(newPlayer)

    local spectators = Shared.GetEntitiesWithClassname("Spectator")
    for e = 0, spectators:GetSize() - 1 do
    
        local spectatorEntity = spectators:GetEntityAtIndex(e)
        if spectatorEntity and spectatorEntity ~= newPlayer then
        
            local spectatorClient = Server.GetOwner(spectatorEntity)
            if spectatorClient and spectatorClient:GetSpectatingPlayer() == self then
            
                local allowedToFollowNewPlayer = newPlayer and not newPlayer:isa("Spectator") and not newPlayer:isa("Commander") and newPlayer:GetIsOnPlayingTeam()
                if not allowedToFollowNewPlayer then
                
                    local success = spectatorEntity:CycleSpectatingPlayer(self, true)
                    if not success and not self:GetIsOnPlayingTeam() then
                        spectatorEntity:SetSpectatorMode(kSpectatorMode.FreeLook)
                    end
                    
                else
                    spectatorClient:SetSpectatingPlayer(newPlayer)
                end
                
            end
            
        end
        
    end
    
end


function Player:GetDestructionAllowed(destructionAllowedTable)
    destructionAllowedTable.allowed = (self.client == nil) and destructionAllowedTable.allowed
end


--[[
 * Replaces the existing player with a new player of the specified map name.
 * Removes old player off its team and adds new player to newTeamNumber parameter
 * if specified. Note this destroys self, so it should be called carefully. Returns 
 * the new player. If preserveWeapons is true, then InitWeapons() isn't called
 * and old ones are kept (including view model).
]]
function Player:Replace(mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues)
    
    local team = self:GetTeam()
    if team == nil then
        return self
    end
    
    local teamNumber = team:GetTeamNumber()
    local client = Server.GetOwner(self)
    local teamChanged = newTeamNumber ~= nil and newTeamNumber ~= self:GetTeamNumber()
    
    -- Add new player to new team if specified
    -- Both nil and -1 are possible invalid team numbers.
    if newTeamNumber ~= nil and newTeamNumber ~= -1 then
        teamNumber = newTeamNumber
    end
    
    local player = CreateEntity(mapName, atOrigin or Vector(self:GetOrigin()), teamNumber, extraValues)
    
    -- Save last player map name so we can show player of appropriate form in the ready room if the game ends while spectating
    player.previousMapName = self:GetMapName()
    
    -- The class may need to adjust values before copying to the new player (such as gravity).
    self:PreCopyPlayerData()
    
    -- If the atOrigin is specified, set self to that origin before
    -- the copy happens or else it will be overridden inside player.
    if atOrigin then
        self:SetOrigin(atOrigin)
    end
    -- Copy over the relevant fields to the new player, before we delete it
    player:CopyPlayerDataFrom(self)
    
    -- Make model look where the player is looking
    player.standingBodyYaw = Math.Wrap( self:GetAngles().yaw, 0, 2*math.pi )
    
    if not player:GetTeam():GetSupportsOrders() and HasMixin(player, "Orders") then
        player:ClearOrders()
    end
    
    -- Remove newly spawned weapons and reparent originals
    if preserveWeapons then
    
        player:DestroyWeapons()
        
        local allWeapons = { }
        local function AllWeapons(weapon) table.insert(allWeapons, weapon) end
        ForEachChildOfType(self, "Weapon", AllWeapons)
        
        for i, weapon in ipairs(allWeapons) do
            player:AddWeapon(weapon)
        end
        
    end
    
    -- Notify others of the change     
    self:SendEntityChanged(player:GetId())
    
    -- Notify LOS mixin of this player's change (to prevent aliens scouted by this player to get
    -- stuck scouted).
    if HasMixin(self, "LOS") then
        self:MarkNearbyDirtyImmediately()
    end

    -- This player is no longer controlled by a client.
    self.client = nil
    self.isVirtual = nil

    -- Remove any spectators currently spectating this player.
    self:RemoveSpectators(player)
    
    player:SetPlayerInfo(self.playerInfo)
    self.playerInfo = nil
    
    -- Only destroy the old player if it is not a ragdoll.
    -- Ragdolls will eventually destroy themselve.
    if not HasMixin(self, "Ragdoll") or not self:GetIsRagdoll() then
        DestroyEntity(self)
    end
    
    player:SetControllerClient(client)
    
    -- There are some cases where the spectating player isn't set to nil.
    -- Handle any edge cases here (like being dead when the game is reset).
    -- In some cases, client will be nil (when the map is changing for example).
    if client and not player:isa("Spectator") then
        client:SetSpectatingPlayer(nil)
    end
    
    -- Log player spawning
    if teamNumber ~= 0 then
        PostGameViz(string.format("%s spawned", SafeClassName(self)), self)
    end
    
    return player
    
end

function Player:GetIsAllowedToBuy()
    return self:GetIsAlive()
end

--[[
 * A table of tech Ids is passed in.
]]
function Player:ProcessBuyAction(techIds)
end

-- Creates an item by mapname and spawns it at our feet.
function Player:GiveItem(itemMapName, setActive, suppressError)

    -- Players must be alive in order to give them items.
    assert(self:GetIsAlive())
    
    local newItem
    if setActive == nil then
        setActive = true
    end

    if itemMapName then
    
        newItem = CreateEntity(itemMapName, self:GetEyePos(), self:GetTeamNumber(), nil, suppressError)
        if newItem then

            if newItem:isa("Weapon") then
                local removedWeapon = self:AddWeapon(newItem, setActive)
                
                if removedWeapon and HasMixin(removedWeapon, "Tech") and LookupTechData(removedWeapon:GetTechId(), kTechDataCostKey, 0) == 0 then
                    DestroyEntity(removedWeapon)
                end
                
            else

                if newItem.OnCollision then
                    newItem:OnCollision(self)
                end
                
            end
            
            local client = self:GetClient()
            if client and newItem.UpdateWeaponSkins then
                newItem:UpdateWeaponSkins(client)
            end
            
        else
            Log("Couldn't create entity named %s.", itemMapName)
            return nil
        end
        
    end
    
    return newItem
    
end

function Player:GetPing()

    local client = Server.GetOwner(self)
    
    if client ~= nil then
        return client:GetPing()
    else
        return 0
    end
    
end

-- To be overridden by children
function Player:AttemptToBuy(techIds)
    return false
end

function Player:UpdateMisc(input)    
end

function Player:GetTechTree()
    Print("Shouldn't be calling this anymore...")
    Print(debug.traceback())
    return GetTechTree(self:GetTeamNumber())
end

function Player:GetPreviousMapName()
    return self.previousMapName
end

function Player:SetDarwinMode(darwinMode)
    self.darwinMode = darwinMode
end

function Player:GetIsInterestedInAlert(techId)
    return LookupTechData(techId, kTechDataAlertTeam, false)
end

-- Send alert to player unless we recently sent the exact same alert. Returns true if it was sent.
function Player:TriggerAlert(techId, entity)

    assert(entity ~= nil)

    if self:GetIsInterestedInAlert(techId) and (not entity:isa("Player") or GetGamerules():GetCanPlayerHearPlayer(self, entity)) then

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

        if self:GetIsVirtual() then
            self.alertQueue = self.alertQueue or {}
            message.time = time
            table.insert(self.alertQueue, message)
        else
            Server.SendNetworkMessage(self, "MinimapAlert", message, true)
        end

        return true
    
    end
    
    return false
    
end

function Player:SetRookie(isRookie)

    if self.isRookie ~= isRookie then
        self.isRookie = isRookie
        if self.playerInfo then self.playerInfo:UpdateScore() end
    end

end

function Player:GetIsRookie()
    return self.isRookie
end

function Player:OnClientUpdated(client)
    -- override me
end

--only use intensity value here to reduce traffic
function Player:SetCameraShake(intensity)

    local message = BuildCameraShakeMessage(intensity)
    Server.SendNetworkMessage(self, "CameraShake", message, false)

end

function Player:UpdateWeaponSkin(client)
    
    local weps = self:GetWeapons()
    for i=1, #weps do
        if weps[i] and weps[i].UpdateWeaponSkins then
            weps[i]:UpdateWeaponSkins(client)
        end
    end
    
    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon then
        activeWeapon:UpdateViewModel(self)
    end
    
end

