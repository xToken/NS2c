
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIAlienHUD.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying the health and armor HUD information for the alien.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIDial.lua")
Script.Load("lua/GUIAnimatedScript.lua")

Script.Load("lua/Hud/Alien/GUIAlienHUDStyle.lua")
Script.Load("lua/Hud/GUIPlayerResource.lua")
Script.Load("lua/Hud/GUIEvent.lua")
Script.Load("lua/Hud/GUIInventory.lua")

class 'GUIAlienHUD' (GUIAnimatedScript)

local kTextureName = "ui/alien_hud_health.dds"
local kAbilityImage = "ui/alien_abilities.dds"
local kBackgroundNoiseTexture = "ui/alien_commander_bg_smoke.dds"

local kHealthFontName = "fonts/Stamp_large.fnt"
local kArmorFontName = "fonts/Stamp_medium.fnt"
local kAbilityNumFontName = "fonts/Kartika_small.fnt"

local kUmbraTextFontName = "fonts/Stamp_large.fnt"
local kUmbraTextYOffset = -52

local kHealthBackgroundWidth = 128
local kHealthBackgroundHeight = 128
local kHealthBackgroundOffset = Vector(30, -50, 0)
local kHealthBackgroundTextureX1 = 0
local kHealthBackgroundTextureY1 = 0
local kHealthBackgroundTextureX2 = 128
local kHealthBackgroundTextureY2 = 128

local kHealthTextureX1 = 0
local kHealthTextureY1 = 128
local kHealthTextureX2 = 128
local kHealthTextureY2 = 256

local kArmorTextureX1 = 128
local kArmorTextureY1 = 0
local kArmorTextureX2 = 256
local kArmorTextureY2 = 128

local kUpgradeSize = Vector(80, 80, 0) * 0.8
local kUpgradeYspacing = 50
local kUpgradePos = Vector(kUpgradeSize.x - 120, 0, 0)
local kUpgradesTexture = "ui/alien_buildmenu.dds"

local kBarMoveRate = 1.1

local kHealthTextYOffset = -9

local kArmorTextYOffset = 15

// This is how long a ball remains visible after it changes.
local kBallFillVisibleTimer = 5
// This is at what point in the kBallFillVisibleTimer to begin fading out.
local kBallStartFadeOutTimer = 2

// Energy ball settings.
local kEnergyBackgroundWidth = 128
local kEnergyBackgroundHeight = 128
local kEnergyBackgroundOffset = Vector(-kEnergyBackgroundWidth - 45, -150, 0)
local kEnergyTextureX1 = 128
local kEnergyTextureY1 = 128
local kEnergyTextureX2 = 256
local kEnergyTextureY2 = 256

local kNotEnoughEnergyColor = Color(0.6, 0, 0, 1)

local kAbilityIconSize = 128
local kSecondaryAbilityIconSize = 60
local kSecondaryAbilityBackgroundOffset = Vector(10, -80, 0)

local kDistanceBetweenAbilities = 50

local kInactiveAbilityBarWidth = kSecondaryAbilityIconSize * kMaxAlienAbilities
local kInactiveAbilityBarHeight = kSecondaryAbilityIconSize
local kInactiveAbilityBarOffset = Vector(-kInactiveAbilityBarWidth - 60, -kInactiveAbilityBarHeight - 120, 0)

local kSelectedAbilityColor = Color(1, 1, 1, 1)
local kUnselectedAbilityColor = Color(0.5, 0.5, 0.5, 1)

local kNotificationUpdateIntervall = 0.2

local function GetTechIdForUpgrade(upg) 
    return LookupTechData(upg, kTechDataKeyStructure, kTechId.None)
end

