//Core Vanilla NS2 movement code

local kFallAccel = 0.34
local kMaxAirAccel = 0.54
local kStopFriction = 6
local kSimpleStopSpeed = 4

//Ground state functions
local function CosFalloff(distanceFraction)
    local piFraction = Clamp(distanceFraction, 0, 1) * math.pi / 2
    return math.cos(piFraction + math.pi) + 1 
end

local function GetOnGroundFraction(self)

    PROFILE("CoreMoveMixin:GetOnGroundFraction")

    local transistionTime = self:GetGroundTransistionTime()
    local groundFraction = self:GetIsOnGround() and Clamp( (Shared.GetTime() - self.timeGroundTouched) / transistionTime, 0, 1) or 0
    groundFraction = CosFalloff(groundFraction)
    if self.ModifyGroundFraction then
        groundFraction = self:ModifyGroundFraction(groundFraction)
    end
    return groundFraction

end

function CoreMoveMixin:GetGroundFraction()
    return GetOnGroundFraction(self)
end

local function DoesStopMove(self, move, velocity)

    PROFILE("CoreMoveMixin:DoesStopMove")

    local wishDir = GetNormalizedVectorXZ(self:GetViewCoords().zAxis) * move.z    
    return wishDir:DotProduct(GetNormalizedVectorXZ(velocity)) < -0.8

end

local function GetFriction(self, input, velocity)

    PROFILE("CoreMoveMixin:GetFriction")

    local friction = GetNormalizedVector(-velocity)
    local velocityLength = 0
    local frictionScalar = 1
	local onGround = self:GetIsOnGround()
    
    if self:GetPerformsVerticalMove() or onGround then
        velocityLength = velocity:GetLength()
    else
        velocityLength = velocity:GetLengthXZ()
    end
    
    if not self:GetPerformsVerticalMove() and not onGround then
        friction.y = 0
    end

    local groundFriction = self:GetSimpleFriction(true)
    local airFriction = self:GetSimpleFriction(false)
    
    local onGroundFraction = GetOnGroundFraction(self)
    frictionScalar = velocityLength * (onGroundFraction * groundFriction + (1 - onGroundFraction) * airFriction)
    
    // use minimum friction when on ground
    if input.move:GetLength() == 0 and onGround and velocity:GetLength() < kSimpleStopSpeed then
        frictionScalar = math.max(kStopFriction, frictionScalar)
    end
    
    return friction * frictionScalar
    
end

function CoreMoveMixin:ApplySimpleFriction(input, velocity, deltaTime)

    PROFILE("CoreMoveMixin:ApplySimpleFriction")

    // Add in the friction force.
    // GetFrictionForce is an expected callback.
    local friction = GetFriction(self, input, velocity) * deltaTime

    // If the friction force will cancel out the velocity completely, then just
    // zero it out so that the velocity doesn't go "negative".
    if math.abs(friction.x) >= math.abs(velocity.x) then
        velocity.x = 0
    else
        velocity.x = friction.x + velocity.x
    end    
    if math.abs(friction.y) >= math.abs(velocity.y) then
        velocity.y = 0
    else
        velocity.y = friction.y + velocity.y
    end    
    if math.abs(friction.z) >= math.abs(velocity.z) then
        velocity.z = 0
    else
        velocity.z = friction.z + velocity.z
    end  

end

function CoreMoveMixin:AccelerateSimpleXZ(input, velocity, maxSpeedXZ, acceleration, deltaTime)

    PROFILE("CoreMoveMixin:AccelerateSimpleXZ")

    maxSpeedXZ = math.max(velocity:GetLengthXZ(), maxSpeedXZ)
    // do XZ acceleration
    
    local wishDir = self:GetViewCoords():TransformVector(input.move)
    wishDir.y = 0
    wishDir:Normalize()
    
    velocity:Add(wishDir * acceleration * deltaTime)
    
    if velocity:GetLengthXZ() > maxSpeedXZ then
    
        local yVel = velocity.y        
        velocity.y = 0
        velocity:Normalize()
        velocity:Scale(maxSpeedXZ)
        velocity.y = yVel
        
    end

end

