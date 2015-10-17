
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIAlienHUD.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying the health and armor HUD information for the alien.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Added hiveinfo and upgrade info, tweaked positions.

Script.Load("lua/Globals.lua")
Script.Load("lua/GUIDial.lua")
Script.Load("lua/GUIAnimatedScript.lua")

Script.Load("lua/Hud/Alien/GUIAlienHUDStyle.lua")
Script.Load("lua/GUIPlayerResource.lua")
Script.Load("lua/GUIEvent.lua")
Script.Load("lua/Hud/GUIInventory.lua")

class 'GUIAlienHUD' (GUIAnimatedScript)

local kTextureName = PrecacheAsset("ui/alien_hud_health.dds")
local kHealthArmorTextureName = PrecacheAsset("ui/alien_health_armor.dds")
local kHealthIconTextureCoordinates = {0, 0, 32, 32}
local kArmorIconTextureCoordinates = {32, 32, 64, 64}

local kBackgroundNoiseTexture = PrecacheAsset("ui/alien_commander_bg_smoke.dds")
local kBabblerTexture = PrecacheAsset("ui/babbler.dds")

local kHealthFontName = Fonts.kStamp_Large
local kArmorFontName = Fonts.kStamp_Medium
local kAbilityNumFontName = Fonts.kKartika_Small
local kHiveLocationFontName = Fonts.kAgencyFB_Tiny

local kUmbraTextFontName = Fonts.kStamp_Large
local kUmbraTextYOffset = -52
local kHealthArmorIconSize = 16

local kAdrenalineEnergyColor = Color(1, 121/255, 12/255, 1)

local kHealthBackgroundWidth = 160
local kHealthBackgroundHeight = 160
local kHealthBackgroundOffset = Vector(30, -50, 0)
local kHealthBackgroundTextureX1 = 0
local kHealthBackgroundTextureY1 = 0
local kHealthBackgroundTextureX2 = 128
local kHealthBackgroundTextureY2 = 128

local kArmorCircleColor = Color(1, 121/255, 12/255, 1)

local kHealthTextureX1 = 0
local kHealthTextureY1 = 128
local kHealthTextureX2 = 128
local kHealthTextureY2 = 256

local kArmorTextureX1 = 128
local kArmorTextureY1 = 0
local kArmorTextureX2 = 256
local kArmorTextureY2 = 128

local kBabblerIndicatorPosition
local kBabblerIconSize

local kBarMoveRate = 1.1

local kHealthTextYOffset = -9

local kArmorTextYOffset = 15

// This is how long a ball remains visible after it changes.
local kBallFillVisibleTimer = 5
// This is at what point in the kBallFillVisibleTimer to begin fading out.
local kBallStartFadeOutTimer = 2

// Energy ball settings.
local kEnergyBackgroundWidth = 160
local kEnergyBackgroundHeight = 160
local kEnergyBackgroundOffset = Vector(-kEnergyBackgroundWidth - 45, -50, 0)

local kEnergyTextureX1 = 0
local kEnergyTextureY1 = 128
local kEnergyTextureX2 = 128
local kEnergyTextureY2 = 256

local kEnergyAdrenalineTextureX1 = 128
local kEnergyAdrenalineTextureY1 = 128
local kEnergyAdrenalineTextureX2 = 256
local kEnergyAdrenalineTextureY2 = 256

local kMovementSpecialIconSize

local kNotEnoughEnergyColor = Color(0.6, 0, 0, 1)

local kSecondaryAbilityIconSize = 60

local kDistanceBetweenAbilities = 50

local kInactiveAbilityBarWidth = kSecondaryAbilityIconSize * kMaxAlienAbilities
local kInactiveAbilityBarHeight = kSecondaryAbilityIconSize
local kInactiveAbilityBarOffset = Vector(-kInactiveAbilityBarWidth - 60, -kInactiveAbilityBarHeight - 120, 0)

local kSelectedAbilityColor = Color(1, 1, 1, 1)
local kUnselectedAbilityColor = Color(0.5, 0.5, 0.5, 1)

local kUpgradeSize = Vector(80, 80, 0) * 0.8
local kUpgradeYspacing = 50
local kUpgradePos = Vector(kUpgradeSize.x - 120, -200, 0)
local kUpgradeYStartPOS = -250

local kHiveStatusSize = Vector(80, 80, 0)
local kHiveStatusPos = Vector(kHiveStatusSize.x - 180, -80, 0)

local kMaxHives = 5
local kHiveStatusYspacing = 100

local kHiveHealthSize = Vector(10, 70, 0)
local kHiveHealthBarPos = Vector(-43, -63, 0)
local kHiveBuiltSize = Vector(10, 70, 0)
local kHiveBuiltBarPos = Vector(-85, -63, 0)
local kHiveTextPos = Vector(-115, 5, 0)
local kExperienceTextPos = Vector(780, -15, 0)
local kLevelTextPos = Vector(600, -15, 0)

local kUpgradesTexture = "ui/buildmenu.dds"
local kStatusTexture = "ui/alien_HUD_status.dds"

local kLowHiveHealth = 0.4
local kLowHealth = 0.4
local kNotificationUpdateIntervall = 0.2
local kHiveUpdateInterval = 1

local kHealthBarSize = Vector(200, 40, 0)
local kHealthBarPixelCoords = { 58, 352, 58 + 200, 352 + 40 }
local kHealthBarPos = Vector(10, -80, 0)
local kHealthBarColor = kAlienFontColor

local kAnimSpeedDown = 0.01
local kAnimSpeedUp = 0.01

local function GetTechIdForUpgrade(upg) 
    return LookupTechData(upg, kTechDataKeyStructure, kTechId.None)
end

local function UpdateItemsGUIScale(self)

    kBabblerIndicatorPosition = GUIScale(Vector(200, -120, 0))
    kBabblerIconSize = GUIScale(42)
    kMovementSpecialIconSize = GUIScale(70)

end

