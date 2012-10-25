// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Armory.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/RecycleMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/AlienDetectableMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CombatMixin.lua")

class 'Armory' (ScriptActor)

Armory.kMapName = "armory"

Armory.kModelName = PrecacheAsset("models/marine/armory/armory.model")
local kAnimationGraph = PrecacheAsset("models/marine/armory/armory.animation_graph")

// Looping sound while using the armory
Armory.kResupplySound = PrecacheAsset("sound/NS2.fev/marine/structures/armory_resupply")

Armory.kAttachPoint = "Root"

Armory.kAdvancedArmoryChildModel = PrecacheAsset("models/marine/advanced_armory/advanced_armory.model")
Armory.kAdvancedArmoryAnimationGraph = PrecacheAsset("models/marine/advanced_armory/advanced_armory.animation_graph")

Armory.kThinkTime = .3
Armory.kHealAmount = 10
Armory.kResupplyInterval = 1

// Players can use menu and be supplied by armor inside this range
Armory.kResupplyUseRange = 2.0

Armory.kDeployTime = 1

if Server then
    Script.Load("lua/Armory_Server.lua")
elseif Client then
    Script.Load("lua/Armory_Client.lua")
end

Shared.PrecacheSurfaceShader("models/marine/armory/health_indicator.surface_shader")
    
local networkVars =
{
    // How far out the arms are for animation (0-1)
    loggedInEast     = "boolean",
    loggedInNorth    = "boolean",
    loggedInSouth    = "boolean",
    loggedInWest     = "boolean",
    deployed         = "boolean"
}

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
AddMixinNetworkVars(AlienDetectableMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)

function Armory:OnCreate()

    ScriptActor.OnCreate(self)
    
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
    InitMixin(self, RagdollMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, AlienDetectableMixin)
    InitMixin(self, ParasiteMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end

    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
    
    // False if the player that's logged into a side is only nearby, true if
    // the pressed their key to open the menu to buy something. A player
    // must use the armory once "logged in" to be able to buy anything.
    self.loginEastAmount = 0
    self.loginNorthAmount = 0
    self.loginWestAmount = 0
    self.loginSouthAmount = 0
    
    self.timeScannedEast = 0
    self.timeScannedNorth = 0
    self.timeScannedWest = 0
    self.timeScannedSouth = 0
    
    self.deployed = false
    
end

function Armory:OnInitialized()

    ScriptActor.OnInitialized(self)

    self:SetModel(Armory.kModelName, kAnimationGraph)
    
    InitMixin(self, WeldableMixin)
    
    if Server then    
    
        self.loggedInArray = { false, false, false, false }
        
        // Use entityId as index, store time last resupplied
        self.resuppliedPlayers = { }

        self:SetNextThink(Armory.kThinkTime)
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, StaticTargetMixin)
        
    elseif Client then
    
        self:OnInitClient()        
        InitMixin(self, UnitStatusMixin)
        
    end
    
end

function Armory:GetTechIfResearched(buildId, researchId)

    local techTree = nil
    if Server then
        techTree = self:GetTeam():GetTechTree()
    else
        techTree = GetTechTree()
    end
    ASSERT(techTree ~= nil)
    
    // If we don't have the research, return it, otherwise return buildId
    local researchNode = techTree:GetTechNode(researchId)
    ASSERT(researchNode ~= nil)
    ASSERT(researchNode:GetIsResearch())
    return ConditionalValue(researchNode:GetResearched(), buildId, researchId)
    
end

function Armory:GetTechButtons(techId)

    local techButtons = nil

    if self:GetTechId() == kTechId.Armory then
    
        techButtons = { kTechId.AdvancedArmoryUpgrade, kTechId.None, kTechId.None, kTechId.None,
                        kTechId.HandGrenadesTech, kTechId.None, kTechId.None, kTechId.None }
    
    else
    
        techButtons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                        kTechId.HandGrenadesTech, kTechId.None, kTechId.None, kTechId.None }
        
    end
    
    return techButtons
    
end

