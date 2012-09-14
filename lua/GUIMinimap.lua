// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMinimap.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying the minimap and icons on the minimap.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/FunctionContracts.lua")

class 'GUIMinimap' (GUIScript)

GUIMinimap.kModeMini = 0
GUIMinimap.kModeBig = 1
GUIMinimap.kModeZoom = 2

GUIMinimap.kMapBackgroundXOffset = 28
GUIMinimap.kMapBackgroundYOffset = 28

GUIMinimap.kBackgroundTextureAlien = "ui/alien_commander_background.dds"
GUIMinimap.kBackgroundTextureMarine = "ui/marine_commander_background.dds"
GUIMinimap.kBackgroundTextureSpec = "ui/minimapbackground.dds"
GUIMinimap.kBackgroundTextureCoords = { X1 = 473, Y1 = 0, X2 = 793, Y2 = 333 }

GUIMinimap.kBigSizeScale = 3
GUIMinimap.kBackgroundSize = GUIScale(300)
GUIMinimap.kBackgroundWidth = GUIMinimap.kBackgroundSize
GUIMinimap.kBackgroundHeight = GUIMinimap.kBackgroundSize

GUIMinimap.kFrameTextureSize = GUIScale( Vector(473, 354, 0) )
GUIMinimap.kMarineFrameTexture = "ui/marine_commander_textures.dds"
GUIMinimap.kFramePixelCoords = { 466, 250 , 466 + 473, 250 + 354 }

GUIMinimap.kMapMinMax = 55
GUIMinimap.kMapRatio = function() return ConditionalValue(Client.minimapExtentScale.z > Client.minimapExtentScale.x, Client.minimapExtentScale.z / Client.minimapExtentScale.x, Client.minimapExtentScale.x / Client.minimapExtentScale.z) end

GUIMinimap.kMinimapSmallSize = Vector(GUIMinimap.kBackgroundWidth, GUIMinimap.kBackgroundHeight, 0)
GUIMinimap.kMinimapBigSize = Vector(GUIMinimap.kBackgroundWidth * GUIMinimap.kBigSizeScale, GUIMinimap.kBackgroundHeight * GUIMinimap.kBigSizeScale, 0)

local kBlipSize = GUIScale(30)
local kZoomedBlipSizeScale = 0.8
GUIMinimap.kUnpoweredNodeBlipSize = GUIScale(32)

local kWaypointColor = Color(1, 1, 1, 1)

GUIMinimap.kUnzoomedColor = Color(1,1,1,0.5)
GUIMinimap.kZoomedColor = Color(1,1,1,0.5)

// colors are defined in the dds
local kTeamColors = { }
kTeamColors[kMinimapBlipTeam.Friendly] = Color(1, 1, 1, 1)
kTeamColors[kMinimapBlipTeam.Enemy] = Color(1, 1, 1, 1)
kTeamColors[kMinimapBlipTeam.Neutral] = Color(1, 1, 1, 1)
kTeamColors[kMinimapBlipTeam.Alien] = Color(1, 1, 1, 1)
kTeamColors[kMinimapBlipTeam.Marine] = Color(1, 1, 1, 1)

local kUnderAttackColor = Color(0.75, 0, 0, 1)
local kBlinkInterval = 1

local kScanColor = Color(0.2, 0.8, 1, 1)
local kScanAnimDuration = 2

GUIMinimap.kPlayerOverLaySize = Vector(kBlipSize * 2.5, kBlipSize * 2.5, 0)

GUIMinimap.kIconFileName = "ui/minimap_blip.dds"
GUIMinimap.kMarineIconFileName = "ui/marine_minimap_blip.dds"

kCommanderPingMinimapSize = Vector(80, 80, 0)

local kBackgroundNoiseTexture = "ui/alien_commander_bg_smoke.dds"
local kSmokeyBackgroundSize = GUIScale(Vector(480, 640, 0))

local function GetIconTextureName(self)

    if self.comMode == GUIMinimap.kModeZoom and PlayerUI_IsOnMarineTeam() then
        return GUIMinimap.kMarineIconFileName    
    end
    
    return GUIMinimap.kIconFileName
    
end

GUIMinimap.kMarineZoomedIconColor = Color(191/255, 226/255, 1, 1)
local function GetPlayerIconColor(self)

    local useColor = Color(1,1,1,1)

    if self.comMode == GUIMinimap.kModeZoom and PlayerUI_IsOnMarineTeam() then
        return GUIMinimap.kMarineZoomedIconColor
    end
    
    if PlayerUI_IsOnMarineTeam() then
        useColor = Color(kMarineTeamColorFloat)
    elseif PlayerUI_IsOnAlienTeam() then
        useColor = Color(kAlienTeamColorFloat)
    end

    return useColor
    
end

local kIconWidth = 32
local kIconHeight = 32

local kBackgroundBlipsLayer = 0
local kStaticBlipsLayer = 1
local kPlayerIconLayer = 2
local kDynamicBlipsLayer = 3
local kLocationNameLayer = 4
local kPingLayer = 5

local kBlipTexture = "ui/blip.dds"

local kBlipTextureCoordinates = { }
kBlipTextureCoordinates[kAlertType.Attack] = { X1 = 0, Y1 = 0, X2 = 64, Y2 = 64 }

local kAttackBlipMinSize = Vector(GUIScale(25), GUIScale(25), 0)
local kAttackBlipMaxSize = Vector(GUIScale(100), GUIScale(100), 0)
local kAttackBlipPulseSpeed = 6
local kAttackBlipTime = 5
local kAttackBlipFadeInTime = 4.5
local kAttackBlipFadeOutTime = 1

local kLocationFontSize = 12

local kPlayerFOVColor = Color(1, 1, 1, 1)

