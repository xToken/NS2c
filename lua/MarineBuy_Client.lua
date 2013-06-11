//=============================================================================
//
// lua/MarineBuy_Client.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

local gWeaponDescription = nil
function MarineBuy_GetWeaponDescription(techId)

    if not gWeaponDescription then
    
        gWeaponDescription = { }
        gWeaponDescription[kTechId.Axe] = "WEAPON_DESC_AXE"
        gWeaponDescription[kTechId.Pistol] = "WEAPON_DESC_PISTOL"
        gWeaponDescription[kTechId.Rifle] = "WEAPON_DESC_RIFLE"
        gWeaponDescription[kTechId.Shotgun] = "WEAPON_DESC_SHOTGUN"
		gWeaponDescription[kTechId.HeavyMachineGun] = "WEAPON_DESC_HEAVYMACHINEGUN"
        gWeaponDescription[kTechId.GrenadeLauncher] = "WEAPON_DESC_GRENADELAUNCHER"
        gWeaponDescription[kTechId.Welder] = "WEAPON_DESC_WELDER"
        gWeaponDescription[kTechId.Mines] = "WEAPON_DESC_MINE"
        gWeaponDescription[kTechId.Jetpack] = "WEAPON_DESC_JETPACK"
        gWeaponDescription[kTechId.HeavyArmorMarine] = "WEAPON_DESC_HEAVY_ARMOR"
        
    end
    
    local description = gWeaponDescription[techId]
    if not description then
        description = ""
    end
    
    return Locale.ResolveString(description)
    
end

function GetCurrentPrimaryWeaponTechId()

    local weapons = Client.GetLocalPlayer():GetHUDOrderedWeaponList()
    if table.count(weapons) > 0 then
    
        // Main weapon is our primary weapon - in the first slot
        return weapons[1]:GetTechId()
        
    end
    
    Print("GetCurrentPrimaryWeaponTechId(): Couldn't find current primary weapon.")
    
    return kTechId.None

end

/**
 * Get weapon id for current weapon (nebulously defined since there are 3 potentials?)
 */
function MarineBuy_GetCurrentWeapon()
    return TechIdToWeaponIndex(GetCurrentPrimaryWeaponTechId())
end

/**
 * Return information about the available weapons in a linear array
 * Name - string (for tooltips?)
 * normal tex x - int
 * normal tex y - int
 */
function MarineBuy_GetEquippedWeapons()

    local t = {}
    
    local player = Client.GetLocalPlayer()
    local items = GetChildEntities(player, "ScriptActor")

    for index, item in ipairs(items) do
    
        local techId = item:GetTechId()
        
        if techId ~= kTechId.Pistol and techId ~= kTechId.Axe then
        
            local itemName = GetDisplayNameForTechId(techId)
            table.insert(t, itemName)    
            
            local index = TechIdToWeaponIndex(techId)
            table.insert(t, 0)
            table.insert(t, index - 1)
            
        end

    end
    
    return t
    
end

/**
 * User pressed close button
 */
function MarineBuy_Close()

    // Close menu
    local player = Client.GetLocalPlayer()
    if player then
        player:CloseMenu()
    end
    
end

local kMarineBuyMenuSounds = { Open = "sound/NS2.fev/common/open",
                              Close = "sound/NS2.fev/common/close",
                              Purchase = "sound/ns2.fev/marine/common/comm_spend_metal",
                              SelectUpgrade = "sound/NS2.fev/common/button_press",
                              SellUpgrade = "sound/ns2.fev/marine/common/comm_spend_metal",
                              Hover = "sound/NS2.fev/common/hovar",
                              SelectWeapon = "sound/NS2.fev/common/hovar",
                              SelectJetpack = "sound/ns2.fev/marine/common/pickup_jetpack",
                              SelectHeavyArmor = "sound/ns2.fev/marine/common/pickup_heavy" }

for i, soundAsset in pairs(kMarineBuyMenuSounds) do
    Client.PrecacheLocalSound(soundAsset)
end

