-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUICommanderButtons.lua
--
-- Created by: Brian Cronin (brianc@unknownworlds.com)
--
-- Manages the right commander panel used to display buttons for commander actions.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Removed idle workers panel.

Script.Load("lua/GUIBorderBackground.lua")
Script.Load("lua/GUICommanderTooltip.lua")
Script.Load("lua/GUIDial.lua")

class 'GUICommanderButtons' (GUIScript)

GUICommanderButtons.kButtonStatusDisabled = { Id = 0, Color = Color(0, 0, 0, 0), Visible = false }
GUICommanderButtons.kButtonStatusEnabled = { Id = 1, Color = Color(1, 1, 1, 1), Visible = true }
GUICommanderButtons.kButtonStatusRed = { Id = 2, Color = Color(1, 0, 0, 1), Visible = true }
GUICommanderButtons.kButtonStatusOff = { Id = 3, Color = Color(0.45, 0.45, 0.45, 1), Visible = true }
GUICommanderButtons.kButtonStatusPassive = { Id = 4, Color = Color(1, 1, 1, 1), Visible = true }
GUICommanderButtons.kButtonStatusData = { }
GUICommanderButtons.kButtonStatusData[GUICommanderButtons.kButtonStatusDisabled.Id] = GUICommanderButtons.kButtonStatusDisabled
GUICommanderButtons.kButtonStatusData[GUICommanderButtons.kButtonStatusEnabled.Id] = GUICommanderButtons.kButtonStatusEnabled
GUICommanderButtons.kButtonStatusData[GUICommanderButtons.kButtonStatusRed.Id] = GUICommanderButtons.kButtonStatusRed
GUICommanderButtons.kButtonStatusData[GUICommanderButtons.kButtonStatusOff.Id] = GUICommanderButtons.kButtonStatusOff
GUICommanderButtons.kButtonStatusData[GUICommanderButtons.kButtonStatusPassive.Id] = GUICommanderButtons.kButtonStatusPassive

local kButtonBackgroundTextures =
{
    [kMarineTeamType] = "ui/marine_buildmenu_buttonbg.dds",
    [kAlienTeamType] = "ui/alien_buildmenu_buttonbg.dds"
}

local kHighlightTexture =
{
    [kMarineTeamType] = "ui/marine_buildmenu_highlight.dds",
    [kAlienTeamType] = "ui/alien_buildmenu_highlight.dds"
}

GUICommanderButtons.kBackgroundTextureCoords = { X1 = 0, Y1 = 0, X2 = 466, Y2 = 363 }
GUICommanderButtons.kMarineTabBackgroundTexture = "ui/marine_commander_tabs.dds"
GUICommanderButtons.kAlienTabBackgroundTexture = "ui/alien_commander_tabs.dds"

GUICommanderButtons.kFrameTextureCoords = { 0, 0, 466, 363 }

GUICommanderButtons.kMarineTabTextureCoords = { }
GUICommanderButtons.kMarineTabTextureCoords.TopNormal = { X1 = 7, Y1 = 340, X2 = 106, Y2 = 381 }
GUICommanderButtons.kMarineTabTextureCoords.BottomNormal = { X1 = 7, Y1 = 391, X2 = 106, Y2 = 400 }
GUICommanderButtons.kMarineTabTextureCoords.TopRollover = { X1 = 117, Y1 = 340, X2 = 216, Y2 = 381 }
GUICommanderButtons.kMarineTabTextureCoords.BottomRollover = { X1 = 117, Y1 = 391, X2 = 216, Y2 = 400 }
GUICommanderButtons.kMarineTabTextureCoords.TopSelected = { X1 = 226, Y1 = 340, X2 = 325, Y2 = 381 }
GUICommanderButtons.kMarineTabTextureCoords.BottomSelected = { X1 = 226, Y1 = 391, X2 = 325, Y2 = 400 }
GUICommanderButtons.kMarineTabTextureCoords.ConnectorMiddle = { X1 = 338, Y1 = 345, X2 = 447, Y2 = 360 }
GUICommanderButtons.kMarineTabTextureCoords.ConnectorSide = { X1 = 338, Y1 = 370, X2 = 447, Y2 = 385 }

GUICommanderButtons.kTabEnabledColor = Color(1,1,1,1)
GUICommanderButtons.kTabDisabledColor = Color(0.35, 0.35, 0.35, 1)

GUICommanderButtons.kTabFontSize = 18
GUICommanderButtons.kTabAlpha = 0.75

GUICommanderButtons.kCooldownColor = Color(1, 1, 1, 0.3)

local kBackgroundNoiseTexture = "ui/alien_commander_bg_smoke.dds"
local kSmokeyBackgroundSize
local kHealthCircleSettings

