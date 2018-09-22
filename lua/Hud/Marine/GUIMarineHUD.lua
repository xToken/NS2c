-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIMarineHUD.lua
--
-- Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- Animated 3d Hud for Marines.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIUtility.lua")
Script.Load("lua/GUIAnimatedScript.lua")

Script.Load("lua/Hud/GUIPlayerResource.lua")
Script.Load("lua/Hud/Marine/GUIMarineStatus.lua")
Script.Load("lua/Hud/GUIEvent.lua")
Script.Load("lua/Hud/Marine/GUIMarineFuel.lua")
Script.Load("lua/Hud/Marine/GUIMarineHUDStyle.lua")
Script.Load("lua/Hud/GUIInventory.lua")
Script.Load("lua/TechTreeConstants.lua")

class 'GUIMarineHUD' (GUIAnimatedScript)

GUIMarineHUD.kUpgradesTexture = "ui/buildmenu.dds"

local POWER_OFF = 1
local POWER_ON = 2
local POWER_DESTROYED = 3
local POWER_DAMAGED = 4

local function GetTechIdForArmorLevel(level)

    local armorTechId = {}
    
    armorTechId[1] = kTechId.Armor1
    armorTechId[2] = kTechId.Armor2
    armorTechId[3] = kTechId.Armor3
    
    return armorTechId[level]

end

local function GetTechIdForWeaponLevel(level)

    local weaponTechId = {}
    
    weaponTechId[1] = kTechId.Weapons1
    weaponTechId[2] = kTechId.Weapons2
    weaponTechId[3] = kTechId.Weapons3
    
    return weaponTechId[level]

end

GUIMarineHUD.kUpgradeSize = Vector(80, 80, 0) * 0.8
GUIMarineHUD.kUpgradePos = Vector(-GUIMarineHUD.kUpgradeSize.x - 16, 40, 0)

GUIMarineHUD.kCommanderNameOffset = Vector(20, 280, 0)

GUIMarineHUD.kMinimapYOffset = 5

-- position and size for stencil buffer
GUIMarineHUD.kStencilSize = Vector(400, 256, 0)
GUIMarineHUD.kStencilPos = Vector(0, 128, 0)

-- initial squares which fade out
GUIMarineHUD.kNumInitSquares = 10
GUIMarineHUD.kInitSquareSize = Vector(64, 80, 0)
GUIMarineHUD.kInitSquareColors = Color(0x01 / 0xFF, 0x8D / 0xFF, 0xFF / 0xFF, 0.3)

-- TEXTURES
GUIMarineHUD.kScanTexture = PrecacheAsset("ui/marine_HUD_scanLines.dds")
GUIMarineHUD.kScanLineTextureCoords = { 0, 0, 362, 1200 }

local kMinimapBorderTexture = PrecacheAsset("ui/marine_HUD_minimap.dds")
GUIMarineHUD.kMinimapBackgroundTextureCoords = { 0, 0, 400, 256 }
GUIMarineHUD.kMinimapBorderTextureCoords = { GUIMarineHUD.kMinimapBackgroundTextureCoords[3], GUIMarineHUD.kMinimapBackgroundTextureCoords[4], 2 * GUIMarineHUD.kMinimapBackgroundTextureCoords[3], 2 * GUIMarineHUD.kMinimapBackgroundTextureCoords[4] }
GUIMarineHUD.kMinimapBackgroundSize = Vector( GUIMarineHUD.kMinimapBackgroundTextureCoords[3] - GUIMarineHUD.kMinimapBackgroundTextureCoords[1], GUIMarineHUD.kMinimapBackgroundTextureCoords[4] - GUIMarineHUD.kMinimapBackgroundTextureCoords[2], 0 )
GUIMarineHUD.kMinimapPowerTextureCoords = { 0, GUIMarineHUD.kMinimapBackgroundTextureCoords[4] * 4, 43, GUIMarineHUD.kMinimapBackgroundTextureCoords[4] * 4 + 28 }
GUIMarineHUD.kMinimapScanlineTextureCoords = { 0, 0, 400, 128 }

GUIMarineHUD.kMinimapScanTextureCoords = { GUIMarineHUD.kMinimapBackgroundTextureCoords[3], 2 * GUIMarineHUD.kMinimapBackgroundTextureCoords[4], 2 * GUIMarineHUD.kMinimapBackgroundTextureCoords[3], 3 * GUIMarineHUD.kMinimapBackgroundTextureCoords[4] }


GUIMarineHUD.kMinimapStencilTextureCoords = { GUIMarineHUD.kMinimapBackgroundTextureCoords[3], 3 * GUIMarineHUD.kMinimapBackgroundTextureCoords[4], 2 * GUIMarineHUD.kMinimapBackgroundTextureCoords[3], 4 * GUIMarineHUD.kMinimapBackgroundTextureCoords[4] }

GUIMarineHUD.kMinimapPowerSize = Vector(GUIMarineHUD.kMinimapPowerTextureCoords[3] - GUIMarineHUD.kMinimapPowerTextureCoords[1], GUIMarineHUD.kMinimapPowerTextureCoords[4] - GUIMarineHUD.kMinimapPowerTextureCoords[2], 0)
GUIMarineHUD.kMinimapPowerPos = Vector(150, -34, 0)
GUIMarineHUD.kMinimapPos = Vector(20, 30, 0)
GUIMarineHUD.kMinimapscanlinesPos = Vector(40, 54, 0)

