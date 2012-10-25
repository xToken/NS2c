//baseadmincommands default config

kDAKRevisions["BaseAdminCommands"] = 1.1
local function SetupDefaultConfig()
	kDAKConfig.BaseAdminCommands = { }
	kDAKConfig.BaseAdminCommands.kEnabled = true
	SaveDAKConfig()
end

table.insert(kDAKPluginDefaultConfigs, {PluginName = "BaseAdminCommands", DefaultConfig = function() SetupDefaultConfig() end })

if kDAKConfig.BaseAdminCommands == nil then
	SetupDefaultConfig()
end
