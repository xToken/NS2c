Script.Load( "lua/Mixins/Elixer_Utility.lua" )
Elixer.UseVersion( 1.5 )

local origControlBindings = GetUpValue( BindingsUI_GetBindingsData,   "globalControlBindings", 			{ LocateRecurse = true } )
local newGlobalControlBindings = { }
for i = 1, #origControlBindings do
	table.insert(newGlobalControlBindings, origControlBindings[i])
	if origControlBindings[i] == "5" then
		table.insert(newGlobalControlBindings, "Weapon6")
		table.insert(newGlobalControlBindings, "input")
		table.insert(newGlobalControlBindings, "Weapon #6")
		table.insert(newGlobalControlBindings, "6")
		
		table.insert(newGlobalControlBindings, "Weapon7")
		table.insert(newGlobalControlBindings, "input")
		table.insert(newGlobalControlBindings, "Weapon #7")
		table.insert(newGlobalControlBindings, "7")
		
		table.insert(newGlobalControlBindings, "Weapon8")
		table.insert(newGlobalControlBindings, "input")
		table.insert(newGlobalControlBindings, "Weapon #8")
		table.insert(newGlobalControlBindings, "8")
		
		table.insert(newGlobalControlBindings, "Weapon9")
		table.insert(newGlobalControlBindings, "input")
		table.insert(newGlobalControlBindings, "Weapon #9")
		table.insert(newGlobalControlBindings, "9")
		
		table.insert(newGlobalControlBindings, "Weapon10")
		table.insert(newGlobalControlBindings, "input")
		table.insert(newGlobalControlBindings, "Weapon #10")
		table.insert(newGlobalControlBindings, "0")
	end	
end
ReplaceLocals(BindingsUI_GetBindingsData, { globalControlBindings = newGlobalControlBindings }) 

local defaults = GetUpValue( GetDefaultInputValue,   "defaults", 			{ LocateRecurse = true } )
table.insert(defaults, { "Weapon6", "6" })
table.insert(defaults, { "Weapon7", "7" })
table.insert(defaults, { "Weapon8", "8" })
table.insert(defaults, { "Weapon9", "9" })
table.insert(defaults, { "Weapon10", "0" })