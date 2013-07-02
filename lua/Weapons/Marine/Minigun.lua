// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Weapons\Marine\Minigun.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/Weapons/Marine/ExoWeaponSlotMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

class 'Minigun' (ClipWeapon)

Minigun.kMapName = "minigun"

local kSpinUpSoundNames = { [ExoWeaponHolder.kSlotNames.Left] = PrecacheAsset("sound/NS2.fev/marine/heavy/spin_up_2"),
                            [ExoWeaponHolder.kSlotNames.Right] = PrecacheAsset("sound/NS2.fev/marine/heavy/spin_up") }

local kSpinDownSoundNames = { [ExoWeaponHolder.kSlotNames.Left] = PrecacheAsset("sound/NS2.fev/marine/heavy/spin_down_2"),
                              [ExoWeaponHolder.kSlotNames.Right] = PrecacheAsset("sound/NS2.fev/marine/heavy/spin_down") }

local kSpinSoundNames = { [ExoWeaponHolder.kSlotNames.Left] = PrecacheAsset("sound/NS2.fev/marine/heavy/spin_2"),
                          [ExoWeaponHolder.kSlotNames.Right] = PrecacheAsset("sound/NS2.fev/marine/heavy/spin") }

local kSpinTailSoundNames = { [ExoWeaponHolder.kSlotNames.Left] = PrecacheAsset("sound/NS2.fev/marine/heavy/tail_2"),
                              [ExoWeaponHolder.kSlotNames.Right] = PrecacheAsset("sound/NS2.fev/marine/heavy/tail") }

Shared.PrecacheSurfaceShader("shaders/ExoMinigunView.surface_shader")

// Trigger on the client based on the "shooting" variable below.
local kShellsCinematics = { [ExoWeaponHolder.kSlotNames.Left] = PrecacheAsset("cinematics/marine/minigun/mm_left_shell.cinematic"),
                            [ExoWeaponHolder.kSlotNames.Right] = PrecacheAsset("cinematics/marine/minigun/mm_shell.cinematic") }
local kShellsAttachPoints = { [ExoWeaponHolder.kSlotNames.Left] = "Exosuit_LElbow",
                              [ExoWeaponHolder.kSlotNames.Right] = "Exosuit_RElbow" }

local kMinigunRange = 400
local kMinigunSpread = Math.Radians(4)

local kBulletSize = 0.03

local networkVars =
{
    minigunAttacking = "private boolean",
    shooting = "boolean",
    spinSoundId = "entityid"
}

AddMixinNetworkVars(ExoWeaponSlotMixin, networkVars)

function Minigun:OnCreate()

    ClipWeapon.OnCreate(self)
    
    InitMixin(self, ExoWeaponSlotMixin)
    
    self.minigunAttacking = false
    self.shooting = false
    
    if Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    end
    
end

function Minigun:OnInitialized()

    if Client then
    
        local attachPointName = kShellsAttachPoints[self:GetExoWeaponSlot()]
        local cinematicName = kShellsCinematics[self:GetExoWeaponSlot()]
        if attachPointName and cinematicName then
        
            self.shellsCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
            self.shellsCinematic:SetCinematic(cinematicName)
            self.shellsCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
            self.shellsCinematic:SetParent(self:GetParent())
            self.shellsCinematic:SetCoords(Coords.GetIdentity())
            self.shellsCinematic:SetAttachPoint(self:GetParent():GetAttachPointIndex(attachPointName))
            self.shellsCinematic:SetIsActive(false)
            
        end
        
    end
    
    ClipWeapon.OnInitialized(self)
    
end

function Minigun:OnDestroy()

    ClipWeapon.OnDestroy(self)
    
    if self.shellsCinematic then
    
        Client.DestroyCinematic(self.shellsCinematic)
        self.shellsCinematic = nil
        
    end
    
end

function Minigun:OnWeaponSlotAssigned(slot)

    assert(Server)
    
    self.spinSound = Server.CreateEntity(SoundEffect.kMapName)
    self.spinSound:SetAsset(kSpinSoundNames[slot])
    self.spinSound:SetParent(self)
    self.spinSoundId = self.spinSound:GetId()
    
end

function Minigun:GetNumStartClips()
    return 2
end

function Minigun:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function Minigun:GetMaxAmmo()
    return 2 * self:GetClipSize()
end

function Minigun:GetClipSize()
    return kMinigunClipSize
end

function Minigun:OnPrimaryAttack(player)
  
    if not self.minigunAttacking then
    
        if Server then
            StartSoundEffectOnEntity(kSpinUpSoundNames[self:GetExoWeaponSlot()], self)
        end
        
    end
    
    self.minigunAttacking = true
        
end

function Minigun:OnPrimaryAttackEnd(player)

    if self.minigunAttacking then
    
        if Server then
        
            if self.shooting then
                StartSoundEffectOnEntity(kSpinTailSoundNames[self:GetExoWeaponSlot()], self)
            end
            
            StartSoundEffectOnEntity(kSpinDownSoundNames[self:GetExoWeaponSlot()], self)
            
            if self.spinSound:GetIsPlaying() then
                self.spinSound:Stop()
            end    
            
        end
        
        self.shooting = false
        
    end
    
    self.minigunAttacking = false
    
end

