// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Crag.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Alien structure that gives the commander defense and protection abilities.
//
// Passive ability - heals nearby players and structures
// Triggered ability - emit defensive umbra (8 seconds)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed unneeded mixins, changed healing to callback

Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
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
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/TargetCacheMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/InfestationMixin.lua")
Script.Load("lua/IdleMixin.lua")

class 'Crag' (ScriptActor)

Crag.kMapName = "crag"

Crag.kModelName = PrecacheAsset("models/alien/crag/crag.model")

Crag.kAnimationGraph = PrecacheAsset("models/alien/crag/crag.animation_graph")

// Same as NS1
Crag.kHealRadius = 10
Crag.kHealAmount = 10
Crag.kPercentHeal = 0.03
Crag.kMaxTargets = 3
Crag.kHealInterval = 2.0

local networkVars =
{
    // For client animations
    healingActive = "boolean"
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
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(InfestationMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)

function Crag:OnCreate()

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
    InitMixin(self, CloakableMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, CombatMixin)    
    InitMixin(self, UmbraMixin)
    
    self.healingActive = false
    
    if Client then    
        InitMixin(self, CommanderGlowMixin)    
    end
    
    self:SetUpdates(true)
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
    
end

function Crag:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(Crag.kModelName, Crag.kAnimationGraph)

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

function Crag:GetDamagedAlertId()
    return kTechId.AlienAlertStructureUnderAttack
end

function Crag:HealInRange()

    if self:GetIsBuilt() and self:GetIsAlive() then
    
        local healtargets = GetEntitiesWithMixinForTeamWithinRange("Live", self:GetTeamNumber(), self:GetOrigin(), Crag.kHealRadius)
        local entsHealed = 0
        for _, entity in ipairs(healtargets) do
       
            if entity ~= self and (entity.lasthealed == nil or entity.lasthealed + Crag.kHealInterval <= Shared.GetTime())  then
                local healAmount = self:TryHeal(entity)
                if healAmount > 0 then
                    entity.lasthealed = Shared.GetTime()
                    entsHealed = entsHealed + 1
                end
            end
            
            if entsHealed >= Crag.kMaxTargets then
                break
            end
            
        end
        if entsHealed > 0 then
            self.healingActive = true
            self:TriggerEffects("crag_heal")
            self.timeOfLastHeal = Shared.GetTime()
        else
            self.healingActive = false
        end
    end
    
    return self:GetIsAlive()
    
end

function Crag:TryHeal(target)

    local heal = (target:GetHealth() * Crag.kPercentHeal) + Crag.kHealAmount

    local amountHealed = target:AddHealth(heal, false, (target:GetMaxHealth() - target:GetHealth() ~= 0))
    if amountHealed > 0 then
        target:TriggerEffects("crag_target_healed")           
    end
    return amountHealed
    
end

function Crag:GetReceivesStructuralDamage()
    return true
end

function Crag:OnUpdateAnimationInput(modelMixin)

    PROFILE("Crag:OnUpdateAnimationInput")
    modelMixin:SetAnimationInput("heal", self.healingActive)
    
end

function Crag:OnOverrideOrder(order)

    // Convert default to set rally point.
    if order:GetType() == kTechId.Default then
        order:SetType(kTechId.SetRally)
    end
    
end

function Crag:GetTechButtons(techId)

    local techButtons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }
    return techButtons
    
end

function Crag:GetCanBeUsed(player, useSuccessTable)
    
    if not self:GetCanConstruct(player) then
        useSuccessTable.useSuccess = false
    else
        useSuccessTable.useSuccess = true
    end
    
end

if Server then

    function Crag:OnConstructionComplete()
    
        local team = self:GetTeam()
        if team and team.OnUpgradeChamberConstructed then
			self:AddTimedCallback(Crag.HealInRange, Crag.kHealInterval + 0.05)
            team:OnUpgradeChamberConstructed(self)
        end
        
    end
    
    function Crag:OnKill(attacker, doer, point, direction)
    
        ScriptActor.OnKill(self, attacker, doer, point, direction)
        
        local team = self:GetTeam()
        if team and team.OnUpgradeChamberDestroyed then
            team:OnUpgradeChamberDestroyed(self)
        end
        
    end
    
end

Shared.LinkClassToMap("Crag", Crag.kMapName, networkVars)