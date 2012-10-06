//reservedslots config

kDAKRevisions["ReservedSlots"] = 1.6
local function SetupDefaultConfig()
	kDAKConfig.ReservedSlots = { }
	kDAKConfig.ReservedSlots.kEnabled = false
	kDAKConfig.ReservedSlots.kMaximumSlots = 19
	kDAKConfig.ReservedSlots.kReservedSlots = 3
	kDAKConfig.ReservedSlots.kMinimumSlots = 1
	kDAKConfig.ReservedSlots.kDelayedSyncTime = 3
	kDAKConfig.ReservedSlots.kDelayedKickTime = 2
	kDAKConfig.ReservedSlots.kReserveSlotServerFull = "Server is full - You must have a reserved slot to connect."
	kDAKConfig.ReservedSlots.kReserveSlotServerFullDisconnectReason = "Server is full."
	kDAKConfig.ReservedSlots.kReserveSlotKickedForRoom = "**You're being kicked due to a reserved slot, this is automatically determined**"
	kDAKConfig.ReservedSlots.kReserveSlotKickedDisconnectReason = "Kicked due to a reserved slot."
end

table.insert(kDAKPluginDefaultConfigs, {PluginName = "ReservedSlots", DefaultConfig = function() SetupDefaultConfig() end })