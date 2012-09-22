//NS2 Tournament Mod Server side script

kDAKRevisions["TournamentMode"] = 2.3
local TournamentModeSettings = { countdownstarted = false, countdownstarttime = 0, countdownstartcount = 0, lastmessage = 0, mode = "PCW"}
TournamentModeSettings[1] = {ready = false, lastready = 0, captain = nil}
TournamentModeSettings[2] = {ready = false, lastready = 0, captain = nil}

if kDAKConfig and kDAKConfig._TournamentMode then

	local function CheckPluginConfig()
	
		if kDAKConfig.kTournamentModePubMode == nil or 
		 kDAKConfig.kTournamentModePubMinPlayers == nil or 
		 kDAKConfig.kTournamentModePubPlayerWarning == nil or 
		 kDAKConfig.kTournamentModePubAlertDelay == nil or 
		 kDAKConfig.kTournamentModeReadyDelay == nil or 
		 kDAKConfig.kTournamentModeGameStartDelay == nil or 
		 kDAKConfig.kTournamentModeCountdown == nil then
		 
			kDAKConfig._TournamentMode = false
			
		end
		
		if kDAKSettings.TournamentMode == nil then
			local TournamentMode = false
			table.insert(kDAKSettings, TournamentMode)
		end
		
		if kDAKSettings.FriendlyFire == nil then
			local FriendlyFire = false
			table.insert(kDAKSettings, FriendlyFire)
		end
	
	end
	CheckPluginConfig()

end

