-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Armory.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Removed unneeded mixins and adjusted weapon techids

Script.Load("lua/Mixins/BaseModelMixin.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/AchievementGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/RecycleMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/IdleMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/SleeperMixin.lua")

class 'Armory' (ScriptActor)

Armory.kMapName = "armory"

Armory.kModelName = PrecacheAsset("models/marine/armory/armory.model")
local kAnimationGraph = PrecacheAsset("models/marine/armory/armory.animation_graph")

-- Looping sound while using the armory
Armory.kResupplySound = PrecacheAsset("sound/NS2.fev/marine/structures/armory_resupply")

Armory.kAttachPoint = "Root"

Armory.kAdvancedArmoryChildModel = PrecacheAsset("models/marine/advanced_armory/advanced_armory.model")
Armory.kAdvancedArmoryAnimationGraph = PrecacheAsset("models/marine/advanced_armory/advanced_armory.animation_graph")

-- Players can use menu and be supplied by armor inside this range
Armory.kResupplyUseRange = 2.0
Armory.kResupplyInterval = .8

local kLoginAndResupplyTime = 1

if Server then
    Script.Load("lua/Armory_Server.lua")
elseif Client then
    Script.Load("lua/Armory_Client.lua")
end

PrecacheAsset("models/marine/armory/health_indicator.surface_shader")
    
local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(RecycleMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)

function Armory:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, AchievementGiverMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, RecycleMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, PowerConsumerMixin)
    InitMixin(self, ParasiteMixin)
    
    if Server then
        InitMixin(self, SleeperMixin)
    elseif Client then
        InitMixin(self, CommanderGlowMixin)
    end

    self:SetUpdates(true)
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
    
end

-- Check if friendly players are nearby and facing armory and heal/resupply them
local function LoginAndResupply(self)
    
    -- Make sure players are still close enough, alive, marines, etc.
    -- Give health and ammo to nearby players.
    if GetIsUnitActive(self) then
        self:ResupplyPlayers()
    end

    return true

end

function Armory:OnInitialized()

    ScriptActor.OnInitialized(self)

    self:SetModel(Armory.kModelName, kAnimationGraph)

    InitMixin(self, WeldableMixin)

    if Server then    
    
        self.loggedInArray = { false, false, false, false }

        -- Use entityId as index, store time last resupplied
        self.resuppliedPlayers = { }

        self:AddTimedCallback(LoginAndResupply, kLoginAndResupplyTime)

        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end

        InitMixin(self, StaticTargetMixin)
        
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        
    end
    
    InitMixin(self, IdleMixin)
    
end

function Armory:GetCanBeUsedConstructed(byPlayer)
    return false
end

function Armory:GetCanSleep()
    return true
end

function Armory:GetTechButtons(techId)

    local techButtons = nil

    techButtons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                    kTechId.HandGrenadesTech, kTechId.None, kTechId.None, kTechId.None }

    -- Show button to upgraded to advanced armory
    if self:GetTechId() == kTechId.Armory and self:GetResearchingId() ~= kTechId.AdvancedArmoryUpgrade then
        techButtons[1] = kTechId.AdvancedArmoryUpgrade
    end

    return techButtons

end

function Armory:GetRequiresPower()
    return false
end

function Armory:OnUse()
    return false
end

function Armory:GetHealthbarOffset()
    return 1.4
end 

function Armory:GetReceivesStructuralDamage()
    return true
end

function Armory:GetDamagedAlertId()
    return kTechId.MarineAlertStructureUnderAttack
end

function Armory:OnUpdatePoseParameters()
    if not self.setpose then
        self:SetPoseParam("log_n", 0)
        self:SetPoseParam("log_s", 0)
        self:SetPoseParam("log_e", 0)
        self:SetPoseParam("log_w", 0)
        self.setpose = true
    end    
end

Shared.LinkClassToMap("Armory", Armory.kMapName, networkVars)

class 'AdvancedArmory' (Armory)

AdvancedArmory.kMapName = "advancedarmory"

Shared.LinkClassToMap("AdvancedArmory", AdvancedArmory.kMapName, {})

class 'ArmoryAddon' (ScriptActor)

ArmoryAddon.kMapName = "ArmoryAddon"

local addonNetworkVars =
{
    -- required for smoother raise animation
    creationTime = "time"
}

AddMixinNetworkVars(BaseModelMixin, addonNetworkVars)
AddMixinNetworkVars(ClientModelMixin, addonNetworkVars)
AddMixinNetworkVars(TeamMixin, addonNetworkVars)

function ArmoryAddon:OnCreate()

    ScriptActor.OnCreate(self)

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, TeamMixin)

    if Server then
        self.creationTime = Shared.GetTime()
    end
    
end

function ArmoryAddon:GetHealthbarOffset()
    return 1.7
end 

function ArmoryAddon:OnInitialized()

    ScriptActor.OnInitialized(self)

    self:SetModel(Armory.kAdvancedArmoryChildModel, Armory.kAdvancedArmoryAnimationGraph)
    
end

function ArmoryAddon:OnUpdatePoseParameters()

    PROFILE("ArmoryAddon:OnUpdatePoseParameters")

    local researchProgress = Clamp((Shared.GetTime() - self.creationTime) / kAdvancedArmoryResearchTime, 0, 1)
    self:SetPoseParam("spawn", researchProgress)

end

function ArmoryAddon:OnUpdateAnimationInput(modelMixin)

    PROFILE("ArmoryAddon:OnUpdateAnimationInput")

    local parent = self:GetParent()
    if parent then
        modelMixin:SetAnimationInput("built", parent:GetTechId() == kTechId.AdvancedArmory)
    end

end

function ArmoryAddon:OnGetIsVisible(visibleTable, viewerTeamNumber)

    local parent = self:GetParent()
    if parent then
        visibleTable.Visible = parent:GetIsVisible()
    end

end

Shared.LinkClassToMap("ArmoryAddon", ArmoryAddon.kMapName, addonNetworkVars)
