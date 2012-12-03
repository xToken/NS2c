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

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")

class 'Bomb' (Projectile)

Bomb.kMapName            = "bomb"
Bomb.kModelName          = PrecacheAsset("models/alien/gorge/bilebomb.model")

// The max amount of time a Bomb can last for
Bomb.kLifetime = 6

local kBileBombDotIntervall = 0.4

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function Bomb:OnCreate()

    Projectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    self.radius = 0.2

end

function Bomb:OnInitialized()

    Projectile.OnInitialized(self)
    
    if Server then
        self:AddTimedCallback(Bomb.TimeUp, Bomb.kLifetime)
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

if Server then

    function Bomb:ProcessHit(targetHit, surface)

        if (not self:GetOwner() or targetHit ~= self:GetOwner()) and not self:GetIsDestroyed() then

            local hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kBileBombSplashRadius)
            
            RadiusDamage(hitEntities, self:GetOrigin(), kBileBombSplashRadius, kBileBombDamage, self)
            
            self:TriggerEffects("bilebomb_hit")
            
            DestroyEntity(self)

        end

    end
    
    function Bomb:TimeUp(currentRate)
        if not self:GetIsDestroyed() then
            DestroyEntity(self)
        end
        return false
    end

end

function Bomb:GetNotifiyTarget()
    return false
end


Shared.LinkClassToMap("Bomb", Bomb.kMapName, networkVars)