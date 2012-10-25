// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Set the name of the VM for debugging
decoda_name = "Client"

Script.Load("lua/Shared.lua")
Script.Load("lua/GhostModelUI.lua")
Script.Load("lua/Render.lua")
Script.Load("lua/MapEntityLoader.lua")
Script.Load("lua/Button.lua")
Script.Load("lua/Chat.lua")
Script.Load("lua/DeathMessage_Client.lua")
Script.Load("lua/DSPEffects.lua")
Script.Load("lua/Notifications.lua")
Script.Load("lua/Scoreboard.lua")
Script.Load("lua/ScoreDisplay.lua")
Script.Load("lua/AlienBuy_Client.lua")
Script.Load("lua/MarineBuy_Client.lua")
Script.Load("lua/Tracer_Client.lua")
Script.Load("lua/GUIManager.lua")
Script.Load("lua/GUIDebugText.lua")
Script.Load("lua/TrailCinematic.lua")
Script.Load("lua/MenuManager.lua")
Script.Load("lua/BindingsDialog.lua")
Script.Load("lua/MainMenu.lua")
Script.Load("lua/ConsoleBindings.lua")

Script.Load("lua/ServerAdmin.lua")

Script.Load("lua/ConsoleCommands_Client.lua")
Script.Load("lua/NetworkMessages_Client.lua")

Script.Load("lua/HiveVision.lua")

// Precache the common surface shaders.
Shared.PrecacheSurfaceShader("shaders/Model.surface_shader")
Shared.PrecacheSurfaceShader("shaders/Emissive.surface_shader")
Shared.PrecacheSurfaceShader("shaders/Model_emissive.surface_shader")
Shared.PrecacheSurfaceShader("shaders/Model_alpha.surface_shader")

Client.propList = { }
Client.lightList = { }
Client.skyBoxList = { }
Client.tracersList = { }
Client.fogAreaModifierList = { }
Client.rules = { }
Client.cinematics = { }
Client.trailCinematics = { }
// cinematics which are queued for destruction next frame
Client.destroyTrailCinematics = { }
Client.worldMessages = { }

// For logging total time played for rookie mode, even with map switch
local timePlayed = nil
local kTimePlayedOptionsKey = "timePlayedSeconds"

local waitingForAutoTeamBalanceUI = GetGUIManager():CreateGUIScript("GUIWaitingForAutoTeamBalance")

function GetRenderCameraCoords()

    if gRenderCamera then
        return gRenderCamera:GetCoords()
    end

    return Coords.GetIdentity()    
    
end

// Displays the "F1 for feedback" text.
GetGUIManager():CreateGUIScript("GUIFeedback")

// Client tech tree
local gTechTree = TechTree()
gTechTree:Initialize() 

function GetTechTree()
    return gTechTree
end

function ClearTechTree()
    gTechTree:Initialize()    
end

/**
 * Destroys all of the objects created during the level load by the
 * OnMapLoadEntity function.
 */
function DestroyLevelObjects()

    // Remove all of the props.
    if Client.propList ~= nil then
        for index, models in ipairs(Client.propList) do
            Client.DestroyRenderModel(models[1])
            Shared.DestroyCollisionObject(models[2])
        end
        Client.propList = { }
    end
    
    // Remove the lights.    
    if Client.lightList ~= nil then
        for index, light in ipairs(Client.lightList) do
            Client.DestroyRenderLight(light)
        end
        Client.lightList = { }
    end
    
    // Remove the billboards.  
    if Client.billboardList ~= nil then  
        for index, billboard in ipairs(Client.billboardList) do
            Client.DestroyRenderBillboard(billboard)
        end
        Client.billboardList = { }
    end

    // Remove the reflection probes.
    if Client.reflectionProbeList ~= nil then
    
        for index, reflectionProbe in ipairs(Client.reflectionProbeList) do
            Client.DestroyRenderReflectionProbe(reflectionProbe)
        end
        Client.reflectionProbeList = { }
        
    end
    
    // Remove the cinematics.
    if Client.cinematics ~= nil then
    
        for index, cinematic in ipairs(Client.cinematics) do
            Client.DestroyCinematic(cinematic)
        end
        Client.cinematics = { }
        
    end
    
    // Remove the skyboxes.
    Client.skyBoxList = { }
    
    Client.tracersList = { }
    Client.rules = { }
    
