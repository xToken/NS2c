// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Spit.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/PredictedProjectile.lua")
Script.Load("lua/DamageMixin.lua")

Shared.PrecacheSurfaceShader("materials/infestation/spit_decal.surface_shader")

class 'Spit' (PredictedProjectile)

Spit.kMapName            = "spit"
Spit.kClearOnImpact = true
Spit.kClearOnEnemyImpact = true

local networkVars = { }

local kSpitLifeTime = 8

Spit.kProjectileCinematic = PrecacheAsset("cinematics/alien/gorge/dripping_slime.cinematic")
Spit.kRadius = 0.05

AddMixinNetworkVars(TeamMixin, networkVars)

-- Disappear up after a time.
local function UpdateLifetime(self)

    // Grenades are created in predict movement, so in order to get the correct
    // lifetime, we start counting our lifetime from the first UpdateLifetime rather than when
    // we were created
    if not self.endOfLife then
        self.endOfLife = Shared.GetTime() + kSpitLifeTime
    end

    if self.endOfLife <= Shared.GetTime() then
    
        DestroyEntity(self)
        return false
        
    end
    
    return true
    
end

function Spit:OnCreate()

    PredictedProjectile.OnCreate(self)
    
    InitMixin(self, DamageMixin)
    InitMixin(self, TeamMixin)
    
    if Server then
        self:AddTimedCallback(UpdateLifetime, 0.1)
        self.endOfLife = nil
    end

end

function Spit:ProcessHit(targetHit, surface, normal)

    if self:GetIsDestroyed() then
        return true
    end
    if Server and self:GetOwner() ~= targetHit then
        self:DoDamage(kSpitDamage, targetHit, self:GetOrigin() + normal * kHitEffectOffset, self:GetCoords().zAxis, surface, false, false)
        if targetHit and targetHit:isa("Hive") and targetHit.OnSpitHit then
            targetHit:OnSpitHit()
        end
        DestroyEntity(self) 
    else
        return true
    end

end

function Spit:GetDeathIconIndex()
    return kDeathMessageIcon.Spit
end

function Spit:GetAbilityUsesFocus()
    return true
end

Shared.LinkClassToMap("Spit", Spit.kMapName, networkVars)