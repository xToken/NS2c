-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\NetworkMessages_Client.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- See the Messages section of the Networking docs in Spark Engine scripting docs for details.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Added hiveinfo message, made adjustments to hitEffect

Script.Load("lua/InsightNetworkMessages_Client.lua")

function OnCommandPing(pingTable)

    local playerId, ping = ParsePingMessage(pingTable)    
    Scoreboard_SetPing(playerId, ping)
    
end

function OnCommandHitEffect(hitEffectTable)

    local position, doer, surface, target, showtracer, altMode, flinchsevere, damage, direction = ParseHitEffectMessage(hitEffectTable)
    HandleHitEffect(position, doer, surface, target, showtracer, altMode, flinchsevere, damage, direction)

end

-- Show damage numbers for players.
function OnCommandDamage(damageTable)

    local targetId, amount, hitpos = ParseDamageMessage(damageTable)

    Client.AddWorldMessage(kWorldTextMessageType.Damage, amount, hitpos, targetId)
    
end

function OnCommandMarkEnemy(msg)

    local target, weapon = ParseMarkEnemyMessage(msg)
    local player = Client.GetLocalPlayer()
    if not player:GetIsCommander() and player.MarkEnemyFromServer then
        player:MarkEnemyFromServer( target, weapon )
    end
    
end

function OnCommandHitSound(hitSoundTable)

    local sound = ParseHitSoundMessage(hitSoundTable)
    HitSounds_PlayHitsound( sound )
    
end

function OnCommandAbilityResult(msg)

    -- The server will send us this message to tell us an ability succeded.
    local player = Client.GetLocalPlayer()
    if player:GetIsCommander() then
        player:OnAbilityResultMessage(msg.techId, msg.success, msg.castTime)
    end

end

function OnCommandScores(scoreTable)

    local status = kPlayerStatus[scoreTable.status]
    if scoreTable.status == kPlayerStatus.Hidden then
        status = "-"
    elseif scoreTable.status == kPlayerStatus.Dead then
        status = Locale.ResolveString("STATUS_DEAD")
    elseif scoreTable.status == kPlayerStatus.Evolving then
        status = Locale.ResolveString("STATUS_EVOLVING")
    elseif scoreTable.status == kPlayerStatus.Embryo then
        status = Locale.ResolveString("STATUS_EMBRYO")
    elseif scoreTable.status == kPlayerStatus.Commander then
        status = Locale.ResolveString("STATUS_COMMANDER")
    elseif scoreTable.status == kPlayerStatus.Exo then
        status = Locale.ResolveString("STATUS_EXO")
    elseif scoreTable.status == kPlayerStatus.GrenadeLauncher then
        status = Locale.ResolveString("STATUS_GRENADE_LAUNCHER")
    elseif scoreTable.status == kPlayerStatus.Rifle then
        status = Locale.ResolveString("STATUS_RIFLE")
    elseif scoreTable.status == kPlayerStatus.HeavyMachineGun then
        status = Locale.ResolveString("STATUS_HMG")
    elseif scoreTable.status == kPlayerStatus.Shotgun then
        status = Locale.ResolveString("STATUS_SHOTGUN")
    elseif scoreTable.status == kPlayerStatus.Flamethrower then
        status = Locale.ResolveString("STATUS_FLAMETHROWER")
    elseif scoreTable.status == kPlayerStatus.Void then
        status = Locale.ResolveString("STATUS_VOID")
    elseif scoreTable.status == kPlayerStatus.Spectator then
        status = Locale.ResolveString("STATUS_SPECTATOR")
    elseif scoreTable.status == kPlayerStatus.Skulk then
        status = Locale.ResolveString("STATUS_SKULK")
    elseif scoreTable.status == kPlayerStatus.Gorge then
        status = Locale.ResolveString("STATUS_GORGE")
    elseif scoreTable.status == kPlayerStatus.Lerk then
        status = Locale.ResolveString("STATUS_LERK")
    elseif scoreTable.status == kPlayerStatus.Fade then
        status = Locale.ResolveString("STATUS_FADE")
    elseif scoreTable.status == kPlayerStatus.Onos then
        status = Locale.ResolveString("STATUS_ONOS")
    elseif scoreTable.status == kPlayerStatus.SkulkEgg then
        status = Locale.ResolveString("SKULK_EGG")
    elseif scoreTable.status == kPlayerStatus.GorgeEgg then
        status = Locale.ResolveString("GORGE_EGG")
    elseif scoreTable.status == kPlayerStatus.LerkEgg then
        status = Locale.ResolveString("LERK_EGG")
    elseif scoreTable.status == kPlayerStatus.FadeEgg then
        status = Locale.ResolveString("FADE_EGG")
    elseif scoreTable.status == kPlayerStatus.OnosEgg then
        status = Locale.ResolveString("ONOS_EGG")
    end
    
    Scoreboard_SetPlayerData(scoreTable.clientId, scoreTable.entityId, scoreTable.playerName, scoreTable.teamNumber, scoreTable.score,
                             scoreTable.kills, scoreTable.deaths, math.floor(scoreTable.resources), scoreTable.isCommander, scoreTable.isRookie,
                             status, scoreTable.isSpectator, scoreTable.assists, scoreTable.clientIndex)
    
