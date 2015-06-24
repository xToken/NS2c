// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\Weapons\Alien\ShadeAbility.lua
// - Dragon

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'ShadeStructureAbility' (StructureAbility)

function ShadeStructureAbility:GetEnergyCost(player)
    return 0
end

function ShadeStructureAbility:GetPrimaryAttackDelay()
    return 0
end

function ShadeStructureAbility:GetGhostModelName(ability)
    return Shade.kModelName
end

function ShadeStructureAbility:GetDropStructureId()
    return kTechId.Shade
end

function ShadeStructureAbility:GetRequiredTechId()
    return kTechId.ShadeHive
end

function ShadeStructureAbility:GetIsPositionValid(displayOrigin, player, normal, lastClickedPosition, entity)
    return entity == nil
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