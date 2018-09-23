-- Natural Selection 2 'Classic' Mod
-- lua\Weapons\HeavyMachineGun.lua
-- - Dragon

Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

class 'HeavyMachineGun' (ClipWeapon)

HeavyMachineGun.kMapName = "heavymachinegun"
HeavyMachineGun.kModelName = PrecacheAsset("models/marine/lmg/lmg.model")
local kViewModels = GenerateMarineViewModelPaths("lmg")
local kAnimationGraph = PrecacheAsset("models/marine/lmg/lmg_view.animation_graph")
local rifleReloadTime = Shared.GetAnimationLength("models/marine/male/male.model", "rifle_reload")
local hmgReloadTime = Shared.GetAnimationLength("models/marine/lmg/lmg_view.model", "reload")

local kRifleToHMGReloadSpeed = 0.5
local kSpread = ClipWeapon.kCone4Degrees
local kHeavyMachineGunClipNum = 2

-- Sounds
local kNumberOfVariants = 3
local kLoopingSounds = {}
local kEndSounds = {}
local kSingleShotSounds = {}
for i=0,3 do
    for j=0,2 do
        table.insert(kLoopingSounds, "sound/NS2.fev/marine/hmg/hmg_fire_loop_w"..i.."_"..j)
    end
    table.insert(kEndSounds, "sound/NS2.fev/marine/hmg/hmg_fire_loop_end_w"..i)
    table.insert(kSingleShotSounds, "sound/NS2.fev/marine/hmg/hmg_fire_loop_end_w"..i)
end
for k, v in ipairs(kLoopingSounds) do PrecacheAsset(v) end
for k, v in ipairs(kEndSounds) do PrecacheAsset(v) end
for k, v in ipairs(kSingleShotSounds) do PrecacheAsset(v) end

local kLoopingShellCinematic = PrecacheAsset("cinematics/marine/rifle/shell_looping.cinematic")
local kLoopingShellCinematicFirstPerson = PrecacheAsset("cinematics/marine/rifle/shell_looping_1p.cinematic")
local kShellEjectAttachPoint = "fxnode_riflecasing"
local kMuzzleCinematic =  PrecacheAsset("cinematics/marine/rifle/muzzle_flash.cinematic")

local networkVars =
{
    soundType = "integer (1 to 12)",
    shooting = "boolean",
}

local kMuzzleEffect = PrecacheAsset("cinematics/marine/rifle/muzzle_flash.cinematic")
local kMuzzleAttachPoint = "fxnode_riflemuzzle"

local function DestroyMuzzleEffect(self)

    if self.muzzleCinematic then
        Client.DestroyCinematic(self.muzzleCinematic)            
    end
    
    self.muzzleCinematic = nil
    self.activeCinematicName = nil

end

local function DestroyShellEffect(self)

    if self.shellsCinematic then
        Client.DestroyCinematic(self.shellsCinematic)            
    end
    
    self.shellsCinematic = nil

end

local function CreateMuzzleEffect(self)

    local player = self:GetParent()

    if player then

        local cinematicName = kMuzzleCinematic
        self.activeCinematicName = cinematicName
        self.muzzleCinematic = CreateMuzzleCinematic(self, cinematicName, cinematicName, kMuzzleAttachPoint, nil, Cinematic.Repeat_Endless)
        self.firstPersonLoaded = player:GetIsLocalPlayer() and player:GetIsFirstPerson()
    
    end

end

local function CreateShellCinematic(self)

    local parent = self:GetParent()

    if parent and Client.GetLocalPlayer() == parent then
        self.loadedFirstPersonShellEffect = true
    else
        self.loadedFirstPersonShellEffect = false
    end

    if self.loadedFirstPersonShellEffect then
        self.shellsCinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)        
        self.shellsCinematic:SetCinematic(kLoopingShellCinematicFirstPerson)
    else
        self.shellsCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        self.shellsCinematic:SetCinematic(kLoopingShellCinematic)
    end    
    
    self.shellsCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
    
    if self.loadedFirstPersonShellEffect then    
        self.shellsCinematic:SetParent(parent:GetViewModelEntity())
    else
        self.shellsCinematic:SetParent(self)
    end
    
    self.shellsCinematic:SetCoords(Coords.GetIdentity())
    
    if self.loadedFirstPersonShellEffect then  
        self.shellsCinematic:SetAttachPoint(parent:GetViewModelEntity():GetAttachPointIndex(kShellEjectAttachPoint))
    else    
        self.shellsCinematic:SetAttachPoint(self:GetAttachPointIndex(kShellEjectAttachPoint))
    end    

    self.shellsCinematic:SetIsActive(false)

