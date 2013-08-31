// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\LerkBite.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
// 
// Bite is main attack, Spores is secondary.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/SporeCloud.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

Shared.PrecacheSurfaceShader("materials/effects/mesh_effects/view_blood.surface_shader")

local kStructureHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_structure.cinematic")
local kMarineHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_marine.cinematic")

class 'LerkBite' (Ability)

LerkBite.kMapName = "lerkbite"

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

local function CreateSporeCloud(self, player)

    local trace = Shared.TraceRay(player:GetEyePos(), player:GetEyePos() + player:GetViewCoords().zAxis * kRange, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterTwo(self, player))
    local destination = trace.endPoint + trace.normal * 2
    
    local sporeCloud = CreateEntity(SporeCloud.kMapName, player:GetEyePos() + player:GetViewCoords().zAxis, player:GetTeamNumber())
    sporeCloud:SetOwner(player)
    sporeCloud:SetTravelDestination(destination)

end

local function GetHasAttackDelay(self, player)

    local attackDelay = kSporeAttackDelay / player:GetAttackSpeed()
    return self.lastSecondaryAttackTime + attackDelay > Shared.GetTime()
    
end

function LerkBite:OnCreate()

    Ability.OnCreate(self)

    self.primaryAttacking = false
    self.secondaryAttacking = false
    self.lastPrimaryAttackTime = 0
    self.lastSecondaryAttackTime = 0
    if Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    end

end

function LerkBite:GetAnimationGraphName()
    return kAnimationGraph
end

function LerkBite:GetEnergyCost(player)
    return kLerkBiteEnergyCost
end

function LerkBite:GetHasSecondary(player)
    return player:GetHasOneHive() 
end

function LerkBite:GetSecondaryEnergyCost(player)
    return kSporeEnergyCost
end

function LerkBite:GetHUDSlot()
    return 1
end

function LerkBite:GetDeathIconIndex()
    return kDeathMessageIcon.LerkBite
end

function LerkBite:GetSecondaryTechId()
    return kTechId.Spores
end

function LerkBite:GetRange()
    return kLerkBiteRange
end

function LerkBite:GetAttackDelay()
    return kLerkBiteDelay
end

function LerkBite:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

function LerkBite:GetDeathIconIndex()

    if self.primaryAttacking then
        return kDeathMessageIcon.Bite
    else
        return kDeathMessageIcon.Gas
    end
    
end

function LerkBite:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost()  and not self:GetHasAttackDelay(self, player) then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end

function LerkBite:OnSecondaryAttack(player)

    if player:GetEnergy() >= self:GetSecondaryEnergyCost(player) and not self.primaryAttacking and not GetHasAttackDelay(self,player) then
        self:TriggerEffects("spores_attack")
        if Server then
            CreateSporeCloud(self, player)
        end
        self:GetParent():DeductAbilityEnergy(self:GetSecondaryEnergyCost())
        self.lastSecondaryAttackTime = Shared.GetTime()
        self.secondaryAttacking = true
    else
        self.secondaryAttacking = false
    end
    
end

function LerkBite:OnPrimaryAttackEnd()
    
    Ability.OnPrimaryAttackEnd(self)
    
    self.primaryAttacking = false
    
end

function LerkBite:OnSecondaryAttackEnd(player)

    Ability.OnSecondaryAttackEnd(self, player)    
    self.secondaryAttacking = false

end

function LerkBite:GetAbilityUsesFocus()
    return true
end

function LerkBite:GetMeleeBase()
    return kLerkBiteMeleeBaseWidth, kLerkBiteMeleeBaseHeight
end

function LerkBite:GetMeleeOffset()
    return 0.0
end

function LerkBite:OnTag(tagName)

    PROFILE("LerkBite:OnTag")

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

    function LerkBite:TriggerFirstPersonHitEffects(player, target)

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

    function LerkBite:CreateBloodEffect(player)
    
        if not Shared.GetIsRunningPrediction() then

            local model = player:GetViewModelEntity():GetRenderModel()

            model:RemoveMaterial(attackEffectMaterial)
            model:AddMaterial(attackEffectMaterial)
            attackEffectMaterial:SetParameter("attackTime", Shared.GetTime())

        end
        
    end

end

function LerkBite:OnUpdateAnimationInput(modelMixin)

    PROFILE("Bite:OnUpdateAnimationInput")

    local activityString = "none"
    local player = self:GetParent()
    if self.primaryAttacking then
        modelMixin:SetAnimationInput("ability", "bite")
        activityString = "primary"
    elseif self.secondaryAttacking then
        modelMixin:SetAnimationInput("ability", "spores")
    elseif player and not GetHasAttackDelay(self, player) then
        modelMixin:SetAnimationInput("ability", "bite")
    end       
    
    modelMixin:SetAnimationInput("activity", activityString)
    
end

function LerkBite:GetDamageType()

	return kLerkBiteDamageType 
    
end

Shared.LinkClassToMap("LerkBite", LerkBite.kMapName, networkVars)