-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\ConsoleCommands_Client.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


-- NS2c
-- Changed debugspeed to not require cheats

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

    if Shared.GetCheatsEnabled() or Shared.GetTestsEnabled() then
        distanceDisplayedOnScreen = not distanceDisplayedOnScreen
    end
    
end

local animationInputsDisplayedOnScreen
local function OnCommandAnimInputs(entId)

    if Shared.GetCheatsEnabled() then
        Log("Showing animation inputs for %s", entId)
        animationInputsDisplayedOnScreen = tonumber(entId)
    end
    
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

-- Save this setting if we set it via a console command
function OnCommandSetName(...)
    
    local overrideEnabled = Client.GetOptionBoolean(kNicknameOverrideKey, false)
    if not overrideEnabled then
		Print( "Use 'sname <name>' to change your Steam Name")
		return
	end
		
	local name = StringConcatArgs(...)
	name = string.UTF8SanitizeForNS2( TrimName(name) )
	
	if name == "" or not string.IsValidNickname(name) then
		Print( "You have to enter a valid nickname or use the Options Menu!")
		return
	end
	
	Client.SetOptionString(kNicknameOptionsKey, name)
	
	local player = Client.GetLocalPlayer()
	if player and name ~= player:GetName() then
		Client.SendNetworkMessage("SetName", { name = name }, true)
	end
end

function OnCommandSetSteamName(...)
    local overrideEnabled = Client.GetOptionBoolean(kNicknameOverrideKey, false)
    if overrideEnabled then
		Print( "Use 'name <name>' to change your NS2 in-game alias, or enable 'Use Steam Name' in the option menu")
		return
	end

	local name = StringConcatArgs(...)
	name = string.UTF8SanitizeForNS2( TrimName(name) )
	
	if name == "" or not string.IsValidNickname(name) then
		Print( "You have to enter a valid nickname or use the Options Menu!")
		return
	end
	
	-- Allow this to change their actual steam name
	-- the in-game representation will be set via a OnPersonaChanged event
	Client.SetUserName( name )
end

local function OnCommandClearDebugLines()
    Client.ClearDebugLines()
end

local function OnCommandGUIInfo()
    GUI.PrintItemInfoToLog()
end

local function OnCommandPlayMusic(name)
    Client.PlayMusic(name)
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

local function OnCommandDebugFeedback()
    
    if not gFeedbackDebug then
        gFeedbackDebug = GetGUIManager():CreateGUIScriptSingle("GUIGameFeedback")
        gFeedbackDebug:SetIsVisible(true)
    else
    
        GetGUIManager():DestroyGUIScriptSingle("GUIGameFeedback")
        gFeedbackDebug = nil
        
    end

end

local function OnCommandDebugNotifications()

    if gDebugNotifications then
        gDebugNotifications = false
    else
        gDebugNotifications = true
    end    

end

local kSayTeamDelay = 3
local timeLastSayTeam
function OnCommandSayTeam(...)
    
    if not timeLastSayTeam or timeLastSayTeam + kSayTeamDelay < Shared.GetTime() then
        
        local chatMessage = StringConcatArgs(...)
        chatMessage = string.UTF8Sub(chatMessage, 1, kMaxChatLength)
        
        if string.len(chatMessage) > 0 then
            
            local player = Client.GetLocalPlayer()
            local playerName = player:GetName()
            local playerLocationId = player.locationId
            local playerTeamNumber = player:GetTeamNumber()
            local playerTeamType = player:GetTeamType()
            
            Client.SendNetworkMessage("ChatClient", BuildChatMessage(true, playerName, playerLocationId, playerTeamNumber, playerTeamType, chatMessage), true)		
        end
        
        timeLastSayTeam = Shared.GetTime()
    end
end

Event.Hook("Console_tsay", OnCommandSayTeam)

local function OnCommandDumpTechTree()
    local player = Client.GetLocalPlayer()
    if player ~= nil then
        local techTree = GetTechTree()
        if techTree ~= nil then
            for index, techNode in pairs(techTree.nodeList) do
                techNode:DumpNode()
            end
        end
    end
end

Event.Hook("Console_soundgeometry", OnCommandSoundGeometry)
Event.Hook("Console_oneffectdebug", OnCommandEffectDebug)
Event.Hook("Console_debugtext", OnCommandDebugText)
Event.Hook("Console_locate", OnCommandLocate)
Event.Hook("Console_distance", OnCommandDistance)
Event.Hook("Console_animinputs", OnCommandAnimInputs)
Event.Hook("Console_name", OnCommandSetName)
Event.Hook("Console_sname", OnCommandSetSteamName)
Event.Hook("Console_cleardebuglines", OnCommandClearDebugLines)
Event.Hook("Console_guiinfo", OnCommandGUIInfo)
Event.Hook("Console_playmusic", OnCommandPlayMusic)

-- Options Console Commands
Event.Hook("Console_setsoundvolume", OnCommandSetSoundVolume)
Event.Hook("Console_sethudmap", OnCommandHUDMapEnabled)
-- Just a shortcut.
Event.Hook("Console_ssv", OnCommandSetSoundVolume)
Event.Hook("Console_setmusicvolume", OnCommandSetMusicVolume)
Event.Hook("Console_setvoicevolume", OnCommandSetVoiceVolume)
Event.Hook("Console_setvv", OnCommandSetVoiceVolume)
Event.Hook("Console_setsensitivity", OnCommandSetMouseSensitivity)
Event.Hook("Console_pathingfill", OnCommandPathingFill)

Event.Hook("Console_cfindref", OnCommandFindRef)
Event.Hook("Console_debugspeed", OnCommandDebugSpeed)
Event.Hook("Console_debugfeedback", OnCommandDebugFeedback)
Event.Hook("Console_debugnotifications", OnCommandDebugNotifications)
Event.Hook("Console_dumptechtree", OnCommandDumpTechTree)

local function OnUpdateClient()
    Client.SetDebugText("ConsoleCommands.OnUpdateClient entry")
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
        
    Client.SetDebugText("ConsoleCommands.OnUpdateClient exit")
end
Event.Hook("UpdateClient", OnUpdateClient,"ConsoleCommands")