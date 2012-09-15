//
// lua\Weapons\Marine\HandGrenade.lua

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")

class 'HandGrenade' (Projectile)

HandGrenade.kMapName = "handgrenade"
HandGrenade.kModelName = PrecacheAsset("models/marine/rifle/rifle_grenade.model")

local kMinLifeTime = .7

// prevents collision with friendly players in range to spawnpoint
HandGrenade.kDisableCollisionRange = 10

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function HandGrenade:OnCreate()

    Projectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    // don't start our lifetime from here, start it from the first actual tick the grenade exists.
    self:SetNextThink(0.01)
    self.endOfLife = nil
    
end

function HandGrenade:GetProjectileModel()
    return HandGrenade.kModelName
end 

function HandGrenade:GetDeathIconIndex()
    return kDeathMessageIcon.Grenade
end

function HandGrenade:GetDamageType()
    return kHandGrenadesDamageType
end

if Server then

    function HandGrenade:ProcessHit(targetHit, surface)
        if targetHit and (HasMixin(targetHit, "Live") and GetGamerules():CanEntityDoDamageTo(self, targetHit)) and self:GetOwner() ~= targetHit then
            self:Detonate(targetHit)            
        else
            if self:GetVelocity():GetLength() > 2 then
                self:TriggerEffects("grenade_bounce")
            end
        end
        
    end

    // Blow up after a time
    function HandGrenade:OnThink()
    
        // Grenades are created in predict movement, so in order to get the correct
        // lifetime, we start counting our lifetime from the first OnThink rather than when
        // we were created
        if not self.endOfLife then
            self.endOfLife = Shared.GetTime() + kHandGrenadesLifetime
        end
    
        local delta = self.endOfLife - Shared.GetTime()
        if delta > 0 then
            self:SetNextThink(delta)
         else
            self:Detonate(nil)
        end
        
    end
    
    function HandGrenade:Detonate(targetHit)
    
        // Do damage to nearby targets.
        local hitEntities
        if GetGamerules():GetFriendlyFire() then
            hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kHandGrenadesRange)
        else
            hitEntities = GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kHandGrenadesRange)
        end
		
        // Remove grenade and add firing player.
        table.removevalue(hitEntities, self)
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
        
    end
    
    function HandGrenade:GetCanDetonate()
        if self.creationTime then
            return self.creationTime + kMinLifeTime < Shared.GetTime()
        end
        return false
    end
    
    function HandGrenade:SetVelocity(velocity)
    
        Projectile.SetVelocity(self, velocity)
        
        if HandGrenade.kDisableCollisionRange > 0 then
        
            if self.physicsBody and not self.collisionDisabled then
            
                // exclude all nearby friendly players from collision
                for index, player in ipairs(GetEntitiesForTeamWithinRange("Player", self:GetTeamNumber(), self:GetOrigin(), HandGrenade.kDisableCollisionRange)) do
                    
                    if player:GetController() then
                        Shared.SetPhysicsObjectCollisionsEnabled(self.physicsBody, player:GetController(), false)
                    end
                
                end

                self.collisionDisabled = true

            end
        
        end
        
    end  

end

Shared.LinkClassToMap("HandGrenade", HandGrenade.kMapName, networkVars)