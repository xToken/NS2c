//GUIVoteBase config

kDAKRevisions["GUIVoteBase"] = 1.0

local function SetupDefaultConfig()
	kDAKConfig.GUIVoteBase = { }
	kDAKConfig.GUIVoteBase.kEnabled = false
	kDAKConfig.GUIVoteBase.kVoteUpdateRate = 2
	SaveDAKConfig()
end

table.insert(kDAKPluginDefaultConfigs, {PluginName = "GUIVoteBase", DefaultConfig = function() SetupDefaultConfig() end })

if kDAKConfig.GUIVoteBase == nil then
	SetupDefaultConfig()
end