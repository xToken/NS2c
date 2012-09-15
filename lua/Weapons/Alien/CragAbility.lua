//
// lua\Weapons\Alien\CragAbility.lua

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'CragStructureAbility' (StructureAbility)

function CragStructureAbility:GetEnergyCost(player)
    return 0
end

function CragStructureAbility:GetPrimaryAttackDelay()
    return 0
end

function CragStructureAbility:GetIconOffsetY(secondary)
    return kAbilityOffset.Hydra
end

function CragStructureAbility:GetGhostModelName(ability)
    return Crag.kModelName
end

function CragStructureAbility:GetDropStructureId()
    return kTechId.Crag
end

function CragStructureAbility:GetSuffixName()
    return "crag"
end

function CragStructureAbility:GetDropClassName()
    return "Crag"
end

function CragStructureAbility:GetDropMapName()
    return Crag.kMapName
end

function CragStructureAbility:IsAllowed(player)
    local structures = GetEntitiesForTeamWithinRange(self:GetDropClassName(), player:GetTeamNumber(), player:GetEyePos(), kMaxAlienStructureRange)
    local teamnum = player:GetTeamNumber()
    local techTree = GetTechTree(teamnum)
    local techNode = techTree:GetTechNode(kTechId.Crag)
    assert(techNode)
    return (techNode:GetAvailable() or player:GetUnassignedHives() > 0) and #structures < kMaxAlienStructuresofType
end
