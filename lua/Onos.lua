// Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Onos.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Gore attack should send players flying (doesn't have to be ragdoll). Stomp will disrupt
// structures in range. 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/Weapons/Alien/Gore.lua")
Script.Load("lua/Weapons/Alien/Devour.lua")
Script.Load("lua/Weapons/Alien/Smash.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/DissolveMixin.lua")

class 'Onos' (Alien)

Onos.kMapName = "onos"
Onos.kModelName = PrecacheAsset("models/alien/onos/onos.model")
Onos.kViewModelName = PrecacheAsset("models/alien/onos/onos_view.model")

local kOnosAnimationGraph = PrecacheAsset("models/alien/onos/onos.animation_graph")

local kChargeStart = PrecacheAsset("sound/NS2.fev/alien/onos/wound_serious")

Onos.kJumpForce = 20
Onos.kJumpVerticalVelocity = 8

Onos.kJumpRepeatTime = .25
Onos.kViewOffsetHeight = 2.5
Onos.XExtents = .7
Onos.YExtents = 1.0
Onos.ZExtents = .4
Onos.kMass = 453 // Half a ton
Onos.kJumpHeight = 1.2

// triggered when the momentum value has changed by this amount (negative because we trigger the effect when the onos stops, not accelerates)
Onos.kMomentumEffectTriggerDiff = 3
Onos.kGroundFrictionForce = 8
Onos.kBaseAcceleration = 58
Onos.kAirAcceleration = 28
Onos.kMaxSpeed = 16
Onos.kMaxCrouchSpeed = 3

Onos.kHealth = kOnosHealth
Onos.kArmor = kOnosArmor
Onos.kChargeEnergyCost = 50
Onos.kChargeAcceleration = 120
Onos.kChargeUpDuration = 0.4
Onos.kChargeDelay = 0.1
Onos.kMinChargeDamage = kChargeMinDamage
Onos.kMaxChargeDamage = kChargeMaxDamage
Onos.kChargeKnockbackForce = 4
Onos.kStoopingCheckInterval = 0.3
Onos.kStoopingAnimationSpeed = 2
Onos.kYHeadExtents = 0.0
Onos.kYHeadExtentsLowered = 0.0

local kAutoCrouchCheckInterval = 0.4

if Server then
    Script.Load("lua/Onos_Server.lua")
else
    Script.Load("lua/Onos_Client.lua")
end

local networkVars =
{
    stooping = "boolean",
    stoopIntensity = "compensated float",
    charging = "private boolean",
    devouring = "private entityid"
}

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)

function Onos:OnCreate()

    InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, GroundMoveMixin)
    InitMixin(self, CameraHolderMixin, { kFov = kOnosFov })
    
    Alien.OnCreate(self)
    
    InitMixin(self, DissolveMixin)
    
    self.altAttack = false
    self.stooping = false
    self.charging = true
    self.stoopIntensity = 0
    self.timeLastCharge = 0
    self.timeLastChargeEnd = 0
    self.chargeSpeed = 0
    self.devouring = nil
    self.timeSinceLastDevourUpdate = 0
    
    if Client then    
        self:SetUpdates(true)
    else
    
    end
    
end

function Onos:OnInitialized()

    Alien.OnInitialized(self)
    self:SetModel(Onos.kModelName, kOnosAnimationGraph)
    self:AddTimedCallback(Onos.UpdateStooping, Onos.kStoopingCheckInterval)

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
    return Alien.GetCanCrouch(self) and not self.charging
end

function Onos:GetAcceleration()

    local acceleration = Onos.kBaseAcceleration
    if not self:GetIsOnGround() then
        acceleration = Onos.kAirAcceleration
    end
    if self.charging then
        acceleration = Onos.kBaseAcceleration + (Onos.kChargeAcceleration - Onos.kBaseAcceleration) * self:GetChargeFraction() 
    end
    
    return acceleration * self:GetMovementSpeedModifier()
    
end

