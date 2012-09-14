// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIInsight_PlayerFrames.lua
//
// Created by: Jon 'Huze' Hughes (jon@jhuze.com)
//
// Spectator: Displays player info
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIInsight_PlayerFrames' (GUIScript)

local isVisible

local kMarineTexture = "ui/marine_sheet.dds"
local kAlienTexture = "ui/alien_sheet.dds"
local kBackgroundTexture = "ui/player.dds"
local kFrameTexture = "ui/players.dds"
local kHealthbarTexture = "ui/player_healthbar.dds"

-- Also change in OnResolutionChanged!
local scale = 0.55
local kHealthBarSize = GUIScale(Vector(14, 30, 0))
local kFrameYOffset = GUIScale(-240)
local kFrameYSpacing = GUIScale(20)
local kTeamNameFontSize = GUIScale(18)
local kTeamInfoFontSize = GUIScale(16)
local kPlayersPanelSize = GUIScale(Vector(95, 32, 0))
local kTopFrameSize = GUIScale(Vector(scale*256, scale*64, 0))
local kBottomFrameSize = GUIScale(Vector(scale*256, scale*128, 0))
local kIconSize = GUIScale(Vector(32, 32, 0))

-- Color constants.
local kInfoColor = Color(1, 1, 1, 1)
local kDeadColor = Color(1, 0, 0, 1)
local kCommanderColor = Color(1, 0.8, 0.1, 1)

-- Texture coordinates.
local leftBackgroundCoords = {0,0,256,92}
local leftFrameCoords = {0,92,256,184}
local leftGradientCoords = {0,184,256,276}
local leftTopCoords = {0,0,256,64}
local leftBottomCoords = {0,128,256,256}

local rightBackgroundCoords = {256,0,0,92}
local rightFrameCoords = {256,92,0,184}
local rightGradientCoords = {256,184,0,276}
local rightTopCoords = {256,0,512,64}
local rightBottomCoords = {256,128,512,256}

local iconSize = Vector(32,32,0)
local kIconCoords = {
    
    [Locale.ResolveString("STATUS_RIFLE")] =             {            0, 0,   iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_SHOTGUN")] =           {   iconSize.x, 0, 2*iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_GRENADE_LAUNCHER")] =  { 2*iconSize.x, 0, 3*iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_HEAVY_MACHINE_GUN")] =  { 2*iconSize.x, 0, 3*iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_FLAMETHROWER")] =      { 3*iconSize.x, 0, 4*iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_HEAVY_ARMOR")] =               { 0, iconSize.y,   iconSize.x, 2*iconSize.y },
    
    [Locale.ResolveString("STATUS_SKULK")] =             {            0, 0,   iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_GORGE")] =             {   iconSize.x, 0, 2*iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_LERK")] =              { 2*iconSize.x, 0, 3*iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_FADE")] =              { 3*iconSize.x, 0, 4*iconSize.x, iconSize.y },
    [Locale.ResolveString("STATUS_ONOS")] =              {            0, iconSize.y,   iconSize.x, 2*iconSize.y },
    [Locale.ResolveString("STATUS_EVOLVING")] =          {   iconSize.x, iconSize.y, 2*iconSize.x, 2*iconSize.y },
    [Locale.ResolveString("STATUS_EMBRYO")] =            {   iconSize.x, iconSize.y, 2*iconSize.x, 2*iconSize.y },
    
    [Locale.ResolveString("STATUS_COMMANDER")] =         { 2*iconSize.x, iconSize.y, 3*iconSize.x, 2*iconSize.y },
    [Locale.ResolveString("STATUS_DEAD")] =              { 3*iconSize.x, iconSize.y, 4*iconSize.x, 2*iconSize.y }

}

function GUIInsight_PlayerFrames:Initialize()

    isVisible = true

    -- Teams table format: Team GUIItems, color, player GUIItem list, get scores function.
    self.teams = {
        -- Blue team.
        [kTeam1Index] = {
            Background    = self:CreateBackground( kTeam1Index ),
            Color         = kBlueColor,
            PlayerList    = {},
            GetScores     = ScoreboardUI_GetBlueScores,
            TeamNumber    = kTeam1Index
        },
        -- Red team.
        [kTeam2Index] = {
            Background    = self:CreateBackground( kTeam2Index ),
            Color         = kRedColor,
            PlayerList    = {},
            GetScores     = ScoreboardUI_GetRedScores,
            TeamNumber    = kTeam2Index
        }
    }

