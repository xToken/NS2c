// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\GrenadeLauncher.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/Weapons/Marine/Grenade.lua")

class 'GrenadeLauncher' (ClipWeapon)

GrenadeLauncher.kMapName = "grenadelauncher"

local kGrenadeSpeed = 25

local networkVars =
{
    // Only used on the view model, so it can be private.
    emptyPoseParam = "private float (0 to 1 by 0.01)"
}

GrenadeLauncher.kModelName = PrecacheAsset("models/marine/grenadelauncher/grenadelauncher.model")
local kViewModels = GenerateMarineViewModelPaths("grenadelauncher")
local kAnimationGraph = PrecacheAsset("models/marine/grenadelauncher/grenadelauncher_view.animation_graph")

function GrenadeLauncher:OnCreate()

    ClipWeapon.OnCreate(self)
    
    self.emptyPoseParam = 0
    
end

function GrenadeLauncher:GetAnimationGraphName()
    return kAnimationGraph
end

function GrenadeLauncher:GetViewModelName(sex, variant)
    return kViewModels[sex][variant]
end

function GrenadeLauncher:GetDeathIconIndex()
    return kDeathMessageIcon.Shotgun
end

function GrenadeLauncher:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function GrenadeLauncher:GetClipSize()
    return kGrenadeLauncherClipSize
end

function GrenadeLauncher:GetMaxAmmo()
    return 7 * self:GetClipSize()
end

function GrenadeLauncher:GetHasSecondary(player)
    return false
end

function GrenadeLauncher:GetPrimaryCanInterruptReload()
    return true
end

function GrenadeLauncher:GetSecondaryAttackRequiresPress()
    return true
end    

function GrenadeLauncher:GetWeight()
    return kGrenadeLauncherWeight + ((self.clip + self.ammo) * kGrenadeLauncherShellWeight)
end

function GrenadeLauncher:UpdateViewModelPoseParameters(viewModel)

    viewModel:SetPoseParam("empty", self.emptyPoseParam)
    
end

local function LoadBullet(self)

    if self.ammo > 0 and self.clip < self:GetClipSize() then
    
        self.clip = self.clip + 1
        self.ammo = self.ammo - 1
        local player = self:GetParent()
        if player then
            player:UpdateWeaponWeights()
        end
    end
    
end

function GrenadeLauncher:GetAmmoPackMapName()
    return GrenadeLauncherAmmo.kMapName
end 

function GrenadeLauncher:OnTag(tagName)

    PROFILE("GrenadeLauncher:OnTag")
    
    local continueReloading = false
    if self:GetIsReloading() and tagName == "reload_end" then
    
        continueReloading = true
        self.reloading = false
        
    end
    
    if tagName == "end" then
        self.primaryAttacking = false
    end
    
    ClipWeapon.OnTag(self, tagName)
    
    if tagName == "load_shell" then
        LoadBullet(self)
    // We have a special case when loading the last shell in the clip.
    elseif tagName == "load_shell_sound" and self.clip < (self:GetClipSize() - 1) then
        self:TriggerEffects("grenadelauncher_reload_shell")
    elseif tagName == "load_shell_sound" then
        self:TriggerEffects("grenadelauncher_reload_shell_last")
    elseif tagName == "reload_start" then
        self:TriggerEffects("grenadelauncher_reload_start")
    elseif tagName == "shut_canister" then
        self:TriggerEffects("grenadelauncher_reload_end")
    end
    
    if continueReloading then
    
        local player = self:GetParent()
        if player then
            player:Reload()
        end
        
    end
    
end

function GrenadeLauncher:OnUpdateAnimationInput(modelMixin)

    ClipWeapon.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("loaded_shells", self:GetClip())
    modelMixin:SetAnimationInput("reserve_ammo_empty", self:GetAmmo() == 0)
    
end

local function ShootGrenade(self, player)

    PROFILE("ShootGrenade")
    
    self:TriggerEffects("grenadelauncher_attack")

    if Server or (Client and Client.GetIsControllingPlayer()) then

        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
        local eyePos = player:GetEyePos()

        local startPointTrace = Shared.TraceCapsule(eyePos, eyePos + viewCoords.zAxis, 0.2, 0, CollisionRep.Move, PhysicsMask.PredictedProjectileGroup, EntityFilterTwo(self, player))
        local startPoint = startPointTrace.endPoint
        
        local direction = viewCoords.zAxis
        
        if startPointTrace.fraction ~= 1 then
            direction = GetNormalizedVector(direction:GetProjection(startPointTrace.normal))
        end
        
        local grenade = player:CreatePredictedProjectile("Grenade", startPoint, direction * kGrenadeSpeed, 0.7, 0.45)
    
    end
    
    TEST_EVENT("Grenade Launcher primary attack")
    
end

function GrenadeLauncher:GetNumStartClips()
    return 2
end

function GrenadeLauncher:FirePrimary(player)
    ShootGrenade(self, player)    
end

function GrenadeLauncher:OnProcessMove(input)

    ClipWeapon.OnProcessMove(self, input)
    self.emptyPoseParam = Clamp(Slerp(self.emptyPoseParam, ConditionalValue(self.clip == 0, 1, 0), input.time * 1), 0, 1)
    
end

if Client then

    function GrenadeLauncher:GetUIDisplaySettings()
        return { xSize = 256, ySize = 256, script = "lua/GUIGrenadelauncherDisplay.lua" }
    end
    
end

Shared.LinkClassToMap("GrenadeLauncher", GrenadeLauncher.kMapName, networkVars)