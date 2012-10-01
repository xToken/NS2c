// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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
    lastSwipedEntityId = "entityid",
    lastPrimaryAttackTime = "time"
}

SwipeBlink.kRange = 1.4

local kAnimationGraph = PrecacheAsset("models/alien/fade/fade_view.animation_graph")

local function GetHasAttackDelay(self, player)

    local attackDelay = ConditionalValue( player:GetIsPrimaled(), (kSwipeDelay / kPrimalScreamROFIncrease), kSwipeDelay)
    local upg, level = GetHasFocusUpgrade(player)
    if upg and level > 0 then
        attackDelay = AdjustAttackDelayforFocus(attackDelay, level)
    end
    return self.lastPrimaryAttackTime + attackDelay > Shared.GetTime()
    
end

function SwipeBlink:OnCreate()

    Blink.OnCreate(self)
    
    self.lastSwipedEntityId = Entity.invalidId
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

function SwipeBlink:GetIconOffsetY(secondary)
    return kAbilityOffset.Swipe
end

function SwipeBlink:GetPrimaryAttackRequiresPress()
    return false
end

function SwipeBlink:GetSecondaryTechId()
    return kTechId.Blink
end


function SwipeBlink:GetDeathIconIndex()
    return kDeathMessageIcon.Swipe
end

function SwipeBlink:GetBlinkAllowed()
    return true
end

function SwipeBlink:OnPrimaryAttack(player)

    if not self:GetIsBlinking() and player:GetEnergy() >= self:GetEnergyCost() and not GetHasAttackDelay(self, player) then
        //self:PerformPrimaryAttack(player)
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end

// Claw attack, or blink if we're in that mode
function SwipeBlink:PerformPrimaryAttack(player)

    self.primaryAttacking = true
    
    // Check if the swipe may hit an entity. Don't actually do any damage yet.
    local didHit, trace = CheckMeleeCapsule(self, player, kSwipeDamage, SwipeBlink.kRange)
    self.lastSwipedEntityId = Entity.invalidId
    if didHit and trace and trace.entity then
        self.lastSwipedEntityId = trace.entity:GetId()
    end
    
    return true
    
end

function SwipeBlink:OnPrimaryAttackEnd()
    
    Blink.OnPrimaryAttackEnd(self)
    
    self.primaryAttacking = false
    
end

function SwipeBlink:GetPrimaryAttackUsesFocus()
    return true
end

function SwipeBlink:GetisUsingPrimaryAttack()
    return self.primaryAttacking
end

function SwipeBlink:OnHolster(player)

    Blink.OnHolster(self, player)
    
    self.primaryAttacking = false
    
end

function SwipeBlink:OnTag(tagName)

    PROFILE("SwipeBlink:OnTag")

    if self.primaryAttacking and tagName == "start" then
    
        local player = self:GetParent()
        if player and not GetHasAttackDelay(self, player) then
        
            self.lastPrimaryAttackTime = Shared.GetTime()
            player:DeductAbilityEnergy(self:GetEnergyCost())
            self:TriggerEffects("swipe_attack")
        end
        
    end
    
    if tagName == "hit" then
        self:PerformMeleeAttack()
    end

end

function SwipeBlink:PerformMeleeAttack()

    local player = self:GetParent()
    if player then
        local didHit, hitObject, endPoint, surface = AttackMeleeCapsule(self, player, kSwipeDamage, SwipeBlink.kRange)
    end
    
end

function SwipeBlink:GetEffectParams(tableParams)

    Blink.GetEffectParams(self, tableParams)
    
    // There is a special case for biting structures.
    if self.lastSwipedEntityId ~= Entity.invalidId then
    
        local lastSwipedEntity = Shared.GetEntity(self.lastSwipedEntityId)
        if lastSwipedEntity and GetReceivesStructuralDamage(lastSwipedEntity) then
            tableParams[kEffectFilterHitSurface] = "structure"
        end
        
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