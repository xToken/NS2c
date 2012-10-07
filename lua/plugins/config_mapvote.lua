//mapvote config

kDAKRevisions["MapVote"] = 1.7
local function SetupDefaultConfig()
	kDAKConfig.MapVote = { }
	kDAKConfig.MapVote.kEnabled = true
	kDAKConfig.MapVote.kVoteStartDelay = 8
	kDAKConfig.MapVote.kVotingDuration = 30
	kDAKConfig.MapVote.kMapsToSelect = 7
	kDAKConfig.MapVote.kDontRepeatFor = 4
	kDAKConfig.MapVote.kVoteNotifyDelay = 6
	kDAKConfig.MapVote.kVoteChangeDelay = 4
	kDAKConfig.MapVote.kVoteMinimumPercentage = 25
	kDAKConfig.MapVote.kRTVMinimumPercentage = 50
	kDAKConfig.MapVote.kVoteMapBeginning = "******                 Map vote will begin in %s seconds.                 ******"
	kDAKConfig.MapVote.kVoteMapHowToVote = "******     You can vote for the map you want by typing vote #     ******"
	kDAKConfig.MapVote.kVoteMapStarted = "*******            Map vote has begun. (%s%% votes needed to win)           ******"
	kDAKConfig.MapVote.kVoteMapMapListing = "******                vote %s for %s                                       "
	kDAKConfig.MapVote.kVoteMapNoWinner = "******               Voting has ended, no map won.                             "
	kDAKConfig.MapVote.kVoteMapTie = "******  Voting has ended with a tie, A new vote will start in %s seconds  ******"
	kDAKConfig.MapVote.kVoteMapWinner = "******     Voting has ended, %s won with %s votes.                           "
	kDAKConfig.MapVote.kVoteMapMinimumNotMet = "******%s had the most votes with %s, but the minimum required is %s.******"
	kDAKConfig.MapVote.kVoteMapTimeLeft = "******                      %.1f seconds are left to vote                   ******"
	kDAKConfig.MapVote.kVoteMapCurrentMapVotes = "******      %s votes for %s (to vote, type vote %s)   ******"
	kDAKConfig.MapVote.kVoteMapRockTheVote = "%s rock'd the vote. (%s votes, needed %s)."
	kDAKConfig.MapVote.kVoteMapCancelled = "******           Map vote has been cancelled.         ******"
	kDAKConfig.MapVote.kVoteMapInsufficientMaps = "******           Not enough maps for a vote.         ******"
end

table.insert(kDAKPluginDefaultConfigs, {PluginName = "MapVote", DefaultConfig = function() SetupDefaultConfig() end })
