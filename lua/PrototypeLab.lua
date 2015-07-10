// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PrototypeLab.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed concept of logging in a related netvars/functions.

Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/RecycleMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/SleeperMixin.lua")

local kAnimationGraph = PrecacheAsset("models/marine/prototype_lab/prototype_lab.animation_graph")

class 'PrototypeLab' (ScriptActor)

PrototypeLab.kMapName = "prototypelab"

PrototypeLab.kModelName = PrecacheAsset("models/marine/prototype_lab/prototype_lab.model")

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(RecycleMixin, networkVars) 
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)

function PrototypeLab:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, RecycleMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, PowerConsumerMixin)
    InitMixin(self, ParasiteMixin)
    
    if Server then
        InitMixin(self, SleeperMixin)
    elseif Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    self:SetUpdates(true)
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
    
end

function PrototypeLab:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(PrototypeLab.kModelName, kAnimationGraph)
    
    InitMixin(self, WeldableMixin)

    if Server then    

        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, StaticTargetMixin)
        
    elseif Client then
        InitMixin(self, UnitStatusMixin)
    end
    
end

function PrototypeLab:GetTechButtons(techId)
    return { kTechId.JetpackTech, kTechId.HeavyArmorTech, kTechId.None, kTechId.None,
                  kTechId.None, kTechId.None, kTechId.None, kTechId.None }    
end

function PrototypeLab:GetDamagedAlertId()
    return kTechId.MarineAlertStructureUnderAttack
end

function PrototypeLab:GetReceivesStructuralDamage()
    return true
end

function PrototypeLab:GetCanSleep()
    return true
end

Shared.LinkClassToMap("PrototypeLab", PrototypeLab.kMapName, networkVars)