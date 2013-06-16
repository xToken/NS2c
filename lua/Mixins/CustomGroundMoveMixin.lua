// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\GroundMoveMixin.lua
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/Mixins/BaseMoveMixin.lua")

CustomGroundMoveMixin = CreateMixin( CustomGroundMoveMixin )
CustomGroundMoveMixin.type = "GroundMove"

CustomGroundMoveMixin.expectedMixins =
{
    BaseMove = "Give basic method to handle player or entity movement"
}

CustomGroundMoveMixin.optionalCallbacks =
{
    PreUpdateMove = "Allows children to update state before the update happens.",
    PostUpdateMove = "Allows children to update state after the update happens.",
}

CustomGroundMoveMixin.networkVars =
{
    onGround = "private compensated boolean",
    timeLastOnGround = "private time",
    timeTouchedGround = "private time",
    jumpHandled = "private compensated boolean",
    timeOfLastJump = "private time",
    jumping = "private compensated boolean",
    onLadder = "boolean",
    crouching = "private compensated boolean",
    crouched = "private compensated boolean",
    timeOfCrouchChange = "compensated interpolated float (0 to 1 by 0.001)",
    crouchfraction = "compensated interpolated float (0 to 1 by 0.01)",
    lastimpact = "compensated interpolated float (0 to 1 by 0.001)",
}

local kNetPrecision = 1/128 // should import from server
local kMaxDeltaTime = 0.1
local kOnGroundDistance = 0.1
//NS1 bhop skulk could get around 530-540 units with good bhop, 290 base makes for 1.84 - Trying 1.8 for now
local kBunnyJumpMaxSpeedFactor = 1.8
local kClimbFriction = 5
local kCrouchAnimationTime = 0.4
local kCrouchSpeedScalar = 0.6
local kGroundFrictionTransition = 0.02
local kStopSpeed = 1.8 //NS1 appears to have used 100, roughly 1.8 @ 60.. Trying 3.6 for interim.
local kBackwardsMovementScalar = 1
local kStepHeight = 0.5

function CustomGroundMoveMixin:__initmixin()
    self.onGround = true
    self.timeLastOnGround = 0
    self.timeTouchedGround = 0
    self.onLadder = false
    self.jumping = false
    self.jumpHandled = false
    self.timeOfLastJump = 0
    self.crouching = false
    self.timeOfCrouchChange = 0
    self.crouched = false
    self.lastimpact = 0
end

//Basic Movement parameters - Max Speed, Air Veer, Friction etc.

function CustomGroundMoveMixin:GetClimbFrictionForce()
    return kClimbFriction
end

function CustomGroundMoveMixin:GetMaxBackwardSpeedScalar()
    return kBackwardsMovementScalar
end

function CustomGroundMoveMixin:GetStepHeight()
    return kStepHeight
end

function CustomGroundMoveMixin:GetStopSpeed()
    return kStopSpeed
end
 
function CustomGroundMoveMixin:GetCanStepOver(entity)
    return entity:isa("Egg")
end

function CustomGroundMoveMixin:GetLastInput()
    return self.latestinput
end

function CustomGroundMoveMixin:SetLastInput(input)
    self.latestinput = input
end

function CustomGroundMoveMixin:ReceivesFallDamage()
    return true
end

function CustomGroundMoveMixin:GetPlayJumpSound()
    return true
end

function CustomGroundMoveMixin:SetIsJumping(Jumping)
    self.jumping = Jumping
end

function CustomGroundMoveMixin:GetIsJumpHandled()
    return self.jumpHandled
end

function CustomGroundMoveMixin:SetIsJumpHandled(Jumped)
    self.jumpHandled = Jumped
end

function CustomGroundMoveMixin:GetMaxJumpingSpeedScalar()
    return kBunnyJumpMaxSpeedFactor
end

function CustomGroundMoveMixin:GetHasLandedThisFrame()
    return self.timeTouchedGround + kGroundFrictionTransition >= Shared.GetTime()
end

function CustomGroundMoveMixin:GetLastImpactForce()
    return self.lastimpact
end

function CustomGroundMoveMixin:SetIsOnGround(onGround)
    self.onGround = onGround
end

function CustomGroundMoveMixin:GetCrouchAmount()
    return self.crouchfraction
end

function CustomGroundMoveMixin:GetCrouching()
    return self.crouching
end

function CustomGroundMoveMixin:GetCrouched()
    return self.crouched
end

function CustomGroundMoveMixin:GetIsForwardOverrideDesired()
    return not self:GetIsOnGround()