end

function GUIInsight_PlayerFrames:Uninitialize()

    for index, team in ipairs(self.teams) do
        GUI.DestroyItem(team.Background)
    end
    self.teams = { }

end

function GUIInsight_PlayerFrames:OnResolutionChanged(oldX, oldY, newX, newY)

    self:Uninitialize()
    kHealthBarSize = GUIScale(Vector(14, 30, 0))
    kFrameYOffset = GUIScale(-240)
    kFrameYSpacing = GUIScale(20)
    kTeamNameFontSize = GUIScale(18)
    kTeamInfoFontSize = GUIScale(16)
    kPlayersPanelSize = GUIScale(Vector(95, 32, 0))
    kTopFrameSize = GUIScale(Vector(scale*256, scale*64, 0))
    kBottomFrameSize = GUIScale(Vector(scale*256, scale*128, 0))
    kIconSize = GUIScale(Vector(32, 32, 0))
    self:Initialize()

end


function GUIInsight_PlayerFrames:CreateBackground(teamNumber)

    -- Player
    local playersBackground = GUIManager:CreateGraphicItem()
    local top = GUIManager:CreateGraphicItem()
    local bottom = GUIManager:CreateGraphicItem()
    
    if teamNumber == kTeam1Index then
        playersBackground:SetAnchor(GUIItem.Left, GUIItem.Middle)
        playersBackground:SetPosition(Vector(0, kFrameYOffset, 0))
        playersBackground:SetColor(kBlueColor)
        
        top:SetTexturePixelCoordinates(unpack(leftTopCoords))
        top:SetAnchor(GUIItem.Left, GUIItem.Top)
        top:SetPosition(-Vector(0, kTopFrameSize.y,0))
        
        bottom:SetTexturePixelCoordinates(unpack(leftBottomCoords))
        bottom:SetAnchor(GUIItem.Left, GUIItem.Bottom)
        
        playersBackground:SetTexturePixelCoordinates(unpack(leftGradientCoords))
    elseif teamNumber == kTeam2Index then
        playersBackground:SetAnchor(GUIItem.Right, GUIItem.Middle)
        playersBackground:SetPosition(Vector(-kPlayersPanelSize.x, kFrameYOffset, 0))
        playersBackground:SetColor(kRedColor)
        
        top:SetTexturePixelCoordinates(unpack(rightTopCoords))
        top:SetAnchor(GUIItem.Right, GUIItem.Top)
        top:SetPosition(-Vector(kTopFrameSize.x, kTopFrameSize.y,0))
        
        bottom:SetTexturePixelCoordinates(unpack(rightBottomCoords))
        bottom:SetAnchor(GUIItem.Right, GUIItem.Bottom)
        bottom:SetPosition(-Vector(kBottomFrameSize.x,0,0))
        
        playersBackground:SetTexturePixelCoordinates(unpack(rightGradientCoords))
    end

    top:SetSize(kTopFrameSize)
    top:SetTexture(kFrameTexture)
    top:SetLayer(kGUILayerInsight+1)
    playersBackground:AddChild(top)
    
    bottom:SetSize(kBottomFrameSize)
    bottom:SetTexture(kFrameTexture)
    bottom:SetLayer(kGUILayerInsight+1)
    playersBackground:AddChild(bottom)
    
    playersBackground:SetTexture(kBackgroundTexture)
    playersBackground:SetColor(Color(0,0,0,1))
    playersBackground:SetLayer(kGUILayerInsight)

    return playersBackground
end

function GUIInsight_PlayerFrames:SetIsVisible(bool)

    isVisible = bool
    
    for index, team in ipairs(self.teams) do
        team.Background:SetIsVisible(bool)
    end

end

local function follow(entity)

    if entity then
    
        local origin = entity:GetOrigin()
        local player = Client.GetLocalPlayer()
        player:SetWorldScrollPosition(origin.x-5, origin.z)
        
    end

end

function GUIInsight_PlayerFrames:Update(deltaTime)

    if isVisible then
    
        --Update Teams and Tech Points
        local maxplayers = 0
        for index, team in ipairs(self.teams) do

            self:UpdatePlayers(team)

            maxplayers = math.max( maxplayers, table.maxn(team.PlayerList) )

        end

        if self.FollowEntityId then
        
            local entity = Shared.GetEntity(self.FollowEntityId)
            follow(entity)
            
        end

    end

