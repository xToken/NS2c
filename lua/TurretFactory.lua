// NS2 - Classic
// lua\TurretFactory.lua
//

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
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")

class 'TurretFactory' (ScriptActor)

TurretFactory.kAnimationGraph = PrecacheAsset("models/marine/robotics_factory/robotics_factory.animation_graph")

TurretFactory.kMapName = "turretfactory"

TurretFactory.kModelName = PrecacheAsset("models/marine/robotics_factory/robotics_factory.model")

TurretFactory.kAttachPoint = "target"

TurretFactory.kActiveEffect = PrecacheAsset("cinematics/marine/roboticsfactory/active.cinematic")

local networkVars = { }

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
AddMixinNetworkVars(ParasiteMixin, networkVars)

function TurretFactory:OnCreate()

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
    InitMixin(self, TurretFactoryMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, PowerConsumerMixin)
    InitMixin(self, ParasiteMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end

    self:SetUpdates(true)
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)

end

function TurretFactory:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    InitMixin(self, WeldableMixin)
    
    self:SetModel(TurretFactory.kModelName, TurretFactory.kAnimationGraph)
    
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

function TurretFactory:GetReceivesStructuralDamage()
    return true
end

function TurretFactory:GetTechButtons(techId)

    local techButtons = {   kTechId.UpgradeTurretFactory, kTechId.None, kTechId.None, kTechId.None, 
               kTechId.None, kTechId.None, kTechId.None, kTechId.None }
               
    if self:GetTechId() == kTechId.AdvancedTurretFactory then
        techButtons[1] = kTechId.None
    end

    return techButtons
    
end

function TurretFactory:GetDamagedAlertId()
    return kTechId.MarineAlertStructureUnderAttack
end

function TurretFactory:OnResearchComplete(researchId)

    if researchId == kTechId.UpgradeTurretFactory then
        self:UpgradeToTechId(kTechId.AdvancedTurretFactory)
    end
        
end

function GetRoomHasNoTurretFactory(techId, origin, normal, commander)

    local location = GetLocationForPoint(origin)
    local locationName = location and location:GetName() or nil
    local validRoom = false
    
    if locationName then
    
        validRoom = true
    
        for index, tf in ientitylist(Shared.GetEntitiesWithClassname("TurretFactory")) do
            
            if tf:GetLocationName() == locationName then
                validRoom = false
                break
            end
            
        end
    
    end
    
    return validRoom

end

if Server then
    
    function TurretFactory:OnConstructionComplete()
        local entities = GetEntitiesWithMixinWithinRange("TurretFactoryMixin", self:GetOrigin(), kTurretFactoryAttachRange)
        for index, entity in ipairs(entities) do
            if entity:GetTeamNumber() == self:GetTeamNumber() then
                if entity.Completed then
                    entity:Completed()
                end
            end
        end
    end
    
    function TurretFactory:OnDestroy()
     
        local entities = GetEntitiesWithMixinWithinRange("TurretFactoryMixin", self:GetOrigin(), kTurretFactoryAttachRange)
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

function TurretFactory:GetHealthbarOffset()
    return 1
end 

Shared.LinkClassToMap("TurretFactory", TurretFactory.kMapName, networkVars)


class 'AdvancedTurretFactory' (TurretFactory)
AdvancedTurretFactory.kMapName = "advancedturretfactory"
Shared.LinkClassToMap("AdvancedTurretFactory", AdvancedTurretFactory.kMapName, { })