// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\GUIMarineSpectatorHUD.lua
// - Dragon

class 'GUIMarineSpectatorHUD' (GUIScript)

local kFontScale = GUIScale(Vector(1, 1, 0))
local kTextFontName = "fonts/AgencyFB_large.fnt"
local kFontColor = Color(1, 1, 1, 1)

local kPadding = GUIScale(32)

local kWhite = Color(1, 1, 1, 1)


local kSpawnInOffset = GUIScale(Vector(0, -125, 0))

function GUIMarineSpectatorHUD:Initialize()

    self.spawnText = GUIManager:CreateTextItem()
    self.spawnText:SetFontName(kTextFontName)
    self.spawnText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.spawnText:SetTextAlignmentX(GUIItem.Align_Center)
    self.spawnText:SetTextAlignmentY(GUIItem.Align_Center)
    self.spawnText:SetColor(kFontColor)
    self.spawnText:SetPosition(kSpawnInOffset)
    
end

function GUIMarineSpectatorHUD:Uninitialize()

    assert(self.spawnText)
    
    GUI.DestroyItem(self.spawnText)
    self.spawnText = nil
    
end

function GUIMarineSpectatorHUD:Update(deltaTime)

    local waitingForTeamBalance = PlayerUI_GetIsWaitingForTeamBalance()

    local isVisible = not waitingForTeamBalance and GetPlayerIsSpawning()
    self.spawnText:SetIsVisible(isVisible)
    
    if isVisible then
    
        local timeToWave = math.max(0, math.floor(PlayerUI_GetWaveSpawnTime()))
        
        if timeToWave == 0 then
            self.spawnText:SetText(Locale.ResolveString("WAITING_TO_SPAWN"))
        else
            self.spawnText:SetText(string.format(Locale.ResolveString("NEXT_SPAWN_IN"), ToString(timeToWave)))
        end
        
    end
    
end