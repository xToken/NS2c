// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Handles Commander movement and actions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Player.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/BuildingMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/Mixins/OverheadMoveMixin.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/MinimapMoveMixin.lua")
Script.Load("lua/HotkeyMoveMixin.lua")
Script.Load("lua/ScoringMixin.lua")

class 'Commander' (Player)

Commander.kMapName = "commander"

Script.Load("lua/Commander_Hotkeys.lua")

Commander.kSpendTeamResourcesSoundName = PrecacheAsset("sound/NS2.fev/marine/common/comm_spend_metal")
Commander.kSpendResourcesSoundName = PrecacheAsset("sound/NS2.fev/marine/common/player_spend_nanites")

Commander.kSelectionCircleModelName = PrecacheAsset("models/misc/marine-build/marine-build.model")
Commander.kSentryOrientationModelName = PrecacheAsset("models/misc/sentry_arc/sentry_arc.model")
Commander.kSentryRangeModelName = PrecacheAsset("models/misc/sentry_arc/sentry_line.model")
Commander.kMarineCircleModelName = PrecacheAsset("models/misc/circle/circle.model")
Commander.kAlienCircleModelName = PrecacheAsset("models/misc/circle/circle_alien.model")
Commander.kMarineLineMaterialName = "ui/WaypointPath.material"
Commander.kAlienLineMaterialName = "ui/WaypointPath_alien.material"

Commander.kSentryArcScale = 8

// Extra hard-coded vertical distance that makes it so we set our scroll position,
// we are looking at that point, instead of setting our position to that point)
Commander.kViewOffsetXHeight = 5
// Default height above the ground when there's no height map
Commander.kDefaultCommanderHeight = 11
Commander.kFov = 90
Commander.kScoreBoardDisplayDelay = .12

// Snap structures to attach points within this range
Commander.kAttachStructuresRadius = 5

Commander.kScrollVelocity = 40

Script.Load("lua/Commander_Selection.lua")

if (Server) then
    Script.Load("lua/Commander_Server.lua")
else
    Script.Load("lua/Commander_Client.lua")
end

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/placement_valid.surface_shader")
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/placement_invalid.surface_shader")

Commander.kSelectMode = enum( {'None', 'SelectedGroup', 'JumpedToGroup'} )

local networkVars =
{
    timeScoreboardPressed   = "float",
    numIdleWorkers          = string.format("integer (0 to %d)", kMaxIdleWorkers),
    numPlayerAlerts         = string.format("integer (0 to %d)", kMaxPlayerAlerts),
    commanderCancel         = "boolean",
    commandStationId        = "entityid",
    // Set to a number after a hotgroup is selected, so we know to jump to it next time we try to select it
    positionBeforeJump      = "vector",
    gotoHotKeyGroup         = string.format("integer (0 to %d)", Player.kMaxHotkeyGroups)
}

AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(OverheadMoveMixin, networkVars)
AddMixinNetworkVars(MinimapMoveMixin, networkVars)
AddMixinNetworkVars(HotkeyMoveMixin, networkVars)

function Commander:OnCreate()

    Player.OnCreate(self)
    
    InitMixin(self, CameraHolderMixin, { kFov = Commander.kFov })
    InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity })
    
end

function Commander:OnInitialized()

    InitMixin(self, OverheadMoveMixin)
    InitMixin(self, MinimapMoveMixin)
    InitMixin(self, HotkeyMoveMixin)
    
    InitMixin(self, BuildingMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })
    
    self.selectedEntities = { }
    
    Player.OnInitialized(self)
    
    self:SetIsVisible(false)
    
    // set to a time to delay any left click action
    self.leftClickActionDelay = 0
    
    if Client then
    
        self.drawResearch = false
        
        // Start in build menu (more useful then command station menu)
        if self:GetIsLocalPlayer() then
            self:SetCurrentTech(kTechId.BuildMenu)
        end
        
    end
    
    if Server then
    
        // Wait a short time before sending hotkey groups to make sure
        // client has been replaced by commander
        self.timeToSendHotkeyGroups = Shared.GetTime() + 0.5
        
    end

    self.timeScoreboardPressed = 0
    self.focusGroupIndex = 1
    self.numIdleWorkers = 0
    self.numPlayerAlerts = 0
    self.positionBeforeJump = Vector(0, 0, 0)
    self.selectMode = Commander.kSelectMode.None
    self.commandStationId = Entity.invalidId
    
    self:SetWeaponsProcessMove(false)
    
end

// Needed so player origin is same as camera for selection
function Commander:GetViewOffset()
    return Vector(0, 0, 0)
end

function Commander:GetTeamType()
    return kNeutralTeamType
end

function Commander:GetTechAllowed(techId, techNode, self)

    local allowed, canAfford = Player.GetTechAllowed(self, techId, techNode, self)
