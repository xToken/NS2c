
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICommanderTooltip.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying a tooltip for the commander when mousing over the UI.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUICommanderTooltip' (GUIScript)

GUICommanderTooltip.kAlienBackgroundTexture = "ui/alien_commander_textures.dds"
GUICommanderTooltip.kMarineBackgroundTexture = "ui/marine_commander_textures.dds"

GUICommanderTooltip.kBackgroundTopCoords = { X1 = 0, Y1 = 411, X2 = 461, Y2 = 478 }
GUICommanderTooltip.kBackgroundTopHeight = GUICommanderTooltip.kBackgroundTopCoords.Y2 - GUICommanderTooltip.kBackgroundTopCoords.Y1
GUICommanderTooltip.kBackgroundCenterCoords = { X1 = 0, Y1 = 478, X2 = 461, Y2 = 578 }
GUICommanderTooltip.kBackgroundBottomCoords = { X1 = 0, Y1 = 578, X2 = 461, Y2 = 578 + 67 }
GUICommanderTooltip.kBackgroundBottomHeight = GUICommanderTooltip.kBackgroundBottomCoords.Y2 - GUICommanderTooltip.kBackgroundBottomCoords.Y1

GUICommanderTooltip.kBackgroundExtraXOffset = GUIScale(26)
GUICommanderTooltip.kBackgroundExtraYOffset = GUIScale(28)

GUICommanderTooltip.kTextFontSize = 16
GUICommanderTooltip.kTextXOffset = 30
GUICommanderTooltip.kTextYOffset = GUICommanderTooltip.kTextFontSize + 10

GUICommanderTooltip.kHotkeyFontSize = 16
GUICommanderTooltip.kHotkeyXOffset = 5

GUICommanderTooltip.kResourceIconSize = 32
GUICommanderTooltip.kResourceIconTextureWidth = 32
GUICommanderTooltip.kResourceIconTextureHeight = 32
GUICommanderTooltip.kResourceIconXOffset = -40
GUICommanderTooltip.kResourceIconYOffset = 20

GUICommanderTooltip.kResourceIconTextureCoordinates = { }
// Team coordinates.
table.insert(GUICommanderTooltip.kResourceIconTextureCoordinates, { X1 = 192, Y1 = 363, X2 = 240, Y2 = 411}) // team res
// Personal coordinates.
table.insert(GUICommanderTooltip.kResourceIconTextureCoordinates, { X1 = 144, Y1 = 363, X2 = 192, Y2 = 411}) // personal res
// Energy coordinates.
table.insert(GUICommanderTooltip.kResourceIconTextureCoordinates, { X1 = 192, Y1 = 363, X2 = 240, Y2 = 411}) // energy
// Ammo coordinates.
table.insert(GUICommanderTooltip.kResourceIconTextureCoordinates, { X1 = 192, Y1 = 363, X2 = 240, Y2 = 411}) // ammo (no texture and not used)

GUICommanderTooltip.kResourceColors = { Color(0, 1, 0, 1), Color(0.2, 0.4, 1, 1), Color(1, 0, 1, 1) }

GUICommanderTooltip.kCostFontSize = 16
GUICommanderTooltip.kCostXOffset = -2

GUICommanderTooltip.kRequiresFontSize = 16
GUICommanderTooltip.kRequiresTextMaxHeight = 32
GUICommanderTooltip.kRequiresYOffset = 10

GUICommanderTooltip.kEnablesFontSize = 16
GUICommanderTooltip.kEnablesTextMaxHeight = 64
GUICommanderTooltip.kEnablesYOffset = 10

GUICommanderTooltip.kInfoFontSize = 16
GUICommanderTooltip.kInfoTextMaxHeight = 48
GUICommanderTooltip.kInfoYOffset = 10

local kBackgroundNoiseTexture = "ui/alien_commander_bg_smoke.dds"
local kSmokeyBackgroundSize = GUIScale(Vector(400, 640, 0))

