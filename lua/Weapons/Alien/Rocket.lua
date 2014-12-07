//
// lua\Weapons\Alien\Rocket.lua

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")

class 'Rocket' (PredictedProjectile)

Rocket.kMapName            = "rocket"
Rocket.kModelName          = PrecacheAsset("models/alien/gorge/bilebomb.model")

// The max amount of time a Rocket can last for
Rocket.kClearOnImpact = true
Rocket.kClearOnEnemyImpact = true
Rocket.kRadius = 0.15

local kRocketLifetime = 6

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

-- Blow up after a time.
local function UpdateLifetime(self)

    // in order to get the correct lifetime, 
	// we start counting our lifetime from the first UpdateLifetime rather than when
    // we were created
    if not self.endOfLife then
        self.endOfLife = Shared.GetTime() + kRocketLifetime
    end

    if self.endOfLife <= Shared.GetTime() then
    
        self:Detonate(nil)
        return false
        
    end
    
    return true
    
end

function Rocket:OnCreate()

    PredictedProjectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    if Server then
        self:AddTimedCallback(UpdateLifetime, 0.1)
        self.endOfLife = nil
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

function Rocket:ProcessHit(targetHit, surface)

    if Server and self:GetOwner() ~= targetHit then
        self:Detonate(targetHit, surface)
        return true        
    end
    return false
    
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