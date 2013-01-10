// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\LerkBitePrimal.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
// 
// Bite is main attack, Primal Scream is secondary.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/PrimalScreamMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

Shared.PrecacheSurfaceShader("materials/effects/mesh_effects/view_blood.surface_shader")

local kStructureHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_structure.cinematic")
local kMarineHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_marine.cinematic")

class 'LerkBitePrimal' (Ability)

LerkBitePrimal.kMapName = "lerkbiteprimal"

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

AddMixinNetworkVars(PrimalScreamMixin, networkVars)

local function GetHasAttackDelay(self, player)

    local attackDelay = ConditionalValue( player:GetIsPrimaled(), (kLerkBiteDelay / kPrimalScreamROFIncrease), kLerkBiteDelay)
    local upg, level = GetHasFocusUpgrade(player)
    if upg and level > 0 then
        attackDelay = AdjustAttackDelayforFocus(attackDelay, level)
    end
    return self.lastPrimaryAttackTime + attackDelay > Shared.GetTime()
    
end

function LerkBitePrimal:OnCreate()

    Ability.OnCreate(self)
    
    InitMixin(self, PrimalScreamMixin)
    
    self.lastBittenEntityId = Entity.invalidId
    self.primaryAttacking = false
    self.lastPrimaryAttackTime = 0
    if Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    end

end

function LerkBitePrimal:GetAnimationGraphName()
    return kAnimationGraph
end

function LerkBitePrimal:GetEnergyCost(player)
    return kLerkBiteEnergyCost
end

function LerkBitePrimal:GetHUDSlot()
    return 3
end

function LerkBitePrimal:GetDeathIconIndex()
    return kDeathMessageIcon.LerkBite
end

function LerkBitePrimal:GetSecondaryTechId()
    return kTechId.PrimalScream
end

function LerkBitePrimal:GetRange()
    return kLerkBiteRange
end

function LerkBitePrimal:GetIconOffsetY(secondary)
    return kAbilityOffset.PrimalScream
end

function LerkBitePrimal:GetDeathIconIndex()

    if self.primaryAttacking then
        return kDeathMessageIcon.Bite
    end
    
end

function LerkBitePrimal:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost()  and not GetHasAttackDelay(self, player) then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end

function LerkBitePrimal:OnPrimaryAttackEnd()
    
    Ability.OnPrimaryAttackEnd(self)
    
    self.primaryAttacking = false
    
end

function LerkBitePrimal:GetPrimaryAttackUsesFocus()
    return true
end

function LerkBitePrimal:GetEffectParams(tableParams)

    Ability.GetEffectParams(self, tableParams)
    
    // There is a special case for biting structures.
    if self.lastBittenEntityId ~= Entity.invalidId then
    
        local lastBittenEntity = Shared.GetEntity(self.lastBittenEntityId)
        if lastBittenEntity and GetReceivesStructuralDamage(lastBittenEntity) then
            tableParams[kEffectFilterHitSurface] = "structure"
        end
        
    end
    
end

function LerkBitePrimal:GetMeleeBase()
    return kLerkBiteMeleeBaseWidth, kLerkBiteMeleeBaseHeight
end

function LerkBitePrimal:GetMeleeOffset()
    return 0.0
end

function LerkBitePrimal:OnTag(tagName)

    PROFILE("LerkBitePrimal:OnTag")

    if tagName == "hit" then
    
        local player = self:GetParent()
        
        if player and not GetHasAttackDelay(self, player) then  
            
            player:DeductAbilityEnergy(self:GetEnergyCost())            
            self:TriggerEffects("lerkbite_attack")
            self.lastPrimaryAttackTime = Shared.GetTime()    
            local didHit, target = AttackMeleeCapsule(self, player, kLerkBiteDamage, self:GetRange())
            
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

    function LerkBitePrimal:TriggerFirstPersonHitEffects(player, target)

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

    function LerkBitePrimal:CreateBloodEffect(player)
    
        if not Shared.GetIsRunningPrediction() then

            local model = player:GetViewModelEntity():GetRenderModel()

            model:RemoveMaterial(attackEffectMaterial)
            model:AddMaterial(attackEffectMaterial)
            attackEffectMaterial:SetParameter("attackTime", Shared.GetTime())

        end
        
    end

end

function LerkBitePrimal:OnUpdateAnimationInput(modelMixin)

    PROFILE("LerkBitePrimal:OnUpdateAnimationInput")

    if not self:GetIsSecondaryBlocking() then
        
        local activityString = "none"
        if self.primaryAttacking then
            modelMixin:SetAnimationInput("ability", "bite")
            activityString = "primary"
        end        
        
        modelMixin:SetAnimationInput("activity", activityString)
    
    end
    
end

function LerkBitePrimal:GetDamageType()

	return kLerkBiteDamageType 
    
end

Shared.LinkClassToMap("LerkBitePrimal", LerkBitePrimal.kMapName, networkVars)