function GUIAlienHUD:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    UpdateItemsGUIScale(self)
    
    self.scale = Client.GetScreenHeight() / kBaseScreenHeight
    
    // Stores all state related to fading balls.
    self.fadeValues = { }
    
    // Keep track of weapon changes.
    self.lastActiveHudSlot = 0
    
    self:CreateHealthBall()
    self:CreateEnergyBall()
    
    self.resourceBackground = self:CreateAnimatedGraphicItem()
    self.resourceBackground:SetIsScaling(false)
    self.resourceBackground:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0))
    self.resourceBackground:SetPosition(Vector(0, 0, 0)) 
    self.resourceBackground:SetIsVisible(true)
    self.resourceBackground:SetLayer(kGUILayerPlayerHUDBackground)
    self.resourceBackground:SetColor(Color(1, 1, 1, 0))

    local style = { }
    style.textColor = kAlienFontColor
    style.textureSet = "alien"
    style.displayTeamRes = false
    self.resourceDisplay = CreatePlayerResourceDisplay(self, kGUILayerPlayerHUDForeground3, self.resourceBackground, style)
    self.eventDisplay = CreateEventDisplay(self, kGUILayerPlayerHUDForeground1, self.resourceBackground, false)
    self.inventoryDisplay = CreateInventoryDisplay(self, kGUILayerPlayerHUDForeground3, self.resourceBackground)
    self.lastNotificationUpdate = 0
    self.lastHiveUpdate = 0
    //self.resourceDisplay.background:SetShader("shaders/GUISmokeHUD.surface_shader")
    //self.resourceDisplay.background:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
    self.resourceDisplay.background:SetFloatParameter("correctionX", 1)
    self.resourceDisplay.background:SetFloatParameter("correctionY", 0.3)
    
    self.babblerIndicationFrame = GetGUIManager():CreateGraphicItem()
    self.babblerIndicationFrame:SetColor(Color(0,0,0,0))
    self.babblerIndicationFrame:SetPosition(kBabblerIndicatorPosition)
    self.babblerIndicationFrame:SetAnchor(GUIItem.Left, GUIItem.Bottom)

    self.upgrades = { }
    self.upgrades[kTechId.Crag] = { }
    self.upgrades[kTechId.Shift] = { }
    self.upgrades[kTechId.Shade] = { }
    self.upgrades[kTechId.Whip] = { }
    //self.upgrades[kTechId.Hive] = { }
    for i = 1, #kAlienUpgradeChambers do
        self.upgrades[kAlienUpgradeChambers[i]][4] = 0
        self.upgrades[kAlienUpgradeChambers[i]][5] = kTechId.None
        self.upgrades[kAlienUpgradeChambers[i]][6] = kTechId.None
        for j = 1, 3 do
            self.upgrades[kAlienUpgradeChambers[i]][j] = GetGUIManager():CreateGraphicItem()
            self.upgrades[kAlienUpgradeChambers[i]][j]:SetTexture(kUpgradesTexture)
            self.upgrades[kAlienUpgradeChambers[i]][j]:SetAnchor(GUIItem.Right, GUIItem.Bottom)
			self.upgrades[kAlienUpgradeChambers[i]][j]:SetIsVisible(false)
            self.resourceBackground:AddChild(self.upgrades[kAlienUpgradeChambers[i]][j])
        end
    end
    
    self.hives = { }
    for i = 1, kMaxHives do
        self.hives[i] = { }
        self.hives[i].icon = GetGUIManager():CreateGraphicItem()
        self.hives[i].icon:SetTexture(kUpgradesTexture)
        self.hives[i].icon:SetAnchor(GUIItem.Right, GUIItem.Top)
        self.resourceBackground:AddChild(self.hives[i].icon)
        self.hives[i].healthBar = self:CreateAnimatedGraphicItem()
        self.hives[i].healthBar:SetTexture(kStatusTexture)
        self.hives[i].healthBar:SetAnchor(GUIItem.Right, GUIItem.Top)
        self.hives[i].healthBar:SetTexturePixelCoordinates(unpack(kHealthBarPixelCoords))
        self.hives[i].healthBar:AddAsChildTo(self.resourceBackground)
        self.hives[i].builtBar = self:CreateAnimatedGraphicItem()
        self.hives[i].builtBar:SetTexture(kStatusTexture)
        self.hives[i].builtBar:SetAnchor(GUIItem.Right, GUIItem.Top)
        self.hives[i].builtBar:SetTexturePixelCoordinates(unpack(kHealthBarPixelCoords))
        self.hives[i].builtBar:AddAsChildTo(self.resourceBackground)
        self.hives[i].locationtext = self:CreateAnimatedTextItem()
        self.hives[i].locationtext:SetNumberTextAccuracy(1)
        self.hives[i].locationtext:SetFontName(kHiveLocationFontName)
        self.hives[i].locationtext:SetTextAlignmentX(GUIItem.Align_Min)
        self.hives[i].locationtext:SetTextAlignmentY(GUIItem.Align_Center)
        self.hives[i].locationtext:SetAnchor(GUIItem.Right, GUIItem.Top)
        self.hives[i].locationtext:SetColor(kHealthBarColor)
        self.hives[i].locationtext:AddAsChildTo(self.resourceBackground)
        self.hives[i].lasthealth = 0
        self.hives[i].lastbuilt = 0
        self.hives[i].lasttime = 0
        self.hives[i].techId = kTechId.Hive
    end
    
    self.levelText = self:CreateAnimatedTextItem()
    self.levelText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.levelText:SetTextAlignmentX(GUIItem.Align_Max)
    self.levelText:SetTextAlignmentY(GUIItem.Align_Max)
    self.levelText:SetColor(kAlienFontColor)
    self.levelText:SetFontIsBold(false)
    self.levelText:SetBlendTechnique(GUIItem.Add)
    self.levelText:SetFontName(kArmorFontName)
    self.levelText:SetText("Level 1")
    self.resourceBackground:AddChild(self.levelText)
    
    self.experienceText = self:CreateAnimatedTextItem()
    self.experienceText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.experienceText:SetTextAlignmentX(GUIItem.Align_Max)
    self.experienceText:SetTextAlignmentY(GUIItem.Align_Max)
    self.experienceText:SetColor(kAlienFontColor)
    self.experienceText:SetFontIsBold(false)
    self.experienceText:SetBlendTechnique(GUIItem.Add)
    self.experienceText:SetFontName(kArmorFontName)
    self.experienceText:SetText("100 XP")
    self.resourceBackground:AddChild(self.experienceText)
    
    self.lastxp = 0
    self.lastlevel = 0
    
    self:Reset()
    
end

function GUIAlienHUD:SetIsVisible(isVisible)

    self.healthBall:SetIsVisible(isVisible)
    self.healthText:SetIsVisible(isVisible)
    self.armorBall:SetIsVisible(isVisible)
    self.armorText:SetIsVisible(isVisible)
    self.energyBall:SetIsVisible(isVisible)
    
    if isVisible then
        
        self:ForceUnfade(self.healthBall:GetBackground())
        self:ForceUnfade(self.energyBall:GetBackground())
        
    end
    
end