end

-------------
-- PLAYERS --
-------------
  
--Sort by entity ID (clientIndex)
function GUIInsight_PlayerFrames:Players_Sort(team)

    function sortById(player1, player2)
        return player1.ClientIndex > player2.ClientIndex
    end

    -- Sort it by entity id
    table.sort(team, sortById)

end

function GUIInsight_PlayerFrames:UpdatePlayers(updateTeam)

    local teamScores = updateTeam["GetScores"]()

    -- How many items per player.
    local numPlayers = table.count(teamScores)
    local playersGUIItem = updateTeam.Background

    -- Draw if there are players
    if numPlayers > 0 then
        local playerList = updateTeam["PlayerList"]
        playersGUIItem:SetIsVisible(true)
        
        -- Resize the player list if it doesn't match.
        if table.count(playerList) ~= numPlayers then
        
            while table.count(playerList) > numPlayers do
                local removeItem = playerList[1]
                playersGUIItem:RemoveChild(removeItem.Background)
                GUI.DestroyItem(removeItem.Background)
                table.remove(playerList,1)
            end
            
            while table.count(playerList) < numPlayers do
                local team = updateTeam.TeamNumber
                local newItem
                if team == kTeam1Index then
                    newItem = self:CreateMarineBackground()
                else
                    newItem = self:CreateAlienBackground()
                end
                playersGUIItem:AddChild(newItem.Background)
                table.insert(playerList,newItem)
            end
            -- Make sure there is enough room for all players on this GUI.
            playersGUIItem:SetSize(Vector(kPlayersPanelSize.x, (kPlayersPanelSize.y + kFrameYSpacing)* numPlayers, 0))
        end

        -- Sort by entity Id so players always remain in the same order
        self:Players_Sort(teamScores) -- kind of hacky, but gets the job done

        local currentY = kFrameYSpacing
        local currentPlayerIndex = 1
        for index, player in pairs(playerList) do
            local playerRecord = teamScores[currentPlayerIndex]

            self:UpdatePlayer(player, playerRecord, updateTeam, currentY)

            currentY = currentY + kPlayersPanelSize.y + kFrameYSpacing
            currentPlayerIndex = currentPlayerIndex + 1
        end
    else
        playersGUIItem:SetIsVisible(false)
    end

end

function GUIInsight_PlayerFrames:UpdatePlayer(player, playerRecord, team, yPosition)

    local playerName = playerRecord.Name
    local isCommander = playerRecord.IsCommander
    
    player.EntityId = playerRecord.EntityId
    
    local resourcesStr = string.format("%d Res", playerRecord.Resources)
    local KDRStr = string.format("%s / %s", playerRecord.Kills, playerRecord.Deaths)
    local currentPosition = Vector(player["Background"]:GetPosition())
    local playerStatus = playerRecord.Status
    local teamNumber = team["TeamNumber"]
    local teamColor = team["Color"]

    currentPosition.y = yPosition
    player["Background"]:SetPosition(currentPosition)
    player["Detail"]:SetText(resourcesStr)
    player.KDR:SetText(KDRStr)
    player["Background"]:SetColor(teamColor)
    -- Name
    local name = player["Name"]
    name:SetText(playerName)

    -- Health bar
    local healthBar = player["HealthBar"]
    local barSize = 0
    if playerStatus == "Dead" then

        player["Background"]:SetColor(kDeadColor)
        healthBar:SetIsVisible(false)
        
    elseif isCommander then
    
        player["Background"]:SetColor(kCommanderColor)
        healthBar:SetIsVisible(false)
        
    else
    
        if playerRecord.Health then           
            local health = playerRecord.Health + playerRecord.Armor * kHealthPointsPerArmor
            local maxHealth = playerRecord.MaxHealth + playerRecord.MaxArmor * kHealthPointsPerArmor
            local healthFraction = health/maxHealth
            
            barSize = math.max(healthFraction * kHealthBarSize.y, 0)
            local barColor
            if healthFraction > 0.6 then
                local redFraction = 1 - ((healthFraction - 0.6) / 0.4)
                barColor = Color(redFraction, 1, 0, 1)
            elseif healthFraction > 0.1 then
                local greenFraction = ((healthFraction - 0.1) / 0.5)
                barColor = Color(1, greenFraction, 0, 1)
            else
                barColor = Color(1, 0, 0, 1)
            end
            healthBar:SetColor(barColor)
            healthBar:SetSize(Vector(kHealthBarSize.x, -barSize, 0))
            healthBar:SetIsVisible(true)
        else
            healthBar:SetIsVisible(false)
        end

    end

    local coords = kIconCoords[playerStatus]
    if coords then
        player["Type"]:SetIsVisible(true)
        player["Type"]:SetTexturePixelCoordinates(unpack(coords))
    else
        player["Type"]:SetIsVisible(false)
    end
    
