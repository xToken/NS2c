// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUISelectionPanel.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the middle commander panel used to display info related to what is currently selected.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed alien comm refs, added energy and removed maturity.

Script.Load("lua/GUIIncrementBar.lua")

class 'GUISelectionPanel' (GUIScript)

GUISelectionPanel.kFontName = Fonts.kAgencyFB_Large
GUISelectionPanel.kFontScale = Vector(1, 1, 0) * kCommanderGUIsGlobalScale * 0.8
GUISelectionPanel.kStatusFontScale = GUISelectionPanel.kFontScale * 0.8


GUISelectionPanel.kStatusFontName = Fonts.kAgencyFB_Small
GUISelectionPanel.StatuskFontScale = Vector(1, 1, 0) * kCommanderGUIsGlobalScale

GUISelectionPanel.kFontColor = Color(0.8, 0.8, 1)
GUISelectionPanel.kStatusFontColor = Color(0.9, 1, 0.7)

GUISelectionPanel.kSelectionTextureMarines = "ui/marine_commander_textures.dds"
GUISelectionPanel.kSelectionTextureAliens = "ui/alien_commander_textures.dds"

GUISelectionPanel.kSelectionTextureCoordinates = { X1 = 466, Y1 = 0, X2 = 466 + 312, Y2 = 250 }
GUISelectionPanel.kHealthIconCoordinates = { X1 = 0, Y1 = 363, X2 = 48, Y2 = 363 + 48 }
GUISelectionPanel.kArmorIconCoordinates = { X1 = 48, Y1 = 363, X2 = 48 * 2, Y2 = 363 + 48 }
GUISelectionPanel.kEnergyIconCoordinates = { X1 = 48 * 2, Y1 = 363, X2 = 48 * 3, Y2 = 363 + 48 }

// The panel will scale with the screen resolution. It is based on
// this screen width.
GUISelectionPanel.kPanelWidth = 312 * kCommanderGUIsGlobalScale
GUISelectionPanel.kPanelHeight = 250 * kCommanderGUIsGlobalScale

GUISelectionPanel.kSelectedIconXOffset = 40 * kCommanderGUIsGlobalScale
GUISelectionPanel.kSelectedIconYOffset = 80 * kCommanderGUIsGlobalScale
GUISelectionPanel.kSelectedIconSize = 70 * kCommanderGUIsGlobalScale

GUISelectionPanel.kMultiSelectedIconSize = GUISelectionPanel.kSelectedIconSize * 0.75
GUISelectionPanel.kSelectedIconTextureWidth = 80
GUISelectionPanel.kSelectedIconTextureHeight = 80

GUISelectionPanel.kStatusIconPos = Vector(40, 160, 0) * kCommanderGUIsGlobalScale
GUISelectionPanel.kStatusBarXOffset = 3 * kCommanderGUIsGlobalScale

GUISelectionPanel.kStatusIconSize = 36 * kCommanderGUIsGlobalScale
GUISelectionPanel.kStatusIconYOffset = 8 * kCommanderGUIsGlobalScale


GUISelectionPanel.kStatusBarWidth = 192 * kCommanderGUIsGlobalScale
GUISelectionPanel.kStatusBarHeight = 22 * kCommanderGUIsGlobalScale

GUISelectionPanel.kSelectedNameYOffset = 40

GUISelectionPanel.kSelectedLocationTextFontSize = 16 * kCommanderGUIsGlobalScale
GUISelectionPanel.kSelectionLocationNameYOffset = -30

GUISelectionPanel.kSelectionStatusTextYOffset = -36
GUISelectionPanel.kSelectionStatusBarYOffset = -20

GUISelectionPanel.kStatusBarColor = Color(1, 133 / 255, 0, 1)

GUISelectionPanel.kResourceIconSize = 48 * kCommanderGUIsGlobalScale

GUISelectionPanel.kResourceTextXOffset = 4
GUISelectionPanel.kResourceTextYOffset = 0

GUISelectionPanel.kHealthIconPos = Vector(114, 74, 0) * kCommanderGUIsGlobalScale
GUISelectionPanel.kArmorIconPos = Vector(0, 18, 0) * kCommanderGUIsGlobalScale + GUISelectionPanel.kHealthIconPos
GUISelectionPanel.kEnergyIconPos = Vector(0, 18, 0) * kCommanderGUIsGlobalScale + GUISelectionPanel.kArmorIconPos

