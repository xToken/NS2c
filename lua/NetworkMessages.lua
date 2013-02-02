// ======= Copyright (c) 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NetworkMessages.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// See the Messages section of the Networking docs in Spark Engine scripting docs for details.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Globals.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/VoiceOver.lua")
Script.Load("lua/InsightNetworkMessages.lua")
Script.Load("lua/SharedDecal.lua")

local kSelectUnitMessage =
{
    teamNumber = "integer (0 to 4)",
    unitId = "entityid",
    selected = "boolean",
    keepSelection = "boolean"

}

local kCreateDecalMessage =
{
    normal = string.format("integer(1 to %d)", kNumIndexedVectors),
    posx = string.format("float (%d to %d by 0.05)", -kHitEffectMaxPosition, kHitEffectMaxPosition),
    posy = string.format("float (%d to %d by 0.05)", -kHitEffectMaxPosition, kHitEffectMaxPosition),
    posz = string.format("float (%d to %d by 0.05)", -kHitEffectMaxPosition, kHitEffectMaxPosition), 
    decalIndex = string.format("integer (1 to %d)", kNumSharedDecals),
    scale = "float (0 to 5 by 0.05)"
}

Shared.RegisterNetworkMessage("CreateDecal", kCreateDecalMessage)

function BuildCreateDecalMessage(normal, position, decalIndex, scale)   
 
    local t = { }
    t.normal = normal
    t.posx = position.x
    t.posy = position.y
    t.posz = position.z
    t.decalIndex = decalIndex
    t.scale = scale
    return t
    
end

function ParseCreateDecalMessage(message)
    return GetVectorFromIndex(message.normal), Vector(message.posx, message.posy, message.posz), GetDecalMaterialNameFromIndex(message.decalIndex), message.scale
end

function BuildSelectUnitMessage(teamNumber, unit, selected, keepSelection)

    assert(teamNumber)

    local t =  {}
    t.teamNumber = teamNumber
    t.unitId = unit and unit:GetId() or Entity.invalidId
    t.selected = selected == true
    t.keepSelection = keepSelection == true    
    return t

end

function ParseSelectUnitMessage(message)
    return message.teamNumber, Shared.GetEntity(message.unitId), message.selected, message.keepSelection
end

function BuildConnectMessage(armorId)

    local t = {}
    t.armorId = armorId
    return t
    
end

function ParseConnectMessage(message)
    return message.armorId
end

local kConnectMessage =
{
    armorId = "enum kArmorType",
}
Shared.RegisterNetworkMessage( "ConnectMessage", kConnectMessage )

function BuildVoiceMessage(voiceId)

    local t = {}
    t.voiceId = voiceId
    return t
    
end

function ParseVoiceMessage(message)
    return message.voiceId
end

local kVoiceOverMessage =
{
    voiceId = "enum kVoiceId",
}

Shared.RegisterNetworkMessage( "VoiceMessage", kVoiceOverMessage )

local kHitEffectMessage =
{
    // TODO: figure out a reasonable precision for the position
    posx = string.format("float (%d to %d by 0.05)", -kHitEffectMaxPosition, kHitEffectMaxPosition),
    posy = string.format("float (%d to %d by 0.05)", -kHitEffectMaxPosition, kHitEffectMaxPosition),
    posz = string.format("float (%d to %d by 0.05)", -kHitEffectMaxPosition, kHitEffectMaxPosition),
    doerId = "entityid",
    surface = "enum kHitEffectSurface",
    targetId = "entityid",
    showtracer = "boolean",
    altMode = "boolean",
    flinch_severe = "boolean",
	damage = "integer (0 to 5000)",
    direction = string.format("integer(1 to %d)", kNumIndexedVectors)
}

function BuildHitEffectMessage(position, doer, surface, target, showtracer, altMode, flinch_severe, damage, direction)

    local t = { }
    t.posx = position.x
    t.posy = position.y
    t.posz = position.z
    t.doerId = (doer and doer:GetId()) or Entity.invalidId
    t.surface = (surface and StringToEnum(kHitEffectSurface, surface)) or kHitEffectSurface.metal
    t.targetId = (target and target:GetId()) or Entity.invalidId
    t.showtracer = showtracer == true
    t.altMode = altMode == true
    t.damage = damage
    t.direction = direction or 1
    t.flinch_severe = flinch_severe == true
    return t
    
end

