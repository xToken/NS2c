// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\UmbraMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

/**
 * UmbraMixin drags out parts of an umbra cloud to protect an alien for additional UmbraMixin.kUmbraDragTime seconds.
 */
UmbraMixin = CreateMixin( UmbraMixin )
UmbraMixin.type = "Umbra"

local kMaterialName = "cinematics/vfx_materials/umbra.material"
local kViewMaterialName = "cinematics/vfx_materials/umbra_view.material"

if Client then
    Shared.PrecacheSurfaceShader("cinematics/vfx_materials/umbra.surface_shader")
    Shared.PrecacheSurfaceShader("cinematics/vfx_materials/umbra_view.surface_shader")
    Shared.PrecacheSurfaceShader("cinematics/vfx_materials/2em_1mask_1norm_scroll_refract_tint.surface_shader")
end

UmbraMixin.expectedMixins =
{
}

UmbraMixin.networkVars =
{
    hasumbra = "boolean"
}

function UmbraMixin:__initmixin()
    self.umbratime = 0
end

function UmbraMixin:GetHasUmbra()
    return hasumbra
end

if Server then

    local function CheckUmbra(self)
        self.hasumbra = self.umbratime > Shared.GetTime()
        return self.hasumbra
    end

    function UmbraMixin:SetHasUmbra()
    
        if HasMixin(self, "Live") and not self:GetIsAlive() then
            return
        end
        if not self:GetHasUmbra() then
            self:AddTimedCallback(CheckUmbra, kUmbraUpdateRate)
        end
        self.umbratime = Shared.GetTime() + kUmbraUpdateRate
        
    end
    
end

function UmbraMixin:OnUpdateRender()

    local model = self:GetRenderModel()
    if model then
    
        if not self.umbraMaterial then        
            self.umbraMaterial = AddMaterial(model, kMaterialName)  
        end
        
        self.umbraMaterial:SetParameter("intensity", self:GetHasUmbra() and 1 or 0)
    
    end
    
    local viewModel = self.GetViewModelEntity and self:GetViewModelEntity() and self:GetViewModelEntity():GetRenderModel()
    if viewModel then
    
        if not self.umbraViewMaterial then        
            self.umbraViewMaterial = AddMaterial(viewModel, kViewMaterialName)        
        end
        
        self.umbraViewMaterial:SetParameter("intensity", self:GetHasUmbra() and 1 or 0)
    
    end

end