-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Commander_Client.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Removed alien comm refs, sentry battery line, idle workers

Script.Load("lua/Commander_Alerts.lua")
Script.Load("lua/Commander_Buttons.lua")
Script.Load("lua/Commander_HotkeyPanel.lua")
Script.Load("lua/Commander_IdleWorkerPanel.lua")
Script.Load("lua/Commander_PlayerAlertPanel.lua")
Script.Load("lua/Commander_ResourcePanel.lua")
Script.Load("lua/Commander_SelectionPanel.lua")

-- These are not predicted.
if Client then

    Script.Load("lua/Commander_MarqueeSelection.lua")
    Script.Load("lua/Commander_Ping.lua")
    Script.Load("lua/Commander_GhostStructure.lua")
    Script.Load("lua/Commander_MouseActions.lua")

    Script.Load("lua/DynamicMeshUtility.lua")

    local function CreateCommanderModel(modelName)

        return function()

            local commModel = Client.CreateRenderModel(RenderScene.Zone_Default)
            commModel:SetModel(modelName)
            commModel:SetIsVisible(false)
            return commModel

        end

    end

    ClientResources.AddResource("CommAlienUnitUnderCursor", "AlienCommander", CreateCommanderModel(Commander.kAlienCircleModelName), Client.DestroyRenderModel)
    ClientResources.AddResource("CommMarineUnitUnderCursor", "MarineCommander", CreateCommanderModel(Commander.kMarineCircleModelName), Client.DestroyRenderModel)
    ClientResources.AddResource("CommSentryOrientation", "Commander", CreateCommanderModel(Commander.kSentryOrientationModelName), Client.DestroyRenderModel)
    ClientResources.AddResource("CommSentryRange", "Commander", CreateCommanderModel(Commander.kSentryRangeModelName), Client.DestroyRenderModel)

    local function CreateSentryBatteryLineModel()

        local sentryBatteryLineHelp = DynamicMesh_Create()
        sentryBatteryLineHelp:SetIsVisible(false)
        sentryBatteryLineHelp:SetMaterial(Commander.kMarineLineMaterialName)
        return sentryBatteryLineHelp

    end

    ClientResources.AddResource("CommSentryBatteryLine", "Commander", CreateSentryBatteryLineModel, DynamicMesh_Destroy)

end

function Commander:OnGetIsVisible(visibleTable)
    visibleTable.Visible = false
end

function Commander:OnShowMap(show)

    self.minimapVisible = show
    self:ShowMap(true, show)

end

function Commander:GetCrossHairTarget()
    return nil
end

function Commander:GetCanRepairOverride(target)
    return false
end

function CommanderUI_GetNumWorkers()

    local player = Client.GetLocalPlayer()
    if player then

        local teamInfo = GetTeamInfoEntity(player:GetTeamNumber())
        if teamInfo then
            return teamInfo:GetNumWorkers()
        end
    end

    return 0

end

function CommanderUI_GetNumCapturedTechpoint()

    local player = Client.GetLocalPlayer()
    if player then

        local teamInfo = GetTeamInfoEntity(player:GetTeamNumber())
        if teamInfo then
            return teamInfo:GetNumCapturedTechPoints()
        end

    end

    return 0

end

function CommanderUI_GetUnitVisions()

    local unitVisions = {}

    local player = Client.GetLocalPlayer()

    if player then

        local losEntities
        if player:isa("Spectator") then
            losEntities = GetEntitiesWithMixin("LOS")
        else
            losEntities = GetEntitiesWithMixinForTeam("LOS", player:GetTeamNumber())
        end

        local eyePos = player:GetCameraViewCoords().origin
        local entityEyePos
        local fov = 0
        for _, losEntity in ipairs(losEntities) do

            if losEntity:GetIsAlive() then

                fov = 90
                if losEntity.GetFov then
                    fov = losEntity:GetFov()
                end

                entityEyePos = losEntity:GetEyePos()
                table.insert(unitVisions, {ScreenPos = Client.WorldToScreen(entityEyePos), Distance = (eyePos - entityEyePos):GetLength(), Radius = losEntity:GetVisionRadius(), FOV = fov})

                --DebugCapsule(entityEyePos, entityEyePos, losEntity:GetVisionRadius(), 0, 0.03)

            end

        end

    end

    return unitVisions

end

local mouseOverUI = false
function CommanderUI_SetMouseIsOverUI(overUI)
    mouseOverUI = overUI
end

function CommanderUI_GetMouseIsOverUI()
    return mouseOverUI
end

function CommanderUI_IsLocalPlayerCommander()

    local player = Client.GetLocalPlayer()
    if player and player:isa("Commander") then
        return true
    end

    return false

end

function CommanderUI_IsAlienCommander()
    return false

end

