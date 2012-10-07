// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\InfantryPortal.lua
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
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/AlienDetectableMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")

class 'InfantryPortal' (ScriptActor)

local kSpinEffect = PrecacheAsset("cinematics/marine/infantryportal/spin.cinematic")
local kAnimationGraph = PrecacheAsset("models/marine/infantry_portal/infantry_portal.animation_graph")

InfantryPortal.kMapName = "infantryportal"

InfantryPortal.kModelName = PrecacheAsset("models/marine/infantry_portal/infantry_portal.model")

InfantryPortal.kAnimSpinStart = "spin_start"
InfantryPortal.kAnimSpinContinuous = "spin"

InfantryPortal.kUnderAttackSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/base_under_attack")

InfantryPortal.kLoopSound = PrecacheAsset("sound/NS2.fev/marine/structures/infantry_portal_active")
InfantryPortal.kIdleLightEffect = PrecacheAsset("cinematics/marine/infantryportal/idle_light.cinematic")

InfantryPortal.kTransponderUseTime = .5
InfantryPortal.kThinkInterval = 0.25
InfantryPortal.kTransponderPointValue = 15
InfantryPortal.kLoginAttachPoint = "keypad"

local kPushRange = 3
local kPushImpulseStrength = 40

local networkVars =
{
    queuedPlayerId = "entityid"
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
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(AlienDetectableMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)

local function CreateSpinEffect(self)

    if not self.spinCinematic then
    
        self.spinCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        self.spinCinematic:SetCinematic(kSpinEffect)
        self.spinCinematic:SetCoords(self:GetCoords())
        self.spinCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
    
    end

end

local function DestroySpinEffect(self)

    if self.spinCinematic then
    
        Client.DestroyCinematic(self.spinCinematic)    
        self.spinCinematic = nil
    
    end

end

function InfantryPortal:OnCreate()

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
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, AlienDetectableMixin)
    InitMixin(self, ParasiteMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    self.queuedPlayerId = Entity.invalidId
    
    self:SetLagCompensated(true)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
    
end

function InfantryPortal:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    InitMixin(self, WeldableMixin)    
    
    // For both client and server
    self:SetNextThink(InfantryPortal.kThinkInterval)
    
    self:SetModel(InfantryPortal.kModelName, kAnimationGraph)
    
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

function InfantryPortal:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    // Put the player back in queue if there was one hoping to spawn at this now destroyed IP.
    if Server then
        self:RequeuePlayer()
    elseif Client then
        DestroySpinEffect(self)        
    end

end

function InfantryPortal:GetShowOrderLine()
    return true
end

function InfantryPortal:GetUseAttachPoint()
    if self:GetIsBuilt() then
        return InfantryPortal.kLoginAttachPoint
    end
    return ""
end

function InfantryPortal:QueueWaitingPlayer()

    if self:GetIsAlive() and self.queuedPlayerId == Entity.invalidId then

        // Remove player from team spawn queue and add here
        local team = self:GetTeam()
        local playerToSpawn = team:GetOldestQueuedPlayer()

        if playerToSpawn ~= nil then
            
            playerToSpawn:SetIsRespawning(true, self:GetId())
            team:RemovePlayerFromRespawnQueue(playerToSpawn)
            
            self.queuedPlayerId = playerToSpawn:GetId()
            self.queuedPlayerStartTime = Shared.GetTime()

            self:StartSpinning()            
            
            SendPlayersMessage({ playerToSpawn }, kTeamMessageTypes.Spawning)
            
            if Server then
                
                if playerToSpawn.SetSpectatorMode then
                    playerToSpawn:SetSpectatorMode(Spectator.kSpectatorMode.Following)
                end
                
                playerToSpawn:ImposeTarget(self)

            end
            
        end
        
    end

end

function InfantryPortal:GetReceivesStructuralDamage()
    return true
end

function InfantryPortal:GetSpawnTime()
    return kMarineRespawnTime
end

function InfantryPortal:OnReplace(newStructure)

    newStructure.queuedPlayerId = self.queuedPlayerId    
    newStructure:SetNextThink(InfantryPortal.kThinkInterval)
    
end

function InfantryPortal:SpawnTimeElapsed()

    local elapsed = false
    
    if self.queuedPlayerId ~= Entity.invalidId then
    
        local queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
        if queuedPlayer then
            elapsed = Shared.GetTime() >= (self.queuedPlayerStartTime + self:GetSpawnTime())
        else
        
            self.queuedPlayerId = nil
            self.queuedPlayerStartTime = nil
            
        end
        
    end
    
    return elapsed
    
end

// Spawn player on top of IP. Returns true if it was able to, false if way was blocked.
local function SpawnPlayer(self)

    if self.queuedPlayerId ~= Entity.invalidId then
    
        local queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
        local team = queuedPlayer:GetTeam()
        
        // Spawn player on top of IP
        local spawnOrigin = self:GetAttachPointOrigin("spawn_point")
        
        local success, player = team:ReplaceRespawnPlayer(queuedPlayer, spawnOrigin, queuedPlayer:GetAngles())
        if success then
        
            player:SetCameraDistance(0)
        
            self.queuedPlayerId = Entity.invalidId
            self.queuedPlayerStartTime = nil
            
            player:ProcessRallyOrder(self)
            
            self:TriggerEffects("infantry_portal_spawn")            
            
            return true
            
        else
            Print("Warning: Infantry Portal failed to spawn the player")
        end
        
    end
    
    return false

end

function InfantryPortal:GetIsWallWalkingAllowed()
    return false
end 

// Takes the queued player from this IP and placed them back in the
// respawn queue to be spawned elsewhere.
function InfantryPortal:RequeuePlayer()

    if self.queuedPlayerId ~= Entity.invalidId then
    
        local player = Shared.GetEntity(self.queuedPlayerId)
        local team = self:GetTeam()
        if team then
            team:PutPlayerInRespawnQueue(Shared.GetEntity(self.queuedPlayerId))
        end
        player:SetIsRespawning(false, Entity.invalidId)
        player:SetSpectatorMode(Spectator.kSpectatorMode.Following)
        
    end
    
    // Don't spawn player.
    self.queuedPlayerId = Entity.invalidId
    self.queuedPlayerStartTime = nil

end

local function StopSpinning(self)

    self:TriggerEffects("infantry_portal_stop_spin")
    self.timeSpinUpStarted = nil
    
end

if Server then

    function InfantryPortal:OnEntityChange(entityId, newEntityId)
    
        if self.queuedPlayerId == entityId then
        
            // Player left or was replaced, either way 
            // they're not in the queue anymore
            self.queuedPlayerId = Entity.invalidId
            self.queuedPlayerStartTime = nil
            
        end
        
    end
    
    function InfantryPortal:OnKill(attacker, doer, point, direction)
    
        ScriptActor.OnKill(self, attacker, doer, point, direction)
        
        StopSpinning(self)
        
        // Put the player back in queue if there was one hoping to spawn at this now dead IP.
        self:RequeuePlayer()
        
    end
    
end

function InfantryPortal:FinishSpawn()

    SpawnPlayer(self)
    StopSpinning(self)
    self.timeSpinUpStarted = nil
    
end

// If built and active 
if Server then

    function InfantryPortal:OnThink()
    
        if GetIsUnitActive(self) then
        
            PROFILE("InfantryPortal:OnThink")
            
            // If no player in queue
            if self.queuedPlayerId == Entity.invalidId then
            
                // Grab available player from team and put in queue
                self:QueueWaitingPlayer()
               
            // else if time has elapsed to spawn player
            elseif self:SpawnTimeElapsed() then
            
                self:FinishSpawn()
                PushPlayersInRange(self:GetOrigin(), kPushRange, kPushImpulseStrength, GetEnemyTeamNumber(self:GetTeamNumber()))
                
            end
            
            // Stop spinning if player left server, switched teams, etc.            
            if self.timeSpinUpStarted and self.queuedPlayerId == Entity.invalidId then            
                StopSpinning(self)
            end
            
        end
        
        self:SetNextThink(InfantryPortal.kThinkInterval)
        
    end
    
end

function InfantryPortal:StartSpinning()

    if self.timeSpinUpStarted == nil then
    
        self:TriggerEffects("infantry_portal_start_spin")
        self.timeSpinUpStarted = Shared.GetTime()
        
    end
    
end

function InfantryPortal:GetDamagedAlertId()
    return kTechId.MarineAlertInfantryPortalUnderAttack
end

function InfantryPortal:OnUpdateAnimationInput(modelMixin)

    PROFILE("InfantryPortal:OnUpdateAnimationInput")
    modelMixin:SetAnimationInput("spawning", self.queuedPlayerId ~= Entity.invalidId)
	modelMixin:SetAnimationInput("powered", true)
    
end

function InfantryPortal:OnOverrideOrder(order)

    // Convert default to set rally point.
    if order:GetType() == kTechId.Default then
        order:SetType(kTechId.SetRally)
    end
    
end

function GetInfantryPortalGhostGuides(commander)

    local commandStations = GetEntitiesForTeam("CommandStation", commander:GetTeamNumber())
    local attachRange = LookupTechData(kTechId.InfantryPortal, kStructureAttachRange, 1)
    local result = { }
    
    for _, commandStation in ipairs(commandStations) do
        if commandStation:GetIsBuilt() then
            result[commandStation] = attachRange
        end
    end
    
    return result

end

function GetCommandStationIsBuilt(techId, origin, normal, commander)

    // check if there is a built command station in our team
    if not commander then
        return false
    end    
    
    local cs = GetEntitiesForTeamWithinRange("CommandStation", commander:GetTeamNumber(), origin, 15)
    if cs and #cs > 0 then
        return cs[1]:GetIsBuilt()
    end
    
    return false

end

function InfantryPortal:OnUpdateRender()

    PROFILE("InfantryPortal:OnUpdateRender")

    local shouldSpin = GetIsUnitActive(self) and self.queuedPlayerId ~= Entity.invalidId
    
    if shouldSpin then
        CreateSpinEffect(self)
    else
        DestroySpinEffect(self)
    end
    
end

local kInfantryPortalHealthbarOffset = Vector(0, 0.5, 0)
function InfantryPortal:GetHealthbarOffset()
    return kInfantryPortalHealthbarOffset
end 

Shared.LinkClassToMap("InfantryPortal", InfantryPortal.kMapName, networkVars, true)