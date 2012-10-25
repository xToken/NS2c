//DAK Loader/Base Config

if Server then

	Script.Load("lua/dkjson.lua")

	local mapCycleFileName = "config://MapCycle.json"
		
    local function LoadMapCycle()
    
        Shared.Message("Loading " .. mapCycleFileName)
		
		local configFile = io.open(mapCycleFileName, "r")
        if configFile then
            local fileContents = configFile:read("*all")
            kDAKMapCycle = json.decode(fileContents) or { maps = { "ns2_docking", "ns2_summit", "ns2_tram", "ns2_veil" }, time = 30, mode = "order", mods = { "5f4f178" } }
			io.close(configFile)
		else
		    local defaultConfig = { maps = { "ns2_docking", "ns2_summit", "ns2_tram", "ns2_veil" }, time = 30, mode = "order", mods = { "5f4f178" } }
			kDAKMapCycle = defaultConfig
        end
		assert(type(kDAKMapCycle.time) == 'number')
		assert(type(kDAKMapCycle.maps) == 'table')
        
    end
	
	LoadMapCycle()
	
	local function SaveMapCycle()
		local configFile = io.open(mapCycleFileName, "w+")
		configFile:write(json.encode(kDAKMapCycle, { indent = true, level = 1 }))
		io.close(configFile)
	end	
	
	local function GetMapName(map)
		if type(map) == "table" and map.map ~= nil then
			return map.map
		end
		return map
	end
	
	function DAKVerifyMapName(mapName)
		local matchingFiles = { }
		Shared.GetMatchingFileNames("maps/*.level", false, matchingFiles)

		for _, mapFile in pairs(matchingFiles) do
			local _, _, filename = string.find(mapFile, "maps/(.*).level")
			if mapName:upper() == string.format(filename):upper() then
				return true
			end
		end
		return false
	end
	
	function MapCycle_GetMapCycle()
		return kDAKMapCycle
	end
	
	function MapCycle_SetMapCycle(newCycle)
		kDAKMapCycle = newCycle
		SaveMapCycle()
	end
	
	function MapCycle_CycleMap()
	
		if #kDAKOverrideMapChange > 0 then
			for i = 1, #kDAKOverrideMapChange do
				if kDAKOverrideMapChange[i]() then
					return
				end
			end
		end
		
		//Fall back on default mapcycle
		local numMaps = #kDAKMapCycle.maps
		
		if numMaps == 0 then
		
			Shared.Message("No maps in the map cycle")
			return
			
		end
		
		local currentMap = Shared.GetMapName()
		local map = nil
		
		if kDAKMapCycle.mode == "random" then
		
			// Choose a random map to switch to.
			local mapIndex = math.random(1, numMaps)
			map = kDAKMapCycle.maps[mapIndex]
			
			// Don't change to the map we're currently playing.
			if GetMapName(map) == currentMap then
			
				mapIndex = mapIndex + 1
				if mapIndex > numMaps then
					mapIndex = 1
				end
				map = kDAKMapCycle.maps[mapIndex]
				
			end
			
		else
		
			// Go to the next map in the cycle. We need to search backwards
			// in case the same map has been specified multiple times.
			local mapIndex = 0
			
			for i = #kDAKMapCycle.maps, 1, -1 do
				if GetMapName(kDAKMapCycle.maps[i]) == currentMap then
					mapIndex = i
					break
				end
			end
			
			mapIndex = mapIndex + 1
			if mapIndex > numMaps then
				mapIndex = 1
			end
			
			map = kDAKMapCycle.maps[mapIndex]
			
		end
		
		local mapName = GetMapName(map)
		if mapName ~= currentMap and DAKVerifyMapName(mapName) then
			local ServerMods = { }
			if kDAKMapCycle and kDAKMapCycle.mods then
				ServerMods = kDAKMapCycle.mods
			end
			Server.StartWorld(ServerMods, mapName)
		end
		
	end

	function MapCycle_TestCycleMap()
			
		if #kDAKCheckMapChange > 0 then
			for i = 1, #kDAKCheckMapChange do
				if kDAKCheckMapChange[i]() then
					return false
				end
			end
		end

		// time is stored as minutes so convert to seconds.
		if Shared.GetTime() < (kDAKMapCycle.time * 60) then
			// We haven't been on the current map for long enough.
			return false
		end
		
		return true
		
	end
	
	local function OnCommandCycleMap(client)

		if client == nil or client:GetIsLocalClient() then
			MapCycle_CycleMap()
		end
		
	end

	local function OnCommandChangeMap(client, mapName)
		
		if client == nil or client:GetIsLocalClient() and DAKVerifyMapName(mapName) then
			local ServerMods = { }
			if kDAKMapCycle and kDAKMapCycle.mods then
				ServerMods = kDAKMapCycle.mods
			end
			Server.StartWorld(ServerMods, mapName)
		end
		
	end

	Event.Hook("Console_changemap", OnCommandChangeMap)
	Event.Hook("Console_cyclemap", OnCommandCycleMap)
	
end