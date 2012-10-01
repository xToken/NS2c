//
// lua\Weapons\Alien\Rocket.lua

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")

class 'Rocket' (Projectile)

Rocket.kMapName            = "rocket"
Rocket.kModelName          = PrecacheAsset("models/alien/gorge/bilebomb.model")

// The max amount of time a Bomb can last for
Rocket.kLifetime = 6

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function Rocket:OnCreate()

    Projectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)

    self.radius = 0.2

end

function Rocket:OnInitialized()

    Projectile.OnInitialized(self)
    
    if Server then
        self:AddTimedCallback(Rocket.TimeUp, Rocket.kLifetime)
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

if Server then

    function Rocket:ProcessHit(targetHit)

        if targetHit ~= self:GetOwner() and not self.detonated then
        
            local hitEntities
            if GetGamerules():GetFriendlyFire() then
                hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kAcidRocketRadius)
            else
                hitEntities = GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kAcidRocketRadius)
            end
        
            // Remove grenade and add firing player.
            table.removevalue(hitEntities, self)
            local owner = self:GetOwner()
            // It is possible this grenade does not have an owner.
            if owner then
                table.insertunique(hitEntities, owner)
            end
        
            RadiusDamage(hitEntities, self:GetOrigin(), kAcidRocketRadius, kAcidRocketDamage, self, true)
            self:TriggerEffects("acidrocket_hit")
            DestroyEntity(self)

        end

    end
    
    function Rocket:TimeUp(currentRate)

        DestroyEntity(self)
        return false
    
    end

end


Shared.LinkClassToMap("Rocket", Rocket.kMapName, networkVars)