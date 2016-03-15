// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\Mixins\NS1GroundMoveMixin.lua - Consolidated gldsrce style movement logic.
// - Dragon

local kMaxDeltaTime = 0.07
local kOnGroundDistance = 0.05
local kMaxAirVeer = 1.2
local kStopSpeed = 2
local kStopSpeedScalar = 2.5
local kMaxMoveTraces = 3
local kStepHeight = 0.5
local kAirGroundTransistionTime = 0.2
local kMaxSpeedClampPerJump = 1.5
local kBunnyJumpMaxSpeedFactor = 1.7
local kAirSpeedMultipler = 3.0
local kDownSlopeFactor = math.tan( math.rad(45) ) // Stick to ground on down slopes up to 45 degrees

//Property Accessors.
function GroundMoveMixin:GetNS1StopSpeed()
    return kStopSpeed
end

function GroundMoveMixin:GetNS1MaxAirVeer()
    return kMaxAirVeer
end

//Ground Detection.
local function GetIsCloseToGround(self, distance)
        
    PROFILE("GroundMoveMixin:GetIsCloseToGround")

    local onGround = false
    local normal = Vector()
    local completedMove, hitEntities, surfaceMaterial
    
    if self.controller == nil then
    
        onGround = true
    
    else
    
        // Try to move the controller downward a small amount to determine if
        // we're on the ground.
        local offset = Vector(0, -distance, 0)
        // need to do multiple slides here to not get traped in V shaped spaces
        completedMove, hitEntities, normal, surfaceMaterial = self:PerformMovement(offset, kMaxMoveTraces, nil, false)
        
        if normal and normal.y >= 0.5 then
            onGround = true
        end
    
    end
    
    return onGround, normal, hitEntities, surfaceMaterial
    
end

local function UpdateOnGroundState(self, velocity)

    PROFILE("GroundMoveMixin:UpdateOnGroundState")
    
    local onGround, normal, hitEntities, surfaceMaterial = GetIsCloseToGround(self, self.GetDistanceToGround and self:GetDistanceToGround() or kOnGroundDistance)
    
    if surfaceMaterial then
        self.onGroundSurface = StringToEnum(kSurfaces, surfaceMaterial) or kSurfaces.metal
    end
    
    if self.OverrideUpdateOnGround then
        onGround = self:OverrideUpdateOnGround(onGround)
    end
    
    if not onGround and onGround ~= self.onGround then
        self.onGround = false
    end
    
end

//Wish Velocity
local function GetWishVelocity(self, input)

    PROFILE("GroundMoveMixin:GetWishVelocity")

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

//Friction
local function ApplyFriction(self, input, velocity, deltaTime)

    PROFILE("GroundMoveMixin:ApplyFriction")

    if self:GetIsOnGround() or self:GetIsOnLadder() then
	
        // Calculate speed
        local speed = velocity:GetLength()
        
        if speed < 0.0001 then
            return velocity
        end
        
        local friction = self:GetNS1GroundFriction()
        if self:GetIsOnLadder() then
            friction = self:GetClimbFrictionForce()
        end
        
        local stopspeed = self:GetNS1StopSpeed()
        
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
local function Accelerate(self, input, velocity, onGround, deltaTime)

    PROFILE("GroundMoveMixin:Accelerate")
	
	local acceleration = self:GetNS1Acceleration(onGround)
	local wishdir = GetWishVelocity(self, input)
    local wishspeed = wishdir:Normalize()
	
	if not onGround and wishspeed > self:GetNS1MaxAirVeer() then
        wishspeed = self:GetNS1MaxAirVeer()
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

//Gravity.
local function ApplyHalfGravity(self, input, velocity, deltaTime)

    PROFILE("GroundMoveMixin:ApplyHalfGravity")
    
	local gravityTable = {gravity = self:GetGravityForce(input)}
	if self.ModifyGravityForce then
		self:ModifyGravityForce(gravityTable)
	end
	velocity.y = velocity.y + gravityTable.gravity * deltaTime * 0.5
		
end

//Prevent overspeed
function GroundMoveMixin:PreventMegaBunnyJumping(onJump, velocity)

    PROFILE("GroundMoveMixin:PreventMegaBunnyJumping")

    local maxscaledspeed = kBunnyJumpMaxSpeedFactor * self:GetMaxSpeed()
    
	if not onJump then
		maxscaledspeed = kAirSpeedMultipler * self:GetMaxSpeed()
	end
	
    if maxscaledspeed > 0.0 then
		local velY = velocity.y
		local spd = velocity:GetLengthXZ()
        if spd > maxscaledspeed then
            local fraction = (maxscaledspeed / (maxscaledspeed + Clamp(spd - maxscaledspeed, 0, kMaxSpeedClampPerJump)))
            velocity:Scale(fraction)
        end
		velocity.y = velY
    end
    
end

