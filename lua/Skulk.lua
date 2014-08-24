// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Skulk.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//                  Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Adjusted Skulk for goldsource movement, also moved most variables to be local

Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/BiteLeap.lua")
Script.Load("lua/Weapons/Alien/Parasite.lua")
Script.Load("lua/Weapons/Alien/XenocideLeap.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/WallMovementMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/SkulkVariantMixin.lua")

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

local kLeapTime = 0.33
local kLeapForce = 11
local kMaxSpeed = 6.75
local kGoodJumpSpeed = 10
local kBestJumpSpeed = 12
local kMaxWalkSpeed = 3.1
local kWallJumpForce = 7
local kWallJumpYBoost = 2
local kWallJumpDelay = 0.35
local kMaxLeapSpeed = 20

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

local kWallJumpInterval = 0.4
local kWallJumpForce = 5.2 // scales down the faster you are
local kMinWallJumpForce = 0.1
local kVerticalWallJumpForce = 4.3

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
    timeOfLeap = "private time",
    // wallwalking is enabled only after we bump into something that changes our velocity
    // it disables when we are on ground or after we jump or leap
    wallWalkingEnabled = "private compensated boolean"
}

AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(SkulkVariantMixin, networkVars)

function Skulk:OnCreate()

    InitMixin(self, CameraHolderMixin, { kFov = kSkulkFov })
    InitMixin(self, WallMovementMixin)
    InitMixin(self, SkulkVariantMixin)
    
    Alien.OnCreate(self)

    InitMixin(self, DissolveMixin)

end

function Skulk:OnInitialized()

    Alien.OnInitialized(self)
    
    // Note: This needs to be initialized BEFORE calling SetModel() below
    // as SetModel() will call GetHeadAngles() through SetPlayerPoseParameters()
    // which will cause a script error if the Skulk is wall walking BEFORE
    // the Skulk is initialized on the client.
    self.currentWallWalkingAngles = Angles(0.0, 0.0, 0.0)
    
    self:SetModel(self:GetVariantModel(), kSkulkAnimationGraph)
    
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
    self.timeOfLeap = 0
    
end

function Skulk:GetBaseArmor()
    return kSkulkArmor
end

function Skulk:GetBaseHealth()
    return kSkulkHealth
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

function Skulk:GetCrouchTime()
    return 0
end

function Skulk:GetGroundFriction()
    return ConditionalValue(self:GetIsWallWalking(), Player.GetGroundFriction(self) + 3, Player.GetGroundFriction(self))
end

function Skulk:GetExtentsCrouchShrinkAmount()
    return 0
end

function Skulk:GetMinFootstepTime()
    return 0.05
end

// required to trigger wall walking animation
function Skulk:GetIsJumping()
    return CoreMoveMixin.GetIsJumping(self) and not self.wallWalking
end

function Skulk:ModifyVelocity(input, velocity, deltaTime)

    PROFILE("Skulk:ModifyVelocity")

    if not self:GetIsLeaping() and self.timeOfLeap ~= 0 then

        local forwardVec = self:GetViewAngles():GetCoords().zAxis
        velocity:Add(GetNormalizedVector(forwardVec) * (kLeapForce))
        
        local moveSpeed = velocity:GetLengthXZ()
        if moveSpeed > kMaxLeapSpeed + self:GetMovementSpeedModifier() then
            velocity:Scale((kMaxLeapSpeed + self:GetMovementSpeedModifier()) / moveSpeed)
        end
        
        if self:GetIsOnGround() then
            velocity.y = self:GetJumpForce()
        end

        self.wallWalkingEnabled = false
        self:SetIsOnGround(false)
        self.leaping = true
        
    end
    
end

function Skulk:OnLeap()    
    self.timeOfLeap = Shared.GetTime()
end

//Skulks can crouch, but only use it to trigger wall uncling..
function Skulk:GetCanCrouch()
    return true
end

