//=============================================================================
//
// lua/BindingsDialog.lua
// 
// Populate and manage key bindings in options screen.
//
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

// Default key bindings if not saved in options
// When changing values in the right-hand column, make sure to change BindingsUI_GetBindingsText() below.
// Type "bind" in console to find out all the allowed bindings (and "print_bindings" to see what's bound)
local defaults = {
    { "MoveForward", "W" },
    { "MoveLeft", "A" },
    { "MoveBackward", "S" },
    { "MoveRight", "D" },
    { "Jump", "Space" },
    { "MovementModifier", "LeftShift" },
    { "Crouch", "LeftControl" },
    { "PrimaryAttack", "MouseButton0" },
    { "SecondaryAttack", "MouseButton1" },
    { "Reload", "R" },
    { "Use", "E" },
    { "Drop", "G" },
    { "VoiceChat", "LeftAlt" },
    { "TextChat", "Return" },
    { "TeamChat", "Y" },
    { "ShowMap", "C" },
    { "Weapon1", "1" },
    { "Weapon2", "2" },
    { "Weapon3", "3" },
    { "Weapon4", "4" },
    { "Weapon5", "5" },
    { "Weapon6", "6" },
    { "Weapon7", "7" },
    { "Weapon8", "8" },
    { "Weapon9", "9" },
    { "Weapon0", "0" },
    { "QuickSwitch", "V" },
    { "Scoreboard", "Tab" },
    { "ToggleConsole", "Grave" },
    { "ToggleFlashlight", "F" },
    { "ReadyRoom", "F4" },
    { "RequestMenu", "X" },
    { "RequestHealth", "Q" },
    { "RequestAmmo", "Z" },
    { "RequestOrder", "H" },
    { "ShowTechMap", "J" },
    { "ShowHelpScreen", "I" },
    { "Taunt", "T" },
    { "PingLocation", "MouseButton2" },
    { "Buy", "B" },
    { "VoteYes", "F1" },
    { "VoteNo", "F2" },
    { "SelectNextWeapon", "MouseWheelUp" },
    { "SelectPrevWeapon", "MouseWheelDown" },
    { "LastUpgrades", "None" },
    { "ToggleMinimapNames", "None" },
    { "Grid1", "Q" },
    { "Grid2", "W" },
    { "Grid3", "E" },
    { "Grid4", "A" },
    { "Grid5", "S" },
    { "Grid6", "D" },
    { "Grid7", "F" },
    { "Grid8", "Z" },
    { "Grid9", "X" },
    { "Grid10", "G" },
    { "Grid11", "V" },
    { "ShowMapCom", "C" },
    { "VoiceChatCom", "LeftAlt" },
    { "TextChatCom", "Return" },
    { "TeamChatCom", "Y" },
    { "PreviousLocationCom", "None" },
    { "OverHeadZoomIncrease", "MouseWheelUp" },
    { "OverHeadZoomDecrease", "MouseWheelDown" },
    { "OverHeadZoomReset", "None" },
    { "MovementModifierCom", "LeftShift" }
}

