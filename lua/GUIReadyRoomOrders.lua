// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIReadyRoomOrders.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Added welcome text to show that this is a mod.

class 'GUIReadyRoomOrders' (GUIScript)

local kOrderSize = GUIScale( Vector(60, 60, 0) )
local kCircleSize = GUIScale( Vector(70, 70, 0) )
local kTextOffset = GUIScale( Vector(0, 40, 0) )

local kOrderPixelCoords = { 0, 0, 128, 128 }
local kCirclePixelCoords = { 0, 128, 512, 640 }

local kTexture = "ui/readyroomorders.dds"

local kFontName = "fonts/AgencyFB_small.fnt"
local kFontScale = GUIScale(Vector(1, 1, 0)) 

local kHoverAnimDistance = GUIScale(8)

local kRotationDuration = 5

local kTeamColors = 
{
    [kTeam1Index] = Color(kMarineTeamColorFloat),
    [kTeam2Index] = Color(kAlienTeamColorFloat)
}

local kWelcomeFontName = "fonts/AgencyFB_medium.fnt"
local kFadeInColor = Color(1, 1, 1, 1)
local kFadeOutColor = Color(1, 1, 1, 0)
// How long it takes for the welcome text to fade in and out.
local kWelcomeFadeInTime = 4
local kWelcomeFadeOutTime = 1
// This is how long to wait until the welcome text begins to fade out.
local kWelcomeStartFadeOutTime = 6
local kWelcomeTextReset = 8
// This is the delay before the welcome text fades in.
local kWelcomeDelay = 1.5

local function CreateVisionElement(self)

    local order = {}

    order.guiItem = GetGUIManager():CreateGraphicItem()
    order.guiItem:SetSize(kOrderSize)
    order.guiItem:SetBlendTechnique(GUIItem.Add)
    order.guiItem:SetTexture(kTexture)
    order.guiItem:SetTexturePixelCoordinates( unpack(kOrderPixelCoords) )
    
    order.circleItem = GetGUIManager():CreateGraphicItem()
    order.circleItem:SetSize(kCircleSize)
    order.circleItem:SetBlendTechnique(GUIItem.Add)
    order.circleItem:SetTexture(kTexture)
    order.circleItem:SetAnchor(GUIItem.Middle, GUIItem.Center)
    order.circleItem:SetTexturePixelCoordinates( unpack(kCirclePixelCoords) )  
    order.circleItem:SetPosition(-kCircleSize * .5)
    
    order.textItem = GetGUIManager():CreateTextItem()
    order.textItem:SetFontName(kFontName)
    order.textItem:SetScale(kFontScale)
    order.textItem:SetTextAlignmentX(GUIItem.Align_Center)
    order.textItem:SetTextAlignmentY(GUIItem.Align_Center)
    order.textItem:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    order.textItem:SetPosition(kTextOffset)

    order.guiItem:AddChild(order.circleItem)
    order.guiItem:AddChild(order.textItem)
    
    return order

end

function GUIReadyRoomOrders:Initialize()

    self.activeVisions = { }
    self.rotation = Vector(0, 0, 0)
    self.hover = Vector(0, 0, 0)
    
    self.welcomeText = GetGUIManager():CreateTextItem()
    self.welcomeText:SetFontName(kWelcomeFontName)
    self.welcomeText:SetTextAlignmentX(GUIItem.Align_Center)
    self.welcomeText:SetTextAlignmentY(GUIItem.Align_Center)
    self.welcomeText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.welcomeText:SetText("This Server is running the Natural Selection 2 Classic Mod.")
    self.welcomeText:SetColor(kFadeOutColor)
    self.welcomeTextStartTime = Shared.GetTime()
    self.welcometextCount = 0
    
end

function GUIReadyRoomOrders:Uninitialize()
    
    for i, blip in ipairs(self.activeVisions) do
        GUI.DestroyItem(blip.guiItem)
    end
    self.activeVisions = { }
    
    if self.welcomeText then
        GUI.DestroyItem(self.welcomeText)
    end
    self.welcomeText = nil
    
end

