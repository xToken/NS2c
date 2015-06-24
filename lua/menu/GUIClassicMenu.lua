// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\menu\GUIClassicMenu.lua
// - Dragon

local function GetUpValue(origfunc, name)

	local index = 1
	local foundValue = nil
	while true do
	
		local n, v = debug.getupvalue(origfunc, index)
		if not n then
			break
		end
		
		-- Find the highest index matching the name.
		if n == name then
			foundValue = v
		end
		
		index = index + 1
		
	end
	
	return foundValue
	
end

local function SetupClassicMenuOptions(optionElements)
	
	local function BoolToIndex(value)
        if value then
            return 2
        end
        return 1
    end

	local advancedmovement = Client.GetOptionBoolean("AdvancedMovement", false)
	if optionElements.AdvancedMovement then
	    optionElements.AdvancedMovement:SetOptionActive(BoolToIndex(advancedmovement))
	end
	
end

local function SaveClassicMenuOptions(mainMenu)

	local advancedmovement = mainMenu.optionElements.AdvancedMovement:GetActiveOptionIndex() > 1
	Client.SetOptionBoolean("AdvancedMovement", advancedmovement)
	
end

local function StoreAdvancedMovementOption(formElement)
    Client.SetOptionBoolean("AdvancedMovement", formElement:GetActiveOptionIndex() > 1)
    if UpdateMovementMode then
        UpdateMovementMode()
    end
end

local function UpdateGUIMainMenu()

	local kAdvancedMovementOption = 
				{
					name    = "AdvancedMovement",
					label   = "ADVANCED MOVEMENT",
					tooltip = "Enables/Disables original NS1 style movement.",
					type    = "select",
					values  = { "OFF", "ON" },
					callback = StoreAdvancedMovementOption
				}

	local InitOptions = GetUpValue(GUIMainMenu.CreateOptionWindow, "InitOptions")
	local SaveOptions = GetUpValue(GUIMainMenu.CreateOptionWindow, "SaveOptions")

	local function ClassicInitOptions(optionElements)
		InitOptions(optionElements)
		SetupClassicMenuOptions(optionElements)
	end

	local function ClassicSaveOptions(mainMenu)
		SaveOptions(mainMenu)
		SaveClassicMenuOptions(mainMenu)
	end

	ReplaceLocals(GUIMainMenu.CreateOptionWindow, { InitOptions = ClassicInitOptions })
	ReplaceLocals(GUIMainMenu.CreateOptionWindow, { SaveOptions = ClassicSaveOptions })

	local origGUIMainMenuCreateOptionsForm
    origGUIMainMenuCreateOptionsForm = Class_ReplaceMethod("GUIMainMenu", "CreateOptionsForm", 
	    function(mainMenu, content, options, optionElements)
            //Determine 'General' tab creation
            if options and options[1] and options[1].name == "NickName" then
                //Add in new classic option
                table.insert(options, kAdvancedMovementOption)
            end
            return origGUIMainMenuCreateOptionsForm(mainMenu, content, options, optionElements)
	    end
	)

end

AddPreInitOverride("menu/GUIMainMenu", UpdateGUIMainMenu)

local function ClassicOnOptionsChanged()

	local mainMenu = GetGUIMainMenu()
    if mainMenu and mainMenu.optionElements then
        SetupClassicMenuOptions(mainMenu.optionElements)
    end
    
end

Event.Hook("OptionsChanged", ClassicOnOptionsChanged)