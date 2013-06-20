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
Script.Load("lua/AlienUpgrades_Client.lua")
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
        return {"Fade", kFadeHealth, kFadeArmor, kFadeCost}
    elseif techId == kTechId.Gorge then
        return {"Gorge", kGorgeHealth, kGorgeArmor, kGorgeCost}
    elseif techId == kTechId.Lerk then
        return {"Lerk", kLerkHealth, kLerkArmor, kLerkCost}
    elseif techId == kTechId.Onos then
        return {"Onos", kOnosHealth, kOnosArmor, kOnosCost}
    else
        return {"Skulk", kSkulkHealth, kSkulkArmor, kSkulkCost}
    end   
    
end

// iconx, icony, name, tooltip, research, cost
function GetUnpurchasedUpgradeInfoArray(techIdTable)

    local t = {}
    
    local player = Client.GetLocalPlayer()
    
    if player then
    
        for index, techId in ipairs(techIdTable) do
        
            if not player:GetIsUpgradeForbidden(techId) then
        
                local iconX, iconY = GetMaterialXYOffset(techId, false)
                
                if iconX and iconY then

                    local techTree = GetTechTree(player:GetTeamNumber())
                
                    table.insert(t, iconX)
                    table.insert(t, iconY)                    
                    table.insert(t, GetDisplayNameForTechId(techId, string.format("<name not found - %s>", EnumToString(kTechId, techId))))                    
                    table.insert(t, GetTooltipInfoText(techId))                 
                    table.insert(t, GetTechTree():GetResearchProgressForNode(techId))
                    table.insert(t, LookupTechData(techId, kTechDataCostKey, 0))
                    table.insert(t, techId)
                    if techTree then
                        table.insert(t, techTree:GetIsTechAvailable(techId))
                    else
                        table.insert(t, false)
                    end
                end
            
            end
            
        end
    
    end
    
    return t
    
end

function AlienBuy_GetTechAvailable(techId)

    local techNode = GetTechTree():GetTechNode(techId)
    
    if techNode ~= nil then
        return techNode:GetAvailable(Client.GetLocalPlayer(), techId, false)
    end
    
    return true

end

function AlienBuy_GetHasTech(techId)
    return GetHasTech(Client.GetLocalPlayer(), techId)
end

function AlienBuy_GetIsUpgradeAllowed(techId, upgradeList)

    local player = Client.GetLocalPlayer()
    return GetIsUpgradeAllowed(player, techId, upgradeList)

end

function AlienBuy_GetUpgradePurchased(techId)

    local player = Client.GetLocalPlayer()
    if player then
        return player:GetHasUpgrade(techId)
    end

end

function GetPurchaseableTechIds(techId)

    // Get list of potential upgrades for lifeform. These are tech nodes with
    // "addOnTechId" set to this tech id.
    local addOnUpgrades = {}
    
    local player = Client.GetLocalPlayer()
    local techTree = GetTechTree()
    
    if techTree ~= nil then
    
        // Use upgrades for our lifeform, plus global upgrades 
        addOnUpgrades = techTree:GetAddOnsForTechId(techId)
        
        table.copy(techTree:GetAddOnsForTechId(kTechId.AllAliens), addOnUpgrades, true)        
        
        // If we've already purchased it, or if it's not available, remove it. Iterate through a different
        // table as we'll be changing it as we go.
        local addOnCopy = {}
        table.copy(addOnUpgrades, addOnCopy)

        for key, value in pairs(addOnCopy) do
        
            local techNode = techTree:GetTechNode(value)
            local canPurchase = (techNode and techNode:GetIsBuy() and techNode:GetAvailable())
            
            if not canPurchase then
            
                table.removevalue(addOnUpgrades, value)
                
            end
            
        end
        
    end
    
    return addOnUpgrades
    
end

function GetUnpurchasedTechIds(techId)

    // Get list of potential upgrades for lifeform. These are tech nodes with
    // "addOnTechId" set to this tech id.
    local addOnUpgrades = {}
    
    local player = Client.GetLocalPlayer()
    local techTree = GetTechTree()
    
    if techTree ~= nil then
    
        // Use upgrades for our lifeform, plus global upgrades 
        addOnUpgrades = techTree:GetAddOnsForTechId(techId)
        
        table.copy(techTree:GetAddOnsForTechId(kTechId.AllAliens), addOnUpgrades, true)        
        
        // If we've already purchased it, or if it's not available, remove it. Iterate through a different
        // table as we'll be changing it as we go.
        local addOnCopy = {}
        table.copy(addOnUpgrades, addOnCopy)

        for key, value in pairs(addOnCopy) do
        
            local hasTech = player:GetHasUpgrade(value)
            local techNode = techTree:GetTechNode(value)
            local canPurchase = (techNode and techNode:GetIsBuy() and techNode:GetAvailable())
            
            if hasTech or not canPurchase then
            
                table.removevalue(addOnUpgrades, value)
                
            end
            
        end
        
    end
    
    return addOnUpgrades
    