end

function GUIInsight_PlayerFrames:SendKeyEvent( key, down )

    if isVisible and key == InputKey.MouseButton0 and down then

        local cursor = MouseTracker_GetCursorPos()
        
        for index, team in ipairs(self.teams) do

            local inside, posX, posY = GUIItemContainsPoint( team.Background, cursor.x, cursor.y )
            if inside then

                local index = math.floor( posY / (kPlayersPanelSize.y + kFrameYSpacing) ) + 1
                local entityId = team.PlayerList[index].EntityId
                -- Teleport to the mapblip with the same entityId
                for _, blip in ientitylist(Shared.GetEntitiesWithClassname("MapBlip")) do

                    if blip.ownerEntityId == entityId then
                    
                        local player = Client.GetLocalPlayer()
                        player:SetWorldScrollPosition(blip.worldX-5, blip.worldZ)
                        
                    end
                    
                end
                self.FollowEntityId = entityId
                return true
                
            end
        
        end
        
    end

    self.FollowEntityId = nil
    return false

end

------------------
-- GUI CREATION --
------------------

function GUIInsight_PlayerFrames:CreateMarineBackground()

    -- Create background.
    local background = GUIManager:CreateGraphicItem()
    background:SetSize(kPlayersPanelSize)
    background:SetAnchor(GUIItem.Left, GUIItem.Top)
    background:SetTexture(kBackgroundTexture)
    background:SetTexturePixelCoordinates(unpack(leftBackgroundCoords))
    
    -- Type icon item (Weapon/Class/CommandStructure)
    local typeIcon = GUIManager:CreateGraphicItem()
    typeIcon:SetSize(kIconSize)
    typeIcon:SetAnchor(GUIItem.Left, GUIItem.Top)
    typeIcon:SetPosition(Vector(kHealthBarSize.x, 0, 0))
    typeIcon:SetTexture(kMarineTexture)
    typeIcon:SetColor(Color(1, 1, 1, .8))
    background:AddChild(typeIcon)

    -- Name text item. (Player Name / Structure Location)
    local nameItem = GUIManager:CreateTextItem()
    nameItem:SetFontIsBold(true)
    nameItem:SetFontSize(kTeamNameFontSize)
    nameItem:SetAnchor(GUIItem.Left, GUIItem.Top)
    nameItem:SetTextAlignmentX(GUIItem.Align_Min)
    nameItem:SetTextAlignmentY(GUIItem.Align_Max)
    nameItem:SetColor(kInfoColor)
    background:AddChild(nameItem)

    -- KDR text item.
    local KDRitem = GUIManager:CreateTextItem()
    KDRitem:SetFontIsBold(true)
    KDRitem:SetFontSize(kTeamInfoFontSize)
    KDRitem:SetAnchor(GUIItem.Left, GUIItem.Top)
    KDRitem:SetTextAlignmentX(GUIItem.Align_Max)
    KDRitem:SetTextAlignmentY(GUIItem.Align_Min)
    KDRitem:SetPosition(Vector(kPlayersPanelSize.x, 0, 0))
    KDRitem:SetColor(kInfoColor)
    background:AddChild(KDRitem)
    
    -- Res text item.
    local detailItem = GUIManager:CreateTextItem()
    detailItem:SetFontIsBold(true)
    detailItem:SetFontSize(kTeamInfoFontSize)
    detailItem:SetAnchor(GUIItem.Left, GUIItem.Middle)
    detailItem:SetTextAlignmentX(GUIItem.Align_Max)
    detailItem:SetTextAlignmentY(GUIItem.Align_Min)
    detailItem:SetPosition(Vector(kPlayersPanelSize.x, 0, 0))
    detailItem:SetColor(kInfoColor)
    background:AddChild(detailItem)
    
    -- Health bar item.
    local healthBar = GUIManager:CreateGraphicItem()
    healthBar:SetSize(kHealthBarSize)
    healthBar:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    healthBar:SetColor(Color(1,1,1,1))
    healthBar:SetTexture(kHealthbarTexture)
    healthBar:SetTexturePixelCoordinates(unpack({0,64,32,0}))
    background:AddChild(healthBar)
    
    local frame = GUIManager:CreateGraphicItem()
    frame:SetSize(kPlayersPanelSize)
    frame:SetAnchor(GUIItem.Left, GUIItem.Top)
    frame:SetTexture(kBackgroundTexture)
    frame:SetTexturePixelCoordinates(unpack(leftFrameCoords))
    background:AddChild(frame)
    
    return { Background = background, Frame = frame, Name = nameItem, Type = typeIcon, Detail = detailItem, KDR = KDRitem, HealthBar = healthBar }

