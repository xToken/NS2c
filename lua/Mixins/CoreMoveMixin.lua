// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\Mixins\CoreMoveMixin.lua - Consolidated gldsrce style movement logic.
// - Dragon

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
    onGroundSurface = "enum kSurfaces",
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
local kLandGraceTime = 0.1
local kMaxAirVeer = 0.7
local kStopSpeed = 2
local kStepHeight = 0.5
local kMaxMoveTraces = 3
local kDownSlopeFactor = math.tan( math.rad(45) ) // Stick to ground on down slopes up to 45 degrees

//Load extra parts of this code.
//Segmented to keep the files more readable.
Script.Load("lua/Mixins/GoldSourceCoreMoveMixin.lua")
Script.Load("lua/Mixins/VanillaNS2CoreMoveMixin.lua")
Script.Load("lua/Mixins/JumpCoreMoveMixin.lua")
Script.Load("lua/Mixins/CrouchCoreMoveMixin.lua")
Script.Load("lua/Mixins/LadderCoreMoveMixin.lua")

function CoreMoveMixin:__initmixin()

    self.onGround = false
    self.onGroundSurface = kSurfaces.metal
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

function CoreMoveMixin:GetOnGroundSurface()
    //Temp cheaty fix
    local fixedOrigin = Vector(self:GetOrigin())
    fixedOrigin.y = fixedOrigin.y + self:GetExtents().y / 2
    local trace = Shared.TraceRay(fixedOrigin, fixedOrigin + Vector(0, -(2.5*self:GetExtents().y + .1), 0), CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOne(self))
    local material = trace.surface
    return StringToEnum(kSurfaces, material) or kSurfaces.metal
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

//Ground Detection.
local function GetIsCloseToGround(self, distance)
        
    PROFILE("CoreMoveMixin:GetIsCloseToGround")

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

function CoreMoveMixin:GetIsCloseToGround(distance)
    return GetIsCloseToGround(self, distance)
end

local function UpdateOnGroundState(self, velocity)

    PROFILE("CoreMoveMixin:UpdateOnGroundState")
    
    local onGround, normal, hitEntities, surfaceMaterial = GetIsCloseToGround(self, self.GetDistanceToGround and self:GetDistanceToGround() or kOnGroundDistance)
    
    if surfaceMaterial then
        self.onGroundSurface = StringToEnum(kSurfaces, surfaceMaterial) or kSurfaces.metal
    end
    
    if self.OverrideUpdateOnGround then
        onGround = self:OverrideUpdateOnGround(onGround)
    end
    
    if not onGround and onGround ~= self.onGround then
        self:SetIsOnGround(onGround)
    end
    
end

//Gravity.
local function ApplyHalfGravity(self, input, velocity, deltaTime)

    PROFILE("CoreMoveMixin:ApplyHalfGravity")
    
	local gravityTable = {gravity = self:GetGravityForce(input)}
	if self.ModifyGravityForce then
		self:ModifyGravityForce(gravityTable)
	end
	velocity.y = velocity.y + gravityTable.gravity * deltaTime * 0.5
		
end

//Step move for moving up stairs/small objects.
local function DoStepMove(self, input, velocity, deltaTime)

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

    PROFILE("CoreMoveMixin:FlushCollisionCallbacks")

    if not self.onGround and self.storedNormal then

        local onGround, normal, hitEntities, surfaceMaterial = GetIsCloseToGround(self, self.GetDistanceToGround and self:GetDistanceToGround() or kOnGroundDistance)
        
        if surfaceMaterial then
            self.onGroundSurface = StringToEnum(kSurfaces, surfaceMaterial) or kSurfaces.metal
        end
        
        if self.OverrideUpdateOnGround then
            onGround = self:OverrideUpdateOnGround(onGround)
        end

        if onGround then
            self:UpdatePlayerLanding(self.storedImpactForce, velocity)
            self:SetIsOnGround(onGround)
        end
        
        self.isOnEntity = onGround and hitEntities ~= nil and #hitEntities > 0
    
    end
    
    self.storedNormal = nil
    self.storedImpactForce = nil

end

//Updates the position of player that collides with world.
local function CollisionEnabledPositionUpdate(self, input, velocity, deltaTime)

    PROFILE("CoreMoveMixin:CollisionEnabledPositionUpdate")

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

//Callback from when colliding with world.
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

function CoreMoveMixin:PreUpdateMove(input, runningPrediction)

    if self.fullPrecisionOrigin then
        local orig = self:GetOrigin()
        local delta = orig:GetDistance(self.fullPrecisionOrigin)
        if delta < kNetPrecision then
            // Origin has lost some precision due to network rounding, use full precision
            self:SetOrigin(self.fullPrecisionOrigin)
        else
            // the change must be due to an external event, so don't use the fullPrecision            
            //Shared.Message(string.format("%s: external origin change, %s -> %s (%s)", self:GetName(), kNetPrecision, orig, delta))
        end
    end
    
    self.prevOrigin = Vector(self:GetOrigin())

end

// Update origin and velocity from input.
function CoreMoveMixin:UpdateMove(input, runningPrediction)

    local deltaTime = input.time //math.min(input.time, kMaxDeltaTime)

    // Note: Using self:GetVelocity() anywhere else in the movement code may lead to buggy behavior.
    local velocity = Vector(self:GetVelocity())
    
    // Modifiers
    // Need to think about the positioning of these calls, its more important than initially apparent..
    // The initial OnGround check here can only account for the player leaving the ground.  Unless something horribly went wrong with the last calculations
    // the cases where you would be airborne at the end of the last move and on the ground now are statiscally extremely unlikely.  This is needed however 
    // to account for changes which would have you leave the ground.  Modifiers are applied before any gravity or friction, which does allow complete
    // bypass of any ground friction by repeated jumping.
  
    UpdateOnGroundState(self, velocity)
    
    self:HandleJump(input, velocity)
    self:UpdateCrouchState(input, deltaTime)
    
    // Apply first half of the gravity
    ApplyHalfGravity(self, input, velocity, deltaTime)
       
    if self:GetUsesGoldSourceMovement() and self:HasAdvancedMovement() then
        self:ApplyFriction(input, velocity, deltaTime)
        self:Accelerate(input, velocity, self.onGround, deltaTime)
    else
        self:ApplySimpleFriction(input, velocity, deltaTime)
        self:SimpleAccelerate(input, velocity, deltaTime)
    end
    
    // Apply second half of the gravity
    ApplyHalfGravity(self, input, velocity, deltaTime)
    
    self:ModifyVelocity(input, velocity, deltaTime)
    self:UpdateLadderMove(input, velocity, deltaTime)
    
    // Clamp AirMove Speed
    if not self:GetIsOnGround() then
        self:PreventMegaBunnyJumping(false, velocity)
    end
    
    UpdatePosition(self, input, velocity, deltaTime)    
   
    // Store new velocity
    self:SetVelocity(velocity)
    
end

function CoreMoveMixin:PostUpdateMove(input, runningPrediction)

    self.fullPrecisionOrigin = Vector(self:GetOrigin())
    self:SetLastInput(input)
    
end