//DAK Loader Client

//No sync of plugins active to clients currently, may be useful to have at some point.
//Used to load client side scripts, may be expanded if plugin sync seems useful.
//Would allow help menus and such to be generated.

//Script.Load("lua/gui/GUIVoteBase.lua")

local function OnCommandVoteUpdate(VoteBaseUpdateMessage)
	Print(ToString(VoteBaseUpdateMessage))
end

Client.HookNetworkMessage("GUIVoteBase", OnCommandVoteUpdate)

local function OnCommandVoteBase(client, parm1)
	local idNum = tonumber(parm1)
	if idNum then
		Client.SendNetworkMessage("GUIVoteBaseRecieved", { key = 0, optionselected = idNum }, true)
	end
end

Event.Hook("console_votebase", OnCommandVoteBase)