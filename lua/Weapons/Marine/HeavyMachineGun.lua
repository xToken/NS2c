// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\HeavyMachineGun.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/PickupableWeaponMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

class 'HeavyMachineGun' (ClipWeapon)

HeavyMachineGun.kMapName = "heavymachinegun"

HeavyMachineGun.kModelName = PrecacheAsset("models/marine/heavymachinegun/heavymachinegun.model")
local kViewModelName = PrecacheAsset("models/marine/rifle/rifle_view.model")
local kAnimationGraph = PrecacheAsset("models/marine/heavymachinegun/heavymachinegun_view.animation_graph")

local kRange = 250
// 15 degrees in NS1
local kSpread = ClipWeapon.kCone10Degrees

local kButtRange = 1.4

local kNumberOfVariants = 3

local kSingleShotSounds = { "sound/NS2.fev/marine/rifle/fire_single", "sound/NS2.fev/marine/rifle/fire_single_2", "sound/NS2.fev/marine/rifle/fire_single_3" }
for k, v in ipairs(kSingleShotSounds) do PrecacheAsset(v) end

//local kSpinUpSoundName = PrecacheAsset("sound/NS2.fev/marine/heavy/spin_up")
//local kSpinDownSoundName = PrecacheAsset("sound/NS2.fev/marine/heavy/spin_down")
//local kSpinSoundName = PrecacheAsset("sound/NS2.fev/marine/heavy/spin")

//local kLoopingSounds = { "sound/NS2.fev/marine/rifle/fire_14_sec_loop", "sound/NS2.fev/marine/rifle/fire_loop_2", "sound/NS2.fev/marine/rifle/fire_loop_3" }
local kLoopingSounds = { "sound/NS2.fev/marine/heavy/spin", "sound/NS2.fev/marine/heavy/spin" , "sound/NS2.fev/marine/heavy/spin"  }
for k, v in ipairs(kLoopingSounds) do PrecacheAsset(v) end

//local kHeavyMachineGunEndSound = PrecacheAsset("sound/NS2.fev/marine/rifle/end")
local kHeavyMachineGunEndSound = PrecacheAsset("sound/NS2.fev/marine/heavy/spin_down")

local networkVars =
{
    soundType = "integer (1 to 3)"
}

local kMuzzleEffect = PrecacheAsset("cinematics/marine/rifle/muzzle_flash.cinematic")
local kMuzzleAttachPoint = "fxnode_riflemuzzle"

function HeavyMachineGun:OnCreate()

    ClipWeapon.OnCreate(self)
    
    InitMixin(self, PickupableWeaponMixin, { kRecipientType = "Marine" })
    InitMixin(self, EntityChangeMixin)
    
    if Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    end

end

function HeavyMachineGun:OnInitialized()

    ClipWeapon.OnInitialized(self)
    
    self.soundType = Shared.GetRandomInt(1, kNumberOfVariants)
    
    if Client then
    
        self:SetUpdates(true)
        self:SetFirstPersonAttackingEffect(kMuzzleEffect)
        self:SetThirdPersonAttackingEffect(kMuzzleEffect)
        self:SetMuzzleAttachPoint(kMuzzleAttachPoint)
        
    end
    
end

function HeavyMachineGun:OnHolsterClient()

    ClipWeapon.OnHolsterClient(self)

end

function HeavyMachineGun:OnDestroy()
    ClipWeapon.OnDestroy(self)
end

function HeavyMachineGun:OnPrimaryAttack(player)

    if not self:GetIsReloading() then
        ClipWeapon.OnPrimaryAttack(self, player)
    end    

end

function HeavyMachineGun:GetNumStartClips()
    return 2
end
/*
function HeavyMachineGun:OnTouch(recipient)
    recipient:AddWeapon(self, true)
    Shared.PlayWorldSound(nil, Marine.kGunPickupSound, nil, recipient:GetOrigin())
end

function HeavyMachineGun:GetIsValidRecipient(player)
    if player then
        local hasWeapon = player:GetWeaponInHUDSlot(self:GetHUDSlot())
        if (not hasWeapon or hasWeapon.kMapName == "rifle") and self.droppedtime + kPickupWeaponTimeLimit < Shared.GetTime() then
            return true
        end
    end
    return false
end
*/
function HeavyMachineGun:GetMaxAmmo()
    return 3 * self:GetClipSize()
