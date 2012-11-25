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
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/CustomGroundMoveMixin.lua")
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

local networkVars =
{
    wallWalking = "compensated boolean",
    timeLastWallWalkCheck = "private time",
    leaping = "compensated boolean",
    timeOfLeap = "private time",
    wallWalkingNormalGoal = "private vector (-1 to 1 by 0.001)",
    wallWalkingNormalCurrent = "private compensated vector (-1 to 1 by 0.001 [ 8 ], -1 to 1 by 0.001 [ 9 ])",
    wallWalkingStickGoal = "private vector (-1 to 1 by 0.001)",
    stickyForce = "private float (0 to 10 by 0.01)",
    wallWalkingStickEnabled = "private boolean",
    // wallwalking is enabled only after we bump into something that changes our velocity
    // it disables when we are on ground or after we jump or leap
    wallWalkingEnabled = "private boolean",
    lastwalljump = "private time"
}

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(CustomGroundMoveMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)

// Balance, movement, animation
Skulk.kJumpRepeatTime = 0.1
Skulk.kViewOffsetHeight = .55
Skulk.kHealth = kSkulkHealth
Skulk.kArmor = kSkulkArmor
Skulk.kLeapTime = 0.2
Skulk.kLeapVerticalVelocity = 8
Skulk.kLeapForce = 15
Skulk.kMaxSpeed = 9
Skulk.kMaxWalkSpeed = 4
Skulk.kJumpHeight = 1.3
Skulk.kWallJumpForce = 7
Skulk.kWallJumpYBoost = 2
Skulk.kJumpDelay = 0.25

Skulk.kMass = 45 // ~100 pounds
Skulk.kWallWalkCheckInterval = .1
Skulk.kWallWalkNormalSmoothRate = 4
Skulk.kNormalWallWalkFeelerSize = 0.25
Skulk.kStickyWallWalkFeelerSize = 0.35
Skulk.kNormalWallWalkRange = 0.1
Skulk.kStickyWallWalkRange = 0.25

// jump is valid when you are close to a wall but not attached yet at this range
Skulk.kJumpWallRange = 0.4
Skulk.kJumpWallFeelerSize = 0.1
Skulk.kWallStickFactor = 0.97

// kStickForce depends on wall walk normal, strongest when walking on ceilings
local kStickForce = 3
local kStickForceWhileSneaking = 5
local kStickWallRangeBoostWhileSneaking = 1.2
local kDefaultAttackSpeed = 1.08

Skulk.kXExtents = .45
Skulk.kYExtents = .45
Skulk.kZExtents = .45

function Skulk:OnCreate()

    InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, CustomGroundMoveMixin)
    InitMixin(self, CameraHolderMixin, { kFov = kSkulkFov })
    InitMixin(self, WallMovementMixin)
    
    Alien.OnCreate(self)

    InitMixin(self, DissolveMixin)
    
    self.stickyForce = 0
    
end

function Skulk:OnInitialized()

    Alien.OnInitialized(self)
    
    self:SetModel(Skulk.kModelName, kSkulkAnimationGraph)
    
    self.wallWalking = false
    self.wallWalkingNormalCurrent = Vector.yAxis
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
    self.lastwalljump = Shared.GetTime()
end

function Skulk:OnDestroy()

    Alien.OnDestroy(self)

end

function Skulk:GetBaseArmor()
    return Skulk.kArmor
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

function Skulk:HandleOnGround(input, velocity)   
    self.adjustToGround = true    
end

function Skulk:OnLeap()

    local velocity = self:GetVelocity()
    //local minSpeed = math.max(0, Skulk.kMinLeapVelocity - velocity:GetLengthXZ() - Skulk.kLeapVerticalForce) * self:GetMovementSpeedModifier()

    local forwardVec = self:GetViewAngles():GetCoords().zAxis
    local newVelocity = velocity + (GetNormalizedVector(forwardVec) * (Skulk.kLeapForce * self:GetMovementSpeedModifier()))
    
    if newVelocity.y < 1 then
        newVelocity.y = Skulk.kLeapVerticalVelocity * self:GetMovementSpeedModifier()
    end
    
    self:SetVelocity(newVelocity)
    
    self.leaping = true
    self.wallWalkingEnabled = false

    //self.onGround = false
    //self.onGroundNeedsUpdate = true
    
    self.timeOfLeap = Shared.GetTime()
    self.timeOfLastJump = Shared.GetTime()
    
end

function Skulk:GetCanCrouch()
    return false
end

