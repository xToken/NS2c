//Goldsource Movement Code

local kStopSpeedScalar = 2.5

//Wish Velocity
local function GetWishVelocity(self, input)

    PROFILE("CoreMoveMixin:GetWishVelocity")

    if self.OverrideWishVelocity then
        return self:OverrideWishVelocity(input)
    end

    local maxspeed = self:GetMaxSpeed()
    
    if input.move.z < 0 then
        maxspeed = maxspeed * self:GetMaxBackwardSpeedScalar()
    end

    // wishdir
    local move = GetNormalizedVector(input.move)
    move:Scale(maxspeed)
    
    // grab view angle (ignoring pitch)
    local angles = self:ConvertToViewAngles(0, input.yaw, 0)
    
    if self:GetPerformsVerticalMove() then
        angles = self:ConvertToViewAngles(input.pitch, input.yaw, 0)
    end
    
    local viewCoords = angles:GetCoords() // to matrix?
    local moveVelocity = viewCoords:TransformVector(move) // get world-space move direction
    
    return moveVelocity
	
end

function CoreMoveMixin:GetWishVelocity(input)
    return GetWishVelocity(self, input)
end

//Friction
function CoreMoveMixin:ApplyFriction(input, velocity, deltaTime)

    PROFILE("CoreMoveMixin:ApplyFriction")

    if self:GetIsOnGround() or self:GetIsOnLadder() then
	
        // Calculate speed
        local speed = velocity:GetLength()
        
        if speed < 0.0001 then
            return velocity
        end
        
        local friction = self:GetGroundFriction()
        if self:GetIsOnLadder() then
            friction = self:GetClimbFrictionForce()
        end
        
        local stopspeed = self:GetStopSpeed()
        
        // Try bleeding at accelerated value when no inputs
        if input.move.x == 0 and input.move.y == 0 and input.move.z == 0 then
            stopspeed = stopspeed * kStopSpeedScalar
        end


        // Bleed off some speed, but if we have less than the bleed
		//  threshhold, bleed the theshold amount.
        local control = (speed < stopspeed) and stopspeed or speed
        
        // Add the amount to the drop amount.
        local drop = control * friction * deltaTime
        
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
	
end

//Acceleration
function CoreMoveMixin:Accelerate(input, velocity, onGround, deltaTime)

    PROFILE("CoreMoveMixin:Accelerate")
	
	local acceleration = self:GetAcceleration(onGround)
	local wishdir = GetWishVelocity(self, input)
    local wishspeed = wishdir:Normalize()
	
	if not onGround and wishspeed > self:GetMaxAirVeer() then
        wishspeed = self:GetMaxAirVeer()
    end

    // Determine veer amount    
    local currentspeed = velocity:DotProduct(wishdir)
    
    // See how much to add
    local addSpeed = wishspeed - currentspeed

    // If not adding any, done.
    if addSpeed <= 0.0 then
        return velocity
    end
    
    // Determine acceleration speed after acceleration
    local accelspeed = acceleration * wishspeed * deltaTime
    
    // Cap it
    if accelspeed > addSpeed then
        accelspeed = addSpeed
    end
    
	// Add to velocity
    velocity:Add(wishdir * accelspeed)
    
    return velocity
	
end