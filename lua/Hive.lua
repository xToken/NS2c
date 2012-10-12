// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Hive.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/CommandStructure.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/HasUmbraMixin.lua")

class 'Hive' (CommandStructure)

local networkVars = 
{
}

AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(HiveVisionMixin, networkVars)
AddMixinNetworkVars(HasUmbraMixin, networkVars)

kResearchToHiveType =
{
    [kTechId.UpgradeToCragHive]  =  kTechId.CragHive,
    [kTechId.UpgradeToShadeHive] =  kTechId.ShadeHive,
    [kTechId.UpgradeToShiftHive] =  kTechId.ShiftHive,
    [kTechId.UpgradeToWhipHive]  =  kTechId.WhipHive,
}

Hive.kMapName = "hive"

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

Hive.kTriggerCatalyst2DSound = PrecacheAsset("sound/NS2.fev/alien/commander/catalyze_2D")
Hive.kTriggerCatalystSound = PrecacheAsset("sound/NS2.fev/alien/commander/catalyze_3D")

Hive.kHealRadius = 12.7     // From NS1
Hive.kHealthPercentage = .15
Hive.kHealthUpdateTime = 2

if Server then
    Script.Load("lua/Hive_Server.lua")
else
    Script.Load("lua/Hive_Client.lua")
end

function Hive:OnCreate()

    CommandStructure.OnCreate(self)
    
    InitMixin(self, CloakableMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, DissolveMixin)
    InitMixin(self, HasUmbraMixin)
    
    if Server then
        
        self.upgradeTechId = kTechId.None
        
        self:SetTechId(kTechId.Hive)

        self.timeOfLastEgg = Shared.GetTime()
        self.queuedplayer = nil
        self.timeWaveEnds = 0
    end

end

function Hive:OnInitialized()

    CommandStructure.OnInitialized(self)
    
    self:SetModel(Hive.kModelName, kAnimationGraph)
    
    // Pre-compute list of egg spawn points.
    if Server then
        
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

if Client then

    function Hive:GetHelpArrowsCinematicName()
        return kHelpArrowsCinematicName
    end
    
end

function Hive:GetShowOrderLine()
    return true
end

function Hive:OnCollision(entity)

    // We may hook this up later.
    /*if entity:isa("Player") and GetEnemyTeamNumber(self:GetTeamNumber()) == entity:GetTeamNumber() then    
        self.lastTimeEnemyTouchedHive = Shared.GetTime()
    end*/
        
end

function GetIsHiveTypeResearch(techId)
    return techId == kTechId.UpgradeToCragHive or techId == kTechId.UpgradedToShadeHive or techId == kTechId.UpgradeToShiftHive or techId == kTechId.UpgradeToWhipHive
end

function GetHiveTypeResearchAllowed(self, techId)
    
    local hiveTypeTechId = kResearchToHiveType[techId]
    return not GetHasTech(self, hiveTypeTechId) and not GetIsTechResearching(self, techId)

end

function Hive:GetMainMenuButtons()
    return nil
end

function Hive:GetCanResearchOverride(techId)

    local allowed = true

    if GetIsHiveTypeResearch(techId) then
        allowed = GetHiveTypeResearchAllowed(self, techId)
    end
    
    return allowed and GetIsUnitActive(self)

end

local function GetLifeFormButtons(self)
    return nil
end

function Hive:GetTechButtons(techId)    
    return nil
end

function Hive:OnManufactured(createdEntity)
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

local kHiveHealthbarOffset = Vector(0, .8, 0)
function Hive:GetHealthbarOffset()
    return kHiveHealthbarOffset
end 

// Don't show objective after we become cloaked
function Hive:OnCloak()
    local attached = self:GetAttached()
    if attached then
        attached.showObjective = false
    end
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