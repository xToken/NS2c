//DAK Loader/Base Config

if Server then

	kCheckGameDirectory = false
	
	//Load base NS2 Scripts
	Script.Load("lua/Server.lua")
	Script.Load("lua/dkjson.lua")

	kDAKConfig = nil //Global variable storing all configuration items for mods
	kDAKSettings = nil //Global variable storing all settings for mods
	kDAKRevisions = { }
	kDAKGameID = { }
	kDAKOnClientConnect = { }
	kDAKOnClientDisconnect = { }
	kDAKOnServerUpdate = { }
	kDAKOnClientDelayedConnect = { }
	kDAKServerAdminCommands = { }
	
	local settings = { groups = { }, users = { } }
	local ServerAdminPath = Server.GetAdminPath()
	local DAKConfigFileName = "DAKConfig.json"
	local DAKSettingsFileName = "DAKSettings.json"
	local serverAdminFileName = "DAKServerAdmin.json"
	local DelayedClientConnect = { }
	local lastserverupdate = 0
	local DAKRevision = 1.2
		
    local function LoadServerAdminSettings()
    
        Shared.Message("Loading " .. "user://" .. ServerAdminPath .. serverAdminFileName)
        
        local initialState = { groups = { }, users = { } }
        settings = initialState
        
		local settingsFile
		if kCheckGameDirectory then
			settingsFile = io.open("game://" .. ServerAdminPath .. serverAdminFileName, "r")
		else
			settingsFile = io.open("user://" .. ServerAdminPath .. serverAdminFileName, "r")
		end
        if settingsFile then
        
            local fileContents = settingsFile:read("*all")
            settings = json.decode(fileContents) or initialState
            
        end
        
        assert(settings.groups, "groups must be defined in " .. serverAdminFileName)
        assert(settings.users, "users must be defined in " .. serverAdminFileName)
        
    end
	
    LoadServerAdminSettings()
    
    function GetGroupCanRunCommand(groupName, commandName)
    
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
    
    function GetClientCanRunCommand(client, commandName)
    
        // Convert to the old Steam Id format.
        local steamId = client:GetUserId()
        for name, user in pairs(settings.users) do
        
            if user.id == steamId then
            
                for g = 1, #user.groups do
                
                    local groupName = user.groups[g]
                    if GetGroupCanRunCommand(groupName, commandName) then
                        return true
                    end
                    
                end
                
            end
            
        end

        return false
        
    end
		
	local function DisableAllPlugins()
	
		kDAKConfig = { }
		table.insert(kDAKConfig,_MOTD)
		kDAKConfig._MOTD = false
		
		table.insert(kDAKConfig,_ReservedSlots)
		kDAKConfig._ReservedSlots = false
		
		table.insert(kDAKConfig,_VoteRandom)
		kDAKConfig._VoteRandom = false
		
		table.insert(kDAKConfig,_TournamentMode)
		kDAKConfig._TournamentMode = false
		
		table.insert(kDAKConfig,_MapVote)
		kDAKConfig._MapVote = false
		
		table.insert(kDAKConfig,_OverrideInterp)
		kDAKConfig._OverrideInterp = false
		
		table.insert(kDAKConfig,_EnhancedLogging)
		kDAKConfig._EnhancedLogging = false
		
		table.insert(kDAKConfig,kDelayedClientConnect)
		table.insert(kDAKConfig,kDelayedServerUpdate)
		kDAKConfig.kDelayedClientConnect = 2
		kDAKConfig.kDelayedServerUpdate = 1
	
	end
	
	local function LoadDAKConfig()
		local DAKConfigFile
		if kCheckGameDirectory then
			DAKConfigFile = io.open("game://" .. ServerAdminPath .. DAKConfigFileName, "r")
		else
			DAKConfigFile = io.open("user://" .. ServerAdminPath .. DAKConfigFileName, "r")
		end
		if DAKConfigFile then
			Shared.Message("Loading DAK configuration.")
			kDAKConfig = json.decode(DAKConfigFile:read("*all"))
			DAKConfigFile:close()
		end
		if kDAKConfig == nil then
			DisableAllPlugins()
		end
	end
	
	LoadDAKConfig()
	
	local function LoadDAKSettings()
		local DAKSettingsFile
		DAKSettingsFile = io.open("user://" .. ServerAdminPath .. DAKSettingsFileName, "r")
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
	
		local DAKSettingsFile = io.open("user://" .. ServerAdminPath .. DAKSettingsFileName, "w+")
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
	
		if kDAKConfig._EnhancedLogging then
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
	
		if kDAKConfig._EnhancedLogging then
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
			local CEntry = { Client = client, Time = Shared.GetTime() + kDAKConfig.kDelayedClientConnect }
			table.insert(DelayedClientConnect, CEntry)
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
		
		if lastserverupdate == nil or lastserverupdate < Shared.GetTime() then
		
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
		
	if kDAKConfig._OverrideInterp then
	
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
	
	CreateServerAdminCommand("Console_sv_reloadconfig", OnCommandLoadDAKConfig, "Will reload the configuration files.")
	
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
	
	CreateServerAdminCommand("Console_sv_rcon", OnCommandRCON, "<command>, Will execute specified command on server.")
	
	local function OnCommandListPlugins(client)
	
		if client ~= nil and kDAKConfig ~= nil then
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
	
	CreateServerAdminCommand("Console_sv_plugins", OnCommandListPlugins, "Will list the state of all plugins.")	
	
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

    CreateServerAdminCommand("Console_sv_maps", OnCommandListMap, "Will list all the maps currently on the server.")
	
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

    CreateServerAdminCommand("Console_sv_listadmins", OnCommandListAdmins, "Will list all groups and admins.")	
	
	local function OnCommandKillServer(client)
		if client ~= nil then 
			ServerAdminPrint(client, string.format("Command sv_killserver executed."))
			local player = client:GetControllingPlayer()
			if player ~= nil then
				PrintToAllAdmins("sv_killserver", client)
			end
		end
		CRASHFILE = io.open("user://" .. ServerAdminPath .. "CRASHFILE", "w")
		if CRASHFILE then
			CRASHFILE:seek("end")
			CRASHFILE:write("\n CRASH")
			CRASHFILE:close()
		end
	end

    CreateServerAdminCommand("Console_sv_killserver", OnCommandKillServer, "Will crash the server (lol).")
	
	//Load Plugins
	
	if kDAKConfig._EnhancedLogging then
		//EnhancedLogging
		Script.Load("lua/EnhancedLogging.lua")
	end
	
	if kDAKConfig._ReservedSlots then
		//ReservedSlots
		Script.Load("lua/ReservedSlots.lua")
	end
	
	if kDAKConfig._VoteRandom then
		//VoteRandom
		Script.Load("lua/VoteRandom.lua")
	end
	
	if kDAKConfig._AFKKicker then
		//AFKKicker
		Script.Load("lua/AFKKick.lua")
	end
	
	if kDAKConfig._MapVote then
		//MapVote
		Script.Load("lua/MapVote.lua")
	end
	
	if kDAKConfig._TournamentMode then
		//TournamentMode
		Script.Load("lua/TournamentMode.lua")
	end
	
	if kDAKConfig._MOTD then
		//MOTD
		Script.Load("lua/MOTD.lua")
	end
	
	//FirstPersonSpectator
	//Script.Load("lua/FirstPersonSpectator.lua")
	
end