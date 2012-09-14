// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIInsight_Tech.lua
//
// Created by: Dghelneshi (nitro35@hotmail.de)
//
// Spectator: Displays team technology
//
// Requires a complete rewrite at some point. E.g. introduce upgrade icons as a separate class.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIInsight_Tech' (GUIScript)

GUIInsight_Tech.kTechIconTextureMarine = "ui/marine_buildmenu.dds"
GUIInsight_Tech.kTechIconTextureAlien = "ui/alien_buildmenu.dds"
GUIInsight_Tech.kFrameTexture = "ui/tech.dds"
GUIInsight_Tech.kGridMarineTexture = "ui/techgridmarine.dds"
GUIInsight_Tech.kGridAlienTexture = "ui/techgridalien.dds"
GUIInsight_Tech.kEdgeTexture = "ui/techedges.dds"
GUIInsight_Tech.kMarineBackgroundTexture = "ui/marinetechbackground.dds"
GUIInsight_Tech.kAlienBackgroundTexture = "ui/alientechbackground.dds"
GUIInsight_Tech.kHorizontalBarTexture = "ui/repeatable_bar_horizontal.dds"
GUIInsight_Tech.kVerticalBarTexture = "ui/repeatable_bar_vertical.dds"

GUIInsight_Tech.kButtonStatusEnabled = Color(1, 1, 1, 1)
GUIInsight_Tech.kButtonStatusRed = Color(1, 0, 0, 1)
GUIInsight_Tech.kButtonStatusOff = Color(0.3, 0.3, 0.3, 1)

-- Also change in OnResolutionChanged!
GUIInsight_Tech.kTechIconSize = Vector(Clamp(GUIScale(42), 25, 53), Clamp(GUIScale(42), 25, 53), 0)

GUIInsight_Tech.gUpgradeIcons = {}

GUIInsight_Tech.gUpgradeFlashes = {}
GUIInsight_Tech.gFlashStartTime = {}
GUIInsight_Tech.gAlreadyFlashed = {}

GUIInsight_Tech.gResearchBars = {}
GUIInsight_Tech.gResearchStarted = {}

GUIInsight_Tech.kRelevantIdMaskMarine = TeamInfo.kRelevantIdMaskMarine
GUIInsight_Tech.kRelevantIdMaskAlien = TeamInfo.kRelevantIdMaskAlien

GUIInsight_Tech.kRelevantTechIdsMarine = TeamInfo.kRelevantTechIdsMarine
GUIInsight_Tech.kRelevantTechIdsAlien = TeamInfo.kRelevantTechIdsAlien

local techIdGridPosition =
{
    
    [kTechId.AdvancedArmory] =      Vector(0, 1, 0),

    [kTechId.Weapons1] =            Vector(0, 2, 0),
--  [kTechId.Weapons2] =            Vector(0, 2, 0),
--  [kTechId.Weapons3] =            Vector(0, 2, 0),
    [kTechId.Armor1] =              Vector(1, 2, 0),
--  [kTechId.Armor2] =              Vector(1, 2, 0),
--  [kTechId.Armor3] =              Vector(1, 2, 0),
    [kTechId.JetpackTech] =         Vector(2, 2, 0),
    [kTechId.HeavyArmorTech] =      Vector(3, 2, 0),
    [kTechId.MotionTracking] =      Vector(4, 2, 0),

    [kTechId.ARCRoboticsFactory] =  Vector(0, 3, 0),
    [kTechId.PhaseTech] =           Vector(4, 3, 0),

    [kTechId.Leap] =                Vector(0, 0, 0),
    [kTechId.BileBomb] =            Vector(1, 0, 0),
    [kTechId.Umbra] =               Vector(2, 0, 0),
    [kTechId.Metabolize] =          Vector(3, 0, 0),
    [kTechId.Stomp] =               Vector(4, 0, 0),
    
    [kTechId.Xenocide] =            Vector(0, 1, 0),
    [kTechId.Web] =                 Vector(1, 1, 0),
    [kTechId.PrimalScream] =        Vector(2, 1, 0),
    [kTechId.AcidRocket] =          Vector(3, 1, 0),
    [kTechId.Smash] =               Vector(4, 1, 0),
    
    [kTechId.CragHive] =            Vector(0, 2, 0),
    [kTechId.Crag] =                Vector(1, 2, 0),
    
    [kTechId.ShadeHive] =           Vector(2, 2, 0),
    [kTechId.Shade] =               Vector(3, 2, 0),
    
    [kTechId.ShiftHive] =           Vector(0, 3, 0),
    [kTechId.Shift] =               Vector(1, 3, 0),
    
    [kTechId.WhipHive] =            Vector(2, 3, 0),
    [kTechId.Whip] =                Vector(3, 3, 0),
}

local rows = 4
local cols = 5
local scale = 0.5

local marineLeftCornerCoords = {0,0,110,110}
local marineLeftBottomCoords = {0,110,110,256}
local marineRightCornerCoords= {146,0,256,110}
local marineRightBottomCoords= {146,110,256,256}
local marineLeftBarCoords =    {0,0,64,288}
local marineRightBarCoords =   {64,0,128,288}

local alienLeftCornerCoords =  {256,0,366,110}
local alienLeftBottomCoords =  {256,110,366,256}
local alienRightCornerCoords = {402,0,512,110}
local alienRightBottomCoords = {402,110,512,256}
local alienLeftBarCoords =     {128,0,192,288}
local alienRightBarCoords =    {192,0,256,288}

local hBarCoords = Vector(484,80,0)
local hBarHeight = GUIScale(12)
local hBarWidth = (hBarCoords.x/hBarCoords.y) * hBarHeight
local hBarTextureWidth = (GUIInsight_Tech.kTechIconSize.x*cols/hBarWidth) * hBarCoords.x

