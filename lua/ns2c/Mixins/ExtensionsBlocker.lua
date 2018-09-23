-- Whelp guess I have to make this.
local oldScriptLoad = Script.Load
local kBlockedTags = { "UWE", "PMShared.lua", "PMHooks.lua"}

function Script.Load(fileName, reload)
	for i = 1, #kBlockedTags do
		if string.find(fileName, kBlockedTags[i]) then
			Print("Blocked loading of " .. fileName .. ".")
			return
		end
	end
	oldScriptLoad(fileName, reload)
end