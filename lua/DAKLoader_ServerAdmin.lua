//DAK Loader/Base Config

if Server then
	
	local settings = { groups = { }, users = { } }
	
	local DAKServerAdminFileName = "config://ServerAdmin.json"
	local DelayedServerAdminCommands = { }
	local DelayedServerCommands = false
		
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
	
	//Internal Globals
	function DAKCreateServerAdminCommand(commandName, commandFunction, helpText, optionalAlwaysAllowed)
		local ServerAdminCmd = { cmdName = commandName, cmdFunction = commandFunction, helpT = helpText, opt = optionalAlwaysAllowed }
		table.insert(DelayedServerAdminCommands, ServerAdminCmd)
		DelayedServerCommands = true
	end
	
	function RegisterServerAdminCommand(commandName, commandFunction, helpText, optionalAlwaysAllowed)
		if kDAKConfig and kDAKConfig.BaseAdminCommands and kDAKConfig.BaseAdminCommands.kEnabled then
			CreateBaseServerAdminCommand(commandName, commandFunction, helpText, optionalAlwaysAllowed)
		else
			CreateServerAdminCommand(commandName, commandFunction, helpText, optionalAlwaysAllowed)
		end
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
	
	local function DelayedServerCommandRegistration()	
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
	
	table.insert(kDAKOnServerUpdate, function(deltatime) return DelayedServerCommandRegistration() end)
	
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
	
end