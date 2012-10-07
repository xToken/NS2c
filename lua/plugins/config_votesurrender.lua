//reservedslots config

kDAKRevisions["VoteSurrender"] = 1.2
local function SetupDefaultConfig()
	kDAKConfig.VoteSurrender = { }
	kDAKConfig.VoteSurrender.kEnabled = true
	kDAKConfig.VoteSurrender.kVoteSurrenderMinimumPercentage = 60
	kDAKConfig.VoteSurrender.kVoteSurrenderVotingTime = 120
	kDAKConfig.VoteSurrender.kVoteSurrenderAlertDelay = 20
end

table.insert(kDAKPluginDefaultConfigs, {PluginName = "VoteSurrender", DefaultConfig = function() SetupDefaultConfig() end })