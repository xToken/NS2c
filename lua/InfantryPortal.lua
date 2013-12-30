// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\InfantryPortal.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed some unneeded mixins

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
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/IdleMixin.lua")
Script.Load("lua/ParasiteMixin.lua")

class 'InfantryPortal' (ScriptActor)

local kSpinEffect = PrecacheAsset("cinematics/marine/infantryportal/spin.cinematic")
local kAnimationGraph = PrecacheAsset("models/marine/infantry_portal/infantry_portal.animation_graph")
local kHoloMarineModel = PrecacheAsset("models/marine/male/male_spawn.model")

local kHoloMarineMaterialname = "cinematics/vfx_materials/marine_ip_spawn.material"

if Client then
    Shared.PrecacheSurfaceShader("cinematics/vfx_materials/marine_ip_spawn.surface_shader")
end

InfantryPortal.kMapName = "infantryportal"

InfantryPortal.kModelName = PrecacheAsset("models/marine/infantry_portal/infantry_portal.model")

InfantryPortal.kAnimSpinStart = "spin_start"
InfantryPortal.kAnimSpinContinuous = "spin"

InfantryPortal.kUnderAttackSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/base_under_attack")
InfantryPortal.kIdleLightEffect = PrecacheAsset("cinematics/marine/infantryportal/idle_light.cinematic")

InfantryPortal.kTransponderUseTime = .5
local kUpdateRate = 0.25
InfantryPortal.kTransponderPointValue = 15
InfantryPortal.kLoginAttachPoint = "keypad"

local kPushRange = 1.5
local kPushImpulseStrength = 20

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
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)

local function CreateSpinEffect(self)

    if not self.spinCinematic then
    
        self.spinCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        self.spinCinematic:SetCinematic(kSpinEffect)
        self.spinCinematic:SetCoords(self:GetCoords())
        self.spinCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
    
    end
    
    if not self.fakeMarineModel and not self.fakeMarineMaterial then
    
        self.fakeMarineModel = Client.CreateRenderModel(RenderScene.Zone_Default)
        self.fakeMarineModel:SetModel(Shared.GetModelIndex(kHoloMarineModel))
        
        local coords = self:GetCoords()
        coords.origin = coords.origin + Vector(0, 0.4, 0)
        
        self.fakeMarineModel:SetCoords(coords)
        self.fakeMarineModel:InstanceMaterials()
        self.fakeMarineModel:SetMaterialParameter("hiddenAmount", 1.0)
        
        self.fakeMarineMaterial = AddMaterial(self.fakeMarineModel, kHoloMarineMaterialname)
    
    end
    
    if self.clientQueuedPlayerId ~= self.queuedPlayerId then
        self.timeSpinStarted = Shared.GetTime()
        self.clientQueuedPlayerId = self.queuedPlayerId
    end
    
    local spawnProgress = Clamp((Shared.GetTime() - self.timeSpinStarted) / kMarineRespawnTime, 0, 1)
    
    self.fakeMarineModel:SetIsVisible(true)
    self.fakeMarineMaterial:SetParameter("spawnProgress", spawnProgress+0.2)    // Add a little so it always fills up

end

local function DestroySpinEffect(self)

    if self.spinCinematic then
    
        Client.DestroyCinematic(self.spinCinematic)    
        self.spinCinematic = nil
    
    end
    
    if self.fakeMarineModel then    
        self.fakeMarineModel:SetIsVisible(false)
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
    InitMixin(self, DetectableMixin)
    InitMixin(self, PowerConsumerMixin)
    InitMixin(self, ParasiteMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    self.queuedPlayerId = Entity.invalidId
    
    self:SetLagCompensated(true)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
    
end

local function StopSpinning(self)

    self:TriggerEffects("infantry_portal_stop_spin")
    self.timeSpinUpStarted = nil
    
end

local function InfantryPortalUpdate(self)

    self:FillQueueIfFree()
    
    if GetIsUnitActive(self) then
    
        if self:SpawnTimeElapsed() then
            self:FinishSpawn()
        end
        
        // Stop spinning if player left server, switched teams, etc.
        if self.timeSpinUpStarted and self.queuedPlayerId == Entity.invalidId then
            StopSpinning(self)
        end
        
    end
    
    return true
    
end

function InfantryPortal:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    InitMixin(self, WeldableMixin)    
    
    self:SetModel(InfantryPortal.kModelName, kAnimationGraph)
    
    if Server then
    
        self:AddTimedCallback(InfantryPortalUpdate, kUpdateRate)
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, StaticTargetMixin)
    
    elseif Client then
        InitMixin(self, UnitStatusMixin)
    end
    
    InitMixin(self, IdleMixin)
    
