// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Fade.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Role: Surgical striker, harassment
//
// The Fade should be a fragile, deadly-sharp knife. Wielded properly, it's force is undeniable. But
// used clumsily or without care will only hurt the user. Make sure Fade isn't better than the Skulk 
// in every way (notably, vs. Structures). To harass, he must be able to stay out in the field
// without continually healing at base, and needs to be able to use blink often.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/SwipeBlink.lua")
Script.Load("lua/Weapons/Alien/Metabolize.lua")
Script.Load("lua/Weapons/Alien/AcidRocket.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/DissolveMixin.lua")

class 'Fade' (Alien)

Fade.kMapName = "fade"

Fade.kModelName = PrecacheAsset("models/alien/fade/fade.model")
Fade.kViewModelName = PrecacheAsset("models/alien/fade/fade_view.model")
local kFadeAnimationGraph = PrecacheAsset("models/alien/fade/fade.animation_graph")

Shared.PrecacheSurfaceShader("models/alien/fade/fade.surface_shader")

Fade.kViewOffsetHeight = 1.7
Fade.XZExtents = .4
Fade.YExtents = 1.05
Fade.kHealth = kFadeHealth
Fade.kArmor = kFadeArmor
Fade.kMass = 158 // ~350 pounds
Fade.kJumpHeight = 1.4
Fade.kMaxSpeed = 7.0
Fade.kWalkSpeed = 4
Fade.kMaxBlinkSpeed = 20
Fade.kAcceleration = 52
Fade.kBlinkAcceleration = 72
Fade.kBlinkFriction = 3.5
Fade.kAirAccelerationFraction = .8

Fade.kAirZMoveWeight = 1
Fade.kAirStrafeWeight = 3
Fade.kAirBrakeWeight = 0.1

if Server then
    Script.Load("lua/Fade_Server.lua")
elseif Client then    
    Script.Load("lua/Fade_Client.lua")
end

local networkVars =
{
    hasDoubleJumped = "private compensated boolean",     
    landedAfterBlink = "compensated boolean",    
    
    etherealStartTime = "private time",
    etherealEndTime = "private time",
    
    // True when we're moving quickly "through the ether"
    ethereal = "boolean",
    
}

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)

function Fade:OnCreate()

    InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, GroundMoveMixin)
    InitMixin(self, CameraHolderMixin, { kFov = kFadeFov })
    
    Alien.OnCreate(self)
    
    InitMixin(self, DissolveMixin)

    if Server then
        self.isBlinking = false
        self.hasDoubleJumped = false
        self.landedAfterBlink = false
    end
    
    self.etherealStartTime = 0
    self.etherealEndTime = 0
    self.ethereal = false

end

function Fade:AdjustGravityForce(input, gravity)
    
    if self:GetIsBlinking() or not self.landedAfterBlink then
        gravity = gravity * .75
    end
    
    return gravity
      
end

function Fade:OnInitialized()

    Alien.OnInitialized(self)
    
    self:SetModel(Fade.kModelName, kFadeAnimationGraph)
    
    if Client then
        self.blinkDissolve = 0
    end    

end

function Fade:OnDestroy()

    Alien.OnDestroy(self)

    if Client then    
        self:DestroyTrailCinematic()    
    end

end

function Fade:GetHeadAttachpointName()
    return "fade_tongue2"
end

// prevents reseting of celerity
function Fade:OnSecondaryAttack()
end

function Fade:PreCopyPlayerData()

    // Reset visibility and gravity in case we were in ether mode.
    self:SetIsVisible(true)
    self:SetGravityEnabled(true)

end

function Fade:GetBaseArmor()
    return Fade.kArmor
end

function Fade:GetArmorFullyUpgradedAmount()
    return kFadeArmorFullyUpgradedAmount
end

function Fade:GetMaxViewOffsetHeight()
    return Fade.kViewOffsetHeight
end

function Fade:GetViewModelName()
    return Fade.kViewModelName
end

function Fade:OnJumpLand(landIntensity, slowDown)

    Alien.OnJumpLand(self, landIntensity, slowDown)
    
    self.hasDoubleJumped = false
    self.landedAfterBlink = true
    
end

function Fade:OnJump()

    if not self:GetIsOnGround() then
        self.hasDoubleJumped = true
    end
    
end

function Fade:PerformsVerticalMove()
    return self:GetIsBlinking()
end

function Fade:GetIsAffectedByAirFriction()
    return self:GetIsBlinking() or not self:GetIsOnGround()
end

function Fade:GetGroundFrictionForce()
    return 7.5
end  

function Fade:GetCanJump()
    return (Alien.GetCanJump(self) or not self.hasDoubleJumped)
end

