// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\LerkBite.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
// 
// Bite is main attack, Umbra is secondary.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/UmbraCloud.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

Shared.PrecacheSurfaceShader("materials/effects/mesh_effects/view_blood.surface_shader")

local kStructureHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_structure.cinematic")
local kMarineHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_marine.cinematic")

class 'LerkBiteUmbra' (Ability)

LerkBiteUmbra.kMapName = "lerkbiteumbra"

local kAnimationGraph = PrecacheAsset("models/alien/lerk/lerk_view.animation_graph")
local attackEffectMaterial = nil
local kRange = 20

if Client then
    attackEffectMaterial = Client.CreateRenderMaterial()
    attackEffectMaterial:SetMaterial("materials/effects/mesh_effects/view_blood.material")
end

local networkVars =
{
    lastPrimaryAttackTime = "time",
    lastSecondaryAttackTime = "time"
}

local function CreateUmbraCloud(self, player)

    local trace = Shared.TraceRay(player:GetEyePos(), player:GetEyePos() + player:GetViewCoords().zAxis * kRange, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterTwo(self, player))
    local destination = trace.endPoint + trace.normal * 2
    
    local umbraCloud = CreateEntity(UmbraCloud.kMapName, player:GetEyePos() + player:GetViewCoords().zAxis, player:GetTeamNumber())
    umbraCloud:SetOwner(player)
    umbraCloud:SetTravelDestination(destination)

end

local function GetHasAttackDelay(self, player)

    local attackDelay = kUmbraAttackDelay / player:GetAttackSpeed()
    return self.lastSecondaryAttackTime + attackDelay > Shared.GetTime()
    
end

function LerkBiteUmbra:OnCreate()

    Ability.OnCreate(self)

    self.primaryAttacking = false
    self.secondaryAttacking = false
    self.lastPrimaryAttackTime = 0
    self.lastSecondaryAttackTime = 0
    if Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    end

end

function LerkBiteUmbra:GetAnimationGraphName()
    return kAnimationGraph
end

function LerkBiteUmbra:GetIconOffsetY(secondary)
    return kAbilityOffset.Umbra
end

function LerkBiteUmbra:GetEnergyCost(player)
    return kLerkBiteEnergyCost
end

function LerkBiteUmbra:GetHasSecondary(player)
    return player.twoHives 
end

function LerkBiteUmbra:GetSecondaryEnergyCost(player)
    return kUmbraEnergyCost
end

function LerkBiteUmbra:GetHUDSlot()
    return 2
end

function LerkBiteUmbra:GetDeathIconIndex()
    return kDeathMessageIcon.LerkBite
end

function LerkBiteUmbra:GetSecondaryTechId()
    return kTechId.Umbra
end

function LerkBiteUmbra:GetRange()
    return kLerkBiteRange
end

function LerkBiteUmbra:GetAttackDelay()
    return kLerkBiteDelay
end

function LerkBiteUmbra:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

function LerkBiteUmbra:GetDeathIconIndex()

    if self.primaryAttacking then
        return kDeathMessageIcon.Bite
    end
    
end

function LerkBiteUmbra:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() and not self:GetHasAttackDelay(self, player) then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end

function LerkBiteUmbra:OnSecondaryAttack(player)

    if player:GetEnergy() >= self:GetSecondaryEnergyCost(player) and not self.primaryAttacking and not GetHasAttackDelay(self,player) then
        self:TriggerEffects("umbra_attack")
        if Server then
            CreateUmbraCloud(self, player)
            self:GetParent():DeductAbilityEnergy(self:GetSecondaryEnergyCost())
        end
        self.lastSecondaryAttackTime = Shared.GetTime()
        self.secondaryAttacking = true
    else
        self.secondaryAttacking = false
    end
    
end

function LerkBiteUmbra:OnPrimaryAttackEnd()
    
    Ability.OnPrimaryAttackEnd(self)
    self.primaryAttacking = false
    
end

function LerkBiteUmbra:OnSecondaryAttackEnd(player)

    Ability.OnSecondaryAttackEnd(self, player)    
    self.secondaryAttacking = false

end

function LerkBiteUmbra:GetAbilityUsesFocus()
    return true
end

function LerkBiteUmbra:GetMeleeBase()
    return kLerkBiteMeleeBaseWidth, kLerkBiteMeleeBaseHeight
end

function LerkBiteUmbra:GetMeleeOffset()
    return 0.0
end

function LerkBiteUmbra:OnTag(tagName)

    PROFILE("LerkBiteUmbra:OnTag")

    if tagName == "hit" then
    
        local player = self:GetParent()
        
        if player and not self:GetHasAttackDelay(self, player) then  
            
            player:DeductAbilityEnergy(self:GetEnergyCost())            
            player:TriggerEffects("lerkbite_attack")
            self.lastPrimaryAttackTime = Shared.GetTime()    
            local didHit, target = AttackMeleeCapsule(self, player, kLerkBiteDamage, self:GetRange(), nil, false, EntityFilterOneAndIsa(player, "Babbler"))
            
            if didHit and target then
            
                if Client then
                    self:TriggerFirstPersonHitEffects(player, target)
                end
            
            end
            
            if target and HasMixin(target, "Live") and not target:GetIsAlive() then
                player:TriggerEffects("bite_kill")
            end
            
        end
        
    end
    
end

if Client then

    function LerkBiteUmbra:TriggerFirstPersonHitEffects(player, target)

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

    function LerkBiteUmbra:CreateBloodEffect(player)
    
        if not Shared.GetIsRunningPrediction() then

            local model = player:GetViewModelEntity():GetRenderModel()

            model:RemoveMaterial(attackEffectMaterial)
            model:AddMaterial(attackEffectMaterial)
            attackEffectMaterial:SetParameter("attackTime", Shared.GetTime())

        end
        
    end

end

function LerkBiteUmbra:OnUpdateAnimationInput(modelMixin)

    PROFILE("Bite:OnUpdateAnimationInput")  
     
    local activityString = "none"
    local player = self:GetParent()
    if self.primaryAttacking then
        modelMixin:SetAnimationInput("ability", "bite")
        activityString = "primary"
    elseif self.secondaryAttacking then
        modelMixin:SetAnimationInput("ability", "umbra")
    elseif player and not GetHasAttackDelay(self, player) then
        modelMixin:SetAnimationInput("ability", "bite")
    end
    
    modelMixin:SetAnimationInput("activity", activityString)
    
end

function LerkBiteUmbra:GetDamageType()

	return kLerkBiteDamageType 
    
end

Shared.LinkClassToMap("LerkBiteUmbra", LerkBiteUmbra.kMapName, networkVars)