function ParseHitEffectMessage(message)

    local position = Vector(message.posx, message.posy, message.posz)
    local doer = Shared.GetEntity(message.doerId)
    local surface = EnumToString(kHitEffectSurface, message.surface)
    local target = Shared.GetEntity(message.targetId)
    local showtracer = message.showtracer
    local altMode = message.altMode
    local flinch_severe = message.flinch_severe
    local damage = message.damage
    local direction = GetVectorFromIndex(message.direction)

    return position, doer, surface, target, showtracer, altMode, flinch_severe, damage, direction

end

Shared.RegisterNetworkMessage( "HitEffect", kHitEffectMessage )

/*
For damage numbers
*/
local kDamageMessage =
{
    posx = string.format("float (%d to %d by 0.05)", -kHitEffectMaxPosition, kHitEffectMaxPosition),
    posy = string.format("float (%d to %d by 0.05)", -kHitEffectMaxPosition, kHitEffectMaxPosition),
    posz = string.format("float (%d to %d by 0.05)", -kHitEffectMaxPosition, kHitEffectMaxPosition),
    targetId = "entityid",
    amount = "float",
}

function BuildDamageMessage(target, amount, hitpos)
    
    local t = {}
    t.posx = hitpos.x
    t.posy = hitpos.y
    t.posz = hitpos.z
    t.amount = amount
    t.targetId = (target and target:GetId()) or Entity.invalidId
    return t
    
end

function ParseDamageMessage(message)
    local position = Vector(message.posx, message.posy, message.posz)
    return Shared.GetEntity(message.targetId), message.amount, position
end

Shared.RegisterNetworkMessage( "Damage", kDamageMessage )

// Tell players WHY they can't join a team
local kJoinErrorMessage =
{
    // Don't really need anything here
}
function BuildJoinErrorMessage()
    return {}
end
Shared.RegisterNetworkMessage( "JoinError", kJoinErrorMessage )

/*
*/

local kCommanderPingMessage =
{
    position = "vector"
}

function BuildCommanderPingMessage(position)

    local t = {}    
    t.position = position    
    return t

end

Shared.RegisterNetworkMessage( "CommanderPing", kCommanderPingMessage )

// From TechNode.kTechNodeVars
local kTechNodeUpdateMessage = 
{
    techId                  = "enum kTechId",
    available               = "boolean",
    researchProgress        = "float",
    prereqResearchProgress  = "float",
    researched              = "boolean",
    researching             = "boolean",
    hasTech                 = "boolean"
}

// Tech node messages. Base message is in TechNode.lua
function BuildTechNodeUpdateMessage(techNode)

    local t = {}
    
    t.techId                    = techNode.techId
    t.available                 = techNode.available
    t.researchProgress          = techNode.researchProgress
    t.prereqResearchProgress    = techNode.prereqResearchProgress
    t.researched                = techNode.researched
    t.researching               = techNode.researching
    t.hasTech                   = techNode.hasTech
    
    return t
    
end

Shared.RegisterNetworkMessage( "TechNodeUpdate", kTechNodeUpdateMessage )

local kMaxPing = 999

local kPingMessage = 
{
    clientIndex = "integer",
    ping = "integer (0 to " .. kMaxPing .. ")"
}

function BuildPingMessage(clientIndex, ping)

    local t = {}
    
    t.clientIndex       = clientIndex
    t.ping              = math.min(ping, kMaxPing)
    
    return t
    
end

function ParsePingMessage(message)
    return message.clientIndex, message.ping
end

Shared.RegisterNetworkMessage( "Ping", kPingMessage )

kWorldTextMessageType = enum({ 'Resources', 'Resource', 'Damage' })
local kWorldTextMessage =
{
    messageType = "enum kWorldTextMessageType",
    data = "float",
    position = "vector"
}

function BuildWorldTextMessage(messageType, data, position)

    local t = { }
    
    t.messageType = messageType
    t.data = data
    t.position = position
    
    return t
    
end

Shared.RegisterNetworkMessage("WorldText", kWorldTextMessage)

local kCommanderErrorMessage =
{
    data = "string (48)",
    position = "vector"
}

function BuildCommanderErrorMessage(data, position)

    local t = { }

    t.data = data
    t.position = position
    
    return t
    
end

Shared.RegisterNetworkMessage("CommanderError", kCommanderErrorMessage)

