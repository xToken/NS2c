// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ConsoleCommands_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function OnCommandOnClientDisconnect(clientIndexString)
    Scoreboard_OnClientDisconnect(tonumber(clientIndexString))
end

// Called when player receives points from an action
function OnCommandPoints(pointsString, resString)

    local points = tonumber(pointsString)
    local res = tonumber(resString)
    ScoreDisplayUI_SetNewScore(points, res)
    
end

function OnCommandSoundGeometry(enabled)

    enabled = enabled ~= "false"
    Shared.Message("Sound geometry occlusion enabled: " .. tostring(enabled))
    Client.SetSoundGeometryEnabled(enabled)
    
end

function OnCommandEffectDebug(className)

    Print("OnCommandEffectDebug(\"%s\")", ToString(className))
    if Shared.GetDevMode() then
    
        if className and className ~= "" then
            gEffectDebugClass = className
        elseif gEffectDebugClass ~= nil then
            gEffectDebugClass = nil
        else
            gEffectDebugClass = ""
        end
    end
    
end

function OnCommandDebugText(debugText, worldOriginString, entIdString)

    if Shared.GetDevMode() then
    
        local success, origin = DecodePointFromString(worldOriginString)
        if success then
        
            local ent = nil
            if entIdString then
                local id = tonumber(entIdString)
                if id and (id >= 0) then
                    ent = Shared.GetEntity(id)
                end
            end
            
            GetEffectManager():AddDebugText(debugText, origin, ent)
            
        else
            Print("OnCommandDebugText(%s, %s): Couldn't decode point.", debugText, worldOriginString)
        end
        
    end
    
end

local locationDisplayedOnScreen = false
function OnCommandLocate(displayOnScreen)

    local player = Client.GetLocalPlayer()
    
    if player ~= nil then
    
        local origin = player:GetOrigin()
        Shared.Message(string.format("Player is located at %f %f %f", origin.x, origin.y, origin.z))
        
    end
    
    locationDisplayedOnScreen = displayOnScreen == "true"
    
end

local distanceDisplayedOnScreen = false
local function OnCommandDistance()

    if Shared.GetCheatsEnabled() then
        distanceDisplayedOnScreen = not distanceDisplayedOnScreen
    end
    
end

local animationInputsDisplayedOnScreen = nil
local function OnCommandAnimInputs(entId)

    if Shared.GetCheatsEnabled() then
        Log("Showing animation inputs for %s", entId)
        animationInputsDisplayedOnScreen = tonumber(entId)
    end
    
end

local displayFPS = false
local function OnCommandDisplayFPS()
    displayFPS = not displayFPS
end

local function OnCommandSetSoundVolume(volume)

    if volume == nil then
        Print("Sound volume is (0-100): %s", OptionsDialogUI_GetSoundVolume())
    else
        OptionsDialogUI_SetSoundVolume(tonumber(volume))
    end
    
end

function OnCommandSetMusicVolume(volume)
    if(volume == nil) then
        Print("Music volume is (0-100): %s",  OptionsDialogUI_GetMusicVolume())
    else
        OptionsDialogUI_SetMusicVolume( tonumber(volume) )
    end
end

function OnCommandSetVoiceVolume(volume)
    if(volume == nil) then
        Print("Voice volume is (0-100): %s",  OptionsDialogUI_GetVoiceVolume())
    else
        OptionsDialogUI_SetVoiceVolume( tonumber(volume) )
    end
end

function OnCommandSetMouseSensitivity(sensitivity)
    if(sensitivity == nil) then
        Print("Mouse sensitivity is %s",  OptionsDialogUI_GetMouseSensitivity())
    else
        OptionsDialogUI_SetMouseSensitivity( tonumber(sensitivity) )
    end
end

// Save this setting if we set it via a console command
function OnCommandSetName(nickname)

    if type(nickname) ~= "string" then
        return
    end
    
    local player = Client.GetLocalPlayer()
    nickname = TrimName(nickname)
    
    if player ~= nil then
    
        if nickname == player:GetName() or nickname == kDefaultPlayerName or string.len(nickname) < 0 then
            return
        end
        
    end
    
    Client.SetOptionString(kNicknameOptionsKey, nickname)
    Client.SendNetworkMessage("SetName", { name = nickname }, true)
    
end

local function OnCommandClearDebugLines()
    Client.ClearDebugLines()
