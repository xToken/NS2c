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
Script.Load("lua/InsightNetworkMessages.lua")

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
    altMode = "boolean"
}

function BuildHitEffectMessage(position, doer, surface, target, showtracer, altMode)

    local t = {}
    t.posx = position.x
    t.posy = position.y
    t.posz = position.z
    t.doerId = (doer and doer:GetId()) or Entity.invalidId
    t.surface = (surface and StringToEnum(kHitEffectSurface, surface)) or kHitEffectSurface.metal
    t.targetId = (target and target:GetId()) or Entity.invalidId
    t.showtracer = showtracer == true   
    t.altMode = altMode == true 
    return t
    
end

function ParseHitEffectMessage(message)

    local position = Vector(message.posx, message.posy, message.posz)
    local doer = Shared.GetEntity(message.doerId)
    local surface = EnumToString(kHitEffectSurface, message.surface)
    local target = Shared.GetEntity(message.targetId)
    local showtracer = message.showtracer
    local altMode = message.altMode
    
    /*
    Print("position %s", ToString(position))
    Print("doer %s", ToString(doer))
    Print("surface %s", ToString(surface))
    Print("target %s", ToString(target))
    Print("showtracer %s", ToString(showtracer))
    */
    
    return position, doer, surface, target, showtracer, altMode

end

Shared.RegisterNetworkMessage( "HitEffect", kHitEffectMessage )

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

kWorldTextMessageType = enum({ 'Resources', 'Resource' })
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

local kClearSelectionMessage =
{
    removeAll = "boolean",
    removeId = "entityid",
    ctrlPressed = "boolean"
}

function BuildClearSelectionMessage(removeAll, entityId, ctrlPressed)
    local t = {}
    t.removeAll = removeAll == true
    t.removeId = entityId or Entity.invalidId
    t.ctrlPressed = ctrlPressed == true
    return t
end

function ParseClearSelectionMessage(message)
    return message.removeAll, message.removeId, message.ctrlPressed
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

local kControlClickSelectMessage =
{
    pickVec = "vector",
    minDot = "float"
}

function BuildControlClickSelectCommand(pickVec, minDot)

    local t = {}
    
    t.pickVec = Vector(pickVec)
    t.minDot = minDot
    
    return t
    
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

function ParseControlClickSelectMessage(message)
    return message.pickVec, message.minDot
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

local kExecuteSayingMessage = 
{
    sayingIndex = "integer (1 to 5)",
    sayingsMenu = "integer (1 to 3)"
}

function BuildExecuteSayingMessage(sayingIndex, sayingsMenu)

    local t = {}
    
    t.sayingIndex = sayingIndex
    t.sayingsMenu = sayingsMenu
    
    return t
    
end

local kGorgeSelectStructureMessage = 
{
    structureIndex = "integer (1 to 5)",
}

function BuildGorgeSelectStructureMessage(structureIndex)

    local t = {}
    
    t.structureIndex = structureIndex
    
    return t
end    

function ParseExecuteSayingMessage(t)
    return t.sayingIndex, t.sayingsMenu
end

function ParseGorgeSelectMessage(t)
    return t.structureIndex
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

function BuildSelectIdMessage(entityId)

    local t = {}        
    t.entityId = entityId        
    return t

end

function ParseSelectIdMessage(t)

        return t.entityId
        
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

local kSelectIdMessage =
{
    entityId = "entityid"
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
    // on structures of this type (ie versions of a structure).
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

local kGameEndMessage =
{
    win = "boolean"
}
Shared.RegisterNetworkMessage("GameEnd", kGameEndMessage)

Shared.RegisterNetworkMessage("EntityChanged", kEntityChangedMessage)
Shared.RegisterNetworkMessage("ResetMouse", {} )
Shared.RegisterNetworkMessage("ResetGame", {} )

// Selection
Shared.RegisterNetworkMessage("MarqueeSelect", kMarqueeSelectMessage)
Shared.RegisterNetworkMessage("ClickSelect", kClickSelectMessage)
Shared.RegisterNetworkMessage("ClearSelection", kClearSelectionMessage)
Shared.RegisterNetworkMessage("ControlClickSelect", kControlClickSelectMessage)
Shared.RegisterNetworkMessage("SelectHotkeyGroup", kSelectHotkeyGroupMessage)
Shared.RegisterNetworkMessage("SelectId", kSelectIdMessage)

// Commander actions
Shared.RegisterNetworkMessage("CommAction", kCommAction)
Shared.RegisterNetworkMessage("CommTargetedAction", kCommTargetedAction)
Shared.RegisterNetworkMessage("CommTargetedActionWorld", kCommTargetedAction)
Shared.RegisterNetworkMessage("CreateHotKeyGroup", kCreateHotkeyGroupMessage)

// Notifications
Shared.RegisterNetworkMessage("MinimapAlert", kMinimapAlertMessage)
Shared.RegisterNetworkMessage("CommanderNotification", kCommanderNotificationMessage)

// Player actions
Shared.RegisterNetworkMessage("ExecuteSaying", kExecuteSayingMessage)
Shared.RegisterNetworkMessage("MutePlayer", kMutePlayerMessage)

// Gorge select structure message
Shared.RegisterNetworkMessage("GorgeSelectStructure", kGorgeSelectStructureMessage)

// Chat
Shared.RegisterNetworkMessage("ChatClient", kChatClientMessage)
Shared.RegisterNetworkMessage("Chat", kChatMessage)

// Debug messages
Shared.RegisterNetworkMessage("DebugLine", kDebugLineMessage)
Shared.RegisterNetworkMessage("DebugCapsule", kDebugCapsuleMessage)

Shared.RegisterNetworkMessage( "TechNodeBase", kTechNodeBaseMessage )
Shared.RegisterNetworkMessage( "ClearTechTree", {} )