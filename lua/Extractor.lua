-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Extractor.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- Marine resource extractor. Gathers resources when built on a nozzle.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Removed unneeded mixins and added electrify hooks.

Script.Load("lua/RecycleMixin.lua")

Script.Load("lua/ResourceTower.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/ElectrifyMixin.lua")
Script.Load("lua/EnergyMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/DetectableMixin.lua")

class 'Extractor' (ResourceTower)

Extractor.kMapName = "extractor"

Extractor.kModelName = PrecacheAsset("models/marine/extractor/extractor.model")

local kAnimationGraph = PrecacheAsset("models/marine/extractor/extractor.animation_graph")

Shared.PrecacheModel(Extractor.kModelName)

local networkVars = { }

AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(RecycleMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)
AddMixinNetworkVars(EnergyMixin, networkVars)
AddMixinNetworkVars(ElectrifyMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)

function Extractor:OnCreate()

    ResourceTower.OnCreate(self)

    InitMixin(self, ResearchMixin)
    InitMixin(self, RecycleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, PowerConsumerMixin)
    InitMixin(self, ParasiteMixin)
    InitMixin(self, EnergyMixin)
    InitMixin(self, ElectrifyMixin)
    InitMixin(self, DamageMixin)
	InitMixin(self, DetectableMixin)
    InitMixin(self, SelectableMixin)

    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
end

function Extractor:OnInitialized()

    ResourceTower.OnInitialized(self)
    
    InitMixin(self, WeldableMixin)
    
    self:SetModel(Extractor.kModelName, kAnimationGraph)
    
    if Server then
    
        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
    elseif Client then
        InitMixin(self, UnitStatusMixin)
    end

end

function Extractor:GetDamagedAlertId()
    return kTechId.MarineAlertExtractorUnderAttack
end

function Extractor:GetTechButtons(techId)
    if self:GetIsElectrified() then
        return { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
             kTechId.None, kTechId.None, kTechId.None, kTechId.None }
    end
    return { kTechId.Electrify, kTechId.None, kTechId.None, kTechId.None,
             kTechId.None, kTechId.None, kTechId.None, kTechId.None }
end

function Extractor:OverrideGetEnergyUpdateRate()
    return kElectrifyEnergyRegain
end

function Extractor:GetCanUpdateEnergy()
    return self:GetIsElectrified() and self:GetCanRegainEnergy()
end

function Extractor:GetHealthbarOffset()
    return 2.0
end 

function Extractor:GetUnitNameOverride()
    
    local description = GetDisplayName(self)

    if self:GetIsElectrified() then
        description = "Electrified " .. description 
    end
    
    if HasMixin(self, "Construct") and not self:GetIsBuilt() then
        description = "Unbuilt " .. description
    end
    
    return description
    
end

Shared.LinkClassToMap("Extractor", Extractor.kMapName, networkVars)