local function UpdateItemsGUIScale(self)
    
    GUICommanderButtons.kButtonWidth = (CommanderUI_MenuButtonWidth() + 18) * GUIScale(kCommanderGUIsGlobalScale)
    GUICommanderButtons.kButtonHeight = (CommanderUI_MenuButtonHeight() + 18) * GUIScale(kCommanderGUIsGlobalScale)
    GUICommanderButtons.kButtonXOffset = 40 * GUIScale(kCommanderGUIsGlobalScale)
    GUICommanderButtons.kButtonYOffset = 58 * GUIScale(kCommanderGUIsGlobalScale)

    kHealthCircleSettings =
    {
        [kMarineTeamType] = {
            BackgroundWidth = GUICommanderButtons.kButtonWidth,
            BackgroundHeight = GUICommanderButtons.kButtonHeight,
            BackgroundAnchorX = GUIItem.Left,
            BackgroundAnchorY = GUIItem.Bottom,
            BackgroundOffset = Vector(0, 0, 0),
            BackgroundTextureName = "ui/marine_command_cooldown.dds",
            BackgroundTextureX1 = 0,
            BackgroundTextureY1 = 0,
            BackgroundTextureX2 = 128,
            BackgroundTextureY2 = 128,
            ForegroundTextureName = "ui/marine_command_cooldown.dds",
            ForegroundTextureWidth = 128,
            ForegroundTextureHeight = 128,
            ForegroundTextureX1 = 128,
            ForegroundTextureY1 = 0,
            ForegroundTextureX2 = 256,
            ForegroundTextureY2 = 128,
            InheritParentAlpha = false,
        },

        [kAlienTeamType] = {
            BackgroundWidth = GUICommanderButtons.kButtonWidth,
            BackgroundHeight = GUICommanderButtons.kButtonHeight,
            BackgroundAnchorX = GUIItem.Left,
            BackgroundAnchorY = GUIItem.Bottom,
            BackgroundOffset = Vector(0, 0, 0),
            BackgroundTextureName = "ui/alien_command_cooldown.dds",
            BackgroundTextureX1 = 0,
            BackgroundTextureY1 = 0,
            BackgroundTextureX2 = 128,
            BackgroundTextureY2 = 128,
            ForegroundTextureName = "ui/alien_command_cooldown.dds",
            ForegroundTextureWidth = 128,
            ForegroundTextureHeight = 128,
            ForegroundTextureX1 = 128,
            ForegroundTextureY1 = 0,
            ForegroundTextureX2 = 256,
            ForegroundTextureY2 = 128,
            InheritParentAlpha = false,
        }  
    }

    GUICommanderButtons.kBackgroundWidth = 466 * GUIScale(kCommanderGUIsGlobalScale)
    GUICommanderButtons.kBackgroundHeight = 363 * GUIScale(kCommanderGUIsGlobalScale)

    -- The background is offset from the edge of the screen.
    GUICommanderButtons.kBackgroundOffset = GUIScale(4)

    -- Used just for testing.
    GUICommanderButtons.kExtraYOffset = 0

    GUICommanderButtons.kBuildMenuTextureWidth = GUIScale(80)
    GUICommanderButtons.kBuildMenuTextureHeight = GUIScale(80)

    -- Also used for player alerts icon
    GUICommanderButtons.kIdleWorkersSize = GUIScale(48)
    GUICommanderButtons.kIdleWorkersXOffset = GUIScale(5)
    GUICommanderButtons.kIdleWorkersFontSize = GUIScale(20)

    GUICommanderButtons.kPlayerAlertX = -GUIScale(2) * (GUICommanderButtons.kIdleWorkersXOffset + GUICommanderButtons.kIdleWorkersSize)

    GUICommanderButtons.kSelectAllPlayersX = GUIScale(10)
    GUICommanderButtons.kSelectAllPlayersY = GUIScale(90)
    GUICommanderButtons.kSelectAllPlayersSize = GUIScale(48)

    kSmokeyBackgroundSize = GUIScale(Vector(480, 640, 0))

end

function GUICommanderButtons:OnResolutionChanged(oldX, oldY, newX, newY)
    self:Uninitialize()
    self:Initialize()
end

function GUICommanderButtons:Initialize()

    UpdateItemsGUIScale(self)
    
    self.teamType = PlayerUI_GetTeamType()
    self.backgroundTextureName = self:GetBackgroundTextureName()
    
    -- The Marine buttons have tabs at the top for the first row of buttons.
    self.tabs = { }
    -- The rest of the non-tab buttons are stored here.
    self.bottomButtons = { }
    self.buttonbackground = { }
    -- All buttons are always stored here for Marine and Aliens.
    self.buttons = { }
    self.cooldowns = { }

    self.background = GUIManager:CreateGraphicItem()

    if CommanderUI_IsAlienCommander() then
        self:InitializeAlienBackground()
    else
        self:InitializeMarineBackground()
    end
    
    self.timeLastErrorMessage = 0

    self:InitializeButtons()
    
    self:InitializePlayerAlertIcon()
    
    self:InitializeSelectAllPlayersIcon()
    
    self.mousePressed = { LMB = { Down = nil, X = 0, Y = 0 }, RMB = { Down = nil, X = 0, Y = 0 } }
    
    self.lastPressedTab = nil
    
