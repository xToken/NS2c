-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\SpitSpray.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- Spit attack on primary.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Spit.lua")
Script.Load("lua/Weapons/Alien/HealSprayMixin.lua")

class 'SpitSpray' (Ability)

SpitSpray.kMapName = "spitspray"

local kSpitSpeed = 20

local kAnimationGraph = PrecacheAsset("models/alien/gorge/gorge_view.animation_graph")

local kSpitViewEffect = PrecacheAsset("cinematics/alien/gorge/spit_1p.cinematic")
local kSpitProjectileEffect = PrecacheAsset("cinematics/alien/gorge/spit_1p_projectile.cinematic")
local kViewSpitMaterial = PrecacheAsset("materials/effects/mesh_effects/view_spit.material")
local attackEffectMaterial

if Client then

    attackEffectMaterial = Client.CreateRenderMaterial()
    attackEffectMaterial:SetMaterial(kViewSpitMaterial)
    
end

local networkVars =
{
    lastPrimaryAttackTime = "private time"
}

AddMixinNetworkVars(HealSprayMixin, networkVars)

function SpitSpray:OnCreate()

    Ability.OnCreate(self)
    
    self.primaryAttacking = false
    self.lastPrimaryAttackTime = 0

    InitMixin(self, HealSprayMixin)
    
end

function SpitSpray:GetAnimationGraphName()
    return kAnimationGraph
end

function SpitSpray:GetEnergyCost(player)
    return kSpitEnergyCost
end

function SpitSpray:GetHUDSlot()
    return 1
end

function SpitSpray:GetSecondaryTechId()
    return kTechId.Spray
end

function SpitSpray:GetPrimaryEnergyCost()
    return kSpitEnergyCost
end

function SpitSpray:GetAttackDelay()
    return kSpitDelay
end

function SpitSpray:GetAbilityUsesFocus()
    return true
end

function SpitSpray:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

local function CreateSpitProjectile(self, player)   

    if not Predict then
        
        local eyePos = player:GetEyePos()        
        local viewCoords = player:GetViewCoords()
        
        local startPointTrace = Shared.TraceCapsule(eyePos, eyePos + viewCoords.zAxis * 1.5, Spit.kRadius, 0, CollisionRep.Damage, PhysicsMask.PredictedProjectileGroup, EntityFilterOneAndIsa(player, "Babbler"))
        local startPoint = startPointTrace.endPoint
        
        local spit = player:CreatePredictedProjectile("Spit", startPoint, viewCoords.zAxis * kSpitSpeed, 0, 0, 0)
    
    end

end

function SpitSpray:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() and not self:GetHasAttackDelay(player) then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end

function SpitSpray:OnPrimaryAttackEnd(player)

    Ability.OnPrimaryAttackEnd(self, player)
    
    self.primaryAttacking = false
    
end

function SpitSpray:OnTag(tagName)

    PROFILE("SpitSpray:OnTag")

    if self.primaryAttacking and tagName == "shoot" then
    
        local player = self:GetParent()
        
        if player then
            
            self.lastPrimaryAttackTime = Shared.GetTime()
            if Server or (Client and Client.GetIsControllingPlayer()) then
                CreateSpitProjectile(self, player)
            end
            
            player:DeductAbilityEnergy(self:GetEnergyCost())
            
            self:TriggerEffects("spitspray_attack")
            
            if Client then
            
                local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
                cinematic:SetCinematic(kSpitViewEffect)
                
                local model = player:GetViewModelEntity():GetRenderModel()

                model:RemoveMaterial(attackEffectMaterial)
                model:AddMaterial(attackEffectMaterial)
                attackEffectMaterial:SetParameter("attackTime", Shared.GetTime())
                
            end
            
        end
        
    end
    
end

function SpitSpray:OnUpdateAnimationInput(modelMixin)

    PROFILE("SpitSpray:OnUpdateAnimationInput")

    modelMixin:SetAnimationInput("ability", "spit")
    
    local activityString = "none"
    if self.primaryAttacking then
        activityString = "primary"
    end
    modelMixin:SetAnimationInput("activity", activityString)
    
end

function SpitSpray:GetDeathIconIndex()
    return ConditionalValue(self.spitted, kDeathMessageIcon.Spit, kDeathMessageIcon.Spray)
end

Shared.LinkClassToMap("SpitSpray", SpitSpray.kMapName, networkVars)