function Skulk:GetCanWallJump()
    return self:GetIsWallWalking() or (not self:GetIsOnGround() and self:GetAverageWallWalkingNormal(Skulk.kJumpWallRange, Skulk.kJumpWallFeelerSize) ~= nil) and self.lastwalljump + Skulk.kJumpDelay < Shared.GetTime() and not self.crouching 
end

function Skulk:GetViewModelName()
    return kViewModelName
end

function Skulk:GetCanJump()
    return Alien.GetCanJump(self) or self:GetCanWallJump()    
end

function Skulk:OverrideAirControl()
    return self:GetIsWallWalking()
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

function Skulk:GetRecentlyJumped()
    return not (self.timeOfLastJump == nil or (Shared.GetTime() > (self.timeOfLastJump + Skulk.kJumpRepeatTime)))
end

// Update wall-walking from current origin
function Skulk:PreUpdateMove(input, runningPrediction)

    PROFILE("Skulk:PreUpdateMove")
    
    self.moveButtonPressed = input.move:GetLength() ~= 0
    
    if not self.wallWalkingEnabled or not self:GetIsWallWalkingPossible() or self.crouching then
    
        self.wallWalking = false
        
    else

        // Don't check wall walking every frame for performance    
        if (Shared.GetTime() > (self.timeLastWallWalkCheck + Skulk.kWallWalkCheckInterval)) then

            // Most of the time, it returns a fraction of 0, which means
            // trace started outside the world (and no normal is returned)           
            local goal = self:GetAverageWallWalkingNormal(Skulk.kNormalWallWalkRange, Skulk.kNormalWallWalkFeelerSize)
            
            if goal ~= nil then
            
                self.wallWalkingNormalGoal = goal
                self.wallWalkingStickGoal = goal
                self.wallWalkingStickEnabled = true
                self.wallWalking = true
                
            // If not on the ground, check for a wall a bit further away and move towards it like a magnet.            
            elseif not self:GetIsOnGround() then
            
                // If the player is trying to stick to the wall put some extra
                // effort into keeping them on it.
                local boostRange = 1
                // Increase the range a bit if they are in sneak mode.
                if self.movementModiferState then
                    boostRange = kStickWallRangeBoostWhileSneaking
                end
                local stickDirectionGoal = self:GetAverageWallWalkingNormal(Skulk.kStickyWallWalkRange * boostRange, Skulk.kStickyWallWalkFeelerSize * boostRange)
                
                
                if stickDirectionGoal then
                    self.wallWalkingNormalGoal = stickDirectionGoal
                    self.wallWalkingStickGoal = stickDirectionGoal
                    self.wallWalkingStickEnabled = true
                    self.wallWalking = true
                else
                    self.wallWalking = false
                end
                
            end
            
            self.timeLastWallWalkCheck = Shared.GetTime()
            
        end 
    
    end
    
    if not self:GetIsWallWalking() then
        // When not wall walking, the goal is always directly up (running on ground).
        
        self.wallWalkingStickGoal = nil        
        self.wallWalkingStickEnabled = false        
        self.wallWalkingNormalGoal = Vector.yAxis
        
        if self.onGround then        
            self.wallWalkingEnabled = false            
        end
    end

    if self.leaping and (self.onGround or self.wallWalking) and (Shared.GetTime() > self.timeOfLeap + Skulk.kLeapTime) then
        self.leaping = false
    end
    
    local fraction = input.time * Skulk.kWallWalkNormalSmoothRate
    self.wallWalkingNormalCurrent = self:SmoothWallNormal(self.wallWalkingNormalCurrent, self.wallWalkingNormalGoal, fraction)
    
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

function Skulk:GetDesiredAngles(deltaTime)

    if self:GetIsWallWalking() then    
        return self:GetAnglesFromWallNormal(self.wallWalkingNormalCurrent, 1)        
    end
    
    return Alien.GetDesiredAngles(self)
    
end 

function Skulk:GetSmoothAngles()
    return not self:GetIsWallWalking()
end  

function Skulk:GoldSrc_GetFriction()
    return ConditionalValue(self:GetIsWallWalking(), Player.kGoldSrcFriction + 3.0, Player.kGoldSrcFriction)
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
            if newSpeed < oldSpeed * Skulk.kWallStickFactor then
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