end

function GUICommanderButtons:InitializeAlienBackground()

    self.background:SetLayer(kGUILayerCommanderHUD)
    self.background:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.background:SetSize(Vector(GUICommanderButtons.kBackgroundWidth, GUICommanderButtons.kBackgroundHeight, 0))
    local posX = -GUICommanderButtons.kBackgroundWidth - GUICommanderButtons.kBackgroundOffset
    local posY = -GUICommanderButtons.kBackgroundHeight - GUICommanderButtons.kBackgroundOffset - GUICommanderButtons.kExtraYOffset
    self.background:SetPosition(Vector(posX, posY, 0))
    self.background:SetColor(Color(0,0,0,0))
    self.background:SetTexturePixelCoordinates( GUIUnpackCoords(GUICommanderButtons.kFrameTextureCoords) )

    self.smokeyBackground = GUIManager:CreateGraphicItem()
    self.smokeyBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.smokeyBackground:SetSize(kSmokeyBackgroundSize)
    self.smokeyBackground:SetPosition(-kSmokeyBackgroundSize * .5)
    self.smokeyBackground:SetTexture("ui/alien_commander_smkmask.dds")
    self.smokeyBackground:SetShader("shaders/GUISmoke.surface_shader")
    self.smokeyBackground:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
    self.smokeyBackground:SetFloatParameter("correctionX", 1)
    self.smokeyBackground:SetFloatParameter("correctionY", 1.3)
    
    self.background:AddChild(self.smokeyBackground)
    
    self.tabBackground = GUIManager:CreateGraphicItem()
    self.tabBackground:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.tabBackground:SetSize(Vector(GUICommanderButtons.kBackgroundWidth, GUICommanderButtons.kBackgroundHeight, 0))
    self.tabBackground:SetTexture(GUICommanderButtons.kAlienTabBackgroundTexture)
    self.background:AddChild(self.tabBackground)
    
end

function GUICommanderButtons:InitializeMarineBackground()

    self.background:SetLayer(kGUILayerCommanderHUD)
    self.background:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    self.background:SetSize(Vector(GUICommanderButtons.kBackgroundWidth, GUICommanderButtons.kBackgroundHeight, 0))
    
    local posX = -GUICommanderButtons.kBackgroundWidth - GUICommanderButtons.kBackgroundOffset
    local posY = -GUICommanderButtons.kBackgroundHeight - GUICommanderButtons.kBackgroundOffset - GUICommanderButtons.kExtraYOffset
    self.background:SetPosition(Vector(posX, posY, 0))
    self.background:SetTexture(self.backgroundTextureName)
    self.background:SetTexturePixelCoordinates( GUIUnpackCoords(GUICommanderButtons.kFrameTextureCoords) )
    
    self.tabBackground = GUIManager:CreateGraphicItem()
    self.tabBackground:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.tabBackground:SetSize(Vector(GUICommanderButtons.kBackgroundWidth, GUICommanderButtons.kBackgroundHeight, 0))
    self.tabBackground:SetTexture(GUICommanderButtons.kMarineTabBackgroundTexture)
    self.background:AddChild(self.tabBackground)

end

function GUICommanderButtons:InitializeHighlighter()

    self.highlightItem = GUIManager:CreateGraphicItem()
    self.highlightItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.highlightItem:SetSize(Vector(GUICommanderButtons.kButtonWidth, GUICommanderButtons.kButtonHeight, 0))
    self.highlightItem:SetTexture(kHighlightTexture[self.teamType])
    local textureWidth, textureHeight = CommanderUI_MenuImageSize()
    local buttonWidth = CommanderUI_MenuButtonWidth()
    local buttonHeight = CommanderUI_MenuButtonHeight()
    self.highlightItem:SetIsVisible(false)

end

local function GetPixelCoordsForTab(index)

    if not index then
        index = 1
    end    

    local pixelWidth = GUICommanderButtons.kFrameTextureCoords[3] - GUICommanderButtons.kFrameTextureCoords[1]
    local pixelHeight = GUICommanderButtons.kFrameTextureCoords[4] - GUICommanderButtons.kFrameTextureCoords[2]
    
    local x1 = (index - 1) * pixelWidth
    local x2 = index * pixelWidth
    local y1 = 0
    local y2 = pixelHeight
    
    return x1, y1, x2, y2


end

local function ButtonPressed(self, index)

    if CommanderUI_MenuButtonRequiresTarget(index) then
        self:SetTargetedButton(index)
    end
    
    CommanderUI_MenuButtonAction(index)
    
    self:SelectTab(index)
    
end

