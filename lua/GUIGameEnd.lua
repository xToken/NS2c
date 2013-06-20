// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//
// lua\GUIGameEnd.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Tweak to use NS2c endgame music

Script.Load("lua/GUIAnimatedScript.lua")

local kEndStates = enum({ 'AlienPlayerWin', 'MarinePlayerWin', 'AlienPlayerLose', 'MarinePlayerLose' })

local kEndIconTextures = { [kEndStates.AlienPlayerWin] = "ui/alien_victory.dds",
                           [kEndStates.MarinePlayerWin] = "ui/marine_victory.dds",
                           [kEndStates.AlienPlayerLose] = "ui/alien_defeat.dds",
                           [kEndStates.MarinePlayerLose] = "ui/marine_defeat.dds" }

local kEndIconWidth = 1024
local kEndIconHeight = 600
local kEndIconPosition = Vector(-kEndIconWidth / 2, -kEndIconHeight / 2, 0)

local kMessageFontName = { marine = "fonts/AgencyFB_huge.fnt", alien = "fonts/Stamp_huge.fnt" }
local kMessageText = { [kEndStates.AlienPlayerWin] = "ALIEN_VICTORY",
                       [kEndStates.MarinePlayerWin] = "MARINE_VICTORY",
                       [kEndStates.AlienPlayerLose] = "ALIEN_DEFEAT",
                       [kEndStates.MarinePlayerLose] = "MARINE_DEFEAT" }
local kMessageWinColor = { marine = kMarineFontColor, alien = kAlienFontColor }
local kMessageLoseColor = { marine = Color(0.2, 0, 0, 1), alien = Color(0.2, 0, 0, 1) }
local kMessageOffset = Vector(0, -255, 0)

class 'GUIGameEnd' (GUIAnimatedScript)

function GUIGameEnd:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.endIcon = self:CreateAnimatedGraphicItem()
    self.endIcon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.endIcon:SetPosition(kEndIconPosition * GUIScale(1))
    self.endIcon:SetSize(Vector(GUIScale(kEndIconWidth), GUIScale(kEndIconHeight), 0))
    self.endIcon:SetBlendTechnique(GUIItem.Add)
    self.endIcon:SetInheritsParentAlpha(true)
    self.endIcon:SetIsVisible(false)
    
    self.messageText = self:CreateAnimatedTextItem()
    self.messageText:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.messageText:SetTextAlignmentX(GUIItem.Align_Center)
    self.messageText:SetTextAlignmentY(GUIItem.Align_Center)
    self.messageText:SetPosition(kMessageOffset * GUIScale(1))
    self.messageText:SetInheritsParentAlpha(true)
    self.endIcon:AddChild(self.messageText)
    
end

function GUIGameEnd:SetGameEnded(playerWon, playerIsMarine)

    assert(type(playerWon) == "boolean")
    assert(type(playerIsMarine) == "boolean")
    
    self.endIcon:DestroyAnimations()
    
    self.endIcon:SetIsVisible(true)
    self.endIcon:SetPosition(kEndIconPosition * GUIScale(1))
    self.endIcon:SetColor(Color(1, 1, 1, 0))
    local invisibleFunc = function() self.endIcon:SetIsVisible(false) end
    local fadeOutFunc = function() self.endIcon:FadeOut(0.2, nil, AnimateLinear, invisibleFunc) end
    local pauseFunc = function() self.endIcon:Pause(6, nil, nil, fadeOutFunc) end
    self.endIcon:FadeIn(1.0, nil, AnimateLinear, pauseFunc)
    
    local endState = kEndStates.AlienPlayerWin
    if playerWon then
    
        if playerIsMarine then
            endState = kEndStates.MarinePlayerWin
        end
        
    else
    
        if playerIsMarine then
            endState = kEndStates.MarinePlayerLose
        else
            endState = kEndStates.AlienPlayerLose
        end
        
    end
    
    self.endIcon:SetTexture(kEndIconTextures[endState])
    
    self.messageText:SetFontName(kMessageFontName[playerIsMarine and "marine" or "alien"])
    
    if playerWon then
        self.messageText:SetColor(kMessageWinColor[playerIsMarine and "marine" or "alien"])
    else
        self.messageText:SetColor(kMessageLoseColor[playerIsMarine and "marine" or "alien"])
    end
    
    local messageString = Locale.ResolveString(kMessageText[endState])
    if PlayerUI_IsASpectator() then
        local winningTeamName = nil
        if endState == kEndStates.MarinePlayerWin then
            winningTeamName = InsightUI_GetTeam1Name()
            Shared.ConsoleCommand("score1 +")
        elseif endState == kEndStates.AlienPlayerWin then
            winningTeamName = InsightUI_GetTeam2Name()
            Shared.ConsoleCommand("score2 +")
        end
        if winningTeamName then
            messageString = string.format("%s Wins!", winningTeamName)
        end
    end
    self.messageText:SetText(messageString)
    
end

local function OnGameEnd(message)

    local localPlayer = Client.GetLocalPlayer()
    if localPlayer then
    
        if localPlayer:GetTeamType() == kNeutralTeamType then
        
            -- Spectators always want the 'Win' screen to appear
            -- Using the win variable to specify which team won instead
            ClientUI.GetScript("GUIGameEnd"):SetGameEnded(true, message.win)
            localPlayer:TriggerEffects("victory")
            //Client.PlayMusic("sound/ns2c.fev/you_win")
        else
            ClientUI.GetScript("GUIGameEnd"):SetGameEnded(message.win, localPlayer:GetTeamType() == kMarineTeamType)
            if message.win then
                localPlayer:TriggerEffects("victory")
            else
                localPlayer:TriggerEffects("lose")
            end
            //Client.PlayMusic("sound/ns2c.fev/you_" .. (message.win and "win" or "lose"))
        end
        
    end
    
    // Automatically end any performance logging when the round is done.
    Shared.ConsoleCommand("p_endlog")
    
end
Client.HookNetworkMessage("GameEnd", OnGameEnd)