function GUIAlienHUD:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.scale = Client.GetScreenHeight() / kBaseScreenHeight
    
    self.lastUmbraState = false
    
    // Stores all state related to fading balls.
    self.fadeValues = { }
    
    // Keep track of weapon changes.
    self.lastActiveHudSlot = 0
    
    self:CreateUmbraText()
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
    
    self.resourceDisplay.background:SetShader("shaders/GUISmokeHUD.surface_shader")
    self.resourceDisplay.background:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
    self.resourceDisplay.background:SetFloatParameter("correctionX", 1)
    self.resourceDisplay.background:SetFloatParameter("correctionY", 0.3)
    
    self.upgrades = { }
    self.upgrades[kTechId.Crag] = { }
    self.upgrades[kTechId.Shift] = { }
    self.upgrades[kTechId.Shade] = { }
    self.upgrades[kTechId.Whip] = { }
    self.upgrades[kTechId.Hive] = { }
    for i = 1, #kAlienUpgradeChambers do
        self.upgrades[kAlienUpgradeChambers[i]][0] = 0
        for j = 1, 3 do
            self.upgrades[kAlienUpgradeChambers[i]][j] = GetGUIManager():CreateGraphicItem()
            self.upgrades[kAlienUpgradeChambers[i]][j]:SetTexture(kUpgradesTexture)
            self.upgrades[kAlienUpgradeChambers[i]][j]:SetAnchor(GUIItem.Right, GUIItem.Center)
            self.resourceBackground:AddChild(self.upgrades[kAlienUpgradeChambers[i]][j])
        end
    end
    
    self:Reset()
    
end

function GUIAlienHUD:SetIsVisible(isVisible)

    self.umbraText:SetIsVisible(isVisible)
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
    
    self.umbraText:SetUniformScale(self.scale)
    self.umbraText:SetPosition(Vector(0, GUIScale(kUmbraTextYOffset),0))
    
    for i = 1, #kAlienUpgradeChambers do
        for j = 1, 3 do
            local xPOS = kUpgradePos.x - (j *30)
            local yPOS = -40
            for k = 1, i do
                yPOS = yPOS + kUpgradeYspacing
            end
            self.upgrades[kAlienUpgradeChambers[i]][j]:SetPosition(Vector(xPOS, yPOS, 0) * self.scale)
            self.upgrades[kAlienUpgradeChambers[i]][j]:SetSize(kUpgradeSize * self.scale)
            self.upgrades[kAlienUpgradeChambers[i]][j]:SetIsVisible(false)
        end
    end
end

function GUIAlienHUD:CreateUmbraText()

    self.umbraText = self:CreateAnimatedTextItem()
    self.umbraText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.umbraText:SetTextAlignmentX(GUIItem.Align_Center)
    self.umbraText:SetTextAlignmentY(GUIItem.Align_Center)
    self.umbraText:SetColor(Color(kAlienThemeColor.r, kAlienThemeColor.g, kAlienThemeColor.b, 0))
    self.umbraText:SetFontIsBold(true)
    self.umbraText:SetFontName(kUmbraTextFontName)
    self.umbraText:SetText("UMBRA")
    
end

function GUIAlienHUD:UpdateUmbraText(deltaTime)

    local inUmbra = AlienUI_GetInUmbra()
    
    if inUmbra ~= self.lastUmbraState then
    
        self.umbraText:DestroyAnimations()
    
        if inUmbra then
            self.umbraText:FadeIn(1)
        else
            self.umbraText:FadeOut(1)
        end
        
        self.lastUmbraState = inUmbra
        
    end
    
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
    
    self.healthText = GUIManager:CreateTextItem()
    self.healthText:SetFontName(kHealthFontName)
    self.healthText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.healthText:SetPosition(Vector(0, GUIScale(kHealthTextYOffset), 0))
    self.healthText:SetTextAlignmentX(GUIItem.Align_Center)
    self.healthText:SetTextAlignmentY(GUIItem.Align_Center)
    self.healthText:SetColor(kAlienFontColor)
    self.healthText:SetInheritsParentAlpha(true)
    
    self.healthBall:GetBackground():AddChild(self.healthText)
    
    self.armorText = GUIManager:CreateTextItem()
    self.armorText:SetFontName(kArmorFontName)
    self.armorText:SetScale(Vector(0.75, 0.75, 0))
    self.armorText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.armorText:SetPosition(Vector(0, GUIScale(kArmorTextYOffset), 0))
    self.armorText:SetTextAlignmentX(GUIItem.Align_Center)
    self.armorText:SetTextAlignmentY(GUIItem.Align_Center)
    self.armorText:SetColor(Color(kAlienFontColor.r * 0.5, kAlienFontColor.g * 0.5, kAlienFontColor.b * 0.5, 1))
    self.armorText:SetInheritsParentAlpha(true)
    
    self.healthBall:GetBackground():AddChild(self.armorText)
    