GUIMarineHUD.kFrameTexture = PrecacheAsset("ui/marine_HUD_frame.dds")
GUIMarineHUD.kFrameTopLeftCoords = { 0, 0, 680, 384 }
GUIMarineHUD.kFrameTopRightCoords = { 680, 0, 1360, 384 }
GUIMarineHUD.kFrameBottomLeftCoords = { 0, 384, 680, 768 }
GUIMarineHUD.kFrameBottomRightCoords = { 680, 384, 1360, 768 }
GUIMarineHUD.kFrameSize = Vector(1000, 600, 0)

-- FONT

GUIMarineHUD.kTextFontName = Fonts.kAgencyFB_Small
GUIMarineHUD.kCommanderFontName = Fonts.kAgencyFB_Small
GUIMarineHUD.kNanoShieldFontName = Fonts.kAgencyFB_Large
GUIMarineHUD.kNanoShieldFontSize = 20

GUIMarineHUD.kActiveCommanderColor = Color(246/255, 254/255, 37/255 )

GUIMarineHUD.kGameTimeTextFontSize = 26
GUIMarineHUD.kGameTimeTextPos = Vector(210, -170, 0)

GUIMarineHUD.kLocationTextSize = 22
GUIMarineHUD.kLocationTextOffset = Vector(280, 5, 0)

GUIMarineHUD.kTeamResourcesTextSize = 22
GUIMarineHUD.kTeamResourcesTextOffset = Vector(410, 280, 0)

GUIMarineHUD.kExperienceTextPos = Vector(780, -17, 0)
GUIMarineHUD.kLevelTextPos = Vector(560, -18, 0)

-- the hud will not show more notifications than at this intervall to prevent too much spam
GUIMarineHUD.kNotificationUpdateIntervall = 0.2

-- we update this only at initialize and then only once every 2 seconds
GUIMarineHUD.kPassiveUpgradesUpdateIntervall = 2

-- COLORS

GUIMarineHUD.kBackgroundColor = Color(0x01 / 0xFF, 0x8F / 0xFF, 0xFF / 0xFF, 1)

-- animation callbacks

function AnimFadeIn(scriptHandle, itemHandle)
    itemHandle:FadeIn(1, nil, AnimateLinear, AnimFadeOut)
end

function AnimFadeOut(scriptHandle, itemHandle)
    itemHandle:FadeOut(1, nil, AnimateLinear, AnimFadeIn)
end

local function UpdateItemsGUIScale(self)
    self.background:SetSize( Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0) )
    self.nanoshieldBackground:SetSize( Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0) )
    self.nanoshieldText:SetScale(GetScaledVector())
    self.nanoshieldText:SetPosition(GUIScale(Vector(0, -32, 0)))
    self.nanoshieldText:SetFontName(GUIMarineHUD.kNanoShieldFontName)
    GUIMakeFontScale(self.nanoshieldText)
end

