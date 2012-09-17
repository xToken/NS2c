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

Script.Load("lua/Mixins/ModelMixin.lua")
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
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

class 'Shift' (ScriptActor)

Shift.kMapName = "shift"

Shift.kModelName = PrecacheAsset("models/alien/shift/shift.model")

local kAnimationGraph = PrecacheAsset("models/alien/shift/shift.animation_graph")

Shift.kEnergizeSoundEffect = PrecacheAsset("sound/NS2.fev/alien/structures/shift/energize")
Shift.kEnergizeTargetSoundEffect = PrecacheAsset("sound/NS2.fev/alien/structures/shift/energize_player")
//Shift.kRecallSoundEffect = PrecacheAsset("sound/NS2.fev/alien/structures/shift/recall")


Shift.kEnergizeEffect = PrecacheAsset("cinematics/alien/shift/energize.cinematic")
Shift.kEnergizeSmallTargetEffect = PrecacheAsset("cinematics/alien/shift/energize_small.cinematic")
Shift.kEnergizeLargeTargetEffect = PrecacheAsset("cinematics/alien/shift/energize_large.cinematic")
Shift.kEnergizeThinkTime = 2

local networkVars =
{
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
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
AddMixinNetworkVars(CombatMixin, networkVars)

function Shift:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
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
    InitMixin(self, CombatMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)    
    end
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)

end

function Shift:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(Shift.kModelName, kAnimationGraph)
    
    if Server then
    
        InitMixin(self, StaticTargetMixin)
    
        self:AddTimedCallback(Shift.EnergizeInRange, Shift.kEnergizeThinkTime)
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
        
    end

end

function Shift:GetCanBeUsedConstructed()
    return true
end   

function Shift:GetCanBeUsed(player, useSuccessTable)
    local hasupg, level = GetHasRedeploymentUpgrade(player)
    if not self:GetCanConstruct(player) and not(hasupg and level > 0) then
        useSuccessTable.useSuccess = false
    else
        useSuccessTable.useSuccess = true
    end
end

function Shift:EnergizeInRange()

    if self:GetIsBuilt() then
    
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

function Shift:ConstructOverride(deltaTime)
    return deltaTime / 2
end

function Shift:OnUse(player, elapsedTime, useAttachPoint, usePoint, useSuccessTable)
    local hasupg, level = GetHasRedeploymentUpgrade(player)
    if hasupg and level > 0 and self:GetIsBuilt() and self:GetTeamNumber() == player:GetTeamNumber() then
        self:TeleportPlayer(player, level)
    end
end

if Server then

    function Shift:OnUpdate(deltaTime)
        PROFILE("Shift:OnUpdate")
        ScriptActor.OnUpdate(self, deltaTime)
    end
    
end

function Shift:TeleportPlayer(player, level)
    if Server then
        if player.nextredeploy == nil or player.nextredeploy < Shared.GetTime() then
            local validshifts = { }
            local shifts = GetEntitiesForTeam("Shift", self:GetTeamNumber())
            local success = false
            for i, shift in ipairs(shifts) do
                local shiftinfo = { shift = shift, dist = 0 }
                local toTarget = shift:GetOrigin() - player:GetOrigin()
                local distanceToTarget = toTarget:GetLength()
                shiftinfo.dist = distanceToTarget
                if shift:GetIsBuilt() and self ~= shift and distanceToTarget > 5 then
                    table.insert(validshifts, shiftinfo)
                end
             end
             local selectedshift
             local selectedshiftdist = 0
             for s = 1, #validshifts do
                if selectedshiftdist < validshifts[s].dist then
                    selectedshift = validshifts[s].shift
                    selectedshiftdist = validshifts[s].dist
                end
             end
             if selectedshift then
                local TechID = kTechId.Skulk
                if player:GetIsAlive() then
                    TechID = player:GetTechId()
                end
                local extents = LookupTechData(TechID, kTechDataMaxExtents)
                local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
                local range = 4
                local spawnPoint = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, selectedshift:GetOrigin(), 2, range, EntityFilterAll())
                if spawnPoint then
                    local validForPlayer = GetIsPlacementForTechId(spawnPoint, true, TechID)
                    local notNearResourcePoint = #GetEntitiesWithinRange("ResourcePoint", spawnPoint, 2) == 0
                    if notNearResourcePoint then
                        Shared.PlayWorldSound(nil, Alien.kTeleportSound, nil, self:GetOrigin())
                        SpawnPlayerAtPoint(player, spawnPoint)
                        success = true
                        player.nextredeploy = Shared.GetTime() + (kRedploymentCooldownBase / level)
                    end
                end
                if not success then
                    player:TriggerInvalidSound()
                end
            end
        end
    end
end

Shared.LinkClassToMap("Shift", Shift.kMapName, networkVars)