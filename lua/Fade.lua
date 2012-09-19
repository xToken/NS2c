// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Fade.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Role: Surgical striker, harassment
//
// The Fade should be a fragile, deadly-sharp knife. Wielded properly, it's force is undeniable. But
// used clumsily or without care will only hurt the user. Make sure Fade isn't better than the Skulk 
// in every way (notably, vs. Structures). To harass, he must be able to stay out in the field
// without continually healing at base, and needs to be able to use blink often.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/SwipeBlink.lua")
Script.Load("lua/Weapons/Alien/Metabolize.lua")
Script.Load("lua/Weapons/Alien/AcidRocket.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/DissolveMixin.lua")

class 'Fade' (Alien)

Fade.kMapName = "fade"

Fade.kModelName = PrecacheAsset("models/alien/fade/fade.model")
Fade.kViewModelName = PrecacheAsset("models/alien/fade/fade_view.model")
local kFadeAnimationGraph = PrecacheAsset("models/alien/fade/fade.animation_graph")

Shared.PrecacheSurfaceShader("models/alien/fade/fade.surface_shader")

Fade.kViewOffsetHeight = 1.7
Fade.XZExtents = .4
Fade.YExtents = 1.05
Fade.kHealth = kFadeHealth
Fade.kArmor = kFadeArmor
Fade.kMass = 50 // ~350 pounds
Fade.kJumpHeight = 1.3
Fade.kMaxSpeed = 21
Fade.kBlinkAccelSpeed = 12
Fade.kWalkSpeed = 4
Fade.kAcceleration = 50
Fade.kAirAcceleration = 25
Fade.kBlinkAirAcceleration = 40
Fade.kBlinkAirAccelerationDuration = 2
Fade.kBlinkAcceleration = 60
Fade.kVerticleBlinkAcceleration = 25
Fade.kVerticleBlinkReduction = 3
Fade.kVerticleBlinkOffset = 0.075

if Server then
    Script.Load("lua/Fade_Server.lua")
elseif Client then    
    Script.Load("lua/Fade_Client.lua")
end

local networkVars =
{    
    etherealStartTime = "private time",
    etherealEndTime = "private time",
    
    // True when we're moving quickly "through the ether"
    ethereal = "boolean"
}

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)

function Fade:OnCreate()

    InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, GroundMoveMixin)
    InitMixin(self, CameraHolderMixin, { kFov = kFadeFov })
    
    Alien.OnCreate(self)
    
    InitMixin(self, DissolveMixin)

    if Server then
        self.isBlinking = false
    end
    
    self.etherealStartTime = 0
    self.etherealEndTime = 0
    self.ethereal = false

end

/*
function Fade:AdjustGravityForce(input, gravity)
   
    if self:GetIsBlinking() or not self.landedAfterBlink then
        gravity = gravity * .75
    end
    
    return gravity
      
end
*/

function Fade:OnInitialized()
    Alien.OnInitialized(self)
    self:SetModel(Fade.kModelName, kFadeAnimationGraph)
    
    if Client then
    
        self:AddHelpWidget("GUIFadeBlinkHelp", 2)
        
    end
    
end

function Fade:OnDestroy()
    Alien.OnDestroy(self)
    if Client then    
        self:DestroyTrailCinematic()    
    end
end

function Fade:GetHeadAttachpointName()
    return "fade_tongue2"
end

function Fade:PreCopyPlayerData()

    // Reset visibility and gravity in case we were in ether mode.
    self:SetIsVisible(true)
    self:SetGravityEnabled(true)

end

function Fade:GetBaseArmor()
    return Fade.kArmor
end

function Fade:GetArmorFullyUpgradedAmount()
    return kFadeArmorFullyUpgradedAmount
end

function Fade:GetMaxViewOffsetHeight()
    return Fade.kViewOffsetHeight
end

function Fade:GetViewModelName()
    return Fade.kViewModelName
end

/*
function Fade:OnJumpLand(landIntensity, slowDown)
    Alien.OnJumpLand(self, landIntensity, slowDown)
    self.landedAfterBlink = true
end
*/

function Fade:PerformsVerticalMove()
    return self:GetIsBlinking()
end