function GUIAlienHUD:Reset()

    self.resourceBackground:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0))
    self.resourceDisplay:Reset(self.scale)
    self.eventDisplay:Reset(self.scale)
    self.inventoryDisplay:Reset(self.scale)
    
    for i = 1, #kAlienUpgradeChambers do
        for j = 1, 3 do
            local xPOS = kUpgradePos.x - (j *30)
            local yPOS = kUpgradeYStartPOS
            for k = 1, i do
                yPOS = yPOS - kUpgradeYspacing
            end
            self.upgrades[kAlienUpgradeChambers[i]][j]:SetPosition(Vector(xPOS, yPOS, 0) * self.scale)
            self.upgrades[kAlienUpgradeChambers[i]][j]:SetSize(kUpgradeSize * self.scale)
            self.upgrades[kAlienUpgradeChambers[i]][j]:SetIsVisible(false)
        end
    end
    
    for i = 1, kMaxHives do
        local yPOS = 0
        for k = 1, i do
            yPOS = yPOS - kHiveStatusYspacing
        end
        self.hives[i].icon:SetPosition(Vector(kHiveStatusPos.x, (kHiveStatusPos.y - yPOS), 0) * self.scale)
        self.hives[i].icon:SetSize(kHiveStatusSize * self.scale)
        self.hives[i].icon:SetIsVisible(false)
        self.hives[i].healthBar:SetUniformScale(self.scale)
        self.hives[i].healthBar:SetSize(kHiveHealthSize)
        self.hives[i].healthBar:SetPosition(Vector(kHiveHealthBarPos.x, (kHiveHealthBarPos.y - yPOS), 0))
        self.hives[i].healthBar:SetIsVisible(false)
        self.hives[i].builtBar:SetUniformScale(self.scale)
        self.hives[i].builtBar:SetSize(kHiveBuiltSize)
        self.hives[i].builtBar:SetPosition(Vector(kHiveBuiltBarPos.x, (kHiveBuiltBarPos.y - yPOS), 0))
        self.hives[i].builtBar:SetIsVisible(false)
        self.hives[i].locationtext:SetUniformScale(self.scale)
        self.hives[i].locationtext:SetPosition(Vector(kHiveTextPos.x, (kHiveTextPos.y - yPOS), 0))
        self.hives[i].locationtext:SetScale(GetScaledVector())
    end
        
    self.levelText:SetScale(Vector(1,1,1) * self.scale * 1.2)
    self.levelText:SetScale(GetScaledVector())
    self.levelText:SetPosition(kLevelTextPos)
    
    self.experienceText:SetScale(Vector(1,1,1) * self.scale * 1.2)
    self.experienceText:SetScale(GetScaledVector())
    self.experienceText:SetPosition(kExperienceTextPos)

end

function GUIAlienHUD:CreateHealthBall()

    self.healthBallFadeAmount = 1
    self.fadeHealthBallTime = 0
    
    self.healthBarPercentage = PlayerUI_GetPlayerHealth() / PlayerUI_GetPlayerMaxHealth()
    
    local healthBallSettings = { }
    healthBallSettings.BackgroundWidth = GUIScale(kHealthBackgroundWidth)
    healthBallSettings.BackgroundHeight = GUIScale(kHealthBackgroundHeight)
    healthBallSettings.BackgroundAnchorX = GUIItem.Left
    healthBallSettings.BackgroundAnchorY = GUIItem.Bottom
    healthBallSettings.BackgroundOffset = kHealthBackgroundOffset * GUIScale(1)
    healthBallSettings.BackgroundTextureName = kTextureName
    healthBallSettings.BackgroundTextureX1 = kHealthBackgroundTextureX1
    healthBallSettings.BackgroundTextureY1 = kHealthBackgroundTextureY1
    healthBallSettings.BackgroundTextureX2 = kHealthBackgroundTextureX2
    healthBallSettings.BackgroundTextureY2 = kHealthBackgroundTextureY2
    healthBallSettings.ForegroundTextureName = kTextureName
    healthBallSettings.ForegroundTextureWidth = 128
    healthBallSettings.ForegroundTextureHeight = 128
    healthBallSettings.ForegroundTextureX1 = kHealthTextureX1
    healthBallSettings.ForegroundTextureY1 = kHealthTextureY1
    healthBallSettings.ForegroundTextureX2 = kHealthTextureX2
    healthBallSettings.ForegroundTextureY2 = kHealthTextureY2
    healthBallSettings.InheritParentAlpha = true
    self.healthBall = GUIDial()
    self.healthBall:Initialize(healthBallSettings)
    
    local healthBallBackground = self.healthBall:GetBackground()
    healthBallBackground:SetShader("shaders/GUISmokeHUD.surface_shader")
    healthBallBackground:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
    healthBallBackground:SetFloatParameter("correctionX", 1)
    healthBallBackground:SetFloatParameter("correctionY", 1)
    healthBallBackground:SetLayer(kGUILayerPlayerHUDBackground)
    
    self.healthBall:GetLeftSide():SetColor(Color(230/255, 171/255, 46/255, 1))
    self.healthBall:GetRightSide():SetColor(Color(230/255, 171/255, 46/255, 1))

    self.armorBarPercentage = PlayerUI_GetPlayerArmor() / PlayerUI_GetPlayerMaxArmor()
    
    local armorBallSettings = { }
    armorBallSettings.BackgroundWidth = GUIScale(kHealthBackgroundWidth)
    armorBallSettings.BackgroundHeight = GUIScale(kHealthBackgroundHeight)
    armorBallSettings.BackgroundAnchorX = GUIItem.Left
    armorBallSettings.BackgroundAnchorY = GUIItem.Bottom
    armorBallSettings.BackgroundOffset = kHealthBackgroundOffset * GUIScale(1)
    armorBallSettings.BackgroundTextureName = nil
    armorBallSettings.BackgroundTextureX1 = kHealthBackgroundTextureX1
    armorBallSettings.BackgroundTextureY1 = kHealthBackgroundTextureY1
    armorBallSettings.BackgroundTextureX2 = kHealthBackgroundTextureX2
    armorBallSettings.BackgroundTextureY2 = kHealthBackgroundTextureY2
    armorBallSettings.ForegroundTextureName = kTextureName
    armorBallSettings.ForegroundTextureWidth = 128
    armorBallSettings.ForegroundTextureHeight = 128
    armorBallSettings.ForegroundTextureX1 = kArmorTextureX1
    armorBallSettings.ForegroundTextureY1 = kArmorTextureY1
    armorBallSettings.ForegroundTextureX2 = kArmorTextureX2
    armorBallSettings.ForegroundTextureY2 = kArmorTextureY2
    armorBallSettings.InheritParentAlpha = false
    self.armorBall = GUIDial()
    self.armorBall:Initialize(armorBallSettings)
    
    self.armorBall:GetBackground():SetLayer(kGUILayerPlayerHUD)
    
    self.armorBall:GetLeftSide():SetColor(kArmorCircleColor)
    self.armorBall:GetRightSide():SetColor(kArmorCircleColor)
    
    self.healthText = GUIManager:CreateTextItem()
    self.healthText:SetFontName(kHealthFontName)
    self.healthText:SetScale(GetScaledVector())
    GUIMakeFontScale(self.healthText)
    self.healthText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.healthText:SetPosition(Vector(0, GUIScale(kHealthTextYOffset), 0))
    self.healthText:SetTextAlignmentX(GUIItem.Align_Center)
    self.healthText:SetTextAlignmentY(GUIItem.Align_Center)
    self.healthText:SetColor(kAlienFontColor)
    self.healthText:SetInheritsParentAlpha(true)
    
    self.healthBall:GetBackground():AddChild(self.healthText)
    
    // Create health icon to display to the right of the health text
    self.healthIcon = GUIManager:CreateGraphicItem()
    self.healthIcon:SetSize(Vector(GUIScale(kHealthArmorIconSize), GUIScale(kHealthArmorIconSize), 0))
    self.healthIcon:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.healthIcon:SetPosition(Vector(GUIScale(1), -GUIScale(kHealthArmorIconSize) / 2, 0))
    self.healthIcon:SetTexture(kHealthArmorTextureName)
    self.healthIcon:SetTexturePixelCoordinates(unpack(kHealthIconTextureCoordinates))
    self.healthIcon:SetIsVisible(true)
    self.healthIcon:SetInheritsParentAlpha(true)
    self.healthIcon:SetInheritsParentScaling(false)
    self.healthText:AddChild(self.healthIcon)
    
    self.armorText = GUIManager:CreateTextItem()
    self.armorText:SetFontName(kArmorFontName)
    self.armorText:SetScale(GetScaledVector()*0.75)
    GUIMakeFontScale(self.armorText)
    self.armorText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.armorText:SetPosition(Vector(0, GUIScale(kArmorTextYOffset), 0))
    self.armorText:SetTextAlignmentX(GUIItem.Align_Center)
    self.armorText:SetTextAlignmentY(GUIItem.Align_Center)
    self.armorText:SetColor(kArmorCircleColor)
    self.armorText:SetInheritsParentAlpha(true)
    
    self.healthBall:GetBackground():AddChild(self.armorText)
    
    // Create armor icon to display to the right of the health text
    self.armorIcon = GUIManager:CreateGraphicItem()
    self.armorIcon:SetSize(Vector(GUIScale(kHealthArmorIconSize), GUIScale(kHealthArmorIconSize), 0))
    self.armorIcon:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.armorIcon:SetPosition(Vector(GUIScale(1), -GUIScale(kHealthArmorIconSize) / 2, 0))
    self.armorIcon:SetTexture(kHealthArmorTextureName)
    self.armorIcon:SetTexturePixelCoordinates(unpack(kArmorIconTextureCoordinates))
    self.armorIcon:SetIsVisible(true)
    self.armorIcon:SetInheritsParentAlpha(true)
    self.armorIcon:SetInheritsParentScaling(false)
    self.armorText:AddChild(self.armorIcon)
    
