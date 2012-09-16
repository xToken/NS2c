
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

local kHealthFontName = "fonts/Stamp_large.fnt"
local kArmorFontName = "fonts/Stamp_medium.fnt"
local kAbilityNumFontName = "fonts/Kartika_small.fnt"

local kUmbraTextFontName = "fonts/Stamp_large.fnt"
local kUmbraTextYOffset = -52

local kUpgradeSize = Vector(80, 80, 0) * 0.8
local kUpgradeYspacing = 50
local kUpgradePos = Vector(kUpgradeSize.x - 120, -200, 0)
local kUpgradesTexture = "ui/alien_buildmenu.dds"

local kHealthTextYOffset = -60
local kArmorTextYOffset = -30
local kEnergyTextYOffset = -30
local kEnergyTextXOffset = -150

local kNotEnoughEnergyColor = Color(0.6, 0, 0, 1)

local kAbilityIconSize = 128
local kSecondaryAbilityIconSize = 60
local kSecondaryAbilityBackgroundOffset = Vector(-150, -80, 0)

local kDistanceBetweenAbilities = 50

local kInactiveAbilityBarWidth = kSecondaryAbilityIconSize * kMaxAlienAbilities
local kInactiveAbilityBarHeight = kSecondaryAbilityIconSize
local kInactiveAbilityBarOffset = Vector(-kInactiveAbilityBarWidth - 60, -kInactiveAbilityBarHeight - 120, 0)

local kSelectedAbilityColor = Color(1, 1, 1, 1)
local kUnselectedAbilityColor = Color(0.5, 0.5, 0.5, 1)

local kLowHealth = 0.3
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
    
    self.resourceBackground = self:CreateAnimatedGraphicItem()
    self.resourceBackground:SetIsScaling(false)
    self.resourceBackground:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0))
    self.resourceBackground:SetPosition(Vector(0, 0, 0)) 
    self.resourceBackground:SetIsVisible(true)
    self.resourceBackground:SetLayer(kGUILayerPlayerHUDBackground)
    self.resourceBackground:SetColor(Color(1, 1, 1, 0))
    
    self:CreateHealthText()
    self:CreateEnergyText()
        
    local style = { }
    style.textColor = kAlienFontColor
    style.textureSet = "alien"
    style.displayTeamRes = false
    self.resourceDisplay = CreatePlayerResourceDisplay(self, kGUILayerPlayerHUDForeground3, self.resourceBackground, style)
    self.eventDisplay = CreateEventDisplay(self, kGUILayerPlayerHUDForeground1, self.resourceBackground, false)
    self.inventoryDisplay = CreateInventoryDisplay(self, kGUILayerPlayerHUDForeground3, self.resourceBackground)
    self.lastNotificationUpdate = 0
    //self.resourceDisplay.background:SetShader("shaders/GUISmokeHUD.surface_shader")
    //self.resourceDisplay.background:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
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
            self.upgrades[kAlienUpgradeChambers[i]][j]:SetAnchor(GUIItem.Right, GUIItem.Bottom)
            self.resourceBackground:AddChild(self.upgrades[kAlienUpgradeChambers[i]][j])
        end
    end
    
    self:Reset()
    
end

function GUIAlienHUD:SetIsVisible(isVisible)

    self.umbraText:SetIsVisible(isVisible)
    self.healthText:SetIsVisible(isVisible)
    self.armorText:SetIsVisible(isVisible)
    self.energyText:SetIsVisible(isVisible)
        
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
            local yPOS = -120
            for k = 1, i do
                yPOS = yPOS - kUpgradeYspacing
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

