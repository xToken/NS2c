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

//NS2c
//Added attackspeed, tweaked some vars for goldsource movement and made some vars local

Script.Load("lua/Utility.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Weapons/Alien/Spores.lua")
Script.Load("lua/Weapons/Alien/Umbra.lua")
Script.Load("lua/Weapons/Alien/Primal.lua")
Script.Load("lua/Weapons/Alien/Spikes.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/WallMovementMixin.lua")
Script.Load("lua/DissolveMixin.lua")

class 'Lerk' (Alien)

Lerk.kMapName = "lerk"

Lerk.kModelName = PrecacheAsset("models/alien/lerk/lerk.model")
local kViewModelName = PrecacheAsset("models/alien/lerk/lerk_view.model")
local kLerkAnimationGraph = PrecacheAsset("models/alien/lerk/lerk.animation_graph")

Shared.PrecacheSurfaceShader("models/alien/lerk/lerk.surface_shader")

if Client then
    Script.Load("lua/Lerk_Client.lua")
elseif Server then
    Script.Load("lua/Lerk_Server.lua")
end

Lerk.XZExtents = 0.4
Lerk.YExtents = 0.4

local kWallGripSlideTime = 0.7
local kWallGripRange = 0.05
local kWallGripFeelerSize = 0.25
local kViewOffsetHeight = 0.5
local kJumpImpulse = 4
local kFlapStraightUpImpulse = 4.7
local kFlapThrustMoveScalar = 7.5
local kMass = 54
local kSwoopGravityScalar = -25.0
local kRegularGravityScalar = -7
local kFlightGravityScalar = -4
local kMaxWalkSpeed = 3.9
local kWalkSpeed = 2.4
local kMaxSpeed = 14
local kDefaultAttackSpeed = 1.1

