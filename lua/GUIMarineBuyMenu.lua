// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMarineBuyMenu.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// Manages the marine buy/purchase menu.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Added classic techids

Script.Load("lua/GUIAnimatedScript.lua")

class 'GUIMarineBuyMenu' (GUIAnimatedScript)

GUIMarineBuyMenu.kBuyMenuTexture = "ui/marine_buy_textures.dds"
GUIMarineBuyMenu.kBuyHUDTexture = "ui/marine_buy_icons.dds"
GUIMarineBuyMenu.kRepeatingBackground = "ui/menu/grid.dds"
GUIMarineBuyMenu.kContentBgTexture = "ui/menu/repeating_bg.dds"
GUIMarineBuyMenu.kContentBgBackTexture = "ui/menu/repeating_bg_black.dds"
GUIMarineBuyMenu.kResourceIconTexture = "ui/pres_icon_big.dds"
GUIMarineBuyMenu.kBigIconTexture = "ui/marine_buy_bigicons.dds"
GUIMarineBuyMenu.kButtonTexture = "ui/marine_buymenu_button.dds"
GUIMarineBuyMenu.kMenuSelectionTexture = "ui/marine_buymenu_selector.dds"
GUIMarineBuyMenu.kScanLineTexture = "ui/menu/scanLine_big.dds"
GUIMarineBuyMenu.kArrowTexture = "ui/menu/arrow_horiz.dds"
GUIMarineBuyMenu.kSmallIcons = "ui/buildmenu.dds"

GUIMarineBuyMenu.kFont = Fonts.kAgencyFB_Small

local kScanLineHeight = 256
GUIMarineBuyMenu.kScanLineHeight = GUIScale(kScanLineHeight)
GUIMarineBuyMenu.kScanLineAnimDuration = 5

local kArrowWidth = 32
local kArrowHeight = 32
GUIMarineBuyMenu.kArrowWidth = GUIScale(kArrowWidth)
GUIMarineBuyMenu.kArrowHeight = GUIScale(kArrowHeight)
GUIMarineBuyMenu.kArrowTexCoords = { 1, 1, 0, 0 }

local gBigIconIndex = nil
local bigIconWidth = 400
local bigIconHeight = 300
local function GetBigIconPixelCoords(techId, researched)

    if not gBigIconIndex then
    
        gBigIconIndex = {}
        gBigIconIndex[kTechId.Weapons1] = 0
        gBigIconIndex[kTechId.Weapons2] = 1
        gBigIconIndex[kTechId.Weapons3] = 2
        gBigIconIndex[kTechId.Shotgun] = 3
        gBigIconIndex[kTechId.GrenadeLauncher] = 4
        gBigIconIndex[kTechId.HeavyMachineGun] = 5
        gBigIconIndex[kTechId.Jetpack] = 6
        gBigIconIndex[kTechId.HeavyArmor] = 7
        gBigIconIndex[kTechId.Welder] = 8
        gBigIconIndex[kTechId.Mines] = 9
        gBigIconIndex[kTechId.Armor1] = 10
        gBigIconIndex[kTechId.Armor2] = 11
        gBigIconIndex[kTechId.Armor3] = 12
        gBigIconIndex[kTechId.HandGrenades] = 13
        gBigIconIndex[kTechId.MedPack] = 14
        gBigIconIndex[kTechId.CatPack] = 15
        gBigIconIndex[kTechId.Scan] = 16
        gBigIconIndex[kTechId.MotionTracking] = 17
    
    end
    
    local index = gBigIconIndex[techId]
    if not index then
        index = 0
    end
    
    local x1 = 0
    local x2 = bigIconWidth
    
    if not researched then
    
        x1 = bigIconWidth
        x2 = bigIconWidth * 2
        
    end
    
    local y1 = index * bigIconHeight
    local y2 = (index + 1) * bigIconHeight
    
    return x1, y1, x2, y2

end

// Small Item Icons
local kMenuIconSize = Vector(70, 70, 0)
local kSelectorSize = Vector(74, 94, 0)
local kIconTopOffset = 10
local kTitleTopOffset = 20
local kHighlightOffset = -6
GUIMarineBuyMenu.kMenuIconSize = GUIScale(kMenuIconSize)
GUIMarineBuyMenu.kSelectorSize = GUIScale(kSelectorSize)
GUIMarineBuyMenu.kIconTopOffset = GUIScale(kIconTopOffset)
GUIMarineBuyMenu.kTitleTopOffset = GUIScale(kTitleTopOffset)
GUIMarineBuyMenu.kHighlightOffset = GUIScale(kHighlightOffset)
GUIMarineBuyMenu.kIconTopXOffset = GUIMarineBuyMenu.kSelectorSize.x
                            
