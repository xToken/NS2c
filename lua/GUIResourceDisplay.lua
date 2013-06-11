
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIResourceDisplay.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying resources and number of resource towers.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUIResourceDisplay' (GUIScript)

GUIResourceDisplay.kBackgroundTextureAlien = "ui/alien_commander_textures.dds"
GUIResourceDisplay.kBackgroundTextureMarine = "ui/marine_commander_textures.dds"
GUIResourceDisplay.kBackgroundTextureCoords = { X1 = 755, Y1 = 342, X2 = 990, Y2 = 405 }
GUIResourceDisplay.kBackgroundWidth = GUIScale(128)
GUIResourceDisplay.kBackgroundHeight = GUIScale(63)
GUIResourceDisplay.kBackgroundYOffset = 10

GUIResourceDisplay.kPersonalResourceIcon = { Width = 0, Height = 0, X = 0, Y = 0, Coords = { X1 = 144, Y1 = 363, X2 = 192, Y2 = 411} }
GUIResourceDisplay.kPersonalResourceIcon.Width = GUIScale(48)
GUIResourceDisplay.kPersonalResourceIcon.Height = GUIScale(48)

GUIResourceDisplay.kTeamResourceIcon = { Width = 0, Height = 0, X = 0, Y = 0, Coords = { X1 = 192, Y1 = 363, X2 = 240, Y2 = 411} }
GUIResourceDisplay.kTeamResourceIcon.Width = GUIScale(48)
GUIResourceDisplay.kTeamResourceIcon.Height = GUIScale(48)

GUIResourceDisplay.kResourceTowerIcon = { Width = 0, Height = 0, X = 0, Y = 0, Coords = { X1 = 240, Y1 = 363, X2 = 280, Y2 = 411} }
GUIResourceDisplay.kResourceTowerIcon.Width = GUIScale(48)
GUIResourceDisplay.kResourceTowerIcon.Height = GUIScale(48)

GUIResourceDisplay.kFontSize = 16
GUIResourceDisplay.kIconTextXOffset = 5
GUIResourceDisplay.kIconXOffset = 30

local kFontName = "fonts/AgencyFB_small.fnt"
local kFontScale = GUIScale(Vector(1,1,1))

local kColorWhite = Color(1, 1, 1, 1)
local kColorRed = Color(1, 0, 0, 1)

local kBackgroundNoiseTexture =  "ui/alien_commander_bg_smoke.dds"
local kSmokeyBackgroundSize = GUIScale(Vector(300, 96, 0))

function GUIResourceDisplay:Initialize(settingsTable)

    self.textureName = ConditionalValue(PlayerUI_GetTeamType() == kAlienTeamType, GUIResourceDisplay.kBackgroundTextureAlien, GUIResourceDisplay.kBackgroundTextureMarine)
    
    // Background, only used for positioning
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(Vector(GUIResourceDisplay.kBackgroundWidth, GUIResourceDisplay.kBackgroundHeight, 0))
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.background:SetPosition(Vector(-GUIResourceDisplay.kBackgroundWidth / 2, GUIResourceDisplay.kBackgroundYOffset, 0))
    self.background:SetColor(Color(1, 1, 1, 0))
    
    if PlayerUI_GetTeamType() == kAlienTeamType then
        self:InitSmokeyBackground()
    end
    
    // Team display.
    self.teamIcon = GUIManager:CreateGraphicItem()
    self.teamIcon:SetSize(Vector(GUIResourceDisplay.kTeamResourceIcon.Width, GUIResourceDisplay.kTeamResourceIcon.Height, 0))
    self.teamIcon:SetAnchor(GUIItem.Left, GUIItem.Center)
    local teamIconX = GUIResourceDisplay.kTeamResourceIcon.X + -GUIResourceDisplay.kTeamResourceIcon.Width - GUIResourceDisplay.kIconXOffset
    local teamIconY = GUIResourceDisplay.kTeamResourceIcon.Y + -GUIResourceDisplay.kPersonalResourceIcon.Height / 2
    self.teamIcon:SetPosition(Vector(teamIconX, teamIconY, 0))
    self.teamIcon:SetTexture(self.textureName)
    GUISetTextureCoordinatesTable(self.teamIcon, GUIResourceDisplay.kTeamResourceIcon.Coords)
    self.background:AddChild(self.teamIcon)

    self.teamText = GUIManager:CreateTextItem()
    self.teamText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.teamText:SetTextAlignmentX(GUIItem.Align_Min)
    self.teamText:SetTextAlignmentY(GUIItem.Align_Center)
    self.teamText:SetPosition(Vector(GUIResourceDisplay.kIconTextXOffset, 0, 0))
    self.teamText:SetColor(Color(1, 1, 1, 1))
    self.teamText:SetFontName(kFontName)
    self.teamText:SetScale(kFontScale)
    self.teamIcon:AddChild(self.teamText)
    
    // Tower display.
    self.towerIcon = GUIManager:CreateGraphicItem()
    self.towerIcon:SetSize(Vector(GUIResourceDisplay.kResourceTowerIcon.Width, GUIResourceDisplay.kResourceTowerIcon.Height, 0))
    self.towerIcon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    local towerIconX = GUIResourceDisplay.kResourceTowerIcon.X + -GUIResourceDisplay.kResourceTowerIcon.Width
    local towerIconY = GUIResourceDisplay.kResourceTowerIcon.Y + -GUIResourceDisplay.kResourceTowerIcon.Height / 2
    self.towerIcon:SetPosition(Vector(towerIconX, towerIconY, 0))
    self.towerIcon:SetTexture(self.textureName)
    GUISetTextureCoordinatesTable(self.towerIcon, GUIResourceDisplay.kResourceTowerIcon.Coords)
    self.background:AddChild(self.towerIcon)

    self.towerText = GUIManager:CreateTextItem()
    self.towerText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.towerText:SetTextAlignmentX(GUIItem.Align_Min)
    self.towerText:SetTextAlignmentY(GUIItem.Align_Center)
    self.towerText:SetPosition(Vector(GUIResourceDisplay.kIconTextXOffset, 0, 0))
    self.towerText:SetColor(Color(1, 1, 1, 1))
    self.towerText:SetFontName(kFontName)
    self.towerText:SetScale(kFontScale)
    self.towerIcon:AddChild(self.towerText)
    
end

function GUIResourceDisplay:Uninitialize()
    
    if self.background then
        GUI.DestroyItem(self.background)
    end
    self.background = nil
    
end

function GUIResourceDisplay:InitSmokeyBackground()

    self.smokeyBackground = GUIManager:CreateGraphicItem()
    self.smokeyBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.smokeyBackground:SetSize(kSmokeyBackgroundSize)
    self.smokeyBackground:SetPosition(-kSmokeyBackgroundSize * .5)
    self.smokeyBackground:SetShader("shaders/GUISmoke.surface_shader")
    self.smokeyBackground:SetTexture("ui/alien_ressources_smkmask.dds")
    self.smokeyBackground:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
    self.smokeyBackground:SetFloatParameter("correctionX", 0.9)
    self.smokeyBackground:SetFloatParameter("correctionY", 0.1)
    
    self.background:AddChild(self.smokeyBackground)

end

local kWhite = Color(1,1,1,1)
local kRed = Color(1,0,0,1)

function GUIResourceDisplay:Update(deltaTime)

    PROFILE("GUIResourceDisplay:Update")

    self.teamText:SetText(ToString(PlayerUI_GetTeamResources()))
    
    local numHarvesters = CommanderUI_GetTeamHarvesterCount()
    self.towerText:SetText(ToString(numHarvesters))
    
end