// Scores 
local kScoresMessage = 
{
    clientId = "integer",
    entityId = "entityid",
    playerName = string.format("string (%d)", kMaxNameLength),
    teamNumber = string.format("integer (-1 to %d)", kRandomTeamType),
    score = string.format("integer (0 to %d)", kMaxScore),
    kills = string.format("integer (0 to %d)", kMaxKills),
    deaths = string.format("integer (0 to %d)", kMaxDeaths),
    resources = string.format("integer (0 to %d)", kMaxResources),
    isCommander = "boolean",
    isRookie = "boolean",
    status = "enum kPlayerStatus",
    isSpectator = "boolean"
}

function BuildScoresMessage(scorePlayer, sendToPlayer)

    local isEnemy = scorePlayer:GetTeamNumber() == GetEnemyTeamNumber(sendToPlayer:GetTeamNumber())
    
    local t = {}

    t.clientId = scorePlayer:GetClientIndex()
    t.entityId = scorePlayer:GetId()
    t.playerName = string.sub(scorePlayer:GetName(), 0, kMaxNameLength)
    t.teamNumber = scorePlayer:GetTeamNumber()
    t.score = 0
    if HasMixin(scorePlayer, "Scoring") then
        t.score = scorePlayer:GetScore()
    end
    t.kills = scorePlayer:GetKills()
    t.deaths = scorePlayer:GetDeaths()
    t.resources = ConditionalValue(isEnemy, 0, math.floor(scorePlayer:GetResources()))
    t.isCommander = ConditionalValue(isEnemy, false, scorePlayer:isa("Commander"))
    t.isRookie = ConditionalValue(isEnemy, false, scorePlayer:GetIsRookie())
    t.status = ConditionalValue(isEnemy, kPlayerStatus.Hidden, scorePlayer:GetPlayerStatusDesc())
    t.isSpectator = ConditionalValue(isEnemy, false, scorePlayer:isa("Spectator"))
    
    return t
    
end

Shared.RegisterNetworkMessage("Scores", kScoresMessage)

// For idle workers
local kSelectAndGotoMessage = 
{
    entityId = "entityid"
}

function BuildSelectAndGotoMessage(entId)
    local t = {}
    t.entityId = entId
    return t   
end

function ParseSelectAndGotoMessage(message)
    return message.entityId
end

Shared.RegisterNetworkMessage("SelectAndGoto", kSelectAndGotoMessage)

// For taking damage
local kTakeDamageIndicator =
{
    worldX = "float",
    worldZ = "float",
    damage = "float"
}

function BuildTakeDamageIndicatorMessage(sourceVec, damage)
    local t = {}
    t.worldX = sourceVec.x
    t.worldZ = sourceVec.z
    t.damage = damage
    return t
end

function ParseTakeDamageIndicatorMessage(message)
    return message.worldX, message.worldZ, message.damage
end

Shared.RegisterNetworkMessage("TakeDamageIndicator", kTakeDamageIndicator)

// Player id changed 
local kEntityChangedMessage = 
{
    oldEntityId = "entityid",
    newEntityId = "entityid",
}

function BuildEntityChangedMessage(oldId, newId)

    local t = {}
    
    t.oldEntityId = oldId
    t.newEntityId = newId
    
    return t
    
end

// Selection
local kMarqueeSelectMessage =
{
    pickStartVec = "vector",
    pickEndVec = "vector",
}

function BuildMarqueeSelectCommand(pickStartVec, pickEndVec)

    local t = {}
    
    t.pickStartVec = Vector(pickStartVec)
    t.pickEndVec = Vector(pickEndVec)

    return t
    
end

function ParseCommMarqueeSelectMessage(message)
    return message.pickStartVec, message.pickEndVec
end

local kClickSelectMessage =
{
    pickVec = "vector"
}

function BuildClickSelectCommand(pickVec)

    local t = {}
    t.pickVec = Vector(pickVec)
    return t
    
end

function ParseCommClickSelectMessage(message)
    return message.pickVec
end

local kCreateHotkeyGroupMessage =
{
    groupNumber = "integer (1 to " .. ToString(kMaxHotkeyGroups) .. ")"
}
function BuildCreateHotkeyGroupMessage(setGroupNumber)

    local t = {}
    
    t.groupNumber = setGroupNumber
    
    return t

end

local kSelectHotkeyGroupMessage =
{
    groupNumber = "integer (1 to " .. ToString(kMaxHotkeyGroups) .. ")"
}

function BuildSelectHotkeyGroupMessage(setGroupNumber)

    local t = {}
    
    t.groupNumber = setGroupNumber
    
    return t

end

function ParseSelectHotkeyGroupMessage(message)
    return message.groupNumber
end

// Commander actions
local kCommAction = 
{
    techId              = "enum kTechId"
}

