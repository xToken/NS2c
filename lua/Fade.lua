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

//NS2c
//Modified for goldsource movement, also made most vars local

Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/SwipeBlink.lua")
Script.Load("lua/Weapons/Alien/Metabolize.lua")
Script.Load("lua/Weapons/Alien/AcidRocket.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")

class 'Fade' (Alien)

Fade.kMapName = "fade"

Fade.kModelName = PrecacheAsset("models/alien/fade/fade.model")
local kViewModelName = PrecacheAsset("models/alien/fade/fade_view.model")
local kFadeAnimationGraph = PrecacheAsset("models/alien/fade/fade.animation_graph")

PrecacheAsset("models/alien/fade/fade.surface_shader")

if Server then
    Script.Load("lua/Fade_Server.lua")
end

Fade.XZExtents = .4
Fade.YExtents = .85

local kViewOffsetHeight = 1.7
local kMass = 76 // 50 // ~350 pounds
local kMaxSpeed = 4.8
local kWalkSpeed = 2
local kCrouchedSpeed = 1.8
local kBlinkImpulseForce = 85
local kFadeBlinkAutoJumpGroundDistance = 0.25
local kMetabolizeAnimationDelay = 0.65

local networkVars =
{
    ethereal = "compensated boolean",
    timeMetabolize = "private compensated time"
}

AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)

function Fade:OnCreate()

    InitMixin(self, CameraHolderMixin, { kFov = kFadeFov })
    
    Alien.OnCreate(self)
    
    InitMixin(self, DissolveMixin)
    InitMixin(self, PredictedProjectileShooterMixin)

    self.ethereal = false
    self.timeMetabolize = 0
    
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
    self:SetIsVisible(true)
end

function Fade:GetBaseArmor()
    return kFadeArmor
end

function Fade:GetBaseHealth()
    return kFadeHealth
end

function Fade:GetArmorFullyUpgradedAmount()
    return kFadeArmorFullyUpgradedAmount
end

function Fade:ModifyCrouchAnimation(crouchAmount)    
    return Clamp(crouchAmount * (1 - ( (self:GetVelocityLength() - kMaxSpeed) / (kMaxSpeed * 0.5))), 0, 1)
end

/*function Fade:GetExtentsCrouchShrinkAmount()
    return ConditionalValue(self:GetIsOnGround() or not self:GetPreventCrouchExtents(), Player.GetExtentsCrouchShrinkAmount(self), 0)
end*/

function Fade:GetMaxViewOffsetHeight()
    return kViewOffsetHeight
end

function Fade:GetViewModelName()
    return kViewModelName
end

function Fade:GetControllerPhysicsGroup()
    return PhysicsGroup.BigPlayerControllersGroup
end

function Fade:GetCanStep()
    return not self:GetIsBlinking()
end

function Fade:OnTakeFallDamage()
//Fades take no falling damage
end

function Fade:GetMaxSpeed(possible)

    if possible then
        return kMaxSpeed
    end
    
    local maxSpeed = kMaxSpeed
        
    if self.movementModiferState and self:GetIsOnGround() then
        maxSpeed = kWalkSpeed
    end
    
    if self:GetCrouching() and self:GetCrouchAmount() == 1 and self:GetIsOnGround() and not self:GetLandedRecently() then
        maxSpeed = kCrouchedSpeed
    end
        
    return maxSpeed + self:GetMovementSpeedModifier()
end

function Fade:GetCollisionSlowdownFraction()
    return 0.05
end

//Vanilla NS2
function Fade:GetSimpleAcceleration(onGround)
    return ConditionalValue(onGround, 11, Player.GetSimpleAcceleration(self, onGround))
end

function Fade:GetAirControl()
    return 40
end

function Fade:GetSimpleFriction(onGround)
    if onGround then
        return 9
    else
        if self:GetIsBlinking() then
            return 0
        end
        local hasupg, level = GetHasCelerityUpgrade(self)
        return 0.17 - (hasupg and level or 0) * 0.01
    end
end 
//End Vanilla NS2

function Fade:GetMass()
    return kMass 
end

function Fade:GetIsBlinking()
    return self.ethereal and self:GetIsAlive()
end

function Fade:OnBlink()
    self:SetIsOnGround(false)
    self:SetIsJumping(true)
    self.ethereal = true
    self:TriggerEffects("blink_out")
end

function Fade:ModifyVelocity(input, velocity, deltaTime)

    PROFILE("Fade:ModifyVelocity")

    if self:GetIsBlinking() then
    
        // Blink impulse
        local zAxis = self:GetViewCoords().zAxis
        velocity:Add( zAxis * kBlinkImpulseForce * deltaTime )
        
        if self:GetIsOnGround() or self:GetIsCloseToGround(kFadeBlinkAutoJumpGroundDistance) then
            self:GetJumpVelocity(input, velocity)
        end
        
        self:DeductAbilityEnergy(kBlinkEnergyCostPerSecond * deltaTime)
        
        if self:GetEnergy() < kStartBlinkEnergyCost then
            self:OnBlinkEnd()
        end
        
    end
    
end

function Fade:PostUpdateMove(input, runningPrediction)

    if self:GetIsBlinking() then
        self:SetIsJumping(true)
        self:SetIsOnGround(false)
    end
    
end

function Fade:GetHasMetabolizeAnimationDelay()
    return self.timeMetabolize + kMetabolizeAnimationDelay > Shared.GetTime()
end

function Fade:OnUpdateAnimationInput(modelMixin)

    if not self:GetHasMetabolizeAnimationDelay() then
    
        Alien.OnUpdateAnimationInput(self, modelMixin)
        
    else
    
        local weapon = self:GetActiveWeapon()
        if weapon ~= nil and weapon.OnUpdateAnimationInput and weapon:GetMapName() == Metabolize.kMapName then
            weapon:OnUpdateAnimationInput(modelMixin)
        end
        
    end

end

function Fade:OnBlinkEnd()
    if self:GetIsOnGround() then
        self:SetIsJumping(false)
    end
    self.ethereal = false
    self:TriggerEffects("blink_in")
end

local kEngageOffset = Vector(0, 0.8, 0)
function Fade:GetEngagementPointOverride()
    return self:GetOrigin() + kEngageOffset
end

Shared.LinkClassToMap("Fade", Fade.kMapName, networkVars, true)