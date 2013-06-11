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

function ShadeStructureAbility:GetRequiredTechId()
    return kTechId.ShadeHive
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
    if Server then
        return UpgradeBaseHivetoChamberSpecific(player, self:GetDropStructureId()) and #structures < kMaxAlienStructuresofType
    else
        local teamInfo = GetTeamInfoEntity(Client.GetLocalPlayer():GetTeamNumber())
        return (((teamInfo and teamInfo.GetActiveUnassignedHiveCount) and teamInfo:GetActiveUnassignedHiveCount() or 0) > 0 
            or GetHasTech(Client.GetLocalPlayer(), self:GetRequiredTechId())) and #structures < kMaxAlienStructuresofType
    end
end