end

function GUIAlienHUD:CreateEnergyBall()

    local energyBallSettings = { }
    energyBallSettings.BackgroundWidth = GUIScale(kEnergyBackgroundWidth)
    energyBallSettings.BackgroundHeight = GUIScale(kEnergyBackgroundHeight)
    energyBallSettings.BackgroundAnchorX = GUIItem.Right
    energyBallSettings.BackgroundAnchorY = GUIItem.Bottom
    energyBallSettings.BackgroundOffset = GUIScale(kEnergyBackgroundOffset)
    energyBallSettings.BackgroundTextureName = kTextureName
    energyBallSettings.BackgroundTextureX1 = kHealthBackgroundTextureX1
    energyBallSettings.BackgroundTextureY1 = kHealthBackgroundTextureY1
    energyBallSettings.BackgroundTextureX2 = kHealthBackgroundTextureX2
    energyBallSettings.BackgroundTextureY2 = kHealthBackgroundTextureY2
    energyBallSettings.ForegroundTextureName = kTextureName
    energyBallSettings.ForegroundTextureWidth = 128
    energyBallSettings.ForegroundTextureHeight = 128
    energyBallSettings.ForegroundTextureX1 = kEnergyTextureX1
    energyBallSettings.ForegroundTextureY1 = kEnergyTextureY1
    energyBallSettings.ForegroundTextureX2 = kEnergyTextureX2
    energyBallSettings.ForegroundTextureY2 = kEnergyTextureY2
    energyBallSettings.InheritParentAlpha = true

    self.energyBarPercentage = AlienUI_GetPlayerEnergy() / AlienUI_GetPlayerMaxEnergy()
    
    self.energyBall = GUIDial()
    self.energyBall:Initialize(energyBallSettings)
    local energyBallBackground = self.energyBall:GetBackground()
    energyBallBackground:SetShader("shaders/GUISmokeHUD.surface_shader")
    energyBallBackground:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
    energyBallBackground:SetFloatParameter("correctionX", 1)
    energyBallBackground:SetFloatParameter("correctionY", 1)
    energyBallBackground:SetLayer(kGUILayerPlayerHUDBackground)
    
    self.energyBall:GetLeftSide():SetColor(Color(230/255, 171/255, 46/255, 1))
    self.energyBall:GetRightSide():SetColor(Color(230/255, 171/255, 46/255, 1))
    
    self.activeAbilityIcon = GUIManager:CreateGraphicItem()
    self.activeAbilityIcon:SetSize(Vector(GUIScale(kInventoryIconTextureWidth*0.75), GUIScale(kInventoryIconTextureHeight*0.75), 0))
    self.activeAbilityIcon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.activeAbilityIcon:SetPosition(Vector(-GUIScale(kInventoryIconTextureWidth*0.75) / 2, -GUIScale(kInventoryIconTextureHeight*0.75) / 2, 0))
    self.activeAbilityIcon:SetTexture(kInventoryIconsTexture)
    self.activeAbilityIcon:SetIsVisible(false)
    self.activeAbilityIcon:SetInheritsParentAlpha(true)
    self.energyBall:GetBackground():AddChild(self.activeAbilityIcon)
    
    self.secondaryAbilityBackground = GUIManager:CreateGraphicItem()
    self.secondaryAbilityBackground:SetSize(Vector(GUIScale(kSecondaryAbilityIconSize*2), GUIScale(kSecondaryAbilityIconSize*2), 0))
    self.secondaryAbilityBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.secondaryAbilityBackground:SetPosition(Vector(15, -90, 0) * GUIScale(1))
    self.secondaryAbilityBackground:SetTexture(kTextureName)
    self.secondaryAbilityBackground:SetTexturePixelCoordinates(kHealthBackgroundTextureX1, kHealthBackgroundTextureY1,
                                                               kHealthBackgroundTextureX2, kHealthBackgroundTextureY2)
    self.secondaryAbilityBackground:SetInheritsParentAlpha(true)
    self.secondaryAbilityBackground:SetIsVisible(false)
    self.secondaryAbilityBackground:SetShader("shaders/GUISmokeHUD.surface_shader")
    self.secondaryAbilityBackground:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
    self.secondaryAbilityBackground:SetFloatParameter("correctionX", 0.5)
    self.secondaryAbilityBackground:SetFloatParameter("correctionY", 0.5)
    self.activeAbilityIcon:AddChild(self.secondaryAbilityBackground)
    
    self.secondaryAbilityIcon = GUIManager:CreateGraphicItem()
    self.secondaryAbilityIcon:SetSize(Vector(GUIScale(kSecondaryAbilityIconSize*2), GUIScale(kSecondaryAbilityIconSize), 0))
    self.secondaryAbilityIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.secondaryAbilityIcon:SetPosition(Vector(0, GUIScale(26), 0))
    self.secondaryAbilityIcon:SetTexture(kInventoryIconsTexture)
    self.secondaryAbilityIcon:SetInheritsParentAlpha(true)
    self.secondaryAbilityBackground:AddChild(self.secondaryAbilityIcon)
    
    self.movementSpecialIconBg = GUIManager:CreateGraphicItem()
    self.movementSpecialIconBg:SetSize(Vector(kMovementSpecialIconSize, kMovementSpecialIconSize, 0))
    self.movementSpecialIconBg:SetPosition(Vector(-kMovementSpecialIconSize * 0.5, kMovementSpecialIconSize * 0.25, 0))
    self.movementSpecialIconBg:SetTexture("ui/buildmenu.dds")
    self.movementSpecialIconBg:SetIsVisible(false)
    self.movementSpecialIconBg:SetColor(Color(0,0,0,1))
    self.energyBall:GetBackground():AddChild(self.movementSpecialIconBg)
    
    self.movementSpecialIcon = GUIManager:CreateGraphicItem()
    self.movementSpecialIcon:SetSize(Vector(kMovementSpecialIconSize, kMovementSpecialIconSize, 0))
    self.movementSpecialIcon:SetPosition(Vector(-kMovementSpecialIconSize * 0.5, kMovementSpecialIconSize * 1.25, 0))
    self.movementSpecialIcon:SetTexture("ui/buildmenu.dds")
    self.movementSpecialIcon:SetIsVisible(false)
    self.energyBall:GetBackground():AddChild(self.movementSpecialIcon)
    
    self.adrenalineEnergy = GUIDial()
    
    local adrenalineBallSettings = { }
    adrenalineBallSettings.BackgroundWidth = GUIScale(kEnergyBackgroundWidth)
    adrenalineBallSettings.BackgroundHeight = GUIScale(kEnergyBackgroundHeight)
    adrenalineBallSettings.BackgroundAnchorX = GUIItem.Right
    adrenalineBallSettings.BackgroundAnchorY = GUIItem.Bottom
    adrenalineBallSettings.BackgroundOffset = kEnergyBackgroundOffset * GUIScale(1)
    adrenalineBallSettings.BackgroundTextureName = nil
    adrenalineBallSettings.BackgroundTextureX1 = kHealthBackgroundTextureX1
    adrenalineBallSettings.BackgroundTextureY1 = kHealthBackgroundTextureY1
    adrenalineBallSettings.BackgroundTextureX2 = kHealthBackgroundTextureX2
    adrenalineBallSettings.BackgroundTextureY2 = kHealthBackgroundTextureY2
    adrenalineBallSettings.ForegroundTextureName = kTextureName
    adrenalineBallSettings.ForegroundTextureWidth = 128
    adrenalineBallSettings.ForegroundTextureHeight = 128
    adrenalineBallSettings.ForegroundTextureX1 = kArmorTextureX1
    adrenalineBallSettings.ForegroundTextureY1 = kArmorTextureY1
    adrenalineBallSettings.ForegroundTextureX2 = kArmorTextureX2
    adrenalineBallSettings.ForegroundTextureY2 = kArmorTextureY2
    adrenalineBallSettings.InheritParentAlpha = false
    
    self.adrenalineEnergy:Initialize(adrenalineBallSettings)
    self.adrenalineEnergy:GetLeftSide():SetColor(kAdrenalineEnergyColor)
    self.adrenalineEnergy:GetRightSide():SetColor(kAdrenalineEnergyColor) 
    self.adrenalineEnergy:GetBackground():SetLayer(kGUILayerPlayerHUD)
    