local ClassToGrid = BuildClassToGrid()

local function PlotToMap(posX, posZ, comMode, zoom)   

    local adjustedX = posX - Client.minimapExtentOrigin.x
    local adjustedZ = posZ - Client.minimapExtentOrigin.z
    
    local xFactor = 2 * GUIMinimap.kBigSizeScale
    local zFactor = xFactor / GUIMinimap.kMapRatio()
    
    local plottedX = (adjustedX / (Client.minimapExtentScale.x / xFactor)) * GUIMinimap.kBackgroundSize * zoom
    local plottedY = (adjustedZ / (Client.minimapExtentScale.z / zFactor)) * GUIMinimap.kBackgroundSize * zoom
    
    if comMode == GUIMinimap.kModeMini then
    
        plottedX = plottedX / GUIMinimap.kBigSizeScale
        plottedY = plottedY / GUIMinimap.kBigSizeScale
        
    end
    
    // The world space is oriented differently from the GUI space, adjust for that here.
    // Return 0 as the third parameter so the results can easily be added to a Vector.
    return plottedY, -plottedX, 0
    
end
AddFunctionContract(PlotToMap, { Arguments = { "number", "number", "number", "number" }, Returns = { "number", "number", "number" } })

function GUIMinimap:Initialize()

    self.zoom = 1
    self.desiredZoom = .75
    self.timeMapOpened = 0

    self:InitializeBackground()
    
    self.minimap = GUIManager:CreateGraphicItem()
    
    self:InitializeLocationNames()
    
    self.comMode = nil
    self:SetBackgroundMode(GUIMinimap.kModeMini)
    self.minimap:SetTexture("maps/overviews/" .. Shared.GetMapName() .. ".tga")
    self.minimap:SetColor(GUIMinimap.kUnzoomedColor)
    self.background:AddChild(self.minimap)
    
    // Used for commander.
    self:InitializeCameraLines()
    // Used for normal players.
    self:InitializePlayerIcon()
  
    self.staticBlips = { }
    
    self.reuseDynamicBlips = { }
    self.inuseDynamicBlips = { }
    
    self.mousePressed = { LMB = { Down = nil, X = 0, Y = 0 }, RMB = { Down = nil, X = 0, Y = 0 } }
    
    self.commanderPing = GUICreateCommanderPing()
    self.commanderPing.Frame:SetAnchor(GUIItem.Center, GUIItem.Middle)
    self.commanderPing.Frame:SetLayer(kPingLayer)
    self.minimap:AddChild(self.commanderPing.Frame)
    
end

function GUIMinimap:InitializeBackground()

    self.background = GUIManager:CreateGraphicItem()
    self.background:SetSize(Vector(GUIMinimap.kBackgroundWidth, GUIMinimap.kBackgroundHeight, 0))
    self.background:SetPosition(Vector(0, -GUIMinimap.kBackgroundHeight, 0))
    self.background:SetColor(Color(1, 1, 1, 0))

    self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.background:SetLayer(kGUILayerMinimap)
    
    self:InitSmokeyBackground()
    self:InitFrame()
    
    // Non-commander players assume the map isn't visible by default.
    if not PlayerUI_IsACommander() then
        self.background:SetIsVisible(false)
    end

end

function GUIMinimap:InitFrame()

    self.minimapFrame = GUIManager:CreateGraphicItem()
    self.minimapFrame:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.minimapFrame:SetSize(GUIMinimap.kFrameTextureSize)
    self.minimapFrame:SetPosition(Vector(-GUIMinimap.kMapBackgroundXOffset, -GUIMinimap.kFrameTextureSize.y + GUIMinimap.kMapBackgroundYOffset, 0))
    self.minimapFrame:SetTexture(GUIMinimap.kMarineFrameTexture)
    self.minimapFrame:SetTexturePixelCoordinates(unpack(GUIMinimap.kFramePixelCoords))
    self.minimapFrame:SetIsVisible(false)
    self.background:AddChild(self.minimapFrame)

end

function GUIMinimap:InitSmokeyBackground()

    self.smokeyBackground = GUIManager:CreateGraphicItem()
    self.smokeyBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.smokeyBackground:SetSize(kSmokeyBackgroundSize)
    self.smokeyBackground:SetPosition(-kSmokeyBackgroundSize * .5)
        self.smokeyBackground:SetTexture("ui/alien_minimap_smkmask.dds")
    self.smokeyBackground:SetShader("shaders/GUISmoke.surface_shader")
    self.smokeyBackground:SetAdditionalTexture("noise", kBackgroundNoiseTexture)
    self.smokeyBackground:SetFloatParameter("correctionX", 1)
    self.smokeyBackground:SetFloatParameter("correctionY", 1.2)
    self.smokeyBackground:SetIsVisible(false)
    
    self.background:AddChild(self.smokeyBackground)

end

function GUIMinimap:SetZoom(zoom)

    self.zoom = zoom
    
    local modeSize = self:GetMinimapSize()
    self.minimap:SetSize(modeSize * self.zoom)

end

function GUIMinimap:InitializeCameraLines()

    self.cameraLines = GUIManager:CreateLinesItem()
    self.cameraLines:SetAnchor(GUIItem.Center, GUIItem.Middle)
    self.cameraLines:SetLayer(kPlayerIconLayer)
    self.minimap:AddChild(self.cameraLines)
    
end

