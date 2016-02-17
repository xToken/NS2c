-- Whelp guess I have to make this.
local oldScriptLoad = Script.Load
function Script.Load(fileName, reload)
	if not string.find(fileName, "UWE") then
		oldScriptLoad(fileName, reload)
	else
		Print("Blocked loading of " .. fileName .. ".")
	end
end