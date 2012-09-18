// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Lerk.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
//    Modified by: James Gu (twiliteblue) on 5 Aug 2011
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Weapons/Alien/LerkBite.lua")
Script.Load("lua/Weapons/Alien/LerkUmbra.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/WallMovementMixin.lua")
Script.Load("lua/DissolveMixin.lua")

class 'Lerk' (Alien)

Lerk.kMapName = "lerk"

if Client then
    Script.Load("lua/Lerk_Client.lua")
elseif Server then
    Script.Load("lua/Lerk_Server.lua")
end

Lerk.kModelName = PrecacheAsset("models/alien/lerk/lerk.model")
local kViewModelName = PrecacheAsset("models/alien/lerk/lerk_view.model")
local kLerkAnimationGraph = PrecacheAsset("models/alien/lerk/lerk.animation_graph")

Shared.PrecacheSurfaceShader("models/alien/lerk/lerk.surface_shader")

local networkVars =
{
    flappedSinceLeftGround  = "boolean",
    gliding = "boolean",
    
    lastTimeFlapped = "compensated time",
    
    // Wall grip. time == 0 no grip, > 0 when grip started.
    wallGripTime = "private compensated time",
    // the normal that the model will use. Calculated the same way as the skulk
    wallGripNormalGoal = "private compensated vector",
    // if we have done our wall normal recheck (when we stop sliding)
    wallGripRecheckDone = "private compensated boolean",
    // if wallChecking is enabled. Means that the next time you press use
    wallGripCheckEnabled = "private compensated boolean",
    
    prevInputMove = "private boolean"
}

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)

// if the user hits a wall and holds the use key and the resulting speed is < this, grip starts
Lerk.kWallGripMaxSpeed = 4
// once you press grip, you will slide for this long a time and then stop. This is also the time you
// have to release your movement keys, after this window of time, pressing movement keys will release the grip.
Lerk.kWallGripSlideTime = 0.7
// after landing, the y-axis of the model will be adjusted to the wallGripNormal after this time.
Lerk.kWallGripSmoothTime = 0.6

// how to grab for stuff ... same as the skulk tight-in code
Lerk.kWallGripRange = 0.2
Lerk.kWallGripFeelerSize = 0.25

local kViewOffsetHeight = 0.5
Lerk.XZExtents = 0.4
Lerk.YExtents = 0.4
local kJumpImpulse = 4
local kFlapStraightUpImpulse = 4.7
local kFlapThrustMoveScalar = 6.3
// ~120 pounds
Lerk.kLerkFlapEnergyCost = 3
local kMass = 54
local kJumpHeight = 1.5
local kSwoopGravityScalar = -25.0
local kRegularGravityScalar = -7
local kFlightGravityScalar = -4
// Lerks walk slowly to encourage flight
local kMaxWalkSpeed = 2.8
local kMaxSpeed = 12
local kAirAcceleration = 2.7
local flying2DSound = PrecacheAsset("sound/NS2.fev/alien/lerk/flying")
local flying3DSound = PrecacheAsset("sound/NS2.fev/alien/lerk/flying")
local kDefaultAttackSpeed = 1.65

function Lerk:OnCreate()

    InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, GroundMoveMixin)
    InitMixin(self, CameraHolderMixin, { kFov = kLerkFov })
    InitMixin(self, WallMovementMixin)
    
    Alien.OnCreate(self)
    
    InitMixin(self, DissolveMixin)
    
    self.prevInputMove = false
    self.flappedSinceLeftGround = false
    self.gliding = false
    self.lastTimeFlapped = 0
    
    self.wallGripTime = 0
    self.wallGripRecheckDone = false
    self.wallGripCheckEnabled = false
    
    if Client then   
    
        self.flySound = CreateLoopingSoundForEntity(self, flying2DSound, nil)
        
        if self.flySound then
        
            self.flySound:Start()
            self.flySound:SetParameter("speed", 0, 10)
            
        end
        
    end
    
end

