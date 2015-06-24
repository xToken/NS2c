// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\NS2cConfig.lua
// - Dragon

Script.Load("lua/ConfigFileUtility.lua")

local configFileName = "ClassicConfig.json"

local defaultConfig = {
                        classic_gamemode = 0,
                        classic_falldamage = true,
                        classic_commrequired = true,
                        classic_maxsentries = 3,
                        classic_maxsiegecannons = 5,
                        classic_maxturretfactories = 1,
                        classic_maxalienstructures = 8,
                        combat_maxlevel = 12,
                        combat_spawnprotection = 3,
                        combat_roundlength = 20,
                        combat_defaultwinner = 2
                      }

local config = LoadConfigFile(configFileName, defaultConfig, true)
local gameMode
                            
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
    if not gameMode then
        //Check for config enforced gamemode first.
        local mode = GetServerConfigSetting("classic_gamemode")
        if mode == 2 then
            gameMode = kGameMode.Combat
        elseif mode == 1 then
            gameMode = kGameMode.Classic
        end
        //Check for gamemode based on map second.
        if not gameMode then
            if Shared.GetMapName():find("co_") or Shared.GetMapName():find("combat") then
                gameMode = kGameMode.Combat
            else
                gameMode = kGameMode.Classic
            end
        end
    end
    return gameMode
end

function UpdateClassicServerSettings()
    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        //Fall Damage
        gameInfo:SetFallDamage(GetServerConfigSetting("classic_falldamage"))
        //Comm Requirement
        gameInfo:SetClassicCommanderRequired(GetServerConfigSetting("classic_commrequired"))
        //Max Sentries per Room
        gameInfo:SetClassicMaxSentriesPerRoom(GetServerConfigSetting("classic_maxsentries"))
        //Max Sieges Per Room
        gameInfo:SetClassicMaxSiegesPerRoom(GetServerConfigSetting("classic_maxsiegecannons"))
        //Max Turret Factories Per Room
        gameInfo:SetClassicMaxFactoriesPerRoom(GetServerConfigSetting("classic_maxturretfactories"))
        //Max nearby Alien Structures of same type
        gameInfo:SetClassicMaxAlienStructures(GetServerConfigSetting("classic_maxalienstructures"))
        //Combat Max Level
        gameInfo:SetCombatMaxLevel(GetServerConfigSetting("combat_maxlevel"))
        //Combat Spawn Protection
        gameInfo:SetCombatSpawnProtectionLength(GetServerConfigSetting("combat_spawnprotection"))
        //Combat Round Length
        gameInfo:SetCombatRoundLength(GetServerConfigSetting("combat_roundlength"))
        //Combat Default Winner
        gameInfo:SetCombatDefaultWinner(GetServerConfigSetting("combat_defaultwinner"))
        //GameMode
        gameInfo:SetGameMode(GetServerGameMode())
    end
end

//Classic Global Commands
local function UpdateGameMode(client, gamemode)

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local newMode = GetServerConfigSetting("classic_gamemode")
        local modeString
        if gamemode and (gamemode == 2 or gamemode == "2" or string.lower(gamemode) == "combat") then
            //Combat
            newMode = 2
        elseif gamemode and (gamemode == 1 or gamemode == "1" or string.lower(gamemode) == "classic") then
            newMode = 1
        elseif not gamemode or gamemode and (gamemode == 0 or gamemode == "0") then
            newMode = 0
        end
        if UpdateServerConfigSetting("classic_gamemode", newMode) then
            gameMode = nil
            local gameRules = GetGamerules()
            gameInfo:SetGameMode(GetServerGameMode())
            gameRules:ResetGame()
        end
        if newMode == 0 then
            modeString = "Map Dependant"
        elseif newMode == 1 then
            modeString = "Classic"
        elseif newMode == 2 then
            modeString = "Combat"
        end
        ServerAdminPrint(client, string.format("NS2c Game mode set to %s", modeString))
    end
    
end

CreateServerAdminCommand("Console_sv_gamemode", UpdateGameMode, "Changes between Automatic based on MapName(0), Classic(1) or Combat(2) gamemodes.")

local function UpdateFallDamageSetting(client, setting)

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local fDamage = gameInfo:GetFallDamageEnabled()
        if setting and (setting == "false" or string.lower(setting) == "false") then
            fDamage = false
        elseif setting and (setting == "true" or string.lower(setting) == "true") then
            fDamage = true
        end
        if UpdateServerConfigSetting("classic_falldamage", fDamage) and gameInfo then
            gameInfo:SetFallDamage(fDamage)
        end
        ServerAdminPrint(client, string.format("NS2c Fall Damage set to %s", fDamage and "Enabled" or "Disabled"))
    end
    
end