function GUICommanderTooltip:Initialize()

    self.textureName = GUICommanderTooltip.kMarineBackgroundTexture
    
    self.tooltipWidth = 466 * kCommanderGUIsGlobalScale
    self.tooltipHeight = 40
    
    self.tooltipX = 0
    self.tooltipY = -60
    
    self.registeredScripts = {}
    
    self:InitializeBackground()
    
    local fontName = "fonts/AgencyFB_small.fnt"
    
    self.text = GUIManager:CreateTextItem()
    self.text:SetFontSize(GUICommanderTooltip.kTextFontSize)
    self.text:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.text:SetTextAlignmentX(GUIItem.Align_Min)
    self.text:SetTextAlignmentY(GUIItem.Align_Min)
    self.text:SetPosition(Vector(GUICommanderTooltip.kTextXOffset, GUICommanderTooltip.kTextYOffset, 0))
    self.text:SetColor(Color(1, 1, 1, 1))
    self.text:SetFontIsBold(true)
    self.text:SetFontName(fontName)
    self.background:AddChild(self.text)
    
    self.hotkey = GUIManager:CreateTextItem()
    self.hotkey:SetFontSize(GUICommanderTooltip.kHotkeyFontSize)
    self.hotkey:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.hotkey:SetTextAlignmentX(GUIItem.Align_Min)
    self.hotkey:SetTextAlignmentY(GUIItem.Align_Min)
    self.hotkey:SetPosition(Vector(GUICommanderTooltip.kHotkeyXOffset, 0, 0))
    self.hotkey:SetColor(Color(1, 1, 1, 1))
    self.hotkey:SetFontIsBold(true)
    self.hotkey:SetFontName(fontName)
    self.text:AddChild(self.hotkey)
    
    self.resourceIcon = GUIManager:CreateGraphicItem()
    self.resourceIcon:SetSize(Vector(GUICommanderTooltip.kResourceIconSize, GUICommanderTooltip.kResourceIconSize, 0))
    self.resourceIcon:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.resourceIcon:SetPosition(Vector(-GUICommanderTooltip.kResourceIconSize + GUICommanderTooltip.kResourceIconXOffset, GUICommanderTooltip.kResourceIconYOffset, 0))
    self.resourceIcon:SetTexture(self.textureName)
    self.resourceIcon:SetIsVisible(false)
    self.background:AddChild(self.resourceIcon)
    
    self.cost = GUIManager:CreateTextItem()
    self.cost:SetFontSize(GUICommanderTooltip.kCostFontSize)
    self.cost:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.cost:SetTextAlignmentX(GUIItem.Align_Max)
    self.cost:SetTextAlignmentY(GUIItem.Align_Center)
    self.cost:SetPosition(Vector(GUICommanderTooltip.kCostXOffset, GUICommanderTooltip.kResourceIconSize / 2, 0))
    self.cost:SetColor(Color(1, 1, 1, 1))
    self.cost:SetFontIsBold(true)
    self.cost:SetFontName(fontName)
    self.resourceIcon:AddChild(self.cost)
    
    self.requires = GUIManager:CreateTextItem()
    self.requires:SetFontSize(GUICommanderTooltip.kRequiresFontSize)
    self.requires:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.requires:SetTextAlignmentX(GUIItem.Align_Min)
    self.requires:SetTextAlignmentY(GUIItem.Align_Min)
    self.requires:SetColor(Color(1, 0, 0, 1))
    self.requires:SetText(Locale.ResolveString("COMM_REQUIRES"))
    self.requires:SetFontIsBold(true)
    self.requires:SetIsVisible(false)
    self.requires:SetFontName(fontName)
    self.background:AddChild(self.requires)
    
    self.requiresInfo = GUIManager:CreateTextItem()
    self.requiresInfo:SetFontSize(GUICommanderTooltip.kRequiresFontSize)
    self.requiresInfo:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.requiresInfo:SetTextAlignmentX(GUIItem.Align_Min)
    self.requiresInfo:SetTextAlignmentY(GUIItem.Align_Min)
    self.requiresInfo:SetPosition(Vector(0, 0, 0))
    self.requiresInfo:SetColor(Color(1, 1, 1, 1))
    self.requiresInfo:SetFontIsBold(true)
    self.requiresInfo:SetTextClipped(true, self.tooltipWidth - GUICommanderTooltip.kTextXOffset * 2, GUICommanderTooltip.kRequiresTextMaxHeight)
    self.requiresInfo:SetFontName(fontName)
    self.requires:AddChild(self.requiresInfo)
    
    self.enables = GUIManager:CreateTextItem()
    self.enables:SetFontSize(GUICommanderTooltip.kEnablesFontSize)
    self.enables:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.enables:SetTextAlignmentX(GUIItem.Align_Min)
    self.enables:SetTextAlignmentY(GUIItem.Align_Min)
    self.enables:SetColor(Color(0, 1, 0, 1))
    self.enables:SetText(Locale.ResolveString("COMM_ENABLES"))
    self.enables:SetFontIsBold(true)
    self.enables:SetIsVisible(false)
    self.enables:SetFontName(fontName)
    self.background:AddChild(self.enables)
    
    self.enablesInfo = GUIManager:CreateTextItem()
    self.enablesInfo:SetFontSize(GUICommanderTooltip.kEnablesFontSize)
    self.enablesInfo:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.enablesInfo:SetTextAlignmentX(GUIItem.Align_Min)
    self.enablesInfo:SetTextAlignmentY(GUIItem.Align_Min)
    self.enablesInfo:SetPosition(Vector(0, 0, 0))
    self.enablesInfo:SetColor(Color(1, 1, 1, 1))
    self.enablesInfo:SetFontIsBold(true)
    self.enablesInfo:SetTextClipped(true, self.tooltipWidth - GUICommanderTooltip.kTextXOffset * 2, GUICommanderTooltip.kEnablesTextMaxHeight)
    self.enablesInfo:SetFontName(fontName)
    self.enables:AddChild(self.enablesInfo)
    
    self.info = GUIManager:CreateTextItem()
    self.info:SetFontSize(GUICommanderTooltip.kInfoFontSize)
    self.info:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.info:SetTextAlignmentX(GUIItem.Align_Min)
    self.info:SetTextAlignmentY(GUIItem.Align_Min)
    self.info:SetColor(Color(1, 1, 1, 1))
    self.info:SetFontIsBold(true)
    self.info:SetTextClipped(true, self.tooltipWidth - GUICommanderTooltip.kTextXOffset * 2, GUICommanderTooltip.kInfoTextMaxHeight)
    self.info:SetIsVisible(false)
    self.info:SetFontName(fontName)
    self.background:AddChild(self.info)
    
