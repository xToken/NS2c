// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIAlienSpectatorHUD.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Displays how much time is left until the alien spawns.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIAlienSpectatorHUD' (GUIScript)

local kFontScale = GUIScale(Vector(1,1,0))
local kTextFontName = "fonts/AgencyFB_large.fnt"
local kFontColor = Color(1, 1, 1, 1)

local kEggSize = GUIScale(Vector(192, 96, 0) * .5)

local kPadding = GUIScale(32)
local kEggTopOffset = GUIScale(128)

local kNoEggsColor = Color(1, 0, 0, 1)
local kWhite = Color(1,1,1,1)

local kEggTexture = "ui/Egg.dds"

local kSpawnInOffset = GUIScale(Vector(0, -125, 0))

function GUIAlienSpectatorHUD:Initialize()

    self.spawnText = GUIManager:CreateTextItem()
    self.spawnText:SetFontName(kTextFontName)
    self.spawnText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.spawnText:SetTextAlignmentX(GUIItem.Align_Center)
    self.spawnText:SetTextAlignmentY(GUIItem.Align_Center)
    self.spawnText:SetColor(kFontColor)
    self.spawnText:SetPosition(kSpawnInOffset)
    
    self.eggIcon = GUIManager:CreateGraphicItem()
    self.eggIcon:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.eggIcon:SetPosition(Vector(-kEggSize.x * .75 - kPadding * .5, kEggTopOffset, 0))
    self.eggIcon:SetTexture(kEggTexture)
    self.eggIcon:SetSize(kEggSize)
    
    self.eggCount = GUIManager:CreateTextItem()
    self.eggCount:SetFontName(kTextFontName)
    self.eggCount:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.eggCount:SetPosition(Vector(kPadding * .5, 0, 0))
    self.eggCount:SetTextAlignmentX(GUIItem.Align_Min)
    self.eggCount:SetTextAlignmentY(GUIItem.Align_Center)
    self.eggCount:SetColor(kFontColor)
    self.eggCount:SetScale(kFontScale)
    self.eggCount:SetFontName(kTextFontName)
    
    self.eggIcon:AddChild(self.eggCount)
    
    self.autoSpawnText = GUIManager:CreateTextItem()
    self.autoSpawnText:SetFontName(kTextFontName)
    self.autoSpawnText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.autoSpawnText:SetPosition(Vector(0, 30, 0))
    self.autoSpawnText:SetTextAlignmentX(GUIItem.Align_Center)
    self.autoSpawnText:SetTextAlignmentY(GUIItem.Align_Center)
    self.autoSpawnText:SetColor(kFontColor)

end

function GUIAlienSpectatorHUD:Uninitialize()

    assert(self.spawnText)
    assert(self.autoSpawnText)
    
    GUI.DestroyItem(self.autoSpawnText)
    self.autoSpawnText = nil
    
    GUI.DestroyItem(self.spawnText)
    self.spawnText = nil
 
    GUI.DestroyItem(self.eggIcon)
    self.eggIcon = nil    
    eggCount = nil
    
end

function GUIAlienSpectatorHUD:Update(deltaTime)

    local waitingForTeamBalance = PlayerUI_GetIsWaitingForTeamBalance()
    self.spawnText:SetIsVisible(not waitingForTeamBalance)
    self.autoSpawnText:SetIsVisible(not waitingForTeamBalance)
    if AlienUI_GetInEgg() then
    
        //self.spawnText:SetText(string.format(Locale.ResolveString("CHANGE_EGG_HELP"), primaryAttackKey, secondaryAttackKey))
        self.autoSpawnText:SetText(string.format(Locale.ResolveString("Spawning in %s seconds..."), math.max(0, math.ceil(AlienUI_GetAutoSpawnTime()))))
        
    else
    
        local timeToWave = math.max(0, math.floor(AlienUI_GetWaveSpawnTime()))
        
        if timeToWave == 0 then
            self.spawnText:SetText(Locale.ResolveString("WAITING_TO_SPAWN"))
        else
            self.spawnText:SetText(string.format(Locale.ResolveString("NEXT_SPAWN_IN"), ToString(timeToWave)))
        end
        
    end
    
    local eggCount = AlienUI_GetEggCount()
    
    self.eggCount:SetText(string.format("x %s", ToString(eggCount)))
    
    if eggCount == 0 then
        self.eggCount:SetColor(kNoEggsColor)
        self.eggIcon:SetColor(kNoEggsColor)
    else
        self.eggCount:SetColor(kWhite)
        self.eggIcon:SetColor(kWhite)
    end
    
end