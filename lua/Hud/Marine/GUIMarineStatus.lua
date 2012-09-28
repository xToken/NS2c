// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMarineStatus.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Manages the health and armor display for the marine hud.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Hud/Marine/GUIMarineHUDElement.lua")
Script.Load("lua/Hud/Marine/GUIMarineHUDStyle.lua")

class 'GUIMarineStatus' (GUIMarineHUDElement)

function CreateStatusDisplay(scriptHandle, hudLayer, frame)

    local marineStatus = GUIMarineStatus()
    marineStatus.script = scriptHandle
    marineStatus.hudLayer = hudLayer
    marineStatus.frame = frame
    marineStatus:Initialize()
    
    return marineStatus
    
end

GUIMarineStatus.kParasiteColor = Color(0xFF / 0xFF, 0xFF / 0xFF, 0xFF / 0xFF, 0.8)

GUIMarineStatus.kStatusTexture = "ui/marine_HUD_status.dds"

GUIMarineStatus.kTextXOffset = 95

GUIMarineStatus.kBackgroundCoords = { 0, 0, 300, 121 }
GUIMarineStatus.kBackgroundPos = Vector(10, -145, 0)
GUIMarineStatus.kBackgroundSize = Vector(GUIMarineStatus.kBackgroundCoords[3], GUIMarineStatus.kBackgroundCoords[4], 0)
GUIMarineStatus.kStencilCoords = { 0, 140, 300, 140 + 121 }

GUIMarineStatus.kArmorBarGlowCoords = { 0, 392, 30, 392 + 30 }
GUIMarineStatus.kArmorBarGlowSize = Vector(8, 22, 0)
GUIMarineStatus.kArmorBarGlowPos = Vector(-GUIMarineStatus.kArmorBarGlowSize.x, 0, 0)

GUIMarineStatus.kScanLinesForeGroundSize = Vector( 200 , kScanLinesBigHeight * 1, 0 )
GUIMarineStatus.kScanLinesForeGroundPos = Vector(-80, -30, 0)

GUIMarineStatus.kHealthTextPos = Vector(-20, 36, 0)
GUIMarineStatus.kArmorTextPos = Vector(-20, 96, 0)
GUIMarineStatus.kAmmoTextPos = Vector(-140, -45, 0)

GUIMarineStatus.kFontName = "fonts/AgencyFB_large_bold.fnt"

GUIMarineStatus.kArmorBarColor = Color(32/255, 222/255, 253/255, 0.8)
GUIMarineStatus.kHealthBarColor = Color(163/255, 210/255, 220/255, 0.8)

GUIMarineStatus.kArmorBarSize = Vector(206, 20, 0)
GUIMarineStatus.kArmorBarPixelCoords = { 58, 352, 58 + 206, 352 + 20 }
GUIMarineStatus.kArmorBarPos = Vector(58, 88, 0)

GUIMarineStatus.kHealthBarSize = Vector(206, 28, 0)
GUIMarineStatus.kHealthBarPixelCoords = { 58, 288, 58 + 206, 288 + 28 }
GUIMarineStatus.kHealthBarPos = Vector(58, 24, 0)

GUIMarineStatus.kAnimSpeedDown = 0.01
GUIMarineStatus.kAnimSpeedUp = 0.01
GUIMarineStatus.kLowAmmoWarning = 0.2

local kBorderTexture = "ui/unitstatus_marine.dds"
local kBorderCoords = { 256, 256, 256 + 512, 256 + 128 }
local kBorderMaskPixelCoords = { 256, 384, 256 + 512, 384 + 512 }
local kBorderMaskCircleRadius = 240
local kHealthBorderPos = Vector(-150, -60, 0)
local kHealthBorderSize = Vector(350, 65, 0)
local kArmorBorderPos = Vector(-150, 10, 0)
local kArmorBorderSize = Vector(350, 50, 0)
local kRotationDuration = 8

