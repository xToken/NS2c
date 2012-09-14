//=============================================================================
//
// lua\Weapons\Marine\Tracer_Client.lua
//
// Created by Charlie Cleveland (charlie@unknownworlds.com)
// Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
//
// A client-side tracer object that disappears when it hits anything.
//
//=============================================================================

class 'Tracer'

Tracer.kMapName             = "tracer"

kDefaultTracerEffectName = PrecacheAsset("cinematics/marine/tracer.cinematic")
kHeavyMachineGunTracerEffectName = PrecacheAsset("cinematics/marine/exo_tracer.cinematic")
kSpikeTracerEffectName = PrecacheAsset("cinematics/alien/tracer.cinematic")

function Tracer:OnDestroy()

    if self.tracerEffect then
    
        Client.DestroyCinematic(self.tracerEffect)
        self.tracerEffect = nil
        
    end
    
end

function Tracer:OnUpdate(deltaTime)

    self.timePassed = self.timePassed + deltaTime
        
    if self.tracerEffect ~= nil then

        local coords = Coords()
        
        coords.origin = self.startPoint + self.timePassed * self.tracerVelocity
        
        coords.zAxis =self.tracerVelocity:GetUnit()
        coords.yAxis = coords.zAxis:GetPerpendicular()
        coords.xAxis = Math.CrossProduct(coords.yAxis, coords.zAxis)
        
        self.tracerEffect:SetCoords(coords)
        
    end 
   
end

function Tracer:GetTimeToDie()
    return self.timePassed >= self.lifetime
end
    
function BuildTracer(startPoint, endPoint, velocity, effectName)

    local tracer = Tracer()
    
    tracer.tracerEffect = Client.CreateCinematic(RenderScene.Zone_Default)
    tracer.tracerEffect:SetCinematic(effectName)
    tracer.tracerEffect:SetCoords(Coords.GetLookIn( startPoint, GetNormalizedVector(endPoint - startPoint) ))
    tracer.tracerEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
    
    tracer.tracerVelocity = Vector(0, 0, 0)
    VectorCopy(velocity, tracer.tracerVelocity)
    
    tracer.startPoint = Vector(0, 0, 0)
    VectorCopy(startPoint, tracer.startPoint)
    
    // Calculate how long we should live so we can animate to that target
    tracer.lifetime = (endPoint - startPoint):GetLength() / velocity:GetLength()
    tracer.timePassed = 0
    
    return tracer
    
end
