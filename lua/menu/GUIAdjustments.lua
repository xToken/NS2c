// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\menu\GUIAdjustments.lua
// - Dragon

Script.Load("lua/Class.lua")

local kPreHookedScripts = { }
local kPostHookedScripts = { }
local kGUIPreOverrides = { }
local kGUIPostOverrides = { }

function AddPreInitOverride(scriptname, func)
	if kGUIPreOverrides[scriptname] == nil then
		kGUIPreOverrides[scriptname] = { }
	end
	table.insert(kGUIPreOverrides[scriptname], func)
end

function AddPostInitOverride(scriptname, func)
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