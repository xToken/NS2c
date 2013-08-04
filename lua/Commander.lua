// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Handles Commander movement and actions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed idle workers and adjusted to use goldsource movement code

Script.Load("lua/Player.lua")
Script.Load("lua/Globals.lua")
Script.Load("lua/BuildingMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/Mixins/OverheadMoveMixin.lua")
Script.Load("lua/MinimapMoveMixin.lua")
Script.Load("lua/HotkeyMoveMixin.lua")
Script.Load("lua/ScoringMixin.lua")

local gTechIdCooldowns = {}
local function GetTechIdCooldowns(teamNumber)

    if not gTechIdCooldowns[teamNumber] then        
        gTechIdCooldowns[teamNumber] = {}        
    end
    
    return gTechIdCooldowns[teamNumber]

end

class 'Commander' (Player)

Commander.kMapName = "commander"

Script.Load("lua/Commander_Hotkeys.lua")

Commander.kSpendTeamResourcesSoundName = PrecacheAsset("sound/NS2.fev/marine/common/comm_spend_metal")
Commander.kSpendResourcesSoundName = PrecacheAsset("sound/NS2.fev/marine/common/player_spend_nanites")

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
    numPlayerAlerts         = string.format("integer (0 to %d)", kMaxPlayerAlerts),
    commanderCancel         = "boolean",
    commandStationId        = "entityid",
    // Set to a number after a hotgroup is selected, so we know to jump to it next time we try to select it
    positionBeforeJump      = "vector",
}

AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(OverheadMoveMixin, networkVars)
AddMixinNetworkVars(MinimapMoveMixin, networkVars)
AddMixinNetworkVars(HotkeyMoveMixin, networkVars)

function Commander:OnCreate()

    Player.OnCreate(self)
    
    InitMixin(self, CameraHolderMixin, { kFov = Commander.kFov })
    
end

function Commander:OnInitialized()

    InitMixin(self, OverheadMoveMixin)
    InitMixin(self, MinimapMoveMixin)
    InitMixin(self, HotkeyMoveMixin)
    
    InitMixin(self, BuildingMixin)
    InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })
    
    Player.OnInitialized(self)
    
    self:SetIsVisible(false)
    
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

function Commander:GetCanCrouch()
    return false
end

function Commander:GetTechAllowed(techId, techNode, self)

    local allowed, canAfford = Player.GetTechAllowed(self, techId, techNode, self)
    
    return allowed, canAfford

end

function Commander:HandleButtons(input)

    PROFILE("Commander:HandleButtons")
    
    // Set Commander orientation to looking down but not straight down for visual interest.
    local yawDegrees = 90
    local pitchDegrees = 70
    local angles = Angles((pitchDegrees / 90) * math.pi / 2, (yawDegrees / 90) * math.pi / 2, 0)
    
    // Update to the current view angles.
    self:SetViewAngles(angles)

    // Check for commander cancel action. It is reset in the flash hook to make
    // sure it's recognized.
    if bit.band(input.commands, Move.Exit) ~= 0 then
        self.commanderCancel = true
    end
    
    if Client and not Shared.GetIsRunningPrediction() then
        self:HandleCommanderHotkeys(input)
    end
    
end

function Commander:UpdateViewAngles()
end

// Move commander without any collision detection
function Commander:UpdatePosition(input, velocity, time)

    PROFILE("Commander:UpdatePosition")

    local offset = velocity * time
    
    if self.controller then
    
        self:UpdateControllerFromEntity()
        
        self.controller:SetPosition(self:GetOrigin() + offset)

        self:UpdateOriginFromController()

    end    

    return velocity
    
end

function Commander:GetNumPlayerAlerts()
    return self.numPlayerAlerts
end

// Returns true if it set our position
function Commander:ProcessNumberKeysMove(input, newPosition)
    return setPosition
end

local function DeleteHotkeyGroup(self, number)

    for _, entity in ipairs(GetEntitiesWithMixinForTeam("Selectable", self:GetTeamNumber())) do
        
        if entity:GetHotGroupNumber() == number then
            entity:SetHotGroupNumber(0)
        end
    
    end

end

// Creates hotkey for number out of current selection. Returns true on success.
// Replaces existing hotkey on this number if it exists.
function Commander:CreateHotkeyGroup(number)

    DeleteHotkeyGroup(self, number)
    for _, unit in ipairs(self:GetSelection()) do
        unit:SetHotGroupNumber(number)
    end

    if Client then
        self:SendCreateHotKeyGroupMessage(number) 
    end
    
    return true
    
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

function Commander:GetMenuTechId()
    return self.menuTechId
end

function Commander:GetCurrentTechButtons(techId, entity)

    local techButtons = self:GetQuickMenuTechButtons(techId)
    
    if not self:GetIsInQuickMenu(techId) and entity then
    
        // Allow selected entities to add/override buttons in the menu (but not top row)
        // only show buttons of friendly units
        if entity:GetTeamNumber() == self:GetTeamNumber() then
        
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
        
    end
    
    return techButtons
    
end

function Commander:SetTechCooldown(techId, cooldownDuration, startTime)

    if techId == kTechId.None or not techId then
        return
    end    

    local reusedEntry = false
    
    for _, techIdCD in ipairs(GetTechIdCooldowns(self:GetTeamNumber())) do
    
        if techIdCD.TechId == techId then
        
            techIdCD.StartTime = startTime
            techIdCD.CooldownDuration = cooldownDuration
            reusedEntry = true
            break
        
        end
    
    end
    
    if not reusedEntry then    
        table.insert( GetTechIdCooldowns(self:GetTeamNumber()), { StartTime = startTime, TechId = techId, CooldownDuration = cooldownDuration } )    
    end
    
    if Server then
    
        // send message to commander to sync the cd
    
    end

end

function Commander:GetIsTechOnCooldown(techId)

    for _, techIdCD in ipairs(GetTechIdCooldowns(self:GetTeamNumber())) do
    
        if techIdCD.TechId == techId then
            
            local time = Shared.GetTime()
            return time < techIdCD.StartTime + techIdCD.CooldownDuration

        end
    
    end

end

function Commander:GetCooldownFraction(techId)

    for _, techIdCD in ipairs(GetTechIdCooldowns(self:GetTeamNumber())) do
    
        if techIdCD.TechId == techId then
            
            local timePassed = Shared.GetTime() - techIdCD.StartTime
            return 1 - math.min(1, timePassed / techIdCD.CooldownDuration)

        end
    
    end
    
    return 0

end

function Commander:OnProcessMove(input)

    Player.OnProcessMove(self, input)
    
    if Server then
        
        if not self.timeLastEnergyCheck then
        
            self.timeLastEnergyCheck = Shared.GetTime()
            self:CheckStructureEnergy()
            
        end
        
        if self.timeLastEnergyCheck + 0.5 < Shared.GetTime() then
        
            self.timeLastEnergyCheck = Shared.GetTime()
            self:CheckStructureEnergy()
            
        end
        
    elseif Client then
        
        // This flag must be cleared inside OnProcessMove. See explaination in Commander:OverrideInput().
        self.setScrollPosition = false
        
    end
    
end

function Commander:GetHostCommandStructure()
    return Shared.GetEntity(self.commandStationId)
end

function Commander:GetIsForwardOverrideDesired()
    return false
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
