// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMarineHUD.lua
//
// Created by: Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Animated 3d Hud for Marines.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIUtility.lua")
Script.Load("lua/GUIAnimatedScript.lua")

Script.Load("lua/Hud/GUIPlayerResource.lua")
Script.Load("lua/Hud/Marine/GUIMarineStatus.lua")
Script.Load("lua/Hud/GUIEvent.lua")
Script.Load("lua/Hud/Marine/GUIMarineFuel.lua")
Script.Load("lua/Hud/Marine/GUIMarineHUDStyle.lua")
Script.Load("lua/Hud/GUIInventory.lua")
Script.Load("lua/TechTreeConstants.lua")

class 'GUIMarineHUD' (GUIAnimatedScript)

GUIMarineHUD.kUpgradesTexture = "ui/buildmenu.dds"

local POWER_OFF = 1
local POWER_ON = 2
local POWER_DESTROYED = 3
local POWER_DAMAGED = 4

local function GetTechIdForArmorLevel(level)

    local armorTechId = {}

    armorTechId[1] = kTechId.Armor1
    armorTechId[2] = kTechId.Armor2
    armorTechId[3] = kTechId.Armor3

    return armorTechId[level]

end

local function GetTechIdForWeaponLevel(level)

    local weaponTechId = {}

    weaponTechId[1] = kTechId.Weapons1
    weaponTechId[2] = kTechId.Weapons2
    weaponTechId[3] = kTechId.Weapons3

    return weaponTechId[level]

end

GUIMarineHUD.kDefaultZoom = 0.75

GUIMarineHUD.kUpgradeSize = Vector(80, 80, 0) * 0.8
GUIMarineHUD.kUpgradePos = Vector(-GUIMarineHUD.kUpgradeSize.x - 16, 40, 0)

GUIMarineHUD.kCommanderNameOffset = Vector(20, 280, 0)

GUIMarineHUD.kMinimapYOffset = 5

// position and size for stencil buffer
GUIMarineHUD.kStencilSize = Vector(400, 256, 0)
GUIMarineHUD.kStencilPos = Vector(0, 128, 0)

// initial squares which fade out
GUIMarineHUD.kNumInitSquares = 10
GUIMarineHUD.kInitSquareSize = Vector(64, 80, 0)
GUIMarineHUD.kInitSquareColors = Color(0x01 / 0xFF, 0x8D / 0xFF, 0xFF / 0xFF, 0.3)

// TEXTURES
GUIMarineHUD.kScanTexture = "ui/marine_HUD_scanLines.dds"
GUIMarineHUD.kScanLineTextureCoords = { 0, 0, 362, 1200 }

GUIMarineHUD.kMinimapBorderTexture = "ui/marine_HUD_minimap.dds"
GUIMarineHUD.kMinimapBackgroundTextureCoords = { 0, 0, 400, 256 }
GUIMarineHUD.kMinimapBorderTextureCoords = { GUIMarineHUD.kMinimapBackgroundTextureCoords[3], GUIMarineHUD.kMinimapBackgroundTextureCoords[4], 2 * GUIMarineHUD.kMinimapBackgroundTextureCoords[3], 2 * GUIMarineHUD.kMinimapBackgroundTextureCoords[4] }
GUIMarineHUD.kMinimapBackgroundSize = Vector( GUIMarineHUD.kMinimapBackgroundTextureCoords[3] - GUIMarineHUD.kMinimapBackgroundTextureCoords[1], GUIMarineHUD.kMinimapBackgroundTextureCoords[4] - GUIMarineHUD.kMinimapBackgroundTextureCoords[2], 0 )
GUIMarineHUD.kMinimapPowerTextureCoords = { 0, GUIMarineHUD.kMinimapBackgroundTextureCoords[4] * 4, 43, GUIMarineHUD.kMinimapBackgroundTextureCoords[4] * 4 + 28 }
GUIMarineHUD.kMinimapScanlineTextureCoords = { 0, 0, 400, 128 }

GUIMarineHUD.kMinimapScanTextureCoords = { GUIMarineHUD.kMinimapBackgroundTextureCoords[3], 2 * GUIMarineHUD.kMinimapBackgroundTextureCoords[4], 2 * GUIMarineHUD.kMinimapBackgroundTextureCoords[3], 3 * GUIMarineHUD.kMinimapBackgroundTextureCoords[4] }


