-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\Gore.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com) and
--                  Urwalek Andreas (andi@unknownworlds.com)
--
-- Basic goring attack. Can also be used to smash down locked or welded doors.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

--NS2c
--Modified to only be gore, no smash

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/StompMixin.lua")

class 'Gore' (Ability)

Gore.kMapName = "gore"

local kAnimationGraph = PrecacheAsset("models/alien/onos/onos_view.animation_graph")

local networkVars =
{
    lastPrimaryAttackTime = "private time"
}

AddMixinNetworkVars(StompMixin, networkVars)

function Gore:OnCreate()

    Ability.OnCreate(self)
    
    InitMixin(self, StompMixin)
    self.lastPrimaryAttackTime = 0
    
end

-- required here to deals different damage depending on if we are goring
function Gore:GetDamageType()
    return kGoreDamageType
end

function Gore:GetDeathIconIndex()
    return kDeathMessageIcon.Gore
end

function Gore:GetAnimationGraphName()
    return kAnimationGraph
end

function Gore:GetEnergyCost(player)
    return kGoreEnergyCost
end

function Gore:GetHUDSlot()
    return 1
end

function Gore:GetRange()
    return kGoreRange
end

function Gore:GetMeleeBase()
    return kGoreMeleeBaseWidth, kGoreMeleeBaseHeight
end

function Gore:GetKnockbackForce()
    return kGoreKnockbackForce
end

function Gore:OnTag(tagName)

    PROFILE("Gore:OnTag")

    if tagName == "hit" then
    
        local player = self:GetParent()
        if player then
        
            local didHit, target, endPoint = AttackMeleeCapsule(self, player, kGoreDamage, self:GetRange(), nil, false, EntityFilterOneAndIsa(player, "Babbler"))
            self.lastPrimaryAttackTime = Shared.GetTime()
            self:TriggerEffects("gore_attack")
            player:DeductAbilityEnergy(self:GetEnergyCost())
            
        end
    end    

end

function Gore:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() and not self:GetHasAttackDelay(player) then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end 

end

function Gore:GetAttackDelay()
    return kGoreDelay
end

function Gore:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

function Gore:OnPrimaryAttackEnd(player)
    Ability.OnPrimaryAttackEnd(self, player)
    self.primaryAttacking = false
end

function Gore:GetAbilityUsesFocus()
    return true
end

function Gore:OnUpdateAnimationInput(modelMixin)

    local activityString = "none"   
    if self.primaryAttacking then
        activityString = "primary"        
    end
    modelMixin:SetAnimationInput("ability", "gore") 
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("Gore", Gore.kMapName, networkVars)