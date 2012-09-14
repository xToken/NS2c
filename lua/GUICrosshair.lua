
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICrosshair.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the crosshairs for aliens and marines.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIAnimatedScript.lua")

class 'GUICrosshair' (GUIAnimatedScript)

GUICrosshair.kFontSize = GUIScale(22)
GUICrosshair.kDescriptionFontSize = GUIScale(18)

GUICrosshair.kTextFadeTime = 0.25
GUICrosshair.kCrosshairSize = 64
GUICrosshair.kTextYOffset = -140
GUICrosshair.kDetailYOffset = GUIScale(1)
GUICrosshair.kTextureWidth = 64
GUICrosshair.kTextureHeight = 1024
GUICrosshair.kCrosshairPos = Vector(-GUICrosshair.kCrosshairSize / 2, -GUICrosshair.kCrosshairSize / 2, 0)
GUICrosshair.kTexture = "ui/crosshairicons.dds"

local kBarBgSize = GUIScale(Vector(256, 16, 0))
local kBarYOffset = GUIScale(-80)
local kBarTexture = "ui/commanderbar.dds"

local kAnimDuration = 2
local kBarBgColor = Color(0,0,0,1)
local kBarColor = Color(1,1,1,1)
local kPadding = 2
local kBarPos = Vector(kPadding, kPadding, 0)
local kBarSize = kBarBgSize - Vector(kPadding, kPadding, 0) * 2

local kHealthIconPixelCoords = { 0, 0, 64, 64 }
local kBuildIconPixelCoords = { 64, 0, 128, 64 }

GUICrosshair.kInvisibleColor = Color(0, 0, 0, 0)
GUICrosshair.kVisibleColor = Color(1, 1, 1, 1)

GUICrosshair.kIconSize = GUIScale(Vector(22, 22, 0))
GUICrosshair.kIconPadding = GUIScale(12)

function GUICrosshair:Initialize()

    GUIAnimatedScript.Initialize(self)

    self.crosshairs = GUIManager:CreateGraphicItem()
    self.crosshairs:SetSize(Vector(GUICrosshair.kCrosshairSize, GUICrosshair.kCrosshairSize, 0))
    self.crosshairs:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.crosshairs:SetPosition(GUICrosshair.kCrosshairPos)
    self.crosshairs:SetTexture("ui/crosshairs.dds")
    self.crosshairs:SetIsVisible(false)
    
    self.damageIndicator = GUIManager:CreateGraphicItem()
    self.damageIndicator:SetSize(Vector(GUICrosshair.kCrosshairSize, GUICrosshair.kCrosshairSize, 0))
    self.damageIndicator:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.damageIndicator:SetPosition(Vector(0, 0, 0))
    self.damageIndicator:SetTexture("ui/crosshairs-hit.dds")
    local yCoord = PlayerUI_GetCrosshairDamageIndicatorY()
    self.damageIndicator:SetTexturePixelCoordinates(0, yCoord,
                                                    64, yCoord + 64)
    self.damageIndicator:SetIsVisible(false)
    self.crosshairs:AddChild(self.damageIndicator)
    
    self.crosshairInfoBackground = self:CreateAnimatedGraphicItem()  
    self.crosshairInfoBackground:SetAnchor(GUIItem.Middle, GUIItem.Center) 
    self.crosshairInfoBackground:SetPosition(Vector(0, GUICrosshair.kTextYOffset, 0)) 
    self.crosshairInfoBackground:SetTexture(GUICrosshair.kTexture)
    self.crosshairInfoBackground:SetTexturePixelCoordinates(0, 0, 1, 1) // invisible
    self.crosshairInfoBackground:SetColor(Color(1, 1, 1, 0))
    
    //self:InitializeProgressBar()

end

function GUICrosshair:Uninitialize()

    // Destroying the crosshair will destroy all it's children too.
    GUI.DestroyItem(self.crosshairs)
    self.crosshairs = nil
    self.crosshairsText = nil
    
    GUIAnimatedScript.Uninitialize(self)
    
end

local crosshairPos = Vector(0,0,0)