function Skulk:GetRecentlyWallJumped()
    return self:GetLastJumpTime() + kWallJumpDelay > Shared.GetTime()
end

function Skulk:GetCanWallJump()
    return not self:GetRecentlyWallJumped() and not self:GetCrouching() and (self:GetIsWallWalking() or (not self:GetIsOnGround() and self:GetAverageWallWalkingNormal(kJumpWallRange, kJumpWallFeelerSize) ~= nil))
end

function Skulk:GetViewModelName()
    return kViewModelName
end

function Skulk:GetCanJump()
    return Player.GetCanJump(self) or self:GetCanWallJump()    
end

function Skulk:GetIsWallWalking()
    return self.wallWalking
end

function Skulk:GetIsLeaping()
    return self.leaping
end

function Skulk:OnTakeFallDamage()
end

// Skulks do not respect ladders due to their wall walking superiority.
function Skulk:GetIsOnLadder()
    return false
end

function Skulk:GetIsWallWalkingPossible() 
    return not self:GetCrouching()
end

local function PredictGoal(self, velocity)

    PROFILE("Skulk:PredictGoal")

    local goal = self.wallWalkingNormalGoal
    if velocity:GetLength() > 1 and not self:GetIsOnGround() then

        local movementDir = GetNormalizedVector(velocity)
        local trace = Shared.TraceCapsule(self:GetOrigin(), movementDir * 2.5, Skulk.kXExtents, 0, CollisionRep.Move, PhysicsMask.Movement, EntityFilterOne(self))

        if trace.fraction < 1 and not trace.entity then
            goal = trace.normal    
        end

    end

    return goal

end

/*
function Skulk:TriggerJumpEffects()
    if not Shared.GetIsRunningPrediction() then
        local spd = self:GetVelocityLength()
        if spd > kBestJumpSpeed then
            self:TriggerEffects("jump_best")
        elseif spd > kGoodJumpSpeed then
            self:TriggerEffects("jump_good")
        end
        self:TriggerEffects("jump")
    end
end
*/

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

function Skulk:GetCollisionSlowdownFraction()
    return 0.15
end

function Skulk:GetSimpleAcceleration(onGround)
    return ConditionalValue(onGround, 13, 9)
end

function Skulk:GetAirControl()
    return 27
end

function Skulk:GetGroundTransistionTime()
    return 0.1
end

function Skulk:GetSimpleFriction(onGround)
    if onGround then
        return 11
    else
        local hasupg, level = GetHasCelerityUpgrade(self)
        return 0.055 - (hasupg and level or 0) * 0.009
    end
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

function Skulk:OnWorldCollision(normal, impactForce, newVelocity)
    local canwallWalk = self:GetIsWallWalkingPossible() and normal.y < 0.5
    if not self.wallWalking and canwallWalk then
        self:SetIsJumpHandled(true)
    end
    self.wallWalking = canwallWalk
end

function Skulk:PreUpdateMove(input, runningPrediction)

    PROFILE("Skulk:PreUpdateMove")
    
    if self:GetCrouching() then
        self.wallWalking = false
    end

    if self.wallWalking then

        // Most of the time, it returns a fraction of 0, which means
        // trace started outside the world (and no normal is returned)           
        local goal = self:GetAverageWallWalkingNormal(kNormalWallWalkRange, kNormalWallWalkFeelerSize)
        if goal ~= nil then
        
            self.wallWalkingNormalGoal = goal
            self.wallWalking = true
            
        else
            self.wallWalking = false     
        end
    
    end
    
    // When not wall walking, the goal is always directly up (running on ground).
    if not self:GetIsWallWalking() then
    
        self.wallWalkingNormalGoal = Vector.yAxis
    end
    
    if self.leaping and self:GetIsOnGround() and (Shared.GetTime() > self.timeOfLeap + kLeapTime) then
        self.leaping = false
        self.timeOfLeap = 0
    end
    
    self.currentWallWalkingAngles = self:GetAnglesFromWallNormal(self.wallWalkingNormalGoal or Vector.yAxis) or self.currentWallWalkingAngles

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

