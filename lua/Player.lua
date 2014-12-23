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

//NS2c
//Major changes here to support GLDSource Movement Code

Script.Load("lua/Globals.lua")
Script.Load("lua/TechData.lua")
Script.Load("lua/Utility.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/PhysicsGroups.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/CoreMoveMixin.lua")
Script.Load("lua/WeaponOwnerMixin.lua")
Script.Load("lua/DoorMixin.lua")
Script.Load("lua/Mixins/ControllerMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/UpgradableMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/MobileTargetMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/AFKMixin.lua")
Script.Load("lua/SmoothedRelevancyMixin.lua")

if Client then
    Script.Load("lua/HelpMixin.lua")
end

--@Abstract
class 'Player' (ScriptActor)

Player.kMapName = "player"

if Server then
    Script.Load("lua/Player_Server.lua")
elseif Predict then
    Script.Load("lua/Player_Predict.lua")
elseif Client then
    Script.Load("lua/Player_Client.lua")
    Script.Load("lua/Chat.lua")
end

// min/max distance for physics culling
Player.kPhysicsCullMin = 3
Player.kPhysicsCullMax = 50
Player.kNotEnoughResourcesSound     = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/more")
//Player.kGravity = -17.7
Player.kGravity = -17.7
Player.kXZExtents = 0.35
Player.kYExtents = 0.9
Player.kWalkMaxSpeed = 4
Player.kPushDuration = 0.5
Player.kOnGroundDistance = 0.1

// Private
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
local kInvalidSound = PrecacheAsset("sound/NS2.fev/common/invalid")
local kChatSound = PrecacheAsset("sound/NS2.fev/common/chat")
local kDownwardUseRange = 2.2
local kUseBoxSize = Vector(0.5, 0.5, 0.5)
local kStowedWeaponWeightScalar = 1
local kThinkInterval = .2

//Movement Code Vars
//NS1
//Should all of these be impacted by units change?  I would think so, but quite clearly not...
//Gravity - 800 - 15.1
//Stopspeed - 100 - 1.8
//Friction - 4 - 0.07
//Accel - 10 - 0.2
//Air Accel - 10 - 0.2

local kGoldSrcAcceleration = 10
local kGoldSrcAirAcceleration = 50
local kGroundFriction = 5
local kClimbFriction = 6
local kCrouchMaxSpeed = 2.2
local kCrouchTime = 0.4
local kAirGroundTransistionTime = 0.2
local kWalkMaxSpeed = 3.5
local kRunMaxSpeed = 6
local kBackwardsMovementScalar = 1
//local kJumpForce = 6.6
// use 8.42 for gravity -23
local kJumpForce = 6.6
local kMaxPlayerSlow = 0.8

//Other Vars
local kMass = 90.7 // ~200 pounds (incl. armor, weapons)
local kStepTotalTime    = 0.1  // Total amount of time to interpolate up a step
local kViewOffsetHeight = Player.kYExtents * 2 - 0.2
local kMaxStepAmount = 1.5
local kCrouchShrinkAmount = 0.6
local kExtentsCrouchShrinkAmount = 0.4
local kMinSlowSpeedScalar = .2
local kBodyYawTurnThreshold = Math.Radians(5)
local kTurnRunDelaySpeed = 5
// Controls how fast the body_yaw pose parameter used for turning while standing
// still blends back to default when the player starts moving.
local kTurnMoveYawBlendToMovingSpeed = 8
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

--[[ When changing these, make sure to update Player:CopyPlayerDataFrom. Any data which
    needs to survive between player class changes needs to go in here.
    Compensated variables are things that you want reverted when processing commands
    so basically things that are important for defining whether or not something can be shot
    for the player this is anything that can affect the hit boxes, like the animation that's playing,
    the current animation time, pose parameters, etc (not for the player firing but for the
    player being shot).
 ]]
local networkVars =
{
    fullPrecisionOrigin = "private vector", 
    
    clientIndex = "entityid",
    
    gamemode = "enum kGameMode",
    
    viewModelId = "private entityid",
    
    resources = "private float (0 to " .. kMaxResources .. " by 0.1)",
    teamResources = "private float (0 to " .. kMaxTeamResources .. " by 1)",
    gameStarted = "private boolean",
    countingDown = "private boolean",
    frozen = "private boolean",
    
    timeOfLastUse = "private time",
    
    --bodyYaw must be compenstated as it feeds into the animation as a pose parameter
    bodyYaw = "compensated interpolated float (-3.14159265 to 3.14159265 by 0.003)",
    standingBodyYaw = "interpolated float (0 to 6.2831853 by 0.003)",
    
    bodyYawRun = "compensated interpolated float (-3.14159265 to 3.14159265 by 0.003)",
    runningBodyYaw = "interpolated float (0 to 6.2831853 by 0.003)",
    timeLastMenu = "private time",
    darwinMode = "private boolean",
    
    moveButtonPressed = "compensated boolean",
    
    primaryAttackLastFrame = "boolean",
    secondaryAttackLastFrame = "boolean",
    
    -- Used to smooth out the eye movement when going up steps.
    stepStartTime = "compensated time",
    stepAmount = "compensated float(-2.1 to 2.1 by 0.001)", -- limits must be just slightly bigger than kMaxStepAmount
    
    isUsing = "boolean",
    
    -- Reduce max player velocity in some cases (marine jumping)
    slowAmount = "float (0 to 1 by 0.01)",
    movementModiferState = "boolean",
    movementmode = "boolean",
    giveDamageTime = "private time",

    level = "float (0 to " .. kCombatMaxLevel .. " by 0.001)",
    pushImpulse = "private vector",
    pushTime = "private time",
    
    isMoveBlocked = "private boolean",
    
    communicationStatus = "enum kPlayerCommunicationStatus"
}

