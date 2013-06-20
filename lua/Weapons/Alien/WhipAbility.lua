//
// lua\Weapons\Alien\WhipAbility.lua

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'WhipStructureAbility' (StructureAbility)

function WhipStructureAbility:GetEnergyCost(player)
    return 0
end

function WhipStructureAbility:GetPrimaryAttackDelay()
    return 0
end

function WhipStructureAbility:GetIconOffsetY(secondary)
    return kAbilityOffset.Hydra
end

function WhipStructureAbility:GetGhostModelName(ability)
    return Whip.kModelName
end

function WhipStructureAbility:GetDropStructureId()
    return kTechId.Whip
end

function WhipStructureAbility:GetRequiredTechId()
    return kTechId.WhipHive
end

function WhipStructureAbility:GetSuffixName()
    return "whip"
end

function WhipStructureAbility:GetDropClassName()
    return "Whip"
end

function WhipStructureAbility:GetDropMapName()
    return Whip.kMapName
end