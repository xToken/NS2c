--[[
// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\PlayerRanking.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
]]

local kPlayerRankingUrl = "http://sabot.herokuapp.com/api/post/matchEnd"
local kPlayerRankingRequestUrl = "http://sabot.herokuapp.com/api/get/playerData/"
--don't track games which are shorter than a minute
local kMinMatchTime = 60

local gRankingDisabled = false

--client side utility functions

function PlayerRankingUI_GetRelativeSkillFraction()

    local relativeSkillFraction = 0
    
    local gameInfo = GetGameInfoEntity()
    local player = Client.GetLocalPlayer()
    
    if gameInfo and player and HasMixin(player, "Scoring") then
    
        local averageSkill = gameInfo:GetAveragePlayerSkill()
        if averageSkill > 0 then
            relativeSkillFraction = Clamp(player:GetPlayerSkill() / averageSkill, 0, 1)
        else
            relativeSkillFraction = 1
        end
    
    end    
    
    return relativeSkillFraction

end

function PlayerRankingUI_GetLevelFraction()

    local levelFraction = 0
    
    local player = Client.GetLocalPlayer()
    if player and HasMixin(player, "Scoring") then
        levelFraction = Clamp(player:GetPlayerLevel() / kMaxPlayerLevel, 0, 1)
    end
    
    return levelFraction

end

class 'PlayerRanking'

local avgNumPlayersSum = 0
local numPlayerCountSamples = 0

function PlayerRanking:StartGame()

    self.gameStartTime = Shared.GetTime()
    self.gameStarted = true
    self.capturedPlayerData = {}
    
    avgNumPlayersSum = 0
    numPlayerCountSamples = 0
end

function PlayerRanking:GetTrackServer()
    return self:GetGamemode() == "ns2" and avgNumPlayersSum / numPlayerCountSamples > 10
end

local kGamemode
function PlayerRanking:GetGamemode()
    if kGamemode then return kGamemode end

    local gameSetup = io.open( "game_setup.xml", "r" )

    if not gameSetup then
        kGamemode = "ns2"

        return "ns2"
    end

    local data = gameSetup:read( "*all" )

    gameSetup:close()

    local dataMatch = data:match( "<name>(.+)</name>" )

    kGamemode = dataMatch or "ns2"

    return kGamemode
end    

function PlayerRanking:OnUpdate()
    
    if gRankingDisabled then
        return
    end    

    PROFILE("PlayerRanking:OnUpdate")

    if self.capturedPlayerData then
    
        for _, player in ipairs(GetEntitiesWithMixin("Scoring")) do
        
            local client = Server.GetOwner(player)
            
            -- only consider players who are connected to the server and ignore any uncontrolled players / ragdolls
            if client and not client:GetIsVirtual() then
            
                local steamId = client:GetUserId()
                
                if not self.capturedPlayerData[steamId] then
        
                    local playerData = 
                    {
                        steamId = steamId,
                        nickname = player:GetName() or "",
                        playTime = player:GetPlayTime(),
                        marineTime = player:GetMarinePlayTime(),
                        alienTime = player:GetAlienPlayTime(),
                        kills = player:GetKills(),
                        deaths = player:GetDeaths(),
                        assists = player:GetAssistKills(),
                        score = player:GetScore(),
                        teamNumber = player:GetTeamNumber(),
                        commanderTime = player:GetCommanderTime(),
                        entranceTime = math.max( 0, ( player:GetEntranceTime() or Shared.GetTime() ) - self.gameStartTime),
                        exitTime = math.max( 0, ( player:GetExitTime() or Shared.GetTime() ) - self.gameStartTime),
                    }
                    
                    self.capturedPlayerData[steamId] = playerData
                    
                else
                
                    local playerData = self.capturedPlayerData[steamId]
                    playerData.steamId = steamId
                    playerData.nickname = player:GetName() or ""
                    playerData.playTime = player:GetPlayTime()
                    playerData.marineTime = player:GetMarinePlayTime()
                    playerData.alienTime = player:GetAlienPlayTime()
                    playerData.kills = player:GetKills()
                    playerData.deaths = player:GetDeaths()
                    playerData.assists = player:GetAssistKills()
                    playerData.score = player:GetScore()
                    local tn = playerData.teamNumber
                    playerData.teamNumber = player:GetTeamNumber() > 0 and player:GetTeamNumber() < 3 and player:GetTeamNumber() or playerData.teamNumber                    
                    if playerData.teamNumber ~= tn then
                        -- avoid the exploit of exiting the game/entering the game/join team to reset the entrance time.
                        -- Only set the entrance time if we switch teams (which is hard to do if you are on the loosing side)
                        playerData.entranceTime = math.max( 0, ( player:GetEntranceTime() or Shared.GetTime() ) - self.gameStartTime)
                        Log("'%s': update entranceTime", playerData.nickName)
                    end
                    playerData.commanderTime = player:GetCommanderTime()


                    playerData.exitTime = math.max( 0, ( player:GetExitTime() or Shared.GetTime() ) - self.gameStartTime)

                end
                
            end
        
        end
    
    end

