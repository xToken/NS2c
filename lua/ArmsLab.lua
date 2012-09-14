// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ArmsLab.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/RecycleMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")

class 'ArmsLab' (ScriptActor)
ArmsLab.kMapName = "armslab"

ArmsLab.kModelName = PrecacheAsset("models/marine/arms_lab/arms_lab.model")
local kAnimationGraph = PrecacheAsset("models/marine/arms_lab/arms_lab.animation_graph")

local function SendArmorUpdateNotification(self)

    if Server then

        local team = self:GetTeam()
        if team then
            team:OnArmsLabChanged()
        end
        
    end    

end

local networkVars =
{
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(RecycleMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)

function ArmsLab:OnCreate()

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
    InitMixin(self, CombatMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, ParasiteMixin)
        
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
    
end

function ArmsLab:OnInitialized()

    ScriptActor.OnInitialized(self)
    
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
    
    self:SetModel(ArmsLab.kModelName, kAnimationGraph)

end

function ArmsLab:GetReceivesStructuralDamage()
    return true
end

function ArmsLab:GetDamagedAlertId()
    return kTechId.MarineAlertStructureUnderAttack
end

function ArmsLab:GetTechButtons(techId)

    return { kTechId.Weapons1, kTechId.Weapons2, kTechId.Weapons3, kTechId.CatPackTech, //kTechId.CatPackTech,
             kTechId.Armor1, kTechId.Armor2, kTechId.Armor3, kTechId.None }

end

function ArmsLab:OnUpdateAnimationInput(modelMixin)

    PROFILE("ArmsLab:OnUpdateAnimationInput")
	modelMixin:SetAnimationInput("powered", true)
    
end

function ArmsLab:OnConstructionComplete()
    SendArmorUpdateNotification(self)
end

if Server then
    
    function ArmsLab:OnResearchComplete(researchId)

        if researchId == kTechId.Armor1 or researchId == kTechId.Armor2 or researchId == kTechId.Armor3 then
            SendArmorUpdateNotification(self)       
        end 
        
    end
    
    function ArmsLab:UpdateTechAvailability()
        SendArmorUpdateNotification(self) 
    end

end

function ArmsLab:OnDestroy()

    ScriptActor.OnDestroy(self)    
    SendArmorUpdateNotification(self)

end

Shared.LinkClassToMap("ArmsLab", ArmsLab.kMapName, networkVars)