
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUISensorBlips.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Manages the blips that are displayed on the Marine HUD due to detection (observatory, scan).
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================


class 'GUISensorBlips' (GUIScript)

GUISensorBlips.kMarineBlipImageName = "ui/sensor.dds"
GUISensorBlips.kAlienBlipImageName = "ui/aliensensor.dds"

GUISensorBlips.kFontName = "fonts/Arial_15.fnt"
GUISensorBlips.kFontSize = GUIScale(30)

GUISensorBlips.kDefaultBlipSize = 20
GUISensorBlips.kMaxBlipSize = 180

GUISensorBlips.kAlphaPerSecond = 0.8
GUISensorBlips.kImpulseIntervall = 2.5

GUISensorBlips.kRotationDuration = 5

function GUISensorBlips:Initialize()

    self.activeBlipList = { }
    
end

function GUISensorBlips:Uninitialize()
    
    for i, blip in ipairs(self.activeBlipList) do
        GUI.DestroyItem(blip.GraphicsItem)
        GUI.DestroyItem(blip.TextItem)
    end
    self.activeBlipList = { }
    
end

function GUISensorBlips:Update(deltaTime)

    PROFILE("GUISensorBlips:Update")

    self:UpdateBlipList(PlayerUI_GetSensorBlipInfo())
    
    self:UpdateAnimations(deltaTime)
    
end

function GUISensorBlips:UpdateAnimations(deltaTime)

    PROFILE("GUISensorBlips:UpdateAnimations")
    
    local baseRotationPercentage = (Shared.GetTime() % GUISensorBlips.kRotationDuration) / GUISensorBlips.kRotationDuration
    
    if not self.timeLastImpulse then
        self.timeLastImpulse = Shared.GetTime()
    end
    
    if self.timeLastImpulse + GUISensorBlips.kImpulseIntervall < Shared.GetTime() then
        self.timeLastImpulse = Shared.GetTime()
    end  

    local destAlpha = math.max(0, 1 - (Shared.GetTime() - self.timeLastImpulse) * GUISensorBlips.kAlphaPerSecond)  
    
    for i, blip in ipairs(self.activeBlipList) do
        local size = math.min(blip.Radius * 2 * GUISensorBlips.kDefaultBlipSize, GUISensorBlips.kMaxBlipSize)
        blip.GraphicsItem:SetSize(Vector(size, size, 0))
        
        // Offset by size / 2 so the blip is centered.
        local newPosition = Vector(blip.ScreenX - size / 2, blip.ScreenY - size / 2, 0)
        blip.GraphicsItem:SetPosition(newPosition)
        
        // rotate the blip
        blip.GraphicsItem:SetRotation(Vector(0, 0, 2 * math.pi * (baseRotationPercentage + (i / #self.activeBlipList))))

        // Draw blips as barely visible when in view, to communicate their purpose. Animate color towards final value.
        local currentColor = blip.GraphicsItem:GetColor()
        destAlpha = ConditionalValue(blip.Obstructed, destAlpha * blip.Radius, currentColor.a - GUISensorBlips.kAlphaPerSecond * deltaTime)

        currentColor.a = destAlpha
        blip.GraphicsItem:SetColor(currentColor)
        blip.TextItem:SetColor(currentColor)
        
    end
    
end

function GUISensorBlips:UpdateBlipList(activeBlips)

    PROFILE("GUISensorBlips:UpdateBlipList")
    
    local numElementsPerBlip = 5
    local numBlips = table.count(activeBlips) / numElementsPerBlip
    
    while numBlips > table.count(self.activeBlipList) do
        local newBlipItem = self:CreateBlipItem()
        table.insert(self.activeBlipList, newBlipItem)
    end
    
    while numBlips < table.count(self.activeBlipList) do
        GUI.DestroyItem(self.activeBlipList[#self.activeBlipList].GraphicsItem)
        table.remove(self.activeBlipList, #self.activeBlipList)
    end
    
    // Update current blip state.
    local currentIndex = 1
    while numBlips > 0 do
        local updateBlip = self.activeBlipList[numBlips]
        updateBlip.ScreenX = activeBlips[currentIndex]
        updateBlip.ScreenY = activeBlips[currentIndex + 1]
        updateBlip.Radius = activeBlips[currentIndex + 2]
        updateBlip.Obstructed = activeBlips[currentIndex + 3]
        updateBlip.name = activeBlips[currentIndex + 4]
        
        //updateBlip.TextItem:SetText( activeBlips[currentIndex + 4] )
        
        numBlips = numBlips - 1
        currentIndex = currentIndex + numElementsPerBlip
    end

end

function GUISensorBlips:CreateBlipItem()

    local newBlip = { ScreenX = 0, ScreenY = 0, Radius = 0, Type = 0 }
    newBlip.GraphicsItem = GUIManager:CreateGraphicItem()
    newBlip.GraphicsItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    
    if PlayerUI_IsOnMarineTeam() then
        newBlip.GraphicsItem:SetTexture(GUISensorBlips.kMarineBlipImageName)
    elseif PlayerUI_IsOnAlienTeam then
        newBlip.GraphicsItem:SetTexture(GUISensorBlips.kAlienBlipImageName)
    end
    
    newBlip.GraphicsItem:SetBlendTechnique(GUIItem.Add)
    
    newBlip.TextItem = GUIManager:CreateTextItem()
    newBlip.TextItem:SetAnchor(GUIItem.Middle, GUIItem.Top)
    newBlip.TextItem:SetFontName(GUISensorBlips.kFontName)
    newBlip.TextItem:SetFontSize(GUISensorBlips.kFontSize)
    newBlip.TextItem:SetTextAlignmentX(GUIItem.Align_Center)
    newBlip.TextItem:SetTextAlignmentY(GUIItem.Align_Min)
    newBlip.TextItem:SetColor(ColorIntToColor(kMarineTeamColor))
    
    newBlip.GraphicsItem:AddChild(newBlip.TextItem)

    return newBlip
    
end
