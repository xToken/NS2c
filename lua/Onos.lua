// Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Onos.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Gore attack should send players flying (doesn't have to be ragdoll). Stomp will stun
// structures in range. 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/Gore.lua")
Script.Load("lua/Weapons/Alien/Devour.lua")
Script.Load("lua/Weapons/Alien/Smash.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/DissolveMixin.lua")

class 'Onos' (Alien)

Onos.kMapName = "onos"
Onos.kModelName = PrecacheAsset("models/alien/onos/onos.model")
local kViewModelName = PrecacheAsset("models/alien/onos/onos_view.model")
local kOnosAnimationGraph = PrecacheAsset("models/alien/onos/onos.animation_graph")

local kChargeStart = PrecacheAsset("sound/NS2.fev/alien/onos/wound_serious")

if Server then
    Script.Load("lua/Onos_Server.lua")
elseif Client then
    Script.Load("lua/Onos_Client.lua")
end

Onos.XExtents = .7
Onos.YExtents = 1.0
Onos.ZExtents = .4

local kMass = 453 // Half a ton
local kViewOffsetHeight = 2.5
local kMomentumEffectTriggerDiff = 3
local kMaxSpeed = 4.5
local kMaxChargeSpeed = 11
local kMaxWalkSpeed = 2
local kChargeEnergyCost = 50
local kChargeAcceleration = 40
local kChargeUpDuration = 0.4
local kChargeDelay = 0.1
local kDefaultAttackSpeed = 1.1

local networkVars =
{
    charging = "private boolean"
}

AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)

function Onos:OnCreate()

    InitMixin(self, CameraHolderMixin, { kFov = kOnosFov })
    
    Alien.OnCreate(self)
    
    InitMixin(self, DissolveMixin)
    
    self.altAttack = false
    self.charging = true
    self.timeLastCharge = 0
    self.timeLastChargeEnd = 0
    self.chargeSpeed = 0
    
    if Client then    
        self:SetUpdates(true)
    end
    
end

function Onos:OnInitialized()

    Alien.OnInitialized(self)
    self:SetModel(Onos.kModelName, kOnosAnimationGraph)

end

function Onos:GetCrouchShrinkAmount()
    return 0.4
end

function Onos:GetExtentsCrouchShrinkAmount()
    return 0.4
end

function Onos:GetIsCharging()
    return self.charging
end

function Onos:GetCanJump()

    local weapon = self:GetActiveWeapon()
    local stomping = weapon and HasMixin(weapon, "Stomp") and weapon:GetIsStomping()

    return Alien.GetCanJump(self) and not stomping
end

function Onos:GetCanCrouch()
    return not self.charging
end

function Onos:GetAcceleration()
    local acceleration = Player.GetAcceleration(self)
    if self.charging then
        acceleration = acceleration + kChargeAcceleration * self:GetChargeFraction()  * 0.11
    end
    
    return acceleration
end

function Onos:GetChargeFraction()
    return ConditionalValue(self.charging, math.min(1, (Shared.GetTime() - self.timeLastCharge) / kChargeUpDuration ), 0)
end

function Onos:EndCharge()

    local surface, normal = GetSurfaceAndNormalUnderEntity(self)

    // align zAxis to player movement
    local moveDirection = self:GetVelocity()
    moveDirection:Normalize()
    
    //TriggerMomentumChangeEffects(self, surface, moveDirection, normal)
    
    self.charging = false
    self.chargeSpeed = 0
    self.timeLastChargeEnd = Shared.GetTime()

end

function Onos:GetCanCloakOverride()
    return not self:GetIsCharging()
end