GUIMarineBuyMenu.kTextColor = Color(kMarineFontColor)

//These are in order, only Can't Afford if Upgrade is unlocked
GUIMarineBuyMenu.kPurchasedColor = Color(0, 216/255, 1, 1)
GUIMarineBuyMenu.kLockedColor = Color(0.5, 0.5, 0.5, 1)
GUIMarineBuyMenu.kCantAffordColor = Color(1, 0, 0, 1)
GUIMarineBuyMenu.kAvailableColor = Color(1, 1, 1, 1)

local kMenuWidth = 190
local kPadding = 8
GUIMarineBuyMenu.kMenuWidth = GUIScale(kMenuWidth)
GUIMarineBuyMenu.kPadding = GUIScale(kPadding)

local kBackgroundWidth = 600
local kBackgroundHeight = 720
local kBackgroundXOffset = 0
GUIMarineBuyMenu.kBackgroundWidth = GUIScale(kBackgroundWidth)
GUIMarineBuyMenu.kBackgroundHeight = GUIScale(kBackgroundHeight)
// We want the background graphic to look centered around the circle even though there is the part coming off to the right.
GUIMarineBuyMenu.kBackgroundXOffset = GUIScale(kBackgroundXOffset)

local kResourceDisplayHeight = 64
GUIMarineBuyMenu.kResourceDisplayHeight = GUIScale(kResourceDisplayHeight)

local kResourceIconWidth = 32
local kResourceIconHeight = 32
GUIMarineBuyMenu.kResourceIconWidth = GUIScale(kResourceIconWidth)
GUIMarineBuyMenu.kResourceIconHeight = GUIScale(kResourceIconHeight)

GUIMarineBuyMenu.kCloseButtonColor = Color(1, 1, 0, 1)

local kButtonWidth = 160
local kButtonHeight = 64
GUIMarineBuyMenu.kButtonWidth = GUIScale(kButtonWidth)
GUIMarineBuyMenu.kButtonHeight = GUIScale(kButtonHeight)

// Big Item Icons
local kBigIconSize = Vector(320, 256, 0)
local kBigIconOffset = -276
GUIMarineBuyMenu.kBigIconSize = GUIScale(kBigIconSize)
GUIMarineBuyMenu.kBigIconOffset = GUIScale(kBigIconOffset)

local kItemNameOffsetX = 10
local kItemNameOffsetY = -300
GUIMarineBuyMenu.kItemNameOffsetX = GUIScale(kItemNameOffsetX)
GUIMarineBuyMenu.kItemNameOffsetY = GUIScale(kItemNameOffsetY)

local kItemDescriptionOffsetX = -150
local kItemDescriptionOffsetY = -200
local kItemDescriptionSize = Vector(450, 180, 0)
GUIMarineBuyMenu.kItemDescriptionOffsetX = GUIScale(kItemDescriptionOffsetX)
GUIMarineBuyMenu.kItemDescriptionOffsetY = GUIScale(kItemDescriptionOffsetY)
GUIMarineBuyMenu.kItemDescriptionSize = GUIScale(kItemDescriptionSize)

GUIMarineBuyMenu.kCombatMarineUpgradeTable = 	{   {kTechId.Weapons1, kTechId.Weapons2, kTechId.Weapons3 },
													{kTechId.Armor1, kTechId.Armor2, kTechId.Armor3 },
													{kTechId.Shotgun, kTechId.HeavyMachineGun, kTechId.GrenadeLauncher },
													{kTechId.Welder, kTechId.Mines, kTechId.HandGrenades },
													{kTechId.MedPack, kTechId.CatPack, kTechId.Scan, kTechId.MotionTracking},
													{kTechId.Jetpack, kTechId.HeavyArmor }
												}

function GUIMarineBuyMenu:OnClose()

    // Check if GUIMarineBuyMenu is what is causing itself to close.
    if not self.closingMenu then
        // Play the close sound since we didn't trigger the close.
        MarineBuy_OnClose()
    end

end

function GUIMarineBuyMenu:Initialize()

    GUIAnimatedScript.Initialize(self)

    self.mouseOverStates = { }
    
    self:_InitializeBackground()
    self:_InitializeContent()
    self:_InitializeResourceDisplay()
    self:_InitializeCloseButton() 
    self:_InitializeItemButtons()
    
    MarineBuy_OnOpen()
    
end

/**
 * Checks if the mouse is over the passed in GUIItem and plays a sound if it has just moved over.
 */
local function GetIsMouseOver(self, overItem)

    local mouseOver = GUIItemContainsPoint(overItem, Client.GetCursorPosScreen())
    if mouseOver and not self.mouseOverStates[overItem] then
        MarineBuy_OnMouseOver()
    end
    self.mouseOverStates[overItem] = mouseOver
    return mouseOver
    
