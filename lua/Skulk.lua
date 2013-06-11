// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Skulk.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//                  Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/BiteLeap.lua")
Script.Load("lua/Weapons/Alien/Parasite.lua")
Script.Load("lua/Weapons/Alien/XenocideLeap.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/WallMovementMixin.lua")
Script.Load("lua/DissolveMixin.lua")

class 'Skulk' (Alien)

Skulk.kMapName = "skulk"

Skulk.kModelName = PrecacheAsset("models/alien/skulk/skulk.model")
local kViewModelName = PrecacheAsset("models/alien/skulk/skulk_view.model")
local kSkulkAnimationGraph = PrecacheAsset("models/alien/skulk/skulk.animation_graph")

if Server then
    Script.Load("lua/Skulk_Server.lua", true)
elseif Client then
    Script.Load("lua/Skulk_Client.lua", true)
end

// Balance, movement, animation
Skulk.kViewOffsetHeight = .55
Skulk.kXExtents = .45
Skulk.kYExtents = .45
Skulk.kZExtents = .45

local kLeapTime = 0.2
local kLeapVerticalVelocity = 8
local kLeapForce = 15
local kMaxSpeed = 7
local kGoodJumpSpeed = 10
local kBestJumpSpeed = 12
local kMaxWalkSpeed = 4
local kJumpHeight = 1.3
local kWallJumpForce = 7
local kWallJumpYBoost = 2
local kJumpDelay = 0.25

local kMass = 45 // ~100 pounds
local kWallWalkCheckInterval = .1
local kWallWalkNormalSmoothRate = 4
local kNormalWallWalkFeelerSize = 0.25
local kStickyWallWalkFeelerSize = 0.35
local kNormalWallWalkRange = 0.1
local kStickyWallWalkRange = 0.2

// jump is valid when you are close to a wall but not attached yet at this range
local kJumpWallRange = 0.2
local kJumpWallFeelerSize = 0.1
local kWallStickFactor = 0.97

// kStickForce depends on wall walk normal, strongest when walking on ceilings
local kStickForce = 1
local kStickForceWhileSneaking = 3
local kStickWallRangeBoostWhileSneaking = 1.2
local kDefaultAttackSpeed = 1.08

local networkVars =
{
    wallWalking = "compensated boolean",
    timeLastWallWalkCheck = "private compensated time",
    leaping = "compensated boolean",
    timeOfLeap = "private compensated time",
    // wallwalking is enabled only after we bump into something that changes our velocity
    // it disables when we are on ground or after we jump or leap
    wallWalkingEnabled = "private compensated boolean",
    timeOfLastJumpLand = "private compensated time",
    timeLastWallJump = "private compensated time",
    jumpLandSpeed = "private compensated float"

}

AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)

function Skulk:OnCreate()

    InitMixin(self, CameraHolderMixin, { kFov = kSkulkFov })
    InitMixin(self, WallMovementMixin)
    
    Alien.OnCreate(self)

    InitMixin(self, DissolveMixin)
    
    self.stickyForce = 0
    
end

function Skulk:OnInitialized()

    Alien.OnInitialized(self)
    
    // Note: This needs to be initialized BEFORE calling SetModel() below
    // as SetModel() will call GetHeadAngles() through SetPlayerPoseParameters()
    // which will cause a script error if the Skulk is wall walking BEFORE
    // the Skulk is initialized on the client.
    self.currentWallWalkingAngles = Angles(0.0, 0.0, 0.0)
    
    self:SetModel(Skulk.kModelName, kSkulkAnimationGraph)
    
    self.wallWalking = false
    self.wallWalkingNormalGoal = Vector.yAxis
    
    if Client then
    
        self.currentCameraRoll = 0
        self.goalCameraRoll = 0
        
        self:AddHelpWidget("GUIEvolveHelp", 2)
        self:AddHelpWidget("GUISkulkParasiteHelp", 1)
        self:AddHelpWidget("GUISkulkLeapHelp", 2)
        self:AddHelpWidget("GUIMapHelp", 1)
        
    end
    
    self.leaping = false
    
    self.timeLastWallJump = 0
    
end

function Skulk:OnDestroy()

    Alien.OnDestroy(self)

end

function Skulk:GetBaseArmor()
    return kSkulkArmor
end