function GUIMarineHUD:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.lastArmorLevel = 0
    self.lastWeaponsLevel = 0
    self.lastPassiveUpgradeCheck = 0
    self.motiontracking = false
	self.lastPowerState = 0
    self.lastNanoShieldState = false
    self.lastLocationText = ""
    
    self.scale =  Client.GetScreenHeight() / kBaseScreenHeight
    self.minimapEnabled = gHUDMapEnabled
    self.lastCommanderName = ""
    self.lastNotificationUpdate = Client.GetTime()
    
    -- used for global offset
    
    self.background = self:CreateAnimatedGraphicItem()
    self.background:SetPosition( Vector(0, 0, 0) )
    self.background:SetIsScaling(false)
    self.background:SetIsVisible(true)
    self.background:SetLayer(kGUILayerPlayerHUDBackground)
    self.background:SetColor( Color(1, 1, 1, 0) )
    
    self:InitFrame()
    
    self.nanoshieldBackground = self:CreateAnimatedGraphicItem()
    self.nanoshieldBackground:SetPosition( Vector(0, 0, 0) )
    self.nanoshieldBackground:SetIsScaling(false)
    self.nanoshieldBackground:SetIsVisible(true)
    self.nanoshieldBackground:SetColor( Color(0.3, 0.3, 1, 0.0) )
    self.nanoshieldBackground:SetLayer(kGUILayerPlayerHUDBackground)
    
    self.nanoshieldText = GetGUIManager():CreateTextItem()
    self.nanoshieldText:SetFontName(GUIMarineHUD.kNanoShieldFontName)
    self.nanoshieldText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.nanoshieldText:SetTextAlignmentX(GUIItem.Align_Center)
    self.nanoshieldText:SetTextAlignmentY(GUIItem.Align_Center)
    self.nanoshieldText:SetText(Locale.ResolveString("NANO_SHIELD_ACTIVE"))
    self.nanoshieldText:SetIsVisible(false)
    self.nanoshieldText:SetColor( Color(0.8, 0.8, 1, 0.8) )
    self.nanoshieldBackground:AddChild(self.nanoshieldText)
    
    -- create all hud elements
    
    self.commanderName = self:CreateAnimatedTextItem()
    self.commanderName:SetFontName(GUIMarineHUD.kTextFontName)
    self.commanderName:SetTextAlignmentX(GUIItem.Align_Min)
    self.commanderName:SetTextAlignmentY(GUIItem.Align_Min)
    self.commanderName:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.commanderName:SetLayer(kGUILayerPlayerHUDForeground1)
    self.commanderName:SetFontName(GUIMarineHUD.kCommanderFontName)
    self.commanderName:SetColor(Color(1,1,1,1))
    self.commanderName:SetFontIsBold(true)
    self.background:AddChild(self.commanderName)
    
    self.scanLeft = self:CreateAnimatedGraphicItem()    
    self.scanLeft:SetTexture(GUIMarineHUD.kScanTexture)
    self.scanLeft:SetTexturePixelCoordinates(GUIUnpackCoords(GUIMarineHUD.kScanLineTextureCoords))
    self.scanLeft:SetLayer(kGUILayerPlayerHUDForeground1)
    self.scanLeft:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.scanLeft:SetBlendTechnique(GUIItem.Add)
    self.scanLeft:AddAsChildTo(self.background)
    
    self.scanRight = self:CreateAnimatedGraphicItem()
    self.scanRight:SetTexture(GUIMarineHUD.kScanTexture)
    self.scanRight:SetTexturePixelCoordinates(GUIUnpackCoords(GUIMarineHUD.kScanLineTextureCoords))
    self.scanRight:SetLayer(kGUILayerPlayerHUDForeground1)
    self.scanRight:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.scanRight:SetBlendTechnique(GUIItem.Add)
    self.scanRight:AddAsChildTo(self.background)
    
    if self.minimapEnabled then
        self:InitializeMinimap()
    end
    
    self.locationText = self:CreateAnimatedTextItem()
    self.locationText:SetFontName(GUIMarineHUD.kTextFontName)
    self.locationText:SetTextAlignmentX(GUIItem.Align_Min)
    self.locationText:SetTextAlignmentY(GUIItem.Align_Min)
    self.locationText:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.locationText:SetLayer(kGUILayerPlayerHUDForeground2)
    self.locationText:SetColor(kBrightColor)
    self.locationText:SetFontIsBold(true)
    self.locationText:AddAsChildTo(self.background)
    
    self.armorLevel = GetGUIManager():CreateGraphicItem()
    self.armorLevel:SetTexture(GUIMarineHUD.kUpgradesTexture)
    self.armorLevel:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.background:AddChild(self.armorLevel)
    
    self.weaponLevel = GetGUIManager():CreateGraphicItem()
    self.weaponLevel:SetTexture(GUIMarineHUD.kUpgradesTexture)
    self.weaponLevel:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.background:AddChild(self.weaponLevel)
    
    self.mtracking = GetGUIManager():CreateGraphicItem()
    self.mtracking:SetTexture(GUIMarineHUD.kUpgradesTexture)
    self.mtracking:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.background:AddChild(self.mtracking)
    
    self.levelText = self:CreateAnimatedTextItem()
    self.levelText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.levelText:SetTextAlignmentX(GUIItem.Align_Max)
    self.levelText:SetTextAlignmentY(GUIItem.Align_Max)
    self.levelText:SetColor(GUIMarineStatus.kArmorBarColor)
    self.levelText:SetFontIsBold(false)
    self.levelText:SetBlendTechnique(GUIItem.Add)
    self.levelText:SetFontName(GUIMarineStatus.kFontName)
    self.levelText:SetText("Level 1")
    self.background:AddChild(self.levelText)
    
    self.experienceText = self:CreateAnimatedTextItem()
    self.experienceText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.experienceText:SetTextAlignmentX(GUIItem.Align_Max)
    self.experienceText:SetTextAlignmentY(GUIItem.Align_Max)
    self.experienceText:SetColor(GUIMarineStatus.kArmorBarColor)
    self.experienceText:SetFontIsBold(false)
    self.experienceText:SetBlendTechnique(GUIItem.Add)
    self.experienceText:SetFontName(GUIMarineStatus.kFontName)
    self.experienceText:SetText("100 XP")
    self.background:AddChild(self.experienceText)
    
    self.lastxp = 0
    self.lastlevel = 0
    
    self.statusDisplay = CreateStatusDisplay(self, kGUILayerPlayerHUDForeground1, self.background)
    self.eventDisplay = CreateEventDisplay(self, kGUILayerPlayerHUDForeground1, self.background, true)
    
    local style = { }
    style.textColor = kBrightColor
    style.textureSet = "marine"
    style.displayTeamRes = true
    self.resourceDisplay = CreatePlayerResourceDisplay(self, kGUILayerPlayerHUDForeground1, self.background, style)
    self.fuelDisplay = CreateFuelDisplay(self, kGUILayerPlayerHUDForeground1, self.background)
    self.inventoryDisplay = CreateInventoryDisplay(self, kGUILayerPlayerHUDForeground1, self.background)
    
    self.commanderNameIsAnimating = nil
    
    UpdateItemsGUIScale(self)
    
    self:Reset()
    
    self.visible = true
    self.statusDisplayVisible = true
    self.frameVisible = true
    self.inventoryDisplayVisible = true

    self:Update(0)

    -- Fix bug where changing resolution displays health bars again for Exos
    local player = Client.GetLocalPlayer()
    if player and player:isa("Exo") then
        self:SetStatusDisplayVisible(false)
        self:SetFrameVisible(false)
        self:SetInventoryDisplayVisible(false)
    end

    -- Fix bug where weapon/armor upgrade icons would display with the wrong coords on res change
    self:ShowNewWeaponLevel(PlayerUI_GetWeaponLevel())
    self:ShowNewArmorLevel(PlayerUI_GetArmorLevel())

end