end

function GUIAlienHUD:CreateEnergyBall()

    self.energyBarPercentage = PlayerUI_GetPlayerEnergy() / PlayerUI_GetPlayerMaxEnergy()
    
    local energyBallSettings = { }
    energyBallSettings.BackgroundWidth = GUIScale(kEnergyBackgroundWidth)
    energyBallSettings.BackgroundHeight = GUIScale(kEnergyBackgroundHeight)
    energyBallSettings.BackgroundAnchorX = GUIItem.Right
    energyBallSettings.BackgroundAnchorY = GUIItem.Bottom
    energyBallSettings.BackgroundOffset = kEnergyBackgroundOffset * GUIScale(1)
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
    self.energyBall = GUIDial()
    self.energyBall:Initialize(energyBallSettings)
    local energyBallBackground = self.energyBall:GetBackground()
    energyBallBackground:SetShader("shaders/GUISmokeHUD.surface_shader")
    energyBallBackground:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
    energyBallBackground:SetFloatParameter("correctionX", 1)
    energyBallBackground:SetFloatParameter("correctionY", 1)
    
    self.activeAbilityIcon = GUIManager:CreateGraphicItem()
    self.activeAbilityIcon:SetSize(Vector(GUIScale(kAbilityIconSize), GUIScale(kAbilityIconSize), 0))
    self.activeAbilityIcon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.activeAbilityIcon:SetPosition(Vector(-GUIScale(kAbilityIconSize) / 2, -GUIScale(kAbilityIconSize) / 2, 0))
    self.activeAbilityIcon:SetTexture(kAbilityImage)
    self.activeAbilityIcon:SetIsVisible(false)
    self.activeAbilityIcon:SetInheritsParentAlpha(true)
    self.energyBall:GetBackground():AddChild(self.activeAbilityIcon)
    
    self.secondaryAbilityBackground = GUIManager:CreateGraphicItem()
    self.secondaryAbilityBackground:SetSize(Vector(GUIScale(kSecondaryAbilityIconSize), GUIScale(kSecondaryAbilityIconSize), 0))
    self.secondaryAbilityBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.secondaryAbilityBackground:SetPosition(kSecondaryAbilityBackgroundOffset * GUIScale(1))
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
    self.secondaryAbilityIcon:SetSize(Vector(GUIScale(kSecondaryAbilityIconSize), GUIScale(kSecondaryAbilityIconSize), 0))
    self.secondaryAbilityIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.secondaryAbilityIcon:SetPosition(Vector(0, 0, 0))
    self.secondaryAbilityIcon:SetTexture(kAbilityImage)
    self.secondaryAbilityIcon:SetInheritsParentAlpha(true)
    self.secondaryAbilityBackground:AddChild(self.secondaryAbilityIcon)
    
    //self:CreateInactiveAbilityIcons()
    
end

