//
// lua\Weapons\Alien\WebAbility.lua

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'WebStructureAbility' (StructureAbility)

function WebStructureAbility:GetEnergyCost(player)
    return 0
end

function WebStructureAbility:GetIconOffsetY(secondary)
    return kAbilityOffset.Cyst
end

function WebStructureAbility:GetGhostModelName(ability)
    return Web.kModelName
end

function WebStructureAbility:GetDropStructureId()
    return kTechId.Web
end

function WebStructureAbility:GetSuffixName()
    return "web"
end

function WebStructureAbility:GetDropClassName()
    return "Web"
end

function WebStructureAbility:GetDropMapName()
    return Web.kMapName
end

function WebStructureAbility:IsAllowed(player)
    local structures = GetEntitiesForTeamWithinRange(self:GetDropClassName(), player:GetTeamNumber(), player:GetEyePos(), kMaxAlienStructureRange)
    return #structures < kMaxAlienStructuresofType and player:GetHasThreeHives()
end