// Order, names, description of keys in menu
local globalControlBindings = {
    "Movement", "title", Locale.ResolveString("BINDINGS_MOVEMENT"), "None",
    "MoveForward", "input", Locale.ResolveString("BINDINGS_MOVE_FORWARD"), "W",
    "MoveLeft", "input", Locale.ResolveString("BINDINGS_MOVE_LEFT"), "A",
    "MoveBackward", "input", Locale.ResolveString("BINDINGS_MOVE_BACKWARD"), "S",
    "MoveRight", "input", Locale.ResolveString("BINDINGS_MOVE_RIGHT"), "D",
    "Jump", "input", Locale.ResolveString("BINDINGS_JUMP"), "Space",
    "MovementModifier", "input", Locale.ResolveString("BINDINGS_MOVEMENT_SPECIAL"), "LeftShift",
    "Crouch", "input", Locale.ResolveString("BINDINGS_CROUCH"), "LeftControl",
    "ShowMap", "input", Locale.ResolveString("BINDINGS_SHOW_MAP"), "C",
    "Action", "title", Locale.ResolveString("BINDINGS_ACTION"), "None",
    "PrimaryAttack", "input", Locale.ResolveString("BINDINGS_PRIMARY_ATTACK"), "MouseButton0",
    "SecondaryAttack", "input", Locale.ResolveString("BINDINGS_SECONDARY_ATTACK"), "MouseButton1",
    "Reload", "input", Locale.ResolveString("BINDINGS_RELOAD"), "R",
    "Use", "input", Locale.ResolveString("BINDINGS_USE"), "E",
    "Drop", "input", Locale.ResolveString("BINDINGS_DROP_WEAPON_/_EJECT"), "G",
    "Buy", "input", Locale.ResolveString("BINDINGS_BUY/EVOLVE_MENU"), "B",
    "LastUpgrades", "input", Locale.ResolveString("BINDINGS_EVOLVE_LAST_UPGRADES"), "None",
    "ShowTechMap", "input", Locale.ResolveString("BINDINGS_SHOW_TECH_TREE"), "J",
    "ShowHelpScreen", "input", Locale.ResolveString("BINDINGS_SHOW_HELP_SCREEN"), "I",
    "Scoreboard", "input", Locale.ResolveString("BINDINGS_SCOREBOARD"), "Tab",
    "VoiceChat", "input", Locale.ResolveString("BINDINGS_USE_MICROPHONE"), "LeftAlt",
    "TextChat", "input", Locale.ResolveString("BINDINGS_PUBLIC_CHAT"), "Y",
    "TeamChat", "input", Locale.ResolveString("BINDINGS_TEAM_CHAT"), "Return",
    "ToggleMinimapNames", "input", Locale.ResolveString("BINDINGS_TOGGLE_MINIMAP_NAMES"), "None",
    "SelectNextWeapon", "input", Locale.ResolveString("BINDINGS_NEXT_WEAPON"), "MouseWheelUp",
    "SelectPrevWeapon", "input", Locale.ResolveString("BINDINGS_PREVIOUS_WEAPON"), "MouseWheelDown",
    "Weapon1", "input", Locale.ResolveString("BINDINGS_WEAPON_#1"), "1",
    "Weapon2", "input", Locale.ResolveString("BINDINGS_WEAPON_#2"), "2",
    "Weapon3", "input", Locale.ResolveString("BINDINGS_WEAPON_#3"), "3",
    "Weapon4", "input", Locale.ResolveString("BINDINGS_WEAPON_#4"), "4",
    "Weapon5", "input", Locale.ResolveString("BINDINGS_WEAPON_#5"), "5",
    "QuickSwitch", "input", Locale.ResolveString("BINDINGS_QUICK_SWITCH"), "V",
    "ToggleConsole", "input", Locale.ResolveString("BINDINGS_TOGGLE_CONSOLE"), "Grave",
    "ToggleFlashlight", "input", Locale.ResolveString("BINDINGS_FLASHLIGHT"), "F",
    "ReadyRoom", "input", Locale.ResolveString("BINDINGS_GO_TO_READY_ROOM"), "F4",
    "RequestMenu", "input", Locale.ResolveString("BINDINGS_VOICEOVER_MENU"), "X",
    "RequestHealth", "input", Locale.ResolveString("BINDINGS_REQUEST_HEALING_/_MEDPACK"), "Q",
    "RequestAmmo", "input", Locale.ResolveString("BINDINGS_REQUEST_AMMO_/_ENZYME"), "Z",
    "RequestOrder", "input", Locale.ResolveString("BINDINGS_REQUEST_ORDER"), "H",
    "Taunt", "input", Locale.ResolveString("BINDINGS_TAUNT"), "T",
    "PingLocation", "input", Locale.ResolveString("BINDINGS_PING_LOCATION"), "MouseButton2",
    "VoteYes", "input", Locale.ResolveString("BINDINGS_VOTE_YES"), "F1",
    "VoteNo", "input", Locale.ResolveString("BINDINGS_VOTE_NO"), "F2",
}

