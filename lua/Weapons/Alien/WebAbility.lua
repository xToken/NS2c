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

class 'WebStructureAbility' (StructureAbility)

function WebStructureAbility:GetEnergyCost(player)
    return 0
end

function WebStructureAbility:GetIconOffsetY(secondary)
    return kAbilityOffset.Cyst
end

function WebStructureAbility:GetGhostModelName(ability)
    return Web.kModelName
end

function WebStructureAbility:GetDropStructureId()
    return kTechId.Web
end

function WebStructureAbility:GetSuffixName()
    return "web"
end

function WebStructureAbility:GetDropClassName()
    return "Web"
end

function WebStructureAbility:GetDropMapName()
    return Web.kMapName
end

function WebStructureAbility:IsAllowed(player)
    local structures = GetEntitiesForTeamWithinRange(self:GetDropClassName(), player:GetTeamNumber(), player:GetEyePos(), kMaxAlienStructureRange)
    return #structures < kMaxAlienStructuresofType and player:GetHasThreeHives()
end