function CommanderUI_TriggerPingInWorld(x, y)

    local player = Client.GetLocalPlayer()
    if player then

        local pickVec = Client.CreatePickingRayXY(x, y)

        local trace = Shared.TraceRay(player:GetOrigin(), player:GetOrigin() + pickVec * 1000, CollisionRep.Select, PhysicsMask.CommanderSelect, EntityFilterAll())

        if trace.fraction ~= 1 then

            local message = BuildCommanderPingMessage(trace.endPoint)
            Client.SendNetworkMessage("CommanderPing", message, true)

        end

    end

end

function CommanderUI_TriggerPingOnMinimap(x, y)

    local player = Client.GetLocalPlayer()
    if player then

        local startPos = MinimapToWorld(player, x, y)
        startPos.y = player:GetOrigin().y

        local trace = Shared.TraceRay(startPos, startPos + Vector(0, -200, 0), CollisionRep.Select, PhysicsMask.CommanderSelect, EntityFilterAll())

        if trace.fraction ~= 1 then

            local message = BuildCommanderPingMessage(trace.endPoint)
            Client.SendNetworkMessage("CommanderPing", message, true)

        end

    end

end

function CommanderUI_OnMouseRelease(mouseButton, x, y)

    local player = Client.GetLocalPlayer()

    -- The .swf gives us both minimap and mouse release events, so don't process this one again
    if mouseButton ~= 1 or (player.timeMinimapRightClicked == nil or (Shared.GetTime() > (player.timeMinimapRightClicked + .2))) then
        player:ClientOnMouseRelease(mouseButton, x, y)
    end

end

--
-- Called from flash to determine if a tech on the button triggers instantly
-- or if it will look for a second mouse click afterwards.
--
function CommanderUI_MenuButtonRequiresTarget(index)

    local techId = GetTechIdFromButtonIndex(index)
    local techTree = GetTechTree()
    local requiresTarget = false

    if(tech ~= 0 and techTree) then

        local techNode = techTree:GetTechNode(techId)

        if(techNode ~= nil) then

            -- Buy nodes require a target for the commander
            requiresTarget = techNode:GetRequiresTarget() or techNode:GetIsBuy() or techNode:GetIsEnergyBuild()

        end

    end

    return requiresTarget

end

-- Returns nil or the index into the menu button array if the player
-- just pressed a hotkey. The hotkey hit will always be set to nil after
-- this function is called to make sure it's only triggered once.
function CommanderUI_HotkeyTriggeredButton()

    local hotkeyHit
    local player = Client.GetLocalPlayer()

    if player.hotkeyIndexHit ~= nil then

        hotkeyHit = player.hotkeyIndexHit
        player.hotkeyIndexHit = nil

    end

    return hotkeyHit

end

function Commander:SetHotkeyHit(index)
    self.hotkeyIndexHit = index
end

-- use only client side (for bringing up menus for example). Key events, and their consequences, are not send to the server
function Commander:SendKeyEvent(key, down)

    local success = CheckKeyEventForCommanderPing(key, down)

    if not self.timeLastHotkeyGroupPressed then
        self.timeLastHotkeyGroupPressed = 0
    end

    -- When exit hit cancel current action, bring up menu otherwise
    if down and key == InputKey.Escape and self.currentTechId ~= kTechId.None then

        self:SetCurrentTech(self.currentTechId)
        success = true

    end

    if key == InputKey.LeftControl or key == InputKey.RightControl then
        self.ctrlDown = down
    end

    if key == InputKey.LeftShift or key == InputKey.RightShift then
        self.shiftDown = down
    end

    if GetIsBinding(key, "PreviousLocationCom") then
        local origin = self:GetPreviousOverheadLocation()
        if origin then
            self:SetWorldScrollPreviousPosition(origin.x + 4, origin.z)
        end
        success = true
    end

    if down then

        local hotkeyGroup = 0
        if key == InputKey.Num1 then
            hotkeyGroup = 1
        elseif key == InputKey.Num2 then
            hotkeyGroup = 2
        elseif key == InputKey.Num3 then
            hotkeyGroup = 3
        elseif key == InputKey.Num4 then
            hotkeyGroup = 4
        elseif key == InputKey.Num5 then
            hotkeyGroup = 5
        elseif key == InputKey.Num6 then
            hotkeyGroup = 6
        elseif key == InputKey.Num7 then
            hotkeyGroup = 7
        elseif key == InputKey.Num8 then
            hotkeyGroup = 8
        elseif key == InputKey.Num9 then
            hotkeyGroup = 9
        end

        local selected, hotgroup = self:GetHotGroupSelected(hotkeyGroup)
        if selected and hotkeyGroup ~= 0 and not self.ctrlDown and (Shared.GetTime() - self.timeLastHotkeyGroupPressed < 0.5) then

            local position = hotgroup[1]:GetOrigin()
            self:SetWorldScrollPosition(position.x, position.z)
            success = true

        elseif hotkeyGroup ~= 0 and self.lastHotkeyGroupPressed ~= hotkeyGroup then

            success = true

            if not self.ctrlDown then
                self:SelectHotkeyGroup(hotkeyGroup)
            else
                self:CreateHotkeyGroup(hotkeyGroup)
            end

            self.timeLastHotkeyGroupPressed = Shared.GetTime()

            self.lastHotkeyGroupPressed = hotkeyGroup

        end

    else
        self.lastHotkeyGroupPressed = nil
    end

    if not success then
        success = Player.SendKeyEvent(self, key, down)
    end

    return success