local function GetWishDir(self, move, simpleAcceleration, velocity)

    PROFILE("CoreMoveMixin:GetWishDir")

    if simpleAcceleration == nil then
        simpleAcceleration = true
    end

    // don't punish people for using the forward key, help them
    if not simpleAcceleration and not self:GetIsOnGround() and move.z ~= 0 and not DoesStopMove(self, move, velocity) then
        
        if move.x ~= 0 then
            move.z = 0
        elseif velocity then
            
            local translateDirection = (-self:GetViewCoords().xAxis):DotProduct(GetNormalizedVectorXZ(velocity))
            local xMove = translateDirection == 0 and 1 or translateDirection / math.abs(translateDirection)
            local speedFraction = velocity:GetLengthXZ() / self:GetMaxSpeed()
            move.z = 0
            
            // normalize translate direction            
            // translate z move to x
            if math.abs(translateDirection) * speedFraction > 0.2 then            
                move.x = xMove
            end

        end
    
    end

    local wishDir = self:GetViewCoords():TransformVector(GetNormalizedVector(move))
  
    if not self:GetPerformsVerticalMove() then
    
        wishDir.y = 0
        wishDir:Normalize()

    end
    
    return wishDir

end

local function ForwardControl(self, deltaTime, velocity)

    PROFILE("CoreMoveMixin:ForwardControl")

    local airControl = self:GetAirControl() * 2

    if airControl > 0 then

        local wishDir = self:GetViewCoords().zAxis
        wishDir.y = 0
        wishDir:Normalize()
        
        //local dot = math.max(0, GetNormalizedVectorXZ(velocity):DotProduct(wishDir))
        local prevXZSpeed = velocity:GetLengthXZ()
        local prevY = velocity.y

        velocity:Add(wishDir * deltaTime * airControl)
        velocity.y = 0
        velocity:Normalize()
        velocity:Scale(prevXZSpeed)
        velocity.y = prevY
    
    end

end

//Max Speed functions.
local function ModifyMaxSpeed(self, maxSpeed, input)

    PROFILE("CoreMoveMixin:ModifyMaxSpeed")

	local backwardsSpeedScalar = 1
	
	if input and input.move.z == -1 then
	
		if input.move.x ~= 0 then
			backwardsSpeedScalar = self:GetMaxBackwardSpeedScalar() * 1.4
		else
			backwardsSpeedScalar = self:GetMaxBackwardSpeedScalar()
		end	
		
		backwardsSpeedScalar = Clamp(backwardsSpeedScalar, 0, 1)
	
	end
	
    return maxSpeed * backwardsSpeedScalar

end

function CoreMoveMixin:SimpleAccelerate(input, velocity, deltaTime)

    PROFILE("CoreMoveMixin:SimpleAccelerate")

    local wishDir = GetWishDir(self, input.move, false, velocity)
    local prevXZSpeed = velocity:GetLengthXZ()
    local currentDir = GetNormalizedVector(velocity)
    local onGround = self:GetIsOnGround()
    
    local maxSpeed = ModifyMaxSpeed(self, self:GetMaxSpeed(), input)
    
    local groundFraction = onGround and GetOnGroundFraction(self) or 0
    
    local wishSpeed = onGround and maxSpeed or self:GetMaxAirVeer()
    local currentSpeed = math.min(velocity:GetLength(), velocity:DotProduct(wishDir))
    local addSpeed = wishSpeed - currentSpeed
    
    local clampedAirSpeed = prevXZSpeed + deltaTime * kMaxAirAccel
    local clampSpeedXZ = math.max(onGround and maxSpeed or clampedAirSpeed, prevXZSpeed)
    
    if input.move.z == 1 and not onGround then
        ForwardControl(self, deltaTime, velocity)
    end
    
    if addSpeed > 0 then
         
        local accel = onGround and groundFraction * self:GetSimpleAcceleration(onGround) or self:GetAirControl()
        local accelSpeed = accel * deltaTime * wishSpeed
        
        accelSpeed = math.min(addSpeed, accelSpeed)    
        velocity:Add(wishDir * accelSpeed)
    
    end
    
    if not onGround then
    
        if not self.GetHasFallAccel or self:GetHasFallAccel() then
        
            wishDir.y = 0
            local fallAccel = math.max(-velocity.y, 0) * deltaTime * kFallAccel
            velocity:Add(GetNormalizedVectorXZ(velocity) * fallAccel)
            
        end
    
        if velocity:GetLengthXZ() > clampSpeedXZ then
        
            local prevY = velocity.y
            velocity.y = 0
            velocity:Normalize()            
            velocity:Scale(clampSpeedXZ)
            velocity.y = prevY
        
        end
    
    end

    if not onGround then
    
        local speedScalar = 1 - Clamp(velocity:GetLengthXZ() / maxSpeed, 0, 1) ^ 2
        self:AccelerateSimpleXZ(input, velocity, maxSpeed, self:GetSimpleAcceleration(false) * speedScalar, deltaTime)

    end
    
end