end

function ExitPressed()

    if not Shared.GetIsRunningPrediction() then
    
        // Close buy menu if open, otherwise show in-game menu
        if MainMenu_GetIsOpened() then
            MainMenu_ReturnToGame()
        else
        
            if not Client.GetLocalPlayer():CloseMenu() then
                MainMenu_Open()
            end
            
        end
        
    end
    
end

/**
 * Called as the map is being loaded to create the entities. If no group, groupName will be "".
 */
function OnMapLoadEntity(className, groupName, values)

    // Create render objects.
    if className == "color_grading" then
    
        // Disabled temporarily because it's crashing
        Print("color_grading map entity ignored (temporarily disabled)")
        /*
        local renderColorGrading = Client.CreateRenderColorGrading()
        
        renderColorGrading:SetOrigin( values.origin )
        renderColorGrading:SetBalance( values.balance )
        renderColorGrading:SetBrightness( values.brightness )
        renderColorGrading:SetContrast( values.contrast )
        renderColorGrading:SetRadius( values.distance )
        renderColorGrading:SetGroup(groupName)
        */
        
    elseif className == "fog_controls" then
    
        Client.globalFogControls = values
        Client.SetZoneFogDepthScale(RenderScene.Zone_ViewModel, 0.0 / values.view_zone_scale)
        Client.SetZoneFogColor(RenderScene.Zone_ViewModel, values.view_zone_color)
        
        Client.SetZoneFogDepthScale(RenderScene.Zone_SkyBox, 0.0 / values.skybox_zone_scale)
        Client.SetZoneFogColor(RenderScene.Zone_SkyBox, values.skybox_zone_color)
        
        Client.SetZoneFogDepthScale(RenderScene.Zone_Default, 0.0 / values.default_zone_scale)
        Client.SetZoneFogColor(RenderScene.Zone_Default, values.default_zone_color)
        
    elseif className == "fog_area_modifier" then
    
        assert(values.start_blend_radius > values.end_blend_radius, "Error: fog_area_modifier must have a larger start blend radius than end blend radius")
        table.insert(Client.fogAreaModifierList, values)
        
    elseif className == "minimap_extents" then
    
        if not Client.rules.numberMiniMapExtents then
            Client.rules.numberMiniMapExtents = 0
        end
        Client.rules.numberMiniMapExtents = Client.rules.numberMiniMapExtents + 1
        Client.minimapExtentScale = values.scale
        Client.minimapExtentOrigin = values.origin
        
    // Only create the client side cinematic if it isn't waiting for a signal to start.
    // Otherwise the server will create the cinematic.
    elseif className == "skybox" or (className == "cinematic" and (values.startsOnMessage == "" or values.startsOnMessage == nil)) then
    
        local coords = values.angles:GetCoords(values.origin)
        
        local zone = RenderScene.Zone_Default
        
        if className == "skybox" then
            zone = RenderScene.Zone_SkyBox
        end
        
        local cinematic = Client.CreateCinematic(zone)
        
        cinematic:SetCinematic(values.cinematicName)
        cinematic:SetCoords(coords)
        
        local repeatStyle = Cinematic.Repeat_None
        
        if (values.repeatStyle == 0) then
            repeatStyle = Cinematic.Repeat_None
        elseif (values.repeatStyle == 1) then
            repeatStyle = Cinematic.Repeat_Loop
        elseif (values.repeatStyle == 2) then
            repeatStyle = Cinematic.Repeat_Endless
        end
        
        if className == "skybox" then
        
            table.insert(Client.skyBoxList, cinematic)
            
            // Becuase we're going to hold onto the skybox, make sure it
            // uses the endless repeat style so that it doesn't delete itself
            repeatStyle = Cinematic.Repeat_Endless
            
        end
        
        cinematic:SetRepeatStyle(repeatStyle)
        table.insert(Client.cinematics, cinematic)
        
    //elseif className == AmbientSound.kMapName then
    
        //local entity = AmbientSound()
        //LoadEntityFromValues(entity, values)
        // Precache the ambient sound effects
        //Shared.PrecacheSound(entity.eventName)
        //table.insert(Client.ambientSoundList, entity)
        
    elseif className == Reverb.kMapName then
    
        //local entity = Reverb()
        //LoadEntityFromValues(entity, values)
        //entity:OnLoad()
        
    elseif className == "pathing_settings" then
        ParsePathingSettings(values)
    else
    
        // $AS FIXME: We are special caasing techPoints for pathing right now :/ 
        if (className == "tech_point") then
            local coords = values.angles:GetCoords(values.origin)
            Pathing.CreatePathingObject(TechPoint.kModelName, coords)
            Pathing.AddFillPoint(values.origin)
        end
        // Allow the MapEntityLoader to load it if all else fails.
        LoadMapEntity(className, groupName, values)
        
    end
    
