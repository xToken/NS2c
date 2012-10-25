//unstuck config

kDAKRevisions["Unstuck"] = 1.0
local function SetupDefaultConfig()
	kDAKConfig.Unstuck = { }
	kDAKConfig.Unstuck.kEnabled = true
	kDAKConfig.Unstuck.kMinimumWaitTime = 5
	kDAKConfig.Unstuck.kTimeBetweenUntucks = 30
	SaveDAKConfig()
end

table.insert(kDAKPluginDefaultConfigs, {PluginName = "Unstuck", DefaultConfig = function() SetupDefaultConfig() end })

if kDAKConfig.Unstuck == nil then
	SetupDefaultConfig()
end