end

function GUIAlienHUD:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    if self.healthBall then
    
        self.healthBall:Uninitialize()
        self.healthBall = nil
        
    end
    
    if self.armorBall then
    
        self.armorBall:Uninitialize()
        self.armorBall = nil
        
    end
    
    if self.energyBall then
    
        self.energyBall:Uninitialize()
        self.energyBall = nil
        
    end
    
    if self.adrenalineEnergy then
    
        self.adrenalineEnergy:Uninitialize()
        self.adrenalineEnergy = nil
        
    end
    
    if self.inactiveAbilitiesBar then
    
        GUI.DestroyItem(self.inactiveAbilitiesBar)
        self.inactiveAbilitiesBar = nil
        self.inactiveAbilityIconList = { }
        
    end
    
    if self.resourceDisplay then
    
        self.resourceDisplay:Destroy()
        self.resourceDisplay = nil
        
    end
    
    if self.eventDisplay then
    
        self.eventDisplay:Destroy()   
        self.eventDisplay = nil 
        
    end
    
    if self.inventoryDisplay then
        self.inventoryDisplay:Destroy()
        self.inventoryDisplay = nil
    end
    
    if self.babblerIndicationFrame then
        GUI.DestroyItem(self.babblerIndicationFrame)
        self.babblerIndicationFrame = nil
    end
    
    self.babblerIcons = nil
    
end

local function UpdateHealthBall(self, deltaTime)

    PROFILE("GUIAlienHUD:UpdateHealthBall")
    
    local healthBarPercentageGoal = PlayerUI_GetPlayerHealth() / PlayerUI_GetPlayerMaxHealth()
    self.healthBarPercentage = Slerp(self.healthBarPercentage, healthBarPercentageGoal, deltaTime * kBarMoveRate)
    
    local maxArmor = PlayerUI_GetPlayerMaxArmor()
    local armorBarPercentageGoal = 1
    
    if maxArmor == 0 then
        armorBarPercentageGoal = 0
        self.armorBarPercentage = 0
    else
        armorBarPercentageGoal = PlayerUI_GetPlayerArmor() / maxArmor
        self.armorBarPercentage = Slerp(self.armorBarPercentage, armorBarPercentageGoal, deltaTime * kBarMoveRate)
    end    
    
    // don't use more than 60% for armor in case armor value is bigger than health
    // for skulk use 10 / 70 = 14% as armor and 86% as health
    local armorUseFraction = Clamp( PlayerUI_GetPlayerMaxArmor() / PlayerUI_GetPlayerMaxHealth(), 0, 0.6)
    local healthUseFraction = 1 - armorUseFraction
    
    // set global rotation to snap to the health ring    
    self.armorBall:SetRotation( - 2 * math.pi * self.healthBarPercentage * healthUseFraction )
    
    self.healthBall:SetPercentage(self.healthBarPercentage * healthUseFraction)
    self.armorBall:SetPercentage(self.armorBarPercentage * armorUseFraction)

    // It's probably better to do a math.ceil for display health instead of floor, but NS1 did it this way
    // and I want to make sure the values are exactly the same to avoid confusion right now. When you are 
    // barely alive though, show 1 health.
    local health = PlayerUI_GetPlayerHealth()
    
    local displayHealth = math.floor(health)
    if health > 0 and displayHealth == 0 then
        displayHealth = 1
    end    
    self.healthText:SetText(tostring(displayHealth))
    self.healthBall:Update(deltaTime)

    self.armorText:SetText(tostring(math.floor(PlayerUI_GetPlayerArmor())))
    self.armorBall:Update(deltaTime)

    local updated = healthBarPercentageGoal ~= self.healthBarPercentage or armorBarPercentageGoal ~= self.armorBarPercentage
    
    -- The resource display will have updated this first, so we only need to set it to full if needed
    -- It will be low already if no animations were running
    if updated and self.updateInterval ~= kUpdateIntervalFull then
        self.updateInterval = kUpdateIntervalFull
    end
    
    self:UpdateFading(self.healthBall:GetBackground(), self.healthBarPercentage * self.armorBarPercentage, deltaTime)
    self.armorBall:GetLeftSide():SetIsVisible(self.healthBall:GetBackground():GetIsVisible())
    self.armorBall:GetRightSide():SetIsVisible(self.healthBall:GetBackground():GetIsVisible())
    