GUISelectionPanel.kSelectedHealthTextFontSize = 15 * kCommanderGUIsGlobalScale

GUISelectionPanel.kSelectedCustomTextFontSize = 16 * kCommanderGUIsGlobalScale
GUISelectionPanel.kSelectedCustomTextXOffset = -183 * kCommanderGUIsGlobalScale
GUISelectionPanel.kSelectedCustomTextYOffset = 125 * kCommanderGUIsGlobalScale

GUISelectionPanel.kInfoBarWidth = 100 * kCommanderGUIsGlobalScale
GUISelectionPanel.kInfoBarHeight = math.floor(6 * kCommanderGUIsGlobalScale)
GUISelectionPanel.kInfoBarOffset = Vector( 10 * kCommanderGUIsGlobalScale, -3 * kCommanderGUIsGlobalScale, 0)

GUISelectionPanel.kBarBGPixelCoords = { 0, 645, 229, 645 + 41 }
GUISelectionPanel.kBarBGSize = Vector(250, 49, 0) * kCommanderGUIsGlobalScale
GUISelectionPanel.kBarBGXPos = -4 * kCommanderGUIsGlobalScale

local kInfoBarTexture = "ui/commanderbar.dds"

local kBackgroundNoiseTexture = "ui/alien_commander_bg_smoke.dds"
local kSmokeyBackgroundSize = GUIScale(Vector(300, 380, 0))


GUISelectionPanel.kHealthBarColors = { [kMarineTeamType] = Color(0.725, 1, 1, 1),
                     [kAlienTeamType] = Color(1, 197 / 255, 71 / 255, 1),
                     [kNeutralTeamType] = Color(1, 1, 1, 1) }
                     
GUISelectionPanel.kArmorBarColors = { [kMarineTeamType] = Color(0.078, 0.9, 1, 1),
                    [kAlienTeamType] = Color(1, 143 / 255, 34 / 255, 1),
                    [kNeutralTeamType] = Color(0.5, 0.5, 0.5, 1) }

function GUISelectionPanel:Initialize()

    self.teamType = PlayerUI_GetTeamType()

    self.textureName = GUISelectionPanel.kSelectionTextureMarines
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.background:SetTexture(self.textureName)
    self.background:SetSize(Vector(GUISelectionPanel.kPanelWidth, GUISelectionPanel.kPanelHeight, 0))
    self.background:SetPosition(Vector(-GUISelectionPanel.kPanelWidth + 36 * kCommanderGUIsGlobalScale, -GUISelectionPanel.kPanelHeight, 0))
    GUISetTextureCoordinatesTable(self.background, GUISelectionPanel.kSelectionTextureCoordinates)
    
    if PlayerUI_GetTeamType() == kAlienTeamType then    
        self:InitSmokeyBackground()
    end
    
    self:InitializeSingleSelectionItems()
    self:InitializeMultiSelectionItems()
    
    self.highlightedMultiItem = 1

end

