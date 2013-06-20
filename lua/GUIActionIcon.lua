// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIActionIcon.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Added in classic techids

local kIconWidth = 128
local kIconHeight = 64

local kPickupBackgroundHeight = 32
local kPickupBackgroundSmallWidth = 32
local kPickupBackgroundBigWidth = 64
local kBackgroundWidthBuffer = 26
local kPickupBackgroundSmallCoords = { 7, 0, 38, 31 }
local kPickupBackgroundBigCoords = { 53, 0, 116, 31 }
local kBackgroundYOffset = -10

local kPickupKeyFontSize = 22
local kPickupTextFontSize = 20

local kIconsTextureName = PrecacheAsset("ui/pickup_icons.dds")
local kKeyTextureName = PrecacheAsset("ui/key_mouse_marine.dds")
local kProgressBarTextureName = PrecacheAsset("ui/progress_bar_bg.dds")
local kCommanderBarTextureName = PrecacheAsset("ui/commanderbar.dds")

local kIconOffsets = { }
kIconOffsets["Rifle"] = 0
kIconOffsets["Shotgun"] = 1
kIconOffsets["Pistol"] = 2
kIconOffsets["HeavyMachineGun"] = 3
kIconOffsets["GrenadeLauncher"] = 4
kIconOffsets["NadeLauncher"] = 4
kIconOffsets["Welder"] = 5
kIconOffsets["Jetpack"] = 6
kIconOffsets["Mines"] = 8
kIconOffsets["HandGrenades"] = 4

local kItemText = { }
kItemText["Jetpack"] = string.format("Buy Jetpack for %s Resources.", LookupTechData(kTechId.Jetpack, kTechDataCostKey))

// Hold-button progress
local kBarPadding = 4
local kBarBgSize = Vector(kIconWidth/2, 32, 0)
local kBarSize = Vector(kBarBgSize.x - (2 * kBarPadding), kBarBgSize.y - (2 * kBarPadding), 0)

class 'GUIActionIcon' (GUIScript)

function GUIActionIcon:Initialize()

    self.pickupIcon = GUIManager:CreateGraphicItem()
    self.pickupIcon:SetSize(Vector(kIconWidth, kIconHeight, 0))
    self.pickupIcon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.pickupIcon:SetTexture(kIconsTextureName)
    self.pickupIcon:SetIsVisible(false)
    
    self.pickupKeyBackground = GUIManager:CreateGraphicItem()
    self.pickupKeyBackground:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.pickupKeyBackground:SetTexture(kKeyTextureName)
    self.pickupIcon:AddChild(self.pickupKeyBackground)

    self.pickupKey = GUIManager:CreateTextItem()
    self.pickupKey:SetFontSize(kPickupKeyFontSize)
    self.pickupKey:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.pickupKey:SetTextAlignmentX(GUIItem.Align_Center)
    self.pickupKey:SetTextAlignmentY(GUIItem.Align_Center)
    self.pickupKey:SetFontIsBold(true)
    self.pickupKey:SetText("")
    self.pickupKey:SetFontName("fonts/AgencyFB_small.fnt")
    self.pickupKeyBackground:AddChild(self.pickupKey)

    self.pickupText = GUIManager:CreateTextItem()
    self.pickupText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.pickupText:SetTextAlignmentX(GUIItem.Align_Center)
    self.pickupText:SetTextAlignmentY(GUIItem.Align_Center)
    self.pickupText:SetPosition(Vector(0, 100, 0))
    self.pickupText:SetText("")
    self.pickupText:SetFontName("fonts/AgencyFB_small.fnt")
    self.pickupKeyBackground:AddChild(self.pickupText)
    
    self.hintText = GUIManager:CreateTextItem()
    self.hintText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.hintText:SetTextAlignmentX(GUIItem.Align_Center)
    self.hintText:SetTextAlignmentY(GUIItem.Align_Center)
    self.hintText:SetPosition(Vector(0, -50, 0))
    self.hintText:SetText("")
    self.hintText:SetFontName("fonts/AgencyFB_small.fnt")
    self.pickupKeyBackground:AddChild(self.hintText)

    // For some things, we need the player to hold the key down for a bit. This displays hold-progress
    self.progressBarBg = GUIManager:CreateGraphicItem()
    self.progressBarBg:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.progressBarBg:SetPosition(Vector(-kBarBgSize.x/2,-kBarBgSize.y/2-16,0))
    self.progressBarBg:SetSize(kBarBgSize)
    self.progressBarBg:SetTexture(kProgressBarTextureName)
    self.pickupIcon:AddChild(self.progressBarBg)
    
    self.progressBar = GUIManager:CreateGraphicItem()
    self.progressBar:SetSize(kBarSize)
    self.progressBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.progressBar:SetPosition(Vector(kBarPadding, kBarPadding, 0))
    self.progressBar:SetTexture(kCommanderBarTextureName)
    self.progressBar:SetInheritsParentAlpha(true)
    self.progressBarBg:AddChild(self.progressBar)
    
    // so it can say "Hold [E]"
    self.holdText = GUIManager:CreateTextItem()
    self.holdText:SetFontSize(kPickupKeyFontSize)
    self.holdText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.holdText:SetPosition(Vector(0, 0, 0))
    self.holdText:SetTextAlignmentX(GUIItem.Align_Center)
    self.holdText:SetTextAlignmentY(GUIItem.Align_Center)
    self.holdText:SetFontIsBold(true)    
    self.holdText:SetText(Locale.ResolveString("HOLD_KEY"))
    self.holdText:SetFontName("fonts/AgencyFB_small.fnt")
    self.progressBarBg:AddChild(self.holdText)


