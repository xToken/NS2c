// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Alien_Upgrade.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Utility functions for readability.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Added classic upgrades and upgrade chamber levels

kAlienUpgradeChambers = {kTechId.Crag, kTechId.Shift, kTechId.Shade, kTechId.Whip}

local function HasUpgrade(player, techId)

    if not player then
        return false, 0
    end

    local chamberId = GetChamberTypeForUpgrade(techId)
    local structurecount = GetChambers(chamberId, player)
    local hasupgrade = player:GetHasUpgrade(techId)
    
    return hasupgrade and structurecount > 0, structurecount

end

function GetHasCelerityUpgrade(player)
    return HasUpgrade(player, kTechId.Celerity)
end

function GetHasRegenerationUpgrade(player)
    return HasUpgrade(player, kTechId.Regeneration)
end

function GetHasAdrenalineUpgrade(player)
    return HasUpgrade(player, kTechId.Adrenaline)
end

function GetHasFocusUpgrade(player)
    return HasUpgrade(player, kTechId.Focus)
end

function GetHasCarapaceUpgrade(player)
    return HasUpgrade(player, kTechId.Carapace)
end

function GetHasAuraUpgrade(player)
    return HasUpgrade(player, kTechId.Aura)
end

function GetHasCamouflageUpgrade(player)
    return HasUpgrade(player, kTechId.Camouflage)
end

function GetHasSilenceUpgrade(player)
    return HasUpgrade(player, kTechId.Silence)
end

function GetHasRedemptionUpgrade(player)
    return HasUpgrade(player, kTechId.Redemption)
end

function GetHasGhostUpgrade(player)
    return HasUpgrade(player, kTechId.Ghost)
end

function GetHasRedeploymentUpgrade(player)
    return HasUpgrade(player, kTechId.Redeployment)
end

function GetHasFuryUpgrade(player)
    return HasUpgrade(player, kTechId.Fury)
end

function GetHasBombardUpgrade(player)
    return HasUpgrade(player, kTechId.Bombard)
end

function GetHiveTypeForChamber(chamberId)
    return kAlienChamberHiveTypes[chamberId]
end

function GetChamberTypeForUpgrade(upgradeId)

    local chamberType = LookupTechData(upgradeId, kTechDataKeyStructure, kTechId.None)
    return chamberType

end

// checks if upgrade category is already used
function GetIsAlienUpgradeAllowed(player, techId, upgradeList)

    local allowed = false

    if player and player:GetGameMode() == kGameMode.Classic then
    
        allowed = true
    
        local cType = GetChamberTypeForUpgrade(techId)
    
        for i = 1, #upgradeList do
        
            if GetChamberTypeForUpgrade(upgradeList[i]) == cType then
                allowed = false
                break
            end
        
        end
    
    end
    
    if player and player:GetGameMode() == kGameMode.Combat then
        //No hive type restrictions in Combat
        allowed = true
        
    end
    
    return allowed

end