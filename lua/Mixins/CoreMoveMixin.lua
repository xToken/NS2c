//    
// lua\CoreMoveMixin.lua
// Consolidated gldsrce style movement logic.

Script.Load("lua/Mixins/BaseMoveMixin.lua")

CoreMoveMixin = CreateMixin( CoreMoveMixin )
CoreMoveMixin.type = "CoreMoveMixin"

CoreMoveMixin.expectedMixins =
{
    BaseMove = "Give basic method to handle player or entity movement"
}

CoreMoveMixin.expectedCallbacks =
{
    GetMaxSpeed = "Returns MaxSpeed of moveable entity.",
	GetAcceleration = "Gets the acceleration amount for this entity.",
    GetSimpleAcceleration = "Gets the acceleration amount for this entity - for Vanilla NS2 movement.",
    GetAirControl = "Air control value - for Vanilla NS2 movement.",
    GetGroundTransistionTime = "Ground easing transition - for Vanilla NS2 movement.",
    GetSimpleFriction = "Air friction for simple movement - for Vanilla NS2 movement.",
	GetGroundFriction = "Gets the base ground friction applied to entity.",
	GetCanJump = "If entity is able to jump.",
	GetJumpVelocity = "Gets the jumping velocity increase for this entity.",
	GetPerformsVerticalMove = "If pitch should be considered when calculating velocity.",
	GetCrouchShrinkAmount = "Amount the entity shrinks when crouching.",
    GetCrouchTime = "Time taken for this entity to fully crouch.",
	GetCanCrouch = "If the entity can crouch.",
	GetSlowOnLand = "If the entity should be slowed on land.",
	GetClimbFrictionForce = "Friction when climbing ladder.",
	GetMaxBackwardSpeedScalar = "Maximum backpeddling speed scalar.",
	GetUsesGoldSourceMovement = "If entity can optionally use goldsource movement.",
	OnTakeFallDamage = "For taking applicable fall damage."
}

CoreMoveMixin.optionalCallbacks =
{
    PreUpdateMove = "Allows children to update state before the update happens.",
	ModifyVelocity = "Allows children to update state after new velocity is calculated, but before position is updated.",
	OnPositionUpdated = "Allows children to update state after new position is calculated.",
    PostUpdateMove = "Allows children to update state after the update happens.",
	OverrideUpdateOnGround = "Allows children to override onGround status.",
	ModifyGroundFraction = "Allows children to modify ground fraction - for Vanilla NS2 movement.",
	GetDistanceToGround = "Allows children to override ground distance check.",
	OnGroundChanged = "Allows children to update on a ground state change.",
	ModifyGravityForce = "Allows children to adjust the force of gravity.",
	OverrideWishVelocity = "Allows children to override wishvelocity.",
	OverrideJump = "Allows children to override jump handling.",
	OnJump = "Allows children to update state after a jump."
}

CoreMoveMixin.networkVars =
{
    onGround = "compensated boolean",
    isOnEntity = "private compensated boolean",
    timeGroundTouched = "private time",
    jumpHandled = "private compensated boolean",
    timeOfLastJump = "private time",
    jumping = "compensated boolean",
    onLadder = "compensated boolean",
    crouching = "compensated boolean",
    timeOfCrouchChange = "time"
}

local kNetPrecision = 1/128
local kMaxDeltaTime = 0.07
local kOnGroundDistance = 0.05
local kMaxSpeedClampPerJump = 1.5
local kBunnyJumpMaxSpeedFactor = 1.7
local kAirSpeedMultipler = 3.0
local kMaxAirVeer = 0.7
local kSlowOnLandScalar = 0.33
local kLandGraceTime = 0.1
local kMinimumJumpTime = 0.02
local kStopSpeed = 2
local kStopSpeedScalar = 2.5
local kStepHeight = 0.5
local kMaxMoveTraces = 3
local kDownSlopeFactor = math.tan( math.rad(45) ) // Stick to ground on down slopes up to 45 degrees
local kFallAccel = 0.34
local kMaxAirAccel = 0.54
local kStopFriction = 6
local kSimpleStopSpeed = 4
local kForwardMove = Vector(0, 0, 1)

function CoreMoveMixin:__initmixin()

    self.onGround = false
    self.isOnEntity = false
    self.timeGroundTouched = 0
    self.onLadder = false
    self.jumping = false
    self.jumpHandled = false
    self.timeOfLastJump = 0
    self.crouching = false
    self.timeOfCrouchChange = 0
    self.lastimpact = 0
    