end

function GUIMarineBuyMenu:OnResolutionChanged(oldX, oldY, newX, newY)

	GUIMarineBuyMenu.kScanLineHeight = GUIScale(kScanLineHeight)
	GUIMarineBuyMenu.kArrowWidth = GUIScale(kArrowWidth)
	GUIMarineBuyMenu.kArrowHeight = GUIScale(kArrowHeight)

	GUIMarineBuyMenu.kMenuIconSize = GUIScale(kMenuIconSize)
	GUIMarineBuyMenu.kSelectorSize = GUIScale(kSelectorSize)
	GUIMarineBuyMenu.kIconTopOffset = GUIScale(kIconTopOffset)
	GUIMarineBuyMenu.kTitleTopOffset = GUIScale(kTitleTopOffset)
	GUIMarineBuyMenu.kHighlightOffset = GUIScale(kHighlightOffset)
	GUIMarineBuyMenu.kIconTopXOffset = GUIMarineBuyMenu.kSelectorSize.x
	GUIMarineBuyMenu.kMenuWidth = GUIScale(kMenuWidth)
	GUIMarineBuyMenu.kPadding = GUIScale(kPadding)
	GUIMarineBuyMenu.kBackgroundWidth = GUIScale(kBackgroundWidth)
	GUIMarineBuyMenu.kBackgroundHeight = GUIScale(kBackgroundHeight)
	GUIMarineBuyMenu.kBackgroundXOffset = GUIScale(kBackgroundXOffset)
	GUIMarineBuyMenu.kResourceDisplayHeight = GUIScale(kResourceDisplayHeight)
	GUIMarineBuyMenu.kResourceIconWidth = GUIScale(kResourceIconWidth)
	GUIMarineBuyMenu.kResourceIconHeight = GUIScale(kResourceIconHeight)
	GUIMarineBuyMenu.kButtonWidth = GUIScale(kButtonWidth)
	GUIMarineBuyMenu.kButtonHeight = GUIScale(kButtonHeight)
	GUIMarineBuyMenu.kBigIconSize = GUIScale(kBigIconSize)
	GUIMarineBuyMenu.kBigIconOffset = GUIScale(kBigIconOffset)
	GUIMarineBuyMenu.kItemNameOffsetX = GUIScale(kItemNameOffsetX)
	GUIMarineBuyMenu.kItemNameOffsetY = GUIScale(kItemNameOffsetY)
	GUIMarineBuyMenu.kItemDescriptionOffsetX = GUIScale(kItemDescriptionOffsetX)
	GUIMarineBuyMenu.kItemDescriptionOffsetY = GUIScale(kItemDescriptionOffsetY)
	GUIMarineBuyMenu.kItemDescriptionSize = GUIScale(kItemDescriptionSize)

	self:Uninitialize()
	self:Initialize()
	
end

function GUIMarineBuyMenu:Update(deltaTime)

    GUIAnimatedScript.Update(self, deltaTime)

    self:_UpdateItemButtons(deltaTime)
    self:_UpdateContent(deltaTime)
    self:_UpdateResourceDisplay(deltaTime)
    self:_UpdateCloseButton(deltaTime)
    
end

function GUIMarineBuyMenu:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)

    self:_UninitializeItemButtons()
    self:_UninitializeBackground()
    self:_UninitializeContent()
    self:_UninitializeResourceDisplay()
    self:_UninitializeCloseButton()

end

local function MoveDownAnim(script, item)

    item:SetPosition( Vector(0, -GUIMarineBuyMenu.kScanLineHeight, 0) )
    item:SetPosition( Vector(0, Client.GetScreenHeight() + GUIMarineBuyMenu.kScanLineHeight, 0), GUIMarineBuyMenu.kScanLineAnimDuration, "MARINEBUY_SCANLINE", AnimateLinear, MoveDownAnim)

end