function Skulk:GetArmorFullyUpgradedAmount()
    return kSkulkArmorFullyUpgradedAmount
end

function Skulk:GetMaxViewOffsetHeight()
    return Skulk.kViewOffsetHeight
end

function Skulk:GetCanClimb()
    return false
end

function Skulk:GetCrouchShrinkAmount()
    return 0
end

function Skulk:GetExtentsCrouchShrinkAmount()
    return 0
end

// required to trigger wall walking animation
function Skulk:GetIsJumping()
    return Player.GetIsJumping(self) and not self.wallWalking
end

// The Skulk movement should factor in the vertical velocity
// only when wall walking.
function Skulk:GetMoveSpeedIs2D()
    return not self:GetIsWallWalking()
end

function Skulk:OnLeap()

    local velocity = self:GetVelocity()
    //local minSpeed = math.max(0, kMinLeapVelocity - velocity:GetLengthXZ() - kLeapVerticalForce) * self:GetMovementSpeedModifier()

    local forwardVec = self:GetViewAngles():GetCoords().zAxis
    local newVelocity = velocity + (GetNormalizedVector(forwardVec) * (kLeapForce * self:GetMovementSpeedModifier()))
    
    if newVelocity.y < 1 then
        newVelocity.y = kLeapVerticalVelocity * self:GetMovementSpeedModifier()
    end
    
    self:SetVelocity(newVelocity)
    
    self.leaping = true
    self.wallWalkingEnabled = false
    
    self.timeOfLeap = Shared.GetTime()
    self.timeOfLastJump = Shared.GetTime()
    
end

function Skulk:GetCanCrouch()
    return false
end

function Skulk:GetRecentlyWallJumped()
    return self.timeLastWallJump + kJumpDelay > Shared.GetTime()
end

function Skulk:GetCanWallJump()
    return self:GetIsWallWalking() or (not self:GetIsOnGround() and self:GetAverageWallWalkingNormal(kJumpWallRange, kJumpWallFeelerSize) ~= nil) and not self:GetRecentlyWallJumped() and not self.crouching 
end

function Skulk:GetViewModelName()
    return kViewModelName
end

function Skulk:GetCanJump()
    return Alien.GetCanJump(self) or self:GetCanWallJump()    
end

function Skulk:GetIsWallWalking()
    return self.wallWalking
end

function Skulk:GetIsLeaping()
    return self.leaping
end

function Skulk:ReceivesFallDamage()
    return false
end

// Skulks do not respect ladders due to their wall walking superiority.
function Skulk:GetIsOnLadder()
    return false
end

function Skulk:GetIsWallWalkingPossible() 
    return not self.crouching
end

local function PredictGoal(self, velocity)

    local goal = self.wallWalkingNormalGoal
    if velocity:GetLength() > 1 and not self:GetIsOnSurface() then

        local movementDir = GetNormalizedVector(velocity)
        local completedMove, hitEntities, averageSurfaceNormal = self:PerformMovement(movementDir * 2.5, 3, nil, false)

        if averageSurfaceNormal then        
            goal = averageSurfaceNormal    
        end

    end

    return goal

end

function Skulk:TriggerJumpEffects()
    if not Shared.GetIsRunningPrediction() then
        local spd = self:GetVelocity():GetLength()
        if spd > kBestJumpSpeed then
            self:TriggerEffects("jump_best", {surface = self:GetMaterialBelowPlayer()})
        elseif spd > kGoodJumpSpeed then
            self:TriggerEffects("jump_good", {surface = self:GetMaterialBelowPlayer()})
        else
            self:TriggerEffects("jump", {surface = self:GetMaterialBelowPlayer()})
        end
    end
end

