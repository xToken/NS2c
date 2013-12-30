//NS2c
//Renamed to SiegeCannon
//Adjusted sieges to be constructed and require nearby TF

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
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
Script.Load("lua/IdleMixin.lua")

class 'SiegeCannon' (ScriptActor)

SiegeCannon.kMapName = "siegecannon"

SiegeCannon.kModelName = PrecacheAsset("models/marine/arc/arc.model")
local kAnimationGraph = PrecacheAsset("models/marine/arc/arc.animation_graph")

// Animations
local kSiegeCannonPitchParam = "arc_pitch"
local kSiegeCannonYawParam = "arc_yaw"
local kBarrelMoveRate         = 150
local kMaxPitch               = 45
local kMaxYaw                 = 180
local kDeployAnimationTime    = 4

SiegeCannon.kMode = enum( {'Inactive', 'Active', 'Targeting' } )

if Server then
    Script.Load("lua/SiegeCannon_Server.lua")
end

local networkVars =
{
    // ARCs can only fire when deployed and can only move when not deployed
    mode = "enum SiegeCannon.kMode",
    
    barrelYawDegrees = "compensated float",
    barrelPitchDegrees = "compensated float",
    
    // So we can update angles and pose parameters smoothly on client
    targetDirection = "vector",
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(UpgradableMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(RecycleMixin, networkVars)
AddMixinNetworkVars(TurretMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)

function SiegeCannon:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, UpgradableMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
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
    InitMixin(self, ResearchMixin)
    InitMixin(self, RecycleMixin)
    InitMixin(self, TurretMixin)

    if Server then
        InitMixin(self, SleeperMixin)
    elseif Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    self:SetLagCompensated(true)
    
end

function SiegeCannon:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    InitMixin(self, WeldableMixin)

    self:SetModel(SiegeCannon.kModelName, kAnimationGraph)
    
    if Server then
	
        // TargetSelectors require the TargetCacheMixin for cleanup.
        InitMixin(self, TargetCacheMixin)
        
        // Prioritize targetting non-Eggs first.
        self.targetSelector = TargetSelector():Init(
                self,
                kSiegeCannonRange,
                false, 
                { kMarineStaticTargets, kMarineMobileTargets },
                { self.FilterTarget(self) },
                { function(target) return target:isa("Hive") end })

        
        self:SetMode(SiegeCannon.kMode.Inactive)
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
		
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
    
    end
    
    InitMixin(self, IdleMixin)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
    self:SetUpdates(true)
    
end

function SiegeCannon:GetHealthbarOffset()
    return 0.7
end 

function SiegeCannon:GetIsIdle()
    return self.mode == SiegeCannon.kMode.Active
end

function SiegeCannon:GetReceivesStructuralDamage()
    return true
end

function SiegeCannon:GetCanSleep()
    return self.mode == SiegeCannon.kMode.Inactive
end

function SiegeCannon:GetDeathIconIndex()
    return kDeathMessageIcon.SiegeCannon
end

function SiegeCannon:OnConstructionComplete()
    self:SetRequiresAdvanced()
end

/**
 * Put the eye up 1 m.
 */
function SiegeCannon:GetViewOffset()
    return self:GetCoords().yAxis * 1.0
end

function SiegeCannon:GetEyePos()
    return self:GetOrigin() + self:GetViewOffset()
end

function SiegeCannon:GetPlayIdleSound()
    return self.mode == SiegeCannon.kMode.Active and self:GetTarget() == nil
end

function SiegeCannon:GetActivationTechAllowed(techId)
    
    if techId == kTechId.Attack then
        return self.mode == SiegeCannon.kMode.Active
    elseif techId == kTechId.Stop then
        return self.mode == SiegeCannon.kMode.Targeting
    end
    return true
    
end

function SiegeCannon:GetTechButtons(techId)
    return  { kTechId.Attack, kTechId.Stop, kTechId.None, kTechId.None,
          kTechId.None, kTechId.None, kTechId.None, kTechId.None }
end

function SiegeCannon:GetInAttackMode()
    return self.mode == SiegeCannon.kMode.Active and self:GetIsPowered()
end

function SiegeCannon:GetCanGiveDamageOverride()
    return true
end

function SiegeCannon:GetFov()
    return 360
end

function SiegeCannon:GetEffectParams(tableParams)
    tableParams[kEffectFilterDeployed] = self:GetInAttackMode()
end

function SiegeCannon:FilterTarget()

    local attacker = self
    return function (target, targetPosition) return attacker:GetCanFireAtTargetActual(target, targetPosition) end
    
end

//
// Do a complete check if the target can be fired on. 
//
function SiegeCannon:GetCanFireAtTarget(target, targetPoint)    

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

function SiegeCannon:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

//
// the checks made in GetCanFireAtTarget has already been made by the TargetCache, this
// is the extra, actual target filtering done.
//
function SiegeCannon:GetCanFireAtTargetActual(target, targetPoint)    

    if not target.GetReceivesStructuralDamage or not target:GetReceivesStructuralDamage() then        
        return false
    end

    if not target:GetIsSighted() and not GetIsTargetDetected(target) then
        return false
    end
    
    local distToTarget = (target:GetOrigin() - self:GetOrigin()):GetLengthXZ()
    if (distToTarget > kSiegeCannonRange) then
        return false
    end
    
    return true
    
end

function SiegeCannon:UpdateAngles(deltaTime)

    if not GetIsUnitActive(self) then        
        return
    end
    
    if self.mode == SiegeCannon.kMode.Targeting and self.targetDirection then
    
        local yawDiffRadians = GetAnglesDifference(GetYawFromVector(self.targetDirection), self:GetAngles().yaw)
        local yawDegrees = DegreesTo360(math.deg(yawDiffRadians))    
        self.desiredYawDegrees = Clamp(yawDegrees, -kMaxYaw, kMaxYaw)
        
        local pitchDiffRadians = GetAnglesDifference(GetPitchFromVector(self.targetDirection), self:GetAngles().pitch)
        local pitchDegrees = DegreesTo360(math.deg(pitchDiffRadians))
        self.desiredPitchDegrees = -Clamp(pitchDegrees, -kMaxPitch, kMaxPitch)       
        
        self.barrelYawDegrees = Slerp(self.barrelYawDegrees, self.desiredYawDegrees, kBarrelMoveRate * deltaTime)
        
    else
    
        self.desiredYawDegrees = 0
        self.desiredPitchDegrees = 0 
        self.barrelYawDegrees = Slerp(self.barrelYawDegrees, self.desiredYawDegrees, kBarrelMoveRate * deltaTime)
        
    end
    
    self.barrelPitchDegrees = Slerp(self.barrelPitchDegrees, self.desiredPitchDegrees, kBarrelMoveRate * deltaTime)
    
end

function SiegeCannon:OnUpdatePoseParameters()

    PROFILE("SiegeCannon:OnUpdatePoseParameters")
    
    self:SetPoseParam(kSiegeCannonPitchParam, self.barrelPitchDegrees)
    self:SetPoseParam(kSiegeCannonYawParam , self.barrelYawDegrees)
    
end

local function PerformAttack(self)

    if self.targetPosition and self.mode == SiegeCannon.kMode.Targeting then
    
        self:TriggerEffects("sc_firing")    
        // Play big hit sound at origin
        
        // don't pass triggering entity so the sound / cinematic will always be relevant for everyone
        GetEffectManager():TriggerEffects("sc_hit_primary", {effecthostcoords = Coords.GetTranslation(self.targetPosition)})
        
        local hitEntities = GetEntitiesWithMixinWithinRange("Live", self.targetPosition, kSiegeCannonSplashRadius)

        // Do damage to every target in range
        RadiusDamage(hitEntities, self.targetPosition, kSiegeCannonSplashRadius, kSiegeCannonDamage, self, true)

        // Play hit effect on each
        for index, target in ipairs(hitEntities) do
        
            if HasMixin(target, "Effects") then
                target:TriggerEffects("sc_hit_secondary")
            end 
           
        end
        
        TEST_EVENT("Siege Cannon attacked entity")
        
    end
    
    // reset target position and acquire new target
    self.targetPosition = nil
    
end

function SiegeCannon:OnTag(tagName)

    PROFILE("SiegeCannon:OnTag")
    
    if tagName == "fire_start" and Server then
        PerformAttack(self)
    elseif tagName == "target_start" and self.mode == SiegeCannon.kMode.Targeting then
        self:TriggerEffects("sc_charge")
    elseif tagName == "attack_end" then
        if Server and self.mode == SiegeCannon.kMode.Targeting then
            self:SetMode(SiegeCannon.kMode.Active)
        end
        self:TriggerEffects("sc_stop_effects")
    end
    
end

function SiegeCannon:OnUpdate(deltaTime)

    PROFILE("SiegeCannon:OnUpdate")
    
    ScriptActor.OnUpdate(self, deltaTime)
    
    if Server then
        self:UpdateOrders(deltaTime)
    end
    
    self:UpdateAngles(deltaTime)
    
end

function SiegeCannon:OnKill(attacker, doer, point, direction)

    if Server then
        self:ClearTargetDirection()
    end 
  
end

function SiegeCannon:OnUpdateAnimationInput(modelMixin)

    PROFILE("SiegeCannon:OnUpdateAnimationInput")
    
    local activity = "none"
    local deployed = false
    local move = "idle"
    
    if self.mode == SiegeCannon.kMode.Targeting then
        activity = "primary"
    end
    
    if self.mode == SiegeCannon.kMode.Active or self.mode == SiegeCannon.kMode.Targeting then
        deployed = true
        move = "idle"
    else
        deployed = false
        move = "run"
    end
    
    modelMixin:SetAnimationInput("activity", activity)
    modelMixin:SetAnimationInput("deployed", deployed)
    modelMixin:SetAnimationInput("move", move)
    
end

function SiegeCannon:GetShowHitIndicator()
    return false
end

function GetCheckSiegeCannonLimit(techId, origin, normal, commander)

    local location = GetLocationForPoint(origin)
    local locationName = location and location:GetName() or nil
    local cannons = 0
    
    if locationName then
    
        validRoom = true
        
        for index, sc in ientitylist(Shared.GetEntitiesWithClassname("SiegeCannon")) do
            
            if sc:GetLocationName() == locationName then
                cannons = cannons + 1
            end
            
        end
    
    end
    
    return cannons < kSiegeCannonsPerFactory
    
end

Shared.LinkClassToMap("SiegeCannon", SiegeCannon.kMapName, networkVars, true)