end

function Commander:OnDestroy()

    Player.OnDestroy(self)

    if self.hudSetup == true then

        GetGUIManager():DestroyGUIScriptSingle("GUICommanderAlerts")
        GetGUIManager():DestroyGUIScriptSingle("GUISelectionPanel")
        GetGUIManager():DestroyGUIScriptSingle("GUIMinimapButtons")

        GetGUIManager():DestroyGUIScript(self.buttonsScript)
        self.buttonsScript = nil

        GetGUIManager():DestroyGUIScriptSingle("GUIHotkeyIcons")
        GetGUIManager():DestroyGUIScriptSingle("GUICommanderLogout")
        GetGUIManager():DestroyGUIScriptSingle("GUIResourceDisplay")
        GetGUIManager():DestroyGUIScript(self.production)
        self.production = nil

        GetGUIManager():DestroyGUIScript(self.managerScript)
        self.managerScript = nil

        --GetGUIManager():DestroyGUIScriptSingle("GUICommanderHelpWidget")

        GetGUIManager():DestroyGUIScriptSingle("GUICommanderTooltip")

        self:DestroyGhostGuides()

        self.hudSetup = false

        MouseTracker_SetIsVisible(false)

    end

end

function Commander:GetCanSeeConstructIcon(ofEntity)
    return true
end

