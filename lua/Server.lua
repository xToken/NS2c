// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Set the name of the VM for debugging
decoda_name = "Server"

Script.Load("lua/Shared.lua")
Script.Load("lua/MapEntityLoader.lua")
Script.Load("lua/Button.lua")
Script.Load("lua/TechData.lua")
Script.Load("lua/TargetCache.lua")

Script.Load("lua/MarineTeam.lua")
Script.Load("lua/AlienTeam.lua")

Script.Load("lua/Bot.lua")
Script.Load("lua/VoteManager.lua")

Script.Load("lua/ServerConfig.lua")
Script.Load("lua/ServerAdmin.lua")
Script.Load("lua/DAKLoader.lua")

Script.Load("lua/ServerWebInterface.lua")
Script.Load("lua/MapCycle.lua")
Script.Load("lua/ConsistencyConfig.lua")

Script.Load("lua/ConsoleCommands_Server.lua")
Script.Load("lua/NetworkMessages_Server.lua")

Script.Load("lua/dkjson.lua")

Script.Load("lua/DbgTracer_Server.lua")

Script.Load("lua/NetworkDebug.lua")
 
Server.dbgTracer = DbgTracer()
Server.dbgTracer:Init()

Server.readyRoomSpawnList = table.array(32)

// map name, group name and values keys for all map entities loaded to
// be created on game reset
Server.mapLoadLiveEntityValues = table.array(100)

// Game entity indices created from mapLoadLiveEntityValues. They are all deleted
// on and rebuilt on map reset.
Server.mapLiveEntities = table.array(32)

// Map entities are stored here in order of their priority so they are loaded
// in the correct order (Structure assumes that Gamerules exists upon loading for example).
Server.mapPostLoadEntities = table.array(32)

// Recent chat messages are stored on the server.
Server.recentChatMessages = CreateRingBuffer(20)
local chatMessageCount = 0

function Server.AddChatToHistory(message, playerName, steamId, teamNumber, teamOnly)

    chatMessageCount = chatMessageCount + 1
    Server.recentChatMessages:Insert({ id = chatMessageCount, message = message, player = playerName,
                                       steamId = steamId, team = teamNumber, teamOnly = teamOnly })
    DAKChatLogging(message, playerName, steamId, teamNumber, teamOnly)
end

/**
 * Map entities with a higher priority are loaded first.
 */
local kMapEntityLoadPriorities = { }
kMapEntityLoadPriorities[NS2Gamerules.kMapName] = 1
local function GetMapEntityLoadPriority(mapName)

    local priority = 0
    
    if kMapEntityLoadPriorities[mapName] then
        priority = kMapEntityLoadPriorities[mapName]
    end
    
    return priority

end

// filter the entities which are explore mode only
function GetLoadEntity(mapName, groupName, values)
    return values.onlyexplore ~= true
end

function GetCreateEntityOnStart(mapName, groupName, values)

    return mapName ~= "prop_static"
       and mapName ~= "light_point"
       and mapName ~= "light_spot"
       and mapName ~= "light_ambient"
       and mapName ~= "color_grading"
       and mapName ~= "cinematic"
       and mapName ~= "skybox"
       and mapName ~= "pathing_settings"
       and mapName ~= ReadyRoomSpawn.kMapName
       //and mapName ~= AmbientSound.kMapName
       and mapName ~= Reverb.kMapName
       and mapName ~= Hive.kMapName
       and mapName ~= CommandStation.kMapName
       //and mapName ~= Cyst.kMapName
       and mapName ~= Particles.kMapName
       and mapName ~= InfantryPortal.kMapName

end

function GetLoadSpecial(mapName, groupName, values)

    local success = false

    if mapName == Hive.kMapName or mapName == CommandStation.kMapName then
       table.insert(Server.mapLoadLiveEntityValues, { mapName, groupName, values })
       success = true
    elseif mapName == ReadyRoomSpawn.kMapName then
    
        local entity = ReadyRoomSpawn()
        entity:OnCreate()
        LoadEntityFromValues(entity, values)
        table.insert(Server.readyRoomSpawnList, entity)
        success = true
        
    //elseif (mapName == AmbientSound.kMapName) then
    
        // Make sure sound index is precached but only create ambient sound object on client
        //Shared.PrecacheSound(values.eventName)
        //success = true
        
    elseif mapName == Particles.kMapName then
        Shared.PrecacheCinematic(values.cinematicName)
        success = true
    elseif mapName == InfantryPortal.kMapName then
        //table.insert(Server.infantryPortalSpawnPoints, values.origin)
        success = false
    //elseif mapName == Cyst.kMapName then
        //table.insert(Server.cystSpawnPoints, values.origin)
        //success = true
    elseif mapName == "pathing_settings" then
        ParsePathingSettings(values)
        success = true
    end

    return success    

end