end

function GUIInsight_PlayerFrames:CreateAlienBackground()

    -- Create background.
    local background = GUIManager:CreateGraphicItem()
    background:SetSize(kPlayersPanelSize)
    background:SetAnchor(GUIItem.Left, GUIItem.Top)
    background:SetTexture(kBackgroundTexture)
    background:SetTexturePixelCoordinates(unpack(rightBackgroundCoords))
    
    -- Type icon item (Weapon/Class/CommandStructure)
    local typeIcon = GUIManager:CreateGraphicItem()
    typeIcon:SetSize(kIconSize)
    typeIcon:SetAnchor(GUIItem.Right, GUIItem.Top)
    typeIcon:SetPosition(Vector(-kHealthBarSize.x - kIconSize.x, 0, 0))
    typeIcon:SetTexture(kAlienTexture)
    typeIcon:SetColor(Color(1, 1, 1, .8))
    background:AddChild(typeIcon)

    -- Name text item. (Player Name / Structure Location)
    local nameItem = GUIManager:CreateTextItem()
    nameItem:SetFontIsBold(true)
    nameItem:SetFontSize(kTeamNameFontSize)
    nameItem:SetAnchor(GUIItem.Right, GUIItem.Top)
    nameItem:SetTextAlignmentX(GUIItem.Align_Max)
    nameItem:SetTextAlignmentY(GUIItem.Align_Max)
    nameItem:SetColor(kInfoColor)
    background:AddChild(nameItem)

    -- KDR text item.
    local KDRitem = GUIManager:CreateTextItem()
    KDRitem:SetFontIsBold(true)
    KDRitem:SetFontSize(kTeamInfoFontSize)
    KDRitem:SetAnchor(GUIItem.Left, GUIItem.Top)
    KDRitem:SetPosition(Vector(GUIScale(2), 0, 0))
    KDRitem:SetTextAlignmentX(GUIItem.Align_Min)
    KDRitem:SetTextAlignmentY(GUIItem.Align_Min)
    KDRitem:SetColor(kInfoColor)
    background:AddChild(KDRitem)
    
    -- Res text item.
    local detailItem = GUIManager:CreateTextItem()
    detailItem:SetFontIsBold(true)
    detailItem:SetFontSize(kTeamInfoFontSize)
    detailItem:SetAnchor(GUIItem.Left, GUIItem.Middle)
    detailItem:SetPosition(Vector(GUIScale(2), 0, 0))
    detailItem:SetTextAlignmentX(GUIItem.Align_Min)
    detailItem:SetTextAlignmentY(GUIItem.Align_Min)
    detailItem:SetColor(kInfoColor)
    background:AddChild(detailItem)
    
    -- Health bar item.
    local healthBar = GUIManager:CreateGraphicItem()
    healthBar:SetSize(kHealthBarSize)
    healthBar:SetAnchor(GUIItem.Right, GUIItem.Bottom)
    healthBar:SetPosition(Vector(-kHealthBarSize.x, 0, 0))
    healthBar:SetColor(Color(1,1,1,1))
    healthBar:SetTexture(kHealthbarTexture)
    healthBar:SetTexturePixelCoordinates(unpack({32,64,0,0}))
    background:AddChild(healthBar)
    
    local frame = GUIManager:CreateGraphicItem()
    frame:SetSize(kPlayersPanelSize)
    frame:SetAnchor(GUIItem.Left, GUIItem.Top)
    frame:SetTexture(kBackgroundTexture)
    frame:SetTexturePixelCoordinates(unpack(rightFrameCoords))
    background:AddChild(frame)
    
    return { Background = background, Frame = frame, Name = nameItem, Type = typeIcon, Detail = detailItem, KDR = KDRitem, HealthBar = healthBar }

end