local kPlayerIconSize = Vector(kBlipSize, kBlipSize, 0)
local kPlayerFOVIconSize = Vector(kBlipSize * 2, kBlipSize, 0)
function GUIMinimap:InitializePlayerIcon()
    
    self.playerIcon = GUIManager:CreateGraphicItem()
    self.playerIcon:SetSize(kPlayerIconSize)
    self.playerIcon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.playerIcon:SetTexture(GetIconTextureName(self))
    iconCol, iconRow = GetSpriteGridByClass(PlayerUI_GetPlayerClass(), ClassToGrid)
    self.playerIcon:SetTexturePixelCoordinates(GUIGetSprite(iconCol, iconRow, kIconWidth, kIconHeight))
    self.playerIcon:SetIsVisible(false)
    self.playerIcon:SetLayer(kPlayerIconLayer)
    self.minimap:AddChild(self.playerIcon)    

    self.playerOverLayIcon = GUIManager:CreateGraphicItem()
    self.playerOverLayIcon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.playerOverLayIcon:SetTexture(GetIconTextureName(self))
    self.playerOverLayIcon:SetTexturePixelCoordinates(GUIGetSprite(iconCol, iconRow, kIconWidth, kIconHeight))
    self.playerOverLayIcon:SetLayer(kPlayerIconLayer)
    self.playerOverLayIcon:SetColor(Color(1, 1, 1, 0.35))
    self.playerIcon:AddChild(self.playerOverLayIcon)
    
    self.playerIconFov = GUIManager:CreateGraphicItem()
    self.playerIconFov:SetSize(kPlayerFOVIconSize)
    self.playerIconFov:SetTexture(GetIconTextureName(self))
    local iconCol, iconRow = GetSpriteGridByClass('PlayerFOV', ClassToGrid)
    local gridPosX, gridPosY, gridWidth, gridHeight = GUIGetSprite(iconCol, iconRow, kIconWidth, kIconHeight)
    self.playerIconFov:SetTexturePixelCoordinates(gridPosX - kIconWidth, gridPosY, gridWidth, gridHeight)
    self.playerIconFov:SetIsVisible(true)
    self.playerIconFov:SetLayer(kBackgroundBlipsLayer)
    self.playerIconFov:SetColor(kPlayerFOVColor)
    self.playerIcon:AddChild(self.playerIconFov)
    
end

function GUIMinimap:InitializeLocationNames()

    self.locationItems = { }
    local locationData = PlayerUI_GetLocationData()
    
    // Average the position of same named locations so they don't display
    // multiple times.
    local multipleLocationsData = { }
    for i, location in ipairs(locationData) do
    
        // Filter out the ready room.
        if location.Name ~= "Ready Room" then
        
            local locationTable = multipleLocationsData[location.Name]
            if locationTable == nil then
            
                locationTable = { }
                multipleLocationsData[location.Name] = locationTable
                
            end
            table.insert(locationTable, location.Origin)
            
        end
        
    end
    
    local uniqueLocationsData = { }
    for name, origins in pairs(multipleLocationsData) do
    
        local averageOrigin = Vector(0, 0, 0)
        table.foreachfunctor(origins, function (origin) averageOrigin = averageOrigin + origin end)
        table.insert(uniqueLocationsData, { Name = name, Origin = averageOrigin / table.count(origins) })
        
    end
    
    for i, location in ipairs(uniqueLocationsData) do
    
        local locationItem = GUIManager:CreateTextItem()
        locationItem:SetFontSize(kLocationFontSize)
        locationItem:SetFontIsBold(true)
        locationItem:SetAnchor(GUIItem.Middle, GUIItem.Center)
        locationItem:SetTextAlignmentX(GUIItem.Align_Center)
        locationItem:SetTextAlignmentY(GUIItem.Align_Center)
        locationItem:SetLayer(kLocationNameLayer)

        local posX, posY = PlotToMap(location.Origin.x, location.Origin.z, self.comMode, self.zoom)

        // Locations only supported on the big mode.
        locationItem:SetPosition(Vector(posX, posY, 0))
        locationItem:SetColor(Color(1, 1, 1, 1))
        locationItem:SetText(location.Name)
        self.minimap:AddChild(locationItem)
        table.insert(self.locationItems, locationItem)
        
    end

end

function GUIMinimap:UninitializeLocationNames()

    for index, locationItem in ipairs(self.locationItems) do
        GUI.DestroyItem(locationItem)    
    end
    
    self.locationItems = {}

end

function GUIMinimap:Uninitialize()

    // The ItemMask is the parent of the Item so this will destroy both.
    for i, blip in ipairs(self.reuseDynamicBlips) do
        GUI.DestroyItem(blip["ItemMask"])
    end
    self.reuseDynamicBlips = { }
    for i, blip in ipairs(self.inuseDynamicBlips) do
        GUI.DestroyItem(blip["ItemMask"])
    end
    self.inuseDynamicBlips = { }
    
    if self.commanderPing then
        GUI.DestroyItem(self.commanderPing.Frame)
        self.commanderPing = nil
    end
    
    if self.minimap then
        GUI.DestroyItem(self.minimap)
    end
    self.minimap = nil
    
    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
    end
    
    // The staticBlips are children of the background so will be cleaned up with it.
    self.staticBlips = { }
    
end

function GUIMinimap:SetButtonsScript(setButtonsScript)
    self.buttonsScript = setButtonsScript
end