end

function CustomGroundMoveMixin:GetCanStep()
    return true
end 

function CustomGroundMoveMixin:GetIsCloseToGround(distance)

    PROFILE("CustomGroundMoveMixin:GetIsCloseToGround")
        
    local onGround = false
    local normal = Vector()
    local completedMove, hitEntities = nil

    if self.controller ~= nil then
        // Try to move the controller downward a small amount to determine if
        // we're on the ground.
        local offset = Vector(0, -distance, 0)
        // need to do multiple slides here to not get traped in V shaped spaces
        completedMove, hitEntities, normal = self:PerformMovement(offset, 3, nil, false)
        
        if normal and normal.y >= 0.5 then
            return true
        end
    end

    return false
    
end

function CustomGroundMoveMixin:UpdateOnGroundState(previousVelocity)
    
    local onGround = false
    onGround = self:GetIsCloseToGround(self.GetDistanceToGround and self:GetDistanceToGround() or kOnGroundDistance)
    if onGround then
        self.timeLastOnGround = Shared.GetTime()
        if not self.onGround then
            self.timeTouchedGround = Shared.GetTime()
            self.lastimpact = math.min(math.abs(previousVelocity.y / 10), 1)
            self:UpdateJumpLand()
            self:UpdateFallDamage(previousVelocity)
        end
    end
    if onGround ~= self.onGround then
        self.onGround = onGround
    end
    
end

function CustomGroundMoveMixin:ApplyHalfGravity(input, velocity, time)
    if self.gravityEnabled and self:GetGravityAllowed() then
        velocity.y = velocity.y + self:GetGravityForce(input) * time * 0.5
    end
end

function CustomGroundMoveMixin:GetWishVelocity(input)
    if HasMixin(self, "Stun") and self:GetIsStunned() then
        return Vector(0,0,0)
    end
    
    // goldSrc maxspeed works different than ns2 maxspeed.
    // Here is it used as an acceleration target, in ns2
    // it's seemingly used for clamping the speed
    local maxspeed = self:GetMaxSpeed()
    
    if input.move.z < 0 then
        maxspeed = maxspeed * self:GetMaxBackwardSpeedScalar()
    end
    
    // Override forward input to allow greater ease of use if set.
    if not self.forwardModifier and input.move.z > 0 and input.move.x ~= 0 and self:GetIsForwardOverrideDesired() then
        input.move.z = 0
    end

    // wishdir
    local move = GetNormalizedVector(input.move)
    move:Scale(maxspeed)
    
    // grab view angle (ignoring pitch)
    local angles = self:ConvertToViewAngles(0, input.yaw, 0)
    
    if self:PerformsVerticalMove() then
        angles = self:ConvertToViewAngles(input.pitch, input.yaw, 0)
    end
    
    local viewCoords = angles:GetCoords() // to matrix?
    local moveVelocity = viewCoords:TransformVector(move) // get world-space move direction
    
    return moveVelocity
end

function CustomGroundMoveMixin:ApplyFriction(input, velocity, time)
    if self:GetIsOnSurface() or self:GetIsOnLadder() then
        // Calculate speed
        local speed = velocity:GetLength()
        
        if speed < 0.0001 or self:GetHasLandedThisFrame() then
            return velocity
        end
        
        local friction = self:GetGroundFriction()
        if self:GetIsOnLadder() then
            friction = self:GetClimbFrictionForce()
        end
        
        local stopspeed = self:GetStopSpeed()
        // Bleed off some speed, but if we have less than the bleed
		//  threshhold, bleed the theshold amount.
        local control = (speed < stopspeed) and stopspeed or speed
        
        // Add the amount to the drop amount.
        local drop = control * friction * time
        
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

function CustomGroundMoveMixin:UpdateJumpLand()

    // If we landed this frame
    if self.jumping then
        self.jumping = false
        if self.OnJumpLand then
            self:OnJumpLand(self:GetLastImpactForce())
        end
    end
    
end

function CustomGroundMoveMixin:UpdateFallDamage(previousVelocity)

    if self:ReceivesFallDamage() then
        if math.abs(previousVelocity.y) > kFallDamageMinimumVelocity then
            local damage = math.max(0, math.abs(previousVelocity.y * kFallDamageScalar) - 195)
            self:TakeDamage(damage, self, self, self:GetOrigin(), nil, 0, damage, kDamageType.Falling)
        end
    end
end

