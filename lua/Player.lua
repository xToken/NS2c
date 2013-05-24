// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Player.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Player coordinates - z is forward, x is to the left, y is up.
// The origin of the player is at their feet.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Globals.lua")
Script.Load("lua/TechData.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/PhysicsGroups.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/CustomGroundMoveMixin.lua")
Script.Load("lua/WeaponOwnerMixin.lua")
Script.Load("lua/DoorMixin.lua")
Script.Load("lua/mixins/ControllerMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/UpgradableMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/MobileTargetMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/BadgeMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")

if Client then
    Script.Load("lua/HelpMixin.lua")
end

--@Abstract
class 'Player' (ScriptActor)

Player.kMapName = "player"

if Server then
    Script.Load("lua/Player_Server.lua")
end

if Client then
    Script.Load("lua/Player_Client.lua")
    Script.Load("lua/Chat.lua")
end

if Predict then

function Player:OnUpdatePlayer(deltaTime)    
    // do nothing
end

function Player:UpdateMisc(input)
    // do nothing
end

end

Player.kNotEnoughResourcesSound     = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/more")
Player.kGravity = -20
Player.kXZExtents = 0.35
Player.kYExtents = 0.95
Player.kWalkMaxSpeed = 4

local kTapInterval = 0.27

local TAP_NONE = 0
local TAP_LEFT = 1
local TAP_RIGHT = 2
local TAP_FORWARD = 3
local TAP_BACKWARD = 4

local tapVector =
{
    TAP_NONE     = Vector(0, 0, 0),
    TAP_LEFT     = Vector(1, 0, 0),
    TAP_RIGHT    = Vector(-1, 0, 0),
    TAP_FORWARD  = Vector(0, 0, 1),
    TAP_BACKWARD = Vector(0, 0, -1)
}
local tapString =
{
    TAP_NONE     = "TAP_NONE",
    TAP_LEFT     = "TAP_LEFT",
    TAP_RIGHT    = "TAP_RIGHT",
    TAP_FORWARD  = "TAP_FORWARD",
    TAP_BACKWARD = "TAP_BACKWARD"
}

local kTooltipSound = PrecacheAsset("sound/NS2.fev/common/tooltip")
local kHintInterval = 18
local kInvalidSound                = PrecacheAsset("sound/NS2.fev/common/invalid")
local kChatSound                   = PrecacheAsset("sound/NS2.fev/common/chat")

local kDownwardUseRange = 2.2
local kUseBoxSize = Vector(0.5, 0.5, 0.5)
local kWalkBackwardSpeedScalar = 1
local kStowedWeaponWeightScalar = 1
local kJumpHeight =  1.2
local kOnGroundDistance = 0.1
local kViewOffsetHeight = Player.kYExtents * 2 - 0.2
local kCrouchSpeedScalar = 0.6
local kCrouchShrinkAmount = 0.6
local kExtentsCrouchShrinkAmount = 0.5
local kCrouchAnimationTime = 0.4
local kThinkInterval = .2

// Player speeds
local kMass = 90.7 // ~200 pounds (incl. armor, weapons)
local kWalkMaxSpeed = 4             // Four miles an hour = 6,437 meters/hour = 1.8 meters/second (increase for FPS tastes)
local kRunMaxSpeed = 8
local kGoldSrcAcceleration = 6.5
local kGoldSrcAirAcceleration = 50
local kGoldSrcFriction = 4
local kStopSpeed = 3.6 //NS1 appears to have used 100, roughly 1.8 @ 60.. Trying 3.6 for interim.

//NS1 bhop skulk could get around 530-540 units with good bhop, 290 base makes for 1.84 - Trying 1.9 for now
local kBunnyJumpMaxSpeedFactor = 1.9 
local kMaxAirVeer = 1.2
local kLadderAcceleration = 16
local kMaxWalkableNormal =  math.cos( math.rad(45) )
local kDownSlopeFactor = math.tan( math.rad(60) ) // Stick to ground on down slopes up to 60 degrees
local kTauntMovementScalar = .05           // Players can only move a little while taunting
local kMinSlowSpeedScalar = .3
local kStepTotalTime    = 0.1  // Total amount of time to interpolate up a step
local kBodyYawTurnThreshold = Math.Radians(5)
local kTurnDelaySpeed = 8
local kTurnRunDelaySpeed = 2.5
local kTurnMoveYawBlendToMovingSpeed = 5
local kMaxStepAmount = 1.5
local kUnstickDistance = .1
local kUnstickOffsets =
{
    Vector(0, kUnstickDistance, 0), 
    Vector(kUnstickDistance, 0, 0), 
    Vector(-kUnstickDistance, 0, 0), 
    Vector(0, 0, kUnstickDistance), 
    Vector(0, 0, -kUnstickDistance)
}

-------------
-- NETWORK --
-------------

// When changing these, make sure to update Player:CopyPlayerDataFrom. Any data which 
// needs to survive between player class changes needs to go in here.
// Compensated variables are things that you want reverted when processing commands
// so basically things that are important for defining whether or not something can be shot
// for the player this is anything that can affect the hit boxes, like the animation that's playing,
// the current animation time, pose parameters, etc (not for the player firing but for the
// player being shot). 
local networkVars =
{
    fullPrecisionOrigin = "private vector", 
    
    // Controlling client index. -1 for not being controlled by a live player (ragdoll, fake player)
    clientIndex = "integer",
    
    viewModelId = "private entityid",
    
    resources = "private float (0 to " .. kMaxResources .. " by 0.1)",
    teamResources = "private float (0 to " .. kMaxResources .. " by 0.1)",
    gameStarted = "private boolean",
    countingDown = "private boolean",
    frozen = "private boolean",
    
    timeOfLastUse = "private time",
    
    crouching = "compensated boolean",
    crouched = "compensated boolean",
    timeOfCrouchChange = "compensated interpolated float (0 to 1 by 0.001)",
    crouchfraction = "compensated interpolated float (0 to 1 by 0.01)",
    
    // bodyYaw must be compenstated as it feeds into the animation as a pose parameter
    bodyYaw = "compensated interpolated float (-3.14159265 to 3.14159265 by 0.003)",
    standingBodyYaw = "interpolated float (0 to 6.2831853 by 0.003)",
    
    bodyYawRun = "compensated interpolated float (-3.14159265 to 3.14159265 by 0.003)",
    runningBodyYaw = "interpolated float (0 to 6.2831853 by 0.003)",
    timeLastMenu = "private time",
    darwinMode = "private boolean",
    
    // Set to true when jump key has been released after jump processed
    // Used to require the key to pressed multiple times
    jumpHandled = "private compensated boolean",
    timeOfLastJump = "private time",
    jumping = "compensated boolean",
    onGround = "compensated boolean",
    onGroundNeedsUpdate = "private compensated boolean",
    
    moveButtonPressed = "compensated boolean",
    
    onLadder = "boolean",
    
    // Player-specific mode. When set to kPlayerMode.Default, player moves and acts normally, otherwise
    // he doesn't take player input. Change mode and set modeTime to the game time that the mode
    // ends. ProcessEndMode() will be called when the mode ends. Return true from that to process
    // that mode change, otherwise it will go back to kPlayerMode.Default. Used for things like taunting,
    // building structures and other player actions that take time while the player is stationary.
    mode = "private enum kPlayerMode",
    
    // Time when mode will end. Set to -1 to have it never end.
    modeTime = "private float",
    
    primaryAttackLastFrame = "boolean",
    secondaryAttackLastFrame = "boolean",
    
    // Used to smooth out the eye movement when going up steps.
    stepStartTime = "compensated time",
    stepAmount = "compensated float(-2.1 to 2.1 by 0.001)", // limits must be just slightly bigger than kMaxStepAmount
    
    isUsing = "boolean",
    
    // Reduce max player velocity in some cases (marine jumping)
    slowAmount = "float (0 to 1 by 0.01)",
    movementModiferState = "boolean",
    forwardModifier = "boolean",
    giveDamageTime = "private time",
    
    pushImpulse = "private vector",
    pushTime = "private time",
    
    isMoveBlocked = "private boolean",
    
    communicationStatus = "enum kPlayerCommunicationStatus",
    
}