end

//Property Accessors.

function CoreMoveMixin:GetStepHeight()
    return kStepHeight
end

function CoreMoveMixin:GetStopSpeed()
    return kStopSpeed
end
 
function CoreMoveMixin:GetCanStepOver(entity)
    return false
end

function CoreMoveMixin:GetCanStep()
    return true
end

function CoreMoveMixin:GetLastInput()
    return self.latestinput
end

function CoreMoveMixin:SetLastInput(input)
    self.latestinput = input
end

function CoreMoveMixin:GetIsJumping()
    return self.jumping
end

function CoreMoveMixin:SetIsJumping(Jumping)
    self.jumping = Jumping
end

function CoreMoveMixin:GetIsJumpHandled()
    return self.jumpHandled
end

function CoreMoveMixin:SetIsJumpHandled(Jumped)
    self.jumpHandled = Jumped
end

function CoreMoveMixin:GetLandedRecently()
    return self.timeGroundTouched + kLandGraceTime > Shared.GetTime()
end

function CoreMoveMixin:GetIsOnGround()
    return self.onGround
end

function CoreMoveMixin:GetLastJumpTime()
    return self.timeOfLastJump
end

function CoreMoveMixin:UpdateLastJumpTime()
    self.timeOfLastJump = Shared.GetTime()
end

function CoreMoveMixin:GetLastImpactForce()
    return self.lastimpact
end

function CoreMoveMixin:SetIsOnGround(onGround)
    self.onGround = onGround
    if self.OnGroundChanged then
        self:OnGroundChanged(onGround)
    end
end

function CoreMoveMixin:GetMaxAirVeer()
    return kMaxAirVeer
end

function CoreMoveMixin:GetCrouching()
    return self.crouching
end

function CoreMoveMixin:GetIsOnLadder()
    return self.onLadder
end

function CoreMoveMixin:GetIsOnEntity()
    return self.isOnEntity == true
end

function CoreMoveMixin:SetIsOnLadder(onLadder, ladderEntity)
    self.onLadder = onLadder
end

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

local function GetIsCloseToGround(self, distance)
        
    PROFILE("CoreMoveMixin:GetIsCloseToGround")

    local onGround = false
    local normal = Vector()
    local completedMove, hitEntities = nil
    
    if self.controller == nil then
    
        onGround = true
    
    else
    
        // Try to move the controller downward a small amount to determine if
        // we're on the ground.
        local offset = Vector(0, -distance, 0)
        // need to do multiple slides here to not get traped in V shaped spaces
        completedMove, hitEntities, normal = self:PerformMovement(offset, kMaxMoveTraces, nil, false)
        
        if normal and normal.y >= 0.5 then
            onGround = true
        end
    
    end
    
    return onGround, normal, hitEntities
    
end

function CoreMoveMixin:GetIsCloseToGround(distance)
    return GetIsCloseToGround(self, distance)
end

local function UpdateJumpLand(self, impactForce, velocity)

    PROFILE("CoreMoveMixin:UpdateJumpLand")

    // If we landed this frame
    if self.jumping then
        self.jumping = false
        if self.OnJumpLand then
            self:OnJumpLand(impactForce)
        end
        if self:GetSlowOnLand(impactForce) then
            self:AddSlowScalar(kSlowOnLandScalar)
            velocity:Scale(kSlowOnLandScalar)
        end
    end
    
end

local function UpdateFallDamage(self, impactForce)
    
    PROFILE("CoreMoveMixin:UpdateFallDamage")

	if math.abs(impactForce) > kFallDamageMinimumVelocity then
		local damage = math.max(0, math.abs(impactForce * kFallDamageScalar) - kFallDamageMinimumVelocity * kFallDamageScalar)
		self:OnTakeFallDamage(damage)
	end
		
end

local function UpdatePlayerLanding(self, impactForce, velocity)
    // dont transistion for only short in air durations
    if self.timeGroundTouched + self:GetGroundTransistionTime() <= Shared.GetTime() then
        self.timeGroundTouched = Shared.GetTime()
    end
    //Shared.Message("Time airborn " .. (self.timeGroundTouched - self:GetLastJumpTime()) .. ".")
    self.lastimpact = impactForce
    UpdateJumpLand(self, impactForce, velocity)
    UpdateFallDamage(self, impactForce)
end

