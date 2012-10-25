// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ARC.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// AI controllable "tank" that the Commander can move around, deploy and use for long-distance
// siege attacks.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/UpgradableMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/RecycleMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/TargetCacheMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/TurretMixin.lua")

class 'ARC' (ScriptActor)

ARC.kMapName = "arc"

ARC.kModelName = PrecacheAsset("models/marine/arc/arc.model")
local kAnimationGraph = PrecacheAsset("models/marine/arc/arc.animation_graph")

// Animations
local kArcPitchParam = "arc_pitch"
local kArcYawParam = "arc_yaw"

ARC.kArcForwardTrackYawParam = "move_yaw"
ARC.kArcForwardTrackPitchParam = "move_pitch"
// Balance
ARC.kHealth                 = kARCHealth
ARC.kAttackDamage           = kARCDamage
ARC.kFireRange              = kARCRange         // From NS1
ARC.kMinFireRange           = kARCMinRange
ARC.kSplashRadius           = 3
ARC.kFov                    = 360
ARC.kBarrelMoveRate         = 150
ARC.kMaxPitch               = 45
ARC.kMaxYaw                 = 180
ARC.kDeployAnimationTime    = 4

ARC.kMode = enum( {'Stationary', 'Targeting', 'Destroyed'} )
ARC.kDeployMode = enum( { 'Undeploying', 'Undeployed', 'Deploying', 'Deployed' } )

if Server then
    Script.Load("lua/ARC_Server.lua")
end

