// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Whip.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Alien structure that provides attacks nearby players with area of effect ballistic attack.
// Also gives attack/hurt capabilities to the commander. Range should be just shorter than 
// marine sentries.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/UpgradableMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/DoorMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/StaticTargetMixin.lua")
Script.Load("lua/TargetCacheMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/HasUmbraMixin.lua")

class 'Whip' (ScriptActor)

Whip.kMapName = "whip"

Whip.kModelName = PrecacheAsset("models/alien/whip/whip.model")
Whip.kAnimationGraph = PrecacheAsset("models/alien/whip/whip.animation_graph")

Whip.kScanThinkInterval = .1
Whip.kROF = 2.0
Whip.kFov = 360
Whip.kTargetCheckTime = .3
Whip.kRange = 6
Whip.kAreaEffectRadius = 3
Whip.kDamage = 50

Whip.kWhipBallParam = "ball"

local networkVars =
{
    attackYaw = "integer (0 to 360)",
    slapping = "private boolean"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(UpgradableMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(HasUmbraMixin, networkVars)

if Server then

    Script.Load("lua/AiAttacksMixin.lua")
    Script.Load("lua/AiSlapAttackType.lua")
    
end

Shared.PrecacheSurfaceShader("models/alien/whip/ball.surface_shader")

function Whip:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, UpgradableMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, CloakableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, DissolveMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, HasUmbraMixin)
    
    self.attackYaw = 0 
    self.slapping = false
    
    if Server then
    else
        InitMixin(self, CommanderGlowMixin)    
    end
    
    self:SetLagCompensated(true)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
    
end

function Whip:OnInitialized()

    ScriptActor.OnInitialized(self)

    InitMixin(self, DoorMixin)

    self:SetModel(Whip.kModelName, Whip.kAnimationGraph)
    
    self:SetUpdates(true)
    
    if Server then
    
        InitMixin(self, StaticTargetMixin)
    
        // The AiAttacks create TargetSelectors, so the TargetCacheMixin is required.
        InitMixin(self, TargetCacheMixin)
        
        InitMixin(self, AiAttacksMixin)
        
        // The various attacks are added here.
        self.slapAttack = AiSlapAttackType():Init(self)
        self:AddAiAttackType(self.slapAttack)
        
        self:UpdateAiAttacks()
        
        InitMixin(self, SleeperMixin)
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
        
    end
    
end

function Whip:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    if Server then
        self.movingSound = nil
    end
    
end

function Whip:GetDamagedAlertId()
    return kTechId.AlienAlertStructureUnderAttack
end

function Whip:GetCanSleep()
    return false // not self.moving and not self.whackAttack:GetTarget()
end

function Whip:GetMinimumAwakeTime()
    return 10
end

// Used for targeting
function Whip:GetFov()
    return Whip.kFov
end

function Whip:GetDeathIconIndex()
    return kDeathMessageIcon.Whip
end

function Whip:GetReceivesStructuralDamage()
    return true
end

function Whip:OnUpdatePoseParameters()

    self:SetPoseParam("attack_yaw", self.attackYaw)
    self:SetPoseParam(Whip.kWhipBallParam, 0)
    
end

function Whip:GetCanGiveDamageOverride()
    return true
end

function Whip:GetIsRooted()
    return self.rooted
end

function Whip:OnUpdate(deltaTime)

    PROFILE("Whip:OnUpdate")
    ScriptActor.OnUpdate(self, deltaTime)
    
    if Server then        

        self:UpdateOrders(deltaTime)
    end
    
end

function Whip:OnUpdateAnimationInput(modelMixin)

    PROFILE("Whip:OnUpdateAnimationInput")  
    
    modelMixin:SetAnimationInput("activity", ((self.slapping and "primary") or "none" ))
    modelMixin:SetAnimationInput("rooted", true)
    modelMixin:SetAnimationInput("move", "idle")
    
end

function Whip:GetEyePos()
    return self:GetOrigin() + self:GetCoords().yAxis * 1.8
end

function Whip:GetShowHitIndicator()
    return false
end

if Client then

    function Whip:OnTag(tagName)

        PROFILE("WHIP:OnTag")
        
        if tagName == "attack_start" then
            self:TriggerEffects("whip_attack_start")        
        end
        
    end

elseif Server then
        
    function Whip:UpdateOrders(deltaTime)
        self:UpdateAiAttacks(deltaTime) 
    end

    function Whip:SetAttackYaw(toPoint)

        // Update our attackYaw to aim at our current target
        local attackDir = GetNormalizedVector(toPoint - self:GetModelOrigin())
        
        // This is negative because of how model is set up (spins clockwise)
        local attackYawRadians = -math.atan2(attackDir.x, attackDir.z)
        
        // Factor in the orientation of the whip.
        attackYawRadians = attackYawRadians + self:GetAngles().yaw
        
        self.attackYaw = DegreesTo360(math.deg(attackYawRadians))
        
        if self.attackYaw < 0 then
            self.attackYaw = self.attackYaw + 360
        end

    end
    
    function Whip:OnAiAttackStart(attackType)
        local target = attackType:GetTarget()
        assert(not target or HasMixin(target, "Target"))
        local point = target and target:GetEngagementPoint() or attackType.targetLocation
        self:SetAttackYaw(point)
        self.slapping = attackType.slapping == true 
    end

    function Whip:OnAiAttackEnd(attackType)
        self.slapping = false
    end

    function Whip:OnAiAttackHit(attackType)
        self.slapping = false 
    end

    function Whip:OnAiAttackHitFail(attackType)
        self.slapping = false
    end

end

function Whip:GetCanBeUsed(player, useSuccessTable)
    if not self:GetCanConstruct(player) then
        useSuccessTable.useSuccess = false
    else
        useSuccessTable.useSuccess = true
    end
end

Shared.LinkClassToMap("Whip", Whip.kMapName, networkVars, true)