local function UpdateOnGroundState(self, velocity)

    PROFILE("CoreMoveMixin:UpdateOnGroundState")
    
    local onGround, normal, hitEntities = GetIsCloseToGround(self, self.GetDistanceToGround and self:GetDistanceToGround() or kOnGroundDistance)
    
    if self.OverrideUpdateOnGround then
        onGround = self:OverrideUpdateOnGround(onGround)
    end
    
    if not onGround and onGround ~= self.onGround then
        self:SetIsOnGround(onGround)
    end
    
end

//Max Speed functions.
function CoreMoveMixin:ModifyMaxSpeed(maxSpeedTable, input)

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
	
    maxSpeedTable.maxSpeed = maxSpeedTable.maxSpeed * backwardsSpeedScalar

end

//Gravity
local function ApplyHalfGravity(self, input, velocity, time)

    PROFILE("CoreMoveMixin:ApplyHalfGravity")
    
	local gravityTable = {gravity = self:GetGravityForce(input)}
	if self.ModifyGravityForce then
		self:ModifyGravityForce(gravityTable)
	end
	velocity.y = velocity.y + gravityTable.gravity * time * 0.5
		
end

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

local function DoesStopMove(self, move, velocity)

    PROFILE("CoreMoveMixin:DoesStopMove")

    local wishDir = GetNormalizedVectorXZ(self:GetViewCoords().zAxis) * move.z    
    return wishDir:DotProduct(GetNormalizedVectorXZ(velocity)) < -0.8

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

function CoreMoveMixin:GetWishVelocity(input)
    return GetWishVelocity(self, input)
end

//Friction
local function ApplyFriction(self, input, velocity, time)

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
	
end

function CoreMoveMixin:GetFriction(input, velocity)

    PROFILE("CoreMoveMixin:GetFriction")

    local friction = GetNormalizedVector(-velocity)
    local velocityLength = 0
    local frictionScalar = 1
    
    if self:GetPerformsVerticalMove() or self:GetIsOnGround() then
        velocityLength = velocity:GetLength()
    else
        velocityLength = velocity:GetLengthXZ()
    end
    
    if not self:GetPerformsVerticalMove() and not self:GetIsOnGround() then
        friction.y = 0
    end

    local groundFriction = self:GetSimpleFriction(true)
    local airFriction = self:GetSimpleFriction(false)
    
    local onGroundFraction = GetOnGroundFraction(self)
    frictionScalar = velocityLength * (onGroundFraction * groundFriction + (1 - onGroundFraction) * airFriction)
    
    // use minimum friction when on ground
    if input.move:GetLength() == 0 and self:GetIsOnGround() and velocity:GetLength() < kSimpleStopSpeed then
        frictionScalar = math.max(kStopFriction, frictionScalar)
    end
    
    return friction * frictionScalar
    
end

local function ApplySimpleFriction(self, input, velocity, deltaTime)

    PROFILE("CoreMoveMixin:ApplySimpleFriction")

    // Add in the friction force.
    // GetFrictionForce is an expected callback.
    local friction = self:GetFriction(input, velocity) * deltaTime

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

//Acceleration
local function Accelerate(self, velocity, time, wishdir, wishspeed, acceleration)

    PROFILE("CoreMoveMixin:Accelerate")

    // Determine veer amount    
    local currentspeed = velocity:DotProduct(wishdir)
    
    // See how much to add
    local addSpeed = wishspeed - currentspeed

    // If not adding any, done.
    if addSpeed <= 0.0 then
        return velocity
    end
    
    // Determine acceleration speed after acceleration
    local accelspeed = acceleration * wishspeed * time
    
    // Cap it
    if accelspeed > addSpeed then
        accelspeed = addSpeed
    end
    
    wishdir:Scale(accelspeed)
    
    // Add to velocity
    velocity:Add(wishdir)
    
    return velocity
end

local function AirAccelerate(self, velocity, time, wishdir, wishspeed, acceleration)

    PROFILE("CoreMoveMixin:AirAccelerate")
    
    //Clamp veer
    if wishspeed > self:GetMaxAirVeer() then
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
    local accelspeed = acceleration * wishspeed * time
    
    // Cap it
    if accelspeed > addSpeed then
        accelspeed = addSpeed
    end
    
    // Add to velocity
    velocity:Add(wishdir * accelspeed)
    
    return velocity
end

local function AccelerateSimpleXZ(self, input, velocity, maxSpeedXZ, acceleration, deltaTime)

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

