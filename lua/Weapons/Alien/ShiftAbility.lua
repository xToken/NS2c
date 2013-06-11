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

function ShiftStructureAbility:GetSuffixName()
    return "shift"
end

function ShiftStructureAbility:GetDropClassName()
    return "Shift"
end

function ShiftStructureAbility:GetDropMapName()
    return Shift.kMapName
end

function ShiftStructureAbility:IsAllowed(player)
    local structures = GetEntitiesForTeamWithinRange(self:GetDropClassName(), player:GetTeamNumber(), player:GetEyePos(), kMaxAlienStructureRange)
    if Server then
        return UpgradeBaseHivetoChamberSpecific(player, self:GetDropStructureId()) and #structures < kMaxAlienStructuresofType
    else
        local teamInfo = GetTeamInfoEntity(Client.GetLocalPlayer():GetTeamNumber())
        return (((teamInfo and teamInfo.GetActiveUnassignedHiveCount) and teamInfo:GetActiveUnassignedHiveCount() or 0) > 0 
            or GetHasTech(Client.GetLocalPlayer(), self:GetRequiredTechId())) and #structures < kMaxAlienStructuresofType
    end
end