function GUIMarineBuyMenu:_InitializeBackground()

    // This invisible background is used for centering only.
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0))
    self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.background:SetColor(Color(0.05, 0.05, 0.1, 0.7))
    self.background:SetLayer(kGUILayerPlayerHUDForeground4)
    
    self.repeatingBGTexture = GUIManager:CreateGraphicItem()
    self.repeatingBGTexture:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0))
    self.repeatingBGTexture:SetTexture(GUIMarineBuyMenu.kRepeatingBackground)
    self.repeatingBGTexture:SetTexturePixelCoordinates(0, 0, Client.GetScreenWidth(), Client.GetScreenHeight())
    self.background:AddChild(self.repeatingBGTexture)
    
    self.content = GUIManager:CreateGraphicItem()
    self.content:SetSize(Vector(GUIMarineBuyMenu.kBackgroundWidth, GUIMarineBuyMenu.kBackgroundHeight, 0))
    self.content:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.content:SetPosition(Vector((-GUIMarineBuyMenu.kBackgroundWidth / 2) + GUIMarineBuyMenu.kBackgroundXOffset, -GUIMarineBuyMenu.kBackgroundHeight / 2, 0))
    self.content:SetTexture(GUIMarineBuyMenu.kContentBgTexture)
    self.content:SetTexturePixelCoordinates(0, 0, GUIMarineBuyMenu.kBackgroundWidth, GUIMarineBuyMenu.kBackgroundHeight)
    self.content:SetColor( Color(1,1,1,0.8) )
    self.background:AddChild(self.content)
    
    self.scanLine = self:CreateAnimatedGraphicItem()
    self.scanLine:SetSize( Vector( Client.GetScreenWidth(), GUIMarineBuyMenu.kScanLineHeight, 0) )
    self.scanLine:SetTexture(GUIMarineBuyMenu.kScanLineTexture)
    self.scanLine:SetLayer(kGUILayerPlayerHUDForeground4)
    self.scanLine:SetIsScaling(false)
    
    self.scanLine:SetPosition( Vector(0, -GUIMarineBuyMenu.kScanLineHeight, 0) )
    self.scanLine:SetPosition( Vector(0, Client.GetScreenHeight() + GUIMarineBuyMenu.kScanLineHeight, 0), GUIMarineBuyMenu.kScanLineAnimDuration, "MARINEBUY_SCANLINE", AnimateLinear, MoveDownAnim)

end

function GUIMarineBuyMenu:_UninitializeBackground()

    GUI.DestroyItem(self.background)
    self.background = nil
    
    self.content = nil
    
end

function GetIndexOf(table, value)
    for k,v in pairs(table) do 
        if v == value then return k end
    end
end

