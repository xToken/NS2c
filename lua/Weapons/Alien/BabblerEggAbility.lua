-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\BabblerEggAbility.lua
--
--    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'BabblerEggAbility' (StructureAbility)

function BabblerEggAbility:GetEnergyCost(player)
    return kDropStructureEnergyCost
end

function BabblerEggAbility:GetGhostModelName(ability)

    local player = ability:GetParent()
    if player and player:isa("Gorge") then
    
        local variant = player:GetVariant()
        if variant == kGorgeVariant.shadow then
            return BabblerEgg.kModelNameShadow
        end
        
    end
    
    return BabblerEgg.kModelName
    
end

function BabblerEggAbility:GetDropStructureId()
    return kTechId.BabblerEgg
end

function BabblerEggAbility:GetRequiredTechId()
    return kTechId.BabblerEgg
end

function BabblerEggAbility:GetSuffixName()
    return "babbleregg"
end

function BabblerEggAbility:GetDropClassName()
    return "BabblerEgg"
end

function BabblerEggAbility:GetIsPositionValid(displayOrigin, player, normal, lastClickedPosition, entity)
    return entity == nil
end

function BabblerEggAbility:GetDropRange()
    return 1.5
end

function BabblerEggAbility:GetDropMapName()
    return BabblerEgg.kMapName
end

function BabblerEggAbility:IsAllowed(player)
    if player and player.GetHasThreeHives then
        return player:GetHasThreeHives()
    end
    return false
end