local function UpdateAttackBlip(self, blip)

    local now = Shared.GetTime()
    local blipLifeRemaining = blip["Time"] - now
    // Fade in.
    if blipLifeRemaining >= kAttackBlipFadeInTime then
    
        local fadeInAmount = ((kAttackBlipTime - blipLifeRemaining) / (kAttackBlipTime - kAttackBlipFadeInTime))
        blip["Item"]:SetColor(Color(1, 1, 1, fadeInAmount))
        
    else
        blip["Item"]:SetColor(Color(1, 1, 1, 1))
    end
    
    // Fade out.
    if blipLifeRemaining <= kAttackBlipFadeOutTime then
    
        if blipLifeRemaining <= 0 then
            return true
        end
        blip["Item"]:SetColor(Color(1, 1, 1, blipLifeRemaining / kAttackBlipFadeOutTime))
        
    end
    
    local pulseAmount = (math.sin(blipLifeRemaining * kAttackBlipPulseSpeed) + 1) / 2
    local blipSize = LerpGeneric(kAttackBlipMinSize, kAttackBlipMaxSize / 2, pulseAmount)
    
    blip["Item"]:SetSize(blipSize)
    // Make sure it is always centered.
    local sizeDifference = kAttackBlipMaxSize - blipSize
    local minimapSize = self:GetMinimapSize()
    local xOffset = (sizeDifference.x / 2) - kAttackBlipMaxSize.x / 2
    local yOffset = (sizeDifference.y / 2) - kAttackBlipMaxSize.y / 2
    local plotX, plotY = PlotToMap(blip["X"], blip["Y"], self.comMode, self.zoom)
    blip["Item"]:SetPosition(Vector(plotX + xOffset, plotY + yOffset, 0))
    
    // Not done yet.
    return false
    
end

local function UpdateDynamicBlips(self)

    PROFILE("GUIMinimap:UpdateDynamicBlips")
    
    local newDynamicBlips = CommanderUI_GetDynamicMapBlips()
    local blipItemCount = 3
    local numBlips = table.count(newDynamicBlips) / blipItemCount
    local currentIndex = 1
    while numBlips > 0 do
    
        local blipType = newDynamicBlips[currentIndex + 2]
        self:AddDynamicBlip(newDynamicBlips[currentIndex], newDynamicBlips[currentIndex + 1], blipType)
        currentIndex = currentIndex + blipItemCount
        numBlips = numBlips - 1
        
    end
    
    local removeBlips = { }
    for i, blip in ipairs(self.inuseDynamicBlips) do
    
        if blip["Type"] == kAlertType.Attack then
        
            if UpdateAttackBlip(self, blip) then
                table.insert(removeBlips, blip)
            end
            
        end
        
        if self.comMode == GUIMinimap.kModeZoom then
            blip["Item"]:SetStencilFunc(GUIItem.NotEqual)
        else
            blip["Item"]:SetStencilFunc(GUIItem.Always)
        end
        
    end
    
    for i, blip in ipairs(removeBlips) do
        self:RemoveDynamicBlip(blip)
    end
    
end

function GUIMinimap:Update(deltaTime)

    PROFILE("GUIMinimap:Update")
    
    self.minimapFrame:SetIsVisible(PlayerUI_GetTeamType() == kMarineTeamType and self.comMode == GUIMinimap.kModeMini)
    self.smokeyBackground:SetIsVisible(PlayerUI_GetTeamType() == kAlienTeamType and self.comMode == GUIMinimap.kModeMini)
    
    if self.comMode == GUIMinimap.kModeBig then
        self.background:SetTexture(nil)
        
    elseif PlayerUI_IsOverhead() then
        
        if PlayerUI_IsACommander() then
        
            // Commander always sees the minimap.
            if not PlayerUI_IsCameraAnimated() then
                self.background:SetIsVisible(true)
            else
                self.background:SetIsVisible(false)
            end
            
            GUISetTextureCoordinatesTable(self.background, GUIMinimap.kBackgroundTextureCoords)
            
        else

            self.background:SetIsVisible(true)
            //self.background:SetTexture(GUIMinimap.kBackgroundTextureSpec)
            //self.background:SetTexturePixelCoordinates(unpack({0,0,572,548}))
            
        end

    end

    if self.background:GetIsVisible() then
    
        self:UpdateIcon()
        
        self:UpdateStaticBlips(deltaTime)
        
        UpdateDynamicBlips(self)
        
        self:UpdateInput()
        
        self.minimap:SetColor(GUIMinimap.kUnzoomedColor)
        
        if self.comMode == GUIMinimap.kModeZoom then
            self.minimap:SetStencilFunc(GUIItem.NotEqual)
            self.minimap:SetColor(GUIMinimap.kZoomedColor)
            
            if self.desiredZoom ~= self.zoom then
            
                if self.zoom < self.desiredZoom then
                    self:SetZoom(Clamp(self.zoom + deltaTime * 0.3, 0, self.desiredZoom))
                else
                    self:SetZoom(Clamp(self.zoom - deltaTime * 0.3, self.desiredZoom, 1))
                end
            
            end
            
        else
            self.minimap:SetStencilFunc(GUIItem.Always)
        end

    end
    
    // update commander ping
    if self.commanderPing then    
    
        local timeSincePing, position, distance = PlayerUI_GetCommanderPingInfo(true)
        local posX, posY = PlotToMap(position.x, position.z, self.comMode, self.zoom)
        self.commanderPing.Frame:SetPosition(Vector(posX, posY, 0))
        GUIAnimateCommanderPing(self.commanderPing.Mark, self.commanderPing.Border, self.commanderPing.Location, kCommanderPingMinimapSize, timeSincePing, Color(1, 0, 0, 1), Color(1, 1, 1, 1))
        
        if self.comMode == GUIMinimap.kModeZoom then
            self.commanderPing.Mark:SetStencilFunc(GUIItem.NotEqual)
            self.commanderPing.Border:SetStencilFunc(GUIItem.NotEqual)
        else
            self.commanderPing.Mark:SetStencilFunc(GUIItem.Always)
            self.commanderPing.Border:SetStencilFunc(GUIItem.Always)
        end
    
    end
    
end

function GUIMinimap:SetDesiredZoom(desiredZoom)
    self.desiredZoom = Clamp(desiredZoom, 0, 1)
end