function GUISelectionPanel:InitializeSingleSelectionItems()

    self.singleSelectionItems = { }
    
    local useColor = Color(1,1,1,1)
    
    local teamType = PlayerUI_GetTeamType()
    
    if teamType == kMarineTeamType then
        useColor = kMarineFontColor
    elseif teamType == kAlienTeamType then
        useColor = kAlienFontColor
    end
    
    self.selectedIcon = GUIManager:CreateGraphicItem()
    self.selectedIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.selectedIcon:SetSize(Vector(GUISelectionPanel.kSelectedIconSize, GUISelectionPanel.kSelectedIconSize, 0))
    self.selectedIcon:SetPosition(Vector(GUISelectionPanel.kSelectedIconXOffset, GUISelectionPanel.kSelectedIconYOffset, 0))
    self.selectedIcon:SetTexture("ui/buildmenu.dds")
    self.selectedIcon:SetColor(kIconColors[teamType])
    self.selectedIcon:SetIsVisible(false)
    table.insert(self.singleSelectionItems, teamType)
    self.background:AddChild(self.selectedIcon)
    
    self.selectedName = GUIManager:CreateTextItem()
    self.selectedName:SetFontName(GUISelectionPanel.kFontName)
    self.selectedName:SetScale(GUISelectionPanel.kFontScale)
    self.selectedName:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.selectedName:SetPosition(Vector(0, GUISelectionPanel.kSelectedNameYOffset, 0))
    self.selectedName:SetTextAlignmentX(GUIItem.Align_Center)
    self.selectedName:SetTextAlignmentY(GUIItem.Align_Center)
    self.selectedName:SetColor(useColor)
    table.insert(self.singleSelectionItems, self.selectedName)
    self.background:AddChild(self.selectedName)
    
    self.selectedLocationName = GUIManager:CreateTextItem()
    self.selectedLocationName:SetFontSize(GUISelectionPanel.kSelectedLocationTextFontSize)
    self.selectedLocationName:SetFontName(GUISelectionPanel.kFontName)
    self.selectedLocationName:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.selectedLocationName:SetPosition(Vector(0, GUISelectionPanel.kSelectionLocationNameYOffset, 0))
    self.selectedLocationName:SetTextAlignmentX(GUIItem.Align_Center)
    self.selectedLocationName:SetTextAlignmentY(GUIItem.Align_Center)
    self.selectedLocationName:SetColor(useColor)
    table.insert(self.singleSelectionItems, self.selectedLocationName)
    self.background:AddChild(self.selectedLocationName)
    
    self.healthIcon = GUIManager:CreateGraphicItem()
    self.healthIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.healthIcon:SetSize(Vector(GUISelectionPanel.kResourceIconSize, GUISelectionPanel.kResourceIconSize, 0))
    self.healthIcon:SetPosition(GUISelectionPanel.kHealthIconPos)
    self.healthIcon:SetTexture(self.textureName)
    GUISetTextureCoordinatesTable(self.healthIcon, GUISelectionPanel.kHealthIconCoordinates)
    self.background:AddChild(self.healthIcon)
    
    self.healthText = GUIManager:CreateTextItem()
    self.healthText:SetScale(GUISelectionPanel.kStatusFontScale)
    self.healthText:SetFontName(GUISelectionPanel.kFontName)
    self.healthText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.healthText:SetPosition(Vector(GUISelectionPanel.kResourceTextXOffset, GUISelectionPanel.kResourceTextYOffset, 0))
    self.healthText:SetTextAlignmentX(GUIItem.Align_Min)
    self.healthText:SetTextAlignmentY(GUIItem.Align_Center)
    self.healthText:SetColor(GUISelectionPanel.kHealthBarColors[teamType])
    table.insert(self.singleSelectionItems, self.healthText)
    self.healthIcon:AddChild(self.healthText)
    
    self.armorIcon = GUIManager:CreateGraphicItem()
    self.armorIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.armorIcon:SetSize(Vector(GUISelectionPanel.kResourceIconSize, GUISelectionPanel.kResourceIconSize, 0))
    self.armorIcon:SetPosition(GUISelectionPanel.kArmorIconPos)
    self.armorIcon:SetTexture(self.textureName)
    GUISetTextureCoordinatesTable(self.armorIcon, GUISelectionPanel.kArmorIconCoordinates)
    self.background:AddChild(self.armorIcon)
    
    self.armorText = GUIManager:CreateTextItem()
    self.armorText:SetScale(GUISelectionPanel.kStatusFontScale)
    self.armorText:SetFontName(GUISelectionPanel.kFontName)
    self.armorText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.armorText:SetPosition(Vector(GUISelectionPanel.kResourceTextXOffset, GUISelectionPanel.kResourceTextYOffset, 0))
    self.armorText:SetTextAlignmentX(GUIItem.Align_Min)
    self.armorText:SetTextAlignmentY(GUIItem.Align_Center)
    self.armorText:SetColor(GUISelectionPanel.kArmorBarColors[teamType])
    table.insert(self.singleSelectionItems, self.armorText)
    self.armorIcon:AddChild(self.armorText)
    
    self.energyIcon = GUIManager:CreateGraphicItem()
    self.energyIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.energyIcon:SetSize(Vector(GUISelectionPanel.kResourceIconSize, GUISelectionPanel.kResourceIconSize, 0))
    self.energyIcon:SetPosition(GUISelectionPanel.kEnergyIconPos)
    self.energyIcon:SetTexture(self.textureName)
    GUISetTextureCoordinatesTable(self.energyIcon, GUISelectionPanel.kEnergyIconCoordinates)
    self.background:AddChild(self.energyIcon)
    
    self.energyText = GUIManager:CreateTextItem()
    self.energyText:SetScale(GUISelectionPanel.kStatusFontScale)
    self.energyText:SetFontName(GUISelectionPanel.kFontName)
    self.energyText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.energyText:SetPosition(Vector(GUISelectionPanel.kResourceTextXOffset, 0, 0))
    self.energyText:SetTextAlignmentX(GUIItem.Align_Min)
    self.energyText:SetTextAlignmentY(GUIItem.Align_Center)
    self.energyText:SetColor(useColor)
    table.insert(self.singleSelectionItems, self.energyText)
    self.energyIcon:AddChild(self.energyText)
    
    self.statusIcon = GUIManager:CreateGraphicItem()
    self.statusIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.statusIcon:SetSize(Vector(GUISelectionPanel.kStatusIconSize, GUISelectionPanel.kStatusIconSize, 0))
    self.statusIcon:SetPosition(GUISelectionPanel.kStatusIconPos)
    self.statusIcon:SetTexture("ui/buildmenu.dds")
    self.background:AddChild(self.statusIcon)
    
    self.researchBarBg = GUIManager:CreateGraphicItem()
    self.researchBarBg:SetTexture(self.textureName)
    self.researchBarBg:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.researchBarBg:SetTexturePixelCoordinates(unpack(GUISelectionPanel.kBarBGPixelCoords))
    self.researchBarBg:SetPosition(Vector(GUISelectionPanel.kBarBGXPos, -GUISelectionPanel.kBarBGSize.y * .5, 0))
    self.researchBarBg:SetSize(GUISelectionPanel.kBarBGSize)
    self.statusIcon:AddChild(self.researchBarBg)
    
    self.statusBar = GUIManager:CreateGraphicItem()
    self.statusBar:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.statusBar:SetPosition(Vector(GUISelectionPanel.kStatusIconSize + GUISelectionPanel.kStatusBarXOffset, -GUISelectionPanel.kStatusBarHeight * .5, 0))
    self.statusBar:SetSize(Vector(GUISelectionPanel.kStatusBarWidth, GUISelectionPanel.kStatusBarHeight, 0))
    self.statusBar:SetColor(GUISelectionPanel.kStatusBarColor)
    table.insert(self.singleSelectionItems, self.statusBar)
    self.researchBarBg:AddChild(self.statusBar)
    
    self.statusText = GUIManager:CreateTextItem()
    self.statusText:SetScale(GUISelectionPanel.StatuskFontScale)
    self.statusText:SetFontName(GUISelectionPanel.kStatusFontName)
    self.statusText:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.statusText:SetTextAlignmentX(GUIItem.Align_Min)
    self.statusText:SetTextAlignmentY(GUIItem.Align_Center)
    self.statusText:SetPosition(Vector(5, 0, 0))
    self.statusText:SetColor(useColor)
    table.insert(self.singleSelectionItems, self.statusText)
    self.statusBar:AddChild(self.statusText)
    
    self.customText = GUIManager:CreateTextItem()
    self.customText:SetFontSize(GUISelectionPanel.kSelectedCustomTextFontSize)
    self.customText:SetFontName(GUISelectionPanel.kFontName)
    self.customText:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.customText:SetPosition(Vector(GUISelectionPanel.kSelectedCustomTextXOffset, GUISelectionPanel.kSelectedCustomTextYOffset, 0))
    self.customText:SetTextAlignmentX(GUIItem.Align_Max)
    self.customText:SetTextAlignmentY(GUIItem.Align_Min)
    self.customText:SetColor(useColor)
    table.insert(self.singleSelectionItems, self.customText)
    self.background:AddChild(self.customText)

