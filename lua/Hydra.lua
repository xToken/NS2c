// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Hydra.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Structure droppable by Gorge that attacks enemy targets with clusters of shards. Can be built
// on walls.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed some uneeded mixins, infestation requirements

Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/TargetCacheMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/TriggerMixin.lua")
Script.Load("lua/TargettingMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/InfestationMixin.lua")
Script.Load("lua/IdleMixin.lua")

class 'Hydra' (ScriptActor)

Hydra.kMapName = "hydra"

Hydra.kModelName = PrecacheAsset("models/alien/hydra/hydra.model")
Hydra.kModelNameShadow = PrecacheAsset("models/alien/hydra/hydra_shadow.model")
Hydra.kAnimationGraph = PrecacheAsset("models/alien/hydra/hydra.animation_graph")

Hydra.kSpikeSpeed = 50
Hydra.kSpread = Math.Radians(12)
Hydra.kTargetVelocityFactor = 2.0 // Don't always hit very fast moving targets (jetpackers).
Hydra.kRange = 17.78              // From NS1 (also "alert" range)
Hydra.kDamage = kHydraDamage
Hydra.kAlertCheckInterval = 2
Hydra.kFov = 360
kHydraDiggestDuration = 1
kHydraScale = 1.6

if Server then
    Script.Load("lua/Hydra_Server.lua")
end

local networkVars =
{
    alerting = "boolean",
    attacking = "boolean",
    hydraParentId = "entityid"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(InfestationMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)

function Hydra:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, CloakableMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, UmbraMixin)
    
    self.alerting = false
    self.attacking = false
    self.hydraParentId = Entity.invalidId
	self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
	
end

function Hydra:OnInitialized()

    if Server then
    
        ScriptActor.OnInitialized(self)
        
        self:SetModel(Hydra.kModelName, Hydra.kAnimationGraph)
       
        self:SetUpdates(true)
        
        // TargetSelectors require the TargetCacheMixin for cleanup.
        InitMixin(self, TargetCacheMixin)
        
        self.targetSelector = TargetSelector():Init(
                self,
                Hydra.kRange, 
                true,
                { kAlienStaticTargets, kAlienMobileTargets })   
        
        
        InitMixin(self, SleeperMixin)
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        self:TriggerEffects("spawn", {effecthostcoords = self:GetCoords()} )
        
        InitMixin(self, StaticTargetMixin)
        
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
        
    end
    
    InitMixin(self, InfestationMixin)
    InitMixin(self, IdleMixin)
    
end

function Hydra:GetBarrelPoint()
    return self:GetEyePos()
end

function Hydra:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    if Client then
    
        Client.DestroyRenderDecal(self.decal)
        self.decal = nil
        
    end
    
end

function Hydra:SetVariant(gorgeVariant)

    if gorgeVariant == kGorgeVariant.shadow then
        self:SetModel(Hydra.kModelNameShadow, Hydra.kAnimationGraph)
    else
        self:SetModel(Hydra.kModelName, Hydra.kAnimationGraph)
    end
    
end
function Hydra:GetCanDie(byDeathTrigger)
    return not byDeathTrigger
end

function Hydra:GetCanAutoBuild()
    return true
end

function Hydra:GetShowHitIndicator()
    return false
end

function Hydra:GetTracerEffectName()
    return kSpikeTracerEffectName
end

function Hydra:GetTracerResidueEffectName()
    return kSpikeTracerResidueEffectName
end

function Hydra:GetReceivesStructuralDamage()
    return true
end

function Hydra:GetDamagedAlertId()
    return kTechId.AlienAlertStructureUnderAttack
end

function Hydra:GetCanSleep()
    return not self.alerting and not self.attacking
end

function Hydra:GetMinimumAwakeTime()
    return 10
end

function Hydra:GetFov()
    return Hydra.kFov
end

function Hydra:GetCanBeUsed(player, useSuccessTable)
    if not self:GetCanConstruct(player) then
        useSuccessTable.useSuccess = false
    else
        useSuccessTable.useSuccess = true
    end
end

function Hydra:GetCanBeUsedConstructed()
    return false
end    

function Hydra:GetEyePos()
    return self:GetOrigin() + self:GetViewOffset()
end

/**
 * Put the eye up roughly 100 cm.
 */
function Hydra:GetViewOffset()
    return self:GetCoords().yAxis * 1
end

function Hydra:GetCanGiveDamageOverride()
    return true
end

function Hydra:OnUpdateAnimationInput(modelMixin)

    PROFILE("Hydra:OnUpdateAnimationInput")

    modelMixin:SetAnimationInput("attacking", self.attacking)
    modelMixin:SetAnimationInput("alerting", self.alerting)
    
end

function Hydra:OnAdjustModelCoords(modelCoords)
    local coords = modelCoords
    coords.xAxis = coords.xAxis * kHydraScale
    coords.yAxis = coords.yAxis * kHydraScale
    coords.zAxis = coords.zAxis * kHydraScale
    return coords
end

local kEngageOffset = Vector(0, 0.4, 0)
function Hydra:GetEngagementPointOverride()
    return self:GetOrigin() + kEngageOffset
end

Shared.LinkClassToMap("Hydra", Hydra.kMapName, networkVars)