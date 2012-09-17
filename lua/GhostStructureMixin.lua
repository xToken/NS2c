// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\GhostStructureMixin.lua    
//    
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

GhostStructureMixin = CreateMixin( GhostStructureMixin )
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

function GhostStructureMixin:GetHasUmbra()
    return self.dragsUmbra or self:GetGameEffectMask(kGameEffect.InUmbra)
end

local function ClearGhostStructure(self)

    self.isGhostStructure = false
    self:TriggerEffects("ghoststructure_destroy")
    local cost = LookupTechData(self:GetTechId(), kTechDataCostKey, 0)
    local refund = math.round(cost * kGhostStructureModifier)
    self:GetTeam():AddTeamResources(refund)
    self:GetTeam():PrintWorldTextForTeamInRange(kWorldTextMessageType.Resources, (refund), self:GetOrigin() + kWordMessageResourceOffset, kResourceMessageRange)
    DestroyEntity(self)
    
end

if Server then

    local function CheckGhostState(self, doer)
    
        if self.isGhostStructure and GetAreFriends(self, doer) then
            self.isGhostStructure = false
        end
        
    end
    
    // listen to game effect mask change of umbra
    function GhostStructureMixin:OnUse(player, elapsedTime, useAttachPoint, usePoint, useSuccessTable)
        CheckGhostState(self, player)
    end
    
    function GhostStructureMixin:OnWeld(doer, elapsedTime)
        CheckGhostState(self, doer)
    end
    
    function GhostStructureMixin:OnConstruct(builder, buildPercentage)
        CheckGhostState(self, builder)
    end
    
    function GhostStructureMixin:OnConstructionComplete()
        self.isGhostStructure = false
    end

end

local function SharedUpdate(self, deltaTime)

    if Server and self.isGhostStructure then
    
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

            if self.isGhostStructure then
            
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
AddFunctionContract(GhostStructureMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

function GhostStructureMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end
AddFunctionContract(GhostStructureMixin.OnProcessMove, { Arguments = { "Entity", "Move" }, Returns = { } })