local gDisplayTechs = nil
local function GetDisplayTechId(techId)

    if not gDisplayTechs then
    
        gDisplayTechs = {}
        gDisplayTechs[kTechId.Axe] = true
        gDisplayTechs[kTechId.Pistol] = true
        gDisplayTechs[kTechId.Rifle] = true
        gDisplayTechs[kTechId.Shotgun] = true
		gDisplayTechs[kTechId.HeavyMachineGun] = true
        gDisplayTechs[kTechId.GrenadeLauncher] = true
        gDisplayTechs[kTechId.Welder] = true
        gDisplayTechs[kTechId.Mines] = true
        gDisplayTechs[kTechId.Jetpack] = true
        gDisplayTechs[kTechId.HeavyArmorMarine] = true
    
    end

    return gDisplayTechs[techId]

end

function MarineBuy_GetEquipped()

    local equipped = {}
    
    local player = Client.GetLocalPlayer()
    local items = GetChildEntities(player, "ScriptActor")

    for index, item in ipairs(items) do
    
        local techId = item:GetTechId()
        if GetDisplayTechId(techId) then
            table.insertunique(equipped, techId)
        end
        
    end
    
    if player and player:isa("JetpackMarine") then
        table.insertunique(equipped, kTechId.Jetpack)
    end    
    
    return equipped

end

// called by GUIMarineBuyMenu

function MarineBuy_IsResearched(techId)

    local techNode = GetTechTree():GetTechNode(techId)
    
    if techNode ~= nil then
        return techNode:GetAvailable(Client.GetLocalPlayer(), techId, 0)
    end
    
    return true
end


function MarineBuy_GetHas(techId)
    //TODO: check if local player already has the item / upgrades    
    return false
end

function MarineBuy_OnMouseOver()
    StartSoundEffect(kMarineBuyMenuSounds.Hover)
end

function MarineBuy_OnOpen()
    StartSoundEffect(kMarineBuyMenuSounds.Open)
end

function MarineBuy_OnClose()

    StartSoundEffect(kMarineBuyMenuSounds.Close)
    MarineBuy_CloseNonFlash()

end

function MarineBuy_OnPurchase()
    StartSoundEffect(kMarineBuyMenuSounds.Puchase)
end

function MarineBuy_OnUpgradeSelected()
    StartSoundEffect(kMarineBuyMenuSounds.SelectUpgrade)    
end

function MarineBuy_OnUpgradeDeselected()
    StartSoundEffect(kMarineBuyMenuSounds.SellUpgrade)    
end

// special sounds for jetpack etc.
function MarineBuy_OnItemSelect(techId)

    if techId == kTechId.Axe or techId == kTechId.Rifle or techId == kTechId.Shotgun or techId == kTechId.GrenadeLauncher or 
        techId == kTechId.Welder or techId == kTechId.Mines then
       
        StartSoundEffect(kMarineBuyMenuSounds.SelectWeapon)
        
    elseif techId == kTechId.Jetpack then
    
        StartSoundEffect(kMarineBuyMenuSounds.SelectJetpack)

    elseif techId == kTechId.HeavyArmorMarine then
    
        StartSoundEffect(kMarineBuyMenuSounds.SelectHeavyArmor)
        
    end

end

/**
 * User pressed close button
 */
function MarineBuy_CloseNonFlash()
    local player = Client.GetLocalPlayer()
    player:CloseMenu()
end

function MarineBuy_PurchaseItem(itemTechId)
    Client.SendNetworkMessage("Buy", BuildBuyMessage({ itemTechId }), true)
end

function MarineBuy_GetDisplayName(techId)
    if techId ~= nil then
        return Locale.ResolveString(LookupTechData(techId, kTechDataDisplayName, ""))
    else
        return ""
    end
end

function MarineBuy_GetCosts(techId)
    if techId ~= nil then
        return LookupTechData(techId, kTechDataCostKey, 0)
    else
        return 0
    end
end

function MarineBuy_GetResearchProgress(techId)

    local techTree = GetTechTree()
    local techNode = nil
    
    if techTree ~= nil then
        techNode = techTree:GetTechNode(techId)
    end
    
    if techNode  ~= nil then
        return techNode:GetPrereqResearchProgress()
    end
    
    return 0    
end