GUIMarineHUD.kMinimapStencilTextureCoords = { GUIMarineHUD.kMinimapBackgroundTextureCoords[3], 3 * GUIMarineHUD.kMinimapBackgroundTextureCoords[4], 2 * GUIMarineHUD.kMinimapBackgroundTextureCoords[3], 4 * GUIMarineHUD.kMinimapBackgroundTextureCoords[4] }

GUIMarineHUD.kMinimapPowerSize = Vector(GUIMarineHUD.kMinimapPowerTextureCoords[3] - GUIMarineHUD.kMinimapPowerTextureCoords[1], GUIMarineHUD.kMinimapPowerTextureCoords[4] - GUIMarineHUD.kMinimapPowerTextureCoords[2], 0)
GUIMarineHUD.kMinimapPowerPos = Vector(150, -34, 0)
GUIMarineHUD.kMinimapPos = Vector(20, 30, 0)
GUIMarineHUD.kMinimapscanlinesPos = Vector(40, 54, 0)

GUIMarineHUD.kFrameTexture = "ui/marine_HUD_frame.dds"
GUIMarineHUD.kFrameTopLeftCoords = { 0, 0, 680, 384 }
GUIMarineHUD.kFrameTopRightCoords = { 680, 0, 1360, 384 }
GUIMarineHUD.kFrameBottomLeftCoords = { 0, 384, 680, 768 }
GUIMarineHUD.kFrameBottomRightCoords = { 680, 384, 1360, 768 }
GUIMarineHUD.kFrameSize = Vector(1000, 600, 0)

// FONT

GUIMarineHUD.kTextFontName = "fonts/AgencyFB_small.fnt"
GUIMarineHUD.kCommanderFontName = "fonts/AgencyFB_small.fnt"

GUIMarineHUD.kActiveCommanderColor = Color(246/255, 254/255, 37/255 )

GUIMarineHUD.kGameTimeTextFontSize = 26
GUIMarineHUD.kGameTimeTextPos = Vector(210, -170, 0)

GUIMarineHUD.kLocationTextSize = 22
GUIMarineHUD.kLocationTextOffset = Vector(280, 5, 0)

// the hud will not show more notifications than at this intervall to prevent too much spam
GUIMarineHUD.kNotificationUpdateIntervall = 0.2

// we update this only at initialize and then only once every 2 seconds
GUIMarineHUD.kPassiveUpgradesUpdateIntervall = 2

// COLORS

GUIMarineHUD.kBackgroundColor = Color(0x01 / 0xFF, 0x8F / 0xFF, 0xFF / 0xFF, 1)

// animation callbacks

function AnimFadeIn(scriptHandle, itemHandle)
    itemHandle:FadeIn(1, nil, AnimateLinear, AnimFadeOut)
end

function AnimFadeOut(scriptHandle, itemHandle)
    itemHandle:FadeOut(1, nil, AnimateLinear, AnimFadeIn)
end

