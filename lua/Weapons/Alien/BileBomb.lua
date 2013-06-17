// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\BileBomb.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Bomb.lua")
Script.Load("lua/Weapons/Alien/HealSprayMixin.lua")

class 'BileBomb' (Ability)

BileBomb.kMapName = "bilebomb"

// part of the players velocity is use for the bomb
local kPlayerVelocityFraction = 0.5
local kBombVelocity = 10

local kAnimationGraph = PrecacheAsset("models/alien/gorge/gorge_view.animation_graph")

local kBbombViewEffect = PrecacheAsset("cinematics/alien/gorge/bbomb_1p.cinematic")

local networkVars =
{
    firingPrimary = "boolean"
}

AddMixinNetworkVars(HealSprayMixin, networkVars)

function BileBomb:OnCreate()

    Ability.OnCreate(self)
    
    self.firingPrimary = false
    self.timeLastBileBomb = 0
    
    InitMixin(self, HealSprayMixin)
    
end

function BileBomb:GetAnimationGraphName()
    return kAnimationGraph
end

function BileBomb:GetEnergyCost(player)
    return kBileBombEnergyCost
end

function BileBomb:GetIconOffsetY(secondary)
    return kAbilityOffset.BileBomb
end

function BileBomb:GetHUDSlot()
    return 3
end

function BileBomb:GetSecondaryTechId()
    return kTechId.Spray
end


function BileBomb:OnTag(tagName)

    PROFILE("BileBomb:OnTag")

    if self.firingPrimary and tagName == "shoot" then
    
        local player = self:GetParent()
        
        if player then
        
            self:FireBombProjectile(player)
            
            player:DeductAbilityEnergy(self:GetEnergyCost())            
            self.timeLastBileBomb = Shared.GetTime()
            
            self:TriggerEffects("bilebomb_attack")
            
            if Client then
            
                local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
                cinematic:SetCinematic(kBbombViewEffect)
                
            end
            
            TEST_EVENT("BileBomp shot")
            
        end
    
    end
    
end

function BileBomb:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() then
    
        self.firingPrimary = true
        
    else
        self.firingPrimary = false
    end  
    
end

function BileBomb:OnPrimaryAttackEnd(player)

    Ability.OnPrimaryAttackEnd(self, player)
    
    self.firingPrimary = false
    
end

function BileBomb:GetTimeLastBomb()
    return self.timeLastBileBomb
end

function BileBomb:FireBombProjectile(player)

    PROFILE("BileBomb:FireBombProjectile")
    
    if not Predict then
    
        local viewAngles = player:GetViewAngles()
        local velocity = player:GetVelocity()
        local viewCoords = viewAngles:GetCoords()
        local startPoint = player:GetEyePos() + viewCoords.zAxis * 0.3
        local startVelocity = velocity * kPlayerVelocityFraction + viewCoords.zAxis * kBombVelocity
        
        local rocket = player:CreatePredictedProjectile("Bomb", startPoint, startVelocity, nil, nil, 13, true)
    
        /*local viewAngles = player:GetViewAngles()
        local velocity = player:GetVelocity()
        local viewCoords = viewAngles:GetCoords()
        local startPoint = player:GetEyePos() + viewCoords.zAxis * 0.35
        
        local startPointTrace = Shared.TraceRay(player:GetEyePos(), startPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(player))
        startPoint = startPointTrace.endPoint
        
        local startVelocity = viewCoords.zAxis * kBombVelocity + velocity * kPlayerVelocityFraction
        
        local bomb = CreateEntity(Bomb.kMapName, startPoint, player:GetTeamNumber())
        bomb:Setup(player, startVelocity, true, nil, player)*/
        
    end
    
end

function BileBomb:OnUpdateAnimationInput(modelMixin)

    PROFILE("BileBomb:OnUpdateAnimationInput")

    modelMixin:SetAnimationInput("ability", "bomb")
    
    local activityString = "none"
    if self.firingPrimary then
        activityString = "primary"
    end
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("BileBomb", BileBomb.kMapName, networkVars)