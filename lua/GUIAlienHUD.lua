
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
local kArmorFontName = "fonts/Stamp_large.fnt"
//local kArmorFontName = "fonts/Stamp_medium.fnt"
local kAbilityNumFontName = "fonts/Kartika_small.fnt"
local kHiveLocationFontName = "fonts/AgencyFB_tiny.fnt"

local kUmbraTextFontName = "fonts/Stamp_large.fnt"
local kUmbraTextYOffset = -52

local kUpgradeSize = Vector(80, 80, 0) * 0.8
local kUpgradeYspacing = 50
local kUpgradePos = Vector(kUpgradeSize.x - 120, -200, 0)

local kHiveStatusSize = Vector(80, 80, 0)
local kHiveStatusPos = Vector(kHiveStatusSize.x - 180, -80, 0)

local kMaxHives = 5
local kHiveStatusYspacing = 100

local kHiveHealthSize = Vector(10, 70, 0)
local kHiveHealthBarPos = Vector(-43, -63, 0)
local kHiveBuiltSize = Vector(10, 70, 0)
local kHiveBuiltBarPos = Vector(-85, -63, 0)
local kHiveTextPos = Vector(-115, 5, 0)

local kUpgradesTexture = "ui/alien_buildmenu.dds"
local kStatusTexture = "ui/alien_HUD_status.dds"

local kHealthTextPos = Vector(220, -70, 0)
local kArmorTextPos = Vector(220, -26, 0)
local kEnergyTextPos = Vector(-60, -31, 0)

local kArmorBarColor = kAlienFontColor
local kHealthBarColor = kAlienFontColor
local kEnergyBarColor = kAlienFontColor

local kArmorBarGlowCoords = { 0, 392, 30, 392 + 30 }
local kArmorBarGlowSize = Vector(8, 22, 0)
local kArmorBarGlowPos = Vector(-kArmorBarGlowSize.x, 0, 0)

local kArmorBarSize = Vector(200, 30, 0)
local kArmorBarPixelCoords = { 58, 352, 58 + 200, 352 + 30 }
local kArmorBarPos = Vector(10, -35, 0)

local kHealthBarSize = Vector(200, 40, 0)
local kHealthBarPixelCoords = { 58, 352, 58 + 200, 352 + 40 }
local kHealthBarPos = Vector(10, -80, 0)

local kEnergyBarSize = Vector(200, 30, 0)
local kEnergyBarPixelCoords = { 58, 352, 58 + 206, 352 + 30 }
local kEnergyBarPos = Vector(-270, -40, 0)

local kNotEnoughEnergyColor = Color(0.6, 0, 0, 1)
local kEnergizeColor = Color(.7, .7, .2, 1)

local kLowHiveHealth = 0.4
local kLowHealth = 0.4
local kNotificationUpdateIntervall = 0.2
local kHiveUpdateInterval = 1

local kAnimSpeedDown = 0.01
local kAnimSpeedUp = 0.01

local function GetTechIdForUpgrade(upg) 
    return LookupTechData(upg, kTechDataKeyStructure, kTechId.None)
end