function Minigun:GetBarrelPoint()

    local player = self:GetParent()
    if player then
    
        if player:GetIsLocalPlayer() then
        
            local origin = player:GetEyePos()
            local viewCoords = player:GetViewCoords()
            
            if self:GetIsLeftSlot() then
                return origin + viewCoords.zAxis * 0.9 + viewCoords.xAxis * 0.65 + viewCoords.yAxis * -0.19
            else
                return origin + viewCoords.zAxis * 0.9 + viewCoords.xAxis * -0.65 + viewCoords.yAxis * -0.19
            end    
        
        else
    
            local origin = player:GetEyePos()
            local viewCoords = player:GetViewCoords()
            
            if self:GetIsLeftSlot() then
                return origin + viewCoords.zAxis * 0.9 + viewCoords.xAxis * 0.35 + viewCoords.yAxis * -0.15
            else
                return origin + viewCoords.zAxis * 0.9 + viewCoords.xAxis * -0.35 + viewCoords.yAxis * -0.15
            end
            
        end    
        
    end
    
    return self:GetOrigin()
    
end

function Minigun:GetTracerEffectName()
    return kMinigunTracerEffectName
end

function Minigun:GetTracerEffectFrequency()
    return 1
end

function Minigun:GetDeathIconIndex()
    return kDeathMessageIcon.Minigun
end

function Minigun:GetWeight()
    return kMinigunWeight
end

// TODO: we should use clip weapons provided functionality here (or create a more general solution which distincts between melee, hitscan and projectile only)!
local function Shoot(self, leftSide)

    local player = self:GetParent()
    
    // We can get a shoot tag even when the clip is empty if the frame rate is low
    // and the animation loops before we have time to change the state.
    if self.minigunAttacking and player then
    
        if Server and not self.spinSound:GetIsPlaying() then
            self.spinSound:Start()
        end    
    
        local viewAngles = player:GetViewAngles()
        local shootCoords = viewAngles:GetCoords()
        
        // Filter ourself out of the trace so that we don't hit ourselves.
        local filter = EntityFilterTwo(player, self)
        local startPoint = player:GetEyePos()
        
        local spreadDirection = CalculateSpread(shootCoords, kMinigunSpread, NetworkRandom)
        
        local range = kMinigunRange
        if GetIsVortexed(player) then
            range = 5
        end
        
        local endPoint = startPoint + spreadDirection * range
        
        local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
        if not trace.entity then
            local extents = GetDirectedExtentsForDiameter(spreadDirection, kBulletSize)
            trace = Shared.TraceBox(extents, startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
        end
        
        if trace.fraction < 1 or GetIsVortexed(player) then
        
            local direction = (trace.endPoint - startPoint):GetUnit()
            local impactPoint = trace.endPoint - direction * kHitEffectOffset
            
            local impactPoint = trace.endPoint - GetNormalizedVector(endPoint - startPoint) * kHitEffectOffset
            local surfaceName = trace.surface
            
            local effectFrequency = self:GetTracerEffectFrequency()
            local showTracer = ConditionalValue(GetIsVortexed(player), false, math.random() < effectFrequency)
            
            self:ApplyBulletGameplayEffects(player, trace.entity, impactPoint, direction, kMinigunDamage, trace.surface, showTracer)
            
            if Client and showTracer then
                TriggerFirstPersonTracer(self, trace.endPoint)
            end
            
        end
        
        self.shooting = true
        
    end
    
end

function Minigun:OnUpdateRender()

    PROFILE("Minigun:OnUpdateRender")
    
    if self.shellsCinematic then
        self.shellsCinematic:SetIsActive(self.shooting)
    end
    
end

if Server then

    function Minigun:OnParentKilled(attacker, doer, point, direction)
    
        self.spinSound:Stop()
        self.shooting = false
        
    end
    
end

function Minigun:OnTag(tagName)

    PROFILE("Minigun:OnTag")
    local player = self:GetParent()
    if self:GetIsLeftSlot() and tagName == "l_shoot" then
        Shoot(self, true)
        if not player or not player:GetDarwinMode() then
            self.clip = self.clip - 1
        end
    elseif not self:GetIsLeftSlot() and tagName == "r_shoot" then
        Shoot(self, false)
        if not player or not player:GetDarwinMode() then
            self.clip = self.clip - 1
        end
    end
    
end

function Minigun:OnUpdateAnimationInput(modelMixin)

    local activity = "none"
    if self.minigunAttacking then
        activity = "primary"
    end
    modelMixin:SetAnimationInput("activity_" .. self:GetExoWeaponSlotName(), activity)
    
end

if Client then

    local kMinigunMuzzleEffectRate = 0.15
    local kAttachPoints = { [ExoWeaponHolder.kSlotNames.Left] = "fxnode_l_minigun_muzzle", [ExoWeaponHolder.kSlotNames.Right] = "fxnode_r_minigun_muzzle" }
    local kMuzzleEffectName = PrecacheAsset("cinematics/marine/minigun/muzzle_flash.cinematic")
    
    function Minigun:GetIsActive()
        return true
    end
    
    function Minigun:GetPrimaryEffectRate()
        return kMinigunMuzzleEffectRate
    end
    
    function Minigun:GetPrimaryAttacking()
        return self.shooting
    end
    
    function Minigun:GetSecondaryAttacking()
        return false
    end
    
    function Minigun:OnClientPrimaryAttacking()
    
        local parent = self:GetParent()
        
        if parent then
            CreateMuzzleCinematic(self, kMuzzleEffectName, kMuzzleEffectName, kAttachPoints[self:GetExoWeaponSlot()] , parent)
        end
    
    end
    
end

Shared.LinkClassToMap("Minigun", Minigun.kMapName, networkVars)