local globalComControlBindings = {
    "Grid1", "input", Locale.ResolveString("COMBINDINGS_GRID_SPOT_1_(DEFAULT_Q)"), "Q",
    "Grid2", "input", Locale.ResolveString("COMBINDINGS_GRID_SPOT_2_(DEFAULT_W)"), "W",
    "Grid3", "input", Locale.ResolveString("COMBINDINGS_GRID_SPOT_3_(DEFAULT_E)"), "E",
    "Grid4", "input", Locale.ResolveString("COMBINDINGS_GRID_SPOT_4_(DEFAULT_A)"), "A",
    "Grid5", "input", Locale.ResolveString("COMBINDINGS_GRID_SPOT_5_(DEFAULT_S)"), "S",
    "Grid6", "input", Locale.ResolveString("COMBINDINGS_GRID_SPOT_6_(DEFAULT_D)"), "D",
    "Grid7", "input", Locale.ResolveString("COMBINDINGS_GRID_SPOT_7_(DEFAULT_F)"), "F",
    "Grid8", "input", Locale.ResolveString("COMBINDINGS_GRID_SPOT_8_(DEFAULT_Z)"), "Z",
    "Grid9", "input", Locale.ResolveString("COMBINDINGS_GRID_SPOT_9_(DEFAULT_X)"), "X",
    "Grid10", "input", Locale.ResolveString("COMBINDINGS_GRID_SPOT_10_(DEFAULT_G)"), "G",
    "Grid11", "input", Locale.ResolveString("COMBINDINGS_GRID_SPOT_11_(DEFAULT_V)"), "V",
    "ShowMapCom", "input", Locale.ResolveString("COMBINDINGS_SHOW_MAP"), "C",
    "VoiceChatCom", "input", Locale.ResolveString("COMBINDINGS_USE_MICROPHONE"), "LeftAlt",
    "TextChatCom", "input", Locale.ResolveString("COMBINDINGS_PUBLIC_CHAT"), "Y",
    "TeamChatCom", "input", Locale.ResolveString("COMBINDINGS_TEAM_CHAT"), "Return",
    "PreviousLocationCom", "input", Locale.ResolveString("COMBINDINGS_GO_TO_PREVIOUS_LOCATION"), "None",
    "OverHeadZoomIncrease", "input", Locale.ResolveString("COMBINDINGS_OVERHEAD_ZOOM_INCREASE"), "MouseWheelUp",
    "OverHeadZoomDecrease", "input", Locale.ResolveString("COMBINDINGS_OVERHEAD_ZOOM_DECREASE"), "MouseWheelDown",
    "OverHeadZoomReset", "input", Locale.ResolveString("COMBINDINGS_OVERHEAD_ZOOM_RESET"), "None",
    "MovementModifierCom", "input", Locale.ResolveString("COMBINDINGS_MOVEMENT_SPECIAL"), "LeftShift",
}

local specialKeys = {
    [" "] = "SPACE"
}

function GetDefaultInputValue(controlId)

    local rc = nil

    for index, pair in ipairs(defaults) do
        if(pair[1] == controlId) then
            rc = pair[2]
            break
        end
    end    
        
    return rc
    
end

/**
 * Get the value of the input control
 */
function BindingsUI_GetInputValue(controlId)

    local value = Client.GetOptionString( "input/" .. controlId, "" )

    local rc = ""
    
    if(value ~= "") then
        rc = value
    else
        rc = GetDefaultInputValue(controlId)
        if (rc ~= nil) then
            Client.SetOptionString( "input/" .. controlId, rc )
        end
        
    end
    
    return rc
    
end

/**
 * Set the value of the input control
 */
function BindingsUI_SetInputValue(controlId, controlValue)

    if(controlId ~= nil) then
        Client.SetOptionString( "input/" .. controlId, controlValue )
    end
    
end

/**
 * Return data in linear array of config elements
 * controlId, "input", name, value
 * controlId, "title", name, instructions
 * controlId, "separator", unused, unused
 */
function BindingsUI_GetBindingsData()
    return globalControlBindings   
end

function BindingsUI_GetComBindingsData()
    return globalComControlBindings   
end
function BindingsUI_GetBindingsTable()

    local bindingsTable = { }
    local bindingsList = BindingsUI_GetBindingsData()
    
    for i = 1, #bindingsList, 4 do
    
        if bindingsList[i + 1] ~= "title" then
            table.insert(bindingsTable, { name = bindingsList[i], detail = bindingsList[i + 2], current = BindingsUI_GetInputValue(bindingsList[i]) })
        end
        
    end
    
    return bindingsTable
    
end

function BindingsUI_GetComBindingsTable()

    local bindingsTable = { }
    local bindingsList = BindingsUI_GetComBindingsData()
    
    for i = 1, #bindingsList, 4 do
    
        if bindingsList[i + 1] ~= "title" then
            table.insert(bindingsTable, { name = bindingsList[i], detail = bindingsList[i + 2], current = BindingsUI_GetInputValue(bindingsList[i]) })
        end
        
    end
    
    return bindingsTable
    
end
/**
 * Returns list of control ids and text to display for each.
 */
function BindingsUI_GetBindingsTranslationData()

    local bindingsTranslationData = {}

    for i = 0, 255 do
    
        local text = string.upper(string.char(i))
        
        // Add special values (must match any values in 'defaults' above)
        for j = 1, table.count(specialKeys) do
        
            if(specialKeys[j][1] == text) then
            
                text = specialKeys[j][2]
                
            end
            
        end
        
        table.insert(bindingsTranslationData, {i, text})
        
    end
    
    local tableData = table.tostring(bindingsTranslationData)
    
    return bindingsTranslationData
    
end

/**
 * Called when bindings is exited and something was changed.
 */
function BindingsUI_ExitDialog()
    Client.ReloadKeyOptions()
end

function GetIsBinding(key, optionKey)
    local boundKey = BindingsUI_GetInputValue(optionKey)
    if tonumber(boundKey) then
        boundKey = "Num" .. boundKey
    end
    return InputKey[boundKey] == key
end
