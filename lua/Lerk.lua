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
Script.Load("lua/LerkVariantMixin.lua")

class 'Lerk' (Alien)

Lerk.kMapName = "lerk"

Lerk.kModelName = PrecacheAsset("models/alien/lerk/lerk.model")
local kViewModelName = PrecacheAsset("models/alien/lerk/lerk_view.model")
local kLerkAnimationGraph = PrecacheAsset("models/alien/lerk/lerk.animation_graph")

PrecacheAsset("models/alien/lerk/lerk.surface_shader")

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
local kJumpForce = 4
local kFlapImpulse = 4.7
local kMass = 54
local kSwoopGravityScalar = -25.0
local kRegularGravityScalar = -7
local kAirStrafeMaxSpeed = 5.5
local kGlideAccel = 3
local kMaxWalkSpeed = 3.9
local kWalkSpeed = 2.4
local kMaxSpeed = 14
local kDefaultAttackSpeed = 1.1

local networkVars =
{
    gliding = "private compensated boolean",   
    glideAllowed = "private compensated boolean",  
    lastTimeFlapped = "time",
    // Wall grip. time == 0 no grip, > 0 when grip started.
    wallGripTime = "private compensated time",
    // the normal that the model will use. Calculated the same way as the skulk
    wallGripNormalGoal = "private compensated vector",
	wallGripAllowed = "private compensated boolean",
    flapPressed = "private compensated boolean"
}

AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(LerkVariantMixin, networkVars)

function Lerk:OnCreate()

    InitMixin(self, CameraHolderMixin, { kFov = kLerkFov })
    InitMixin(self, WallMovementMixin)
    InitMixin(self, LerkVariantMixin)
    
    Alien.OnCreate(self)
    
    InitMixin(self, DissolveMixin)
    
    self.gliding = false
    self.lastTimeFlapped = 0
    
    self.wallGripTime = 0
    
end

function Lerk:OnInitialized()

    Alien.OnInitialized(self)
    
    self:SetModel(Lerk.kModelName, kLerkAnimationGraph)
    
    if Client then
    
        self.currentCameraRoll = 0
        self.goalCameraRoll = 0
        self.previousYaw = 0
        
    end
    
end

function Lerk:OnDestroy()

    Alien.OnDestroy(self)
    
end 

function Lerk:GetAngleSmoothRate()
    return 6
end

function Lerk:GetCollisionSlowdownFraction()
    return 0.1
end

function Lerk:GetRollSmoothRate()
    return 3
end    

local kMaxGlideRoll = math.rad(30)

function Lerk:GetDesiredAngles()

    if self:GetIsWallGripping() then
        return self:GetAnglesFromWallNormal( self.wallGripNormalGoal )
    end

    local desiredAngles = Alien.GetDesiredAngles(self)

    if not self:GetIsOnGround() and not self:GetIsWallGripping() then   
        if self.gliding then
            desiredAngles.pitch = self.viewPitch
        end 
        local diff = RadianDiff( self:GetAngles().yaw, self.viewYaw )
        if math.abs(diff) < 0.001 then
            diff = 0
        end
        desiredAngles.roll = Clamp( diff, -kMaxGlideRoll, kMaxGlideRoll)   
        -- Log("%s: yaw %s, viewYaw %s, diff %s, roll %s", self, self:GetAngles().yaw, self.viewYaw , diff, desiredAngles.roll)
    end
    
    return desiredAngles

end

local kLerkGlideYaw = 90

function Lerk:OverrideGetMoveYaw()

    // stop the animation from banking the model; the animation was originally intended
    // to handle left/right banking using move_speed and move_yaw, but this was too cumbersome.
    // By setting the moveYaw to 90 (straight ahead), the animation-state banking is zeroed out
    // and the banking can be handled by changing the roll angle instead

    if not self:GetIsOnGround() then
        return kLerkGlideYaw
    end
    return nil

end

function Lerk:OverrideGetMoveSpeed(speed)

    if self:GetIsOnGround() then
        return kMaxWalkSpeed
    end
    // move_speed determines how often we flap. We fiddle some to 
    // flap more at minimum flying speed
    return Clamp((speed - kMaxWalkSpeed) / kMaxSpeed, 0, 1) 
           
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

function Lerk:GetCrouchTime()
    return 0
end

function Lerk:GetExtentsCrouchShrinkAmount()
    return 0
end

function Lerk:GetJumpForce()
    return kJumpForce
end

function Lerk:GetViewModelName()
    return self:GetVariantViewModel(self:GetVariant())
end

function Lerk:GetIsWallGripping()
    return self.wallGripTime ~= 0 
end

function Lerk:OnTakeFallDamage()
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
    
    if self.movementModiferState and self:GetIsOnGround() then
        maxSpeed = kWalkSpeed
    end
    
    return speed + self:GetMovementSpeedModifier()
    
end

function Lerk:GetCanCrouch()
    return true
end

function Lerk:GetMass()
    return kMass
end

function Lerk:GetTimeOfLastFlap()
    return self.lastTimeFlapped
end

function Lerk:OverrideUpdateOnGround(onGround)
    return (onGround or self:GetIsWallGripping())
end

function Lerk:OnWorldCollision(normal)
    self.wallGripAllowed = normal.y < 0.5 and not self:GetCrouching()
