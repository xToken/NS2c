// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIInsight_TopBar.lua
//
// Created by: Jon 'Huze' Hughes (jon@jhuze.com)
//
// Spectator: Displays team names and gametime
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class "GUIInsight_TopBar" (GUIScript)

local isVisible

local kBackgroundTexture = "ui/topbar.dds"
local kIconTextureAlien = "ui/alien_commander_textures.dds"
local kIconTextureMarine = "ui/marine_commander_textures.dds"
local kTeamResourceIconCoords = {192, 363, 240, 411}
local kResourceTowerIconCoords = {240, 363, 280, 411}
local kBuildMenuTexture = "ui/buildmenu.dds"

local kTimeFontName = "fonts/AgencyFB_medium.fnt"
local kTimeFontScale = GUIScale(Vector(1, 1, 0))
local kMarineFontName = "fonts/AgencyFB_medium.fnt"
local kAlienFontName = "fonts/AgencyFB_medium.fnt"
local kTeamFontScale = GUIScale(Vector(1, 1, 0))

local kScoreFontScale = GUIScale(Vector(1.2, 1.2, 0))

local kInfoFontName = "fonts/AgencyFB_small.fnt"
local kInfoFontScale = GUIScale(Vector(1, 1, 0))

local kBackgroundSize = GUIScale(Vector(400, 35, 0))
local kScoresSize = GUIScale(Vector(50,32, 0))
local kTeamNameSize = GUIScale(Vector(150, 24, 0))
local kIconSize = GUIScale(Vector(32, 32, 0))
local kButtonSize = GUIScale(Vector(8, 8, 0))

local kButtonOffset = GUIScale(Vector(0,20,0))

local background
local gameTime

local scoresBackground
local teamsSwapButton
local marinePlusButton
local marineMinusButton
local alienPlusButton
local alienMinusButton

local marineTeamScore
local alienTeamScore

local marineNameBackground
local marineTeamName
local marineResources
local marineExtractors

local alienNameBackground
local alienTeamName
local alienResources
local alienHarvesters

local function CreateIconTextItem(team, parent, position, texture, coords)

    local background = GUIManager:CreateGraphicItem()
    if team == kTeam1Index then
        background:SetAnchor(GUIItem.Left, GUIItem.Top)
    else
        background:SetAnchor(GUIItem.Right, GUIItem.Top)
    end
    background:SetColor(Color(0,0,0,0))
    background:SetSize(kIconSize)
    parent:AddChild(background)

    local icon = GUIManager:CreateGraphicItem()
    icon:SetSize(kIconSize)
    icon:SetAnchor(GUIItem.Left, GUIItem.Top)
    icon:SetPosition(position)
    icon:SetTexture(texture)
    icon:SetTexturePixelCoordinates(unpack(coords))
    background:AddChild(icon)
    
    local value = GUIManager:CreateTextItem()
    value:SetFontName(kInfoFontName)
    value:SetScale(kInfoFontScale)
    value:SetAnchor(GUIItem.Left, GUIItem.Center)
    value:SetTextAlignmentX(GUIItem.Align_Min)
    value:SetTextAlignmentY(GUIItem.Align_Center)
    value:SetColor(Color(1, 1, 1, 1))
    value:SetPosition(position + Vector(kIconSize.x + GUIScale(5), 0, 0))
    background:AddChild(value)
    
    return value
    
end

local function CreateButtonItem(parent, position, color)

    local button = GUIManager:CreateGraphicItem()
    button:SetSize(kButtonSize)
    button:SetPosition(position - kButtonSize/2)
    button:SetColor(color)
    button:SetIsVisible(false)
    parent:AddChild(button)
    
    return button
    
end

local function GetTeamInfoStrings(teamInfo)

    local teamRes = teamInfo:GetTeamResources()
    local numRTs = teamInfo:GetNumResourceTowers()
    local constructingRTs = teamInfo:GetNumCapturedResPoints() - numRTs
    
    local resString = tostring(teamRes)
    local rtString = tostring(numRTs)
    if constructingRTs > 0 then
        rtString = rtString .. string.format(" (%d)", constructingRTs)
    end

    return resString, rtString
    
end