function Commander:AddGhostGuide(origin, radius)

    local guide

    if #self.reuseGhostGuides > 0 then
        guide = self.reuseGhostGuides[#self.reuseGhostGuides]
        table.remove(self.reuseGhostGuides, #self.reuseGhostGuides)
    end

    -- Insert point, circle

    if not guide then
        guide = Client.CreateRenderDecal()
        guide.material = Client.CreateRenderMaterial()
    end

    local materialName = ConditionalValue(self:GetTeamType() == kAlienTeamType, Commander.kAlienCircleDecalName, Commander.kMarineCircleDecalName)
    guide.material:SetMaterial(materialName)
    guide:SetMaterial(guide.material)
    local coords = Coords.GetTranslation(origin)
    guide:SetCoords( coords )
    guide:SetExtents(Vector(1,1,1)*radius)

    table.insert(self.ghostGuides, {origin, guide})

end

-- Check tech id and create guides showing where extractors, harvesters, infantry portals, etc. go. Also draw
-- visual range for selected units if they are specified.
function Commander:UpdateGhostGuides()

    self:DestroyGhostGuides(true)
    self.selectedEntities = self:GetSelection()

    local techId = self.currentTechId
    if techId ~= nil and techId ~= kTechId.None then

        -- check if entity has a special ghost guide method
        local method = LookupTechData(techId, kTechDataGhostGuidesMethod, nil)

        if method then
            local entities, ranges = method(self)
            for _, entity in ipairs(entities) do
                local radius = ranges[entity]
                if radius then
                    self:AddGhostGuide(Vector(entity:GetOrigin()), radius)
                end
            end
        end

        -- If entity can only be placed within range of attach structures, get all the ents that
        -- count for this and draw circles around them
        local ghostRadius = LookupTechData(techId, kStructureAttachRange, 0)

        if ghostRadius ~= 0 then

            -- Lookup attach entity
            local attachId = LookupTechData(techId, kStructureAttachId)

            -- Handle table of attach ids
            local supportingTechIds = {}
            if type(attachId) == "table" then
                for index, currentAttachId in ipairs(attachId) do
                    table.insert(supportingTechIds, currentAttachId)
                end
            else
                table.insert(supportingTechIds, attachId)
            end

            for index, ent in ipairs(GetEntsWithTechIdIsActive(supportingTechIds)) do
                self:AddGhostGuide(Vector(ent:GetOrigin()), ghostRadius)
            end

        else

            -- Otherwise, draw only the free attach entities for this build tech (this is the common case)
            for index, ent in ipairs(GetFreeAttachEntsForTechId(techId)) do
                self:AddGhostGuide(Vector(ent:GetOrigin()), kStructureSnapRadius)
            end

        end

        -- If attach range specified, then structures don't go on this attach point, but within this range of it
        self.attachRange = LookupTechData(techId, kStructureAttachRange, nil)

    end

    -- Now draw visual ranges for selected units
    for _, entity in ipairs(self.selectedEntities) do

        -- Draw visual range on structures that specify it (no building effects)
        -- if GetVisualRadius() returns an array of radiuses, draw them all
        local visualRadius = entity:GetVisualRadius()

        if visualRadius ~= nil then
            if type(visualRadius) == "table" then
                for i,r in ipairs(visualRadius) do
                    self:AddGhostGuide(Vector(entity:GetOrigin()), r)
                end
            else
                self:AddGhostGuide(Vector(entity:GetOrigin()), visualRadius)
            end
        end

    end

end


function Commander:DestroyGhostGuides(reuse)

    for index, guide in ipairs(self.ghostGuides) do
        if not reuse then
            Client.DestroyRenderDecal(guide[2])

        else
            guide[2]:SetExtents(Vector(0,0,0))
            table.insert(self.reuseGhostGuides, guide[2])
        end
    end

    if not reuse then

        for index, guide in ipairs(self.reuseGhostGuides) do
            Client.DestroyRenderMaterial(guide.material)
            Client.DestroyRenderDecal(guide)
            guide = nil
        end

        self.reuseGhostGuides = {}

    end

    self.ghostGuides = {}

end

--
-- Flash should call this whenever we're in a mode like waiting for a target. If this returns true,
-- the action should be cancelled and the mode should be exited. For instance, if selecting a target
-- for an ability and CommanderUI_ActionCancelled() returns true, the menu should no longer highlight
-- that ability's button and mouse input should return to normal. This returns true when a player
-- triggers the CommCancel command.
--
function CommanderUI_ActionCancelled()

    local player = Client.GetLocalPlayer()
    local cancelled = (player.commanderCancel ~= nil) and (player.commanderCancel == true)

    -- Clear cancel after we trigger it
    player.commanderCancel = false

    SetCommanderGhostStructureEnabled(false)

    return cancelled

end

function CommanderUI_GetUIClickable()
    return not GetIsCommanderMarqueeSelectorDown() and not MainMenu_GetIsOpened()
end

function GetTechIdFromButtonIndex(index)

    local techId = kTechId.None
    local player = Client.GetLocalPlayer()

    if(index <= table.icount(player.menuTechButtons)) then
        techId = player.menuTechButtons[index]
    end

    return techId

end

function Commander:CloseMenu()

    SetCommanderGhostStructureEnabled(false)

    return Player.CloseMenu(self)

end

--
-- Returns a linear array of dynamic blip data
-- These are ONE-SHOT, i.e. once a blip is requested
-- from this function, it should be removed from the
-- list of blips returned
-- from this function
--
-- Data is formatted as:
-- X position, Y position, blip type
--
-- Blip types - kAlertType
--
-- 0 - Attack
-- Attention-getting spinning squares that start outside the minimap and spin down to converge to point
-- on map, continuing to draw at point for a few seconds).
--
-- 1 - Info
-- Research complete, area blocked, structure couldn't be built, etc. White effect, not as important to
-- grab your attention right away).
--
-- 2 - Request
-- Soldier needs ammo, asking for order, etc. Should be yellow or green effect that isn't as
-- attention-getting as the under attack. Should draw for a couple seconds.)
--
-- Eg {0.5, 0.5, 2} generates a request in the middle of the map
--
function CommanderUI_GetDynamicMapBlips()

    local player = Client.GetLocalPlayer()
    if player then
        return player:GetAlertBlips()
    end

    return { }

end

function CommanderUI_GetPheromones()
    return EntityListToTable(Shared.GetEntitiesWithClassname("Pheromone"))
end

function Commander:GetAndClearAlertMessages()

    local alertMessages = {}
    table.copy(self.alertMessages, alertMessages)
    table.clear(self.alertMessages)
    return alertMessages

end

