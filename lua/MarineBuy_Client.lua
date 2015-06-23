//=============================================================================
//
// lua/MarineBuy_Client.lua
// 
// Created by Henry Kropf and Charlie Cleveland
// Copyright 2011, Unknown Worlds Entertainment
//
//=============================================================================

//NS2c
//Adjusted techids for classic

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
        gWeaponDescription[kTechId.HandGrenades] = "WEAPON_DESC_HANDGRENADES"
        gWeaponDescription[kTechId.Jetpack] = "WEAPON_DESC_JETPACK"
        gWeaponDescription[kTechId.HeavyArmor] = "WEAPON_DESC_HEAVY_ARMOR"
        gWeaponDescription[kTechId.Weapons1] = "WEAPON_DESC_WEAPONS1"
        gWeaponDescription[kTechId.Weapons2] = "WEAPON_DESC_WEAPONS2"
        gWeaponDescription[kTechId.Weapons3] = "WEAPON_DESC_WEAPONS3"
        gWeaponDescription[kTechId.Armor1] = "WEAPON_DESC_ARMOR1"
        gWeaponDescription[kTechId.Armor2] = "WEAPON_DESC_ARMOR2"
        gWeaponDescription[kTechId.Armor3] = "WEAPON_DESC_ARMOR3"
        gWeaponDescription[kTechId.MedPack] = "WEAPON_DESC_RESUPPLY"
        gWeaponDescription[kTechId.Scan] = "WEAPON_DESC_SCAN"
        gWeaponDescription[kTechId.CatPack] = "WEAPON_DESC_CATPACK"
        gWeaponDescription[kTechId.MotionTracking] = "WEAPON_DESC_MOTIONTRACKING"
        
    end
    
    local description = gWeaponDescription[techId]
    if not description then
        description = ""
    end
    
    return Locale.ResolveString(description)
    
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