function GUIMarineStatus:Initialize()

    self.scale = 1

    self.lastHealth = 0
    self.lastArmor = 0
    self.spawnArmorParticles = false

    self.statusbackground = self.script:CreateAnimatedGraphicItem()
    self.statusbackground:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.statusbackground:SetTexture(GUIMarineStatus.kStatusTexture)
    self.statusbackground:SetTexturePixelCoordinates(unpack(GUIMarineStatus.kBackgroundCoords))
    self.statusbackground:AddAsChildTo(self.frame)
    
    self.statusStencil = GetGUIManager():CreateGraphicItem()
    self.statusStencil:SetTexture(GUIMarineStatus.kStatusTexture)
    self.statusStencil:SetTexturePixelCoordinates(unpack(GUIMarineStatus.kStencilCoords))
    self.statusStencil:SetIsStencil(true)
    self.statusStencil:SetClearsStencilBuffer(false)
    self.statusbackground:AddChild(self.statusStencil)
    
    self.healthText = self.script:CreateAnimatedTextItem()
    self.healthText:SetNumberTextAccuracy(1)
    self.healthText:SetFontName(GUIMarineStatus.kFontName)
    self.healthText:SetTextAlignmentX(GUIItem.Align_Min)
    self.healthText:SetTextAlignmentY(GUIItem.Align_Center)
    self.healthText:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.healthText:SetLayer(self.hudLayer + 1)
    self.healthText:SetColor(GUIMarineStatus.kHealthBarColor)
    self.statusbackground:AddChild(self.healthText)
    
    self.armorText = self.script:CreateAnimatedTextItem()
    self.armorText:SetNumberTextAccuracy(1)
    self.armorText:SetText(tostring(self.lastHealth))
    self.armorText:SetFontName(GUIMarineStatus.kFontName)
    self.armorText:SetTextAlignmentX(GUIItem.Align_Min)
    self.armorText:SetTextAlignmentY(GUIItem.Align_Center)
    self.armorText:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.armorText:SetLayer(self.hudLayer + 1)
    self.armorText:SetColor(GUIMarineStatus.kArmorBarColor)
    self.statusbackground:AddChild(self.armorText)

    self.armorBar = self.script:CreateAnimatedGraphicItem()
    self.armorBar:SetTexture(GUIMarineStatus.kStatusTexture)
    self.armorBar:SetTexturePixelCoordinates(unpack(GUIMarineStatus.kArmorBarPixelCoords))
    self.armorBar:AddAsChildTo(self.statusbackground)
    
    self.armorBarGlow = self.script:CreateAnimatedGraphicItem()
    self.armorBarGlow:SetLayer(self.hudLayer + 2)
    self.armorBarGlow:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.armorBarGlow:SetBlendTechnique(GUIItem.Add)
    self.armorBarGlow:SetIsVisible(true)
    self.armorBarGlow:SetStencilFunc(GUIItem.NotEqual)
    self.armorBar:AddChild(self.armorBarGlow)
    
    self.healthBar = self.script:CreateAnimatedGraphicItem()
    self.healthBar:SetTexture(GUIMarineStatus.kStatusTexture)
    self.healthBar:SetTexturePixelCoordinates(unpack(GUIMarineStatus.kHealthBarPixelCoords))
    self.healthBar:AddAsChildTo(self.statusbackground)

    self.healthBorder = GetGUIManager():CreateGraphicItem()
    self.healthBorder:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.healthBorder:SetTexture(kBorderTexture)
    self.healthBorder:SetTexturePixelCoordinates(unpack(kBorderCoords))
    self.healthBorder:SetIsStencil(true)
    
    self.healthBorderMask = GetGUIManager():CreateGraphicItem()
    self.healthBorderMask:SetTexture(kBorderTexture)
    self.healthBorderMask:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.healthBorderMask:SetBlendTechnique(GUIItem.Add)
    self.healthBorderMask:SetTexturePixelCoordinates(unpack(kBorderMaskPixelCoords))
    self.healthBorderMask:SetStencilFunc(GUIItem.NotEqual)
    
    self.healthBorder:AddChild(self.healthBorderMask)
    self.statusbackground:AddChild(self.healthBorder)
    
    self.armorBorder = GetGUIManager():CreateGraphicItem()
    self.armorBorder:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.armorBorder:SetTexture(kBorderTexture)
    self.armorBorder:SetTexturePixelCoordinates(unpack(kBorderCoords))
    self.armorBorder:SetIsStencil(true)
    
    self.armorBorderMask = GetGUIManager():CreateGraphicItem()
    self.armorBorderMask:SetTexture(kBorderTexture)
    self.armorBorderMask:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.armorBorderMask:SetBlendTechnique(GUIItem.Add)
    self.armorBorderMask:SetTexturePixelCoordinates(unpack(kBorderMaskPixelCoords))
    self.armorBorderMask:SetStencilFunc(GUIItem.NotEqual)
    
    self.armorBorder:AddChild(self.armorBorderMask)
    self.statusbackground:AddChild(self.armorBorder)

    self.ammoText = self.script:CreateAnimatedTextItem()
    self.ammoText:SetFontName(GUIMarineStatus.kFontName)
    self.ammoText:SetAnchor(GUIItem.Right, GUIItem.Bottom)    
    self.ammoText:SetTextAlignmentX(GUIItem.Align_Min)    
    self.ammoText:SetTextAlignmentY(GUIItem.Align_Center)    
    self.ammoText:SetPosition(GUIMarineStatus.kAmmoTextPos)
    self.ammoText:SetColor(GUIMarineStatus.kHealthBarColor) 
    self.ammoText:SetText("--/--")
    //self.statusbackground:AddChild(self.ammoText)