function GUIAlienHUD:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.scale = Client.GetScreenHeight() / kBaseScreenHeight
    
    self.lastHealth = 0
    self.lastArmor = 0
    self.lastEnergy = 0
    
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
    self.lastHiveUpdate = 0
    //self.resourceDisplay.background:SetShader("shaders/GUISmokeHUD.surface_shader")
    //self.resourceDisplay.background:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
    self.resourceDisplay.background:SetFloatParameter("correctionX", 1)
    self.resourceDisplay.background:SetFloatParameter("correctionY", 0.3)
    
    self.upgrades = { }
    self.upgrades[kTechId.Crag] = { }
    self.upgrades[kTechId.Shift] = { }
    self.upgrades[kTechId.Shade] = { }
    self.upgrades[kTechId.Whip] = { }
    //self.upgrades[kTechId.Hive] = { }
    for i = 1, #kAlienUpgradeChambers do
        self.upgrades[kAlienUpgradeChambers[i]][0] = 0
        for j = 1, 3 do
            self.upgrades[kAlienUpgradeChambers[i]][j] = GetGUIManager():CreateGraphicItem()
            self.upgrades[kAlienUpgradeChambers[i]][j]:SetTexture(kUpgradesTexture)
            self.upgrades[kAlienUpgradeChambers[i]][j]:SetAnchor(GUIItem.Right, GUIItem.Bottom)
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
    
    self.healthText:SetUniformScale(self.scale)
    self.healthText:SetScale(GetScaledVector())
    self.healthText:SetPosition(kHealthTextPos)
    
    self.armorText:SetUniformScale(self.scale)
    self.armorText:SetScale(GetScaledVector() * 0.8)
    self.armorText:SetPosition(kArmorTextPos)

    self.energyText:SetUniformScale(self.scale)
    self.energyText:SetScale(GetScaledVector())
    self.energyText:SetPosition(kEnergyTextPos)
    
    self.armorBar:SetUniformScale(self.scale)
    self.armorBar:SetSize(kArmorBarSize)
    self.armorBar:SetPosition(kArmorBarPos)
    
    self.armorBarGlow:SetUniformScale(self.scale)
    self.armorBarGlow:FadeOut(1)
    self.armorBarGlow:SetSize(kArmorBarGlowSize) 
    self.armorBarGlow:SetPosition(Vector(-kArmorBarGlowSize.x / 2, 0, 0))
    
    self.healthBar:SetUniformScale(self.scale)
    self.healthBar:SetSize(kHealthBarSize)
    self.healthBar:SetPosition(kHealthBarPos)
    
    self.energyBar:SetUniformScale(self.scale)
    self.energyBar:SetSize(kEnergyBarSize)
    self.energyBar:SetPosition(kEnergyBarPos)

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
    
    self.healthText = self:CreateAnimatedTextItem()
    self.healthText:SetNumberTextAccuracy(1)
    self.healthText:SetFontName(kHealthFontName)
    self.healthText:SetTextAlignmentX(GUIItem.Align_Min)
    self.healthText:SetTextAlignmentY(GUIItem.Align_Center)
    self.healthText:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.healthText:SetColor(kHealthBarColor)
    self.resourceBackground:AddChild(self.healthText)

    self.healthBar = self:CreateAnimatedGraphicItem()
    self.healthBar:SetTexture(kStatusTexture)
    self.healthBar:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.healthBar:SetTexturePixelCoordinates(unpack(kHealthBarPixelCoords))
    self.healthBar:AddAsChildTo(self.resourceBackground)
        
    self.armorText = self:CreateAnimatedTextItem()
    self.armorText:SetNumberTextAccuracy(1)
    self.armorText:SetFontName(kArmorFontName)
    self.armorText:SetTextAlignmentX(GUIItem.Align_Min)
    self.armorText:SetTextAlignmentY(GUIItem.Align_Center)
    self.armorText:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.armorText:SetColor(kArmorBarColor)
    self.resourceBackground:AddChild(self.armorText)
    
    self.armorBar = self:CreateAnimatedGraphicItem()
    self.armorBar:SetTexture(kStatusTexture)
    self.armorBar:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.armorBar:SetTexturePixelCoordinates(unpack(kArmorBarPixelCoords))
    self.armorBar:AddAsChildTo(self.resourceBackground)
    
    self.armorBarGlow = self:CreateAnimatedGraphicItem()
    self.armorBarGlow:SetLayer(kGUILayerPlayerHUDForeground1 + 2)
    self.armorBarGlow:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.armorBarGlow:SetBlendTechnique(GUIItem.Add)
    self.armorBarGlow:SetIsVisible(true)
    self.armorBarGlow:SetStencilFunc(GUIItem.NotEqual)
    self.armorBar:AddChild(self.armorBarGlow)
    