function Lerk:OnInitialized()

    Alien.OnInitialized(self)
    
    self:SetModel(Lerk.kModelName, kLerkAnimationGraph)
    
    if Client then
    
        self.currentCameraRoll = 0
        self.goalCameraRoll = 0
        self.previousYaw = 0
        
        self:AddHelpWidget("GUILerkFlapHelp", 2)
        
    end
    
end

function Lerk:OnDestroy()

    Alien.OnDestroy(self)
    
    if Client then
    
        if self.flySound then
        
            Client.DestroySoundEffect(self.flySound)
            self.flySound = nil
        
        end    
    
    end
    
end 

function Lerk:GetAngleSmoothRate()
    return 6
end

function Lerk:GetCanClimb()
    return true
end

function Lerk:GetRollSmoothRate()
    return 3
end    

local kMaxGlideRoll = math.rad(60)

function Lerk:GetDesiredAngles()

    if self:GetIsWallGripping() then
        return self:GetAnglesFromWallNormal(self.wallGripNormalGoal, 1)
    end

    local desiredAngles = Alien.GetDesiredAngles(self)
    /*
    if not self:GetIsOnGround() then
        desiredAngles.pitch = self.viewPitch
    end    
    */
    if not self:GetIsOnSurface() then    
        desiredAngles.roll = Clamp( RadianDiff( self:GetAngles().yaw, self.viewYaw ), -kMaxGlideRoll, kMaxGlideRoll)    
    end
    
    return desiredAngles

end

function Lerk:GetSmoothAngles()
    return not self:GetIsWallGripping()
end

function Lerk:GetBaseArmor()
    return kLerkArmor
end

function Lerk:GetArmorFullyUpgradedAmount()
    return kLerkArmorFullyUpgradedAmount
end

function Lerk:GetMaxViewOffsetHeight()
    return kViewOffsetHeight
end

function Lerk:GetCrouchShrinkAmount()
    return 0
end

function Lerk:GetExtentsCrouchShrinkAmount()
    return 0
end

function Lerk:GetViewModelName()
    return kViewModelName
end

function Lerk:GetIsWallGripping()
    return self.wallGripTime ~= 0 
end

// Gain speed gradually the longer we stay in the air
function Lerk:GetMaxSpeed(possible)

    if possible then
        return 13
    end

    local speed = kMaxWalkSpeed
    if not self:GetIsOnGround() then
    
        local kBaseAirScalar = 1.2      // originally 0.5
        local kAirTimeToMaxSpeed = 5  // originally 10
        local airTimeScalar = Clamp((Shared.GetTime() - self.timeLastOnGround) / kAirTimeToMaxSpeed, 0, 1)
        local speedScalar = kBaseAirScalar + airTimeScalar * (1 - kBaseAirScalar)
        speed = kMaxWalkSpeed + speedScalar * (kMaxSpeed - kMaxWalkSpeed)
        
        // half max speed while the walk key is pressed
        if self.movementModiferState then
            speed = speed * 0.5
        end
        
    end 
    
    return speed * self:GetMovementSpeedModifier()
    
end

function Lerk:GetAcceleration()
    return ConditionalValue(self:GetIsOnGround(), Alien.GetAcceleration(self), kAirAcceleration) * self:GetMovementSpeedModifier()
end

function Lerk:OverrideStrafeJump()
    return true
end

function Lerk:GetMass()
    return kMass
end

function Lerk:GetJumpHeight()
    return kJumpHeight
end

function Lerk:GetFrictionForce(input, velocity)
    
    local frictionScalar = 0.3
    local prevVelocity = self:GetVelocity()
    
    if self.gliding then
        return Vector(-prevVelocity.x, -prevVelocity.y, -prevVelocity.z) * .02
    end
    
    // When in the air, but not gliding (spinning out of control)
    // Allow holding the jump key to reduce velocity, and slow the fall
    if (not self:GetIsOnGround()) and (bit.band(input.commands, Move.Jump) ~= 0) and (not self.gliding) then
    
        if prevVelocity.y < 0 then
            return Vector(-prevVelocity.x, -prevVelocity.y, -prevVelocity.z) * frictionScalar
        else
            return Vector(-prevVelocity.x, 0, -prevVelocity.z) * frictionScalar
        end
        
    end
    
    return Alien.GetFrictionForce(self, input, velocity)
    
