//
// lua\Weapons\Alien\HarvesterAbility.lua

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

function HarvesterStructureAbility:GetIsPositionValid(displayOrigin, player, normal, lastClickedPosition, entity)
    local checkBypass = { }
    local coords
    checkBypass["ValidExit"] = true
    local validBuild, legalPosition, attachEntity, errorString = GetIsBuildLegal(self:GetDropStructureId(), displayOrigin, player:GetViewCoords().zAxis, self:GetDropRange(), player, false, checkBypass)
    if attachEntity then
        coords = attachEntity:GetAngles():GetCoords()
        coords.origin = legalPosition
    end
    return validBuild, coords
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

function HarvesterStructureAbility:CreateStructure(coords, player, lastClickedPosition)
	local success, entid = player:AttemptToBuild(self:GetDropStructureId(), coords.origin, nil, 0, nil, false, self, nil, player)
    if success then
        return Shared.GetEntity(entid)
    end
    return nil
end

function HarvesterStructureAbility:IsAllowed(player)
    local structures = GetEntitiesForTeamWithinRange(self:GetDropClassName(), player:GetTeamNumber(), player:GetEyePos(), kMaxAlienStructureRange)
    return #structures < kMaxAlienStructuresofType
end
