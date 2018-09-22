
-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIResourceDisplay.lua
--
-- Created by: Brian Cronin (brianc@unknownworlds.com)
--
-- Manages displaying resources and number of resource towers.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Removed idle workers item

Script.Load("lua/GUIScript.lua")

class 'GUIResourceDisplay' (GUIScript)

GUIResourceDisplay.kBackgroundTextureAlien = "ui/alien_commander_textures.dds"
GUIResourceDisplay.kBackgroundTextureMarine = "ui/marine_commander_textures.dds"
GUIResourceDisplay.kBackgroundTextureCoords = { X1 = 755, Y1 = 342, X2 = 990, Y2 = 405 }

GUIResourceDisplay.kPersonalResourceIcon = { Width = 0, Height = 0, X = 0, Y = 0, Coords = { X1 = 144, Y1 = 363, X2 = 192, Y2 = 411} }

GUIResourceDisplay.kTeamResourceIcon = { Width = 0, Height = 0, X = 0, Y = 0, Coords = { X1 = 192, Y1 = 363, X2 = 240, Y2 = 411} }

GUIResourceDisplay.kResourceTowerIcon = { Width = 0, Height = 0, X = 0, Y = 0, Coords = { X1 = 240, Y1 = 363, X2 = 280, Y2 = 411} }

GUIResourceDisplay.kWorkerIcon = { Width = 0, Height = 0, X = 0, Y = 0, Coords = { X1 = 280, Y1 = 363, X2 = 320, Y2 = 411} }

GUIResourceDisplay.kEggsIcon = { Width = 0, Height = 0, X = 0, Y = 0, Coords = { X1 = 80 * 6, Y1 = 80 * 3, X2 = 80 * 7, Y2 = 80 * 4 } }

local kFontName = Fonts.kAgencyFB_Small
local kFontScale

local kColorWhite = Color(1, 1, 1, 1)
local kColorRed = Color(1, 0, 0, 1)

local kBackgroundNoiseTexture =  "ui/alien_commander_bg_smoke.dds"
local kSmokeyBackgroundSize

local function UpdateItemsGUIScale(self)
    GUIResourceDisplay.kBackgroundWidth = GUIScale(128)
    GUIResourceDisplay.kBackgroundHeight = GUIScale(63)
    GUIResourceDisplay.kBackgroundYOffset = GUIScale(10)

    GUIResourceDisplay.kPersonalResourceIcon.Width = GUIScale(48)
    GUIResourceDisplay.kPersonalResourceIcon.Height = GUIScale(48)

    GUIResourceDisplay.kTeamResourceIcon.Width = GUIScale(48)
    GUIResourceDisplay.kTeamResourceIcon.Height = GUIScale(48)

    GUIResourceDisplay.kResourceTowerIcon.Width = GUIScale(48)
    GUIResourceDisplay.kResourceTowerIcon.Height = GUIScale(48)

    GUIResourceDisplay.kWorkerIcon.Width = GUIScale(48)
    GUIResourceDisplay.kWorkerIcon.Height = GUIScale(48)

    GUIResourceDisplay.kIconTextXOffset = GUIScale(5)
    GUIResourceDisplay.kIconXOffset = GUIScale(30)

    GUIResourceDisplay.kEggsIcon.Width = GUIScale(57)
    GUIResourceDisplay.kEggsIcon.Height = GUIScale(57)
    
    kSmokeyBackgroundSize = GUIScale(Vector(375, 100, 0))
    kFontScale = GetScaledVector()
end

function GUIResourceDisplay:OnResolutionChanged(oldX, oldY, newX, newY)
    self:Uninitialize()
    self:Initialize()
end

function GUIResourceDisplay:Initialize(settingsTable)

    UpdateItemsGUIScale(self)
    
    self.textureName = ConditionalValue(PlayerUI_GetTeamType() == kAlienTeamType, GUIResourceDisplay.kBackgroundTextureAlien, GUIResourceDisplay.kBackgroundTextureMarine)
    
    -- Background, only used for positioning
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(Vector(GUIResourceDisplay.kBackgroundWidth, GUIResourceDisplay.kBackgroundHeight, 0))
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.background:SetPosition(Vector(-GUIResourceDisplay.kBackgroundWidth / 2, GUIResourceDisplay.kBackgroundYOffset, 0))
    self.background:SetColor(Color(1, 1, 1, 0))
    
    if PlayerUI_GetTeamType() == kAlienTeamType then
        self:InitSmokeyBackground()
    end
    
    -- Team display.
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
    GUIMakeFontScale(self.teamText)
    self.teamIcon:AddChild(self.teamText)
    
    -- Tower display.
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
    GUIMakeFontScale(self.towerText)
    self.towerIcon:AddChild(self.towerText)
    
	self.eggsIcon = GUIManager:CreateGraphicItem()
    self.eggsIcon:SetSize(Vector(GUIResourceDisplay.kEggsIcon.Width, GUIResourceDisplay.kEggsIcon.Height, 0))
    self.eggsIcon:SetAnchor(GUIItem.Right, GUIItem.Center)
    local eggsIconX = GUIResourceDisplay.kEggsIcon.X + GUIResourceDisplay.kEggsIcon.Width + GUIResourceDisplay.kIconXOffset
    local eggsIconY = GUIResourceDisplay.kEggsIcon.Y + -GUIResourceDisplay.kEggsIcon.Height / 2
    self.eggsIcon:SetPosition(Vector(eggsIconX, eggsIconY, 0))
    self.eggsIcon:SetTexture("ui/alien_buildmenu_profile.dds")
    GUISetTextureCoordinatesTable(self.eggsIcon, GUIResourceDisplay.kEggsIcon.Coords)
    self.background:AddChild(self.eggsIcon)
    
    self.eggsText = GUIManager:CreateTextItem()
    self.eggsText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.eggsText:SetTextAlignmentX(GUIItem.Align_Min)
    self.eggsText:SetTextAlignmentY(GUIItem.Align_Center)
    self.eggsText:SetPosition(Vector(GUIResourceDisplay.kIconTextXOffset, 0, 0))
    self.eggsText:SetColor(Color(1, 1, 1, 1))
    self.eggsText:SetFontName(kFontName)
    self.eggsText:SetScale(kFontScale)
    GUIMakeFontScale(self.eggsText)
    self.eggsIcon:AddChild(self.eggsText)

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
    
    local currentTeamRes = PlayerUI_GetTeamResources()
    if not self.displayedTeamRes then
        self.displayedTeamRes = currentTeamRes
    else

        if self.displayedTeamRes > currentTeamRes then
            self.displayedTeamRes = currentTeamRes
        else
            self.displayedTeamRes = Slerp(self.displayedTeamRes, currentTeamRes, deltaTime * 40)
        end    
            
    end

    self.teamText:SetText(ToString(math.round(self.displayedTeamRes)))
    
    local numHarvesters = CommanderUI_GetTeamHarvesterCount()
    self.towerText:SetText(ToString(numHarvesters))
    
	local eggCount = AlienUI_GetEggCount()   
    self.eggsText:SetText(ToString(eggCount))
    
    local hasEggs = eggCount > 0
    self.eggsText:SetColor(hasEggs and kWhite or kRed)
    self.eggsIcon:SetColor(hasEggs and kWhite or kRed)
    
    if PlayerUI_GetTeamType() ~= kAlienTeamType then
        self.eggsIcon:SetIsVisible(false)
        self.eggsText:SetIsVisible(false)
    end
    
end