end

// TODO: Change this to setting the alpha instead of visibility when supported
function SetCommanderPropState(isComm)

    for index, propPair in ipairs(Client.propList) do
        local prop = propPair[1]
        if prop.commAlpha < 1 then
            prop:SetIsVisible(not isComm)
        end
    end

end

local function ExpireDebugText()

    // Expire debug text items after lifetime has elapsed        
    local numElements = table.maxn(gDebugTextList)

    for i = 1, numElements do
    
        local elementPair = gDebugTextList[i]
        
        if elementPair and elementPair[1]:GetExpired() then
        
            GetGUIManager():DestroyGUIScript(elementPair[1])
            
            table.remove(gDebugTextList, i)
                
            numElements = numElements - 1
            
            i = i - 1
            
        end
        
    end
        
end

local function UpdateTrailCinematics(deltaTime)

    for index, destroyCinematic in ipairs(Client.destroyTrailCinematics) do
        Client.DestroyTrailCinematic(destroyCinematic)
    end

    for index, trailCinematic in ipairs(Client.trailCinematics) do
        trailCinematic:Update(deltaTime)
    end

end

// This function should be called for demos where a lot of players are
// trying the game for the first time. PAX, GamesCom, etc.
local lastTimeHelpReset = nil
local kResetHelpTimer = 60 * 15
local kHelpAutoResetEnabled = false
local function UpdateHelpAutoReset()

    if lastTimeHelpReset == nil or Shared.GetTime() - lastTimeHelpReset >= kResetHelpTimer then
    
        Client.RemoveOption("help/")
        Shared.Message("Help has been reset")
        lastTimeHelpReset = Shared.GetTime()
        
    end
    
end

local function UpdateWaitingToSpawnUI(player)

    local displayUI = false
    if player and player:GetIsWaitingForTeamBalance() then
        displayUI = true
    end
    
    waitingForAutoTeamBalanceUI:SetIsVisible(displayUI)
    
end

function OnUpdateClient(deltaTime)

    PROFILE("Client:OnUpdateClient")
    
    UpdateTrailCinematics(deltaTime)
    UpdateWorldMessages()
    
    local player = Client.GetLocalPlayer()
    if player ~= nil then
        //UpdateParticles(deltaTime)
        UpdateTracers(deltaTime) 
    end
    
    GetEffectManager():OnUpdate(deltaTime)
    
    ExpireDebugText()
    
    if kHelpAutoResetEnabled then
        UpdateHelpAutoReset()
    end
    
    UpdateWaitingToSpawnUI(player)
    
end

function OnNotifyGUIItemDestroyed(destroyedItem)
    
    GetGUIManager():NotifyGUIItemDestroyed(destroyedItem)

end

function CreateTracer(startPoint, endPoint, velocity, doer, effectName)

    if not Shared.GetIsRunningPrediction() then

        if not effectName then
        
            if doer.GetTracerEffectName then
                effectName = doer:GetTracerEffectName()
            else
                effectName = kDefaultTracerEffectName
            end
        
        end

        local tracer = BuildTracer(startPoint, endPoint, velocity, effectName)
        table.insert(Client.tracersList, tracer)
        
    end
    
end

function UpdateTracers(deltaTime)

    PROFILE("Client:UpdateTracers")
    
    for index, tracer in ipairs(Client.tracersList) do
    
        tracer:OnUpdate(deltaTime)
        
        if tracer:GetTimeToDie() then
            tracer:OnDestroy()
        end
        
    end
    
    table.removeConditional(Client.tracersList, Tracer.GetTimeToDie)    

end