------------
-- MIXINS --
------------

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(CustomGroundMoveMixin, networkVars)
AddMixinNetworkVars(ControllerMixin, networkVars)
AddMixinNetworkVars(WeaponOwnerMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(UpgradableMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(BadgeMixin, networkVars)

local function GetTabDirectionVector(buttonReleased)

    if buttonReleased > 0 and buttonReleased < 5 then
        return tapVector[buttonReleased]
    end
    
    return tapVector[TAP_NONE]

end

function Player:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
	InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, CustomGroundMoveMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, ControllerMixin)
    InitMixin(self, WeaponOwnerMixin, { kStowedWeaponWeightScalar = kStowedWeaponWeightScalar })
    InitMixin(self, DoorMixin)
    // TODO: move LiveMixin to child classes (some day)
    InitMixin(self, LiveMixin)
    InitMixin(self, UpgradableMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, BadgeMixin)
    
    if Client then
        InitMixin(self, HelpMixin)
    end
    
    self:SetLagCompensated(true)
    
    self:SetUpdates(true)
    
    if Server then
        self.name = ""
        self.giveDamageTime = 0
        self.sendTechTreeBase = false
        self.waitingForAutoTeamBalance = false
        
    end
    
    self.viewOffset = Vector(0, 0, 0)
    
    self.bodyYaw = 0
    self.standingBodyYaw = 0
    
    self.bodyYawRun = 0
    self.runningBodyYaw = 0
    
    self.clientIndex = -1
	//NS2c Additions
    self.forwardModifier = false
    self.movementModiferState = false
	self.crouched = false
	self.landtime = 0
    
    self.timeLastMenu = 0
    self.darwinMode = false
    self.kills = 0
    self.deaths = 0
    
    self.jumpHandled = false
    self.jumping = false
    self.leftFoot = true
    self.mode = kPlayerMode.Default
    self.modeTime = -1
    self.primaryAttackLastFrame = false
    self.secondaryAttackLastFrame = false
    
    self.requestsScores = false
    self.viewModelId = Entity.invalidId
    
    self.usingStructure = nil
    self.timeOfLastUse = 0
    
    self.timeOfDeath = nil
    self.crouching = false
    self.timeOfCrouchChange = 0
    self.onGroundNeedsUpdate = true
    self.onGround = false
    
    self.onLadder = false
    
    self.timeLastOnGround = 0
    
    self.resources = 0
    
    self.stepStartTime = 0
    self.stepAmount = 0
    
    self.isMoveBlocked = false
    self.isRookie = false
    
    self.moveButtonPressed = false
    
    // Create the controller for doing collision detection.
    // Just use default values for the capsule size for now. Player will update to correct
    // values when they are known.
    self:CreateController(PhysicsGroup.PlayerControllersGroup)
    
    // Make the player kinematic so that bullets and other things collide with it.
    self:SetPhysicsGroup(PhysicsGroup.PlayerGroup)
    
    self.isUsing = false
    self.slowAmount = 0
    
    self.lastButtonReleased = TAP_NONE
    self.timeLastButtonReleased = 0
    self.previousMove = Vector(0, 0, 0)
    
    self.pushImpulse = Vector(0, 0, 0)
    self.pushTime = 0
    
end

local function InitViewModel(self)

    assert(Server)
    assert(self.viewModelId == Entity.invalidId)
    
    local viewModel = CreateEntity(ViewModel.mapName)
    viewModel:SetOrigin(self:GetOrigin())
    viewModel:SetParent(self)
    self.viewModelId = viewModel:GetId()
    
end

function Player:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    if Server then
    
        InitViewModel(self)
        // Only give weapons when playing.
        if self:GetTeamNumber() ~= kNeutralTeamType then
            self:InitWeapons()
        end
        
        self:SetName(kDefaultPlayerName)
        
        InitMixin(self, MobileTargetMixin)
        
    end
    
    self:SetScoreboardChanged(true)
    
    self:SetViewOffsetHeight(self:GetMaxViewOffsetHeight())
    
    self:UpdateControllerFromEntity()
    
    if Client then
    
        self.cameraShakeAmount = 0
        self.cameraShakeSpeed = 0
        self.cameraShakeTime = 0
        self.cameraShakeLastTime = 0
        
        self.lightShakeAmount = 0
        self.lightShakeEndTime = 0
        self.lightShakeScalar = 1
        
        self.giveDamageTimeClient = self.giveDamageTime
        
        if not self:GetIsLocalPlayer() and not self:isa("Commander") and not self:isa("Spectator") then
            InitMixin(self, UnitStatusMixin)
        end
        
    end
    
    self.communicationStatus = kPlayerCommunicationStatus.None
    
end

function DisablePlayerDanger(player)

    // Stop looping music.
    if player:GetIsLocalPlayer() then
        Client.StopMusic("sound/NS2.fev/danger")
    end
    
end

/**
 * Called when the player entity is destroyed.
 */
function Player:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    if Client then
    
        if self.viewModel ~= nil then
        
            Client.DestroyRenderViewModel(self.viewModel)
            self.viewModel = nil
            
        end
        
        self:UpdateCloakSoundLoop(false)
        self:UpdateDisorientSoundLoop(false)
        
        self:CloseMenu()
        
        if self.idleSoundInstance then
            Client.DestroySoundEffect(self.idleSoundInstance)
        end
        
        if self.guiCountDownDisplay then
        
            GetGUIManager():DestroyGUIScript(self.guiCountDownDisplay)
            self.guiCountDownDisplay = nil
            
        end
        
        if self.unitStatusDisplay then
        
            GetGUIManager():DestroyGUIScriptSingle("GUIUnitStatus")
            self.unitStatusDisplay = nil
            
        end
        
        DisablePlayerDanger(self)
        
    elseif Server then
        self:RemoveSpectators(nil)
    end
    
end

function Player:AddKill()

    self.kills = Clamp(self.kills + 1, 0, kMaxKills)
    self:SetScoreboardChanged(true)
    
end

function Player:OnEntityChange(oldEntityId, newEntityId)

    if Client then

        if self:GetId() == oldEntityId then
            // If this player is changing is any way, just assume the
            // buy/evolve menu needs to close.
            self:CloseMenu()
        end

    end

end

/**
 * Camera will zoom to third person and not attach to the ragdolls head when set to false.
 * Child classes can overwrite this.
 */
function Player:GetAnimateDeathCamera()
    return true
end 

function Player:GetReceivesBiologicalDamage()
    return true
end

function Player:GetReceivesVaporousDamage()
    return true
end

// Special unique client-identifier 
function Player:GetClientIndex()
    return self.clientIndex
end

function Player:AddPushImpulse(vector)
    self.pushImpulse = Vector(vector)
    self.pushTime = Shared.GetTime()
end

function Player:OverrideInput(input)

    ClampInputPitch(input)
    
    if self.timeClosedMenu and (Shared.GetTime() < self.timeClosedMenu + .25) then
    
        // Don't allow weapon firing
        local removePrimaryAttackMask = bit.bxor(0xFFFFFFFF, Move.PrimaryAttack)
        input.commands = bit.band(input.commands, removePrimaryAttackMask)
        
    end
    
    if self.shortcircuitInput then
        input.commands = 0x00000000
        input.move = Vector(0,0,0)
    end
    
    self.shortcircuitInput = MainMenu_GetIsOpened()
    
    return input
    
end

function Player:GetIsFirstPerson()
    return (Client and (Client.GetLocalPlayer() == self) and not self:GetIsThirdPerson())
end

function Player:GetViewOffset()
    return self.viewOffset
end

/**
 * Returns the view offset with the step smoothing factored in.
 */
function Player:GetSmoothedViewOffset()

    local deltaTime = Shared.GetTime() - self.stepStartTime
    
    if deltaTime < kStepTotalTime then
        return self.viewOffset + Vector( 0, -self.stepAmount * (1 - deltaTime / kStepTotalTime), 0 )
    end
    
    return self.viewOffset
    
end

/**
 * Stores the player's current view offset. Calculated from GetMaxViewOffset() and crouch state.
 */
function Player:SetViewOffsetHeight(newViewOffsetHeight)
    self.viewOffset.y = newViewOffsetHeight
end

function Player:GetMaxViewOffsetHeight()
    return kViewOffsetHeight
end

// worldX => -map y
// worldZ => +map x
function Player:GetMapXY(worldX, worldZ)

    local success = false
    local mapX = 0
    local mapY = 0
    
    local heightmap = GetHeightmap()

    if heightmap then
        mapX = heightmap:GetMapX(worldZ)
        mapY = heightmap:GetMapY(worldX)
    else
        Print("Player:GetMapXY(): heightmap is nil")
        return false, 0, 0
    end

    if mapX >= 0 and mapX <= 1 and mapY >= 0 and mapY <= 1 then
        success = true
    end

    return success, mapX, mapY

end

// Return modifier to our max speed (1 is none, 0 is full)
function Player:GetSlowSpeedModifier()

    // Never drop to 0 speed
    return 1 - (1 - kMinSlowSpeedScalar) * self.slowAmount
    
end

function Player:GetController()

    return self.controller
    
end

function Player:WeaponUpdate()

    local weapon = self:GetActiveWeapon()
    if weapon then
        weapon:OnUpdateWeapon(self)
    end
    
end

function Player:OnPrimaryAttack()
end

function Player:OnSecondaryAttack()
end

function Player:PrimaryAttack()

    local weapon = self:GetActiveWeapon()
    if weapon then
        weapon:OnPrimaryAttack(self)
        self:OnPrimaryAttack()
    end
    
end

function Player:SecondaryAttack()

    local weapon = self:GetActiveWeapon()        
    if weapon and weapon:GetHasSecondary(self) then
        weapon:OnSecondaryAttack(self)
        self:OnSecondaryAttack()
    end

end

function Player:PrimaryAttackEnd()

    local weapon = self:GetActiveWeapon()
    if weapon then
        weapon:OnPrimaryAttackEnd(self)
    end

end

function Player:SecondaryAttackEnd()

    local weapon = self:GetActiveWeapon()
    if weapon and weapon:GetHasSecondary(self) then
        weapon:OnSecondaryAttackEnd(self)
    end
    
end

function Player:SelectNextWeapon()
    self:SelectNextWeaponInDirection(1)
end

function Player:SelectPrevWeapon()
    self:SelectNextWeaponInDirection(-1)
end

function Player:Reload()

    local weapon = self:GetActiveWeapon()
    if weapon ~= nil then
        weapon:OnReload(self)
    end
    
end

local function GetIsValidUseOfPoint(self, entity, usablePoint, useRange)

    if GetPlayerCanUseEntity(self, entity) then
    
        local viewCoords = self:GetViewAngles():GetCoords()
        local toUsePoint = usablePoint - self:GetEyePos()
        
        return toUsePoint:GetLength() < useRange and viewCoords.zAxis:DotProduct(GetNormalizedVector(toUsePoint)) > 0.8
        
    end
    
    return false
    
end

/**
 * Will return true if the passed in entity can be used by self and
 * the entity has no attach points to use.
 */
local function GetCanEntityBeUsedWithNoUsablePoint(self, entity)

    if HasMixin(entity, "Usable") then
    
        // Ignore usable points if a Structure has not been built.
        local usablePointOverride = HasMixin(entity, "Construct") and not entity:GetIsBuilt()
        
        local usablePoints = entity:GetUsablePoints()
        if usablePointOverride or (not usablePoints or #usablePoints == 0) and GetPlayerCanUseEntity(self, entity) then
            return true, nil
        end
        
    end
    
    return false, nil
    
end

function Player:PerformUseTrace()

    local startPoint = self:GetEyePos()
    local viewCoords = self:GetViewAngles():GetCoords()
    
    // To make building low objects like an infantry portal easier, increase the use range
    // as we look downwards. This effectively makes use trace in a box shape when looking down.
    local useRange = kPlayerUseRange
    local sinAngle = viewCoords.zAxis:GetLengthXZ()
    if viewCoords.zAxis.y < 0 and sinAngle > 0 then
    
        useRange = kPlayerUseRange / sinAngle
        if -viewCoords.zAxis.y * useRange > kDownwardUseRange then
            useRange = kDownwardUseRange / -viewCoords.zAxis.y
        end
        
    end
    
    // Get possible useable entities within useRange that have an attach point.
    local ents = GetEntitiesWithMixinWithinRange("Usable", self:GetOrigin(), useRange)
    for e = 1, #ents do
    
        local entity = ents[e]
        // Filter away anything on the enemy team. Allow using entities not on any team.
        if not HasMixin(entity, "Team") or self:GetTeamNumber() == entity:GetTeamNumber() then
        
            local usablePoints = entity:GetUsablePoints()
            if usablePoints then
            
                for p = 1, #usablePoints do
                
                    local usablePoint = usablePoints[p]
                    local success = GetIsValidUseOfPoint(self, entity, usablePoint, useRange)
                    if success then
                        return entity, usablePoint
                    end
                    
                end
                
            end
            
        end
        
    end
    
    // If failed, do a regular trace with entities that don't have usable points.
    local viewCoords = self:GetViewAngles():GetCoords()
    local endPoint = startPoint + viewCoords.zAxis * useRange
    local activeWeapon = self:GetActiveWeapon()
    
    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Default, PhysicsMask.AllButPCs, EntityFilterTwo(self, activeWeapon))  
    
    if trace.fraction < 1 and trace.entity ~= nil then
    
        // Only return this entity if it can be used and it does not have a usable point (which should have been
        // caught in the above cases).
        if GetCanEntityBeUsedWithNoUsablePoint(self, trace.entity) then
            return trace.entity, trace.endPoint
        end
        
    end
    
    // Called in case the normal trace fails to allow some tolerance.
    // Modify the endPoint to account for the size of the box.
    local maxUseLength = (kUseBoxSize - -kUseBoxSize):GetLength()
    endPoint = startPoint + viewCoords.zAxis * (useRange - maxUseLength / 2)
    local traceBox = Shared.TraceBox(kUseBoxSize, startPoint, endPoint, CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterTwo(self, activeWeapon))
    // Only return this entity if it can be used and it does not have a usable point (which should have been caught in the above cases).
    if traceBox.fraction < 1 and traceBox.entity ~= nil and GetCanEntityBeUsedWithNoUsablePoint(self, traceBox.entity) then
    
        local direction = startPoint - traceBox.entity:GetOrigin()
        direction:Normalize()
        
        // Must be generally facing the entity.
        if viewCoords.zAxis:DotProduct(direction) < -0.5 then
            return traceBox.entity, traceBox.endPoint
        end
        
    end
    
    return nil, Vector(0, 0, 0)
    
end

function Player:UseTarget(entity, attachPoint, timePassed)

    assert(entity)
    
    local useSuccessTable = { useSuccess = false } 
    if entity.OnUse then
    
        useSuccessTable.useSuccess = true
        entity:OnUse(self, timePassed, useSuccessTable)
        
    end
    
    self:OnUseTarget(entity)
    
    return useSuccessTable.useSuccess
    
end

/**
 * Check to see if there's a ScriptActor we can use. Checks any usable points returned from  
 * GetUsablePoints() and if that fails, does a regular trace ray. Returns true if we processed the action.
 */
local function AttemptToUse(self, timePassed)

    PROFILE("Player:AttemptToUse")
    
    assert(timePassed >= 0)
    
    if (Shared.GetTime() - self.timeOfLastUse) < kUseInterval then
        return false
    end
    
    // Cannot use anything unless playing the game (a non-spectating player).
    if not self:GetIsOnPlayingTeam() then
        return false
    end
    
    // Trace to find use entity.
    local entity, usablePoint = self:PerformUseTrace()
    
    // Use it.
    if entity then
    
        // if the game isn't started yet, check if the entity is usuable in non-started game
        // (allows players to select commanders before the game has started)
        if not self:GetGameStarted() and not (entity.GetUseAllowedBeforeGameStart and entity:GetUseAllowedBeforeGameStart()) then
            return false
        end
        
        // Use it.
        if self:UseTarget(entity, attachPoint, kUseInterval) then
        
            self:SetIsUsing(true)
            self.timeOfLastUse = Shared.GetTime()
            return true
            
        end
        
    end
    
end

function Player:Buy()
end

function Player:Holster()

    local success = false
    local weapon = self:GetActiveWeapon()
    
    if weapon then
    
        weapon:OnHolster(self)
        
        success = true
        
    end
    
    return success
    
end

function Player:Draw(previousWeaponName)

    local success = false
    local weapon = self:GetActiveWeapon()
    
    if weapon ~= nil then
    
        weapon:OnDraw(self, previousWeaponName)
        
        success = true
        
    end
    
    return success
    
end

function Player:GetExtentsOverride()

    local extents = self:GetMaxExtents()
    if self.crouched then
        extents.y = extents.y * (1 - self:GetExtentsCrouchShrinkAmount())
    end
    return extents
    
end

/**
 * Returns true if the player is currently on a team and the game has started.
 */
function Player:GetIsPlaying()
    return self.gameStarted and self:GetIsOnPlayingTeam()
end

function Player:GetIsOnPlayingTeam()
    return self:GetTeamNumber() == kTeam1Index or self:GetTeamNumber() == kTeam2Index
end

local function HasTeamAssigned(self)

    local teamNumber = self:GetTeamNumber()
    return (teamNumber == kTeam1Index or teamNumber == kTeam2Index)
    
end

function Player:GetCanTakeDamageOverride()
    return HasTeamAssigned(self)
end

function Player:GetIsDevoured()
    return false
end

function Player:GetCanDieOverride()
    return HasTeamAssigned(self) and not self:GetIsDevoured()
end

// Individual resources
function Player:GetResources()
    return self.resources
end

// Returns player mass in kg
function Player:GetMass()
    return kMass
end

function Player:AddResources(amount)

    local resReward = math.min(amount, kMaxPersonalResources - self:GetResources())
    local oldRes = self.resources
    self:SetResources(self:GetResources() + resReward)
    
    if oldRes ~= self.resources then
        self:SetScoreboardChanged(true)
    end
    
    return resReward
    
end

function Player:AddTeamResources(amount)
    self.teamResources = math.max(math.min(self.teamResources + amount, kMaxResources), 0)
end

function Player:GetDisplayResources()

    local displayResources = self.resources
    if(Client and self.resourceDisplay) then
        displayResources = self.animatedResourcesDisplay:GetDisplayValue()
    end
    return math.floor(displayResources)
    
end

function Player:GetPersonalResources()

    return self.resources
    
end

function Player:GetDisplayTeamResources()

    local displayTeamResources = self.teamResources
    if(Client and self.resourceDisplay) then
        displayTeamResources = self.animatedTeamResourcesDisplay:GetDisplayValue()
    end
    return displayTeamResources
    
end

// Team resources
function Player:GetTeamResources()
    return self.teamResources
end

function Player:GetVerticleMove()
    return false
end

function Player:GetMaxAirVeer()
    return kMaxAirVeer
end

function Player:GoldSrc_AirAccelerate(velocity, time, wishdir, wishspeed, acceleration)
    if wishspeed > kMaxAirVeer then
        wishspeed = kMaxAirVeer
    end
    
    return self:GoldSrc_Accelerate(velocity, time, wishdir, wishspeed, acceleration)
end

function Player:GoldSrc_Accelerate(velocity, time, wishdir, wishspeed, acceleration)
    // Determine veer amount    
    local currentspeed = velocity:DotProduct(wishdir)
    
    // See how much to add
    local addSpeed = wishspeed - currentspeed
    
    // If not adding any, done.
    if addSpeed <= 0.0 then
        return velocity
    end
    
    // Determine acceleration speed after acceleration
    local accelspeed = acceleration * wishspeed * time
    
    // Cap it
    if accelspeed > addSpeed then
        accelspeed = addSpeed
    end
    
    wishdir:Scale(accelspeed)
    
    // Add to velocity
    velocity:Add(wishdir)
    
    return velocity
end

function Player:UpdateMovementMode(movementmode)
    self.forwardModifier = movementmode
end

function Player:GoldSrc_GetWishVelocity(input)
    if HasMixin(self, "Stun") and self:GetIsStunned() then
        return Vector(0,0,0)
    end
    
    // goldSrc maxspeed works different than ns2 maxspeed.
    // Here is it used as an acceleration target, in ns2
    // it's seemingly used for clamping the speed
    local maxspeed = self:GoldSrc_GetMaxSpeed()
    
    // Override forward input to allow greater ease of use if set.
    if not self.forwardModifier and input.move.z > 0 and input.move.x ~= 0 and not self:GetIsOnGround() then
        input.move.z = 0
    end

    // wishdir
    local move = GetNormalizedVector(input.move)
    move:Scale(maxspeed)
    
    // grab view angle (ignoring pitch)
    local angles = self:ConvertToViewAngles(0, input.yaw, 0)
    
    if self:GetIsOnLadder() then
        angles = self:ConvertToViewAngles(input.pitch, input.yaw, 0)
    elseif self.GetIsWallWalking and self:GetIsWallWalking() then
        angles = self:ConvertToViewAngles(input.pitch, input.yaw, 0)
    end
    
    local viewCoords = angles:GetCoords() // to matrix?
    local moveVelocity = viewCoords:TransformVector(move) // get world-space move direction

    return moveVelocity
end

function Player:GetIsAffectedByAirFriction()
    return not self:GetIsOnGround()
end

function Player:GetGroundFrictionForce()
    return ConditionalValue(self.crouching, 10, 4)
end   

function Player:GetAirFrictionForce()
    return 0.5
end

function Player:GetClimbFrictionForce()
    return 5
end

function Player:GetCanClimb()
    return true
end

function Player:GetStopSpeed()
    return kStopSpeed
end

function Player:PerformsVerticalMove()
    return false
end

function Player:GoldSrc_GetFriction()
    return kGoldSrcFriction
end

function Player:GoldSrc_Friction(input, velocity)
    if self:GetIsOnSurface() or self:GetIsOnLadder() then
        // Calculate speed
        local speed = velocity:GetLength()
        
        if speed < 0.0001 then
            return velocity
        end
        
        local friction = self:GoldSrc_GetFriction()
        if self:GetIsOnLadder() then
            friction = self:GetClimbFrictionForce()
        end
        
        local stopspeed = self:GetStopSpeed()
        // Bleed off some speed, but if we have less than the bleed
		//  threshhold, bleed the theshold amount.
        local control = (speed < stopspeed) and stopspeed or speed
        
        // Add the amount to the drop amount.
        local drop = control * friction * input.time
        
        // scale the velocity
        local newspeed = speed - drop
        if newspeed < 0 then
            newspeed = 0
        end
        
        // Determine proportion of old speed we are using.
        newspeed = newspeed / speed
        
        // Adjust velocity according to proportion.
        velocity:Scale(newspeed)
    end
    
    return velocity
end

function Player:GoldSrc_GetMaxSpeed(possible)
    if possible then
        return kRunMaxSpeed
    end
    
    local maxSpeed = kRunMaxSpeed
    
    if self.movementModiferState and self:GetIsOnSurface() then
        maxSpeed = kWalkMaxSpeed
    end
      
    return maxSpeed
end

function Player:GoldSrc_GetAcceleration()
    return ConditionalValue(self:GetIsOnGround(), kGoldSrcAcceleration, kGoldSrcAirAcceleration)
end

function Player:GetGravityAllowed()

    // No gravity when on ladders or on the ground.
    return not self:GetIsOnLadder() and not self:GetIsOnGround()
    
end

function Player:GetCrouchSpeedScalar()
    return kCrouchSpeedScalar
end

function Player:GetMoveDirection(moveVelocity)

    if self:GetIsOnLadder() then
        return GetNormalizedVector(moveVelocity)
    end
    
    local up = Vector(0, 1, 0)
    local right = GetNormalizedVector(moveVelocity):CrossProduct(up)
    local moveDirection = up:CrossProduct(right)
    moveDirection:Normalize()
    
    return moveDirection
    
end

function Player:OnUseTarget(target)
end

function Player:OnUseEnd()
end

function Player:EndUse(deltaTime)

    if not self:GetIsUsing() then
        return
    end
    
    local callOnUseEnd = false
    
    // Pull out weapon again if we haven't built for a bit
    if (Shared.GetTime() - self.timeOfLastUse) > kUseInterval then
    
        self:SetIsUsing(false)
        callOnUseEnd = true
        
    elseif self:isa("Alien") then
    
        self:SetIsUsing(false)
        callOnUseEnd = true
        
    end
    
    if callOnUseEnd then
        self:OnUseEnd()
    end
    
    self.updatedSinceUse = true
    
end

function Player:GetMinimapFov(targetEntity)

    if targetEntity and targetEntity:isa("Player") then
        return 60
    end
    
    return 90
    
end

// Allow child classes to alter player's move at beginning of frame. Alter amount they
// can move by scaling input.move, remove key presses, etc.
function Player:AdjustMove(input)

    PROFILE("Player:AdjustMove")
    
    // Don't allow movement when frozen in place
    if self.frozen then
        input.move:Scale(0)
    else        
    
        // Allow child classes to affect how much input is allowed at any time
        if self.mode == kPlayerMode.Taunt then
            input.move:Scale(kTauntMovementScalar)
        end
        
    end
    
    return input
    
end

function Player:GetAngleSmoothingMode()
    return "euler"
end

function Player:GetDesiredAngles(deltaTime)

    desiredAngles = Angles()
    desiredAngles.pitch = 0
    desiredAngles.roll = self.viewRoll
    desiredAngles.yaw = self.viewYaw
    
    return desiredAngles

end

function Player:GetAngleSmoothRate()
    return 8
end

function Player:GetRollSmoothRate()
    return 6
end

function Player:GetPitchSmoothRate()
    return 6
end

function Player:GetSlerpSmoothRate()
    return 6
end

function Player:GetSmoothRoll()
    return true
end

function Player:GetSmoothPitch()
    return true
end

function Player:GetPredictSmoothing()
    return true
end

// also predict smoothing on the local client, since no interpolation is happening here and some effects can depent on current players angle (like exo HUD)
function Player:AdjustAngles(deltaTime)

    local angles = self:GetAngles()
    local desiredAngles = self:GetDesiredAngles(deltaTime)
    local smoothMode = self:GetAngleSmoothingMode()
    
    if desiredAngles == nil then

        // Just keep the old angles

    elseif smoothMode == "euler" then
        
        angles.yaw = SlerpRadians(angles.yaw, desiredAngles.yaw, self:GetAngleSmoothRate() * deltaTime )
        angles.roll = SlerpRadians(angles.roll, desiredAngles.roll, self:GetRollSmoothRate() * deltaTime )
        angles.pitch = SlerpRadians(angles.pitch, desiredAngles.pitch, self:GetPitchSmoothRate() * deltaTime )
        
    elseif smoothMode == "quatlerp" then

        //DebugDrawAngles( angles, self:GetOrigin(), 2.0, 0.5 )
        //Print("pre slerp = %s", ToString(angles)) 
        angles = Angles.Lerp( angles, desiredAngles, self:GetSlerpSmoothRate()*deltaTime )

    else
        
        angles.pitch = desiredAngles.pitch
        angles.roll = desiredAngles.roll
        angles.yaw = desiredAngles.yaw

    end

    AnglesTo2PiRange(angles)
    self:SetAngles(angles)
    
end

function Player:UpdateViewAngles(input)

    PROFILE("Player:UpdateViewAngles")

    // Update to the current view angles.    
    local viewAngles = Angles(input.pitch, input.yaw, 0)
    self:SetViewAngles(viewAngles)
        
    // Update view offset from crouching

    local viewY = self:GetMaxViewOffsetHeight()

    // Don't set new view offset height unless needed (avoids Vector churn).
    local lastViewOffsetHeight = self:GetSmoothedViewOffset().y
    if math.abs(viewY - lastViewOffsetHeight) > kEpsilon then
        self:SetViewOffsetHeight(viewY)
    end
    
    self:AdjustAngles(input.time)
    
end

function Player:OnJumpLand(landIntensity, slowDown)

    self.landtime = Shared.GetTime()
    
    if Client and self:GetIsLocalPlayer() then
        self:OnJumpLandLocalClient()
    end
    
end

function Player:SlowDown(slowScalar)
    self:AddSlowScalar(slowScalar)
end

function Player:GetIsOnSurface()
    return self:GetIsOnGround()
end    

function Player:ReceivesFallDamage()
    return true
end

local function UpdateJumpLand(self, wasOnGround, previousVelocity)

    // If we landed this frame
    if self.jumping and wasOnGround == false and self:GetIsOnSurface() then
    
        local slowDown = false
        if self:GetSlowOnLand() then
        
            self:AddSlowScalar(0.5)
            slowDown = true
            
        end
        
        self.landIntensity = math.abs(previousVelocity.y) / 10
        
        self.jumping = false
        
        self:OnJumpLand(self.landIntensity, slowDown)
        
    end
    
end

local function UpdateFallDamage(self, wasOnGround, previousVelocity)

    if wasOnGround == false and self:GetIsOnSurface() and self:ReceivesFallDamage() then
        if math.abs(previousVelocity.y) > kFallDamageMinimumVelocity then
            local damage = math.max(0, math.abs(previousVelocity.y * kFallDamageScalar) - 195)
            self:TakeDamage(damage, self, self, self:GetOrigin(), nil, 0, damage, kDamageType.Falling)
        end
    end
end

local kDoublePI = math.pi * 2
local kHalfPI = math.pi / 2

function Player:GetIsUsingBodyYaw()
    return true
end

local function UpdateBodyYaw(self, deltaTime, tempInput)

    if self:GetIsUsingBodyYaw() then

        local yaw = self:GetAngles().yaw

        // Reset values when moving.
        if self:GetVelocityLength() > 0.1 then
        
            // Take a bit of time to reset value so going into the move animation doesn't skip.
            self.standingBodyYaw = SlerpRadians(self.standingBodyYaw, yaw, deltaTime * kTurnMoveYawBlendToMovingSpeed)
            self.standingBodyYaw = Math.Wrap(self.standingBodyYaw, 0, kDoublePI)
            
            self.runningBodyYaw = SlerpRadians(self.runningBodyYaw, yaw, deltaTime * kTurnRunDelaySpeed)
            self.runningBodyYaw = Math.Wrap(self.runningBodyYaw, 0, kDoublePI)
            
        else
        
            self.runningBodyYaw = yaw
            
            local diff = RadianDiff(self.standingBodyYaw, yaw)
            if math.abs(diff) >= kBodyYawTurnThreshold then
            
                diff = Clamp(diff, -kBodyYawTurnThreshold, kBodyYawTurnThreshold)
                self.standingBodyYaw = Math.Wrap(diff + yaw, 0, kDoublePI)
                
            end
            
        end
        
        self.bodyYawRun = Clamp(RadianDiff(self.runningBodyYaw, yaw), -kHalfPI, kHalfPI)
        self.runningBodyYaw = Math.Wrap(self.bodyYawRun + yaw, 0, kDoublePI)
        
        local adjustedBodyYaw = RadianDiff(self.standingBodyYaw, yaw)
        if adjustedBodyYaw >= 0 then
            self.bodyYaw = adjustedBodyYaw % kHalfPI
        else
            self.bodyYaw = -(kHalfPI - adjustedBodyYaw % kHalfPI)
        end

    else

        // Sometimes, probably due to prediction, these values can go out of range. Wrap them here
        self.standingBodyYaw = Math.Wrap(self.standingBodyYaw, 0, kDoublePI)
        self.runningBodyYaw = Math.Wrap(self.runningBodyYaw, 0, kDoublePI)
        self.bodyYaw = 0
        self.bodyYawRun = 0

    end
    
end

local function UpdateAnimationInputs(self, input)

    // From WeaponOwnerMixin.
    // NOTE: We need to process moves on weapons and view model before adjusting origin + angles below.
    self:ProcessMoveOnWeapons(input)
    
    local viewModel = self:GetViewModelEntity()
    if viewModel then
        viewModel:ProcessMoveOnModel()
    end
    
    if self.ProcessMoveOnModel then
        self:ProcessMoveOnModel()
    end

end

function Player:OnProcessIntermediate(input)
   
    if self:GetIsAlive() and not self.countingDown then
        // Update to the current view angles so that the mouse feels smooth and responsive.
        self:UpdateViewAngles(input)
    end
    
    // This is necessary to update the child entity bones so that the view model
    // animates smoothly and attached weapons will have the correct coords.
    local numChildren = self:GetNumChildren()
    for i = 1,numChildren do
        local child = self:GetChildAtIndex(i - 1)
        if child.OnProcessIntermediate then
            child:OnProcessIntermediate(input)
        end
    end
    
    self:UpdateClientEffects(input.time, true)
    
end

// done once per process move before handling player movement
local function UpdateOnGroundState(self)

    self.onGround = false        
    self.onGround = self:GetIsCloseToGround(Player.kOnGroundDistance)
    
    if self.onGround then
        self.timeLastOnGround = Shared.GetTime()
    end

end

// You can't modify a compensated field for another (relevant) entity during OnProcessMove(). The
// "local" player doesn't undergo lag compensation it's only all of the other players and entities.
// For example, if health was compensated, you can't modify it when a player was shot -
// it will just overwrite it with the old value after OnProcessMove() is done. This is because
// compensated fields are rolled back in time, so it needs to restore them once the processing
// is done. So it backs up, synchs to the old state, runs the OnProcessMove(), then restores them. 
function Player:OnProcessMove(input)

    PROFILE("Player:OnProcessMove")

    local commands = input.commands
    if self:GetIsAlive() then
    
        if self.countingDown then
        
            input.move:Scale(0)
            input.commands = 0
            
        else
        
            // Allow children to alter player's move before processing. To alter the move
            // before it's sent to the server, use OverrideInput
            input = self:AdjustMove(input)
            
            // Update player angles and view angles smoothly from desired angles if set. 
            // But visual effects should only be calculated when not predicting.
            self:UpdateViewAngles(input)  
            
        end
        
    end
    
    // Drop timers
    self.timeOfCrouchChange = math.max(0, self.timeOfCrouchChange - input.time)
    
    self:OnUpdatePlayer(input.time)
    
    ScriptActor.OnProcessMove(self, input)
    
    self:HandleButtons(input)
    
    UpdateAnimationInputs(self, input)
    
    if self:GetIsAlive() then
    
        ASSERT(self.controller ~= nil)
        
        // Force an update to whether or not we're on the ground in case something
        // has moved out from underneath us.
        self.onGroundNeedsUpdate = true      
        local wasOnGround = self.onGround
        local previousVelocity = self:GetVelocity()
        
        //UpdateOnGroundState(self)
                
        // Update origin and velocity from input move (main physics behavior).
        self:UpdateMove(input)
        
        self:UpdateMaxMoveSpeed(input.time) 
        
        UpdateFallDamage(self, wasOnGround, previousVelocity)
        UpdateJumpLand(self, wasOnGround, previousVelocity)
        
        // Restore the buttons so that things like the scoreboard, etc. work.
        input.commands = commands
        
        // Everything else
        self:UpdateMisc(input)
        self:UpdateSharedMisc(input)
        
        // Debug if desired
        //self:OutputDebug()
        
        UpdateBodyYaw(self, input.time, input)
        
    end
    
    self:EndUse(input.time)
    
end

function Player:OnProcessSpectate(deltaTime)

    ScriptActor.OnProcessSpectate(self, deltaTime)
    
    local numChildren = self:GetNumChildren()
    for i = 1, numChildren do
    
        local child = self:GetChildAtIndex(i - 1)
        if child.OnProcessIntermediate then
            child:OnProcessIntermediate()
        end
        
    end
    
    local viewModel = self:GetViewModelEntity()
    if viewModel then
        viewModel:ProcessMoveOnModel()
    end
    
    self:OnUpdatePlayer(deltaTime)
    
end

function Player:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)
    
    self:OnUpdatePlayer(deltaTime)
    
