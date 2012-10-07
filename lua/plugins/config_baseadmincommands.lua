//baseadmincommands default config

kDAKRevisions["BaseAdminCommands"] = 1.1
local function SetupDefaultConfig()
	kDAKConfig.BaseAdminCommands = { }
	kDAKConfig.BaseAdminCommands.kEnabled = true
end

table.insert(kDAKPluginDefaultConfigs, {PluginName = "BaseAdminCommands", DefaultConfig = function() SetupDefaultConfig() end })