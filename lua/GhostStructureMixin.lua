// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\GhostStructureMixin.lua    
//    
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

GhostStructureMixin = CreateMixin(GhostStructureMixin)
GhostStructureMixin.type = "GhostStructure"

GhostStructureMixin.kGhostStructureCancelRange = 3

GhostStructureMixin.expectedMixins =
{
    Construct = "Makes no sense to use this mixin for non constructable units.",
    Team = "Required to identify enemies and to cancel ghost mode by onuse from friendly players"
}

GhostStructureMixin.networkVars =
{
    isGhostStructure = "boolean"
}

if Client then
    Shared.PrecacheSurfaceShader("cinematics/vfx_materials/ghoststructure.surface_shader")
end

function GhostStructureMixin:__initmixin()

    // init the entity in ghost structure mode
    if Server then
        self.isGhostStructure = true
    end
    
end

function GhostStructureMixin:GetIsGhostStructure()
    return self.isGhostStructure
end

local function ClearGhostStructure(self)

    self.isGhostStructure = false
    self:TriggerEffects("ghoststructure_destroy")
    local cost = LookupTechData(self:GetTechId(), kTechDataCostKey, 0)
    local refund = math.round(cost * kGhostStructureModifier)
    self:GetTeam():AddTeamResources(refund)
    self:GetTeam():PrintWorldTextForTeamInRange(kWorldTextMessageType.Resources, refund, self:GetOrigin() + kWorldMessageResourceOffset, kResourceMessageRange)
    DestroyEntity(self)
    
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
    
	// If we start constructing, make us no longer a ghost
    function GhostStructureMixin:OnConstruct(builder, buildPercentage)
        CheckGhostState(self, builder)
    end
    
    function GhostStructureMixin:OnConstructionComplete()
        self.isGhostStructure = false
    end

end

local function SharedUpdate(self, deltaTime)

    if Server and self:GetIsGhostStructure() then
    
        // check for enemies in range and destroy the structure, return resources to team
        local enemies = GetEntitiesForTeamWithinRange("Player", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin() + Vector(0, 0.3, 0), GhostStructureMixin.kGhostStructureCancelRange)
        
        for _, enemy in ipairs (enemies) do
        
            if enemy:GetIsAlive() then
            
                ClearGhostStructure(self)
                break
                
            end
            
        end
        
    elseif Client then
    
        local model = nil
        if HasMixin(self, "Model") then
            model = self:GetRenderModel()
        end
        
        if model then

            if self:GetIsGhostStructure() then
            
                self:SetOpacity(0, "ghostStructure")
            
                if not self.ghostStructureMaterial then
                    self.ghostStructureMaterial = AddMaterial(model, "cinematics/vfx_materials/ghoststructure.material") 
                end
        
            else
            
                self:SetOpacity(1, "ghostStructure")
            
                if RemoveMaterial(model, self.ghostStructureMaterial) then
                    self.ghostStructureMaterial = nil
                end

            end
            
        end
        
    end
    
end

function GhostStructureMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end

function GhostStructureMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end