function GUIInsight_TopBar:Initialize()

    isVisible = true
        
    local texSize = GUIScale(Vector(512,57,0))
    local texCoord = {0,0,512,57}
    local texPos = Vector(-texSize.x/2,0,0)
    background = GUIManager:CreateGraphicItem()
    background:SetAnchor(GUIItem.Middle, GUIItem.Top)
    background:SetTexture(kBackgroundTexture)
    background:SetTexturePixelCoordinates(unpack(texCoord))
    background:SetSize(texSize)
    background:SetPosition(texPos)
    background:SetLayer(kGUILayerInsight)
    
    gameTime = GUIManager:CreateTextItem()
    gameTime:SetFontName(kTimeFontName)
    gameTime:SetScale(kTimeFontScale)
    gameTime:SetAnchor(GUIItem.Middle, GUIItem.Top)
    gameTime:SetPosition(GUIScale(Vector(0, 5, 0)))
    gameTime:SetTextAlignmentX(GUIItem.Align_Center)
    gameTime:SetTextAlignmentY(GUIItem.Align_Min)
    gameTime:SetColor(Color(1, 1, 1, 1))
    gameTime:SetText("")
    background:AddChild(gameTime)
    
    local scoresTexSize = GUIScale(Vector(512,71,0))
    local scoresTexCoord = {0,57,512,128}    
    
    scoresBackground = GUIManager:CreateGraphicItem()
    scoresBackground:SetTexture(kBackgroundTexture)
    scoresBackground:SetTexturePixelCoordinates(unpack(scoresTexCoord))
    scoresBackground:SetSize(scoresTexSize)
    scoresBackground:SetAnchor(GUIItem.Middle, GUIItem.Top)
    scoresBackground:SetPosition(Vector(-scoresTexSize.x/2, texSize.y - GUIScale(15), 0))
    scoresBackground:SetIsVisible(false)
    background:AddChild(scoresBackground)
    
    marineTeamScore = GUIManager:CreateTextItem()
    marineTeamScore:SetFontName(kTimeFontName)
    marineTeamScore:SetScale(kScoreFontScale)
    marineTeamScore:SetAnchor(GUIItem.Middle, GUIItem.Center)
    marineTeamScore:SetTextAlignmentX(GUIItem.Align_Center)
    marineTeamScore:SetTextAlignmentY(GUIItem.Align_Center)
    marineTeamScore:SetPosition(GUIScale(Vector(-30, -5, 0)))
    marineTeamScore:SetColor(Color(1, 1, 1, 1))
    scoresBackground:AddChild(marineTeamScore)
    
    alienTeamScore = GUIManager:CreateTextItem()
    alienTeamScore:SetFontName(kTimeFontName)
    alienTeamScore:SetScale(kScoreFontScale)
    alienTeamScore:SetAnchor(GUIItem.Middle, GUIItem.Center)
    alienTeamScore:SetTextAlignmentX(GUIItem.Align_Center)
    alienTeamScore:SetTextAlignmentY(GUIItem.Align_Center)
    alienTeamScore:SetPosition(GUIScale(Vector(30, -5, 0)))
    alienTeamScore:SetColor(Color(1, 1, 1, 1))
    scoresBackground:AddChild(alienTeamScore)
    
    marineTeamName = GUIManager:CreateTextItem()
    marineTeamName:SetFontName(kMarineFontName)
    marineTeamName:SetScale(kTeamFontScale)
    marineTeamName:SetAnchor(GUIItem.Middle, GUIItem.Center)
    marineTeamName:SetTextAlignmentX(GUIItem.Align_Center)
    marineTeamName:SetTextAlignmentY(GUIItem.Align_Center)
    marineTeamName:SetPosition(GUIScale(Vector(-scoresTexSize.x/4, -7, 0)))
    marineTeamName:SetColor(Color(1, 1, 1, 1))
    scoresBackground:AddChild(marineTeamName)
    
    alienTeamName = GUIManager:CreateTextItem()
    alienTeamName:SetFontName(kAlienFontName)
    alienTeamName:SetScale(kTeamFontScale)
    alienTeamName:SetAnchor(GUIItem.Middle, GUIItem.Center)
    alienTeamName:SetTextAlignmentX(GUIItem.Align_Center)
    alienTeamName:SetTextAlignmentY(GUIItem.Align_Center)
    alienTeamName:SetPosition(GUIScale(Vector(scoresTexSize.x/4, -7, 0)))
    alienTeamName:SetColor(Color(1, 1, 1, 1))
    scoresBackground:AddChild(alienTeamName)
    
    local yoffset = GUIScale(4)
    marineResources = CreateIconTextItem(kTeam1Index, background, Vector(GUIScale(130),yoffset,0), kIconTextureMarine, kTeamResourceIconCoords)
    marineExtractors = CreateIconTextItem(kTeam1Index, background, Vector(GUIScale(50),yoffset,0), kIconTextureMarine, kResourceTowerIconCoords)

    alienHarvesters = CreateIconTextItem(kTeam2Index, background, Vector(-GUIScale(115),yoffset,0), kIconTextureAlien, kResourceTowerIconCoords)
    
    teamsSwapButton = CreateButtonItem(scoresBackground, kButtonOffset, Color(1,1,1,0.5))
    teamsSwapButton:SetAnchor(GUIItem.Middle, GUIItem.Center)
    
    marinePlusButton = CreateButtonItem(scoresBackground, kButtonOffset + Vector(-kButtonSize.x,-kButtonSize.y,0), Color(0,1,0,0.5))
    marinePlusButton:SetAnchor(GUIItem.Middle, GUIItem.Center)
    
    alienPlusButton = CreateButtonItem(scoresBackground, kButtonOffset + Vector(kButtonSize.x,-kButtonSize.y,0), Color(0,1,0,0.5))
    alienPlusButton:SetAnchor(GUIItem.Middle, GUIItem.Center)
    
    marineMinusButton = CreateButtonItem(scoresBackground, kButtonOffset + Vector(-kButtonSize.x,kButtonSize.y,0), Color(1,0,0,0.5))
    marineMinusButton:SetAnchor(GUIItem.Middle, GUIItem.Center)
    
    alienMinusButton = CreateButtonItem(scoresBackground, kButtonOffset + Vector(kButtonSize.x,kButtonSize.y,0), Color(1,0,0,0.5))
    alienMinusButton:SetAnchor(GUIItem.Middle, GUIItem.Center)
        
    self:SetTeams(InsightUI_GetTeam1Name(), InsightUI_GetTeam2Name())
    self:SetScore(InsightUI_GetTeam1Score(), InsightUI_GetTeam2Score())
        