function Fade:ConstrainMoveVelocity(moveVelocity)
    
    if not self:GetIsBlinking() then
        // allow acceleration in air for fades
        if not self:GetIsOnSurface() then
            local speedFraction = Clamp(self:GetVelocity():GetLengthXZ() / self:GetMaxSpeed(), 0, 1)
            speedFraction = 1 - (speedFraction * speedFraction)
            moveVelocity:Scale(speedFraction * Fade.kAirAccelerationFraction)
        end
    end
    
end

function Fade:GetIsOnGround()

    if self:GetIsBlinking() then
        return false
    end
    
    return Alien.GetIsOnGround(self)
    
end

function Fade:GetAirFrictionForce(input, velocity)

    if self:GetIsBlinking() then
        return Fade.kBlinkFriction
    end

    return 0.35
    
end

local kBlinkTraceOffset = Vector(0, 0.5, 0)
function Fade:GetMoveDirection(moveVelocity)

    if self:GetIsBlinking() then
        
        local direction = GetNormalizedVector(moveVelocity)
        
        // check if we attempt to blink into the ground
        // TODO: get rid of this hack here once UpdatePosition is adjusted for blink
        if direction.y < 0 then
        
            local trace = Shared.TraceRay(self:GetOrigin() + kBlinkTraceOffset, self:GetOrigin() + kBlinkTraceOffset + direction * 1.7, CollisionRep.Move, PhysicsMask.Movement, EntityFilterAll())
            if trace.fraction ~= 1 then
                direction.y = 0.1
            end
            
        end
        
        return direction
        
    end

    return Alien.GetMoveDirection(self, moveVelocity)    

end

function Fade:GetAcceleration()
    
    if self:GetIsBlinking() then
        return Fade.kBlinkAcceleration * self:GetMovementSpeedModifier()
    end

    return Fade.kAcceleration * self:GetMovementSpeedModifier() * ( 1 - self:GetCrouchAmount() * Player.kCrouchSpeedScalar )

end

function Fade:GetMaxSpeed(possible)

    if possible then
        return Fade.kMaxSpeed
    end
    
    //Walking
    local maxSpeed = ConditionalValue(self.movementModiferState and self:GetIsOnSurface(), Fade.kWalkSpeed, Fade.kMaxSpeed)
    
    if self:GetIsBlinking() or self:GetIsOnSurface() then
        maxSpeed = Fade.kMaxBlinkSpeed
    end
    
    // Take into account crouching
    return ( 1 - self:GetCrouchAmount() * Player.kCrouchSpeedScalar ) * maxSpeed * self:GetMovementSpeedModifier()

end

function Fade:GetMass()
    return Fade.kMass 
end

function Fade:GetJumpHeight()
    return Fade.kJumpHeight
end

function Fade:GetIsBlinking()
    return self.ethereal and self:GetIsAlive()
end

function Fade:GetRecentlyBlinked(player)
    return Shared.GetTime() - self.etherealEndTime < Blink.kMinEnterEtherealTime
end

function Fade:GetRecentlyJumped()
    return self.timeOfLastJump ~= nil and self.timeOfLastJump + 0.15 > Shared.GetTime()
end

function Fade:OverrideInput(input)

    Player.OverrideInput(self, input)
    
    if self:GetIsBlinking() then
        input.move.z = 1
        input.move.x = 0
    end
    
    return input
    
end

function Fade:OnProcessMove(input)

    Alien.OnProcessMove(self, input)

    if Server then
    
    end
    
end

// for update position
function Fade:GetCanStep()
    return self:GetIsBlinking() or Alien.GetCanStep(self)
end

function Fade:OnScan()

    if Server then

    end

end

function Fade:GetStepHeight()
    return Player.GetStepHeight() 
end

function Fade:GetGravityAllowed()
    return not self:GetIsBlinking()
end

