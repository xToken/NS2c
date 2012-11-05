//=============================================================================
//
// lua\Weapons\Alien\Spit.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/DamageMixin.lua")

Shared.PrecacheSurfaceShader("materials/infestation/spit_decal.surface_shader")

class 'Spit' (Projectile)

Spit.kMapName            = "spit"
Spit.kDamage             = kSpitDamage

local kSpitTrail =
{ 
    PrecacheAsset("cinematics/alien/gorge/dripping_slime.cinematic")
}

local networkVars =
{
    onSurface = "boolean",
    ownerId = "entityid"
}

local kSpitLifeTime = 8

function Spit:OnCreate()

    Projectile.OnCreate(self)
    
    self.onSurface = false
    InitMixin(self, DamageMixin)
    
    if Server then
        self:AddTimedCallback(Spit.TimeUp, kSpitLifeTime)
    end
    
    self.creationTime = Shared.GetTime()

end

function Spit:TimeUp()

    DestroyEntity(self)
    return false
    
end

function Spit:GetPrimaryAttackUsesFocus()
    return true
end

function Spit:GetSimulatePhysics()
    return not self:GetIsOnSurface()
end

function Spit:GetIsOnSurface()
    return self.onSurface
end

if Client then

    function Spit:OnInitialized()
    
        Projectile.OnInitialized(self)
        
        local player = Client.GetLocalPlayer()
        //if /*not player or player:GetId() ~= self.ownerId*/ then
        
            self.trailCinematic = Client.CreateTrailCinematic(RenderScene.Zone_Default)
            self.trailCinematic:SetCinematicNames(kSpitTrail)
            self.trailCinematic:AttachTo(self, TRAIL_ALIGN_MOVE, Vector(0, 0, 0))
            
            self.trailCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
            self.trailCinematic:SetOptions( {
                    numSegments = 1,
                    collidesWithWorld = false,
                    visibilityChangeDuration = 0.0,
                    fadeOutCinematics = true,
                    stretchTrail = false,
                    trailLength = 1.5,
                    minHardening = 1,
                    maxHardening = 1,
                    hardeningModifier = 1,
                    trailWeight = 0.2
                } )
                
            self.trailCinematic:SetIsVisible(true)

        //end
    
    end

end

function Spit:OnDestroy()

    if Client then
    
        if self.trailCinematic then
        
            Client.DestroyTrailCinematic(self.trailCinematic)
            self.trailCinematic = nil
            
        end
        
        if self.decal then
        
            Client.DestroyRenderDecal(self.decal)
            self.decal = nil
        
        end
        
    end
    
    Projectile.OnDestroy(self)

end

function Spit:GetDeathIconIndex()
    return kDeathMessageIcon.Spit
end

function Spit:ProcessHit(targetHit, surface, normal)

    if normal:GetLength() == 0 then
        DestroyEntity(self)
        
    elseif not targetHit then
    
        self.onSurface = true
        
        local coords = Coords.GetIdentity()
        coords.origin = self:GetOrigin()
        coords.yAxis = normal
        coords.zAxis = GetNormalizedVector(self.desiredVelocity)
        coords.xAxis = coords.zAxis:CrossProduct(coords.yAxis)
        coords.zAxis = coords.yAxis:CrossProduct(coords.xAxis)
        
        self:SetCoords(coords)

    // Don't hit owner - shooter
    elseif self:GetOwner() ~= targetHit then
    
        self:TriggerEffects("spit_hit", { effecthostcoords = Coords.GetTranslation(self:GetOrigin()) } )
    
        self:DoDamage(Spit.kDamage, targetHit, self:GetOrigin(), nil, surface)
        
        DestroyEntity(self)
        
    end    
    
end

function Spit:OnUpdate(deltaTime)

    Projectile.OnUpdate(self, deltaTime)
    
    if Client then
    
        if self:GetIsOnSurface() and self.trailCinematic then

            Client.DestroyTrailCinematic(self.trailCinematic)
            self.trailCinematic = nil
            
        end
    
    end

end

if Client then

    local kSpitRadius = 0.8
    local kSplatAnimDuration = 0.1
    local kFadeOutAnimDuration = 3

    function Spit:OnUpdateRender()
    
        PROFILE("Spit:OnUpdateRender")
    
        if self:GetIsOnSurface() then
        
            if not self.decal then
            
                self.decal = Client.CreateRenderDecal()
                self.spitMaterial = Client.CreateRenderMaterial()
                self.spitMaterial:SetMaterial("materials/infestation/spit_decal.material")
                self.decal:SetMaterial(self.spitMaterial)
                self.creationTime = Shared.GetTime()
                self:TriggerEffects("spit_hit", { effecthostcoords = Coords.GetTranslation(self:GetOrigin()) } )
                
            end

            if self.decal then
            
                local radius = kSpitRadius * Clamp( (Shared.GetTime() - self.creationTime) / kSplatAnimDuration, 0, 1)
            
                self.decal:SetCoords(self:GetCoords())
                
                local intensity = 0.0
                local remainingTime = kSpitLifeTime - (Shared.GetTime() - self.creationTime) - 0.5

                if remainingTime < kFadeOutAnimDuration then
                    intensity = 1 - (remainingTime / kFadeOutAnimDuration)
                end
                
                self.decal:SetExtents(Vector(radius, 0.3, radius))
                self.spitMaterial:SetParameter("intensity", 1-intensity)
                
            end
        
        end
        
    end
    
end

Shared.LinkClassToMap("Spit", Spit.kMapName, networkVars)