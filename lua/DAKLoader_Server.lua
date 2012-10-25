//DAK Loader/Base Config

if Server then
	
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
	
	Script.Load("lua/dkjson.lua")
	Script.Load("lua/DAKLoader_ServerAdmin.lua")
	Script.Load("lua/DAKLoader_Config.lua")
	Script.Load("lua/DAKLoader_Settings.lua")
	Script.Load("lua/DAKLoader_MapCycle.lua")
	Script.Load("lua/Class.lua")
	
	local DelayedClientConnect = { }
	local serverupdatetime = 0
	kDAKRevisions["DAKLoader"] = 2.0
	
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

	function DAKCreateGUIVoteBase(OnVoteFunction, OnVoteUpdateFunction, Relevancy)
		if kDAKConfig and kDAKConfig.GUIVoteBase and kDAKConfig.GUIVoteBase.kEnabled then
			return CreateGUIVoteBase(OnVoteFunction, OnVoteUpdateFunction, Relevancy)
		end
		return false
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
			
		end
		
	end	
	
	Event.Hook("UpdateServer", DAKUpdateServer)
	
	if kDAKConfig and kDAKConfig.DAKLoader and kDAKConfig.DAKLoader.GamerulesExtensions then
	
		if kDAKConfig.DAKLoader.GamerulesClassName == nil then kDAKConfig.DAKLoader.GamerulesClassName = "NS2Gamerules" end
			
		local originalNS2GRJoinTeam
		
		originalNS2GRJoinTeam = Class_ReplaceMethod(kDAKConfig.DAKLoader.GamerulesClassName, "JoinTeam", 
			function(self, player, newTeamNumber, force)
			
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
				return originalNS2GRJoinTeam(self, player, newTeamNumber, force)

			end
		)
		
		local originalNS2GREndGame
		
		originalNS2GREndGame = Class_ReplaceMethod(kDAKConfig.DAKLoader.GamerulesClassName, "EndGame", 
			function(self, winningTeam)
				if #kDAKOnGameEnd > 0 then
					for i = 1, #kDAKOnGameEnd do
						kDAKOnGameEnd[i](winningTeam)
					end
				end
				originalNS2GREndGame(self, winningTeam)
			end
		)
		
		local originalNS2GREntityKilled
		
		originalNS2GREntityKilled = Class_ReplaceMethod(kDAKConfig.DAKLoader.GamerulesClassName, "OnEntityKilled", 
			function(self, targetEntity, attacker, doer, point, direction)
			
				if attacker and targetEntity and doer then
					if #kDAKOnEntityKilled > 0 then
						for i = 1, #kDAKOnEntityKilled do
							kDAKOnEntityKilled[i](targetEntity, attacker, doer, point, direction)
						end
					end
				end
				originalNS2GREntityKilled(self, targetEntity, attacker, doer, point, direction)
			
			end
		)
		
		local originalNS2GRUpdatePregame
		
		originalNS2GRUpdatePregame = Class_ReplaceMethod(kDAKConfig.DAKLoader.GamerulesClassName, "UpdatePregame", 
			function(self, timePassed)

				if #kDAKOnUpdatePregame > 0 then
					for i = 1, #kDAKOnUpdatePregame do
						if not kDAKOnUpdatePregame[i](timePassed) then
							return
						end
					end
				end
				originalNS2GRUpdatePregame(self, timePassed)
			
			end
		)

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
	
	local function OnCommandKillServer(client)
		if client ~= nil then 
			ServerAdminPrint(client, string.format("Command sv_killserver executed."))
			local player = client:GetControllingPlayer()
			if player ~= nil then
				PrintToAllAdmins("sv_killserver", client)
			end
		end
		//No need for this durrrrr, server supports exit
		//Shared.ConsoleCommand("exit") I wish :<
		CRASHFILE = io.open("config://CRASHFILE", "w")
		if CRASHFILE then
			CRASHFILE:seek("end")
			CRASHFILE:write("\n CRASH")
			CRASHFILE:close()
		end
	end

    DAKCreateServerAdminCommand("Console_sv_killserver", OnCommandKillServer, "Will crash the server (lol).")
	
	//Load Plugins
	local function LoadPlugins()
		if kDAKConfig == nil or kDAKConfig == { } or kDAKConfig.DAKLoader == nil or kDAKConfig.DAKLoader == { } or kDAKConfig.DAKLoader.kPluginsList == nil then
			DAKGenerateDefaultDAKConfig(true)
		end
		if kDAKConfig ~= nil and kDAKConfig.DAKLoader ~= nil  then
			for i = 1, #kDAKConfig.DAKLoader.kPluginsList do
				local filename = string.format("lua/plugins/plugin_%s.lua", kDAKConfig.DAKLoader.kPluginsList[i])
				Script.Load(filename)
			end
		else
			Shared.Message("Something may be wrong with your config file.")
		end
	end
	
	LoadPlugins()
	
	DAKCreateServerAdminCommand("Console_sv_reloadplugins", LoadPlugins, "Reloads all plugins.")
	
end