end

function Player:GetSlowOnLand()
    return false
end

function Player:UpdateMaxMoveSpeed(deltaTime)    

    ASSERT(deltaTime >= 0)
    
    // Only recover max speed when on the ground
    if self:GetIsOnGround() then
    
        local newSlow = math.max(0, self.slowAmount - deltaTime)
        //if newSlow ~= self.slowAmount then
        //    Print("UpdateMaxMoveSpeed(%s) => %s => %s (time: %s)", ToString(deltaTime), ToString(self.slowAmount), newSlow, ToString(Shared.GetTime()))
        //end
        self.slowAmount = newSlow    
        
    end
    
end

function Player:OutputDebug()

    local startPoint = Vector(self:GetOrigin())
    startPoint.y = startPoint.y + self:GetExtents().y
    DebugBox(startPoint, startPoint, self:GetExtents(), .05, 1, 1, 0, 1)
    
end

// Note: It doesn't look like this is being used anymore.
function Player:GetItem(mapName)
    
    for i = 0, self:GetNumChildren() - 1 do
    
        local currentChild = self:GetChildAtIndex(i)
        if currentChild:GetMapName() == mapName then
            return currentChild
        end

    end
    
    return nil
    
end

function Player:OverrideVisionRadius()
    return kPlayerLOSDistance