/*
    if techId == kTechId.Harvester or techId == kTechId.Extractor then
        allowed = GetIsUnderResourceTowerLimit(self)
    end
    */
    
    return allowed, canAfford

end

function Commander:HandleButtons(input)
  
    PROFILE("Commander:HandleButtons")
    
    // Set Commander orientation to looking down but not straight down for visual interest
    local yawDegrees    = 90
    local pitchDegrees  = 70
    local angles        = Angles((pitchDegrees/90)*math.pi/2, (yawDegrees/90)*math.pi/2, 0)   
    
    // Update to the current view angles.
    self:SetViewAngles(angles)
    
    // Update shift order drawing/queueing
    self.queuingOrders = (bit.band(input.commands, Move.MovementModifier) ~= 0)

    // Check for commander cancel action. It is reset in the flash hook to make 
    // sure it's recognized.
    if(bit.band(input.commands, Move.Exit) ~= 0) then
        // TODO: If we have nothing to cancel, bring up menu
        //ShowInGameMenu()
        self.commanderCancel = true
    end

    if Client and not Shared.GetIsRunningPrediction() then    
    
        self:HandleCommanderHotkeys(input)
        
    end
    
    if Client then
        //self:ShowMap(true, bit.band(input.commands, Move.ShowMap) ~= 0)
    end
    
end

function Commander:UpdateCrouch()
end

function Commander:UpdateViewAngles()
end

// Move commander without any collision detection
function Commander:UpdatePosition(velocity, time)

    PROFILE("Commander:UpdatePosition")

    local offset = velocity * time
    
    if self.controller then
    
        self:UpdateControllerFromEntity()
        
        self.controller:SetPosition(self:GetOrigin() + offset)

        self:UpdateOriginFromController()

    end    

    return velocity
    
end

function Commander:GetNumIdleWorkers()
    return self.numIdleWorkers
end

function Commander:GetNumPlayerAlerts()
    return self.numPlayerAlerts
end

function Commander:UpdateMisc(input)

    PROFILE("Commander:UpdateMisc")
   
    if Client then
        self:UpdateChat(input)
    end
    
end

// Returns true if it set our position
function Commander:ProcessNumberKeysMove(input, newPosition)
    return setPosition
end

// Creates hotkey for number out of current selection. Returns true on success.
// Replaces existing hotkey on this number if it exists.
function Commander:CreateHotkeyGroup(number, entityIds)

    if Client then
        self:SendCreateHotKeyGroupMessage(number)
    elseif Server then
    
        if number >= 1 and number <= Player.kMaxHotkeyGroups then
        
            if entityIds ~= nil and #entityIds > 0 then
            
                // Don't update hotkeys if they are the same (also happens when key is held down)
                if not table.getIsEquivalent(entityIds, self.hotkeyGroups[number]) then
                
                    self:SetEntitiesHotkeyState(self.hotkeyGroups[number], false)
                    table.copy(entityIds, self.hotkeyGroups[number])
                    self:SetEntitiesHotkeyState(self.hotkeyGroups[number], true)
                    
                    self:SendHotkeyGroup(number)
                    
                    return true
                    
                end
                
            end
            
        end
        
    end
    
    return false
    
end

// Assumes number non-zero
function Commander:ProcessHotkeyGroup(number, newPosition)

    local setPosition = false
    
    if (self.gotoHotKeyGroup == 0) or (number ~= self.gotoHotKeyGroup) then
    
        // Select hotgroup        
        self:SelectHotkeyGroup(number)        
        self.positionBeforeJump = Vector(self:GetOrigin())
        self.gotoHotKeyGroup = number
        
    else
    
        // Jump to hotgroup if we're selecting same one and not nearby
        if self.gotoHotKeyGroup == number then
        
            // TODO: re-enabled once we have "jump back" functionality
            // setPosition = self:GotoHotkeyGroup(number, newPosition)
            
        end
        
    end

    return setPosition
    
end

function Commander:GetPlayFootsteps()
    return false
end    

function Commander:GetIsCommander()
    return true
end

function Commander:GetIsOverhead()
    return true
end

function Commander:GetOrderConfirmedEffect()
    return ""
end

/**
 * Returns the x-coordinate of the commander current position in the minimap.
 */
function Commander:GetScrollPositionX()
    local scrollPositionX = 1
    local heightmap = GetHeightmap()
    if(heightmap ~= nil) then
        scrollPositionX = heightmap:GetMapX( self:GetOrigin().z )
    end
    return scrollPositionX
end

/**
 * Returns the y-coordinate of the commander current position in the minimap.
 */
function Commander:GetScrollPositionY()
    local scrollPositionY = 1
    local heightmap = GetHeightmap()
    if(heightmap ~= nil) then
        scrollPositionY = heightmap:GetMapY( self:GetOrigin().x + Commander.kViewOffsetXHeight )
    end
    return scrollPositionY
