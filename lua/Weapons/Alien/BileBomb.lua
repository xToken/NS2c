-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\BileBomb.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

--NS2c
--Bilebomb is now predicted

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Bomb.lua")
Script.Load("lua/Weapons/Alien/HealSprayMixin.lua")

class 'BileBomb' (Ability)

BileBomb.kMapName = "bilebomb"

-- part of the players velocity is use for the bomb
local kPlayerVelocityFraction = 0.5
local kBombVelocity = 10

local kAnimationGraph = PrecacheAsset("models/alien/gorge/gorge_view.animation_graph")

local kBbombViewEffect = PrecacheAsset("cinematics/alien/gorge/bbomb_1p.cinematic")

local networkVars = { }

AddMixinNetworkVars(HealSprayMixin, networkVars)

function BileBomb:OnCreate()

    Ability.OnCreate(self)
    
    self.primaryAttacking = false
    
    InitMixin(self, HealSprayMixin)
    
end

function BileBomb:GetAnimationGraphName()
    return kAnimationGraph
end

function BileBomb:GetEnergyCost(player)
    return kBileBombEnergyCost
end

function BileBomb:GetHUDSlot()
    return 3
end

function BileBomb:GetSecondaryTechId()
    return kTechId.Spray
end

function BileBomb:OnTag(tagName)

    PROFILE("BileBomb:OnTag")

    if self.primaryAttacking and tagName == "shoot" then
    
        local player = self:GetParent()
        
        if player then
        
            self:FireBombProjectile(player)
            
            player:DeductAbilityEnergy(self:GetEnergyCost())            
            
            self:TriggerEffects("bilebomb_attack")
            
            if Client then
            
                local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
                cinematic:SetCinematic(kBbombViewEffect)
                
            end
            
        end
    
    end
    
end

function BileBomb:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() then  
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end  
    
end

function BileBomb:OnPrimaryAttackEnd(player)

    Ability.OnPrimaryAttackEnd(self, player)
    
    self.primaryAttacking = false
    
end

function BileBomb:FireBombProjectile(player)

    PROFILE("BileBomb:FireBombProjectile")
    
    if Server or (Client and Client.GetIsControllingPlayer()) then
    
        local viewAngles = player:GetViewAngles()
        local velocity = player:GetVelocity()
        local viewCoords = viewAngles:GetCoords()
        local startPoint = player:GetEyePos() + viewCoords.zAxis
        local startVelocity = velocity * kPlayerVelocityFraction + viewCoords.zAxis * kBombVelocity

        local bomb = player:CreatePredictedProjectile("Bomb", startPoint, startVelocity, 0, 0, 13)
        
    end
    
end

function BileBomb:OnUpdateAnimationInput(modelMixin)

    PROFILE("BileBomb:OnUpdateAnimationInput")

    modelMixin:SetAnimationInput("ability", "bomb")
    
    local activityString = "none"
    if self.primaryAttacking then
        activityString = "primary"
    end
    modelMixin:SetAnimationInput("activity", activityString)
    
end

function BileBomb:GetDeathIconIndex()
    return kDeathMessageIcon.Spray
end

Shared.LinkClassToMap("BileBomb", BileBomb.kMapName, networkVars)