end


function GUIInsight_TopBar:Uninitialize()

    GUI.DestroyItem(background)
    background = nil

end

function GUIInsight_TopBar:OnResolutionChanged(oldX, oldY, newX, newY)

    self:Uninitialize()
    
    self:Initialize()

end

function GUIInsight_TopBar:SetIsVisible(bool)

    isVisible = bool
    background:SetIsVisible(bool)

end

function GUIInsight_TopBar:SendKeyEvent(key, down)

    if isVisible then
        local cursor = MouseTracker_GetCursorPos()
        local inBackground, posX, posY = GUIItemContainsPoint(scoresBackground, cursor.x, cursor.y)
        if inBackground then
        
            if key == InputKey.MouseButton0 and down then

                local inSwap, posX, posY = GUIItemContainsPoint(teamsSwapButton, cursor.x, cursor.y)
                if inSwap then
                    Shared.ConsoleCommand("teams swap")
                end
                local inMPlus, posX, posY = GUIItemContainsPoint(marinePlusButton, cursor.x, cursor.y)
                if inMPlus then
                    Shared.ConsoleCommand("score1 +")
                end
                local inMMinus, posX, posY = GUIItemContainsPoint(marineMinusButton, cursor.x, cursor.y)
                if inMMinus then
                    Shared.ConsoleCommand("score1 -")
                end
                local inAPlus, posX, posY = GUIItemContainsPoint(alienPlusButton, cursor.x, cursor.y)
                if inAPlus then
                    Shared.ConsoleCommand("score2 +")
                end
                local inAMinus, posX, posY = GUIItemContainsPoint(alienMinusButton, cursor.x, cursor.y)
                if inAMinus then
                    Shared.ConsoleCommand("score2 -")
                end
                --Shared.ConsoleCommand("teams reset")
                return true
                
            end
            
        end    
    
    end

    return false

end

function GUIInsight_TopBar:Update(deltaTime)

    local startTime = PlayerUI_GetGameStartTime()

    if startTime ~= 0 then
        startTime = Shared.GetTime() - startTime
    end

    local minutes = math.floor(startTime/60)
    local seconds = startTime - minutes*60
    local gameTimeText = string.format("%d:%02d", minutes, seconds)

    gameTime:SetText(gameTimeText)
    
    local resString
    local rtString
    
    local marineTeamInfo = GetTeamInfoEntity(kTeam1Index)
    if marineTeamInfo then
    
        resString, rtString = GetTeamInfoStrings(marineTeamInfo)
        marineResources:SetText(resString)
        marineExtractors:SetText(rtString)
        
    end

    local alienTeamInfo = GetTeamInfoEntity(kTeam2Index)
    if alienTeamInfo then
    
        resString, rtString = GetTeamInfoStrings(alienTeamInfo)
        alienHarvesters:SetText(rtString)
        
    end

    local cursor = MouseTracker_GetCursorPos()
    local inBackground, posX, posY = GUIItemContainsPoint(scoresBackground, cursor.x, cursor.y)
    teamsSwapButton:SetIsVisible(inBackground)
    marinePlusButton:SetIsVisible(inBackground)
    marineMinusButton:SetIsVisible(inBackground)
    alienPlusButton:SetIsVisible(inBackground)
    alienMinusButton:SetIsVisible(inBackground)

end

function GUIInsight_TopBar:SetTeams(team1Name, team2Name)

    if team1Name == nil and team2Name == nil then
    
        scoresBackground:SetIsVisible(false)
            
    else

        scoresBackground:SetIsVisible(true)
        if team1Name == nil then
            alienTeamName:SetText(team2Name)
        elseif team2Name == nil then
            marineTeamName:SetText(team1Name)
        else        
            marineTeamName:SetText(team1Name)
            alienTeamName:SetText(team2Name)
        end
        
    end
    
end

function GUIInsight_TopBar:SetScore(team1Score, team2Score)

    marineTeamScore:SetText(tostring(team1Score))
    alienTeamScore:SetText(tostring(team2Score))

end