function GUIMarineHUD:Initialize()

    GUIAnimatedScript.Initialize(self)

    self.lastArmorLevel = 0
    self.lastWeaponsLevel = 0
    self.lastPassiveUpgradeCheck = 0
    self.motiontracking = false
    
    self.scale =  Client.GetScreenHeight() / kBaseScreenHeight
    self.minimapEnabled = gHUDMapEnabled
    self.lastCommanderName = ""
    self.lastNotificationUpdate = Client.GetTime()

    // used for global offset

    self.background = self:CreateAnimatedGraphicItem()
    self.background:SetIsScaling(false)
    self.background:SetSize( Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0) )
    self.background:SetPosition( Vector(0, 0, 0) )
    self.background:SetIsVisible(true)
    self.background:SetLayer(kGUILayerPlayerHUDBackground)
    self.background:SetColor( Color(1, 1, 1, 0) )

    self:InitFrame()

    // create all hud elements

    self.commanderName = self:CreateAnimatedTextItem()
    self.commanderName:SetFontName(GUIMarineHUD.kTextFontName)
    self.commanderName:SetTextAlignmentX(GUIItem.Align_Min)
    self.commanderName:SetTextAlignmentY(GUIItem.Align_Min)
    self.commanderName:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.commanderName:SetLayer(kGUILayerPlayerHUDForeground1)
    self.commanderName:SetFontName(GUIMarineHUD.kCommanderFontName)
    self.commanderName:SetColor(Color(1,1,1,1))
    self.commanderName:SetFontIsBold(true)
    self.background:AddChild(self.commanderName)

    self.scanLeft = self:CreateAnimatedGraphicItem()
    self.scanLeft:SetTexture(GUIMarineHUD.kScanTexture)
    self.scanLeft:SetTexturePixelCoordinates(unpack(GUIMarineHUD.kScanLineTextureCoords))
    self.scanLeft:SetLayer(kGUILayerPlayerHUDForeground1)
    self.scanLeft:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.scanLeft:SetBlendTechnique(GUIItem.Add)
    self.scanLeft:SetIsVisible(false)
    self.scanLeft:AddAsChildTo(self.background)

    self.scanRight = self:CreateAnimatedGraphicItem()
    self.scanRight:SetTexture(GUIMarineHUD.kScanTexture)
    self.scanRight:SetTexturePixelCoordinates(unpack(GUIMarineHUD.kScanLineTextureCoords))
    self.scanRight:SetLayer(kGUILayerPlayerHUDForeground1)
    self.scanRight:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.scanRight:SetBlendTechnique(GUIItem.Add)
    self.scanRight:SetIsVisible(false)
    self.scanRight:AddAsChildTo(self.background)
    
    if self.minimapEnabled then
        self:InitializeMinimap()
    end

    self.locationText = self:CreateAnimatedTextItem()
    self.locationText:SetFontName(GUIMarineHUD.kTextFontName)
    self.locationText:SetTextAlignmentX(GUIItem.Align_Max)
    self.locationText:SetTextAlignmentY(GUIItem.Align_Min)
    self.locationText:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.locationText:SetLayer(kGUILayerPlayerHUDForeground2)
    self.locationText:SetColor(kBrightColor)
    self.locationText:SetFontIsBold(true)
    self.locationText:AddAsChildTo(self.background)

    self.armorLevel = GetGUIManager():CreateGraphicItem()
    self.armorLevel:SetTexture(GUIMarineHUD.kUpgradesTexture)
    self.armorLevel:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.background:AddChild(self.armorLevel)

    self.weaponLevel = GetGUIManager():CreateGraphicItem()
    self.weaponLevel:SetTexture(GUIMarineHUD.kUpgradesTexture)
    self.weaponLevel:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.background:AddChild(self.weaponLevel)
    
    self.mtracking = GetGUIManager():CreateGraphicItem()
    self.mtracking:SetTexture(GUIMarineHUD.kUpgradesTexture)
    self.mtracking:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.background:AddChild(self.mtracking)
    
    self.statusDisplay = CreateStatusDisplay(self, kGUILayerPlayerHUDForeground1, self.background)
    self.eventDisplay = CreateEventDisplay(self, kGUILayerPlayerHUDForeground1, self.background, true)
    
    local style = { }
    style.textColor = kBrightColor
    style.textureSet = "marine"
    style.displayTeamRes = true

    self.fuelDisplay = CreateFuelDisplay(self, kGUILayerPlayerHUDForeground1, self.background)
    self.inventoryDisplay = CreateInventoryDisplay(self, kGUILayerPlayerHUDForeground1, self.background)

    self:Reset()

    self:Update(0)

end

function GUIMarineHUD:InitFrame()

end