end

local gEnergizeColors = nil
local function GetEnergizeColor(energizeLevel)

    if not gEnergizeColors then
        gEnergizeColors = {
            Color(243/255, 189/255, 77/255,0),
            Color(252/255, 219/255, 149/255,0),
            Color(254/255, 249/255, 238/255,0),
        }
    
    end
    
    return gEnergizeColors[energizeLevel]
    
end

local lastEnergy = 0
local function UpdateEnergyBall(self, deltaTime)

    PROFILE("GUIAlienHUD:UpdateEnergyBall")
    
    local energy = AlienUI_GetPlayerEnergy()
    local totalMaxEnergy = AlienUI_GetPlayerMaxEnergy()
    local additionalMaxEnergy = 0
    local normalMaxEnergy = totalMaxEnergy - additionalMaxEnergy

    local normalEnergy = math.min(normalMaxEnergy, energy)
    local additionalEnergy = math.max(0, energy - normalMaxEnergy)

    local overflowFraction = (totalMaxEnergy - additionalMaxEnergy) / totalMaxEnergy
    local normalEnergyFraction = normalEnergy / normalMaxEnergy
    local overFlowEnergyFraction = additionalMaxEnergy > 0 and additionalEnergy / additionalMaxEnergy or 0

    self.energyBall:SetPercentage(normalEnergyFraction * overflowFraction)
    self.energyBall:Update(deltaTime)
  
    self.adrenalineEnergy:SetRotation(- 2 * math.pi * normalEnergyFraction * overflowFraction)
    self.adrenalineEnergy:SetPercentage(overFlowEnergyFraction * (1 - overflowFraction))
    self.adrenalineEnergy:Update(deltaTime)
    
    //self:UpdateFading(self.energyBall:GetBackground(), energy / totalMaxEnergy, deltaTime)
    self:UpdateAbilities(deltaTime)
    
    local hasMovementSpecial = AlienUI_GetHasMovementSpecial()
    if hasMovementSpecial then

        local techId = AlienUI_GetMovementSpecialTechId()
        if techId then
        
            local energyCost = AlienUI_GetMovementSpecialEnergyCost()
            local msFraction = 1-AlienUI_GetMovementSpecialCooldown()
            local color = AlienUI_GetPlayerEnergy() >= energyCost and Color(kArmorCircleColor) or Color(1, 0, 0, 1)

            local x1, y1, x2, y2 = unpack(GetTextureCoordinatesForIcon(techId))
            self.movementSpecialIcon:SetTexturePixelCoordinates(x1, y2, x2, y2-(y2-y1)*msFraction)
            self.movementSpecialIcon:SetSize(Vector(kMovementSpecialIconSize, -kMovementSpecialIconSize*msFraction, 0))
            self.movementSpecialIconBg:SetTexturePixelCoordinates(x1, y1, x2, y2)
            self.movementSpecialIconBg:SetIsVisible(true)
            self.movementSpecialIcon:SetIsVisible(true)
            self.movementSpecialIcon:SetColor(color)
            
        end
        
    else
        self.movementSpecialIcon:SetIsVisible(false)
        self.movementSpecialIconBg:SetIsVisible(false)
    end    
    
    -- Same as with the healthbar, but this runs after it
    -- Only set to full if values changed for smooth animation
    if lastEnergy ~= energy and self.updateInterval ~= kUpdateIntervalFull then
        self.updateInterval = kUpdateIntervalFull
        lastEnergy = energy
    end
end

local function UpdateNotifications(self, deltaTime)

    PROFILE("UpdateNotifications")
    
    if self.lastNotificationUpdate + kNotificationUpdateIntervall < Client.GetTime() then
    
        local purchaseId, playSound = PlayerUI_GetRecentPurchaseable()
        self.eventDisplay:Update(Client.GetTime() - self.lastNotificationUpdate, { PlayerUI_GetRecentNotification(), purchaseId, playSound } )
        self.lastNotificationUpdate = Client.GetTime()
        
    end
    
end