if kDAKConfig and kDAKConfig._TournamentMode then

	local function LoadTournamentMode()
		if kDAKSettings.TournamentMode then
			Shared.Message("TournamentMode Enabled")
			//EnhancedLog("TournamentMode Enabled")
		else
			kDAKSettings.TournamentMode = false
		end
		if kDAKSettings.FriendlyFire then
			Shared.Message("FriendlyFire Enabled")
			//EnhancedLog("FriendlyFire Enabled")
		else
			kDAKSettings.FriendlyFire = false
		end
	end

	LoadTournamentMode()

	function GetTournamentMode()
		return kDAKSettings.TournamentMode
	end

	function GetFriendlyFire()
		return kDAKSettings.FriendlyFire
	end
	
	local function StartCountdown(gamerules)
		gamerules:ResetGame() 
		gamerules:ResetGame()
        gamerules:SetGameState(kGameState.Countdown)      
        gamerules.countdownTime = kCountDownLength     
        gamerules.lastCountdownPlayed = nil       
    end
	
	local function ClearTournamentModeState()
		TournamentModeSettings[1] = {ready = false, lastready = 0, captain = nil}
		TournamentModeSettings[2] = {ready = false, lastready = 0, captain = nil}
		TournamentModeSettings.countdownstarted = false
		TournamentModeSettings.countdownstarttime = 0
		TournamentModeSettings.countdownstartcount = 0
		TournamentModeSettings.lastmessage = 0
	end
	
	local function DisplayNotification(message)
		Shared.Message(message)
		EnhancedLog(message)
		chatMessage = string.sub(message, 1, kMaxChatLength)
		Server.SendNetworkMessage("Chat", BuildChatMessage(false, "Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
	end
	
	local function CheckCancelGameStart()
		if TournamentModeSettings.countdownstarttime ~= 0 then
			DisplayNotification("Game start cancelled.")
			TournamentModeSettings.countdownstarttime = 0
			TournamentModeSettings.countdownstartcount = 0
			TournamentModeSettings.countdownstarted = false
		end
	end
	
	local function MonitorCountDown()
	
		if TournamentModeSettings.countdownstarted then	
								
			if TournamentModeSettings.countdownstarttime - TournamentModeSettings.countdownstartcount < Shared.GetTime() and TournamentModeSettings.countdownstartcount ~= 0 then
				if (math.fmod(TournamentModeSettings.countdownstartcount, 5) == 0 or TournamentModeSettings.countdownstartcount <= 5) then
					DisplayNotification(string.format(kDAKConfig.kTournamentModeCountdown, TournamentModeSettings.countdownstartcount), 1, kMaxChatLength)
				end
				TournamentModeSettings.countdownstartcount = TournamentModeSettings.countdownstartcount - 1
			end
			
			if TournamentModeSettings.countdownstarttime < Shared.GetTime() then
				ClearTournamentModeState()
				local gamerules = GetGamerules()
				if gamerules ~= nil then
					StartCountdown(gamerules)
				end
			end
			
		end
		
	end
	
	local function MonitorPubMode(gamerules)
	
		if gamerules:GetTeam1():GetNumPlayers() >= kDAKConfig.kTournamentModePubMinPlayers and gamerules:GetTeam2():GetNumPlayers() >= kDAKConfig.kTournamentModePubMinPlayers then
			if not TournamentModeSettings.countdownstarted then
				TournamentModeSettings.countdownstarted = true
				TournamentModeSettings.countdownstarttime = Shared.GetTime() + kDAKConfig.kTournamentModeGameStartDelay
				TournamentModeSettings.countdownstartcount = kDAKConfig.kTournamentModeGameStartDelay	
			end
		else
			CheckCancelGameStart()
			if TournamentModeSettings.lastpubmessage + kDAKConfig.kTournamentModePubAlertDelay < Shared.GetTime() then
				DisplayNotification(string.format(kDAKConfig.kTournamentModePubPlayerWarning, kDAKConfig.kTournamentModePubMinPlayers), 1, kMaxChatLength)
				TournamentModeSettings.lastpubmessage = Shared.GetTime()
			end
		end

	end
	
	local function TournamentModeOnDisconnect(client)
		if TournamentModeSettings.countdownstarted and not kDAKConfig.kTournamentModePubMode then
			CheckCancelGameStart()
		end
	end
	
	table.insert(kDAKOnClientDisconnect, function(client) return TournamentModeOnDisconnect(client) end)
		
	local function UpdatePregame(timePassed)
	
		local gamerules = GetGamerules()
		if gamerules and GetTournamentMode() and not Shared.GetCheatsEnabled() and not Shared.GetDevMode() and gamerules:GetGameState() == kGameState.PreGame then
			if kDAKConfig.kTournamentModePubMode then
				MonitorPubMode(gamerules)
			end
			MonitorCountDown()
			return false
		end
		return true
		
	end
		
	table.insert(kDAKOnUpdatePregame, function(timePassed) return UpdatePregame(timePassed) end)
	
	if kDAKConfig and kDAKConfig._GamerulesExtensions then
	
		function NS2DAKGamerules:GetCanJoinTeamNumber(teamNumber)

			if GetTournamentMode() and (teamNumber == 1 or teamNumber == 2) then
				return true
			end
			kDAKBaseGamerules.GetCanJoinTeamNumber(self, teamNumber)
			
		end
		
	end
	
	local function EnablePCWMode(client)
		DisplayNotification("PCW Mode set, team captains not required.")
	end	
	
	local function EnableOfficialMode(client)
		DisplayNotification("Official Mode set, team captains ARE required.")
		//eventually add additional req. for offical matches
	end

	local function OnCommandTournamentMode(client, state, ffstate, newmode)
		if state ~= true or state ~= false then
			local newstate = tonumber(state)
			assert(type(newstate) == "number")
			if newstate > 0 then
				state = true
			else
				state = false
			end
		end
		if ffstate ~= true or ffstate ~= false then
			local newffstate = tonumber(ffstate)
			assert(type(newffstate) == "number")
			if newffstate > 0 then
				ffstate = true
			else
				ffstate = false
			end
		else
		end
		if client ~= nil and state ~= GetTournamentMode() then
			kDAKSettings.TournamentMode = state
			ServerAdminPrint(client, "TournamentMode/FriendlyFire " .. ConditionalValue(GetTournamentMode(), "enabled", "disabled"))
			SaveDAKSettings()
		end
		if client ~= nil and ffstate ~= GetFriendlyFire() then
			kDAKSettings.FriendlyFire = ffstate
			ServerAdminPrint(client, "FriendlyFire " .. ConditionalValue(GetFriendlyFire(), "enabled", "disabled"))
			SaveDAKSettings()
		end
		if client ~= nil and TournamentModeSettings.mode ~= newmode and (newmode == "PCW" or newmode == "OFFICIAL") then
			if newmode == "PCW" then
				EnablePCWMode(client)
			elseif newmode == "OFFICIAL" then
				EnableOfficialMode(client)
			end		
		end
		if client ~= nil then 		
			local player = client:GetControllingPlayer()
			if player ~= nil then
				PrintToAllAdmins("sv_tournamentmode", client, " " .. ToString(state) .. " " .. ToString(ffstate) .. " " .. ToString(newmode))
			end
		end
	end

	CreateServerAdminCommand("Console_sv_tournamentmode", OnCommandTournamentMode, "<state> <ffstate> <mode> Enable/Disable tournament mode, friendlyfire or change mode (PCW/OFFICIAL).")
	
	local function OnCommandSetupCaptain(client, teamnum, captain)
	
		local tmNum = tonumber(teamnum)
		local cp = tonumber(captain)
		assert(type(tmNum) == "number")
		assert(type(cp) == "number")
		if tmNum == 1 or tmNum == 2 then
			if GetClientMatchingGameId(cp) then
				TournamentModeSettings[tmNum].captain = GetClientMatchingGameId(cp):GetUserId()
			else
				TournamentModeSettings[tmNum].captain = captain
			end
		end
		if client ~= nil then 
			local player = client:GetControllingPlayer()
			if player ~= nil then
				PrintToAllAdmins("sv_setcaptain", client, " " .. ToString(tmNum) .. " " .. ToString(cp))
			end
		end
		
	end
	
	CreateServerAdminCommand("Console_sv_setcaptain", OnCommandSetupCaptain, "<team> <captain> Set the captain for a team by gameid/steamid.")
	
	local function OnCommandForceStartRound(client)
	
		ClearTournamentModeState()
		local gamerules = GetGamerules()
		if gamerules ~= nil then
			StartCountdown(gamerules)
		end
		
		if client ~= nil then 
			local player = client:GetControllingPlayer()
			if player ~= nil then
				PrintToAllAdmins("sv_forceroundstart", client)
			end
		end
	end
	
	CreateServerAdminCommand("Console_sv_forceroundstart", OnCommandForceStartRound, "Force start a round in tournamentmode.")
	
	local function OnCommandCancelRoundStart(client)
	
		CheckCancelGameStart()
		ClearTournamentModeState()
		
		if client ~= nil then 
			local player = client:GetControllingPlayer()
			if player ~= nil then
				PrintToAllAdmins("sv_cancelroundstart", client)
			end
		end
	end
	
	CreateServerAdminCommand("Console_sv_cancelroundstart", OnCommandCancelRoundStart, "Cancel the start of a round in tournamentmode.")

	local function CheckGameCountdownStart()
		if TournamentModeSettings[1].ready and TournamentModeSettings[2].ready then
			TournamentModeSettings.countdownstarted = true
			TournamentModeSettings.countdownstarttime = Shared.GetTime() + kDAKConfig.kTournamentModeGameStartDelay
			TournamentModeSettings.countdownstartcount = kDAKConfig.kTournamentModeGameStartDelay
		end
	end
	
	local function ClientReady(client)
	
		local player = client:GetControllingPlayer()
		local teamnum = player:GetTeamNumber()
		local clientid = client:GetUserId()
		if teamnum == 1 or teamnum == 2 then
			if mode == "OFFICIAL" and TournamentModeSettings[teamnum].captain then			
				if TournamentModeSettings[teamnum].lastready + kDAKConfig.kTournamentModeReadyDelay < Shared.GetTime() and TournamentModeSettings[teamnum].captain == clientid then
					TournamentModeSettings[teamnum].ready = not TournamentModeSettings[teamnum].ready
					TournamentModeSettings[teamnum].lastready = Shared.GetTime()
					DisplayNotification(string.format("%s has " .. ConditionalValue(TournamentModeSettings[teamnum].ready, "readied", "unreadied") .. " for Team %s.",clientid, teamnum))
					CheckGameCountdownStart()
				end
			else
				if TournamentModeSettings[teamnum].lastready + kDAKConfig.kTournamentModeReadyDelay < Shared.GetTime() then
					TournamentModeSettings[teamnum].ready = not TournamentModeSettings[teamnum].ready
					TournamentModeSettings[teamnum].lastready = Shared.GetTime()
					DisplayNotification(string.format("%s has " .. ConditionalValue(TournamentModeSettings[teamnum].ready, "readied", "unreadied") .. " for Team %s.",clientid, teamnum))
					CheckGameCountdownStart()
				end
			end
		end
		if teamoneready == false or teamtwoready == false then
			CheckCancelGameStart()
		end
		
	end

	local function OnCommandReady(client)
		local gamerules = GetGamerules()
		if gamerules ~= nil and client ~= nil then
			if GetTournamentMode() and (gamerules:GetGameState() == kGameState.NotStarted or gamerules:GetGameState() == kGameState.PreGame) and not kDAKConfig.kTournamentModePubMode then
				ClientReady(client)
			end
		end
	end

	Event.Hook("Console_ready",                 OnCommandReady)
	
	Shared.Message("TournamentMode Loading Complete")
	
end