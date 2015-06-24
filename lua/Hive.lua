// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Hive.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed most unneeded mixins for production, added passive infestation

Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/CommandStructure.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/InfestationMixin.lua")

class 'Hive' (CommandStructure)

local networkVars = { }

AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(HiveVisionMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(InfestationMixin, networkVars)

kResearchToHiveType =
{
    [kTechId.UpgradeToCragHive]  =  kTechId.CragHive,
    [kTechId.UpgradeToShadeHive] =  kTechId.ShadeHive,
    [kTechId.UpgradeToShiftHive] =  kTechId.ShiftHive,
    [kTechId.UpgradeToWhipHive]  =  kTechId.WhipHive,
}

Hive.kMapName = "hive"

PrecacheAsset("cinematics/vfx_materials/hive_frag.surface_shader")

Hive.kModelName = PrecacheAsset("models/alien/hive/hive.model")
local kAnimationGraph = PrecacheAsset("models/alien/hive/hive.animation_graph")

Hive.kWoundSound = PrecacheAsset("sound/NS2.fev/alien/structures/hive_wound")
// Play special sound for players on team to make it sound more dramatic or horrible
Hive.kWoundAlienSound = PrecacheAsset("sound/NS2.fev/alien/structures/hive_wound_alien")

Hive.kIdleMistEffect = PrecacheAsset("cinematics/alien/hive/idle_mist.cinematic")
Hive.kL2IdleMistEffect = PrecacheAsset("cinematics/alien/hive/idle_mist_lev2.cinematic")
Hive.kL3IdleMistEffect = PrecacheAsset("cinematics/alien/hive/idle_mist_lev3.cinematic")
Hive.kGlowEffect = PrecacheAsset("cinematics/alien/hive/glow.cinematic")
Hive.kSpecksEffect = PrecacheAsset("cinematics/alien/hive/specks.cinematic")

Hive.kCompleteSound = PrecacheAsset("sound/NS2.fev/alien/voiceovers/hive_complete")
Hive.kSpecialCompleteSound = PrecacheAsset("sound/ns2c.fev/ns2c/ui/now_we_dance")
Hive.kUnderAttackSound = PrecacheAsset("sound/NS2.fev/alien/voiceovers/hive_under_attack")
Hive.kStructureUnderAttackSound = PrecacheAsset("sound/NS2.fev/alien/voiceovers/structure_under_attack")
Hive.kHarvesterUnderAttackSound = PrecacheAsset("sound/NS2.fev/alien/voiceovers/harvester_under_attack")
Hive.kLifeformUnderAttackSound = PrecacheAsset("sound/NS2.fev/alien/voiceovers/lifeform_under_attack")
Hive.kDyingSound = PrecacheAsset("sound/NS2.fev/alien/voiceovers/hive_dying")
Hive.kEnemyApproachesSound = PrecacheAsset("sound/ns2c.fev/ns2c/ui/alien_enemyapproaches")

Hive.kTriggerCatalyst2DSound = PrecacheAsset("sound/NS2.fev/alien/commander/catalyze_2D")
Hive.kTriggerCatalystSound = PrecacheAsset("sound/NS2.fev/alien/commander/catalyze_3D")

Hive.kHealRadius = 12.7     // From NS1
Hive.kHealthPercentage = .15
Hive.kHealthUpdateTime = 2

local kHiveInfestationRadius = 25
local kHiveInfestationBlobDensity = 3
local kHiveInfestationGrowthRate = 0.1
local kHiveMinInfestationRadius = 5

if Server then
    Script.Load("lua/Hive_Server.lua")
elseif Client then
    Script.Load("lua/Hive_Client.lua")
end

function Hive:OnCreate()

    CommandStructure.OnCreate(self)
    
    InitMixin(self, SelectableMixin)
    InitMixin(self, CloakableMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, UmbraMixin)
        
    if Server then
        
        self.upgradeTechId = kTechId.None
        
        self:SetTechId(kTechId.Hive)

        self.timeOfLastEgg = Shared.GetTime()
        self.queuedplayer = nil
        self.timeWaveEnds = 0
        
    end
    
end

function Hive:OnInitialized()

    InitMixin(self, InfestationMixin)
    
    CommandStructure.OnInitialized(self)

    // Pre-compute list of egg spawn points.
    if Server then
        
        self:SetModel(Hive.kModelName, kAnimationGraph)
        SetAlwaysRelevantToTeam(self, true)
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, StaticTargetMixin)
        
    elseif Client then
    
        // Create glowy "plankton" swimming around hive, along with mist and glow
        local coords = self:GetCoords()
        self:AttachEffect(Hive.kSpecksEffect, coords)
        //self:AttachEffect(Hive.kGlowEffect, coords, Cinematic.Repeat_Loop)
        
        // For mist creation
        self:SetUpdates(true)
        
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)
        
        self.glowIntensity = ConditionalValue(self:GetIsBuilt(), 1, 0)
        
    end
    