end

function Lerk:OnGroundChanged(onGround, impactForce, normal, velocity)

    Alien.OnGroundChanged(self, onGround, impactForce, normal, velocity)

    if onGround then
        self.glideAllowed = false
    end

end

local function UpdateFlap(self, input, velocity)

    local flapPressed = bit.band(input.commands, Move.Jump) ~= 0

    if flapPressed ~= self.flapPressed then

        self.flapPressed = flapPressed
        self.glideAllowed = not self:GetIsOnGround()

        if flapPressed and self:GetEnergy() > kLerkFlapEnergyCost and not self.gliding then
        
            // take off
            if self:GetIsOnGround() or input.move:GetLength() == 0 then
                velocity.y = velocity.y * 0.5 + 5

            else

                local flapForce = kFlapImpulse
                local move = Vector(input.move)
                move.x = move.x * 0.75
                // flap only at 50% speed side wards
                
                local wishDir = self:GetViewCoords():TransformVector(move)
                wishDir:Normalize()

                // the speed we already have in the new direction
                local currentSpeed = move:DotProduct(velocity)
                // prevent exceeding max speed of kMaxSpeed by flapping
                
                local maxSpeed = math.max(currentSpeed, self:GetMaxSpeed())
                
                if input.move.z ~= 1 and velocity.y < 0 then
                // apply vertical flap
                    velocity.y = velocity.y * 0.5 + 3.8     
                elseif input.move.z == 1 and input.move.x == 0 then
                    flapForce = 3 + flapForce             
                elseif input.move.z == 0 and input.move.x ~= 0 then
                    velocity.y = velocity.y + 3.5
                end
                
                // directional flap
                velocity:Scale(0.65)
                velocity:Add(wishDir * flapForce)
                
                if velocity:GetLength() > maxSpeed then
                    velocity:Normalize()
                    velocity:Scale(maxSpeed)
                end
                
            end
 
            self:DeductAbilityEnergy(kLerkFlapEnergyCost)
            self.lastTimeFlapped = Shared.GetTime()
            self.onGround = false
            self:TriggerEffects("flap")

        end

    end

end

local function UpdateGlide(self, input, velocity, deltaTime)

    // more control when moving forward
    local holdingGlide = bit.band(input.commands, Move.Jump) ~= 0 and self.glideAllowed
    if input.move.z == 1 and holdingGlide then
    
        local useMove = Vector(input.move)
        useMove.x = useMove.x * 0.5
        
        local wishDir = GetNormalizedVector(self:GetViewCoords():TransformVector(useMove))
        // slow down when moving in another XZ direction, accelerate when falling down
        local currentDir = GetNormalizedVector(velocity)
        local glideAccel = -currentDir.y * deltaTime * kGlideAccel

        local maxSpeed = self:GetMaxSpeed()
        
        local speed = velocity:GetLength() // velocity:DotProduct(wishDir) * 0.1 + velocity:GetLength() * 0.9
        local useSpeed = math.min(maxSpeed, speed + glideAccel)
		
		// when speed falls below 1, set horizontal speed to 1, and vertical speed to zero, but allow dive to regain speed
		if useSpeed < 4 then
			useSpeed = 4
			local newY = math.min(wishDir.y, 0)
			wishDir.y = newY
			wishDir = GetNormalizedVector(wishDir)
		end
		
        // when gliding we always have 100% control
        local redirectVelocity = wishDir * useSpeed
        VectorCopy(redirectVelocity, velocity)
        
        self.gliding = not self:GetIsOnGround()

    else
        self.gliding = false
    end

end

// jetpack and exo do the same, move to utility function
local function UpdateAirStrafe(self, input, velocity, deltaTime)

    if not self:GetIsOnGround() and not self.gliding then
    
        // do XZ acceleration
        local wishDir = self:GetViewCoords():TransformVector(input.move) 
        wishDir.y = 0
        wishDir:Normalize()
        
        local maxSpeed = math.max(kAirStrafeMaxSpeed, velocity:GetLengthXZ())        
        velocity:Add(wishDir * 18 * deltaTime)
        
        if velocity:GetLengthXZ() > maxSpeed then
        
            local yVel = velocity.y        
            velocity.y = 0
            velocity:Normalize()
            velocity:Scale(maxSpeed)
            velocity.y = yVel
            
        end 
        
    end

end

function Lerk:ModifyVelocity(input, velocity, deltaTime)

    UpdateFlap(self, input, velocity)
    UpdateAirStrafe(self, input, velocity, deltaTime)
    UpdateGlide(self, input, velocity, deltaTime)

end

function Lerk:GetAirFriction()
    return 0.1
end

function Lerk:GetAirAcceleration()
    return 0
end

function Lerk:GetCanStep()
    return self:GetIsOnGround() and not self:GetIsWallGripping()
end

// Glide if jump held down.
function Lerk:ModifyGravityForce(gravityTable)

    if self:GetIsOnGround() then
        gravityTable.gravity = 0
    elseif self:GetCrouching() then
        // Swoop
        gravityTable.gravity = kSwoopGravityScalar
    else
        // Fall very slowly by default
        gravityTable.gravity = kRegularGravityScalar
    end
    
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