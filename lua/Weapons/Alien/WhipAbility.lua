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

function WhipStructureAbility:IsAllowed(player)
    local structures = GetEntitiesForTeamWithinRange(self:GetDropClassName(), player:GetTeamNumber(), player:GetEyePos(), kMaxAlienStructureRange)
    if Server then
        return UpgradeBaseHivetoChamberSpecific(player, self:GetDropStructureId()) and #structures < kMaxAlienStructuresofType
    else
        local teamInfo = GetTeamInfoEntity(Client.GetLocalPlayer():GetTeamNumber())
        return (((teamInfo and teamInfo.GetActiveUnassignedHiveCount) and teamInfo:GetActiveUnassignedHiveCount() or 0) > 0 
            or GetHasTech(Client.GetLocalPlayer(), self:GetRequiredTechId())) and #structures < kMaxAlienStructuresofType
    end
end
