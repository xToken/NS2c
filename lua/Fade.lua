-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Fade.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- Role: Surgical striker, harassment
--
-- The Fade should be a fragile, deadly-sharp knife. Wielded properly, it's force is undeniable. But
-- used clumsily or without care will only hurt the user. Make sure Fade isn't better than the Skulk
-- in every way (notably, vs. Structures). To harass, he must be able to stay out in the field
-- without continually healing at base, and needs to be able to use blink often.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Modified for goldsource movement, also made most vars local

Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/SwipeBlink.lua")
-- Script.Load("lua/Weapons/Alien/Metabolize.lua")
Script.Load("lua/Weapons/Alien/AcidRocket.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")
Script.Load("lua/FadeVariantMixin.lua")

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
local kJumpHeight = 1.4
local kMaxSpeed = 4.8
local kWalkSpeed = 2
local kCrouchedSpeed = 1.8
local kBlinkImpulseForce = 85
local kFadeBlinkAutoJumpGroundDistance = 0.25
local kEtherealForce = 6
local kBlinkAddForce = 1
local kEtherealVerticalForce = 2
local kBlinkSpeed = 14
local kBlinkAcceleration = 40
local kBlinkAddAcceleration = 1
local kMetabolizeAnimationDelay = 0.65
local kBlinkMinEffectCooldown = 1
local kOffsetUpdate = 0
local kFadeOffsetRange = 1
local kFadeOffsetScalar = 5
kFadeCrouchModelOffset = 0.70

local networkVars =
{
    ethereal = "compensated boolean",
    timeMetabolize = "private compensated time",
    timeBlinked = "private compensated time",
    firstBlink = "private boolean",
    modelOffset = "compensated interpolated float", 
    updateOffset = "compensated boolean", 
    lastOffsetTime = "compensated time"
}

AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(FadeVariantMixin, networkVars)

function Fade:OnCreate()

    InitMixin(self, CameraHolderMixin, { kFov = kFadeFov })
    
    Alien.OnCreate(self)
    
    InitMixin(self, DissolveMixin)
    InitMixin(self, PredictedProjectileShooterMixin)
	InitMixin(self, FadeVariantMixin)
    self.ethereal = false
    self.firstBlink = false
    self.timeMetabolize = 0
    self.timeBlinked = 0
    self.updateOffset = false
    self.modelOffset = 0
    self.lastOffsetTime = 0
    
end

function Fade:OnInitialized()

    Alien.OnInitialized(self)
    self:SetModel(Fade.kModelName, kFadeAnimationGraph)
    
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
    return self:GetVariantViewModel(self:GetVariant())
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

function Fade:MovementModifierChanged(newMovementModifierState, input)
    if newMovementModifierState then
        if self:GetHasTwoHives() and not self:GetHasMetabolizeDelay() and self:GetEnergy() >= kMetabolizeEnergyCost then
            self.timeMetabolize = Shared.GetTime()
        end
    end
end

function Fade:GetHasMetabolizeDelay()
    return self.timeMetabolize + kMetabolizeDelay > Shared.GetTime()
end

function Fade:GetMaxSpeed(possible)

    if possible then
        return kMaxSpeed
    end
    
    local maxSpeed = kMaxSpeed
        
    /*if self.movementModiferState and self:GetIsOnGround() then
        maxSpeed = kWalkSpeed
    end*/
    
    if self:GetCrouching() and self:GetCrouchAmount() == 1 and self:GetIsOnGround() then
        maxSpeed = kCrouchedSpeed
    end
        
    return maxSpeed + self:GetMovementSpeedModifier()
end

function Fade:OnGroundChanged(onGround, impactForce, normal, velocity)

    Alien.OnGroundChanged(self, onGround, impactForce, normal, velocity)

    if onGround then
        self.landedAfterBlink = true
    end
    
end

function Fade:GetCollisionSlowdownFraction()
    return 0.05
end

function Fade:GetAcceleration()
    return 11
end

function Fade:GetAirControl()
    return 40
end

function Fade:ModifyGravityForce(gravityTable)
    if self:GetIsBlinking() then
        gravityTable.gravity = 0
    end
    Alien.ModifyGravityForce(self, gravityTable)
end

function Fade:GetAirFriction()
    if self:GetIsBlinking() then
        return 0
    end
    return 0.14
end
//End Vanilla NS2

function Fade:GetMass()
    return kMass 
end

function Fade:GetJumpHeight()
    return kJumpHeight
end

function Fade:GetIsBlinking()
    return self.ethereal and self:GetIsAlive()
end

function Fade:OnAdjustModelCoords(modelCoords)
    modelCoords.origin = modelCoords.origin - Vector(0, self.modelOffset, 0)
    return modelCoords
end

function Fade:OnBlink()

    if not self:GetIsBlinking() then
        //Impulse Blink from NS2
        local oldSpeed = self:GetVelocity():GetLengthXZ()
        local hasupg, level = GetHasCelerityUpgrade(self)
        local oldVelocity = self:GetVelocity()
        oldVelocity.y = 0
        local newSpeed = math.max(oldSpeed, kEtherealForce + ((hasupg and level or 0) * 0.5))
        local celerityMultiplier = 1 + (hasupg and level or 0 * 0.10)

        local newVelocity = self:GetViewCoords().zAxis * (kEtherealForce + (hasupg and level or 0) * 0.5) + oldVelocity
        self:SetVelocity(newVelocity)
        if newVelocity:GetLength() > newSpeed then
            newVelocity:Scale(newSpeed / newVelocity:GetLength())
        end
        
        if self:GetIsOnGround() then
            newVelocity.y = math.max(newVelocity.y, kEtherealVerticalForce)
        end
        
        newVelocity:Add(self:GetViewCoords().zAxis * kBlinkAddForce * celerityMultiplier)
        self:SetVelocity(newVelocity)

    end
    
    self.onGround = false
    self.jumping = true
    self.ethereal = true
    
    if self.timeBlinked + kBlinkMinEffectCooldown < Shared.GetTime() then
        self:TriggerEffects("blink_out")
        self.timeBlinked = Shared.GetTime()
    end
    