function BuildCommActionMessage(techId)

    local t = {}
    
    t.techId = techId
    
    return t
    
end

function ParseCommActionMessage(t)
    return t.techId
end

local kCommTargetedAction = 
{
    techId              = "enum kTechId",
    
    // normalized pick coords for CommTargetedAction
    // or world coords for kCommTargetedAction
    x                   = "float",
    y                   = "float",
    z                   = "float",
    
    orientationRadians  = "angle (11 bits)"
}

function BuildCommTargetedActionMessage(techId, x, y, z, orientationRadians)

    local t = {}
    
    t.techId = techId
    t.x = x
    t.y = y
    t.z = z
    t.orientationRadians = orientationRadians
    
    return t
    
end

function ParseCommTargetedActionMessage(t)
    return t.techId, Vector(t.x, t.y, t.z), t.orientationRadians
end

local kGorgeBuildStructureMessage = 
{
    origin = "vector",
    direction = "vector",
    structureIndex = "integer (1 to 5)",
    lastClickedPosition = "vector"
}

function BuildGorgeDropStructureMessage(origin, direction, structureIndex, lastClickedPosition)

    local t = {}
    
    t.origin = origin
    t.direction = direction
    t.structureIndex = structureIndex
    t.lastClickedPosition = lastClickedPosition or Vector(0,0,0)

    return t
    
end    

function ParseGorgeBuildMessage(t)
    return t.origin, t.direction, t.structureIndex, t.lastClickedPosition
end

local kMutePlayerMessage = 
{
    muteClientIndex = "integer",
    setMute = "boolean"
}

function BuildMutePlayerMessage(muteClientIndex, setMute)

    local t = {}

    t.muteClientIndex = muteClientIndex
    t.setMute = setMute
    
    return t
    
end

function ParseMutePlayerMessage(t)
    return t.muteClientIndex, t.setMute
end

local kDebugLineMessage =
{
    startPoint = "vector",
    endPoint = "vector",
    lifetime = "float",
    r = "float",
    g = "float",
    b = "float",
    a = "float"
}

function BuildDebugLineMessage(startPoint, endPoint, lifetime, r, g, b, a)

    local t = { }
    
    t.startPoint = startPoint
    t.endPoint = endPoint
    t.lifetime = lifetime
    t.r = r
    t.g = g
    t.b = b
    t.a = a
    
    return t
    
end

function ParseDebugLineMessage(t)
    return t.startPoint, t.endPoint, t.lifetime, t.r, t.g, t.b, t.a
end

local kDebugCapsuleMessage =
{
    sweepStart = "vector",
    sweepEnd = "vector",
    capsuleRadius = "float",
    capsuleHeight = "float",
    lifetime = "float"
}

function BuildDebugCapsuleMessage(sweepStart, sweepEnd, capsuleRadius, capsuleHeight, lifetime)

    local t = { }
    
    t.sweepStart = sweepStart
    t.sweepEnd = sweepEnd
    t.capsuleRadius = capsuleRadius
    t.capsuleHeight = capsuleHeight
    t.lifetime = lifetime
    
    return t
    
end

function ParseDebugCapsuleMessage(t)
    return t.sweepStart, t.sweepEnd, t.capsuleRadius, t.capsuleHeight, t.lifetime
end

local kMinimapAlertMessage = 
{
    techId = "enum kTechId",
    worldX = "float",
    worldZ = "float",
    entityId = "entityid",
    entityTechId = "enum kTechId"
}

local kCommanderNotificationMessage =
{
    locationId = "integer",
    techId = "enum kTechId"
}

// From TechNode.kTechNodeVars
local kTechNodeBaseMessage =
{

    // Unique id
    techId              = string.format("integer (0 to %d)", kTechIdMax),
    
    // Type of tech
    techType            = "enum kTechType",
    
    // Tech nodes that are required to build or research (or kTechId.None)
    prereq1             = string.format("integer (0 to %d)", kTechIdMax),
    prereq2             = string.format("integer (0 to %d)", kTechIdMax),
    
    // This node is an upgrade, addition, evolution or add-on to another node
    // This includes an alien upgrade for a specific lifeform or an alternate
    // ammo upgrade for a weapon. For research nodes, they can only be triggered
    // on structures of this type (ie, mature versions of a structure).
    addOnTechId         = string.format("integer (0 to %d)", kTechIdMax),

    // Resource costs (team resources, individual resources or energy depending on type)
    cost                = "integer (0 to 150)",

    // If tech node can be built/researched/used. Requires prereqs to be met and for 
    // research, means that it hasn't already been researched and that it's not
    // in progress. Computed when structures are built or killed or when
    // global research starts or stops (TechTree:ComputeAvailability()).
    available           = "boolean",

    // Seconds to complete research or upgrade. Structure build time is kept in Structure.buildTime (Server).
    time                = "integer (0 to 360)",   
    
    // 0-1 research progress. This is non-authoritative and set/duplicated from Structure:SetResearchProgress()
    // so player buy menus can display progress.
    researchProgress    = "float",
    
    // 0-1 research progress of the prerequisites of this node.
    prereqResearchProgress = "float",

    // True after being researched.
    researched          = "boolean",
    
    // True for research in progress (not upgrades)
    researching         = "boolean",
    
    // If true, tech tree activity requires ghost, otherwise it will execute at target location's position (research, most actions)
    requiresTarget      = "boolean",
    
    hasTech             = "boolean"
    
}