function GUIMinimap:UpdateIcon()

    PROFILE("GUIMinimap:UpdateIcon")

    local isOverhead = PlayerUI_IsOverhead()
    local isCameraAnimating = PlayerUI_IsCameraAnimated()
    
    if isOverhead and not isCameraAnimating then -- Handle overhead viewplane points

        self.playerIcon:SetIsVisible(false)
        self.playerIconFov:SetIsVisible(false)
        self.cameraLines:SetIsVisible(true)
        
        local topLeftPoint, topRightPoint, bottomLeftPoint, bottomRightPoint = OverheadUI_ViewFarPlanePoints()
        if topLeftPoint == nil then
            return
        end
        
        topLeftPoint = Vector(PlotToMap(topLeftPoint.x, topLeftPoint.z, self.comMode, self.zoom))
        topRightPoint = Vector(PlotToMap(topRightPoint.x, topRightPoint.z, self.comMode, self.zoom))
        bottomLeftPoint = Vector(PlotToMap(bottomLeftPoint.x, bottomLeftPoint.z, self.comMode, self.zoom))
        bottomRightPoint = Vector(PlotToMap(bottomRightPoint.x, bottomRightPoint.z, self.comMode, self.zoom))
        
        self.cameraLines:ClearLines()
        local lineColor = Color(1, 1, 1, 1)
        self.cameraLines:AddLine(topLeftPoint, topRightPoint, lineColor)
        self.cameraLines:AddLine(topRightPoint, bottomRightPoint, lineColor)
        self.cameraLines:AddLine(bottomRightPoint, bottomLeftPoint, lineColor)
        self.cameraLines:AddLine(bottomLeftPoint, topLeftPoint, lineColor)

    elseif PlayerUI_IsAReadyRoomPlayer() then
    
        // No icons for ready room players.
        self.cameraLines:SetIsVisible(false)
        self.playerIcon:SetIsVisible(false)
        self.playerIconFov:SetIsVisible(false)

    else
    
        // Draw a player icon representing this player's position.
        local playerOrigin = PlayerUI_GetOrigin()
        local playerRotation = PlayerUI_GetMinimapPlayerDirection()

        local posX, posY = PlotToMap(playerOrigin.x, playerOrigin.z, self.comMode, self.zoom)

        self.cameraLines:SetIsVisible(false)
        self.playerIcon:SetIsVisible(true)
        self.playerIcon:SetTexture(GetIconTextureName(self))
        
        local playerIconColor = GetPlayerIconColor(self)
        local animFraction = 1 - Clamp((Shared.GetTime() - self.timeMapOpened) / 0.5, 0, 1)
        playerIconColor.r = playerIconColor.r + animFraction
        playerIconColor.g = playerIconColor.g + animFraction
        playerIconColor.b = playerIconColor.b + animFraction
        playerIconColor.a = playerIconColor.a + animFraction
        
        local overLaySize = GUIMinimap.kPlayerOverLaySize * animFraction
        local playerIconSize = Vector(kBlipSize, kBlipSize, 0)
        
        if self.comMode == GUIMinimap.kModeMini then
            overLaySize = overLaySize / 2
            playerIconSize = playerIconSize / 2
        end
        
        self.playerOverLayIcon:SetSize(overLaySize)
        self.playerOverLayIcon:SetPosition(-overLaySize * 0.5)
        self.playerIcon:SetSize(playerIconSize)
        
        self.playerIcon:SetColor(playerIconColor)
        // Disabled until rotation is correct.
        self.playerIconFov:SetIsVisible(true)

        posX = posX - (playerIconSize.x / 2)
        posY = posY - (playerIconSize.y / 2)
        
        // move the background instead of the playericon in zoomed mode
        if self.comMode  == GUIMinimap.kModeZoom then

            local size = self:GetMinimapSize() * self.zoom
            
            self.background:SetPosition(Vector(-posX - size.x/2, -posY - size.y/2 , 0))
            self.playerIcon:SetPosition(Vector(posX, posY, 0))
        
        else

            self.playerIcon:SetPosition(Vector(posX, posY, 0))
        
        end
        
        local rotation = Vector(0, 0, playerRotation)
        
        self.playerIcon:SetRotation(rotation)
        self.playerOverLayIcon:SetRotation(rotation)
        self.playerIconFov:SetRotation(rotation)
        
        self.playerIconFov:SetAnchor(GUIItem.Left, GUIItem.Top)
        self.playerIconFov:SetPosition(Vector(-kBlipSize / 2, 0, 0))
        self.playerIconFov:SetTexture(GetIconTextureName(self))

        local playerClass = PlayerUI_GetPlayerClass()
        if self.playerClass ~= playerClass then

            local iconCol, iconRow = GetSpriteGridByClass(playerClass, ClassToGrid)
            self.playerIcon:SetTexturePixelCoordinates(GUIGetSprite(iconCol, iconRow, kIconWidth, kIconHeight))
            self.playerClass = playerClass

        end

    end
    
end

function GUIMinimap:UpdateStaticBlips(deltaTime)

    PROFILE("GUIMinimap:UpdateStaticBlips")

    // First hide all previous static blips.
    local oldBlips = self.staticBlips
    for index = 1,#oldBlips do
        oldBlips[index]:SetIsVisible(false)
    end
    
    local staticBlips = PlayerUI_GetStaticMapBlips()
    local blipItemCount = 8
    local numBlips = table.count(staticBlips) / blipItemCount
    local currentIndex = 1
    local freeBlip = 1
    
    // Create all of the blips we'll need.
    for i=#self.staticBlips,numBlips do
        self:AddStaticBlip()
    end    
    
    while numBlips > 0 do
    
        local xPos, yPos = PlotToMap(staticBlips[currentIndex], staticBlips[currentIndex + 1], self.comMode, self.zoom)
        local rotation = staticBlips[currentIndex + 2]
        local xTexture = staticBlips[currentIndex + 3]
        local yTexture = staticBlips[currentIndex + 4]
        local blipType = staticBlips[currentIndex + 5]
        local blipTeam = staticBlips[currentIndex + 6]
        local underAttack = staticBlips[currentIndex + 7]
        
        local blip = self.staticBlips[freeBlip]
        freeBlip = freeBlip + 1
        
        self:SetStaticBlip(blip, xPos, yPos, rotation, xTexture, yTexture, blipType, blipTeam, useStencil, underAttack)
        currentIndex = currentIndex + blipItemCount
        numBlips = numBlips - 1
        
    end
    
