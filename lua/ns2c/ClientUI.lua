-- ======= Copyright (c) 2013, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
--
-- lua\ClientUI.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com)
--
-- Creates and evaluates validity of UI scripts on the Client.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

ClientUI = { }

-- Below are the rules for what scripts should be active when the local player is on certain teams.
local kTeamTypes =
{
    "all",
    kTeamReadyRoom,
    kTeam1Index,
    kTeam2Index,
    kSpectatorIndex,
}

local kShowOnTeam = { }
kShowOnTeam["all"] =
{
    GUIGameEnd = true,
    GUIFeedback = true,
    GUIScoreboard = true,
    GUIDeathMessages = true, 
    GUIChat = true,
    GUIVoiceChat = true,
    GUIMinimapFrame = true,
    GUIMapAnnotations = true,
    GUICommunicationStatusIcons = true,
    GUIUnitStatus = true,
    GUIDeathScreen = true,
    GUIStartVoteMenu = true,
    GUIVoteMenu = true,
    GUISensorBlips = true
    --["ns2c/GUIHelpScreen"] = true
}

kShowOnTeam[kTeamReadyRoom] =
{
    GUIReadyRoomOrders = true,
    GUIRequestMenu = true,
    --GUIGameFeedback = true,
}

kShowOnTeam[kTeam1Index] =
{
	["ns2c/Hud/Marine/GUIMarineSpectatorHUD"] = true, 
}

kShowOnTeam[kTeam2Index] =
{
    GUIAlienSpectatorHUD = true,
}

kShowOnTeam[kSpectatorIndex] =
{
    GUISpectator = true,
}

local kBothAlienAndMarine = 
{ 
    GUICrosshair = true, 
    GUINotifications = true, 
    GUIDamageIndicators = true, 
    GUIWorldText = true,
    GUIPing = true, 
    GUIWaitingForAutoTeamBalance = true, 
    GUITechMap = true
}

for n, e in pairs(kBothAlienAndMarine) do

    kShowOnTeam[kTeam1Index][n] = e
    kShowOnTeam[kTeam2Index][n] = e
    
end

function AddClientUIScriptForTeam(showOnTeam, scriptName)
    kShowOnTeam[showOnTeam][scriptName] = true
end

-- Below are the rules for what scripts should be active when the local player is a certain class.
local kShowAsClass = { }

kShowAsClass["Marine"] = 
{ 
    ["Hud/Marine/GUIMarineHUD"] = true, 
    GUIPoisonedFeedback = true, 
    GUIPickups = true,
    GUIObjectiveDisplay = true,
    GUIProgressBar = true,
    GUIRequestMenu = true,
    GUIWaypoints = true,
    ["ns2c/Hud/Marine/GUIMarineDevoured"] = true,
    ["ns2c/Hud/Marine/GUIMotionTrackingDisplay"] = true
}

kShowAsClass["JetpackMarine"] =
{
    GUIJetpackFuel = true,
}

kShowAsClass["Exo"] = 
{
    GUIExoThruster = true
}
kShowAsClass["MarineSpectator"] = { GUIRequestMenu = true }
kShowAsClass["Alien"] = 
{ 
    GUIObjectiveDisplay = true,
    GUIProgressBar = true,
    GUIRequestMenu = true,
    GUIWaypoints = true,
    GUIAlienHUD = true,
    GUIEggDisplay = true,
    GUIRegenerationFeedback = true,
    GUIAuraDisplay = true,
    GUIHiveStatus = true
}
kShowAsClass["AlienSpectator"] = { GUIRequestMenu = true }
kShowAsClass["Commander"] = { GUICommanderOrders = true }
kShowAsClass["MarineCommander"] = { GUICommanderTutorial = true, GUISensorBlips = true, GUIDistressBeacon = true }
kShowAsClass["ReadyRoomPlayer"] = { }
kShowAsClass["TeamSpectator"] = { }
kShowAsClass["Spectator"] = { }


