//enhanced logging default config

kDAKRevisions["EnhancedLogging"] = 1.6
local function SetupDefaultConfig()
	kDAKConfig.EnhancedLogging = { }
	kDAKConfig.EnhancedLogging.kEnabled = true
	kDAKConfig.EnhancedLogging.kEnhancedLoggingSubDir = "Logs"
end

table.insert(kDAKPluginDefaultConfigs, {PluginName = "EnhancedLogging", DefaultConfig = function() SetupDefaultConfig() end })