local function SimpleAccelerate(self, input, velocity, deltaTime)

    PROFILE("CoreMoveMixin:SimpleAccelerate")

    local wishDir = GetWishDir(self, input.move, false, velocity)
    local prevXZSpeed = velocity:GetLengthXZ()
    local currentDir = GetNormalizedVector(velocity)
    local onGround = self:GetIsOnGround()
    
    local maxSpeedTable = { maxSpeed = self:GetMaxSpeed() }
    self:ModifyMaxSpeed(maxSpeedTable, input)
    
    local groundFraction = onGround and GetOnGroundFraction(self) or 0
    
    local wishSpeed = onGround and maxSpeedTable.maxSpeed or self:GetMaxAirVeer()
    local currentSpeed = math.min(velocity:GetLength(), velocity:DotProduct(wishDir))
    local addSpeed = wishSpeed - currentSpeed
    
    local clampedAirSpeed = prevXZSpeed + deltaTime * kMaxAirAccel
    local clampSpeedXZ = math.max(onGround and maxSpeedTable.maxSpeed or clampedAirSpeed, prevXZSpeed)
    
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
    
        local speedScalar = 1 - Clamp(velocity:GetLengthXZ() / maxSpeedTable.maxSpeed, 0, 1) ^ 2
        AccelerateSimpleXZ(self, input, velocity, maxSpeedTable.maxSpeed, self:GetSimpleAcceleration(false) * speedScalar, deltaTime)

    end
    
end

local function DoStepMove(self, input, velocity, time)

    PROFILE("CoreMoveMixin:DoStepMove")
    
    local oldOrigin = Vector(self:GetOrigin())
    local oldVelocity = Vector(velocity)
    local success = false
    local stepAmount = 0
    local slowDownFraction = self.GetCollisionSlowdownFraction and self:GetCollisionSlowdownFraction() or 1
    local deflectMove = self.GetDeflectMove and self:GetDeflectMove() or false
    
    // step up at first
    self:PerformMovement(Vector(0, self:GetStepHeight(), 0), 1)
    stepAmount = self:GetOrigin().y - oldOrigin.y
    
    // do the normal move
    local startOrigin = Vector(self:GetOrigin())
    local completedMove, hitEntities, averageSurfaceNormal = self:PerformMovement(velocity * time, kMaxMoveTraces, velocity, true, slowDownFraction, deflectMove)
    local horizMoveAmount = (startOrigin - self:GetOrigin()):GetLengthXZ()
    
    if completedMove then
        // step down again
        local completedMove2, hitEntities2, averageSurfaceNormal2 = self:PerformMovement(Vector(0, -stepAmount - horizMoveAmount * kDownSlopeFactor, 0), 1)
        
        if averageSurfaceNormal2 and averageSurfaceNormal2.y >= 0.5 then
            success = true
        else
            
            local onGround = GetIsCloseToGround(self, self.GetDistanceToGround and self:GetDistanceToGround() or kOnGroundDistance)
            
            if onGround then
                success = true
            end
            
        end
        
    end    
        
    // not succesful. fall back to normal move
    if not success then
    
        self:SetOrigin(oldOrigin)
        VectorCopy(oldVelocity, velocity)
        self:PerformMovement(velocity * time, kMaxMoveTraces, velocity, true, slowDownFraction, deflectMove)
        
    end

    return success

end

local function FlushCollisionCallbacks(self, velocity)

    PROFILE("CoreMoveMixin:FlushCollisionCallbacks")

    if not self.onGround and self.storedNormal then

        local onGround, normal, hitEntities = GetIsCloseToGround(self, self.GetDistanceToGround and self:GetDistanceToGround() or kOnGroundDistance)
        
        if self.OverrideUpdateOnGround then
            onGround = self:OverrideUpdateOnGround(onGround)
        end

        if onGround then
            UpdatePlayerLanding(self, self.storedImpactForce, velocity)
            self:SetIsOnGround(onGround)
        end
        
        self.isOnEntity = onGround and hitEntities ~= nil and #hitEntities > 0
    
    end
    
    self.storedNormal = nil
    self.storedImpactForce = nil

end