end

function Fade:ModifyVelocity(input, velocity, deltaTime)

    PROFILE("Fade:ModifyVelocity")

    if self:GetIsBlinking() then
    
        /*if self:HasAdvancedMovement() then
        
            //NS1 Style Blink.
            // Blink impulse
            local zAxis = self:GetViewCoords().zAxis
            velocity:Add( zAxis * kBlinkImpulseForce * deltaTime )
            
            if self:GetIsOnGround() or self:GetIsCloseToGround(kFadeBlinkAutoJumpGroundDistance) then
                self:GetJumpVelocity(input, velocity)
            end
            
        else*/
        
        //Vanilla Style Blink
        local wishDir = self:GetViewCoords().zAxis
        local hasupg, level = GetHasCelerityUpgrade(self)
        local prevSpeed = velocity:GetLength()
        local maxSpeed = math.max(prevSpeed, kBlinkSpeed + ((hasupg and level or 0) * 0.5))
        velocity:Add(wishDir * kBlinkAcceleration * deltaTime)
        maxSpeed = math.min(25, maxSpeed)   
        
        if velocity:GetLength() > maxSpeed then

            velocity:Normalize()
            velocity:Scale(maxSpeed)
            
        end 
        
        // additional acceleration when holding down blink to exceed max speed
        velocity:Add(wishDir * kBlinkAddAcceleration * deltaTime)   
        //end
        
        self:DeductAbilityEnergy(kBlinkEnergyCostPerSecond * deltaTime)
        
        if self:GetEnergy() < kStartBlinkEnergyCost then
            self:OnBlinkEnd()
        end
        
    end
    
    //Model offset for crouching blinking fades
    if self.lastOffsetTime + kOffsetUpdate < Shared.GetTime() then
        local origin = self:GetOrigin()
        //Trace up to make sure we are against the ceiling.
        //Default to no updates
        self.updateOffset = false
        local upTrace = Shared.TraceRay(origin, origin + Vector(0, Fade.YExtents + kFadeCrouchModelOffset, 0), CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOneAndIsa(self, "Babbler"))
        if upTrace.fraction > 0 and upTrace.fraction < 1 then
            //The ceiling is here.
            //Trace down to make sure we are not against the floor.
            local downTrace = Shared.TraceRay(origin, origin - Vector(0, kFadeCrouchModelOffset, 0), CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOne(self))
            if downTrace.fraction <= 0 or downTrace.fraction >= 1 then
                self.updateOffset = true
            end
        end
        self.lastOffsetTime = Shared.GetTime()
    end
    
    local crouchoffset = self:GetCrouchAmount() 
    local modelcrouchoffset = self:ModifyCrouchAnimation(crouchoffset)
    local maxoffset = (crouchoffset - modelcrouchoffset) * kFadeCrouchModelOffset
    if crouchoffset > 0 and self.updateOffset then
        if self.modelOffset < maxoffset then
            self.modelOffset = math.min(maxoffset, self.modelOffset + (input.time * kFadeOffsetScalar))
        end
    else
        if self.modelOffset > 0 then
            self.modelOffset = math.max(0, self.modelOffset - (input.time * kFadeOffsetScalar))
        end
    end
    
end

function Fade:PostUpdateMove(input, runningPrediction)

    if self:GetIsBlinking() then
        self.jumping = true
        self.onGround = false
    end
    
    Player.PostUpdateMove(self, input, runningPrediction)
end

function Fade:GetHasMetabolizeAnimationDelay()
    return self.timeMetabolize + kMetabolizeAnimationDelay > Shared.GetTime()
end

function Fade:ProcessMetabolizeTag(weapon, tagName)

    if tagName == "metabolize" then
        self:DeductAbilityEnergy(kMetabolizeEnergyCost)
        self:TriggerEffects("metabolize")
        local totalHealed = self:AddHealth(kMetabolizeHealthGain, false, false)
        if Client and totalHealed > 0 then
            local GUIRegenerationFeedback = ClientUI.GetScript("GUIRegenerationFeedback")
            GUIRegenerationFeedback:TriggerRegenEffect()
            local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
            cinematic:SetCinematic(kRegenerationViewCinematic)
        end
        self:AddEnergy(kMetabolizeEnergyGain)
    end

end

function Fade:OnUpdateAnimationInput(modelMixin)

    if not self:GetHasMetabolizeAnimationDelay() then
        Alien.OnUpdateAnimationInput(self, modelMixin)
    else
        modelMixin:SetAnimationInput("ability", "vortex")
        modelMixin:SetAnimationInput("activity", "primary")
    end

end

function Fade:OnBlinkEnd()
    if self:GetIsOnGround() then
        self.jumping = false
    end
    self.ethereal = false
    self:TriggerEffects("blink_in")
end

local kEngageOffset = Vector(0, 0.8, 0)
function Fade:GetEngagementPointOverride()
    return self:GetOrigin() + kEngageOffset
end

Shared.LinkClassToMap("Fade", Fade.kMapName, networkVars, true)