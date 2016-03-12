// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\Weapons\Marine\HandGrenade.lua
// - Dragon

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")

class 'HandGrenade' (PredictedProjectile)

HandGrenade.kMapName = "handgrenade"
HandGrenade.kModelName = PrecacheAsset("models/marine/grenades/gr_cluster_world.model")

// prevents collision with friendly players in range to spawnpoint
HandGrenade.kDisableCollisionRange = 10
HandGrenade.kClearOnSurfaceImpact = false
HandGrenade.kClearOnEntityImpact = false
HandGrenade.kClearOnEnemyImpact = true
HandGrenade.kClearOnSelfImpact = false
HandGrenade.kRadius = 0.1

local kGrenadeCameraShakeDistance = 15
local kGrenadeMinShakeIntensity = 0.01
local kGrenadeMaxShakeIntensity = 0.12
local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function HandGrenade:OnCreate()

    PredictedProjectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    if Server then
        self:AddTimedCallback(HandGrenade.TimedDetonateCallback, kHandGrenadesLifetime)
    end
    
end

function HandGrenade:GetProjectileModel()
    return HandGrenade.kModelName
end 

function HandGrenade:GetDeathIconIndex()
    return kDeathMessageIcon.ClusterGrenade
end

function HandGrenade:GetDamageType()
    return kHandGrenadesDamageType
end

function HandGrenade:ProcessHit(targetHit, surface)

    if targetHit and GetAreEnemies(self, targetHit) then
        self:Detonate(targetHit)
    end

    if Server then
    
        if self:GetVelocity():GetLength() > 2 then
            self:TriggerEffects("grenade_bounce")
        end
        
    end
    
end

function HandGrenade:TimedDetonateCallback()
    self:Detonate()
end

function HandGrenade:Detonate(targetHit)       

    if Server then
        
        // Do damage to nearby targets.
        local hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kHandGrenadesRange)
        
        // Remove grenade and add firing player.
        table.removevalue(hitEntities, self)
        
        // full damage on direct impact
        if targetHit then
            table.removevalue(hitEntities, targetHit)
            self:DoDamage(kHandGrenadesDamage, targetHit, targetHit:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - self:GetOrigin()), "none")
        end        
        
        local owner = self:GetOwner()
        // It is possible this grenade does not have an owner.
        if owner then
            table.insertunique(hitEntities, owner)
        end
        
        RadiusDamage(hitEntities, self:GetOrigin(), kHandGrenadesRange, kHandGrenadesDamage, self)
        
        // TODO: use what is defined in the material file
        local surface = GetSurfaceFromEntity(targetHit)
        
        local params = {surface = surface}
        if not targetHit then
            params[kEffectHostCoords] = Coords.GetLookIn( self:GetOrigin(), self:GetCoords().zAxis )
        end
        
        self:TriggerEffects("grenade_explode", params)
        
        DestroyEntity(self)
        
    elseif Client then
    
        CreateExplosionDecals(self)

        TriggerCameraShake(self, kGrenadeMinShakeIntensity, kGrenadeMaxShakeIntensity, kGrenadeCameraShakeDistance)
    
    end
    
end

Shared.LinkClassToMap("HandGrenade", HandGrenade.kMapName, networkVars)