end

local function OnCommandGUIInfo()
    GUI.PrintItemInfoToLog()
end

function OnCommandPathingFill()

    local player = Client.GetLocalPlayer()
    Pathing.FloodFill(player:GetOrigin())
    
end

function OnCommandHUDMapEnabled(enabled)

    GetGUIManager():SetHUDMapEnabled(enabled == "true")
    gHUDMapEnabled = enabled == "true"
    
end

local function OnCommandFindRef(className)

    if Shared.GetCheatsEnabled() then
    
        if className ~= nil then
            Debug.FindTypeReferences(className)        
        end
        
    end
    
end

local function OnCommandDebugSpeed()

    if not gSpeedDebug then
        gSpeedDebug = GetGUIManager():CreateGUIScriptSingle("GUISpeedDebug")
    else
    
        GetGUIManager():DestroyGUIScriptSingle("GUISpeedDebug")
        gSpeedDebug = nil
        
    end
    
end

local function OnCommandDebugNotifications()

    if gDebugNotifications then
        gDebugNotifications = false
    else
        gDebugNotifications = true
    end    
    
end

Event.Hook("Console_clientdisconnect", OnCommandOnClientDisconnect)
Event.Hook("Console_points", OnCommandPoints)
Event.Hook("Console_soundgeometry", OnCommandSoundGeometry)
Event.Hook("Console_oneffectdebug", OnCommandEffectDebug)
Event.Hook("Console_debugtext", OnCommandDebugText)
Event.Hook("Console_locate", OnCommandLocate)
Event.Hook("Console_distance", OnCommandDistance)
Event.Hook("Console_animinputs", OnCommandAnimInputs)
Event.Hook("Console_fps", OnCommandDisplayFPS)
Event.Hook("Console_name", OnCommandSetName)
Event.Hook("Console_cleardebuglines", OnCommandClearDebugLines)
Event.Hook("Console_guiinfo", OnCommandGUIInfo)

// Options Console Commands
Event.Hook("Console_setsoundvolume", OnCommandSetSoundVolume)
Event.Hook("Console_sethudmap", OnCommandHUDMapEnabled)
// Just a shortcut.
Event.Hook("Console_ssv", OnCommandSetSoundVolume)
Event.Hook("Console_setmusicvolume", OnCommandSetMusicVolume)
Event.Hook("Console_setvoicevolume", OnCommandSetVoiceVolume)
Event.Hook("Console_setvv", OnCommandSetVoiceVolume)
Event.Hook("Console_setsensitivity", OnCommandSetMouseSensitivity)
Event.Hook("Console_pathingfill", OnCommandPathingFill)

Event.Hook("Console_cfindref", OnCommandFindRef)
Event.Hook("Console_debugspeed", OnCommandDebugSpeed)
Event.Hook("Console_debugnotifications", OnCommandDebugNotifications)

local function OnUpdateClient()

    if displayFPS then
        Client.ScreenMessage(string.format("FPS: %.0f", Client.GetFrameRate()))
    end
    
    local player = Client.GetLocalPlayer()
    if locationDisplayedOnScreen == true then
    
        local origin = player:GetOrigin()
        Client.ScreenMessage(string.format("%.2f %.2f %.2f", origin.x, origin.y, origin.z))
        
    end
    
    if distanceDisplayedOnScreen == true then
    
        local startPoint = player:GetEyePos()
        local viewAngles = player:GetViewAngles()
        local fowardCoords = viewAngles:GetCoords()
        local trace = Shared.TraceRay(startPoint, startPoint + (fowardCoords.zAxis * 10000), CollisionRep.LOS, PhysicsMask.AllButPCs, EntityFilterOne(player))
        
        Client.ScreenMessage(string.format("%.2f", (trace.endPoint - startPoint):GetLength()))
        
        if trace.entity then
            Client.ScreenMessage(GetEntityInfo(trace.entity))
        end
        
    end
    
    if animationInputsDisplayedOnScreen ~= nil then
    
        local ent = Shared.GetEntity(animationInputsDisplayedOnScreen)
        if ent then
        
            for name, value in pairs(ent.animationInputValues) do
                Client.ScreenMessage(name .. " = " .. ToString(value))
            end
            
        end
        
    end
    
end
Event.Hook("UpdateClient", OnUpdateClient)