end

function Player:GetTraceCapsule()
    return GetTraceCapsuleFromExtents(self:GetExtents())    
end

// Required by ControllerMixin.
function Player:GetControllerSize()
    return GetTraceCapsuleFromExtents(self:GetExtents())
end

// Required by ControllerMixin.
function Player:GetMovePhysicsMask()
    return PhysicsMask.Movement
end

/**
 * Moves the player downwards (by at most a meter).
 */
function Player:DropToFloor()

    PROFILE("Player:DropToFloor")

    if self.controller then
        self:UpdateControllerFromEntity()
        self.controller:Move( Vector(0, -1, 0), CollisionRep.Move, CollisionRep.Move, self:GetMovePhysicsMask())    
        self:UpdateOriginFromController()
    end

end


function Player:GetCanStep()
    return self:GetIsOnGround()
end

function Player:GetCanStepOver(entity)
    return false
end

local function CheckCanStepOver(self, hitEntities)

    local canStepOver = true

    if hitEntities then
    
        for _, entity in ipairs(hitEntities) do
        
            if not self:GetCanStepOver(entity) then
                canStepOver = false
            end
            
        end
    
    end 
    
    return canStepOver

end

function Player:UpdatePosition(velocity, time)

    PROFILE("Player:UpdatePosition")
    
    if not self.controller then
        return velocity
    end

    // We need to make a copy so that we aren't holding onto a reference
    // which is updated when the origin changes.
    local start         = Vector(self:GetOrigin())
    local startVelocity = Vector(velocity)
   
    local maxSlideMoves = 3
    
    local offset = nil
    local stepHeight = self:GetStepHeight()
    local canStep = self:GetCanStep()
    local onGround = self:GetIsOnGround()
    
    local offset = velocity * time
    local horizontalOffset = Vector(offset)
    horizontalOffset.y = 0
    local hitEntities = nil
    local completedMove = false
    local averageSurfaceNormal = nil
    
    local stepUpOffset = 0

    if canStep then
        
        local horizontalOffsetLength = horizontalOffset:GetLength()
        local fractionOfOffset = 1
        
        if horizontalOffsetLength > 0 then
        
            // check if we would collide with something, set fourth parameter to false
            completedMove, hitEntities, averageSurfaceNormal = self:PerformMovement(horizontalOffset, maxSlideMoves, velocity, false)   
            velocity = Vector(startVelocity)       

            if CheckCanStepOver(self, hitEntities) then

                // Move up
                self:PerformMovement(Vector(0, stepHeight, 0), 1)
                local steppedStart = self:GetOrigin()
                stepUpOffset = steppedStart.y - start.y
            
            end
        
            // Horizontal move
            self:PerformMovement(horizontalOffset, maxSlideMoves, velocity)
            
            local movePerformed = self:GetOrigin() - (steppedStart or start)
            fractionOfOffset = movePerformed:DotProduct(horizontalOffset) / (horizontalOffsetLength*horizontalOffsetLength)
            
        end

        local downStepAmount = offset.y - stepUpOffset - horizontalOffsetLength * kDownSlopeFactor
        
        if fractionOfOffset < 0.5 then
        
            // Didn't really move very far, try moving without step up
            local savedOrigin = Vector(self:GetOrigin())
            local savedVelocity = Vector(velocity)

            self:SetOrigin(start)
            velocity = Vector(startVelocity)
                 
            self:PerformMovement(offset, maxSlideMoves, velocity)
            
            local movePerformed = self:GetOrigin() - start
            local alternativeFractionOfOffset = movePerformed:DotProduct(offset) / offset:GetLengthSquared()
            
            if alternativeFractionOfOffset > fractionOfOffset then
                // This move is better!
                downStepAmount = 0
            else
                // Stepped move was better - go back to it!
                self:SetOrigin(savedOrigin)
                velocity = savedVelocity                    
            end            

        end
        
        // Vertical move
        if downStepAmount ~= 0 then
            self:PerformMovement(Vector(0, downStepAmount, 0), 1)
        end
        
        // Check to see if we moved up a step and need to smooth out
        // the movement.
        local yDelta = self:GetOrigin().y - start.y
        
        if yDelta ~= 0 then
        
            // If we're already interpolating up a step, we need to take that into account
            // so that we continue that interpolation, plus our new step interpolation
            
            local deltaTime      = Shared.GetTime() - self.stepStartTime
            local prevStepAmount = 0
            
            if deltaTime < kStepTotalTime then
                prevStepAmount = self.stepAmount * (1 - deltaTime / kStepTotalTime)
            end        
            
            self.stepStartTime = Shared.GetTime()
            self.stepAmount    = Clamp(yDelta + prevStepAmount, -kMaxStepAmount, kMaxStepAmount)
            
        end      

    else
        
        // Just do the move
        completedMove, hitEntities, averageSurfaceNormal = self:PerformMovement(offset, maxSlideMoves, velocity)        
            
    end

    return velocity, hitEntities, averageSurfaceNormal
    
