// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Observatory.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Tweaked detector on Obs, added motion tracking and beaconing of dead players.

Script.Load("lua/CommAbilities/Marine/Scan.lua")

Script.Load("lua/Mixins/ClientModelMixin.lua")
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
Script.Load("lua/EnergyMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/DetectorMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/IdleMixin.lua")
Script.Load("lua/ParasiteMixin.lua")

class 'Observatory' (ScriptActor)

Observatory.kMapName = "observatory"

Observatory.kModelName = PrecacheAsset("models/marine/observatory/observatory.model")

Observatory.kScanSound = PrecacheAsset("sound/NS2.fev/marine/structures/observatory_scan")
Observatory.kCommanderScanSound = PrecacheAsset("sound/NS2.fev/marine/commander/scan_com")

local kDistressBeaconSoundDistance = 100
local kDistressBeaconSoundMarine = PrecacheAsset("sound/NS2.fev/marine/common/distress_beacon_marine")

Observatory.kDistressBeaconTime = kDistressBeaconTime
Observatory.kDistressBeaconRange = kDistressBeaconRange
Observatory.kDetectionRange = 22 // From NS1 

local kPassiveDetectorSoundDelay = 30
local kAnimationGraph = PrecacheAsset("models/marine/observatory/observatory.animation_graph")

local networkVars = { }

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
AddMixinNetworkVars(EnergyMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)

function Observatory:OnCreate()

    ScriptActor.OnCreate(self)
    
    if Server then
    
        self.distressBeaconSound = Server.CreateEntity(SoundEffect.kMapName)
        self.distressBeaconSound:SetAsset(kDistressBeaconSoundMarine)
        self.distressBeaconSound:SetRelevancyDistance(Math.infinity)
        
    end
    
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
    InitMixin(self, EnergyMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, DetectorMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, PowerConsumerMixin)
    InitMixin(self, ParasiteMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
    self.distressorigin = nil
    
end

function Observatory:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    InitMixin(self, WeldableMixin)
    
    self:SetModel(Observatory.kModelName, kAnimationGraph)
    
    if Server then
    
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

function Observatory:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    if Server then
    
        DestroyEntity(self.distressBeaconSound)
        self.distressBeaconSound = nil

        
    end
    
end

function Observatory:GetTechButtons(techId)
    return { kTechId.Scan, kTechId.PhaseTech, kTechId.None, kTechId.None, 
            kTechId.DistressBeacon, kTechId.MotionTracking, kTechId.None, kTechId.None }
end

function Observatory:GetDetectionRange()

    if GetIsUnitActive(self) then
        return Observatory.kDetectionRange
    end
    
    return 0
    
end

function Observatory:GetReceivesStructuralDamage()
    return true
end

function Observatory:GetIdleSoundInterval()
    return kPassiveDetectorSoundDelay
end

function Observatory:GetDamagedAlertId()
    return kTechId.MarineAlertStructureUnderAttack
end

function Observatory:GetDistressOrigin()

    // Respawn at nearest occupied command station
    local origin = self:GetOrigin()
    
    local nearest = GetNearest(origin, "CommandStation", self:GetTeamNumber(), function(ent) return ent:GetIsBuilt() and ent:GetIsOccupied() end)
    if nearest then
        origin = nearest:GetModelOrigin()
    end
    
    return origin
    
end

function Observatory:GetCanUpdateEnergy()
    return GetIsUnitActive(self)
end

local function TriggerMarineBeaconEffects(self)

    for index, marine in ipairs(GetEntitiesForTeam("Marine", self:GetTeamNumber())) do
    
        if marine:GetIsAlive() then
            marine:TriggerEffects("player_beacon")
        end
    
    end

end

function Observatory:TriggerDistressBeacon()

    local success = false
    
    if not self:GetIsBeaconing() then

        self.distressBeaconSound:Start()

        local origin = self:GetDistressOrigin()
        
        if origin then
        
            self.distressBeaconSound:SetOrigin(origin)

            // Beam all faraway players back in a few seconds!
            self.distressBeaconTime = Shared.GetTime() + Observatory.kDistressBeaconTime
            
            if Server then
            
                TriggerMarineBeaconEffects(self)
                
                local location = GetLocationForPoint(self:GetDistressOrigin())
                local locationName = location and location:GetName() or ""
                local locationId = Shared.GetStringIndex(locationName)
                SendTeamMessage(self:GetTeam(), kTeamMessageTypes.Beacon, locationId)
                
            end
            
            success = true
        
        end
    
    end
    
    return success, not success
    
end

function Observatory:CancelDistressBeacon()

    self.distressBeaconTime = nil
    self.distressorigin = nil
    self.locationId = nil
    self.distressBeaconSound:Stop()

end

local function GetIsPlayerInRoom(self, player)
    return Shared.GetStringIndex(player:GetLocationName()) == self.locationId
end

local function GetPlayersToBeacon(self, toOrigin)

    local players = { }
	local locationName = self:GetLocationName()

    for index, player in ipairs(self:GetTeam():GetPlayers()) do
        // Don't affect Commanders
        if not player:isa("Commander") then

            // Don't respawn players that are already nearby.
            if not GetIsPlayerInRoom(self, player, locationName) and (not HasMixin(self, "Devourable") or not self:GetIsDevoured()) and (not player.GetIsRagdoll or not player:GetIsRagdoll()) then
                table.insert(players, player)
            end
        end
    end
    
    return players
    
end

local function ResurrectPlayer(self, player, distressOrigin)
    local TechID = kTechId.Marine
    if player:GetIsAlive() then
        TechID = player:GetTechId()
    end
    local extents = LookupTechData(TechID, kTechDataMaxExtents)
    local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
    local range = Observatory.kDistressBeaconRange
    local spawnPoint = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, distressOrigin, 2, range, EntityFilterAll())
    local team = player:GetTeam()
    local success, player = team:ReplaceRespawnPlayer(player, spawnPoint, player:GetAngles())
    if success then
        team:RemovePlayerFromRespawnQueue(player)
        player:SetCameraDistance(0)
    end
    return success
