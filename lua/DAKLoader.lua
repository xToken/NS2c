//DAK Loader/Base Config

if Server then
	
	//Load base NS2 Scripts
	Script.Load("lua/Server.lua")
	Script.Load("lua/dkjson.lua")

	kDAKConfig = nil 						//Global variable storing all configuration items for mods
	kDAKSettings = nil 						//Global variable storing all settings for mods
	kDAKRevisions = { }						//List used to track revisions of plugins
	kDAKGameID = { }						//List of clients on connect for GameID
	kDAKOnClientConnect = { }				//Functions run on Client Connect
	kDAKOnClientDisconnect = { }			//Functions run on Client Disconnect
	kDAKOnServerUpdate = { }				//Functions run on ServerUpdate
	kDAKOnClientDelayedConnect = { }		//Functions run on DelayedClientConnect
	kDAKOnTeamJoin = { }					//Functions run on Teamjoin from Gamerules
	kDAKOnGameEnd = { }						//Functions run on GameEnd from Gamerules
	kDAKOnEntityKilled = { }				//Functions run on EntityKilled from Gamerules
	kDAKOnUpdatePregame = { }				//Functions run on UpdatePregame from Gamerules
	kDAKOnClientChatMessage = { }			//Functions run on ChatMessages
	kDAKServerAdminCommands = { }			//List of ServerAdmin Commands
	kDAKBaseGamerules = NS2Gamerules
	
	local settings = { groups = { }, users = { } }
	
	local DAKConfigFileName = "config://DAKConfig.json"
	local DAKSettingsFileName = "config://DAKSettings.json"
	local DAKServerAdminFileName = "config://DAKServerAdmin.json"
	local DelayedClientConnect = { }
	local lastserverupdate = 0
	local DAKRevision = 1.6
		
    local function LoadServerAdminSettings()
    
        Shared.Message("Loading " .. DAKServerAdminFileName)
        
        local initialState = { groups = { }, users = { } }
        settings = initialState
        
		local settingsFile = io.open(DAKServerAdminFileName, "r")
        if settingsFile then
        
            local fileContents = settingsFile:read("*all")
            settings = json.decode(fileContents) or initialState
            
        end
        
        assert(settings.groups, "groups must be defined in " .. DAKServerAdminFileName)
        assert(settings.users, "users must be defined in " .. DAKServerAdminFileName)
        
    end
	
    LoadServerAdminSettings()
    
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
		
	local function DisableAllPlugins()	
		kDAKConfig = nil
	end
	
	local function LoadDAKConfig()
		local DAKConfigFile = io.open(DAKConfigFileName, "r")
		if DAKConfigFile then
			Shared.Message("Loading DAK configuration.")
			kDAKConfig = json.decode(DAKConfigFile:read("*all"))
			DAKConfigFile:close()
		end
		if kDAKConfig == nil or kDAKConfig == { } then
			DisableAllPlugins()
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
			DAKSettingsFile:write(json.encode(kDAKSettings))
			DAKSettingsFile:close()
		end
	
	end
	
	Script.Load("lua/BaseAdminCommands.lua")
	
	//*****************************************************************************************************************
	//Globals
	//*****************************************************************************************************************
	
	function EnhancedLog(message)
	
		if kDAKConfig and kDAKConfig._EnhancedLogging then
			EnhancedLogMessage(message)
		end
	
	end
	
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
	
	function PrintToAllAdmins(commandname, client, parm1)
	
		if kDAKConfig and kDAKConfig._EnhancedLogging then
			EnhancedLoggingAllAdmins(commandname, client, parm1)
		end
	
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
	
		if client ~= nil and VerifyClient(client) ~= nil then
			table.insert(kDAKGameID, client)
			if #kDAKOnClientConnect > 0 then
				for i = 1, #kDAKOnClientConnect do
					if not kDAKOnClientConnect[i](client) then break end
				end
			end
			if kDAKConfig and kDAKConfig.kDelayedClientConnect then
				local CEntry = { Client = client, Time = Shared.GetTime() + kDAKConfig.kDelayedClientConnect }
				table.insert(DelayedClientConnect, CEntry)
			end
		end
		
	end

	Event.Hook("ClientConnect", DAKOnClientConnected)
	
	local function DAKOnClientDisconnected(client)
	
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

	Event.Hook("ClientDisconnect", DAKOnClientDisconnected)
	
	local function DAKUpdateServer(deltaTime)
	
		PROFILE("DAKLoader:DAKUpdateServer")
		
		if kDAKConfig and kDAKConfig.kDelayedServerUpdate and (lastserverupdate == nil or lastserverupdate < Shared.GetTime()) then
		
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
			
			lastserverupdate = Shared.GetTime() + kDAKConfig.kDelayedServerUpdate
			
		end
	
	end	
	
	Event.Hook("UpdateServer", DAKUpdateServer)
	
	if kDAKConfig and kDAKConfig._GamerulesExtensions then
	
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
						kDAKOnTeamJoin[i](player, newTeamNumber, force)
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
					
		function Server.AddChatToHistory(message, playerName, steamId, teamNumber, teamOnly)
			
			local client = GetClientMatchingSteamId(steamId)
			if #kDAKOnClientChatMessage > 0 then
				for i = 1, #kDAKOnClientChatMessage do
					kDAKOnClientChatMessage[i](message, playerName, steamId, teamNumber, teamOnly, client)
				end
			end
			if chatMessageCount == nil then chatMessageCount = 0 end
			chatMessageCount = chatMessageCount + 1
			Server.recentChatMessages:Insert({ id = chatMessageCount, message = message, player = playerName,
											   steamId = steamId, team = teamNumber, teamOnly = teamOnly })

		end
		
	end
		
	if kDAKConfig and kDAKConfig._OverrideInterp then
	
		local function SetInterpOnClientConnected(client)
			if kDAKConfig._OverrideInterp then
				Shared.ConsoleCommand(string.format("interp %f", (kDAKConfig.kInterp/1000)))
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
			ServerAdminPrint(client, string.format("DAK Loader v%.1f.", DAKRevision))
			for k,v in pairs(kDAKConfig) do
				if string.find(k,"_") then
					local plugin = string.gsub(k, "_", "")
					local version = kDAKRevisions[plugin]
					if version == nil then version = 1 end
					if plugin ~= nil then
						if v then
							ServerAdminPrint(client, string.format("Plugin %s v%.1f is enabled.", plugin, version))
						else
							ServerAdminPrint(client, string.format("Plugin %s is disabled.", plugin))
						end
					end
				end
			end
		end
	
	end
	
	DAKCreateServerAdminCommand("Console_sv_plugins", OnCommandListPlugins, "Will list the state of all plugins.")	
	
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
		CRASHFILE = io.open("config://CRASHFILE", "w")
		if CRASHFILE then
			CRASHFILE:seek("end")
			CRASHFILE:write("\n CRASH")
			CRASHFILE:close()
		end
	end

    DAKCreateServerAdminCommand("Console_sv_killserver", OnCommandKillServer, "Will crash the server (lol).")
	
	//Load Plugins
	
	if kDAKConfig and kDAKConfig._EnhancedLogging then
		//EnhancedLogging
		Script.Load("lua/EnhancedLogging.lua")
	end
	
	if kDAKConfig and kDAKConfig._ReservedSlots then
		//ReservedSlots
		Script.Load("lua/ReservedSlots.lua")
	end
	
	if kDAKConfig and kDAKConfig._VoteRandom then
		//VoteRandom
		Script.Load("lua/VoteRandom.lua")
	end
	
	if kDAKConfig and kDAKConfig._AFKKicker then
		//AFKKicker
		Script.Load("lua/AFKKick.lua")
	end
	
	if kDAKConfig and kDAKConfig._MapVote then
		//MapVote
		Script.Load("lua/MapVote.lua")
	end
	
	if kDAKConfig and kDAKConfig._VoteSurrender then
		//VoteSurrender
		Script.Load("lua/VoteSurrender.lua")
	end
	
	if kDAKConfig and kDAKConfig._TournamentMode then
		//TournamentMode
		Script.Load("lua/TournamentMode.lua")
	end
	
	if kDAKConfig and kDAKConfig._MOTD then
		//MOTD
		Script.Load("lua/MOTD.lua")
	end
	
end