function Skulk:GetMaxSpeed(possible)

    if possible then
        return kMaxSpeed
    end
    
    local maxSpeed = kMaxSpeed
    
    if self.movementModiferState and self:GetIsOnGround() then
        maxSpeed = kMaxWalkSpeed
    end

    return maxSpeed + self:GetMovementSpeedModifier()
    
end

function Skulk:GetMass()
    return kMass
end

function Skulk:OverrideUpdateOnGround(onGround)
    return onGround or (self:GetIsWallWalking() and not self:GetCrouching())
end

/**
 * Knockback only allowed while the Skulk is in the air (jumping or leaping).
 */
function Skulk:GetIsKnockbackAllowed()
    return not self:GetIsOnGround()
end

function Skulk:GetPerformsVerticalMove()
    return self:GetIsWallWalking()
end

function Skulk:GetJumpVelocity(input, velocity)

    if self:GetCanWallJump() then
        if not self:HasAdvancedMovement() then
            local direction = input.move.z == -1 and -1 or 1
            // we add the bonus in the direction the move is going
            local viewCoords = self:GetViewAngles():GetCoords()
            local bonusVec = viewCoords.zAxis * direction
            bonusVec.y = 0
            bonusVec:Normalize()
            
            local hasupg, level = GetHasCelerityUpgrade(self)
            local celerityMod = (hasupg and level or 0) * 0.4
            local currentSpeed = velocity:GetLengthXZ()
            local fraction = 1 - Clamp( currentSpeed / (11 + celerityMod), 0, 1)               
            velocity.y = 3 + math.min(1, 1 + viewCoords.zAxis.y) * 2
            
            local force = math.max(kMinWallJumpForce, (kWallJumpForce + celerityMod) * fraction)  
            bonusVec:Scale(force)      

            if not self:GetRecentlyWallJumped() then
            
                bonusVec.y = viewCoords.zAxis.y * kVerticalWallJumpForce
                velocity:Add(bonusVec)

            end
        else
            if velocity:GetLengthXZ() < kMaxSpeed then
                // From testing in NS1:
                // Only viewangle seem to be used for determining force direction
                // Only wall-jump if facing away from the surface that we're currently sticking to
                // Walljump velocity is slightly higher than normal maxspeed. Celerity bonus also applies.
                // There seems to be a small upwards velocity added regardless of viewangles
                // Previous velocity seems to be ignored
                local direction = self:GetViewAngles():GetCoords().zAxis
                if self.wallWalkingNormalGoal:DotProduct(direction) >= 0.0 then
                    direction:Scale(kWallJumpForce)
                    direction.y = direction.y + kWallJumpYBoost
                    VectorCopy(direction, velocity)
                end
            end
        end
    else
        Player.GetJumpVelocity(self, input, velocity)
    end
end

function Skulk:OnGroundChanged(onGround)
    if not onGround then
        self.wallWalking = false
        self.wallWalkingEnabled = false
    end
end

function Skulk:GetBaseAttackSpeed()
    return kDefaultAttackSpeed
end

function Skulk:OnUpdateAnimationInput(modelMixin)

    PROFILE("Skulk:OnUpdateAnimationInput")
    
    Alien.OnUpdateAnimationInput(self, modelMixin)
    
    if self:GetIsLeaping() then
        modelMixin:SetAnimationInput("move", "leap")
    end
    
    modelMixin:SetAnimationInput("onwall", self:GetIsWallWalking() and not self:GetIsJumping())
end

local kSkulkEngageOffset = Vector(0, 0.5, 0)
function Skulk:GetEngagementPointOverride()
    return self:GetOrigin() + kSkulkEngageOffset
end

Shared.LinkClassToMap("Skulk", Skulk.kMapName, networkVars)