end

// Return the height that this player can step over automatically
function Player:GetStepHeight()
    return .5
end

function Player:SplineFraction(value, scale)
    value = scale * value
    local valueSq = value * value
    
    // Nice little ease-in, ease-out spline-like curve
    return 3.0 * valueSq - 2.0 * valueSq * value
end

/**
 * Returns a value between 0 and 1 indicating how much the player has crouched
 * visually (actual crouching is binary).
 */
function Player:GetCrouchAmount()
    return self.crouchfraction
end

function Player:GetCrouching()
    return self.crouching
end

function Player:GetCrouched()
    return self.crouched
end

function Player:GetCrouchShrinkAmount()
    return kCrouchShrinkAmount
end

function Player:GetExtentsCrouchShrinkAmount()
    return kExtentsCrouchShrinkAmount
end

// Returns true if the player is currently standing on top of something solid. Recalculates
// onGround if we've updated our position since we've last called this.
function Player:GetIsOnGround()
    
    // Re-calculate every time SetOrigin is called
    if self.onGroundNeedsUpdate then
    
        self.onGround = false
        
        self.onGround = self:GetIsCloseToGround(kOnGroundDistance)
        
        if self.onGround then
            self.timeLastOnGround = Shared.GetTime()
        end
        
        self.onGroundNeedsUpdate = false        
        
    end
    
    if self:GetIsOnLadder() then
        return false
    end
    
    return self.onGround
    
end

