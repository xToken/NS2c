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
kAlienUpgradeRequirements = {kTechId.CragHive, kTechId.ShiftHive, kTechId.ShadeHive, kTechId.WhipHive}

function GetHasPrereqs(teamNumber, techId)

    local techTree = GetTechTree(teamNumber)
    if techTree then
    
        local techNode = techTree:GetTechNode(techId)
        if techNode then
            return techTree:GetHasTech(techNode:GetPrereq1()) and techTree:GetHasTech(techNode:GetPrereq2())
        end 
   
    end
    
    return false

end

function GetIsTechAvailable(teamNumber, techId)

    local techTree = GetTechTree(teamNumber)
    if techTree then
    
        local techNode = techTree:GetTechNode(techId)
        if techNode then
            return techNode:GetAvailable()
        end 
   
    end
    
    return false

end

function GetIsTechResearched(teamNumber, techId)

    local techTree = GetTechTree(teamNumber)
    if techTree then
    
        local techNode = techTree:GetTechNode(techId)
        if techNode then
            return techNode:GetResearched()
        end 
   
    end
    
    return false

end

local function GetTeamHasTech(teamNumber, techId)

    local techTree = GetTechTree(teamNumber)
    if techTree then
        return techTree:GetHasTech(techId, true)
    end
    
    return false

end

function GetHasHealingBedUpgrade(teamNumber)
    return GetTeamHasTech(teamNumber, kTechId.HealingBed)
end

function GetHasMucousMembraneUpgrade(teamNumber)
    return GetTeamHasTech(teamNumber, kTechId.MucousMembrane)
end

function GetHasBacterialReceptorsUpgrade(teamNumber)
    return GetTeamHasTech(teamNumber, kTechId.BacterialReceptors)
end

local function HasUpgrade(callingEntity, techId)

    if not callingEntity then
        return false, 0
    end

    local techtree = GetTechTree(callingEntity:GetTeamNumber())
    local chamberId = GetChamberTypeForUpgrade(techId)
    local structurecount = GetChambers(chamberId, callingEntity:GetTeamNumber())
    
    if techtree then
        return callingEntity:GetHasUpgrade(techId) and structurecount > 0, structurecount
    else
        return false, 0
    end

end

function GetHasCelerityUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Celerity)
end

function GetHasRegenerationUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Regeneration)
end

function GetHasAdrenalineUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Adrenaline)
end

function GetHasFocusUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Focus)
end

function GetHasCarapaceUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Carapace)
end

function GetHasAuraUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Aura)
end

function GetHasCamouflageUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Camouflage)
end

function GetHasSilenceUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Silence)
end

function GetHasRedemptionUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Redemption)
end

function GetHasGhostUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Ghost)
end

function GetHasRedeploymentUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Redeployment)
end

function GetHasFuryUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Fury)
end

function GetHasBombardUpgrade(callingEntity)
    return HasUpgrade(callingEntity, kTechId.Bombard)
end

function GetHiveTypeForUpgrade(upgradeId)

    local hiveType = LookupTechData(upgradeId, kTechDataCategory, kTechId.None)
    return hiveType

end

function GetChamberTypeForUpgrade(upgradeId)

    local chamberType = LookupTechData(upgradeId, kTechDataKeyStructure, kTechId.None)
    return chamberType

end

// checks if upgrade category is already used
function GetIsUpgradeAllowed(callingEntity, techId, upgradeList)

    local allowed = false

    if callingEntity then
    
        allowed = true
    
        local hiveType = GetHiveTypeForUpgrade(techId)
    
        for i = 1, #upgradeList do
        
            if GetHiveTypeForUpgrade(upgradeList[i]) == hiveType then
                allowed = false
                break
            end
        
        end
    
    end
    
    return allowed

end