// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PhaseGate.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed some unneeded mixins.
//These used to require using but that seemed to confused players - Not sure what is best atm

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
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/MinimapConnectionMixin.lua")
Script.Load("lua/IdleMixin.lua")
Script.Load("lua/ParasiteMixin.lua")

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
    local invVel = invSrcCoords:TransformVector(player:GetVelocity())
    local newVelocity = dstCoords:TransformVector(invVel)
    player:SetVelocity(newVelocity)
    
    local viewCoords = dstCoords * (invSrcCoords * viewCoords)
    local viewAngles = Angles()
    viewAngles:BuildFromCoords(viewCoords)
    
    player:SetViewAngles(viewAngles)
    
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

local kUpdateInterval = 0.1

// Can only teleport a player every so often
local kDepartureRate = 0.75

local kPushRange = 1
local kPushImpulseStrength = 20

local networkVars =
{
    linked = "boolean",
    phase = "boolean",
    deployed = "boolean",
    destLocationId = "entityid",
    timeOfLastPhase = "compensated time",
    destinationEndpoint = "position"
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
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)
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
    InitMixin(self, DetectableMixin)
    InitMixin(self, PowerConsumerMixin)
    InitMixin(self, ParasiteMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    // Compute link state on server and propagate to client for looping effects
    self.linked = false
    self.phase = false
    self.deployed = false
    self.timeOfLastPhase = 0
    self.destLocationId = Entity.invalidId
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
    
end

function PhaseGate:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    InitMixin(self, WeldableMixin)
    
    self:SetModel(PhaseGate.kModelName, kAnimationGraph)
    
    if Server then
    
        self:AddTimedCallback(PhaseGate.Update, kUpdateInterval)
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, StaticTargetMixin)
        InitMixin(self, MinimapConnectionMixin)
    
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        
    end
    
    InitMixin(self, IdleMixin)
    
end

function PhaseGate:GetIsWallWalkingAllowed()
    return false
end 

function PhaseGate:GetTechButtons(techId)

    return { kTechId.None, kTechId.None, kTechId.None, kTechId.None, 
             kTechId.None, kTechId.None, kTechId.None, kTechId.None }
    
end

// Temporarily don't use "target" attach point
local kPhaseGateEngagementPointOffset = Vector(0, 0.1, 0)
function PhaseGate:GetEngagementPointOverride()
    return self:GetOrigin() + kPhaseGateEngagementPointOffset
end

function PhaseGate:GetIsPowered()
    return self.linked
end

function PhaseGate:GetDestLocationId()
    return self.destLocationId
end

function PhaseGate:GetEffectParams(tableParams)

    // Override active field here to mean "linked"
    tableParams[kEffectFilterActive] = self.linked
    
end

function PhaseGate:GetReceivesStructuralDamage()
    return true
end

function PhaseGate:GetDamagedAlertId()
    return kTechId.MarineAlertStructureUnderAttack
end

function PhaseGate:GetPlayIdleSound()
    return ScriptActor.GetPlayIdleSound(self) and self.linked
end

function PhaseGate:GetCanBeUsedConstructed()
    return true
end   

function PhaseGate:GetCanBeUsed(player, useSuccessTable)

    if self:GetCanConstruct(player) or (self.linked and self:GetIsPhaseReady()) then
        useSuccessTable.useSuccess = true
    else
        useSuccessTable.useSuccess = false
    end
    
end

function PhaseGate:OnUse(player, elapsedTime, useSuccessTable)
    if self:GetIsDeployed() and self:GetIsPhaseReady() and GetIsUnitActive(self) and Server then
        self:Phase(player)
	end
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

local function ComputeDestinationLocationId(self, destGate)

    local destLocationId = Entity.invalidId
    if destGate then
    
        local location = GetLocationForPoint(destGate:GetOrigin())
        if location then
            destLocationId = location:GetId()
        end
        
    end
    
    return destLocationId
    
end

function PhaseGate:OnIncomingPhase()
    self.timeOfLastPhase = Shared.GetTime()
end

function PhaseGate:Phase(user)

    local destinationPhaseGate = GetDestinationGate(self)
    if self.linked and not GetAreEnemies(self, user) and destinationPhaseGate and GetIsUnitActive(destinationPhaseGate) and destinationPhaseGate:GetIsPhaseReady() then

        destinationPhaseGate:OnIncomingPhase()
        // Don't bother checking if destination is clear, rely on pushing away entities
        user:TriggerEffects("phase_gate_player_enter")        
        user:TriggerEffects("teleport")
        
        local destinationCoords = Angles(0, destinationPhaseGate:GetAngles().yaw, 0):GetCoords()
        destinationCoords.origin = self.destinationEndpoint
        
        TransformPlayerCoordsForPhaseGate(user, self:GetCoords(), destinationCoords)

        user:SetOrigin(self.destinationEndpoint)
        // trigger exit effect at destination
        user:TriggerEffects("phase_gate_player_exit")
        
        self.timeOfLastPhase = Shared.GetTime()
        
        return true
        
    end
    
    return false

end

function PhaseGate:GetIsPhaseReady()
    return self.timeOfLastPhase + kDepartureRate < Shared.GetTime()
end

if Server then

    function PhaseGate:Update()
    
        self.phase = (self.timeOfLastPhase ~= nil) and (Shared.GetTime() < (self.timeOfLastPhase + kDepartureRate))

        local destinationPhaseGate = GetDestinationGate(self)
        if destinationPhaseGate ~= nil and GetIsUnitActive(self) and self.deployed and destinationPhaseGate.deployed and self:GetIsPhaseReady() then        
        
            self.destinationEndpoint = destinationPhaseGate:GetOrigin()
            self.linked = true
            self.destLocationId = ComputeDestinationLocationId(self, destinationPhaseGate)
            
        else
            self.linked = false
            self.destLocationId = Entity.invalidId
        end

        return true
        
    end

end

local function SharedUpdate(self)

    if self:GetIsPhaseReady() and GetIsUnitActive(self) then
        //Auto phase the bots :s
        for _, marine in ipairs(GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(), self:GetOrigin(), 0.5)) do
            local client = Server.GetOwner(marine)
            if client and client:GetIsVirtual() and self:Phase(marine) then                
                break
            end
        end
    
    end

end

// for non players
if Server then

    function PhaseGate:OnUpdate(deltaTime)    
        SharedUpdate(self)
    end

end

function PhaseGate:GetConnectionStartPoint()
    return self:GetOrigin()
end

function PhaseGate:GetConnectionEndPoint()

    if GetIsUnitActive(self) and self.linked then
        return self.destinationEndpoint
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

end

function PhaseGate:GetHealthbarOffset()
    return 1.2
end 

local function GetDestinationLocationName(self)

    local locationEndId = self:GetDestLocationId()
    local location = Shared.GetEntity(locationEndId)
    
    if location then
        return location:GetName()
    end

end

function PhaseGate:GetIsDeployed()
    return self.deployed
end

function PhaseGate:GetUnitNameOverride(viewer)

    local unitName = GetDisplayName(self)

    if not GetAreEnemies(self, viewer) then
    
        local destinationName = GetDestinationLocationName(self)        
        if destinationName then
            unitName = unitName .. " to " .. destinationName
        end

    end

    return unitName

end

function CheckSpaceForPhaseGate(techId, origin, normal, commander)
    return GetHasRoomForCapsule(Vector(Player.kXZExtents, Player.kYExtents, Player.kXZExtents), origin + Vector(0, 0.1 + Player.kYExtents, 0), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls)
end

Shared.LinkClassToMap("PhaseGate", PhaseGate.kMapName, networkVars)