------------
-- MIXINS --
------------

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(CoreMoveMixin, networkVars)
AddMixinNetworkVars(ControllerMixin, networkVars)
AddMixinNetworkVars(WeaponOwnerMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(UpgradableMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

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
    InitMixin(self, CoreMoveMixin)
	InitMixin(self, GroundMoveMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, ControllerMixin)
    InitMixin(self, WeaponOwnerMixin, { kStowedWeaponWeightScalar = kStowedWeaponWeightScalar })
    InitMixin(self, DoorMixin)
    -- TODO: move LiveMixin to child classes (some day)
    InitMixin(self, LiveMixin)
    InitMixin(self, UpgradableMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, SmoothedRelevancyMixin)

    if Client then
        InitMixin(self, HelpMixin)
    end

    self:SetLagCompensated(true)
    
    self:SetUpdates(true)
    
    if Server then
    
        InitMixin(self, AFKMixin)
        
        self.name = ""
        self.giveDamageTime = 0
        self.sendTechTreeBase = false
        self.waitingForAutoTeamBalance = false
        self.gamemode = GetServerGameMode()
        
    end
    
    self.viewOffset = Vector(0, 0, 0)
    
    self.bodyYaw = 0
    self.standingBodyYaw = 0
    
    self.bodyYawRun = 0
    self.runningBodyYaw = 0
    
    self.clientIndex = -1
	//NS2c Additions
    self.movementmode = false
    self.movementModiferState = false
    
    self.timeLastMenu = 0
    self.darwinMode = false
    
    self.leftFoot = true
    self.primaryAttackLastFrame = false
    self.secondaryAttackLastFrame = false
    
    self.viewModelId = Entity.invalidId
    
    self.usingStructure = nil
    self.timeOfLastUse = 0
    
    self.timeOfDeath = nil
    
    self.resources = 0
    self.level = 1
    self.stepStartTime = 0
    self.stepAmount = 0
    
    self.isMoveBlocked = false
    self.isRookie = false
    
    self.moveButtonPressed = false

    -- Make the player kinematic so that bullets and other things collide with it.
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
        -- Only give weapons when playing.
        if self:GetTeamNumber() ~= kNeutralTeamType and not self.preventWeapons then
            self:InitWeapons()
        elseif self:GetTeamNumber() == kNeutralTeamType then
            self:InitWeaponsForReadyRoom()
        end
        
        self:SetName(kDefaultPlayerName)
        
        self:SetNextThink(kThinkInterval)
        
        InitMixin(self, MobileTargetMixin)
        
    end

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

function Player:GetIsSteamFriend()

    if self.isSteamFriend == nil and self.clientIndex > 0 then
    
        local steamId = GetSteamIdForClientIndex(self.clientIndex)
        if steamId then
            self.isSteamFriend = Client.GetIsSteamFriend(steamId)
        end
    
    end

    return self.isSteamFriend
end

--[[
    Called when the player entity is destroyed.
]]
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
        
        if self.guiCountDownDisplay then
        
            GetGUIManager():DestroyGUIScript(self.guiCountDownDisplay)
            self.guiCountDownDisplay = nil
            
        end
        
        if self.unitStatusDisplay then
        
            GetGUIManager():DestroyGUIScriptSingle("GUIUnitStatus")
            self.unitStatusDisplay = nil
            
        end
        
    elseif Server then
        self:RemoveSpectators(nil)
        
        if self.playerInfo then
        
            DestroyEntity(self.playerInfo)
            self.playerInfo = nil
            
        end
        
    end
    
end

function Player:OnEntityChange(oldEntityId, newEntityId)

    if Client then

        if self:GetId() == oldEntityId then
            -- If this player is changing is any way, just assume the
            -- buy/evolve menu needs to close.
            self:CloseMenu()
        end

        -- If this is a player changing classes that we're already following, update the id
        local player = Client.GetLocalPlayer()
        if player.followId == oldEntityId then
            Client.SendNetworkMessage("SpectatePlayer", {entityId = newEntityId}, true)
            player.followId = newEntityId
        end
        
    end

end

--[[
    Camera will zoom to third person and not attach to the ragdolls head when set to false.
    Child classes can overwrite this.
]]
function Player:GetAnimateDeathCamera()
    return true
end 

function Player:GetReceivesBiologicalDamage()
    return true
end

function Player:GetReceivesVaporousDamage()
    return true
end

function Player:GetGameMode()
    return self.gamemode
end

function Player:SetGameMode(newmode)
    self.gamemode = newmode
end

-- Special unique client-identifier 
function Player:GetClientIndex()
    return self.clientIndex
end

function Player:AddPushImpulse(vector)
    self.pushImpulse = Vector(vector)
    self.pushTime = Shared.GetTime()
end

function Player:GetPlayerLevel()
    return math.floor(self.level)
end

function Player:GetPlayerExperience()
    local levelprogress = self.level - math.floor(self.level)
    local lastlevelxp = CalculateLevelXP(math.floor(self.level))
    local nextlevelxp = CalculateLevelXP(math.floor(self.level) + 1)
    return lastlevelxp + math.floor((nextlevelxp - lastlevelxp) * levelprogress)
end

function Player:AddExperience(xp)
    if self.level >= kCombatMaxLevel then
        return
    end
    local oldlevel = math.floor(self.level)
    local xpbalance = self.level - oldlevel
    local lastlevelxp = CalculateLevelXP(oldlevel)
    local nextlevelxp = CalculateLevelXP(oldlevel + 1)
    local xptolevel = (1 - (self.level - oldlevel)) * (nextlevelxp - lastlevelxp)
    local xpaddition = xp / (nextlevelxp - lastlevelxp)
    local xpbalance = math.floor(xp - xptolevel)
    //Shared.Message(string.format("XP Added %s : Old Level %s : New Level %s : LastXPBreak %s : NextXPBreak %s : OldXPTowardsLevel %s : NewXPTowardsLevel %s : XPToLevel %s : XPBalance %s.", 
    //            xp, self.level, self.level + xpaddition, lastlevelxp, nextlevelxp, self.level - oldlevel, xpaddition, xptolevel, xpbalance))
    if xp >= xptolevel and self.level < kCombatMaxLevel then
        //Trigger levelup!
        self:Levelup()
    else
        self.level = math.min(self.level + xpaddition, kCombatMaxLevel)
    end
    if xpbalance > 0 and self.level < kCombatMaxLevel then
        self:AddExperience(xpbalance)
    end
end

function Player:ResetLevel()
    self.level = 1
end

function Player:Levelup()
    //Trigger effects, give player resources (points)
    self.level = math.min(math.floor(self.level) + 1, kCombatMaxLevel)
    self:AddResources(kCombatResourcesPerLevel)
    self:TriggerEffects("res_received")
end

function Player:OverrideInput(input)
    
    ClampInputPitch(input)
    
    if self.timeClosedMenu and (Shared.GetTime() < self.timeClosedMenu + .25) then
    
        -- Don't allow weapon firing
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

--[[
    Returns the view offset with the step smoothing factored in.
]]
function Player:GetSmoothedViewOffset()

    local deltaTime = Shared.GetTime() - self.stepStartTime
    
    if deltaTime < kStepTotalTime then
        return self.viewOffset + Vector( 0, -self.stepAmount * (1 - deltaTime / kStepTotalTime), 0 )
    end
    
    return self.viewOffset
    
end

--[[
    Stores the player's current view offset. Calculated from GetMaxViewOffset() and crouch state.
]]
function Player:SetViewOffsetHeight(newViewOffsetHeight)
    self.viewOffset.y = newViewOffsetHeight
end

function Player:GetMaxViewOffsetHeight()
    return kViewOffsetHeight
end

-- worldX => -map y
-- worldZ => +map x
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

-- Return modifier to our max speed (1 is none, 0 is full)
function Player:GetSlowSpeedModifier()
    return math.max(kMinSlowSpeedScalar, 1 - self.slowAmount)
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

--[[
    Will return true if the passed in entity can be used by self and
    the entity has no attach points to use.
]]
local function GetCanEntityBeUsedWithNoUsablePoint(self, entity)

    if HasMixin(entity, "Usable") then
    
        -- Ignore usable points if a Structure has not been built.
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
    
    -- To make building low objects like an infantry portal easier, increase the use range
    -- as we look downwards. This effectively makes use trace in a box shape when looking down.
    local useRange = kPlayerUseRange
    local sinAngle = viewCoords.zAxis:GetLengthXZ()
    if viewCoords.zAxis.y < 0 and sinAngle > 0 then
    
        useRange = kPlayerUseRange / sinAngle
        if -viewCoords.zAxis.y * useRange > kDownwardUseRange then
            useRange = kDownwardUseRange / -viewCoords.zAxis.y
        end
        
    end
    
    -- Get possible useable entities within useRange that have an attach point.
    local ents = GetEntitiesWithMixinWithinRange("Usable", self:GetOrigin(), useRange)
    for e = 1, #ents do
    
        local entity = ents[e]
        -- Filter away anything on the enemy team. Allow using entities not on any team.
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
    
    -- If failed, do a regular trace with entities that don't have usable points.
    local viewCoords = self:GetViewAngles():GetCoords()
    local endPoint = startPoint + viewCoords.zAxis * useRange
    local activeWeapon = self:GetActiveWeapon()
    
    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Default, PhysicsMask.AllButPCs, EntityFilterTwo(self, activeWeapon))  
    
    if trace.fraction < 1 and trace.entity ~= nil then
    
        -- Only return this entity if it can be used and it does not have a usable point (which should have been
        -- caught in the above cases).
        if GetCanEntityBeUsedWithNoUsablePoint(self, trace.entity) then
            return trace.entity, trace.endPoint
        end
        
    end
    
    -- Called in case the normal trace fails to allow some tolerance.
    -- Modify the endPoint to account for the size of the box.
    local maxUseLength = (kUseBoxSize - -kUseBoxSize):GetLength()
    endPoint = startPoint + viewCoords.zAxis * (useRange - maxUseLength / 2)
    local traceBox = Shared.TraceBox(kUseBoxSize, startPoint, endPoint, CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterTwo(self, activeWeapon))
    -- Only return this entity if it can be used and it does not have a usable point (which should have been caught in the above cases).
    if traceBox.fraction < 1 and traceBox.entity ~= nil and GetCanEntityBeUsedWithNoUsablePoint(self, traceBox.entity) then
    
        local direction = startPoint - traceBox.entity:GetOrigin()
        direction:Normalize()
        
        -- Must be generally facing the entity.
        if viewCoords.zAxis:DotProduct(direction) < -0.5 then
            return traceBox.entity, traceBox.endPoint
        end
        
    end
    
    return nil, Vector(0, 0, 0)
    
end

function Player:UseTarget(entity, timePassed)

    assert(entity)
    
    local useSuccessTable = { useSuccess = false } 
    if entity.OnUse then
    
        useSuccessTable.useSuccess = true
        entity:OnUse(self, timePassed, useSuccessTable)
        
    end
    
    self:OnUseTarget(entity)
    
    return useSuccessTable.useSuccess
    
end

--[[
    Check to see if there's a ScriptActor we can use. Checks any usable points returned from
    GetUsablePoints() and if that fails, does a regular trace ray. Returns true if we processed the action.
]]
local function AttemptToUse(self, timePassed)

    PROFILE("Player:AttemptToUse")
    
    assert(timePassed >= 0)
    
    if (Shared.GetTime() - self.timeOfLastUse) < kUseInterval then
        return false
    end
    
    -- Cannot use anything unless playing the game (a non-spectating player).
    if not self:GetIsOnPlayingTeam() then
        return false
    end
    
    -- Trace to find use entity.
    local entity, usablePoint = self:PerformUseTrace()
    
    -- Use it.
    if entity then
    
        -- if the game isn't started yet, check if the entity is usuable in non-started game
        -- (allows players to select commanders before the game has started)
        if not self:GetGameStarted() and not (entity.GetUseAllowedBeforeGameStart and entity:GetUseAllowedBeforeGameStart()) then
            return false
        end
        
        -- Use it.
        if self:UseTarget(entity, kUseInterval) then
        
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
    if self:GetCrouching() and self:GetCrouchAmount() == 1 then
        extents.y = extents.y * (1 - (self:GetExtentsCrouchShrinkAmount()))
    end
    return extents
    
end

--[[
    Returns true if the player is currently on a team and the game has started.
]]
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

function Player:GetCanDieOverride()
    return HasTeamAssigned(self)
end

function Player:GetIsStateFrozen()
	return HasMixin(self, "Devourable") and self:GetIsDevoured()
end

function Player:GetCanSuicide()
    return not self:GetIsStateFrozen()
end

-- Individual resources
function Player:GetResources()

    if Shared.GetCheatsEnabled() and Player.kAllFreeCheat then
        return 100
    else
        return Round(self.resources, 2)
    end

end

-- Returns player mass in kg
function Player:GetMass()
    return kMass
end

function Player:AddResources(amount)

    local resReward = math.min(amount, kMaxPersonalResources - self:GetResources())
    local oldRes = self.resources
    self:SetResources(self:GetResources() + resReward)
    
    return resReward
    
end

function Player:AddTeamResources(amount)
    self.teamResources = math.max(math.min(self.teamResources + amount, kMaxTeamResources), 0)
end

function Player:GetDisplayResources()
    return self:GetResources()    
end

function Player:GetPersonalResources()

    if Shared.GetCheatsEnabled() and Player.kAllFreeCheat then
        return 100
    else
        return self:GetResources()
    end
    
end

function Player:GetDisplayTeamResources()

    local displayTeamResources = self.teamResources
    if(Client and self.resourceDisplay) then
        displayTeamResources = self.animatedTeamResourcesDisplay:GetDisplayValue()
    end
    return displayTeamResources
    
end

-- Team resources
function Player:GetTeamResources()
    return self.teamResources
end

function Player:GetVerticleMove()
    return false
end

function Player:UpdateMovementMode(movementmode)
    self.movementmode = movementmode
end

function Player:ModifyVelocity(input, velocity, deltaTime)
end

function Player:HasAdvancedMovement()
    return self.movementmode
end

function Player:GetCanClimb()
    return true
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
    
    -- Pull out weapon again if we haven't built for a bit
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

-- Allow child classes to alter player's move at beginning of frame. Alter amount they
-- can move by scaling input.move, remove key presses, etc.
function Player:AdjustMove(input)

    PROFILE("Player:AdjustMove")
    
    -- Don't allow movement when frozen in place
    if self.frozen then
        input.move:Scale(0)
    end
    
    return input
    
end

function Player:GetAngleSmoothingMode()
    return "euler"
end

function Player:GetDesiredAngles(deltaTime)

    local desiredAngles = Angles()
    desiredAngles.pitch = 0
    desiredAngles.roll = self.viewRoll
    desiredAngles.yaw = self.viewYaw
    
    return desiredAngles

end

function Player:GetAngleSmoothRate()
    return 10
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

-- also predict smoothing on the local client, since no interpolation is happening here and some effects can depent on current players angle (like exo HUD)
function Player:AdjustAngles(deltaTime)

    local angles = self:GetAngles()
    local desiredAngles = self:GetDesiredAngles(deltaTime)
    local smoothMode = self:GetAngleSmoothingMode()
    
    if desiredAngles == nil then

        -- Just keep the old angles

    elseif smoothMode == "euler" then

        
        angles.yaw = SlerpRadians(angles.yaw, desiredAngles.yaw, self:GetAngleSmoothRate() * deltaTime )
        angles.roll = SlerpRadians(angles.roll, desiredAngles.roll, self:GetRollSmoothRate() * deltaTime )
        angles.pitch = SlerpRadians(angles.pitch, desiredAngles.pitch, self:GetPitchSmoothRate() * deltaTime )
        
    elseif smoothMode == "quatlerp" then

        --DebugDrawAngles( angles, self:GetOrigin(), 2.0, 0.5 )
        --Print("pre slerp = %s", ToString(angles)) 
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

    -- Update to the current view angles.    
    local viewAngles = Angles(input.pitch, input.yaw, 0)
    self:SetViewAngles(viewAngles)
        
    -- Update view offset from crouching

    local viewY = self:GetMaxViewOffsetHeight()

    -- Don't set new view offset height unless needed (avoids Vector churn).
    local lastViewOffsetHeight = self:GetSmoothedViewOffset().y
    if math.abs(viewY - lastViewOffsetHeight) > kEpsilon then
        self:SetViewOffsetHeight(viewY)
    end
    
    self:AdjustAngles(input.time)
    
end

function Player:TriggerLandEffects()
    if not Shared.GetIsRunningPrediction() then
        self:TriggerEffects("land", {surface = self:GetMaterialBelowPlayer()})
    end
end

function Player:OnJumpLand(impactForce)
    if self:GetPlayLandSound(impactForce) then
        self:TriggerLandEffects()
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

        -- Reset values when moving.
        if self:GetVelocityLength() > 0.1 then
            -- Take a bit of time to reset value so going into the move animation doesn't skip.
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

        -- Sometimes, probably due to prediction, these values can go out of range. Wrap them here
        self.standingBodyYaw = Math.Wrap(self.standingBodyYaw, 0, kDoublePI)
        self.runningBodyYaw = Math.Wrap(self.runningBodyYaw, 0, kDoublePI)
        self.bodyYaw = 0
        self.bodyYawRun = 0

    end
    
end
local function UpdateAnimationInputs(self, input)

    -- From WeaponOwnerMixin.
    -- NOTE: We need to process moves on weapons and view model before adjusting origin + angles below.
    self:ProcessMoveOnWeapons(input)
    
    local viewModel = self:GetViewModelEntity()
    if viewModel then
        viewModel:ProcessMoveOnModel()
    end
    
    if self.ProcessMoveOnModel then
        self:ProcessMoveOnModel()
    end

end

function Player:ConfigurePhysicsCuller()
    local viewCoords = self:GetViewCoords()
    local viewPoint = self:GetOrigin()
    local fovDegrees = Math.Degrees(GetScreenAdjustedFov(Client.GetEffectiveFov(self), 4/3))
        
    Client.ConfigurePhysicsCuller(viewPoint, self:GetViewAngles(), fovDegrees, Player.kPhysicsCullMin, Player.kPhysicsCullMax)
end

function Player:OnProcessIntermediate(input)
   
    if self:GetIsAlive() and not self.countingDown then
        -- Update to the current view angles so that the mouse feels smooth and responsive.
        self:UpdateViewAngles(input)
    end
    
    -- This is necessary to update the child entity bones so that the view model
    -- animates smoothly and attached weapons will have the correct coords.
    local numChildren = self:GetNumChildren()
    for i = 1,numChildren do
        local child = self:GetChildAtIndex(i - 1)
        if child.OnProcessIntermediate then
            child:OnProcessIntermediate(input)
        end
    end
    
    self:UpdateClientEffects(input.time, true)
    
    if Client then
        self:ConfigurePhysicsCuller()
    end
    
end

function Player:GetHasController()

    if (Client or Predict) and self.isHallucination then
        return false
    end    

    return HasMixin(self, "Live") and self:GetIsAlive()
    
end

function Player:GetHasOutterController()

    if (Client or Predict) and self.isHallucination then
        return false
    end

    return HasMixin(self, "Live") and self:GetIsAlive()
    
end

-- You can't modify a compensated field for another (relevant) entity during OnProcessMove(). The
-- "local" player doesn't undergo lag compensation it's only all of the other players and entities.
-- For example, if health was compensated, you can't modify it when a player was shot -
-- it will just overwrite it with the old value after OnProcessMove() is done. This is because
-- compensated fields are rolled back in time, so it needs to restore them once the processing
-- is done. So it backs up, synchs to the old state, runs the OnProcessMove(), then restores them. 
function Player:OnProcessMove(input)

    local commands = input.commands
    if self:GetIsAlive() then
    
        if self.countingDown then
        
            input.move:Scale(0)
            input.commands = 0
            
        else
        
            -- Allow children to alter player's move before processing. To alter the move
            -- before it's sent to the server, use OverrideInput
            input = self:AdjustMove(input)
            
            -- Update player angles and view angles smoothly from desired angles if set. 
            -- But visual effects should only be calculated when not predicting.
            self:UpdateViewAngles(input)  
            
        end
        
    end
    
    self:OnUpdatePlayer(input.time)
    
    ScriptActor.OnProcessMove(self, input)
    
    self:HandleButtons(input)
    
    UpdateAnimationInputs(self, input)
    
    if self:GetIsAlive() then

        local runningPrediction = Shared.GetIsRunningPrediction()

        self:PreUpdateMove(input, runningPrediction)
    
        self:UpdateMove(input, runningPrediction)
        
        self:PostUpdateMove(input, runningPrediction)

		self:UpdateMaxMoveSpeed(input.time)

        -- Restore the buttons so that things like the scoreboard, etc. work.
        input.commands = commands
        
        -- Everything else
        self:UpdateMisc(input)
        self:UpdateSharedMisc(input)
        
        -- Debug if desired
        --self:OutputDebug()
        
        UpdateBodyYaw(self, input.time, input)

    end
    
    self:EndUse(input.time)
    
    if Server then
        HitSound_DispatchHits()
    end
    
    if Client then
        self:ConfigurePhysicsCuller()
    end
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

function Player:GetSlowOnLand(impactForce)
    return false
end

function Player:UpdateMaxMoveSpeed(deltaTime)    

    ASSERT(deltaTime >= 0)
    
    -- Only recover max speed when on the ground
    if self:GetIsOnGround() then
    
        local newSlow = math.max(0, self.slowAmount - deltaTime)
        self.slowAmount = newSlow    
        
    end
    
end

function Player:OutputDebug()

    local startPoint = Vector(self:GetOrigin())
    startPoint.y = startPoint.y + self:GetExtents().y
    DebugBox(startPoint, startPoint, self:GetExtents(), .05, 1, 1, 0, 1)
    
end

-- Note: It doesn't look like this is being used anymore.
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

-- Required by ControllerMixin.
function Player:GetControllerSize()
    return GetTraceCapsuleFromExtents(self:GetExtents())
end

function Player:GetControllerPhysicsGroup()
    return PhysicsGroup.PlayerControllersGroup
end

-- Required by ControllerMixin.
function Player:GetMovePhysicsMask()
    return PhysicsMask.Movement
end

--[[
    Moves the player downwards (by at most a meter).
]]
function Player:DropToFloor()

    PROFILE("Player:DropToFloor")

    if self.controller then
        self:UpdateControllerFromEntity()
        self.controller:Move( Vector(0, -1, 0), CollisionRep.Move, CollisionRep.Move, self:GetMovePhysicsMask())    
        self:UpdateOriginFromController()
    end

end

function Player:GetCanStepOver(entity)
    return not entity:isa("Player")
end

function Player:GetCanStep()
    return self:GetIsOnGround()
end

function Player:OnTakeFallDamage(damage)
    self:TakeDamage(damage, self, self, self:GetOrigin(), nil, 0, damage, kDamageType.Falling)
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

function Player:GetCanCrouch()
    return true
end

function Player:GetJumpMode()
    if not self:HasAdvancedMovement() then
        return kJumpMode.Queued
    else
        return kJumpMode.Repeating
    end
end

function Player:GetJumpForce()
    return kJumpForce
end

function Player:GetJumpVelocity(input, velocity)
    velocity.y = self:GetJumpForce()// - math.abs(self:GetGravityForce(input) * input.time)
    //This shouldnt be needed because we jump before any gravity is applied, therefore an entire frames worth of gravity
    //will be deducted correctly.
end

function Player:GetGroundFriction()
    return kGroundFriction
end

function Player:GetClimbFrictionForce()
    return kClimbFriction
end

function Player:GetAirControl()
    return 11 * self:GetSlowSpeedModifier()
end

function Player:GetSimpleAcceleration(onGround)
    return ConditionalValue(onGround, 13 * self:GetSlowSpeedModifier(), 6 * self:GetSlowSpeedModifier())
end

function Player:GetGroundTransistionTime()
    return kAirGroundTransistionTime
end

function Player:GetSimpleFriction(onGround)
    if onGround then
        return 9
    else
        return 0
    end
end

function Player:GetAirFriction()
    return 0
end

function Player:GetClampedMaxSpeed()
    return 30
end

function Player:GetMaxBackwardSpeedScalar()
    return kBackwardsMovementScalar
end

function Player:GetPerformsVerticalMove()
    return false
end

function Player:ModifyGravityForce(gravityTable)
    if self:GetIsOnLadder() or self:GetIsOnGround() then
        gravityTable.gravity = 0
    end
end

function Player:GetAcceleration(OnGround)
    return ConditionalValue(OnGround, kGoldSrcAcceleration, kGoldSrcAirAcceleration)
end

function Player:GetUsesGoldSourceMovement()
    return true
end

function Player:GetMaxSpeed(possible)
    if possible then
        return kRunMaxSpeed
    end
    
    local maxSpeed = kRunMaxSpeed
    
    if self.movementModiferState and self:GetIsOnGround() then
        maxSpeed = kWalkMaxSpeed
    end
    
    if self:GetCrouching() and self:GetCrouchAmount() == 1 and self:GetIsOnGround() and not self:GetLandedRecently() then
        maxSpeed = kCrouchMaxSpeed
    end
      
    return maxSpeed
end

/**
 * Returns a value between 0 and 1 indicating how much the player has crouched
 * visually (actual crouching is binary).
 */
  
function Player:GetCrouchShrinkAmount()
    return kCrouchShrinkAmount
end

function Player:GetExtentsCrouchShrinkAmount()
    return kExtentsCrouchShrinkAmount
end

function Player:SetOrigin(origin)

    Entity.SetOrigin(self, origin)
    
    self:UpdateControllerFromEntity()
    
end

function Player:GetPlayFootsteps()
    return self:GetVelocityLength() > kFootstepsThreshold and self:GetIsOnGround() and self:GetIsAlive() and not self:GetIsDestroyed()  
end

function Player:GetMovementModifierState()
    return self.movementModiferState
end

local function UpdateStepAmount(self, stepAmount)

    local deltaTime      = Shared.GetTime() - self.stepStartTime
    local prevStepAmount = 0
    
    if deltaTime < kStepTotalTime then
        prevStepAmount = self.stepAmount * (1 - deltaTime / kStepTotalTime)
    end        
    
    self.stepStartTime = Shared.GetTime()
    self.stepAmount    = Clamp(stepAmount + prevStepAmount, -kMaxStepAmount, kMaxStepAmount)

end

// Check to see if we moved up a step and need to smooth out the movement.
function Player:OnPositionUpdated(moveVector, stepAllowed)

    if not Shared.GetIsRunningPrediction() then
        if moveVector.y ~= 0 and stepAllowed then
            UpdateStepAmount(self, moveVector.y)
        end
    end

end

-- Called by client/server UpdateMisc()
function Player:UpdateSharedMisc(input)

    -- Update the view offet with the smoothed value.
    self:SetViewOffsetHeight(self:GetSmoothedViewOffset().y)
end

-- Subclasses can override this.
-- In particular, the Skulk must override this since its view angles do NOT correspond to its head angles.
function Player:GetHeadAngles()
    return self:GetViewAngles()
end

function Player:OnUpdatePoseParameters()
    
    if not Shared.GetIsRunningPrediction() then
        
        local viewModel = self:GetViewModelEntity()
        if viewModel ~= nil then
        
            local activeWeapon = self:GetActiveWeapon()
            if activeWeapon and activeWeapon.UpdateViewModelPoseParameters then
                activeWeapon:UpdateViewModelPoseParameters(viewModel)
            end
            
        end

        SetPlayerPoseParameters(self, viewModel, self:GetHeadAngles())
        
    end

end

-- for marquee selection
function Player:GetIsMoveable()
    return true
end

function Player:GetIsIdle()
    return self:GetVelocityLength() < 0.1 and not self.moveButtonPressed
end

function Player:GetPlayIdleSound()
    return self:GetIsAlive() and (self:GetVelocityLength() / self:GetMaxSpeed()) > 0.5
end

function Player:GetPlayLandSound(impactForce)
    return impactForce > 3
end

function Player:OnJump()
    self:TriggerJumpEffects()
end

function Player:TriggerJumpEffects()
    if not Shared.GetIsRunningPrediction() then
        self:TriggerEffects("jump", {surface = self:GetMaterialBelowPlayer()})
    end
end

-- 0-1 scalar which goes away over time (takes 1 seconds to get expire of a scalar of 1)
-- Never more than 1 second of recovery time
-- Also reduce velocity by this amount
function Player:AddSlowScalar(scalar)
    self.slowAmount = Clamp(self.slowAmount + scalar, 0, kMaxPlayerSlow)
end

function Player:ClearSlow()
    self.slowAmount = 0
end

function Player:GetMaterialBelowPlayer()

    local fixedOrigin = Vector(self:GetOrigin())
    
    -- Start the trace a bit above the very bottom of the origin because
    -- of cases where a large velocity has pushed the origin below the
    -- surface the player is on
    fixedOrigin.y = fixedOrigin.y + self:GetExtents().y / 2
    local trace = Shared.TraceRay(fixedOrigin, fixedOrigin + Vector(0, -(2.5*self:GetExtents().y + .1), 0), CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOne(self))
    
    local material = trace.surface
    -- Default to metal if no surface material is found.
    if not material or string.len(material) == 0 then
        material = "metal"
    end
    
    return material
end

function Player:GetFootstepSpeedScalar()
    return Clamp(self:GetVelocityLength() / kRunMaxSpeed, 0, 1)
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

    -- Remember if we attacked so we don't call AttackEnd() until mouse button is released
    self.primaryAttackLastFrame = (bit.band(input.commands, Move.PrimaryAttack) ~= 0)
    self.secondaryAttackLastFrame = (bit.band(input.commands, Move.SecondaryAttack) ~= 0)
    
end

function Player:MovementModifierChanged(state, input)
end

function Player:GetPrimaryAttackLastFrame()
    return self.primaryAttackLastFrame
end

function Player:GetSecondaryAttackLastFrame()
    return self.secondaryAttackLastFrame
end

function Player:GetSpeedDebugSpecial()
    return self:GetCrouchAmount()
end

function Player:GetIsAbleToUse()
    return self:GetIsAlive()
end

function Player:GetCanBeKnocked()
    return self:GetIsAlive()
end

function Player:HandleButtons(input)

    PROFILE("Player:HandleButtons")
    
    if not self:GetCanControl() then
    
        -- The following inputs are disabled when the player cannot control themself.
        input.commands = bit.band(input.commands, bit.bnot(bit.bor(Move.Use, Move.Buy, Move.Jump,
                                                                   Move.PrimaryAttack, Move.SecondaryAttack,
                                                                   Move.SelectNextWeapon, Move.SelectPrevWeapon, Move.Reload,
                                                                   Move.Taunt, Move.Weapon1, Move.Weapon2,
                                                                   Move.Weapon3, Move.Weapon4, Move.Weapon5, Move.Crouch, Move.Drop, Move.MovementModifier)))
                                                                   
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
    
    self.movementModiferState = newMovementState
    
    local ableToUse = self:GetIsAbleToUse()
    if ableToUse and bit.band(input.commands, Move.Use) ~= 0 and not self.primaryAttackLastFrame and not self.secondaryAttackLastFrame then
        AttemptToUse(self, input.time)
    end
    
    if Client and not Shared.GetIsRunningPrediction() then
    
        self.buyLastFrame = self.buyLastFrame or false
        -- Player is bringing up the buy menu (don't toggle it too quickly)
        local buyButtonPressed = bit.band(input.commands, Move.Buy) ~= 0
        if not self.buyLastFrame and buyButtonPressed and Shared.GetTime() > (self.timeLastMenu + 0.3) then
        
            self:Buy()
            self.timeLastMenu = Shared.GetTime()
            
        end
        
        self.buyLastFrame = buyButtonPressed
        
    end

    self:HandleAttacks(input)
    
    // Remember when jump released
    if bit.band(input.commands, Move.Jump) == 0 then
        self:SetIsJumpHandled(false)
    end
    
    if bit.band(input.commands, Move.Reload) ~= 0 then
        self:Reload()
    end
    
    -- Weapon switch
    if not self:GetIsCommander() and not self:GetIsUsing() then
    
        if bit.band(input.commands, Move.SelectNextWeapon) ~= 0 then
            self:SelectNextWeapon()
        end
        
        if bit.band(input.commands, Move.SelectPrevWeapon) ~= 0 then
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

--[[
    Returns the view model entity.
]]
function Player:GetViewModelEntity()

    local result
    -- viewModelId is a private field
    if not Client or self:GetIsLocalPlayer() then  
    
        result = Shared.GetEntity(self.viewModelId)
        ASSERT(not result or result:isa("ViewModel"), "%s: viewmodel is a %s!", self, result)
        
    end
    
    return result
    
end

--[[
    Sets the model currently displayed on the view model.
]]
function Player:SetViewModel(viewModelName, weapon)

    local viewModel = self:GetViewModelEntity()
    
    -- Currently there is an edge case where this function is called when
    -- there is no view model entity. This will help us figure out why.
    if not viewModel then
        return
    end

    local animationGraphFileName = weapon and weapon:GetAnimationGraphName()
    viewModel:SetModel(viewModelName, animationGraphFileName)
    viewModel:SetWeapon(weapon)
    
end

function Player:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false
end

function Player:GetScoreboardChanged()
    return self.scoreboardChanged
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

-- Overwrite to get player status description
function Player:GetPlayerStatusDesc()
    if (self:GetIsAlive() == false) then
        return kPlayerStatus.Dead
    end
    return kPlayerStatus.Void
end

function Player:GetCanGiveDamageOverride()
    return true
end

-- Overwrite how players interact with doors
function Player:OnOverrideDoorInteraction(inEntity)
    if self:GetVelocityLength() > 8 then
        return true, 10
    else
        return true, 6
    end
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

-- childs should override this
function Player:GetArmorAmount()
    return self:GetMaxArmor()
end

function Player:TriggerFootstep()
    
	self.leftFoot = not self.leftFoot
	//local sprinting = not self.movementModiferState
	local viewVec = self:GetViewAngles():GetCoords().zAxis
	local forward = self:GetVelocity():DotProduct(viewVec) > -0.1
	local crouch = self:GetCrouching() and self:GetCrouchAmount() == 1

	self:TriggerEffects("footstep", {surface = self:GetMaterialBelowPlayer(), left = self.leftFoot, sprinting = true, forward = forward, crouch = crouch})
	
end

local kStepTagNames = { }
kStepTagNames["step"] = true
kStepTagNames["step_run"] = true
kStepTagNames["step_sprint"] = true
kStepTagNames["step_crouch"] = true
function Player:OnTag(tagName)

    PROFILE("Player:OnTag")
    
    -- Filter out crouch steps from playing at inappropriate times.
    if tagName == "step_crouch" and not self:GetCrouching() then
        return
    end
    
    -- Play footstep when foot hits the ground.
    if self:GetPlayFootsteps() and not Predict and not Shared.GetIsRunningPrediction() and kStepTagNames[tagName] then
        self:TriggerFootstep()
    end
    
end

function Player:OnUpdateAnimationInput(modelMixin)

    PROFILE("Player:OnUpdateAnimationInput")
    
    local moveState = "run"
    if self:GetIsJumping() and not self:GetIsOnLadder() then
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
    return self:GetVelocityLength() / self:GetMaxSpeed()
end

function Player:OnUpdateCamera(deltaTime)

    // Update view offset from crouching
    local offset = -self:GetCrouchShrinkAmount() * self:GetCrouchAmount()
    self:SetCameraYOffset(offset)
    
end

function Player:GetCrouchTime()
    return kCrouchTime
end

function Player:BlockMove()
    self.isMoveBlocked = true
end

function Player:RetrieveMove()
    self.isMoveBlocked = false
end

function Player:GetCanControl()
    return not self.isMoveBlocked and self:GetIsAlive() and not self.countingDown
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

function Player:OnJoinTeam()
    self.sendTechTreeBase = true
end

-- This causes problems when doing a trace ray against CollisionRep.Move.
function Player:OnCreateCollisionModel()
    
    -- Remove any "move" collision representation from the player's model, since
    -- all of the movement collision will be handled by the controller.
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

function Player:GetIsRookie()
    return self.isRookie
end

function Player:TriggerBeaconEffects()

    self.timeLastBeacon = Shared.GetTime()
    self:TriggerEffects("distress_beacon_spawn")

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
        -- Send a message as a FP spectating player will need to be notified.
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

function Player:UpdateArmorAmount(armorLevel)

    -- note: some player may have maxArmor == 0
    local armorPercent = self.maxArmor > 0 and self.armor/self.maxArmor or 0
    local newMaxArmor = self:GetArmorAmount(armorLevel)
    
    if newMaxArmor ~= self.maxArmor then    
    
        self.maxArmor = newMaxArmor
        self:SetArmor(self.maxArmor * armorPercent)
        
    end
    
end

Shared.LinkClassToMap("Player", Player.kMapName, networkVars, true)
