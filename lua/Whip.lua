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
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/InfestationMixin.lua")
Script.Load("lua/IdleMixin.lua")

class 'Whip' (ScriptActor)

Whip.kMapName = "whip"

Whip.kModelName = PrecacheAsset("models/alien/whip/whip.model")
Whip.kAnimationGraph = PrecacheAsset("models/alien/whip/whip.animation_graph")

local kEmpowerRange = 6
local kEmpowerThinkTime = 2

Whip.kWhipBallParam = "ball"

local networkVars = { }

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
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(InfestationMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)

Shared.PrecacheSurfaceShader("models/alien/whip/ball.surface_shader")

function Whip:OnCreate()

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
    InitMixin(self, RagdollMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, UmbraMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)    
    end
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
    
end

function Whip:OnInitialized()

    ScriptActor.OnInitialized(self)

    self:SetModel(Whip.kModelName, Whip.kAnimationGraph)
    InitMixin(self, InfestationMixin)
    self:SetUpdates(true)
    
    if Server then
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
        
    end
    
    InitMixin(self, IdleMixin)
    
end

function Whip:GetDamagedAlertId()
    return kTechId.AlienAlertStructureUnderAttack
end

function Whip:GetCanSleep()
    return true
end

function Whip:GetMinimumAwakeTime()
    return 10
end

function Whip:GetDeathIconIndex()
    return kDeathMessageIcon.Whip
end

function Whip:GetReceivesStructuralDamage()
    return true
end

function Whip:OnUpdatePoseParameters()
    self:SetPoseParam(Whip.kWhipBallParam, 0) 
end

function Whip:GetCanGiveDamageOverride()
    return true
end

function Whip:GetIsRooted()
    return self.rooted
end

function Whip:EmpowerInRange()

    if self:GetIsBuilt() and self:GetIsAlive() then
    
        local empents = GetEntitiesWithMixinForTeamWithinRange("Empower", self:GetTeamNumber(), self:GetOrigin(), kEmpowerRange)
        
        for _, entity in ipairs(empents) do
        
            if entity ~= self then
                entity:Empower()
            end
            
        end
    
    end
    
    return self:GetIsAlive()
    
end

function Whip:OnUpdateAnimationInput(modelMixin)

    PROFILE("Whip:OnUpdateAnimationInput")  
    
    modelMixin:SetAnimationInput("activity", "none" )
    modelMixin:SetAnimationInput("rooted", true)
    modelMixin:SetAnimationInput("move", "idle")
    
end

function Whip:GetEyePos()
    return self:GetOrigin() + self:GetCoords().yAxis * 1.8
end

function Whip:GetShowHitIndicator()
    return false
end

if Server then
            
    function Whip:OnConstructionComplete()
    
        local team = self:GetTeam()
        if team and team.OnUpgradeChamberConstructed then
			self:AddTimedCallback(Whip.EmpowerInRange, kEmpowerThinkTime)
            team:OnUpgradeChamberConstructed(self)
        end
        
    end
    
    function Whip:OnKill(attacker, doer, point, direction)
    
        ScriptActor.OnKill(self, attacker, doer, point, direction)
        
        local team = self:GetTeam()
        if team and team.OnUpgradeChamberDestroyed then
            team:OnUpgradeChamberDestroyed(self)
        end
    
    end
    
end

function Whip:GetCanBeUsed(player, useSuccessTable)
    if not self:GetCanConstruct(player) then
        useSuccessTable.useSuccess = false
    else
        useSuccessTable.useSuccess = true
    end
end

Shared.LinkClassToMap("Whip", Whip.kMapName, networkVars)