end

-- Don't inherit this from Rifle. We are going to initialise mixins our own way
function HeavyMachineGun:OnCreate()

    ClipWeapon.OnCreate(self)
    
    InitMixin(self, EntityChangeMixin)
    
    if Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    elseif Server then
        self.soundVariant = Shared.GetRandomInt(1, kNumberOfVariants)
        self.soundType = self.soundVariant
    end
    
end

function HeavyMachineGun:OnDestroy()

    ClipWeapon.OnDestroy(self)
    
    DestroyMuzzleEffect(self)
    DestroyShellEffect(self)
    
end

function HeavyMachineGun:GetPickupOrigin()
    return self:GetCoords():TransformPoint(Vector(0.13956764340400696, 0.08423030376434326, -0.1180378794670105))
end

local function UpdateSoundType(self, player)

    local upgradeLevel = 0
    
    if player.GetWeaponUpgradeLevel then
        upgradeLevel = player:GetWeaponUpgradeLevel()
    end

    self.soundType = self.soundVariant + upgradeLevel * kNumberOfVariants

end

function HeavyMachineGun:OnPrimaryAttack(player)

    if not self:GetIsReloading() then
        
        if Server then
            UpdateSoundType(self, player)
        end
        
        ClipWeapon.OnPrimaryAttack(self, player)
        
    end    

end

function HeavyMachineGun:GetMaxClips()
    return kHeavyMachineGunClipNum
end

function HeavyMachineGun:OnHolster(player)

    DestroyMuzzleEffect(self)
    DestroyShellEffect(self)
    ClipWeapon.OnHolster(self, player)
    
end

function HeavyMachineGun:OnHolsterClient()

    DestroyMuzzleEffect(self)
    DestroyShellEffect(self)
    ClipWeapon.OnHolsterClient(self)
    
end

function HeavyMachineGun:GetAnimationGraphName()
    return kAnimationGraph
end

function HeavyMachineGun:GetViewModelName(sex, variant)
    return kViewModels[sex][variant]
end

function HeavyMachineGun:GetDeathIconIndex()

    return kDeathMessageIcon.HeavyMachineGun
    
end

function HeavyMachineGun:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function HeavyMachineGun:GetClipSize()
    return kHeavyMachineGunClipSize
end

function HeavyMachineGun:GetSpread()
    return kSpread
end

function HeavyMachineGun:GetBulletDamage(target, endPoint)
    return kHeavyMachineGunDamage
end

function HeavyMachineGun:GetRange()
    return kHeavyMachineGunRange
end

function HeavyMachineGun:GetWeight()
    return kHeavyMachineGunWeight + ((math.ceil(self.ammo / self:GetClipSize()) + math.ceil(self.clip / self:GetClipSize())) * kHeavyMachineGunClipWeight)
end

function HeavyMachineGun:GetDamageType()
    return kHeavyMachineGunDamageType
end

function HeavyMachineGun:GetHasSecondary()
    return false
end

function HeavyMachineGun:GetSecondaryCanInterruptReload()
    return true
end

function HeavyMachineGun:OnTag(tagName)

    PROFILE("HeavyMachineGun:OnTag")

    ClipWeapon.OnTag(self, tagName)
    
    if tagName == "hit" then
    
        self.shooting = false
    
        local player = self:GetParent()
        if player then
            self:PerformMeleeAttack(player)
        end
        
    end

end

function HeavyMachineGun:SetGunLoopParam(viewModel, paramName, rateOfChange)

    local current = viewModel:GetPoseParam(paramName)
    -- 0.5 instead of 1 as full arm_loop is intense.
    local new = Clamp(current + rateOfChange, 0, 0.5)
    viewModel:SetPoseParam(paramName, new)
    
end

function HeavyMachineGun:OnSecondaryAttack(player)
end

function HeavyMachineGun:UpdateViewModelPoseParameters(viewModel)

    viewModel:SetPoseParam("hide_gl", 1)
    viewModel:SetPoseParam("gl_empty", 1)
    
    local attacking = self:GetPrimaryAttacking()
    local sign = (attacking and 1) or 0
    
    self:SetGunLoopParam(viewModel, "arm_loop", sign)
    
end

function HeavyMachineGun:OnUpdateAnimationInput(modelMixin)

    PROFILE("HeavyMachineGun:OnUpdateAnimationInput")
    
    ClipWeapon.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("reload_speed", kRifleToHMGReloadSpeed)

