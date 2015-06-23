// Natural Selection 2 'Classic' Mod
// lua\Weapons\Alien\CragAbility.lua
// - Dragon

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'CragStructureAbility' (StructureAbility)

function CragStructureAbility:GetEnergyCost(player)
    return 0
end

function CragStructureAbility:GetPrimaryAttackDelay()
    return 0
end

function CragStructureAbility:GetGhostModelName(ability)
    return Crag.kModelName
end

function CragStructureAbility:GetDropStructureId()
    return kTechId.Crag
end

function CragStructureAbility:GetIsPositionValid(displayOrigin, player, normal, lastClickedPosition, entity)
    return entity == nil
end

function CragStructureAbility:GetRequiredTechId()
    return kTechId.CragHive
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