local function UpdateTabs(self)

    -- Assume no tabs are pressed or highlighted.
    for t = 1, #self.tabs do
    
        local tabTable = self.tabs[t]

        if self.lastPressedTab ~= tabTable then        
            tabTable.TopItem:SetColor(GUICommanderButtons.kTabDisabledColor)            
        else        
            tabTable.TopItem:SetColor(kIconColors[self.teamType])            
        end
        
        local buttonWidth = CommanderUI_MenuButtonWidth()
        local buttonHeight = CommanderUI_MenuButtonHeight()
        local buttonXOffset, buttonYOffset = CommanderUI_MenuButtonOffset(t)

        if buttonXOffset and buttonYOffset then
            local textureXOffset = buttonXOffset * buttonWidth
            local textureYOffset = buttonYOffset * buttonHeight
            tabTable.TopItem:SetTexturePixelCoordinates(textureXOffset, textureYOffset, textureXOffset + buttonWidth, textureYOffset + buttonHeight)
        end
        
        local tooltipData = CommanderUI_MenuButtonTooltip(t)
        if tooltipData[1] then
            tabTable.TextItem:SetText(tooltipData[1])
        end
        
    end
    
    -- Select the first tab if no tab has been selected yet.
    -- This will cause the tab to be selected on the server as well.
    if not self.selectedTabIndex then
        ButtonPressed(self, self:ConvertTechIdToTabIndex(kTechId.BuildMenu))
    end
    
    self.tabBackground:SetTexturePixelCoordinates( GetPixelCoordsForTab(self.selectedTabIndex) )
    
end

function GUICommanderButtons:SharedInitializeButtons(settingsTable)

    self.numberOfTabs = settingsTable.NumberOfTabs
    -- Tab row.
    for t = 1, self.numberOfTabs do
    
        -- Top tab item first.
        local topItem = GUIManager:CreateGraphicItem()
        topItem:SetAnchor(GUIItem.Left, GUIItem.Top)
        
        local xPos = GUICommanderButtons.kButtonXOffset + (((t - 1) % 4) * (GUICommanderButtons.kButtonWidth) )
        local yPos = settingsTable.TabYOffset
        
        if t == 4 then
            topItem:SetSize(Vector(GUICommanderButtons.kButtonWidth * 0.7, GUICommanderButtons.kButtonHeight * 0.7, 0))
            topItem:SetPosition(Vector(xPos + GUICommanderButtons.kButtonWidth * 0.15, yPos + GUICommanderButtons.kButtonHeight * 0.15, 0))
            topItem:SetTexture("ui/buildmenu.dds")
        else
            topItem:SetSize(Vector(GUICommanderButtons.kButtonWidth, GUICommanderButtons.kButtonHeight, 0))
            topItem:SetPosition(Vector(xPos, yPos, 0))
            topItem:SetTexture("ui/buildmenu.dds")
        end
        topItem:SetColor(kIconColors[self.teamType])
        self.background:AddChild(topItem)
        
        -- Tab text.
        local textItem = GUIManager:CreateTextItem()
        textItem:SetFontSize(GUICommanderButtons.kTabFontSize)
        textItem:SetAnchor(GUIItem.Middle, GUIItem.Center)
        textItem:SetTextAlignmentX(GUIItem.Align_Center)
        textItem:SetTextAlignmentY(GUIItem.Align_Center)
        textItem:SetColor(Color(1, 1, 1, 1))
        textItem:SetFontIsBold(true)
        textItem:SetIsVisible(false)
        topItem:AddChild(textItem)
        
        local tabItem = { TopItem = topItem, TextItem = textItem }
        table.insert(self.buttons, topItem)
        table.insert(self.tabs, tabItem)

    end
    
    UpdateTabs(self)
    
    -- Button rows.
    for i = 1, settingsTable.NumberOfButtons do
    
        local backgroundItem = GUIManager:CreateGraphicItem()
        backgroundItem:SetAnchor(GUIItem.Left, GUIItem.Top)
        backgroundItem:SetSize(Vector(GUICommanderButtons.kButtonWidth, GUICommanderButtons.kButtonHeight, 0))
        local xPos = ((i - 1) % settingsTable.NumberOfColumns) * GUICommanderButtons.kButtonWidth
        local yPos = math.floor(((i - 1) / settingsTable.NumberOfColumns)) * GUICommanderButtons.kButtonHeight
        yPos = yPos + settingsTable.ButtonYOffset + settingsTable.TabTopHeight + settingsTable.TabBottomHeight
        backgroundItem:SetPosition(Vector(xPos + GUICommanderButtons.kButtonXOffset, yPos + GUICommanderButtons.kButtonYOffset, 0))
        backgroundItem:SetTexture(kButtonBackgroundTextures[self.teamType])
        self.background:AddChild(backgroundItem)
    
        local buttonItem = GUIManager:CreateGraphicItem()
        buttonItem:SetAnchor(GUIItem.Left, GUIItem.Top)
        buttonItem:SetSize(Vector(GUICommanderButtons.kButtonWidth, GUICommanderButtons.kButtonHeight, 0))
        local xPos = ((i - 1) % settingsTable.NumberOfColumns) * GUICommanderButtons.kButtonWidth
        local yPos = math.floor(((i - 1) / settingsTable.NumberOfColumns)) * GUICommanderButtons.kButtonHeight
        yPos = yPos + settingsTable.ButtonYOffset + settingsTable.TabTopHeight + settingsTable.TabBottomHeight
        buttonItem:SetPosition(Vector(xPos + GUICommanderButtons.kButtonXOffset, yPos + GUICommanderButtons.kButtonYOffset, 0))
        buttonItem:SetTexture("ui/buildmenu.dds")
        self.background:AddChild(buttonItem)
        
        table.insert(self.buttons, buttonItem)
        table.insert(self.bottomButtons, buttonItem)        
        self.buttonbackground[i + self.numberOfTabs] = backgroundItem        
        
        self:UpdateButtonStatus(i + self.numberOfTabs)
        
        local cooldown = GUIDial()
        cooldown:Initialize(kHealthCircleSettings[self.teamType])
        cooldown:GetLeftSide():SetBlendTechnique(GUIItem.Add)
        cooldown:GetRightSide():SetBlendTechnique(GUIItem.Add)
        
        buttonItem:AddChild(cooldown:GetBackground())
        self.cooldowns[self.numberOfTabs + i] = cooldown
        
    end
    
