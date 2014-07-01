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
    { "Taunt", "T" },
    { "PingLocation", "MouseButton2" },
    { "Buy", "B" },
    { "VoteYes", "F1" },
    { "VoteNo", "F2" },
    { "SelectNextWeapon", "MouseWheelUp" },
    { "SelectPrevWeapon", "MouseWheelDown" },
	{ "LastUpgrades", "" },
	{ "ToggleMinimapNames", "" },
    { "Grid1", "Q" },
    { "Grid2", "W" },
    { "Grid3", "E" },
    { "Grid4", "A" },
    { "Grid5", "S" },
    { "Grid6", "D" },
    { "Grid7", "F" },
    { "Grid8", "Z" },
    { "Grid9", "X" },
    { "Grid10", "C" },
    { "Grid11", "V" },
	{ "ShowMapCom", "C" },
    { "VoiceChatCom", "LeftAlt" },
    { "TextChatCom", "Return" },
    { "TeamChatCom", "Y" }
}

// Order, names, description of keys in menu
local globalControlBindings = {
    "Movement", "title", "Movement", "",
    "MoveForward", "input", "Move forward", "W",
    "MoveLeft", "input", "Move left", "A",
    "MoveBackward", "input", "Move backward", "S",
    "MoveRight", "input", "Move right", "D",
    "Jump", "input", "Jump", "Space",
    "MovementModifier", "input", "Movement special", "LeftShift",
    "Crouch", "input", "Crouch", "LeftControl",
	"ShowMap", "input", "Show Map", "C",
    "Action", "title", "Action", "",
    "PrimaryAttack", "input", "Primary attack", "MouseButton0",
    "SecondaryAttack", "input", "Secondary attack", "MouseButton1",
    "Reload", "input", "Reload", "R",
    "Use", "input", "Use", "E",
    "Drop", "input", "Drop weapon / Eject", "G",
    "Buy", "input", "Buy/evolve menu", "B",
	"LastUpgrades", "input", "Evolve Last Upgrades", "",
	"ShowTechMap", "input", "Show Tech Tree", "J",
    "Scoreboard", "input", "Scoreboard", "Tab",
    "VoiceChat", "input", "Use microphone", "LeftAlt",
    "TextChat", "input", "Public chat", "Y",
    "TeamChat", "input", "Team chat", "Return",
	"ToggleMinimapNames", "input", "Toggle Minimap Names", "",
    "SelectNextWeapon", "input", "Next Weapon", "MouseWheelUp",
    "SelectPrevWeapon", "input", "Previous Weapon", "MouseWheelDown",
    "Weapon1", "input", "Weapon #1", "1",
    "Weapon2", "input", "Weapon #2", "2",
    "Weapon3", "input", "Weapon #3", "3",
    "Weapon4", "input", "Weapon #4", "4",
    "Weapon5", "input", "Weapon #5", "5",
    "Weapon6", "input", "Weapon #6", "6",
    "Weapon7", "input", "Weapon #7", "7",
    "Weapon8", "input", "Weapon #8", "8",
    "Weapon9", "input", "Weapon #9", "9",
    "Weapon0", "input", "Weapon #0", "0",
    "QuickSwitch", "input", "Quick switch", "V",
    "ToggleConsole", "input", "Toggle Console", "Grave",
    "ToggleFlashlight", "input", "Flashlight", "F",
    "ReadyRoom", "input", "Go to Ready Room", "F4",
    "RequestMenu", "input", "Voiceover menu", "X",
    "RequestHealth", "input", "Request healing / medpack", "Q",
    "RequestAmmo", "input", "Request Ammo / Enzyme", "Z",
    "RequestOrder", "input", "Request order", "H",
    "Taunt", "input", "taunt", "T",
    "PingLocation", "input", "ping location", "MouseButton2",
    "VoteYes", "input", "Vote Yes", "F1",
    "VoteNo", "input", "Vote No", "F2",
}

local globalComControlBindings = {
    "Grid1", "input", "Grid Spot 1 (Default Q)", "U",
    "Grid2", "input", "Grid Spot 2 (Default W)", "W",
    "Grid3", "input", "Grid Spot 3 (Default E)", "E",
    "Grid4", "input", "Grid Spot 4 (Default A)", "A",
    "Grid5", "input", "Grid Spot 5 (Default S)", "S",
    "Grid6", "input", "Grid Spot 6 (Default D)", "D",
    "Grid7", "input", "Grid Spot 7 (Default F)", "F",
    "Grid8", "input", "Grid Spot 8 (Default Z)", "Z",
    "Grid9", "input", "Grid Spot 9 (Default X)", "X",
    "Grid10", "input", "Grid Spot 10 (Default C)", "C",
    "Grid11", "input", "Grid Spot 11 (Default V)", "V",
    "ShowMapCom", "input", "Show Map", "C",
	"VoiceChatCom", "input", "Use microphone", "LeftAlt",
    "TextChatCom", "input", "Public chat", "Y",
    "TeamChatCom", "input", "Team chat", "Return",
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