//Step move for moving up stairs/small objects.
local function DoStepMove(self, input, velocity, deltaTime)

    PROFILE("GroundMoveMixin:DoStepMove")
    
    local oldOrigin = Vector(self:GetOrigin())
    local oldVelocity = Vector(velocity)
    local success = false
    local stepAmount = 0
    local slowDownFraction = self.GetCollisionSlowdownFraction and self:GetCollisionSlowdownFraction() or 1
    local deflectMove = self.GetDeflectMove and self:GetDeflectMove() or false
    
    // step up at first
    self:PerformMovement(Vector(0, kStepHeight, 0), 1)
    stepAmount = self:GetOrigin().y - oldOrigin.y
    
    // do the normal move
    local startOrigin = Vector(self:GetOrigin())
    local completedMove, hitEntities, averageSurfaceNormal = self:PerformMovement(velocity * deltaTime, kMaxMoveTraces, velocity, true, slowDownFraction, deflectMove)
    local horizMoveAmount = (startOrigin - self:GetOrigin()):GetLengthXZ()
    
    if completedMove then
        // step down again
        completedMove, hitEntities, averageSurfaceNormal = self:PerformMovement(Vector(0, -stepAmount - horizMoveAmount * kDownSlopeFactor, 0), 1)
        
        if averageSurfaceNormal and averageSurfaceNormal.y >= 0.5 then
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
        self:PerformMovement(velocity * deltaTime, kMaxMoveTraces, velocity, true, slowDownFraction, deflectMove)
        
    end

    return success

end

//Handles any stored normals from collisions with world during move.
local function FlushCollisionCallbacks(self, velocity)

    PROFILE("GroundMoveMixin:FlushCollisionCallbacks")

    if not self.onGround and self.storedNormal then

        local onGround, normal, hitEntities, surfaceMaterial = GetIsCloseToGround(self, 0.15)
        
        if surfaceMaterial then
            self.onGroundSurface = StringToEnum(kSurfaces, surfaceMaterial) or kSurfaces.metal
        end
    
        if self.OverrideUpdateOnGround then
            onGround = self:OverrideUpdateOnGround(onGround)
        end

        if onGround then
        
            self.onGround = true
            
            // dont transistion for only short in air durations
            if self.timeGroundTouched + kAirGroundTransistionTime <= Shared.GetTime() then
                self.timeGroundTouched = Shared.GetTime()
            end

            if self.OnGroundChanged then
                self:OnGroundChanged(self.onGround, self.storedImpactForce, normal, velocity)
            end
            
        end
    
    end
    
    self.storedNormal = nil
    self.storedImpactForce = nil

end

//Updates the position of player that collides with world.
local function CollisionEnabledPositionUpdate(self, input, velocity, deltaTime)

    PROFILE("GroundMoveMixin:CollisionEnabledPositionUpdate")

    local oldVelocity = Vector(velocity)
    local stepAllowed = self:GetIsOnGround() and self:GetCanStep()
    local didStep = false
    local stepAmount = 0
    local hitObstacle = false

    // check if we are allowed to step:
    local completedMove, hitEntities, averageSurfaceNormal = self:PerformMovement(velocity * deltaTime * 2, 1, nil, false)

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
        
        self:PerformMovement(velocity * deltaTime, kMaxMoveTraces, velocity, true, slowDownFraction * 0.5, deflectMove)
        
    else
    
        didStep, stepAmount = DoStepMove(self, input, velocity, deltaTime)
        
    end
    
    FlushCollisionCallbacks(self, velocity)
    
    if self.OnPositionUpdated then
        self:OnPositionUpdated(self:GetOrigin() - self.prevOrigin, stepAllowed, input, velocity)
    end
    
end

local function UpdatePosition(self, input, velocity, deltaTime)
    
    if self.controller then
		CollisionEnabledPositionUpdate(self, input, velocity, deltaTime)        
    end
    
end

// Update origin and velocity from input.
function GroundMoveMixin:UpdateNS1Move(input, runningPrediction)

    local deltaTime = input.time //math.min(input.time, kMaxDeltaTime)
    local velocity = Vector(self:GetVelocity())
    
    UpdateOnGroundState(self, velocity)
    
    // Apply first half of the gravity
    ApplyHalfGravity(self, input, velocity, deltaTime)
       
    ApplyFriction(self, input, velocity, deltaTime)
    Accelerate(self, input, velocity, self.onGround, deltaTime)
    
    // Apply second half of the gravity
    ApplyHalfGravity(self, input, velocity, deltaTime)
    
    self:ModifyVelocity(input, velocity, deltaTime)
    
    // Clamp AirMove Speed
    if not self:GetIsOnGround() then
        self:PreventMegaBunnyJumping(false, velocity)
    end
    
    UpdatePosition(self, input, velocity, deltaTime)    
   
    // Store new velocity
    self:SetVelocity(velocity)
    
end