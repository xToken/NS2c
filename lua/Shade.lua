// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Shade.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Alien structure that provides cloaking abilities and confuse and deceive capabilities.
//
// Disorient (Passive) - Enemy structures and players flicker in and out when in range of Shade, 
// making it hard for Commander and team-mates to be able to support each other. Extreme reverb 
// sounds for enemies (and slight reverb sounds for friendlies) enhance the effect.
//
// Cloak (Triggered) - Instantly cloaks self and all enemy structures and aliens in range
// for a short time. Mutes or changes sounds too? Cleverly used, this would ideally allow a 
// team to get a stealth hive built. Allow players to stay cloaked for awhile, until they attack
// (even if they move out of range - great for getting by sentries).
//
// Hallucination - Allow Commander to create fake Fade, Onos, Hive (and possibly 
// ammo/medpacks). They can be pathed around and used to create tactical distractions or divert 
// forces elsewhere.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ClientModelMixin.lua")
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
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/TriggerMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/DetectorMixin.lua")

class 'Shade' (ScriptActor)

Shade.kMapName = "shade"

Shade.kModelName = PrecacheAsset("models/alien/shade/shade.model")
Shade.kAnimationGraph = PrecacheAsset("models/alien/shade/shade.animation_graph")

local kCloakTriggered = PrecacheAsset("sound/NS2.fev/alien/structures/shade/cloak_triggered")
local kCloakTriggered2D = PrecacheAsset("sound/NS2.fev/alien/structures/shade/cloak_triggered_2D")

Shade.kCloakRadius = 20
Shade.kCloakUpdateRate = 0.5
Shade.kHiveSightRange = 25

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
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
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
        
function Shade:OnCreate()

    ScriptActor.OnCreate(self)
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
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
    InitMixin(self, ObstacleMixin)
    InitMixin(self, UmbraMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, DissolveMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, DetectorMixin)
        
    if Server then
    
        //InitMixin(self, TriggerMixin, {kPhysicsGroup = PhysicsGroup.TriggerGroup, kFilterMask = PhysicsMask.AllButTriggers} )    
    else
        InitMixin(self, CommanderGlowMixin)            
    end
    
    self:SetLagCompensated(true)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
    
end

function Shade:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(Shade.kModelName, Shade.kAnimationGraph)
    
    if Server then
    
        InitMixin(self, StaticTargetMixin)
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

function Shade:GetDetectionRange()

    if GetIsUnitActive(self) then
        return Shade.kHiveSightRange
    end    
    return 0
end

function Shade:GetShowOrderLine()
    return true
end    

function Shade:GetDamagedAlertId()
    return kTechId.AlienAlertStructureUnderAttack
end

function Shade:GetCanDie(byDeathTrigger)
    return not byDeathTrigger
end

function Shade:GetReceivesStructuralDamage()
    return true
end

function Shade:ConstructOverride(deltaTime)
    return deltaTime / 2
end

function Shade:OnUpdateAnimationInput(modelMixin)

    PROFILE("Shade:OnUpdateAnimationInput")
    modelMixin:SetAnimationInput("cloak", true)
    
end

function Shade:OnOverrideOrder(order)

    // Convert default to set rally point.
    if order:GetType() == kTechId.Default then
        order:SetType(kTechId.SetRally)
    end
    
end

function Shade:GetCanSleep()
    return true
end

function Shade:GetCanBeUsed(player, useSuccessTable)

    if not self:GetCanConstruct(player) then
        useSuccessTable.useSuccess = false
    else
        useSuccessTable.useSuccess = true
    end
    
end

if Server then
    
    function Shade:OnTriggerListChanged(entity, entered)
        
        local team = self:GetTeam()
        if team then
            if entered then
                team:RegisterCloakable(entity)    
            else
                team:DeregisterCloakable(entity)
            end
        end
    
    end

    /*    
    function Shade:OnKill(attacker, doer, point, direction)
    
        ScriptActor.OnKill(self, attacker, doer, point, direction)
        
        local team = self:GetTeam()
        if team then
            for _, cloakable in ipairs(self:GetEntitiesInTrigger()) do
                team:DeregisterCloakable(cloakable)
            end
        end 
        
    end
    */
    
    function Shade:GetTrackEntity(entity)
        return HasMixin(entity, "Team") and entity:GetTeamNumber() == self:GetTeamNumber() and HasMixin(entity, "Cloakable") and self:GetIsBuilt() and self:GetIsAlive()
    end
    
    function Shade:OnConstructionComplete()    
        self:AddTimedCallback(Shade.UpdateCloaking, Shade.kCloakUpdateRate)    
        //self:AddTimedCallback(Shade.UpdateHiveSight, Shade.kHiveSightUpdateRate) 
    end
    
    function Shade:UpdateCloaking()
    
        for _, cloakable in ipairs( GetEntitiesWithMixinForTeamWithinRange("Cloakable", self:GetTeamNumber(), self:GetOrigin(), Shade.kCloakRadius) ) do
        
            cloakable:SetIsCloaked(true, 1, false)
        
        end
        
        return self:GetIsAlive()
    
    end
    
    function Shade:UpdateHiveSight()
    
        for _, hivesightable in ipairs( GetEntitiesWithMixinForTeamWithinRange("ParasiteAble", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Shade.kCloakRadius) ) do
        
            hivesightable:SetParasited(self, 1)
        
        end
        
        return self:GetIsAlive()
    
    end

end

Shared.LinkClassToMap("Shade", Shade.kMapName, networkVars, true)