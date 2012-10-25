//DAK Loader/Base Config

if Server then

	local DAKConfigFileName = "config://DAKConfig.json"
	
	local function LoadDAKConfig()
		local DAKConfigFile = io.open(DAKConfigFileName, "r")
		if DAKConfigFile then
			Shared.Message("Loading DAK configuration.")
			kDAKConfig = json.decode(DAKConfigFile:read("*all"))
			DAKConfigFile:close()
		end
	end
	
	LoadDAKConfig()
	
	function SaveDAKConfig()
		//Write config to file
		local configFile = io.open(DAKConfigFileName, "w+")
		configFile:write(json.encode(kDAKConfig, { indent = true, level = 1 }))
		io.close(configFile)
	end
	
	local function GenerateDefaultDAKConfig(Plugin)
	
		if kDAKConfig == nil then
			kDAKConfig = { }
		end
		
		if Plugin == "DAKLoader" or Plugin == "ALL" then
			//Base DAK Config
			kDAKConfig.DAKLoader = { }
			kDAKConfig.DAKLoader.kDelayedClientConnect = 2
			kDAKConfig.DAKLoader.kDelayedServerUpdate = 1
			kDAKConfig.DAKLoader.kPluginsList = { "afkkick", "baseadmincommands", "enhancedlogging", "mapvote", "motd", "reservedslots",
													"tournamentmode", "unstuck", "voterandom", "votesurrender" }
			kDAKConfig.DAKLoader.GamerulesExtensions = true
			kDAKConfig.DAKLoader.GamerulesClassName = "NS2Gamerules"
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
		
		SaveDAKConfig()
		
	end
	
	local function LoadDAKPluginConfigs()
	
		if kDAKConfig == nil or kDAKConfig == { } then
			GenerateDefaultDAKConfig("DAKLoader")
		end
		
		if kDAKConfig and kDAKConfig.DAKLoader and kDAKConfig.DAKLoader.kPluginsList then
			for i = 1, #kDAKConfig.DAKLoader.kPluginsList do
				local plugin = kDAKConfig.DAKLoader.kPluginsList[i]
				local filename = string.format("lua/plugins/config_%s.lua", plugin)
				Script.Load(filename)
			end
		end
		
	end
	
	LoadDAKPluginConfigs()
	
	function DAKGenerateDefaultDAKConfig(Plugin)
		GenerateDefaultDAKConfig(Plugin)
	end
	
	local function OnCommandLoadDAKConfig(client)
	
		if client ~= nil then
			LoadDAKConfig()
			Shared.Message(string.format("%s reloaded DAK config", client:GetUserId()))
			ServerAdminPrint(client, string.format("DAK Config reloaded."))
			PrintToAllAdmins("sv_reloadconfig", client)
		end
		
	end
	
	DAKCreateServerAdminCommand("Console_sv_reloadconfig", OnCommandLoadDAKConfig, "Will reload the configuration files.")
	
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
	
end