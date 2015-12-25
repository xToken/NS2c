// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AmmoPack.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Changed ammo back to 1 clip, added in per weapon ammo packs

Script.Load("lua/DropPack.lua")

class 'AmmoPack' (DropPack)

AmmoPack.kMapName = "ammopack"

AmmoPack.kModelNameWinter = PrecacheAsset("seasonal/holiday2012/models/gift_ammopack_01.model")
AmmoPack.kModelName = PrecacheAsset("models/marine/ammopack/ammopack.model")
local function GetModelName()
    return GetSeason() == Seasons.kWinter and AmmoPack.kModelNameWinter or AmmoPack.kModelName
end

AmmoPack.kPickupSound = PrecacheAsset("sound/NS2.fev/marine/common/pickup_ammo")

function AmmoPack:OnInitialized()

    DropPack.OnInitialized(self)
    
    self:SetModel(GetModelName())
	
end

function AmmoPack:OnTouch(recipient)

    local weapon = recipient:GetActiveWeapon()
    
    if weapon and weapon:GiveAmmo(kClipsPerAmmoPack * weapon:GetAmmoPackMultiplyer(), false) then
        StartSoundEffectAtOrigin(AmmoPack.kPickupSound, recipient:GetOrigin())
    end
    
end

function AmmoPack:GetIsValidRecipient(recipient)

    // Ammo packs give ammo to clip as well (so pass true to GetNeedsAmmo())
    local weapon = recipient:GetActiveWeapon()
    return weapon ~= nil and weapon:isa("ClipWeapon") and weapon:GetNeedsAmmo(false) and recipient:GetIsAlive()
    
end

Shared.LinkClassToMap("AmmoPack", AmmoPack.kMapName)

class 'WeaponAmmoPack' (AmmoPack)
WeaponAmmoPack.kMapName = "weapoanammopack"

function WeaponAmmoPack:SetAmmoPackSize(size)
    self.ammoPackSize = size
end

function WeaponAmmoPack:OnTouch(recipient)

    local weapon = recipient:GetActiveWeapon()
    weapon:GiveReserveAmmo(self.ammoPackSize)
    StartSoundEffectAtOrigin(AmmoPack.kPickupSound, recipient:GetOrigin())
    
end

function WeaponAmmoPack:GetIsValidRecipient(recipient)
	
    local weapon = recipient:GetActiveWeapon()
    local correctWeaponType = weapon and weapon:isa(self:GetWeaponClassName())    
    return self.ammoPackSize ~= nil and correctWeaponType and AmmoPack.GetIsValidRecipient(self, recipient) and not recipient:GetIsStateFrozen()
    
end

Shared.LinkClassToMap("WeaponAmmoPack", WeaponAmmoPack.kMapName)

// -------------

class 'RifleAmmo' (WeaponAmmoPack)
RifleAmmo.kMapName = "rifleammo"
RifleAmmo.kModelName = PrecacheAsset("models/marine/ammopacks/lmg.model")

function RifleAmmo:OnInitialized()

    WeaponAmmoPack.OnInitialized(self)
    self:SetModel(RifleAmmo.kModelName)

end

function RifleAmmo:GetWeaponClassName()
    return "Rifle"
end  

Shared.LinkClassToMap("RifleAmmo", RifleAmmo.kMapName)

// -------------

class 'ShotgunAmmo' (WeaponAmmoPack)
ShotgunAmmo.kMapName = "shotgunammo"
ShotgunAmmo.kModelName = PrecacheAsset("models/marine/ammopacks/sg.model")

function ShotgunAmmo:OnInitialized()

    WeaponAmmoPack.OnInitialized(self)    
    self:SetModel(ShotgunAmmo.kModelName)

end

function ShotgunAmmo:GetWeaponClassName()
    return "Shotgun"
end    

Shared.LinkClassToMap("ShotgunAmmo", ShotgunAmmo.kMapName)


class 'GrenadeLauncherAmmo' (WeaponAmmoPack)
GrenadeLauncherAmmo.kMapName = "grenadelauncherammo"
GrenadeLauncherAmmo.kModelName = PrecacheAsset("models/marine/ammopacks/gl.model")

function GrenadeLauncherAmmo:OnInitialized()

    WeaponAmmoPack.OnInitialized(self)    
    self:SetModel(GrenadeLauncherAmmo.kModelName)

end

function GrenadeLauncherAmmo:GetWeaponClassName()
    return "GrenadeLauncher"
end

Shared.LinkClassToMap("GrenadeLauncherAmmo", GrenadeLauncherAmmo.kMapName)


class 'HeavyMachineGunAmmo' (WeaponAmmoPack)
HeavyMachineGunAmmo.kMapName = "heavymachinegunammo"
HeavyMachineGunAmmo.kModelName = PrecacheAsset("models/marine/ammopacks/hmg.model")

function HeavyMachineGunAmmo:OnInitialized()

    WeaponAmmoPack.OnInitialized(self)    
    self:SetModel(HeavyMachineGunAmmo.kModelName)

end

function HeavyMachineGunAmmo:GetWeaponClassName()
    return "HeavyMachineGun"
end    

Shared.LinkClassToMap("HeavyMachineGunAmmo", HeavyMachineGunAmmo.kMapName)