end

local function Flap(self, input, velocity)

    local lift = 0
    local flapVelocity = Vector(0, 0, 0)
    local flapDirection = self:GetViewCoords():TransformVector( input.move )
    flapDirection:Normalize()
    
    if self:GetEnergy() > Lerk.kLerkFlapEnergyCost then

        // Thrust forward or backward, or laterally

        if input.move:GetLength() ~= 0 then
        
            // Flapping backward and sideways generate very small amounts of thrust        
            // Allow full forward thrust, half lateral thrust, and minimal backward thrust

            if input.move.x ~= 0 then
                lift = kFlapStraightUpImpulse * 0.5
            end
            
            flapVelocity = flapDirection * kFlapThrustMoveScalar * self:GetMovementSpeedModifier()
            
        else
        
            // Get more lift and slow down in the XZ directions when trying to flap straight up
            lift = kFlapStraightUpImpulse
            flapVelocity = Vector(velocity.x, 0, velocity.z) * -0.1
            
        end
        
        flapVelocity.y = flapVelocity.y + lift
        
        // Each flap reduces some of the previous velocity
        // So we can change direction quickly by flapping
        
        if velocity.y < 0  then
            velocity.y = velocity.y * 0.5
        end
        
        VectorCopy(velocity * 0.5 + flapVelocity, velocity)
        
        self:TriggerEffects("flap")
        
        self.flappedSinceLeftGround = true
        
        self.lastTimeFlapped = Shared.GetTime()
        
        self:DeductAbilityEnergy(Lerk.kLerkFlapEnergyCost)
    
    end

end


// Lerk flight
//
// Lift = New vertical movement
// Thrust = New forward direction movement
//
// First flap should take off of ground and have you hover a bit before landing 
// Flapping without pressing forward applies more lift but 0 thrust. Flapping while
// holding forward moves you in that direction, but if looking down there's no lift.
// Flapping while pressing forward and backward are the same.
// Tilt view a bit when banking. Hold jump key to glide then look down to swoop down.
// When gliding while looking up or horizontal, hover in mid-air.
function Lerk:HandleJump(input, velocity)

    if self:GetIsOnGround() then
    
        velocity.y = velocity.y + kJumpImpulse
        
        self.timeOfLastJump = Shared.GetTime()
        
        self.lastTimeFlapped = Shared.GetTime()
        
    else
        Flap(self, input, velocity)
    end
    
    return true
    
end

function Lerk:HandleButtons(input)

    PROFILE("Lerk:HandleButtons")

    Alien.HandleButtons(self, input)
    
    if self:GetIsOnGround() or self:GetIsWallGripping() then
        self.flappedSinceLeftGround = false
    end
    
    if not self:GetIsWallGripping()  then
    
        if bit.band(input.commands, Move.MovementModifier) ~= 0 then
            
            if self.wallGripCheckEnabled then
        
                if not self:GetIsOnGround() then
                
                    // check if we can grab anything around us
                    local wallNormal = self:GetAverageWallWalkingNormal(Lerk.kWallGripRange, Lerk.kWallGripFeelerSize)
                    
                    if wallNormal then
                    
                        self.wallGripTime = Shared.GetTime()
                        self.wallGripNormalGoal = wallNormal
                        self.wallGripRecheckDone = false
                        
                    end
                    
                end
                
                // we clear the wallGripCheckEnabled here to make sure we don't trigger a flood of TraceRays just because
                // we hold down the use key
                self.wallGripCheckEnabled = false
            
            end
        
        end
    
    else
        
        // we always abandon wall gripping if we flap (even if we are sliding to a halt)
        local breakWallGrip = bit.band(input.commands, Move.Jump) ~= 0 
        
        // after sliding to a stop, pressing movment or crouch will drop the grip
        if not breakWallGrip and Shared.GetTime() - self.wallGripTime > Lerk.kWallGripSlideTime then
            breakWallGrip = input.move:GetLength() > 0 or bit.band(input.commands, Move.Crouch) ~= 0 
        end
        
        if breakWallGrip then
            self.wallGripTime = 0
            self.wallGripNormal = nil
            self.wallGripRecheckDone = false
        end
        
    end
    
