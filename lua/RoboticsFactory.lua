// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\RoboticsFactory.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Updated to add hooks for turret factory mixin, removal of production values.

Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/RecycleMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/TurretFactoryMixin.lua")
Script.Load("lua/DetectableMixin.lua")
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

class 'RoboticsFactory' (ScriptActor)

RoboticsFactory.kAnimationGraph = PrecacheAsset("models/marine/robotics_factory/robotics_factory.animation_graph")

RoboticsFactory.kMapName = "roboticsfactory"

RoboticsFactory.kModelName = PrecacheAsset("models/marine/robotics_factory/robotics_factory.model")

RoboticsFactory.kAttachPoint = "target"

RoboticsFactory.kCloseDelay  = .5
RoboticsFactory.kActiveEffect = PrecacheAsset("cinematics/marine/roboticsfactory/active.cinematic")
RoboticsFactory.kAnimOpen   = "open"
RoboticsFactory.kAnimClose  = "close"

local kOpenSound = PrecacheAsset("sound/NS2.fev/marine/structures/roboticsfactory_open")
local kCloseSound = PrecacheAsset("sound/NS2.fev/marine/structures/roboticsfactory_close")

local networkVars =
{
    open = "boolean",
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
AddMixinNetworkVars(TurretFactoryMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

function RoboticsFactory:OnCreate()

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
    InitMixin(self, TurretFactoryMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, ParasiteMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end

    self:SetLagCompensated(true)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
        
    self.open = false

end

function RoboticsFactory:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    InitMixin(self, WeldableMixin)
    
    self:SetModel(RoboticsFactory.kModelName, RoboticsFactory.kAnimationGraph)
    
    self:SetPhysicsType(PhysicsType.Kinematic)
    
    self.researchId = Entity.invalidId
    
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

function RoboticsFactory:GetReceivesStructuralDamage()
    return true
end

function RoboticsFactory:GetShowOrderLine()
    return true
end

function RoboticsFactory:GetTechAllowed(techId, techNode, player)

    local allowed, canAfford = ScriptActor.GetTechAllowed(self, techId, techNode, player) 

    allowed = allowed and not self.open
    
    return allowed, canAfford
    
end

function RoboticsFactory:GetTechButtons(techId)

    local techButtons = {   kTechId.UpgradeRoboticsFactory, kTechId.None, kTechId.None, kTechId.None, 
               kTechId.None, kTechId.None, kTechId.None, kTechId.None }
               
    if self:GetTechId() == kTechId.ARCRoboticsFactory then
        techButtons[1] = kTechId.None
    end

    return techButtons
    
end

function RoboticsFactory:GetDamagedAlertId()
    return kTechId.MarineAlertStructureUnderAttack
end

function RoboticsFactory:GetPositionForEntity(entity)
    
    local direction = Vector(self:GetAngles():GetCoords().zAxis)    
    local origin = self:GetOrigin() + direction * 3.2
    
    if entity:GetIsFlying() then
        origin = GetHoverAt(entity, origin)
    end
    
    return Coords.GetLookIn( origin, direction )

end

function RoboticsFactory:ManufactureEntity()
    
end

// Actual creation of entity happens delayed.
function RoboticsFactory:OverrideCreateManufactureEntity(techId)

end

function RoboticsFactory:OnResearchComplete(researchId)

    if researchId == kTechId.UpgradeRoboticsFactory then
        self:UpgradeToTechId(kTechId.ARCRoboticsFactory)
    end
        
end

function RoboticsFactory:OnTag(tagName)
    
    PROFILE("RoboticsFactory:OnTag")
    
    if tagName == "open_start" then
        StartSoundEffectAtOrigin(kOpenSound, self:GetOrigin())
    elseif tagName == "close_start" then
        StartSoundEffectAtOrigin(kCloseSound, self:GetOrigin())
    end
    
end

function RoboticsFactory:OnUpdateAnimationInput(modelMixin)

    PROFILE("RoboticsFactory:OnUpdateAnimationInput")
    modelMixin:SetAnimationInput("open", self.open)

end

function GetRoomHasNoRoboticsFactory(techId, origin, normal, commander)

    local location = GetLocationForPoint(origin)
    local locationName = location and location:GetName() or nil
    local validRoom = false
    
    if locationName then
    
        validRoom = true
    
        for index, sentryBattery in ientitylist(Shared.GetEntitiesWithClassname("RoboticsFactory")) do
            
            if sentryBattery:GetLocationName() == locationName then
                validRoom = false
                break
            end
            
        end
    
    end
    
    return validRoom

end

if Server then

    function RoboticsFactory:OnUpdate()
               
    end
    
    function RoboticsFactory:OnConstructionComplete()
        local entities = GetEntitiesWithMixinWithinRange("TurretFactoryMixin", self:GetOrigin(), kRoboticsFactoryAttachRange)
        for index, entity in ipairs(entities) do
            if entity:GetTeamNumber() == self:GetTeamNumber() then
                if entity.Completed then
                    entity:Completed()
                end
            end
        end
    end
    
    function RoboticsFactory:OnDestroy()
     
        local entities = GetEntitiesWithMixinWithinRange("TurretFactoryMixin", self:GetOrigin(), kRoboticsFactoryAttachRange)
        for index, entity in ipairs(entities) do
            if entity:GetTeamNumber() == self:GetTeamNumber() then
                if entity.Destroyed then
                    entity:Destroyed()
                end
            end
        end
        
        ScriptActor.OnDestroy(self)
        
    end
    
end

function RoboticsFactory:OnUpdateAnimationInput(modelMixin)

    PROFILE("RoboticsFactory:OnUpdateAnimationInput")
	modelMixin:SetAnimationInput("powered", true)
    
end

function RoboticsFactory:OnOverrideOrder(order)

    // Convert default to set rally point.
    if order:GetType() == kTechId.Default then
        order:SetType(kTechId.SetRally)
    end
    
end

local kRoboticsFactoryHealthbarOffset = Vector(0, 1., 0)
function RoboticsFactory:GetHealthbarOffset()
    return kRoboticsFactoryHealthbarOffset
end 


Shared.LinkClassToMap("RoboticsFactory", RoboticsFactory.kMapName, networkVars, true)


class 'ARCRoboticsFactory' (RoboticsFactory)
ARCRoboticsFactory.kMapName = "arcroboticsfactory"
Shared.LinkClassToMap("ARCRoboticsFactory", ARCRoboticsFactory.kMapName, { })


class 'RoboticsAddon' (ScriptActor)

RoboticsAddon.kMapName = "RoboticsAddon"

local addonNetworkVars = { }

AddMixinNetworkVars(ModelMixin, addonNetworkVars)
AddMixinNetworkVars(TeamMixin, addonNetworkVars)

function RoboticsAddon:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)    
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    
end

Shared.LinkClassToMap("RoboticsAddon", RoboticsAddon.kMapName, addonNetworkVars)