-- Any lua file loaded on demand should be listed here to avoid being loaded after game has started
local kMiscPreloads = {
    'Babbler',
    'GUIActionIcon',
    'GUIAlienBuyMenu',
    'GUIAlienTeamMessage',
    'GUIAnimatedScript',
    'GUIBabblerMoveIndicator',
    'GUIBorderBackground',
    'GUICommanderAlerts',
    'GUICommanderButtons',
    'GUICommanderButtonsAliens',
    'GUICommanderLogout',
    'GUICommanderManager',
    'GUICommanderTooltip',
    'GUIDial',
    'GUIHotkeyIcons',
    'GUIIncrementBar',
    'GUIList',
    'GUIMarineBuyMenu',
    'GUIMarineTeamMessage',
    'GUIMinimapButtons',
    'GUIParticleSystem',
    'GUIProduction',
    'GUIResourceDisplay',
    'GUIScript',
    'GUISelectionPanel',
    'GUIXenocideFeedback',
    'Hud/Commander/AlienGhostModel',
    'Hud/Commander/CystGhostModel',
    'Hud/Commander/GhostModel',
    'Hud/Commander/TeleportAlienGhostModel',
    'menu/GUIHoverTooltip',
    'menu/PlayScreen',
    'tweener/Tweener',
    'GUICommanderButtonsMarines',
    'GUICommanderButtons',
    'Hud/Commander/MarineGhostModel'

}

function AddClientUIScriptForClass(className, scriptName)

    kShowAsClass[className] = kShowAsClass[className] or { }
    kShowAsClass[className][scriptName] = true
    
end

local scripts = { }
local scriptCreationEventListeners = { }

function ClientUI.GetScript(name)
    return scripts[name]
end

function ClientUI.DestroyUIScripts()

    for name, script in pairs(scripts) do
        GetGUIManager():DestroyGUIScript(script)
    end
    scripts = { }
    
end

function ClientUI.AddScriptCreationEventListener(listener)
    table.insert(scriptCreationEventListeners, listener)
end

local function CheckPlayerIsOnTeam(forPlayer, teamType)
    return teamType == "all" or forPlayer:GetTeamNumber() == teamType
end

local removeScripts = { }
local function RemoveScripts(forPlayer)

    for name, script in pairs(scripts) do
    
        local shouldExist = false
        if forPlayer then
        
            -- Determine if this script should exist based on the team the forPlayer is on.
            for t = 1, #kTeamTypes do
            
                local teamType = kTeamTypes[t]
                if CheckPlayerIsOnTeam(forPlayer, teamType) or MainMenu_GetIsOpened() then
                
                    if kShowOnTeam[teamType][name] then
                    
                        shouldExist = true
                        if MainMenu_GetIsOpened() and teamType ~= "all" then
                            shouldExist = false
                        end

                        break
                        
                    end
                    
                end
                
            end
            
            -- Determine if this script should exist based on the class the forPlayer is.
            if not shouldExist then
            
                for class, scriptTable in pairs(kShowAsClass) do
                
                    if forPlayer:isa(class) or MainMenu_GetIsOpened() then
                    
                        if scriptTable[name] then
                        
                            -- Most scripts are not allowed in the Ready Room regardless of player class.
                            shouldExist = true
                            if CheckPlayerIsOnTeam(forPlayer, kTeamReadyRoom) then
                                shouldExist = kShowOnTeam[kTeamReadyRoom][name] and not MainMenu_GetIsOpened() or kShowOnTeam["all"][name]
                            elseif MainMenu_GetIsOpened() and not kShowOnTeam["all"][name] then
                                shouldExist = false
                            end
                            
                            break
                            
                        end
                        
                    end
                    
                end
                
            end
            
        end
        
        if not shouldExist then
            table.insert(removeScripts, name)
        end
        
    end
    
    if #removeScripts > 0 then
    
        for s = 1, #removeScripts do
        
            local script = scripts[removeScripts[s]]
            GetGUIManager():DestroyGUIScript(script)
            scripts[removeScripts[s]] = nil
            
        end
        removeScripts = { }
        
    end
    
end

local function NotifyListenersOfScriptCreation(scriptName, script)

    for i = 1, #scriptCreationEventListeners do
        scriptCreationEventListeners[i](scriptName, script)
    end
    
end

