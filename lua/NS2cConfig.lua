
//Dragon

Script.Load("lua/ConfigFileUtility.lua")

local cachedGameMode

local function GetGameModeSetting()

    local setting = Server.GetConfigSetting("classic_gamemode")
    if not setting or not setting.mode then
        return nil
    end
    
    return setting.mode
    
end

local function UpdateGameModeSetting(newmode)

    if GetGameModeSetting() ~= newmode then
        Server.SetConfigSetting("classic_gamemode", { mode = newmode })
        Server.SaveConfigSettings()
        return true
    end
    return false
    
end

function GetServerGameMode()
    if cachedGameMode == nil then
        local mode = GetGameModeSetting()
        if mode == 2 then
            cachedGameMode = kGameMode.Combat
        elseif mode == 1 then
            cachedGameMode = kGameMode.Classic
        end
        if cachedGameMode == nil then
            if Shared.GetMapName():find("co_") or Shared.GetMapName():find("combat") then
                cachedGameMode = kGameMode.Combat
            else
                cachedGameMode = kGameMode.Classic
            end
        end
    end
    return cachedGameMode
end

local function UpdateGameMode(client, gamemode)

    local newmode = nil
    if gamemode ~= nil and (gamemode == 2 or gamemode == "2" or string.lower(gamemode) == "combat") then
        //Combat
        newmode = 2
    elseif gamemode ~= nil and (gamemode == 1 or gamemode == "1" or string.lower(gamemode) == "classic") then
        newmode = 1
    end
    if UpdateGameModeSetting(newmode) then
        cachedGameMode = nil
        GetServerGameMode()
        local gamerules = GetGamerules()
        for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
            player:SetGameMode(cachedGameMode)
        end
        gamerules:ResetGame()
    end
    
end

CreateServerAdminCommand("Console_sv_gamemode", UpdateGameMode, "Changes between Automatic based on MapName(0), Classic(1) or Combat(2) gamemodes.")
//Event.Hook("Console_sv_gamemode", UpdateGameMode)

//Testing Hacks :o
function ClientModelMixin:__initmixin()

    self.limitedModel = true
    self.fullyUpdated = Client or Predict
    
    if Server then
        self.forceModelUpdateUntilTime = 0
        self:ForceUpdateUntil(Shared.GetTime() + 2)
    end

end