function GUIAlienHUD:CreateInactiveAbilityIcons()

    self.inactiveAbilityIconList = { }
    self.inactiveAbilitiesBar = GUI.CreateItem()
    self.inactiveAbilitiesBar:SetSize(Vector(GUIScale(kInactiveAbilityBarWidth), GUIScale(kInactiveAbilityBarHeight), 0))
    self.inactiveAbilitiesBar:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.inactiveAbilitiesBar:SetPosition(kInactiveAbilityBarOffset * GUIScale(1))
    self.inactiveAbilitiesBar:SetColor(Color(0, 0, 0, 0))
    
    local currentIcon = 0
    while currentIcon < kMaxAlienAbilities do
    
        local iconBackground = GUIManager:CreateGraphicItem()
        iconBackground:SetSize(Vector(GUIScale(kSecondaryAbilityIconSize), GUIScale(kSecondaryAbilityIconSize), 0))
        iconBackground:SetAnchor(GUIItem.Left, GUIItem.Top)
        iconBackground:SetTexture(kTextureName)
        iconBackground:SetTexturePixelCoordinates(kHealthBackgroundTextureX1, kHealthBackgroundTextureY1,
                                                  kHealthBackgroundTextureX2, kHealthBackgroundTextureY2)
        iconBackground:SetIsVisible(false)
        iconBackground:SetShader("shaders/GUISmokeHUD.surface_shader")
        iconBackground:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
        iconBackground:SetFloatParameter("correctionX", 0.5)
        iconBackground:SetFloatParameter("correctionY", 0.5)
        
        self.inactiveAbilitiesBar:AddChild(iconBackground)
        
        local inactiveIcon = GUIManager:CreateGraphicItem()
        inactiveIcon:SetSize(Vector(GUIScale(kSecondaryAbilityIconSize), GUIScale(kSecondaryAbilityIconSize), 0))
        inactiveIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
        inactiveIcon:SetPosition(Vector(0, 0, 0))
        inactiveIcon:SetTexture(kAbilityImage)
        inactiveIcon:SetInheritsParentAlpha(true)
        iconBackground:AddChild(inactiveIcon)
        
        local numberIndicatorText = GUIManager:CreateTextItem()
        numberIndicatorText:SetFontName(kAbilityNumFontName)
        numberIndicatorText:SetScale(Vector(0.85, 0.85, 1))
        numberIndicatorText:SetColor(kAlienFontColor)
        numberIndicatorText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
        numberIndicatorText:SetPosition(Vector(GUIScale(1), GUIScale(3), 0))
        numberIndicatorText:SetTextAlignmentX(GUIItem.Align_Center)
        numberIndicatorText:SetTextAlignmentY(GUIItem.Align_Max)
        numberIndicatorText:SetText(tostring(currentIcon + 1))
        numberIndicatorText:SetInheritsParentAlpha(true)
        inactiveIcon:AddChild(numberIndicatorText)
        
        table.insert(self.inactiveAbilityIconList, { Background = iconBackground, Icon = inactiveIcon })
        
        currentIcon = currentIcon + 1
        
    end
    
    // The first and third icon are raised up a bit.
    self.inactiveAbilityIconList[1].Background:SetPosition(Vector(0, GUIScale(-20), 0))
    self.inactiveAbilityIconList[2].Background:SetPosition(Vector(GUIScale(kDistanceBetweenAbilities), 0, 0))
    self.inactiveAbilityIconList[3].Background:SetPosition(Vector(2 * GUIScale(kDistanceBetweenAbilities), GUIScale(-20), 0))
    
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
	
end

function GUIAlienHUD:Update(deltaTime)

    PROFILE("GUIAlienHUD:Update")
    
    self:UpdateHealthBall(deltaTime)
    self:UpdateEnergyBall(deltaTime)
    self:UpdateUmbraText(deltaTime)
    
    // update resource display
    self.resourceDisplay:Update(deltaTime, { PlayerUI_GetTeamResources(), PlayerUI_GetPersonalResources(), CommanderUI_GetTeamHarvesterCount() } )
    
    // updates animations
    GUIAnimatedScript.Update(self, deltaTime)
    
    // Update notifications and events
    if self.lastNotificationUpdate + kNotificationUpdateIntervall < Client.GetTime() then
    
        local purchaseId, playSound = PlayerUI_GetRecentPurchaseable()
        self.eventDisplay:Update(Client.GetTime() - self.lastNotificationUpdate, { PlayerUI_GetRecentNotification(), purchaseId, playSound } )
        self.lastNotificationUpdate = Client.GetTime()
        
    end

    if PlayerUI_GetIsPlaying() then
        for i = 1, #kAlienUpgradeChambers do
            local chambers = 0
            chambers = AlienUI_GetChamberCount(kAlienUpgradeChambers[i])
            if self.upgrades[kAlienUpgradeChambers[i]][0] ~= chambers then
                self:ShowUpgradeIcon(kAlienUpgradeChambers[i], chambers)
            end
        end
        /*
        if PlayerUI_GetChamberVote() > 0 then
            self.upgrades[kTechId.Hive][0]:SetIsVisible(true)
            self.upgrades[kTechId.Hive][0]:SetTexturePixelCoordinates(unpack(textureCoords))
        else
            self.upgrades[kTechId.Hive][0]:SetIsVisible(false)
        end
        */
    end
    
    self.inventoryDisplay:Update(deltaTime, { PlayerUI_GetActiveWeaponTechId(), PlayerUI_GetInventoryTechIds() })
    
