// Natural Selection 2 'Classic' Mod
// lua\Weapons\HeavyMachineGun.lua
// - Dragon

Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

class 'HeavyMachineGun' (ClipWeapon)

HeavyMachineGun.kMapName = "heavymachinegun"

HeavyMachineGun.kModelName = PrecacheAsset("models/marine/heavymachinegun/heavymachinegun.model")
local kViewModelName = PrecacheAsset("models/marine/heavymachinegun/heavymachinegun_view.model")
local kAnimationGraph = PrecacheAsset("models/marine/heavymachinegun/heavymachinegun_view.animation_graph")

local kSpread = ClipWeapon.kCone4Degrees
local kSingleShotSound = PrecacheAsset("sound/ns2c.fev/ns2c/marine/weapon/hmg_fire")
local kHeavyMachineGunEndSound = PrecacheAsset("sound/NS2.fev/marine/heavy/spin_down")
local kMuzzleEffect = PrecacheAsset("cinematics/marine/heavymachinegun/muzzle_flash.cinematic")
local kMuzzleAttachPoint = "fxnode_riflemuzzle"

function HeavyMachineGun:OnCreate()

    ClipWeapon.OnCreate(self)
    
    InitMixin(self, EntityChangeMixin)
    
    if Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    end

end

function HeavyMachineGun:OnInitialized()

    ClipWeapon.OnInitialized(self)
    self.lastfiredtime = 0
    self.reloadtime = 0
    if Client then
    
        self:SetUpdates(true)
        self:SetFirstPersonAttackingEffect(kMuzzleEffect)
        self:SetThirdPersonAttackingEffect(kMuzzleEffect)
        self:SetMuzzleAttachPoint(kMuzzleAttachPoint)
        
    end
    
end

local function CancelReload(self)
    self.reloading = false
    self:TriggerEffects("reload_cancel")
end

function HeavyMachineGun:OnPrimaryAttack(player)

    if self:GetIsPrimaryAttackAllowed(player) then
        if not self:GetIsReloading() and self.clip > 0 and self.deployed then
            if player and not self:GetHasAttackDelay() then
                if self:GetIsReloading() then
                    CancelReload(self)
                end
                self:FirePrimary(player)
                // Don't decrement ammo in Darwin mode
                if not player or not player:GetDarwinMode() then
                    self.clip = self.clip - 1
                end
                self.lastfiredtime = Shared.GetTime()
                self:CreatePrimaryAttackEffect(player)
                Weapon.OnPrimaryAttack(self, player)
                self.primaryAttacking = true
            end
        elseif self.ammo > 0 and self.deployed then
            self:OnPrimaryAttackEnd(player)
            // Automatically reload if we're out of ammo.
            player:Reload()
        else
            self:OnPrimaryAttackEnd(player)
            self.blockingPrimary = false
        end
    else
        self:OnPrimaryAttackEnd(player)
        self.blockingPrimary = false
    end
    
end

function HeavyMachineGun:GetNumStartClips()
    return 2
end

function HeavyMachineGun:GetMaxAmmo()
    return 2 * self:GetClipSize()
end

function HeavyMachineGun:GetAnimationGraphName()
    return kAnimationGraph
end

function HeavyMachineGun:GetViewModelName()
    return kViewModelName
end

function HeavyMachineGun:GetFireDelay()
    local player = self:GetParent()
    local modifier = 1
    if player then
        modifier = ConditionalValue(player:GetHasCatpackBoost(), kCatPackFireRateScalar, 1)
    end
    return (kHeavyMachineGunROF / modifier)
end

function HeavyMachineGun:CanReload()
    return self.ammo > 0 and self.clip < self:GetClipSize() and not self.reloading and self.deployed
end

function HeavyMachineGun:OnReload(player)
    if self:CanReload() then
        self.reloadtime = Shared.GetTime()
    end
    ClipWeapon.OnReload(self, player)
end

function HeavyMachineGun:OnUpdateAnimationInput(modelMixin)
    
    PROFILE("HeavyMachineGun:OnUpdateAnimationInput")
    ClipWeapon.OnUpdateAnimationInput(self, modelMixin)
    
    if Server and self.reloading and self.reloadtime + kHeavyMachineGunReloadTime < Shared.GetTime() then
        self.reloading = false
        self.ammo = self.ammo + self.clip
        self.reloadtime = 0
        // Transfer bullets from our ammo pool to the weapon's clip
        self.clip = math.min(self.ammo, self:GetClipSize())
        self.ammo = self.ammo - self.clip
        local player = self:GetParent()
        if player then
            player:UpdateWeaponWeights()
        end
    end
    
end

function HeavyMachineGun:GetHasAttackDelay()
    return self.lastfiredtime + self:GetFireDelay() > Shared.GetTime()
end

function HeavyMachineGun:OnTag(tagName)
    PROFILE("HeavyMachineGun:OnTag")
    if tagName == "deploy_end" then
        self.deployed = true
    end
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

function HeavyMachineGun:GetWeight()
    return kHeavyMachineGunWeight + ((math.ceil(self.ammo / self:GetClipSize()) + math.ceil(self.clip / self:GetClipSize())) * kHeavyMachineGunClipWeight)
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

function HeavyMachineGun:SetGunLoopParam(viewModel, paramName, rateOfChange)

    local current = viewModel:GetPoseParam(paramName)
    // 0.5 instead of 1 as full arm_loop is intense.
    local new = Clamp(current + rateOfChange, 0, 0.5)
    viewModel:SetPoseParam(paramName, new)
    
end

function HeavyMachineGun:OnSecondaryAttack(player)
end

function HeavyMachineGun:UpdateViewModelPoseParameters(viewModel)

    local attacking = self:GetPrimaryAttacking()
    local sign = (attacking and 1) or 0

    self:SetGunLoopParam(viewModel, "arm_loop", sign)
    
end

function HeavyMachineGun:GetAmmoPackMapName()
    return HeavyMachineGunAmmo.kMapName
end

if Client then

    function HeavyMachineGun:OnClientPrimaryAttackStart()
        // Start the looping sound for the rest of the shooting. Pew pew pew...
        Shared.PlaySound(self, kSingleShotSound)
    end
    
    function HeavyMachineGun:GetTriggerPrimaryEffects()
        return not self:GetIsReloading()
    end
    
    function HeavyMachineGun:OnClientPrimaryAttacking()
        Shared.PlaySound(self, kSingleShotSound)
    end
    
    function HeavyMachineGun:OnClientPrimaryAttackEnd()
        Shared.PlaySound(self, kHeavyMachineGunEndSound)
    end

    function HeavyMachineGun:GetPrimaryEffectRate()
        return 0.07
    end
    
    function HeavyMachineGun:GetPreventCameraAnimation()
        return true
    end

    function HeavyMachineGun:GetBarrelPoint()

        local player = self:GetParent()
        if player then
        
            local origin = player:GetEyePos()
            local viewCoords= player:GetViewCoords()
        
            return origin + viewCoords.zAxis * 0.4 + viewCoords.xAxis * -0.3 + viewCoords.yAxis * -0.25
        end
        
        return self:GetOrigin()
        
    end  

end

Shared.LinkClassToMap("HeavyMachineGun", HeavyMachineGun.kMapName, { })