function Player:SetIsOnLadder(onLadder, ladderEntity)
    self.onLadder = onLadder
end

// Override this for Player types that shouldn't be on Ladders
function Player:GetIsOnLadder()
    return self.onLadder
end

// Recalculate self.onGround next time
function Player:SetOrigin(origin)

    Entity.SetOrigin(self, origin)
    
    self:UpdateControllerFromEntity()
    
    self.onGroundNeedsUpdate = true
    
end

// Returns boolean indicating if we're at least the passed in distance from the ground.
function Player:GetIsCloseToGround(distanceToGround)

    PROFILE("Player:GetIsCloseToGround")

    if self.controller == nil then
        return false
    end

    if (self:GetVelocity().y > 0 and self.timeOfLastJump ~= nil and (Shared.GetTime() - self.timeOfLastJump < .2)) then
    
        // If we are moving away from the ground, don't treat
        // us as standing on it.
        return false
        
    end
        
    // Try to move the controller downward a small amount to determine if
    // we're on the ground.
    local offset = Vector(0, -distanceToGround, 0)
    local trace = self.controller:Trace(offset, CollisionRep.Move, CollisionRep.Move, self:GetMovePhysicsMask())

    local result = false
    
    if trace.fraction < 1 then
    
        // Trace ray down to get normal of ground
        local rayTrace = Shared.TraceRay(self:GetOrigin() + Vector(0, 0.1, 0),
                                         self:GetOrigin() - Vector(0, 1, 0),
                                         CollisionRep.Move, EntityFilterOne(self))

        if rayTrace.fraction == 1 or math.abs(rayTrace.normal.y) >= kMaxWalkableNormal then
            result = true
        end
        
    end

    return result
    
end


function Player:GetPlayFootsteps()
    return self:GetVelocityLength() > kFootstepsThreshold and self:GetIsOnGround() and self:GetIsAlive()    
end

function Player:GetMovementModifierState()
    return self.movementModiferState
end

// Called by client/server UpdateMisc()
function Player:UpdateSharedMisc(input)

    // Update the view offet with the smoothed value.
    self:SetViewOffsetHeight(self:GetSmoothedViewOffset().y)
    
    self:UpdateMode()
    
end

// Subclasses can override this.
// In particular, the Skulk must override this since its view angles do NOT correspond to its head angles.
function Player:GetHeadAngles()
    return self:GetViewAngles()
end

function Player:OnUpdatePoseParameters()
    
    if not Shared.GetIsRunningPrediction() then
        
        local viewModel = self:GetViewModelEntity()
        if viewModel ~= nil then
        
            local activeWeapon = self:GetActiveWeapon()
            if activeWeapon and activeWeapon.UpdateViewModelPoseParameters then
                activeWeapon:UpdateViewModelPoseParameters(viewModel, input)
            end
            
        end

        SetPlayerPoseParameters(self, viewModel, self:GetHeadAngles())
        
    end

end

// By default the movement speed will not factor in the vertical velocity.
function Player:GetMoveSpeedIs2D()
    return true
end

function Player:UpdateMode()

    if(self.mode ~= kPlayerMode.Default and self.modeTime ~= -1 and Shared.GetTime() > self.modeTime) then
    
        if(not self:ProcessEndMode()) then
        
            self.mode = kPlayerMode.Default
            self.modeTime = -1
            
        end

    end
    
end

function Player:ProcessEndMode()

    if(self.mode == kPlayerMode.Knockback) then
        
        // No anim yet, set modetime manually
        self.modeTime = 1.25
        return true
        
    end
    
    return false
end

// for marquee selection
function Player:GetIsMoveable()
    return true
end

// Maximum speed a player can move backwards
function Player:GetMaxBackwardSpeedScalar()
    return kWalkBackwardSpeedScalar
end

function Player:GetAirMoveScalar()
    return 0.7
end

function Player:GetIsJumping()
    return self.jumping
end

function Player:GetIsIdle()
    return self:GetVelocity():GetLengthXZ() < 0.1 and not self.moveButtonPressed
end

local function CheckSpaceAboveForJump(self)

    local startPoint = self:GetOrigin() + Vector(0, self:GetExtents().y, 0)
    local endPoint = startPoint + Vector(0, 0.5, 0)
    local trace = Shared.TraceCapsule(startPoint, endPoint, 0.1, self:GetExtents().y, CollisionRep.Move, PhysicsMask.Movement, EntityFilterOne(self))
    
    return trace.fraction == 1
    
end

function Player:GetCanJump()
    return self:GetIsOnGround() and CheckSpaceAboveForJump(self)
end

function Player:GetJumpHeight()
    return kJumpHeight
end

function Player:GetJumpVelocity(input, velocity)
    velocity.y = math.sqrt(math.abs(2 * self:GetJumpHeight() * self:GetGravityForce(input)))
end

function Player:GetPlayJumpSound()
    return true
end

function Player:PreventMegaBunnyJumping(velocity)
    local maxscaledspeed = kBunnyJumpMaxSpeedFactor * self:GoldSrc_GetMaxSpeed()
    
    if maxscaledspeed > 0.0 then
       local spd = velocity:GetLength()
        
        if spd > maxscaledspeed then
            local fraction = (maxscaledspeed / spd)
            velocity:Scale(fraction)
        end
    end
end

// If we jump, make sure to set self.timeOfLastJump to the current time
function Player:HandleJump(input, velocity)

    local success = false
    
    if self:GetCanJump() then
    
        self:PreventMegaBunnyJumping(velocity)
    
        // Compute the initial velocity to give us the desired jump
        // height under the force of gravity.
        self:GetJumpVelocity(input, velocity)
        
        if self:GetPlayJumpSound() then
        
            if not Shared.GetIsRunningPrediction() then
                self:TriggerEffects("jump", {surface = self:GetMaterialBelowPlayer()})
            end
            
        end

        // TODO: Set this somehow (set on sounds for entity, not by sound name?)
        //self:SetSoundParameter(soundName, "speed", self:GetFootstepSpeedScalar(), 1)
        
        self.timeOfLastJump = Shared.GetTime()
        
        // Velocity may not have been set yet, so force onGround to false this frame
        self.onGroundNeedsUpdate = false
        self.onGround = false
        
        self.jumping = true
        success = true
        
    end
    
    return success
    
end

// 0-1 scalar which goes away over time (takes 1 seconds to get expire of a scalar of 1)
// Never more than 1 second of recovery time
// Also reduce velocity by this amount
function Player:AddSlowScalar(scalar)

    self.slowAmount = Clamp(self.slowAmount + scalar, 0, 1)
    
    self:SetVelocity(self:GetVelocity() * (1 - (scalar * (1 - kMinSlowSpeedScalar))))
    
end

function Player:GetMaterialBelowPlayer()

    local fixedOrigin = Vector(self:GetOrigin())
    
    // Start the trace a bit above the very bottom of the origin because
    // of cases where a large velocity has pushed the origin below the
    // surface the player is on
    fixedOrigin.y = fixedOrigin.y + self:GetExtents().y / 2
    local trace = Shared.TraceRay(fixedOrigin, fixedOrigin + Vector(0, -(2.5*self:GetExtents().y + .1), 0), CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOne(self))
    
    local material = trace.surface
    // Default to metal if no surface material is found.
    if not material or string.len(material) == 0 then
        material = "metal"
    end
    
    return material
end

function Player:GetFootstepSpeedScalar()
    return Clamp(self:GetVelocity():GetLength() / kRunMaxSpeed, 0, 1)
end

function Player:HandleAttacks(input)

    PROFILE("Player:HandleAttacks")

    if not self:GetCanAttack() then
        return
    end
    
    self:WeaponUpdate()
    
    
    if (bit.band(input.commands, Move.PrimaryAttack) ~= 0) then
    
        self:PrimaryAttack()
        
    else
    
        if self.primaryAttackLastFrame then
        
            self:PrimaryAttackEnd()
            
        end
        
    end

    if (bit.band(input.commands, Move.SecondaryAttack) ~= 0) then
    
        self:SecondaryAttack()
        
    else
    
        if(self.secondaryAttackLastFrame ~= nil and self.secondaryAttackLastFrame) then
        
            self:SecondaryAttackEnd()
            
        end
        
    end

    // Remember if we attacked so we don't call AttackEnd() until mouse button is released
    self.primaryAttackLastFrame = (bit.band(input.commands, Move.PrimaryAttack) ~= 0)
    self.secondaryAttackLastFrame = (bit.band(input.commands, Move.SecondaryAttack) ~= 0)
    
    // Have idle sound respond
    if Client and (self.primaryAttackLastFrame or self.secondaryAttackLastFrame) then
        self:SetIdleSoundInactive()
    end
    
end

function Player:HandleDoubleTap(input)

    PROFILE("Player:HandleDoubleTap")
    
    // check which button has been released and store that one
    if not self.previousMove then
        self.previousMove = Vector(input.move)
        self.lastButtonReleased = TAP_NONE
        self.timeLastButtonReleased = 0
        return
    end  
    
    local buttonReleased = TAP_NONE

    if input.move.x == 0 then
        if self.previousMove.x > 0 then
            buttonReleased = TAP_LEFT
        elseif self.previousMove.x < 0 then
            buttonReleased = TAP_RIGHT
        end
    end

    if input.move.z == 0 then
        if self.previousMove.z < 0 then
            buttonReleased = TAP_BACKWARD
        elseif self.previousMove.z > 0 then
            buttonReleased = TAP_FORWARD
        end
    end
    
    /*
    if buttonReleased ~= TAP_NONE then
        Print("button released %s", ToString(tapString[buttonReleased]))
    end
    */

    if buttonReleased ~= TAP_NONE then
    
        if self.timeLastButtonReleased ~= 0 and self.timeLastButtonReleased + kTapInterval > Shared.GetTime() then
        
            if self.lastButtonReleased == buttonReleased then
            
                self.timeLastButtonReleased = 0
                self.lastButtonReleased = TAP_NONE
                self:OnDoubleTap(GetTabDirectionVector(buttonReleased) )
            
            else
            
                self.lastButtonReleased = buttonReleased
                self.timeLastButtonReleased = Shared.GetTime()
                
            end
        
        else
            self.lastButtonReleased = buttonReleased
            self.timeLastButtonReleased = Shared.GetTime()
        end
    
    end    
    
    self.previousMove = Vector(input.move)
    
end

// Pass view model direction
function Player:OnDoubleTap(direction)
end

function Player:MovementModifierChanged(state, input)
end