// Build tech node from data sent in base update
// Was TechNode:InitializeFromNetwork
function ParseTechNodeBaseMessage(techNode, networkVars)

    techNode.techId                 = networkVars.techId
    techNode.techType               = networkVars.techType
    techNode.prereq1                = networkVars.prereq1
    techNode.prereq2                = networkVars.prereq2
    techNode.addOnTechId            = networkVars.addOnTechId
    techNode.cost                   = networkVars.cost
    techNode.available              = networkVars.available
    techNode.time                   = networkVars.time
    techNode.researchProgress       = networkVars.researchProgress
    techNode.prereqResearchProgress = networkVars.prereqResearchProgress
    techNode.researched             = networkVars.researched
    techNode.researching            = networkVars.researching
    techNode.requiresTarget         = networkVars.requiresTarget
    techNode.hasTech                = networkVars.hasTech
    
end

// Update values from kTechNodeUpdateMessage
// Was TechNode:UpdateFromNetwork
function ParseTechNodeUpdateMessage(techNode, networkVars)

    techNode.available              = networkVars.available
    techNode.researchProgress       = networkVars.researchProgress
    techNode.prereqResearchProgress = networkVars.prereqResearchProgress
    techNode.researched             = networkVars.researched
    techNode.researching            = networkVars.researching
    techNode.hasTech                = networkVars.hasTech
    
end

function BuildTechNodeBaseMessage(techNode)

    local t = {}
    
    t.techId                    = techNode.techId
    t.techType                  = techNode.techType
    t.prereq1                   = techNode.prereq1
    t.prereq2                   = techNode.prereq2
    t.addOnTechId               = techNode.addOnTechId
    t.cost                      = techNode.cost
    t.available                 = techNode.available
    t.time                      = techNode.time
    t.researchProgress          = techNode.researchProgress
    t.prereqResearchProgress    = techNode.prereqResearchProgress
    t.researched                = techNode.researched
    t.researching               = techNode.researching
    t.requiresTarget            = techNode.requiresTarget
    t.hasTech                   = techNode.hasTech
    
    return t
    
end

function BuildCommanderNotificationMessage(locationId, techId)

    local t = {}
    
    t.locationId        = locationId
    t.techId            = techId
    
    return t

end

local kChatClientMessage =
{
    teamOnly = "boolean",
    message = string.format("string (%d)", kMaxChatLength)
}

function BuildChatClientMessage(teamOnly, chatMessage)
    return { teamOnly = teamOnly, message = chatMessage }
end

local kChatMessage =
{
    teamOnly = "boolean",
    playerName = "string (" .. kMaxNameLength .. ")",
    locationId = "integer (-1 to 1000)",
    teamNumber = "integer (" .. kTeamInvalid .. " to " .. kSpectatorIndex .. ")",
    teamType = "integer (" .. kNeutralTeamType .. " to " .. kAlienTeamType .. ")",
    message = string.format("string (%d)", kMaxChatLength)
}

function BuildChatMessage(teamOnly, playerName, playerLocationId, playerTeamNumber, playerTeamType, chatMessage)

    local message = { }
    
    message.teamOnly = teamOnly
    message.playerName = playerName
    message.locationId = playerLocationId
    message.teamNumber = playerTeamNumber
    message.teamType = playerTeamType
    message.message = chatMessage
    
    return message
    
end

function BuildRookieMessage(isRookie)

    local t = {}

    t.isRookie = isRookie
    
    return t
    
end

function ParseRookieMessage(t)
    return t.isRookie
end

local kMovementMode = 
{
    movement = "boolean"
}

