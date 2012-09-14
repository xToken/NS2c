//NS2 Reserved Slot

kDAKRevisions["ReservedSlots"] = 1.4
local ReservedPlayers = { }
local cachedPlayersList = { }
local lastconnect = 0
local lastdisconnect = 0
local disconnectclients = { }
local disconnectclienttime = 0
local reserveslotactionslog = { }

local ServerAdminPath = Server.GetAdminPath()
local ReservedPlayersFileName = "ReservedPlayers.json"

if kDAKConfig._ReservedSlots then

	local function LoadReservedPlayers()
		-- Borrowed :< from Huze reserved slot plugin to maintain compat.
		local ReservedPlayersFile
		if kCheckGameDirectory then
			ReservedPlayersFile = assert(io.open("game://" .. ServerAdminPath .. ReservedPlayersFileName, "r"))
		else
			ReservedPlayersFile = assert(io.open("user://" .. ServerAdminPath .. ReservedPlayersFileName, "r"))
		end
		if ReservedPlayersFile then
			Shared.Message("Loading Reserve slot players.")
			ReservedPlayers = json.decode(ReservedPlayersFile:read("*all"))
		end
		ReservedPlayersFile:close()
	end
	LoadReservedPlayers()

	local function SaveReservedPlayers()

		local ReservedPlayersFile = io.open("user://" .. ServerAdminPath .. reservedPlayersFileName, "w+")
		ReservedPlayersFile:write(json.encode(ReservedPlayers))
		ReservedPlayersFile:close()
		
	end
	
	local function DisconnectClientForReserveSlot(client)

		Server.DisconnectClient(client)
		
	end

	local function GetPlayerList()

		local playerList = EntityListToTable(Shared.GetEntitiesWithClassname("Player"))
		return playerList
		
	end

	local function CheckReserveStatus(client, silent)

		if client:GetIsVirtual() then
			//Bots get no reserve slots
			return false
		end
		
		if GetClientCanRunCommand(client, "sv_hasreserve") then
			if not silent then ServerAdminPrint(client, "Reserved Slot Entry For - id: " .. tostring(client:GetUserId()) .. " - Is Valid") end
			return true
		end
		
		for r = #ReservedPlayers, 1, -1 do
			local ReservePlayer = ReservedPlayers[r]
			local UserId = client:GetUserId()
			
			if ReservePlayer.id == UserId then
				// Check if enough time has passed on a temporary reserve slot.
				if not silent then table.insert(reserveslotactionslog, "Reserve Slot check for " .. tostring(ReservePlayer.name) .. " - id: " .. tostring(ReservePlayer.id)) end
				local now = Shared.GetSystemTime()
				if ReservePlayer.time ~= 0 and now > ReservePlayer.time then
					if not silent then ServerAdminPrint(client, "Reserved Slot Entry For " .. tostring(ReservePlayer.name) .. " - id: " .. tostring(ReservePlayer.id) .. " - Has Expired") end
					return false
				else
					if not silent then ServerAdminPrint(client, "Reserved Slot Entry For " .. tostring(ReservePlayer.name) .. " - id: " .. tostring(ReservePlayer.id) .. " - Is Valid") end
					return true
				end
			end	
		end
	end

	local function OnReserveSlotClientConnected(client)
		local playerCount = #cachedPlayersList
		local serverFull = kDAKConfig.kMaximumSlots - playerCount <= kDAKConfig.kReservedSlots
		local serverReallyFull = kDAKConfig.kMaximumSlots - playerCount <= kDAKConfig.kMinimumSlots
		
		local reserved = CheckReserveStatus(client, false)
		local playerList = EntityListToTable(Shared.GetEntitiesWithClassname("Player"))
		table.insert(cachedPlayersList,client:GetUserId())
		
		if serverFull and not reserved then
			local player = client:GetControllingPlayer()
			if player ~= nil then
				chatMessage = string.sub(string.format(kDAKConfig.kReserveSlotServerFull), 1, kMaxChatLength)
				Server.SendNetworkMessage(player, "Chat", BuildChatMessage(false, "PM - Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
				table.insert(reserveslotactionslog, "Kicking player "  .. tostring(player.name) .. " - id: " .. tostring(client:GetUserId()) .. " for no reserve slot.")
				EnhancedLog("Kicking player "  .. tostring(player.name) .. " - id: " .. tostring(client:GetUserId()) .. " for no reserve slot.")
			end
			client.disconnectreason = kDAKConfig.kReserveSlotServerFullDisconnectReason
			table.insert(disconnectclients, client)
			disconnectclienttime = Shared.GetTime() + kDAKConfig.kDelayedKickTime
			return false
		end
		if serverReallyFull and reserved then
		
			local playertokick
			local lowestscore = 0
				
			for r = #playerList, 1, -1 do
				if playerList[r] ~= nil then
					local plyr = playerList[r]
					local clnt = playerList[r]:GetClient()
					if plyr ~= nil and clnt ~= nil then
						if plyr.score == nil then
							plyr.score = 0
						end

						if (plyr.score <= lowestscore) and not plyr:GetIsCommander() and not CheckReserveStatus(clnt, true) then
							lowestscore = plyr.score
							playertokick = plyr
						end
					end
				end
			end
			
			if playertokick ~= nil then
			
				table.insert(reserveslotactionslog, "Kicking player "  .. tostring(playertokick.name) .. " - id: " .. tostring(playertokick:GetClient():GetUserId()) .. " with score: " .. tostring(playertokick.score))
				EnhancedLog("Kicking player "  .. tostring(playertokick.name) .. " - id: " .. tostring(playertokick:GetClient():GetUserId()) .. " with score: " .. tostring(playertokick.score))
				chatMessage = string.sub(string.format(kDAKConfig.kReserveSlotKickedForRoom), 1, kMaxChatLength)
				Server.SendNetworkMessage(playertokick, "Chat", BuildChatMessage(false, "PM - Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
				playertokick.disconnectreason = kDAKConfig.kReserveSlotKickedDisconnectReason
				table.insert(disconnectclients, playertokick:GetClient())
				disconnectclienttime = Shared.GetTime() + kDAKConfig.kDelayedKickTime
				return true
			else
				table.insert(reserveslotactionslog, "Attempted to kick player but no valid player could be located")
				EnhancedLog("Attempted to kick player but no valid player could be located")
			end
			
		end
		lastconnect = Shared.GetTime() + kDAKConfig.kDelayedSyncTime
		return true
		
	end

	table.insert(kDAKOnClientDelayedConnect, function(client) return OnReserveSlotClientConnected(client) end)

	local function ReserveSlotClientDisconnect(client)    
	
		if client ~= nil and VerifyClient(client) ~= nil then
			for r = #cachedPlayersList, 1, -1 do
				if cachedPlayersList[r] == client:GetUserId() then
					table.remove(cachedPlayersList,r)
					break
				end
			end
		else
			return false
		end
		
		lastdisconnect = Shared.GetTime() + kDAKConfig.kDelayedSyncTime
		return true
		
	end

	table.insert(kDAKOnClientDisconnect, function(client) return ReserveSlotClientDisconnect(client) end)

	local function CheckReserveSlotSync()

		PROFILE("ReserveSlots:CheckReserveSlotSync")

		if #disconnectclients > 0 and disconnectclienttime < Shared.GetTime() then
			for r = #disconnectclients, 1, -1 do
				if disconnectclients[r] ~= nil and VerifyClient(disconnectclients[r]) ~= nil then
					DisconnectClientForReserveSlot(disconnectclients[r])
				end
			end
			disconnectclients = { }
			disconnectclienttime = 0
		end

		if lastconnect ~= 0 or lastdisconnect ~= 0 then
			if lastconnect >= lastdisconnect then
				if lastconnect < Shared.GetTime() then
					lastconnect = 0
					lastdisconnect = 0
					local playerList = GetPlayerList()
					if #cachedPlayersList ~= #playerList then
						table.insert(reserveslotactionslog, string.format("Cached PlayerList differs from actual, %s actual, %s  cached", #playerList, #cachedPlayersList))
						EnhancedLog(string.format("Cached PlayerList differs from actual, %s actual, %s  cached", #playerList, #cachedPlayersList))
					end
					cachedPlayersList = { }
					for r = #playerList, 1, -1 do
						if playerList[r] ~= nil then
							local client = Server.GetOwner(playerList[r])
							if client ~= nil then
								table.insert(cachedPlayersList,client:GetUserId())
							end
						end
					end
				end
			else
				if lastdisconnect < Shared.GetTime() then
					lastconnect = 0
					lastdisconnect = 0
					local playerList = GetPlayerList()
					if #cachedPlayersList ~= #playerList then
						table.insert(reserveslotactionslog, string.format("Cached PlayerList differs from actual, %s actual, %s  cached", #playerList, #cachedPlayersList))
						EnhancedLog(string.format("Cached PlayerList differs from actual, %s actual, %s  cached", #playerList, #cachedPlayersList))
					end
					cachedPlayersList = { }
					for r = #playerList, 1, -1 do
						if playerList[r] ~= nil then
							local client = Server.GetOwner(playerList[r])
							if client ~= nil then
								table.insert(cachedPlayersList,client:GetUserId())
							end
						end
					end
				end
			end	
		end
				
	end

	table.insert(kDAKOnServerUpdate, function(deltatime) return CheckReserveSlotSync() end)

	local function AddReservePlayer(client, parm1, parm2, parm3, parm4)



	end

	CreateServerAdminCommand("Console_sv_addreserve", AddReservePlayer, "<name> <id> <reason> <time> Will add a reserve player to the list.")
	
	local function DebugReserveSlots(client)
	
		if client ~= nil then
			for r = 1, #reserveslotactionslog, 1 do
				if reserveslotactionslog[r] ~= nil then
					ServerAdminPrint(client, reserveslotactionslog[r])
				end
			end
		end

	end

	CreateServerAdminCommand("Console_sv_reservedebug", DebugReserveSlots, "Will print messages logged during actions taken by reserve slot plugin.")

	Shared.Message("ReserveSlot Loading Complete")
	
end