end

/**
 * Return 1-d array of all unpurchased upgrades for this class index
 * Format is x icon offset, y icon offset, name, tooltip,
 * research pct [0.0 - 1.0], and cost
 */
function AlienBuy_GetUnpurchasedUpgrades(idx)
    if idx == nil then
        Print("AlienBuy_GetUnpurchasedUpgrades(nil) called")
        return {}
    end
    
    return GetUnpurchasedUpgradeInfoArray(GetUnpurchasedTechIds(IndexToAlienTechId(idx)))   
end

function GetPurchasedUpgradeInfoArray(techIdTable)

    local t = {}
    
    local player = Client.GetLocalPlayer()
    
    for index, techId in ipairs(techIdTable) do

        local iconX, iconY = GetMaterialXYOffset(techId, false)
        if iconX and iconY then

            local techTree = GetTechTree(player:GetTeamNumber())
        
            table.insert(t, iconX)
            table.insert(t, iconY)
            table.insert(t, GetDisplayNameForTechId(techId, string.format("<not found - %s>", EnumToString(kTechId, techId))))
            table.insert(t, GetTooltipInfoText(techId))
            table.insert(t, techId)
            table.insert(t, GetIsTechAvailable(player:GetTeamNumber(), techId))

            if techTree then
                table.insert(t, techTree:GetIsTechAvailable(techId))
            else
                table.insert(t, false)
            end
            
        else
        
            Print("GetPurchasedUpgradeInfoArray():GetAlienUpgradeIconXY(%s): Couldn't find upgrade icon.", ToString(techId))
            
        end
    end
    
    return t
    
end

/**
 * Filter out tech Ids that don't apply to this specific Alien or all Aliens.
 */
local function FilterInvalidUpgradesForPlayer(player, forAlienTechId)

    local techIdTable = player:GetUpgrades()
    local techTree = GetTechTree()
    // We can't check if there is no tech tree, assume everything is ok.
    if not techTree then
        return techIdTable
    end
    
    local validAddons = techTree:GetAddOnsForTechId(forAlienTechId)
    table.copy(techTree:GetAddOnsForTechId(kTechId.AllAliens), validAddons, true)  

    local validIds = { }
    for index, upgradeTechId in ipairs(techIdTable) do
    
        if table.contains(validAddons, upgradeTechId) then
            table.insert(validIds, upgradeTechId)
        end
    
    end
    
    return validIds

end

/**
 * Return 1-d array of all purchased upgrades for this class index
 * Format is x icon offset, y icon offset, and name
 */
function AlienBuy_GetPurchasedUpgrades(idx)

    local player = Client.GetLocalPlayer()
    return GetPurchasedUpgradeInfoArray(FilterInvalidUpgradesForPlayer(player, IndexToAlienTechId(idx)))
    
end

local function PurchaseTechs(purchaseIds)

    assert(purchaseIds)
    assert(table.count(purchaseIds) > 0)
    
    local player = Client.GetLocalPlayer()
    
    local validPurchaseIds = { }
    
    for i = 1, #purchaseIds do
    
        local purchaseId = purchaseIds[i]
        local techNode = GetTechTree():GetTechNode(purchaseId)
        
        if techNode ~= nil then
        
            if techNode:GetAvailable() then
                table.insert(validPurchaseIds, purchaseId)
            end
            
        else
        
            Shared.Message("PurchaseTechs(): Couldn't find tech node " .. purchaseId)
            return
            
        end
        
    end
    
    if #validPurchaseIds > 0 then
        Client.SendNetworkMessage("Buy", BuildBuyMessage(validPurchaseIds), true)
    end
    
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
    
    PurchaseTechs(purchaseTechIds)

end

function GetAlienTechNode(idx, isAlienIndex)

    local techNode = nil
    
    local techId = idx
    
    if isAlienIndex then
        techId = IndexToAlienTechId(idx)
    end
    
    local techTree = GetTechTree()
    
    if techTree ~= nil then
        techNode = techTree:GetTechNode(techId)
    end
    
    return techNode
    
end

/**
 * Return true if alien type is researched, false otherwise
 */
function AlienBuy_IsAlienResearched(alienType)
    local techNode = GetAlienTechNode(alienType, true)
    return (techNode ~= nil) and techNode:GetAvailable()    
end

/**
 * Return the research progress (0-1) of the passed in alien type.
 * Returns 0 if the passed in alien type didn't have a tech node.
 */
function AlienBuy_GetAlienResearchProgress(alienType)

    local techNode = GetAlienTechNode(alienType, true)
    if techNode then
        return techNode:GetPrereqResearchProgress()
    end
    return 0
    
end

/**
 * Return cost for the base alien type
 */
function AlienBuy_GetAlienCost(alienType)

    local cost = nil
    
    local techNode = GetAlienTechNode(alienType, true)
    if techNode ~= nil then
        cost = techNode:GetCost()
    end
    
    if cost == nil then
        cost = 0
    end
    
    return cost
    
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