end

// Called from GroundMoveMixin.
function Lerk:ComputeForwardVelocity(input)

    // If we're in the air, move a little to left and right, but move in view direction when 
    // pressing forward. Modify velocity when looking up or down.
    if not self:GetIsOnGround() then
        
        local move          = GetNormalizedVector(input.move)
        local viewCoords    = self:GetViewAngles():GetCoords()
        

        if self.gliding then
        
            if input.move:GetLength() == 0 then
                return GetNormalizedVector(self:GetVelocity()) * 0.5
            end
        

            // Gliding: ignore air control
            // Add or remove velocity depending if we're looking up or down
            local zAxis = viewCoords.zAxis
           
            local dot = Clamp(Vector(0, -1, 0):DotProduct(zAxis), 0, 1)

            local glideAmount = dot// math.sin( dot * math.pi / 2 )

            local glideVelocity = viewCoords.zAxis * math.abs(glideAmount) * self:GetAcceleration()

            return glideVelocity
            
        else
        
            // Not gliding: use normal ground movement, or air control if we're in the air
            local transformedVertical = viewCoords:TransformVector( Vector(0, 0, move.z) )


            local moveVelocity = viewCoords:TransformVector( move ) * self:GetAcceleration()


            return moveVelocity

            
        end
    
    else

        // Fallback on the base function.
        return Alien.ComputeForwardVelocity(self, input)
    end
    
end


function Lerk:RedirectVelocity(redirectDir)

    local velocity = self:GetVelocity() 
    
    local newVelocity = redirectDir * velocity:GetLength() // * Clamp(GetNormalizedVector(velocity):DotProduct(redirectDir) * 0.7 + 0.3, 0.3, 1) 
    self:SetVelocity(newVelocity)
    
end

function Lerk:CalcWallGripSpeedFraction()

    local dt = (Shared.GetTime() - self.wallGripTime)
    if dt > Lerk.kWallGripSlideTime then
        return 0
    end
    local k = Lerk.kWallGripSlideTime
    return (k - dt) / k
    
end

function Lerk:UpdatePosition(velocity, time)

    PROFILE("Lerk:UpdatePosition")

    local requestedVelocity = Vector(velocity)
    
    // slow down (to zero) if we are wallgripping
    if self:GetIsWallGripping() then   
        velocity = velocity * self:CalcWallGripSpeedFraction()
    end
    
    velocity = Alien.UpdatePosition(self, velocity, time)
    
    if not self:GetIsWallGripping() and not self.wallGripCheckEnabled then
        // if we bounced into something and we are not on the ground, we enable one
        // wall gripping on the next use use.
        // Lerks don't have any use other use for their use key, so this works in practice
        local deltaV = (requestedVelocity - velocity):GetLength()
        self.wallGripCheckEnabled = deltaV > 0 and not self:GetIsOnGround()
    end
    
    return velocity

end

