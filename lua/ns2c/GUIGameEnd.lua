-- ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
--
-- lua\GUIGameEnd.lua
--
-- Created by: Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Tweak to use NS2c endgame music

Script.Load("lua/GUIAnimatedScript.lua")

local kEndStates = enum({ 'AlienPlayerWin', 'MarinePlayerWin', 'AlienPlayerLose', 'MarinePlayerLose', 'AlienPlayerDraw', 'MarinePlayerDraw' })

local kEndIconTextures = { [kEndStates.AlienPlayerWin] = "ui/alien_victory.dds",
                           [kEndStates.MarinePlayerWin] = "ui/marine_victory.dds",
                           [kEndStates.AlienPlayerLose] = "ui/alien_defeat.dds",
                           [kEndStates.MarinePlayerLose] = "ui/marine_defeat.dds",
                           [kEndStates.AlienPlayerDraw] = "ui/alien_draw.dds",
                           [kEndStates.MarinePlayerDraw] = "ui/marine_draw.dds", }

local kEndIconWidth = 1024
local kEndIconHeight = 600
local kEndIconPosition = Vector(-kEndIconWidth / 2, -kEndIconHeight / 2, 0)

local kMessageFontName = { marine = Fonts.kAgencyFB_Huge, alien = Fonts.kStamp_Huge }
local kMessageText = { [kEndStates.AlienPlayerWin] = "ALIEN_VICTORY",
                       [kEndStates.MarinePlayerWin] = "MARINE_VICTORY",
                       [kEndStates.AlienPlayerLose] = "ALIEN_DEFEAT",
                       [kEndStates.MarinePlayerLose] = "MARINE_DEFEAT",
                       [kEndStates.AlienPlayerDraw] = "DRAW_GAME",
                       [kEndStates.MarinePlayerDraw] = "DRAW_GAME", }   
local kMessageWinColor = { marine = kMarineFontColor, alien = kAlienFontColor }
local kMessageLoseColor = { marine = Color(0.2, 0, 0, 1), alien = Color(0.2, 0, 0, 1) }
local kMessageDrawColor = { marine = Color(0.75, 0.75, 0.75, 1), alien = Color(0.75, 0.75, 0.75, 1) }
local kMessageOffset = Vector(0, -255, 0)

class 'GUIGameEnd' (GUIAnimatedScript)

function GUIGameEnd:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.endIcon = self:CreateAnimatedGraphicItem()
    self.endIcon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.endIcon:SetBlendTechnique(GUIItem.Add)
    self.endIcon:SetLayer(kGUILayerPlayerHUD)
    self.endIcon:SetInheritsParentAlpha(true)
    self.endIcon:SetIsScaling(false)
    self.endIcon:SetIsVisible(false)
    
    self.messageText = self:CreateAnimatedTextItem()
    self.messageText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.messageText:SetTextAlignmentX(GUIItem.Align_Center)
    self.messageText:SetTextAlignmentY(GUIItem.Align_Center)
    self.messageText:SetLayer(kGUILayerPlayerHUD)
    self.messageText:SetIsScaling(false)
    self.messageText:SetInheritsParentAlpha(true)
    self.endIcon:AddChild(self.messageText)
    
end

function GUIGameEnd:SetGameEnded(playerWon, playerDraw, playerTeamType )

    self.endIcon:DestroyAnimations()

    self.endIcon:SetIsVisible(true)
    self.endIcon:SetColor(Color(1, 1, 1, 0))
    local invisibleFunc = function() self.endIcon:SetIsVisible(false) end
    local fadeOutFunc = function() self.endIcon:FadeOut(0.2, nil, AnimateLinear, invisibleFunc) end
    local pauseFunc = function() self.endIcon:Pause(6, nil, nil, fadeOutFunc) end
    self.endIcon:FadeIn(1.0, nil, AnimateLinear, pauseFunc)

    local playerIsMarine = playerTeamType == kMarineTeamType

    local endState
    if playerWon then
        endState = playerIsMarine and kEndStates.MarinePlayerWin or kEndStates.AlienPlayerWin
    elseif playerDraw then
        endState = playerIsMarine and kEndStates.MarinePlayerDraw or kEndStates.AlienPlayerDraw
    else
        endState = playerIsMarine and kEndStates.MarinePlayerLose or kEndStates.AlienPlayerLose
    end

    self.endIcon:SetTexture(kEndIconTextures[endState])
    self.endIcon:SetPosition(kEndIconPosition * GUIScale(1))
    self.endIcon:SetSize(Vector(GUIScale(kEndIconWidth), GUIScale(kEndIconHeight), 0))

    self.messageText:SetFontName(kMessageFontName[playerIsMarine and "marine" or "alien"])
    self.messageText:SetScale(GetScaledVector())
    GUIMakeFontScale(self.messageText)
    self.messageText:SetPosition(kMessageOffset * GUIScale(1))

    if playerWon then
        self.messageText:SetColor(kMessageWinColor[playerIsMarine and "marine" or "alien"])
    elseif playerDraw then
        self.messageText:SetColor(kMessageDrawColor[playerIsMarine and "marine" or "alien"])        
    else
        self.messageText:SetColor(kMessageLoseColor[playerIsMarine and "marine" or "alien"])
    end

    local messageString = Locale.ResolveString(kMessageText[endState])
    if PlayerUI_IsASpectator() then
        local winningTeamName
        if endState == kEndStates.MarinePlayerWin then
            winningTeamName = InsightUI_GetTeam1Name()
            InsightUI_AddScoreForMarineWin()
        elseif endState == kEndStates.AlienPlayerWin then
            winningTeamName = InsightUI_GetTeam2Name()
            InsightUI_AddScoreForAlienWin()            
        elseif playerDraw then
            InsightUI_AddScoreForDrawGame()
        end
        if winningTeamName then
            messageString = string.format("%s Wins!", winningTeamName)
        end
    end
    
    self.messageText:SetText(messageString)

