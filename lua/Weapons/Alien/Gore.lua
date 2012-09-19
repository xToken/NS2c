// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Gore.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com) and
//                  Urwalek Andreas (andi@unknownworlds.com)
//
// Basic goring attack. Can also be used to smash down locked or welded doors.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/StompMixin.lua")

class 'Gore' (Ability)

Gore.kMapName = "gore"

local kAnimationGraph = PrecacheAsset("models/alien/onos/onos_view.animation_graph")

local networkVars =
{
    lastPrimaryAttackTime = "time"
}

AddMixinNetworkVars(StompMixin, networkVars)

local kAttackRadius = 1.5
local kAttackOriginDistance = 2
local kAttackRange = 2.2

local function GetHasAttackDelay(self, player)

    local attackDelay = ConditionalValue( player:GetIsPrimaled(), (kGoreDelay / kPrimalScreamROFIncrease), kGoreDelay)
    local upg, level = GetHasFocusUpgrade(player)
    if upg and level > 0 then
        attackDelay = AdjustAttackDelayforFocus(attackDelay, level)
    end
    return self.lastPrimaryAttackTime + attackDelay > Shared.GetTime()
    
end

// required here to deals different damage depending on if we are goring
function Gore:GetDamageType()
    return kGoreDamageType
end    

function Gore:OnCreate()

    Ability.OnCreate(self)
    
    InitMixin(self, StompMixin)
    self.lastPrimaryAttackTime = 0
    
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

function Gore:OnHolster(player)

    Ability.OnHolster(self, player)
    
    self:OnAttackEnd()
    
end

function Gore:GetIconOffsetY(secondary)
    return kAbilityOffset.Gore
end

function Gore:OnTag(tagName)

    PROFILE("Gore:OnTag")

    if tagName == "hit" then
    
        local player = self:GetParent()
        if player and not GetHasAttackDelay(self, player) then
        
            self.lastPrimaryAttackTime = Shared.GetTime()
            //local didHit, impactPoint, target = self:Attack(player)
            local didHit, target, endPoint = AttackMeleeCapsule(self, player, kGoreDamage, kAttackRange)
            self.lastPrimaryAttackTime = Shared.GetTime()
            self:TriggerEffects("gore_attack")
            player:DeductAbilityEnergy(self:GetEnergyCost())
            if didHit then

            end
        end
    end    

end

function Gore:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() and not GetHasAttackDelay(self, player) then
        self.primaryAttacking = true
    else
        self:OnAttackEnd()
    end 

end

function Gore:OnPrimaryAttackEnd(player)
    
    Ability.OnPrimaryAttackEnd(self, player)
    self:OnAttackEnd()
    
end

function Gore:GetPrimaryAttackUsesFocus()
    return true
end

function Gore:GetisUsingPrimaryAttack()
    return self.primaryAttacking
end

function Gore:OnAttackEnd()
    self.primaryAttacking = false
end

function Gore:GetEffectParams(tableParams)

    Ability.GetEffectParams(self, tableParams)
    
end

function Gore:OnUpdateAnimationInput(modelMixin)

    local activityString = "none"
    local abilityString = "gore"
    local attackMarine = false   
    
    if self.primaryAttacking then
        activityString = "primary"        
    end
   
    modelMixin:SetAnimationInput("ability", abilityString) 
    modelMixin:SetAnimationInput("activity", activityString)
    modelMixin:SetAnimationInput("attack_marine", attackMarine)
    
end

Shared.LinkClassToMap("Gore", Gore.kMapName, networkVars)