end

function GUICommanderTooltip:InitializeBackground()

    self.backgroundTop = GUIManager:CreateGraphicItem()
    self.backgroundTop:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.backgroundTop:SetSize(Vector(self.tooltipWidth, self.tooltipHeight, 0))
    self.backgroundTop:SetTexture(self.textureName)
    GUISetTextureCoordinatesTable(self.backgroundTop, GUICommanderTooltip.kBackgroundTopCoords)
    
    self.background = self.backgroundTop
    
    self.backgroundCenter = GUIManager:CreateGraphicItem()
    self.backgroundCenter:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.backgroundCenter:SetSize(Vector(self.tooltipWidth, self.tooltipHeight, 0))
    self.backgroundCenter:SetTexture(self.textureName)
    GUISetTextureCoordinatesTable(self.backgroundCenter, GUICommanderTooltip.kBackgroundCenterCoords)
    self.backgroundTop:AddChild(self.backgroundCenter)
    
    self.backgroundBottom = GUIManager:CreateGraphicItem()
    self.backgroundBottom:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.backgroundBottom:SetSize(Vector(self.tooltipWidth, GUICommanderTooltip.kBackgroundBottomHeight, 0))
    self.backgroundBottom:SetTexture(self.textureName)
    GUISetTextureCoordinatesTable(self.backgroundBottom, GUICommanderTooltip.kBackgroundBottomCoords)
    self.backgroundCenter:AddChild(self.backgroundBottom)

end

function GUICommanderTooltip:InitSmokeyBackground()

    self.smokeyBackground = GUIManager:CreateGraphicItem()
    self.smokeyBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.smokeyBackground:SetSize(kSmokeyBackgroundSize)
    self.smokeyBackground:SetPosition(Vector(-kSmokeyBackgroundSize.x * 0.5, -kSmokeyBackgroundSize.y * 0.3, 0))
    self.smokeyBackground:SetShader("shaders/GUISmoke.surface_shader")
    self.smokeyBackground:SetTexture("ui/alien_logout_smkmask.dds")
    self.smokeyBackground:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
    self.smokeyBackground:SetFloatParameter("correctionX", 0.5)
    self.smokeyBackground:SetFloatParameter("correctionY", 0.8)
    
    self.background:AddChild(self.smokeyBackground)

end

function GUICommanderTooltip:Uninitialize()

    // Everything is attached to the background so uninitializing it will destroy all items.
    if self.background then
        GUI.DestroyItem(self.background)
    end
    
end