local vBarSize = GUIScale(Vector(28,120,0))

function GUIInsight_Tech:Initialize()

    self.hidden = false
    
    local statsSize = GUIInsight_Statistics:GetBackgroundSize()

    -- Marines
    
    self.marineTechBackground = GUIManager:CreateGraphicItem()
    self.marineTechBackground:SetSize(Vector(GUIInsight_Tech.kTechIconSize.x * cols, GUIInsight_Tech.kTechIconSize.y * rows, 0))
    self.marineTechBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.marineTechBackground:SetPosition(Vector(-GUIInsight_Tech.kTechIconSize.x * cols - statsSize.x/2 - hBarHeight, -GUIInsight_Tech.kTechIconSize.y * rows, 0))
    self.marineTechBackground:SetTexture(self.kMarineBackgroundTexture)
    self.marineTechBackground:SetTexturePixelCoordinates(unpack({0,0,512,512}))
    self.marineTechBackground:SetColor(Color(1,1,1,0.9))
    self.marineTechBackground:SetLayer(kGUILayerInsight)
    
    self.marineTechGrid = GUIManager:CreateGraphicItem()
    self.marineTechGrid:SetSize(Vector(GUIInsight_Tech.kTechIconSize.x * cols, GUIInsight_Tech.kTechIconSize.y * rows, 0))
    self.marineTechGrid:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.marineTechGrid:SetTexture(self.kGridMarineTexture)
    self.marineTechGrid:SetTexturePixelCoordinates(unpack({0,0,80*cols,80*rows}))
    self.marineTechGrid:SetColor(Color(0.302, 0.859, 1, 0.75))
    self.marineTechBackground:AddChild(self.marineTechGrid)
        
    local techIdsMarine = GUIInsight_Tech.kRelevantTechIdsMarine
    for i = 1, #techIdsMarine do

        self:CreateUpgradeIcon(techIdsMarine[i], true)

    end
        
    -- Marine Frame
    
    local topBar = GUIManager:CreateGraphicItem()
    topBar:SetSize(Vector(self.kTechIconSize.x*cols,hBarHeight,0))
    topBar:SetPosition(Vector(0,-hBarHeight,0))
    topBar:SetTexture(self.kHorizontalBarTexture)
    topBar:SetTexturePixelCoordinates(unpack({0,0,hBarTextureWidth,hBarCoords.y}))
    topBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    topBar:SetLayer(kGUILayerInsight)
    self.marineTechBackground:AddChild(topBar)
        
    local leftBar = GUIManager:CreateGraphicItem()
    leftBar:SetSize(vBarSize)
    leftBar:SetPosition(Vector(-vBarSize.x,GUIScale(10),0))
    leftBar:SetTexture(self.kEdgeTexture)
    leftBar:SetTexturePixelCoordinates(unpack(marineLeftBarCoords))
    leftBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    leftBar:SetLayer(kGUILayerInsight)
    self.marineTechBackground:AddChild(leftBar)
    
    local rightBar = GUIManager:CreateGraphicItem()
    rightBar:SetSize(vBarSize)
    rightBar:SetPosition(Vector(0,GUIScale(10),0))
    rightBar:SetTexture(self.kEdgeTexture)
    rightBar:SetTexturePixelCoordinates(unpack(marineRightBarCoords))
    rightBar:SetAnchor(GUIItem.Right, GUIItem.Top)
    rightBar:SetLayer(kGUILayerInsight)
    self.marineTechBackground:AddChild(rightBar)
    
    local leftcorner = GUIManager:CreateGraphicItem()
    leftcorner:SetSize(Vector(GUIScale(scale*110),GUIScale(scale*110),0))
    leftcorner:SetPosition(-Vector(GUIScale(scale*55),GUIScale(scale*55),0))
    leftcorner:SetTexture(self.kFrameTexture)
    leftcorner:SetTexturePixelCoordinates(unpack(marineLeftCornerCoords))
    leftcorner:SetAnchor(GUIItem.Left, GUIItem.Top)
    leftcorner:SetLayer(kGUILayerInsight+1)
    self.marineTechBackground:AddChild(leftcorner)
    
    local leftbottom = GUIManager:CreateGraphicItem()
    leftbottom:SetSize(Vector(GUIScale(scale*110),GUIScale(scale*146),0))
    leftbottom:SetPosition(-Vector(GUIScale(scale*55),GUIScale(scale*146),0))
    leftbottom:SetTexture(self.kFrameTexture)
    leftbottom:SetTexturePixelCoordinates(unpack(marineLeftBottomCoords))
    leftbottom:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    leftbottom:SetLayer(kGUILayerInsight+1)
    self.marineTechBackground:AddChild(leftbottom)
    
    local rightcorner = GUIManager:CreateGraphicItem()
    rightcorner:SetSize(Vector(GUIScale(scale*110),GUIScale(scale*110),0))
    rightcorner:SetPosition(-Vector(GUIScale(scale*55),GUIScale(scale*55),0))
    rightcorner:SetTexture(self.kFrameTexture)
    rightcorner:SetTexturePixelCoordinates(unpack(marineRightCornerCoords))
    rightcorner:SetAnchor(GUIItem.Right, GUIItem.Top)
    rightcorner:SetLayer(kGUILayerInsight+1)
    self.marineTechBackground:AddChild(rightcorner)
    
    local rightbottom = GUIManager:CreateGraphicItem()
    rightbottom:SetSize(Vector(GUIScale(scale*110),GUIScale(scale*146),0))
    rightbottom:SetPosition(-Vector(GUIScale(scale*55),GUIScale(scale*146),0))
    rightbottom:SetTexture(self.kFrameTexture)
    rightbottom:SetTexturePixelCoordinates(unpack(marineRightBottomCoords))
    rightbottom:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    rightbottom:SetLayer(kGUILayerInsight+1)
    self.marineTechBackground:AddChild(rightbottom)
    
    -- Aliens
    
    self.alienTechBackground = GUIManager:CreateGraphicItem()
    self.alienTechBackground:SetSize(Vector(GUIInsight_Tech.kTechIconSize.x * cols, GUIInsight_Tech.kTechIconSize.y * rows, 0))
    self.alienTechBackground:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.alienTechBackground:SetPosition(Vector(statsSize.x/2 + hBarHeight, -GUIInsight_Tech.kTechIconSize.y * rows, 0))
    self.alienTechBackground:SetTexture(self.kAlienBackgroundTexture)
    self.alienTechBackground:SetTexturePixelCoordinates(unpack({0,0,512,512}))
    self.alienTechBackground:SetColor(Color(1,1,1,0.9))
    self.alienTechBackground:SetLayer(kGUILayerInsight)
    
    self.alienTechGrid = GUIManager:CreateGraphicItem()
    self.alienTechGrid:SetSize(Vector(GUIInsight_Tech.kTechIconSize.x * cols, GUIInsight_Tech.kTechIconSize.y * rows, 0))
    self.alienTechGrid:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.alienTechGrid:SetTexture(self.kGridAlienTexture)
    self.alienTechGrid:SetTexturePixelCoordinates(unpack({0,0,80*cols,80*rows}))
    self.alienTechGrid:SetColor(Color(1, .61, 0, 0.6))
    self.alienTechBackground:AddChild(self.alienTechGrid)
    
    local techIdsAlien = GUIInsight_Tech.kRelevantTechIdsAlien
    for i = 1, #techIdsAlien do

        self:CreateUpgradeIcon(techIdsAlien[i], false)

    end
    
    -- Alien Frame
    
    topBar = GUIManager:CreateGraphicItem()
    topBar:SetSize(Vector(self.kTechIconSize.x*cols,hBarHeight,0))
    topBar:SetPosition(Vector(0,-hBarHeight,0))
    topBar:SetTexture(self.kHorizontalBarTexture)
    topBar:SetTexturePixelCoordinates(unpack({hBarTextureWidth,hBarCoords.y,0,2*hBarCoords.y}))
    topBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    topBar:SetLayer(kGUILayerInsight)
    self.alienTechBackground:AddChild(topBar)
    
    leftBar = GUIManager:CreateGraphicItem()
    leftBar:SetSize(vBarSize)
    leftBar:SetPosition(Vector(-vBarSize.x,GUIScale(10),0))
    leftBar:SetTexture(self.kEdgeTexture)
    leftBar:SetTexturePixelCoordinates(unpack(alienLeftBarCoords))
    leftBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    leftBar:SetLayer(kGUILayerInsight)
    self.alienTechBackground:AddChild(leftBar)
    
    rightBar = GUIManager:CreateGraphicItem()
    rightBar:SetSize(vBarSize)
    rightBar:SetPosition(Vector(0,GUIScale(10),0))
    rightBar:SetTexture(self.kEdgeTexture)
    rightBar:SetTexturePixelCoordinates(unpack(alienRightBarCoords))
    rightBar:SetAnchor(GUIItem.Right, GUIItem.Top)
    rightBar:SetLayer(kGUILayerInsight)
    self.alienTechBackground:AddChild(rightBar)
        
    leftcorner = GUIManager:CreateGraphicItem()
    leftcorner:SetSize(Vector(GUIScale(scale*110),GUIScale(scale*110),0))
    leftcorner:SetPosition(-Vector(GUIScale(scale*55),GUIScale(scale*55),0))
    leftcorner:SetTexture(self.kFrameTexture)
    leftcorner:SetTexturePixelCoordinates(unpack(alienLeftCornerCoords))
    leftcorner:SetAnchor(GUIItem.Left, GUIItem.Top)
    leftcorner:SetLayer(kGUILayerInsight+1)
    self.alienTechBackground:AddChild(leftcorner)
    
    leftbottom = GUIManager:CreateGraphicItem()
    leftbottom:SetSize(Vector(GUIScale(scale*110),GUIScale(scale*146),0))
    leftbottom:SetPosition(-Vector(GUIScale(scale*55),GUIScale(scale*146),0))
    leftbottom:SetTexture(self.kFrameTexture)
    leftbottom:SetTexturePixelCoordinates(unpack(alienLeftBottomCoords))
    leftbottom:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    leftbottom:SetLayer(kGUILayerInsight+1)
    self.alienTechBackground:AddChild(leftbottom)
    
    rightcorner = GUIManager:CreateGraphicItem()
    rightcorner:SetSize(Vector(GUIScale(scale*110),GUIScale(scale*110),0))
    rightcorner:SetPosition(-Vector(GUIScale(scale*55),GUIScale(scale*55),0))
    rightcorner:SetTexture(self.kFrameTexture)
    rightcorner:SetTexturePixelCoordinates(unpack(alienRightCornerCoords))
    rightcorner:SetAnchor(GUIItem.Right, GUIItem.Top)
    rightcorner:SetLayer(kGUILayerInsight+1)
    self.alienTechBackground:AddChild(rightcorner)
    
    rightbottom = GUIManager:CreateGraphicItem()
    rightbottom:SetSize(Vector(GUIScale(scale*110),GUIScale(scale*146),0))
    rightbottom:SetPosition(-Vector(GUIScale(scale*55),GUIScale(scale*146),0))
    rightbottom:SetTexture(self.kFrameTexture)
    rightbottom:SetTexturePixelCoordinates(unpack(alienRightBottomCoords))
    rightbottom:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    rightbottom:SetLayer(kGUILayerInsight+1)
    self.alienTechBackground:AddChild(rightbottom)
    