function Onos:GetChargeFraction()
    return ConditionalValue(self.charging, math.min(1, (Shared.GetTime() - self.timeLastCharge) / Onos.kChargeUpDuration ), 0)
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
        
        self:DeductAbilityEnergy(Onos.kChargeEnergyCost * input.time)
    
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

    if self.autoCrouching then
        self.crouching = self.autoCrouching
    end 

end

function Onos:GetAngleSmoothRate()
    return 3
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
    
    if not self.charging and self.timeLastChargeEnd + Onos.kChargeDelay < Shared.GetTime() and self:GetIsOnGround() and not self:GetCrouching() and self.oneHive then

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
    
    if not Shared.GetIsRunningPrediction() then
    
        if self.movementModiferState then
        
            self:TriggerCharge(input.move)
            
        else
        
            if self.charging then
                self:EndCharge()
            end
        
        end  
    
    end

end

// Required by ControllerMixin.
function Onos:GetMovePhysicsMask()
    return PhysicsMask.OnosMovement
end

function Onos:CheckEndDevour()

    if self.devouring ~= nil then
        local food = Shared.GetEntity(self.devouring)
        if food then
            if food.OnDevouredEnd then
                food:OnDevouredEnd()
            end
            if food.physicsModel then
                food.physicsModel:SetCollisionEnabled(true)
            end
        end
    end
    self.devouring = nil
    
end

function Onos:OnHiveTeleport()
    self:CheckEndDevour()
end

function Onos:GetBaseArmor()
    return Onos.kArmor
end

function Onos:GetArmorFullyUpgradedAmount()
    return kOnosArmorFullyUpgradedAmount
end

function Onos:GetViewModelName()
    return Onos.kViewModelName
end

function Onos:GetMaxViewOffsetHeight()
    return Onos.kViewOffsetHeight
end

function Onos:GetGroundFrictionForce()
    return Onos.kGroundFrictionForce
end

function Onos:GetMaxSpeed(possible)

    if possible then
        return 10
    end
    
    local maxSpeed = Onos.kMaxSpeed
    
    // Take into account crouching
    
    if self:GetCrouching() and self.onGround then
        maxSpeed = Onos.kMaxCrouchSpeed
    end

    return maxSpeed * self:GetMovementSpeedModifier()

end

// Half a ton
function Onos:GetMass()
    return Onos.kMass
end

function Onos:GetJumpHeight()
    return Onos.kJumpHeight
end

local kStoopPos = Vector(0, 2.6, 0)
function Onos:UpdateStooping(deltaTime)

    local topPos = self:GetOrigin() + kStoopPos
    topPos.y = topPos.y + Onos.kYHeadExtents
    
    local xzDirection = self:GetViewCoords().zAxis
    xzDirection.y = 0
    xzDirection:Normalize()
    
    local trace = Shared.TraceRay(topPos, topPos + xzDirection * 4, CollisionRep.Move, PhysicsMask.Movement, EntityFilterOne(self))
    
    if not self.stooping and not self.crouching then

        if trace.fraction ~= 1 then
        
            local stoopPos = self:GetEyePos()
            stoopPos.y = stoopPos.y + Onos.kYHeadExtentsLowered
            
            local traceStoop = Shared.TraceRay(stoopPos, stoopPos + xzDirection * 4, CollisionRep.Move, PhysicsMask.Movement, EntityFilterOne(self))
            if traceStoop.fraction == 1 then
                self.stooping = true                
            end
            
        end    

    elseif self.stoopIntensity == 1 and trace.fraction == 1 then
        self.stooping = false
    end

    
    return true

end