end

local function GetBlinkRedColor(time)

    local mod = math.sin(((time % kBlinkInterval) / kBlinkInterval) * math.pi)    
    return kUnderAttackColor.r * mod
    
end

local function GetBlinkAlpha(time, color)

    local mod = math.sin(((time % kBlinkInterval) / kBlinkInterval) * math.pi)
    return Color(color.r, color.g, color.b, mod)
    
end

local function MapPointSpecialCase(blipType, blipColor, underAttack, blipTeam, blipSize, blipLayer)

    PROFILE("MapPointSpecialCase")
    
    return blipColor, nil, nil, blipSize, kBackgroundBlipsLayer
    
end

local function EggSpecialCase(blipType, blipColor, underAttack, blipTeam, blipSize, blipLayer)

    PROFILE("EggSpecialCase")
    
    local iconCol, iconRow = GetSpriteGridByClass("Infestation", ClassToGrid)
    return blipColor, iconCol, iconRow, blipSize / 2, blipLayer
    
end

local function OrderSpecialCase(blipType, blipColor, underAttack, blipTeam, blipSize, blipLayer)

    PROFILE("OrderSpecialCase")
    
    return kWaypointColor, nil, nil, blipSize, blipLayer
    
end

local function ScanSpecialCase(blipType, blipColor, underAttack, blipTeam, blipSize, blipLayer)

    PROFILE("ScanSpecialCase")
    
    blipColor = kScanColor
    local scanAnimFraction = (Shared.GetTime() % kScanAnimDuration) / kScanAnimDuration
    blipColor.a = 1 - scanAnimFraction
    blipSize = blipSize * (0.5 + scanAnimFraction) * 2
    return blipColor, nil, nil, blipSize, kBackgroundBlipsLayer
    
end

local kSpecialCaseStaticBlipModifiers = { }
kSpecialCaseStaticBlipModifiers[kMinimapBlipType.ResourcePoint] = MapPointSpecialCase
kSpecialCaseStaticBlipModifiers[kMinimapBlipType.TechPoint] = MapPointSpecialCase
kSpecialCaseStaticBlipModifiers[kMinimapBlipType.Egg] = EggSpecialCase
kSpecialCaseStaticBlipModifiers[kMinimapBlipType.MoveOrder] = OrderSpecialCase
kSpecialCaseStaticBlipModifiers[kMinimapBlipType.AttackOrder] = OrderSpecialCase
kSpecialCaseStaticBlipModifiers[kMinimapBlipType.BuildOrder] = OrderSpecialCase
kSpecialCaseStaticBlipModifiers[kMinimapBlipType.Scan] = ScanSpecialCase

// Simple optimization to prevent unnecessary Vector creation inside the function.
local foundBlipSize = Vector()
local foundBlipPos = Vector()
local foundBlipRotation = Vector()
function GUIMinimap:SetStaticBlip(foundBlip, xPos, yPos, rotation, xTexture, yTexture, blipType, blipTeam, useStencil, underAttack)

    PROFILE("GUIMinimap:SetStaticBlip")
    
    local blipColor = kTeamColors[blipTeam]
    local iconCol = nil
    local iconRow = nil
    local blipSize = kBlipSize
    local blipLayer = kStaticBlipsLayer
    
    if self.comMode == GUIMinimap.kModeZoom then
        blipSize = blipSize * kZoomedBlipSizeScale
    end
    
    // Draw other structures a little smaller
    if blipType ~= kMinimapBlipType.Hive and blipType ~= kMinimapBlipType.CommandStation and blipType ~= kMinimapBlipType.TechPoint then
        blipSize = kBlipSize * 0.7
    end
    
    local specialCaseMod = kSpecialCaseStaticBlipModifiers[blipType]
    if specialCaseMod then
        blipColor, iconCol, iconRow, blipSize, blipLayer = specialCaseMod(blipType, blipColor, underAttack, blipTeam, blipSize, blipLayer)
    end
    
    if (iconCol == nil or iconRow == nil) and kMinimapBlipType[blipType] ~= nil then
        iconCol, iconRow = GetSpriteGridByClass(EnumToString(kMinimapBlipType, blipType), ClassToGrid)
    end
    
    foundBlip:SetLayer(blipLayer)
    
    if self.comMode == GUIMinimap.kModeMini then
        blipSize = blipSize / 2
    end
    
    if underAttack and blipTeam == kMinimapBlipTeam.Friendly then 
        blipColor = GetBlinkAlpha(Shared.GetTime(), blipColor)
    end
    
    local player = Client.GetLocalPlayer()
    if underAttack and player:GetTeamNumber() == kSpectatorIndex then
        blipColor = Color(GetBlinkRedColor(Shared.GetTime()) + 0.25, 0, 0, blipColor.a)
    end
    
    foundBlip:SetTexture(GetIconTextureName(self))
    foundBlip:SetTexturePixelCoordinates(GUIGetSprite(iconCol, iconRow, kIconWidth, kIconHeight))
    foundBlip:SetIsVisible(true)
    
    foundBlipSize.x = blipSize
    foundBlipSize.y = blipSize
    foundBlip:SetSize(foundBlipSize)
    
    foundBlipPos.x = xPos - (blipSize / 2)
    foundBlipPos.y = yPos - (blipSize / 2)
    foundBlip:SetPosition(foundBlipPos)
    
    foundBlipRotation.z = rotation
    foundBlip:SetRotation(foundBlipRotation)
    
    foundBlip:SetColor(blipColor)
    foundBlip:SetBlendTechnique(GUIItem.Default)
    
    if self.comMode == GUIMinimap.kModeZoom then
        foundBlip:SetStencilFunc(GUIItem.NotEqual)
    else
        foundBlip:SetStencilFunc(GUIItem.Always)
    end
    