local function CollisionEnabledPositionUpdate(self, input, velocity, time)

    PROFILE("CoreMoveMixin:CollisionEnabledPositionUpdate")

    local oldVelocity = Vector(velocity)
    local stepAllowed = self:GetIsOnGround() and self:GetCanStep()
    local didStep = false
    local stepAmount = 0
    local hitObstacle = false

    // check if we are allowed to step:
    local completedMove, hitEntities, averageSurfaceNormal = self:PerformMovement(velocity * time * 2, 1, nil, false)

    if stepAllowed and hitEntities then
    
        for i = 1, #hitEntities do
            if not self:GetCanStepOver(hitEntities[i]) then
            
                hitObstacle = true
                stepAllowed = false
                break
                
            end
        end
    
    end
    
    if not stepAllowed then
    
        local slowDownFraction = self.GetCollisionSlowdownFraction and self:GetCollisionSlowdownFraction() or 1 
            
        local deflectMove = self.GetDeflectMove and self:GetDeflectMove() or false
    
        if hitObstacle then
            velocity.y = oldVelocity.y
        end
        
        self:PerformMovement(velocity * time, kMaxMoveTraces, velocity, true, slowDownFraction * 0.5, deflectMove)
        
    else
    
        didStep, stepAmount = DoStepMove(self, input, velocity, time)
        
    end
    
    FlushCollisionCallbacks(self, velocity)
    
    if self.OnPositionUpdated then
        self:OnPositionUpdated(self:GetOrigin() - self.prevOrigin, stepAllowed, input, velocity)
    end
    
end

local function UpdatePosition(self, input, velocity, time)
    
    if self.controller then
		CollisionEnabledPositionUpdate(self, input, velocity, time)        
    end
    
end

local function GetSign(number)
    return number >= 0 and 1 or -1    
end

function CoreMoveMixin:OnWorldCollision(normal, impactForce)

    PROFILE("CoreMoveMixin:OnWorldCollision")

    if normal then

        if not self.storedNormal then
            self.storedNormal = normal
        else
            self.storedNormal:Add(normal)
            self.storedNormal:Normalize()
        end
    
    end
    
    if impactForce then
    
        if not self.storedImpactForce then
            self.storedImpactForce = impactForce
        else
            self.storedImpactForce = (self.storedImpactForce + impactForce) * 0.5
        end
        
    end
    
end

//Movement Modifiers -Ladders, Jumping, Crouching etc.
local function PreventMegaBunnyJumping(self, onground, velocity)

    PROFILE("CoreMoveMixin:PreventMegaBunnyJumping")

    local maxscaledspeed = kBunnyJumpMaxSpeedFactor * self:GetMaxSpeed()
    
	if not onground then
		maxscaledspeed = kAirSpeedMultipler * self:GetMaxSpeed()
	end
	
    if maxscaledspeed > 0.0 then
       local spd = velocity:GetLength()
        
        if spd > maxscaledspeed then
            local fraction = (maxscaledspeed / (maxscaledspeed + Clamp(spd - maxscaledspeed, 0, kMaxSpeedClampPerJump)))
            velocity:Scale(fraction)
        end
    end
    
end

local function HandleJump(self, input, velocity)

    PROFILE("CoreMoveMixin:HandleJump")

    if bit.band(input.commands, Move.Jump) ~= 0 and not self:GetIsJumpHandled() then
    
        if self:GetCanJump(self) then
            
            if self:GetUsesGoldSourceMovement() and self:HasAdvancedMovement() then
                PreventMegaBunnyJumping(self, true, velocity)
            end
            
            self:GetJumpVelocity(input, velocity)
            
            self:SetIsOnGround(false)
            self:SetIsJumping(true)
            
            if self.OnJump then
                self:OnJump()
            end
            
            self:UpdateLastJumpTime()
            
            if self:GetJumpMode() == kJumpMode.Repeating then
                self:SetIsJumpHandled(false)
            else
                self:SetIsJumpHandled(true)
            end
            
        elseif self:GetJumpMode() == kJumpMode.Default then
        
            self:SetIsJumpHandled(true)
            
        end
        
    end
    
end

local function UpdateCrouchState(self, input, time)

    PROFILE("CoreMoveMixin:UpdateCrouchState")

	local crouchDesired = bit.band(input.commands, Move.Crouch) ~= 0	
    if crouchDesired == self.crouching then
		//If enough time has passed, clear time.
		if self.timeOfCrouchChange > 0 and self.timeOfCrouchChange + self:GetCrouchTime() < Shared.GetTime() then
			self.timeOfCrouchChange = 0
		end
        return
    end
   
    if not crouchDesired then
        
        // Check if there is room for us to stand up.
        self.crouching = crouchDesired
        self:UpdateControllerFromEntity()
        
        if self:GetIsColliding() then
            self.crouching = true
            self:UpdateControllerFromEntity()
        else
            self.timeOfCrouchChange = Shared.GetTime()
        end
        
    elseif self:GetCanCrouch() then
        self.crouching = crouchDesired
        self.timeOfCrouchChange = Shared.GetTime()
        self:UpdateControllerFromEntity()
    end
    