end

function GUIAlienHUD:CreateEnergyText()

    self.energyText = self:CreateAnimatedTextItem()
    self.energyText:SetNumberTextAccuracy(1)
    self.energyText:SetFontName(kHealthFontName)
    self.energyText:SetTextAlignmentX(GUIItem.Align_Min)
    self.energyText:SetTextAlignmentY(GUIItem.Align_Center)
    self.energyText:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.energyText:SetColor(kEnergyBarColor)
    self.resourceBackground:AddChild(self.energyText)
        
    self.energyBar = self:CreateAnimatedGraphicItem()
    self.energyBar:SetTexture(kStatusTexture)
    self.energyBar:SetTexturePixelCoordinates(unpack(kEnergyBarPixelCoords))
    self.energyBar:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.energyBar:AddAsChildTo(self.resourceBackground)
    
    self.energyBarGlow = self:CreateAnimatedGraphicItem()
    self.energyBarGlow:SetLayer(kGUILayerPlayerHUDForeground1 + 2)
    self.energyBarGlow:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.energyBarGlow:SetBlendTechnique(GUIItem.Add)
    self.energyBarGlow:SetIsVisible(true)
    self.energyBarGlow:SetStencilFunc(GUIItem.NotEqual)
    self.energyBar:AddChild(self.energyBarGlow)

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
    self:UpdateHiveInformation(deltaTime)
    
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

local kLowHealthAnimRate = 0.3

local function LowHealthPulsate(script, item)

    item:SetColor(Color(0.7, 0, 0, 1), kLowHealthAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, 
        function (script, item)        
            item:SetColor(Color(1, 0, 0, 1), kLowHealthAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, LowHealthPulsate )        
        end )

end

local kLowEnergyAnimRate = 0.6

local function CriticalLowEnergyPulsate(script, item)

    item:SetColor(Color(0.7, 0, 0, 1), kLowEnergyAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, 
        function (script, item)        
            item:SetColor(Color(1, 0, 0, 1), kLowEnergyAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, CriticalLowEnergyPulsate )        
        end )

end

local function LowEnergyPulsate(script, item)

    item:SetColor(Color(0.7, 1, 0, 1), kLowEnergyAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, 
        function (script, item)        
            item:SetColor(kAlienFontColor, kLowEnergyAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, LowEnergyPulsate )        
        end )

end