// Update local time played in options file, so we can track "rookie" status
function UpdateTimePlayed(deltaTime)

    PROFILE("Client:UpdateTimePlayed")

    local player = Client.GetLocalPlayer()
    assert(player)

    local teamNumber = player:GetTeamNumber()
    if player:GetGameStarted() and (teamNumber == kMarineTeamType or teamNumber == kAlienTeamType) then
    
        // Increment time
        if timePlayed == nil then
            timePlayed = 0
        end
        timePlayed = timePlayed + deltaTime
        
        if timePlayed > kRookieSaveInterval then
        
            SaveTimePlayed(kRookieSaveInterval)
            timePlayed = 0
            
            // If we are a rookie and we just increased over the time threshold, set ourselves no longer as a rookie
            if Client.GetOptionInteger(kTimePlayedOptionsKey, 0) > kRookieTimeThreshold and Client.GetOptionBoolean(kRookieOptionsKey, true ) then
            
                local minutesPlayed = math.round(Client.GetOptionInteger(kTimePlayedOptionsKey, 0)/60)
                local displayMessage = string.format(Locale.ResolveString("ROOKIE_DONE"), minutesPlayed)
                Print(displayMessage)
                Client.SetOptionBoolean( kRookieOptionsKey, false )
                    
            end
            
        end
        
    end
    
end

function SaveTimePlayed(additionalTimePlayed)

    if additionalTimePlayed ~= nil then
    
        assert(additionalTimePlayed > 0)
        
        local newTimePlayed = Client.GetOptionInteger(kTimePlayedOptionsKey, 0) + additionalTimePlayed
        Client.SetOptionInteger(kTimePlayedOptionsKey, newTimePlayed)
        
    end
    
end

/**
 * Shows or hides the skybox(es) based on the specified state.
 */
function SetSkyboxDrawState(skyBoxVisible)

    for index, skyBox in ipairs(Client.skyBoxList) do
        skyBox:SetIsVisible( skyBoxVisible )
    end

end

function OnMapPreLoad()

    // Add our current time we played
    SaveTimePlayed(timePlayed)
    
    // Clear our list of render objects, lights, props
    Client.propList = { }
    Client.lightList = { }
    Client.skyBoxList = { }
    Client.tracersList = { }
    
    Client.rules = { }
    Client.DestroyReverbs()
    Client.ResetSoundSystem()
    
    Shared.PreLoadSetGroupNeverVisible(kCollisionGeometryGroupName)   
    Shared.PreLoadSetGroupPhysicsId(kNonCollisionGeometryGroupName, 0)

    Shared.PreLoadSetGroupNeverVisible(kCommanderBuildGroupName)   
    Shared.PreLoadSetGroupPhysicsId(kCommanderBuildGroupName, PhysicsGroup.CommanderBuildGroup)      
    
    // Any geometry in kCommanderInvisibleGroupName or kCommanderNoBuildGroupName shouldn't interfere with selection or other commander actions
    Shared.PreLoadSetGroupPhysicsId(kCommanderInvisibleGroupName, PhysicsGroup.CommanderPropsGroup)
    Shared.PreLoadSetGroupPhysicsId(kCommanderNoBuildGroupName, PhysicsGroup.CommanderPropsGroup)
    
    // Don't have bullets collide with collision geometry
    Shared.PreLoadSetGroupPhysicsId(kCollisionGeometryGroupName, PhysicsGroup.CollisionGeometryGroup)   
    
end

function ShowFeedbackPage()
    Client.ShowWebpage(kFeedbackURL)
end

local function CheckRules()

    //Client side check for game requirements (listen server)
    //Required to prevent scripting errors on the client that can lead to false positives
    if Client.rules.numberMiniMapExtents == nil then
        Shared.Message('ERROR: minimap_extent entity is missing from the level.')
        Client.minimapExtentScale = Vector(100,100,100)
        Client.minimapExtentOrigin = Vector(0,0,0)
    elseif Client.rules.numberMiniMapExtents > 1 then
        Shared.Message('WARNING: There are too many minimap_extents, There should only be one placed in the level.')
    end

end

/**
 * Callback handler for when the map is finished loading.
 */
local function OnMapPostLoad()

    // Set sound falloff defaults
    Client.SetMinMaxSoundDistance(7, 100)
    
    InitializePathing()
    
    //CreateDSPs()
    
    Scoreboard_Clear()
    
    CheckRules()
    
end