function GUIMarineHUD:InitFrame()

    self.topLeftFrame = GetGUIManager():CreateGraphicItem()
    self.topLeftFrame:SetTexture(GUIMarineHUD.kFrameTexture)
    self.topLeftFrame:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.topLeftFrame:SetTexturePixelCoordinates(GUIUnpackCoords(GUIMarineHUD.kFrameTopLeftCoords))
    self.background:AddChild(self.topLeftFrame)
    
    self.topRightFrame = GetGUIManager():CreateGraphicItem()
    self.topRightFrame:SetTexture(GUIMarineHUD.kFrameTexture)
    self.topRightFrame:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.topRightFrame:SetTexturePixelCoordinates(GUIUnpackCoords(GUIMarineHUD.kFrameTopRightCoords))
    self.background:AddChild(self.topRightFrame)
    
    self.bottomLeftFrame = GetGUIManager():CreateGraphicItem()
    self.bottomLeftFrame:SetTexture(GUIMarineHUD.kFrameTexture)
    self.bottomLeftFrame:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.bottomLeftFrame:SetTexturePixelCoordinates(GUIUnpackCoords(GUIMarineHUD.kFrameBottomLeftCoords))
    self.background:AddChild(self.bottomLeftFrame)
    
    self.bottomRightFrame = GetGUIManager():CreateGraphicItem()
    self.bottomRightFrame:SetTexture(GUIMarineHUD.kFrameTexture)
    self.bottomRightFrame:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.bottomRightFrame:SetTexturePixelCoordinates(GUIUnpackCoords(GUIMarineHUD.kFrameBottomRightCoords))
    self.background:AddChild(self.bottomRightFrame)

end

function GUIMarineHUD:InitializeMinimap()

    self.lastLocationText = ""
    
    self.minimapBackground = self:CreateAnimatedGraphicItem()
    self.minimapBackground:SetTexture(kMinimapBorderTexture)
    self.minimapBackground:SetTexturePixelCoordinates(GUIUnpackCoords(GUIMarineHUD.kMinimapScanTextureCoords))
    self.minimapBackground:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.minimapBackground:SetColor(Color(1,1,1,1))
    self.minimapBackground:SetLayer(kGUILayerPlayerHUDForeground1)
    self.minimapBackground:AddAsChildTo(self.background)
    
    self.minimapPower = self:CreateAnimatedGraphicItem()
    self.minimapPower:SetTexture(kMinimapBorderTexture)
    self.minimapPower:SetTexturePixelCoordinates(GUIUnpackCoords(GUIMarineHUD.kMinimapPowerTextureCoords))
    self.minimapPower:SetLayer(kGUILayerPlayerHUDForeground2)
    self.minimapPower:SetColor( Color(1,1,1,0.5) )
    self.minimapPower:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.minimapPower:SetBlendTechnique(GUIItem.Add)
    self.minimapBackground:AddChild(self.minimapPower)
    
    self.minimapStencil = GetGUIManager():CreateGraphicItem()
    self.minimapStencil:SetColor( Color(1,1,1,1) )
    self.minimapStencil:SetIsStencil(true)
    self.minimapStencil:SetClearsStencilBuffer(false)
    self.minimapStencil:SetTexture(kMinimapBorderTexture)
    self.minimapStencil:SetTexturePixelCoordinates(GUIUnpackCoords(GUIMarineHUD.kMinimapStencilTextureCoords))
    self.minimapStencil:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.minimapBackground:AddChild(self.minimapStencil)
    
    self.minimapScript = GetGUIManager():CreateGUIScript("GUIMinimapFrame")
    self.minimapScript:ShowMap(true)
    self.minimapScript:SetBackgroundMode(GUIMinimapFrame.kModeZoom)
    -- skip updating icons outside this radius; saves CPU. Radius is heuristic;
    -- measured as when items just start disappearing in the corners
    self.minimapScript.updateRadius = 145
    -- the updateIntervalMultiplier is by default set to zero which runs the minimap at close to full framerate
    -- setting it to 0.5 causes things to work pretty well for the marine HUD
    self.minimapScript.updateIntervalMultipler = 0.5

    self:RefreshMinimapZoom()
    
    -- we need an additional frame here since all positions are relative in the minimap script (due to zooming)
    self.minimapFrame = GetGUIManager():CreateGraphicItem()
    self.minimapFrame:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.minimapFrame:AddChild(self.minimapScript:GetBackground())
    self.minimapFrame:SetColor(Color(1,1,1,0))
    
    self.minimapScanLines = self:CreateAnimatedGraphicItem()
    self.minimapScanLines:SetTexture(kMinimapBorderTexture)
    self.minimapScanLines:SetTexturePixelCoordinates(GUIUnpackCoords(GUIMarineHUD.kMinimapScanlineTextureCoords))
    self.minimapScanLines:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.minimapScanLines:SetColor(Color(1,1,1,1))
    self.minimapScanLines:SetLayer(1)
    self.minimapScanLines:SetBlendTechnique(GUIItem.Add)
    self.minimapScanLines:SetStencilFunc(GUIItem.NotEqual)
    self.minimapBackground:AddChild(self.minimapScanLines)
    
    self.minimapBackground:AddChild(self.minimapFrame)

end

function GUIMarineHUD:SetHUDMapEnabled(enabled)
    if self.minimapEnabled == enabled then return end

    if enabled then
        self:InitializeMinimap()
        self:ResetMinimap()
    else
        self:UninitializeMinimap()
    end
    
    self.minimapEnabled = enabled

end

function GUIMarineHUD:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)

    if self.statusDisplay then
        self.statusDisplay:Destroy()
        self.statusDisplay = nil
    end
    
    if self.eventDisplay then    
        self.eventDisplay:Destroy()   
        self.eventDisplay = nil 
    end
    
    if self.resourceDisplay then
        self.resourceDisplay:Destroy()
        self.resourceDisplay = nil
    end
    
    if self.fuelDisplay then
        self.fuelDisplay:Destroy()
        self.fuelDisplay = nil
    end
    
    if self.inventoryDisplay then
        self.inventoryDisplay:Destroy()
        self.inventoryDisplay = nil
    end
    
    self:UninitializeMinimap()

