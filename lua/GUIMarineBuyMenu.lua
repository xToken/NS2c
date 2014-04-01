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

GUIMarineBuyMenu.kFont = "fonts/AgencyFB_small.fnt"
GUIMarineBuyMenu.kFont2 = "fonts/AgencyFB_small.fnt"

GUIMarineBuyMenu.kDescriptionFontName = "fonts/AgencyFB_small.fnt"
GUIMarineBuyMenu.kDescriptionFontSize = GUIScale(20)

GUIMarineBuyMenu.kScanLineHeight = GUIScale(256)
GUIMarineBuyMenu.kScanLineAnimDuration = 5

GUIMarineBuyMenu.kArrowWidth = GUIScale(32)
GUIMarineBuyMenu.kArrowHeight = GUIScale(32)
GUIMarineBuyMenu.kArrowTexCoords = { 1, 1, 0, 0 }

// Big Item Icons
GUIMarineBuyMenu.kBigIconSize = GUIScale( Vector(320, 256, 0) )
GUIMarineBuyMenu.kBigIconOffset = GUIScale(20)

local kEquippedMouseoverColor = Color(1, 1, 1, 1)
local kEquippedColor = Color(0.5, 0.5, 0.5, 0.5)

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
GUIMarineBuyMenu.kMenuIconSize = GUIScale( Vector(71, 71, 0) )
GUIMarineBuyMenu.kSelectorSize = GUIScale( Vector(75, 75, 0) )
GUIMarineBuyMenu.kIconTopOffset = 10
GUIMarineBuyMenu.kItemIconYOffset = {}

GUIMarineBuyMenu.kEquippedIconTopOffset = 58
                            
GUIMarineBuyMenu.kTextColor = Color(kMarineFontColor)

GUIMarineBuyMenu.kMenuWidth = GUIScale(190)
GUIMarineBuyMenu.kPadding = GUIScale(8)

GUIMarineBuyMenu.kEquippedWidth = GUIScale(128)

GUIMarineBuyMenu.kBackgroundWidth = GUIScale(600)
GUIMarineBuyMenu.kBackgroundHeight = GUIScale(720)
// We want the background graphic to look centered around the circle even though there is the part coming off to the right.
GUIMarineBuyMenu.kBackgroundXOffset = GUIScale(0)

GUIMarineBuyMenu.kPlayersTextSize = GUIScale(24)
GUIMarineBuyMenu.kResearchTextSize = GUIScale(24)

GUIMarineBuyMenu.kResourceDisplayHeight = GUIScale(64)

GUIMarineBuyMenu.kResourceIconWidth = GUIScale(32)
GUIMarineBuyMenu.kResourceIconHeight = GUIScale(32)

GUIMarineBuyMenu.kMouseOverInfoTextSize = GUIScale(20)
GUIMarineBuyMenu.kMouseOverInfoOffset = Vector(GUIScale(-30), GUIScale(-20), 0)
GUIMarineBuyMenu.kMouseOverInfoResIconOffset = Vector(GUIScale(-40), GUIScale(-60), 0)

GUIMarineBuyMenu.kDisabledColor = Color(0.5, 0.5, 0.5, 0.5)
GUIMarineBuyMenu.kCannotBuyColor = Color(1, 0, 0, 0.5)
GUIMarineBuyMenu.kEnabledColor = Color(1, 1, 1, 1)

GUIMarineBuyMenu.kCloseButtonColor = Color(1, 1, 0, 1)

GUIMarineBuyMenu.kButtonWidth = GUIScale(160)
GUIMarineBuyMenu.kButtonHeight = GUIScale(64)

GUIMarineBuyMenu.kItemNameOffsetX = GUIScale(28)
GUIMarineBuyMenu.kItemNameOffsetY = GUIScale(256)

GUIMarineBuyMenu.kItemDescriptionOffsetY = GUIScale(300)
GUIMarineBuyMenu.kItemDescriptionSize = GUIScale( Vector(450, 180, 0) )

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
    self.equipped = { }
    
    self:_InitializeBackground()
    self:_InitializeContent()
    self:_InitializeResourceDisplay()
    self:_InitializeCloseButton()
    //self:_InitializeEquipped()    
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

local function UpdateEquipped(self, deltaTime)

    self.hoverItem = nil
    for i = 1, #self.equipped do
    
        local equipped = self.equipped[i]
        if GetIsMouseOver(self, equipped.Graphic) then
        
            self.hoverItem = equipped.TechId
            equipped.Graphic:SetColor(kEquippedMouseoverColor)
            
        else
            equipped.Graphic:SetColor(kEquippedColor)
        end
        
    end
    
end