function GUIAlienHUD:UpdateHealthText(deltaTime)

    // It's probably better to do a math.ceil for display health instead of floor, but NS1 did it this way
    // and I want to make sure the values are exactly the same to avoid confusion right now. When you are 
    // barely alive though, show 1 health.
    
    local health = PlayerUI_GetPlayerHealth()
    local armor = PlayerUI_GetPlayerArmor()
    local currentArmor = math.floor(armor)
    local currentHealth = math.floor(health)
    local maxHealth = PlayerUI_GetPlayerMaxHealth()
    local maxArmor = PlayerUI_GetPlayerMaxArmor()
    
    if currentHealth ~= self.lastHealth then
    
        local animSpeed = ConditionalValue(currentHealth < self.lastHealth, kAnimSpeedDown, kAnimSpeedUp)
        
	    local healthFraction = currentHealth / maxHealth
	    local healthBarSize = Vector(kHealthBarSize.x * healthFraction, kHealthBarSize.y, 0)
	    local pixelCoords = kHealthBarPixelCoords
	    pixelCoords[3] = kHealthBarSize.x * healthFraction + pixelCoords[1]
    
        if currentHealth < self.lastHealth then
            self.healthText:DestroyAnimation("ANIM_TEXT")
            self.healthText:SetText(tostring(math.ceil(currentHealth)))
            self.healthBar:DestroyAnimation("ANIM_HEALTH_SIZE")
            self.healthBar:SetSize(healthBarSize)
            self.healthBar:SetTexturePixelCoordinates(unpack(pixelCoords))
        else
            self.healthText:SetNumberText(tostring(math.ceil(currentHealth)), kAnimSpeedUp, "ANIM_TEXT")
            self.healthBar:SetSize(healthBarSize, animSpeed, "ANIM_HEALTH_SIZE")
            self.healthBar:SetTexturePixelCoordinates(pixelCoords[1], pixelCoords[2], pixelCoords[3], pixelCoords[4], animSpeed, "ANIM_HEALTH_TEXTURE")
        end
	    
	    self.lastHealth = currentHealth
	    
	    if healthFraction < kLowHealth  then
	    
	        if not self.lowHealthAnimPlaying then
                self.lowHealthAnimPlaying = true
                self.healthBar:SetColor(Color(1, 0, 0, 1), kLowHealthAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, LowHealthPulsate )
                self.healthText:SetColor(Color(1, 0, 0, 1), kLowHealthAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, LowHealthPulsate )
	        end
	        
	    else
	    
            self.lowHealthAnimPlaying = false
            self.healthBar:DestroyAnimation("ANIM_HEALTH_PULSATE")
            self.healthText:DestroyAnimation("ANIM_HEALTH_PULSATE")
            self.healthBar:SetColor(kHealthBarColor)
            self.healthText:SetColor(kHealthBarColor)
            
        end    
    
    end
    
    if currentArmor ~= self.lastArmor then
    
        local animSpeed = ConditionalValue(currentArmor < self.lastArmor, kAnimSpeedDown, kAnimSpeedUp)
        
        local armorFraction = currentArmor / maxArmor
        local armorBarSize = Vector(kArmorBarSize.x * armorFraction, kArmorBarSize.y, 0)
	    local pixelCoords = kArmorBarPixelCoords
	    pixelCoords[3] = kArmorBarSize.x * armorFraction + pixelCoords[1]
    
        if self.lastArmor > currentArmor then
        
            self.armorBar:SetSize( armorBarSize )
            self.armorText:SetText(tostring(math.ceil(currentArmor)))
            self.armorBar:SetTexturePixelCoordinates(unpack(pixelCoords))
        
            local particleSize = Vector(10, 14, 0)
            if armorFraction < (kLowHealth / 2) then
                self.armorBar:SetColor(Color(1, 0, 0, 1))
                self.armorText:SetColor(Color(1, 0, 0, 1))
            end

            for i = 1, 3 do
                
                local armorParticle = self:CreateAnimatedGraphicItem()
                armorParticle:SetUniformScale(self.scale)
                armorParticle:SetBlendTechnique(GUIItem.Add)
                armorParticle:SetSize(particleSize)
                armorParticle:AddAsChildTo(self.armorBar)
                armorParticle:SetAnchor(GUIItem.Right, GUIItem.Top)
                armorParticle:SetColor( Color(1,1,1,1) )
                
                local randomDirection = Vector(math.random(1, 60), math.random(30,80),0)
                
                armorParticle:SetColor( Color(kArmorBarColor.r, kArmorBarColor.g, kArmorBarColor.b, 0.0), 0.8)
                armorParticle:SetPosition(randomDirection, 1, nil, AnimateLinear, 
                    function(self,item)
                        item:Destroy()
                    end
                    )
            
            end
            
        else
        
            self.armorBar:DestroyAnimations()
            self.armorBar:SetSize( armorBarSize, animSpeed )
            if armorFraction > (kLowHealth / 2) then
                self.armorBar:SetColor(kArmorBarColor)
                self.armorText:SetColor(kArmorBarColor)
            end
            self.armorBar:SetTexturePixelCoordinates(pixelCoords[1], pixelCoords[2], pixelCoords[3], pixelCoords[4], animSpeed, "ANIM_ARMOR_TEXTURE")
            
            self.armorText:DestroyAnimations()
            self.armorText:SetNumberText(tostring(math.ceil(currentArmor)), animSpeed)
            
        end

        self.armorBarGlow:DestroyAnimations()
        self.armorBarGlow:SetColor(kArmorBarColor) 
        self.armorBarGlow:FadeOut(1, nil, AnimateLinear)
        
        self.lastArmor = currentArmor

    end