end

function GUISelectionPanel:InitializeMultiSelectionItems()

    self.multiSelectionIcons = { }
    
end

function GUISelectionPanel:InitSmokeyBackground()

    self.smokeyBackground = GUIManager:CreateGraphicItem()
    self.smokeyBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.smokeyBackground:SetSize(kSmokeyBackgroundSize)
    self.smokeyBackground:SetPosition(-kSmokeyBackgroundSize * .5)
    self.smokeyBackground:SetShader("shaders/GUISmoke.surface_shader")
    self.smokeyBackground:SetTexture("ui/alien_logout_smkmask.dds")
    self.smokeyBackground:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
    self.smokeyBackground:SetFloatParameter("correctionX", 1)
    self.smokeyBackground:SetFloatParameter("correctionY", 1.5)
    
    self.background:AddChild(self.smokeyBackground)

end

function GUISelectionPanel:Uninitialize()
    
    // Everything is attached to the background so destroying it will
    // destroy everything else.
    GUI.DestroyItem(self.background)
    self.background = nil
    self.selectedIcon = nil
    self.selectedName = nil
    self.selectedLocationName = nil
    self.multiSelectionIcons = { }
    
end

function GUISelectionPanel:Update(deltaTime)

    PROFILE("GUISelectionPanel:Update")
    
    self:UpdateSelected()
    