function GUIMarineBuyMenu:Update(deltaTime)

    GUIAnimatedScript.Update(self, deltaTime)

    UpdateEquipped(self, deltaTime)
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
    local itemcolumns = { a = {kTechId.MedPack, kTechId.CatPack, kTechId.Scan, kTechId.MotionTracking, kTechId.Welder, kTechId.Mines, kTechId.HandGrenades, kTechId.Shotgun, kTechId.HeavyMachineGun, kTechId.GrenadeLauncher },
                          b = {kTechId.Weapons1, kTechId.Weapons2, kTechId.Weapons3, kTechId.Armor1, kTechId.Armor2, kTechId.Armor3, kTechId.Jetpack, kTechId.HeavyArmor } }
                        
    local selectorPosX = -GUIMarineBuyMenu.kSelectorSize.x + GUIMarineBuyMenu.kPadding
    local fontScaleVector = Vector(0.8, 0.8, 0)
    
    for k, itemTechId in ipairs(itemTechIdList) do
    
        local xPos, yPos
        if table.contains(itemcolumns.a, itemTechId) then
            xPos = -GUIMarineBuyMenu.kMenuIconSize.x
            yPos = GUIMarineBuyMenu.kIconTopOffset + (GUIMarineBuyMenu.kMenuIconSize.y) * GetIndexOf(itemcolumns.a, itemTechId) - GUIMarineBuyMenu.kMenuIconSize.y
        elseif table.contains(itemcolumns.b, itemTechId) then
            xPos = 0
            yPos = GUIMarineBuyMenu.kIconTopOffset + (GUIMarineBuyMenu.kMenuIconSize.y) * GetIndexOf(itemcolumns.b, itemTechId) - GUIMarineBuyMenu.kMenuIconSize.y
        end
        
        local graphicItem = GUIManager:CreateGraphicItem()
        graphicItem:SetSize(GUIMarineBuyMenu.kMenuIconSize)
        graphicItem:SetAnchor(GUIItem.Middle, GUIItem.Top)
        graphicItem:SetPosition(Vector(xPos, yPos, 0))
        graphicItem:SetTexture(GUIMarineBuyMenu.kSmallIcons)
        graphicItem:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(itemTechId, false)))
        
        local graphicItemActive = GUIManager:CreateGraphicItem()
        graphicItemActive:SetSize(GUIMarineBuyMenu.kSelectorSize)
        
        graphicItemActive:SetPosition(Vector(selectorPosX, -GUIMarineBuyMenu.kSelectorSize.y / 2, 0))
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
        
        local useColor = Color(1, 1, 1, 1)
        
        // set grey if not unlocked
        if PlayerUI_GetHasItem(item.TechId) then
            useColor = Color(0, 216/255, 1, 1)
        elseif not BuyMenus_GetUpgradeAvailable(item.TechId) then
            useColor = Color(0.5, 0.5, 0.5, 0.4)
        // set red if can't afford
        elseif PlayerUI_GetPlayerResources() < BuyMenus_GetUpgradeCost(item.TechId) then
           useColor = Color(1, 0, 0, 1)
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
    self.itemName:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.itemName:SetPosition(Vector(GUIMarineBuyMenu.kItemNameOffsetX , GUIMarineBuyMenu.kItemNameOffsetY , 0))
    self.itemName:SetTextAlignmentX(GUIItem.Align_Min)
    self.itemName:SetTextAlignmentY(GUIItem.Align_Min)
    self.itemName:SetColor(GUIMarineBuyMenu.kTextColor)
    self.itemName:SetText("no selection")
    
    self.content:AddChild(self.itemName)
    
    self.portrait = GetGUIManager():CreateGraphicItem()
    self.portrait:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.portrait:SetPosition(Vector(-GUIMarineBuyMenu.kBigIconSize.x/2, GUIMarineBuyMenu.kBigIconOffset, 0))
    self.portrait:SetSize(GUIMarineBuyMenu.kBigIconSize)
    self.portrait:SetTexture(GUIMarineBuyMenu.kBigIconTexture)
    self.portrait:SetTexturePixelCoordinates(GetBigIconPixelCoords(kTechId.Axe))
    self.portrait:SetIsVisible(false)
    self.content:AddChild(self.portrait)
    
    self.itemDescription = GetGUIManager():CreateTextItem()
    self.itemDescription:SetFontName(GUIMarineBuyMenu.kDescriptionFontName)
    //self.itemDescription:SetFontIsBold(true)
    self.itemDescription:SetFontSize(GUIMarineBuyMenu.kDescriptionFontSize)
    self.itemDescription:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.itemDescription:SetPosition(Vector(-GUIMarineBuyMenu.kItemDescriptionSize.x / 2, GUIMarineBuyMenu.kItemDescriptionOffsetY, 0))
    self.itemDescription:SetTextAlignmentX(GUIItem.Align_Min)
    self.itemDescription:SetTextAlignmentY(GUIItem.Align_Min)
    self.itemDescription:SetColor(GUIMarineBuyMenu.kTextColor)
    self.itemDescription:SetTextClipped(true, GUIMarineBuyMenu.kItemDescriptionSize.x - 2* GUIMarineBuyMenu.kPadding, GUIMarineBuyMenu.kItemDescriptionSize.y - GUIMarineBuyMenu.kPadding)
    
    self.content:AddChild(self.itemDescription)
    
end

function GUIMarineBuyMenu:_UpdateContent(deltaTime)

    local techId = self.hoverItem
    if not self.hoverItem then
        techId = self.selectedItem
    end
    
    if techId then
    
        local unlocked = self:_GetIsUnlocked(techId)
        local alreadyhas = PlayerUI_GetHasItem(techId)        
        local itemCost = BuyMenus_GetUpgradeCost(techId)
        local canAfford = PlayerUI_GetPlayerResources() >= itemCost

        local color = Color(1, 1, 1, 1)
        if not canAfford and unlocked then
            color = Color(1, 0, 0, 1)
        elseif not unlocked then
            // Make it clear that we can't buy this
            color = Color(0.5, 0.5, 0.5, 1)
        elseif alreadyhas then
            color = Color(0, 216/255, 1, 1)
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
    //self.resourceDisplay:SetColor(GUIMarineBuyMenu.kTextColor)
    
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
                    MarineBuy_OnClose()
                end
                
                return true, true
                
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