end

function GUICommanderButtons:InitializePlayerAlertIcon()

    self.playerAlerts = GUIManager:CreateGraphicItem()
    self.playerAlerts:SetSize(Vector(GUICommanderButtons.kIdleWorkersSize, GUICommanderButtons.kIdleWorkersSize, 0))
    self.playerAlerts:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.playerAlerts:SetPosition(Vector(GUICommanderButtons.kPlayerAlertX, 0, 0))
    self.playerAlerts:SetTexture("ui/buildmenu.dds")
    
    local coordinates = CommanderUI_GetPlayerAlertOffset()
    local x1 = GUICommanderButtons.kBuildMenuTextureWidth * coordinates[1]
    local x2 = x1 + GUICommanderButtons.kBuildMenuTextureWidth
    local y1 = GUICommanderButtons.kBuildMenuTextureHeight * coordinates[2]
    local y2 = y1 + GUICommanderButtons.kBuildMenuTextureHeight
    self.playerAlerts:SetTexturePixelCoordinates(x1, y1, x2, y2)
    self.playerAlerts:SetIsVisible(false)
    self.background:AddChild(self.playerAlerts)
    
    self.playerAlertsText = GUIManager:CreateTextItem()
    self.playerAlertsText:SetFontSize(GUICommanderButtons.kIdleWorkersFontSize)
    self.playerAlertsText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.playerAlertsText:SetTextAlignmentX(GUIItem.Align_Center)
    self.playerAlertsText:SetTextAlignmentY(GUIItem.Align_Min)
    self.playerAlertsText:SetColor(Color(1, 1, 1, 1))
    self.playerAlertsText:SetText("0")
    self.playerAlerts:AddChild(self.playerAlertsText)

end

function GUICommanderButtons:InitializeSelectAllPlayersIcon()

    if PlayerUI_GetTeamType() == kMarineTeamType then

        self.selectAllPlayers = GUIManager:CreateGraphicItem()
        self.selectAllPlayers:SetSize(Vector(GUICommanderButtons.kSelectAllPlayersSize, GUICommanderButtons.kSelectAllPlayersSize, 0))
        self.selectAllPlayers:SetAnchor(GUIItem.Left, GUIItem.Top)
        self.selectAllPlayers:SetPosition(Vector(GUICommanderButtons.kSelectAllPlayersX, GUICommanderButtons.kSelectAllPlayersY, 0))
        self.selectAllPlayers:SetTexture("ui/buildmenu.dds")
        
        local coordinates = GetTextureCoordinatesForIcon(kTechId.Marine)
        self.selectAllPlayers:SetTexturePixelCoordinates(GUIUnpackCoords(coordinates))
    
    end
    
end

function GUICommanderButtons:Uninitialize()

    if self.highlightItem then
        GUI.DestroyItem(self.highlightItem)
        self.highlightItem = nil
    end

    if self.playerAlerts then
        GUI.DestroyItem(self.playerAlerts)
        self.playerAlerts = nil
    end

    if self.selectAllPlayers then
        GUI.DestroyItem(self.selectAllPlayers)
        self.selectAllPlayers = nil
    end
    
    -- Everything is attached to the background so destroying it will
    -- destroy everything else.
    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
        self.tabs = { }
        self.bottomButtons = { }
        self.buttons = { }
    end
    
end

-- Returns the main button list, does not include tabs.
function GUICommanderButtons:GetButtonList()

    local buttonList = self.buttons
    local indexOffset = 0
    buttonList = self.bottomButtons
    indexOffset = self.numberOfTabs
    
    return buttonList, indexOffset

