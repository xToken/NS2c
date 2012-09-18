//NS2 Team Surrender Vote

kDAKRevisions["VoteSurrender"] = 1.0
local kVoteSurrenderRunning = { }
local kSurrenderVotes = { }
local kSurrenderVotesAlertTime = { }

if kDAKConfig and kDAKConfig._VoteSurrender then

	local function CheckPluginConfig()
	
		if kDAKConfig.kVoteSurrenderAlertDelay == nil or
		 kDAKConfig.kVoteSurrenderMinimumPercentage == nil or
		 kDAKConfig.kVoteSurrenderVotingTime == nil then
		 
			kDAKConfig._VoteSurrender = false
			
		end
	
	end
	CheckPluginConfig()

end

if kDAKConfig and kDAKConfig._VoteSurrender then

	local function SetupSurrenderVars()
		for i = 1, 2 do
			table.insert(kVoteSurrenderRunning, 0)
			table.insert(kSurrenderVotes, { })
			table.insert(kSurrenderVotesAlertTime, 0)			
		end
	end
	
	SetupSurrenderVars()

	local function ValidateTeamNumber(teamnum)
		return teamnum == 1 or teamnum == 2
	end

	local function UpdateSurrenderVotes()
		local gamerules = GetGamerules()
		for i = 1, 2 do

			if kVoteSurrenderRunning[i] ~= 0 and gamerules ~= nil and gamerules:GetGameState() == kGameState.Started and kSurrenderVotesAlertTime[i] + kDAKConfig.kVoteSurrenderAlertDelay < Shared.GetTime() then
				local playerRecords =  GetEntitiesForTeam("Player", i)
				local totalvotes = 0
				for j = #kSurrenderVotes, 1, -1 do
					local clientid = kSurrenderVotes[i][j]
					local stillplaying = false
				
					for i = 1, #playerRecords do
						local player = playerRecords[i]
						if player ~= nil then
							local client = Server.GetOwner(player)
							if client ~= nil then
								if clientid == client:GetUserId() then
									stillplaying = true
									totalvotes = totalvotes + 1
									break
								end
							end					
						end
					end
				
					if not stillplaying then
						table.remove(kSurrenderVotes[i], j)
					end
				
				end
				if totalvotes >= math.ceil((#playerRecords * (kDAKConfig.kVoteSurrenderMinimumPercentage / 100))) then
			
					chatMessage = string.sub(string.format("Team %s has voted to surrender.", ToString(i)), 1, kMaxChatLength)
					Server.SendNetworkMessage("Chat", BuildChatMessage(false, "Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
					
					for i = 1, #playerRecords do
						if playerRecords[i] ~= nil then
							GetGamerules():JoinTeam(playerRecords[i], kTeamReadyRoom)
						end
					end
					
					kSurrenderVotesAlertTime[i] = 0
					kVoteSurrenderRunning[i] = 0
					kSurrenderVotes[i] = { }

				else
					local chatmessage
					if kSurrenderVotesAlertTime[i] == 0 then
						chatMessage = string.sub(string.format("A vote has started for your team to surrender. %s votes are needed.", 
						 math.ceil((#playerRecords * (kDAKConfig.kVoteSurrenderMinimumPercentage / 100))) ), 1, kMaxChatLength)
						kSurrenderVotesAlertTime[i] = Shared.GetTime()
					elseif kVoteSurrenderRunning[i] + kDAKConfig.kVoteSurrenderVotingTime < Shared.GetTime() then
						chatMessage = string.sub(string.format("The surrender vote for your team has expired."), 1, kMaxChatLength)
						kSurrenderVotesAlertTime[i] = 0
						kVoteSurrenderRunning[i] = 0
						kSurrenderVotes[i] = { }
					else
						chatMessage = string.sub(string.format("%s votes to surrender, %s needed, %s seconds left. Surrender in console to vote", totalvotes, 
						 math.ceil((#playerRecords * (kDAKConfig.kVoteSurrenderMinimumPercentage / 100))), 
						 math.ceil((kVoteSurrenderRunning[i] + kDAKConfig.kVoteSurrenderVotingTime) - Shared.GetTime()) ), 1, kMaxChatLength)
						kSurrenderVotesAlertTime[i] = Shared.GetTime()
					end
					for k = 1, #playerRecords do
						local player = playerRecords[k]
						if player ~= nil then
							Server.SendNetworkMessage(player, "Chat", BuildChatMessage(false, "Team - Admin", -1, i, kNeutralTeamType, chatMessage), true)
						end
					end
				end
				
			end
			
		end
	end
	
	table.insert(kDAKOnServerUpdate, function(deltatime) return UpdateSurrenderVotes() end)
	
	local function ClearSurrenderVotes()
		kSurrenderVotesAlertTime[1] = 0
		kVoteSurrenderRunning[1] = 0
		kSurrenderVotes[1] = { }
		kSurrenderVotesAlertTime[2] = 0
		kVoteSurrenderRunning[2] = 0
		kSurrenderVotes[2] = { }
	end
		
	table.insert(kDAKOnGameEnd, function(winningTeam) return ClearSurrenderVotes() end)

	local function OnCommandVoteSurrender(client)

		if client ~= nil then
			local player = client:GetControllingPlayer()
			local gamerules = GetGamerules()
			local clientID = client:GetUserId()
			if player ~= nil and clientID ~= nil and gamerules ~= nil and gamerules:GetGameState() == kGameState.Started then
				local teamnumber = player:GetTeamNumber()
				if teamnumber and ValidateTeamNumber(teamnumber) then
					if kVoteSurrenderRunning[teamnumber] ~= 0 then
						local alreadyvoted = false
						for i = #kSurrenderVotes[teamnumber], 1, -1 do
							if kSurrenderVotes[teamnumber][i] == clientID then
								alreadyvoted = true
								break
							end
						end
						if alreadyvoted then
							chatMessage = string.sub(string.format("You already voted for to surrender."), 1, kMaxChatLength)
							Server.SendNetworkMessage(player, "Chat", BuildChatMessage(false, "PM - Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
						else
							chatMessage = string.sub(string.format("You have voted to surrender."), 1, kMaxChatLength)
							Server.SendNetworkMessage(player, "Chat", BuildChatMessage(false, "PM - Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
							table.insert(kSurrenderVotes[teamnumber], clientID)
						end						
					else
						chatMessage = string.sub(string.format("You have voted to surrender."), 1, kMaxChatLength)
						Server.SendNetworkMessage(player, "Chat", BuildChatMessage(false, "PM - Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
						kVoteSurrenderRunning[teamnumber] = Shared.GetTime()
						table.insert(kSurrenderVotes[teamnumber], clientID)
					end
				end
			end
		end
		
	end

	Event.Hook("Console_surrender",               OnCommandVoteSurrender)

	local function VoteSurrenderOff(client, teamnum)
		local tmNum = tonumber(teamnum)
		if tmNum ~= nil and ValidateTeamNumber(tmNum) and kVoteSurrenderRunning[tmNum] ~= 0 then
			kSurrenderVotesAlertTime[tmNum] = 0
			kVoteSurrenderRunning[tmNum] = 0
			kSurrenderVotes[tmNum] = { }
			chatMessage = string.sub(string.format("Surrender vote for team %s has been cancelled.", tmNum), 1, kMaxChatLength)
			Server.SendNetworkMessage("Chat", BuildChatMessage(false, "Admin", -1, tmNum, kNeutralTeamType, chatMessage), true)
			if client ~= nil then 
				ServerAdminPrint(client, string.format("Surrender vote cancelled for team %s.", ToString(tmNum)))
				local player = client:GetControllingPlayer()
				if player ~= nil then
					PrintToAllAdmins("sv_cancelsurrendervote", client, teamnum)
				end
			end
		end

	end

	CreateServerAdminCommand("Console_sv_cancelsurrendervote", VoteSurrenderOff, "<teamnumber> Cancelles a currently running surrender vote for the provided team.")

	local function VoteSurrenderOn(client, teamnum)
		local tmNum = tonumber(teamnum)
		if tmNum ~= nil and ValidateTeamNumber(tmNum) and kVoteSurrenderRunning[tmNum] == 0 then
			kVoteSurrenderRunning[tmNum] = Shared.GetTime()
			if client ~= nil then
				ServerAdminPrint(client, string.format("Surrender vote started for team %s.", ToString(tmNum)))
				local player = client:GetControllingPlayer()
				if player ~= nil then
					PrintToAllAdmins("sv_surrendervote", client, teamnum)
				end			
			end
		end

	end

	CreateServerAdminCommand("Console_sv_surrendervote", VoteSurrenderOn, "<teamnumber> Will start a surrender vote for that team.")

	Shared.Message("VoteSurrender Loading Complete")

end