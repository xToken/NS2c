//afkkick default config

kDAKRevisions["AFKKicker"] = 1.6
local function SetupDefaultConfig()
	kDAKConfig.AFKKicker = { }
	kDAKConfig.AFKKicker.kEnabled = true
	kDAKConfig.AFKKicker.kAFKKickDelay = 150
	kDAKConfig.AFKKicker.kAFKKickCheckDelay = 5
	kDAKConfig.AFKKicker.kAFKKickMinimumPlayers = 5
	kDAKConfig.AFKKicker.kAFKKickReturnMessage = "You are no longer flagged as idle."
	kDAKConfig.AFKKicker.kAFKKickMessage = "%s kicked from the server for idling more than %d seconds."
	kDAKConfig.AFKKicker.kAFKKickDisconnectReason = "Kicked from the server for idling more than %d seconds."
	kDAKConfig.AFKKicker.kAFKKickClientMessage = "You are being kicked for idling for more than %d seconds."
	kDAKConfig.AFKKicker.kAFKKickWarning1 = 30
	kDAKConfig.AFKKicker.kAFKKickWarningMessage1 = "You will be kicked in %d seconds for idling."
	kDAKConfig.AFKKicker.kAFKKickWarning2 = 10
	kDAKConfig.AFKKicker.kAFKKickWarningMessage2 = "You will be kicked in %d seconds for idling."
end

table.insert(kDAKPluginDefaultConfigs, {PluginName = "AFKKicker", DefaultConfig = function() SetupDefaultConfig() end })