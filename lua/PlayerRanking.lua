// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\PlayerRanking.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kPlayerRankingUrl = "http://sabot.herokuapp.com/api/post/matchEnd"
local kPlayerRankingRequestUrl = "http://sabot.herokuapp.com/api/get/playerData/"
// only track a player who was playing a round for mroe than 5 minutes
local kMinPlayTime = 5 * 60
// don't track games which are shorter than a minute
local kMinMatchTime = 60

local gRankingDisabled = false

// client side utility functions

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

function PlayerRanking:StartGame()

    self.gameStartTime = Shared.GetTime()
    self.gameStarted = true
    self.capturedPlayerData = {}

end

function PlayerRanking:GetTrackServer()
    return Server.GetNumActiveMods() == 0 and not GetServerContainsBots()
end

function PlayerRanking:GetGameMode()
    return Server.GetNumActiveMods() == 0 and "ns2" or "mod"
end    

function PlayerRanking:OnUpdate()
    
    if gRankingDisabled then
        return
    end    

    PROFILE("PlayerRanking:OnUpdate")

    if self.capturedPlayerData then
    
        for _, player in ipairs(GetEntitiesWithMixin("Scoring")) do
        
            local client = Server.GetOwner(player)
            
            // only consider players who are connected to the server and ignore any uncontrolled players / ragdolls
            if client and not client:GetIsVirtual() then
            
                local steamId = client:GetUserId()
                
                if not self.capturedPlayerData[steamId..""] then
        
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
                    }
                    
                    self.capturedPlayerData[steamId..""] = playerData
                    
                else
                
                    local playerData = self.capturedPlayerData[steamId..""]
                    playerData.steamId = steamId
                    playerData.nickname = player:GetName() or ""
                    playerData.playTime = player:GetPlayTime()
                    playerData.marineTime = player:GetMarinePlayTime()
                    playerData.alienTime = player:GetAlienPlayTime()
                    playerData.kills = player:GetKills()
                    playerData.deaths = player:GetDeaths()
                    playerData.assists = player:GetAssistKills()
                    playerData.score = player:GetScore()
                    playerData.teamNumber = player:GetTeamNumber()
                    playerData.commanderTime = player:GetCommanderTime()

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
    
        local gameTime = math.max(0, Shared.GetTime() - self.gameStartTime)
        // dont send data of games lasting shorter than a minute. Those are most likely over because of players leaving the server / team.
        if gameTime > kMinMatchTime then

            local gameInfo = {

                serverIp = IPAddressToString(Server.GetIpAddress()),
                port = Server.GetPort(),
                mapName = Shared.GetMapName(),
                gameTime = gameTime,
                tournamentMode = GetTournamentModeEnabled(),
                gameMode = self:GetGameMode(),
                players = {},

            }
            
            Print("PlayerRanking: game info ------------------")
            Print("%s", ToString(gameInfo))

            for steamIdString, playerData in pairs(self.capturedPlayerData) do   
                self:InsertPlayerData(gameInfo.players, playerData, winningTeam, gameTime)
            end
			
			//NS2c - Dont want to mess up their stats
            //Shared.SendHTTPRequest(kPlayerRankingUrl, "POST", { data = json.encode(gameInfo) })
        
        end

    end
    
    self.gameStarted = false

end

local function GetPlayerIsValidForRanking(recordedData, gameTime)

    local playTime = recordedData.playTime or 0
    local playedFraction = playTime / gameTime
    
    //Print("player valid for ranking %s", ToString(playedFraction > 0.9 or playTime > kMinPlayTime))

    return (playedFraction > 0.9 or playTime > kMinPlayTime)

end

function PlayerRanking:InsertPlayerData(playerTable, recordedData, winningTeam, gameTime)

    PROFILE("PlayerRanking:InsertPlayerData")

    // only consider players who are connected to the server and ignore any uncontrolled players / ragdolls
    if GetPlayerIsValidForRanking(recordedData, gameTime) then

        local playerData = 
        {
            steamId = recordedData.steamId,
            nickname = recordedData.nickname or "",
            playTime = recordedData.playTime,
            marineTime = recordedData.marineTime,
            alienTime = recordedData.alienTime,
            kills = recordedData.kills,
            deaths = recordedData.deaths,
            assists = recordedData.assists,
            score = recordedData.score,
            isWinner = winningTeam:GetTeamNumber() == recordedData.teamNumber,
            isCommander = (recordedData.commanderTime / gameTime) > 0.75,
        }
        
        Print("PlayerRanking: dumping player data ------------------")
        Print("%s", ToString(playerData))
        
        table.insert(playerTable, playerData)
    
    end

end