end

function GUIMinimap:AddStaticBlip()

    addedBlip = GUIManager:CreateGraphicItem()
    addedBlip:SetAnchor(GUIItem.Center, GUIItem.Middle)
    addedBlip:SetLayer(kStaticBlipsLayer)
    self.minimap:AddChild(addedBlip)
    table.insert(self.staticBlips, addedBlip)
    return addedBlip

end

function GUIMinimap:AddDynamicBlip(xPos, yPos, blipType)

    /**
     * Blip types - kAlertType
     * 
     * 0 - Attack
     * Attention-getting spinning squares that start outside the minimap and spin down to converge to point 
     * on map, continuing to draw at point for a few seconds).
     * 
     * 1 - Info
     * Research complete, area blocked, structure couldn't be built, etc. White effect, not as important to
     * grab your attention right away).
     * 
     * 2 - Request
     * Soldier needs ammo, asking for order, etc. Should be yellow or green effect that isn't as 
     * attention-getting as the under attack. Should draw for a couple seconds.)
     */
    
    if blipType == kAlertType.Attack then
    
        addedBlip = self:GetFreeDynamicBlip(xPos, yPos, blipType)
        addedBlip["Item"]:SetSize(Vector(0, 0, 0))
        addedBlip["Time"] = Shared.GetTime() + kAttackBlipTime
        
    end
    
end

function GUIMinimap:RemoveDynamicBlip(blip)

    blip["Item"]:SetIsVisible(false)
    table.removevalue(self.inuseDynamicBlips, blip)
    table.insert(self.reuseDynamicBlips, blip)
    
end

function GUIMinimap:GetFreeDynamicBlip(xPos, yPos, blipType)

    local returnBlip = nil
    if table.count(self.reuseDynamicBlips) > 0 then
    
        returnBlip = self.reuseDynamicBlips[1]
        table.removevalue(self.reuseDynamicBlips, returnBlip)
        table.insert(self.inuseDynamicBlips, returnBlip)
        
    else
    
        returnBlip = { }
        returnBlip["Item"] = GUIManager:CreateGraphicItem()
        returnBlip["Item"]:SetStencilFunc(GUIItem.NotEqual)
        // Make sure these draw a layer above the minimap so they are on top.
        returnBlip["Item"]:SetLayer(kDynamicBlipsLayer)
        returnBlip["Item"]:SetTexture(kBlipTexture)
        returnBlip["Item"]:SetBlendTechnique(GUIItem.Add)
        returnBlip["Item"]:SetAnchor(GUIItem.Center, GUIItem.Middle)
        self.minimap:AddChild(returnBlip["Item"])
        table.insert(self.inuseDynamicBlips, returnBlip)
        
    end
    
    returnBlip["X"] = xPos
    returnBlip["Y"] = yPos
    
    returnBlip["Type"] = blipType
    returnBlip["Item"]:SetIsVisible(true)
    returnBlip["Item"]:SetColor(Color(1, 1, 1, 1))
    local minimapSize = self:GetMinimapSize()
    local plotX, plotY = PlotToMap(xPos, yPos, self.comMode, self.zoom)
    returnBlip["Item"]:SetPosition(Vector(plotX, plotY, 0))
    GUISetTextureCoordinatesTable(returnBlip["Item"], kBlipTextureCoordinates[blipType])
    return returnBlip
    
end

function GUIMinimap:UpdateInput()

    if PlayerUI_IsOverhead() then
    
        -- Don't teleport if the command is dragging a selection or pinging
        if PlayerUI_IsACommander() and ( not CommanderUI_GetUIClickable() or self.pingEnabled ) then
            return
        end
    
        local mouseX, mouseY = Client.GetCursorPosScreen()
        if self.mousePressed["LMB"]["Down"] then

            local containsPoint, withinX, withinY = GUIItemContainsPoint(self.minimap, mouseX, mouseY)
            if containsPoint then
            
                local minimapSize = self:GetMinimapSize()
                local backgroundScreenPosition = self.minimap:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
                
                local cameraPosition = Vector(mouseX, mouseY, 0)
                
                cameraPosition.x = cameraPosition.x - backgroundScreenPosition.x
                cameraPosition.y = cameraPosition.y - backgroundScreenPosition.y

                local horizontalScale = OverheadUI_MapLayoutHorizontalScale()
                local verticalScale = OverheadUI_MapLayoutVerticalScale()

                local moveX = (cameraPosition.x / minimapSize.x) * horizontalScale
                local moveY = (cameraPosition.y / minimapSize.y) * verticalScale

                OverheadUI_MapMoveView(moveX, moveY)
                
            end
            
        end
        
    end

end

