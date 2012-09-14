// lua\Weapons\Alien\HydraStructureAbility.lua
//

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'HiveStructureAbility' (StructureAbility)

function HiveStructureAbility:ModifyCoords(coords)
    coords.origin = coords.origin + coords.yAxis * kHiveYOffset
end

function HiveStructureAbility:GetEnergyCost(player)
    return 0
end

function HiveStructureAbility:GetPrimaryAttackDelay()
    return 0
end

function HiveStructureAbility:GetIconOffsetY(secondary)
    return kAbilityOffset.Hydra
end

function HiveStructureAbility:GetGhostModelName(ability)
    return Hive.kModelName
end

function HiveStructureAbility:GetDropStructureId()
    return kTechId.Hive
end

function HiveStructureAbility:GetIsPositionValid(position, player)
    return GetIsBuildPickVecLegal(self:GetDropStructureId(), player, position)
end

function HiveStructureAbility:GetSuffixName()
    return "hive"
end

function HiveStructureAbility:GetDropClassName()
    return "Hive"
end

function HiveStructureAbility:GetDropMapName()
    return Hive.kMapName
end

function HiveStructureAbility:IsAllowed(player)
    local structures = GetEntitiesForTeamWithinRange(self:GetDropClassName(), player:GetTeamNumber(), player:GetEyePos(), kMaxAlienStructureRange)
    return #structures < kMaxAlienStructuresofType
end