end

function GUISelectionPanel:SetIsVisible(state)

    self.background:SetIsVisible(state)
    self.selectedIcon:SetIsVisible(state)
    self.healthIcon:SetIsVisible(state)
    self.armorIcon:SetIsVisible(state)
    self.energyIcon:SetIsVisible(state)
    self.statusBar:SetIsVisible(state)
    self.selectedName:SetIsVisible(state)
    self.selectedLocationName:SetIsVisible(state)
    self.statusText:SetIsVisible(state)
    self.armorText:SetIsVisible(state)
    self.energyText:SetIsVisible(state)
    self.customText:SetIsVisible(state)
    
end

function GUISelectionPanel:UpdateSelected()

    local selectedEntities = CommanderUI_GetSelectedEntities()
    local numberSelectedEntities = table.count(selectedEntities)
    self.selectedIcon:SetIsVisible(false)
    
    // Hide selection panel with nothing selected
    self:SetIsVisible(numberSelectedEntities > 0)
    
    if numberSelectedEntities > 0 then
    
        if numberSelectedEntities == 1 then
            self:UpdateSingleSelection(selectedEntities[1])
        else
        
            self:UpdateSingleSelection(selectedEntities[1])
            self:UpdateMultiSelection(selectedEntities)
            
        end
        
    end
    
end

function GUISelectionPanel:UpdateSingleSelection(entity)

    // Make all multiselection icons invisible.
    function SetItemInvisible(item) item:SetIsVisible(false) end
    table.foreachfunctor(self.multiSelectionIcons, SetItemInvisible)
    
    self.selectedIcon:SetIsVisible(true)
    
    self:SetIconTextureCoordinates(self.selectedIcon, entity)
    if not self.selectedIcon:GetIsVisible() then
        return
    end
    
    local selectedDescription = CommanderUI_GetSelectedDescriptor(entity)
    self.selectedName:SetIsVisible(true)
    self.selectedName:SetText(string.upper(selectedDescription))
    local selectedLocationText = CommanderUI_GetSelectedLocation(entity)
    self.selectedLocationName:SetIsVisible(false)
    self.selectedLocationName:SetText(string.upper(selectedLocationText))
    
    local selectedBargraphs = CommanderUI_GetSelectedBargraphs(entity)
    local healthText = CommanderUI_GetSelectedHealth(entity)
    self.healthText:SetText(healthText)
    self.healthIcon:SetIsVisible(string.len(healthText) > 0)
    
    local armorText = CommanderUI_GetSelectedArmor(entity)
    self.armorText:SetText(armorText)
    self.armorIcon:SetIsVisible(string.len(armorText) > 0)

    local statusText = selectedBargraphs[1]
    local statusPercentage = selectedBargraphs[2]
    local statusTechId = selectedBargraphs[3]
    
    if table.count(selectedBargraphs) > 2 and statusPercentage then
    
        local pulseColor = Color(GUISelectionPanel.kStatusFontColor)
        pulseColor.a = 0.65 + (((math.sin(Shared.GetTime() * 10) + 1) / 2) * 0.35)
        self.statusText:SetColor(pulseColor)
        self.statusText:SetText(string.upper(statusText))        
        
        self.statusBar:SetSize(Vector(GUISelectionPanel.kStatusBarWidth * statusPercentage, GUISelectionPanel.kStatusBarHeight, 0))
        
        self.statusIcon:SetIsVisible(true)
        self.statusBar:SetIsVisible(true)
        self.statusText:SetIsVisible(true)

        if statusTechId and statusTechId ~= kTechId.None then
            self.statusIcon:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(statusTechId, PlayerUI_GetTeamType() == kMarineTeamType)))
        end
        
    else
    
        self.statusIcon:SetIsVisible(false)
        self.statusBar:SetIsVisible(false)
        self.statusText:SetIsVisible(false)
    
    end
    
    local showEnergy = entity and HasMixin(entity, "Energy")
    local energy = CommanderUI_GetSelectedEnergy(entity)
    
    self.energyText:SetIsVisible(showEnergy)
    self.energyText:SetText(energy)
    self.energyIcon:SetIsVisible(showEnergy)
    
    local singleSelectionCustomText = CommanderUI_GetSingleSelectionCustomText(entity)
    if singleSelectionCustomText and string.len(singleSelectionCustomText) > 0 then
        self.customText:SetIsVisible(true)
        self.customText:SetText(singleSelectionCustomText)
    else
        self.customText:SetIsVisible(false)
    end
    