function GUIAlienHUD:CreateHealthText()

    self.healthText = GUIManager:CreateTextItem()
    self.healthText:SetFontName(kHealthFontName)
    self.healthText:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.healthText:SetTextAlignmentX(GUIItem.Align_Min)
    self.healthText:SetTextAlignmentY(GUIItem.Align_Center)
    self.healthText:SetPosition(Vector(10 , GUIScale(kHealthTextYOffset), 0))
    self.healthText:SetColor(Color(1, 1, 1, 1))
    self.healthText:SetText("HEALTH :")
    self.resourceBackground:AddChild(self.healthText)
    
    self.armorText = GUIManager:CreateTextItem()
    self.armorText:SetFontName(kArmorFontName)
    self.armorText:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.armorText:SetTextAlignmentX(GUIItem.Align_Min)
    self.armorText:SetTextAlignmentY(GUIItem.Align_Center)
    self.armorText:SetPosition(Vector(10 , GUIScale(kArmorTextYOffset), 0))
    self.armorText:SetColor(Color(1, 1, 1, 1))
    self.armorText:SetText("ARMOR :")
    self.resourceBackground:AddChild(self.armorText)

end

function GUIAlienHUD:CreateEnergyText()

    self.energyText = GUIManager:CreateTextItem()
    self.energyText:SetFontName(kHealthFontName)
    self.energyText:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.energyText:SetTextAlignmentX(GUIItem.Align_Min)
    self.energyText:SetTextAlignmentY(GUIItem.Align_Center)
    self.energyText:SetPosition(Vector(GUIScale(kEnergyTextXOffset) , GUIScale(kEnergyTextYOffset), 0))
    self.energyText:SetColor(Color(1, 1, 1, 1))
    self.energyText:SetText("ENERGY :")
    self.resourceBackground:AddChild(self.energyText)

end

function GUIAlienHUD:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
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
    
    self:UpdateHealthText(deltaTime)
    self:UpdateEnergyText(deltaTime)
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

function GUIAlienHUD:UpdateHealthText(deltaTime)

    // It's probably better to do a math.ceil for display health instead of floor, but NS1 did it this way
    // and I want to make sure the values are exactly the same to avoid confusion right now. When you are 
    // barely alive though, show 1 health.
    local health = PlayerUI_GetPlayerHealth()
    local displayHealth = math.floor(health)
    if health > 0 and displayHealth == 0 then
        displayHealth = 1
    end
    if (PlayerUI_GetPlayerHealth() / PlayerUI_GetPlayerMaxHealth()) < kLowHealth then
        self.healthText:SetColor(Color(1, 0, 0, 1))
    else
        self.healthText:SetColor(Color(1, 1, 1, 1))
    end
    self.healthText:SetText("HEALTH: " .. tostring(displayHealth))
    self.armorText:SetText("ARMOR: " .. tostring(math.floor(PlayerUI_GetPlayerArmor())))

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

function GUIAlienHUD:UpdateEnergyText(deltaTime)

    local player = Client.GetLocalPlayer()
    if player:isa("Embryo") or player:isa("Egg") then
        return
    end
    
    self.energyText:SetText("Energy: "   .. ToString(math.floor(PlayerUI_GetPlayerEnergy())))

    local activeHudSlot = 0
    
    local abilityData = PlayerUI_GetAbilityData()
    local secabilityData = PlayerUI_GetSecondaryAbilityData()
    local setColor = Color(1, 1, 1, 1)
    local currentIndex = 1
    local primpower = 0
    if table.count(abilityData) > 0 then
        local totalPower = abilityData[currentIndex]
        local minimumPower = abilityData[currentIndex + 1]
        if totalPower <= minimumPower then
            primpower = minimumPower
            setColor = kNotEnoughEnergyColor
        elseif table.count(secabilityData) > 0 then
            local totalPower = secabilityData[currentIndex]
            local minimumPower = secabilityData[currentIndex + 1]
            if totalPower <= minimumPower then
                setColor = Color(1, 0.5, 0.5, 1)
            end
        end
    end
    self.energyText:SetColor(setColor)
end

function GUIAlienHUD:OnResolutionChanged(oldX, oldY, newX, newY)

    self.scale = newY / kBaseScreenHeight
    self:Reset()
    
end

function GUIAlienHUD:OnAnimationCompleted(animatedItem, animationName, itemHandle)
    self.resourceDisplay:OnAnimationCompleted(animatedItem, animationName, itemHandle)
end