// Update origin and velocity from input.
function CustomGroundMoveMixin:UpdateMove(input)

    local runningPrediction = Shared.GetIsRunningPrediction()
    local previousVelocity = self:GetVelocity()
    local time = input.time
    // use the full precision origin
    if self.fullPrecisionOrigin then
        local orig = self:GetOrigin()
        local delta = orig:GetDistance(self.fullPrecisionOrigin)
        if delta < kNetPrecision then
            // Origin has lost some precision due to network rounding, use full precision
            self:SetOrigin(self.fullPrecisionOrigin);
        //else
            // the change must be due to an external event, so don't use the fullPrecision            
            //Log("%s: external origin change, %s -> %s (%s)", self, netPrec, orig, delta)
        end
    end
    
    self.prevOrigin = Vector(self:GetOrigin())
    
    if self.PreUpdateMove then
        self:PreUpdateMove(input, runningPrediction)
    end
    
    // Note: Using self:GetVelocity() anywhere else in the movement code may lead to buggy behavior.
    local velocity = self:GetVelocity()
    
    // If we were on ground at the end of last frame, zero out vertical velocity while
    // calling GetIsOnGround, as to not trip it into thinking you're in the air when moving
    // on curved surfaces
    if self:GetIsOnGround() then
        velocity.y = 0
    end
    
    local wishdir = self:GetWishVelocity(input)
    local wishspeed = wishdir:Normalize()
    
    // Modifiers
    self:HandleJump(input, velocity)
    self:UpdateCrouchState(input, time)
    
    // Apply first half of the gravity
    self:ApplyHalfGravity(input, velocity, time)
    
    // Run friction
    self:ApplyFriction(input, velocity, time)
    
    // Accelerate
    if self:GetIsOnSurface() then
        self:Accelerate(velocity, time, wishdir, wishspeed, self:GetAcceleration())
    else
        self:AirAccelerate(velocity, time, wishdir, wishspeed, self:GetAcceleration())
    end
    
    // Apply second half of the gravity
    self:ApplyHalfGravity(input, velocity, time)
 
    self:UpdatePosition(input, velocity, time)
    
    self:UpdateOnGroundState(previousVelocity)
    
    // Store new velocity
    self:SetVelocity(velocity)
    
    if self.PostUpdateMove then
        self:PostUpdateMove(input, runningPrediction)
    end
    
    self.fullPrecisionOrigin = Vector(self:GetOrigin())
    
end

//Movement Modifiers -Ladders, Jumping, Crouching etc.

function CustomGroundMoveMixin:SetIsOnLadder(onLadder, ladderEntity)
    self.onLadder = onLadder
end

function CustomGroundMoveMixin:GetIsOnLadder()
    return self.onLadder
end

function CustomGroundMoveMixin:PreventMegaBunnyJumping(velocity)
    local maxscaledspeed = self:GetMaxJumpingSpeedScalar() * self:GetMaxSpeed()
    
    if maxscaledspeed > 0.0 then
       local spd = velocity:GetLength()
        
        if spd > maxscaledspeed then
            local fraction = (maxscaledspeed / spd)
            velocity:Scale(fraction)
        end
    end
end

function CustomGroundMoveMixin:SplineFraction(value, scale)
    value = scale * value
    local valueSq = value * value
    
    // Nice little ease-in, ease-out spline-like curve
    return 3.0 * valueSq - 2.0 * valueSq * value
end

function CustomGroundMoveMixin:FinishDuck()
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

function CustomGroundMoveMixin:Duck(crouching, lastcrouching)
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
                    self:FinishDuck()
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
            
            if self:CanUnduck() then
                if self.crouched or self.crouching then
                    // Finish ducking immediately if duck time is over or not on ground
                    local time = 1.0 - self.timeOfCrouchChange
                    local animationtime = (kCrouchAnimationTime * 0.5)
                    if time > animationtime or not self:GetIsOnGround() then
                        self:FinishUnduck()
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

function CustomGroundMoveMixin:CanUnduck()
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

function CustomGroundMoveMixin:FinishUnduck()
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
end

function CustomGroundMoveMixin:UpdateCrouchState(input, time)
    self.timeOfCrouchChange = math.max(0, self.timeOfCrouchChange - time)
    local lastcrouch = false
    if self:GetLastInput() ~= nil then
        lastcrouch = bit.band(self:GetLastInput().commands, Move.Crouch) ~= 0
    end
    self:Duck(bit.band(input.commands, Move.Crouch) ~= 0, lastcrouch)
    self:SetLastInput(input)
end