function GUIMarineBuyMenu:_InitializeItemButtons()
    
    self.menu = GetGUIManager():CreateGraphicItem()
    self.menu:SetPosition(Vector( -GUIMarineBuyMenu.kMenuWidth - GUIMarineBuyMenu.kPadding, 0, 0))
    self.menu:SetTexture(GUIMarineBuyMenu.kContentBgTexture)
    self.menu:SetSize(Vector(GUIMarineBuyMenu.kMenuWidth, GUIMarineBuyMenu.kBackgroundHeight, 0))
    self.menu:SetTexturePixelCoordinates(0, 0, GUIMarineBuyMenu.kMenuWidth, GUIMarineBuyMenu.kBackgroundHeight)
    self.content:AddChild(self.menu)
    
    self.menuHeader = GetGUIManager():CreateGraphicItem()
    self.menuHeader:SetSize(Vector(GUIMarineBuyMenu.kMenuWidth, GUIMarineBuyMenu.kResourceDisplayHeight, 0))
    self.menuHeader:SetPosition(Vector(0, -GUIMarineBuyMenu.kResourceDisplayHeight, 0))
    self.menuHeader:SetTexture(GUIMarineBuyMenu.kContentBgBackTexture)
    self.menuHeader:SetTexturePixelCoordinates(0, 0, GUIMarineBuyMenu.kMenuWidth, GUIMarineBuyMenu.kResourceDisplayHeight)
    self.menu:AddChild(self.menuHeader) 
    
    self.menuHeaderTitle = GetGUIManager():CreateTextItem()
    self.menuHeaderTitle:SetFontName(GUIMarineBuyMenu.kFont)
    self.menuHeaderTitle:SetFontIsBold(true)
    self.menuHeaderTitle:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.menuHeaderTitle:SetTextAlignmentX(GUIItem.Align_Center)
    self.menuHeaderTitle:SetTextAlignmentY(GUIItem.Align_Center)
    self.menuHeaderTitle:SetColor(GUIMarineBuyMenu.kTextColor)
    self.menuHeaderTitle:SetText(Locale.ResolveString("BUY"))
    self.menuHeader:AddChild(self.menuHeaderTitle)
    
    self.itemButtons = { }
    
    local itemTechIdList = MarineUI_GetPersonalUpgrades()
                        
    local selectorPosX = -GUIMarineBuyMenu.kSelectorSize.x + GUIMarineBuyMenu.kPadding
    local fontScaleVector = Vector(0.8, 0.8, 0)
    
    for k, itemTechId in ipairs(itemTechIdList) do
    
        local xPos, yPos
        
        for i = 1, #GUIMarineBuyMenu.kCombatMarineUpgradeTable do
            if table.contains(GUIMarineBuyMenu.kCombatMarineUpgradeTable[i], itemTechId) then
                xPos = (-GUIMarineBuyMenu.kIconTopXOffset) + GUIMarineBuyMenu.kIconTopXOffset * (i - 1)
                yPos = GUIMarineBuyMenu.kIconTopOffset + (GUIMarineBuyMenu.kSelectorSize.y) * GetIndexOf(GUIMarineBuyMenu.kCombatMarineUpgradeTable[i], itemTechId) - GUIMarineBuyMenu.kMenuIconSize.y
            end        
        end
        
        local graphicItem = GUIManager:CreateGraphicItem()
        graphicItem:SetSize(GUIMarineBuyMenu.kMenuIconSize)
        graphicItem:SetAnchor(GUIItem.Middle, GUIItem.Top)
        graphicItem:SetPosition(Vector(xPos, yPos, 0))
        graphicItem:SetTexture(GUIMarineBuyMenu.kSmallIcons)
        graphicItem:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(itemTechId, false)))
		
		local itemTitle = GUIManager:CreateTextItem()
        itemTitle:SetFontName(GUIMarineBuyMenu.kFont)
        itemTitle:SetFontIsBold(true)
        itemTitle:SetAnchor(GUIItem.Right, GUIItem.Center)
        itemTitle:SetPosition(Vector(selectorPosX, (-GUIMarineBuyMenu.kSelectorSize.y / 2) + GUIMarineBuyMenu.kTitleTopOffset, 0))
        itemTitle:SetTextAlignmentX(GUIItem.Align_Min)
        itemTitle:SetTextAlignmentY(GUIItem.Align_Center)
        itemTitle:SetScale(fontScaleVector)
        itemTitle:SetColor(GUIMarineBuyMenu.kTextColor)
        itemTitle:SetText(ToString(LookupTechData(itemTechId, kTechDataCombatDisplayName, "")))
		graphicItem:AddChild(itemTitle)
        
        local graphicItemActive = GUIManager:CreateGraphicItem()
        graphicItemActive:SetSize(GUIMarineBuyMenu.kSelectorSize)
        graphicItemActive:SetPosition(Vector(selectorPosX + GUIMarineBuyMenu.kHighlightOffset, -GUIMarineBuyMenu.kSelectorSize.y / 2, 0))
        graphicItemActive:SetAnchor(GUIItem.Right, GUIItem.Center)
        graphicItemActive:SetTexture(GUIMarineBuyMenu.kMenuSelectionTexture)
        graphicItemActive:SetIsVisible(false)
        graphicItem:AddChild(graphicItemActive)
        
        local costIcon = GUIManager:CreateGraphicItem()
        costIcon:SetSize(Vector(GUIMarineBuyMenu.kResourceIconWidth * 0.8, GUIMarineBuyMenu.kResourceIconHeight * 0.8, 0))
        costIcon:SetAnchor(GUIItem.Right, GUIItem.Bottom)
        costIcon:SetPosition(Vector(-32, -GUIMarineBuyMenu.kResourceIconHeight * 0.5, 0))
        costIcon:SetTexture(GUIMarineBuyMenu.kResourceIconTexture)
        costIcon:SetColor(GUIMarineBuyMenu.kTextColor)
        
        local selectedArrow = GUIManager:CreateGraphicItem()
        selectedArrow:SetSize(Vector(GUIMarineBuyMenu.kArrowWidth, GUIMarineBuyMenu.kArrowHeight, 0))
        selectedArrow:SetAnchor(GUIItem.Left, GUIItem.Center)
        selectedArrow:SetPosition(Vector(-GUIMarineBuyMenu.kArrowWidth - GUIMarineBuyMenu.kPadding, -GUIMarineBuyMenu.kArrowHeight * 0.5, 0))
        selectedArrow:SetTexture(GUIMarineBuyMenu.kArrowTexture)
        selectedArrow:SetColor(GUIMarineBuyMenu.kTextColor)
        selectedArrow:SetTextureCoordinates(unpack(GUIMarineBuyMenu.kArrowTexCoords))
        selectedArrow:SetIsVisible(false)
        
        graphicItem:AddChild(selectedArrow) 
        
        local itemCost = GUIManager:CreateTextItem()
        itemCost:SetFontName(GUIMarineBuyMenu.kFont)
        itemCost:SetFontIsBold(true)
        itemCost:SetAnchor(GUIItem.Right, GUIItem.Center)
        itemCost:SetPosition(Vector(0, 0, 0))
        itemCost:SetTextAlignmentX(GUIItem.Align_Min)
        itemCost:SetTextAlignmentY(GUIItem.Align_Center)
        itemCost:SetScale(fontScaleVector)
        itemCost:SetColor(GUIMarineBuyMenu.kTextColor)
        itemCost:SetText(ToString(LookupTechData(itemTechId, kTechDataCostKey, 0)))
        
        costIcon:AddChild(itemCost)  
        
        graphicItem:AddChild(costIcon)  
        
        self.menu:AddChild(graphicItem)
        table.insert(self.itemButtons, { Button = graphicItem, Highlight = graphicItemActive, TechId = itemTechId, Cost = itemCost, ResourceIcon = costIcon, Arrow = selectedArrow } )
    
    end
    
    // to prevent wrong display before the first update
    self:_UpdateItemButtons(0)

