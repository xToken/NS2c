// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PhaseGate.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
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
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/AlienDetectableMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("Lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CombatMixin.lua")

local kAnimationGraph = PrecacheAsset("models/marine/phase_gate/phase_gate.animation_graph")

local kPhaseGatePushForce = 500

// Offset about the phase gate origin where the player will spawn
local kSpawnOffset = Vector(0, 0.1, 0)

// Transform angles, view angles and velocity from srcCoords to destCoords (when going through phase gate)
local function TransformPlayerCoordsForPhaseGate(player, srcCoords, dstCoords)

    local viewCoords = player:GetViewCoords()
    
    // If we're going through the backside of the phase gate, orient us
    // so we go out of the front side of the other gate.
    if Math.DotProduct(viewCoords.zAxis, srcCoords.zAxis) < 0 then
        srcCoords.zAxis = -srcCoords.zAxis
        srcCoords.xAxis = -srcCoords.xAxis
    end
    
    // Redirect player velocity relative to gates
    local invSrcCoords = srcCoords:GetInverse()
    local invVel = invSrcCoords:TransformVector( player:GetVelocity() )
    local newVelocity = dstCoords:TransformVector( invVel )
    player:SetVelocity(newVelocity)
    
    local viewCoords = dstCoords * (invSrcCoords * viewCoords)
    local viewAngles = Angles()
    viewAngles:BuildFromCoords(viewCoords)
    
    player:SetOffsetAngles(viewAngles)
    
end

local function GetDestinationOrigin(origin, direction, player, phaseGate, extents)

    local capusuleOffset = Vector(0, 0.4, 0)
    origin = origin + kSpawnOffset
    if not extents then
        extents = Vector(0.17, 0.2, 0.17)
    end

    // check at first a desired spawn, if that one is free we use that
    if GetHasRoomForCapsule(extents, origin + capusuleOffset, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, phaseGate) then
        return origin
    end
    
    local numChecks = 6
    
    for i = 0, numChecks do
    
        local offset = direction * (i - numChecks/2) * -0.5
        if GetHasRoomForCapsule(extents, origin + offset + capusuleOffset, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, phaseGate) then
            origin = origin + offset
            break
        end
        
    end
    
    return origin

end

class 'PhaseGate' (ScriptActor)

PhaseGate.kMapName = "phasegate"

PhaseGate.kModelName = PrecacheAsset("models/marine/phase_gate/phase_gate.model")

PhaseGate.kUpdateInterval = 0.25

// Can only teleport a player every so often
local kDepartureRate = 0.5

local kPushRange = 1
local kPushImpulseStrength = 20