end

local function SplineFraction(value, scale)
    value = scale * value
    local valueSq = value * value
    
    // Nice little ease-in, ease-out spline-like curve
    return 3.0 * valueSq - 2.0 * valueSq * value
end

function CoreMoveMixin:GetCrouchAmount()

    PROFILE("CoreMoveMixin:GetCrouchAmount")

    local crouchScalar = ConditionalValue(self.crouching, 1, 0)
    if self.lastcrouchamountcalc == Shared.GetTime() then
        return self.lastcrouchamount
    end
    if self.timeOfCrouchChange > 0 then
        local crouchspeed = self:GetCrouchTime()
        if crouchspeed > 0 then
            local crouchtime = Shared.GetTime() - self.timeOfCrouchChange
            if(self.crouching) then
                crouchScalar = SplineFraction(crouchtime / crouchspeed, 1.0)
            else
                if crouchtime >= (crouchspeed * 0.5) then
                    crouchScalar = 0
                else
                    crouchScalar = SplineFraction(1.0 - (crouchtime / (crouchspeed * 0.5)), 1.0)
                end
            end
        end
    end
    self.lastcrouchamountcalc = Shared.GetTime()
    self.lastcrouchamount = crouchScalar
    return crouchScalar
    
end

local function CheckFullPrecisionOrigin(self)
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
end

local function UpdateFullPrecisionOrigin(self)
    self.fullPrecisionOrigin = Vector(self:GetOrigin())
end

// Update origin and velocity from input.
function CoreMoveMixin:UpdateMove(input)

    local runningPrediction = Shared.GetIsRunningPrediction()
    local time = input.time //math.min(input.time, kMaxDeltaTime)
    
    CheckFullPrecisionOrigin(self)    
    
    if self.PreUpdateMove then
        self:PreUpdateMove(input, runningPrediction)
    end
    
    // If we were on ground at the end of last frame, zero out vertical velocity while
    // calling GetIsOnGround, as to not trip it into thinking you're in the air when moving
    // on curved surfaces
    /*if self:GetIsOnGround() then
        velocity.y = 0
    end*/
    
    // Note: Using self:GetVelocity() anywhere else in the movement code may lead to buggy behavior.
    local velocity = Vector(self:GetVelocity())
    local wishdir = GetWishVelocity(self, input)
    local wishspeed = wishdir:Normalize()
    
    // Modifiers
    // Need to think about the positioning of these calls, its more important than instantly apparent..
    // Having OnGround check right here allows you to never have ground friction run, which WOULD make jumping transitions smoother in theory..
    // But there are tradeoffs - half a frame of gravity would be applied for anything that modifies your onground state IE Blinking.
    // I think here is better in the end.
    
    UpdateOnGroundState(self, velocity)
    
    HandleJump(self, input, velocity)
    UpdateCrouchState(self, input, time)
    
    // Apply first half of the gravity
    ApplyHalfGravity(self, input, velocity, time)
       
    if self:GetUsesGoldSourceMovement() and self:HasAdvancedMovement() then
    
        // Run friction
        ApplyFriction(self, input, velocity, time)
        
        // Accelerate        
        if self:GetIsOnGround() then
            Accelerate(self, velocity, time, wishdir, wishspeed, self:GetAcceleration(true))
        else
            AirAccelerate(self, velocity, time, wishdir, wishspeed, self:GetAcceleration(false))
        end
        
    else
    
        ApplySimpleFriction(self, input, velocity, time)
        SimpleAccelerate(self, input, velocity, time)
        
    end
    
    // Apply second half of the gravity
    ApplyHalfGravity(self, input, velocity, time)
    
    self:ModifyVelocity(input, velocity, time)
    
    // Clamp AirMove Speed
    if not self:GetIsOnGround() then
        PreventMegaBunnyJumping(self, false, velocity)
    end
    
    UpdatePosition(self, input, velocity, time)    
   
    // Store new velocity
    self:SetVelocity(velocity)
    
    if self.PostUpdateMove then
        self:PostUpdateMove(input, runningPrediction)
    end
	
    self:SetLastInput(input)
    UpdateFullPrecisionOrigin(self)
    
end