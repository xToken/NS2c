// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Weapons\Alien\Blink.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Blink - Attacking many times in a row will create a cool visual "chain" of attacks, 
// showing the more flavorful animations in sequence. Base class for swipe and vortex,
// available at tier 2.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Adjusted blink impact and energy usage, also removed visual effects

Script.Load("lua/Weapons/Alien/Ability.lua")

class 'Blink' (Ability)
Blink.kMapName = "blink"

local kMinBlinkEffectTime = 1

local networkVars = { }

function Blink:OnCreate()

    Ability.OnCreate(self)
    self.lastblinkeffect = 0
    
end

function Blink:OnHolster(player)

    Ability.OnHolster(self, player)
    
    self:SetEthereal(player, false)
    
end

function Blink:GetHasSecondary(player)
    return player:GetHasOneHive() 
end

function Blink:GetSecondaryAttackRequiresPress()
    return true
end

function Blink:TriggerBlinkOutEffects(player)
	if not Shared.GetIsRunningPrediction() and self.lastblinkeffect + kMinBlinkEffectTime < Shared.GetTime() then
	    self.lastblinkeffect = Shared.GetTime()
	    player:TriggerEffects("blink_out")
	end
end

function Blink:TriggerBlinkInEffects(player)
	if not Shared.GetIsRunningPrediction() and self.lastblinkeffect + kMinBlinkEffectTime < Shared.GetTime() then
	    self.lastblinkeffect = Shared.GetTime()
	    player:TriggerEffects("blink_in")	 
	end
end

function Blink:GetSecondaryEnergyCost(player)
    return kStartBlinkEnergyCost
end

function Blink:OnSecondaryAttack(player)

    if not player:GetIsBlinking() and player:GetEnergy() >= self:GetSecondaryEnergyCost(player) then
        self:SetEthereal(player, true)
    end
    
    Ability.OnSecondaryAttack(self, player)
    
end

function Blink:OnSecondaryAttackEnd(player)

    if player:GetIsBlinking() then
        self:SetEthereal(player, false)
    end
    
    Ability.OnSecondaryAttackEnd(self, player)
    
end

function Blink:SetEthereal(player, state)

    if player.ethereal ~= state then
        
        player.ethereal = state
        
        if player.ethereal then
            player:OnBlink()
            player:DeductAbilityEnergy(self:GetSecondaryEnergyCost())
            self:TriggerBlinkOutEffects(player)   
        else
            player:OnBlinkEnd()
            self:TriggerBlinkInEffects(player) 
        end
        
    end
    
end

function Blink:OnUpdateAnimationInput(modelMixin)

    local player = self:GetParent()
    if player:GetIsBlinking() then
        modelMixin:SetAnimationInput("move", "blink")
    end
    
end

Shared.LinkClassToMap("Blink", Blink.kMapName, networkVars)