local function AddScripts(forPlayer)

    if forPlayer then
    
        for t = 1, #kTeamTypes do
        
            local teamType = kTeamTypes[t]
            if CheckPlayerIsOnTeam(forPlayer, teamType) then
            
                for name, exists in pairs(kShowOnTeam[teamType]) do
                
                    if exists and scripts[name] == nil and not MainMenu_GetIsOpened() then
                    
                        scripts[name] = GetGUIManager():CreateGUIScript(name)
                        NotifyListenersOfScriptCreation(name, scripts[name])
                        
                    end
                    
                end
                
            end
            
        end
        
        for class, scriptTable in pairs(kShowAsClass) do
        
            if forPlayer:isa(class) and not MainMenu_GetIsOpened() then
            
                for name, exists in pairs(scriptTable) do
                
                    -- Most scripts are not allowed in the Ready Room regardless of player class.
                    local allowed = exists
                    if CheckPlayerIsOnTeam(forPlayer, kTeamReadyRoom) then
                        allowed = allowed and (not MainMenu_GetIsOpened() and kShowOnTeam[kTeamReadyRoom][name]) or kShowOnTeam["all"][name]
                    end
                    
                    if allowed and scripts[name] == nil then
                    
                        scripts[name] = GetGUIManager():CreateGUIScript(name)
                        NotifyListenersOfScriptCreation(name, scripts[name])
                        
                    end
                    
                end
                
            end
            
        end
        
    end
    
end

local function NotifyScriptsOfPlayerChange(forPlayer)

    for name, script in pairs(scripts) do
    
        if script.OnLocalPlayerChanged then
            script:OnLocalPlayerChanged(forPlayer)
        end
        
    end
    
end

function ClientUI.EvaluateUIVisibility(forPlayer)

    RemoveScripts(forPlayer)
    AddScripts(forPlayer)
    
    NotifyScriptsOfPlayerChange(forPlayer)
    
end

local function PrintUIScripts()

    for name, script in pairs(scripts) do
        Shared.Message(name)
    end
    
end
Event.Hook("Console_print_client_ui", PrintUIScripts)

function PreLoadGUIScripts()

    for team, uiScripts in pairs(kShowOnTeam) do
    
        for name, enabled in pairs(uiScripts) do
            
            if enabled then
                Script.Load("lua/" .. name .. ".lua")
            end
            
        end 

    end   

    for name, enabled in pairs(kBothAlienAndMarine) do
        
        if enabled then
            Script.Load("lua/" .. name .. ".lua")
        end
        
    end
    
    for class, uiScripts in pairs(kShowAsClass) do

        for name, enabled in pairs(uiScripts) do
            
            if enabled then
                Script.Load("lua/" .. name .. ".lua")
            end
            
        end
    
    end
    
    local showSorted = false
    table.sort(kMiscPreloads)
    local duplicateSet = {}
    for _, name in ipairs(kMiscPreloads) do
        if showSorted then
            if not duplicateSet[name] then
                Print("    '%s',", name)
                duplicateSet[name] = true
            end
        end
        Script.Load("lua/" .. name .. ".lua")
    end

end

local hiddenScripts = {}
function ClientUI.GetScriptVisibility(scriptName)
    
    if hiddenScripts[scriptName] then
        return false
    end
    
    return true
    
end

local kImplCheck = { "SetIsVisible", "GetIsVisible" } -- required method names for GUIScript's used in ClientUI methods.
local missingImpl = {} -- dict of script names that didn't have all required methods implemented.