end

function GUIAlienHUD:ShowUpgradeIcon(techId, count)
	local textureCoords = GetTextureCoordinatesForIcon(techId, false)
	for i = 1, 3 do
	    self.upgrades[techId][i]:SetIsVisible(i <= count)
		self.upgrades[techId][i]:SetTexturePixelCoordinates(unpack(textureCoords))
	end     
	self.upgrades[techId][0] = count
end

function GUIAlienHUD:UpdateHealthBall(deltaTime)

    local healthBarPercentageGoal = PlayerUI_GetPlayerHealth() / PlayerUI_GetPlayerMaxHealth()
    self.healthBarPercentage = Slerp(self.healthBarPercentage, healthBarPercentageGoal, deltaTime * kBarMoveRate)
    
    local armorBarPercentageGoal = PlayerUI_GetPlayerArmor() / PlayerUI_GetPlayerMaxArmor()
    self.armorBarPercentage = Slerp(self.armorBarPercentage, armorBarPercentageGoal, deltaTime * kBarMoveRate)
    self.healthBall:SetPercentage(self.healthBarPercentage)

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
    
    self.armorBall:SetPercentage(self.armorBarPercentage)
    self.armorText:SetText(tostring(math.floor(PlayerUI_GetPlayerArmor())))
    self.armorBall:Update(deltaTime)
    
    self:UpdateFading(self.healthBall:GetBackground(), self.healthBarPercentage * self.armorBarPercentage, deltaTime)
    self.armorBall:GetLeftSide():SetColor(self.healthBall:GetBackground():GetColor())
    self.armorBall:GetLeftSide():SetIsVisible(self.healthBall:GetBackground():GetIsVisible())
    self.armorBall:GetRightSide():SetColor(self.healthBall:GetBackground():GetColor())
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

function GUIAlienHUD:UpdateEnergyBall(deltaTime)

    local player = Client.GetLocalPlayer()
    if player:isa("Embryo") or player:isa("Egg") then
        self.energyBall:GetBackground():SetIsVisible(false)
        return
    end
    
    local energyBarPercentageGoal = PlayerUI_GetPlayerEnergy() / PlayerUI_GetPlayerMaxEnergy()
    self.energyBarPercentage = Slerp(self.energyBarPercentage, energyBarPercentageGoal, deltaTime * kBarMoveRate)
    
    self.energyBall:SetPercentage(self.energyBarPercentage)
    self.energyBall:Update(deltaTime)
    
    self:UpdateFading(self.energyBall:GetBackground(), self.energyBarPercentage, deltaTime)
    
    self:UpdateAbilities(deltaTime)
    
    local currentAlpha = self.energyBall:GetLeftSide():GetColor().a
    local useColor = Color(230/255, 171/255, 46/255, 1)
    local energizeLevel = PlayerUI_GetEnergizeLevel()

    if energizeLevel > 0 then
        useColor = GetEnergizeColor(energizeLevel)
    end
    
    useColor.a = currentAlpha
    
    self.energyBall:GetLeftSide():SetColor(useColor)
    self.energyBall:GetRightSide():SetColor(useColor)
    
end

