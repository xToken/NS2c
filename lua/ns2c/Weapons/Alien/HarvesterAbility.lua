// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\Weapons\Alien\HarvesterAbility.lua
// - Dragon

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'HarvesterStructureAbility' (StructureAbility)

function HarvesterStructureAbility:GetEnergyCost(player)
    return 0
end

function HarvesterStructureAbility:GetPrimaryAttackDelay()
    return 0
end

function HarvesterStructureAbility:GetGhostModelName(ability)
    return Harvester.kModelName
end

function HarvesterStructureAbility:GetDropStructureId()
    return kTechId.Harvester
end

function HarvesterStructureAbility:GetSuffixName()
    return "harvester"
end

function HarvesterStructureAbility:GetRequiredTechId()
    return kTechId.None
end

function HarvesterStructureAbility:GetDropClassName()
    return "Harvester"
end

function HarvesterStructureAbility:GetDropMapName()
    return Harvester.kMapName
end

function HarvesterStructureAbility:CreateStructure(coords, player, lastClickedPosition)
	local success, entid = player:AttemptToBuild(self:GetDropStructureId(), coords.origin, nil, 0, nil, false, self, nil, player)
    if success then
        return Shared.GetEntity(entid)
    end
    return nil
end
