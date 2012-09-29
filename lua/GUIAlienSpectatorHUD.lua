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

local kTextFontName = "fonts/AgencyFB_large.fnt"
local kFontColor = Color(1, 1, 1, 1)
local kFontSize = 16

function GUIAlienSpectatorHUD:Initialize()

    self.spawnText = GUIManager:CreateTextItem()
    self.spawnText:SetFontName(kTextFontName)
    self.spawnText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.spawnText:SetPosition(Vector(0, 0, 0))
    self.spawnText:SetTextAlignmentX(GUIItem.Align_Center)
    self.spawnText:SetTextAlignmentY(GUIItem.Align_Center)
    self.spawnText:SetColor(kFontColor)
    
    self.autoSpawnText = GUIManager:CreateTextItem()
    self.autoSpawnText:SetFontName(kTextFontName)
    self.autoSpawnText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.autoSpawnText:SetPosition(Vector(0, kFontSize * 2, 0))
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
    
end

function GUIAlienSpectatorHUD:Update(deltaTime)

    local waitingForTeamBalance = PlayerUI_GetIsWaitingForTeamBalance()
    self.spawnText:SetIsVisible(not waitingForTeamBalance)
    self.autoSpawnText:SetIsVisible(not waitingForTeamBalance)
    if AlienUI_GetInEgg() then
    
        local primaryAttackKey = GetPrettyInputName("PrimaryAttack")
        local secondaryAttackKey = GetPrettyInputName("SecondaryAttack")
        self.spawnText:SetText(string.format(Locale.ResolveString("CHANGE_EGG_HELP"), primaryAttackKey, secondaryAttackKey))
        self.autoSpawnText:SetText(string.format(Locale.ResolveString("AUTO_SPAWNING_IN"), math.max(0, math.ceil(AlienUI_GetAutoSpawnTime()))))
        
    else
    
        local timeToWave = math.max(0, math.floor(AlienUI_GetWaveSpawnTime()))
        
        if timeToWave == 0 then
            self.spawnText:SetText(Locale.ResolveString("WAITING_TO_SPAWN"))
        else
            self.spawnText:SetText(string.format(Locale.ResolveString("NEXT_SPAWN_IN"), ToString(timeToWave)))
        end
        
    end
    
end