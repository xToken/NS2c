// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\StabBlink.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Left-click to stab (with both claws), right-click to do the massive rising up and 
// downward attack, with both claws. Insta-kill.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Blink.lua")

class 'StabBlink' (Blink)

StabBlink.kMapName = "stab"

local networkVars =
{
    primaryAttacking = "boolean",
    primaryBlocked = "boolean"
}

// Balance
StabBlink.kDamage = kStabDamage
StabBlink.kPrimaryEnergyCost = kStabEnergyCost
StabBlink.kDamageType = kStabDamageType
StabBlink.kRange = 2.6
StabBlink.kStabDuration = 1

local kAnimationGraph = PrecacheAsset("models/alien/fade/fade_view.animation_graph")

function StabBlink:OnCreate()

    Blink.OnCreate(self)
    
    self.primaryBlocked = false
    self.primaryAttacking = false

end

function StabBlink:GetAnimationGraphName()
    return kAnimationGraph
end

function StabBlink:GetPrimaryEnergyCost(player)
    return StabBlink.kPrimaryEnergyCost
end

function StabBlink:GetHUDSlot()
    return 2
end

function StabBlink:GetDeathIconIndex()
    return kDeathMessageIcon.SwipeBlink
end

function StabBlink:GetIconOffsetY(secondary)
    return kAbilityOffset.StabBlink
end

function StabBlink:GetBlinkAllowed()
    return not self.primaryBlocked
end

function StabBlink:ConstrainMoveVelocity(moveVelocity)

    if self.primaryBlocked then
        moveVelocity:Scale(0.2)
    end
    
end

// prevent jumping during stab to prevent exploiting
function StabBlink:GetCanJump()
    return not self.primaryBlocked
end

function StabBlink:OnProcessMove(input)

    Blink.OnProcessMove(self, input)
    
    // We need to clear this out in OnProcessMove (rather than ProcessMoveOnWeapon)
    // since this will get called after the view model has been updated from
    // Player:OnProcessMove. 
    self.primaryAttacking = false

end

function StabBlink:OnPrimaryAttack(player)

    if not self:GetIsBlinking() and Shared.GetTime() - self.etherealEndTime > 1 and player:GetEnergy() >= self:GetEnergyCost() then
    
        self.primaryAttacking = true
        self.primaryBlocked = true
        
    end
    
end

function StabBlink:OnHolster(player)

    Blink.OnHolster(self, player)
    
    self.primaryAttacking = false
    self.primaryBlocked = false
    
end

local function PerformMeleeAttack(self)

    local player = self:GetParent()
    if player then
        local didHit, hitObject, endPoint, surface = AttackMeleeCapsule(self, player, StabBlink.kDamage, StabBlink.kRange)
    end
    
end

function StabBlink:OnTag(tagName)

    PROFILE("StabBlink:OnTag")

    if self.primaryBlocked then
    
        if tagName == "start" then
        
            local player = self:GetParent()
            if player then
                player:DeductAbilityEnergy(self:GetEnergyCost())
            end
            
            self:TriggerEffects("stab_attack")
            
        elseif tagName == "attack_end" then
            self.primaryBlocked = false
        end
        
    end
    
    if tagName == "hit" then
        PerformMeleeAttack(self)
    end
    
end

function StabBlink:OnUpdateAnimationInput(modelMixin)

    PROFILE("StabBlink:OnUpdateAnimationInput")

    Blink.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("ability", "stab")
    
    local activityString = (self.primaryAttacking and "primary") or "none"
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("StabBlink", StabBlink.kMapName, networkVars)