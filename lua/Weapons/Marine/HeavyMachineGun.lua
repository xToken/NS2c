//
// lua\Weapons\HeavyMachineGun.lua

Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/PickupableWeaponMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

class 'HeavyMachineGun' (ClipWeapon)

HeavyMachineGun.kMapName = "heavymachinegun"

HeavyMachineGun.kModelName = PrecacheAsset("models/marine/heavymachinegun/heavymachinegun.model")
local kViewModelName = PrecacheAsset("models/marine/heavymachinegun/heavymachinegun_view.model")
local kAnimationGraph = PrecacheAsset("models/marine/heavymachinegun/heavymachinegun_view.animation_graph")

local kRange = 250
local kSpread = ClipWeapon.kCone10Degrees
local kLoopingSound = PrecacheAsset("sound/NS2.fev/marine/heavy/spin")
local kHeavyMachineGunEndSound = PrecacheAsset("sound/NS2.fev/marine/heavy/spin_down")
local kHeavyMachineGunROF = 0.05
local kHeavyMachineGunReloadTime = 6.3
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
    self.lastfiredtime = 0
    self.reloadtime = 0
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

    if not self:GetIsReloading() and self.clip > 0 and self.deployed then
        if player and not self:GetHasAttackDelay() then
        
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
    
end

function HeavyMachineGun:OnPrimaryAttackEnd(player)

    if self.primaryAttacking then
        ClipWeapon.OnPrimaryAttackEnd(self, player)
        self.primaryAttacking = false 
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
        modifier = ConditionalValue(player:GetHasCatpackBoost(), CatPack.kAttackSpeedModifier, 1)
    end
    return (kHeavyMachineGunROF / modifier)
end

function HeavyMachineGun:CanReload()
    return self.ammo > 0 and self.clip < self:GetClipSize() and not self.reloading and self.deployed
end

function HeavyMachineGun:OnReload(player)
    if self:CanReload() then
        self:TriggerEffects("reload")
        self.reloading = true
        self.reloadtime = Shared.GetTime()
    end
end

function HeavyMachineGun:OnUpdateAnimationInput(modelMixin)
    
    PROFILE("HeavyMachineGun:OnUpdateAnimationInput")
    ClipWeapon.OnUpdateAnimationInput(self, modelMixin)
    
    if self.reloading and self.reloadtime + kHeavyMachineGunReloadTime < Shared.GetTime() then
        self.reloading = false
        self.ammo = self.ammo + self.clip
        self.reloadtime = 0
        // Transfer bullets from our ammo pool to the weapon's clip
        self.clip = math.min(self.ammo, self:GetClipSize())
        self.ammo = self.ammo - self.clip
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

    if self:GetSecondaryAttacking() then
        return kDeathMessageIcon.Minigun
    end
    return kDeathMessageIcon.Minigun
    
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

function HeavyMachineGun:SetGunLoopParam(viewModel, paramName, rateOfChange)

    local current = viewModel:GetPoseParam(paramName)
    // 0.5 instead of 1 as full arm_loop is intense.
    local new = Clamp(current + rateOfChange, 0, 0.5)
    viewModel:SetPoseParam(paramName, new)
    
end

function HeavyMachineGun:UpdateViewModelPoseParameters(viewModel)

    local attacking = self:GetPrimaryAttacking()
    local sign = (attacking and 1) or 0

    self:SetGunLoopParam(viewModel, "arm_loop", sign)
    
end

function HeavyMachineGun:Dropped(prevOwner)

    ClipWeapon.Dropped(self, prevOwner)
    
end

function HeavyMachineGun:GetAmmoPackMapName()
    return HeavyMachineGunAmmo.kMapName
end

if Client then

    function HeavyMachineGun:OnClientPrimaryAttackStart()
    
        // Start the looping sound for the rest of the shooting. Pew pew pew...
        Shared.PlaySound(self, kLoopingSound)
        
    end
    
    function HeavyMachineGun:OnClientPrimaryAttackEnd()
    
        // Just assume the looping sound is playing.
        Shared.StopSound(self, kLoopingSound)
        Shared.PlaySound(self, kHeavyMachineGunEndSound)

    end

    function HeavyMachineGun:GetPrimaryEffectRate()
        return 0.05
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