end

local function UpdateHighlight(self)

    local player = Client.GetLocalPlayer()
    if player then
    
        local highlightTech = GetHighlightButtonTechId()
    
        for i = 1, #self.buttons do
        
            local buttonAvailable = CommanderUI_MenuButtonStatus(i) == 1
            if buttonAvailable then
            
                if type(highlightTech) == "table" then
                
                    if table.icontains(highlightTech, player.menuTechButtons[i]) then
                        self.buttons[i]:SetColor(Color(0.4, 1, 0.4, 1))
                    end
            
                elseif player.menuTechButtons[i] == highlightTech then
                    self.buttons[i]:SetColor(Color(0.4, 1, 0.4, 1))
                end
            
            end
        
        end
    
    end

end

function GUICommanderButtons:Update(deltaTime)

    PROFILE("GUICommanderButtons:Update")

    UpdateTabs(self)
    
    self.tooltipButtonIndex = self:UpdateInput()
    
    self:UpdateAlertIcon()

    local buttonList, indexOffset = self:GetButtonList()
    
    for i, buttonItem in ipairs(buttonList) do
        self:UpdateButtonStatus(i + indexOffset)
    end
    
    self:UpdateButtonHotkeys()
    
    UpdateHighlight(self)
    
end

local function HighlightButton(self, buttonItem)

    local foundTabTable
    table.foreachfunctor(self.tabs, function (tabTable) if tabTable.TopItem == buttonItem then foundTabTable = tabTable end end)
    
    if foundTabTable == nil then
    
        local currentParent = self.highlightItem:GetParent()
        if currentParent ~= buttonItem then
    
            if currentParent then
                currentParent:RemoveChild(self.highlightItem)
            end
            
            buttonItem:AddChild(self.highlightItem)
            CommanderUI_OnButtonHover()
        
        end
        
        self.highlightItem:SetIsVisible(true)
        
    end
    
end

function GUICommanderButtons:UpdateInput()

    local tooltipButtonIndex
    
    if self.highlightItem then
    
        self.highlightItem:SetIsVisible(false)
        
        local mouseX, mouseY = Client.GetCursorPosScreen()
        
        if CommanderUI_GetUIClickable() and GUIItemContainsPoint(self.background, mouseX, mouseY) then
        
            for i, buttonItem in ipairs(self.buttons) do
            
                local buttonStatus = CommanderUI_MenuButtonStatus(i)
                if GUIItemContainsPoint(buttonItem, mouseX, mouseY) then
                
                    if (buttonItem:GetIsVisible() and buttonStatus == GUICommanderButtons.kButtonStatusEnabled.Id) and
                       (self.targetedButton == nil or self.targetedButton == i) then
                       
                        HighlightButton(self, buttonItem)
                        tooltipButtonIndex = i
                        
                        break
                        
                    -- Off or red buttons can still have a tooltip.
                    elseif buttonStatus == GUICommanderButtons.kButtonStatusOff.Id or buttonStatus == GUICommanderButtons.kButtonStatusRed.Id or buttonStatus == GUICommanderButtons.kButtonStatusPassive.Id then
                    
                        tooltipButtonIndex = i
                        break
                        
                    end
                    
                end
                
            end
            
        end
        
    end
    
    return tooltipButtonIndex
    
end

function GUICommanderButtons:GetTooltipData()

    local player = Client.GetLocalPlayer()
    
    if self.tooltipButtonIndex and player then    
        return PlayerUI_GetTooltipDataFromTechId(player.menuTechButtons[self.tooltipButtonIndex], self.tooltipButtonIndex)        
    end

    return nil

end

function ScalePlayerAlertOperator(item, scalar)

    local newScalar = math.cos(scalar * math.sin(scalar * math.pi))
    local sizeVector = Vector(newScalar * GUICommanderButtons.kIdleWorkersSize, newScalar * GUICommanderButtons.kIdleWorkersSize, 0)
    item:SetSize(sizeVector)
    
    local sizeDifferenceX = GUICommanderButtons.kIdleWorkersSize - sizeVector.x
    local sizeDifferenceY = GUICommanderButtons.kIdleWorkersSize - sizeVector.y
    
    -- Make sure it is always centered.
    item:SetPosition(Vector(GUICommanderButtons.kPlayerAlertX + sizeDifferenceX / 2, sizeDifferenceY / 2, 0))
    
end

-- Shake item back and forth a bit
function ShakePlayerAlertOperator(item, scalar)

    local amount = math.floor((1 - scalar) * 5)
    scalar = math.cos(scalar * math.pi * 10)    
    local currentPosition = item:GetPosition()
    item:SetPosition(Vector(currentPosition.x + scalar * amount, currentPosition.y, 0))
    
end