function GUIMarineHUD:InitializeMinimap()

    self.lastLocationText = ""

    self.minimapBackground = self:CreateAnimatedGraphicItem()
    self.minimapBackground:SetTexture(GUIMarineHUD.kMinimapBorderTexture)
    self.minimapBackground:SetTexturePixelCoordinates(unpack(GUIMarineHUD.kMinimapScanTextureCoords))
    self.minimapBackground:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.minimapBackground:SetColor(Color(1,1,1,1))
    self.minimapBackground:SetLayer(kGUILayerPlayerHUDForeground1)
    self.minimapBackground:AddAsChildTo(self.background)

    /*
    self.minimapPower = self:CreateAnimatedGraphicItem()
    self.minimapPower:SetTexture(GUIMarineHUD.kMinimapBorderTexture)
    self.minimapPower:SetTexturePixelCoordinates(unpack(GUIMarineHUD.kMinimapPowerTextureCoords))
    self.minimapPower:SetLayer(kGUILayerPlayerHUDForeground2)
    self.minimapPower:SetColor( Color(1,1,1,0.5) )
    self.minimapPower:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.minimapPower:SetBlendTechnique(GUIItem.Add)
    self.minimapBackground:AddChild(self.minimapPower)
    */
    
    self.minimapStencil = GetGUIManager():CreateGraphicItem()
    self.minimapStencil:SetColor( Color(1,1,1,1) )
    self.minimapStencil:SetIsStencil(true)
    self.minimapStencil:SetClearsStencilBuffer(false)
    self.minimapStencil:SetTexture(GUIMarineHUD.kMinimapBorderTexture)
    self.minimapStencil:SetTexturePixelCoordinates(unpack(GUIMarineHUD.kMinimapStencilTextureCoords))
    self.minimapStencil:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.minimapBackground:AddChild(self.minimapStencil)

    self.minimapScript = GetGUIManager():CreateGUIScript("GUIMinimapFrame")
    self.minimapScript:ShowMap(true)
    self.minimapScript:SetBackgroundMode(GUIMinimapFrame.kModeZoom)
    local minimapSize = self.minimapScript:GetMinimapSize()
    self.minimapScript:SetZoom(GUIMarineHUD.kDefaultZoom)

    // we need an additional frame here since all positions are relative in the minimap script (due to zooming)
    self.minimapFrame = GetGUIManager():CreateGraphicItem()
    self.minimapFrame:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.minimapFrame:AddChild(self.minimapScript:GetBackground())
    self.minimapFrame:SetColor(Color(1,1,1,0))

    self.minimapScanLines = self:CreateAnimatedGraphicItem()
    self.minimapScanLines:SetTexture(GUIMarineHUD.kMinimapBorderTexture)
    self.minimapScanLines:SetTexturePixelCoordinates(unpack(GUIMarineHUD.kMinimapScanlineTextureCoords))
    self.minimapScanLines:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.minimapScanLines:SetColor(Color(1,1,1,1))
    self.minimapScanLines:SetLayer(1)
    self.minimapScanLines:SetBlendTechnique(GUIItem.Add)
    self.minimapScanLines:SetStencilFunc(GUIItem.NotEqual)
    self.minimapScanLines:SetIsVisible(false)
    self.minimapBackground:AddChild(self.minimapScanLines)

    self.minimapBackground:AddChild(self.minimapFrame)

end

function GUIMarineHUD:SetHUDMapEnabled(enabled)

    if (enabled == false) and self.minimapScript then
        self:UninitializeMinimap()
    elseif (enabled == true) and self.minimapScript == nil then
        self:InitializeMinimap()
        self:ResetMinimap()
    end

    self.minimapEnabled = enabled

end

function GUIMarineHUD:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)

    if self.statusDisplay then
        self.statusDisplay:Destroy()
        self.statusDisplay = nil
    end
    
    if self.eventDisplay then    
        self.eventDisplay:Destroy()   
        self.eventDisplay = nil 
    end

    if self.fuelDisplay then
        self.fuelDisplay:Destroy()
        self.fuelDisplay = nil
    end

    if self.inventoryDisplay then
        self.inventoryDisplay:Destroy()
        self.inventoryDisplay = nil
    end

    self:UninitializeMinimap()

end

function GUIMarineHUD:UninitializeMinimap()

    if self.minimapScript then
        GetGUIManager():DestroyGUIScript(self.minimapScript)
        self.minimapScript = nil
    end

    if self.minimapBackground then
        self.minimapBackground:Destroy()
        self.minimapBackground = nil
    end

    if self.minimapFrame then
        GUI.DestroyItem(self.minimapFrame)
        self.minimapFrame = nil
    end

end