end

function GUIMarineStatus:Reset(scale)

    self.scale = scale

    self.statusbackground:SetUniformScale(scale)
    self.statusbackground:SetPosition(GUIMarineStatus.kBackgroundPos)
    self.statusbackground:SetSize(GUIMarineStatus.kBackgroundSize)
    
    self.statusStencil:SetSize(GUIMarineStatus.kBackgroundSize * self.scale)

    self.healthText:SetUniformScale(self.scale)
    self.healthText:SetScale(GetScaledVector())
    self.healthText:SetPosition(GUIMarineStatus.kHealthTextPos)
    
    self.armorText:SetUniformScale(self.scale)
    self.armorText:SetScale(GetScaledVector() * 0.8)
    self.armorText:SetPosition(GUIMarineStatus.kArmorTextPos)

    self.ammoText:SetUniformScale(self.scale)
    self.ammoText:SetScale(GetScaledVector())
    self.ammoText:SetPosition(GUIMarineStatus.kAmmoTextPos)

    //self.scanLinesForeground:SetUniformScale(self.scale)
    //self.scanLinesForeground:SetPosition(GUIMarineStatus.kScanLinesForeGroundPos)
    //self.scanLinesForeground:SetSize(GUIMarineStatus.kScanLinesForeGroundSize)

    self.armorBar:SetUniformScale(self.scale)
    self.armorBar:SetPosition(GUIMarineStatus.kArmorBarPos)
    
    self.armorBarGlow:SetUniformScale(self.scale)
    self.armorBarGlow:FadeOut(1)
    self.armorBarGlow:SetSize(GUIMarineStatus.kArmorBarGlowSize) 
    self.armorBarGlow:SetPosition(Vector(-GUIMarineStatus.kArmorBarGlowSize.x / 2, 0, 0))
    
    self.healthBar:SetUniformScale(self.scale)
    self.healthBar:SetSize(GUIMarineStatus.kHealthBarSize)
    self.healthBar:SetPosition(GUIMarineStatus.kHealthBarPos)

    self.healthBorder:SetSize(kHealthBorderSize * self.scale)
    self.healthBorder:SetPosition(kHealthBorderPos * self.scale)
    self.healthBorderMask:SetSize(Vector(kBorderMaskCircleRadius * 2, kBorderMaskCircleRadius * 2, 0) * self.scale)
    self.healthBorderMask:SetPosition(Vector(-kBorderMaskCircleRadius, -kBorderMaskCircleRadius, 0) * self.scale)
    
    self.armorBorder:SetSize(kArmorBorderSize * self.scale)
    self.armorBorder:SetPosition(kArmorBorderPos * self.scale)
    self.armorBorderMask:SetSize(Vector(kBorderMaskCircleRadius * 2, kBorderMaskCircleRadius * 2, 0) * self.scale)
    self.armorBorderMask:SetPosition(Vector(-kBorderMaskCircleRadius, -kBorderMaskCircleRadius, 0) * self.scale)

