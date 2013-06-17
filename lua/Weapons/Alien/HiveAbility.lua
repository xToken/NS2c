//
// lua\Weapons\Alien\HiveAbility.lua

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

function HiveStructureAbility:GetSuffixName()
    return "hive"
end

function HiveStructureAbility:GetDropClassName()
    return "Hive"
end

function HiveStructureAbility:GetDropMapName()
    return Hive.kMapName
end

function HiveStructureAbility:CreateStructure(coords, player, lastClickedPosition)
	local success, entid = player:AttemptToBuild(self:GetDropStructureId(), coords.origin, nil, 0, nil, false, self, nil, player)
    if success then
        return Shared.GetEntity(entid)
    end
    return nil
end

function HiveStructureAbility:IsAllowed(player)
    if Server then
        local BuildingHives = 0
        for index, hive in ipairs(GetEntitiesForTeam("Hive", player:GetTeamNumber())) do
            if not hive:GetIsBuilt() then
                BuildingHives = BuildingHives + 1
            end
        end
        return BuildingHives < kMaxBuildingHives
    else
        return true
    end
end