function GUICommanderButtons:UpdateAlertIcon()
    
    local numAlerts = CommanderUI_GetPlayerAlertCount()
    
    if numAlerts > 0 then
    
        self.playerAlerts:SetIsVisible(true)
        self.playerAlertsText:SetText(ToString(numAlerts))
        self.playerAlertsText:SetIsVisible(true)
    
    else
    
        self.playerAlerts:SetIsVisible(false)
        self.playerAlertsText:SetIsVisible(false)
        
    end
    
end

function GUICommanderButtons:UpdateButtonStatus(buttonIndex)

    local buttonStatus = CommanderUI_MenuButtonStatus(buttonIndex)
    local buttonCooldownFraction = CommanderUI_MenuButtonCooldownFraction(buttonIndex)
    local buttonItem = self.buttons[buttonIndex]
    local cooldownItem = self.cooldowns[buttonIndex]
    local backgroundItem = self.buttonbackground[buttonIndex]    
    
    if cooldownItem then
    
        cooldownItem:SetIsVisible(buttonCooldownFraction ~= 0)
        if buttonCooldownFraction ~= 0 then
        
            cooldownItem:SetPercentage(buttonCooldownFraction)
            cooldownItem:Update()
            
        end
        
    end
    
    buttonItem:SetIsVisible(GUICommanderButtons.kButtonStatusData[buttonStatus].Visible)
    
    if buttonStatus == GUICommanderButtons.kButtonStatusEnabled.Id or buttonStatus == GUICommanderButtons.kButtonStatusPassive.Id then
        buttonItem:SetColor(kIconColors[self.teamType])
    else    
        buttonItem:SetColor(GUICommanderButtons.kButtonStatusData[buttonStatus].Color)
    end
    
    if buttonItem:GetIsVisible() then
    
        local buttonWidth = CommanderUI_MenuButtonWidth()
        local buttonHeight = CommanderUI_MenuButtonHeight()
        local buttonXOffset, buttonYOffset = CommanderUI_MenuButtonOffset(buttonIndex)
        
        if buttonXOffset and buttonYOffset then
        
            local textureXOffset = buttonXOffset * buttonWidth
            local textureYOffset = buttonYOffset * buttonHeight
            buttonItem:SetTexturePixelCoordinates(textureXOffset, textureYOffset, textureXOffset + buttonWidth, textureYOffset + buttonHeight)
            
        end
        
    end
    
    if self.targetedButton ~= nil then
    
        if self.targetedButton == buttonIndex then
            buttonItem:SetColor(kIconColors[self.teamType])
        else
            buttonItem:SetColor(GUICommanderButtons.kButtonStatusOff.Color)
        end
        
    end  
    
    backgroundItem:SetIsVisible(buttonItem:GetIsVisible() and buttonStatus ~= GUICommanderButtons.kButtonStatusPassive.Id)
    
end

function GUICommanderButtons:UpdateButtonHotkeys()

    local triggeredButton = CommanderUI_HotkeyTriggeredButton()
    if triggeredButton ~= nil then
    
        local buttonStatus = CommanderUI_MenuButtonStatus(triggeredButton)
        
        -- Only allow hotkeys on enabled buttons.
        if buttonStatus == GUICommanderButtons.kButtonStatusEnabled.Id then
        
            local player = Client.GetLocalPlayer()
            player:TriggerButtonIndex(triggeredButton)
            
        end
        
    end
    
end

function GUICommanderButtons:SetTargetedButton(setButton)

    self.targetedButton = setButton
    local buttonList, indexOffset = self:GetButtonList()
    for i, buttonItem in ipairs(buttonList) do
        self:UpdateButtonStatus(i + indexOffset)
    end
    
end

function GUICommanderButtons:GetTargetedButton()
    return self.targetedButton
end

function GUICommanderButtons:SendKeyEvent(key, down)

    local mouseX, mouseY = Client.GetCursorPosScreen()
    
    if key == InputKey.MouseButton0 and self.mousePressed["LMB"]["Down"] ~= down then
    
        self.mousePressed["LMB"]["Down"] = down
        if down then
            self:MousePressed(key, mouseX, mouseY)
        end
        
    elseif key == InputKey.MouseButton1 and self.mousePressed["RMB"]["Down"] ~= down then
    
        self.mousePressed["RMB"]["Down"] = down
        if down then
            self:MousePressed(key, mouseX, mouseY)
        end
        
    end
    
end

local function SendButtonTargetedAction(index, x, y)

    local techId = GetTechIdFromButtonIndex(index)
    local player = Client.GetLocalPlayer()
    local normalizedPickRay = CreatePickRay(player, x, y)
    
    -- Don't execute targeted action if we're still on top of the UI
    if not CommanderUI_GetMouseIsOverUI() then
        
        player:SendTargetedAction(techId, normalizedPickRay)
        return true
        
    end
    
    return false
    
end