end

function GUIInsight_Tech:Uninitialize()

    GUI.DestroyItem(self.marineTechBackground)
    self.marineTechBackground = nil

    GUI.DestroyItem(self.alienTechBackground)
    self.alienTechBackground = nil

    for i, techId in ipairs(GUIInsight_Tech.kRelevantTechIdsMarine) do

        local techIdString = EnumToString(kTechId, techId)

        self.gResearchBars[techIdString] = nil
        self.gUpgradeIcons[techIdString] = nil
        self.gUpgradeFlashes[techIdString] = nil

    end

    for i, techId in ipairs(GUIInsight_Tech.kRelevantTechIdsAlien) do

        local techIdString = EnumToString(kTechId, techId)

        self.gResearchBars[techIdString] = nil
        self.gUpgradeIcons[techIdString] = nil
        self.gUpgradeFlashes[techIdString] = nil

    end

end

function GUIInsight_Tech:OnResolutionChanged(oldX, oldY, newX, newY)

    self:Uninitialize()
    
    GUIInsight_Tech.kTechIconSize = Vector(Clamp(GUIScale(42), 25, 53), Clamp(GUIScale(42), 25, 53), 0)

    self:Initialize()
    
end

function GUIInsight_Tech:CreateUpgradeIcon(techId, isMarine)

    local position = Vector(0, 0, 0)
    
    if techIdGridPosition[techId] then

        if isMarine then

            position.x = GUIInsight_Tech.kTechIconSize.x * techIdGridPosition[techId].x
            position.y = GUIInsight_Tech.kTechIconSize.y * techIdGridPosition[techId].y

            self.gUpgradeIcons[EnumToString(kTechId, techId)] = GetGUIManager():CreateGraphicItem()
            self.gUpgradeIcons[EnumToString(kTechId, techId)]:SetTexture(GUIInsight_Tech.kTechIconTextureMarine)
            self.gUpgradeIcons[EnumToString(kTechId, techId)]:SetAnchor(GUIItem.Left, GUIItem.Top)
            self.gUpgradeIcons[EnumToString(kTechId, techId)]:SetSize(GUIInsight_Tech.kTechIconSize)
            self.gUpgradeIcons[EnumToString(kTechId, techId)]:SetPosition(position)
            self.gUpgradeIcons[EnumToString(kTechId, techId)]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, true)))
            self.marineTechBackground:AddChild(self.gUpgradeIcons[EnumToString(kTechId, techId)])
            
        else

            position.x = GUIInsight_Tech.kTechIconSize.x * techIdGridPosition[techId].x
            position.y = GUIInsight_Tech.kTechIconSize.y * techIdGridPosition[techId].y

            self.gUpgradeIcons[EnumToString(kTechId, techId)] = GetGUIManager():CreateGraphicItem()
            self.gUpgradeIcons[EnumToString(kTechId, techId)]:SetTexture(GUIInsight_Tech.kTechIconTextureAlien)
            self.gUpgradeIcons[EnumToString(kTechId, techId)]:SetAnchor(GUIItem.Left, GUIItem.Top)
            self.gUpgradeIcons[EnumToString(kTechId, techId)]:SetSize(GUIInsight_Tech.kTechIconSize)
            self.gUpgradeIcons[EnumToString(kTechId, techId)]:SetPosition(position)
            
