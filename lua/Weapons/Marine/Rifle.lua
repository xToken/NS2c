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

// 4 degrees in NS1
local kSpread = ClipWeapon.kCone3Degrees

//local kSingleShotSound = PrecacheAsset("sound/ns2c.fev/ns2c/marine/weapon/lmg_fire")
//local kEndSound = PrecacheAsset("sound/NS2.fev/marine/rifle/end")

local kSingleShotSound = PrecacheAsset("sound/NS2.fev/marine/rifle/fire_single_3")
local kLoopingSound = PrecacheAsset("sound/NS2.fev/marine/rifle/fire_loop_1_upgrade_3")
local kEndSound = PrecacheAsset("sound/NS2.fev/marine/rifle/end_upgrade_3")

local kMuzzleEffect = PrecacheAsset("cinematics/marine/rifle/muzzle_flash.cinematic")
local kMuzzleAttachPoint = "fxnode_riflemuzzle"

local function DestroyMuzzleEffect(self)

    if self.muzzleCinematic then
        Client.DestroyCinematic(self.muzzleCinematic)            
    end
    
    self.muzzleCinematic = nil
    self.activeCinematicName = nil

end

local function CreateMuzzleEffect(self)

    local player = self:GetParent()

    if player then

        local cinematicName = kMuzzleEffect
        self.activeCinematicName = cinematicName
        self.muzzleCinematic = CreateMuzzleCinematic(self, cinematicName, cinematicName, kMuzzleAttachPoint, nil, Cinematic.Repeat_Endless)
        self.firstPersonLoaded = player:GetIsLocalPlayer() and player:GetIsFirstPerson()
    
    end

end

function Rifle:OnCreate()

    ClipWeapon.OnCreate(self)
    
    InitMixin(self, PickupableWeaponMixin)
    InitMixin(self, EntityChangeMixin)
    
    if Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    end
    
end

function Rifle:OnDestroy()

    ClipWeapon.OnDestroy(self)
    
    DestroyMuzzleEffect(self)
    
end

function Rifle:OnPrimaryAttack(player)

    if not self:GetIsReloading() then
    
        ClipWeapon.OnPrimaryAttack(self, player)
        
    end    

end

function Rifle:GetNumStartClips()
    return 3
end

function Rifle:OnHolster(player)

    DestroyMuzzleEffect(self)    
    ClipWeapon.OnHolster(self, player)
    
end

function Rifle:OnHolsterClient()
    DestroyMuzzleEffect(self)
    ClipWeapon.OnHolsterClient(self)
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

function Rifle:GetWeight()
    return kRifleWeight + ((math.ceil(self.ammo / self:GetClipSize()) + math.ceil(self.clip / self:GetClipSize())) * kRifleClipWeight)
end

function Rifle:GetBarrelSmokeEffect()
    return Rifle.kBarrelSmokeEffect
end

function Rifle:OnSecondaryAttack(player)
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
        //Shared.StopSound(self, kSingleShotSound)
        //Shared.PlaySound(self, kSingleShotSound)        
		Shared.PlaySound(self, kLoopingSound)
        
        local player = self:GetParent()
        
        if not self.muzzleCinematic then            
            CreateMuzzleEffect(self)                
        elseif player then
        
            local cinematicName = kMuzzleEffect
            local useFirstPerson = player:GetIsLocalPlayer() and player:GetIsFirstPerson()
            
            if cinematicName ~= self.activeCinematicName or self.firstPersonLoaded ~= useFirstPerson then
            
                DestroyMuzzleEffect(self)
                CreateMuzzleEffect(self)
                
            end
            
        end
            
        // CreateMuzzleCinematic() can return nil in case there is no parent or the parent is invisible (for alien commander for example)
        if self.muzzleCinematic then
            self.muzzleCinematic:SetIsVisible(true)
        end
        
    end
    
    /*function Rifle:OnClientPrimaryAttacking()
        Shared.StopSound(self, kSingleShotSound)
        Shared.PlaySound(self, kSingleShotSound)
    end*/

	// needed for first person muzzle effect since it is attached to the view model entity: view model entity gets cleaned up when the player changes (for example becoming a commander and logging out again) 
    // this results in viewmodel getting destroyed / recreated -> cinematic object gets destroyed which would result in an invalid handle.
    function Rifle:OnParentChanged(oldParent, newParent)
        
        ClipWeapon.OnParentChanged(self, oldParent, newParent)
        DestroyMuzzleEffect(self)
        
    end
    
    function Rifle:OnClientPrimaryAttackEnd()
    
        // Just assume the looping sound is playing.
        //Shared.StopSound(self, kSingleShotSound)
		Shared.StopSound(self, kLoopingSound)
        Shared.PlaySound(self, kEndSound)
		if self.muzzleCinematic then
            self.muzzleCinematic:SetIsVisible(false)
        end
        
    end
    
    function Rifle:GetPrimaryEffectRate()
        return 0.09
    end
    
    function Rifle:GetBarrelPoint()
    
        local player = self:GetParent()
        if player then
        
            local origin = player:GetEyePos()
            local viewCoords= player:GetViewCoords()
            
            return origin + viewCoords.zAxis * 0.4 + viewCoords.xAxis * -0.15 + viewCoords.yAxis * -0.22
            
        end
        
        return self:GetOrigin()
        
    end
    
    function Rifle:GetUIDisplaySettings()
        return { xSize = 256, ySize = 417, script = "lua/GUIRifleDisplay.lua" }
    end
end

Shared.LinkClassToMap("Rifle", Rifle.kMapName, { })