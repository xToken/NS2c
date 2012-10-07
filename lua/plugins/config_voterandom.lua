//reservedslots config

kDAKRevisions["VoteRandom"] = 1.6
local function SetupDefaultConfig()
	kDAKConfig.VoteRandom = { }
	kDAKConfig.VoteRandom.kEnabled = true
	kDAKConfig.VoteRandom.kVoteRandomInstantly = false
	kDAKConfig.VoteRandom.kVoteRandomDuration = 30
	kDAKConfig.VoteRandom.kVoteRandomMinimumPercentage = 60
	kDAKConfig.VoteRandom.kVoteRandomEnabled = "Random teams have been enabled, the round will restart."
	kDAKConfig.VoteRandom.kVoteRandomEnabledDuration = "Random teams have been enabled for the next %s Minutes"
	kDAKConfig.VoteRandom.kVoteRandomConnectAlert = "Random teams are enabled, you are being randomed to a team."
	kDAKConfig.VoteRandom.kVoteRandomVoteCountAlert = "%s voted for random teams. (%s votes, needed %s)."
end

table.insert(kDAKPluginDefaultConfigs, {PluginName = "VoteRandom", DefaultConfig = function() SetupDefaultConfig() end })