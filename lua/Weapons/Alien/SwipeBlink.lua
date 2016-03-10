// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\SwipeBlink.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Swipe/blink - Left-click to attack, right click to show ghost. When ghost is showing,
// right click again to go there. Left-click to cancel. Attacking many times in a row will create
// a cool visual "chain" of attacks, showing the more flavorful animations in sequence.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Blink.lua")

class 'SwipeBlink' (Blink)
SwipeBlink.kMapName = "swipe"

local networkVars =
{
    lastPrimaryAttackTime = "private time"
}

local kAnimationGraph = PrecacheAsset("models/alien/fade/fade_view.animation_graph")

function SwipeBlink:OnCreate()

    Blink.OnCreate(self)
    
    self.primaryAttacking = false
    self.lastPrimaryAttackTime = 0
    
end

function SwipeBlink:GetAnimationGraphName()
    return kAnimationGraph
end

function SwipeBlink:GetEnergyCost(player)
    return kSwipeEnergyCost
end

function SwipeBlink:GetHUDSlot()
    return 1
end

function SwipeBlink:GetPrimaryAttackRequiresPress()
    return false
end

function SwipeBlink:GetRange()
    return kSwipeRange
end

function SwipeBlink:GetMeleeBase()
    return kSwipeMeleeBaseWidth, kSwipeMeleeBaseHeight
end

function SwipeBlink:GetDeathIconIndex()
    return kDeathMessageIcon.Swipe
end

function SwipeBlink:GetSecondaryTechId()
    return kTechId.Blink
end

function SwipeBlink:GetBlinkAllowed()
    return true
end

function SwipeBlink:GetAttackDelay()
    return kSwipeDelay
end

function SwipeBlink:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

function SwipeBlink:GetKnockbackForce()
    return kSwipeKnockbackForce
end

function SwipeBlink:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() and not self:GetHasAttackDelay(player) then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end

function SwipeBlink:OnPrimaryAttackEnd()
    
    Blink.OnPrimaryAttackEnd(self)
    
    self.primaryAttacking = false
    
end

function SwipeBlink:GetAbilityUsesFocus()
    return true
end

function SwipeBlink:OnHolster(player)

    Blink.OnHolster(self, player)
    
    self.primaryAttacking = false
    
end

function SwipeBlink:OnTag(tagName)

    PROFILE("SwipeBlink:OnTag")
    
    local player = self:GetParent()
    if player then
        if self.primaryAttacking and tagName == "hit" then
            player:DeductAbilityEnergy(self:GetEnergyCost())
            player:TriggerEffects("swipe_attack")
            AttackMeleeCapsule(self, player, kSwipeDamage, self:GetRange(), nil, false, EntityFilterOneAndIsa(player, "Babbler"))
            self.lastPrimaryAttackTime = Shared.GetTime()
        end
        player:ProcessMetabolizeTag(self, tagName)
    end
end

function SwipeBlink:OnUpdateAnimationInput(modelMixin)

    PROFILE("SwipeBlink:OnUpdateAnimationInput")

    Blink.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("ability", "swipe")
    
    local activityString = (self.primaryAttacking and "primary") or "none"
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("SwipeBlink", SwipeBlink.kMapName, networkVars)