local function SetupHud(self)
    
    HelpScreen_GetHelpScreen():Hide()
    
    MouseTracker_SetIsVisible(true, nil, true)

    self:InitializeMenuTechButtons()

    self.entityIdUnderCursor = Entity.invalidId

    local alertsScript = GetGUIManager():CreateGUIScriptSingle("GUICommanderAlerts")
    -- Every Player already has a GUIMinimap.
    local minimapScript = ClientUI.GetScript("GUIMinimapFrame")

    local selectionPanelScript = GetGUIManager():CreateGUIScriptSingle("GUISelectionPanel")

    local buttonsScriptName = ConditionalValue(self:GetTeamType() == kAlienTeamType, "GUICommanderButtonsAliens", "GUICommanderButtonsMarines")
    self.buttonsScript = GetGUIManager():CreateGUIScript(buttonsScriptName)
    minimapScript:SetButtonsScript(self.buttonsScript)

    local hotkeyIconScript = GetGUIManager():CreateGUIScriptSingle("GUIHotkeyIcons")
    local logoutScript = GetGUIManager():CreateGUIScriptSingle("GUICommanderLogout")
    GetGUIManager():CreateGUIScriptSingle("GUIResourceDisplay")

    local minimapButtons = GetGUIManager():CreateGUIScriptSingle("GUIMinimapButtons")
    if PlayerUI_GetTeamType() == kMarineTeamType then
        minimapScript.minimapFrame:AddChild(minimapButtons:GetBackground())
    else
        minimapScript.smokeyBackground:AddChild(minimapButtons:GetBackground())
    end

    minimapScript:GetBackground():AddChild(hotkeyIconScript:GetBackground())
    self.managerScript = GetGUIManager():CreateGUIScript("GUICommanderManager")

    --local worldbuttons = GetGUIManager():CreateGUIScriptSingle("GUICommanderHelpWidget")

    self.production = GetGUIManager():CreateGUIScript("GUIProduction")
    self.production:SetTeam(self:GetTeamType())
    minimapScript:GetBackground():AddChild(self.production:GetBackground())

    -- The manager needs to know about other commander UI scripts for things like
    -- making sure mouse clicks don't click through UI elements.
    self.managerScript:AddChildScript(alertsScript)
    self.managerScript:AddChildScript(minimapScript)
    self.managerScript:AddChildScript(selectionPanelScript)
    self.managerScript:AddChildScript(self.buttonsScript)
    self.managerScript:AddChildScript(hotkeyIconScript)
    self.managerScript:AddChildScript(logoutScript)
    self.managerScript:AddChildScript(minimapButtons)
    --self.managerScript:AddChildScript(worldbuttons)

    self.commanderTooltip = GetGUIManager():CreateGUIScriptSingle("GUICommanderTooltip")

    self.commanderTooltip:Register(self.buttonsScript)
    --self.commanderTooltip:Register(worldbuttons)

    -- Calling SetBackgroundMode() will sometimes access self.managerScript through
    -- CommanderUI_GetUIClickable() so call after self.managerScript is created above.
    minimapScript:SetBackgroundMode(GUIMinimapFrame.kModeMini)

    self.hudSetup = true

end

local function SetStartPosition(self)

    local entId = FindNearestEntityId("CommandStructure", self:GetOrigin())
    local commandStructure = Shared.GetEntity(entId)
    if commandStructure ~= nil then

        local origin = commandStructure:GetOrigin()
        self:SetWorldScrollPosition(origin.x, origin.z)

    else
        Print("%s:SetStartPosition(): Couldn't find command structure to center view upon.", self:GetClassName())
    end

end

function Commander:OnInitLocalClient()

    Player.OnInitLocalClient(self)

    self.sentryArcs = { }
    self.ghostGuides = { }
    self.reuseGhostGuides = { }

    SetupHud(self)

    -- Turn off skybox rendering when commanding.
    SetSkyboxDrawState(false)

    -- Set props invisible for Comm.
    SetCommanderPropState(true)

    -- Turn off sound occlusion for Comm.
    Client.SetSoundGeometryEnabled(false)

    -- Set commander geometry invisible.
    SetLocalPlayerIsOverhead(true)

    -- Set our location so we are viewing the command structure we're in.
    SetStartPosition(self)

    self.lastHotkeyIndex = nil

end

--
-- Allow player to create a different move if desired (Client only).
--
function Commander:OverrideInput(input)

    -- Completely override movement and impulses
    input.move.x = 0
    input.move.y = 0
    input.move.z = 0

    -- Move to position if minimap clicked or idle work clicked.
    -- Put in yaw and pitch because they are 16 bits
    -- each. Without them we get a "settling" after
    -- clicking the minimap due to differences after
    -- sending to the server
    input.yaw = self.minimapNormX or 0
    input.pitch = self.minimapNormY or 0

    if self.setScrollPosition then

        input.commands = bit.bor(input.commands, Move.Minimap)

        -- self.setScrollPosition is cleared in OnProcessMove() because
        -- this OverrideInput() function is called in intermediate mode
        -- in addition to non-intermediate mode. This means that sometimes
        -- OverrideInput() is called when the move is not going to be sent
        -- to the server which would mean this special Move.Minimap flag
        -- would not be sent and would be lost. So moving the clearing of
        -- the flag into OnProcessMove() fixes this problem as OnProcessMove()
        -- is called right before sending the move to the server.

    end

    if self.OverrideMove then
        input = self:OverrideMove(input)
    end

    return input

end

function Commander:HotkeyGroupButtonPressed(index)
    self.hotkeyGroupButtonPressed = index
end

function Commander:Logout()
    Shared.ConsoleCommand("logout")
end