end

function PlayerRanking:EndGame(winningTeam)

    PROFILE("PlayerRanking:EndGame")
    
    if gRankingDisabled then
        return
    end 

    if self.gameStarted and self:GetTrackServer() then
    
        local _, marineSkill, alienSkill = self:GetAveragePlayerSkill()
        local isGatherGame = Server.GetIsGatherReady()
    
        local gameTime = math.max(0, Shared.GetTime() - self.gameStartTime)
        -- dont send data of games lasting shorter than a minute. Those are most likely over because of players leaving the server / team.
        if gameTime > kMinMatchTime then

            local gameInfo = {

                serverIp = Server.GetIpAddress(),
                port = Server.GetPort(),
                mapName = Shared.GetMapName(),
                gameTime = gameTime,
                tournamentMode = GetTournamentModeEnabled(),
                gameMode = self:GetGamemode(),
                avgPlayers = avgNumPlayersSum / numPlayerCountSamples,
                winner = winningTeam:GetTeamNumber(),
                players = {},

            }
            
            DebugPrint("PlayerRanking: game info ------------------")
            DebugPrint("%s", ToString(gameInfo))

            for _, playerData in pairs(self.capturedPlayerData) do
                self:InsertPlayerData(gameInfo.players, playerData, winningTeam, gameTime, marineSkill, alienSkill, isGatherGame)
            end
			
			//NS2c - Dont want to mess up their stats
            //Shared.SendHTTPRequest(kPlayerRankingUrl, "POST", { data = json.encode(gameInfo) })
        
        end

    end
    
    self.gameStarted = false

end

function PlayerRanking:InsertPlayerData(playerTable, recordedData, winningTeam, gameTime, marineSkill, alienSkill, isGatherGame)

    PROFILE("PlayerRanking:InsertPlayerData")
    local playerData =
    {
        steamId = recordedData.steamId,
        nickname = recordedData.nickname or "",
        playTime = recordedData.playTime,
        marineTime = recordedData.marineTime,
        alienTime = recordedData.alienTime,
        teamNumber = recordedData.teamNumber,
        kills = recordedData.kills,
        deaths = recordedData.deaths,
        assists = recordedData.assists,
        score = recordedData.score,
        isWinner = winningTeam:GetTeamNumber() == recordedData.teamNumber,
        isCommander = (recordedData.commanderTime / gameTime) > 0.75,
        marineTeamSkill = marineSkill,
        alienTeamSkill = alienSkill,
        gatherGame = isGatherGame,
        commanderTime = recordedData.commanderTime,
        entranceTime = recordedData.entranceTime,
        exitTime = recordedData.exitTime,
    }
        
    DebugPrint("PlayerRanking: dumping player data ------------------")
    DebugPrint("%s", ToString(playerData))

    table.insert(playerTable, playerData)

end

