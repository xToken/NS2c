//=============================================================================
//
// lua\Weapons\Marine\Grenade.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")

class 'Grenade' (Projectile)

Grenade.kMapName = "grenade"
Grenade.kModelName = PrecacheAsset("models/marine/rifle/rifle_grenade.model")

local kMinLifeTime = .7

// prevents collision with friendly players in range to spawnpoint
Grenade.kDisableCollisionRange = 10

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
        self.endOfLife = Shared.GetTime() + kGrenadeLifetime
    end
    
    local fuse = self.endOfLife - Shared.GetTime()
    if fuse <= 0 then
    
        self:Detonate(nil)
        return false
        
    end
    
    return true
    
end

function Grenade:OnCreate()

    Projectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
	

	if Server then
    
        self:AddTimedCallback(UpdateLifetime, 0.1)
        self.endOfLife = nil
        
    end
    
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

if Server then

    function Grenade:ProcessHit(targetHit, surface)
    
        if targetHit and (HasMixin(targetHit, "Live") and GetGamerules():CanEntityDoDamageTo(self, targetHit)) and self:GetOwner() ~= targetHit then
            self:Detonate(targetHit)
        elseif self:GetVelocity():GetLength() > 2 then
            self:TriggerEffects("grenade_bounce")
        end
        
    end
    
    function Grenade:Detonate(targetHit)
    
        // Do damage to nearby targets.
        local hitEntities
        if GetGamerules():GetFriendlyFire() then
            hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kGrenadeLauncherGrenadeDamageRadius)
        else
            hitEntities = GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kGrenadeLauncherGrenadeDamageRadius)
        end
		
        // Remove grenade and add firing player.
        table.removevalue(hitEntities, self)
        
        // full damage on direct impact
        if targetHit then
            table.removevalue(hitEntities, targetHit)
            self:DoDamage(kGrenadeLauncherGrenadeDamage, targetHit, targetHit:GetOrigin(), GetNormalizedVector(targetHit:GetOrigin() - self:GetOrigin()), "none")
        end
        
        local owner = self:GetOwner()
        // It is possible this grenade does not have an owner.
        if owner then
            table.insertunique(hitEntities, owner)
        end
        
        RadiusDamage(hitEntities, self:GetOrigin(), kGrenadeLauncherGrenadeDamageRadius, kGrenadeLauncherGrenadeDamage, self)
        
        // TODO: use what is defined in the material file
        local surface = GetSurfaceFromEntity(targetHit)
                
        local params = { surface = surface }
        params[kEffectHostCoords] = Coords.GetLookIn( self:GetOrigin(), self:GetCoords().zAxis)        
        self:TriggerEffects("grenade_explode", params)
        
        CreateExplosionDecals(self)
        
        DestroyEntity(self)
        
    end
    
    function Grenade:PrepareToBeWhackedBy(whacker)
    
        self.whackerId = whacker:GetId()
        
        // It is possible that the endOfLife isn't set yet.
        if not self.endOfLife then
            self.endOfLife = 0
        end
        
        // Prolong lifetime a bit to give it time to get out of range.
        self.endOfLife = math.max(self.endOfLife, Shared.GetTime() + 2)
        self.prepTime = Shared.GetTime()
        
    end
    
    function Grenade:GetCanDetonate()
        if self.creationTime then
            return self.creationTime + kMinLifeTime < Shared.GetTime()
        end
        return false
    end
    
    function Grenade:SetVelocity(velocity)
    
        Projectile.SetVelocity(self, velocity)
        
        if Grenade.kDisableCollisionRange > 0 then
        
            if self.physicsBody and not self.collisionDisabled then
            
                // exclude all nearby friendly players from collision
                for index, player in ipairs(GetEntitiesForTeamWithinRange("Player", self:GetTeamNumber(), self:GetOrigin(), Grenade.kDisableCollisionRange)) do
                    
                    if player:GetController() then
                        Shared.SetPhysicsObjectCollisionsEnabled(self.physicsBody, player:GetController(), false)
                    end
                
                end

                self.collisionDisabled = true

            end
        
        end
        
    end  

end

Shared.LinkClassToMap("Grenade", Grenade.kMapName, networkVars)