function GUICommanderButtons:MousePressed(key, mouseX, mouseY)

    if CommanderUI_GetUIClickable() then
    
        if key == InputKey.MouseButton1 then
        
            -- Cancel targeted button upon right mouse press.
            if self.targetedButton ~= nil then
                self:SetTargetedButton(nil)
            end
            
        elseif key == InputKey.MouseButton0 then
        
			local success = false
            
			if self.playerAlerts:GetIsVisible() and GUIItemContainsPoint(self.playerAlerts, mouseX, mouseY) then
                CommanderUI_ClickedPlayerAlert()
                success = true
            elseif self.selectAllPlayers and GUIItemContainsPoint(self.selectAllPlayers, mouseX, mouseY) then
                CommanderUI_ClickedSelectAllPlayers()
                success = true
            elseif self.targetedButton ~= nil then
            
                -- Commander_GhostStructure handles ghost structures. This code path handles tech that doesn't
                -- have a ghost model like Scan and Nano Shield.
                if not GetCommanderGhostStructureEnabled() then
                
                    if SendButtonTargetedAction(self.targetedButton, mouseX, mouseY) then
                        self:SetTargetedButton(nil)
                    end
                    
                end
                
            else
            
                for i = 1, #self.buttons do
                
                    local buttonItem = self.buttons[i]
                    local buttonStatus = CommanderUI_MenuButtonStatus(i)
                    if buttonItem:GetIsVisible() and buttonStatus == GUICommanderButtons.kButtonStatusEnabled.Id and
                       GUIItemContainsPoint(buttonItem, mouseX, mouseY) then
                       
                        ButtonPressed(self, i)
                        success = true
                        break
                        
                    end
                    
                end
                
            end
            
            if success then
                CommanderUI_OnButtonClicked()
            end
            
        end
        
    end
    
end

function GUICommanderButtons:DeselectTab()
    self.lastPressedTab = nil
end

function GUICommanderButtons:SelectTab(index)

    -- If this button is a tab, change it to the selected state.
    local buttonItem = self.buttons[index]
    local foundTabTable
    table.foreachfunctor(self.tabs, function (tabTable) if tabTable.TopItem == buttonItem then foundTabTable = tabTable end end)
    if foundTabTable then
        foundTabTable.TopItem:SetIsVisible(true)
        self.lastPressedTab = foundTabTable
        self.selectedTabIndex = index
    else
    
        -- This is a bit of a hack for now.
        local tooltipData = CommanderUI_MenuButtonTooltip(index)
        -- NOTE: This will fail to work when "Back" has been localized.
        local isBackButton = tooltipData[1] == "Back"
        -- Only the back button should unselect tabs and hide tab connectors.
        if isBackButton then
        
            table.foreachfunctor(self.tabs, DeselectTab)
            self.lastPressedTab = nil
            
        end
        
    end
    
end

function GUICommanderButtons:SelectTabForTechId(techId)

    if self:IsTab(techId) then
        self:SelectTab(self:ConvertTechIdToTabIndex(techId))
    end
    
end

function GUICommanderButtons:GetSelectedTab()
    return self.lastPressedTab
end

function GUICommanderButtons:GetSelectedTabIndex()
    return self.selectedTabIndex
end

function GUICommanderButtons:ConvertTechIdToTabIndex(techId)

    local techTree = GetTechTree()
    local techText = techTree:GetDescriptionText(techId)
    for t = 1, #self.tabs do
    
        local currentTab = self.tabs[t]
        local tabText = currentTab.TextItem:GetText()
        if tabText == techText then
            return t
        end
        
    end
    
    return nil
    
end

function GUICommanderButtons:IsTabSelected(techId)

    local techTree = GetTechTree()
    local techText = techTree:GetDescriptionText(techId)
    
    if self.lastPressedTab then
    
        local tabText = self.lastPressedTab.TextItem:GetText()
        if tabText == nil then
            return false
        end
        
        if tabText == techText then
            return true
        end
        
    end
    
    return false
    
end

function GUICommanderButtons:IsTab(techId)

    local techTree = GetTechTree()
    local techText = techTree:GetDescriptionText(techId)
    
    for t = 1, #self.tabs do
    
        local tabTable = self.tabs[t]
        local tabText = tabTable.TextItem:GetText()
        if tabText == nil then
            return false
        end
        
        if tabText == techText then
            return true
        end
        
    end
    
end

function GUICommanderButtons:GetBackground()
    return self.background
end

function GUICommanderButtons:ContainsPoint(pointX, pointY)

    -- Check if the point is over any of the UI managed by the GUICommanderButtons.
    local containsPoint = (self.playerAlerts:GetIsVisible() and GUIItemContainsPoint(self.playerAlerts, pointX, pointY))
    containsPoint = containsPoint or (selectAllPlayers ~= nil and GUIItemContainsPoint(self.selectAllPlayers, pointX, pointY))
    return containsPoint or GUIItemContainsPoint(self.background, pointX, pointY)
    
end