end

function GUIMarineBuyMenu:_UpdateItemButtons(deltaTime)

    for i, item in ipairs(self.itemButtons) do
    
        if GetIsMouseOver(self, item.Button) then
        
            item.Highlight:SetIsVisible(true)
            self.hoverItem = item.TechId
            
        else
            item.Highlight:SetIsVisible(false)
        end
        
        local useColor = GUIMarineBuyMenu.kAvailableColor
		if PlayerUI_GetHasItem(item.TechId) then
            useColor = GUIMarineBuyMenu.kPurchasedColor
		elseif not BuyMenus_GetUpgradeAvailable(item.TechId) then
            useColor = GUIMarineBuyMenu.kLockedColor
        elseif PlayerUI_GetPlayerResources() < BuyMenus_GetUpgradeCost(item.TechId) then
           useColor = GUIMarineBuyMenu.kCantAffordColor
        end
        
        item.Button:SetColor(useColor)
        item.Highlight:SetColor(useColor)
        item.Cost:SetColor(useColor)
        item.ResourceIcon:SetColor(useColor)
        item.Arrow:SetIsVisible(self.selectedItem == item.TechId)
        
    end

end

function GUIMarineBuyMenu:_UninitializeItemButtons()

    for i, item in ipairs(self.itemButtons) do
        GUI.DestroyItem(item.Button)
    end
    self.itemButtons = nil

end

function GUIMarineBuyMenu:_InitializeContent()

    self.itemName = GUIManager:CreateTextItem()
    self.itemName:SetFontName(GUIMarineBuyMenu.kFont)
    self.itemName:SetFontIsBold(true)
    self.itemName:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.itemName:SetPosition(Vector(-GUIMarineBuyMenu.kBigIconSize.x / 2 + GUIMarineBuyMenu.kItemNameOffsetX , GUIMarineBuyMenu.kItemNameOffsetY , 0))
    self.itemName:SetTextAlignmentX(GUIItem.Align_Min)
    self.itemName:SetTextAlignmentY(GUIItem.Align_Min)
    self.itemName:SetColor(GUIMarineBuyMenu.kTextColor)
    self.itemName:SetText("no selection")
    self.content:AddChild(self.itemName)
    
    self.portrait = GetGUIManager():CreateGraphicItem()
    self.portrait:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.portrait:SetPosition(Vector(-GUIMarineBuyMenu.kBigIconSize.x / 2, GUIMarineBuyMenu.kBigIconOffset, 0))
    self.portrait:SetSize(GUIMarineBuyMenu.kBigIconSize)
    self.portrait:SetTexture(GUIMarineBuyMenu.kBigIconTexture)
    self.portrait:SetTexturePixelCoordinates(GetBigIconPixelCoords(kTechId.Axe))
    self.portrait:SetIsVisible(false)
    self.content:AddChild(self.portrait)
    
    self.itemDescription = GetGUIManager():CreateTextItem()
    self.itemDescription:SetFontName(GUIMarineBuyMenu.kFont)
    self.itemDescription:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.itemDescription:SetPosition(Vector(GUIMarineBuyMenu.kItemDescriptionOffsetX, GUIMarineBuyMenu.kItemDescriptionOffsetY, 0))
    self.itemDescription:SetTextAlignmentX(GUIItem.Align_Min)
    self.itemDescription:SetTextAlignmentY(GUIItem.Align_Min)
    self.itemDescription:SetColor(GUIMarineBuyMenu.kTextColor)
    self.itemDescription:SetTextClipped(true, GUIMarineBuyMenu.kItemDescriptionSize.x - 2 * GUIMarineBuyMenu.kPadding, GUIMarineBuyMenu.kItemDescriptionSize.y - GUIMarineBuyMenu.kPadding)
    self.content:AddChild(self.itemDescription)
    
end

