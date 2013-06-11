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

// higher numbers reduces the spread
local kSpreadDistance = 11.3
local kStartOffset = 0
local kSpreadVectors =
{
    GetNormalizedVector(Vector(-0.01, 0.01, kSpreadDistance)),
    
    GetNormalizedVector(Vector(-0.45, 0.45, kSpreadDistance)),
    GetNormalizedVector(Vector(0.45, 0.45, kSpreadDistance)),
    GetNormalizedVector(Vector(0.45, -0.45, kSpreadDistance)),
    GetNormalizedVector(Vector(-0.45, -0.45, kSpreadDistance)),
    
    GetNormalizedVector(Vector(-1, 0, kSpreadDistance)),
    GetNormalizedVector(Vector(1, 0, kSpreadDistance)),
    GetNormalizedVector(Vector(0, -1, kSpreadDistance)),
    GetNormalizedVector(Vector(0, 1, kSpreadDistance)),
    
    GetNormalizedVector(Vector(-0.35, 0, kSpreadDistance)),
    GetNormalizedVector(Vector(0.35, 0, kSpreadDistance)),
    GetNormalizedVector(Vector(0, -0.35, kSpreadDistance)),
    GetNormalizedVector(Vector(0, 0.35, kSpreadDistance)),
    
    GetNormalizedVector(Vector(-0.8, -0.8, kSpreadDistance)),
    GetNormalizedVector(Vector(-0.8, 0.8, kSpreadDistance)),
    GetNormalizedVector(Vector(0.8, 0.8, kSpreadDistance)),
    GetNormalizedVector(Vector(0.8, -0.8, kSpreadDistance)),
    
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

function Shotgun:GetSpread(bulletNum)

    // NS1 was 20 degrees for half the shots and 20 degrees plus 7 degrees for half the shots
    if bulletNum < (kShotgunBulletsPerShot / 2) then
        return Math.Radians(10)
    else
        return Math.Radians(20)
    end
    
end

function Shotgun:GetRange()
    return kShotgunMaxRange
end

// Only play weapon effects every other bullet to avoid sonic overload
function Shotgun:GetTracerEffectFrequency()
    return 0.5
end

function Shotgun:GetBulletDamage(target, endPoint)
    /*
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
    */
    return kShotgunDamage
end

function Shotgun:GetHasSecondary(player)
    return false
end

function Shotgun:GetPrimaryCanInterruptReload()
    return true
end

function Shotgun:GetWeight()
    return kShotgunWeight + ((self.clip + self.ammo) * kShotgunShellWeight)
end

function Shotgun:UpdateViewModelPoseParameters(viewModel)

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

    local viewAngles = player:GetViewAngles()
    viewAngles.roll = NetworkRandom() * math.pi * 2
    
    local viewCoords = viewAngles:GetCoords()
    
    
    // Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterTwo(player, self)
    local range = self:GetRange()
    
    if GetIsVortexed(player) then
        range = 5
    end
    
    local numberBullets = self:GetBulletsPerShot()
    local startPoint = player:GetEyePos()
    
    self:TriggerEffects("shotgun_attack")
    
    for bullet = 1, math.min(numberBullets, #kSpreadVectors) do
    
        if not kSpreadVectors[bullet] then
            break
        end    
    
        local spreadDirection = viewCoords:TransformVector(kSpreadVectors[bullet])

        local endPoint = startPoint + spreadDirection * range
        startPoint = player:GetEyePos() + viewCoords.xAxis * kSpreadVectors[bullet].x * kStartOffset + viewCoords.yAxis * kSpreadVectors[bullet].y * kStartOffset
        
        local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
        if not trace.entity then
            local extents = GetDirectedExtentsForDiameter(viewCoords.zAxis, self:GetBulletSize())
            trace = Shared.TraceBox(extents, startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
        end        
        
        local damage = 0

        /*
        // Check prediction
        local values = GetPredictionValues(startPoint, endPoint, trace)
        if not CheckPredictionData( string.format("attack%d", bullet), true, values ) then
            Server.PlayPrivateSound(player, "sound/NS2.fev/marine/voiceovers/game_start", player, 1.0, Vector(0, 0, 0))
        end
        */
            
        // don't damage 'air'..
        if trace.fraction < 1 or GetIsVortexed(player) then
        
            local direction = (trace.endPoint - startPoint):GetUnit()
            local impactPoint = trace.endPoint - direction * kHitEffectOffset
            local surfaceName = trace.surface

            local effectFrequency = self:GetTracerEffectFrequency()
            local showTracer = bullet % effectFrequency == 0
            
            self:ApplyBulletGameplayEffects(player, trace.entity, impactPoint, direction, kShotgunDamage, trace.surface, showTracer)
            
            if Client and showTracer then
                TriggerFirstPersonTracer(self, trace.endPoint)
            end
            
        end
        
        local client = Server and player:GetClient() or Client
        if not Shared.GetIsRunningPrediction() and client.hitRegEnabled then
            RegisterHitEvent(player, bullet, startPoint, trace, damage)
        end
        
    end
    
    TEST_EVENT("Shotgun primary attack")
    
end

function Shotgun:OnProcessMove(input)
    ClipWeapon.OnProcessMove(self, input)
    self.emptyPoseParam = Clamp(Slerp(self.emptyPoseParam, ConditionalValue(self.clip == 0, 1, 0), input.time * 1), 0, 1)
end

function Shotgun:GetAmmoPackMapName()
    return ShotgunAmmo.kMapName
end    


if Client then

    function Shotgun:GetBarrelPoint()
    
        local player = self:GetParent()
        if player then
        
            local origin = player:GetEyePos()
            local viewCoords= player:GetViewCoords()
            
            return origin + viewCoords.zAxis * 0.4 + viewCoords.xAxis * -0.18 + viewCoords.yAxis * -0.2
            
        end
        
        return self:GetOrigin()
        
    end
    
    function Shotgun:GetUIDisplaySettings()
        return { xSize = 256, ySize = 128, script = "lua/GUIShotgunDisplay.lua" }
    end

end

Shared.LinkClassToMap("Shotgun", Shotgun.kMapName, networkVars)