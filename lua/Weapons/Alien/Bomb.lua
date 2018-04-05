// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\Weapons\Alien\Bomb.lua
// - Dragon

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")

PrecacheAsset("cinematics/vfx_materials/decals/bilebomb_decal.surface_shader")

class 'Bomb' (PredictedProjectile)

Bomb.kMapName = "bomb"
Bomb.kModelName = PrecacheAsset("models/alien/gorge/bilebomb.model")

-- The max amount of time a Bomb can last for
Bomb.kClearOnSurfaceImpact = true
Bomb.kClearOnEntityImpact = true
Bomb.kClearOnEnemyImpact = true
Bomb.kClearOnSelfImpact = false
Bomb.kRadius = 0.2

local kBombLifetime = 6

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function Bomb:OnCreate()

    PredictedProjectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    if Server then
        self:AddTimedCallback(Bomb.TimedDetonateCallback, kBombLifetime)
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

function Bomb:TimedDetonateCallback()
    self:Detonate()
end

function Bomb:ProcessHit(targetHit, surface)

    if Server and self:GetOwner() ~= targetHit then
        self:Detonate(targetHit, surface)
    end
    
end

function Bomb:Detonate(targetHit, surface)

    if Server then
    
        local hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kBileBombSplashRadius)
        
        -- full damage on direct impact
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