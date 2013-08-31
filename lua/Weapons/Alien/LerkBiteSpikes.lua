// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\LerkBite.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
// 
// Bite is main attack, Spikes is secondary.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

Shared.PrecacheSurfaceShader("materials/effects/mesh_effects/view_blood.surface_shader")

local kStructureHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_structure.cinematic")
local kMarineHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_marine.cinematic")

class 'LerkBiteSpikes' (Ability)

LerkBiteSpikes.kMapName = "lerkbitespikes"

local kAnimationGraph = PrecacheAsset("models/alien/lerk/lerk_view.animation_graph")
local attackEffectMaterial = nil
local kSpread = Math.Radians(4)
local kSpikeSize = 0.03

if Client then
    attackEffectMaterial = Client.CreateRenderMaterial()
    attackEffectMaterial:SetMaterial("materials/effects/mesh_effects/view_blood.material")
end

local networkVars =
{
    lastPrimaryAttackTime = "time",
    lastSecondaryAttackTime = "time",
    silenced = "boolean"
}

local function FireSpikes(self)

    local player = self:GetParent()    
    local viewAngles = player:GetViewAngles()
    viewAngles.roll = NetworkRandom() * math.pi * 2
    local shootCoords = viewAngles:GetCoords()
    
    // Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterOneAndIsa(player, "Babbler")
    local range = kSpikesRange
    
    local numSpikes = kSpikesPerShot
    local startPoint = player:GetEyePos()
    
    local viewCoords = player:GetViewCoords()
    
    self.spiked = true
    self.silenced = GetHasSilenceUpgrade(player)
    
    for spike = 1, numSpikes do

        // Calculate spread for each shot, in case they differ    
        local spreadDirection = CalculateSpread(viewCoords, kSpread, NetworkRandom) 

        local endPoint = startPoint + spreadDirection * range
        startPoint = player:GetEyePos()
        
        local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
        if not trace.entity then
            local extents = GetDirectedExtentsForDiameter(spreadDirection, kSpikeSize)
            trace = Shared.TraceBox(extents, startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
        end
        
        local distToTarget = (trace.endPoint - startPoint):GetLength()
        
        if trace.fraction < 1 then

            // Have damage increase to reward close combat
            local damageDistScalar = Clamp(1 - (distToTarget / kSpikeMinDamageRange), 0, 1)
            local damage = kSpikeMinDamage + damageDistScalar * (kSpikeMaxDamage - kSpikeMinDamage)
            local direction = (trace.endPoint - startPoint):GetUnit()
            self:DoDamage(damage, trace.entity, trace.endPoint - direction * kHitEffectOffset, direction, trace.surface, true, true, true)
                
        end
        
    end
    
end

local function GetHasAttackDelay(self, player)

    local attackDelay = kSpikesAttackDelay / player:GetAttackSpeed()
    return self.lastSecondaryAttackTime + attackDelay > Shared.GetTime()
    
end

function LerkBiteSpikes:OnCreate()

    Ability.OnCreate(self)
    
    self.primaryAttacking = false
    self.secondaryAttacking = false
    self.lastPrimaryAttackTime = 0
    self.lastSecondaryAttackTime = 0
    self.silenced = false
    if Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    end

end

function LerkBiteSpikes:GetAnimationGraphName()
    return kAnimationGraph
end

function LerkBiteSpikes:GetIconOffsetY(secondary)
    return kAbilityOffset.Spikes
end

function LerkBiteSpikes:GetEnergyCost(player)
    return kLerkBiteEnergyCost
end

function LerkBiteSpikes:GetSecondaryEnergyCost(player)
    return kSpikeEnergyCost
end

function LerkBiteSpikes:GetHUDSlot()
    return 4
end

function LerkBiteSpikes:GetDeathIconIndex()
    return kDeathMessageIcon.LerkBite
end

function LerkBiteSpikes:GetSecondaryTechId()
    return kTechId.Spikes
end

function LerkBiteSpikes:GetHasSecondary(player)
    return player:GetHasOneHive()
end

function LerkBiteSpikes:GetRange()
    return kLerkBiteRange
end

function LerkBiteSpikes:GetAttackDelay()
    return kLerkBiteDelay
end

function LerkBiteSpikes:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

function LerkBiteSpikes:GetDeathIconIndex()

    if self.primaryAttacking then
        return kDeathMessageIcon.Bite
    end
    
end

function LerkBiteSpikes:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() and not self:GetHasAttackDelay(self, player) then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end

function LerkBiteSpikes:OnSecondaryAttack(player)

    if player:GetEnergy() >= self:GetSecondaryEnergyCost(player) and not self.primaryAttacking then
        self.secondaryAttacking = true
    else
        self.secondaryAttacking = false
    end
    
end

function LerkBiteSpikes:OnPrimaryAttackEnd()
    Ability.OnPrimaryAttackEnd(self)
    self.primaryAttacking = false
end

function LerkBiteSpikes:OnSecondaryAttackEnd(player)
    Ability.OnSecondaryAttackEnd(self, player)    
    self.secondaryAttacking = false
end

function LerkBiteSpikes:GetAbilityUsesFocus()
    return true
end

function LerkBiteSpikes:GetMeleeBase()
    return kLerkBiteMeleeBaseWidth, kLerkBiteMeleeBaseHeight
end

function LerkBiteSpikes:GetMeleeOffset()
    return 0.0
end

function LerkBiteSpikes:GetBarrelPoint()

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

function LerkBiteSpikes:GetTriggerSecondaryEffects()

    local parent = self:GetParent()
    return parent ~= nil and parent:GetIsAlive()

end

function LerkBiteSpikes:OnTag(tagName)

    PROFILE("LerkBiteSpikes:OnTag")

    if tagName == "hit" then
    
        local player = self:GetParent()
        
        if player and not self:GetHasAttackDelay(self, player) then  
            
            player:DeductAbilityEnergy(self:GetEnergyCost())            
            self:TriggerEffects("lerkbite_attack")
            self.lastPrimaryAttackTime = Shared.GetTime()    
            local didHit, target = AttackMeleeCapsule(self, player, kLerkBiteDamage, self:GetRange(), nil, false, EntityFilterOneAndIsa(player, "Babbler"))
            
            if didHit and target then
            
                if Client then
                    self:TriggerFirstPersonHitEffects(player, target)
                end
            
            end
            
            if target and HasMixin(target, "Live") and not target:GetIsAlive() then
                self:TriggerEffects("bite_kill")
            end
            
        end
        
    end
    
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

function LerkBiteSpikes:GetIsSecondaryBlocking()
    return self.secondaryAttacking or GetHasAttackDelay(self, self:GetParent())
end

function LerkBiteSpikes:GetTracerEffectName()
    return kSpikeTracerEffectName
end

function LerkBiteSpikes:GetTracerResidueEffectName()

    local parent = self:GetParent()
    if parent and parent:GetIsLocalPlayer() then
        return kSpikeTracerFirstPersonResidueEffectName
    else
        return kSpikeTracerResidueEffectName
    end 
    
end

function LerkBiteSpikes:OnClientSecondaryAttacking()

    if not self.silenced then
        self:TriggerEffects("spikes_attack")
    end
    
end

if Client then

    function LerkBiteSpikes:TriggerFirstPersonHitEffects(player, target)

        if player == Client.GetLocalPlayer() and target then
            
            local cinematicName = kStructureHitEffect
            if target:isa("Marine") then
                self:CreateBloodEffect(player)        
                cinematicName = kMarineHitEffect
            end
        
            local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
            cinematic:SetCinematic(cinematicName)
        
        
        end

    end

    function LerkBiteSpikes:CreateBloodEffect(player)
    
        if not Shared.GetIsRunningPrediction() then

            local model = player:GetViewModelEntity():GetRenderModel()

            model:RemoveMaterial(attackEffectMaterial)
            model:AddMaterial(attackEffectMaterial)
            attackEffectMaterial:SetParameter("attackTime", Shared.GetTime())

        end
        
    end

end

function LerkBiteSpikes:OnUpdateAnimationInput(modelMixin)

    PROFILE("Bite:OnUpdateAnimationInput")

    if not self:GetIsSecondaryBlocking() then
        
        local activityString = "none"
        if self.primaryAttacking then
            modelMixin:SetAnimationInput("ability", "bite")
            activityString = "primary"
        end        
        
        modelMixin:SetAnimationInput("activity", activityString)
    
    end

    local player = self:GetParent()
    if player and self.secondaryAttacking and player:GetEnergy() >= self:GetSecondaryEnergyCost(player) then
        modelMixin:SetAnimationInput("activity", "secondary")
    end
    
end

function LerkBiteSpikes:GetDamageType()
	return kLerkBiteDamageType 
end

Shared.LinkClassToMap("LerkBiteSpikes", LerkBiteSpikes.kMapName, networkVars)