end

function OnCommandClearTechTree()
    ClearTechTree()
end

function OnCommandTechNodeBase(techNodeBaseTable)
    GetTechTree():CreateTechNodeFromNetwork(techNodeBaseTable)
end

function OnCommandTechNodeUpdate(techNodeUpdateTable)
    GetTechTree():UpdateTechNodeFromNetwork(techNodeUpdateTable)
end

function OnCommandOnResetGame()

    Scoreboard_OnResetGame()
    ResetLights()

    if GetGameInfoEntity() then
        GetGameInfoEntity():OnResetGame()
    end
end

function OnCommandDebugLine(debugLineMessage)
    DebugLine(ParseDebugLineMessage(debugLineMessage))
end

function OnCommandDebugCapsule(debugCapsuleMessage)
    DebugCapsule(ParseDebugCapsuleMessage(debugCapsuleMessage))
end

function OnCommandMinimapAlert(message)

    local player = Client.GetLocalPlayer()
    if player then
        player:AddAlert(message.techId, message.worldX, message.worldZ, message.entityId, message.entityTechId)
    end
    
end

function OnCommandCommanderNotification(message)

    local player = Client.GetLocalPlayer()
    if player:isa("Marine") then
        player:AddNotification(message.locationId, message.techId)
    end
    
end

kWorldTextResolveStrings = { }
kWorldTextResolveStrings[kWorldTextMessageType.Resources] = "RESOURCES_ADDED"
kWorldTextResolveStrings[kWorldTextMessageType.Resource] = "RESOURCE_ADDED"
kWorldTextResolveStrings[kWorldTextMessageType.Damage] = "DAMAGE_TAKEN"
function OnCommandWorldText(message)

    local messageStr = string.format(Locale.ResolveString(kWorldTextResolveStrings[message.messageType]), message.data)
    Client.AddWorldMessage(message.messageType, messageStr, message.position)
    
end

function OnCommandCommanderError(message)

    local messageStr = Locale.ResolveString(message.data)
	local method = LookupTechData(message.techId, kTechDataBuildMethodFailedLookup, nil)
    if method then
        messageStr = string.format(messageStr, method())
    end
    Client.AddWorldMessage(kWorldTextMessageType.CommanderError, messageStr, message.position)
    
end

function OnCommandJoinError(message)
    if message.reason == 0 then
        ChatUI_AddSystemMessage( Locale.ResolveString("JOIN_ERROR_TOO_MANY") )
    elseif message.reason == 1 then
        ChatUI_AddSystemMessage( Locale.ResolveString("JOIN_ERROR_ROOKIE") )

        MainMenu_Open()
        GetGUIMainMenu():CreateTutorialNagWindow()
    elseif message.reason == 2 then
        ChatUI_AddSystemMessage( Locale.ResolveString("JOIN_ERROR_VETERAN") )

        MainMenu_Open()
        GetGUIMainMenu():CreateRookieOnlyNagWindow()
    elseif message.reason == 3 then
        ChatUI_AddSystemMessage( Locale.ResolveString("JOIN_ERROR_NO_PLAYER_SLOT_LEFT") )
    end
end

function OnCommanderLoginError(message)
    ChatUI_AddSystemMessage( Locale.ResolveString("LOGIN_ERROR_ROOKIE") )
end

function OnVoteConcedeCast(message)

    local text = string.format(Locale.ResolveString("VOTE_CONCEDE_BROADCAST"), message.voterName, message.votesMoreNeeded)
    ChatUI_AddSystemMessage(text)
    
end

function OnVoteEjectCast(message)

    local text = string.format(Locale.ResolveString("VOTE_EJECT_BROADCAST"), message.voterName, message.votesMoreNeeded)
    ChatUI_AddSystemMessage(text)
    
end

function OnVoteChamberCast(message)

    local text = string.format(Locale.ResolveString("VOTE_CHAMBER_BROADCAST"), message.voterName, EnumToString(kTechId, message.voteId), message.votesMoreNeeded)
    ChatUI_AddSystemMessage(text)
    
end

function OnTeamConceded(message)

    if message.teamNumber == kMarineTeamType then
        ChatUI_AddSystemMessage(Locale.ResolveString("TEAM_MARINES_CONCEDED"))
    else
        ChatUI_AddSystemMessage(Locale.ResolveString("TEAM_ALIENS_CONCEDED"))
    end
    
end