end

function GUIActionIcon:Uninitialize()
    
    GUI.DestroyItem(self.pickupKey)
    self.pickupKey = nil
    
    GUI.DestroyItem(self.pickupKeyBackground)
    self.pickupKeyBackground = nil
    
    GUI.DestroyItem(self.pickupIcon)
    self.pickupIcon = nil
    
    GUI.DestroyItem(self.hintText)
    self.hintText = nil
    
    GUI.DestroyItem(self.progressBarBg)
    self.progressBarBg = nil

    GUI.DestroyItem(self.progressBar)
    self.progressBar = nil

    GUI.DestroyItem(self.holdText)
    self.holdText = nil
 
end

function GUIActionIcon:SetColor(c)
    self.pickupKey:SetColor(c)
    self.pickupKeyBackground:SetColor(c)
    self.pickupText:SetColor(c)
    self.hintText:SetColor(c)
    self.progressBarBg:SetColor(c)
    self.progressBar:SetColor(c)
    self.holdText:SetColor(c)
end

// Optionally specify text to display before button
// use holdFraction = nil if this is not a held action
function GUIActionIcon:ShowIcon(buttonText, weaponType, hintText, holdFraction)

    PROFILE("GUIActionIcon:ShowIcon")
    
    self.pickupIcon:SetIsVisible(true)
    self.hintText:SetIsVisible(false)
    
    // Show no icon if not specified
    if weaponType == nil then
        self.pickupIcon:SetColor(Color(1, 1, 1, 0))
        self.pickupText:SetText("")
        self.pickupText:SetIsVisible(false)
    else
        local iconIndex = kIconOffsets[weaponType]
        self.pickupIcon:SetColor(Color(1, 1, 1, 1))
        self.pickupIcon:SetTexturePixelCoordinates(0, iconIndex * kIconHeight, kIconWidth, (iconIndex + 1) * kIconHeight)

        self.pickupText:SetText(ConditionalValue(kItemText[weaponType] ~= nil, kItemText[weaponType], ""))
        self.pickupText:SetIsVisible(true)
    end
    
    self.pickupIcon:SetPosition(Vector(-kIconWidth / 2, (-kIconHeight / 2) + Client.GetScreenHeight() / 4, 0))    
    self.pickupKey:SetText(buttonText)
    local buttonTextWidth = self.pickupKey:GetTextWidth(buttonText)
    
    local backgroundWidth = kPickupBackgroundSmallWidth
    local backgroundHeight = kPickupBackgroundHeight
    local backgroundTextureCoordinates = kPickupBackgroundSmallCoords
    if string.len(buttonText) > 2 then
        backgroundWidth = ((kPickupBackgroundBigWidth > buttonTextWidth + kBackgroundWidthBuffer) and kPickupBackgroundBigWidth) or (buttonTextWidth + kBackgroundWidthBuffer)
        backgroundTextureCoordinates = kPickupBackgroundBigCoords
    end
    
    self.pickupKeyBackground:SetPosition(Vector(-backgroundWidth / 2, -backgroundHeight + kBackgroundYOffset, 0))
    self.pickupKeyBackground:SetSize(Vector(backgroundWidth, backgroundHeight, 0))
    self.pickupKeyBackground:SetTexturePixelCoordinates(unpack(backgroundTextureCoordinates))
    
    if hintText ~= nil then
        self.hintText:SetText(Locale.ResolveString(hintText))
        self.hintText:SetIsVisible(true)
    end

    // handle hold progress
    if holdFraction ~= nil then
        self.progressBarBg:SetIsVisible(true)
        self.progressBar:SetSize( Vector( kBarSize.x*holdFraction, kBarSize.y, 0 ) )
    else
        self.progressBarBg:SetIsVisible(false)
    end
end

function GUIActionIcon:Hide()
    self.pickupIcon:SetIsVisible(false)
end