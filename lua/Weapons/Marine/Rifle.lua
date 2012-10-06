// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Rifle.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/PickupableWeaponMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

class 'Rifle' (ClipWeapon)

Rifle.kMapName = "rifle"

Rifle.kModelName = PrecacheAsset("models/marine/rifle/rifle.model")
local kViewModelName = PrecacheAsset("models/marine/rifle/rifle_view.model")
local kAnimationGraph = PrecacheAsset("models/marine/rifle/rifle_view.animation_graph")

local kRange = 250
// 4 degrees in NS1
local kSpread = ClipWeapon.kCone4Degrees

local kButtRange = 1.4

local kNumberOfVariants = 3

local kSingleShotSound = PrecacheAsset("sound/ns2c.fev/ns2c/marine/weapon/lmg_fire")

//local kSingleShotSounds = { "sound/NS2.fev/marine/rifle/fire_single", "sound/NS2.fev/marine/rifle/fire_single_2", "sound/NS2.fev/marine/rifle/fire_single_3" }
//for k, v in ipairs(kSingleShotSounds) do PrecacheAsset(v) end

//local kLoopingSounds = { "sound/NS2.fev/marine/rifle/fire_14_sec_loop", "sound/NS2.fev/marine/rifle/fire_loop_2", "sound/NS2.fev/marine/rifle/fire_loop_3",
                         //"sound/NS2.fev/marine/rifle/fire_loop_1_upgrade_1", "sound/NS2.fev/marine/rifle/fire_loop_2_upgrade_1", "sound/NS2.fev/marine/rifle/fire_loop_3_upgrade_1",
                         //"sound/NS2.fev/marine/rifle/fire_loop_1_upgrade_3", "sound/NS2.fev/marine/rifle/fire_loop_2_upgrade_3", "sound/NS2.fev/marine/rifle/fire_loop_3_upgrade_3" }

//for k, v in ipairs(kLoopingSounds) do PrecacheAsset(v) end

local kEndSounds = PrecacheAsset("sound/NS2.fev/marine/rifle/end")

local kMuzzleCinematics = {
    PrecacheAsset("cinematics/marine/rifle/muzzle_flash.cinematic"),
    PrecacheAsset("cinematics/marine/rifle/muzzle_flash2.cinematic"),
    PrecacheAsset("cinematics/marine/rifle/muzzle_flash3.cinematic"),
}

local kMuzzleEffect = PrecacheAsset("cinematics/marine/rifle/muzzle_flash.cinematic")
local kMuzzleAttachPoint = "fxnode_riflemuzzle"

function Rifle:OnCreate()

    ClipWeapon.OnCreate(self)
    
    InitMixin(self, PickupableWeaponMixin, { kRecipientType = "Marine" })
    InitMixin(self, EntityChangeMixin)
    
    if Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    end
    
end

function Rifle:OnInitialized()

    ClipWeapon.OnInitialized(self)
    
    if Client then
    
        self:SetUpdates(true)
        
    end
    
end

function Rifle:OnDestroy()

    ClipWeapon.OnDestroy(self)
    
    if self.muzzleCinematic then
    
        Client.DestroyCinematic(self.muzzleCinematic)
        self.muzzleCinematic = nil
        
    end
    
end

function Rifle:OnPrimaryAttack(player)

    if not self:GetIsReloading() then
    
        ClipWeapon.OnPrimaryAttack(self, player)
        
    end    

end

/*
function Rifle:OnTouch(recipient)
    recipient:AddWeapon(self, true)
    Shared.PlayWorldSound(nil, Marine.kGunPickupSound, nil, recipient:GetOrigin())
end

function Rifle:GetIsValidRecipient(player)
    if player and GetPlayerAutoWeaponPickup(player) then
        local hasWeapon = player:GetWeaponInHUDSlot(self:GetHUDSlot())
        if (not hasWeapon) and self.droppedtime + kPickupWeaponTimeLimit < Shared.GetTime() then
            return true
        end
    end
    return false
end
*/

function Rifle:OnSecondaryAttack(player)
end

function Rifle:GetNumStartClips()
    return 3
end

function Rifle:OnHolster(player)

    if self.muzzleCinematic then
    
        Client.DestroyCinematic(self.muzzleCinematic)
        self.muzzleCinematic = nil
        
    end
    
    ClipWeapon.OnHolster(self, player)
    
end

function Rifle:GetAnimationGraphName()
    return kAnimationGraph
end

function Rifle:GetViewModelName()
    return kViewModelName
end