function Onos:PreUpdateMove(input, runningPrediction)
    // determines how manuverable the onos is. When not charging, manuverability is 1. 
    // when charging it goes towards zero as the speed increased. At zero, you can't strafe or change
    // direction.
    // The math.sqrt makes you drop manuverability quickly at the start and then drop it less and less
    // the 0.8 cuts manuverability to zero before the max speed is reached
    // Fiddle until it feels right. 
    // 0.8 allows about a 90 degree turn in atrium, ie you can start charging
    // at the entrance, and take the first two stairs before you hit the lockdown.
    local manuverability = ConditionalValue(self.charging, math.max(0, 0.8 - math.sqrt(self:GetChargeFraction())), 1)

    if self.charging then

        // fiddle here to determine strafing 
        input.move.x = input.move.x * math.max(0.3, manuverability)
        input.move.z = 1
        
        self:DeductAbilityEnergy(kChargeEnergyCost * input.time)
    
        local xzViewDirection = self:GetViewCoords().zAxis
        xzViewDirection.y = 0
        xzViewDirection:Normalize()
        
        // stop charging if out of energy, jumping or we have charged for a second and our speed drops below 4.5
        // - changed from 0.5 to 1s, as otherwise touchin small obstactles orat started stopped you from charging 
        if self:GetEnergy() == 0 or 
           self:GetIsJumping() or
          (self.timeLastCharge + 1 < Shared.GetTime() and self:GetVelocity():GetLengthXZ() < 4.5 ) then
    
            self:EndCharge()
            
        end
            
    end

end

function Onos:GetAngleSmoothRate()
    return 3
end

function Onos:OnKill(attacker, doer, point, direction)
    local devourWeapon = self:GetWeapon("devour")
    if devourWeapon and devourWeapon:IsAlreadyEating() then
        devourWeapon:OnForceUnDevour()
    end
    Alien.OnKill(self, attacker, doer, point, direction)
end

function Onos:PostUpdateMove(input, runningPrediction)

    if self.charging then
    
        local xzSpeed = self:GetVelocity():GetLengthXZ()
        if xzSpeed > self.chargeSpeed then
            self.chargeSpeed = xzSpeed
        end    
    
    end

end

function Onos:TriggerCharge(move)
    
    if not self.charging and self.timeLastChargeEnd + kChargeDelay < Shared.GetTime() and self:GetIsOnGround() and not self:GetCrouching() and self:GetHasOneHive() then

        self.charging = true
        self.timeLastCharge = Shared.GetTime()
        
        if Server and not GetHasSilenceUpgrade(self) then
        
            StartSoundEffectAtOrigin(kChargeStart, self:GetOrigin())
            self:TriggerEffects("onos_charge")
        
        end
        
        self:TriggerUncloak()
    
    end
    
end

function Onos:HandleButtons(input)

    Alien.HandleButtons(self, input)

    if self.movementModiferState then
    
        self:TriggerCharge(input.move)
        
    else
    
        if self.charging then
            self:EndCharge()
        end
    
    end

end

// Required by ControllerMixin.
function Onos:GetMovePhysicsMask()
    return PhysicsMask.OnosMovement
end

function Onos:GetBaseArmor()
    return kOnosArmor
end

function Onos:GetArmorFullyUpgradedAmount()
    return kOnosArmorFullyUpgradedAmount
end

function Onos:GetViewModelName()
    return kViewModelName
end

function Onos:GetMaxViewOffsetHeight()
    return kViewOffsetHeight
end

function Onos:GetMaxSpeed(possible)

    if possible then
        return kMaxSpeed
    end
    
    local maxSpeed = kMaxSpeed
    
    if self.charging then
        maxSpeed = kMaxChargeSpeed
    end
    
    if self:GetCrouched() and self:GetIsOnSurface() then
        maxSpeed = kMaxWalkSpeed
    end

    return maxSpeed + self:GetMovementSpeedModifier()

end

// Half a ton
function Onos:GetMass()
    return kMass
end

local kOnosHeadMoveAmount = 0.0

// Give dynamic camera motion to the player
function Onos:OnUpdateCamera(deltaTime) 

    local camOffsetHeight = 0
    
    if not self:GetIsJumping() then
        camOffsetHeight = -self:GetMaxViewOffsetHeight() * self:GetCrouchShrinkAmount() * self:GetCrouchAmount()
    end
    
    self:SetCameraYOffset(camOffsetHeight)

end

function Onos:GetBaseAttackSpeed()
    return kDefaultAttackSpeed
end

local kOnosEngageOffset = Vector(0, 1.3, 0)
function Onos:GetEngagementPointOverride()
    return self:GetOrigin() + kOnosEngageOffset
end

Shared.LinkClassToMap("Onos", Onos.kMapName, networkVars)