function Skulk:PreventWallWalkIntersection(dt)
    
    PROFILE("Skulk:PreventWallWalkIntersection")
    
    // Try moving skulk in a few different directions until we're not intersecting.
    local intersectDirections = { self:GetCoords().xAxis,
                                  -self:GetCoords().xAxis,
                                  self:GetCoords().zAxis,
                                  -self:GetCoords().zAxis }
    
    local originChanged = 0
    local length = self:GetExtents():GetLength()
    local origin = self:GetOrigin()
    for index, direction in ipairs(intersectDirections) do
    
        local extentsDirection = length * 0.75 * direction
        local trace = Shared.TraceRay(origin, origin + extentsDirection, CollisionRep.Move, self:GetMovePhysicsMask(), EntityFilterOne(self))
        if trace.fraction < 1 then
            self:PerformMovement((-extentsDirection * dt * 5 * (1 - trace.fraction)), 3)
        end

    end

end

function Skulk:UpdateCrouch()

    // Skulks cannot crouch!
    
end

function Skulk:GoldSrc_GetMaxSpeed(possible)

    if possible then
        return Skulk.kMaxSpeed
    end
    
    local maxSpeed = Skulk.kMaxSpeed
    
    if self.movementModiferState and self:GetIsOnSurface() then
        maxSpeed = Skulk.kMaxWalkSpeed
    end

    return maxSpeed * self:GetMovementSpeedModifier()
    
end

function Skulk:GetMaxSpeed(possible)

    if possible then
        return Skulk.kMaxSpeed
    end
    
    local maxSpeed = Skulk.kMaxSpeed
    
    if self.movementModiferState and self:GetIsOnSurface() then
        maxSpeed = Skulk.kMaxWalkSpeed
    end

    return maxSpeed * self:GetMovementSpeedModifier()
    
end

function Skulk:GetGravityAllowed()
    return not self:GetIsWallWalking()
end

function Skulk:GetIsOnSurface()
    return Alien.GetIsOnSurface(self) or (self:GetIsWallWalking() and not self.crouching)
end

function Skulk:GetMoveDirection(moveVelocity)

    // Don't constrain movement to XZ so we can walk smoothly up walls
    if self:GetIsWallWalking() then
        return GetNormalizedVector(moveVelocity)
    end
    
    return Alien.GetMoveDirection(self, moveVelocity)
    
end

// Normally players moving backwards can't go full speed, but wall-walking skulks can
function Skulk:GetMaxBackwardSpeedScalar()
    return ConditionalValue(self:GetIsWallWalking(), 1, Alien.GetMaxBackwardSpeedScalar(self))
end

function Skulk:GetIsCloseToGround(distanceToGround)

    if self:GetIsWallWalking() then
        return false
    end
    
    return Alien.GetIsCloseToGround(self, distanceToGround)
    
end

function Skulk:GetPlayFootsteps()
    
    // Don't play footsteps when we're walking
    return self:GetVelocityLength() > 5 and not GetHasSilenceUpgrade(self) and not self:GetIsCloaked() and self:GetIsOnSurface() and self:GetIsAlive()
    
end

function Skulk:GetIsOnGround()

    return Alien.GetIsOnGround(self) and not self:GetIsWallWalking()
    
end

/**
 * Knockback only allowed while the Skulk is in the air (jumping or leaping).
 */
function Skulk:GetIsKnockbackAllowed()

    return not self:GetIsOnSurface()
end

function Skulk:GetJumpHeight()
    return Skulk.kJumpHeight
end

function Skulk:PerformsVerticalMove()
    return self:GetIsWallWalking()
end

function Skulk:GetJumpVelocity(input, velocity)

    if self:GetCanWallJump() then
        if velocity:GetLengthXZ() < Skulk.kMaxSpeed then
            // From testing in NS1:
            // Only viewangle seem to be used for determining force direction
            // Only wall-jump if facing away from the surface that we're currently sticking to
            // Walljump velocity is slightly higher than normal maxspeed. Celerity bonus also applies.
            // There seems to be a small upwards velocity added regardless of viewangles
            // Previous velocity seems to be ignored
            
            local direction = self:GetViewAngles():GetCoords().zAxis
            
            if self.wallWalkingStickGoal:DotProduct(direction) >= 0.0 then
                direction:Scale(Skulk.kWallJumpForce * self:GetMovementSpeedModifier())
                direction.y = direction.y + Skulk.kWallJumpYBoost * self:GetMovementSpeedModifier()
                
                VectorCopy(direction, velocity)
                self.lastwalljump = Shared.GetTime()
            end
        end
    else
        Alien.GetJumpVelocity(self, input, velocity)
    end
end

// skulk handles jump sounds itself
function Skulk:GetPlayJumpSound()
    return false
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


local kSkulkEngageOffset = Vector(0, 0.28, 0)
function Skulk:GetEngagementPointOverride()
    return self:GetOrigin() + kSkulkEngageOffset
end

Shared.LinkClassToMap("Skulk", Skulk.kMapName, networkVars)