// Update wall-walking from current origin
function Skulk:PreUpdateMove(input, runningPrediction)

    PROFILE("Skulk:PreUpdateMove")
    
    self.moveButtonPressed = input.move:GetLength() ~= 0
    
    if not self.wallWalkingEnabled or not self:GetIsWallWalkingPossible() or self.crouching then
    
        self.wallWalking = false
        
    else

        // Don't check wall walking every frame for performance    
        if (Shared.GetTime() > (self.timeLastWallWalkCheck + kWallWalkCheckInterval)) then

            // Most of the time, it returns a fraction of 0, which means
            // trace started outside the world (and no normal is returned)           
            local goal = self:GetAverageWallWalkingNormal(kNormalWallWalkRange, kNormalWallWalkFeelerSize)
            
            if goal ~= nil then
            
                self.wallWalkingNormalGoal = goal
                self.wallWalking = true
                       
            else
                self.wallWalking = false                
            end
            
            self.timeLastWallWalkCheck = Shared.GetTime()
            
        end 
        
    end
    
    // When not wall walking, the goal is always directly up (running on ground).
    if not self:GetIsWallWalking() then
    
        self.wallWalkingNormalGoal = Vector.yAxis
        
        if self:GetIsOnGround() then
            self.wallWalkingEnabled = false
        end
        
    end
    
    if self.leaping and (Alien.GetIsOnGround(self) or self.wallWalking) and (Shared.GetTime() > self.timeOfLeap + kLeapTime) then
        self.leaping = false
    end
    
    self.currentWallWalkingAngles = self:GetAnglesFromWallNormal(PredictGoal(self, self:GetVelocity()) or Vector.yAxis) or self.currentWallWalkingAngles
    
end

function Skulk:GetAngleSmoothRate()

    if self:GetIsWallWalking() then
        return 1.5
    end

    return 7
    
end

function Skulk:GetRollSmoothRate()
    return 4
end

function Skulk:GetPitchSmoothRate()
    return 3
end

function Skulk:GetSlerpSmoothRate()
    return 5
end

function Skulk:GetDesiredAngles(deltaTime)
    return self.currentWallWalkingAngles
end 

function Skulk:GetHeadAngles()

    if self:GetIsWallWalking() then
        return self.currentWallWalkingAngles
    else
        return self:GetViewAngles()
    end

end

function Skulk:UpdatePosition(velocity, time)

    PROFILE("Skulk:UpdatePosition")
    local yAxis = self.wallWalkingNormalGoal
    local requestedVelocity = Vector(velocity)
    
    if self.adjustToGround then
        velocity.y = 0
        self.adjustToGround = false
    end
        
    // Fallback on default behavior when wallWalking is disabled
    if not self.wallWalkingEnabled then
        
        local oldSpeed = velocity:GetLengthXZ()
        local wereOnGround = self:GetIsOnGround()
        velocity = Alien.UpdatePosition(self, velocity, time)
        // we enable wallkwalk if we are no longer on ground but were the previous 
        if wereOnGround and not self:GetIsOnGround() then
            self.wallWalkingEnabled = self:GetIsWallWalkingPossible()
        else
            // we enable wallwalk if our new velocity is significantly smaller than the requested velocity
            local newSpeed = velocity:GetLengthXZ()
            if newSpeed < oldSpeed * kWallStickFactor then
                self.wallWalkingEnabled = self:GetIsWallWalkingPossible()
            end
        end
   
    else

        // We need to make a copy so that we aren't holding onto a reference
        // which is updated when the origin changes.
        local start = Vector(self:GetOrigin())

        // First move the Skulk upwards from their current orientation to go over small obstacles. 
        local offset = nil
        local stepHeight = self:GetStepHeight()

        // First try moving capsule half the desired distance.
        self:PerformMovement(velocity * time * 0.5, 3, nil)
        
        // Then attempt to run over objects in the way.
        self:PerformMovement( yAxis * stepHeight, 1 )
        offset = self:GetOrigin() - start

        // Complete the move.
        self:PerformMovement(velocity * time * 0.5, 3, nil)

        // Finally, move the skulk back down to compensate for moving them up.
        // We add in an additional step height for moving down steps/ramps.
        offset = -(yAxis * stepHeight)
        self:PerformMovement( offset, 1, nil, true )
        
        // Move towards the stick goal if there is a stick goal.
        
        if self.wallWalkingStickEnabled and self.wallWalkingStickGoal then
        
            self.stickyForce = math.max( 0, kStickForce * self.wallWalkingStickGoal:DotProduct(Vector(0,-1,0)) )
            // Increase the stick force if they are in sneak mode.
            if self.movementModiferState then
                self.stickyForce = kStickForceWhileSneaking
            end
            
            // make sure we don't pull downwards (then we can't move up from the floor)
            local pull = -self.wallWalkingStickGoal * (time * self.stickyForce)
            pull.y = math.max(0, pull.y)
            self:PerformMovement(pull, 1, nil)
            
        end

    end

    return velocity