end

function GUIMarineHUD:UninitializeMinimap()

    if self.minimapScript then
        GetGUIManager():DestroyGUIScript(self.minimapScript)
        self.minimapScript = nil
    end
    
    if self.minimapBackground then
        self.minimapBackground:Destroy()
        self.minimapBackground = nil
    end
    
    if self.minimapFrame then
        GUI.DestroyItem(self.minimapFrame)
        self.minimapFrame = nil
    end

end

function GUIMarineHUD:SetStatusDisplayVisible(visible)
    
    self.statusDisplayVisible = visible
    self:UpdateVisibility()
    
end

function GUIMarineHUD:SetFrameVisible(visible)
    
    self.frameVisible = visible
    self:UpdateVisibility()
    
end

function GUIMarineHUD:SetInventoryDisplayVisible(visible)
    
    self.inventoryDisplayVisible = visible
    self:UpdateVisibility()
    
end

function GUIMarineHUD:Reset()
    
    self.scanLeft:SetUniformScale(self.scale)
    self.scanLeft:SetSize(Vector(1100, 1200, 0))
    self.scanLeft:SetColor(Color(1,1,1,0))
    
    self.scanRight:SetUniformScale(self.scale)
    self.scanRight:SetSize(Vector(-1100, 1200, 0))
    self.scanRight:SetColor(Color(1,1,1,0))

    self.commanderName:SetUniformScale(self.scale)
    self.commanderName:SetScale(GetScaledVector() * 1.1)
    self.commanderName:SetPosition(GUIMarineHUD.kCommanderNameOffset)
    self.commanderName:SetFontName(GUIMarineHUD.kTextFontName)
    GUIMakeFontScale(self.commanderName)
    
    self.statusDisplay:Reset(self.scale)
    self.eventDisplay:Reset(self.scale)
    self.resourceDisplay:Reset(self.scale)
    self.inventoryDisplay:Reset(self.scale)
    
    self.armorLevel:SetPosition(GUIMarineHUD.kUpgradePos * self.scale)
    self.armorLevel:SetSize(GUIMarineHUD.kUpgradeSize * self.scale)
    self.armorLevel:SetIsVisible(false)    
    
    self.weaponLevel:SetPosition(Vector(GUIMarineHUD.kUpgradePos.x, GUIMarineHUD.kUpgradePos.y + GUIMarineHUD.kUpgradeSize.y + 8, 0) * self.scale)
    self.weaponLevel:SetSize(GUIMarineHUD.kUpgradeSize * self.scale)
    self.weaponLevel:SetIsVisible(false)
    
    self.mtracking:SetPosition(Vector(GUIMarineHUD.kUpgradePos.x, GUIMarineHUD.kUpgradePos.y + GUIMarineHUD.kUpgradeSize.y + GUIMarineHUD.kUpgradeSize.y + 16, 0) * self.scale)
    self.mtracking:SetSize(GUIMarineHUD.kUpgradeSize * self.scale)
    self.mtracking:SetIsVisible(false)
        
    self.levelText:SetScale(Vector(1,1,1) * self.scale * 1.2)
    self.levelText:SetScale(GetScaledVector() * 0.8)
    self.levelText:SetPosition(GUIMarineHUD.kLevelTextPos)
    
    self.experienceText:SetScale(Vector(1,1,1) * self.scale * 1.2)
    self.experienceText:SetScale(GetScaledVector() * 0.8)
    self.experienceText:SetPosition(GUIMarineHUD.kExperienceTextPos)
    
    if self.minimapEnabled then    
        self:ResetMinimap()       
    end
    
    self.locationText:SetUniformScale(self.scale)
    self.locationText:SetScale(GetScaledVector())
    self.locationText:SetPosition(GUIMarineHUD.kLocationTextOffset)
    self.locationText:SetFontName(GUIMarineHUD.kTextFontName)
    GUIMakeFontScale(self.locationText)

    self.topLeftFrame:SetSize(GUIMarineHUD.kFrameSize * self.scale)
    
    self.topRightFrame:SetSize(GUIMarineHUD.kFrameSize * self.scale)
    self.topRightFrame:SetPosition(Vector(-GUIMarineHUD.kFrameSize.x, 0, 0) * self.scale)
    
    self.bottomLeftFrame:SetSize(GUIMarineHUD.kFrameSize * self.scale)
    self.bottomLeftFrame:SetPosition(Vector(0, -GUIMarineHUD.kFrameSize.y, 0) * self.scale)
    
    self.bottomRightFrame:SetSize(GUIMarineHUD.kFrameSize * self.scale)
    self.bottomRightFrame:SetPosition(Vector(-GUIMarineHUD.kFrameSize.x, -GUIMarineHUD.kFrameSize.y, 0) * self.scale)

end

GUIMarineHUD.kMinimapScanStartPos = Vector(0, - 128, 0)
GUIMarineHUD.kMinimapScanEndPos = Vector(0, GUIMarineHUD.kMinimapBackgroundSize.y + 512, 0)

local function ScanLineAnim(script, item)

    item:SetPosition(GUIMarineHUD.kMinimapScanStartPos)
    item:SetPosition(GUIMarineHUD.kMinimapScanEndPos, 4, "MINIMAP_SCANLINE_ANIM", AnimateLinear, ScanLineAnim)