local networkVars =
{
    // ARCs can only fire when deployed and can only move when not deployed
    mode            = "enum ARC.kMode",
    deployMode      = "enum ARC.kDeployMode",
    
    barrelYawDegrees            = "compensated float",
    barrelPitchDegrees          = "compensated float",
    
    // pose parameters for forward track (should be compensated??)
    forwardTrackYawDegrees        = "float",
    forwardTrackPitchDegrees      = "float",
    deploytime                  = "private time",
    // So we can update angles and pose parameters smoothly on client
    targetDirection             = "vector"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(UpgradableMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(RecycleMixin, networkVars)
AddMixinNetworkVars(TurretMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)

function ARC:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, UpgradableMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, RecycleMixin)
    InitMixin(self, TurretMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, GhostStructureMixin)
    
    if Server then
        InitMixin(self, SleeperMixin)
        
    elseif Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    self:SetLagCompensated(true)
end

function ARC:OnInitialized()

    ScriptActor.OnInitialized(self) 
    InitMixin(self, WeldableMixin) 
    self:SetModel(ARC.kModelName, kAnimationGraph)
    
    if Server then
        // TargetSelectors require the TargetCacheMixin for cleanup.
        InitMixin(self, TargetCacheMixin)
        
        // Prioritize targetting non-Eggs first.
        self.targetSelector = TargetSelector():Init(
                self,
                ARC.kFireRange,
                false, 
                { kMarineStaticTargets, kMarineMobileTargets },
                { self.FilterTarget(self) },
                { function(target) return target:isa("Hive") end })

        
        self:SetPhysicsType(PhysicsType.Kinematic)
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        self:SetMode(ARC.kMode.Stationary)
    elseif Client then
        self.lastModeClient = self.mode
        InitMixin(self, UnitStatusMixin)
    end
    self.deployMode = ARC.kDeployMode.Undeployed
    self.deploytime = 0
    self.active = true
    self:SetUpdates(true)
end

local kARCHealthbarOffset = Vector(0, 0.7, 0)
function ARC:GetHealthbarOffset()
    return kARCHealthbarOffset
end 

function ARC:GetIsIdle()
    return self.deployMode == ARC.kDeployMode.Undeployed
end

function ARC:GetReceivesStructuralDamage()
    return true
end

function ARC:GetCanSleep()
    return self.mode == ARC.kMode.Stationary
end

function ARC:GetDeathIconIndex()
    return kDeathMessageIcon.ARC
end

/**
 * Put the eye up 1 m.
 */
function ARC:GetViewOffset()
    return self:GetCoords().yAxis * 1.0
end

function ARC:GetEyePos()
    return self:GetOrigin() + self:GetViewOffset()
end

function ARC:OnPowerOn()

    self.deployMode = ARC.kDeployMode.Deploying
    self:TriggerEffects("arc_deploying")
    self.deploytime = Shared.GetTime()
    //Print("POWERON")
    self.active = true
end

function ARC:OnPowerOff()

    if self:GetTarget() ~= nil then
        self:CompletedCurrentOrder()
    end
    self.deploytime = 0
    self.active = false
    //Print("POWEROFF")
    self.deployMode = ARC.kDeployMode.Undeploying
    self:TriggerEffects("arc_stop_charge")
    self:TriggerEffects("arc_undeploying")
    
end

function ARC:PerformActivation(techId, position, normal, commander)
    return false, true
end

function ARC:GetActivationTechAllowed(techId)
    
    if techId == kTechId.Attack then
        return self.deployMode == ARC.kDeployMode.Deployed
    elseif techId == kTechId.Stop then
        return self.mode == ARC.kMode.Targeting
    end
    return true
    
end

function ARC:GetTechButtons(techId)
    return  { kTechId.Attack, kTechId.Stop, kTechId.None, kTechId.None,
          kTechId.None, kTechId.None, kTechId.None, kTechId.None }
end

function ARC:GetInAttackMode()
    return self.deployMode == ARC.kDeployMode.Deployed
end

function ARC:GetCanGiveDamageOverride()
    return true
end

function ARC:GetFov()
    return ARC.kFov
end

function ARC:GetEffectParams(tableParams)

    ScriptActor.GetEffectParams(self, tableParams)    
    tableParams[kEffectFilterDeployed] = self:GetInAttackMode() 
    
end

function ARC:FilterTarget()

    local attacker = self
    return function (target, targetPosition) return attacker:GetCanFireAtTargetActual(target, targetPosition) end
    
end

//
// Do a complete check if the target can be fired on. 
//
function ARC:GetCanFireAtTarget(target, targetPoint)    

    if target == nil then        
        return false
    end
    
    if not HasMixin(target, "Live") or not target:GetIsAlive() then
        return false
    end
    
    if not GetAreEnemies(self, target) then        
        return false
    end
    
    if not target.GetReceivesStructuralDamage or not target:GetReceivesStructuralDamage() then        
        return false
    end
    
    return self:GetCanFireAtTargetActual(target, targetPoint)
    
end

function ARC:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

//
// the checks made in GetCanFireAtTarget has already been made by the TargetCache, this
// is the extra, actual target filtering done.
//
function ARC:GetCanFireAtTargetActual(target, targetPoint)    

    if not target.GetReceivesStructuralDamage or not target:GetReceivesStructuralDamage() then        
        return false
    end

    if not target:GetIsSighted() and not GetIsTargetDetected(target) then
        return false
    end
    
    local distToTarget = (target:GetOrigin() - self:GetOrigin()):GetLengthXZ()
    if (distToTarget > ARC.kFireRange) then
        return false
    end
    
    return true
    
end

function ARC:UpdateAngles(deltaTime)

    if not self:GetInAttackMode() or not self:GetIsAlive() then
        return
    end
    
    if self.mode == ARC.kMode.Targeting then
    
        if self.targetDirection then
        
            local yawDiffRadians = GetAnglesDifference(GetYawFromVector(self.targetDirection), self:GetAngles().yaw)
            local yawDegrees = DegreesTo360(math.deg(yawDiffRadians))    
            self.desiredYawDegrees = Clamp(yawDegrees, -ARC.kMaxYaw, ARC.kMaxYaw)
            
            local pitchDiffRadians = GetAnglesDifference(GetPitchFromVector(self.targetDirection), self:GetAngles().pitch)
            local pitchDegrees = DegreesTo360(math.deg(pitchDiffRadians))
            self.desiredPitchDegrees = -Clamp(pitchDegrees, -ARC.kMaxPitch, ARC.kMaxPitch)       
            
            self.barrelYawDegrees = Slerp(self.barrelYawDegrees, self.desiredYawDegrees, ARC.kBarrelMoveRate * deltaTime)
            
        end
        
    elseif self.deployMode == ARC.kDeployMode.Deployed or self.mode == ARC.kMode.Targeting then
    
        self.desiredYawDegrees = 0
        self.desiredPitchDegrees = 0
        
        self.barrelYawDegrees = Slerp(self.barrelYawDegrees, self.desiredYawDegrees, ARC.kBarrelMoveRate * deltaTime)
        
    end
    
    self.barrelPitchDegrees = Slerp(self.barrelPitchDegrees, self.desiredPitchDegrees, ARC.kBarrelMoveRate * deltaTime)
    
end

function ARC:OnUpdatePoseParameters()

    PROFILE("ARC:OnUpdatePoseParameters")
    
    self:SetPoseParam(kArcPitchParam, self.barrelPitchDegrees)
    self:SetPoseParam(kArcYawParam , self.barrelYawDegrees)
    //self:SetPoseParam(ARC.kArcForwardTrackYawParam , self.forwardTrackYawDegrees)
    //self:SetPoseParam(ARC.kArcForwardTrackPitchParam , self.forwardTrackPitchDegrees)
    
end

function ARC:OnUpdate(deltaTime)

    PROFILE("ARC:OnUpdate")
    
    ScriptActor.OnUpdate(self, deltaTime)
    
    if Server then
        self:UpdateOrders(deltaTime)
        if self.deploytime ~= 0 and self.deploytime + ARC.kDeployAnimationTime < Shared.GetTime() and self:GetIsAlive() and self:GetIsPowered() and self.deployMode == ARC.kDeployMode.Deploying then
            self.deploytime = 0
            self:ForceDeployed()
            //Print("FORCEDEPLOYED")
        end
        if self.deployMode == ARC.kDeployMode.Undeployed and self:GetIsPowered() then
            self.deployMode = ARC.kDeployMode.Deploying
            self:TriggerEffects("arc_deploying")
            self.deploytime = Shared.GetTime()
            //Print("FORCEDEPLOYED2")
        end
    end
    
    if self.mode ~= ARC.kMode.Stationary and self.deployMode ~= ARC.kDeployMode.Deploying and self.deployMode ~= ARC.kMode.Undeploying and self.mode ~= ARC.kMode.Destroyed then
        self:UpdateAngles(deltaTime)
    end
    
    if Client then
    
        if self.lastModeClient ~= self.mode then
            self:OnModeChangedClient(self.lastModeClient, self.mode)
        end
    
        self.lastModeClient = self.mode
    
    end
    
end

function ARC:OnModeChangedClient(oldMode, newMode)

    if oldMode == ARC.kMode.Targeting and newMode ~= ARC.kMode.Targeting then
        self:TriggerEffects("arc_stop_effects")
    end

end

function ARC:OnKill(attacker, doer, point, direction)

    self:TriggerEffects("arc_stop_effects")
    
    if Server then
    
        self:ClearTargetDirection()
        self:ClearOrders()
        
        self:SetMode(ARC.kMode.Destroyed)
        
    end 
  
end

function ARC:OnUpdateAnimationInput(modelMixin)

    PROFILE("ARC:OnUpdateAnimationInput")
    
    local activity = "none"
    if self.mode == ARC.kMode.Targeting and self.deployMode == ARC.kDeployMode.Deployed then
        activity = "primary"
    end
    modelMixin:SetAnimationInput("activity", activity)
    
    local deployed = self.deployMode == ARC.kDeployMode.Deploying or self.deployMode == ARC.kDeployMode.Deployed
    modelMixin:SetAnimationInput("deployed", deployed)
    
    local move = "idle"
    if self.deployMode == ARC.kDeployMode.Undeployed then
        move = "run"
    end
    modelMixin:SetAnimationInput("move", move)
    
end

function ARC:GetShowHitIndicator()
    return false
end

Shared.LinkClassToMap("ARC", ARC.kMapName, networkVars, true)