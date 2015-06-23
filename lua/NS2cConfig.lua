// Natural Selection 2 'Classic' Mod
// lua\NS2cConfig.lua
// - Dragon

Script.Load("lua/ConfigFileUtility.lua")

local configFileName = "ClassicConfig.json"

local defaultConfig = {
                        classic_gamemode = 0,
                        classic_falldamage = true,
                        combat_maxlevel = 12,
                        combat_spawnprotection = 3,
                        combat_roundlength = 20,
                        combat_defaultwinner = 2
                      }

local config = LoadConfigFile(configFileName, defaultConfig, true)

//"classic_gamemode"
//"classic_falldamage"
//"combat_maxlevel"
//"combat_spawnprotection"
                            
local function GetServerConfigSetting(setting)
    local value = config[setting]
    if value then
        return value
    end
    return defaultConfig[setting]
end

local function UpdateServerConfigSetting(setting, value)
    local curvalue = config[setting]
    if curvalue ~= value then
        config[setting] = value
        SaveConfigFile(configFileName, config)
        return true
    end
    return false
end

function GetServerGameMode()
    if kNS2cServerSettings.GameMode == 0 then
        //Check for config enforced gamemode first.
        local mode = GetServerConfigSetting("classic_gamemode")
        if mode == 2 then
            kNS2cServerSettings.GameMode = kGameMode.Combat
        elseif mode == 1 then
            kNS2cServerSettings.GameMode = kGameMode.Classic
        end
        //Check for gamemode based on map second.
        if kNS2cServerSettings.GameMode == 0 then
            if Shared.GetMapName():find("co_") or Shared.GetMapName():find("combat") then
                kNS2cServerSettings.GameMode = kGameMode.Combat
            else
                kNS2cServerSettings.GameMode = kGameMode.Classic
            end
        end
    end
    return kNS2cServerSettings.GameMode
end

local function UpdateServerSettings()
    //Fall Damage
    kNS2cServerSettings.FallDamage = GetServerConfigSetting("classic_falldamage")
    //Combat Max Level
    kNS2cServerSettings.CombatMaxLevel = GetServerConfigSetting("combat_maxlevel")
    //Combat Spawn Protection
    kNS2cServerSettings.CombatSpawnProtection = GetServerConfigSetting("combat_spawnprotection")
    //Combat Round Length
    kNS2cServerSettings.CombatRoundLength = GetServerConfigSetting("combat_roundlength")
    //Combat Default Winner
    kNS2cServerSettings.CombatDefaultWinner = GetServerConfigSetting("combat_defaultwinner")
    //GameMode
    GetServerGameMode()
end

UpdateServerSettings()

local function UpdateGameMode(client, gamemode)

    local newmode = defaultConfig.classic_gamemode
    if gamemode and (gamemode == 2 or gamemode == "2" or string.lower(gamemode) == "combat") then
        //Combat
        newmode = 2
    elseif gamemode and (gamemode == 1 or gamemode == "1" or string.lower(gamemode) == "classic") then
        newmode = 1
    elseif gamemode and (gamemode == 0 or gamemode == "0") then
        newmode = 0
    end
    if UpdateServerConfigSetting("classic_gamemode", newmode) then
        kNS2cServerSettings.GameMode = 0
        GetServerGameMode()
        local gamerules = GetGamerules()
        for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
            player:SetGameMode(kNS2cServerSettings.GameMode)
        end
        gamerules:ResetGame()
    end
    ServerAdminPrint(client, string.format("NS2c Game mode set to %s", kNS2cServerSettings.GameMode == 1 and "Classic" or "Combat"))
    
end

CreateServerAdminCommand("Console_sv_gamemode", UpdateGameMode, "Changes between Automatic based on MapName(0), Classic(1) or Combat(2) gamemodes.")

local function UpdateFallDamageSetting(client, setting)

    local fDamage = defaultConfig.classic_falldamage
    if setting and (setting == "false" or string.lower(setting) == "false") then
        fDamage = false
    elseif setting and (setting == "true" or string.lower(setting) == "true") then
        fDamage = true
    end
    if UpdateServerConfigSetting("classic_falldamage", fDamage) then
        kNS2cServerSettings.FallDamage = fDamage
    end
    ServerAdminPrint(client, string.format("NS2c Fall Damage set to %s", kNS2cServerSettings.FallDamage and "Enabled" or "Disabled"))
    
end

CreateServerAdminCommand("Console_sv_falldamage", UpdateFallDamageSetting, "Toggles Fall Damage - (true = enabled).")

local function UpdateMaxLevel(client, setting)

    local mLevel = defaultConfig.combat_maxlevel
    setting = tonumber(setting)
    if setting and setting >= 5 and setting <= kCombatMaxAllowedLevel then
        mLevel = math.floor(setting)
    end
    if UpdateServerConfigSetting("combat_maxlevel", mLevel) then
        kNS2cServerSettings.CombatMaxLevel = mLevel
        for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
            player:SetMaxPlayerLevel(kNS2cServerSettings.CombatMaxLevel)
        end
    end
    ServerAdminPrint(client, string.format("NS2c Combat Max Level set to %s", kNS2cServerSettings.CombatMaxLevel))
    
end

CreateServerAdminCommand("Console_sv_combatmaxlevel", UpdateMaxLevel, "Update max level for combat mode (Between 5 and " .. kCombatMaxAllowedLevel .. ".")

local function UpdateSpawnProtect(client, setting)

    local mLength = defaultConfig.combat_spawnprotection
    setting = tonumber(setting)
    if setting and setting >= 0 and setting <= kCombatMaxSpawnProtection then
        mLength = math.floor(setting)
    end
    if UpdateServerConfigSetting("combat_spawnprotection", mLength) then
        kNS2cServerSettings.CombatSpawnProtection = mLength
    end
    ServerAdminPrint(client, string.format("NS2c Combat Spawn Protection Length set to %s", kNS2cServerSettings.CombatSpawnProtection))
    
end

CreateServerAdminCommand("Console_sv_combatspawnprotection", UpdateSpawnProtect, "Update spawn protection length for combat mode (Between 0 and " .. kCombatMaxSpawnProtection .. ".")

local function UpdateRoundLength(client, setting)

    local rLength = defaultConfig.combat_roundlength
    setting = tonumber(setting)
    if setting and setting >= 5 and setting <= kCombatMaxRoundLength then
        rLength = math.floor(setting)
    end
    if UpdateServerConfigSetting("combat_roundlength", rLength) then
        kNS2cServerSettings.CombatRoundLength = rLength
    end
    ServerAdminPrint(client, string.format("NS2c Combat Round Length set to %s", kNS2cServerSettings.CombatRoundLength))
    
end

CreateServerAdminCommand("Console_sv_combatroundlength", UpdateRoundLength, "Update round length for combat mode (Between 5 and " .. kCombatMaxRoundLength .. ".")

local function UpdateDefaultWinningTeam(client, setting)

    local mTeam = defaultConfig.combat_defaultwinner
    setting = tonumber(setting)
    if setting and setting == 1 or setting == 2 then
        mTeam = setting
    end
    if UpdateServerConfigSetting("combat_defaultwinner", mTeam) then
        kNS2cServerSettings.CombatDefaultWinner = mTeam
    end
    ServerAdminPrint(client, string.format("NS2c Combat Default Winning Team set to %s", kNS2cServerSettings.CombatDefaultWinner))
    
end

CreateServerAdminCommand("Console_sv_combatdefaultwinner", UpdateDefaultWinningTeam, "Update default winning team for combat mode (1= Marines, 2= Aliens).")