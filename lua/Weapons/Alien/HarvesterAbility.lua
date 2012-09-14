// lua\Weapons\Alien\HarvesterStructureAbility.lua
//
//    Created by:   
//
// Gorge builds Harvester.

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'HarvesterStructureAbility' (StructureAbility)

function HarvesterStructureAbility:GetEnergyCost(player)
    return 0
end

function HarvesterStructureAbility:GetPrimaryAttackDelay()
    return 0
end

function HarvesterStructureAbility:GetIconOffsetY(secondary)
    return kAbilityOffset.Hydra
end

function HarvesterStructureAbility:GetGhostModelName(ability)
    return Harvester.kModelName
end

function HarvesterStructureAbility:GetIsPositionValid(position, player)
    return GetIsBuildPickVecLegal(self:GetDropStructureId(), player, position)
end

function HarvesterStructureAbility:GetDropStructureId()
    return kTechId.Harvester
end

function HarvesterStructureAbility:GetSuffixName()
    return "harvester"
end

function HarvesterStructureAbility:GetDropClassName()
    return "Harvester"
end

function HarvesterStructureAbility:GetDropMapName()
    return Harvester.kMapName
end

function HarvesterStructureAbility:IsAllowed(player)
    local structures = GetEntitiesForTeamWithinRange(self:GetDropClassName(), player:GetTeamNumber(), player:GetEyePos(), kMaxAlienStructureRange)
    return #structures < kMaxAlienStructuresofType
end