end

local kHelpArrowsCinematicName = PrecacheAsset("cinematics/alien/commander_arrow.cinematic")
PrecacheAsset("models/misc/commander_arrow_aliens.model")

if Client then

    function Hive:GetHelpArrowsCinematicName()
        return kHelpArrowsCinematicName
    end
    
end

function Hive:SetIncludeRelevancyMask(includeMask)

    includeMask = bit.bor(includeMask, kRelevantToTeam2Commander)    
    CommandStructure.SetIncludeRelevancyMask(self, includeMask)    

end

function Hive:GetTechButtons(techId)

    local techButtons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }
    return techButtons
    
end

function Hive:OnCollision(entity)

    // We may hook this up later.
    /*if entity:isa("Player") and GetEnemyTeamNumber(self:GetTeamNumber()) == entity:GetTeamNumber() then    
        self.lastTimeEnemyTouchedHive = Shared.GetTime()
    end*/
    
end

function Hive:SetInfestationFullyGrown()
end

function GetIsHiveTypeResearch(techId)
    return techId == kTechId.UpgradeToCragHive or techId == kTechId.UpgradedToShadeHive or techId == kTechId.UpgradeToShiftHive or techId == kTechId.UpgradeToWhipHive
end

function GetHiveTypeResearchAllowed(self, techId)
    
    local hiveTypeTechId = kResearchToHiveType[techId]
    return not GetHasTech(self, hiveTypeTechId)

end

function Hive:GetMainMenuButtons()
    return nil
end

function Hive:GetGrowthRate()
    return kHiveInfestationRadius
end

function Hive:OverrideGetMaxRadius()
    return kHiveInfestationRadius
end

function Hive:OverrideGetMinRadius()
    return kHiveMinInfestationRadius
end

function Hive:OverrideGetGrowthRate()
    return kHiveInfestationGrowthRate
end

function Hive:OverrideGetInfestationDensity()
    return kHiveInfestationBlobDensity
end

function Hive:GetCanResearchOverride(techId)

    local allowed = true

    if GetIsHiveTypeResearch(techId) then
        allowed = GetHiveTypeResearchAllowed(self, techId)
    end
    
    return allowed and GetIsUnitActive(self)

end

function Hive:OnManufactured(createdEntity)
end

function Hive:GetAutoBuildScalar()
    return 1
end

function Hive:GetShowUnitStatusForOverride(forEntity)
    return not GetAreEnemies(self, forEntity)
end

function Hive:OnUpdateAnimationInput(modelMixin)

    PROFILE("Hive:OnUpdateAnimationInput")
    if self:GetIsBuilt() then
        modelMixin:SetAnimationInput("hive_deploy", false)
    end
    
end

function Hive:OnSighted(sighted)

    if sighted then
        local techPoint = self:GetAttached()
        if techPoint then
            techPoint:SetSmashScouted()
        end    
    end
    
    CommandStructure.OnSighted(self, sighted)

end

function Hive:GetHealthbarOffset()
    return 0.8
end 

function Hive:OverrideVisionRadius()
    return 20
end

Shared.LinkClassToMap("Hive", Hive.kMapName, networkVars)

class 'CragHive' (Hive)
CragHive.kMapName = "crag_hive"
Shared.LinkClassToMap("CragHive", CragHive.kMapName, { })

class 'ShadeHive' (Hive)
ShadeHive.kMapName = "shade_hive"
Shared.LinkClassToMap("ShadeHive", ShadeHive.kMapName, { })

class 'ShiftHive' (Hive)
ShiftHive.kMapName = "shift_hive"
Shared.LinkClassToMap("ShiftHive", ShiftHive.kMapName, { })

class 'WhipHive' (Hive)
WhipHive.kMapName = "whip_hive"
Shared.LinkClassToMap("WhipHive", WhipHive.kMapName, { })