function Onos:UpdateAutoCrouch(move)
 
    local moveDirection = self:GetCoords():TransformVector(move)
    
    local extents = GetExtents(kTechId.Onos)
    local startPos1 = self:GetOrigin() + Vector(0, extents.y * self:GetCrouchShrinkAmount(), 0)
    
    local frontLeft = -self:GetCoords().xAxis * extents.x - self:GetCoords().zAxis * extents.z
    local backRight = self:GetCoords().xAxis * extents.x - self:GetCoords().zAxis * extents.z
    
    local startPos2 = self:GetOrigin() + frontLeft + Vector(0, extents.y * (1 - self:GetCrouchShrinkAmount()), 0)
    local startPos3 = self:GetOrigin() + backRight + Vector(0, extents.y * (1 - self:GetCrouchShrinkAmount()), 0)
    
    local trace1 = Shared.TraceRay(startPos1, startPos1 + moveDirection * 3, CollisionRep.Move, PhysicsMask.Movement, EntityFilterOne(self))
    local trace2 = Shared.TraceRay(startPos2, startPos2 + moveDirection * 3, CollisionRep.Move, PhysicsMask.Movement, EntityFilterOne(self))
    local trace3 = Shared.TraceRay(startPos3, startPos3 + moveDirection * 3, CollisionRep.Move, PhysicsMask.Movement, EntityFilterOne(self))
    
    if trace1.fraction == 1 and trace2.fraction == 1 and trace3.fraction == 1 then
        self.crouching = true
        self.autoCrouching = true
    end

end

function Onos:DevourUpdate()

    if self.devouring ~= nil then
        local food = Shared.GetEntity(self.devouring)
        local devour = self:GetWeapon("devour")
        if food and devour then
        
            if self.timeSinceLastDevourUpdate + Devour.kDigestionSpeed < Shared.GetTime() then   
                //Player still being eaten, damage them
                self.timeSinceLastDevourUpdate = Shared.GetTime()
                if devour:DoDamage(kDevourDamage , food, self:GetOrigin(), 0, "none" ) then
                    if food.OnDevouredEnd then 
                        food:OnDevouredEnd()
                    end
                    self.devouring = nil
                end
            end
            
            food:DestroyController()
            //Always update players POS relative to the onos
            food:SetOrigin(self:GetOrigin())
        else
            self.devouring = nil
        end
    end
    
end

function Onos:OnProcessMove(input)

    PROFILE("Onos:OnProcessMove")
    
    Alien.OnProcessMove(self, input)
    
    self:DevourUpdate()

    if self.stooping then    
        self.stoopIntensity = math.min(1, self.stoopIntensity + Onos.kStoopingAnimationSpeed * input.time)
    else    
        self.stoopIntensity = math.max(0, self.stoopIntensity - Onos.kStoopingAnimationSpeed * input.time)
    end
    
end

function Onos:OnUpdatePoseParameters(viewModel)

    PROFILE("Onos:OnUpdatePoseParameters")
    
    Alien.OnUpdatePoseParameters(self, viewModel)
    
    self:SetPoseParam("stoop", self.stoopIntensity)
    
end

function Onos:OnUpdateAnimationInput(modelMixin)

    PROFILE("Onos:OnUpdateAnimationInput")

    Alien.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("weapon", activeWeapon)

end

local kOnosHeadMoveAmount = 0.0

// Give dynamic camera motion to the player
function Onos:OnUpdateCamera(deltaTime) 

    local camOffsetHeight = 0
    
    if not self:GetIsJumping() then
        camOffsetHeight = -self:GetMaxViewOffsetHeight() * self:GetCrouchShrinkAmount() * self:GetCrouchAmount()
    end
    
    if self:GetIsFirstPerson() then
    
        if not self:GetIsJumping() then
        
            //local movementScalar = Clamp((self:GetVelocity():GetLength() / self:GetMaxSpeed(true)), 0.0, 0.8)
            //local bobbing = ( math.sin(Shared.GetTime() * 7) - 1 )
            //camOffsetHeight = camOffsetHeight + kOnosHeadMoveAmount * movementScalar * bobbing
            
        end
        
    end
    
    self:SetCameraYOffset(camOffsetHeight)

end

local kOnosEngageOffset = Vector(0, 1.3, 0)
function Onos:GetEngagementPointOverride()
    return self:GetOrigin() + kOnosEngageOffset
end

Shared.LinkClassToMap("Onos", Onos.kMapName, networkVars)