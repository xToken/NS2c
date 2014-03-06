//=============================================================================
//
// lua/AlienBuy_Client.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

//NS2c
//Removed concept of hypermutation, added classic techids and data

Script.Load("lua/InterfaceSounds_Client.lua")
Script.Load("lua/Skulk.lua")
Script.Load("lua/Gorge.lua")
Script.Load("lua/Lerk.lua")
Script.Load("lua/Fade.lua")
Script.Load("lua/Onos.lua")

// Indices passed in from flash
local indexToAlienTechIdTable = {kTechId.Fade, kTechId.Gorge, kTechId.Lerk, kTechId.Onos, kTechId.Skulk}

local kAlienBuyMenuSounds = { Open = "sound/NS2.fev/alien/common/alien_menu/open_menu",
                              Close = "sound/NS2.fev/alien/common/alien_menu/close_menu",
                              Evolve = "sound/NS2.fev/alien/common/alien_menu/evolve",
                              BuyUpgrade = "sound/NS2.fev/alien/common/alien_menu/buy_upgrade",
                              SellUpgrade = "sound/NS2.fev/alien/common/alien_menu/sell_upgrade",
                              Hover = "sound/NS2.fev/alien/common/alien_menu/hover",
                              SelectSkulk = "sound/NS2.fev/alien/common/alien_menu/skulk_select",
                              SelectFade = "sound/NS2.fev/alien/common/alien_menu/fade_select",
                              SelectGorge = "sound/NS2.fev/alien/common/alien_menu/gorge_select",
                              SelectOnos = "sound/NS2.fev/alien/common/alien_menu/onos_select",
                              SelectLerk = "sound/NS2.fev/alien/common/alien_menu/lerk_select" }

for i, soundAsset in pairs(kAlienBuyMenuSounds) do
    Client.PrecacheLocalSound(soundAsset)
end

function IndexToAlienTechId(index)

    if index >= 1 and index <= table.count(indexToAlienTechIdTable) then
        return indexToAlienTechIdTable[index]
    else    
        Print("IndexToAlienTechId(%d) - invalid id passed", index)
        return kTechId.None
    end
    
end

function AlienTechIdToIndex(techId)
    for index, alienTechId in ipairs(indexToAlienTechIdTable) do
        if techId == alienTechId then
            return index
        end
    end
    
    ASSERT(false, "AlienTechIdToIndex(" .. ToString(techId) .. ") - invalid tech id passed")
    return 0
    
end

/**
 * Return 1-d array of name, hp, ap, and cost for this class index
 */
function AlienBuy_GetClassStats(idx)

    if idx == nil then
        Print("AlienBuy_GetClassStats(nil) called")
    end
    
    // name, hp, ap, cost
    local techId = IndexToAlienTechId(idx)
    
    if techId == kTechId.Fade then
        return {"Fade", kFadeHealth, kFadeArmor, LookupTechData(techId, kTechDataCostKey, 0)}
    elseif techId == kTechId.Gorge then
        return {"Gorge", kGorgeHealth, kGorgeArmor, LookupTechData(techId, kTechDataCostKey, 0)}
    elseif techId == kTechId.Lerk then
        return {"Lerk", kLerkHealth, kLerkArmor, LookupTechData(techId, kTechDataCostKey, 0)}
    elseif techId == kTechId.Onos then
        return {"Onos", kOnosHealth, kOnosArmor, LookupTechData(techId, kTechDataCostKey, 0)}
    else
        return {"Skulk", kSkulkHealth, kSkulkArmor, LookupTechData(techId, kTechDataCostKey, 0)}
    end   
    
end

function AlienBuy_GetIsUpgradeAllowed(techId, upgradeList)
    return GetIsAlienUpgradeAllowed(Client.GetLocalPlayer(), techId, upgradeList)
end

function AlienBuy_GetPersonalUpgrades()

    local upgrades = {}
    local player = Client.GetLocalPlayer()
    local techTree = player:GetTechTree()
    
    if techTree then
    
        for _, upgradeId in ipairs(techTree:GetAddOnsForTechId(kTechId.AllAliens)) do
            table.insert(upgrades, {TechId = upgradeId, Category = GetChamberTypeForUpgrade(upgradeId)})
        end
    
    end
    
    return upgrades

end

function AlienBuy_GetUpgradesForChamber(category)

    local upgrades = {}
    local player = Client.GetLocalPlayer()
    local techTree = player:GetTechTree()
    
    if techTree then
        if player:GetGameMode() == kGameMode.Classic then
            for _, upgradeId in ipairs(techTree:GetAddOnsForTechId(kTechId.AllAliens)) do
            
                if GetChamberTypeForUpgrade(upgradeId) == category then        
                    table.insert(upgrades, upgradeId)
                end
                
            end
        else
            //Combat tracks the category as the actual upgrade, since each upgrade has its own slot
            table.insert(upgrades, category)
        end
       
    end
    
    return upgrades