function GUIMinimap:SetBackgroundMode(setMode, forceReset)

    if self.comMode ~= setMode or forceReset then
        
        self.comMode = setMode
        local modeIsMini = self.comMode == GUIMinimap.kModeMini
        local modeIsZoom = self.comMode == GUIMinimap.kModeZoom
        
        // Locations only visible in the big mode
        table.foreachfunctor(self.locationItems, function (item) item:SetIsVisible(not modeIsMini) end)
        
        local modeSize = self:GetMinimapSize()

        // We want the background to sit "inside" the border so move it up and to the right a bit.
        local borderExtraWidth = ConditionalValue(self.background, GUIMinimap.kBackgroundWidth - self:GetMinimapSize().x, 0)
        local borderExtraHeight = ConditionalValue(self.background, GUIMinimap.kBackgroundHeight - self:GetMinimapSize().y, 0)
        local defaultPosition = Vector(borderExtraWidth / 2, borderExtraHeight / 2, 0)
        local modePosition = ConditionalValue(modeIsMini, defaultPosition, Vector(0, 0, 0))
        self.minimap:SetPosition(modePosition * self.zoom)
        
        if self.background then
        
            if modeIsMini then
                self.background:SetAnchor(GUIItem.Left, GUIItem.Bottom)
                self.background:SetPosition(Vector(GUIMinimap.kMapBackgroundXOffset, -GUIMinimap.kBackgroundHeight - GUIMinimap.kMapBackgroundYOffset, 0) * self.zoom)
                self.background:SetSize(Vector(GUIMinimap.kBackgroundWidth, GUIMinimap.kBackgroundHeight, 0))
                self.minimap:SetAnchor(GUIItem.Left, GUIItem.Top)
            elseif modeIsZoom then
                self.background:SetAnchor(GUIItem.Top, GUIItem.Left)
                self.background:SetSize(Vector(GUIMinimap.kBackgroundWidth, GUIMinimap.kBackgroundHeight, 0))
                self.minimap:SetAnchor(GUIItem.Middle, GUIItem.Center)
                self:UninitializeLocationNames()
            else
                self.background:SetAnchor(GUIItem.Left, GUIItem.Top)
                self.background:SetSize( Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0) )
                self.background:SetPosition(Vector(0, 0, 0))
                
                local minimapSize = self.minimap:GetSize()
                
                self.minimap:SetAnchor(GUIItem.Middle, GUIItem.Center)
                self.minimap:SetPosition(-modeSize / 2)

            end
            
        end
        
        self.minimap:SetSize(modeSize * self.zoom)
        
        
        // Make sure everything is in sync in case this function is called after GUIMinimap:Update() is called.
        self:Update(0)
    
    end
    
end

function GUIMinimap:GetMinimapSize()
    return ConditionalValue(self.comMode == GUIMinimap.kModeMini, GUIMinimap.kMinimapSmallSize, GUIMinimap.kMinimapBigSize)
end

function GUIMinimap:GetPositionOnBackground(xPos, yPos, currentSize)

    local backgroundScreenPosition = self.minimap:GetScreenPosition(Client.GetScreenWidth(), Client.GetScreenHeight())
    local inBackgroundPosition = Vector((xPos * self:GetMinimapSize().x) - (currentSize.x / 2), (yPos * self:GetMinimapSize().y) - (currentSize.y / 2), 0)
    return backgroundScreenPosition + inBackgroundPosition

end

// Shows or hides the big map.
function GUIMinimap:ShowMap(showMap)

    if self.background:GetIsVisible() ~= showMap then
        
        self.background:SetIsVisible(showMap)
        if showMap then
            self.timeMapOpened = Shared.GetTime()
            self:Update(0)
        end
    end
    
end

function GUIMinimap:SendKeyEvent(key, down)

    if PlayerUI_IsOverhead() then
    
        local mouseX, mouseY = Client.GetCursorPosScreen()
        local containsPoint, withinX, withinY = GUIItemContainsPoint(self.minimap, mouseX, mouseY)
        
        if key == InputKey.MouseButton2 and down == false then
        
            if PlayerUI_IsACommander() then
            
                local size = self:GetMinimapSize()
                local x = withinX / size.x
                local y = withinY / size.y	
                
                CommanderUI_TriggerPingOnMinimap(x, y)

                self.pingEnabled = false
                return true
                
            end

        elseif key == InputKey.MouseButton0 and self.mousePressed["LMB"]["Down"] ~= down then
            
            self.mousePressed["LMB"]["Down"] = down            
            if not down and containsPoint then
            
                local buttonIndex = nil                
                local player = Client.GetLocalPlayer()
                
                if PlayerUI_IsACommander() then
                
                    if self.pingEnabled then    

                        local size = self:GetMinimapSize()
                        local x = withinX / size.x
                        local y = withinY / size.y	
                        
                        CommanderUI_TriggerPingOnMinimap(x, y)

                        self.pingEnabled = shiftDown
                        return true
                    
                    end
                    
                end
       
                return false
                
            end
            
        elseif key == InputKey.MouseButton1 and self.mousePressed["RMB"]["Down"] ~= down then
        
            self.mousePressed["RMB"]["Down"] = down
            if down and containsPoint then
            
                if self.buttonsScript then
                
                    if PlayerUI_IsACommander() then
                    
                        // Cancel just in case the user had a targeted action selected before this press.
                        CommanderUI_ActionCancelled()
                        self.buttonsScript:SetTargetedButton(nil)
                    
                    end
                    
                end
                
                OverheadUI_MapClicked(withinX / self:GetMinimapSize().x, withinY / self:GetMinimapSize().y, 1, nil)
                return true
                
            end
            
        end
        
    end
    
    return false

end

function GUIMinimap:GetBackground()

    return self.background

end

function GUIMinimap:ContainsPoint(pointX, pointY)

    return GUIItemContainsPoint(self:GetBackground(), pointX, pointY) or GUIItemContainsPoint(self.minimap, pointX, pointY)

end

function GUIMinimap:GetPingEnabled()
    return self.pingEnabled
end

function GUIMinimap:SetPingEnabled(enabled)
    self.pingEnabled = enabled
end