function GUIMarineBuyMenu:_UpdateContent(deltaTime)

    local techId = self.hoverItem
    if not self.hoverItem then
        techId = self.selectedItem
    end
    
    if techId then
    
        local unlocked = self:_GetIsUnlocked(techId)
        local alreadyHas = PlayerUI_GetHasItem(techId)        
        local itemCost = BuyMenus_GetUpgradeCost(techId)
        local canAfford = PlayerUI_GetPlayerResources() >= itemCost

        local color = GUIMarineBuyMenu.kAvailableColor
		if alreadyHas then
            color = GUIMarineBuyMenu.kPurchasedColor
		elseif not unlocked then
            color = GUIMarineBuyMenu.kLockedColor
		elseif not canAfford then
			color = GUIMarineBuyMenu.kCantAffordColor
        end
    
        self.itemName:SetColor(color)
        self.portrait:SetColor(color)        
        self.itemDescription:SetColor(color)

        self.itemName:SetText(MarineBuy_GetDisplayName(techId))
        self.portrait:SetTexturePixelCoordinates(GetBigIconPixelCoords(techId, unlocked))
        self.itemDescription:SetText(MarineBuy_GetWeaponDescription(techId))
        self.itemDescription:SetTextClipped(true, GUIMarineBuyMenu.kItemDescriptionSize.x - 2* GUIMarineBuyMenu.kPadding, GUIMarineBuyMenu.kItemDescriptionSize.y - GUIMarineBuyMenu.kPadding)

    end
    
    local contentVisible = techId ~= nil and techId ~= kTechId.None
    
    self.portrait:SetIsVisible(contentVisible)
    self.itemName:SetIsVisible(contentVisible)
    self.itemDescription:SetIsVisible(contentVisible)
    
end

function GUIMarineBuyMenu:_UninitializeContent()

    GUI.DestroyItem(self.itemName)

end

function GUIMarineBuyMenu:_InitializeResourceDisplay()
    
    self.resourceDisplayBackground = GUIManager:CreateGraphicItem()
    self.resourceDisplayBackground:SetSize(Vector(GUIMarineBuyMenu.kBackgroundWidth, GUIMarineBuyMenu.kResourceDisplayHeight, 0))
    self.resourceDisplayBackground:SetPosition(Vector(0, -GUIMarineBuyMenu.kResourceDisplayHeight, 0))
    self.resourceDisplayBackground:SetTexture(GUIMarineBuyMenu.kContentBgBackTexture)
    self.resourceDisplayBackground:SetTexturePixelCoordinates(0, 0, GUIMarineBuyMenu.kBackgroundWidth, GUIMarineBuyMenu.kResourceDisplayHeight)
    self.content:AddChild(self.resourceDisplayBackground)
    
    self.resourceDisplayIcon = GUIManager:CreateGraphicItem()
    self.resourceDisplayIcon:SetSize(Vector(GUIMarineBuyMenu.kResourceIconWidth, GUIMarineBuyMenu.kResourceIconHeight, 0))
    self.resourceDisplayIcon:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.resourceDisplayIcon:SetPosition(Vector(-GUIMarineBuyMenu.kResourceIconWidth * 2.2, -GUIMarineBuyMenu.kResourceIconHeight / 2, 0))
    self.resourceDisplayIcon:SetTexture(GUIMarineBuyMenu.kResourceIconTexture)
    self.resourceDisplayIcon:SetColor(GUIMarineBuyMenu.kTextColor)
    self.resourceDisplayBackground:AddChild(self.resourceDisplayIcon)

    self.resourceDisplay = GUIManager:CreateTextItem()
    self.resourceDisplay:SetFontName(GUIMarineBuyMenu.kFont)
    self.resourceDisplay:SetFontIsBold(true)
    self.resourceDisplay:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.resourceDisplay:SetPosition(Vector(-GUIMarineBuyMenu.kResourceIconWidth , 0, 0))
    self.resourceDisplay:SetTextAlignmentX(GUIItem.Align_Min)
    self.resourceDisplay:SetTextAlignmentY(GUIItem.Align_Center)
    self.resourceDisplay:SetColor(GUIMarineBuyMenu.kTextColor)    
    self.resourceDisplay:SetText("")
    self.resourceDisplayBackground:AddChild(self.resourceDisplay)
    
    self.currentDescription = GUIManager:CreateTextItem()
    self.currentDescription:SetFontName(GUIMarineBuyMenu.kFont)
    self.currentDescription:SetFontIsBold(true)
    self.currentDescription:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.currentDescription:SetPosition(Vector(-GUIMarineBuyMenu.kResourceIconWidth * 3 , GUIMarineBuyMenu.kResourceIconHeight, 0))
    self.currentDescription:SetTextAlignmentX(GUIItem.Align_Max)
    self.currentDescription:SetTextAlignmentY(GUIItem.Align_Center)
    self.currentDescription:SetColor(GUIMarineBuyMenu.kTextColor)
    self.currentDescription:SetText(Locale.ResolveString("CURRENT"))
    
    self.resourceDisplayBackground:AddChild(self.currentDescription) 