function Armory:OnUpdatePoseParameters()

    if GetIsUnitActive(self) and self.deployed then
        
        if self.loginNorthAmount then
            self:SetPoseParam("log_n", self.loginNorthAmount)
        end
        
        if self.loginSouthAmount then
            self:SetPoseParam("log_s", self.loginSouthAmount)
        end
        
        if self.loginEastAmount then
            self:SetPoseParam("log_e", self.loginEastAmount)
        end
        
        if self.loginWestAmount then
            self:SetPoseParam("log_w", self.loginWestAmount)
        end
        
        if self.scannedParamValue then
        
            for extension, value in pairs(self.scannedParamValue) do
                self:SetPoseParam("scan_" .. extension, value)
            end
            
        end
        
    end
    
end

local function UpdateArmoryAnim(self, extension, loggedIn, scanTime, timePassed)

    local loggedInName = "log_" .. extension
    local loggedInParamValue = ConditionalValue(loggedIn, 1, 0)

    if extension == "n" then
        self.loginNorthAmount = Clamp(Slerp(self.loginNorthAmount, loggedInParamValue, timePassed * 2), 0, 1)
    elseif extension == "s" then
        self.loginSouthAmount = Clamp(Slerp(self.loginSouthAmount, loggedInParamValue, timePassed * 2), 0, 1)
    elseif extension == "e" then
        self.loginEastAmount = Clamp(Slerp(self.loginEastAmount, loggedInParamValue, timePassed * 2), 0, 1)
    elseif extension == "w" then
        self.loginWestAmount = Clamp(Slerp(self.loginWestAmount, loggedInParamValue, timePassed * 2), 0, 1)
    end
    
    local scannedName = "scan_" .. extension
    self.scannedParamValue = self.scannedParamValue or { }
    self.scannedParamValue[extension] = ConditionalValue(scanTime == 0 or (Shared.GetTime() > scanTime + 3), 0, 1)
    
end

function Armory:OnUpdate(deltaTime)

    if Client then
        self:UpdateArmoryWarmUp()
    end
    
    if GetIsUnitActive(self) and self.deployed then
    
        // Set pose parameters according to if we're logged in or not
        UpdateArmoryAnim(self, "e", self.loggedInEast, self.timeScannedEast, deltaTime)
        UpdateArmoryAnim(self, "n", self.loggedInNorth, self.timeScannedNorth, deltaTime)
        UpdateArmoryAnim(self, "w", self.loggedInWest, self.timeScannedWest, deltaTime)
        UpdateArmoryAnim(self, "s", self.loggedInSouth, self.timeScannedSouth, deltaTime)
        
    end
    
    ScriptActor.OnUpdate(self, deltaTime)
    
end

function Armory:GetReceivesStructuralDamage()
    return true
end

function Armory:GetDamagedAlertId()
    return kTechId.MarineAlertStructureUnderAttack
end

function Armory:OnUpdateAnimationInput(modelMixin)

    PROFILE("Armory:OnUpdateAnimationInput")
	modelMixin:SetAnimationInput("powered", true)
    
end

function Armory:GetItemList()
    
    local itemList = {   
        kTechId.Mines, 
        kTechId.Shotgun,
        kTechId.Welder,
    }
    
    if self:GetTechId() == kTechId.AdvancedArmory then
    
	    itemList = {   
	        kTechId.Mines,
	        kTechId.Shotgun,
	        kTechId.Welder,
	        kTechId.GrenadeLauncher,
	    }
	    
    end
    
    return itemList
    
end

if Server then
    /* not used anymore since all animation are now client side
    function Armory:OnTag(tagName)
        if tagName == "deploy_end" then
            self.deployed = true
        end
    end
    */

end

Shared.LinkClassToMap("Armory", Armory.kMapName, networkVars)

class 'AdvancedArmory' (Armory)

AdvancedArmory.kMapName = "advancedarmory"

Shared.LinkClassToMap("AdvancedArmory", AdvancedArmory.kMapName, {})

class 'ArmoryAddon' (ScriptActor)

ArmoryAddon.kMapName = "ArmoryAddon"

local addonNetworkVars =
{
    // required for smoother raise animation
    creationTime = "float"
}

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

function ArmoryAddon:OnInitialized()

    ScriptActor.OnCreate(self)
    
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

local kArmoryHealthbarOffset = Vector(0, 1.5, 0)
function Armory:GetHealthbarOffset()
    return kArmoryHealthbarOffset
end 

Shared.LinkClassToMap("ArmoryAddon", ArmoryAddon.kMapName, addonNetworkVars)