function GUICommanderTooltip:UpdateData(text, hotkey, costNumber, requires, enables, info, typeNumber)

    local totalTextHeight = self:CalculateTotalTextHeight(text, requires, enables, info)
    self:UpdateSizeAndPosition(totalTextHeight)
    
    self.text:SetText(text)
    self.hotkey:SetText("( " .. hotkey .. " )")
    self.hotkey:SetIsVisible(string.len(hotkey) > 0)
    // typeNumber may be 0 if the tech data hasn't been fully synced to the Client yet.
    if costNumber > 0 and typeNumber ~= 0 then
    
        self.resourceIcon:SetIsVisible(true)
        GUISetTextureCoordinatesTable(self.resourceIcon, GUICommanderTooltip.kResourceIconTextureCoordinates[typeNumber])
        self.cost:SetText(ToString(costNumber))
        
    else
        self.resourceIcon:SetIsVisible(false)
    end
    
    local nextYPosition = self.text:GetPosition().y + self.text:GetTextHeight(text)
    if string.len(requires) > 0 then
        self.requires:SetIsVisible(true)
        nextYPosition = nextYPosition + GUICommanderTooltip.kRequiresYOffset
        self.requires:SetPosition(Vector(GUICommanderTooltip.kTextXOffset, nextYPosition, 0))
        self.requiresInfo:SetText(requires)
    else
        self.requires:SetIsVisible(false)
    end
    
    if self.requires:GetIsVisible() then
        nextYPosition = self.requires:GetPosition().y + self.requires:GetTextHeight(self.requires:GetText()) + self.requiresInfo:GetTextHeight(self.requiresInfo:GetText())
    end
    
    if string.len(enables) > 0 then
        nextYPosition = nextYPosition + GUICommanderTooltip.kEnablesYOffset
        self.enables:SetIsVisible(true)
        self.enables:SetPosition(Vector(GUICommanderTooltip.kTextXOffset, nextYPosition, 0))
        self.enablesInfo:SetText(enables)
    else
        self.enables:SetIsVisible(false)
    end
    
    if self.enables:GetIsVisible() then
    
        local enablesText = self.enablesInfo:GetText()
        if string.len(enablesText) > 0 then
            nextYPosition = self.enables:GetPosition().y + self.enables:GetTextHeight(self.enables:GetText()) + self.enablesInfo:GetTextHeight(self.enablesInfo:GetText())
        end
        
    end

    if string.len(info) > 0 then
        nextYPosition = nextYPosition + GUICommanderTooltip.kInfoYOffset
        self.info:SetIsVisible(true)
        self.info:SetPosition(Vector(GUICommanderTooltip.kTextXOffset, nextYPosition, 0))
        self.info:SetText(info)
    else
        self.info:SetIsVisible(false)
    end
    
end

// Determine the height of the tooltip based on all the text inside of it.
function GUICommanderTooltip:CalculateTotalTextHeight(text, requires, enables, info)

    local totalHeight = 0
    
    if string.len(text) > 0 then
        totalHeight = totalHeight + self.text:GetTextHeight(text)
    end
    
    if string.len(requires) > 0 then
        totalHeight = totalHeight + self.requiresInfo:GetTextHeight(requires)
    end
    
    if string.len(enables) > 0 then
        totalHeight = totalHeight + self.enablesInfo:GetTextHeight(enables)
    end
    
    if string.len(info) > 0 then
        totalHeight = totalHeight + self.info:GetTextHeight(info)
    end
    
    return totalHeight

end

function GUICommanderTooltip:UpdateSizeAndPosition(totalTextHeight)
    
    local topAndBottomHeight = GUICommanderTooltip.kBackgroundTopHeight - GUICommanderTooltip.kBackgroundBottomHeight
    local adjustedHeight = self.tooltipHeight + totalTextHeight - topAndBottomHeight
    self.backgroundCenter:SetSize(Vector(self.tooltipWidth, adjustedHeight, 0))
    
    local adjustedY = self.tooltipY - self.tooltipHeight - totalTextHeight - topAndBottomHeight - GUICommanderTooltip.kBackgroundExtraYOffset
    self.background:SetPosition(Vector(self.tooltipX + GUICommanderTooltip.kBackgroundExtraXOffset, adjustedY, 0))

end

function GUICommanderTooltip:SetIsVisible(setIsVisible)

    self.background:SetIsVisible(setIsVisible)

end

function GUICommanderTooltip:GetBackground()
    return self.background
end

function GUICommanderTooltip:Register(script)
    table.insertunique(self.registeredScripts, script)
end

function GUICommanderTooltip:Update(deltaTime)

    local tooltipData = nil

    for _, script in ipairs(self.registeredScripts) do
    
        if not tooltipData then
            tooltipData = script:GetTooltipData()
        end
    
    end

    if tooltipData then
    
        self:UpdateData(tooltipData.text, tooltipData.hotKey, tooltipData.costNumber, tooltipData.requires, tooltipData.enabled, tooltipData.info, tooltipData.resourceType)
        self.background:SetIsVisible(true)
    
    else
        self.background:SetIsVisible(false)
    end

end

