//
// lua\Weapons\Alien\ShiftAbility.lua

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'ShiftStructureAbility' (StructureAbility)

function ShiftStructureAbility:GetEnergyCost(player)
    return 0
end

function ShiftStructureAbility:GetPrimaryAttackDelay()
    return 0
end

function ShiftStructureAbility:GetIconOffsetY(secondary)
    return kAbilityOffset.Hydra
end

function ShiftStructureAbility:GetGhostModelName(ability)
    return Shift.kModelName
end

function ShiftStructureAbility:GetDropStructureId()
    return kTechId.Shift
end

function ShiftStructureAbility:GetRequiredTechId()
    return kTechId.ShiftHive
end

function ShiftStructureAbility:GetIsPositionValid(displayOrigin, player, normal, lastClickedPosition, entity)
    return entity == nil
end

function ShiftStructureAbility:GetSuffixName()
    return "shift"
end

function ShiftStructureAbility:GetDropClassName()
    return "Shift"
end

function ShiftStructureAbility:GetDropMapName()
    return Shift.kMapName
end