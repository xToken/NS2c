//=============================================================================
//
// lua/AlienUpgrades_Client.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

// Number if icons in each row of Alien.kUpgradeIconsTexture
local kUpgradeIconRowSize = 6

// The order of icons in Alien.kUpgradeIconsTexture
local kIconIndexToUpgradeId = {
    kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None, 
    kTechId.None, kTechId.None, kTechId.Carapace, kTechId.Regeneration,
    kTechId.None, kTechId.None, kTechId.Adrenaline, kTechId.None, kTechId.None, kTechId.None, 
    kTechId.Stomp, kTechId.None, kTechId.Leap, kTechId.None, kTechId.None, kTechId.None, 
}

function GetAlienUpgradeIconXY(techId)

    for index, id in ipairs(kIconIndexToUpgradeId) do
    
        if id == techId then
        
            return true, (index - 1) % kUpgradeIconRowSize, math.floor((index - 1)/ kUpgradeIconRowSize)
            
        end    
        
    end
    
    Print("GetUpgradeIconXY(%s): Invalid techId passed.", EnumToString(kTechId, techId))
    return false, 0, 0
    
end