function PlayerRanking:GetAveragePlayerSkill()

    PROFILE("PlayerRanking:GetAveragePlayerSkill")

    // update this only max once per frame
    if not self.timeLastSkillUpdate or self.timeLastSkillUpdate < Shared.GetTime() then
    
        self.averagePlayerSKills = { 
            [kMarineTeamType] = { numPlayers = 0, skillSum = 0 }, 
            [kAlienTeamType] = { numPlayers = 0, skillSum = 0 },
            [3] = { numPlayers = 0, skillSum = 0 },
        }
    
        local numPlayers = 0
        local skillSum = 0

        for _, player in ipairs(GetEntitiesWithMixin("Scoring")) do

            local client = Server.GetOwner(player)
            local skill = player:GetPlayerSkill()
            
            //DebugPrint("%s skill: %s", ToString(player:GetName()), ToString(skill))
            
            if client and skill then // and not client:GetIsVirtual()
            
                local teamType = HasMixin(player, "Team") and player:GetTeamType() or -1
                if teamType == kMarineTeamType or teamType == kAlienTeamType then
                
                    self.averagePlayerSKills[teamType].numPlayers = self.averagePlayerSKills[teamType].numPlayers + 1
                    self.averagePlayerSKills[teamType].skillSum = self.averagePlayerSKills[teamType].skillSum + player:GetPlayerSkill()
                    
                end
                
                self.averagePlayerSKills[3].numPlayers = self.averagePlayerSKills[3].numPlayers + 1
                self.averagePlayerSKills[3].skillSum = self.averagePlayerSKills[3].skillSum + player:GetPlayerSkill()
                
            end
            
        end
        
        self.averagePlayerSKills[kMarineTeamType].averageSkill = self.averagePlayerSKills[kMarineTeamType].numPlayers == 0 and 0 or self.averagePlayerSKills[kMarineTeamType].skillSum / self.averagePlayerSKills[kMarineTeamType].numPlayers
        self.averagePlayerSKills[kAlienTeamType].averageSkill = self.averagePlayerSKills[kAlienTeamType].numPlayers == 0 and 0 or self.averagePlayerSKills[kAlienTeamType].skillSum / self.averagePlayerSKills[kAlienTeamType].numPlayers
        self.averagePlayerSKills[3].averageSkill = self.averagePlayerSKills[3].numPlayers == 0 and 0 or self.averagePlayerSKills[3].skillSum / self.averagePlayerSKills[3].numPlayers
    
        self.timeLastSkillUpdate = Shared.GetTime()
        
    end

    return self.averagePlayerSKills[3].averageSkill, self.averagePlayerSKills[kMarineTeamType].averageSkill, self.averagePlayerSKills[kAlienTeamType].averageSkill

end

if Server then

    local gPlayerData = {}
    local gSendRequestNow = false
    local gGameStarted = false
    
    local function PlayerDataResponse(steamId)
        return function (playerData)
        
            PROFILE("PlayerRanking:PlayerDataResponse")
            
            local obj, pos, err = json.decode(playerData, 1, nil)
            
            if obj then
            
                gPlayerData[steamId..""] = obj
            
                // its possible that the server does not send all data we want, need to check for nil here to not cause any script errors later:            
                obj.kills = obj.kills or 0
                obj.assists = obj.assists or 0
                obj.deaths = obj.deaths or 0
                obj.skill = obj.skill or 0
                obj.score = obj.score or 0
                obj.playTime = obj.playTime or 0
                obj.level = obj.level or 0

            end
            
            //Print("player data of %s: %s", ToString(steamId), ToString(obj))
        
        end
    end
    
    local function GetGameEnded()
    
        local gameRules = GetGamerules()
        local gameStarted = (gameRules ~= nil) and gameRules:GetGameStarted()
        if gGameStarted and not gameStarted then
            gGameEndTime = Shared.GetTime()
        end

        gGameStarted = gameStarted
        
        if gGameEndTime and gGameEndTime + 5 < Shared.GetTime() then
        
            gGameEndTime = nil
            return true
            
        end    
        
        return false
    
    end

    local function UpdatePlayerStats()
    
        PROFILE("PlayerRanking:UpdatePlayerStats")
            
        if gRankingDisabled then
            return
        end 

        for _, player in ipairs(GetEntitiesWithMixin("Scoring")) do  
        
            local client = Server.GetOwner(player)
            if client and not client:GetIsVirtual() then
            
                local steamId = client:GetUserId()
                local playerData = gPlayerData[steamId..""]
            
                if gSendRequestNow or not playerData then

                    if not playerData then
                    
                        playerData = {}
                        
                        playerData.kills = 0
                        playerData.assists = 0
                        playerData.deaths = 0
                        playerData.skill = 0
                        playerData.score = 0
                        playerData.playTime = 0
                        playerData.level = 0
                        
                        gPlayerData[steamId..""] = playerData
                    
                    end
            
                    //DebugPrint("send player data request for %s", ToString(steamId))
                    local requestUrl = kPlayerRankingRequestUrl .. steamId
                    Shared.SendHTTPRequest(requestUrl, "GET", { }, PlayerDataResponse(steamId))
                
                end

                player:SetTotalKills(playerData.kills)
                player:SetTotalAssists(playerData.assists)
                player:SetTotalDeaths(playerData.deaths)
                player:SetPlayerSkill(playerData.skill)
                player:SetTotalScore(playerData.score)
                player:SetTotalPlayTime(playerData.playTime)
                player:SetPlayerLevel(playerData.level)
                player:SetReinforcedTier(playerData.reinforcedTier)
            
            end
        
        end
        
        gSendRequestNow = false
        
        if GetGameEnded() then
            gSendRequestNow = true
        end

    end

    Event.Hook("UpdateServer", UpdatePlayerStats)
    
    
    local function OnCommandDisableRanking()
        if Shared.GetCheatsEnabled() then
            gRankingDisabled = not gRankingDisabled
            Print("player ranking %s", ToString(not gRankingDisabled))
        end
    end
    
    Event.Hook("Console_disableranking", OnCommandDisableRanking)

end