--            if not (techId == kTechId.TwoHives) then --  or techId == kTechId.ThreeHives
                self.gUpgradeIcons[EnumToString(kTechId, techId)]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, false)))
--            else
--                self.gUpgradeIcons[EnumToString(kTechId, techId)]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.Augmentation, false)))
--            end
            
            self.alienTechBackground:AddChild(self.gUpgradeIcons[EnumToString(kTechId, techId)])

        end

    end
    
end

function GUIInsight_Tech:SetIsVisible(bool)

    self.marineTechBackground:SetIsVisible(bool)
    self.alienTechBackground:SetIsVisible(bool)

end

function GUIInsight_Tech:Update(deltaTime)

    PROFILE("GUIInsight_Tech:Update")

    if self.marineTechBackground:GetIsVisible() then  -- we assume they both get toggled at the same time
    
        local player = Client.GetLocalPlayer()
        if player == nil then
            return
        end

        if self.lastUpdateTime == nil or Shared.GetTime() > (self.lastUpdateTime + 1) then

            local marineTeamInfo = GetEntitiesForTeam("TeamInfo", kTeam1Index)
            if table.count(marineTeamInfo) > 0 then

                for i, techId in ipairs(GUIInsight_Tech.kRelevantTechIdsMarine) do

                    self:UpdateTechDisplay(techId, marineTeamInfo[1], true)

                end

            end

            local alienTeamInfo = GetEntitiesForTeam("TeamInfo", kTeam2Index)
            if table.count(alienTeamInfo) > 0 then

                for i, techId in ipairs(GUIInsight_Tech.kRelevantTechIdsAlien) do

                    self:UpdateTechDisplay(techId, alienTeamInfo[1], false)

                end

            end

            self.lastUpdateTime = Shared.GetTime()

        end

        -- needs more fps!
        for i, techId in ipairs(GUIInsight_Tech.kRelevantTechIdsMarine) do
            self:UpdateFlashIcon(techId)
        end

        for i, techId in ipairs(GUIInsight_Tech.kRelevantTechIdsAlien) do
            self:UpdateFlashIcon(techId)
        end

    end
    
