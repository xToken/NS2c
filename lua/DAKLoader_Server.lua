//DAK Loader/Base Config

if Server then

	Script.Load("lua/dkjson.lua")

	kDAKConfig = nil 						//Global variable storing all configuration items for mods
	kDAKSettings = nil 						//Global variable storing all settings for mods
	kDAKRevisions = { }						//List used to track revisions of plugins
	kDAKGameID = { }						//List of connected clients for GameID
	kDAKMapCycle = { }						//MapCycle.json information
	
	//DAK Hookable Functions
	kDAKOnClientConnect = { }				//Functions run on Client Connect
	kDAKOnClientDisconnect = { }			//Functions run on Client Disconnect
	kDAKOnServerUpdate = { }				//Functions run on ServerUpdate
	kDAKOnClientDelayedConnect = { }		//Functions run on DelayedClientConnect
	kDAKOnTeamJoin = { }					//Functions run on TeamJoin from Gamerules
	kDAKOnGameEnd = { }						//Functions run on GameEnd from Gamerules
	kDAKOnEntityKilled = { }				//Functions run on EntityKilled from Gamerules
	kDAKOnUpdatePregame = { }				//Functions run on UpdatePregame from Gamerules
	kDAKOnClientChatMessage = { }			//Functions run on ChatMessages
	kDAKCheckMapChange = { }	    		//List of functions run to confirm if map should change
	kDAKOverrideMapChange = { }	    		//Functions run before MapCycle
	
	//Other globals
	kDAKServerAdminCommands = { }			//List of ServerAdmin Commands
	kDAKPluginDefaultConfigs = { }			//List of functions to setup default configs per plugin
	
	kDAKBaseGamerules = NS2Gamerules
	
	local settings = { groups = { }, users = { } }
	
	local DAKConfigFileName = "config://DAKConfig.json"
	local DAKSettingsFileName = "config://DAKSettings.json"
	local DAKServerAdminFileName = "config://ServerAdmin.json"
	local mapCycleFileName = "config://MapCycle.json"
	local DelayedClientConnect = { }
	local DelayedServerAdminCommands = { }
	local DelayedServerCommands = false
	local serverupdatetime = 0
	kDAKRevisions["DAKLoader"] = 2.0
		
    local function LoadServerAdminSettings()
    
        Shared.Message("Loading " .. DAKServerAdminFileName)
		
        local initialState = { groups = { }, users = { } }
        settings = initialState
		
		local configFile = io.open(DAKServerAdminFileName, "r")
        if configFile then
            local fileContents = configFile:read("*all")
            settings = json.decode(fileContents) or initialState
			io.close(configFile)
		else
		    local defaultConfig = {
									groups =
										{
										  admin_group = { type = "disallowed", commands = { } },
										  mod_group = { type = "allowed", commands = { "sv_reset", "sv_ban" } }
										},
									users =
										{
										  NsPlayer = { id = 10000001, groups = { "admin_group" } }
										}
								  }
			local configFile = io.open(DAKServerAdminFileName, "w+")
			configFile:write(json.encode(defaultConfig, { indent = true, level = 1 }))
			io.close(configFile)
        end
        assert(settings.groups, "groups must be defined in " .. DAKServerAdminFileName)
        assert(settings.users, "users must be defined in " .. DAKServerAdminFileName)
        
    end
	
    LoadServerAdminSettings()
	
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
    
    function DAKGetGroupCanRunCommand(groupName, commandName)
    
        local group = settings.groups[groupName]
        if not group then
            error("There is no group defined with name: " .. groupName)
        end
        
        local existsInList = false
        for c = 1, #group.commands do
        
            if group.commands[c] == commandName then
            
                existsInList = true
                break
                
            end
            
        end
        
        if group.type == "allowed" then
            return existsInList
        elseif group.type == "disallowed" then
            return not existsInList
        else
            error("Only \"allowed\" and \"disallowed\" are valid terms for the type of the admin group")
        end
        
    end
    
    function DAKGetClientCanRunCommand(client, commandName)
    
        // Convert to the old Steam Id format.
        local steamId = client:GetUserId()
        for name, user in pairs(settings.users) do
        
            if user.id == steamId then
            
                for g = 1, #user.groups do
                
                    local groupName = user.groups[g]
                    if DAKGetGroupCanRunCommand(groupName, commandName) then
                        return true
                    end
                    
                end
                
            end
            
        end

        return false
        
    end
	
	local function GenerateDefaultDAKConfig(Plugin)
		
		//Base DAK Config
		if Plugin == "DAKLoader" or Plugin == "ALL" then
			if kDAKConfig == nil then
				kDAKConfig = { }
			end
			kDAKConfig.DAKLoader = { }
			kDAKConfig.DAKLoader.kDelayedClientConnect = 2
			kDAKConfig.DAKLoader.kDelayedServerUpdate = 1
			kDAKConfig.DAKLoader.GamerulesExtensions = true
			kDAKConfig.DAKLoader.OverrideInterp = { }
			kDAKConfig.DAKLoader.OverrideInterp.kEnabled = false
			kDAKConfig.DAKLoader.OverrideInterp.kInterp = 100
			kDAKConfig.DAKLoader.kEnabled = true
			//Base DAK Config
		end
		
		//Generate default configs for all plugins
		for i = 1, #kDAKPluginDefaultConfigs do
			PluginDefaultConfig = kDAKPluginDefaultConfigs[i]
			if Plugin == PluginDefaultConfig.PluginName or Plugin == "ALL" then
				kDAKPluginDefaultConfigs[i].DefaultConfig()
			end
		end
		
		//Write config to file
		local configFile = io.open(DAKConfigFileName, "w+")
		configFile:write(json.encode(kDAKConfig, { indent = true, level = 1 }))
		io.close(configFile)
		
	end
	
	local function LoadDAKPluginConfigs()
		local matchingFiles = { }
		Shared.GetMatchingFileNames("lua/plugins/*.lua", false, matchingFiles)
		for _, pFile in pairs(matchingFiles) do
			local _, _, filename = string.find(pFile, "lua/plugins/(.*).lua")
			if string.sub(filename, 1, 6) == "config" then
				Script.Load(pFile)
			end
		end
	end
	
	LoadDAKPluginConfigs()
	
	local function LoadDAKConfig()
		local DAKConfigFile = io.open(DAKConfigFileName, "r")
		if DAKConfigFile then
			Shared.Message("Loading DAK configuration.")
			kDAKConfig = json.decode(DAKConfigFile:read("*all"))
			DAKConfigFile:close()
		end
		if kDAKConfig == nil or kDAKConfig == { } then
			Shared.Message("Generating Default DAK configuration.")
			GenerateDefaultDAKConfig("ALL")
		end
	end
	
	LoadDAKConfig()
	
	local function LoadDAKSettings()
		local DAKSettingsFile
		DAKSettingsFile = io.open(DAKSettingsFileName, "r")
		if DAKSettingsFile then
			Shared.Message("Loading DAK settings.")
			kDAKSettings = json.decode(DAKSettingsFile:read("*all"))
			DAKSettingsFile:close()
		end
		if kDAKSettings == nil then
			kDAKSettings = { }
		end
	end
	
	LoadDAKSettings()
	
	function SaveDAKSettings()
	
		local DAKSettingsFile = io.open(DAKSettingsFileName, "w+")
		if DAKSettingsFile then
			DAKSettingsFile:write(json.encode(kDAKSettings, { indent = true, level = 1 }))
			DAKSettingsFile:close()
		end
	
	end
	
	//*****************************************************************************************************************
	//Globals
	//*****************************************************************************************************************
	
	//Hooks for logging functions
	function EnhancedLog(message)
	
		if kDAKConfig and kDAKConfig.EnhancedLogging and kDAKConfig.EnhancedLogging.kEnabled then
			EnhancedLogMessage(message)
		end
	
	end
		
	function PrintToAllAdmins(commandname, client, parm1)
	
		if kDAKConfig and kDAKConfig.EnhancedLogging and kDAKConfig.EnhancedLogging.kEnabled then
			EnhancedLoggingAllAdmins(commandname, client, parm1)
		end
	
	end
	
	//Internal Globals
	function DAKCreateServerAdminCommand(commandName, commandFunction, helpText, optionalAlwaysAllowed)
		local ServerAdminCmd = { cmdName = commandName, cmdFunction = commandFunction, helpT = helpText, opt = optionalAlwaysAllowed }
		table.insert(DelayedServerAdminCommands, ServerAdminCmd)
		DelayedServerCommands = true
	end
	
	function DAKGenerateDefaultDAKConfig(Plugin)
		GenerateDefaultDAKConfig(Plugin)
	end
	
	function RegisterServerAdminCommand(commandName, commandFunction, helpText, optionalAlwaysAllowed)
		if kDAKConfig and kDAKConfig.BaseAdminCommands and kDAKConfig.BaseAdminCommands.kEnabled then
			CreateBaseServerAdminCommand(commandName, commandFunction, helpText, optionalAlwaysAllowed)
		else
			CreateServerAdminCommand(commandName, commandFunction, helpText, optionalAlwaysAllowed)
		end
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
	
	function DAKCreateGUIVoteBase(OnVoteFunction, OnVoteUpdateFunction, Relevancy)
		if kDAKConfig and kDAKConfig.GUIVoteBase and kDAKConfig.GUIVoteBase.kEnabled then
			return CreateGUIVoteBase(OnVoteFunction, OnVoteUpdateFunction, Relevancy)
		end
		return false
	end
	
	//Client ID Translators
	function VerifyClient(client)
	
		local playerList = EntityListToTable(Shared.GetEntitiesWithClassname("Player"))
		for r = #playerList, 1, -1 do
			if playerList[r] ~= nil then
				local plyr = playerList[r]
				local clnt = playerList[r]:GetClient()
				if plyr ~= nil and clnt ~= nil then
					if client ~= nil and clnt == client then
						return clnt
					end
				end
			end				
		end
		return nil
	
	end
	
	function GetPlayerMatchingGameId(id)
	
		assert(type(id) == "number")
		if id > 0 and id <= #kDAKGameID then
			local client = kDAKGameID[id]
			if client ~= nil and VerifyClient(client) ~= nil then
				return client:GetControllingPlayer()
			end
		end
		
		return nil
		
	end
	
	function GetClientMatchingGameId(id)
	
		assert(type(id) == "number")
		if id > 0 and id <= #kDAKGameID then
			local client = kDAKGameID[id]
			if client ~= nil and VerifyClient(client) ~= nil then
				return client
			end
		end
		
		return nil
		
	end
	
	function GetGameIdMatchingPlayer(player)
	
		local client = Server.GetOwner(player)
		if client ~= nil and VerifyClient(client) ~= nil then
			for p = 1, #kDAKGameID do
			
				if client == kDAKGameID[p] then
					return p
				end
				
			end
		end
		
		return 0
	end
	
	function GetGameIdMatchingClient(client)
	
		if client ~= nil and VerifyClient(client) ~= nil then
			for p = 1, #kDAKGameID do
			
				if client == kDAKGameID[p] then
					return p
				end
				
			end
		end
		
		return 0
	end
	
	function GetClientMatchingSteamId(steamId)

		assert(type(steamId) == "number")
		
		local playerList = EntityListToTable(Shared.GetEntitiesWithClassname("Player"))
		for r = #playerList, 1, -1 do
			if playerList[r] ~= nil then
				local plyr = playerList[r]
				local clnt = playerList[r]:GetClient()
				if plyr ~= nil and clnt ~= nil then
					if clnt:GetUserId() == steamId then
						return clnt
					end
				end
			end				
		end
		
		return nil
		
	end

	function ShufflePlayerList()
	
		local playerList = EntityListToTable(Shared.GetEntitiesWithClassname("Player"))
		local gamerules = GetGamerules()
		for i = 1, (#playerList) do
			r = math.random(1, #playerList)
			local iplayer = playerList[i]
			playerList[i] = playerList[r]
			playerList[r] = iplayer
		end
		return playerList
		
	end	
	
	//******************************************************************************************************************
	//Event Hooking
	//******************************************************************************************************************
	
	local function DAKOnClientConnected(client)
	
		if kDAKConfig and kDAKConfig.DAKLoader and kDAKConfig.DAKLoader.kEnabled then
			if client ~= nil and VerifyClient(client) ~= nil then
				table.insert(kDAKGameID, client)
				if #kDAKOnClientConnect > 0 then
					for i = 1, #kDAKOnClientConnect do
						if not kDAKOnClientConnect[i](client) then break end
					end
				end
				if kDAKConfig and kDAKConfig.DAKLoader and kDAKConfig.DAKLoader.kDelayedClientConnect then
					local CEntry = { Client = client, Time = Shared.GetTime() + kDAKConfig.DAKLoader.kDelayedClientConnect }
					table.insert(DelayedClientConnect, CEntry)
				end
			end
		end
	end

	Event.Hook("ClientConnect", DAKOnClientConnected)
	
	local function DAKOnClientDisconnected(client)
	
		if kDAKConfig and kDAKConfig.DAKLoader and kDAKConfig.DAKLoader.kEnabled then
			if client ~= nil and VerifyClient(client) ~= nil then
				if #DelayedClientConnect > 0 then
					for i = 1, #DelayedClientConnect do
						local PEntry = DelayedClientConnect[i]
						if PEntry ~= nil and PEntry.Client ~= nil then
							if client == PEntry.Client then
								DelayedClientConnect[i] = nil
								break
							end
						end
					end		
				end
				if #kDAKOnClientDisconnect > 0 then
					for i = 1, #kDAKOnClientDisconnect do
						if not kDAKOnClientDisconnect[i](client) then break end
					end
				end
			end
		end
		
	end

	Event.Hook("ClientDisconnect", DAKOnClientDisconnected)
	
	local function DAKUpdateServer(deltaTime)
	
		PROFILE("DAKLoader:DAKUpdateServer")
		
		if kDAKConfig and kDAKConfig.DAKLoader and kDAKConfig.DAKLoader.kEnabled then
			serverupdatetime = serverupdatetime + deltaTime
			if kDAKConfig.DAKLoader.kDelayedServerUpdate and serverupdatetime > kDAKConfig.DAKLoader.kDelayedServerUpdate then
			
				if #kDAKOnServerUpdate > 0 then
					for i = 1, #kDAKOnServerUpdate do
						kDAKOnServerUpdate[i](deltaTime)
					end
				end
				
				if #DelayedClientConnect > 0 then
					for i = #DelayedClientConnect, 1, -1 do
						local CEntry = DelayedClientConnect[i]
						if CEntry ~= nil and CEntry.Client ~= nil and VerifyClient(CEntry.Client) ~= nil then
							if CEntry.Time < Shared.GetTime() then
								if #kDAKOnClientDelayedConnect > 0 then
									for i = 1, #kDAKOnClientDelayedConnect do
										if not kDAKOnClientDelayedConnect[i](CEntry.Client) then
											break 
										end
									end
								end
								DelayedClientConnect[i] = nil
							end
						else
							DelayedClientConnect[i] = nil
						end
					end
				end
				
				//Print(string.format("%.5f Accuracy", (100 - math.abs(100 - ((serverupdatetime/1) * 100)))))
				serverupdatetime = serverupdatetime - kDAKConfig.DAKLoader.kDelayedServerUpdate
				
			end
			
			if DelayedServerCommands then
				if #DelayedServerAdminCommands > 0 then
					for i = 1, #DelayedServerAdminCommands do
						local ServerAdminCmd = DelayedServerAdminCommands[i]
						RegisterServerAdminCommand(ServerAdminCmd.cmdName, ServerAdminCmd.cmdFunction, ServerAdminCmd.helpT, ServerAdminCmd.opt)
					end
				end
				Shared.Message("Server Commands Registered")
				DelayedServerAdminCommands = nil
				DelayedServerCommands = false
			end
		end
		
	end	
	
	Event.Hook("UpdateServer", DAKUpdateServer)
	
	if kDAKConfig and kDAKConfig.DAKLoader and kDAKConfig.DAKLoader.GamerulesExtensions then
	
		//Creating another layer here so that compat can be maintained with any other mods that may hook this.
		class 'NS2DAKGamerules' (kDAKBaseGamerules)
		NS2DAKGamerules.kMapName = kDAKBaseGamerules.kMapName
		
		function NS2DAKGamerules:OnCreate()

			// Calls SetGamerules()
			kDAKBaseGamerules.OnCreate(self)
			
		end
		
		function NS2DAKGamerules:JoinTeam(player, newTeamNumber, force)
			local client = Server.GetOwner(player)
			if client ~= nil then
				if #kDAKOnTeamJoin > 0 then
					for i = 1, #kDAKOnTeamJoin do
						if not kDAKOnTeamJoin[i](player, newTeamNumber, force) then
							return false, player
						end
					end
				end
			end
			return kDAKBaseGamerules.JoinTeam(self, player, newTeamNumber, force)
		end
		
		function NS2DAKGamerules:EndGame(winningTeam)
		
			if #kDAKOnGameEnd > 0 then
				for i = 1, #kDAKOnGameEnd do
					kDAKOnGameEnd[i](winningTeam)
				end
			end
			kDAKBaseGamerules.EndGame(self, winningTeam)
			
		end
		
		function NS2DAKGamerules:OnEntityKilled(targetEntity, attacker, doer, point, direction)
		
			if attacker and targetEntity and doer then
				if #kDAKOnEntityKilled > 0 then
					for i = 1, #kDAKOnEntityKilled do
						kDAKOnEntityKilled[i](targetEntity, attacker, doer, point, direction)
					end
				end
			end
			kDAKBaseGamerules.OnEntityKilled(self, targetEntity, attacker, doer, point, direction)

		end
		
		function NS2DAKGamerules:UpdatePregame(timePassed)
		
			if #kDAKOnUpdatePregame > 0 then
				for i = 1, #kDAKOnUpdatePregame do
					if not kDAKOnUpdatePregame[i](timePassed) then
						return
					end
				end
			end
			kDAKBaseGamerules.UpdatePregame(self, timePassed)
			
		end	
		
		Shared.LinkClassToMap("NS2DAKGamerules", NS2DAKGamerules.kMapName, { })
					
		function DAKChatLogging(message, playerName, steamId, teamNumber, teamOnly)
			
			local client = GetClientMatchingSteamId(steamId)
			if #kDAKOnClientChatMessage > 0 then
				for i = 1, #kDAKOnClientChatMessage do
					kDAKOnClientChatMessage[i](message, playerName, steamId, teamNumber, teamOnly, client)
				end
			end

		end
		
	end
		
	if kDAKConfig and kDAKConfig.DAKLoader and kDAKConfig.DAKLoader.OverrideInterp and kDAKConfig.DAKLoader.OverrideInterp.kEnabled then
	
		local function SetInterpOnClientConnected(client)
			if kDAKConfig.DAKLoader.OverrideInterp.kEnabled then
				Shared.ConsoleCommand(string.format("interp %f", (kDAKConfig.DAKLoader.OverrideInterp.kInterp/1000)))
			end
			return true
		end

		table.insert(kDAKOnClientConnect, function(client) return SetInterpOnClientConnected() end)
		
	end
	
	//******************************************************************************************************************
	//Extra Server Admin commands
	//******************************************************************************************************************
	
	local function OnCommandLoadDAKConfig(client)
	
		if client ~= nil then
			LoadDAKConfig()
			Shared.Message(string.format("%s reloaded DAK config", client:GetUserId()))
			ServerAdminPrint(client, string.format("DAK Config reloaded."))
			PrintToAllAdmins("sv_reloadconfig", client)
		end
		
	end
	
	DAKCreateServerAdminCommand("Console_sv_reloadconfig", OnCommandLoadDAKConfig, "Will reload the configuration files.")
	
	local function OnCommandRCON(client, ...)
	
		 local rconcommand = StringConcatArgs(...)
		 if rconcommand ~= nil and client ~= nil then
			Shared.Message(string.format("%s executed command %s.", client:GetUserId(), rconcommand))
			Shared.ConsoleCommand(rconcommand)
			ServerAdminPrint(client, string.format("Command %s executed.", rconcommand))
			if client ~= nil then 
				local player = client:GetControllingPlayer()
				if player ~= nil then
					PrintToAllAdmins("sv_rcon", client, " " .. rconcommand)
				end
			end
		end
	
	end
	
	DAKCreateServerAdminCommand("Console_sv_rcon", OnCommandRCON, "<command>, Will execute specified command on server.")
	
	local function OnCommandListPlugins(client)
	
		if client ~= nil and kDAKConfig then
			for k,v in pairs(kDAKConfig) do
				local plugin = k
				local version = kDAKRevisions[plugin]
				if version == nil then version = 1 end
				if plugin ~= nil then
					if v.kEnabled then
						ServerAdminPrint(client, string.format("Plugin %s v%.1f is enabled.", plugin, version))
						//Shared.Message(string.format("Plugin %s v%.1f is enabled.", plugin, version))
					else
						ServerAdminPrint(client, string.format("Plugin %s is disabled.", plugin))
						//Shared.Message(string.format("Plugin %s is disabled.", plugin))
					end
				end
			end
		end
	
	end
	
	DAKCreateServerAdminCommand("Console_sv_listplugins", OnCommandListPlugins, "Will list the state of all plugins.")	
	
	local function OnCommandListMap(client)
		local matchingFiles = { }
		Shared.GetMatchingFileNames("maps/*.level", false, matchingFiles)

		for _, mapFile in pairs(matchingFiles) do
			local _, _, filename = string.find(mapFile, "maps/(.*).level")
			if client ~= nil then
				ServerAdminPrint(client, string.format(filename))
			end		
		end
	end

    DAKCreateServerAdminCommand("Console_sv_maps", OnCommandListMap, "Will list all the maps currently on the server.")
	
	local function OnCommandCheats(client, parm)
		local num = tonumber(parm)
		if client ~= nil and num ~= nil then
			ServerAdminPrint(client, string.format("Command sv_cheats %s executed.", parm))
			Shared.ConsoleCommand("cheats " .. parm)
			local player = client:GetControllingPlayer()
			if player ~= nil then
				PrintToAllAdmins("sv_cheats", client, " " .. parm)
			end
		end
	end

    DAKCreateServerAdminCommand("Console_sv_cheats", OnCommandCheats, "<1/0> Will enable/disable cheats.")
	
	local function OnCommandDefaultPluginConfig(client, plugin)
		if client ~= nil and plugin ~= nil then
			ServerAdminPrint(client, string.format("Defaulting %s config", plugin))
			GenerateDefaultDAKConfig(plugin)
			local player = client:GetControllingPlayer()
			if player ~= nil then
				PrintToAllAdmins("sv_defaultconfig", client, plugin)
			end
		end
	end

    DAKCreateServerAdminCommand("Console_sv_defaultconfig", OnCommandDefaultPluginConfig, "<Plugin Name> Will list all the maps currently on the server.")
	
	local function OnCommandListAdmins(client)
	
		if settings ~= nil then
			if settings.groups ~= nil then
				for group, commands in pairs(settings.groups) do
					if client ~= nil then
						ServerAdminPrint(client, string.format(group .. " - " .. ToString(commands)))
					end		
				end
			end
	
			if settings.users ~= nil then
				for name, user in pairs(settings.users) do
					if client ~= nil then
						ServerAdminPrint(client, string.format(name .. " - " .. ToString(user)))
					end		
				end
			end
		end
		
	end

    DAKCreateServerAdminCommand("Console_sv_listadmins", OnCommandListAdmins, "Will list all groups and admins.")	
	
	local function OnCommandKillServer(client)
		if client ~= nil then 
			ServerAdminPrint(client, string.format("Command sv_killserver executed."))
			local player = client:GetControllingPlayer()
			if player ~= nil then
				PrintToAllAdmins("sv_killserver", client)
			end
		end
		//No need for this durrrrr, server supports exit
		Shared.ConsoleCommand("exit")
	end

    DAKCreateServerAdminCommand("Console_sv_killserver", OnCommandKillServer, "Will crash the server (lol).")
	
	//Load Plugins
	local function LoadPlugins()
		local matchingFiles = { }
		Shared.GetMatchingFileNames("lua/plugins/*.lua", false, matchingFiles)
		for _, pFile in pairs(matchingFiles) do
			local _, _, filename = string.find(pFile, "lua/plugins/(.*).lua")
			if string.sub(filename, 1, 6) == "plugin" then
				Shared.Message("Loading " .. string.format(filename))
				Script.Load(pFile)
			end
		end
	end
	
	LoadPlugins()
	
	DAKCreateServerAdminCommand("Console_sv_reloadplugins", LoadPlugins, "Reloads all plugins.")
	
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
			Server.StartWorld(ServerMods.mods, mapName)
		end
		
	end

	Event.Hook("Console_changemap", OnCommandChangeMap)
	Event.Hook("Console_cyclemap", OnCommandCycleMap)
	
end