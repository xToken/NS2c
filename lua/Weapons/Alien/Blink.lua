-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\Weapons\Alien\Blink.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- Blink - Attacking many times in a row will create a cool visual "chain" of attacks,
-- showing the more flavorful animations in sequence. Base class for swipe and vortex,
-- available at tier 2.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

--NS2c
--Adjusted blink impact and energy usage

Script.Load("lua/Weapons/Alien/Ability.lua")

class 'Blink' (Ability)

Blink.kMapName = "blink"

local networkVars = { }

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

local function TriggerBlinkOutEffects(self, player)

    -- Play particle effect at vanishing position.
    if not Shared.GetIsRunningPrediction() then

    end
    
end

local function TriggerBlinkInEffects(self, player)

    if not Shared.GetIsRunningPrediction() then

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

        if state then
            player:OnBlink()
            player:DeductAbilityEnergy(self:GetSecondaryEnergyCost())
			TriggerBlinkOutEffects(self, player)
        else
			TriggerBlinkInEffects(self, player)
			if player.OnBlinkEnd then
            	player:OnBlinkEnd()
			end
        end
        
    end
    
end

function Blink:OnUpdateAnimationInput(modelMixin)

    local player = self:GetParent()
    if player:GetIsBlinking() and (not player.GetHasMetabolizeAnimationDelay or not player:GetHasMetabolizeAnimationDelay()) then
        modelMixin:SetAnimationInput("move", "blink")
    end
    
end

Shared.LinkClassToMap("Blink", Blink.kMapName, networkVars)
