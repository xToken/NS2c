-- NS2c_Server.lua

-- For Classic
gRankingDisabled = true

Script.Load("lua/NS2c_Shared.lua")
Script.Load("lua/ns2c/NS2cConfig.lua")

Server.armorySpawnPoints = table.array(10)

function GetLoadEntity(mapName, _, values)
    return mapName ~= "power_point"
        and mapName ~= "commander_camera"
        and mapName ~= "cyst"
        and mapName ~= "reflection_probe"
        and mapName ~= InfantryPortal.kMapName
        and mapName ~= "decal"
		and values.onlyexplore ~= true
end

function GetCreateEntityOnStart(mapName, _, _)

    return mapName ~= "prop_static"
       and mapName ~= "light_point"
       and mapName ~= "light_spot"
       and mapName ~= "light_ambient"
       and mapName ~= "color_grading"
       and mapName ~= "cinematic"
       and mapName ~= "skybox"
       and mapName ~= "pathing_settings"
       and mapName ~= ReadyRoomSpawn.kMapName
       and mapName ~= "ambient_sound"
       and mapName ~= Reverb.kMapName
       and mapName ~= Hive.kMapName
       and mapName ~= CommandStation.kMapName
       and mapName ~= InfantryPortal.kMapName
       and mapName ~= "spawn_selection_override"
    
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
        
    elseif mapName == InfantryPortal.kMapName then
    
        table.insert(Server.infantryPortalSpawnPoints, values.origin)
        success = true
        
    elseif mapName == Armory.kMapName then
    
        table.insert(Server.armorySpawnPoints, values.origin)
        success = true
        
    elseif mapName == "pathing_settings" then
    
        ParsePathingSettings(values)
        success = true
        
    elseif mapName == "cinematic" then
    
        success = values.startsOnMessage ~= nil and values.startsOnMessage ~= ""
        if success then
        
            PrecacheAsset(values.cinematicName)
            local entity = Server.CreateEntity(ServerParticleEmitter.kMapName, values)
            if entity then
                entity:SetMapEntity()
            end
            
        end
        
    elseif mapName == "spawn_selection_override" then
    
        Server.spawnSelectionOverrides = Server.spawnSelectionOverrides or { }
        table.insert(Server.spawnSelectionOverrides, { alienSpawn = string.lower(values.alienSpawn), marineSpawn = string.lower(values.marineSpawn) })
        success = true
        
    end
    
    return success
    
end