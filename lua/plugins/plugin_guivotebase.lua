//NS2 Vote Base GUI Implementation

local kGlobalVote = { }

//GUIVoteBase
//OnVoteFunction(client, OptionSelected)
//OnVoteUpdateFunction(kVoteBaseUpdateMessage)
//Relevancy, 0 (Global), 1 (Marines), 2 (Aliens)

if kDAKConfig and kDAKConfig.GUIVoteBase and kDAKConfig.GUIVoteBase.kEnabled then

	local function ClearGUIVoteBase()
		for i = 1, 3 do
			kGlobalVote[i] = { OnVoteFunction = nil, OnVoteUpdateFunction = nil, VoteBaseUpdateMessage = nil, UpdateTime = nil}
		end
	end
	
	ClearGUIVoteBase()
	
	local function GetRelevantPlayerList(key)
		local index = (key - 1)
		if index == 0 then
			return EntityListToTable(Shared.GetEntitiesWithClassname("Player"))
		else
			return EntityListToTable(Shared.GetEntitiesForTeam("Player", index))
		end
	end
	
	function CreateGUIVoteBase(OnVoteFunction, OnVoteUpdateFunction, Relevancy)
		local running = false
		for i = 1, 3 do
			if kGlobalVote[i].UpdateTime ~= nil then
				if i == 1 then
					running = true
					break
				end
				if (Relevancy == 1 and i == 2) or (Relevancy == 2 and i == 3) then
					running = true
					break
				end			
			end		
		end
		if running then
			return false
		end
		local index = Relevancy + 1
		kGlobalVote[index].UpdateTime = 0
		kGlobalVote[index].OnVoteFunction = OnVoteFunction
		kGlobalVote[index].OnVoteUpdateFunction = OnVoteUpdateFunction
		kGlobalVote[index].VoteBaseUpdateMessage = nil
		return true
	end
	
	local function UpdateVotes(deltatime)
	
		for i = 1, 3 do
			if kGlobalVote[i] and kGlobalVote[i].UpdateTime ~= nil then
				if kGlobalVote[i].UpdateTime >= kDAKConfig.GUIVoteBase.kVoteUpdateRate then
					local newVoteBaseUpdateMessage = kGlobalVote[i].OnVoteUpdateFunction(kGlobalVote[i].VoteBaseUpdateMessage)
					local playerList = GetRelevantPlayerList(i)
					for i = 1, #playerList do
						Server.SendNetworkMessage(playerList[i], "GUIVoteBase", newVoteBaseUpdateMessage, false)
					end
					kGlobalVote[i].VoteBaseUpdateMessage = newVoteBaseUpdateMessage
					if newVoteBaseUpdateMessage.votetime == 0 or newVoteBaseUpdateMessage.votetime == nil then
						kGlobalVote[i].UpdateTime = nil
					else
						kGlobalVote[i].UpdateTime = 0
					end
				else
					kGlobalVote[i].UpdateTime = kGlobalVote[i].UpdateTime + deltatime
				end
			end
		end
	
	end

	table.insert(kDAKOnServerUpdate, function(deltatime) return UpdateVotes(deltatime) end)
	
	local function OnMessageBaseVote(client, voteMessage)
		Shared.Message(string.format("Recieved vote %s", voteMessage.optionselected))
	end

	Server.HookNetworkMessage("GUIVoteBaseRecieved", OnMessageBaseVote)

elseif kDAKConfig and not kDAKConfig.GUIVoteBase then

	DAKGenerateDefaultDAKConfig("GUIVoteBase")

end

Shared.Message("GUIVoteBase Loading Complete")