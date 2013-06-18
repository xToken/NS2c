// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommandStructure.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed arrows of doom

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
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

class 'CommandStructure' (ScriptActor)
CommandStructure.kMapName = "commandstructure"

if Server then
    Script.Load("lua/CommandStructure_Server.lua")
end

local networkVars =
{
    occupied = "boolean",
    commanderId = "entityid",
    attachedId = "entityid",
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
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

function CommandStructure:OnCreate()

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
    InitMixin(self, CombatMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, ObstacleMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    self.occupied = false
    self.commanderId = Entity.invalidId
    
    self:SetLagCompensated(true)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
    
end

function CommandStructure:GetReceivesStructuralDamage()
    return true
end

function CommandStructure:GetIsOccupied()
    return self.occupied
end

function CommandStructure:GetEffectParams(tableParams)
    tableParams[kEffectFilterOccupied] = self.occupied
end

if Client then
    
    function CommandStructure:OnUpdateRender()
    
        local player = Client.GetLocalPlayer()
        local now = Shared.GetTime()
        
        self.lastTimeOccupied = self.lastTimeOccupied or now
        if self:GetIsOccupied() then
            self.lastTimeOccupied = now
        end

    end
    
    function CommandStructure:OnDestroy()
    
        ScriptActor.OnDestroy(self)
                
    end
    
end

function CommandStructure:OnUpdateAnimationInput(modelMixin)

    PROFILE("CommandStructure:OnUpdateAnimationInput")
    modelMixin:SetAnimationInput("occupied", self.occupied)
    
end

function CommandStructure:GetCanBeUsedConstructed()
    return not self:GetIsOccupied()
end

// allow players to enter the hives before game start to signal that they want to command
function CommandStructure:GetUseAllowedBeforeGameStart()
    return true
end

Shared.LinkClassToMap("CommandStructure", CommandStructure.kMapName, networkVars, true)