end

function GUIAlienHUD:UpdateEnergyText(deltaTime)

    local player = Client.GetLocalPlayer()
    if player:isa("Embryo") or player:isa("Egg") then
        return
    end
    
    local energy = PlayerUI_GetPlayerEnergy()
    local maxenergy = PlayerUI_GetPlayerMaxEnergy()
    local currentenergy = math.floor(energy)
    
    if currentenergy ~= self.lastEnergy then
    
	    local energyFraction = currentenergy / maxenergy
	    local energyBarSize = Vector(kEnergyBarSize.x * energyFraction, kEnergyBarSize.y, 0)
	    local pixelCoords = kEnergyBarPixelCoords
	    pixelCoords[3] = kEnergyBarSize.x * energyFraction + pixelCoords[1]
	    local energizeLevel = PlayerUI_GetEnergizeLevel()
        if energizeLevel > 0 then
            self.energyText:SetColor(Color(1, energyFraction, 1, 1))
        else
            self.energyText:SetColor(Color(1, energyFraction, 0, 1))
        end
        self.energyBar:SetColor(Color(1, energyFraction, 0, 1))
        
        if currentenergy < self.lastEnergy then
            self.energyText:DestroyAnimation("ANIM_TEXT")
            self.energyText:SetText(tostring(math.ceil(currentenergy)))
            self.energyBar:DestroyAnimation("ANIM_HEALTH_SIZE")
            self.energyBar:SetSize(energyBarSize)
            self.energyBar:SetTexturePixelCoordinates(unpack(pixelCoords))
        else
            self.energyText:SetNumberText(tostring(math.ceil(currentenergy)), kAnimSpeedUp, "ANIM_TEXT")
            self.energyBar:SetSize(energyBarSize, animSpeed, "ANIM_HEALTH_SIZE")
            self.energyBar:SetTexturePixelCoordinates(pixelCoords[1], pixelCoords[2], pixelCoords[3], pixelCoords[4], animSpeed, "ANIM_HEALTH_TEXTURE")
        end

        //local abilityData = PlayerUI_GetAbilityData()
        //local secabilityData = PlayerUI_GetSecondaryAbilityData()
        
        //local currentIndex = 1
        
        /*
        if table.count(abilityData) > 0 then
            local totalPower = abilityData[currentIndex]
            local minimumPower = abilityData[currentIndex + 1]
            local minimumSecPower = secabilityData[currentIndex + 1]
            if minimumPower == nil then minimumPower = 0 end
            if minimumSecPower == nil then minimumSecPower = 0 end
            if minimumPower <= minimumSecPower or minimumSecPower == 0 then
                if totalPower <= minimumPower then
                    if not self.CriticallowEnergyAnimPlaying then
                        if self.lowEnergyAnimPlaying then
                            self.lowEnergyAnimPlaying = false
                            self.energyBar:DestroyAnimation("ANIM_HEALTH_PULSATE")
                            self.energyText:DestroyAnimation("ANIM_HEALTH_PULSATE")
                        end
                        self.CriticallowEnergyAnimPlaying = true
                        self.energyBar:SetColor(kNotEnoughEnergyColor, kLowEnergyAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, CriticalLowEnergyPulsate )
                        self.energyText:SetColor(kNotEnoughEnergyColor, kLowEnergyAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, CriticalLowEnergyPulsate )
                    end
                elseif totalPower <= minimumSecPower then
                    if not self.lowEnergyAnimPlaying then
                        if self.CriticallowEnergyAnimPlaying then
                            self.CriticallowEnergyAnimPlaying = false
                            self.energyBar:DestroyAnimation("ANIM_HEALTH_PULSATE")
                            self.energyText:DestroyAnimation("ANIM_HEALTH_PULSATE")
                        end
                        self.lowEnergyAnimPlaying = true
                        self.energyBar:SetColor(Color(1, 1, 0, 1), kLowEnergyAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, LowEnergyPulsate )
                        self.energyText:SetColor(Color(1, 1, 0, 1), kLowEnergyAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, LowEnergyPulsate )
	                end
                else
                    self.lowEnergyAnimPlaying = false
                    self.CriticallowEnergyAnimPlaying = false
                    self.energyBar:DestroyAnimation("ANIM_HEALTH_PULSATE")
                    self.energyText:DestroyAnimation("ANIM_HEALTH_PULSATE")
                    self.energyBar:SetColor(kEnergyBarColor)
                    self.energyText:SetColor(kEnergyBarColor)
                end
            else
                if totalPower <= minimumSecPower then
                    if not self.lowEnergyAnimPlaying then
                        if self.lowEnergyAnimPlaying then
                            self.lowEnergyAnimPlaying = false
                            self.energyBar:DestroyAnimation("ANIM_HEALTH_PULSATE")
                            self.energyText:DestroyAnimation("ANIM_HEALTH_PULSATE")
                        end
                        self.CriticallowEnergyAnimPlaying = true
                        self.energyBar:SetColor(Color(1, 1, 0, 1), kLowEnergyAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, LowEnergyPulsate )
                        self.energyText:SetColor(Color(1, 1, 0, 1), kLowEnergyAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, LowEnergyPulsate )
                    end
                elseif totalPower <= minimumPower then
                    if not self.lowEnergyAnimPlaying then
                        if self.CriticallowEnergyAnimPlaying then
                            self.CriticallowEnergyAnimPlaying = false
                            self.energyBar:DestroyAnimation("ANIM_HEALTH_PULSATE")
                            self.energyText:DestroyAnimation("ANIM_HEALTH_PULSATE")
                        end
                        self.lowEnergyAnimPlaying = true
                        self.energyBar:SetColor(kNotEnoughEnergyColor, kLowEnergyAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, CriticalLowEnergyPulsate )
                        self.energyText:SetColor(kNotEnoughEnergyColor, kLowEnergyAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, CriticalLowEnergyPulsate )
	                end
                else
                    self.lowEnergyAnimPlaying = false
                    self.CriticallowEnergyAnimPlaying = false
                    self.energyBar:DestroyAnimation("ANIM_HEALTH_PULSATE")
                    self.energyText:DestroyAnimation("ANIM_HEALTH_PULSATE")
                    self.energyBar:SetColor(kEnergyBarColor)
                    self.energyText:SetColor(kEnergyBarColor)
                end
            end
        end
        */
        
        self.lastEnergy = currentenergy
        
    end
