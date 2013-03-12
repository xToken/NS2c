// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Weapons\JetpackOnBack.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Jetpack version which is attacehd to the marines back. Creates trail cinematics and
//    triggers animations. No physical model with this one.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// TODO: delay closing of thrusters and add impact effect here (currently in JetpackMarine)

Script.Load("lua/TeamMixin.lua")

class 'JetpackOnBack' (ScriptActor)

JetpackOnBack.kMapName = "jetpackonback"

local kModelName = PrecacheAsset("models/marine/jetpack/jetpack.model")
local kAnimationGraph = PrecacheAsset("models/marine/jetpack/jetpack.animation_graph")

local kImpactCinematic = PrecacheAsset("cinematics/marine/jetpack/impact.cinematic")
local kJetpackTakeOffEffect = PrecacheAsset("cinematics/marine/jetpack/takeoff.cinematic")

local kSmokeEffectInterval = 0.1
local kSmokeEffectDuration = 0.7

local kCloseJetpackDelay = 3

local networkVars =
{
    flying = "boolean",
    thrustersOpen = "boolean"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function JetpackOnBack:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    
    self:SetTeamNumber(kTeam1Index)
    
    self:SetUpdates(true)
    
    self.flying = false
    self.thrustersOpen = false
    self.timeFlyingEnd = 0
    
    self:SetModel(kModelName, kAnimationGraph)
    
end

function JetpackOnBack:GetTechId()
    return kTechId.Jetpack
end

function JetpackOnBack:OnDestroy()

    if Client then
        self:DestroyTrails()
    end
    
    ScriptActor.OnDestroy(self)
    
end

function JetpackOnBack:SetIsFlying(flying)

    if flying then
    
        self.thrustersOpen = true
        self.timeFlyingEnd = 0
        
    else
        self.timeFlyingEnd = Shared.GetTime()
    end
    
    self.flying = flying
    
end

function JetpackOnBack:GetIsFlying()
    return self.flying
end

/**
 * Only visible when the parent Marine is visible.
 */
function JetpackOnBack:OnGetIsVisible(visibleTable, viewerTeamNumber)

    local parent = self:GetParent()
    if parent then
        visibleTable.Visible = parent:GetIsVisible()
    end
    
end

if Client then

    local kNumSegments = 5
    local kTrailLength = 2
    // Time required to set visibility of trails.
    local kVisibilityChangeDuration = 0.3
    
    local kYOffset = 0.18
    local kXOffset = 0.26
    
    local kTrailCinematics =
    {
        PrecacheAsset("cinematics/marine/jetpack/trail_1.cinematic"),
        PrecacheAsset("cinematics/marine/jetpack/trail_2.cinematic"),
        PrecacheAsset("cinematics/marine/jetpack/trail_2.cinematic"),
        PrecacheAsset("cinematics/marine/jetpack/trail_2.cinematic"),
        PrecacheAsset("cinematics/marine/jetpack/trail_3.cinematic")
    }
    
    function JetpackOnBack:InitTrails()
    
        if self.trailCinematicLeft == nil then
        
            self.trailCinematicLeft = Client.CreateTrailCinematic(RenderScene.Zone_Default)
            self.trailCinematicLeft:SetCinematicNames(kTrailCinematics)
            self.trailCinematicLeft:AttachTo(self, TRAIL_ALIGN_MOVE,  Vector(-kXOffset, kYOffset, 0))
            
            self.trailCinematicLeft:SetIsVisible(false)
            self.trailCinematicLeft:SetRepeatStyle(Cinematic.Repeat_Endless)
            self.trailCinematicLeft:SetOptions( {
                    numSegments = kNumSegments,
                    collidesWithWorld = false,
                    visibilityChangeDuration = kVisibilityChangeDuration,
                    fadeOutCinematics = true,
                    stretchTrail = false,
                    trailLength = kTrailLength,
                    minHardening = 0.01,
                    maxHardening = 0.3,
                    hardeningModifier = 0.3,
                    trailWeight = 0.8
                } )
            
            self.trailCinematicLeft:SetSegmentWeight(2, 3.5)    
            
        end
        
        if self.trailCinematicRight == nil then
        
            self.trailCinematicRight = Client.CreateTrailCinematic(RenderScene.Zone_Default)
            self.trailCinematicRight:SetCinematicNames(kTrailCinematics)
            self.trailCinematicRight:AttachTo(self, TRAIL_ALIGN_MOVE,  Vector(kXOffset, kYOffset, 0))
            
            self.trailCinematicRight:SetIsVisible(false)
            self.trailCinematicRight:SetRepeatStyle(Cinematic.Repeat_Endless)
            self.trailCinematicRight:SetOptions( {
                    numSegments = kNumSegments,
                    collidesWithWorld = false,
                    visibilityChangeDuration = kVisibilityChangeDuration,
                    fadeOutCinematics = true,
                    stretchTrail = false,
                    trailLength = kTrailLength,
                    minHardening = 0.01,
                    maxHardening = 0.3,
                    hardeningModifier = 0.3,
                    trailWeight = 0.8
                } )
            
            self.trailCinematicRight:SetSegmentWeight(2, 3.5)
            
        end
        
    end
    
    function JetpackOnBack:DestroyTrails()
    
        if self.trailCinematicLeft then
        
            Client.DestroyTrailCinematic(self.trailCinematicLeft)
            self.trailCinematicLeft = nil
            
        end
        
        if self.trailCinematicRight then
        
            Client.DestroyTrailCinematic(self.trailCinematicRight)
            self.trailCinematicRight = nil
            
        end
        
    end
    
    // for changing visibility of trails
    function JetpackOnBack:UpdateJetpackTrails(deltaTime)
    
        // take off this frame
        if self.lastGetIsFlying == false and self:GetIsFlying() == true then
            self:TriggerJetpackStartEffect()
        end
        
        self.lastGetIsFlying = self:GetIsFlying()
        
        // trigger smoke effect
        if self:GetIsFlying() == true then
            //self:TriggerTakeOffSmokeEffect()
        end
        
        local player = self:GetParent()
        local isLocal = Client.GetLocalPlayer() == player
        
        if isLocal and not player:GetIsThirdPerson() then
            self:DestroyTrails()
            return    
        else
            self:InitTrails()
        end  
        
        local trailsVisible = self:GetIsFlying() and self:GetIsVisible()
        
        if self.trailCinematicLeft then
            self.trailCinematicLeft:SetIsVisible(trailsVisible)
        end
        
        if self.trailCinematicRight then
            self.trailCinematicRight:SetIsVisible(trailsVisible)
        end
        
    end
    
    function JetpackOnBack:TriggerTakeOffSmokeEffect()
    
        if self.timeJetpackTakeOffEffectStarted and self.timeJetpackTakeOffEffectStarted + kSmokeEffectDuration > Shared.GetTime() then
        
            // trigger only every kSmokeEffectInterval
            if not self.timeLastSmokeEffect or (self.timeLastSmokeEffect + kSmokeEffectInterval < Shared.GetTime()) then
            
                Shared.CreateEffect(nil, kJetpackTakeOffEffect, nil, self:GetCoords())
                self.timeLastSmokeEffect = Shared.GetTime()
                
            end
            
        end
        
    end
    
    function JetpackOnBack:TriggerJetpackStartEffect()
    
        local player = self:GetParent()
        
        if player then
        
            // Don't play the effect every time on take off
            if not self.timeJetpackTakeOffEffectStarted or self.timeJetpackTakeOffEffectStarted + 1 < Shared.GetTime() then
            
                local coords = self:GetCoords()
                
                local startPoint = coords.origin
                local endPoint = coords.origin + coords.yAxis * 3
                
                local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())
                
                if trace.endPoint ~= endPoint and trace.entity == nil then
                
                    local angles = Angles(0,0,0)
                    angles.yaw = GetYawFromVector(trace.normal)
                    angles.pitch = GetPitchFromVector(trace.normal) + (math.pi/2)
                    
                    local normalCoords = angles:GetCoords()
                    normalCoords.origin = trace.endPoint
                    
                    // create jet impact cinematic
                    Shared.CreateEffect(nil, kImpactCinematic, nil, normalCoords)
                    
                end
                
                self.timeJetpackTakeOffEffectStarted = Shared.GetTime()
                
            end
            
        end
        
    end
    
end

function JetpackOnBack:UpdateThrusters()

    if self.thrustersOpen and self.timeFlyingEnd ~= 0 then
    
        if self.timeFlyingEnd + kCloseJetpackDelay < Shared.GetTime() then
        
            self.thrustersOpen = false
            self.timeFlyingEnd = 0
            
        end
        
    end
    
end

function JetpackOnBack:OnUpdateAnimationInput(modelMixin)

    self:UpdateThrusters()
    
    local player = self:GetParent()
    if player then
        SetPlayerPoseParameters( player, self, player:GetHeadAngles() )
    end
    
    modelMixin:SetAnimationInput("flying", self.thrustersOpen)
    
end

Shared.LinkClassToMap("JetpackOnBack", JetpackOnBack.kMapName, networkVars)