/**
 * Returns the horizontal field of view adjusted so that regardless of the resolution,
 * the vertical fov is a constant. standardAspect specifies the aspect ratio the game
 * is designed to be played at.
 */
function GetScreenAdjustedFov(horizontalFov, standardAspect)
        
    local actualAspect   = Client.GetScreenWidth() / Client.GetScreenHeight()
    
    local verticalFov    = 2.0 * math.atan(math.tan(horizontalFov * 0.5) / standardAspect)
    horizontalFov = 2.0 * math.atan(math.tan(verticalFov * 0.5) * actualAspect)

    return horizontalFov    

end

local function UpdateFogAreaModifiers(fromOrigin)

    local globalFogControls = Client.globalFogControls
    if globalFogControls then
    
        local viewZoneScale = globalFogControls.view_zone_scale
        local viewZoneColor = globalFogControls.view_zone_color
        
        local skyboxZoneScale = globalFogControls.skybox_zone_scale
        local skyboxZoneColor = globalFogControls.skybox_zone_color
        
        local defaultZoneScale = globalFogControls.default_zone_scale
        local defaultZoneColor = globalFogControls.default_zone_color
        
        for f = 1, #Client.fogAreaModifierList do
        
            local fogAreaModifier = Client.fogAreaModifierList[f]
            
            // Check if the passed in origin is within the range of this fog area modifier.
            local distSq = (fogAreaModifier.origin - fromOrigin):GetLengthSquared()
            local startBlendRadiusSq = fogAreaModifier.start_blend_radius
            startBlendRadiusSq = startBlendRadiusSq * startBlendRadiusSq
            if distSq <= startBlendRadiusSq then
            
                local endBlendRadiusSq = fogAreaModifier.end_blend_radius
                endBlendRadiusSq = endBlendRadiusSq * endBlendRadiusSq
                local blendDistanceSq = startBlendRadiusSq - endBlendRadiusSq
                local distPercent = 1 - (math.max(distSq - endBlendRadiusSq, 0) / blendDistanceSq)
                 
                viewZoneScale = LerpNumber(viewZoneScale, fogAreaModifier.view_zone_scale, distPercent)
                viewZoneColor = LerpColor(viewZoneColor, fogAreaModifier.view_zone_color, distPercent)
                
                skyboxZoneScale = LerpNumber(skyboxZoneScale, fogAreaModifier.skybox_zone_scale, distPercent)
                skyboxZoneColor = LerpColor(skyboxZoneColor, fogAreaModifier.skybox_zone_color, distPercent)
                
                defaultZoneScale = LerpNumber(defaultZoneScale, fogAreaModifier.default_zone_scale, distPercent)
                defaultZoneColor = LerpColor(defaultZoneColor, fogAreaModifier.default_zone_color, distPercent)
                
                // This only works with 1 fog area modifier currently.
                break
                
            end
            
        end
        
        Client.SetZoneFogDepthScale(RenderScene.Zone_ViewModel, 0.0 / viewZoneScale)
        Client.SetZoneFogColor(RenderScene.Zone_ViewModel, viewZoneColor)
        
        Client.SetZoneFogDepthScale(RenderScene.Zone_SkyBox, 0.0 / skyboxZoneScale)
        Client.SetZoneFogColor(RenderScene.Zone_SkyBox, skyboxZoneColor)
        
        Client.SetZoneFogDepthScale(RenderScene.Zone_Default, 0.0 / defaultZoneScale)
        Client.SetZoneFogColor(RenderScene.Zone_Default, defaultZoneColor)
        
    end
    
end

/**
 * Called once per frame to setup the camera for rendering the scene.
 */
