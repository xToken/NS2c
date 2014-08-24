// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineGhostModel.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Shows an additional rotating circle.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Hud/Commander/GhostModel.lua")

local kCircleModelName = PrecacheAsset("models/misc/circle/placement_circle_marine.model")

class 'MarineGhostModel' (GhostModel)

local kElectricTexture = "ui/electric.dds"
local kIconSize = GUIScale(Vector(32, 32, 0))
local kHalfIconSize = kIconSize * 0.5
local kIconOffset = GUIScale(100)

function MarineGhostModel:Initialize()

    GhostModel.Initialize(self)
    
    if not self.circleModel then    
        self.circleModel = Client.CreateRenderModel(RenderScene.Zone_Default)
        self.circleModel:SetModel(kCircleModelName)
    end
    
    if not self.powerIcon then
    
        self.powerIcon = GUI.CreateItem()
        self.powerIcon:SetTexture(kElectricTexture)
        self.powerIcon:SetSize(kIconSize)
        self.powerIcon:SetIsVisible(false)
    
    end
    
end

function MarineGhostModel:Destroy() 

    GhostModel.Destroy(self)   
    
    if self.circleModel then 
    
        Client.DestroyRenderModel(self.circleModel)
        self.circleModel = nil
    
    end
    
    if self.powerIcon then
    
        GUI.DestroyItem(self.powerIcon)
        self.powerIcon = nil
        
    end
    
end

function MarineGhostModel:SetIsVisible(isVisible)

    self.circleModel:SetIsVisible(isVisible)
    GhostModel.SetIsVisible(self, isVisible)
    
end

function MarineGhostModel:LoadValidMaterial(isValid)
    GhostModel.LoadValidMaterial(self, isValid)
end

function MarineGhostModel:Update()

    local modelCoords = GhostModel.Update(self)
    
    if modelCoords then
        
        local time = Shared.GetTime()
        local zAxis = Vector(math.cos(time), 0, math.sin(time))

        local coords = Coords.GetLookIn(modelCoords.origin, zAxis)
        self.circleModel:SetCoords(coords) 
        
    else
    
        self.powerIcon:SetIsVisible(false)
    
    end
    
end