end

local ArmorWeaponsIdStrings = {

    ["Armor1"] = true,
    ["Armor2"] = true,
    ["Armor3"] = true,
    ["Weapons1"] = true,
    ["Weapons2"] = true,
    ["Weapons3"] = true

}
local ArmorIdStrings = {

    ["Armor1"] = true,
    ["Armor2"] = true,
    ["Armor3"] = true

}
local WeaponsIdStrings = {

    ["Weapons1"] = true,
    ["Weapons2"] = true,
    ["Weapons3"] = true

}
local AlienTier3Strings = {

    ["Xenocide"] = true,
    ["WebStalk"] = true,
    ["Umbra"] = true,
    ["AcidRocket"] = true,
    ["Stomp"] = true -- Stomp is T3 right now, maybe Primal will be T2 or T4?
    
}
local AlienTier2Strings = {
    
    ["Leap"] = true,
    ["BileBomb"] = true,
    ["Spores"] = true,
    ["Blink"] = true,
--    ["Stomp"] = true -- Stomp is T3 right now, maybe Primal will be T2 or T4? 

}

function GUIInsight_Tech:UpdateTechDisplay(techId, teamInfo, isMarine)

    local techIdString = EnumToString(kTechId, techId)

    local capturedTechPoints = teamInfo:GetNumCapturedTechPoints()
    local armsLabUp = teamInfo:IsArmsLabUp()
    local protoLabUp = teamInfo:IsProtoLabUp()
    local observatoryUp = teamInfo:IsObservatoryUp()
    local roboticsUp = teamInfo:IsRoboticsUp()
    local techResearching = 0
    local techResearched = 0

    if isMarine then
        techResearching, techResearched = teamInfo:GetTeamTechTreeInfoMarine()
    else
        techResearching, techResearched = teamInfo:GetTeamTechTreeInfoAlien()
    end

    local isDisabled = false
    if self.gAlreadyFlashed[techIdString] then
        isDisabled = true  -- only used for lost alien evolutions
    end

    local AAUp = bit.band(techResearched, GUIInsight_Tech.kRelevantIdMaskMarine["AdvancedArmory"]) > 0

    if isMarine then

        if bit.band(techResearched, GUIInsight_Tech.kRelevantIdMaskMarine[techIdString]) > 0 then

            if ArmorIdStrings[techIdString] then

                self.gUpgradeIcons["Armor1"]:SetColor(self.kButtonStatusEnabled)

                self.gUpgradeIcons["Armor1"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, true)))

                if not armsLabUp then
                    self.gUpgradeIcons["Armor1"]:SetColor(self.kButtonStatusRed)
                end

            elseif WeaponsIdStrings[techIdString] then

                self.gUpgradeIcons["Weapons1"]:SetColor(self.kButtonStatusEnabled)

                self.gUpgradeIcons["Weapons1"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, true)))

                if not armsLabUp then
                    self.gUpgradeIcons["Weapons1"]:SetColor(self.kButtonStatusRed)
                end

            elseif self.gUpgradeIcons[techIdString] then -- needed since there may be other research which isn't actually on the grid (like the fake entries)

                self.gUpgradeIcons[techIdString]:SetColor(self.kButtonStatusEnabled)

                if techIdString == "JetpackTech" then

                    if (not protoLabUp) or (capturedTechPoints < 2) then
                        self.gUpgradeIcons[techIdString]:SetColor(self.kButtonStatusRed)
                    end
                    
                elseif techIdString == "PhaseTech" or  techIdString == "MotionTracking" then

                    if not observatoryUp then
                        self.gUpgradeIcons[techIdString]:SetColor(self.kButtonStatusRed)
                    end
                
                end
                
            end
            
            -- temporary alerts for 217
            if (not self.gUpgradeFlashes[techIdString]) and ((not self.gAlreadyFlashed[techIdString]) or (self.gFlashStartTime[techIdString] and (self.gFlashStartTime[techIdString] < PlayerUI_GetGameStartTime()))) and
               self.gUpgradeIcons[techIdString] then
            
                local text = string.format("%s Completed", GetDisplayNameForTechId(techId, "Tech"))
                
                local icon = {Texture = "ui/marine_buildmenu.dds", TextureCoordinates = GetTextureCoordinatesForIcon(techId, true), Color = Color(1,1,1,0.5), Size = Vector(15,15,0)}
                local info = {Text = text, Scale = Vector(0.2,0.2,0.2), Color = Color(0.5,0.5,0.5,0.5), ShadowColor = Color(0,0,0,0.5)}
                local position = self.gUpgradeIcons[techIdString]:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
                
                local alert = GUIInsight_AlertQueue:CreateAlert(position, icon, info, kTeam1Index)
                GUIInsight_AlertQueue:AddAlert(alert, Color(1,1,1,1), Color(1,1,1,1))
                
            end
            
            self:DestroyResearchBar(techIdString)

            self:CreateDestroyFlashIcon(techId)

        elseif bit.band(techResearching, GUIInsight_Tech.kRelevantIdMaskMarine[techIdString]) > 0 then

            if ArmorIdStrings[techIdString] then

                self.gUpgradeIcons["Armor1"]:SetColor(self.kButtonStatusEnabled)

                self.gUpgradeIcons["Armor1"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, true)))

            elseif WeaponsIdStrings[techIdString] then

                self.gUpgradeIcons["Weapons1"]:SetColor(self.kButtonStatusEnabled)

                self.gUpgradeIcons["Weapons1"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, true)))

            elseif self.gUpgradeIcons[techIdString] then -- needed since there may be other research which isn't actually on the grid (like the fake entries)

                self.gUpgradeIcons[techIdString]:SetColor(self.kButtonStatusEnabled)

            end

            -- temporary alerts for 217
            if not self.gResearchBars[techIdString] and self.gUpgradeIcons[techIdString] then

                local text = string.format("%s Started", GetDisplayNameForTechId(techId, "Tech"))
                
                local icon = {Texture = "ui/marine_buildmenu.dds", TextureCoordinates = GetTextureCoordinatesForIcon(techId, true), Color = Color(1,1,1,0.5), Size = Vector(15,15,0)}
                local info = {Text = text, Scale = Vector(0.2,0.2,0.2), Color = Color(0.5,0.5,0.5,0.5), ShadowColor = Color(0,0,0,0.5)}
                local position = self.gUpgradeIcons[techIdString]:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
                
                local alert = GUIInsight_AlertQueue:CreateAlert(position, icon, info, kTeam1Index)
                GUIInsight_AlertQueue:AddAlert(alert, Color(1,1,1,1), Color(1,1,1,1))
            
            end
            
            self:CreateUpdateResearchBar(techIdString, techId)

        else -- if neither researched nor researching
        
            if techIdString == "Armor1" or techIdString == "Weapons1" then

                self.gUpgradeIcons[techIdString]:SetColor(self.kButtonStatusOff)

            elseif not ArmorWeaponsIdStrings[techIdString] and self.gUpgradeIcons[techIdString] then -- do not make icon disabled because of higher level research

                self.gUpgradeIcons[techIdString]:SetColor(self.kButtonStatusOff)
                
            end

            self:DestroyResearchBar(techIdString)

            if self:DestroyFlashIcon(techId) then
                self.gAlreadyFlashed[techIdString] = true
            end

        end

    else -- alien tech

        if bit.band(techResearched, GUIInsight_Tech.kRelevantIdMaskAlien[techIdString]) > 0 then
        
            if AlienTier3Strings[techIdString] then
            
                if techIdString == "Xenocide" then
                
                    if (capturedTechPoints > 2) then
                        self.gUpgradeIcons["Leap"]:SetColor(self.kButtonStatusEnabled)
                    else
                        self.gUpgradeIcons["Leap"]:SetColor(self.kButtonStatusRed)
                    end
                    
                    if (capturedTechPoints < 2) then -- switch to Tier 2 icons if below 2 hives to indicate that T2 abilities are also lost
                        self.gUpgradeIcons["Leap"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.Leap, false)))
                    else 
                        self.gUpgradeIcons["Leap"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, false)))
                    end
                
                elseif techIdString == "WebStalk" then
                
                    if (capturedTechPoints > 2) then
                        self.gUpgradeIcons["BileBomb"]:SetColor(self.kButtonStatusEnabled)
                    else
                        self.gUpgradeIcons["BileBomb"]:SetColor(self.kButtonStatusRed)
                    end
                    
                    if (capturedTechPoints < 2) then -- switch to Tier 2 icons if below 2 hives to indicate that T2 abilities are also lost
                        self.gUpgradeIcons["BileBomb"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.BileBomb, false)))
                    else 
                        self.gUpgradeIcons["BileBomb"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, false)))
                    end
                
                elseif techIdString == "Spikes" then
                
                    if (capturedTechPoints > 2) then
                        self.gUpgradeIcons["Spores"]:SetColor(self.kButtonStatusEnabled)
                    else
                        self.gUpgradeIcons["Spores"]:SetColor(self.kButtonStatusRed)
                    end
                    
                    if (capturedTechPoints < 2) then -- switch to Tier 2 icons if below 2 hives to indicate that T2 abilities are also lost
                        self.gUpgradeIcons["Spores"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.Spores, false)))
                    else 
                        self.gUpgradeIcons["Spores"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, false)))
                    end
                
                elseif techIdString == "AcidRocket" then
                
                    if (capturedTechPoints > 2) then
                        self.gUpgradeIcons["Blink"]:SetColor(self.kButtonStatusEnabled)
                    else
                        self.gUpgradeIcons["Blink"]:SetColor(self.kButtonStatusRed)
                    end
                    
                    if (capturedTechPoints < 2) then -- switch to Tier 2 icons if below 2 hives to indicate that T2 abilities are also lost
                        self.gUpgradeIcons["Blink"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.Blink, false)))
                    else 
                        self.gUpgradeIcons["Blink"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, false)))
                    end
                
                elseif techIdString == "Smash" then
                
                    if (capturedTechPoints > 2) then
                        self.gUpgradeIcons["Stomp"]:SetColor(self.kButtonStatusEnabled)
                    else
                        self.gUpgradeIcons["Stomp"]:SetColor(self.kButtonStatusRed)
                    end
                    
                    self.gUpgradeIcons["Stomp"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, false)))
                
                end
                
            elseif AlienTier2Strings[techIdString] then
            
                if techIdString == "Leap" then
                
                    if (capturedTechPoints > 1) then
                        self.gUpgradeIcons["Leap"]:SetColor(self.kButtonStatusEnabled)
                    else
                        -- T3 is checked after T2, so no need to switch textures twice right now. See above.
                        -- self.gUpgradeIcons["Leap"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, false)))
                        self.gUpgradeIcons["Leap"]:SetColor(self.kButtonStatusRed)
                    end
                    
                
                elseif techIdString == "BileBomb" then
                
                    if (capturedTechPoints > 1) then
                        self.gUpgradeIcons["BileBomb"]:SetColor(self.kButtonStatusEnabled)
                    else
                        self.gUpgradeIcons["BileBomb"]:SetColor(self.kButtonStatusRed)
                        -- self.gUpgradeIcons["BileBomb"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, false)))
                    end
                
                elseif techIdString == "Umbra" then
                
                    if (capturedTechPoints > 1) then
                        self.gUpgradeIcons["Spores"]:SetColor(self.kButtonStatusEnabled)
                    else
                        self.gUpgradeIcons["Spores"]:SetColor(self.kButtonStatusRed)
                        -- self.gUpgradeIcons["Spores"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, false)))
                    end

                elseif techIdString == "Metabolize" then
                
                    if (capturedTechPoints > 1) then
                        self.gUpgradeIcons["Blink"]:SetColor(self.kButtonStatusEnabled)
                    else
                        self.gUpgradeIcons["Blink"]:SetColor(self.kButtonStatusRed)
                       --  self.gUpgradeIcons["Blink"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, false)))
                    end
                    
                end
            
            elseif self.gUpgradeIcons[techIdString] then -- needed since there may be other research which isn't actually on the grid (like the fake entries)

                self.gUpgradeIcons[techIdString]:SetColor(self.kButtonStatusEnabled)

            end
            
            -- temporary alerts for 217
            if (not self.gUpgradeFlashes[techIdString]) and ((not self.gAlreadyFlashed[techIdString]) or (self.gFlashStartTime[techIdString] and (self.gFlashStartTime[techIdString] < PlayerUI_GetGameStartTime()))) and
               self.gUpgradeIcons[techIdString] then
            
                local text = string.format("%s Completed", GetDisplayNameForTechId(techId, "Tech"))
                
                local icon = {Texture = "ui/alien_buildmenu.dds", TextureCoordinates = GetTextureCoordinatesForIcon(techId, false), Color = Color(1,1,1,0.5), Size = Vector(15,15,0)}
                local info = {Text = text, Scale = Vector(0.2,0.2,0.2), Color = Color(0.5,0.5,0.5,0.5), ShadowColor = Color(0,0,0,0.5)}
                local position = self.gUpgradeIcons[techIdString]:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
                
                local alert = GUIInsight_AlertQueue:CreateAlert(position, icon, info, kTeam2Index)
                GUIInsight_AlertQueue:AddAlert(alert, Color(1,1,1,1), Color(1,1,1,1))
                
            end

            self:DestroyResearchBar(techIdString)

            self:CreateDestroyFlashIcon(techId)

        elseif bit.band(techResearching, GUIInsight_Tech.kRelevantIdMaskAlien[techIdString]) > 0 then

            if AlienTier3Strings[techIdString] then
            
                if techIdString == "Xenocide" then
                
                    self.gUpgradeIcons["Leap"]:SetColor(self.kButtonStatusEnabled)
                    
                    self.gUpgradeIcons["Leap"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, false)))
                
                elseif techIdString == "WebStalk" then
                
                    self.gUpgradeIcons["BileBomb"]:SetColor(self.kButtonStatusEnabled)
                    
                    self.gUpgradeIcons["BileBomb"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, false)))
                
                elseif techIdString == "Spikes" then
                
                    self.gUpgradeIcons["Spores"]:SetColor(self.kButtonStatusEnabled)
                    
                    self.gUpgradeIcons["Spores"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, false)))
                
                elseif techIdString == "AcidRocket" then
                
                    self.gUpgradeIcons["Blink"]:SetColor(self.kButtonStatusEnabled)
                    
                    self.gUpgradeIcons["Blink"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, false)))
                
                elseif techIdString == "Smash" then -- Stomp is T3 right now, maybe Primal will be T2 or T4?
                
                    self.gUpgradeIcons["Stomp"]:SetColor(self.kButtonStatusEnabled)
                    
                    self.gUpgradeIcons["Stomp"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(techId, false)))
                
                end
            
            elseif self.gUpgradeIcons[techIdString] then -- needed since there may be other research which isn't actually on the grid (like the fake entries)

                self.gUpgradeIcons[techIdString]:SetColor(self.kButtonStatusEnabled)

            end

            -- temporary alerts for 217
            if not self.gResearchBars[techIdString] and self.gUpgradeIcons[techIdString] then

                local text = string.format("%s Started", GetDisplayNameForTechId(techId, "Tech"))
                
                local icon = {Texture = "ui/alien_buildmenu.dds", TextureCoordinates = GetTextureCoordinatesForIcon(techId, false), Color = Color(1,1,1,0.5), Size = Vector(15,15,0)}
                local info = {Text = text, Scale = Vector(0.2,0.2,0.2), Color = Color(0.5,0.5,0.5,0.5), ShadowColor = Color(0,0,0,0.5)}
                local position = self.gUpgradeIcons[techIdString]:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
                
                local alert = GUIInsight_AlertQueue:CreateAlert(position, icon, info, kTeam2Index)
                GUIInsight_AlertQueue:AddAlert(alert, Color(1,1,1,1), Color(1,1,1,1))
            
            end
            
            self:CreateUpdateResearchBar(techIdString, techId)

        else -- if neither researched nor researching (also includes lost evolutions for aliens, though not T2/T3 abilities)

            if techIdString == "CragHive" or techIdString == "ShadeHive" or techIdString == "ShiftHive" then
            
                self.gUpgradeIcons[techIdString]:SetColor(self.kButtonStatusOff)
                
            elseif self.gUpgradeIcons[techIdString] then -- needed since there may be other research which isn't actually on the grid (like the fake entries)
            
                if isDisabled then
                    self.gUpgradeIcons[techIdString]:SetColor(self.kButtonStatusRed)
                else
                    self.gUpgradeIcons[techIdString]:SetColor(self.kButtonStatusOff)
                end
                
            end
            
            self:DestroyResearchBar(techIdString)

            if self:DestroyFlashIcon(techId) then
                self.gAlreadyFlashed[techIdString] = true
            end

        end

    end

