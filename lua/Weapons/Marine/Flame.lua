//=============================================================================
//
// lua\Weapons\Marine\Flame.lua
//
// Created by Andreas Urwalek (andi@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
//=============================================================================

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/decals/flame_decal.surface_shader")

class 'Flame' (ScriptActor)

Flame.kMapName = "flame"
Flame.kFireEffect = PrecacheAsset("cinematics/marine/flamethrower/burning_surface.cinematic")
Flame.kFireWallEffect = PrecacheAsset("cinematics/marine/flamethrower/burning_vertical_surface.cinematic")

Flame.kDamageRadius = 1.8
Flame.kLifeTime = 5.6
local kUpdateTime = 0.6
Flame.kDamage = 8

local networkVars = { }

AddMixinNetworkVars(TeamMixin, networkVars)

function Flame:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
end

local function UpdateLifetime(self)

    self.lifeTime = self.lifeTime - kUpdateTime
    
    self:Detonate(nil)
    
    if self.lifeTime <= 0 then
    
        if Server then
           self:Detonate(nil)
        end
        
        DestroyEntity(self)
        
        return false
        
    end
    
    return true
    
end

function Flame:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    if Server then
    
	    // intervall of dealing damage
	    self.lifeTime = Flame.kLifeTime - 1
	    self:AddTimedCallback(UpdateLifetime, kUpdateTime)
        
    elseif Client then
    
        self.fireEffect = Client.CreateCinematic(RenderScene.Zone_Default)
        
        local startPosition = self:GetOrigin() + Vector(0, 0.2, 0)
        local endPosition = self:GetOrigin() - Vector(0, 10, 0)
        
        local trace = Shared.TraceRay(startPosition, endPosition, CollisionRep.Damage, PhysicsMask.Bullets,  EntityFilterAll())        
        local cinematicName = Flame.kFireEffect
        
        self.fireEffect:SetCinematic(cinematicName)
        self.fireEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.fireEffect:SetIsVisible(self:GetIsVisible())

        local coords = Coords.GetIdentity()
        coords.origin = self:GetOrigin()
        self.fireEffect:SetCoords(coords)
        
        Client.CreateTimeLimitedDecal("cinematics/vfx_materials/decals/flame_decal.material", self:GetCoords(), 3, Flame.kLifeTime - 1)
    
    end
    
end

function Flame:OnDestroy()

	if Client then
	
        Client.DestroyCinematic(self.fireEffect)
        self.fireEffect = nil
        
	end
	
	ScriptActor.OnDestroy(self)
    
end

function Flame:GetDeathIconIndex()
    return kDeathMessageIcon.Flamethrower
end

function Flame:GetDamageType()
    return kFlamethrowerDamageType
end

function Flame:GetShowHitIndicator()
    return false
end
    
if Server then

    function Flame:Detonate(targetHit)
    
    	local player = self:GetOwner()
	    local ents = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), Flame.kDamageRadius)
	    
	    if targetHit ~= nil then
	    	table.insert(ents, targetHit)
	    end
	    
	    for index, ent in ipairs(ents) do
        
            if ent ~= self:GetOwner() or GetGamerules():GetFriendlyFire() then
            
                local toEnemy = GetNormalizedVector(ent:GetModelOrigin() - self:GetOrigin())
                self:DoDamage(Flame.kDamage, ent, ent:GetModelOrigin(), toEnemy)
                
            end
            
	    end
        
    end
    
elseif Client then

    function Flame:OnUpdate(deltaTime)
    
        ScriptActor.OnUpdate(self, deltaTime)
    
        if self.fireEffect then
            self.fireEffect:SetIsVisible(self:GetIsVisible())
        end
    
    end
    
end

Shared.LinkClassToMap("Flame", Flame.kMapName, networkVars)