function Player:GetPrimaryAttackLastFrame()
    return self.primaryAttackLastFrame
end

function Player:GetSecondaryAttackLastFrame()
    return self.secondaryAttackLastFrame
end

function Player:GetJumpMode()
    return kJumpMode.Repeating
end

// Children can add or remove velocity according to special abilities, modes, etc.
function Player:ModifyVelocity(input, velocity)   
    PROFILE("Player:ModifyVelocity")
    
    if bit.band(input.commands, Move.Jump) ~= 0 and not self.jumpHandled then
        
        local jumped = self:HandleJump(input, velocity)
        if jumped and self.OnJump then
            self:OnJump()
        end
        
        if self:GetJumpMode() == kJumpMode.Repeating then
            self.jumpHandled = false
        elseif self:GetJumpMode() == kJumpMode.Queued then
            self.jumpHandled = jumped
        else
            self.jumpHandled = true
        end

    elseif self:GetIsOnGround() then
        self:HandleOnGround(input, velocity)
    end
end

function Player:GetSpeedDebugSpecial()
    return 0
end

function Player:HandleOnGround(input, velocity)
    if Sign(velocity.y) == -1 then
        velocity.y = 0
    end
    
end

function Player:GetIsAbleToUse()
    return true
end

function Player:HandleButtons(input)

    PROFILE("Player:HandleButtons")
    
    if not self:GetCanControl() then
    
        // The following inputs are disabled when the player cannot control themself.
        input.commands = bit.band(input.commands, bit.bnot(bit.bor(Move.Use, Move.Buy, Move.Jump,
                                                                   Move.PrimaryAttack, Move.SecondaryAttack,
                                                                   Move.NextWeapon, Move.PrevWeapon, Move.Reload, Move.QuickSwitch,
                                                                   Move.Taunt, Move.Weapon1, Move.Weapon2,
                                                                   Move.Weapon3, Move.Weapon4, Move.Weapon5, Move.Crouch)))
                                                                   
        input.move.x = 0
        input.move.y = 0
        input.move.z = 0
                                                                   
        return
        
    end
    
    if self.HandleButtonsMixin then
        self:HandleButtonsMixin(input)
    end
    
    self.moveButtonPressed = input.move:GetLength() ~= 0
    
    // Update movement ability
    local newMovementState = bit.band(input.commands, Move.MovementModifier) ~= 0
    if newMovementState ~= self:GetMovementModifierState() then
        self:MovementModifierChanged(newMovementState, input)
    end
    
    local lastcrouch = false
    if self.latestinput ~= nil then
        lastcrouch = bit.band(self.latestinput.commands, Move.Crouch) ~= 0
    end
    
    self.movementModiferState = newMovementState
    self.latestinput = input
    
    local ableToUse = self:GetIsAbleToUse()
    if ableToUse and bit.band(input.commands, Move.Use) ~= 0 and not self.primaryAttackLastFrame and not self.secondaryAttackLastFrame then
        AttemptToUse(self, input.time)
    end
    
    if Client and not Shared.GetIsRunningPrediction() then
    
        self.buyLastFrame = self.buyLastFrame or false
        // Player is bringing up the buy menu (don't toggle it too quickly)
        local buyButtonPressed = bit.band(input.commands, Move.Buy) ~= 0
        if not self.buyLastFrame and buyButtonPressed and Shared.GetTime() > (self.timeLastMenu + 0.3) then
        
            self:Buy()
            self.timeLastMenu = Shared.GetTime()
            
        end
        
        self.buyLastFrame = buyButtonPressed
        
    end
    
    // Remember when jump released
    if bit.band(input.commands, Move.Jump) == 0 then
        self.jumpHandled = false
    end
    
    self:HandleAttacks(input)
    
    // self:HandleDoubleTap(input)

    if bit.band(input.commands, Move.Reload) ~= 0 then
        self:Reload()
    end
    
    // Weapon switch
    if not self:GetIsCommander() and not self:GetIsUsing() then
    
        if bit.band(input.commands, Move.NextWeapon) ~= 0 then
            self:SelectNextWeapon()
        end
        
        if bit.band(input.commands, Move.PrevWeapon) ~= 0 then
            self:SelectPrevWeapon()
        end
    
        if bit.band(input.commands, Move.Weapon1) ~= 0 then
            self:SwitchWeapon(1)
        end
        
        if bit.band(input.commands, Move.Weapon2) ~= 0 then
            self:SwitchWeapon(2)
        end
        
        if bit.band(input.commands, Move.Weapon3) ~= 0 then
            self:SwitchWeapon(3)
        end
        
        if bit.band(input.commands, Move.Weapon4) ~= 0 then
            self:SwitchWeapon(4)
        end
        
        if bit.band(input.commands, Move.Weapon5) ~= 0 then
            self:SwitchWeapon(5)
        end
        
        if bit.band(input.commands, Move.QuickSwitch) ~= 0 then
            self:QuickSwitchWeapon()
        end
        
    end
    
    self:SetCrouchState(bit.band(input.commands, Move.Crouch) ~= 0, lastcrouch)
    
end

function Player:GetCanCrouch()
    return true
end

function Player:GoldSrc_FinishDuck()
    self.crouched = true
    self.crouching = false
    if not self:GetIsOnGround() then
        // Player is crouching while in the air, move legs up instead of moving upper body down
        local org = self:GetOrigin()
        org.y = org.y + self:GetCrouchShrinkAmount() * 0.5
        self:SetOrigin(org)
        if self:GetIsColliding() then
            org.y = org.y - self:GetCrouchShrinkAmount() * 0.5
            self:SetOrigin(org)
        end
    end
    self:UpdateControllerFromEntity()
    self.crouchfraction = 1.0
end

function Player:GoldSrc_Duck(crouching, lastcrouching)
    local duckpressed = crouching and not lastcrouching
    local duckreleased = not crouching and lastcrouching

    // crouching = player holding down crouch
    // self.crouching = in process of crouching (up or down)
    // self.crouched = player is fully crouched
    if not self:GetCanCrouch() then
        // Keep button-state for skulk as un-sticky button
        // todo: change to use self.latestinput?
        self.crouching = crouching
        return
    end
    
    // Holding duck, in process of ducking or fully ducked?
    if crouching or self.crouching or self.crouched then
        // holding duck
        if crouching then
            // Just pressed duck, and not fully ducked?
            if duckpressed and not self.crouched then
                self.timeOfCrouchChange = 1.0
                self.crouching = true
            end
            
            // doing a duck movement? (ie. not fully ducked?)
            if self.crouching then
                // Finish ducking immediately if duck time is over or not on ground
                local time = 1.0 - self.timeOfCrouchChange
                if time > kCrouchAnimationTime or not self:GetIsOnGround() or self.crouched then
                    self:GoldSrc_FinishDuck()
                else
                    // Set view
                    self.crouchfraction = self:SplineFraction(time/kCrouchAnimationTime, 1.0)
                end
            end
        else
            if duckreleased and self.crouched then
                // start a unduck
                self.timeOfCrouchChange = 1.0
                self.crouching = true
            end
            
            if self:GoldSrc_CanUnduck() then
                if self.crouched or self.crouching then
                    // Finish ducking immediately if duck time is over or not on ground
                    local time = 1.0 - self.timeOfCrouchChange
                    local animationtime = (kCrouchAnimationTime * 0.5)
                    if time > animationtime or not self:GetIsOnGround() then
                        self:GoldSrc_FinishUnduck()
                    else
                        // set view
                        self.crouchfraction = self:SplineFraction(1.0 - (time/animationtime), 1.0)
                    end
                end
            else
                // Still under something where we can't unduck, so make sure we reset this timer so
                //  that we'll unduck once we exit the tunnel, etc.
                self.timeOfCrouchChange = 1.0
            end
        end
    end
end

function Player:GoldSrc_CanUnduck()
    if not self.crouched then
        if self.crouching then
            // In a partial duck, allow unducking without checking bbox, as the
            // bounding box is only shrinked when self.crouched is true
            return true
        end
        // Not ducked and not in a partial duck
        return false
    end
    
    local oldOrg = Vector(self:GetOrigin())
    local org = self:GetOrigin()
    
    if not self:GetIsOnGround() then
        // See if we can put down our feet
        org.y = org.y -  self:GetCrouchShrinkAmount() * 0.5
        self:SetOrigin(org)
    end
    
    self.crouched = false
    local blocked = self:GetIsColliding()
    
    // Revert changes
    self.crouched = true
    self:SetOrigin(oldOrg)
    self:UpdateControllerFromEntity()
    
    return not blocked
end

function Player:GoldSrc_FinishUnduck()
    local org = self:GetOrigin()
    
    if not self:GetIsOnGround() then
        // See if we can put down our feet
        org.y = org.y -  self:GetCrouchShrinkAmount() * 0.5
        self:SetOrigin(org)
    end
    
    self.crouched = false
    self.crouching = false
    self:UpdateControllerFromEntity()
    self.timeOfCrouchChange = 0.0
    self.crouchfraction = 0.0
    self.onGroundNeedsUpdate = true
end

function Player:SetCrouchState(crouching, lastcrouching)

    PROFILE("Player:SetCrouchState")
    
    self:GoldSrc_Duck(crouching, lastcrouching)
    /*
    if crouching == self.crouching then
        return
    end
   
    if not crouching then
        
        // Check if there is room for us to stand up.
        self.crouching = crouching
        self:UpdateControllerFromEntity()
        
        if self:GetIsColliding() then
            self.crouching = true
            self:UpdateControllerFromEntity()
        else
            self.timeOfCrouchChange = Shared.GetTime()
        end
        
    elseif self:GetCanCrouch() then
    
        if not self:GetIsOnGround() then
            // Player is crouching while in the air, move legs up instead of moving upper body down
            local org = self:GetOrigin()
            org.y = org.y + self:GetCrouchShrinkAmount()
            self:SetOrigin(org)
        end
        
    
        self.crouching = crouching
        self.timeOfCrouchChange = Shared.GetTime()
        self:UpdateControllerFromEntity()
    end
    */
end

function Player:GetNotEnoughResourcesSound()
    return Player.kNotEnoughResourcesSound    
end

function Player:GetIsCommander()
    return false
end

function Player:GetIsOverhead()
    return false
end

/**
 * Returns the view model entity.
 */
