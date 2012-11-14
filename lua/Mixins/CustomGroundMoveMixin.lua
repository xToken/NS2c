// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\GroundMoveMixin.lua
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")

CustomGroundMoveMixin = CreateMixin( CustomGroundMoveMixin )
CustomGroundMoveMixin.type = "GroundMove"

CustomGroundMoveMixin.expectedMixins =
{
    BaseMove = "Give basic method to handle player or entity movement"
}

CustomGroundMoveMixin.expectedCallbacks =
{
    GoldSrc_Accelerate = "Should return a forward velocity.",
    GoldSrc_Friction = "Should return the friction force based on the input and velocity passed in.",
    GetGravityAllowed = "Should return true if gravity should take effect.",
    ModifyVelocity = "Should modify the passed in velocity based on the input and whatever other conditions are needed.",
    UpdatePosition = "Should update the position based on the velocity and time passed in. Should return a velocity."
}

CustomGroundMoveMixin.optionalCallbacks =
{
    PreUpdateMove = "Allows children to update state before the update happens.",
    PostUpdateMove = "Allows children to update state after the update happens.",
    OnClampSpeed = "The passed in velocity is clamped to min or max speeds based on the input passed in."
}

function CustomGroundMoveMixin:__initmixin()
end

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

local kNetPrecision = 1/128 // should import from server

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
    
    local velocity = self:GetVelocity()
    
    // Jump
    self:ModifyVelocity(input, velocity)
    
    if self:GetIsOnGround() then
        //velocity.y = 0.0
    end
    if self.gravityEnabled and self:GetGravityAllowed() then
        // Update velocity with gravity after we update our position (it accounts for gravity and varying frame rates)
        velocity.y = velocity.y + self:GetGravityForce(input) * input.time * 0.5
    end
    
    self:GoldSrc_Friction(input, velocity)
    
    if self:GetIsOnGround() then
        //velocity.y = 0.0
    end
    
    // Don't factor in forward velocity if stunned.
    if not HasMixin(self, "Stun") or not self:GetIsStunned() then
        self:GoldSrc_Accelerate(input, velocity)
    end
    
    if self:GetIsOnGround() then
        //velocity.y = 0.0
    end
    if self.gravityEnabled and self:GetGravityAllowed() then
        // Update velocity with gravity after we update our position (it accounts for gravity and varying frame rates)
        velocity.y = velocity.y + self:GetGravityForce(input) * input.time * 0.5
    end
    
    velocity = self:UpdatePosition(velocity, input.time, input.move)
        
    self:SetVelocity(velocity)
    
    if self.PostUpdateMove then
        self:PostUpdateMove(input, runningPrediction)
    end
    
    self.fullPrecisionOrigin = Vector(self:GetOrigin())
    
end
AddFunctionContract(CustomGroundMoveMixin.UpdateMove, { Arguments = { "Entity", "Move" }, Returns = { } })