end

function GUIMarineBuyMenu:_UpdateResourceDisplay(deltaTime)

    self.resourceDisplay:SetText(ToString(PlayerUI_GetPlayerResources()))
    
end

function GUIMarineBuyMenu:_UninitializeResourceDisplay()

    GUI.DestroyItem(self.resourceDisplay)
    self.resourceDisplay = nil
    
    GUI.DestroyItem(self.resourceDisplayIcon)
    self.resourceDisplayIcon = nil
    
    GUI.DestroyItem(self.resourceDisplayBackground)
    self.resourceDisplayBackground = nil
    
end

function GUIMarineBuyMenu:_InitializeCloseButton()

    self.closeButton = GUIManager:CreateGraphicItem()
    self.closeButton:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.closeButton:SetSize(Vector(GUIMarineBuyMenu.kButtonWidth, GUIMarineBuyMenu.kButtonHeight, 0))
    self.closeButton:SetPosition(Vector(-GUIMarineBuyMenu.kButtonWidth, GUIMarineBuyMenu.kPadding, 0))
    self.closeButton:SetTexture(GUIMarineBuyMenu.kButtonTexture)
    self.closeButton:SetLayer(kGUILayerPlayerHUDForeground4)
    self.content:AddChild(self.closeButton)
    
    self.closeButtonText = GUIManager:CreateTextItem()
    self.closeButtonText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.closeButtonText:SetFontName(GUIMarineBuyMenu.kFont)
    self.closeButtonText:SetTextAlignmentX(GUIItem.Align_Center)
    self.closeButtonText:SetTextAlignmentY(GUIItem.Align_Center)
    self.closeButtonText:SetText(Locale.ResolveString("EXIT"))
    self.closeButtonText:SetFontIsBold(true)
    self.closeButtonText:SetColor(GUIMarineBuyMenu.kCloseButtonColor)
    self.closeButton:AddChild(self.closeButtonText)
    
end

function GUIMarineBuyMenu:_UpdateCloseButton(deltaTime)

    if GetIsMouseOver(self, self.closeButton) then
        self.closeButton:SetColor(Color(1, 1, 1, 1))
    else
        self.closeButton:SetColor(Color(0.5, 0.5, 0.5, 1))
    end
    
end

function GUIMarineBuyMenu:_UninitializeCloseButton()
    
    GUI.DestroyItem(self.closeButton)
    self.closeButton = nil

end

function GUIMarineBuyMenu:_GetIsUnlocked(techId)

    local unlocked = BuyMenus_GetUpgradeAvailable(techId)
    
    return unlocked
end

local function HandleItemClicked(self, mouseX, mouseY)

    for i = 1, #self.itemButtons do
    
        local item = self.itemButtons[i]
        if GetIsMouseOver(self, item.Button) then
        
            local unlocked = self:_GetIsUnlocked(item.TechId)
            local itemCost = BuyMenus_GetUpgradeCost(item.TechId)
            local canAfford = PlayerUI_GetPlayerResources() >= itemCost
            local hasItem = PlayerUI_GetHasItem(item.TechId)
            
            if unlocked and canAfford and not hasItem then
            
                MarineBuy_PurchaseItem(item.TechId)
                if PlayerUI_GetPlayerResources() - itemCost == 0 then
                    return true, true
                end
                return true, false
                
            end
            
        end
        
    end
    
    return false, false
    
end

function GUIMarineBuyMenu:SendKeyEvent(key, down)

    local closeMenu = false
    local inputHandled = false
    
    if key == InputKey.MouseButton0 and self.mousePressed ~= down then
    
        self.mousePressed = down
        
        local mouseX, mouseY = Client.GetCursorPosScreen()
        if down then
        
            inputHandled, closeMenu = HandleItemClicked(self, mouseX, mouseY)
            
            if not inputHandled then
            
                // Check if the close button was pressed.
                if GetIsMouseOver(self, self.closeButton) then
                
                    closeMenu = true
                    MarineBuy_OnClose()
                    
                end
                
            end
            
        end
        
    end
    
    // No matter what, this menu consumes MouseButton0/1.
    if key == InputKey.MouseButton0 or key == InputKey.MouseButton1 then
        inputHandled = true
    end
    
    if InputKey.Escape == key and not down then
    
        closeMenu = true
        inputHandled = true
        MarineBuy_OnClose()
        
    end
    
    if closeMenu then
    
        self.closingMenu = true
        MarineBuy_Close()
        
    end
    
    return inputHandled
    
end