end

function GUISelectionPanel:UpdateMultiSelection(selectedEntities)

    function SetItemInvisible(item) item:SetIsVisible(false) end
    // Make all previous selection icons invisible.
    table.foreachfunctor(self.multiSelectionIcons, SetItemInvisible)
    
    local currentIconIndex = 1
    for i, selectedEntity in ipairs(selectedEntities) do
        local selectedIcon = nil
        if table.count(self.multiSelectionIcons) >= currentIconIndex then
            selectedIcon = self.multiSelectionIcons[currentIconIndex]
        else
            selectedIcon = self:CreateMultiSelectionIcon()
        end
        selectedIcon:SetIsVisible(true)
        self:SetIconTextureCoordinates(selectedIcon, selectedEntity)
        selectedIcon:SetColor(kIconColors[self.teamType])
        
        local xOffset = -(GUISelectionPanel.kMultiSelectedIconSize * currentIconIndex)
        selectedIcon:SetPosition(Vector(xOffset, -GUISelectionPanel.kMultiSelectedIconSize, 0))
        
        currentIconIndex = currentIconIndex + 1
    end

end

function GUISelectionPanel:CreateMultiSelectionIcon()

    local createdIcon = GUI.CreateItem()
    createdIcon:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    createdIcon:SetSize(Vector(GUISelectionPanel.kMultiSelectedIconSize, GUISelectionPanel.kMultiSelectedIconSize, 0))
    createdIcon:SetTexture("ui/buildmenu.dds")
    self.background:AddChild(createdIcon)
    table.insert(self.multiSelectionIcons, createdIcon)
    return createdIcon

end

function GUISelectionPanel:SendKeyEvent(key, down)

    if key == InputKey.LeftShift then
        if self.tabPressed ~= down then
            self.tabPressed = down
            if down then
                self.highlightedMultiItem = self.highlightedMultiItem + 1
                return true
            end
        end
    end
    
    return false

end

function GUISelectionPanel:SetIconTextureCoordinates(selectedIcon, entity)

    local textureOffsets = CommanderUI_GetSelectedIconOffset(entity)
    local techId = (entity and HasMixin(entity, "Tech")) and entity:GetTechId() or kTechId.None
    local texCoords = GetTextureCoordinatesForIcon(techId)
    
    selectedIcon:SetTexturePixelCoordinates(unpack(texCoords))
    
end

function GUISelectionPanel:GetBackground()
    return self.background
end

function GUISelectionPanel:ContainsPoint(pointX, pointY)
    return self.background:GetIsVisible() and GUIItemContainsPoint(self.background, pointX, pointY)
end