function GUIMarineHUD:SetIsVisible(isVisible)
    self.background:SetIsVisible(isVisible)
end

function GUIMarineHUD:SetStatusDisplayVisible(visible)
    self.statusDisplay:SetIsVisible(visible)
end

function GUIMarineHUD:SetFrameVisible(visible)    
end

function GUIMarineHUD:SetInventoryDisplayVisible(visible)
    self.inventoryDisplay:SetIsVisible(visible)
end

function GUIMarineHUD:Reset()

    // --- kGUILayerPlayerHUDForeground1

    self.scanLeft:SetUniformScale(self.scale)
    self.scanLeft:SetSize(Vector(1100, 1200, 0))
    self.scanLeft:SetColor(Color(1,1,1,0))

    self.scanRight:SetUniformScale(self.scale)
    self.scanRight:SetSize(Vector(-1100, 1200, 0))
    self.scanRight:SetColor(Color(1,1,1,0))

    self.commanderName:SetUniformScale(self.scale)
    self.commanderName:SetScale(GetScaledVector() * 1.1)
    self.commanderName:SetPosition(GUIMarineHUD.kCommanderNameOffset)

    self.statusDisplay:Reset(self.scale)
    self.eventDisplay:Reset(self.scale)
    //self.resourceDisplay:Reset(self.scale)
    self.inventoryDisplay:Reset(self.scale)

    self.armorLevel:SetPosition(GUIMarineHUD.kUpgradePos * self.scale)
    self.armorLevel:SetSize(GUIMarineHUD.kUpgradeSize * self.scale)
    self.armorLevel:SetIsVisible(false)

    self.weaponLevel:SetPosition(Vector(GUIMarineHUD.kUpgradePos.x, GUIMarineHUD.kUpgradePos.y + GUIMarineHUD.kUpgradeSize.y + 8, 0) * self.scale)
    self.weaponLevel:SetSize(GUIMarineHUD.kUpgradeSize * self.scale)
    self.weaponLevel:SetIsVisible(false)
    
    self.mtracking:SetPosition(Vector(GUIMarineHUD.kUpgradePos.x, GUIMarineHUD.kUpgradePos.y + GUIMarineHUD.kUpgradeSize.y + GUIMarineHUD.kUpgradeSize.y + 16, 0) * self.scale)
    self.mtracking:SetSize(GUIMarineHUD.kUpgradeSize * self.scale)
    self.mtracking:SetIsVisible(false)
    
    if self.minimapEnabled then    
        self:ResetMinimap()       
    end

    self.locationText:SetUniformScale(self.scale)
    self.locationText:SetScale(GetScaledVector())
    self.locationText:SetPosition(GUIMarineHUD.kLocationTextOffset)

end

GUIMarineHUD.kMinimapScanStartPos = Vector(0, - 128, 0)
GUIMarineHUD.kMinimapScanEndPos = Vector(0, GUIMarineHUD.kMinimapBackgroundSize.y + 512, 0)

local function ScanLineAnim(script, item)

    item:SetPosition(GUIMarineHUD.kMinimapScanStartPos)
    item:SetPosition(GUIMarineHUD.kMinimapScanEndPos, 4, "MINIMAP_SCANLINE_ANIM", AnimateLinear, ScanLineAnim)

end

function GUIMarineHUD:ResetMinimap()

    self.minimapBackground:SetUniformScale(self.scale)
    self.minimapBackground:SetSize(GUIMarineHUD.kMinimapBackgroundSize)
    self.minimapBackground:SetPosition( GUIMarineHUD.kMinimapPos )

    //self.minimapPower:SetUniformScale(self.scale)
    //self.minimapPower:SetSize(GUIMarineHUD.kMinimapPowerSize)
    //self.minimapPower:SetPosition(GUIMarineHUD.kMinimapPowerPos)

    self.minimapStencil:SetSize(self.scale * GUIMarineHUD.kStencilSize)
    self.minimapStencil:SetPosition(self.scale * (- GUIMarineHUD.kStencilSize/2 + GUIMarineHUD.kStencilPos))

    self.minimapScanLines:SetUniformScale(self.scale)
    self.minimapScanLines:SetSize(GUIMarineHUD.kMinimapBackgroundSize)

    self.minimapFrame:SetPosition(Vector(-190, -180, 0) * self.scale)

    self.minimapScanLines:SetPosition(GUIMarineHUD.kMinimapScanStartPos)
    self.minimapScanLines:SetPosition(GUIMarineHUD.kMinimapScanEndPos, 4, "MINIMAP_SCANLINE_ANIM", AnimateLinear, ScanLineAnim)

