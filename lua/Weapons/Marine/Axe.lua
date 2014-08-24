// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Axe.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Moved balance vars to balance.lua

Script.Load("lua/Weapons/Weapon.lua")
Script.Load("lua/IdleAnimationMixin.lua")

class 'Axe' (Weapon)

Axe.kMapName = "axe"

Axe.kModelName = PrecacheAsset("models/marine/axe/axe.model")

local kViewModels = GenerateMarineViewModelPaths("axe")
local kAnimationGraph = PrecacheAsset("models/marine/axe/axe_view.animation_graph")

local networkVars = { }

local kAxeIdleAnimations = {"idle", "idle_toss", "idle_toss"}

function Axe:OnCreate()

    Weapon.OnCreate(self)
    
    if Client then
        InitMixin(self, IdleAnimationMixin)
    end
    
end

function Axe:OnInitialized()

    Weapon.OnInitialized(self)
    
    self:SetModel(Axe.kModelName)
    
end

function Axe:GetViewModelName(sex, variant)
    return kViewModels[sex][variant]
end

function Axe:GetAnimationGraphName()
    return kAnimationGraph
end

function Axe:GetHUDSlot()
    return kTertiaryWeaponSlot
end

function Axe:GetRange()
    return kAxeRange
end

function Axe:GetShowDamageIndicator()
    return true
end

function Axe:GetSprintAllowed()
    return false
end

function Axe:GetDeathIconIndex()
    return kDeathMessageIcon.Axe
end

function Axe:GetMeleeBase()
    // Width of box, height of box
    return kAxeMeleeBaseWidth, kAxeMeleeBaseHeight
end

function Axe:GetIdleAnimations()
    return kAxeIdleAnimations
end

function Axe:OnDraw(player, previousWeaponMapName)

    Weapon.OnDraw(self, player, previousWeaponMapName)
    
    // Attach weapon to parent's hand
    self:SetAttachPoint(Weapon.kHumanAttachPoint)
    
end

function Axe:OnHolster(player)

    Weapon.OnHolster(self, player)

    self.primaryAttacking = false
    
end

function Axe:OnPrimaryAttack(player)

    if not self.attacking then
        
        self.primaryAttacking = true
        
    end

end

function Axe:OnPrimaryAttackEnd(player)
    self.primaryAttacking = false
end

function Axe:OnTag(tagName)

    PROFILE("Axe:OnTag")

    if tagName == "swipe_sound" then
    
        local player = self:GetParent()
        if player then
            player:TriggerEffects("axe_attack")
        end
        
    elseif tagName == "hit" then
    
        local player = self:GetParent()
        if player then
            AttackMeleeCapsule(self, player, kAxeDamage, self:GetRange())
        end

	elseif tagName == "idle_toss_start" then
        self:TriggerEffects("axe_idle_toss")
    elseif tagName == "idle_fiddle_start" then
        self:TriggerEffects("axe_idle_fiddle")
    end
    
end

function Axe:OnUpdateAnimationInput(modelMixin)

    PROFILE("Axe:OnUpdateAnimationInput")

    local activity = "none"
    if self.primaryAttacking then
        activity = "primary"
    end
    modelMixin:SetAnimationInput("activity", activity)
    
end

Shared.LinkClassToMap("Axe", Axe.kMapName, networkVars)