end

function GUIMarineHUD:ResetMinimap()

    self.minimapBackground:SetUniformScale(self.scale)
    self.minimapBackground:SetSize(GUIMarineHUD.kMinimapBackgroundSize)
    self.minimapBackground:SetPosition( GUIMarineHUD.kMinimapPos )
    
    self.minimapPower:SetUniformScale(self.scale)
    self.minimapPower:SetSize(GUIMarineHUD.kMinimapPowerSize)
    self.minimapPower:SetPosition(GUIMarineHUD.kMinimapPowerPos)
    
    self.minimapStencil:SetSize(self.scale * GUIMarineHUD.kStencilSize)
    self.minimapStencil:SetPosition(self.scale * (- GUIMarineHUD.kStencilSize/2 + GUIMarineHUD.kStencilPos))
    
    self.minimapScanLines:SetUniformScale(self.scale)
    self.minimapScanLines:SetSize(GUIMarineHUD.kMinimapBackgroundSize)
    
    self.minimapFrame:SetPosition(Vector(-190, -180, 0) * self.scale)
    
    self.minimapScanLines:SetPosition(GUIMarineHUD.kMinimapScanStartPos)
    self.minimapScanLines:SetPosition(GUIMarineHUD.kMinimapScanEndPos, 4, "MINIMAP_SCANLINE_ANIM", AnimateLinear, ScanLineAnim)

end

function GUIMarineHUD:TriggerInitAnimations()

    self.scanLeft:SetColor(Color(1,1,1,0.8))
    --self.scanLeft:SetSize(Vector(1200, 1200, 0), 1)
    self.scanLeft:FadeIn(0.3, nil, AnimateLinear, 
        function (self)        
            self.scanLeft:FadeOut(0.5, nil, AnimateQuadratic)
        end
        )
    
    self.scanRight:SetColor(Color(1,1,1,0.8))
    --self.scanRight:SetSize(Vector(-1200, 1200, 0), 1)
    self.scanRight:FadeIn(0.3, nil, AnimateLinear, 
        function (self)        
            self.scanRight:FadeOut(0.5, nil, AnimateQuadratic)
        end
        )
        
    -- create random squares that fade out
    for i = 1, GUIMarineHUD.kNumInitSquares do
    
        local animatedSquare = self:CreateAnimatedGraphicItem()
        
        local randomPos = Vector(
                    math.random(0, 1920), 
                    math.random(0, 1200), 
                    0)
         
        animatedSquare:SetUniformScale(self.scale)           
        animatedSquare:SetPosition(randomPos)
        animatedSquare:SetSize(GUIMarineHUD.kInitSquareSize)
        animatedSquare:SetColor(GUIMarineHUD.kInitSquareColors)
        animatedSquare:FadeOut(1, nil, AnimateLinear,
            function (self, item)
                item:Destroy()
            end
            )
    
    end

end