function OnChamberSelected(message)
    local text = string.format(Locale.ResolveString("VOTE_CHAMBER_SELECTED"), EnumToString(kTechId, message.voteId))
    ChatUI_AddSystemMessage(text)
end

local function OnCommandCreateDecal(message)
    
    local normal, position, materialName, scale = ParseCreateDecalMessage(message)
    
    local coords = Coords.GetTranslation(position)
    coords.yAxis = normal
    
    local randomAxis = Vector(math.random() * 2 - 0.9, math.random() * 2 - 1.1, math.random() * 2 - 1)
    randomAxis:Normalize()
    
    coords.zAxis = randomAxis
    coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
    coords.zAxis = coords.xAxis:CrossProduct(coords.yAxis)
    
    coords.xAxis:Normalize()
    coords.yAxis:Normalize()
    
    Shared.CreateTimeLimitedDecal(materialName, coords, scale)

end
Client.HookNetworkMessage("CreateDecal", OnCommandCreateDecal)

local function OnSetClientIndex(message)
    Client.localClientIndex = message.clientIndex
end
Client.HookNetworkMessage("SetClientIndex", OnSetClientIndex)

local function OnSetServerHidden(message)
    Client.serverHidden = message.hidden
end
Client.HookNetworkMessage("ServerHidden", OnSetServerHidden)

local function OnSetClientTeamNumber(message)
    Client.localClientTeamNumber = message.teamNumber
end
Client.HookNetworkMessage("SetClientTeamNumber", OnSetClientTeamNumber)

local function OnScoreUpdate(message)
    ScoreDisplayUI_SetNewScore(message.points, message.res, message.wasKill)
end
Client.HookNetworkMessage("ScoreUpdate", OnScoreUpdate)

local function OnMessageAutoConcedeWarning(message)

    local warningText = StringReformat(Locale.ResolveString("AUTO_CONCEDE_WARNING"), { time = message.time, teamName = message.team1Conceding and "Marines" or "Aliens" })
    ChatUI_AddSystemMessage(warningText)
    
end

local function OnCommandCameraShake(message)

    local intensity = ParseCameraShakeMessage(message)
    
    local player = Client.GetLocalPlayer()
    if player and player.SetCameraShake then
        player:SetCameraShake(intensity * 0.1, 5, 0.25)    
    end

end

local function OnSetAchievement(message)
    if message and message.name then
        Client.SetAchievement(message.name)
    end
end

local function OnCommandViewPunch(message)

    if message.punchangle then
        Client.SetYaw(Client.GetYaw() + message.punchangle.x)
        Client.SetPitch(Client.GetPitch() + message.punchangle.z)
    end
    
end

Client.HookNetworkMessage("AutoConcedeWarning", OnMessageAutoConcedeWarning)

Client.HookNetworkMessage("Ping", OnCommandPing)
Client.HookNetworkMessage("HitEffect", OnCommandHitEffect)
Client.HookNetworkMessage("Damage", OnCommandDamage)
Client.HookNetworkMessage("MarkEnemy", OnCommandMarkEnemy)
Client.HookNetworkMessage("HitSound", OnCommandHitSound)
Client.HookNetworkMessage("AbilityResult", OnCommandAbilityResult)
Client.HookNetworkMessage("JoinError", OnCommandJoinError)
Client.HookNetworkMessage("CommanderLoginError", OnCommanderLoginError)

Client.HookNetworkMessage("ClearTechTree", OnCommandClearTechTree)
Client.HookNetworkMessage("TechNodeBase", OnCommandTechNodeBase)
Client.HookNetworkMessage("TechNodeUpdate", OnCommandTechNodeUpdate)

Client.HookNetworkMessage("MinimapAlert", OnCommandMinimapAlert)
Client.HookNetworkMessage("CommanderNotification", OnCommandCommanderNotification)

Client.HookNetworkMessage("ResetGame", OnCommandOnResetGame)

Client.HookNetworkMessage("DebugLine", OnCommandDebugLine)
Client.HookNetworkMessage("DebugCapsule", OnCommandDebugCapsule)

Client.HookNetworkMessage("WorldText", OnCommandWorldText)
Client.HookNetworkMessage("CommanderError", OnCommandCommanderError)

Client.HookNetworkMessage("VoteConcedeCast", OnVoteConcedeCast)
Client.HookNetworkMessage("VoteChamberCast", OnVoteChamberCast)
Client.HookNetworkMessage("VoteEjectCast", OnVoteEjectCast)
Client.HookNetworkMessage("TeamConceded", OnTeamConceded)
Client.HookNetworkMessage("ChamberSelected", OnChamberSelected)
Client.HookNetworkMessage("CameraShake", OnCommandCameraShake)
Client.HookNetworkMessage("ViewPunch", OnCommandViewPunch)
Client.HookNetworkMessage("SetAchievement", OnSetAchievement)