local networkVars =
{
    linked = "boolean",
    phase = "boolean",
    deployed = "boolean",
    phaseallowed = "time",
    destLocationId = "entityid"
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
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(AlienDetectableMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)

function PhaseGate:OnCreate()

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
    InitMixin(self, CombatMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, AlienDetectableMixin)
    InitMixin(self, ParasiteMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    // Compute link state on server and propagate to client for looping effects
    self.linked = false
    self.phase = false
    self.deployed = false
    self.destLocationId = Entity.invalidId
    self.phaseallowed = 0
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
    
end

function PhaseGate:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    InitMixin(self, WeldableMixin)
    
    self:SetModel(PhaseGate.kModelName, kAnimationGraph)
    
    if Server then
    
        self.timeOfLastPhase = nil
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, StaticTargetMixin)
    
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        
    end
    
end

function PhaseGate:GetIsWallWalkingAllowed()
    return false
end 

function PhaseGate:GetTechButtons(techId)

    return { kTechId.None, kTechId.None, kTechId.None, kTechId.None, 
             kTechId.None, kTechId.None, kTechId.None, kTechId.None }
    
end

// Temporarily don't use "target" attach point
function PhaseGate:GetEngagementPointOverride()
    return self:GetModelOrigin()
end

function PhaseGate:GetDestLocationId()
    return self.destLocationId
end

function PhaseGate:GetEffectParams(tableParams)

    ScriptActor.GetEffectParams(self, tableParams)
    
    // Override active field here to mean "linked"
    tableParams[kEffectFilterActive] = self.linked
        
end

function PhaseGate:GetReceivesStructuralDamage()
    return true
end

function PhaseGate:GetDamagedAlertId()
    return kTechId.MarineAlertStructureUnderAttack
end

function PhaseGate:GetIsIdle()
    return ScriptActor.GetIsIdle(self) and self.linked
end

function PhaseGate:GetCanBeUsedConstructed()
    return true
end   

function PhaseGate:GetCanBeUsed(player, useSuccessTable)

    if self:GetCanConstruct(player) or self.phaseallowed < Shared.GetTime() then
        useSuccessTable.useSuccess = true
    else
        useSuccessTable.useSuccess = false
    end
    
end

if Server then

    /**
     * Returns true if the phase gate is ready to teleport a player. This does not check if
     * there is a destination phase gate however.
     */
    local function GetCanPhase(self)
        
        if not self.deployed or not GetIsUnitActive(self) then
            return false
        end
        
        if self.timeOfLastPhase == nil or (Shared.GetTime() > (self.timeOfLastPhase + kDepartureRate)) then
            return true
        end
        
        return false
        
    end
    
    // Returns next phase gate in round-robin order. Returns nil if there are no other built/active phase gates
    local function GetDestinationGate(self)

        // Find next phase gate to teleport to
        local phaseGates = {}    
        for index, phaseGate in ipairs( GetEntitiesForTeam("PhaseGate", self:GetTeamNumber()) ) do
            if GetIsUnitActive(phaseGate) then
                table.insert(phaseGates, phaseGate)
            end
        end    
        
        if table.count(phaseGates) < 2 then
            return nil
        end
        
        // Find our index and add 1
        local index = table.find(phaseGates, self)
        if (index ~= nil) then
        
            local nextIndex = ConditionalValue(index == table.count(phaseGates), 1, index + 1)
            ASSERT(nextIndex >= 1)
            ASSERT(nextIndex <= table.count(phaseGates))
            return phaseGates[nextIndex]
            
        end
        
        return nil
        
    end
    
    local function ComputeDestinationLocationId(self)

        local destLocationId = Entity.invalidId
        
        local destGate = GetDestinationGate(self)
        if destGate then
        
            local location = GetLocationForPoint(destGate:GetOrigin())
            if location then
                destLocationId = location:GetId()
            end
            
        end
        
        return destLocationId
        
    end
    
    function PhaseGate:ScanForGates()

        local destinationPhaseGate = GetDestinationGate(self)
        // Update network variable state
        self.linked = GetIsUnitActive(self) and self.deployed and (destinationPhaseGate ~= nil) and destinationPhaseGate.deployed
        self.phase = (self.timeOfLastPhase ~= nil) and (Shared.GetTime() < (self.timeOfLastPhase + .1))
        // Update destination id for displaying in description
        self.destLocationId = ComputeDestinationLocationId(self)
        return self:GetIsAlive()
        
    end
    
    function PhaseGate:OnConstructionComplete()
        self:AddTimedCallback(PhaseGate.ScanForGates, PhaseGate.kUpdateInterval)
        self.phaseallowed = Shared.GetTime() + 1
    end
    
    function PhaseGate:OnUse(player, elapsedTime, useAttachPoint, usePoint, useSuccessTable)

        local destinationPhaseGate = GetDestinationGate(self)
        
        // If built and active 
        if destinationPhaseGate ~= nil and GetCanPhase(destinationPhaseGate) and GetCanPhase(self) and player.GetCanPhase and player:GetCanPhase() then
            
            // check for free place
            local destOrigin = GetDestinationOrigin(destinationPhaseGate:GetOrigin(), destinationPhaseGate:GetCoords().zAxis, destinationPhaseGate, player:GetExtents())
            
            // Don't bother checking if destination is clear, rely on pushing away entities
            self:TriggerEffects("phase_gate_player_enter")
            
            player:TriggerEffects("teleport")
            
            TransformPlayerCoordsForPhaseGate(player, self:GetCoords(), destinationPhaseGate:GetCoords())
            
            PushPlayersInRange(destOrigin, kPushRange, kPushImpulseStrength, GetEnemyTeamNumber(self:GetTeamNumber()))

            SpawnPlayerAtPoint(player, destOrigin)
            
            destinationPhaseGate:TriggerEffects("phase_gate_player_exit")
            
            self.timeOfLastPhase = Shared.GetTime()
            destinationPhaseGate.timeOfLastPhase = Shared.GetTime()
            
            player:SetTimeOfLastPhase(self.timeOfLastPhase)
            
        end
        
    end
    
end

function PhaseGate:OnTag(tagName)

    PROFILE("PhaseGate:OnTag")

    if tagName == "deploy_end" then
        self.deployed = true
    end
    
end

function PhaseGate:OnUpdateRender()

    PROFILE("PhaseGate:OnUpdateRender")

    if self.clientLinked ~= self.linked then
    
        self.clientLinked = self.linked
        
        local effects = ConditionalValue(self.linked and self:GetIsVisible(), "phase_gate_linked", "phase_gate_unlinked")
        self:TriggerEffects(effects)
        
    end

end

function PhaseGate:OnUpdateAnimationInput(modelMixin)

    PROFILE("PhaseGate:OnUpdateAnimationInput")

    modelMixin:SetAnimationInput("linked", self.linked)
	modelMixin:SetAnimationInput("phase", self.phase)
	modelMixin:SetAnimationInput("powered", true)

end

local kPhaseGateHealthbarOffset = Vector(0, 1.2, 0)
function PhaseGate:GetHealthbarOffset()
    return kPhaseGateHealthbarOffset
end 


Shared.LinkClassToMap("PhaseGate", PhaseGate.kMapName, networkVars)