end

function Skulk:GetAngleSmoothingMode()

    if self:GetIsWallWalking() then
        return "quatlerp"
    else
        return "euler"
    end

end

function Skulk:GetIsUsingBodyYaw()

    return not self:GetIsWallWalking()

end

function Skulk:GoldSrc_GetFriction()
    return ConditionalValue(self:GetIsWallWalking(), Player.GoldSrc_GetFriction(self) + 3.0, Player.GoldSrc_GetFriction(self))
end

function Skulk:UpdateCrouch()
    // Skulks cannot crouch! 
end

function Skulk:GoldSrc_GetMaxSpeed(possible)

    if possible then
        return kMaxSpeed
    end
    
    local maxSpeed = kMaxSpeed
    
    if self.movementModiferState and self:GetIsOnSurface() then
        maxSpeed = kMaxWalkSpeed
    end

    return maxSpeed * self:GetMovementSpeedModifier()
    
end

function Skulk:GetMass()
    return kMass
end

function Skulk:GetGravityAllowed()
    return not self:GetIsWallWalking()
end

function Skulk:GetIsOnSurface()
    return Alien.GetIsOnSurface(self) or (self:GetIsWallWalking() and not self.crouching)
end

function Skulk:GetIsAffectedByAirFriction()
    return not self:GetIsOnSurface()
end

function Skulk:GetIsCloseToGround(distanceToGround)

    if self:GetIsWallWalking() then
        return false
    end
    
    return Alien.GetIsCloseToGround(self, distanceToGround)
    
end

function Skulk:GetPlayFootsteps()
    return self:GetVelocityLength() > 4 and not GetHasSilenceUpgrade(self) and self:GetIsOnSurface() and self:GetIsAlive()
end

/**
 * Knockback only allowed while the Skulk is in the air (jumping or leaping).
 */
function Skulk:GetIsKnockbackAllowed()

    return not self:GetIsOnSurface()
end

function Skulk:GetJumpHeight()
    return kJumpHeight
end

function Skulk:PerformsVerticalMove()
    return self:GetIsWallWalking()
end

function Skulk:GetJumpVelocity(input, velocity)

    if self:GetCanWallJump() then
        if velocity:GetLengthXZ() < kMaxSpeed then
            // From testing in NS1:
            // Only viewangle seem to be used for determining force direction
            // Only wall-jump if facing away from the surface that we're currently sticking to
            // Walljump velocity is slightly higher than normal maxspeed. Celerity bonus also applies.
            // There seems to be a small upwards velocity added regardless of viewangles
            // Previous velocity seems to be ignored
            local direction = self:GetViewAngles():GetCoords().zAxis
            if self.wallWalkingNormalGoal:DotProduct(direction) >= 0.0 then
                direction:Scale(kWallJumpForce * self:GetMovementSpeedModifier())
                direction.y = direction.y + kWallJumpYBoost * self:GetMovementSpeedModifier()
                VectorCopy(direction, velocity)
                self.lastwalljump = Shared.GetTime()
            end
        end
    else
        Alien.GetJumpVelocity(self, input, velocity)
    end
end

function Skulk:HandleJump(input, velocity)

    local success = Alien.HandleJump(self, input, velocity)
    
    if success then
    
        self.wallWalking = false
        self.wallWalkingEnabled = false
    
    end
        
    return success
    
end

function Skulk:OnUpdateAnimationInput(modelMixin)

    PROFILE("Skulk:OnUpdateAnimationInput")
    
    Alien.OnUpdateAnimationInput(self, modelMixin)
    
    if self:GetIsLeaping() then
        modelMixin:SetAnimationInput("move", "leap")
    end
    
    modelMixin:SetAnimationInput("onwall", self:GetIsWallWalking() and not self:GetIsJumping())
    modelMixin:SetAnimationInput("attack_speed", self:GetIsPrimaled() and (kDefaultAttackSpeed * kPrimalScreamROFIncrease) or kDefaultAttackSpeed)
end

local kSkulkEngageOffset = Vector(0, 0.5, 0)
function Skulk:GetEngagementPointOverride()
    return self:GetOrigin() + kSkulkEngageOffset
end

Shared.LinkClassToMap("Skulk", Skulk.kMapName, networkVars)