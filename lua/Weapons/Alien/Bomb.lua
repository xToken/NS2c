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

-- Blow up after a time.
local function UpdateLifetime(self)

    // Grenades are created in predict movement, so in order to get the correct
    // lifetime, we start counting our lifetime from the first UpdateLifetime rather than when
    // we were created
    if not self.endOfLife then
        self.endOfLife = Shared.GetTime() + kBombLifetime
    end

    if self.endOfLife <= Shared.GetTime() then
    
        self:Detonate(nil)
        return false
        
    end
    
    return true
    
end

function Bomb:OnCreate()

    PredictedProjectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    if Server then
        self:AddTimedCallback(UpdateLifetime, 0.1)
        self.endOfLife = nil
    end

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

    if Server then
        self:Detonate(targetHit, surface)
    else
        return true
    end
    
end

if Server then

    function Bomb:Detonate(targetHit, surface)

        if not self:GetIsDestroyed() then

            local hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kBileBombSplashRadius)
            
            // full damage on direct impact
            if targetHit then
                table.removevalue(hitEntities, targetHit)
                self:DoDamage(kBileBombDamage, targetHit, targetHit:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - self:GetOrigin()), "none")
            end
            
            RadiusDamage(hitEntities, self:GetOrigin(), kBileBombSplashRadius, kBileBombDamage, self)
            
            self:TriggerEffects("bilebomb_hit")
            
            DestroyEntity(self)
            
            CreateExplosionDecals(self, "bilebomb_decal")

        end

    end

end

function Bomb:GetNotifiyTarget()
    return false
end


Shared.LinkClassToMap("Bomb", Bomb.kMapName, networkVars)