end

// For making top row the same. Marine commander overrides to set top four icons to always be identical.
function Commander:GetTopRowTechButtons()
    return {}
end

function Commander:GetSelectionRowsTechButtons(menuTechId)
    return {}
end

function Commander:GetIsInQuickMenu(techId)
    return techId == kTechId.BuildMenu or techId == kTechId.AdvancedMenu or techId == kTechId.AssistMenu
end

function Commander:GetMenuTechIdFor(techId)

    for menuTechId, techIdTable in pairs(self:GetButtonTable()) do
    
        if table.contains(techIdTable, techId) then
            return menuTechId
        end
    
    end

end

function Commander:GetCurrentTechButtons(techId, entity)

    local techButtons = self:GetQuickMenuTechButtons(techId)
    
    if not self:GetIsInQuickMenu(techId) and entity then
    
        // Allow selected entities to add/override buttons in the menu (but not top row)
        local selectedTechButtons = entity:GetTechButtons(techId, self:GetTeamType())
        if selectedTechButtons then
        
            for index, id in pairs(selectedTechButtons) do
               techButtons[4 + index] = id 
            end
            
        end
        
        if (HasMixin(entity, "Research") and entity:GetIsResearching()) or (HasMixin(entity, "GhostStructure") and entity:GetIsGhostStructure()) then
        
            local foundCancel = false
            for b = 1, #techButtons do
            
                if techButtons[b] == kTechId.Cancel then
                
                    foundCancel = true
                    break
                    
                end
                
            end
            
            if not foundCancel then
                techButtons[kRecycleCancelButtonIndex] = kTechId.Cancel
            end
        
        // add recycle button if not researching / ghost structure mode
        elseif HasMixin(entity, "Recycle") and not entity:GetIsResearching() and entity:GetCanRecycle() and not entity:GetIsRecycled() then
            techButtons[kRecycleCancelButtonIndex] = kTechId.Recycle
        end
        
    end
    
    return techButtons
    
end

// Updates hotkeys to account for entity changes. Pass both parameters to indicate
// that an entity has changed (ie, a player has changed class), or pass nil
// for newEntityId to indicate an entity has been destroyed.
function Commander:OnEntityChange(oldEntityId, newEntityId)

    // It is possible this function will be called before the Commander has
    // been fully initialized.
    if self.selectedEntities then
    
        // Replace old object with new one if selected
        local newSelection = {}
        table.copy(self.selectedEntities, newSelection)
        
        local selectionChanged = false
        for index, pair in ipairs(newSelection) do
        
            if pair[1] == oldEntityId then
            
                if newEntityId then
                    pair[1] = newEntityId
                else
                    table.remove(newSelection, index)
                end
                
                selectionChanged = true
                
            end
            
        end
        
        if selectionChanged then
            self:InternalSetSelection(newSelection)
        end
        
    end
    
    // Hotkey groups are handled in player.
    Player.OnEntityChange(self, oldEntityId, newEntityId)
    
end

function Commander:GetIsEntityNameSelected(className)

    for tableIndex, entityPair in ipairs(self.selectedEntities) do
    
        local entityIndex = entityPair[1]
        local entity = Shared.GetEntity(entityIndex)
        
        // Don't allow it to be researched while researching
        if( entity ~= nil and entity:isa(className) ) then
        
            return true
            
        end
        
    end
    
    return false
    
end

function Commander:OnProcessMove(input)

    Player.OnProcessMove(self, input)
    
    // Remove selected units that are no longer valid for selection
    self:UpdateSelection(input.time)
    
    if Server then
        self:UpdateHotkeyGroups()
        
        if not self.timeLastEnergyCheck then
            self.timeLastEnergyCheck = Shared.GetTime()
            self:CheckStructureEnergy()
        end
        
        if self.timeLastEnergyCheck + .5 < Shared.GetTime() then
            self.timeLastEnergyCheck = Shared.GetTime()
            self:CheckStructureEnergy()
        end
    end
    
end

// Draw waypoint of selected unit as our own as quick ability for commander to see results of orders
function Commander:GetVisibleWaypoint()

    if self.selectedEntities and table.count(self.selectedEntities) > 0 then
    
        local ent = Shared.GetEntity(self.selectedEntities[1][1])
        
        if ent and ent:isa("Player") then
        
            return ent:GetVisibleWaypoint()
            
        end
        
    end
    
    return Player.GetVisibleWaypoint(self)
    
end

function Commander:GetHostCommandStructure()
    return Shared.GetEntity(self.commandStationId)
end

/**
 * Commanders never sight nearby enemy players.
 */
function Commander:OverrideCheckVision()
    return false
end

function Commander:OnProcessIntermediate(input)
    self:UpdateClientEffects(input.time, true)
end


Shared.LinkClassToMap("Commander", Commander.kMapName, networkVars)
