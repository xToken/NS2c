// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Marine\Grenade.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")

class 'Grenade' (PredictedProjectile)

Grenade.kMapName = "grenade"
Grenade.kModelName = PrecacheAsset("models/marine/rifle/rifle_grenade.model")

Grenade.kRadius = 0.1
Grenade.kMinLifeTime = 0.0
Grenade.kClearOnImpact = false
Grenade.kClearOnEnemyImpact = true

local kGrenadeCameraShakeDistance = 15
local kGrenadeMinShakeIntensity = 0.02
local kGrenadeMaxShakeIntensity = 0.13

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function Grenade:OnCreate()

    PredictedProjectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
	  
    self:AddTimedCallback(Grenade.Detonate, kGrenadeLifetime)
    
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

function Grenade:ProcessHit(targetHit, surface)

    if targetHit and GetAreEnemies(self, targetHit) then
        self:Detonate(targetHit)
        return true
    end

    if Server then
    
        if self:GetVelocity():GetLength() > 2 then
            self:TriggerEffects("grenade_bounce")
        end
        
    end
    
    return false
    
end

function Grenade:Detonate(targetHit)

    // Do damage to nearby targets.
    
    if Server then
    
        local hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kGrenadeLauncherGrenadeDamageRadius)
    
        // Remove grenade and add firing player.
        table.removevalue(hitEntities, self)
        
        // full damage on direct impact
        if targetHit then
            table.removevalue(hitEntities, targetHit)
            self:DoDamage(kGrenadeLauncherGrenadeDamage, targetHit, targetHit:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - self:GetOrigin()), "none")
        end

        RadiusDamage(hitEntities, self:GetOrigin(), kGrenadeLauncherGrenadeDamageRadius, kGrenadeLauncherGrenadeDamage, self)
        
        // TODO: use what is defined in the material file
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