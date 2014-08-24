// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NetworkMessages_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// See the Messages section of the Networking docs in Spark Engine scripting docs for details.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Added hiveinfo message, made adjustments to hitEffect

Script.Load("lua/InsightNetworkMessages_Client.lua")

function OnCommandPing(pingTable)

    local playerId, ping = ParsePingMessage(pingTable)    
    Scoreboard_SetPing(playerId, ping)
    
end

function OnCommandHitEffect(hitEffectTable)

    local position, doer, surface, target, showtracer, altMode, flinchsevere, damage, direction = ParseHitEffectMessage(hitEffectTable)
    HandleHitEffect(position, doer, surface, target, showtracer, altMode, flinchsevere, damage, direction)

end

// Show damage numbers for players.
function OnCommandDamage(damageTable)

    local target, amount, hitpos = ParseDamageMessage(damageTable)
    if target then
        Client.AddWorldMessage(kWorldTextMessageType.Damage, amount, hitpos, target:GetId())
    end
    
end

function OnCommandHitSound(hitSoundTable)

    local sound = ParseHitSoundMessage(hitSoundTable)
    HitSounds_PlayHitsound( sound )
    
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
    Client.AddWorldMessage(kWorldTextMessageType.CommanderError, messageStr, message.position)
    
end

function OnCommandJoinError(message)
    ChatUI_AddSystemMessage( Locale.ResolveString("JOIN_ERROR_TOO_MANY") )
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

    local text = string.format(kNS2cLocalizedStrings.VOTE_CHAMBER_BROADCAST, message.voterName, EnumToString(kTechId, message.voteId), message.votesMoreNeeded)
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
    local text = string.format(kNS2cLocalizedStrings.VOTE_CHAMBER_SELECTED, EnumToString(kTechId, message.voteId))
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
Client.HookNetworkMessage("HitSound", OnCommandHitSound)
Client.HookNetworkMessage("JoinError", OnCommandJoinError)

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