function OnUpdateRender()

    local player = Client.GetLocalPlayer()
    
    local camera = Camera()
    
    local cullingMode = RenderCamera.CullingMode_Occlusion
    
    // If we have a player, use them to setup the camera. 
    if player ~= nil then
    
        local coords = player:GetCameraViewCoords()
        
        //UpdateFogAreaModifiers(coords.origin)
        
        camera:SetCoords(coords)
		
        local adjustValue   = Clamp( Client.GetOptionFloat("graphics/display/fov-adjustment",0), 0, 1 )
		local adjustRadians = math.rad(
			(1-adjustValue)*kMinFOVAdjustmentDegrees + adjustValue*kMaxFOVAdjustmentDegrees)
		
		// Don't adjust the FOV for the commander.
		if player:isa("Commander") then
		    adjustRadians = 0
	    end
			
        camera:SetFov(player:GetRenderFov()+adjustRadians)
        
        // In commander mode use frustum culling since the occlusion geometry
        // isn't generally setup for viewing the level from the outside (and
        // there is very little occlusion anyway)
        if player:GetIsOverhead() then
            cullingMode = RenderCamera.CullingMode_Frustum
        end
        
        local horizontalFov = GetScreenAdjustedFov( camera:GetFov(), 4 / 3 )
        
        gRenderCamera:SetCoords(camera:GetCoords())
        gRenderCamera:SetFov(horizontalFov)
        gRenderCamera:SetNearPlane(0.03)
        gRenderCamera:SetFarPlane(400.0)
        gRenderCamera:SetCullingMode(cullingMode)
        Client.SetRenderCamera(gRenderCamera)
        
        HiveVision_SetEnabled( GetIsAlienUnit(player) )
        HiveVision_SyncCamera( gRenderCamera, player:isa("Commander") )
        
        EquipmentOutline_SetEnabled( GetIsMarineUnit(player) )
        EquipmentOutline_SyncCamera( gRenderCamera, player:isa("Commander") )
        
    else
    
        Client.SetRenderCamera(nil)
        HiveVision_SetEnabled( false )
        EquipmentOutline_SetEnabled( false )
        
    end
    
end

function UpdateWorldMessages()

    local removeEntries = {}
    
    for _, message in ipairs(Client.worldMessages) do
    
        if (Client.GetTime() - message.creationTime) >= message.lifeTime then
            table.insert(removeEntries, message)
        else
            message.animationFraction = (Client.GetTime() - message.creationTime) / message.lifeTime
        end
    
    end
    
    for _, removeMessage in ipairs(removeEntries) do    
        table.removevalue(Client.worldMessages, removeMessage)    
    end

end

function Client.AddWorldMessage(messageType, message, position, entityId)

    // Only add damage messages if we have it enabled
    if messageType ~= kWorldTextMessageType.Damage or (Client.GetOptionBoolean( "drawDamage", true ) and Shared.GetCheatsEnabled()) then

        // If we already have a message for this entity id, update existing message instead of adding new one
        local time = Client.GetTime()
            
        local updatedExisting = false
        
        if messageType == kWorldTextMessageType.Damage then
        
            for _, currentWorldMessage in ipairs(Client.worldMessages) do
            
                if currentWorldMessage.messageType == messageType and currentWorldMessage.entityId == entityId and entityId ~= nil and entityId ~= Entity.invalidId then
                
                    currentWorldMessage.creationTime = time
                    currentWorldMessage.position = position
                    currentWorldMessage.previousNumber = tonumber(currentWorldMessage.message)
                    currentWorldMessage.message = tostring(tonumber(currentWorldMessage.message) + tonumber(message))
                    currentWorldMessage.minimumAnimationFraction = kWorldDamageRepeatAnimationScalar
                    
                    updatedExisting = true
                    break
                    
                end
                
            end
            
        end
        
        if not updatedExisting then
        
            local worldMessage = {}
            
            worldMessage.messageType = messageType
            worldMessage.message = message
            worldMessage.position = position        
            worldMessage.creationTime = time
            worldMessage.entityId = entityId
            worldMessage.animationFraction = 0
            worldMessage.lifeTime = ConditionalValue(kWorldTextMessageType.CommanderError == messageType, kCommanderErrorMessageLifeTime, kWorldMessageLifeTime)
            
            if messageType == kWorldTextMessageType.CommanderError then
            
                local commander = Client.GetLocalPlayer()
                if commander then
                    commander:TriggerInvalidSound()
                end
                
            end
            
            table.insert(Client.worldMessages, worldMessage)
            
        end
        
    end
    
end

function Client.GetWorldMessages()
    return Client.worldMessages
end

function Client.CreateTrailCinematic(renderZone)
    local trailCinematic = TrailCinematic()
    trailCinematic:Initialize(renderZone)
    table.insert(Client.trailCinematics, trailCinematic)
    return trailCinematic
end

function Client.ResetTrailCinematic(trailCinematic)
    return trailCinematic:Destroy()    
end