end

function GUIGameEnd:GetIsVisible()
    return self.endIcon:GetIsVisible()
end

local function GetTeamSkills()
    local averagePlayerSkills = {
        [kMarineTeamType] = {},
        [kAlienTeamType] = {},
        [3] = {},
    }

    for _, player in ipairs(GetEntitiesWithMixin("Scoring")) do

        local skill = player:GetPlayerSkill() and math.max(player:GetPlayerSkill(), 0)
        -- DebugPrint("%s skill: %s", ToString(player:GetName()), ToString(skill))

        if skill then

            local teamType = HasMixin(player, "Team") and player:GetTeamType() or -1
            if teamType == kMarineTeamType or teamType == kAlienTeamType then
                table.insert(averagePlayerSkills[teamType], skill)
            end

            table.insert(averagePlayerSkills[3], skill)

        end

    end

    averagePlayerSkills[kMarineTeamType].mean = table.mean(averagePlayerSkills[kMarineTeamType])
    averagePlayerSkills[kAlienTeamType].mean = table.mean(averagePlayerSkills[kAlienTeamType])
    averagePlayerSkills[3].mean = table.mean(averagePlayerSkills[3])

    averagePlayerSkills[kMarineTeamType].median = table.median(averagePlayerSkills[kMarineTeamType])
    averagePlayerSkills[kAlienTeamType].median = table.median(averagePlayerSkills[kAlienTeamType])
    averagePlayerSkills[3].median = table.median(averagePlayerSkills[3])

    averagePlayerSkills[kMarineTeamType].standardDeviation = table.standardDeviation(averagePlayerSkills[kMarineTeamType])
    averagePlayerSkills[kAlienTeamType].standardDeviation = table.standardDeviation(averagePlayerSkills[kAlienTeamType])
    averagePlayerSkills[3].standardDeviation = table.standardDeviation(averagePlayerSkills[3])

    return averagePlayerSkills
end

local function OnGameEnd(message)

    local localPlayer = Client.GetLocalPlayer()

    if localPlayer then

        local playerTeamType = localPlayer:GetTeamType()

        if playerTeamType == kMarineTeamType then
            Client.SetAchievement("First_0_3")
        elseif playerTeamType == kAlienTeamType then
            Client.SetAchievement("First_0_4")
        end

        local option = string.format("maps/%s", Shared.GetMapName())
        if not Client.GetOptionBoolean(option, false ) then
            Client.SetOptionBoolean(option, true )

            local numPlayedMaps = Client.GetOptionInteger("maps/numPlayed", 0 ) + 1
            Client.SetOptionInteger("maps/numPlayed", numPlayedMaps )

            if numPlayedMaps >= 3 then
                Client.SetAchievement("First_0_5")
            end
        end

        if playerTeamType == kNeutralTeamType then playerTeamType = message.win end
        if playerTeamType == kNeutralTeamType then playerTeamType = kMarineTeamType end

        local playerWin = ( message.win == playerTeamType )
        local playerDraw = ( message.win == kNeutralTeamType )

        ClientUI.GetScript("GUIGameEnd"):SetGameEnded( playerWin, playerDraw, playerTeamType )
        if playerWin or playerDraw then
            -- Client.PlayMusic("sound/NS2.fev/victory")
            localPlayer:TriggerEffects("victory")
        else
            -- Client.PlayMusic("sound/NS2.fev/loss")
			localPlayer:TriggerEffects("lose")
        end

        Client.TriggerItemDrop() -- If they've earned an item, give it now
        
    end

    local entityList = Shared.GetEntitiesWithClassname("GameInfo")
    if entityList:GetSize() > 0 then
        local gameInfo = entityList:GetEntityAtIndex(0)
        local gameLength = math.max( 0, math.floor(Shared.GetTime()) - gameInfo:GetStartTime() )

        gameInfo.prevTimeLength = gameLength
        gameInfo.prevWinner = message.win
        gameInfo.prevTeamsSkills = GetTeamSkills()
        Client.showFeedback = true

        if GetGameInfoEntity():GetIsDedicated() and gameLength > 300 then
            local rounds = Client.GetUserStat_Int("rounds_played") or 0
            Client.SetUserStat_Int("rounds_played", rounds + 1)

            if rounds >= 5 and not GetOwnsItem(kSummerGorgePatchItemId) then
                Client.AddPromoItem(kSummerGorgePatchItemId)
                InventoryNewItemNotifyPush( kSummerGorgePatchItemId )
            end
        end
    end

    -- Automatically end any performance logging when the round is done.
    Shared.ConsoleCommand("p_endlog")

end
Client.HookNetworkMessage("GameEnd", OnGameEnd)