local function UpdateWelcomeText(self, deltaTime)

    local now = Shared.GetTime()
    local timeSinceStart = now - (self.welcomeTextStartTime + kWelcomeDelay)
    local color = nil
    if timeSinceStart <= kWelcomeFadeInTime then
        color = LerpColor(kFadeOutColor, kFadeInColor, Clamp(timeSinceStart / kWelcomeFadeInTime, 0, 1))
    elseif timeSinceStart >= kWelcomeStartFadeOutTime then
        color = LerpColor(kFadeInColor, kFadeOutColor, Clamp((timeSinceStart - kWelcomeStartFadeOutTime) / kWelcomeFadeOutTime, 0, 1))
    end
    
    if color then
        self.welcomeText:SetColor(color)
    end
    
    if timeSinceStart > kWelcomeTextReset and self.welcometextCount == 1 then
        self.welcomeText:SetText("For more information, visit NS2cmod.com.")
        self.welcomeText:SetColor(kFadeOutColor)
        self.welcomeTextStartTime = Shared.GetTime()
        self.welcometextCount = 2
    end
    
    if timeSinceStart > kWelcomeTextReset and self.welcometextCount == 0 then
        self.welcomeText:SetText("This mod changes much of the game to be more like NS1.")
        self.welcomeText:SetColor(kFadeOutColor)
        self.welcomeTextStartTime = Shared.GetTime()
        self.welcometextCount = 1
    end
    
end

function GUIReadyRoomOrders:Update(deltaTime)

    PROFILE("GUIReadyRoomOrders:Update")

    local unitVisions = PlayerUI_GetReadyRoomOrders()
    
    local numActiveVisions = #self.activeVisions
    local numCurrentVisions = #unitVisions
    
    local stencilUpdated = numActiveVisions ~= numCurrentVisions
    
    if numCurrentVisions > numActiveVisions then
    
        for i = 1, numCurrentVisions - numActiveVisions do
            table.insert(self.activeVisions, CreateVisionElement(self))
        end
    
    elseif numActiveVisions > numCurrentVisions then
    
        for i = 1, numActiveVisions - numCurrentVisions do
        
            GUI.DestroyItem(self.activeVisions[#self.activeVisions].guiItem)
            table.remove(self.activeVisions, #self.activeVisions)
            
        end
    
    end
    
    self.rotation.z = ((Shared.GetTime() % kRotationDuration) / kRotationDuration) * 2 * math.pi
    self.hover.y = math.cos(Shared.GetTime() * 4) * kHoverAnimDistance

    for index, currentVision in ipairs(unitVisions) do   
    
        local visionElement = self.activeVisions[index]
        
        local teamColor = Color(1,1,1,1)
        
        if kTeamColors[currentVision.TeamNumber] then
            teamColor = kTeamColors[currentVision.TeamNumber]
        end
        
        local worldPosition = currentVision.Position
        local screenPosition = GetClampedScreenPosition(worldPosition, GUIScale(196))
        visionElement.guiItem:SetPosition(screenPosition - kOrderSize *.5 + self.hover)        
        visionElement.guiItem:SetSize(kOrderSize)
        
        // Keep in mind that the nearest exit may be behind you
        local player = Client.GetLocalPlayer()
        local dotProduct = player:GetViewCoords().zAxis:DotProduct(GetNormalizedVector(worldPosition - player:GetEyePos()))
        local alpha = .2 + math.max(dotProduct * .8, 0)
        visionElement.guiItem:SetColor(Color(teamColor.r, teamColor.g, teamColor.b, alpha))    
                
        local playerString = ConditionalValue(currentVision.PlayerCount == 1, Locale.ResolveString("PLAYER"), Locale.ResolveString("PLAYERS"))
        
        visionElement.textItem:SetText(ToString(currentVision.PlayerCount) .. " " .. playerString)
        
        visionElement.circleItem:SetRotation(self.rotation)
        visionElement.circleItem:SetColor(Color(teamColor.r, teamColor.g, teamColor.b, alpha))
        visionElement.circleItem:SetIsVisible(not currentVision.IsFull)
        
    end
    
    UpdateWelcomeText(self, deltaTime)
    
end