CreateServerAdminCommand("Console_sv_falldamage", UpdateFallDamageSetting, "Toggles Fall Damage - (true = enabled).")

//'Classic' Specific Commands
local function UpdateCommanderRequired(client, setting)

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local mComm = gameInfo:GetClassicCommanderRequired()
        if setting and (setting == "false" or string.lower(setting) == "false") then
            mComm = false
        elseif setting and (setting == "true" or string.lower(setting) == "true") then
            mComm = true
        end
        if UpdateServerConfigSetting("classic_commrequired", mComm) then
            gameInfo:SetClassicCommanderRequired(mComm)
        end
        ServerAdminPrint(client, string.format("NS2c Commander Requirement for game start set to %s", mComm and "Required" or "Not Required"))
    end
    
end

CreateServerAdminCommand("Console_sv_classiccommrequired", UpdateCommanderRequired, "Toggles Commander Requirement for game start (true = required).")

local function UpdateMaxSentries(client, setting)

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local mSentries = gameInfo:GetClassicMaxSentriesPerRoom()
        setting = tonumber(setting)
        if setting and setting >= 1 and setting <= kMaxSentriesPerRoom then
            mSentries = math.floor(setting)
        end
        if UpdateServerConfigSetting("classic_maxsentries", mSentries) then
            gameInfo:SetClassicMaxSentriesPerRoom(mSentries)
        end
        ServerAdminPrint(client, string.format("NS2c Max Sentries per room set to %s", mSentries))
    end
    
end

CreateServerAdminCommand("Console_sv_classicmaxsentries", UpdateMaxSentries, "Update maximum amount of sentries per room (Between 1 and " .. kMaxSentriesPerRoom .. ".")

local function UpdateMaxSieges(client, setting)

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local mSieges = gameInfo:GetClassicMaxSiegesPerRoom()
        setting = tonumber(setting)
        if setting and setting >= 1 and setting <= kMaxSiegesPerRoom then
            mSieges = math.floor(setting)
        end
        if UpdateServerConfigSetting("classic_maxsiegecannons", mSieges) then
            gameInfo:SetClassicMaxSiegesPerRoom(mSieges)
        end
        ServerAdminPrint(client, string.format("NS2c Max Sieges per room set to %s", mSieges))
    end
    
end

CreateServerAdminCommand("Console_sv_classicmaxsieges", UpdateMaxSieges, "Update maximum amount of sieges per room (Between 1 and " .. kMaxSiegesPerRoom .. ".")

local function UpdateMaxFactories(client, setting)

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local mFactories = gameInfo:GetClassicMaxFactoriesPerRoom()
        setting = tonumber(setting)
        if setting and setting >= 1 and setting <= kMaxTurretFactoriesPerRoom then
            mFactories = math.floor(setting)
        end
        if UpdateServerConfigSetting("classic_maxturretfactories", mFactories) then
            gameInfo:SetClassicMaxFactoriesPerRoom(mFactories)
        end
        ServerAdminPrint(client, string.format("NS2c Max Factories per room set to %s", mFactories))
    end
    
end

CreateServerAdminCommand("Console_sv_classicmaxfactories", UpdateMaxFactories, "Update maximum amount of turret factories per room (Between 1 and " .. kMaxTurretFactoriesPerRoom .. ".")

local function UpdateMaxAlienStructures(client, setting)

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local mStructures = gameInfo:GetClassicMaxAlienStructures()
        setting = tonumber(setting)
        if setting and setting >= 1 and setting <= kMaxAlienStructuresofType then
            mStructures = math.floor(setting)
        end
        if UpdateServerConfigSetting("classic_maxalienstructures", mStructures) then
            gameInfo:SetClassicMaxAlienStructures(mStructures)
        end
        ServerAdminPrint(client, string.format("NS2c Max nearby Alien Structures of the same type set to %s", mStructures))
    end
    
end

CreateServerAdminCommand("Console_sv_classicmaxalienstructures", UpdateMaxAlienStructures, "Update maximum amount of nearby aliens structures of the same type (Between 3 and " .. kMaxAlienStructuresofType .. ".")

//'Combat' Specific Commands
local function UpdateMaxLevel(client, setting)

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local mLevel = gameInfo:GetCombatMaxLevel()
        setting = tonumber(setting)
        if setting and setting >= 5 and setting <= kCombatMaxAllowedLevel then
            mLevel = math.floor(setting)
        end
        if UpdateServerConfigSetting("combat_maxlevel", mLevel) then
            gameInfo:SetCombatMaxLevel(mLevel)
        end
        ServerAdminPrint(client, string.format("NS2c Combat Max Level set to %s", mLevel))
    end
    
end

CreateServerAdminCommand("Console_sv_combatmaxlevel", UpdateMaxLevel, "Update max level for combat mode (Between 5 and " .. kCombatMaxAllowedLevel .. ".")

