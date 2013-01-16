// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Axe.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Weapon.lua")

class 'Axe' (Weapon)

Axe.kMapName = "axe"

Axe.kModelName = PrecacheAsset("models/marine/axe/axe.model")
Axe.kViewModelName = PrecacheAsset("models/marine/axe/axe_view.model")
local kAnimationGraph = PrecacheAsset("models/marine/axe/axe_view.animation_graph")

local networkVars =
{
    sprintAllowed = "boolean",
}

function Axe:OnCreate()

    Weapon.OnCreate(self)
    
    self.sprintAllowed = true

end

function Axe:OnInitialized()

    Weapon.OnInitialized(self)
    
    self:SetModel(Axe.kModelName)

end

function Axe:GetViewModelName()
    return Axe.kViewModelName
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

// Max degrees that weapon can swing left or right
function Axe:GetSwingAmount()
    return 10
end

function Axe:GetShowDamageIndicator()
    return true
end

function Axe:GetSprintAllowed()
    return self.sprintAllowed
end

function Axe:GetDeathIconIndex()
    return kDeathMessageIcon.Axe
end

function Axe:GetMeleeBase()
    // Width of box, height of box
    return kAxeMeleeBaseWidth, kAxeMeleeBaseHeight
end

function Axe:OnDraw(player, previousWeaponMapName)

    Weapon.OnDraw(self, player, previousWeaponMapName)
    
    // Attach weapon to parent's hand
    self:SetAttachPoint(Weapon.kHumanAttachPoint)
    
end

function Axe:OnHolster(player)

    Weapon.OnHolster(self, player)
    
    self.sprintAllowed = true
    self.primaryAttacking = false
    
end

function Axe:OnPrimaryAttack(player)

    if not self.attacking then
        
        self.sprintAllowed = false
        self.primaryAttacking = true
        
    end

end

function Axe:OnPrimaryAttackEnd(player)
    self.primaryAttacking = false
end

function Axe:OnTag(tagName)

    PROFILE("Axe:OnTag")

    if tagName == "swipe_sound" then
        self:TriggerEffects("axe_attack")
    elseif tagName == "hit" then
    
        local player = self:GetParent()
        if player then
            AttackMeleeCapsule(self, player, kAxeDamage, self:GetRange())
        end
        
    elseif tagName == "attack_end" then
        self.sprintAllowed = true
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