end

function InfantryPortal:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    // Put the player back in queue if there was one hoping to spawn at this now destroyed IP.
    if Server then
        self:RequeuePlayer()
    elseif Client then
    
        DestroySpinEffect(self)
        
        if self.fakeMarineModel then
        
            Client.DestroyRenderModel(self.fakeMarineModel)
            self.fakeMarineModel = nil
            self.fakeMarineMaterial = nil
            
        end
        
    end

end

local function QueueWaitingPlayer(self)

    if self:GetIsAlive() and self.queuedPlayerId == Entity.invalidId then

        // Remove player from team spawn queue and add here
        local team = self:GetTeam()
        local playerToSpawn = team:GetOldestQueuedPlayer()

        if playerToSpawn ~= nil then
            
            playerToSpawn:SetIsRespawning(true)
            team:RemovePlayerFromRespawnQueue(playerToSpawn)
            
            self.queuedPlayerId = playerToSpawn:GetId()
            self.queuedPlayerStartTime = Shared.GetTime()

            self:StartSpinning()            
            
            SendPlayersMessage({ playerToSpawn }, kTeamMessageTypes.Spawning)
            
            if Server then
                
                if playerToSpawn.SetSpectatorMode then
                    playerToSpawn:SetSpectatorMode(kSpectatorMode.Following)
                end
                
                playerToSpawn:SetFollowTarget(self)

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
        player:SetIsRespawning(false)
        player:SetSpectatorMode(kSpectatorMode.Following)
        
    end
    
    // Don't spawn player.
    self.queuedPlayerId = Entity.invalidId
    self.queuedPlayerStartTime = nil

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

if Server then

    function InfantryPortal:FillQueueIfFree()
    
        if GetIsUnitActive(self) then
        
            if self.queuedPlayerId == Entity.invalidId then
                QueueWaitingPlayer(self)
            end
            
        end
        
    end
    
    function InfantryPortal:FinishSpawn()
    
        SpawnPlayer(self)
        StopSpinning(self)
        self.timeSpinUpStarted = nil
        
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

local kTraceOffset = 0.1
function GetCommandStationIsBuilt(techId, origin, normal, commander)

    // check if there is a built command station in our team
    if not commander then
        return false
    end

    local spaceFree = GetHasRoomForCapsule(Vector(Player.kXZExtents, Player.kYExtents, Player.kXZExtents), origin + Vector(0, 0.1 + Player.kYExtents, 0), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls)
    
    if spaceFree then
    
        local cs = GetEntitiesForTeamWithinRange("CommandStation", commander:GetTeamNumber(), origin, 15)
        if cs and #cs > 0 then
            return cs[1]:GetIsBuilt()
        end
    
    end
    
    return false

end

if Client then

    function InfantryPortal:PreventSpinEffect(duration)
        self.preventSpinDuration = duration
        DestroySpinEffect(self)
    end

    function InfantryPortal:OnUpdate(deltaTime)

        PROFILE("InfantryPortal:OnUpdate")
        
        ScriptActor.OnUpdate(self, deltaTime)
        
        if self.preventSpinDuration then            
            self.preventSpinDuration = math.max(0, self.preventSpinDuration - deltaTime)         
        end

        local shouldSpin = GetIsUnitActive(self) and self.queuedPlayerId ~= Entity.invalidId and (self.preventSpinDuration == nil or self.preventSpinDuration == 0)
        
        if shouldSpin then
            CreateSpinEffect(self)
        else
            DestroySpinEffect(self)
        end
        
    end

end

function InfantryPortal:GetTechButtons()
    return { kTechId.None, kTechId.None, kTechId.None, kTechId.None, 
             kTechId.None, kTechId.None, kTechId.None, kTechId.None,  }
end

function InfantryPortal:GetHealthbarOffset()
    return 0.5
end 

Shared.LinkClassToMap("InfantryPortal", InfantryPortal.kMapName, networkVars, true)