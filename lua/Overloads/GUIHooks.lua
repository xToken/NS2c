// Natural Selection 2 GUI Hooking Library
// GUIHooks.lua
// - Dragon

// This basic library is designed to make hooking GUI files easier.  Simply reference this file, then add functions
// you want called when specific GUIScripts are loaded.
// GHook:AddPreInitOverride("GUIMinimapFrame", testfunc) - Will call testfunc when GUIMinimapFrame is loaded, but before its :Initialize() function is run
// GHook:AddPostInitOverride("GUIMinimapFrame", testfunc) Would call testfunc after the :Initialize() function is run.

Script.Load("lua/Class.lua")

local version = 1.0

GHook = GHook or { }

if GHook.version and GHook.version >= version then
	//Already loaded or newer version
	return
end

GHook.version = version

local kPreHookedScripts = { }
local kPostHookedScripts = { }
local kGUIPreOverrides = { }
local kGUIPostOverrides = { }

function GHook:GetUpValue(origfunc, name)

	local index = 1
	local foundValue = nil
	while true do
	
		local n, v = debug.getupvalue(origfunc, index)
		if not n then
			break
		end
		
		if n == name then
			foundValue = v
		end
		
		index = index + 1
		
	end
	
	return foundValue
	
end

function GHook:AddPreInitOverride(scriptname, func)
	if kGUIPreOverrides[scriptname] == nil then
		kGUIPreOverrides[scriptname] = { }
	end
	table.insert(kGUIPreOverrides[scriptname], func)
end

function GHook:AddPostInitOverride(scriptname, func)
	if kGUIPostOverrides[scriptname] == nil then
		kGUIPostOverrides[scriptname] = { }
	end
	table.insert(kGUIPostOverrides[scriptname], func)
end

local function PreInitOverrides(scriptName)
	local functions = kGUIPreOverrides[scriptName]
	if not kPreHookedScripts[scriptName] and functions then
		for i = #functions, 1, -1 do
			if type(functions[i]) == "function" then
				Script.Load("lua/" .. scriptName .. ".lua")
				functions[i]()
			else
				Shared.Message(string.format("Non-valid function registered for %s GUIScript ", scriptName))
			end
		end
		kPreHookedScripts[scriptName] = true
    end
end

local function PostInitOverrides(scriptName, script)
	local functions = kGUIPostOverrides[scriptName]
	if not kPostHookedScripts[scriptName] and functions then
		for i = #functions, 1, -1 do
			if type(functions[i]) == "function" then
				functions[i](script)
			else
				Shared.Message(string.format("Non-valid function registered for %s GUIScript ", scriptName))
			end
		end
		kPostHookedScripts[scriptName] = true
	end
end
		
local origGUIManagerCreateGUIScriptSingle
origGUIManagerCreateGUIScriptSingle = Class_ReplaceMethod("GUIManager", "CreateGUIScriptSingle", 
	function(self, scriptName)
		local script
		PreInitOverrides(scriptName)
		script = origGUIManagerCreateGUIScriptSingle(self, scriptName)
		PostInitOverrides(scriptName, script)
		return script
	end
)

local origGUIManagerCreateGUIScript
origGUIManagerCreateGUIScript = Class_ReplaceMethod("GUIManager", "CreateGUIScript", 
	function(self, scriptName)
		local script
		PreInitOverrides(scriptName)
		script = origGUIManagerCreateGUIScript(self, scriptName)
		PostInitOverrides(scriptName, script)
		return script
	end
)