end

// Spawn players at nearest Command Station to Observatory - not initial marine start like in NS1. Allows relocations and more versatile tactics.
local function RespawnPlayer(self, player, distressOrigin)

    // Always marine capsule (player could be dead/spectator)
    local extents = LookupTechData(kTechId.Marine, kTechDataMaxExtents)
    local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
    local range = Observatory.kDistressBeaconRange
    local spawnPoint = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, distressOrigin, 2, range, EntityFilterAll())
    
    if spawnPoint then
    
        player:SetOrigin(spawnPoint)
        if player.TriggerBeaconEffects then
            player:TriggerBeaconEffects()
        end
        
    else
        Print("Observatory:RespawnPlayer(): Couldn't find space to respawn player.")
    end
    
    return spawnPoint ~= nil
    
end

function Observatory:PerformDistressBeacon()

    self.distressBeaconSound:Stop()
    
    local anyPlayerWasBeaconed = false
    
    //local distressOrigin = self:GetDistressOrigin()
    local distressOrigin = self.distressorigin
    for index, player in ipairs(GetPlayersToBeacon(self, distressOrigin)) do
        local success = false
        if player:GetIsAlive() then
            success = RespawnPlayer(self, player, distressOrigin)
        else
            success = ResurrectPlayer(self, player, distressOrigin)      
        end
        if success then
            anyPlayerWasBeaconed = true
        end
        
    end
    
    // Also respawn players that are spawning in at infantry portals near command station (use a little extra range to account for vertical difference)
    //for index, ip in ipairs(GetEntitiesForTeamWithinRange("InfantryPortal", self:GetTeamNumber(), distressOrigin, kInfantryPortalAttachRange + 1)) do
        //ip:FinishSpawn()
    //end
    self.distressorigin = nil
    self.locationId = nil
    // Play mega-spawn sound in world.
    if anyPlayerWasBeaconed then
        self:TriggerEffects("distress_beacon_complete")
    end
    
end

function Observatory:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)

    if self:GetIsBeaconing() and (Shared.GetTime() >= self.distressBeaconTime) then
    
        self:PerformDistressBeacon()
        
        self.distressBeaconTime = nil
            
    end
    
end

function Observatory:PerformActivation(techId, position, normal, commander)

    local success = false
    
    if GetIsUnitActive(self) then
    
        if techId == kTechId.DistressBeacon then
            return self:TriggerDistressBeacon()
        end
        
    end
    
    return ScriptActor.PerformActivation(self, techId, position, normal, commander)
    
end

function Observatory:OverrideTechTreeAction(techNode, position, orientation, commander)

    local success = false
    local keepProcessing = true
    local techId = techNode:GetTechId()
    if techId == kTechId.Recycle and self:GetIsBeaconing() then
        self:CancelDistressBeacon()
        local team = self:GetTeam()
        if team then
            local bNode = team:GetTechTree():GetTechNode(kTechId.DistressBeacon)
            if bNode ~= nil then
                team:SetTeamResources(team:GetTeamResources() + bNode:GetCost())
            end
        end
        success = true
        keepProcessing = false
    end
    return success, keepProcessing
    
end

function Observatory:GetIsBeaconing()
    return self.distressBeaconTime ~= nil
end

if Server then

    function Observatory:OnKill(killer, doer, point, direction)

        if self:GetIsBeaconing() then
            self:CancelDistressBeacon()
        end
        
        ScriptActor.OnKill(self, killer, doer, point, direction)
        
    end
    
end

function Observatory:OverrideVisionRadius()
    return Observatory.kDetectionRange
end

if Server then

    function OnConsoleDistress()
    
        if Shared.GetCheatsEnabled() or Shared.GetDevMode() then
            local beacons = Shared.GetEntitiesWithClassname("Observatory")
            for i, beacon in ientitylist(beacons) do
                beacon:TriggerDistressBeacon()
            end
        end
        
    end
    
    Event.Hook("Console_distress", OnConsoleDistress)
    
end

if Server then

    function Observatory:OnConstructionComplete()

        if self.phaseTechResearched then

            local techTree = self:GetTeam():GetTechTree()
            if techTree then
                local researchNode = techTree:GetTechNode(kTechId.PhaseTech)
                researchNode:SetResearched(true)
                techTree:QueueOnResearchComplete(kTechId.PhaseTech, self)
            end    
            
        end

    end
    
end    

function Observatory:GetHealthbarOffset()
    return 0.9
end 


Shared.LinkClassToMap("Observatory", Observatory.kMapName, networkVars)