local networkVars =
{
    gliding = "private compensated boolean",
    
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

AddMixinNetworkVars(CameraHolderMixin, networkVars)

function Lerk:OnCreate()

    InitMixin(self, CameraHolderMixin, { kFov = kLerkFov })
    InitMixin(self, WallMovementMixin)
    
    Alien.OnCreate(self)
    
    InitMixin(self, DissolveMixin)
    
    self.prevInputMove = false
    self.gliding = false
    self.lastTimeFlapped = 0
    
    self.wallGripTime = 0
    self.wallGripRecheckDone = false
    self.wallGripCheckEnabled = false
    
end

function Lerk:OnInitialized()

    Alien.OnInitialized(self)
    
    self:SetModel(Lerk.kModelName, kLerkAnimationGraph)
    
    if Client then
    
        self.currentCameraRoll = 0
        self.goalCameraRoll = 0
        self.previousYaw = 0
        
        self:AddHelpWidget("GUILerkFlapHelp", 2)
        self:AddHelpWidget("GUILerkSporesHelp", 2)
        
    end
    
end

function Lerk:OnDestroy()

    Alien.OnDestroy(self)
    
end 

function Lerk:GetAngleSmoothRate()
    return 6
end

function Lerk:GetRollSmoothRate()
    return 3
end    

local kMaxGlideRoll = math.rad(60)

function Lerk:GetDesiredAngles()

    if self:GetIsWallGripping() then
        return self:GetAnglesFromWallNormal( self.wallGripNormalGoal )
    end

    local desiredAngles = Alien.GetDesiredAngles(self)

    if not self:GetIsOnGround() and self.gliding then
        desiredAngles.pitch = self.viewPitch
    end 
   
    if not self:GetIsOnSurface() then    
        desiredAngles.roll = Clamp( RadianDiff( self:GetAngles().yaw, self.viewYaw ), -kMaxGlideRoll, kMaxGlideRoll)    
    end
    
    return desiredAngles

end

function Lerk:GetAngleSmoothingMode()

    if self:GetIsWallGripping() then
        return "quatlerp"
    else
        return "euler"
    end

end

function Lerk:GetBaseArmor()
    return kLerkArmor
end

function Lerk:GetBaseHealth()
    return kLerkHealth
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

function Lerk:ReceivesFallDamage()
    return false
end

function Lerk:GetJumpMode()
    return kJumpMode.Default
end

// Gain speed gradually the longer we stay in the air
function Lerk:GetMaxSpeed(possible)

    if possible then
        return kMaxSpeed
    end

    local speed = kMaxWalkSpeed
    
    if not self:GetIsOnGround() then
        speed = kMaxSpeed
    end
    
    if self.movementModiferState and self:GetIsOnSurface() then
        maxSpeed = kWalkSpeed
    end
    
    return speed + self:GetMovementSpeedModifier()
    
end

function Lerk:GetCanCrouch()
    return false
end

function Lerk:GetIsForwardOverrideDesired()
    return false
end

function Lerk:GetMass()
    return kMass
end

local function Flap(self, input, velocity)

    local flapStraightMod = ConditionalValue(input.move.z >= 0, 1.2, 1)
    local lift = 0
    local flapVelocity = Vector(0, 0, 0)
    local flapDirection = self:GetViewCoords():TransformVector( input.move )
    flapDirection:Normalize()
    
    if self:GetEnergy() > kLerkFlapEnergyCost then

        // Thrust forward or backward, or laterally

        if input.move:GetLength() ~= 0 then
        
            // Flapping backward and sideways generate very small amounts of thrust        
            // Allow full forward thrust, half lateral thrust, and minimal backward thrust

            if input.move.x ~= 0 then
                lift = kFlapStraightUpImpulse * 0.5
            end
            
            flapVelocity = flapDirection * kFlapThrustMoveScalar
            
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
        
        self.lastTimeFlapped = Shared.GetTime()
        
        self:DeductAbilityEnergy(kLerkFlapEnergyCost)
    
    end

end

function Lerk:GetTimeOfLastFlap()
    return self.lastTimeFlapped
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

    if bit.band(input.commands, Move.Jump) ~= 0 and not self:GetIsJumpHandled() then
        if self:GetIsOnGround() and self:GetCanJump() then
            velocity.y = velocity.y + kJumpImpulse
            self:UpdateLastJumpTime()
            self:SetIsOnGround(false)
            self.lastTimeFlapped = Shared.GetTime()
        else
            Flap(self, input, velocity)
        end
        self:SetIsJumpHandled(true)
    end
    
end

function Lerk:HandleButtons(input)

    PROFILE("Lerk:HandleButtons")

    Alien.HandleButtons(self, input)
    
    if not self:GetIsWallGripping()  then
    
        if bit.band(input.commands, Move.MovementModifier) ~= 0 then
            
            if self.wallGripCheckEnabled then
        
                if not self:GetIsOnGround() then
                
                    // check if we can grab anything around us
                    local wallNormal = self:GetAverageWallWalkingNormal(kWallGripRange, kWallGripFeelerSize)
                    
                    if wallNormal then
                    
                        self.wallGripTime = Shared.GetTime()
                        self.wallGripNormalGoal = wallNormal
                        self.wallGripRecheckDone = false
                        self:SetVelocity(Vector(0,0,0))
                        
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
        if not breakWallGrip and Shared.GetTime() - self.wallGripTime > kWallGripSlideTime then
            breakWallGrip = input.move:GetLength() > 0 or bit.band(input.commands, Move.Crouch) ~= 0 
        end
        
        if breakWallGrip then
            self.wallGripTime = 0
            self.wallGripNormal = nil
            self.wallGripRecheckDone = false
        end
        
    end
    
end

local kLerkEngageOffset = Vector(0, 0.6, 0)
function Lerk:GetEngagementPointOverride()
    return self:GetOrigin() + kLerkEngageOffset
end

function Lerk:RedirectVelocity(redirectDir)

    local velocity = self:GetVelocity() 
    
    local newVelocity = redirectDir * velocity:GetLength() // * Clamp(GetNormalizedVector(velocity):DotProduct(redirectDir) * 0.7 + 0.3, 0.3, 1) 
    self:SetVelocity(newVelocity)
    
end

function Lerk:CalcWallGripSpeedFraction()

    local dt = (Shared.GetTime() - self.wallGripTime)
    if dt > kWallGripSlideTime then
        return 0
    end
    local k = kWallGripSlideTime
    return (k - dt) / k
    
end

function Lerk:UpdatePosition(input, velocity, time)

    PROFILE("Lerk:UpdatePosition")
    
    local wasOnSurface = self:GetIsOnSurface()
    local moveDirection = GetNormalizedVector(velocity)
    local requestedVelocity = Vector(velocity)
    
    local completedMove = nil
    local hitEntities = nil
    local averageSurfaceNormal = nil
    
    // slow down (to zero) if we are wallgripping
    if self:GetIsWallGripping() then   
        velocity = velocity * self:CalcWallGripSpeedFraction()
    end
    
    Player.UpdatePosition(self, input, velocity, time)
    
    if not self:GetIsWallGripping() and not self.wallGripCheckEnabled then
        // if we bounced into something and we are not on the ground, we enable one
        // wall gripping on the next use use.
        // Lerks don't have any use other use for their use key, so this works in practice
        local deltaV = (requestedVelocity - velocity):GetLength()
        self.wallGripCheckEnabled = deltaV > 0 and not self:GetIsOnGround()
        
    end
    
    local steepImpact = averageSurfaceNormal ~= nil and hitEntities == nil and moveDirection:DotProduct(averageSurfaceNormal) < -.85

    if self.gliding and not steepImpact then
        velocity = requestedVelocity
    end

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
    
        self.wallGripNormalGoal = self:GetAverageWallWalkingNormal(kWallGripRange, kWallGripFeelerSize)
        self.wallGripRecheckDone = true
        
        if not self.wallGripNormalGoal then
            self.wallGripTime = 0
            self.wallGripOrigin = nil
        end
        
    end
    
end

function Lerk:HandleAttacks(input)

    Player.HandleAttacks(self, input)
    
    local moveDirection = GetNormalizedVector( self:GetVelocity() )
    local turnedSharp = self:GetViewCoords().zAxis:DotProduct(moveDirection) < .4
    local holdingJump = bit.band(input.commands, Move.Jump) ~= 0
    
    // If we're holding down jump, glide
    self.gliding = input.move.z > 0 and self:GetVelocityLength() > kMaxSpeed *.5 and not self:GetIsOnSurface() and not turnedSharp and holdingJump
    
end

// Glide if jump held down.
function Lerk:AdjustGravityForce(input, gravity)

    if self:GetIsWallGripping() then
        return 0

    elseif bit.band(input.commands, Move.Crouch) ~= 0 then
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

function Lerk:GetBaseAttackSpeed()
    return kDefaultAttackSpeed
end

function Lerk:OnUpdateAnimationInput(modelMixin)

    PROFILE("Lerk:OnUpdateAnimationInput")
    
    Alien.OnUpdateAnimationInput(self, modelMixin)
    
    if not self:GetIsWallGripping() and not self:GetIsOnGround() then
        modelMixin:SetAnimationInput("move", "fly")
    end
    
    local flappedRecently = (Shared.GetTime() - self.lastTimeFlapped) <= 0.5
    modelMixin:SetAnimationInput("flapping", flappedRecently)
    
end

Shared.LinkClassToMap("Lerk", Lerk.kMapName, networkVars, true)