//NS2 Tournament Mod Server side script

kDAKRevisions["TournamentMode"] = 2.3
local friendlyfire = false
local teamoneready = false
local teamtwoready = false
local countdownstarted = false
local teamonelastready = 0
local teamtwolastready = 0
local countdownstarttime = 0
local countdownstartcount = 0
local lastpubmessage = 0

if kDAKConfig and kDAKConfig._TournamentMode then

	local function CheckPluginConfig()
	
		if kDAKConfig.kTournamentModePubMode == nil or 
		 kDAKConfig.kTournamentModePubMinPlayers == nil or 
		 kDAKConfig.kTournamentModePubPlayerWarning == nil or 
		 kDAKConfig.kTournamentModePubAlertDelay == nil or 
		 kDAKConfig.kTournamentModeReadyDelay == nil or 
		 kDAKConfig.kTournamentModeGameStartDelay == nil or 
		 kDAKConfig.kEnableFriendlyFireWithTournamentMode == nil or 
		 kDAKConfig.kTournamentModeCountdown == nil then
		 
			kDAKConfig._TournamentMode = false
			
		end
	
	end
	CheckPluginConfig()

end

if kDAKConfig and kDAKConfig._TournamentMode then

	local function LoadTournamentMode()
		if kDAKSettings.TournamentMode then
			Shared.Message("TournamentMode Enabled")
			EnhancedLog("TournamentMode Enabled")
		else
			kDAKSettings.TournamentMode = false
		end
		if kDAKConfig.kEnableFriendlyFireWithTournamentMode then
			friendlyfire = kDAKSettings.TournamentMode
		end
	end

	LoadTournamentMode()

	function GetTournamentMode()
		return kDAKSettings.TournamentMode
	end

	function GetFriendlyFire()
		return friendlyfire
	end
	
	local function StartCountdown(self)
		self:ResetGame() 
		self:ResetGame()
        self:SetGameState(kGameState.Countdown)      
        self.countdownTime = NS2Gamerules.kCountDownLength     
        self.lastCountdownPlayed = nil       
    end
	
	local function ClearTournamentModeState()
		teamoneready = false
		teamtwoready = false
		countdownstarted = false
		teamonelastready = 0
		teamtwolastready = 0
		countdownstarttime = 0
		countdownstartcount = 0
	end
	
	local function DisplayNotification(message)
		Shared.Message(message)
		EnhancedLog(message)
		chatMessage = string.sub(message, 1, kMaxChatLength)
		Server.SendNetworkMessage("Chat", BuildChatMessage(false, "Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
	end
	
	local function CheckCancelGameStart()
		if countdownstarttime ~= 0 then
			DisplayNotification("Game start cancelled.")
			countdownstarttime = 0
			countdownstartcount = 0
			countdownstarted = false
		end
	end
	
	local function MonitorCountDown()
	
		if countdownstarted then	
								
			if countdownstarttime - countdownstartcount < Shared.GetTime() and countdownstartcount ~= 0 then
				if (math.fmod(countdownstartcount, 5) == 0 or countdownstartcount <= 5) then
					chatMessage = string.sub(string.format(kDAKConfig.kTournamentModeCountdown, countdownstartcount), 1, kMaxChatLength)
					Server.SendNetworkMessage("Chat", BuildChatMessage(false, "Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
				end
				countdownstartcount = countdownstartcount - 1
			end
			
			if countdownstarttime < Shared.GetTime() then
				ClearTournamentModeState()
				local gamerules = GetGamerules()
				if gamerules ~= nil then
					StartCountdown(gamerules)
				end
			end
			
		end
		
	end
	
	local function MonitorPubMode(self)
	
		if self:GetTeam1():GetNumPlayers() >= kDAKConfig.kTournamentModePubMinPlayers and self:GetTeam2():GetNumPlayers() >= kDAKConfig.kTournamentModePubMinPlayers then
			if not countdownstarted then
				countdownstarted = true
				countdownstarttime = Shared.GetTime() + kDAKConfig.kTournamentModeGameStartDelay
				countdownstartcount = kDAKConfig.kTournamentModeGameStartDelay	
			end
		else
			CheckCancelGameStart()
			if lastpubmessage + kDAKConfig.kTournamentModePubAlertDelay < Shared.GetTime() then
				chatMessage = string.sub(string.format(kDAKConfig.kTournamentModePubPlayerWarning, kDAKConfig.kTournamentModePubMinPlayers), 1, kMaxChatLength)
				Shared.Message(chatMessage)
				Server.SendNetworkMessage("Chat", BuildChatMessage(false, "Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
				lastpubmessage = Shared.GetTime()
			end
		end

	end
	
	local function UpdatePregameOrig(self, timePassed)
	
		if self:GetGameState() == kGameState.PreGame then
		
            local preGameTime = NS2Gamerules.kPregameLength
            if Shared.GetCheatsEnabled() then
                preGameTime = 0
            end
            if self.timeSinceGameStateChanged > preGameTime then  
                StartCountdown(self)
                if Shared.GetCheatsEnabled() then
                    self.countdownTime = 1
                end      
            end
            
        elseif self:GetGameState() == kGameState.Countdown then
        
            self.countdownTime = self.countdownTime - timePassed           
            // Play count down sounds for last few seconds of count-down
            local countDownSeconds = math.ceil(self.countdownTime)
            if self.lastCountdownPlayed ~= countDownSeconds and (countDownSeconds < 4) then            
                self.worldTeam:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
                self.team1:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
                self.team2:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)
                self.spectatorTeam:PlayPrivateTeamSound(NS2Gamerules.kCountdownSound)             
                self.lastCountdownPlayed = countDownSeconds   
            end
            
            if self.countdownTime <= 0 then
                self.team1:PlayPrivateTeamSound(ConditionalValue(self.team1:GetTeamType() == kAlienTeamType, NS2Gamerules.kAlienStartSound, NS2Gamerules.kMarineStartSound))
                self.team2:PlayPrivateTeamSound(ConditionalValue(self.team2:GetTeamType() == kAlienTeamType, NS2Gamerules.kAlienStartSound, NS2Gamerules.kMarineStartSound))    
                self:SetGameState(kGameState.Started)
            end
            
        end
	end
	
	function NS2Gamerules:UpdatePregame(timePassed)
	
		if GetTournamentMode() and not Shared.GetCheatsEnabled() and not Shared.GetDevMode() and self:GetGameState() == kGameState.PreGame then
			if kDAKConfig.kTournamentModePubMode then
				MonitorPubMode(self)
			end
			MonitorCountDown()
		else
			UpdatePregameOrig(self, timePassed)
		end
	
	end

	local function OnCommandTournamentMode(client)

		local gamerules = GetGamerules()
		if gamerules ~= nil and client ~= nil then
			if gamerules:GetGameState() == kGameState.NotStarted or gamerules:GetGameState() == kGameState.PreGame then
				if GetTournamentMode() then
					kDAKSettings.TournamentMode = false
					if kDAKConfig.kEnableFriendlyFireWithTournamentMode then
						friendlyfire = false
					end
					ServerAdminPrint(client, "TournamentMode disabled")
				else
					kDAKSettings.TournamentMode = true
					if kDAKConfig.kEnableFriendlyFireWithTournamentMode then
						friendlyfire = true
					end
					ServerAdminPrint(client, "TournamentMode enabled")
				end
				SaveDAKSettings()
			end
		end
		if client ~= nil then 		
			local player = client:GetControllingPlayer()
			if player ~= nil then
				PrintToAllAdmins("sv_tournamentmode", client)
			end
		end
	end

	CreateServerAdminCommand("Console_sv_tournamentmode", OnCommandTournamentMode, "Enable/Disable Tournament Mode")

	local function OnCommandFriendlyFire(client)

		local gamerules = GetGamerules()
		if gamerules ~= nil and client ~= nil then
			if gamerules:GetGameState() == kGameState.NotStarted or gamerules:GetGameState() == kGameState.PreGame then
				if GetFriendlyFire() then
					friendlyfire = false
					ServerAdminPrint(client, "FriendlyFire disabled")
				else
					friendlyfire = true
					ServerAdminPrint(client, "FriendlyFire enabled")
				end
			end
		end
		if client ~= nil then 
			local player = client:GetControllingPlayer()
			if player ~= nil then
				PrintToAllAdmins("sv_friendlyfire", client)
			end
		end
	end

	CreateServerAdminCommand("Console_sv_friendlyfire", OnCommandFriendlyFire, "Enable/Disable Friendly Fire")
	
	
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
	
	CreateServerAdminCommand("Console_sv_forceroundstart", OnCommandForceStartRound, "Force start a round in tournamentmode")
	
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
	
	CreateServerAdminCommand("Console_sv_cancelroundstart", OnCommandCancelRoundStart, "Cancel the start of a round in tournamentmode")
	
	local function CheckGameCountdownStart()
		if teamtwoready and teamoneready then
			countdownstarted = true
			countdownstarttime = Shared.GetTime() + kDAKConfig.kTournamentModeGameStartDelay
			countdownstartcount = kDAKConfig.kTournamentModeGameStartDelay
		end
	end

	local function OnCommandReady(client)
		local gamerules = GetGamerules()
		if gamerules ~= nil and client ~= nil then
			if GetTournamentMode() and (gamerules:GetGameState() == kGameState.NotStarted or gamerules:GetGameState() == kGameState.PreGame) and not kDAKConfig.kTournamentModePubMode then
				local player = client:GetControllingPlayer()
				local teamnum = player:GetTeamNumber()
				if teamnum == 1 and teamonelastready + kDAKConfig.kTournamentModeReadyDelay < Shared.GetTime() then
					if teamoneready == false then
						teamoneready = true
						DisplayNotification(string.format("%s has readied for Team one.",client:GetUserId()))
					else
						teamoneready = false
						DisplayNotification(string.format("%s has unreadied for Team one.",client:GetUserId()))			
						CheckCancelGameStart()
					end
					teamonelastready = Shared.GetTime()
				elseif teamnum == 2 and teamtwolastready + kDAKConfig.kTournamentModeReadyDelay < Shared.GetTime() then
					if teamtwoready == false then
						teamtwoready = true
						DisplayNotification(string.format("%s has readied for Team two.",client:GetUserId()))
					else
						teamtwoready = false
						DisplayNotification(string.format("%s has unreadied for Team two.",client:GetUserId()))			
						CheckCancelGameStart()
					end
					teamtwolastready = Shared.GetTime()
				end
				CheckGameCountdownStart()
			end
		end
	end

	Event.Hook("Console_ready",                 OnCommandReady)
	
	Shared.Message("TournamentMode Loading Complete")
	
end