function Fade:UpdatePosition(velocity, time)

    // TODO: update position in a smarter way when blinking: move player in desired direction, if failed  try to step over the object (default step, Y = 0 or positive), if failed try under the object (Y = 0 or negative)

    PROFILE("Fade:UpdatePosition")

    if self:GetIsBlinking() then

        if not self.controller then
            return velocity
        end
        
        SetSpeedDebugText("vertical velocity %s", ToString(velocity.y))
        
        // We need to make a copy so that we aren't holding onto a reference
        // which is updated when the origin changes.
        local start         = Vector(self:GetOrigin())
        local startVelocity = Vector(velocity)
        
        local maxSlideMoves = 3
        
        local offset     = nil
        local stepHeight = self:GetStepHeight()
        local canStep    = self:GetCanStep()
        local onGround   = self:GetIsOnGround()
        local stepped    = false
        
        local completedMove = self:PerformMovement( velocity * time, maxSlideMoves, velocity )
        
        if not completedMove and canStep then
        
            // Go back to the beginning and now try a step move.
            self:SetOrigin(start)
            
            // First move the character upwards to allow them to go up stairs and over small obstacles. 
            self:PerformMovement( Vector(0, stepHeight, 0), 1 )
            local steppedStart = self:GetOrigin()
            
            if self:GetIsColliding() then
            
                // Moving up didn't allow us to go over anything, so move back
                // to the start position so we don't get stuck in an elevated position
                // due to not being able to move back down.
                self:SetOrigin(start)
                offset = Vector(0, 0, 0)
                
            else
            
                offset = steppedStart - start
                
                // Now try moving the controller the desired distance.
                VectorCopy( startVelocity, velocity )
                self:PerformMovement( startVelocity * time, maxSlideMoves, velocity )
                stepped = true
                
            end
            
        else
            offset = Vector(0, 0, 0)
        end
        
        if canStep then
        
            // Finally, move the player back down to compensate for moving them up.
            // We add in an additional step  height for moving down steps/ramps.
            if stepped then        
                offset.y = -(offset.y + stepHeight)
            end
            self:PerformMovement( offset, 1, nil )
            
            // Check to see if we moved up a step and need to smooth out
            // the movement.
            local yDelta = self:GetOrigin().y - start.y
            
            if yDelta ~= 0 then
            
                // If we're already interpolating up a step, we need to take that into account
                // so that we continue that interpolation, plus our new step interpolation
                
                local deltaTime      = Shared.GetTime() - self.stepStartTime
                local prevStepAmount = 0
                
                if deltaTime < Player.stepTotalTime then
                    prevStepAmount = self.stepAmount * (1 - deltaTime / Player.stepTotalTime)
                end        
                
                self.stepStartTime = Shared.GetTime()
                self.stepAmount    = Clamp(yDelta + prevStepAmount, -Player.kMaxStepAmount, Player.kMaxStepAmount)
                
            end
            
        end
        
        return velocity
    
    else
        return Alien.UpdatePosition(self, velocity, time)
    end
    
end

function Fade:TriggerBlink()
    self.ethereal = true
    self.onGroundNeedsUpdate = false
    self.jumping = true
    self.landedAfterBlink = false
end

function Fade:OnBlinkEnd()
    if self:GetIsCloseToGround(0.3) then
        self.jumping = false
    end
    self.onGroundNeedsUpdate = true
    self.ethereal = false
end

function Fade:ModifyVelocity(input, velocity)

    Alien.ModifyVelocity(self, input, velocity)

    if not self:GetIsOnGround() and not self:GetIsBlinking() and input.move:GetLength() ~= 0 then
    
        local moveLengthXZ = velocity:GetLengthXZ()
        local previousY = velocity.y
        local adjustedZ = false

        if input.move.z ~= 0 then
        
            local redirectedVelocityZ = GetNormalizedVectorXZ(self:GetViewCoords().zAxis) * input.move.z
            
            if input.move.z < 0 then
            
                redirectedVelocityZ = GetNormalizedVectorXZ(velocity)
                redirectedVelocityZ:Normalize()
                
                local xzVelocity = Vector(velocity)
                xzVelocity.y = 0
                
                VectorCopy(velocity - (xzVelocity * input.time * Fade.kAirBrakeWeight), velocity)
                
            else
            
                redirectedVelocityZ = redirectedVelocityZ * input.time * Fade.kAirZMoveWeight + GetNormalizedVectorXZ(velocity)
                redirectedVelocityZ:Normalize()                
                redirectedVelocityZ:Scale(moveLengthXZ)
                redirectedVelocityZ.y = previousY
                VectorCopy(redirectedVelocityZ,  velocity)
                adjustedZ = true
            
            end
        
        end
    
        if input.move.x ~= 0  then
    
            local redirectedVelocityX = GetNormalizedVectorXZ(self:GetViewCoords().xAxis) * input.move.x
        
            if adjustedZ then
                redirectedVelocityX = redirectedVelocityX * input.time * Fade.kAirStrafeWeight + GetNormalizedVectorXZ(velocity)
            else
                redirectedVelocityX = redirectedVelocityX * input.time * 2 + GetNormalizedVectorXZ(velocity)
            end
            
            redirectedVelocityX:Normalize()            
            redirectedVelocityX:Scale(moveLengthXZ)
            redirectedVelocityX.y = previousY
            VectorCopy(redirectedVelocityX,  velocity)
            
        end    
    
    end
    
end

function Fade:GetSurfaceOverride()

    if self:GetIsBlinking() then
        return "ethereal"
    end
    
    return "organic"
    
end

local kFadeEngageOffset = Vector(0, 0.6, 0)
function Fade:GetEngagementPointOverride()
    return self:GetOrigin() + kFadeEngageOffset
end

function Fade:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.8, 0)
end

Shared.LinkClassToMap("Fade", Fade.kMapName, networkVars)