//
// lua\Weapons\Alien\ShadeAbility.lua

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'ShadeStructureAbility' (StructureAbility)

function ShadeStructureAbility:GetEnergyCost(player)
    return 0
end

function ShadeStructureAbility:GetPrimaryAttackDelay()
    return 0
end

function ShadeStructureAbility:GetIconOffsetY(secondary)
    return kAbilityOffset.Hydra
end

function ShadeStructureAbility:GetGhostModelName(ability)
    return Shade.kModelName
end

function ShadeStructureAbility:GetDropStructureId()
    return kTechId.Shade
end

function ShadeStructureAbility:GetSuffixName()
    return "shade"
end

function ShadeStructureAbility:GetDropClassName()
    return "Shade"
end

function ShadeStructureAbility:GetDropMapName()
    return Shade.kMapName
end

function ShadeStructureAbility:IsAllowed(player)
    local structures = GetEntitiesForTeamWithinRange(self:GetDropClassName(), player:GetTeamNumber(), player:GetEyePos(), kMaxAlienStructureRange)
    local teamnum = player:GetTeamNumber()
    local techTree = GetTechTree(teamnum)
    local techNode = techTree:GetTechNode(kTechId.Shade)
    assert(techNode)
    return (techNode:GetAvailable() or player:GetUnassignedHives() > 0) and #structures < kMaxAlienStructuresofType
end