function PlayerRanking:GetAveragePlayerSkill()

    PROFILE("PlayerRanking:GetAveragePlayerSkill")

    -- update this only max once per frame
    if not self.timeLastSkillUpdate or self.timeLastSkillUpdate < Shared.GetTime() then
    
        self.averagePlayerSkills = { 
            [kMarineTeamType] = { numPlayers = 0, skillSum = 0 }, 
            [kAlienTeamType] = { numPlayers = 0, skillSum = 0 },
            [3] = { numPlayers = 0, skillSum = 0 },
        }

        for _, player in ipairs(GetEntitiesWithMixin("Scoring")) do

            local client = Server.GetOwner(player)
            local skill = player:GetPlayerSkill()
            -- DebugPrint("%s skill: %s", ToString(player:GetName()), ToString(skill))
            
            if client and skill then
            
                local teamType = HasMixin(player, "Team") and player:GetTeamType() or -1
                if teamType == kMarineTeamType or teamType == kAlienTeamType then
                
                    self.averagePlayerSkills[teamType].numPlayers = self.averagePlayerSkills[teamType].numPlayers + 1
                    self.averagePlayerSkills[teamType].skillSum = self.averagePlayerSkills[teamType].skillSum + player:GetPlayerSkill()
                    
                end
                
                self.averagePlayerSkills[3].numPlayers = self.averagePlayerSkills[3].numPlayers + 1
                self.averagePlayerSkills[3].skillSum = self.averagePlayerSkills[3].skillSum + player:GetPlayerSkill()
                
            end
            
        end
        
        self.averagePlayerSkills[kMarineTeamType].averageSkill = self.averagePlayerSkills[kMarineTeamType].numPlayers == 0 and 0 or self.averagePlayerSkills[kMarineTeamType].skillSum / self.averagePlayerSkills[kMarineTeamType].numPlayers
        self.averagePlayerSkills[kAlienTeamType].averageSkill = self.averagePlayerSkills[kAlienTeamType].numPlayers == 0 and 0 or self.averagePlayerSkills[kAlienTeamType].skillSum / self.averagePlayerSkills[kAlienTeamType].numPlayers
        self.averagePlayerSkills[3].averageSkill = self.averagePlayerSkills[3].numPlayers == 0 and 0 or self.averagePlayerSkills[3].skillSum / self.averagePlayerSkills[3].numPlayers
    
        self.timeLastSkillUpdate = Shared.GetTime()
        
    end

    return self.averagePlayerSkills[3].averageSkill, self.averagePlayerSkills[kMarineTeamType].averageSkill, self.averagePlayerSkills[kAlienTeamType].averageSkill

end

if Server then

    local gPlayerData = {}

    function GetHiveDataBySteamId(steamid)
        return gPlayerData[steamid]
    end

    local function SetPlayerParams(client, obj)
        local player = client and client:GetControllingPlayer()

        if player then
            Badges_SetBadges(client:GetId(), obj.badges)

            player:SetTotalKills(obj.kills)
            player:SetTotalAssists(obj.assists)
            player:SetTotalDeaths(obj.deaths)
            player:SetPlayerSkill(obj.skill)
            player:SetTotalScore(obj.score)
            player:SetTotalPlayTime(obj.playTime)
            player:SetPlayerLevel(obj.level)
        end

    end

    local function PlayerDataResponse(steamId,clientId)
        return function (playerData)
        
            PROFILE("PlayerRanking:PlayerDataResponse")
            
            local obj = json.decode(playerData, 1, nil)
            
            if obj then

                -- its possible that the server does not send all data we want,
                -- need to check for nil here to not cause any script errors later:
                obj.kills = obj.kills or 0
                obj.assists = obj.assists or 0
                obj.deaths = obj.deaths or 0
                obj.skill = obj.skill or 0
                obj.score = obj.score or 0
                obj.playTime = obj.playTime or 0
                obj.level = obj.level or 0

                gPlayerData[steamId] = obj

                local client = Server.GetClientById(clientId)
                if client then
                    SetPlayerParams(client, obj)
                end

            end
            
            DebugPrint("player data of %s: %s", ToString(steamId), ToString(obj))
        
        end
    end

    local function OnConnect(client)
        PROFILE("PlayerRanking:OnConnect")

        if client and not client:GetIsVirtual() then

            local steamId = client:GetUserId()
            local playerData = gPlayerData[steamId]

            if not playerData or playerData.steamId ~= steamId then --no playerdata or invalid ones
                
                DebugPrint("send player data request for %s", ToString(steamId))
                
                local requestUrl = string.format("%s%s", kPlayerRankingRequestUrl, steamId)
                Shared.SendHTTPRequest(requestUrl, "GET", { }, PlayerDataResponse(steamId, client:GetId()))
                
            else --set badges and values
                SetPlayerParams(client, playerData)
            end

        end

    end

    local gConfigChecked
    local function UpdatePlayerStats()
    
        PROFILE("PlayerRanking:UpdatePlayerStats")
        
        if not gConfigChecked and Server.GetConfigSetting then
            gRankingDisabled = Server.GetConfigSetting("hiveranking") == false
            gConfigChecked = true 
        end
        
        if GetServerContainsBots() or Shared.GetCheatsEnabled() then
            gRankingDisabled = true
        end

        if gRankingDisabled then
            return
        end

        local gameRules = GetGamerules()

        if gameRules then
            local team1PlayerNum = gameRules:GetTeam1():GetNumPlayers()
            local team2PlayerNum = gameRules:GetTeam2():GetNumPlayers()

            avgNumPlayersSum = avgNumPlayersSum + team1PlayerNum + team2PlayerNum
            numPlayerCountSamples = numPlayerCountSamples + 1
        end

    end

    Event.Hook("ClientConnect", OnConnect)
    Event.Hook("UpdateServer", UpdatePlayerStats)
end