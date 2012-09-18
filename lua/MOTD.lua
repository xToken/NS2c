//NS2 Client Message of the Day

kDAKRevisions["MOTD"] = 1.5
local MOTDClientTracker = { }
local MOTDAcceptedClients = { }

if kDAKConfig and kDAKConfig._MOTD then

	local function CheckPluginConfig()
	
		if kDAKConfig.kMOTDMessage == nil or
		 kDAKConfig.kMOTDMessageDelay == nil or
		 kDAKConfig.kMOTDMessageRevision == nil or
		 kDAKConfig.kMOTDMessagesPerTick == nil then
		 
			kDAKConfig._MOTD = false
			
		end
	
	end
	CheckPluginConfig()

end

if kDAKConfig and kDAKConfig._MOTD then

	if kDAKSettings.MOTDAcceptedClients == nil then
		kDAKSettings.MOTDAcceptedClients = { }
	end
       
	local function DisplayMOTDMessage(client, message)

		local player = client:GetControllingPlayer()
		chatMessage = string.sub(string.format(message), 1, kMaxChatLength)
		Server.SendNetworkMessage(player, "Chat", BuildChatMessage(false, "PM - Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)

	end
	
	local function IsAcceptedClient(client)
		if client ~= nil then
		
			for r = #kDAKSettings.MOTDAcceptedClients, 1, -1 do
				local AcceptedClient = kDAKSettings.MOTDAcceptedClients[r]
				local steamid = client:GetUserId()
				if AcceptedClient.id == steamid and AcceptedClient.revision == kDAKConfig.kMOTDMessageRevision then
					return true
				end
			end
		end
		return false
	end
	
	local function ProcessMessagesforUser(PEntry)
		
		local messagestart = PEntry.Message
		for i = messagestart, #kDAKConfig.kMOTDMessage do
		
			if i < kDAKConfig.kMOTDMessagesPerTick + messagestart then
				DisplayMOTDMessage(PEntry.Client, kDAKConfig.kMOTDMessage[i])
			else
				PEntry.Message = i
				PEntry.Time = Shared.GetTime() + kDAKConfig.kMOTDMessageDelay
				break
			end
			
		end
		
		if #kDAKConfig.kMOTDMessage < messagestart + kDAKConfig.kMOTDMessagesPerTick then
			PEntry = nil
		end
	
		return PEntry
	end

	local function MOTDOnClientConnect(client)
	
		if client:GetIsVirtual() then
			return true
		end
		
		if VerifyClient(client) == nil then
			return false
		end
		
		if IsAcceptedClient(client) then
			return true
		end
		
		local PEntry = { ID = client:GetUserId(), Client = client, Message = 1, Time = 0 }
		PEntry = ProcessMessagesforUser(PEntry)
		if PEntry ~= nil then
			table.insert(MOTDClientTracker, PEntry)
		end
		return true
	end

	table.insert(kDAKOnClientDelayedConnect, function(client) return MOTDOnClientConnect(client) end)

	local function MOTDOnClientDisconnect(client)    

		if #MOTDClientTracker > 0 then
			for i = 1, #MOTDClientTracker do
				local PEntry = MOTDClientTracker[i]
				if PEntry ~= nil and PEntry.Client ~= nil and VerifyClient(PEntry.Client) ~= nil then
					if client == PEntry.Client then
						MOTDClientTracker[i] = nil
						break
					end
				end
			end		
		end
		return true

	end

	table.insert(kDAKOnClientDisconnect, function(client) return MOTDOnClientDisconnect(client) end)

	local function ProcessRemainingMOTDMessages(deltatime)

		PROFILE("MOTD:ProcessRemainingMOTDMessages")

		if #MOTDClientTracker > 0 then
			
			for i = 1, #MOTDClientTracker do
				local PEntry = MOTDClientTracker[i]
				if PEntry ~= nil then
					if PEntry.Client ~= nil and VerifyClient(PEntry.Client) ~= nil then
						if PEntry.Time < Shared.GetTime() then
							MOTDClientTracker[i] = ProcessMessagesforUser(PEntry)
						end
					else
						MOTDClientTracker[i] = nil
					end
				else
					MOTDClientTracker[i] = nil
				end
			end
		end
		return true	
	end

	table.insert(kDAKOnServerUpdate, function(deltatime) return ProcessRemainingMOTDMessages(deltatime) end)

	local function OnCommandAcceptMOTD(client)

		if IsAcceptedClient(client) then
			local player = client:GetControllingPlayer()
			if player ~= nil then
				chatMessage = string.sub(string.format("You already accepted the MOTD"), 1, kMaxChatLength)
				Server.SendNetworkMessage(player, "Chat", BuildChatMessage(false, "PM - Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
			end
			return
		end
		
		local NewClient = { }
		NewClient.id = client:GetUserId()
		NewClient.revision = kDAKConfig.kMOTDMessageRevision
		
		local player = client:GetControllingPlayer()
		chatMessage = string.sub(string.format("You accepted the MOTD"), 1, kMaxChatLength)
		Server.SendNetworkMessage(player, "Chat", BuildChatMessage(false, "PM - Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)

		table.insert(kDAKSettings.MOTDAcceptedClients, NewClient)
		
		SaveDAKSettings()

	end

	Event.Hook("Console_acceptmotd",                 OnCommandAcceptMOTD)
	
	local function OnCommandPrintMOTD(client)
	
		local PEntry = { ID = client:GetUserId(), Client = client, Message = 1, Time = 0 }
		PEntry = ProcessMessagesforUser(PEntry)
		if PEntry ~= nil then
			table.insert(MOTDClientTracker, PEntry)
		end
		
	end
	
	Event.Hook("Console_printmotd",                 OnCommandPrintMOTD)

	Shared.Message("ServerMOTD Loading Complete")
	
end