end

function HeavyMachineGun:OnSecondaryAttack(player)
    
end

function HeavyMachineGun:GetAnimationGraphName()
    return kAnimationGraph
end

function HeavyMachineGun:GetViewModelName()
    return kViewModelName
end

function HeavyMachineGun:GetDeathIconIndex()

    if self:GetSecondaryAttacking() then
        return kDeathMessageIcon.HeavyMachineGunButt
    end
    return kDeathMessageIcon.HeavyMachineGun
    
end

function HeavyMachineGun:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function HeavyMachineGun:GetClipSize()
    return kHeavyMachineGunClipSize
end

function HeavyMachineGun:GetReloadTime()
    return kHeavyMachineGunReloadTime
end

function HeavyMachineGun:GetSpread()
    return kSpread
end

function HeavyMachineGun:GetBulletDamage(target, endPoint)
    return kHeavyMachineGunDamage
end

function HeavyMachineGun:GetRange()
    return kRange
end

function HeavyMachineGun:GetWeight()
    return kHeavyMachineGunWeight
end

function HeavyMachineGun:GetSecondaryCanInterruptReload()
    return true
end

function HeavyMachineGun:OverrideWeaponName()
    return "rifle"
end

function HeavyMachineGun:GetBarrelSmokeEffect()
    return HeavyMachineGun.kBarrelSmokeEffect
end

function HeavyMachineGun:GetShellEffect()
    return chooseWeightedEntry ( HeavyMachineGun.kShellEffectTable )
end

function HeavyMachineGun:OnTag(tagName)

    PROFILE("HeavyMachineGun:OnTag")

    ClipWeapon.OnTag(self, tagName)

end

function HeavyMachineGun:SetGunLoopParam(viewModel, paramName, rateOfChange)

    local current = viewModel:GetPoseParam(paramName)
    // 0.5 instead of 1 as full arm_loop is intense.
    local new = Clamp(current + rateOfChange, 0, 0.5)
    viewModel:SetPoseParam(paramName, new)
    
end

function HeavyMachineGun:UpdateViewModelPoseParameters(viewModel)

    viewModel:SetPoseParam("hide_gl", 0)
    viewModel:SetPoseParam("gl_empty", 0)

    local attacking = self:GetPrimaryAttacking()
    local sign = (attacking and 1) or 0

    self:SetGunLoopParam(viewModel, "arm_loop", sign)
    
end

function HeavyMachineGun:Dropped(prevOwner)

    ClipWeapon.Dropped(self, prevOwner)
    
end

function HeavyMachineGun:OnUpdateAnimationInput(modelMixin)
    
    PROFILE("HeavyMachineGun:OnUpdateAnimationInput")
    ClipWeapon.OnUpdateAnimationInput(self, modelMixin)

    modelMixin:SetAnimationInput("gl", false)
    
end

function HeavyMachineGun:GetAmmoPackMapName()
    return HeavyMachineGunAmmo.kMapName
end

if Client then

    function HeavyMachineGun:OnClientPrimaryAttackStart()
    
        // Fire off a single shot on the first shot. Pew.
        Shared.PlaySound(self, kSingleShotSounds[self.soundType])
        // Start the looping sound for the rest of the shooting. Pew pew pew...
        Shared.PlaySound(self, kLoopingSounds[self.soundType])
    
    end
    
    function HeavyMachineGun:OnClientPrimaryAttackEnd()
    
        // Just assume the looping sound is playing.
        Shared.StopSound(self, kLoopingSounds[self.soundType])
        Shared.PlaySound(self, kHeavyMachineGunEndSound)

    end

    function HeavyMachineGun:GetPrimaryEffectRate()
        return 0.03
    end
    
    function HeavyMachineGun:GetPreventCameraAnimation()
        return self:GetIsReloading()
    end

    function HeavyMachineGun:GetBarrelPoint()

        local player = self:GetParent()
        if player then
        
            local origin = player:GetEyePos()
            local viewCoords= player:GetViewCoords()
        
            return origin + viewCoords.zAxis * 0.4 + viewCoords.xAxis * -0.2 + viewCoords.yAxis * -0.22
        end
        
        return self:GetOrigin()
        
    end  

end

Shared.LinkClassToMap("HeavyMachineGun", HeavyMachineGun.kMapName, networkVars)