end

/**
 * Pass in a table describing what should be purchased. The table has the following format:
 * Type = "Alien" or "Upgrade"
 * Alien = "Skulk", "Lerk", etc
 * UpgradeIndex = Only needed when purchasing an upgrade, number index for the upgrade
 */
function AlienBuy_Purchase(purchaseTable)

    ASSERT(type(purchaseTable) == "table")
    
    local purchaseTechIds = { }
    
    for i, purchase in ipairs(purchaseTable) do

        if purchase.Type == "Alien" then
            table.insert(purchaseTechIds, IndexToAlienTechId(purchase.Alien))
        elseif purchase.Type == "Upgrade" then
            table.insert(purchaseTechIds, purchase.TechId)
        end
    
    end
    
    //Second part validation for the client?  Buy menu might as well be assumed to be valid, will get validatied by server in the end anyways so just wasting time.
    if #purchaseTechIds > 0 then
        Client.SendNetworkMessage("Buy", BuildBuyMessage(purchaseTechIds), true)
    end

end

function AlienBuy_GetAlienCost(index)
    local techId = IndexToAlienTechId(index)
    return BuyMenus_GetUpgradeCost(techId)
end

/**
 * Return current alien type
 */
function AlienBuy_GetCurrentAlien()
    local player = Client.GetLocalPlayer()
    local techId = player:GetTechId()
    local index = AlienTechIdToIndex(techId)
    
    ASSERT(index >= 1 and index <= table.count(indexToAlienTechIdTable), "AlienBuy_GetCurrentAlien(" .. ToString(techId) .. "): returning invalid index " .. ToString(index) .. " for " .. SafeClassName(player))
    
    return index
    
end

function AlienBuy_OnMouseOver()

    StartSoundEffect(kAlienBuyMenuSounds.Hover)

end

function AlienBuy_OnOpen()

    StartSoundEffect(kAlienBuyMenuSounds.Open)

end

function AlienBuy_OnClose()

    StartSoundEffect(kAlienBuyMenuSounds.Close)

end

function AlienBuy_OnPurchase()

    StartSoundEffect(kAlienBuyMenuSounds.Evolve)

end

function AlienBuy_OnSelectAlien(type)

    local assetName = ""
    if type == "Skulk" then
        assetName = kAlienBuyMenuSounds.SelectSkulk
    elseif type == "Gorge" then
        assetName = kAlienBuyMenuSounds.SelectGorge
    elseif type == "Lerk" then
        assetName = kAlienBuyMenuSounds.SelectLerk
    elseif type == "Onos" then
        assetName = kAlienBuyMenuSounds.SelectOnos
    elseif type == "Fade" then
        assetName = kAlienBuyMenuSounds.SelectFade
    end
    StartSoundEffect(assetName)

end

function AlienBuy_OnUpgradeSelected()
    StartSoundEffect(kAlienBuyMenuSounds.BuyUpgrade)    
end

// use those function also in Alien.lua
local gTierTwoTech = nil
function GetAlienTierTwoFor(techId)

    if not gTierTwoTech then
    
        gTierTwoTech = {}
        
        gTierTwoTech[kTechId.Skulk] = kTechId.Leap
        gTierTwoTech[kTechId.Gorge] = kTechId.BileBomb
        gTierTwoTech[kTechId.Lerk]  = kTechId.Umbra
        gTierTwoTech[kTechId.Fade]  = kTechId.Metabolize
        gTierTwoTech[kTechId.Onos]  = kTechId.Stomp
        
    end
    
    return gTierTwoTech[techId]

end

local gTierThreeTech = nil
function GetAlienTierThreeFor(techId)

    if not gTierThreeTech then
    
        gTierThreeTech = {}
        
        gTierThreeTech[kTechId.Skulk] = kTechId.Xenocide
        gTierThreeTech[kTechId.Gorge] = kTechId.Web
        gTierThreeTech[kTechId.Lerk]  = kTechId.PrimalScream
        gTierThreeTech[kTechId.Fade]  = kTechId.AcidRocket
        gTierThreeTech[kTechId.Onos]  = kTechId.Devour
        
    end
    
    return gTierThreeTech[techId]

end

function AlienBuy_GetAbilitiesFor(lifeFormTechId)

    local abilityIds = {}

    local tierTwoTech = GetAlienTierTwoFor(lifeFormTechId)
    if tierTwoTech then
        table.insert(abilityIds, tierTwoTech)
    end
    
    local tierThreeTech = GetAlienTierThreeFor(lifeFormTechId)
    if tierThreeTech then
        table.insert(abilityIds, tierThreeTech)
    end
    
    return abilityIds

end

function AlienBuy_OnUpgradeDeselected()
    StartSoundEffect(kAlienBuyMenuSounds.SellUpgrade)    
end

/**
 * User pressed close button
 */
function AlienBuy_Close()
    local player = Client.GetLocalPlayer()
    player:CloseMenu()
end