end

function GUIMarineHUD:TriggerInitAnimations()

    self.scanLeft:SetColor(Color(1,1,1,0.8))
    //self.scanLeft:SetSize(Vector(1200, 1200, 0), 1)
    self.scanLeft:FadeIn(0.3, nil, AnimateLinear,
        function (self)
            self.scanLeft:FadeOut(0.5, nil, AnimateQuadratic)
        end
        )

    self.scanRight:SetColor(Color(1,1,1,0.8))
    //self.scanRight:SetSize(Vector(-1200, 1200, 0), 1)
    self.scanRight:FadeIn(0.3, nil, AnimateLinear,
        function (self)
            self.scanRight:FadeOut(0.5, nil, AnimateQuadratic)
        end
        )

    // create random squares that fade out
    for i = 1, GUIMarineHUD.kNumInitSquares do

        local animatedSquare = self:CreateAnimatedGraphicItem()

        local randomPos = Vector(
                    math.random(0, 1920),
                    math.random(0, 1200),
                    0)

        animatedSquare:SetUniformScale(self.scale)
        animatedSquare:SetPosition(randomPos)
        animatedSquare:SetSize(GUIMarineHUD.kInitSquareSize)
        animatedSquare:SetColor(GUIMarineHUD.kInitSquareColors)
        animatedSquare:FadeOut(1, nil, AnimateLinear,
            function (self, item)
                item:Destroy()
            end
            )

    end

end

function GUIMarineHUD:Update(deltaTime)

    PROFILE("GUIMarineHUD:Update")

    // Update health / armor bar
    self.statusDisplay:Update(deltaTime, { PlayerUI_GetPlayerHealth(), PlayerUI_GetPlayerMaxHealth(), PlayerUI_GetPlayerArmor(), PlayerUI_GetPlayerMaxArmor(), PlayerUI_GetPlayerParasiteState() } )

    // Update notifications and events
    if self.lastNotificationUpdate + GUIMarineHUD.kNotificationUpdateIntervall < Client.GetTime() then

        self.eventDisplay:Update(Client.GetTime() - self.lastNotificationUpdate, { PlayerUI_GetRecentNotification(), PlayerUI_GetRecentPurchaseable() } )
        self.lastNotificationUpdate = Client.GetTime()

    end

    // Update inventory
    self.inventoryDisplay:Update(deltaTime, { PlayerUI_GetActiveWeaponTechId(), PlayerUI_GetInventoryTechIds() })

    // Update commander name
    local commanderName = PlayerUI_GetCommanderName()

    if commanderName == nil then

        commanderName = Locale.ResolveString("NO_COMMANDER")

        if not self.commanderNameIsAnimating then

            self.commanderNameIsAnimating = true
            self.commanderName:SetColor(Color(1, 0, 0, 1))
            self.commanderName:FadeOut(1, nil, AnimateLinear, AnimFadeIn)

        end

    else

        commanderName = Locale.ResolveString("COMMANDER") .. commanderName

        if self.commanderNameIsAnimating then

            self.commanderNameIsAnimating = false
            self.commanderName:DestroyAnimations()
            self.commanderName:SetColor(GUIMarineHUD.kActiveCommanderColor)

        end

    end

    commanderName = string.upper(commanderName)
    if self.lastCommanderName ~= commanderName then

        self.commanderName:DestroyAnimation("COMM_TEXT_WRITE")
        self.commanderName:SetText("")
        self.commanderName:SetText(commanderName, 0.5, "COMM_TEXT_WRITE")
        self.lastCommanderName = commanderName

    end

    // Update game time
    local gameTime = PlayerUI_GetGameStartTime()

    if gameTime ~= 0 then
        gameTime = math.floor(Shared.GetTime()) - PlayerUI_GetGameStartTime()
    end

    //local minutes = math.floor(gameTime/60)
    //local seconds = gameTime - minutes*60
    //local gameTimeText = string.format("game time: %d:%02d", minutes, seconds)

    //self.gameTimeText:SetText(gameTimeText)

    // Update minimap
    local locationName = PlayerUI_GetLocationName()
    if locationName then
        locationName = string.upper(locationName)
    else
        locationName = ""
    end

    if self.lastLocationText ~= locationName then

        // Delete current string and start write animation
        self.locationText:DestroyAnimations()
        self.locationText:SetText("")
        self.locationText:SetText(string.format(Locale.ResolveString("IN_LOCATION"), locationName), 0.8)

        self.lastLocationText = locationName

    end

    // Update passive upgrades
    local armorLevel = 0
    local weaponLevel = 0
    local motiontracking = false
    
    if PlayerUI_GetIsPlaying() then

        armorLevel = PlayerUI_GetArmorLevel()
        weaponLevel = PlayerUI_GetWeaponLevel()
        motiontracking = PlayerUI_GetHasMotionTracking()
        
    end
    
    if armorLevel ~= self.lastArmorLevel then
    
        self:ShowNewArmorLevel(armorLevel)
        self.lastArmorLevel = armorLevel
        
    end
    
    if weaponLevel ~= self.lastWeaponLevel then
    
        self:ShowNewWeaponLevel(weaponLevel)
        self.lastWeaponLevel = weaponLevel
        
    end
    
    if motiontracking ~= self.motiontracking then
        self:ShowMotionTracking(motiontracking)
        self.motiontracking = motiontracking
        
    end

    local useColor = kIconColors[kMarineTeamType]
    if not MarineUI_GetHasArmsLab() then
        useColor = Color(1, 0, 0, 1)
    end
    self.weaponLevel:SetColor(useColor)
    self.armorLevel:SetColor(useColor)
    
    local useObsColor = Color(1, 1, 1, 1)        
    if not MarineUI_GetHasObservatory() then
        useObsColor = Color(1, 0, 0, 1)
    end
    self.mtracking:SetColor(useObsColor)
    
    // Updates animations
    GUIAnimatedScript.Update(self, deltaTime)