function Client.DestroyTrailCinematic(trailCinematic, nextFrame)

    if nextFrame then
        table.insert(Client.destroyTrailCinematics, trailCinematic)
        return true
    end

    local success = trailCinematic:Destroy()
    return success and table.removevalue(Client.trailCinematics, trailCinematic)
end

function OnClientConnected()
end

/**
 * Called when the client is disconnected from the server.
 */
function OnClientDisconnected(reason)

    // Clean up the render objects we created during the level load.
    DestroyLevelObjects()
    
    // Destroy all shared GUIs
    GetGUIManager():DestroyGUIScriptSingle("GUICrosshair")
    GetGUIManager():DestroyGUIScriptSingle("GUIScoreboard")
    GetGUIManager():DestroyGUIScriptSingle("GUINotifications")
    GetGUIManager():DestroyGUIScriptSingle("GUIDamageIndicators")
    GetGUIManager():DestroyGUIScriptSingle("GUIDeathMessages")
    GetGUIManager():DestroyGUIScriptSingle("GUIChat")
    GetGUIManager():DestroyGUIScriptSingle("GUIVoiceChat")
    GetGUIManager():DestroyGUIScriptSingle("GUIMinimapFrame")
    GetGUIManager():DestroyGUIScriptSingle("GUIMapAnnotations")
    GetGUIManager():DestroyGUIScriptSingle("GUIGameEnd")
    GetGUIManager():DestroyGUIScriptSingle("GUIWorldText")
    GetGUIManager():DestroyGUIScriptSingle("GUICommunicationStatusIcons")
    
    GetGUIManager():DestroyGUIScript(waitingForAutoTeamBalanceUI)
    waitingForAutoTeamBalanceUI = nil
    
    // Destroy graphical debug text items
    for index, item in ipairs(gDebugTextList) do
        GetGUIManager():DestroyGUIScript(item)
    end
    
end

/**
 * UI scripts that need to precache assets are loaded here.
 * Not all GUI scripts need to be listed here.
 * They must be loaded after OnLoadComplete() below because they need functions
 * that are only available after the Client is fully loaded.
 */
local function LoadGUIScripts()

    Script.Load("lua/GUIMinimapFrame.lua")
    Script.Load("lua/GUIMinimap.lua")
    Script.Load("lua/Hud/Marine/GUIMarineHud.lua")
    Script.Load("lua/GUIActionIcon.lua")
    Script.Load("lua/GUIMarineTeamMessage.lua")
    Script.Load("lua/GUINotifications.lua")
    Script.Load("lua/Hud/GUINotificationItem.lua")
    Script.Load("lua/Hud/Marine/GUIMarineStatus.lua")
    Script.Load("lua/Hud/Marine/GUIMarineHUDStyle.lua")
    Script.Load("lua/Hud/Marine/GUIExoHud.lua")
    Script.Load("lua/Hud/GUIEvent.lua")
    Script.Load("lua/Hud/GUIPlayerResource.lua")
    Script.Load("lua/GUIAlienBuyMenu.lua")
    Script.Load("lua/GUIWaypoints.lua")
    Script.Load("lua/GUIProgressBar.lua")
    Script.Load("lua/GUIAlienTeamMessage.lua")
    Script.Load("lua/GUIAlienHUD.lua")
    
end

/**
 * Fade to black and show messages, global so transistion between classes is smooth.
 */
local function OnLoadComplete()

    gRenderCamera = Client.CreateRenderCamera()
    gRenderCamera:SetRenderSetup("renderer/Deferred.render_setup")
    
    Render_SyncRenderOptions()
    
    GetGUIManager():CreateGUIScript("GUIDeathScreen")
    HiveVision_Initialize()
    EquipmentOutline_Initialize()
    LoadGUIScripts()
    
end

Event.Hook("ClientDisconnected", OnClientDisconnected)
Event.Hook("ClientConnected", OnClientConnected)
Event.Hook("UpdateRender", OnUpdateRender)
Event.Hook("MapLoadEntity", OnMapLoadEntity)
Event.Hook("MapPreLoad", OnMapPreLoad)
Event.Hook("MapPostLoad", OnMapPostLoad)
Event.Hook("UpdateClient", OnUpdateClient)
Event.Hook("NotifyGUIItemDestroyed", OnNotifyGUIItemDestroyed)
Event.Hook("LoadComplete", OnLoadComplete)