local function UpdateSpawnProtect(client, setting)

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local mLength = gameInfo:GetCombatSpawnProtectionLength()
        setting = tonumber(setting)
        if setting and setting >= 0 and setting <= kCombatMaxSpawnProtection then
            mLength = math.floor(setting)
        end
        if UpdateServerConfigSetting("combat_spawnprotection", mLength) then
            gameInfo:SetCombatSpawnProtectionLength(mLength)
        end
        ServerAdminPrint(client, string.format("NS2c Combat Spawn Protection Length set to %s", mLength))
    end
    
end

CreateServerAdminCommand("Console_sv_combatspawnprotection", UpdateSpawnProtect, "Update spawn protection length for combat mode (Between 0 and " .. kCombatMaxSpawnProtection .. ".")

local function UpdateRoundLength(client, setting)

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local rLength = gameInfo:GetCombatRoundLength()
        setting = tonumber(setting)
        if setting and setting >= 5 and setting <= kCombatMaxRoundLength then
            rLength = math.floor(setting)
        end
        if UpdateServerConfigSetting("combat_roundlength", rLength) then
            gameInfo:SetCombatRoundLength(rLength)
        end
        ServerAdminPrint(client, string.format("NS2c Combat Round Length set to %s", rLength))
    end
    
end

CreateServerAdminCommand("Console_sv_combatroundlength", UpdateRoundLength, "Update round length for combat mode (Between 5 and " .. kCombatMaxRoundLength .. ".")

local function UpdateDefaultWinningTeam(client, setting)

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        local mTeam = gameInfo:GetCombatDefaultWinner()
        setting = tonumber(setting)
        if setting and setting == 1 or setting == 2 then
            mTeam = setting
        end
        if UpdateServerConfigSetting("combat_defaultwinner", mTeam) then
            gameInfo:SetCombatDefaultWinner(mTeam)
        end
        ServerAdminPrint(client, string.format("NS2c Combat Default Winning Team set to %s", mTeam == 1 and "Marines" or "Aliens"))
    end
    
end

CreateServerAdminCommand("Console_sv_combatdefaultwinner", UpdateDefaultWinningTeam, "Update default winning team for combat mode (1= Marines, 2= Aliens).")

local function ShowClassicSpecificConsoleCommands(client)

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        
        local gameMode = gameInfo:GetGameMode()
        local modeString
        if gameMode == 0 then
            modeString = "Map Dependant"
        elseif gameMode == 1 then
            modeString = "Classic"
        elseif gameMode == 2 then
            modeString = "Combat"
        end
        ServerAdminPrint(client, string.format("sv_gamemode - Controls NS2c Game mode based on MapName(0), Classic(1) or Combat(2) - %s", modeString))
        ServerAdminPrint(client, string.format("sv_falldamage - Controls Falling Damage - %s", gameInfo:GetFallDamageEnabled() and "Enabled" or "Disabled"))
        ServerAdminPrint(client, string.format("sv_classiccommrequired - Controls Commander Requirement for round start - %s", gameInfo:GetClassicCommanderRequired() and "Required" or "Not Required"))
        ServerAdminPrint(client, string.format("sv_classicmaxsentries - Controls maximum number of Sentries per room - %s", gameInfo:GetClassicMaxSentriesPerRoom()))
        ServerAdminPrint(client, string.format("sv_classicmaxsieges - Controls maximum number of Sieges per room - %s", gameInfo:GetClassicMaxSiegesPerRoom()))
        ServerAdminPrint(client, string.format("sv_classicmaxfactories - Controls maximum number of Turret Factories per room - %s", gameInfo:GetClassicMaxFactoriesPerRoom()))
        ServerAdminPrint(client, string.format("sv_classicmaxalienstructures Controls maximum number of nearby Alien Structures of the same type - %s", gameInfo:GetClassicMaxAlienStructures()))
        ServerAdminPrint(client, string.format("sv_combatmaxlevel - Controls maximum player level during Combat mode - %s", gameInfo:GetCombatMaxLevel()))
        ServerAdminPrint(client, string.format("sv_combatspawnprotection - Controls length of Spawn Protection Length during Combat mode - %s", gameInfo:GetCombatSpawnProtectionLength()))
        ServerAdminPrint(client, string.format("sv_combatroundlength - Controls length of each round during Combat mode - %s", gameInfo:GetCombatRoundLength()))
        ServerAdminPrint(client, string.format("sv_combatdefaultwinner - Controls default winning team if combat round length expires - %s", gameInfo:GetCombatDefaultWinner() == 1 and "Marines" or "Aliens"))
    end
    
end

CreateServerAdminCommand("Console_sv_classichelp", ShowClassicSpecificConsoleCommands, "Shows a list of Classic Console commands and their current settings.")