function Fade:GetGroundFrictionForce()
    return 7.2
end

function Fade:GetCanJump()
    return Alien.GetCanJump(self)
end

function Fade:GetIsOnGround()

    if self:GetIsBlinking() then
        return false
    end
    
    return Alien.GetIsOnGround(self)
    
end

function Fade:GetAcceleration()
    
    if self:GetIsBlinking() then
        return Fade.kBlinkAcceleration * self:GetMovementSpeedModifier()
    end
    if self:GetRecentlyBlinked() and self:GetVelocity():GetLengthXZ() > Fade.kBlinkAccelSpeed then
        return Fade.kBlinkAirAcceleration * self:GetMovementSpeedModifier()
    end
    if not self:GetIsOnGround() then
        return Fade.kAirAcceleration * self:GetMovementSpeedModifier()
    end
    
    return Fade.kAcceleration * self:GetMovementSpeedModifier()
end

function Fade:GetMaxSpeed(possible)

    if possible then
        return 8
    end
    
    //Walking
    local maxSpeed = ConditionalValue(self.movementModiferState and self:GetIsOnSurface(), Fade.kWalkSpeed, Fade.kMaxSpeed)
    
    // Take into account crouching
    return maxSpeed * self:GetMovementSpeedModifier()

end

function Fade:ModifyVelocity(input, velocity)     
 
    Alien.ModifyVelocity(self, input, velocity)
    
    if self:GetIsBlinking() then
        self:PerformMovement( velocity * input.time, 1, velocity )
        local viewCoords = self:GetViewAngles():GetCoords()
        local zAxis = viewCoords.zAxis
        //Convert velocity instantly if opposite direction for additional responsiveness
        //offset viewangle slightly to account for downwards trending
        zAxis.y = zAxis.y + Fade.kVerticleBlinkOffset
        if Sign(velocity.y) ~= Sign(zAxis.y) then
            if Sign(zAxis.y) > 0 then
                velocity.y = 10
            elseif zAxis.y < (-0.25) then
                velocity.y = 0
            end
        end
        velocity.y = velocity.y + Clamp( Fade.kVerticleBlinkAcceleration * ((1 - math.cos(zAxis.y)) / Fade.kVerticleBlinkReduction) ,0, zAxis.y)
    end
    
end

function Fade:GetMass()
    return Fade.kMass 
end

function Fade:GetJumpHeight()
    return Fade.kJumpHeight
end

function Fade:GetIsBlinking()
    return self.ethereal and self:GetIsAlive()
end

function Fade:GetRecentlyBlinked()
    return Shared.GetTime() - self.etherealEndTime < Fade.kBlinkAirAccelerationDuration
end

function Fade:GetRecentlyJumped()
    return self.timeOfLastJump ~= nil and self.timeOfLastJump + 0.15 > Shared.GetTime()
end

function Fade:OnProcessMove(input)
    Alien.OnProcessMove(self, input)
end

function Fade:HandleOnGround(input, velocity)
    if Sign(velocity.y) == -1 then
        velocity.y = 0
    end
end

// for update position
function Fade:GetCanStep()
    return self:GetIsBlinking() or Alien.GetCanStep(self)
end

function Fade:GetStepHeight()
    return Player.GetStepHeight() 
end

function Fade:GetGravityAllowed()
    return not self:GetIsBlinking()
end

function Fade:TriggerBlink()
    self.ethereal = true
    self.onGroundNeedsUpdate = false
    self.jumping = true
end

function Fade:OverrideInput(input)

    Player.OverrideInput(self, input)

    if self:GetIsBlinking() then
        input.move.z = 1
        input.move.x = 0
    end
    
    return input
    
end

function Fade:GetCanClimb()
    return false
end

function Fade:OnBlinkEnd()
    self.onGroundNeedsUpdate = true
    if self:GetIsOnGround() then
        self.jumping = false
    end
    self.ethereal = false
end

/*
local kFadeEngageOffset = Vector(0, 0.6, 0)
function Fade:GetEngagementPointOverride()
    return self:GetOrigin() + kFadeEngageOffset
end

function Fade:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.8, 0)
end
*/

Shared.LinkClassToMap("Fade", Fade.kMapName, networkVars)