function Commander:SendCreateHotKeyGroupMessage(number)

    local message = BuildCreateHotkeyGroupMessage(number)
    Client.SendNetworkMessage("CreateHotKeyGroup", message, true)

end

function Commander:SendSelectHotkeyGroupMessage(groupNumber)

    local message = BuildSelectHotkeyGroupMessage(groupNumber)
    Client.SendNetworkMessage("SelectHotkeyGroup", message, true)

end

function Commander:OnAbilityResultMessage(techId, success, castTime)

    -- If the ability succeded, show and enforce the cooldown
    if success then
        local cooldown = LookupTechData(techId, kTechDataCooldown, 0)
        if cooldown ~= 0 then
            self:SetTechCooldown(techId, cooldown, castTime)
        end
    end

end

function Commander:SendAction(techId)

    --Print("Commander:SendAction(%s)", EnumToString(kTechId, techId))

    local message = BuildCommActionMessage(techId, self.shiftDown)
    Client.SendNetworkMessage("CommAction", message, true)
    self.lastUsedTech = techId

end

function Commander:SendTargetedAction(techId, normalizedPickRay, orientation, entity)

    --Print("Commander:SendTargetedAction(%s)", EnumToString(kTechId, techId))

    local entityId = entity and entity:GetId() or Entity.invalidId
    local orientation = ConditionalValue(orientation, orientation, math.random() * 2 * math.pi)
    local message = BuildCommTargetedActionMessage(techId, normalizedPickRay.x, normalizedPickRay.y, normalizedPickRay.z, orientation, entityId, self.shiftDown)
    Client.SendNetworkMessage("CommTargetedAction", message, true)
    self.timeLastTargetedAction = Shared.GetTime()
    self:SetCurrentTech(kTechId.None)
    self.lastUsedTech = techId

end

function Commander:GetTimeLastTargetedAction()
    return self.timeLastTargetedAction or 0
end

function Commander:PollLastUsedTech()

    local lastUsedTech = self.lastUsedTech
    self.lastUsedTech = nil
    return lastUsedTech

end

function Commander:SendTargetedActionWorld(techId, worldCoords, orientation, entity)

    --Print("Commander:SendTargetedActionWorld(%s)", EnumToString(kTechId, techId))

    local entityId = entity and entity:GetId() or Entity.invalidId
    local message = BuildCommTargetedActionMessage(techId, worldCoords.x, worldCoords.y, worldCoords.z, ConditionalValue(orientation, orientation, 0), entityId, self.shiftDown)
    Client.SendNetworkMessage("CommTargetedActionWorld", message, true)
    self:SetCurrentTech(kTechId.None)
    self.timeLastTargetedAction = Shared.GetTime()
    self.lastUsedTech = techId

end

local function UpdateSentryBatteryLine(self, fromPoint)

    local sentriesNearby = GetEntitiesForTeamWithinRange("Sentry", self:GetTeamNumber(), fromPoint, SentryBattery.kRange)
    Shared.SortEntitiesByDistance(fromPoint, sentriesNearby)

    local closestSentry = sentriesNearby[1]

    local inRange = false

    if closestSentry then

        local distance = GetPathDistance(fromPoint, closestSentry:GetOrigin())
        if distance and distance <= SentryBattery.kRange then
            inRange = true
        end

    end

    if inRange then

        local startPoint = fromPoint + Vector(0, kZFightingConstant, 0)
        local endPoint = closestSentry:GetOrigin() + Vector(0, kZFightingConstant, 0)
        local direction = GetNormalizedVector(endPoint - startPoint)

        UpdateOrderLine(startPoint, endPoint, ClientResources.GetResource("CommSentryBatteryLine"))

    else
        ClientResources.GetResource("CommSentryBatteryLine"):SetIsVisible(false)
    end

end

local function UpdateGhostStructureVisuals(self)

    local commSpecifyingOrientation = GetCommanderGhostStructureSpecifyingOrientation()

    local sentryRangeModel = ClientResources.GetResource("CommSentryRange")
    sentryRangeModel:SetIsVisible(self.currentTechId == kTechId.Sentry and commSpecifyingOrientation)
    ClientResources.GetResource("CommSentryBatteryLine"):SetIsVisible(false)

    local coords = GetCommanderGhostStructureCoords()

    local displayOrientation = GetCommanderGhostStructureValid() and commSpecifyingOrientation
    local orientationModel = ClientResources.GetResource("CommSentryOrientation")
    orientationModel:SetIsVisible(displayOrientation)
    if displayOrientation then

        coords:Scale(Commander.kSentryArcScale)
        coords.zAxis = -coords.zAxis
        orientationModel:SetCoords(coords)

    end

    if coords and self.currentTechId == kTechId.Sentry then

        coords.zAxis = coords.zAxis * Sentry.kRange
        sentryRangeModel:SetCoords(coords)
        
    -- elseif coords and self.currentTechId == kTechId.SentryBattery then
        -- UpdateSentryBatteryLine(self, coords.origin)
    end

