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
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/DissolveMixin.lua")

class 'Fade' (Alien)

Fade.kMapName = "fade"

Fade.kModelName = PrecacheAsset("models/alien/fade/fade.model")
local kViewModelName = PrecacheAsset("models/alien/fade/fade_view.model")
local kFadeAnimationGraph = PrecacheAsset("models/alien/fade/fade.animation_graph")

Shared.PrecacheSurfaceShader("models/alien/fade/fade.surface_shader")

if Server then
    Script.Load("lua/Fade_Server.lua")
elseif Client then    
    Script.Load("lua/Fade_Client.lua")
end

Fade.XZExtents = .4
Fade.YExtents = .85

local kViewOffsetHeight = 1.7
local kMass = 76 // 50 // ~350 pounds
local kMaxSpeed = 4.5
local kMaxBlinkSpeed = 16 // ns1 fade blink is (3x maxSpeed) + celerity
local kWalkSpeed = 2
local kCrouchedSpeed = 1.8
local kBlinkAccelerationDuration = 0.33
local kBlinkImpulseForce = 10
local kBlinkVerticleScalar = 0.05
local networkVars =
{    
    etherealStartTime = "private time",
    etherealEndTime = "private time",
    // True when we're moving quickly "through the ether"
    ethereal = "boolean"
}

AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)

function Fade:OnCreate()

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

function Fade:OnInitialized()

    Alien.OnInitialized(self)
    
    self:SetModel(Fade.kModelName, kFadeAnimationGraph)
    
    if Client then
    
        self:AddHelpWidget("GUIFadeBlinkHelp", 2)
        
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
    return kFadeArmor
end

function Fade:GetArmorFullyUpgradedAmount()
    return kFadeArmorFullyUpgradedAmount
end

function Fade:GetMaxViewOffsetHeight()
    return kViewOffsetHeight
end

function Fade:GetViewModelName()
    return kViewModelName
end

function Fade:PerformsVerticalMove()
    return self:GetIsBlinking()
end

function Fade:ReceivesFallDamage()
    return false
end

function Fade:GetMaxSpeed(possible)
    if possible then
        return kMaxSpeed
    end
    
    local maxSpeed = kMaxSpeed
        
    if self.movementModiferState and self:GetIsOnSurface() then
        maxSpeed = kWalkSpeed
    end
    
    if self:GetCrouched() then
        maxSpeed = kCrouchedSpeed
    end
        
    return maxSpeed + self:GetMovementSpeedModifier()
end

function Fade:GetMass()
    return kMass 
end

function Fade:GetIsBlinking()
    return self.ethereal and self:GetIsAlive()
end

function Fade:GetRecentlyBlinked()
    return Shared.GetTime() - self.etherealEndTime < kBlinkAccelerationDuration
end

function Fade:OnBlink()
    self:SetIsOnGround(false)
    self:SetIsJumping(true)
end

function Fade:OnBlinking(input)
    local velocity = self:GetVelocity()
       
    // Blink impulse
    velocity:Add( self:GetViewCoords().zAxis * kBlinkImpulseForce )
    
    // Cap groundspeed
    local groundspeed = velocity:GetLengthXZ()
    local maxspeed = kMaxBlinkSpeed + self:GetMovementSpeedModifier()
    
    if groundspeed > maxspeed then
        local oldYvelocity = velocity.y
        velocity:Scale(maxspeed/groundspeed)
        velocity.y = oldYvelocity
    end
    
    local pitchAngle = Clamp(self:GetViewCoords().zAxis.y, -0.5, 0.5)
    if pitchAngle < 0.25 and pitchAngle >= -0.05 and math.abs(velocity.y) < 1 then
        self:GetJumpVelocity(input, velocity)
    else
        velocity.y = velocity.y + (pitchAngle * self:GetJumpForce() * kBlinkVerticleScalar * input.time)
    end
    //Cap Y Velocity    
    velocity.y = Clamp(velocity.y, (-1 * (kMaxBlinkSpeed + self:GetMovementSpeedModifier())), kMaxBlinkSpeed + self:GetMovementSpeedModifier())    
    
    // Finish
    self:SetVelocity(velocity)
    self.jumping = true // Animation
    self:SetIsOnGround(false)
    
end

function Fade:OnBlinkEnd()
    if self:GetIsOnGround() then
        self.jumping = false
    end
end

local kFadeEngageOffset = Vector(0, 0.6, 0)
function Fade:GetEngagementPointOverride()
    return self:GetOrigin() + kFadeEngageOffset
end

function Fade:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.8, 0)
end

Shared.LinkClassToMap("Fade", Fade.kMapName, networkVars)