end

function GUIMarineStatus:Destroy()

    if self.statusbackground then
        self.statusbackground:Destroy()
    end

    if self.healthText then
        self.healthText:Destroy()
    end   
    
    if self.armorText then
        self.armorText:Destroy()
    end

    if self.ammoText then
        self.ammoText:Destroy()
    end

end

function GUIMarineStatus:SetIsVisible(visible)
    self.statusbackground:SetIsVisible(visible)
end

local kLowHealth = 40
local kLowHealthAnimRate = 0.3

local function LowHealthPulsate(script, item)

    item:SetColor(Color(0.7, 0, 0, 1), kLowHealthAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, 
        function (script, item)        
            item:SetColor(Color(1, 0, 0,1), kLowHealthAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, LowHealthPulsate )        
        end )

end

// set armor/health and trigger effects accordingly (armor bar particles)
function GUIMarineStatus:Update(deltaTime, parameters)

    if table.count(parameters) < 4 then
        Print("WARNING: GUIMarineStatus:Update received an incomplete parameter table.")
    end
    
    //Update AmmoCounter
    local clipammo = ToString(PlayerUI_GetWeaponClip())
    local ammo = ToString(PlayerUI_GetWeaponAmmo())
    if clipammo == nil then clipammo = "--" end
    if ammo == "0" then ammo = "--" end
    self.ammoText:SetText(clipammo .. " / " .. ammo)
    self.ammoText:SetIsVisible(true)
    if PlayerUI_GetWeaponClip() < PlayerUI_GetWeaponClipSize() * GUIMarineStatus.kLowAmmoWarning then
        self.ammoText:SetColor(Color(1, 0, 0, 1)) 
    else
        self.ammoText:SetColor(GUIMarineStatus.kArmorBarColor) 
    end
    
    local currentHealth, maxHealth, currentArmor, maxArmor, parasiteState = unpack(parameters)
    
    if currentHealth ~= self.lastHealth then
    
	    local healthFraction = currentHealth / maxHealth
	    local healthBarSize = Vector(GUIMarineStatus.kHealthBarSize.x * healthFraction, GUIMarineStatus.kHealthBarSize.y, 0)
	    local pixelCoords = GUIMarineStatus.kHealthBarPixelCoords
	    pixelCoords[3] = GUIMarineStatus.kHealthBarSize.x * healthFraction + pixelCoords[1]
    
        if currentHealth < self.lastHealth then
            self.healthText:DestroyAnimation("ANIM_TEXT")
            self.healthText:SetText(tostring(math.ceil(currentHealth)))
            self.healthBar:DestroyAnimation("ANIM_HEALTH_SIZE")
            self.healthBar:SetSize(healthBarSize)
            self.healthBar:SetTexturePixelCoordinates(unpack(pixelCoords))
        else
            self.healthText:SetNumberText(tostring(math.ceil(currentHealth)), GUIMarineStatus.kAnimSpeedUp, "ANIM_TEXT")
            self.healthBar:SetSize(healthBarSize, animSpeed, "ANIM_HEALTH_SIZE")
            self.healthBar:SetTexturePixelCoordinates(pixelCoords[1], pixelCoords[2], pixelCoords[3], pixelCoords[4], animSpeed, "ANIM_HEALTH_TEXTURE")
        end
	    
	    self.lastHealth = currentHealth
	    
	    if self.lastHealth < kLowHealth  then
	    
	        if not self.lowHealthAnimPlaying then
                self.lowHealthAnimPlaying = true
                self.healthBar:SetColor(Color(1, 0, 0, 1), kLowHealthAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, LowHealthPulsate )
                self.healthText:SetColor(Color(1, 0, 0, 1), kLowHealthAnimRate, "ANIM_HEALTH_PULSATE", AnimateQuadratic, LowHealthPulsate )
	        end
	        
	    else
	    
            self.lowHealthAnimPlaying = false
            self.healthBar:DestroyAnimation("ANIM_HEALTH_PULSATE")
            self.healthText:DestroyAnimation("ANIM_HEALTH_PULSATE")
            self.healthBar:SetColor(GUIMarineStatus.kHealthBarColor)
            self.healthText:SetColor(GUIMarineStatus.kHealthBarColor)
            
        end    
    
    end
    
    if currentArmor ~= self.lastArmor then
    
        local animSpeed = ConditionalValue(currentArmor < self.lastArmor, GUIMarineStatus.kAnimSpeedDown, GUIMarineStatus.kAnimSpeedUp)
        
        local armorFraction = currentArmor / maxArmor
        local armorBarSize = Vector(GUIMarineStatus.kArmorBarSize.x * armorFraction, GUIMarineStatus.kArmorBarSize.y, 0)
	    local pixelCoords = GUIMarineStatus.kArmorBarPixelCoords
	    pixelCoords[3] = GUIMarineStatus.kArmorBarSize.x * armorFraction + pixelCoords[1]
    
        if self.lastArmor > currentArmor then
        
            self.armorBar:SetSize( armorBarSize )
            self.armorText:SetText(tostring(math.ceil(currentArmor)))
            self.armorBar:SetTexturePixelCoordinates(unpack(pixelCoords))
        
            local particleSize = Vector(10, 14, 0)

            for i = 1, 3 do
                
                local armorParticle = self.script:CreateAnimatedGraphicItem()
                armorParticle:SetUniformScale(self.scale)
                armorParticle:SetBlendTechnique(GUIItem.Add)
                armorParticle:SetSize(particleSize)
                armorParticle:AddAsChildTo(self.armorBar)
                armorParticle:SetAnchor(GUIItem.Right, GUIItem.Top)
                armorParticle:SetColor( Color(1,1,1,1) )
                
                local randomDirection = Vector(math.random(1, 60), math.random(30,80),0)
                
                armorParticle:SetColor( Color(GUIMarineStatus.kArmorBarColor.r, GUIMarineStatus.kArmorBarColor.g, GUIMarineStatus.kArmorBarColor.b, 0.0), 0.8)
                armorParticle:SetPosition(randomDirection, 1, nil, AnimateLinear, 
                    function(self,item)
                        item:Destroy()
                    end
                    )
            
            end
            
        else
        
            self.armorBar:DestroyAnimations()
            self.armorBar:SetSize( armorBarSize, animSpeed )
            self.armorBar:SetTexturePixelCoordinates(pixelCoords[1], pixelCoords[2], pixelCoords[3], pixelCoords[4], animSpeed, "ANIM_ARMOR_TEXTURE")
            
            self.armorText:DestroyAnimations()
            self.armorText:SetNumberText(tostring(math.ceil(currentArmor)), animSpeed)
            
        end

        self.armorBarGlow:DestroyAnimations()
        self.armorBarGlow:SetColor( Color(1,1,1,1) ) 
        self.armorBarGlow:FadeOut(1, nil, AnimateLinear)
        
        self.lastArmor = currentArmor

    end

    // update border animation
    local baseRotationPercentage = (Shared.GetTime() % kRotationDuration) / kRotationDuration
    local color = Color(1, 1, 1,  math.sin(Shared.GetTime() * 0.5 ) * 0.5)
    self.healthBorderMask:SetRotation(Vector(0, 0, -2 * math.pi * baseRotationPercentage))   
    self.healthBorderMask:SetColor(color)
    self.armorBorderMask:SetRotation(Vector(0, 0, -2 * math.pi * (baseRotationPercentage + math.pi)))
    self.armorBorderMask:SetColor(color)
    
end
