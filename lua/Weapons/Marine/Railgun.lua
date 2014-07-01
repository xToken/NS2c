// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Weapons\Marine\Railgun.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Marine/ClipWeapon.lua")
Script.Load("lua/Weapons/Marine/ExoWeaponSlotMixin.lua")
Script.Load("lua/TechMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

class 'Railgun' (ClipWeapon)

Railgun.kMapName = "railgun"

local kRailgunRange = 100
local kRailgunSpread = Math.Radians(0)
local kBulletSize = 0.03

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/alien_frag.surface_shader")
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/decals/railgun_hole.surface_shader")

local networkVars =
{
    timeOfLastShot = "private time"
}

AddMixinNetworkVars(ExoWeaponSlotMixin, networkVars)

function Railgun:OnCreate()

    ClipWeapon.OnCreate(self)
    
    InitMixin(self, ExoWeaponSlotMixin)
    
    self.timeOfLastShot = 0

end

function Railgun:OnDestroy()

    ClipWeapon.OnDestroy(self)
    
end

function Railgun:OnPrimaryAttack(player)
    self.primaryAttacking = true
end

function Railgun:GetNumStartClips()
    return 1
end

function Railgun:GetMaxAmmo()
    return 2 * self:GetClipSize()
end

function Railgun:GetClipSize()
    return kRailgunClipSize
end

function Railgun:GetWeight()
    return kRailgunWeight
end

function Railgun:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function Railgun:OnPrimaryAttackEnd(player)
    self.primaryAttacking = false
end

function Railgun:GetBarrelPoint()

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

function Railgun:GetTracerEffectName()
    return kRailgunTracerEffectName
end

function Railgun:GetTracerResidueEffectName()
    return kRailgunTracerResidueEffectName
end

function Railgun:GetTracerEffectFrequency()
    return 1
end

function Railgun:GetDeathIconIndex()
    return kDeathMessageIcon.Railgun
end

local function TriggerSteamEffect(self, player)

    if self:GetIsLeftSlot() then
        player:TriggerEffects("railgun_steam_left")
    elseif self:GetIsRightSlot() then
        player:TriggerEffects("railgun_steam_right")
    end
    
end

local function ExecuteShot(self, startPoint, endPoint, player)

    // Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterTwo(player, self)
    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterAllButIsa("Tunnel"))
    local hitPointOffset = trace.normal * 0.3
    local direction = (endPoint - startPoint):GetUnit()
    local damage = kRailgunDamage
    
    local extents = GetDirectedExtentsForDiameter(direction, kBulletSize)
    
    if trace.fraction < 1 then
    
        local endPoint = trace.endPoint
        local target = trace.entity
        
        local hitEntities = GetEntitiesWithMixinWithinRange("Live", endPoint, kRailgunSplashRadius)

        // Do damage to every target in range
        RadiusDamage(hitEntities, endPoint, kRailgunSplashRadius, kRailgunDamage, self, true)
        
        // for tracer
        local effectFrequency = self:GetTracerEffectFrequency()
        local showTracer = math.random() < effectFrequency
        self:DoDamage(0, nil, trace.endPoint + hitPointOffset, direction, trace.surface, false, showTracer)
        
        if Client and showTracer then
            TriggerFirstPersonTracer(self, trace.endPoint)
        end
    
    end
    
end

local function Shoot(self, leftSide)

    local player = self:GetParent()
    
    // We can get a shoot tag even when the clip is empty if the frame rate is low
    // and the animation loops before we have time to change the state.
    if player then
    
        player:TriggerEffects("railgun_attack")
        
        local viewAngles = player:GetViewAngles()
        local shootCoords = viewAngles:GetCoords()
        
        local startPoint = player:GetEyePos()
        
        local spreadDirection = CalculateSpread(shootCoords, kRailgunSpread, NetworkRandom)
        
        local endPoint = startPoint + spreadDirection * kRailgunRange
        ExecuteShot(self, startPoint, endPoint, player)
        
        if Client then
            TriggerSteamEffect(self, player)
        end
        
        self.timeOfLastShot = Shared.GetTime()
        
    end
    
end

if Server then

    function Railgun:OnParentKilled(attacker, doer, point, direction)
    end
    
    /**
     * The Railgun explodes players. We must bypass the ragdoll here.
     */
    function Railgun:OnDamageDone(doer, target)
    
        if doer == self then
        
            if target:isa("Player") and not target:GetIsAlive() then
                target:SetBypassRagdoll(true)
            end
            
        end
        
    end
    
end

function Railgun:OnUpdateRender()

    PROFILE("Railgun:OnUpdateRender")
    
    local parent = self:GetParent()
    if parent and parent:GetIsLocalPlayer() then
    
        local viewModel = parent:GetViewModelEntity()
        if viewModel and viewModel:GetRenderModel() then
        
            viewModel:InstanceMaterials()
            local renderModel = viewModel:GetRenderModel()
            renderModel:SetMaterialParameter("timeSinceLastShot" .. self:GetExoWeaponSlotName(), Shared.GetTime() - self.timeOfLastShot)
            
        end
        
    end
    
end

function Railgun:OnTag(tagName)

    PROFILE("Railgun:OnTag")
    
    if self:GetIsLeftSlot() then
    
        if tagName == "l_shoot" then
            Shoot(self, true)
            if not player or not player:GetDarwinMode() then
                self.clip = self.clip - 1
            end
        end
        
    elseif not self:GetIsLeftSlot() then
    
        if tagName == "r_shoot" then
            Shoot(self, false)
            if not player or not player:GetDarwinMode() then
                self.clip = self.clip - 1
            end
        end
        
    end
    
end

function Railgun:OnUpdateAnimationInput(modelMixin)

    local activity = "none"
    if self.primaryAttacking then
        activity = "primary"
    end
    modelMixin:SetAnimationInput("activity_" .. self:GetExoWeaponSlotName(), activity)
    
end

if Client then

    local kRailgunMuzzleEffectRate = 0.5
    local kAttachPoints = { [ExoWeaponHolder.kSlotNames.Left] = "fxnode_l_railgun_muzzle", [ExoWeaponHolder.kSlotNames.Right] = "fxnode_r_railgun_muzzle" }
    local kMuzzleEffectName = PrecacheAsset("cinematics/marine/railgun/muzzle_flash.cinematic")
    
    function Railgun:GetIsActive()
        return true
    end
    
    function Railgun:GetPrimaryEffectRate()
        return kRailgunMuzzleEffectRate
    end
    
    function Railgun:GetPrimaryAttacking()
        return (Shared.GetTime() - self.timeOfLastShot) <= kRailgunMuzzleEffectRate
    end
    
    function Railgun:GetSecondaryAttacking()
        return false
    end
    
    function Railgun:OnClientPrimaryAttacking()
    
        local parent = self:GetParent()
        
        if parent then
            CreateMuzzleCinematic(self, kMuzzleEffectName, kMuzzleEffectName, kAttachPoints[self:GetExoWeaponSlot()] , parent)
        end
        
    end

end

Shared.LinkClassToMap("Railgun", Railgun.kMapName, networkVars)