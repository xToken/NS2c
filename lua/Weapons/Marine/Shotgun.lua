// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Shotgun.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Balance.lua")
Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/PickupableWeaponMixin.lua")

class 'Shotgun' (ClipWeapon)

Shotgun.kMapName = "shotgun"

local networkVars =
{
    emptyPoseParam = "private float (0 to 1 by 0.01)"
}

Shotgun.kModelName = PrecacheAsset("models/marine/shotgun/shotgun.model")
local kViewModelName = PrecacheAsset("models/marine/shotgun/shotgun_view.model")
local kAnimationGraph = PrecacheAsset("models/marine/shotgun/shotgun_view.animation_graph")

local kMuzzleEffect = PrecacheAsset("cinematics/marine/shotgun/muzzle_flash.cinematic")
local kMuzzleAttachPoint = "fxnode_shotgunmuzzle"

function Shotgun:OnCreate()

    ClipWeapon.OnCreate(self)
    
    InitMixin(self, PickupableWeaponMixin)
    
    self.emptyPoseParam = 0

end

if Client then

    function Shotgun:OnInitialized()
    
        ClipWeapon.OnInitialized(self)
    
    end

end

function Shotgun:GetAnimationGraphName()
    return kAnimationGraph
end

function Shotgun:GetViewModelName()
    return kViewModelName
end

function Shotgun:GetDeathIconIndex()
    return kDeathMessageIcon.Shotgun
end

function Shotgun:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function Shotgun:GetClipSize()
    return kShotgunClipSize
end

function Shotgun:GetBulletsPerShot()
    return kShotgunBulletsPerShot
end
/*
function Shotgun:OnTouch(recipient)
    recipient:AddWeapon(self, true)
    Shared.PlayWorldSound(nil, Marine.kGunPickupSound, nil, recipient:GetOrigin())
end

function Shotgun:GetIsValidRecipient(player)
    if player then
        local hasWeapon = player:GetWeaponInHUDSlot(self:GetHUDSlot())
        if (not hasWeapon or hasWeapon.kMapName == "rifle") and self.droppedtime + kPickupWeaponTimeLimit < Shared.GetTime() then
            return true
        end
    end
    return false
end
*/
function Shotgun:GetSpread(bulletNum)

    // NS1 was 20 degrees for half the shots and 20 degrees plus 7 degrees for half the shots
    if bulletNum < (kShotgunBulletsPerShot / 2) then
        return Math.Radians(8)
    else
        return Math.Radians(20)
    end
    
end

function Shotgun:GetRange()
    return kShotgunMaxRange
end

function Shotgun:GetNumStartClips()
    return 2
end

// Only play weapon effects every other bullet to avoid sonic overload
function Shotgun:GetTracerEffectFrequency()
    return 0.5
end

function Shotgun:GetBulletDamage(target, endPoint)
    //
    if Server then
        local player = self:GetParent()
        if player then  
            local distanceTo = (player:GetOrigin() - endPoint):GetLength()
            if distanceTo > kShotgunMaxRange then
                return 0
            elseif distanceTo <= kShotgunDropOffStartRange then
                return kShotgunDamage
            else
                return kShotgunDamage * (1 - math.sin((distanceTo - kShotgunDropOffStartRange) / kShotgunMaxRange))
            end
        end
    end
    return kShotgunDamage
end

function Shotgun:GetHasSecondary(player)
    return false
end

function Shotgun:GetPrimaryCanInterruptReload()
    return true
end

function Shotgun:GetWeight()
    return kShotgunWeight
end

function Shotgun:UpdateViewModelPoseParameters(viewModel)

    viewModel:SetPoseParam("empty", self.emptyPoseParam)
    
end

local function LoadBullet(self)

    if self.ammo > 0 and self.clip < self:GetClipSize() then
    
        self.clip = self.clip + 1
        self.ammo = self.ammo - 1
        
    end
    
end

function Shotgun:OnTag(tagName)

    PROFILE("Shotgun:OnTag")

    continueReloading = false
    if self:GetIsReloading() and tagName == "reload_end" then
        continueReloading = true
    end
    
    if tagName == "end" then
        self.primaryAttacking = false
    end
    
    ClipWeapon.OnTag(self, tagName)
    
    if tagName == "load_shell" then
        LoadBullet(self)
    elseif tagName == "reload_shotgun_start" then
        self:TriggerEffects("shotgun_reload_start")
    elseif tagName == "reload_shotgun_shell" then
        self:TriggerEffects("shotgun_reload_shell")
    elseif tagName == "reload_shotgun_end" then
        self:TriggerEffects("shotgun_reload_end")
    end
    
    if continueReloading then
    
        local player = self:GetParent()
        if player then
            player:Reload()
        end
        
    end
    
end

function Shotgun:FirePrimary(player)
    
    ClipWeapon.FirePrimary(self, player)
    self:TriggerEffects("shotgun_attack")

end

function Shotgun:OnProcessMove(input)
    ClipWeapon.OnProcessMove(self, input)
    self.emptyPoseParam = Clamp(Slerp(self.emptyPoseParam, ConditionalValue(self.clip == 0, 1, 0), input.time * 1), 0, 1)
end

function Shotgun:GetAmmoPackMapName()
    return ShotgunAmmo.kMapName
end    


Shared.LinkClassToMap("Shotgun", Shotgun.kMapName, networkVars)