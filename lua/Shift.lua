// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Shift.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Alien structure that allows commander to outmaneuver and redeploy forces. 
//
// Recall - Ability that lets players jump to nearest structure (or hive) under attack (cooldown 
// of a few seconds)
// Energize - Passive ability that gives energy to nearby players
// Echo - Targeted ability that lets Commander move a structure or drifter elsewhere on the map
// (even a hive or harvester!). 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Changed to remove some abilities, also to cleanup needless code.

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
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/InfestationMixin.lua")
Script.Load("lua/IdleMixin.lua")

class 'Shift' (ScriptActor)

Shift.kMapName = "shift"

Shift.kModelName = PrecacheAsset("models/alien/shift/shift.model")

local kAnimationGraph = PrecacheAsset("models/alien/shift/shift.animation_graph")
local kShiftUseDelay = 1 //Used to prevent instant TP after building.

Shift.kEnergizeSoundEffect = PrecacheAsset("sound/NS2.fev/alien/structures/shift/energize")
Shift.kEnergizeTargetSoundEffect = PrecacheAsset("sound/NS2.fev/alien/structures/shift/energize_player")
//Shift.kRecallSoundEffect = PrecacheAsset("sound/NS2.fev/alien/structures/shift/recall")


Shift.kEnergizeEffect = PrecacheAsset("cinematics/alien/shift/energize.cinematic")
Shift.kEnergizeSmallTargetEffect = PrecacheAsset("cinematics/alien/shift/energize_small.cinematic")
Shift.kEnergizeLargeTargetEffect = PrecacheAsset("cinematics/alien/shift/energize_large.cinematic")

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
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(InfestationMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)

function Shift:OnCreate()

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
    InitMixin(self, ResearchMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, UmbraMixin)
	InitMixin(self, DissolveMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    self:SetUpdates(false)
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
    
end

function Shift:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(Shift.kModelName, kAnimationGraph)
    InitMixin(self, InfestationMixin)
    if Server then
    
        InitMixin(self, StaticTargetMixin)
    
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

function Shift:GetCanBeUsedConstructed()
    return true
end

function Shift:GetCanBeUsed(player, useSuccessTable)
    if self:GetCanConstruct(player) or (HasMixin(player, "Redeploy") and player:GetCanRedeploy()) then
        useSuccessTable.useSuccess = true
    else
        useSuccessTable.useSuccess = false
    end
end

function Shift:EnergizeInRange()

    if self:GetIsBuilt() and self:GetIsAlive() then
    
        local energizeAbles = GetEntitiesWithMixinForTeamWithinRange("Energize", self:GetTeamNumber(), self:GetOrigin(), kEnergizeRange)
        
        for _, entity in ipairs(energizeAbles) do
        
            if entity ~= self then
                entity:Energize(self)
            end
            
        end
    
    end
    
    return self:GetIsAlive()
    
end

function Shift:GetDamagedAlertId()
    return kTechId.AlienAlertStructureUnderAttack
end

function Shift:GetReceivesStructuralDamage()
    return true
end

function Shift:GetShowOrderLine()
    return true
end

function Shift:OnUse(player, elapsedTime, useSuccessTable)
    local hasupg, level = GetHasRedeploymentUpgrade(player)
	local completedelay = (Shared.GetTime() - (self.constructioncomplete or 0)) > kShiftUseDelay
    if hasupg and level > 0 and self:GetIsBuilt() and self:GetTeamNumber() == player:GetTeamNumber() and HasMixin(player, "Redeploy") and completedelay then
        player:Redeploy(level)
    end
end

if Server then
    
    function Shift:OnConstructionComplete()
        local team = self:GetTeam()
        if team and team.OnUpgradeChamberConstructed then
			self:AddTimedCallback(Shift.EnergizeInRange, kEnergizeUpdateRate)
            team:OnUpgradeChamberConstructed(self)
        end
		self.constructioncomplete = Shared.GetTime()
    end
    
    function Shift:OnKill(attacker, doer, point, direction)
    
        ScriptActor.OnKill(self, attacker, doer, point, direction)
        
        local team = self:GetTeam()
        if team and team.OnUpgradeChamberDestroyed then
            team:OnUpgradeChamberDestroyed(self)
        end
        
    end
    
end

Shared.LinkClassToMap("Shift", Shift.kMapName, networkVars)