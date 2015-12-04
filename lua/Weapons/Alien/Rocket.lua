// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\Weapons\Alien\Rocket.lua
// - Dragon

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")

class 'Rocket' (PredictedProjectile)

Rocket.kMapName = "rocket"
Rocket.kModelName = PrecacheAsset("models/alien/gorge/bilebomb.model")

// The max amount of time a Rocket can last for
Rocket.kClearOnSurfaceImpact = true
Rocket.kClearOnEntityImpact = true
Rocket.kClearOnEnemyImpact = true
Rocket.kClearOnSelfImpact = false
Rocket.kRadius = 0.15

local kRocketLifetime = 6

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function Rocket:OnCreate()

    PredictedProjectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    if Server then
        self:AddTimedCallback(Rocket.TimedDetonateCallback, kRocketLifetime)
    end

end

function Rocket:GetProjectileModel()
    return Rocket.kModelName
end 

function Rocket:GetDeathIconIndex()
    return kDeathMessageIcon.BileBomb
end

function Rocket:GetDamageType()
    return kAcidRocketDamageType
end

function Rocket:TimedDetonateCallback()
    self:Detonate()
end

function Rocket:ProcessHit(targetHit, surface)

    if Server and self:GetOwner() ~= targetHit then
        self:Detonate(targetHit, surface)    
    end
    
end

if Server then

    function Rocket:Detonate(targetHit, surface)

        if not self:GetIsDestroyed() then
            local hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kAcidRocketRadius)
            // full damage on direct impact
            if targetHit then
                table.removevalue(hitEntities, targetHit)
                self:DoDamage(kAcidRocketDamage, targetHit, targetHit:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - self:GetOrigin()), "none")
            end
            RadiusDamage(hitEntities, self:GetOrigin(), kAcidRocketRadius, kAcidRocketDamage, self, true)
            self:TriggerEffects("acidrocket_hit")
            DestroyEntity(self)
        end

    end

end


Shared.LinkClassToMap("Rocket", Rocket.kMapName, networkVars)