end

local function UpdateCircleUnderCursor(self)

    local unitUnderCursorModel = ClientResources.GetResource(self:isa("AlienCommander") and "CommAlienUnitUnderCursor" or "CommMarineUnitUnderCursor")

    local visibility = false

    if self.entityIdUnderCursor ~= Entity.invalidId then

        local entity = Shared.GetEntity(self.entityIdUnderCursor)
        if entity ~= nil and HasMixin(entity, "Selectable") then

            local scale = GetCircleSizeForEntity(entity)

            local coords = Coords.GetLookIn(entity:GetOrigin(), Vector.xAxis)
            coords:Scale(scale)
            unitUnderCursorModel:SetCoords(coords)

            visibility = true

        end

    end

    unitUnderCursorModel:SetIsVisible(visibility)

end

-- Only called when not running prediction
function Commander:UpdateClientEffects(deltaTime, isLocal)

    Player.UpdateClientEffects(self, deltaTime, isLocal)

    if isLocal then

        self:UpdateMenu()

        -- Update highlighted unit under cursor.
        local xScalar, yScalar = Client.GetCursorPos()
        local x = xScalar * Client.GetScreenWidth()
        local y = yScalar * Client.GetScreenHeight()
        if not MainMenu_GetIsOpened() then

            if not GetCommanderGhostStructureEnabled() and not CommanderUI_GetMouseIsOverUI() then

                local oldEntityIdUnderCursor = self.entityIdUnderCursor
                self.entityIdUnderCursor = self:GetUnitIdUnderCursor(CreatePickRay(self, x, y))

                if self.entityIdUnderCursor ~= Entity.invalidId and oldEntityIdUnderCursor ~= self.entityIdUnderCursor then
                    Shared.PlayPrivateSound(self, self:GetHoverSound(), self, 1.0, self:GetOrigin())
                end

            else
                self.entityIdUnderCursor = Entity.invalidId
            end

            UpdateGhostStructureVisuals(self)

            self:UpdateGhostGuides()

            UpdateCircleUnderCursor(self)

            self:UpdateCursor()

            self.lastMouseX = x
            self.lastMouseY = y

        end
    end

end

-- For debugging order-giving, selection, etc.
function Commander:DrawDebugTrace()

    if(self.lastMouseX ~= nil and self.lastMouseY ~= nil) then

        local trace = GetCommanderPickTarget(self, Client.CreatePickingRayXY(self.lastMouseX, self.lastMouseY))

        if(trace ~= nil and trace.endPoint ~= nil) then

            Shared.CreateEffect(self, "cinematics/debug.cinematic", nil, Coords.GetTranslation(trace.endPoint))

        end

    end

end

-- Set the context-sensitive mouse cursor
-- Marine Commander default (like arrow from Starcraft 2, pointing to upper-left, MarineCommanderDefault.dds)
-- Alien Commander default (like arrow from Starcraft 2, pointing to upper-left, AlienCommanderDefault.dds)
-- Valid for friendly action (green "brackets" in Starcraft 2, FriendlyAction.dds)
-- Valid for neutral action (yellow "brackets" in Starcraft 2, NeutralAction.dds)
-- Valid for enemy action (red "brackets" in Starcraft 2, EnemyAction.dds)
-- Build/target default (white crosshairs, BuildTargetDefault.dds)
-- Build/target enemy (red crosshairs, BuildTargetEnemy.dds)
function Commander:UpdateCursor()

    -- By default, use side-specific default cursor
    local baseCursor = "MarineCommanderDefault"
    
    -- By default, the "click" spot on the cursor graphic is in the top left corner.
    local hotspot = Vector(0, 0, 0)

    -- Update highlighted unit under cursor
    local xScalar, yScalar = Client.GetCursorPos()

    local entityUnderCursor

    if self.entityIdUnderCursor ~= Entity.invalidId then

        hotspot = Vector(16, 16, 0)

        entityUnderCursor = Shared.GetEntity(self.entityIdUnderCursor)
        baseCursor = "NeutralAction"

        if HasMixin(entityUnderCursor, "Team") then

            if entityUnderCursor:GetTeamNumber() == self:GetTeamNumber() then
                baseCursor = "FriendlyAction"
            elseif entityUnderCursor:GetTeamNumber() == GetEnemyTeamNumber(self:GetTeamNumber()) then
                baseCursor = "EnemyAction"
            end

        end

    end

    -- If we're building or in a targeted mode, use a special targeting cursor
    if GetCommanderGhostStructureEnabled() then

        hotspot = Vector(16, 16, 0)
        baseCursor = "BuildTargetDefault"

        -- Or if we're targeting an ability
    elseif self.currentTechId ~= nil and self.currentTechId ~= kTechId.None then

        local techNode = GetTechNode(self.currentTechId)

        if techNode ~= nil and techNode:GetRequiresTarget() then

            hotspot = Vector(16, 16, 0)
            baseCursor = "BuildTargetDefault"

            if entityUnderCursor and HasMixin(entityUnderCursor, "Team") and (entityUnderCursor:GetTeamNumber() == GetEnemyTeamNumber(self:GetTeamNumber())) then
                baseCursor = "BuildTargetEnemy"
            end

        end

    end

    -- Set the cursor if it changed
    local cursorTexture = string.format("ui/Cursor_%s.dds", baseCursor)
    if CommanderUI_GetMouseIsOverUI() and self.currentTechId == kTechId.None then

        hotspot = Vector(0, 0, 0)
        cursorTexture = "ui/Cursor_MenuDefault.dds"

    end

    if cursorTexture ~= self.lastCursorTexture then

        Client.SetCursor(cursorTexture, hotspot.x, hotspot.y)
        self.lastCursorTexture = cursorTexture

    end

