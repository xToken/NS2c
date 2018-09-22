-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\LeapMixin.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com) and
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

LeapMixin = CreateMixin( LeapMixin )
LeapMixin.type = "Leap"

-- GetHasSecondary and GetSecondaryEnergyCost should completely override any existing
-- same named function defined in the object.
LeapMixin.overrideFunctions =
{
    "GetHasSecondary",
    "GetSecondaryEnergyCost",
    "PerformSecondaryAttack"
}

function LeapMixin:GetHasSecondary(player)
    return player:GetHasTwoHives() 
end

function LeapMixin:GetSecondaryEnergyCost()
    return kLeapEnergyCost
end

function LeapMixin:PerformSecondaryAttack(player)

    local parent = self:GetParent()
    if parent and self:GetHasSecondary(player) and not player:GetSecondaryAttackLastFrame() then
    
        player:OnLeap()
        player:TriggerEffects("leap")
        return true
        
    end
    
    return false
    
end