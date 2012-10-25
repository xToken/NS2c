// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\SpikesMixin.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

SpikesMixin = CreateMixin( SpikesMixin )
SpikesMixin.type = "Spikes"

local kSpread = Math.Radians(7)

// GetHasSecondary and GetSecondaryEnergyCost should completely override any existing
// same named function defined in the object.
SpikesMixin.overrideFunctions =
{
    "GetHasSecondary",
    "GetSecondaryEnergyCost",
    "GetBarrelPoint",
    "OnSecondaryAttack",
    "OnSecondaryAttackEnd",
    "GetTracerEffectName"
    
}

SpikesMixin.networkVars =
{
    shootingSpikes = "boolean",
    lastSecondaryAttackTime = "time",
    // need to use a network variable for silence upgrade here, since the marines do not know the alien tech tree
    silenced = "boolean"
}

function SpikesMixin:__initmixin()
    self.lastSecondaryAttackTime = 0
    shootginSpikes = false
    silenced = false
end

local function FireSpikes(self)

    local player = self:GetParent()    
    local viewAngles = player:GetViewAngles()
    viewAngles.roll = NetworkRandom() * math.pi * 2
    local shootCoords = viewAngles:GetCoords()
    
    // Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterTwo(player, self)
    local range = kSpikesRange
    
    local numSpikes = kSpikesPerShot
    local startPoint = player:GetEyePos()
    
    local viewCoords = player:GetViewCoords()
    
    self.spiked = true
    self.silenced = GetHasSilenceUpgrade(player)

    for spike = 1, numSpikes do

        // Calculate spread for each shot, in case they differ    
        local randomAngle  = NetworkRandom() * math.pi * 2
        local randomRadius = NetworkRandom() * NetworkRandom() * math.tan(kSpread)
        local spreadDirection = (viewCoords.xAxis * math.cos(randomAngle) + viewCoords.yAxis * math.sin(randomAngle))
        local fireDirection = viewCoords.zAxis + spreadDirection * randomRadius
        fireDirection:Normalize()  

        local endPoint = startPoint + fireDirection * range
        startPoint = player:GetEyePos()
        
        local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
  
        local distToTarget = (trace.endPoint - startPoint):GetLength()

        if trace.fraction < 1 then

            // Have damage increase to reward close combat
            local damageDistScalar = Clamp(1 - (distToTarget / kSpikeMinDamageRange), 0, 1)
            local damage = kSpikeMinDamage + damageDistScalar * (kSpikeMaxDamage - kSpikeMinDamage)
            local direction = (trace.endPoint - startPoint):GetUnit()
            self:DoDamage(damage, trace.entity, trace.endPoint - direction * kHitEffectOffset, direction, trace.surface, true)
                
        end
        
    end
    
end

local function GetHasAttackDelay(self, player)

    local attackDelay = ConditionalValue( player:GetIsPrimaled(), (kSpikesAttackDelay / kPrimalScreamROFIncrease), kSpikesAttackDelay)
    return self.lastSecondaryAttackTime + attackDelay > Shared.GetTime()
    
end

function SpikesMixin:GetTracerEffectName()
    return kSpikeTracerEffectName
end

function SpikesMixin:OnSecondaryAttack(player)

    if player:GetEnergy() >= self:GetSecondaryEnergyCost(player) and not self.primaryAttacking then
        self.secondaryAttacking = true
    else
        self.secondaryAttacking = false
    end
    
end

function SpikesMixin:OnSecondaryAttackEnd(player)

    Ability.OnSecondaryAttackEnd(self, player)    
    self.secondaryAttacking = false

end

function SpikesMixin:OnHolster()
    self.secondaryAttacking = false
end

function SpikesMixin:GetHasSecondary(player)
    return true
end

function SpikesMixin:GetSecondaryEnergyCost(player)
    return kSpikeEnergyCost
end

function SpikesMixin:GetBarrelPoint()

    local player = self:GetParent()
    
    if player then
    
        local viewCoords = player:GetViewCoords()
        local barrelPoint = viewCoords.origin + viewCoords.zAxis * 2 - viewCoords.yAxis * 0.1
        
        if self.shootLeft then
            barrelPoint = barrelPoint - viewCoords.xAxis * 0.3
        else
            barrelPoint = barrelPoint + viewCoords.xAxis * 0.3
        end
        
        self.shootLeft = not self.shootLeft
        
        return barrelPoint
        
    end

end

function SpikesMixin:OnTag(tagName)

    PROFILE("SpikesMixin:OnTag")

    if self.secondaryAttacking and tagName == "shoot" then
    
        local player = self:GetParent()
        if player and player:GetEnergy() > self:GetSecondaryEnergyCost() then
        
            FireSpikes(self)
            self.lastSecondaryAttackTime = Shared.GetTime()
            self:GetParent():DeductAbilityEnergy(self:GetSecondaryEnergyCost())

        else
            self.secondaryAttacking = false
        end
        
    end

end

function SpikesMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("SpikesMixin:OnUpdateAnimationInput")

    local player = self:GetParent()
    if player and self.secondaryAttacking and player:GetEnergy() >= self:GetSecondaryEnergyCost(player) then
        modelMixin:SetAnimationInput("activity", "secondary")
    end
    
end

function SpikesMixin:GetIsSecondaryBlocking()
    return self.secondaryAttacking or GetHasAttackDelay(self, self:GetParent())
end

function SpikesMixin:OnClientSecondaryAttacking()

    if not self.silenced then
        self:TriggerEffects("spikes_attack")
    end
    
end

function SpikesMixin:GetTriggerSecondaryEffects()

    local parent = self:GetParent()
    return parent ~= nil and parent:GetIsAlive()

end

function SpikesMixin:GetDamageType()
    return kSpikeDamageType
end