end

function Commander:ClientOnMouseRelease(mouseButton, x, y)

    local displayConfirmationEffect = false

    local normalizedPickRay = CreatePickRay(self, x, y)
    if mouseButton == 1 then

        if self.currentTechId ~= kTechId.None then
            self:SetCurrentTech(kTechId.None)
        else

            local trace = GetCommanderPickTarget(self, normalizedPickRay, false, false)
            self:SendTargetedAction(kTechId.Default, normalizedPickRay, nil, trace.entity)
            displayConfirmationEffect = true

        end

    end

    if displayConfirmationEffect then

        local trace = GetCommanderPickTarget(self, normalizedPickRay)
        self:TriggerEffects("issue_order", { effecthostcoords = Coords.GetTranslation(trace.endPoint) } )

    end

end

function Commander:TechCausesDelay(techId)
    return false
end

function Commander:SetCurrentTech(techId)

    -- Change menu if it is a menu.
    local techNode = GetTechNode(techId)
    local isMenu = false
    local requiresTarget = false

    --DebugPrint("SetCurrentTech:\n%s", debug.traceback())

    if techNode ~= nil then

        if techNode:GetIsMenu() then

            self.menuTechId = techId
            isMenu = true

        end

        if techNode:GetRequiresTarget() then
            requiresTarget = true
        end

    end

    if techNode and not techNode:GetRequiresTarget() and not techNode:GetIsBuy() and not techNode:GetIsEnergyBuild() then

        -- Send action up to server. Necessary for even menu changes as
        -- server validates all actions.
        self:SendAction(techId)

    end

    -- Remember this techId, which we need during ClientOnMouseRelease()
    if not isMenu and requiresTarget then
        self.currentTechId = techId
    else

        self.currentTechId = kTechId.None
        if self.buttonsScript then

            self.buttonsScript:SelectTabForTechId(techId)
            self.buttonsScript:SetTargetedButton(nil)

        end

    end

    CommanderGhostStructureSetTech(self.currentTechId)
    CancelCommanderMarqueeSelect()

end

function Commander:TriggerButtonIndex(index)

    -- Only execute for the local Commander player.
    if self:GetIsLocalPlayer() then

        local commButtons = self.buttonsScript
        if CommanderUI_MenuButtonRequiresTarget(index) and commButtons then
            commButtons:SetTargetedButton(index)
        end

        CommanderUI_MenuButtonAction(index)

        if commButtons then
            commButtons:SelectTab(index)
        end

    end

end

function Commander:GetSelectedTabIndex()

    if self:GetIsLocalPlayer() then

        if self.buttonsScript then
            return self.buttonsScript:GetSelectedTabIndex()
        end

    end

end

function Commander:GetShowGhostModel()
    return GetCommanderGhostStructureEnabled()
end

function Commander:GetGhostModelTechId()
    return self.currentTechId
end

function Commander:GetGhostModelCoords()
    return GetCommanderGhostStructureCoords()
end

function Commander:GetIsPlacementValid()
    return GetCommanderGhostStructureValid()
end

function Commander:GetShowAtmosphericLight()
    return false
end

--
-- The Commander ignores the countdown camera animation.
--
function Commander:GetCameraViewCoordsCountdown(cameraCoords)
    return cameraCoords
end


-- Find the position the commander is speaking from when using local chat
-- Returns entity, offset pair. If entity is nil, then no source was found.

function Commander:FindVoiceEarLocation()

    local selectedEntities = self:GetSelection()
    if #selectedEntities == 1 then
        local entity = selectedEntities[1]
        if GetAreFriends(self, entity) then
            -- talk from above and behind right shoulder, roughly
            return entity, Vector(-1,3,-2)
        end
    end
    return nil, nil
end