end

local kHiveDamageAnimRate = 0.2

local function HiveDamagePulsate(script, item)

    item:SetColor(Color(0.7, 0, 0, 1), kHiveDamageAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, 
        function (script, item)        
            item:SetColor(Color(1, 0, 0, 1), kHiveDamageAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, HiveDamagePulsate )        
        end )

end

function GUIAlienHUD:UpdateHiveInformation(deltaTime)
    local hivesinfo = PlayerUI_GetHiveInformation()
    local hivenum = 1
    if hivesinfo ~= nil then
        for i = 1, #hivesinfo do
            if i < kMaxHives then
                local hiveinfo = hivesinfo[i]
                if self.hives[i].lasthealth ~= hiveinfo.healthpercent or self.hives[i].techId ~= hiveinfo.techId or self.hives[i].lastbuilt ~= hiveinfo.buildprogress or self.hives[i].lasttime ~= hiveinfo.time then
                
                    local textureCoords = GetTextureCoordinatesForIcon(hiveinfo.techId, false)
                    self.hives[i].locationtext:SetText(hiveinfo.location)
                    self.hives[i].locationtext:SetIsVisible(true)
                    self.hives[i].locationtext:SetColor(kHealthBarColor)
                    self.hives[i].icon:SetTexturePixelCoordinates(unpack(textureCoords))
                    self.hives[i].icon:SetIsVisible(true)
                    self.hives[i].healthBar:SetSize(Vector(kHiveHealthSize.x, kHiveHealthSize.y * hiveinfo.healthpercent, 0))
                    self.hives[i].healthBar:SetIsVisible(true)
                    self.hives[i].builtBar:SetSize(Vector(kHiveBuiltSize.x, kHiveBuiltSize.y * hiveinfo.buildprogress, 0))
                    
                    local animSpeed = ConditionalValue(hiveinfo.healthpercent < self.hives[i].lasthealth, kAnimSpeedDown, kAnimSpeedUp)
                    local pixelCoords = kHealthBarPixelCoords
                    pixelCoords[3] = kHealthBarSize.x * hiveinfo.healthpercent + pixelCoords[1]

                    if hiveinfo.healthpercent < kLowHiveHealth then
                        self.hives[i].icon:SetColor(Color(1, 0, 0, 1))
                        self.hives[i].locationtext:SetColor(Color(1, 0, 0, 1))
                    end
                    if self.hives[i].lasthealth > hiveinfo.healthpercent then
                        self.hives[i].hivedamageAnimPlaying = Client.GetTime() + 5
                        self.hives[i].healthBar:SetColor(Color(1, 0, 0, 1), kHiveDamageAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, HiveDamagePulsate )
                    else
                        self.hives[i].healthBar:SetColor(kHealthBarColor)
                        self.hives[i].icon:SetColor(kHealthBarColor)
                        self.hives[i].locationtext:SetColor(kHealthBarColor)
                    end

                    if hiveinfo.buildprogress == 1 then
                        self.hives[i].builtBar:SetIsVisible(false)
                    else
                        self.hives[i].builtBar:SetIsVisible(true) 
                    end
                    self.hives[i].lasthealth = hiveinfo.healthpercent
                    self.hives[i].techId = hiveinfo.techId
                    self.hives[i].lastbuilt = hiveinfo.buildprogress
                    self.hives[i].lasttime = hiveinfo.time
                elseif hiveinfo.time - Client.GetTime() < 5 then
                    if self.hives[i].hivedamageAnimPlaying ~= nil and self.hives[i].hivedamageAnimPlaying < Client.GetTime() then
                        self.hives[i].hivedamageAnimPlaying = nil
                        self.hives[i].healthBar:DestroyAnimation("ANIM_HEALTH_PULSATE")
                        self.hives[i].healthBar:SetColor(kHealthBarColor)
                        self.hives[i].icon:SetColor(kHealthBarColor)
                        self.hives[i].locationtext:SetColor(kHealthBarColor)
                    end
                end
            
                hivenum = i + 1
            end
        end
            
        if self.lastHiveUpdate + kHiveUpdateInterval < Client.GetTime() then
            for i = hivenum, kMaxHives do
                self.hives[i].icon:SetIsVisible(false)
                self.hives[i].healthBar:SetIsVisible(false)
                self.hives[i].builtBar:SetIsVisible(false)
                self.hives[i].locationtext:SetIsVisible(false)
            end
        end
    end
end

function GUIAlienHUD:OnResolutionChanged(oldX, oldY, newX, newY)

    self.scale = newY / kBaseScreenHeight
    self:Reset()
    
end

function GUIAlienHUD:OnAnimationCompleted(animatedItem, animationName, itemHandle)
    self.resourceDisplay:OnAnimationCompleted(animatedItem, animationName, itemHandle)
end