function Rifle:GetDeathIconIndex()

    if self:GetSecondaryAttacking() then
        return kDeathMessageIcon.RifleButt
    end
    return kDeathMessageIcon.Rifle
    
end

function Rifle:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function Rifle:GetClipSize()
    return kRifleClipSize
end

function Rifle:GetReloadTime()
    return kRifleReloadTime
end

function Rifle:GetSpread()
    return kSpread
end

function Rifle:GetBulletDamage(target, endPoint)
    return kRifleDamage
end

function Rifle:GetRange()
    return kRange
end

function Rifle:GetWeight()
    return kRifleWeight
end

function Rifle:GetSecondaryCanInterruptReload()
    return true
end

function Rifle:GetBarrelSmokeEffect()
    return Rifle.kBarrelSmokeEffect
end

function Rifle:GetShellEffect()
    return chooseWeightedEntry ( Rifle.kShellEffectTable )
end

function Rifle:OnTag(tagName)

    PROFILE("Rifle:OnTag")

    ClipWeapon.OnTag(self, tagName)
    
    if tagName == "hit" then
    
        local player = self:GetParent()
        if player then
            self:PerformMeleeAttack(player)
        end
        
    end

end

function Rifle:SetGunLoopParam(viewModel, paramName, rateOfChange)

    local current = viewModel:GetPoseParam(paramName)
    // 0.5 instead of 1 as full arm_loop is intense.
    local new = Clamp(current + rateOfChange, 0, 0.5)
    viewModel:SetPoseParam(paramName, new)
    
end

function Rifle:UpdateViewModelPoseParameters(viewModel)

    viewModel:SetPoseParam("hide_gl", 1)
    viewModel:SetPoseParam("gl_empty", 1)
    
    local attacking = self:GetPrimaryAttacking()
    local sign = (attacking and 1) or 0
    
    self:SetGunLoopParam(viewModel, "arm_loop", sign)
    
end

function Rifle:OnUpdateAnimationInput(modelMixin)

    PROFILE("Rifle:OnUpdateAnimationInput")
    
    ClipWeapon.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("gl", false)
    
end

function Rifle:GetAmmoPackMapName()
    return RifleAmmo.kMapName
end

if Client then

    function Rifle:OnClientPrimaryAttackStart()
        Shared.StopSound(self, kSingleShotSound)
        Shared.PlaySound(self, kSingleShotSound)
        
        if not self.muzzleCinematic then
        
            local cinematicName = kMuzzleCinematics[1]
            self.activeCinematicName = cinematicName
            self.muzzleCinematic = CreateMuzzleCinematic(self, cinematicName, cinematicName, kMuzzleAttachPoint, nil, Cinematic.Repeat_Endless)
            
        else
        
            local cinematicName = kMuzzleCinematics[1]
            if cinematicName ~= self.activeCinematicName then
            
                Client.DestroyCinematic(self.muzzleCinematic)
                self.muzzleCinematic = CreateMuzzleCinematic(self, cinematicName, cinematicName, kMuzzleAttachPoint, nil, Cinematic.Repeat_Endless)
                self.activeCinematicName = cinematicName
                
            end
            
        end
        
        // CreateMuzzleCinematic() can return nil in case there is no parent or the parent is invisible (for alien commander for example)
        if self.muzzleCinematic then
            self.muzzleCinematic:SetIsVisible(true)
        end
        
    end
    
    function Rifle:OnClientPrimaryAttacking()
        Shared.StopSound(self, kSingleShotSound)
        Shared.PlaySound(self, kSingleShotSound)
    end
    
    function Rifle:OnClientPrimaryAttackEnd()
    
        // Just assume the looping sound is playing.
        Shared.StopSound(self, kSingleShotSound)
        Shared.PlaySound(self, kEndSounds)
        if self.muzzleCinematic then
            self.muzzleCinematic:SetIsVisible(false)
        end
        
    end
    
    function Rifle:GetPrimaryEffectRate()
        return 0.07
    end
    
    function Rifle:GetPreventCameraAnimation()
        return true
    end
    
    function Rifle:GetBarrelPoint()
    
        local player = self:GetParent()
        if player then
        
            local origin = player:GetEyePos()
            local viewCoords= player:GetViewCoords()
            
            return origin + viewCoords.zAxis * 0.4 + viewCoords.xAxis * -0.2 + viewCoords.yAxis * -0.22
            
        end
        
        return self:GetOrigin()
        
    end
    
end

Shared.LinkClassToMap("Rifle", Rifle.kMapName, { })