function Player:GetViewModelEntity()

    local result = nil
    
    // viewModelId is a private field
    if not Client or self:GetIsLocalPlayer() then  
    
        result = Shared.GetEntity(self.viewModelId)
        ASSERT(not result or result:isa("ViewModel"), "%s: viewmodel is a %s!", self, result);
        
    end
    
    return result
    
end

/**
 * Sets the model currently displayed on the view model.
 */
function Player:SetViewModel(viewModelName, weapon)

    local viewModel = self:GetViewModelEntity()
    
    // Currently there is an edge case where this function is called when
    // there is no view model entity. This will help us figure out why.
    if not viewModel then
        return
    end
    
    local animationGraphFileName = nil
    if weapon then
        animationGraphFileName = weapon:GetAnimationGraphName()
    end
    viewModel:SetModel(viewModelName, animationGraphFileName)
    viewModel:SetWeapon(weapon)
    
end

function Player:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false
end

function Player:GetScoreboardChanged()
    return self.scoreboardChanged
end

// Set to true when score, name, kills, team, etc. changes so it's propagated to players
function Player:SetScoreboardChanged(state)
    self.scoreboardChanged = state
end

function Player:SpaceClearForEntity(position, printResults)

    local capsuleHeight, capsuleRadius = self:GetTraceCapsule()
    local center = Vector(0, capsuleHeight * 0.5 + capsuleRadius, 0)
    
    local traceStart = position + center
    local traceEnd = traceStart + Vector(0, .1, 0)

    if capsuleRadius == 0 and printResults then    
        Print("%s:SpaceClearForEntity(): capsule radius is 0, returning true.", self:GetClassName())
        return true
    elseif capsuleRadius < 0 and printResults then
        Print("%s:SpaceClearForEntity(): capsule radius is %.2f.", self:GetClassName(), capsuleRadius)
    end
    
    local trace = Shared.TraceCapsule(traceStart, traceEnd, capsuleRadius, capsuleHeight, CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOne(self))
    
    if trace.fraction ~= 1 and printResults then
        Print("%s:SpaceClearForEntity: Hit %s", self:GetClassName(), SafeClassName(trace.entity))
    end
    
    return (trace.fraction == 1)
    
end

function Player:GetChatSound()
    return kChatSound
end

function Player:GetHotkeyGroups()

    local hotKeyGroups = {}

    for _, entity in ipairs(GetEntitiesWithMixinForTeam("Selectable", self:GetTeamNumber())) do
    
        local group = entity:GetHotGroupNumber()
        if group ~= 0 then
        
            if not hotKeyGroups[group] then
                hotKeyGroups[group] = {}
            end
            
            table.insert(hotKeyGroups[group], entity)
        
        end
    
    end

    return hotKeyGroups
    
end

function Player:GetVisibleWaypoint()

    local currentOrder = self:GetCurrentOrder()
    if currentOrder then
    
        local location = currentOrder:GetLocation()
    
            if currentOrder:GetType() == kTechId.Weld or currentOrder:GetType() == kTechId.Heal then
                
                local orderTargetId = currentOrder:GetParam()
                if orderTargetId ~= Entity.invalidId then
                    local orderTarget = Shared.GetEntity(orderTargetId)
                    if orderTarget then
                        location =  orderTarget:GetOrigin()
                    end
                end
                
            end
    
        return location
    end
    
    return nil
    
end

// Overwrite to get player status description
function Player:GetPlayerStatusDesc()
    if (self:GetIsAlive() == false) then
        return kPlayerStatus.Dead
    end
    return kPlayerStatus.Void
end

function Player:GetCanGiveDamageOverride()
    return true
end

// Overwrite how players interact with doors
function Player:OnOverrideDoorInteraction(inEntity)
    return true, 6
end

function Player:SetIsUsing (isUsing)
    self.isUsing = isUsing
end

function Player:GetIsUsing ()
    return self.isUsing
end

function Player:GetDarwinMode()
    return self.darwinMode
end

function Player:OnSighted(sighted)

    if self.GetActiveWeapon then
    
        local weapon = self:GetActiveWeapon()
        if weapon ~= nil then
            weapon:SetRelevancy(sighted)
        end
        
    end
    
end

function Player:GetGameStarted()
    return self.gameStarted
end

function Player:Drop(weapon, ignoreDropTimeLimit)
    return false
end

// childs should override this
function Player:GetArmorAmount()
    return self:GetMaxArmor()
end

if Client then

    function Player:TriggerFootstep()
    
        self.leftFoot = not self.leftFoot
		//local sprinting = not self.movementModiferState
        local viewVec = self:GetViewAngles():GetCoords().zAxis
        local forward = self:GetVelocity():DotProduct(viewVec) > -0.1
        local crouch = self:GetCrouched()
        local localPlayer = Client.GetLocalPlayer()
        local enemy = localPlayer and GetAreEnemies(self, localPlayer)
        self:TriggerEffects("footstep", {surface = self:GetMaterialBelowPlayer(), left = self.leftFoot, sprinting = true, forward = forward, crouch = crouch, enemy = enemy})
        
    end
    
end

local kStepTagNames = { }
kStepTagNames["step"] = true
kStepTagNames["step_run"] = true
kStepTagNames["step_sprint"] = true
kStepTagNames["step_crouch"] = true
function Player:OnTag(tagName)

    PROFILE("Player:OnTag")
    
    // Filter out crouch steps from playing at inappropriate times.
    if tagName == "step_crouch" and not self:GetCrouched() then
        return
    end
    
    // Play footstep when foot hits the ground. Client side only.
    if Client and self:GetPlayFootsteps() and not Shared.GetIsRunningPrediction() and kStepTagNames[tagName] then
        self:TriggerFootstep()
    end
    
end

function Player:OnUpdateAnimationInput(modelMixin)

    PROFILE("Player:OnUpdateAnimationInput")
    
    local moveState = "run"
    if self:GetIsJumping() then
        moveState = "jump"
    elseif self:GetIsIdle() then
        moveState = "idle"
    end
    modelMixin:SetAnimationInput("move", moveState)
    
    local activeWeapon = "none"
    local weapon = self:GetActiveWeapon()
    if weapon ~= nil then
    
        if weapon.OverrideWeaponName then
            activeWeapon = weapon:OverrideWeaponName()
        else
            activeWeapon = weapon:GetMapName()
        end
        
    end
    
    modelMixin:SetAnimationInput("weapon", activeWeapon)
    
    local weapon = self:GetActiveWeapon()
    if weapon ~= nil and weapon.OnUpdateAnimationInput then
        weapon:OnUpdateAnimationInput(modelMixin)
    end
    
end

function Player:GetSpeedScalar()
    return self:GetVelocityLength() / self:GoldSrc_GetMaxSpeed()
end

function Player:OnUpdateCamera(deltaTime)

    // Update view offset from crouching
    local offset = -self:GetCrouchShrinkAmount() * self:GetCrouchAmount()
    self:SetCameraYOffset(offset)
    
end

function Player:BlockMove()
    self.isMoveBlocked = true
end

function Player:RetrieveMove()
    self.isMoveBlocked = false
end

function Player:GetCanControl()
    return (not self.isMoveBlocked) and self:GetIsAlive() and not self.countingDown
end

function Player:GetCanAttack()
    return not self:GetIsUsing()
end

function Player:TriggerInvalidSound()

    if not self.timeLastInvalidSound or self.timeLastInvalidSound + 1 < Shared.GetTime() then
        StartSoundEffectForPlayer(kInvalidSound, self)  
        self.timeLastInvalidSound = Shared.GetTime()
    end
    
end

function Player:SetEthereal(ethereal)
end

function Player:GetIsWallWalkingAllowed(entity)
    return false
end

function Player:GetEngagementPointOverride()
    return self:GetModelOrigin()
end

function Player:OnInitialSpawn(techPointOrigin)
    
    local viewCoords = Coords.GetLookIn(self:GetEyePos(), GetNormalizedVectorXZ(techPointOrigin - self:GetEyePos()))
    local angles = Angles()
    angles:BuildFromCoords(viewCoords)
    self:SetViewAngles(angles)

    angles.pitch = 0.0
    self:SetAngles(angles)
    
end

// This causes problems when doing a trace ray against CollisionRep.Move.
function Player:OnCreateCollisionModel()
    
    // Remove any "move" collision representation from the player's model, since
    // all of the movement collision will be handled by the controller.
    local collisionModel = self:GetCollisionModel()
    collisionModel:RemoveCollisionRep(CollisionRep.Move)
    
end

function Player:OnAdjustModelCoords(modelCoords)
    
    local deltaTime = Shared.GetTime() - self.stepStartTime
    if deltaTime < kStepTotalTime then
        modelCoords.origin = modelCoords.origin - self.stepAmount * (1 - deltaTime / kStepTotalTime) * self:GetCoords().yAxis
    end
      
    return modelCoords
    
end

function Player:GetWeaponUpgradeLevel()

    if not self.weaponUpgradeLevel then
        return 0
    end

    return self.weaponUpgradeLevel    

end

function Player:GetIsRookie()
    return self.isRookie
end

function Player:GetCommunicationStatus()
    return self.communicationStatus
end

function Player:SetCommunicationStatus(status)
    self.communicationStatus = status
end

if Server then

    function Player:SetWaitingForTeamBalance(waiting)
    
        self.waitingForAutoTeamBalance = waiting
        // Send a message as a FP spectating player will need to be notified.
        Server.SendNetworkMessage(Server.GetOwner(self), "WaitingForAutoTeamBalance", { waiting = waiting }, true)
        
    end
    
    function Player:GetIsWaitingForTeamBalance()
        return self.waitingForAutoTeamBalance
    end
    
end

function Player:GetPositionForMinimap()

    local tunnels = GetEntitiesWithinRange("Tunnel", self:GetOrigin(), 30)
    local isInTunnel = #tunnels > 0
    
    if isInTunnel then
        return tunnels[1]:GetRelativePosition(self:GetOrigin())        
    else
        return self:GetOrigin()
    end

end

function Player:GetDirectionForMinimap()

    local zAxis = self:GetViewAngles():GetCoords().zAxis
    local direction = math.atan2(zAxis.x, zAxis.z)
    
    local tunnels = GetEntitiesWithinRange("Tunnel", self:GetOrigin(), 30)
    local isInTunnel = #tunnels > 0
    
    if isInTunnel then
        direction = direction + tunnels[1]:GetMinimapYawOffset()
    end
    
    return direction

end

Shared.LinkClassToMap("Player", Player.kMapName, networkVars, true)