end

function HeavyMachineGun:GetAmmoPackMapName()
    return HeavyMachineGunAmmo.kMapName
end

function HeavyMachineGun:OverrideWeaponName()
    return "rifle"
end

if Client then

    function HeavyMachineGun:OnClientPrimaryAttackStart()
    
        local player = self:GetParent()
        
        StartSoundEffectAtOrigin(kSingleShotSounds[math.floor((self.soundType-1)/3) + 1], self:GetOrigin())
        
        Shared.PlaySound(self, kLoopingSounds[self.soundType])
        self.clientSoundTypePlaying = self.soundType
        
        if not self.muzzleCinematic then            
            CreateMuzzleEffect(self)                
        elseif player then
        
            local cinematicName = kMuzzleCinematic
            local useFirstPerson = player:GetIsLocalPlayer() and player:GetIsFirstPerson()
            
            if cinematicName ~= self.activeCinematicName or self.firstPersonLoaded ~= useFirstPerson then
            
                DestroyMuzzleEffect(self)
                CreateMuzzleEffect(self)
                
            end
            
        end
            
        -- CreateMuzzleCinematic() can return nil in case there is no parent or the parent is invisible (for alien commander for example)
        if self.muzzleCinematic then
            self.muzzleCinematic:SetIsVisible(true)
        end
        
        if player then
        
            local useFirstPerson = player == Client.GetLocalPlayer()
            
            if useFirstPerson ~= self.loadedFirstPersonShellEffect then
                DestroyShellEffect(self)
            end
        
            if not self.shellsCinematic then
                CreateShellCinematic(self)
            end
        
            self.shellsCinematic:SetIsActive(true)

        end
        
    end
    
    -- needed for first person muzzle effect since it is attached to the view model entity: view model entity gets cleaned up when the player changes (for example becoming a commander and logging out again) 
    -- this results in viewmodel getting destroyed / recreated -> cinematic object gets destroyed which would result in an invalid handle.
    function HeavyMachineGun:OnParentChanged(oldParent, newParent)
        
        ClipWeapon.OnParentChanged(self, oldParent, newParent)
        DestroyMuzzleEffect(self)
        DestroyShellEffect(self)
        
    end
    
    function HeavyMachineGun:OnClientPrimaryAttackEnd()
    
        -- Just assume the looping sound is playing.
        Shared.StopSound(self, kLoopingSounds[self.clientSoundTypePlaying])
        --[[
        local player = self:GetParent()
        if player and player:GetIsLocalPlayer() then
            Shared.StopSound(self, kAttackSoundName)
        end
        --]]
        Shared.PlaySound(self, kEndSounds[math.floor((self.soundType-1)/3)+1])
        
        if self.muzzleCinematic and self.muzzleCinematic ~= Entity.invalidId then
            self.muzzleCinematic:SetIsVisible(false)
        end
        
        if self.shellsCinematic and self.shellsCinematic ~= Entity.invalidId then
            self.shellsCinematic:SetIsActive(false)
        end
        
    end
    
    function HeavyMachineGun:OnClientPrimaryAttacking(deltaTime)
    
        -- Update weapon sounds if the weapon upgrade level has changed
        if self.clientSoundTypePlaying and self.clientSoundTypePlaying ~= self.soundType then
            
            Shared.StopSound(self, kLoopingSounds[self.clientSoundTypePlaying])
            Shared.PlaySound(self, kLoopingSounds[self.soundType])
            self.clientSoundTypePlaying = self.soundType
            
        end
    
    end
    
    function HeavyMachineGun:GetPrimaryEffectRate()
        return 0.08
    end
    
    function HeavyMachineGun:GetTriggerPrimaryEffects()
        return not self:GetIsReloading() and self.shooting
    end
    
    function HeavyMachineGun:GetBarrelPoint()
    
        local player = self:GetParent()
        if player then
        
            local origin = player:GetEyePos()
            local viewCoords= player:GetViewCoords()
            
            return origin + viewCoords.zAxis * 0.65 + viewCoords.xAxis * -0.15 + viewCoords.yAxis * -0.2
            
        end
        
        return self:GetOrigin()
        
    end
	
    function HeavyMachineGun:GetUIDisplaySettings()
        return { xSize = 256, ySize = 417, script = "lua/GUIHeavyMachineGunDisplay.lua", textureNameOverride = "lmg" }
    end
    
end

Shared.LinkClassToMap("HeavyMachineGun", HeavyMachineGun.kMapName, networkVars)
