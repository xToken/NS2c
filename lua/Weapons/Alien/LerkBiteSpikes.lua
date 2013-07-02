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
Script.Load("lua/Weapons/Alien/SpikesMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

Shared.PrecacheSurfaceShader("materials/effects/mesh_effects/view_blood.surface_shader")

local kStructureHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_structure.cinematic")
local kMarineHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_marine.cinematic")

class 'LerkBiteSpikes' (Ability)

LerkBiteSpikes.kMapName = "lerkbitespikes"

local kAnimationGraph = PrecacheAsset("models/alien/lerk/lerk_view.animation_graph")
local attackEffectMaterial = nil

if Client then
    attackEffectMaterial = Client.CreateRenderMaterial()
    attackEffectMaterial:SetMaterial("materials/effects/mesh_effects/view_blood.material")
end

local networkVars =
{
    lastBittenEntityId = "entityid",
    lastPrimaryAttackTime = "time"
}

AddMixinNetworkVars(SpikesMixin, networkVars)

function LerkBiteSpikes:OnCreate()

    Ability.OnCreate(self)
    
    InitMixin(self, SpikesMixin)
    
    self.lastBittenEntityId = Entity.invalidId
    self.primaryAttacking = false
    self.lastPrimaryAttackTime = 0
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

function LerkBiteSpikes:GetHUDSlot()
    return 4
end

function LerkBiteSpikes:GetDeathIconIndex()
    return kDeathMessageIcon.LerkBite
end

function LerkBiteSpikes:GetSecondaryTechId()
    return kTechId.Spikes
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

function LerkBiteSpikes:OnPrimaryAttackEnd()
    
    Ability.OnPrimaryAttackEnd(self)
    
    self.primaryAttacking = false
    
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
    
end

function LerkBiteSpikes:GetDamageType()

	return kLerkBiteDamageType 
    
end

Shared.LinkClassToMap("LerkBiteSpikes", LerkBiteSpikes.kMapName, networkVars)