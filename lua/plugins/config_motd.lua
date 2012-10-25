//motd config

kDAKRevisions["MOTD"] = 1.6
local function SetupDefaultConfig()
	local MOTDTable = { }
	table.insert(MOTDTable, "********************************************************************")
	table.insert(MOTDTable, "* Commands: These can be entered via chat or the console (~)        ")
	table.insert(MOTDTable, "* rtv: To initiate a map vote aka Rock The Vote                     ")
	table.insert(MOTDTable, "* random: To vote for auto-random teams for next 30 minutes         ")
	table.insert(MOTDTable, "* timeleft: To display the time until next map vote                 ")
	table.insert(MOTDTable, "* surrender: To initiate or vote in a surrender vote for your team. ")
	table.insert(MOTDTable, "* acceptmotd: To accept and suppress this message                   ")
	table.insert(MOTDTable, "* stuck: To have your player teleported to be unstuck.              ")
	table.insert(MOTDTable, "********************************************************************")
	kDAKConfig.MOTD = { }
	kDAKConfig.MOTD.kEnabled = true
	kDAKConfig.MOTD.kMOTDMessage = MOTDTable
	kDAKConfig.MOTD.kMOTDMessageDelay = 6
	kDAKConfig.MOTD.kMOTDMessageRevision = 1
	kDAKConfig.MOTD.kMOTDMessagesPerTick = 5
	SaveDAKConfig()
end

table.insert(kDAKPluginDefaultConfigs, {PluginName = "MOTD", DefaultConfig = function() SetupDefaultConfig() end })

if kDAKConfig.MOTD == nil then
	SetupDefaultConfig()
end