-- Checks the given GUIScript to ensure it's implemented certain required methods.  If not, it will log an error
-- message, but only once, so as to not spam the user's console.
-- Returns true if the script has implemented all needed methods, false if not.
function ClientUI.PerformScriptImplementChecks(scriptName)
    
    local script = ClientUI.GetScript(scriptName)
    if not script then
        return nil
    end
    
    local missing = {}
    for i=1, #kImplCheck do
        if script[kImplCheck[i]] == nil then
            missing[#missing+1] = kImplCheck[i]
        end
    end
    
    if #missing == 0 then
        -- not missing any methods, no further action needed.
        return true
    end
    
    if #missing > 0 and missingImpl[scriptName] then
        -- already warned for this script, skip error messages.
        return false
    end
    
    -- Print the needed error messages.
    if #missing > 1 then
        if #missing == 2 then
            Log("ERROR!  The methods '%s' and '%s' were not implemented in GUIScript '%s'.", missing[1], missing[2], scriptName)
        else
            local methodNameList = ""
            for i=1, #missing do
                methodNameList = methodNameList.."'"..missing[i].."'"
                if i < #missing-1 then
                    methodNameList = methodNameList..", "
                elseif i == #missing-1 then
                    methodNameList = methodNameList..", and " -- oxford comma ftw!!!
                end
            end
            Log("ERROR!  The methods %s were not implemented in GUIScript '%s'.", methodNameList, scriptName)
        end
    elseif #missing == 1 then
        Log("ERROR!  The method '%s' was not implemented in GUIScript '%s'.", missing[1], scriptName)
    end
    
    -- mark down that these error messages have been delivered.
    missingImpl[scriptName] = true
    
    return false
    
end

-- Performs the actual call to SetIsVisible for a gui script.  Called whenever a GUIScript is created, or
-- when its visibility is set via ClientUI.SetScriptVisiblity()
function ClientUI.UpdateScriptVisibility(scriptName)
    
    ClientUI.PerformScriptImplementChecks(scriptName)
    
    local script = ClientUI.GetScript(scriptName)
    if not script then
        return
    end
    
    local result = ClientUI.PerformScriptImplementChecks(scriptName)
    if result == false then
        return
    end
    
    local shouldBeVisible = ClientUI.GetScriptVisibility(scriptName)
    local isVisible = script:GetIsVisible()
    if isVisible == nil then
        Log("ERROR!  Call to %s's GetIsVisible() method returned nil!", scriptName)
        return
    end
    
    if shouldBeVisible ~= isVisible then
        script:SetIsVisible(shouldBeVisible)
    end
    
end

-- New way of hiding/unhiding UI elements.  Should NOT use old, direct access of script:SetIsVisible().
-- Parameters:
--      scriptName      string      Name of GUIScript (that ClientUI will recognize).
--      invokerName     string      Name of component or functionality that is making the visibility change.
--      isVisible       bool        Whether or not this particular invoker wishes the GUI script to be visible.
-- A gui script will ONLY be visible in the event that ALL of its invokers wish it to be visible.  This ensures
-- no functionality can un-hide a UI element that some other functionality wishes to remain hidden.
function ClientUI.SetScriptVisibility(scriptName, invokerName, isVisible)
    
    if not invokerName then
        Log("ERROR:  Invalid parameter to ClientUI.SetScriptVisiblity().  A valid \"invokerName\" must be specified. (was %s)", invokerName);
        Log("%s", debug.traceback())
        return
    end
    
    local script = ClientUI.GetScript(scriptName)
    -- Can be nil.  Check before using, but should silently fail.  We check individually because
    -- we want scripts being set visible/invisible to still happen even if the script doesn't YET
    -- exist.  Prevents issues where a script is set invisible before it is created, then created
    -- visible.  Scripts must simply check with ClientUI if they are visible or not upon
    -- initialization.
    
    if isVisible then
        
        if not hiddenScripts[scriptName] then
            -- script wasn't hidden...
            return
        end
        
        if hiddenScripts[scriptName].invokers[invokerName] then
            hiddenScripts[scriptName].invokers[invokerName] = nil
            hiddenScripts[scriptName].refCount = hiddenScripts[scriptName].refCount - 1
        end
        
        if hiddenScripts[scriptName].refCount == 0 then
            hiddenScripts[scriptName] = nil
        end
        
    else
        
        hiddenScripts[scriptName] = hiddenScripts[scriptName] or {invokers = {}, refCount = 0,}
        if not hiddenScripts[scriptName].invokers[invokerName] then
            hiddenScripts[scriptName].refCount = hiddenScripts[scriptName].refCount + 1
            hiddenScripts[scriptName].invokers[invokerName] = true
        end
        
    end
    
    ClientUI.UpdateScriptVisibility(scriptName)
    
end

