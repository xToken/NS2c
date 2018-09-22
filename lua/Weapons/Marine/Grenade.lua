-- ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Marine\Grenade.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")

class 'Grenade' (PredictedProjectile)

Grenade.kMapName = "grenade"
Grenade.kModelName = PrecacheAsset("models/marine/rifle/rifle_grenade.model")

Grenade.kRadius = 0.1
Grenade.kMinLifeTime = 0.0
Grenade.kClearOnSurfaceImpact = false
Grenade.kClearOnEntityImpact = false
Grenade.kClearOnEnemyImpact = true
Grenade.kClearOnSelfImpact = false

local kGrenadeCameraShakeDistance = 15
local kGrenadeMinShakeIntensity = 0.02
local kGrenadeMaxShakeIntensity = 0.13

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)

function Grenade:OnCreate()

    PredictedProjectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, DamageMixin)

    if Server then    
        self:AddTimedCallback(Grenade.TimedDetonateCallback, kGrenadeLifetime)        
    end
    
end

function Grenade:GetProjectileModel()
    return Grenade.kModelName
end

function Grenade:GetDeathIconIndex()
    return kDeathMessageIcon.Grenade
end

function Grenade:GetDamageType()
    return kGrenadeLauncherGrenadeDamageType
end

function Grenade:GetIsAffectedByWeaponUpgrades()
    return true
end

function Grenade:TimedDetonateCallback()
    self:Detonate()
end

function Grenade:ProcessHit(targetHit, surface, normal, endPoint )

    if targetHit and GetAreEnemies(self, targetHit) then
        self:Detonate(targetHit)
    end

    if Server then
    
        if self:GetVelocity():GetLength() > 2 then
            self:TriggerEffects("grenade_bounce")
        end
        
    end

end

function Grenade:Detonate(targetHit)

    -- Do damage to nearby targets.
    
    if Server then
    
        -- Do damage to nearby targets.
        local hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kGrenadeLauncherGrenadeDamageRadius)
        
        -- Remove grenade and add firing player.
        table.removevalue(hitEntities, self)
        
        -- full damage on direct impact
        if targetHit then
            table.removevalue(hitEntities, targetHit)
            self:DoDamage(kGrenadeLauncherGrenadeDamage, targetHit, targetHit:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - self:GetOrigin()), "none")
        end

        RadiusDamage(hitEntities, self:GetOrigin(), kGrenadeLauncherGrenadeDamageRadius, kGrenadeLauncherGrenadeDamage, self)
        
        -- TODO: use what is defined in the material file
        local surface = GetSurfaceFromEntity(targetHit)
                
        local params = { surface = surface }
        params[kEffectHostCoords] = Coords.GetLookIn( self:GetOrigin(), self:GetCoords().zAxis)
        
        self:TriggerEffects("grenade_explode", params)
        
        DestroyEntity(self)
                
    elseif Client then
    
        CreateExplosionDecals(self)
    
        TriggerCameraShake(self, kGrenadeMinShakeIntensity, kGrenadeMaxShakeIntensity, kGrenadeCameraShakeDistance)
    
    end
    
end

Shared.LinkClassToMap("Grenade", Grenade.kMapName, networkVars)