function GUICrosshair:Update(deltaTime)

    GUIAnimatedScript.Update(self, deltaTime)
    
    PROFILE("GUICrosshair:Update")
    
    // Update crosshair image.
    local xCoord = PlayerUI_GetCrosshairX()
    local yCoord = PlayerUI_GetCrosshairY()
    
    local showCrossHair = not PlayerUI_GetIsDead() and PlayerUI_GetIsPlaying() and not PlayerUI_GetIsThirdperson() and not PlayerUI_IsACommander() and not PlayerUI_GetBuyMenuDisplaying()
                          //and not PlayerUI_GetIsConstructing() and not PlayerUI_GetIsRepairing()
    
    self.crosshairs:SetIsVisible(showCrossHair)
    
    if showCrossHair then
        if xCoord and yCoord then
        
            self.crosshairs:SetTexturePixelCoordinates(xCoord, yCoord,
                                                       xCoord + PlayerUI_GetCrosshairWidth(), yCoord + PlayerUI_GetCrosshairHeight())
            
            self.damageIndicator:SetTexturePixelCoordinates(xCoord, yCoord,
                                                       xCoord + PlayerUI_GetCrosshairWidth(), yCoord + PlayerUI_GetCrosshairHeight())

        end
    end
    
    // Update give damage indicator.
    local indicatorVisible, timePassedPercent = PlayerUI_GetShowGiveDamageIndicator()
    self.damageIndicator:SetIsVisible(indicatorVisible and showCrossHair)
    self.damageIndicator:SetColor(Color(1, 1, 1, 1 - timePassedPercent * 3))
    self.crosshairs:SetColor(Color(1, 1, 1, timePassedPercent * 3))

    crosshairPos = Vector(0, PlayerUI_GetCrossHairVerticalOffset(), 0) + GUICrosshair.kCrosshairPos
    self.crosshairs:SetPosition(crosshairPos)
    
    //self:UpdateProgressBar(deltaTime)

end

function GUICrosshair:InitializeProgressBar()

    self.progressBarBg = GetGUIManager():CreateGraphicItem()
    self.progressBarBg:SetSize(kBarBgSize)
    self.progressBarBg:SetPosition(Vector(kBarBgSize.x * -.5, kBarYOffset, 0))
    self.progressBarBg:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.progressBarBg:SetClearsStencilBuffer(true)
    self.progressBarBg:SetColor(Color(0,0,0,0))
    
    self.progressBarStencil = GetGUIManager():CreateGraphicItem()
    self.progressBarStencil:SetSize(kBarSize)
    self.progressBarStencil:SetIsStencil(true)
    self.progressBarStencil:SetPosition(kBarPos)
    self.progressBarStencil:SetSize(kBarSize)
    self.progressBarBg:AddChild(self.progressBarStencil)   
    
    self.progressAnim = GetGUIManager():CreateGraphicItem()
    self.progressAnim:SetTexture(kBarTexture)
    self.progressAnim:SetStencilFunc(GUIItem.NotEqual)
    self.progressAnim:SetSize(kBarSize)
    self.progressAnim:SetColor(Color(0,0,0,0))
    self.progressBarStencil:AddChild(self.progressAnim)

end

function GUICrosshair:UpdateProgressBar(deltaTime)

    local animFraction = (Shared.GetTime() % kAnimDuration) / kAnimDuration
    self.progressAnim:SetTextureCoordinates(-animFraction, 0, 1 - animFraction, 1)
    
    local progressFraction = PlayerUI_GetProgressFraction()
    
    local hideBar = not progressFraction or progressFraction == 0 or progressFraction == 1 or (not PlayerUI_GetIsConstructing() and not PlayerUI_GetIsRepairing())
    
    if progressFraction then    
        self.progressBarStencil:SetSize(Vector(kBarSize.x * progressFraction, kBarSize.y, 0))        
    end

    if hideBar then
    
        local currentAlpha = math.max(0, self.progressBarBg:GetColor().a - deltaTime)
        self.progressBarBg:SetColor(Color(kBarBgColor.r, kBarBgColor.g, kBarBgColor.b, currentAlpha))
        self.progressAnim:SetColor(Color(kBarColor.r, kBarColor.g, kBarColor.b, currentAlpha))

    else
        
        self.progressBarBg:SetColor(kBarBgColor)
        self.progressAnim:SetColor(kBarColor)
        
    end

end