function GUIMarineHUD:Update(deltaTime)

    PROFILE("GUIMarineHUD:Update")
    
    local fullMode = Client.GetOptionInteger("hudmode", kHUDMode.Full) == kHUDMode.Full
    
    self:SetHUDMapEnabled(fullMode)
    
    -- Update health / armor bar
    local statusUpdate = {
        PlayerUI_GetPlayerHealth(),
        PlayerUI_GetPlayerMaxHealth(),
        PlayerUI_GetPlayerArmor(),
        PlayerUI_GetPlayerMaxArmor(),
        PlayerUI_GetPlayerParasiteState(),
        0,
        0
    }

    self.statusDisplay:Update(deltaTime, statusUpdate)
    
    -- Update resource display
    local resourceUpdate = {
        PlayerUI_GetTeamResources(),
        PlayerUI_GetPersonalResources(),
        CommanderUI_GetTeamHarvesterCount()
    }

    self.resourceDisplay:Update(deltaTime, resourceUpdate)
    
    -- Update notifications and events
    if self.lastNotificationUpdate + GUIMarineHUD.kNotificationUpdateIntervall < Client.GetTime() then
    
        local notification = PlayerUI_GetRecentNotification()
        
        if Client.GetOptionInteger("hudmode", kHUDMode.Full) == kHUDMode.Minimal then
            notification = nil
        end
    
        self.eventDisplay:Update(Client.GetTime() - self.lastNotificationUpdate, { notification, PlayerUI_GetRecentPurchaseable() } )
        self.lastNotificationUpdate = Client.GetTime()
        
    end
    
    -- Update inventory
    local inventoryUpdate = {
        PlayerUI_GetActiveWeaponTechId(),
        PlayerUI_GetInventoryTechIds()
    }
    self.inventoryDisplay:Update(deltaTime, inventoryUpdate)

    if Client.GetOptionInteger("hudmode", kHUDMode.Full) == kHUDMode.Full then
    
        -- Update commander name
        local commanderName = PlayerUI_GetCommanderName()
    
        self.commanderName:SetIsVisible(true)
    
        if commanderName == nil then
        
            commanderName = Locale.ResolveString("NO_COMMANDER")
            
            if not self.commanderNameIsAnimating then
            
                self.commanderNameIsAnimating = true
                self.commanderName:SetColor(Color(1, 0, 0, 1))
                self.commanderName:FadeOut(1, nil, AnimateLinear, AnimFadeIn)
                
            end
            
        else
        
            if self.commanderNameIsAnimating then
            
                self.commanderNameIsAnimating = false
                self.commanderName:DestroyAnimations()
                
            end
            
            commanderName = Locale.ResolveString("COMMANDER") .. commanderName
            self.commanderName:SetColor(GUIMarineHUD.kActiveCommanderColor)
            
        end

        if self.lastCommanderName ~= commanderName then

            self.lastCommanderName = commanderName

            commanderName = string.UTF8Upper(commanderName)
            self.commanderName:DestroyAnimation("COMM_TEXT_WRITE")
            self.commanderName:SetText("")
            self.commanderName:SetText(commanderName, 0.5, "COMM_TEXT_WRITE")
            
        end
    
    else
        
        self.commanderName:SetIsVisible(false)
        
    end
    
    -- Update minimap
    local locationName = ConditionalValue(PlayerUI_GetLocationName(), string.upper(PlayerUI_GetLocationName()), "")
    
    if self.lastLocationText ~= locationName then
    
        self.locationText:SetText(locationName)
        self.lastLocationText = locationName
        
    end
    
    -- Update passive upgrades
    local armorLevel = 0
    local weaponLevel = 0
    local motiontracking = false
    
    armorLevel = PlayerUI_GetArmorLevel()
    weaponLevel = PlayerUI_GetWeaponLevel()
    motiontracking = PlayerUI_GetHasMotionTracking()
    
    self.armorLevel:SetIsVisible(armorLevel ~= 0)
    self.weaponLevel:SetIsVisible(weaponLevel ~= 0)
    
    if armorLevel ~= self.lastArmorLevel then
    
        self:ShowNewArmorLevel(armorLevel)
        self.lastArmorLevel = armorLevel
        
    end
    
    if weaponLevel ~= self.lastWeaponLevel then
    
        self:ShowNewWeaponLevel(weaponLevel)
        self.lastWeaponLevel = weaponLevel
        
    end
    
    if motiontracking ~= self.motiontracking then
        self:ShowMotionTracking(motiontracking)
        self.motiontracking = motiontracking
        
    end

    local useColor = kIconColors[kMarineTeamType]
    if not MarineUI_GetHasArmsLab() then
        useColor = Color(1, 0, 0, 1)
    end
    self.weaponLevel:SetColor(useColor)
    self.armorLevel:SetColor(useColor)
    
    -- Updates animations
    GUIAnimatedScript.Update(self, deltaTime)

    local useObsColor = Color(1, 1, 1, 1)        
    if not MarineUI_GetHasObservatory() then
        useObsColor = Color(1, 0, 0, 1)
    end
    self.mtracking:SetColor(useObsColor)
    
    if PlayerUI_GetGameMode() == kGameMode.Classic then
    
        self.experienceText:SetIsVisible(false)
        self.levelText:SetIsVisible(false)
        
    elseif PlayerUI_GetGameMode() == kGameMode.Combat then
    
        self.experienceText:SetIsVisible(true)
        self.levelText:SetIsVisible(true)
        self.clientxp = self.clientxp or 0

        local level = PlayerUI_GetCurrentLevel()
        local xp = PlayerUI_GetCurrentXP()
        local nxp = PlayerUI_GetNextLevelXP()
        
        if self.clientxp ~= xp then
            self.experienceText:SetText(ToString(math.floor(xp)) .. " XP / " .. ToString(math.floor(nxp)) .. " XP")
            self.levelText:SetText("Level " .. ToString(math.floor(level)))
			self.clientxp = xp
        end
        
    end
    
    -- Update power indicator
    if self.minimapScript and false then
    
        if not self.lastPowerCheck then
            self.lastPowerCheck = Client.GetTime()
        end
        
        if self.lastPowerCheck + 0.3 < Client.GetTime() then
        
            local currentPowerState = POWER_OFF
            local locationPower = PlayerUI_GetLocationPower()
            local isPowered, powerSource = locationPower[1], locationPower[2]
            
            if powerSource and powerSource:GetIsSocketed() then
            
                if isPowered then
                    currentPowerState = ConditionalValue(powerSource:GetHealth() < powerSource:GetMaxHealth(), POWER_DAMAGED, POWER_ON)
                else
                    currentPowerState = ConditionalValue(powerSource:GetIsDisabled(), POWER_DESTROYED, POWER_DAMAGED)  
                end
                
            else
                currentPowerState = POWER_OFF
            end
            
            if currentPowerState ~= self.lastPowerState then
            
                self:UpdatePowerIcon(currentPowerState)
                self.lastPowerState = currentPowerState
                
            end
            
            self.lastPowerCheck = Client.GetTime()
            
        end
    
    end

    -- Update nanoshield
    if self.lastNanoShieldState ~= PlayerUI_GetHasSpawnProtection() then

        self.lastNanoShieldState = PlayerUI_GetHasSpawnProtection()
        
        if self.lastNanoShieldState then
        
            self.nanoshieldBackground:SetColor(Color(0.6, 0.6, 1, 0.4), 0.3, "NANO_SHIELD_IN")
            self.nanoshieldText:SetIsVisible(true)
            
        else
        
            self.nanoshieldBackground:DestroyAnimations()
            self.nanoshieldBackground:FadeOut(0.4)
            self.nanoshieldText:SetIsVisible(false)
            
        end
        
    end   
    
end

