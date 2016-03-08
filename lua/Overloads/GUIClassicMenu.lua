// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\Overloads\GUIClassicMenu.lua
// - Dragon

Script.Load("lua/Class.lua")
Script.Load("lua/Overloads/GUIHooks.lua")

local function BoolToIndex(value)
    if value then
        return 2
    end
    return 1
end

local function SetupClassicMenuOptions(optionElements)

    if optionElements and optionElements.AdvancedMovement then
	    local advancedmovement = Client.GetOptionBoolean("AdvancedMovement", false)
	    optionElements.AdvancedMovement:SetOptionActive(BoolToIndex(advancedmovement))
	end
	
end

local function SaveClassicMenuOptions(mainMenu)

    if mainMenu and mainMenu.optionElements and mainMenu.optionElements.AdvancedMovement then
	    local advancedmovement = mainMenu.optionElements.AdvancedMovement:GetActiveOptionIndex() > 1
	    Client.SetOptionBoolean("AdvancedMovement", advancedmovement)
	end
	
end

local function StoreAdvancedMovementOption(formElement)
    if formElement then
        Client.SetOptionBoolean("AdvancedMovement", formElement:GetActiveOptionIndex() > 1)
        if UpdateMovementMode then
            UpdateMovementMode()
        end
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

	local InitOptions = GHook:GetUpValue(GUIMainMenu.CreateOptionWindow, "InitOptions")
	local SaveOptions = GHook:GetUpValue(GUIMainMenu.CreateOptionWindow, "SaveOptions")

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

GHook:AddPreInitOverride("menu/GUIMainMenu", UpdateGUIMainMenu)

local function ClassicOnOptionsChanged()

	local mainMenu = GetGUIMainMenu()
    if mainMenu and mainMenu.optionElements then
        SetupClassicMenuOptions(mainMenu.optionElements)
    end
    
end

Event.Hook("OptionsChanged", ClassicOnOptionsChanged)