end

function GUIMarineHUD:UpdatePowerIcon(powerState)
end

function GUIMarineHUD:SetIsVisible(isVisible)
    self.background:SetIsVisible(isVisible)
end

function GUIMarineHUD:ShowNewArmorLevel(armorLevel)

    if armorLevel ~= 0 then
        local textureCoords = GetTextureCoordinatesForIcon(GetTechIdForArmorLevel(armorLevel), true)
        self.armorLevel:SetIsVisible(true)
        self.armorLevel:SetTexturePixelCoordinates(unpack(textureCoords))
    else
        self.armorLevel:SetIsVisible(false)
    end

end

function GUIMarineHUD:ShowMotionTracking(motiontracking)

    if motiontracking then
        local textureCoords = GetTextureCoordinatesForIcon(kTechId.MotionTracking, true)
        self.mtracking:SetIsVisible(true)
        self.mtracking:SetTexturePixelCoordinates(unpack(textureCoords))
    else
        self.mtracking:SetIsVisible(false)
    end

end

function GUIMarineHUD:ShowNewWeaponLevel(weaponLevel)

    if weaponLevel ~= 0 then
        local textureCoords = GetTextureCoordinatesForIcon(GetTechIdForWeaponLevel(weaponLevel), true)
        self.weaponLevel:SetIsVisible(true)
        self.weaponLevel:SetTexturePixelCoordinates(unpack(textureCoords))
    else
        self.weaponLevel:SetIsVisible(false)
    end

end

function GUIMarineHUD:OnAnimationCompleted(animatedItem, animationName, itemHandle)

    //self.resourceDisplay:OnAnimationCompleted(animatedItem, animationName, itemHandle)

end

function GUIMarineHUD:OnResolutionChanged(oldX, oldY, newX, newY)

    self.scale = newY / kBaseScreenHeight 
    self.background:SetSize( Vector(newX, newY, 0) )
    
    self:Reset()
    
end