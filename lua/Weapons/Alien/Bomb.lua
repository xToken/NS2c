//=============================================================================
//
// lua\Weapons\Alien\Bomb.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
// Bile bomb projectile
//
//=============================================================================

//NS2c
//Bilebomb is now a predicted projectile.

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/decals/bilebomb_decal.surface_shader")
Shared.RegisterDecalMaterial("cinematics/vfx_materials/decals/bilebomb_decal.material")

class 'Bomb' (PredictedProjectile)

Bomb.kMapName            = "bomb"
Bomb.kModelName          = PrecacheAsset("models/alien/gorge/bilebomb.model")

// The max amount of time a Bomb can last for
Bomb.kClearOnImpact = true
Bomb.kClearOnEnemyImpact = true
local kBombLifetime = 6

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function Bomb:OnCreate()

    PredictedProjectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    self:AddTimedCallback(Bomb.Detonate, kBombLifetime)

end

function Bomb:GetProjectileModel()
    return Bomb.kModelName
end 
   
function Bomb:GetDeathIconIndex()
    return kDeathMessageIcon.BileBomb
end

function Bomb:GetDamageType()
    return kBileBombDamageType
end

function Bomb:ProcessHit(targetHit, surface)
    self:Detonate(targetHit, surface)
    return true    
end

function Bomb:Detonate(targetHit, surface)

    if Server then
    
        local hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kBileBombSplashRadius)
        
        // full damage on direct impact
        if targetHit then
            table.removevalue(hitEntities, targetHit)
            self:DoDamage(kBileBombDamage, targetHit, targetHit:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - self:GetOrigin()), "none")
        end
        
        RadiusDamage(hitEntities, self:GetOrigin(), kBileBombSplashRadius, kBileBombDamage, self)
        
        self:TriggerEffects("bilebomb_hit")
        
        DestroyEntity(self)
        
    elseif Client then
    
        CreateExplosionDecals(self, "bilebomb_decal")
    
    end

end

function Bomb:GetNotifiyTarget()
    return false
end

Shared.LinkClassToMap("Bomb", Bomb.kMapName, networkVars)