function Lerk:PreUpdateMove(input, runningPrediction)

    PROFILE("Lerk:PreUpdateMove")

    // If we're gliding, redirect velocity to whichever way we're looking
    // so we get that cool soaring feeling from NS1
    // Now with strafing and air brake
    if not self:GetIsOnGround() then
    



        local move = GetNormalizedVector(input.move)     
        local viewCoords = self:GetViewAngles():GetCoords()
        local velocity = GetNormalizedVector(self:GetVelocity())
        local redirectDir = ConditionalValue( input.move:GetLength() ~= 0, self:GetViewAngles():GetCoords().zAxis, velocity)
        
        if self.gliding then
        
            if not self.prevInputMove and input.move:GetLength() ~= 0 then
                self.flappedSinceLeftGround = false
                redirectDir = velocity
            end
            
            self.prevInputMove = input.move:GetLength() ~= 0
                               
            // Glide forward, strafe left/right, or brake slowly
            if move.z ~= 0 then
            
                // Forward/Back key pressed - Glide in the facing direction
                // Allow some backward acceleration and some strafing
                move.z = Clamp(move.z, -0.05, 0)
                move.x = Clamp(move.x, -0.5, 0.5)                
                redirectDir = redirectDir + viewCoords:TransformVector( move )
                
            else
            
                // Non forward/back-key gliding, zero download velocity
                // Useful for maintaining height when attacking targets below
                move.x = Clamp(move.x, -0.5, 0.5)
                redirectDir = Vector(redirectDir.x, math.max(redirectDir.y, velocity.y, -0.01), redirectDir.z)                
                redirectDir = redirectDir + viewCoords:TransformVector( move )
                redirectDir:Normalize()
                
            end
            
            // Limit max speed so strafing does not increase total velocity
            if (redirectDir:GetLength() > 1) then
                redirectDir:Normalize()
            end

            self:RedirectVelocity(redirectDir)
            
        end
        
    end
    
    // wallgrip, recheck wallwalknormal as soon as the slide has stopped
    if self:GetIsWallGripping() and not self.wallGripRecheckDone and self:CalcWallGripSpeedFraction() == 0 then
    
        self.wallGripNormalGoal = self:GetAverageWallWalkingNormal(Lerk.kWallGripRange, Lerk.kWallGripFeelerSize)
        self.wallGripRecheckDone = true
        
        if not self.wallGripNormalGoal then
            self.wallGripTime = 0
            self.wallGripOrigin = nil
        end
        
    end
    
end

function Lerk:HandleAttacks(input)

    Player.HandleAttacks(self, input)
    
    // If we're holding down jump, glide

    local zAxis = self:GetViewAngles():GetCoords().zAxis    
    local velocity = self:GetVelocity()
    
    local changedDirection = false
    
    if input.move.z == 1 then
    
        local dot = 0
        if velocity:GetLength() > 1 then
            dot = GetNormalizedVector(velocity):DotProduct(zAxis)
        end
    
        changedDirection = dot <= .7
        
    end
    
    self.gliding = not self:GetIsOnGround() and self.flappedSinceLeftGround and bit.band(input.commands, Move.Jump) ~= 0 and (input.move.z > 0 or input.move:GetLength() == 0) and not changedDirection
    
end

// Glide if jump held down.
function Lerk:AdjustGravityForce(input, gravity)

    if bit.band(input.commands, Move.Crouch) ~= 0 then
        // Swoop
        gravity = kSwoopGravityScalar
    elseif self.gliding and self:GetVelocity().y <= 0 then
        // Glide for a long time
        gravity = kFlightGravityScalar
    else
        // Fall very slowly by default
        gravity = kRegularGravityScalar
    end
    
    return gravity
    
end

function Lerk:OnUpdatePoseParameters()
    
    Alien.OnUpdatePoseParameters(self)
    
    local activeAbility = self:GetActiveWeapon()
    local activeAbilityIsSpores = activeAbility ~= nil and activeAbility:isa("Spores")
    self:SetPoseParam("spore", activeAbilityIsSpores and 1 or 0)
    
end

function Lerk:OnUpdateAnimationInput(modelMixin)

    PROFILE("Lerk:OnUpdateAnimationInput")
    
    Player.OnUpdateAnimationInput(self, modelMixin)
    
    if not self:GetIsWallGripping() and not self:GetIsOnGround() then
        modelMixin:SetAnimationInput("move", "fly")
    end
    
    local flappedRecently = (Shared.GetTime() - self.lastTimeFlapped) <= 0.5
    modelMixin:SetAnimationInput("flapping", flappedRecently)
    modelMixin:SetAnimationInput("attack_speed", self:GetIsPrimaled() and (kDefaultAttackSpeed * kPrimalScreamROFIncrease) or kDefaultAttackSpeed)
    
end

Shared.LinkClassToMap("Lerk", Lerk.kMapName, networkVars)