// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PrototypeLab.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ModelMixin.lua")
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
Script.Load("lua/AlienDetectableMixin.lua")
Script.Load("lua/ParasiteMixin.lua")

local kAnimationGraph = PrecacheAsset("models/marine/prototype_lab/prototype_lab.animation_graph")

class 'PrototypeLab' (ScriptActor)

PrototypeLab.kMapName = "prototypelab"

PrototypeLab.kThinkTime = 2
// Players can use menu and be supplied by PrototypeLab inside this range
PrototypeLab.kResupplyUseRange = 2.0

PrototypeLab.kModelName = PrecacheAsset("models/marine/prototype_lab/prototype_lab.model")

if Server then
    Script.Load("lua/PrototypeLab_Server.lua")
elseif Client then
    Script.Load("lua/PrototypeLab_Client.lua")
end    

local networkVars =
{
    // How far out the arms are for animation (0-1)
    loggedInEast = "boolean",
    loggedInNorth = "boolean",
    loggedInSouth = "boolean",
    loggedInWest = "boolean"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
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
AddMixinNetworkVars(AlienDetectableMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)

function PrototypeLab:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
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
    InitMixin(self, AlienDetectableMixin)
    InitMixin(self, ParasiteMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
    
end

function PrototypeLab:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(PrototypeLab.kModelName, kAnimationGraph)
    
    InitMixin(self, WeldableMixin)
    
    self.loginEastAmount = 0
    self.loginNorthAmount = 0
    self.loginWestAmount = 0
    self.loginSouthAmount = 0
    
    self.timeScannedEast = 0
    self.timeScannedNorth = 0
    self.timeScannedWest = 0
    self.timeScannedSouth = 0

    self.loginNorthAmount = 0
    self.loginEastAmount = 0
    self.loginSouthAmount = 0
    self.loginWestAmount = 0

    if Server then    
    
        self.loggedInArray = {false, false, false, false}
        self:SetNextThink(PrototypeLab.kThinkTime)
        
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
                  kTechId.Jetpack, kTechId.HeavyArmor, kTechId.None, kTechId.None }    
end

function PrototypeLab:UpdatePrototypeLabAnim(extension, loggedIn, scanTime, timePassed)

    local loggedInName = "log_" .. extension
    local loggedInParamValue = ConditionalValue(loggedIn, 1, 0)
    
    if extension == "n" then
    
        self.loginNorthAmount = Clamp(Slerp(self.loginNorthAmount, loggedInParamValue, timePassed*2), 0, 1)
        self:SetPoseParam(loggedInName, self.loginNorthAmount)
        
    elseif extension == "s" then
    
        self.loginSouthAmount = Clamp(Slerp(self.loginSouthAmount, loggedInParamValue, timePassed*2), 0, 1)
        self:SetPoseParam(loggedInName, self.loginSouthAmount)
    elseif extension == "e" then
        self.loginEastAmount = Clamp(Slerp(self.loginEastAmount, loggedInParamValue, timePassed*2), 0, 1)
        self:SetPoseParam(loggedInName, self.loginEastAmount)
    elseif extension == "w" then
        self.loginWestAmount = Clamp(Slerp(self.loginWestAmount, loggedInParamValue, timePassed*2), 0, 1)
        self:SetPoseParam(loggedInName, self.loginWestAmount)
    end
    
    local scannedName = "scan_" .. extension
    local scannedParamValue = ConditionalValue(scanTime == 0 or (Shared.GetTime() > scanTime + 3), 0, 1)
    self:SetPoseParam(scannedName, scannedParamValue)
    
end

function PrototypeLab:GetDamagedAlertId()
    return kTechId.MarineAlertStructureUnderAttack
end

function PrototypeLab:OnUpdate(deltaTime)

    if Client then
        self:UpdatePrototypeLabWarmUp()
    end
    
    ScriptActor.OnUpdate(self, deltaTime)
    
end

function PrototypeLab:GetItemList()

    return nil
    
end

// TechName, UpgradeList, Max number of upgrades, upgrades mutual exlusive
function PrototypeLab:GetUpgradeList()


    
end

function PrototypeLab:GetReceivesStructuralDamage()
    return true
end

function PrototypeLab:OnUpdateAnimationInput(modelMixin)

    PROFILE("PrototypeLab:OnUpdateAnimationInput")
	modelMixin:SetAnimationInput("powered", true)
    
end


Shared.LinkClassToMap("PrototypeLab", PrototypeLab.kMapName, networkVars)