function GUIAlienHUD:UpdateAbilities(deltaTime)

    local activeHudSlot = 0
    
    local abilityData = PlayerUI_GetAbilityData()
    local currentIndex = 1
    
    if table.count(abilityData) > 0 then
    
        local totalPower = abilityData[currentIndex]
        local minimumPower = abilityData[currentIndex + 1]
        local texXOffset = abilityData[currentIndex + 2] * kAbilityIconSize
        local texYOffset = (abilityData[currentIndex + 3] - 1) * kAbilityIconSize
        local visibility = abilityData[currentIndex + 4]
        
        activeHudSlot = abilityData[currentIndex + 5]
        self.activeAbilityIcon:SetIsVisible(true)
        self.activeAbilityIcon:SetTexturePixelCoordinates(texXOffset, texYOffset, texXOffset + kAbilityIconSize, texYOffset + kAbilityIconSize)
        local setColor = kNotEnoughEnergyColor
        
        if totalPower >= minimumPower then
            setColor = Color(1, 1, 1, 1)
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
    abilityData = PlayerUI_GetSecondaryAbilityData()
    currentIndex = 1
    if table.count(abilityData) > 0 then
    
        local totalPower = abilityData[currentIndex]
        local minimumPower = abilityData[currentIndex + 1]
        local texXOffset = abilityData[currentIndex + 2] * kAbilityIconSize
        local texYOffset = (abilityData[currentIndex + 3] - 1) * kAbilityIconSize
        local visibility = abilityData[currentIndex + 4]
        
        self.secondaryAbilityBackground:SetIsVisible(true)
        self.secondaryAbilityIcon:SetTexturePixelCoordinates(texXOffset, texYOffset, texXOffset + kAbilityIconSize, texYOffset + kAbilityIconSize)
        
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

    local numberElementsPerAbility = 3
    local abilityData = PlayerUI_GetInactiveAbilities()
    local numberAbilties = table.count(abilityData) / numberElementsPerAbility
    local currentIndex = 1
    
    if numberAbilties > 0 then
    
        self.inactiveAbilitiesBar:SetIsVisible(true)
        
        local totalAbilityCount = table.count(self.inactiveAbilityIconList)
        local fixedOffset = (kInactiveAbilityBarOffset * GUIScale(1)) + Vector(GUIScale(kDistanceBetweenAbilities), 0, 0)
        
        self.inactiveAbilitiesBar:SetPosition(fixedOffset)
        
        local currentAbilityIndex = 1
        
        while currentAbilityIndex <= totalAbilityCount do
        
            local visible = currentAbilityIndex <= numberAbilties
            self.inactiveAbilityIconList[currentAbilityIndex].Background:SetIsVisible(visible)
            
            if visible then
            
                local texXOffset = abilityData[currentIndex] * kAbilityIconSize
                local texYOffset = (abilityData[currentIndex + 1] - 1) * kAbilityIconSize
                local hudSlot = abilityData[currentIndex + 2]
                self.inactiveAbilityIconList[currentAbilityIndex].Icon:SetTexturePixelCoordinates(texXOffset, texYOffset, texXOffset + kAbilityIconSize, texYOffset + kAbilityIconSize)
                
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
        self.fadeValues[fadeItem].fadeTime = math.max(0, self.fadeValues[fadeItem].fadeTime - deltaTime)
        if self.fadeValues[fadeItem].fadeTime <= kBallStartFadeOutTimer then
            self.fadeValues[fadeItem].currentFadeAmount = self.fadeValues[fadeItem].fadeTime / kBallStartFadeOutTimer
        end
        
        if self.fadeValues[fadeItem].currentFadeAmount == 0 then
            fadeItem:SetIsVisible(false)
        else
            fadeItem:SetColor(Color(1, 1, 1, self.fadeValues[fadeItem].currentFadeAmount))
        end
        
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

function GUIAlienHUD:OnResolutionChanged(oldX, oldY, newX, newY)

    self.scale = newY / kBaseScreenHeight
    self:Reset()
    
end

function GUIAlienHUD:OnAnimationCompleted(animatedItem, animationName, itemHandle)
    self.resourceDisplay:OnAnimationCompleted(animatedItem, animationName, itemHandle)
end