local kGameEndMessage =
{
    win = "boolean"
}

local kHiveInfoMessage = 
{
    key              = "integer",
    location         = string.format("string (%d)", kMaxHiveNameLength),
    healthpercent    = "float",
    buildprogress    = "float",
    techId           = "enum kTechId",
    timelastdamaged  = "time"
}

Shared.RegisterNetworkMessage("GameEnd", kGameEndMessage)

Shared.RegisterNetworkMessage("EntityChanged", kEntityChangedMessage)
Shared.RegisterNetworkMessage("ResetMouse", {} )
Shared.RegisterNetworkMessage("ResetGame", {} )

// Selection
Shared.RegisterNetworkMessage("SelectUnit", kSelectUnitMessage)
Shared.RegisterNetworkMessage("SelectHotkeyGroup", kSelectHotkeyGroupMessage)

// Commander actions
Shared.RegisterNetworkMessage("CommAction", kCommAction)
Shared.RegisterNetworkMessage("CommTargetedAction", kCommTargetedAction)
Shared.RegisterNetworkMessage("CommTargetedActionWorld", kCommTargetedAction)
Shared.RegisterNetworkMessage("CreateHotKeyGroup", kCreateHotkeyGroupMessage)

// Notifications
Shared.RegisterNetworkMessage("MinimapAlert", kMinimapAlertMessage)
Shared.RegisterNetworkMessage("CommanderNotification", kCommanderNotificationMessage)

// Player actions
Shared.RegisterNetworkMessage("MutePlayer", kMutePlayerMessage)

// Gorge select structure message
Shared.RegisterNetworkMessage("GorgeBuildStructure", kGorgeBuildStructureMessage)
Shared.RegisterNetworkMessage("GorgeBuildStructure2", kGorgeBuildStructureMessage)

// Chat
Shared.RegisterNetworkMessage("ChatClient", kChatClientMessage)
Shared.RegisterNetworkMessage("Chat", kChatMessage)

// Debug messages
Shared.RegisterNetworkMessage("DebugLine", kDebugLineMessage)
Shared.RegisterNetworkMessage("DebugCapsule", kDebugCapsuleMessage)

Shared.RegisterNetworkMessage( "TechNodeBase", kTechNodeBaseMessage )
Shared.RegisterNetworkMessage( "ClearTechTree", {} )

Shared.RegisterNetworkMessage( "MovementMode", kMovementMode )
Shared.RegisterNetworkMessage( "HiveInfo", kHiveInfoMessage )

local kRookieMessage =
{
    isRookie = "boolean"
}
Shared.RegisterNetworkMessage( "SetRookieMode", kRookieMessage )


local kCommunicationStatusMessage = 
{
    communicationStatus = "enum kPlayerCommunicationStatus"
}

function BuildCommunicationStatus(communicationStatus)

    local t = {}

    t.communicationStatus = communicationStatus
    
    return t
    
end

function ParseCommunicationStatus(t)
    return t.communicationStatus
end

Shared.RegisterNetworkMessage( "SetCommunicationStatus", kCommunicationStatusMessage )

local kBuyMessage =
{
    techId1 = "enum kTechId",
    techId2 = "enum kTechId",
    techId3 = "enum kTechId",
    techId4 = "enum kTechId",
    techId5 = "enum kTechId",
    techId6 = "enum kTechId",
    techId7 = "enum kTechId",
    techId8 = "enum kTechId"
}

function BuildBuyMessage(techIds)

    assert(#techIds <= table.countkeys(kBuyMessage))
    
    local buyMessage = { techId1 = kTechId.None, techId2 = kTechId.None, techId3 = kTechId.None,
                         techId4 = kTechId.None, techId5 = kTechId.None, techId6 = kTechId.None,
                         techId7 = kTechId.None, techId8 = kTechId.None }
    
    for t = 1, #techIds do
        buyMessage["techId" .. t] = techIds[t]
    end
    
    return buyMessage
    
end

function ParseBuyMessage(buyMessage)

    local maxNumTechs = table.countkeys(kBuyMessage)
    
    // We need to iterate over the buyMessage table and insert
    // the tech Ids in the correct order into the techIds list.
    local techIds = { }
    for t = 1, maxNumTechs do
    
        for name, techId in pairs(buyMessage) do
        
            if ("techId" .. t) == name and techId ~= kTechId.None then
                table.insert(techIds, techId)
            end
            
        end
        
    end
    
    return techIds
    
end

Shared.RegisterNetworkMessage("Buy", kBuyMessage)