//Ladder movement code.

local kLadderAcceleration = 25
local kLadderFriction = 9
local kLadderMaxSpeed = 5

function CoreMoveMixin:UpdateLadderMove(input, velocity, deltaTime)

    if self:GetIsOnLadder() then
        
        // apply friction
        local newVelocity = SlerpVector(velocity, Vector(0,0,0), -velocity:GetLength() * deltaTime * kLadderFriction)
        VectorCopy(newVelocity, velocity)
    
        local wishDir = self:GetViewCoords():TransformVector(input.move)
        if wishDir.y ~= 0 then     
            wishDir.y = GetSign(wishDir.y)            
        end
        
        local currentSpeed = velocity:DotProduct(wishDir)
        local addSpeed = math.max(0, kLadderMaxSpeed - currentSpeed)
        if addSpeed > 0 then
        
            local accelSpeed = math.min(addSpeed, deltaTime * kLadderAcceleration)
            velocity:Add(accelSpeed * wishDir)
        
        end
    
    end

end