function GUIMarineHUD:UpdatePowerIcon(powerState)

    self.minimapPower:DestroyAnimations()

    if powerState == POWER_OFF then
        self.minimapPower:SetColor(Color(1,1,1,0))
    elseif powerState == POWER_ON then
        self.minimapPower:SetColor(Color(30/255, 150/255, 151/255, 0.8))
    elseif powerState == POWER_DAMAGED then
        self.minimapPower:SetColor(Color(30/255, 150/255, 151/255, 0.8))
        self.minimapPower:Pause(1, "POWER_ANIM")
    elseif powerState == POWER_DESTROYED then
        self.minimapPower:SetColor(Color(0.6, 0, 0, 0.5))
        self.minimapPower:Pause(1, "POWER_ANIM")
    end

end

-- Shared function that sets gui items visible or invisible based on a number of variables.
function GUIMarineHUD:UpdateVisibility()
    
    self.background:SetIsVisible(self.visible)
    
    self.statusDisplay:SetIsVisible(self.visible and self.statusDisplayVisible)
    
    local frameVis = self.visible and self.frameVisible
    self.topLeftFrame:SetIsVisible(frameVis)
    self.topRightFrame:SetIsVisible(frameVis)
    self.bottomLeftFrame:SetIsVisible(frameVis)
    self.bottomRightFrame:SetIsVisible(frameVis)
    
    self.inventoryDisplay:SetIsVisible(self.visible and self.inventoryDisplayVisible)
    
end

function GUIMarineHUD:SetIsVisible(isVisible)
    
    self.visible = isVisible
    self:UpdateVisibility()
    
end

function GUIMarineHUD:GetIsVisible()
    
    return self.visible
    
end

function GUIMarineHUD:ShowNewArmorLevel(armorLevel)

    if armorLevel ~= 0 then
    
        local textureCoords = GetTextureCoordinatesForIcon(GetTechIdForArmorLevel(armorLevel), true)
        self.armorLevel:SetTexturePixelCoordinates(GUIUnpackCoords(textureCoords))
    end

end

function GUIMarineHUD:ShowMotionTracking(motiontracking)

    if motiontracking then
        local textureCoords = GetTextureCoordinatesForIcon(kTechId.MotionTracking, true)
        self.mtracking:SetIsVisible(true)
        self.mtracking:SetTexturePixelCoordinates(GUIUnpackCoords(textureCoords))
    end

end

function GUIMarineHUD:ShowNewWeaponLevel(weaponLevel)

    if weaponLevel ~= 0 then
    
        local textureCoords = GetTextureCoordinatesForIcon(GetTechIdForWeaponLevel(weaponLevel), true)
        self.weaponLevel:SetIsVisible(true)
        self.weaponLevel:SetTexturePixelCoordinates(GUIUnpackCoords(textureCoords))
   
    end

end

function GUIMarineHUD:OnAnimationCompleted(animatedItem, animationName, itemHandle)

    self.resourceDisplay:OnAnimationCompleted(animatedItem, animationName, itemHandle)
    
    if animationName == "POWER_ANIM" then
    
        self.minimapPower:FadeOut(1.5, nil, AnimateLinear,
        
            function(self, item)            
                item:Pause(1, nil, AnimateLinear, 
                
                    function(self, item)
                        item:FadeIn(1.5, "POWER_ANIM")
                    end)
            
            end)
            
    elseif animationName == "NANO_SHIELD_IN" then
    
        self.nanoshieldBackground:SetColor(Color(0.3, 0.3, 1, 0.1), 0.3, "NANO_SHIELD_OUT")
    
    elseif animationName == "NANO_SHIELD_OUT" then

        self.nanoshieldBackground:SetColor(Color(0.3, 0.3, 1, 0.2), 0.3, "NANO_SHIELD_IN")
    
    end

end

function GUIMarineHUD:OnLocalPlayerChanged(newPlayer)

    if newPlayer:isa("Exo") then
    
        self:SetStatusDisplayVisible(false)
        self:SetFrameVisible(false)
        self:SetInventoryDisplayVisible(false)
        
    else
    
        self:SetStatusDisplayVisible(true)
        self:SetFrameVisible(true)
        self:SetInventoryDisplayVisible(true)
        if newPlayer:GetTeamNumber() ~= kTeamReadyRoom and Client.GetIsControllingPlayer() then
            self:TriggerInitAnimations()
        end
        
    end
    
end

function GUIMarineHUD:OnResolutionChanged(oldX, oldY, newX, newY)

    self.scale = newY / kBaseScreenHeight 
    
    self:Reset()
    
    self:Uninitialize()
    self:Initialize()
    
end

local kMinUserZoomRoot = math.sqrt(0.3)
local kMaxUserZoomRoot = math.sqrt(1.0)
local kDefaultZoom = 0.75

-- The Client options is the master copy, so modify that, and call this when it changes
function GUIMarineHUD:RefreshMinimapZoom()

    if self.minimapScript then

        local normRoot = Clamp( Client.GetOptionFloat("minimap-zoom", kDefaultZoom), 0, 1 )
        local root = (1-normRoot)*kMinUserZoomRoot + normRoot*kMaxUserZoomRoot
        self.minimapScript:SetDesiredZoom( root*root )

    end

end

-- A global function anyone can call
function SafeRefreshMinimapZoom()

    local marineHUDScript = ClientUI.GetScript("Hud/Marine/GUIMarineHUD")
    if marineHUDScript then
        marineHUDScript:RefreshMinimapZoom()
    end
    
end

-- Some console commands players can use
function OnCommandChangeMiniZoom(val)

    local normRoot = Client.GetOptionFloat("minimap-zoom", kDefaultZoom)
    Client.SetOptionFloat("minimap-zoom", Clamp(normRoot+val, 0, 1))
    SafeRefreshMinimapZoom()
    
end

Event.Hook("Console_changeminizoom", OnCommandChangeMiniZoom)