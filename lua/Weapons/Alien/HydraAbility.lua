// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\HydraStructureAbility.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Gorge builds hydra.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'HydraStructureAbility' (StructureAbility)

function HydraStructureAbility:GetEnergyCost(player)
    return kDropStructureEnergyCost
end

function HydraStructureAbility:GetGhostModelName(ability)
    return Hydra.kModelName
end

function HydraStructureAbility:GetDropStructureId()
    return kTechId.Hydra
end

function HydraStructureAbility:GetRequiredTechId()
    return kTechId.None
end

function HydraStructureAbility:GetIsPositionValid(displayOrigin, player, normal, lastClickedPosition, entity)
    return entity == nil
end

function HydraStructureAbility:GetSuffixName()
    return "hydra"
end

function HydraStructureAbility:GetDropClassName()
    return "Hydra"
end

function HydraStructureAbility:GetDropMapName()
    return Hydra.kMapName
end
