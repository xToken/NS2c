// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\SpitSpray.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Spit attack on primary.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Spit.lua")
Script.Load("lua/Weapons/Alien/HealSprayMixin.lua")

class 'SpitSpray' (Ability)

SpitSpray.kMapName = "spitspray"

local kSpitSpeed = 55
local kSpitRange = 40

local kAnimationGraph = PrecacheAsset("models/alien/gorge/gorge_view.animation_graph")

local kSpitViewEffect = PrecacheAsset("cinematics/alien/gorge/spit_1p.cinematic")
local kSpitProjectileEffect = PrecacheAsset("cinematics/alien/gorge/spit_1p_projectile.cinematic")
local attackEffectMaterial = nil

if Client then

    attackEffectMaterial = Client.CreateRenderMaterial()
    attackEffectMaterial:SetMaterial("materials/effects/mesh_effects/view_spit.material")
    
end

local networkVars =
{
    lastPrimaryAttackTime = "time"
}

AddMixinNetworkVars(HealSprayMixin, networkVars)

function SpitSpray:OnCreate()

    Ability.OnCreate(self)
    
    self.primaryAttacking = false
    
    InitMixin(self, HealSprayMixin)
    self.lastPrimaryAttackTime = 0
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

    if Server then
        
        local viewAngles = player:GetViewAngles()
        local velocity = player:GetVelocity()
        local viewCoords = viewAngles:GetCoords()
        local startPoint = player:GetEyePos() + viewCoords.zAxis * 0.35

        local startVelocity = viewCoords.zAxis * kSpitSpeed + velocity * 0.5
        
        local spit = CreateEntity(Spit.kMapName, startPoint, player:GetTeamNumber())
        SetAnglesFromVector(spit, viewCoords.zAxis)
        spit:Setup(player, startVelocity, false, nil, player)
        
    end

end

local function CreatePredictedProjectile(self, player)

    local viewAngles = player:GetViewAngles()
    local viewCoords = viewAngles:GetCoords()
    local startPoint = player:GetEyePos() - viewCoords.yAxis * 0.2
    local trace = Shared.TraceRay(startPoint, player:GetEyePos() + viewCoords.zAxis * kSpitRange, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterAll())
    local endPoint = trace.endPoint
    local tracerVelocity = viewCoords.zAxis * kSpitSpeed

    if Client then
        CreateTracer(startPoint, endPoint, tracerVelocity, self, kSpitProjectileEffect)
    elseif Server then
    
        if not self.compensatedProjectiles then
            self.compensatedProjectiles = {}
        end    
    
        local compensatedProjectile = {}
        compensatedProjectile.velocity = Vector(tracerVelocity)
        compensatedProjectile.origin = Vector(startPoint)
        compensatedProjectile.endPoint = Vector(endPoint)
        compensatedProjectile.endTime = ((startPoint - endPoint):GetLength() / kSpitSpeed) + Shared.GetTime()
        
        table.insert(self.compensatedProjectiles, compensatedProjectile)
    
    end

end

function SpitSpray:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() and not self:GetHasAttackDelay(self, player) then
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
        
        if player and not self:GetHasAttackDelay(self, player) then
        
            self.lastPrimaryAttackTime = Shared.GetTime()
            CreateSpitProjectile(self, player)
            CreatePredictedProjectile(self, player)
            
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

function SpitSpray:GetDamageType()
    return ConditionalValue(self.spitted, kSpitDamageType, kHealsprayDamageType)
end

if Server then

    function SpitSpray:OnProcessMove(input)

        local player = self:GetParent()
        if self.compensatedProjectiles and player then
        
            local updateTable = {}
        
            for _, compensatedProjectile in ipairs(self.compensatedProjectiles) do
            
                if compensatedProjectile.endTime > Shared.GetTime() then
                
                    local trace = Shared.TraceRay(compensatedProjectile.origin, compensatedProjectile.origin + 3 * compensatedProjectile.velocity * input.time, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterTwo(self, player))
                    if trace.entity then
                    
                        self.spitted = true
                        self:DoDamage(kSpitDamage, trace.entity, compensatedProjectile.origin, trace.endPoint - compensatedProjectile.origin, trace.surface)
                        self.spitted = false
                        
                        if trace.entity:isa("Marine") then
                        
                            local direction = compensatedProjectile.origin - trace.entity:GetEyePos()
                            direction:Normalize()
                            
                        end
                        
                    else
                        compensatedProjectile.origin = compensatedProjectile.origin + input.time * compensatedProjectile.velocity
                        table.insert(updateTable, compensatedProjectile)
                    end
                
                end
            
            end
            
            self.compensatedProjectiles = updateTable
        
        end

    end

end

Shared.LinkClassToMap("SpitSpray", SpitSpray.kMapName, networkVars)