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

//NS2c
//Changed many vars to local, removed unneeded movement and effect code.

Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/Gore.lua")
Script.Load("lua/Weapons/Alien/Smash.lua")
Script.Load("lua/Weapons/Alien/Devour.lua")
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
local kMaxChargeSpeed = 7
local kBonusChargeSpeed = 3
local kChargeAddSpeedTime = 2
local kMaxWalkSpeed = 2
local kChargeEnergyCost = 30
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

function Onos:EndCharge()

    local surface, normal = GetSurfaceAndNormalUnderEntity(self)

    // align zAxis to player movement
    local moveDirection = self:GetVelocity()
    moveDirection:Normalize()
    
    //TriggerMomentumChangeEffects(self, surface, moveDirection, normal)
    
    self.charging = false
    self.timeLastChargeEnd = Shared.GetTime()

end

function Onos:GetCanCloakOverride()
    return not self:GetIsCharging()
end

function Onos:PreUpdateMove(input, runningPrediction)

    if self.charging then
        self:DeductAbilityEnergy(kChargeEnergyCost * input.time)
        if self:GetEnergy() == 0 or (self.timeLastCharge + 1 < Shared.GetTime() and self:GetVelocity():GetLengthXZ() < 4.5 ) then
            self:EndCharge()
        end
    end
    
end

function Onos:GetAngleSmoothRate()
    return 3
end

local function ClearDevourState(self)
    local devourWeapon = self:GetWeapon("devour")
    if devourWeapon and devourWeapon:IsDevouringPlayer() then
        devourWeapon:OnForceUnDevour()
    end
end

function Onos:OnKill(attacker, doer, point, direction)
    ClearDevourState(self)
    Alien.OnKill(self, attacker, doer, point, direction)
end

function Onos:OnRedemed()
    ClearDevourState(self)
end

function Onos:GetPlayerControllersGroup()
    return PhysicsGroup.BigPlayerControllersGroup
end

function Onos:EvolveAllowed()
    local devourWeapon = self:GetWeapon("devour")
    if devourWeapon and devourWeapon:IsDevouringPlayer() then
        return false
    end
    return true
end

function Onos:ChargeAmount()
    return math.max((Shared.GetTime() - self.timeLastCharge) / kChargeAddSpeedTime, 1)
end

function Onos:TriggerCharge(move)
    
    if not self.charging and self.timeLastChargeEnd + kChargeDelay < Shared.GetTime() and not self:GetCrouching() and self:GetHasOneHive() and self:GetEnergy() > kStartChargeEnergyCost then

        self.charging = true
        self.timeLastCharge = Shared.GetTime()
        
        if Server and not GetHasSilenceUpgrade(self) then
        
            StartSoundEffectAtOrigin(kChargeStart, self:GetOrigin())
            self:TriggerEffects("onos_charge")
        
        end
        
        self:TriggerUncloak()
        self:DeductAbilityEnergy(kStartChargeEnergyCost)
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

function Onos:GetBaseHealth()
    return kOnosHealth
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
        maxSpeed = kMaxSpeed + (kBonusChargeSpeed * self:ChargeAmount())
    end
    
    if self:GetCrouching() and self:GetCrouchAmount() == 1 and self:GetIsOnSurface() and not self:GetLandedRecently() then
        maxSpeed = kMaxWalkSpeed
    end

    return maxSpeed + self:GetMovementSpeedModifier()

end

// Half a ton
function Onos:GetMass()
    return kMass
end

local kOnosEngageOffset = Vector(0, 1.3, 0)
function Onos:GetEngagementPointOverride()
    return self:GetOrigin() + kOnosEngageOffset
end

Shared.LinkClassToMap("Onos", Onos.kMapName, networkVars)