-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GhostStructureMixin.lua
--
--    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Adjusted to acount for recycling refund changes

GhostStructureMixin = CreateMixin(GhostStructureMixin)
GhostStructureMixin.type = "GhostStructure"

GhostStructureMixin.kGhostStructureCancelRange = 3
local kScanTime = 0.1

GhostStructureMixin.expectedMixins =
{
    Construct = "Makes no sense to use this mixin for non constructable units.",
    Team = "Required to identify enemies and to cancel ghost mode by onuse from friendly players"
}

GhostStructureMixin.networkVars =
{
    isGhostStructure = "boolean"
}

local kGhoststructureMaterial = PrecacheAsset("cinematics/vfx_materials/ghoststructure.material") 

if Client then
    PrecacheAsset("cinematics/vfx_materials/ghoststructure.surface_shader")
end

local function ClearGhostStructure(self)

    self.isGhostStructure = false
    self:TriggerEffects("ghoststructure_destroy")
    local cost = LookupTechData(self:GetTechId(), kTechDataCostKey, 0)
    local refund = math.round(cost * kGhostStructureRefundModifier)
    self:GetTeam():AddTeamResources(refund)
    self:GetTeam():PrintWorldTextForTeamInRange(kWorldTextMessageType.Resources, refund, self:GetOrigin() + kWorldMessageResourceOffset, kResourceMessageRange)
    DestroyEntity(self)
    
end

local function CheckNearbyEnemies(self)

    if self:GetIsGhostStructure() then
        local enemies = GetEntitiesForTeamWithinRange("Player", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin() + Vector(0, 0.3, 0), GhostStructureMixin.kGhostStructureCancelRange)
        for _, enemy in ipairs (enemies) do
            if enemy:GetIsAlive() then
                ClearGhostStructure(self)
                break
            end
        end
    end
    return self:GetIsGhostStructure()
    
end

function GhostStructureMixin:__initmixin()
    
    PROFILE("GhostStructureMixin:__initmixin")
    
    -- init the entity in ghost structure mode
    if Server then
        self.isGhostStructure = true
		self:AddTimedCallback(CheckNearbyEnemies, kScanTime)
    end
    
end

function GhostStructureMixin:GetIsGhostStructure()
    return self.isGhostStructure
end

function GhostStructureMixin:PerformAction(techNode, position)

    if techNode.techId == kTechId.Cancel and self:GetIsGhostStructure() then
        ClearGhostStructure(self)
    end
    
end

if Server then

    local function CheckGhostState(self, doer)
    
        if self:GetIsGhostStructure() and GetAreFriends(self, doer) then
            self.isGhostStructure = false
        end
        
    end
    
	-- If we start constructing, make us no longer a ghost
    function GhostStructureMixin:OnConstruct(builder, buildPercentage)
        CheckGhostState(self, builder)
    end
    
    function GhostStructureMixin:OnConstructionComplete()
        self.isGhostStructure = false
    end

end

function GhostStructureMixin:OnUpdateRender()

    PROFILE("GhostStructureMixin:OnUpdateRender")
    
    local model = nil
    if HasMixin(self, "Model") then
        model = self:GetRenderModel()
    end
    
    if model then

        if self:GetIsGhostStructure() then
        
            self:SetOpacity(0, "ghostStructure")
        
            if not self.ghostStructureMaterial then
                self.ghostStructureMaterial = AddMaterial(model, kGhoststructureMaterial) 
            end
    
        else
        
            self:SetOpacity(1, "ghostStructure")
        
            if RemoveMaterial(model, self.ghostStructureMaterial) then
                self.ghostStructureMaterial = nil
            end

        end
        
    end
    
end