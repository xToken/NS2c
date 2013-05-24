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

CustomGroundMoveMixin.expectedCallbacks =
{
    GoldSrc_GetWishVelocity = "Should return the wanted velocity from player input",
    GoldSrc_Accelerate = "Should add the acceleration component to the passed velocity",
    GoldSrc_Friction = "Should add (subtract?) the friction component to the passed velocity",
    GetGravityAllowed = "Should return true if gravity should take effect.",
    ModifyVelocity = "Should modify the passed in velocity based on the input and whatever other conditions are needed.",
    UpdatePosition = "Should update the position based on the velocity and time passed in. Should return a velocity."
}

CustomGroundMoveMixin.optionalCallbacks =
{
    PreUpdateMove = "Allows children to update state before the update happens.",
    OnClampSpeed = "Allows children to clamp speed (sucks 2 add this just for marine backpedalling.",
    PostUpdateMove = "Allows children to update state after the update happens.",
}

function CustomGroundMoveMixin:__initmixin()
end
/*
// round the new value to network precision, rounding towards the old value
local function RoundToNetwork(v)
    local qMul = 128 // need to get this from the server
    return math.floor(qMul * v + 0.5) / qMul
end

local function RoundToNetworkVec(vec)
    vec.x = RoundToNetwork(vec.x)
    vec.y = RoundToNetwork(vec.y)
    vec.z = RoundToNetwork(vec.z)
    return vec
end
*/
local kNetPrecision = 1/128 // should import from server

function CustomGroundMoveMixin:ApplyHalfGravity(input, velocity)
    if self.gravityEnabled and self:GetGravityAllowed() then
        velocity.y = velocity.y + self:GetGravityForce(input) * input.time * 0.5
    end
end

// Update origin and velocity from input.
function CustomGroundMoveMixin:UpdateMove(input)
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

    local runningPrediction = Shared.GetIsRunningPrediction()
    
    if self.PreUpdateMove then
        self:PreUpdateMove(input, runningPrediction)
    end
    
    // Note: Using self:GetVelocity() anywhere else in the movement code may lead to buggy behavior.
    local velocity = self:GetVelocity()
    
    // If we were on ground at the end of last frame, zero out vertical velocity while
    // calling GetIsOnGround, as to not trip it into thinking you're in the air when moving
    // on curved surfaces
    local oldOnGround = self.onGround
    if oldOnGround then
        local oldvelocity = velocity.y
        velocity.y = 0
        self:GetIsOnSurface()
        velocity.y = oldvelocity
    end
    
    local wishdir = self:GoldSrc_GetWishVelocity(input)
    local wishspeed = wishdir:Normalize()
    
    // Take into account crouching
    if self:GetCanCrouch() and self:GetCrouched() and self:GetIsOnGround() then
        wishspeed = self:GetCrouchSpeedScalar() * wishspeed
    end
    
    // Jump
    self:ModifyVelocity(input, velocity)
    
    // Apply first half of the gravity
    self:ApplyHalfGravity(input, velocity)
    
    // Run friction
    self:GoldSrc_Friction(input, velocity)
    
    // Accelerate
    if self:GetIsOnSurface() then
        self:GoldSrc_Accelerate(velocity, input.time, wishdir, wishspeed, self:GoldSrc_GetAcceleration())
    else
        self:GoldSrc_AirAccelerate(velocity, input.time, wishdir, wishspeed, self:GoldSrc_GetAcceleration())
    end
    
    // Apply first half of the gravity
    self:ApplyHalfGravity(input, velocity)
    
    velocity = self:UpdatePosition(velocity, input.time, input.move)
    
    if self.OnClampSpeed then
        self:OnClampSpeed(input, velocity)
    end

    // Store new velocity
    self:SetVelocity(velocity)
    
    if self.PostUpdateMove then
        self:PostUpdateMove(input, runningPrediction)
    end
    
    self.fullPrecisionOrigin = Vector(self:GetOrigin())
    
end