// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GhostModel.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Specifiy in TechData classname
//
//    Optional overrides for child classes:
//
//    Initialize() - load models, materials
//    Destroy() - destroy models, materials
//    SetIsVisible(isVisible)
//    LoadValidMaterial(isValid) - assign materials to loaded models
//    Update() - returns modelCoords, should be used for any additional models attached to the main model
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GhostModel'

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/placement_valid.surface_shader")
local kMaterialValid = "cinematics/vfx_materials/placement_valid.material"
local kMaterialInvalid = "cinematics/vfx_materials/placement_invalid.material"

local kArrowTexture = "ui/marinewaypoint_arrow.dds"
local kArrowSize = Vector(24, 24, 0)

local kCircleModelMarine = PrecacheAsset("models/misc/circle/circle.model")
local kCircleModelAlien = PrecacheAsset("models/misc/circle/circle_alien.model")

// children can override, but make sure to call this function as well
function GhostModel:Initialize()

    if not self.circleRangeModel then
        local player = Client.GetLocalPlayer()
        local kCircleModelName = ConditionalValue(player:isa("MarineCommander"), kCircleModelMarine, kCircleModelAlien)
        
        self.circleRangeModel = Client.CreateRenderModel(RenderScene.Zone_Default)
        self.circleRangeModel:SetModel(kCircleModelName)
    end

    if not self.renderModel then    
        self.renderModel = Client.CreateRenderModel(RenderScene.Zone_Default)    
    end
    
    if not self.renderMaterial then    
    
        self.renderMaterial = Client.CreateRenderMaterial()
        self.renderModel:AddMaterial(self.renderMaterial)
        
    end
    
    if not self.attachArrow then
    
        self.attachArrow = GUI.CreateItem()
        self.attachArrow:SetIsVisible(false)
        self.attachArrow:SetTexture(kArrowTexture)
        self.attachArrow:SetSize(kArrowSize)
        self.attachArrow:SetLayer(kGUILayerCommanderHUD)
        
    end
    
end

// children can override, but make sure to call this function as well
function GhostModel:Destroy()

    if self.circleRangeModel then
        Client.DestroyRenderModel(self.circleRangeModel)
        self.circleRangeModel = nil
    end

    if self.renderModel then
    
        Client.DestroyRenderModel(self.renderModel)
        self.renderModel = nil
        self.loadedModelName = nil
        
    end
    
    if self.attachArrow then
    
        GUI.DestroyItem(self.attachArrow)
        self.attachArrow = nil
        
    end
    
end

// children can override, but make sure to call this function as well
function GhostModel:SetIsVisible(isVisible)
    local player = Client.GetLocalPlayer()
    
    self.renderModel:SetIsVisible(isVisible)
    self.circleRangeModel:SetIsVisible(isVisible)
end

// children can override, but make sure to call this function as well
function GhostModel:LoadValidMaterial(isValid)

    if isValid then
        self.renderMaterial:SetMaterial(kMaterialValid)
    else
        self.renderMaterial:SetMaterial(kMaterialInvalid)
    end

end

// children can override, but make sure to call this function as well
function GhostModel:Update()

    local player = Client.GetLocalPlayer()

    self.attachArrow:SetIsVisible(false)
    self:SetIsVisible(true)
    
    if player:isa("Commander") then
        self.renderMaterial:SetParameter("edge", 0)
    else
        self.renderMaterial:SetParameter("edge", 3)
    end
    
    local modelName = GhostModelUI_GetModelName()
    if not modelName then
    
        self:SetIsVisible(false)
        return
        
    end
    
    local modelIndex = Shared.GetModelIndex(modelName)
    local modelCoords = GhostModelUI_GetGhostModelCoords()
    local isValid = GhostModelUI_GetIsValidPlacement()
    
    if not modelIndex then
    
        self:SetIsVisible(false)
        return
        
    end

    if self.loadedModelIndex ~= modelIndex then
    
        self.renderModel:SetModel(modelIndex)
        self.loadedModelIndex = modelIndex
        
    end
    
    if self.validLoaded ~= nil or self.validLoaded ~= isValid then
  
        self:LoadValidMaterial(isValid)
        self.validLoaded = isValid
    
    end
    
    if not modelCoords or not modelCoords:GetIsFinite() then
    
        self:SetIsVisible(false)
        return nil
        
    else    
        
        self.renderModel:SetCoords(modelCoords)
        
        local direction = GhostModelUI_GetNearestAttachPointDirection()
        direction = direction or GhostModelUI_GetNearestAttachStructureDirection()
        if direction then
        
            self.attachArrow:SetIsVisible(true)
            local arrowDist = 3
            arrowDist = arrowDist + ((math.cos(Shared.GetTime() * 8) + 1) / 2)
            self.attachArrow:SetPosition(Client.WorldToScreen(modelCoords.origin + direction * arrowDist) - kArrowSize / 2)
            self.attachArrow:SetRotation(Vector(0, 0, GetYawFromVector(direction) + math.pi / 2))
            
        end
        
        if player and player.currentTechId then
        
            local radius = LookupTechData(player.currentTechId, kVisualRange, nil)
            
            if radius then
            
                local ringCoords = CopyCoords(modelCoords)
                ringCoords:Scale(radius*2)
                // Raise a bit to avoid Z-Fighting
                ringCoords.origin.y = ringCoords.origin.y+0.01
                
                self.circleRangeModel:SetCoords(ringCoords)
                
            end
            
        end
        
    end
    
    return modelCoords

end