local function LoadServerMapEntity(mapName, groupName, values)

    if not GetLoadEntity(mapName, groupName, values) then
        return
    end
    
    if mapName == InfantryPortal.kMapName then
        return
    end
    
    // Skip the classes that are not true entities and are handled separately
    // on the client.
    if GetCreateEntityOnStart(mapName, groupName, values) then
        
        local entity = Server.CreateEntity(mapName, values)
        if entity then
        
            entity:SetMapEntity()
            
            // Map Entities with LiveMixin can be destroyed during the game.
            if HasMixin(entity, "Live") then
            
                // Insert into table so we can re-create them all on map post load (and game reset)
                table.insert(Server.mapLoadLiveEntityValues, {mapName, groupName, values})
                
                // Delete it because we're going to recreate it on map reset
                table.insert(Server.mapLiveEntities, entity:GetId())
                
            end
            
            // $AS FIXME: We are special caasing techPoints for pathing right now :/ 
            if (mapName == "tech_point") or values.pathInclude == true then
            
                local coords = values.angles:GetCoords(values.origin)
                Pathing.CreatePathingObject(entity:GetModelName(), coords)
                
            end
            
            local renderModelCommAlpha = GetAndCheckValue(values.commAlpha, 0, 1, "commAlpha", 1, true)
            local blocksPlacement = groupName == kCommanderInvisibleGroupName or
                                    groupName == kCommanderNoBuildGroupName
            
            if HasMixin(entity, "Model") and (renderModelCommAlpha < 1 or blocksPlacement) then
                entity:SetPhysicsGroup(PhysicsGroup.CommanderPropsGroup)
            end
            
        end
        
    end  
        
    if not GetLoadSpecial(mapName, groupName, values) then
    
        // Allow the MapEntityLoader to load it if all else fails.
        LoadMapEntity(mapName, groupName, values)
        
    end
    
end

/**
 * Called as the map is being loaded to create the entities.
 */
function OnMapLoadEntity(mapName, groupName, values)

    local priority = GetMapEntityLoadPriority(mapName)
    if Server.mapPostLoadEntities[priority] == nil then
        Server.mapPostLoadEntities[priority] = { }
    end
    
    if mapName == "tech_point" then
        Pathing.AddFillPoint(values.origin) 
    end

    table.insert(Server.mapPostLoadEntities[priority], { MapName = mapName, GroupName = groupName, Values = values })

end

function OnMapPreLoad()

    Shared.PreLoadSetGroupNeverVisible(kCollisionGeometryGroupName)
    Shared.PreLoadSetGroupPhysicsId(kNonCollisionGeometryGroupName, 0)
    
    Shared.PreLoadSetGroupNeverVisible(kCommanderBuildGroupName)   
    Shared.PreLoadSetGroupPhysicsId(kCommanderBuildGroupName, PhysicsGroup.CommanderBuildGroup)     
    
    // Any geometry in kCommanderInvisibleGroupName or kCommanderNoBuildGroupName shouldn't interfere with selection or other commander actions
    Shared.PreLoadSetGroupPhysicsId(kCommanderInvisibleGroupName, PhysicsGroup.CommanderPropsGroup)
    Shared.PreLoadSetGroupPhysicsId(kCommanderNoBuildGroupName, PhysicsGroup.CommanderPropsGroup)
    
    // Don't have bullets collide with collision geometry
    Shared.PreLoadSetGroupPhysicsId(kCollisionGeometryGroupName, PhysicsGroup.CollisionGeometryGroup)
    
    // Clear spawn points
    Server.readyRoomSpawnList = {}
    
    Server.mapLoadLiveEntityValues = {}
    Server.mapLiveEntities = {}
    
end

function DestroyLiveMapEntities()

    // Delete any map entities that have been created
    for index, mapEntId in ipairs(Server.mapLiveEntities) do
    
        local ent = Shared.GetEntity(mapEntId)
        if ent then
            DestroyEntity(ent)
        end
        
    end
    
    Server.mapLiveEntities = { }
    
end

function CreateLiveMapEntities()

    // Create new Live map entities
    for index, triple in ipairs(Server.mapLoadLiveEntityValues) do
        
        // {mapName, groupName, keyvalues}
        local entity = Server.CreateEntity(triple[1], triple[3])
        
        // Store so we can track it during the game and delete it on game reset if not dead yet
        table.insert(Server.mapLiveEntities, entity:GetId())

    end

end

local function CheckForDuplicateLocations()

    local locations = GetLocations()
    for _, checkLocation in ipairs(locations) do
    
        for _, dupLocation in ipairs(locations) do
        
            // Don't check the same exact location against itself.
            if checkLocation ~= dupLocation then
            
                if checkLocation:GetOrigin() == dupLocation:GetOrigin() then
                    Print("Duplicate location detected: " .. dupLocation:GetName())
                end
                
            end
            
        end
        
    end
    
end

/**
 * Callback handler for when the map is finished loading.
 */
local function OnMapPostLoad()

    // Higher priority entities are loaded first.
    local highestPriority = 0
    for k, v in pairs(kMapEntityLoadPriorities) do
        if v > highestPriority then highestPriority = v end
    end
    
    for i = highestPriority, 0, -1 do
    
        if Server.mapPostLoadEntities[i] then
        
            for k, entityData in ipairs(Server.mapPostLoadEntities[i]) do
                LoadServerMapEntity(entityData.MapName, entityData.GroupName, entityData.Values)
            end
            
        end
        
    end
    
    Server.mapPostLoadEntities = { }
    
    InitializePathing()
    CheckForDuplicateLocations()
    
    GetGamerules():OnMapPostLoad()
    
end

function GetTechTree(teamNumber)

    if GetGamerules() then
    
        local team = GetGamerules():GetTeam(teamNumber)
        if team and team.GetTechTree then
            return team:GetTechTree()
        end
        
    end
    
    return nil
    
end

/**
 * Called by the engine to test if a player (represented by the entity they are
 * controlling) can hear another player for the purposes of voice chat.
 */
local function OnCanPlayerHearPlayer(listener, speaker)
    return GetGamerules():GetCanPlayerHearPlayer(listener, speaker)
end

Event.Hook("MapPreLoad", OnMapPreLoad)
Event.Hook("MapPostLoad", OnMapPostLoad)
Event.Hook("MapLoadEntity", OnMapLoadEntity)
Event.Hook("CanPlayerHearPlayer", OnCanPlayerHearPlayer)