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

GUIMarineStatus.kFontName = "fonts/AgencyFB_large_bold.fnt"

GUIMarineStatus.kArmorBarColor = Color(32/255, 222/255, 253/255, 0.8)
GUIMarineStatus.kHealthBarColor = Color(32/255, 222/255, 253/255, 0.8)
GUIMarineStatus.kLowAmmoWarning = .3
GUIMarineStatus.kAnimSpeedDown = 0.2
GUIMarineStatus.kAnimSpeedUp = 0.5

local kBorderTexture = "ui/unitstatus_marine.dds"
local kBorderCoords = { 256, 256, 256 + 512, 256 + 128 }
local kBorderMaskPixelCoords = { 256, 384, 256 + 512, 384 + 512 }
local kBorderMaskCircleRadius = 240
local kHealthBorderPos = Vector(-150, -60, 0)
local kHealthBorderSize = Vector(350, 65, 0)
local kArmorBorderPos = Vector(-150, 10, 0)
local kArmorBorderSize = Vector(350, 50, 0)
local kRotationDuration = 8
local kHealthTextYOffset = -70
local kArmorTextYOffset = -25

function GUIMarineStatus:Initialize()

    self.scale = 1

    self.lastHealth = 0
    self.lastArmor = 0
    self.spawnArmorParticles = false
    self.lastParasiteState = 1
    
    self.healthText = self.script:CreateAnimatedTextItem()
    self.healthText:SetFontName(GUIMarineStatus.kFontName)
    self.healthText:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.healthText:SetTextAlignmentX(GUIItem.Align_Min)
    self.healthText:SetTextAlignmentY(GUIItem.Align_Center)
    self.healthText:SetPosition(Vector(10 , GUIScale(kHealthTextYOffset), 0))
    self.healthText:SetColor(GUIMarineStatus.kHealthBarColor)
    self.healthText:SetText("HEALTH :")
    
    self.armorText = self.script:CreateAnimatedTextItem()
    self.armorText:SetFontName(GUIMarineStatus.kFontName)
    self.armorText:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.armorText:SetTextAlignmentX(GUIItem.Align_Min)
    self.armorText:SetTextAlignmentY(GUIItem.Align_Center)
    self.armorText:SetPosition(Vector(10 , GUIScale(kArmorTextYOffset), 0))
    self.armorText:SetColor(GUIMarineStatus.kArmorBarColor)
    self.armorText:SetText("ARMOR :")

    self.ammoText = self.script:CreateAnimatedTextItem()
    self.ammoText:SetFontName(GUIMarineStatus.kFontName)
    self.ammoText:SetAnchor(GUIItem.Right, GUIItem.Bottom)    
    self.ammoText:SetTextAlignmentX(GUIItem.Align_Min)    
    self.ammoText:SetTextAlignmentY(GUIItem.Align_Center)    
    self.ammoText:SetPosition(Vector(-170, -25, 0))
    self.ammoText:SetColor(Color(1, 1, 1, 1)) 
    self.ammoText:SetText("--/--")
    
end

function GUIMarineStatus:Reset(scale)

end

function GUIMarineStatus:Destroy()

    if self.armorText then
        self.armorText:Destroy()
    end
    
    if self.healthText then
        self.healthText:Destroy()
    end
    
    if self.ammoText then
        self.ammoText:Destroy()
    end

end

function GUIMarineStatus:SetIsVisible(visible)
    self.statusbackground:SetIsVisible(visible)
end

local kLowHealth = 40

// set armor/health and trigger effects accordingly (armor bar particles)
function GUIMarineStatus:Update(deltaTime, parameters)

    if table.count(parameters) < 4 then
        Print("WARNING: GUIMarineStatus:Update received an incomplete parameter table.")
    end
    
    //Update AmmoCounter
    local activeWeapon = PlayerUI_GetWeapon()
    if activeWeapon then
        self.ammoText:SetText(ToString(activeWeapon.clip or "--") .. " / " .. ToString(activeWeapon.ammo or "--"))
        self.ammoText:SetIsVisible(true)
        if activeWeapon.clip and activeWeapon.GetClipSize and activeWeapon.clip < activeWeapon:GetClipSize() * GUIMarineStatus.kLowAmmoWarning then
            self.ammoText:SetColor(Color(1, 0, 0, 1)) 
        else
            self.ammoText:SetColor(Color(1, 1, 1, 1)) 
        end
    else
        self.ammoText:SetText("--/--")    
        self.ammoText:SetIsVisible(true)
    end
    
    local currentHealth, maxHealth, currentArmor, maxArmor, parasiteState = unpack(parameters)
    
    if currentHealth ~= self.lastHealth then
        self.healthText:SetText("HEALTH: " .. tostring(math.ceil(currentHealth)))  
	    self.lastHealth = currentHealth
	    
	    if self.lastHealth < kLowHealth  then
            self.healthText:SetColor(Color(1, 0, 0, 1))	        
	    else
	    	if parasiteState then
                self.healthText:SetColor(GUIMarineStatus.kHealthBarColor)
            else
                self.healthText:SetColor(kParasiteColor)
            end
        end    
    end
    
    if currentArmor ~= self.lastArmor then
        self.armorText:SetText("ARMOR: " .. tostring(math.ceil(currentArmor))) 
        self.lastArmor = currentArmor
        if currentArmor == 0 then
            self.armorText:SetColor(Color(1, 1, 1, 1))
        else
            self.armorText:SetColor(GUIMarineStatus.kArmorBarColor)
        end
    end
       
end
