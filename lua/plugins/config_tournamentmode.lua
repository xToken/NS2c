//reservedslots config

kDAKRevisions["TournamentMode"] = 2.6
local function SetupDefaultConfig()
	kDAKConfig.TournamentMode = { }
	kDAKConfig.TournamentMode.kEnabled = false
	kDAKConfig.TournamentMode.kTournamentModePubMode = false
	kDAKConfig.TournamentMode.kTournamentModePubMinPlayers = 3
	kDAKConfig.TournamentMode.kTournamentModePubPlayerWarning = "Game will start once each team has %s players."
	kDAKConfig.TournamentMode.kTournamentModePubAlertDelay = 30
	kDAKConfig.TournamentMode.kTournamentModeReadyDelay = 2
	kDAKConfig.TournamentMode.kTournamentModeGameStartDelay = 15
	kDAKConfig.TournamentMode.kTournamentModeCountdown = "Game will start in %s seconds!"
	SaveDAKConfig()
end

table.insert(kDAKPluginDefaultConfigs, {PluginName = "TournamentMode", DefaultConfig = function() SetupDefaultConfig() end })

if kDAKConfig.TournamentMode == nil then
	SetupDefaultConfig()
end