end

function GUIInsight_Tech:CreateUpdateResearchBar(techIdString, techId)

    if not self.gResearchBars[techIdString] then

        if (not self.gResearchStarted[techIdString]) or (self.gResearchStarted[techIdString] < PlayerUI_GetGameStartTime())  then

            self.gResearchStarted[techIdString] = Shared.GetTime()

        end

        self.gResearchBars[techIdString] = GUIManager:CreateGraphicItem()
        self.gResearchBars[techIdString]:SetColor(Color(0.8, 0.9, 1, 1))
        self.gResearchBars[techIdString]:SetSize(Vector(0, 4, 0))
        self.gResearchBars[techIdString]:SetPosition(Vector(0, 0, 0))
        self.gResearchBars[techIdString]:SetAnchor(GUIItem.Left, GUIItem.Top)
        
        if ArmorIdStrings[techIdString] then
        
            self.gUpgradeIcons["Armor1"]:AddChild(self.gResearchBars[techIdString])
            
        elseif WeaponsIdStrings[techIdString] then
        
            self.gUpgradeIcons["Weapons1"]:AddChild(self.gResearchBars[techIdString])
            
        elseif self.gUpgradeIcons[techIdString] then
        
            self.gUpgradeIcons[techIdString]:AddChild(self.gResearchBars[techIdString])
            
        else -- needed since there may be other research which isn't actually on the grid (like the fake entries)
        
            self:DestroyResearchBar(techIdString)
            
        end

    elseif self.gResearchStarted[techIdString] then

        local timeSinceStart = Shared.GetTime() - self.gResearchStarted[techIdString]
        local researchTime = LookupTechData(techId, kTechDataResearchTimeKey, 1)

        self.gResearchBars[techIdString]:SetSize(Vector(timeSinceStart/researchTime*GUIInsight_Tech.kTechIconSize.x, Clamp(GUIScale(5), 4, 7), 0))

    end