local function UpdateBabblerIndication(self, delatTime)

    local numBabblers = PlayerUI_GetNumClingedBabblers()
    
    if not self.babblerIcons then
        self.babblerIcons = {}
    end

    local displayedNumBabblers = #self.babblerIcons
    if displayedNumBabblers < numBabblers then
        
        for i = 1, numBabblers - displayedNumBabblers do
        
            local icon = GetGUIManager():CreateGraphicItem()
            icon:SetSize(Vector(kBabblerIconSize, kBabblerIconSize, 0))
            icon:SetPosition(Vector(#self.babblerIcons * kBabblerIconSize, 0, 0))
            icon:SetTexture(kBabblerTexture)
            self.babblerIndicationFrame:AddChild(icon)
            table.insert(self.babblerIcons, icon)
            
        end
        
    elseif numBabblers < displayedNumBabblers then
    
        for i = 1, displayedNumBabblers - numBabblers do
        
            GUI.DestroyItem(self.babblerIcons[#self.babblerIcons])
            table.remove(self.babblerIcons, #self.babblerIcons)    
    
        end
    
    end
    
    local size = Vector(kBabblerIconSize * numBabblers, kBabblerIconSize, 0)
    self.babblerIndicationFrame:SetSize(size)
    

end

function GUIAlienHUD:Update(deltaTime)

    PROFILE("GUIAlienHUD:Update")
    
    // update resource display
    self.resourceDisplay:Update(deltaTime, { PlayerUI_GetTeamResources(), PlayerUI_GetPersonalResources(), CommanderUI_GetTeamHarvesterCount() } )
    
    // updates animations
    GUIAnimatedScript.Update(self, deltaTime)
    
    UpdateNotifications(self, deltaTime)

    if PlayerUI_GetIsPlaying() and PlayerUI_GetGameMode() == kGameMode.Classic then
        for i = 1, #kAlienUpgradeChambers do
            local chambers, hastech, upgrade, upgrades
            chambers = AlienUI_GetChamberCount(kAlienUpgradeChambers[i])
            hastech = BuyMenus_GetTechAvailable(kAlienUpgradeChambers[i])
            upgrades = AlienBuy_GetUpgradesForChamber(kAlienUpgradeChambers[i])
            for j = 1, #upgrades do
                if BuyMenus_GetUpgradePurchased(upgrades[j]) then
                    upgrade = upgrades[j]
                end
            end
            if self.upgrades[kAlienUpgradeChambers[i]][4] ~= chambers or self.upgrades[kAlienUpgradeChambers[i]][5] ~= hastech or self.upgrades[kAlienUpgradeChambers[i]][6] ~= upgrade then
                self:ShowUpgradeIcon(kAlienUpgradeChambers[i], chambers, hastech, upgrade)
            end
        end
    end
    if not BuyMenus_GetTechAvailable(kTechId.Hive) then
        upgrades = AlienBuy_GetUpgradesForChamber(kAlienUpgradeChambers[i])
        for j = 1, #upgrades do
            for i = 1, 3 do
                self.upgrades[upgrades[j]][i]:SetIsVisible(false)
            end
        end
    end
    
    self.inventoryDisplay:Update(deltaTime, { PlayerUI_GetActiveWeaponTechId(), PlayerUI_GetInventoryTechIds() })

-- The resource display was modifying the update interval for the script, so this block will run last
    -- This way we can also update the display rate in case it's set to low after an animation finishes
    UpdateHealthBall(self, deltaTime)
    UpdateEnergyBall(self, deltaTime)
    UpdateBabblerIndication(self, deltaTime)
    
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
        
        if xp ~= self.clientxp then
            self.experienceText:SetText(ToString(math.floor(xp)) .. " XP / " .. ToString(math.floor(nxp)) .. " XP")
            self.levelText:SetText("Level " .. ToString(math.floor(level)))
			self.clientxp = xp
        end
        
    end
    
end

function GUIAlienHUD:UpdateAbilities(deltaTime)

    local activeHudSlot = 0
    
    local abilityData = AlienUI_GetAbilityData()
    local currentIndex = 1
    
    if table.count(abilityData) > 0 then
    
        local totalPower = abilityData[currentIndex]
        local minimumPower = abilityData[currentIndex + 1]
        local techId = abilityData[currentIndex + 2]
        local visibility = abilityData[currentIndex + 3]
        activeHudSlot = abilityData[currentIndex + 4]
        
        self.activeAbilityIcon:SetIsVisible(true)
        self.activeAbilityIcon:SetTexturePixelCoordinates(GetTexCoordsForTechId(techId))
        local setColor = kNotEnoughEnergyColor
        
        if totalPower >= minimumPower then
            setColor = Color(230/255, 171/255, 46/255, 1)
        end
        
        local currentBackgroundColor = self.energyBall:GetBackground():GetColor()
        currentBackgroundColor.r = setColor.r
        currentBackgroundColor.g = setColor.g
        currentBackgroundColor.b = setColor.b
        
        self.energyBall:GetBackground():SetColor(currentBackgroundColor)
        self.activeAbilityIcon:SetColor(setColor)
        self.energyBall:GetLeftSide():SetColor(setColor)
        self.energyBall:GetRightSide():SetColor(setColor)
        
    else
        self.activeAbilityIcon:SetIsVisible(false)
    end
    
    // The the player changed abilities, force show the energy ball and
    // the inactive abilities bar.
    if activeHudSlot ~= self.lastActiveHudSlot then
    
        self.energyBall:GetBackground():SetIsVisible(true)
        self:ForceUnfade(self.energyBall:GetBackground())
        /*
        for i, ability in ipairs(self.inactiveAbilityIconList) do
            self:ForceUnfade(ability.Background)
        end
        */
        
    end
    
    self.lastActiveHudSlot = activeHudSlot
    
    // Secondary ability.
    abilityData = AlienUI_GetSecondaryAbilityData()
    currentIndex = 1
    if table.count(abilityData) > 0 then
    
        local totalPower = abilityData[currentIndex]
        local minimumPower = abilityData[currentIndex + 1]
        local techId = abilityData[currentIndex + 2]
        local visibility = abilityData[currentIndex + 3]
        local hudSlot = abilityData[currentIndex + 4]

        if techId ~= kTechId.None then        
            self.secondaryAbilityBackground:SetIsVisible(true)
            self.secondaryAbilityIcon:SetTexturePixelCoordinates(GetTexCoordsForTechId(techId))
        else
            self.secondaryAbilityBackground:SetIsVisible(false)
        end
        
        if totalPower < minimumPower then
        
            self.secondaryAbilityIcon:SetColor(kNotEnoughEnergyColor)
            self.secondaryAbilityBackground:SetColor(kNotEnoughEnergyColor)
            
        else
        
            local enoughEnergyColor = Color(1, 1, 1, 1)
            self.secondaryAbilityIcon:SetColor(enoughEnergyColor)
            self.secondaryAbilityBackground:SetColor(enoughEnergyColor)
            
        end
        
    else
        self.secondaryAbilityBackground:SetIsVisible(false)
    end
    
    // self:UpdateInactiveAbilities(deltaTime, activeHudSlot)
    
end

function GUIAlienHUD:UpdateInactiveAbilities(deltaTime, activeHudSlot)

    local numberElementsPerAbility = 2
    local abilityData = AlienUI_GetInactiveAbilities()
    local numberAbilities = table.count(abilityData) / numberElementsPerAbility
    local currentIndex = 1
    
    if numberAbilities > 0 then
    
        self.inactiveAbilitiesBar:SetIsVisible(true)
        
        local totalAbilityCount = table.count(self.inactiveAbilityIconList)
        local fixedOffset = (kInactiveAbilityBarOffset * GUIScale(1)) + Vector(GUIScale(kDistanceBetweenAbilities), 0, 0)
        
        self.inactiveAbilitiesBar:SetPosition(fixedOffset)
        
        local currentAbilityIndex = 1
        
        while currentAbilityIndex <= totalAbilityCount do
        
            local visible = currentAbilityIndex <= numberAbilities
            self.inactiveAbilityIconList[currentAbilityIndex].Background:SetIsVisible(visible)
            
            if visible then
            
                local hudSlot = abilityData[currentIndex]
                local techId = abilityData[currentIndex + 1]
                self.inactiveAbilityIconList[currentAbilityIndex].Icon:SetTexturePixelCoordinates(GetTexCoordsForTechId(techId))
                
                if hudSlot == activeHudSlot then
                
                    self.inactiveAbilityIconList[currentAbilityIndex].Icon:SetColor(kSelectedAbilityColor)
                    self.inactiveAbilityIconList[currentAbilityIndex].Background:SetColor(kSelectedAbilityColor)
                    
                else
                
                    self.inactiveAbilityIconList[currentAbilityIndex].Icon:SetColor(kUnselectedAbilityColor)
                    self.inactiveAbilityIconList[currentAbilityIndex].Background:SetColor(kUnselectedAbilityColor)
                    
                end
                
                currentIndex = currentIndex + numberElementsPerAbility
                
            end
            
            self:UpdateFading(self.inactiveAbilityIconList[currentAbilityIndex].Background, 1, deltaTime)
            currentAbilityIndex = currentAbilityIndex + 1
            
        end
    else
        self.inactiveAbilitiesBar:SetIsVisible(false)
    end
    
end

function GUIAlienHUD:UpdateFading(fadeItem, itemFillPercentage, deltaTime)

    if self.fadeValues[fadeItem] == nil then
    
        self.fadeValues[fadeItem] = { }
        self.fadeValues[fadeItem].lastFillPercentage = 0
        self.fadeValues[fadeItem].currentFadeAmount = 1
        self.fadeValues[fadeItem].fadeTime = 0
        
    end
    
    local lastFadePercentage = self.fadeValues[fadeItem].lastPercentage
    self.fadeValues[fadeItem].lastPercentage = itemFillPercentage
    
    // Only fade when the ball is completely filled.
    if itemFillPercentage == 1 then
    
        // Check if we should start fading (itemFillPercentage just hit 100%).
        if lastFadePercentage ~= 1 then
            self:ForceUnfade(fadeItem)
        end
        
        // Handle fading out the health ball.
        /*
        self.fadeValues[fadeItem].fadeTime = math.max(0, self.fadeValues[fadeItem].fadeTime - deltaTime)
        if self.fadeValues[fadeItem].fadeTime <= kBallStartFadeOutTimer then
            self.fadeValues[fadeItem].currentFadeAmount = self.fadeValues[fadeItem].fadeTime / kBallStartFadeOutTimer
        end
        
        if self.fadeValues[fadeItem].currentFadeAmount == 0 then
            fadeItem:SetIsVisible(false)
        else
            fadeItem:SetColor(Color(1, 1, 1, self.fadeValues[fadeItem].currentFadeAmount))
        end
        */
        
    else
    
        fadeItem:SetIsVisible(true)
        fadeItem:SetColor(Color(1, 1, 1, 1))
        
    end

end

function GUIAlienHUD:ForceUnfade(unfadeItem)

    if self.fadeValues[unfadeItem] ~= nil then
    
        unfadeItem:SetColor(Color(1, 1, 1, 1))
        self.fadeValues[unfadeItem].fadeTime = kBallFillVisibleTimer
        self.fadeValues[unfadeItem].currentFadeAmount = 1
        
    end
    
end

function GUIAlienHUD:ShowUpgradeIcon(techId, count, hastech, upgrade)
    local textureCoords
    if upgrade ~= nil then
        textureCoords = GetTextureCoordinatesForIcon(upgrade, false)
    else
        textureCoords = GetTextureCoordinatesForIcon(techId, false)
    end
    for i = 1, 3 do
        if count == 0 and not hastech then 
            self.upgrades[techId][i]:SetIsVisible(false)
        else
            self.upgrades[techId][i]:SetIsVisible(true)
        end
        self.upgrades[techId][i]:SetColor(ConditionalValue(i <= count, kAlienFontColor, Color(1, 0, 0, 1)))
        self.upgrades[techId][i]:SetTexturePixelCoordinates(unpack(textureCoords))
    end
    self.upgrades[techId][4] = count
    self.upgrades[techId][5] = hastech
    self.upgrades[techId][6] = upgrade
end

local kHiveDamageAnimRate = 0.2

local function HiveDamagePulsate(script, item)

    item:SetColor(Color(0.7, 0, 0, 1), kHiveDamageAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, 
        function (script, item)        
            item:SetColor(Color(1, 0, 0, 1), kHiveDamageAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, HiveDamagePulsate )        
        end )

end

local function CheckHiveStatusChanged(hive, icon)

	if icon.healthpercent ~= hive:GetHealth() / hive:GetMaxHealth() or 
        icon.buildprogress ~= ConditionalValue(hive:GetIsBuilt(), 1, hive:GetBuiltFraction()) or 
        icon.location ~= hive:GetLocationName() or icon.lastupdate + 10 < Shared.GetTime() or icon.techId ~= hive:GetTechId() then
		return true
	else
		return false
	end

end

function GUIAlienHUD:UpdateHiveInformation(deltaTime)

    PROFILE("GUIAlienHUD:UpdateHiveInformation")

    local hives = AlienUI_GetHiveList()
    for i = 1, kMaxHives do
		local hive = hives[i]
		if hive ~= nil then
		
			if CheckHiveStatusChanged(hive, self.hives[i]) then
			
			    local techId = hive:GetTechId()
			    local locationname = hive:GetLocationName()
				local textureCoords = GetTextureCoordinatesForIcon(techId, false)
				local healthpercent = hive:GetHealth() / hive:GetMaxHealth()
				local buildprogress = ConditionalValue(hive:GetIsBuilt(), 1, hive:GetBuiltFraction())
				self.hives[i].locationtext:SetText(locationname)
				self.hives[i].locationtext:SetIsVisible(true)
				self.hives[i].locationtext:SetColor(kHealthBarColor)
				self.hives[i].icon:SetTexturePixelCoordinates(unpack(textureCoords))
				self.hives[i].icon:SetIsVisible(true)
				self.hives[i].healthBar:SetSize(Vector(kHiveHealthSize.x, kHiveHealthSize.y * healthpercent, 0))
				self.hives[i].healthBar:SetIsVisible(true)
				self.hives[i].builtBar:SetSize(Vector(kHiveBuiltSize.x, kHiveBuiltSize.y * buildprogress, 0))
				self.hives[i].builtBar:SetIsVisible(buildprogress < 1)

				if hive:GetLastAttackedOrWarnedTime() > (Shared.GetTime() - 5) then
					self.hives[i].hivedamageAnimPlaying = Shared.GetTime() + 1
					self.hives[i].healthBar:SetColor(Color(1, 0, 0, 1), kHiveDamageAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, HiveDamagePulsate )
			    else
			        self.hives[i].hivedamageAnimPlaying = 0
			        self.hives[i].healthBar:DestroyAnimation("ANIM_HEALTH_PULSATE")
					self.hives[i].healthBar:SetColor(kHealthBarColor)
			    end
			    
				if healthpercent < kLowHiveHealth then
				    self.hives[i].icon:SetColor(Color(1, 0, 0, 1))
					self.hives[i].locationtext:SetColor(Color(1, 0, 0, 1))
				else
					self.hives[i].icon:SetColor(kHealthBarColor)
					self.hives[i].locationtext:SetColor(kHealthBarColor)
				end

				self.hives[i].healthpercent = healthpercent
				self.hives[i].buildprogress = buildprogress
				self.hives[i].location = locationname
				self.hives[i].techId = techId
				self.hives[i].lastupdate = Shared.GetTime()
				
			end
			
		else
		
			self.hives[i].icon:SetIsVisible(false)
            self.hives[i].healthBar:SetIsVisible(false)
            self.hives[i].builtBar:SetIsVisible(false)
            self.hives[i].locationtext:SetIsVisible(false)
			
		end
	end
	
end

function GUIAlienHUD:OnResolutionChanged(oldX, oldY, newX, newY)

    self.scale = newY / kBaseScreenHeight
    self:Reset()
    
    self:Uninitialize()
    self:Initialize()
    
end

function GUIAlienHUD:OnAnimationCompleted(animatedItem, animationName, itemHandle)
    self.resourceDisplay:OnAnimationCompleted(animatedItem, animationName, itemHandle)
end