end

function GUIInsight_Tech:DestroyResearchBar(techIdString)

    if self.gResearchBars[techIdString] then

        GUI.DestroyItem(self.gResearchBars[techIdString])
        self.gResearchBars[techIdString] = nil

    end

    if self.gResearchStarted[techIdString] then

        self.gResearchStarted[techIdString] = nil

    end

end

function GUIInsight_Tech:CreateDestroyFlashIcon(techId)

    local position = Vector(0, 0, 0)
    local techIdString = EnumToString(kTechId, techId)

    // UGH. if flash does not exist and either it hasn't already flashed or the flash start time is before last round restart
    if (not self.gUpgradeFlashes[techIdString]) and ((not self.gAlreadyFlashed[techIdString]) or (self.gFlashStartTime[techIdString] and (self.gFlashStartTime[techIdString] < PlayerUI_GetGameStartTime()))) then

        if (not self.gFlashStartTime[techIdString]) then

            self.gFlashStartTime[techIdString] = Shared.GetTime()

        end

        self.gUpgradeFlashes[techIdString] = GetGUIManager():CreateGraphicItem()
        self.gUpgradeFlashes[techIdString]:SetAnchor(GUIItem.Left, GUIItem.Top)
        self.gUpgradeFlashes[techIdString]:SetSize(GUIInsight_Tech.kTechIconSize)
        self.gUpgradeFlashes[techIdString]:SetPosition(position)
        self.gUpgradeFlashes[techIdString]:SetColor(Color(1, 1, 1, 0))
        self.gUpgradeFlashes[techIdString]:SetIsVisible(true)
        
        if ArmorIdStrings[techIdString] then
        
            self.gUpgradeIcons["Armor1"]:AddChild(self.gUpgradeFlashes[techIdString])
            
        elseif WeaponsIdStrings[techIdString] then
        
            self.gUpgradeIcons["Weapons1"]:AddChild(self.gUpgradeFlashes[techIdString])
            
        elseif self.gUpgradeIcons[techIdString] then
        
            self.gUpgradeIcons[techIdString]:AddChild(self.gUpgradeFlashes[techIdString])
            
        else  -- needed since there may be other research which isn't actually on the grid (like the fake entries)
        
            self:DestroyFlashIcon(techId)
        
        end
           
    elseif self.gFlashStartTime[techIdString] then

        if (Shared.GetTime() - self.gFlashStartTime[techIdString]) > 5 then

            if self:DestroyFlashIcon(techId) then
                self.gAlreadyFlashed[techIdString] = true
            end
            
        end

    end

end

function GUIInsight_Tech:DestroyFlashIcon(techId)

    local techIdString = EnumToString(kTechId, techId)

    if self.gFlashStartTime[techIdString] then
        self.gFlashStartTime[techIdString] = nil
    end
    if self.gUpgradeFlashes[techIdString] then
    
        GUI.DestroyItem(self.gUpgradeFlashes[techIdString])
        self.gUpgradeFlashes[techIdString] = nil
        
        return true
        
    end
    
    return false

end

function GUIInsight_Tech:UpdateFlashIcon(techId)

    local techIdString = EnumToString(kTechId, techId)

    if self.gUpgradeFlashes[techIdString] and self.gFlashStartTime[techIdString] then

        local timeSinceStart = Shared.GetTime() - self.gFlashStartTime[techIdString]

        self.gUpgradeFlashes[techIdString]:SetColor(Color(1, 1, 1, math.abs(0.5-((timeSinceStart % 2)/2))))

    end

end