// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\ScoringMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

/**
 * ScoringMixin keeps track of a score. It provides function to allow changing the score.
 */
ScoringMixin = CreateMixin(ScoringMixin)
ScoringMixin.type = "Scoring"

ScoringMixin.expectedCallbacks =
{
    SetScoreboardChanged = "Called to notify the entity that the score has changed and should be updated on the client's scoreboard."
}

ScoringMixin.networkVars =
{
    playerLevel = "private integer",
    playerSkill = "private integer",
}

function ScoringMixin:__initmixin()

    self.score = 0
    // Some types of points are added continuously. These are tracked here.
    self.continuousScores = { }
    
    self.serverJoinTime = Shared.GetTime()
    
end

function ScoringMixin:GetScore()
    return self.score
end

function ScoringMixin:AddScore(points, res)

    // Should only be called on the Server.
    if Server then
    
        // Tell client to display cool effect.
        if points ~= nil and points ~= 0 then
        
            local displayRes = ConditionalValue(type(res) == "number", res, 0)
            Server.SendNetworkMessage(self, "PointsUpdate", { points = points, res = res }, true)
            self.score = Clamp(self.score + points, 0, self:GetMixinConstants().kMaxScore or 100)
            self:SetScoreboardChanged(true)
            
            if not self.scoreGainedCurrentLife then
                self.scoreGainedCurrentLife = 0
            end

            self.scoreGainedCurrentLife = self.scoreGainedCurrentLife + points    

        end
    
    end
    
end

function ScoringMixin:GetScoreGainedCurrentLife()
    return self.scoreGainedCurrentLife
end

function ScoringMixin:GetPlayerLevel()
    return self.playerLevel
end
  
function ScoringMixin:GetPlayerSkill()
    return self.playerSkill
end

if Server then

    function ScoringMixin:CopyPlayerDataFrom(player)
    
        self.scoreGainedCurrentLife = player.scoreGainedCurrentLife    
        self.score = player.score or 0
        self.kills = player.kills or 0
        self.assistkills = player.assistkills or 0
        self.deaths = player.deaths or 0
        self.playTime = player.playTime or 0
        self.commanderTime = player.commanderTime or 0
        self.marineTime = player.marineTime or 0
        self.alienTime = player.alienTime or 0
        
        self.totalKills = player.totalKills
        self.totalAssists = player.totalAssists
        self.totalDeaths = player.totalDeaths
        self.playerSkill = player.playerSkill
        self.totalScore = player.totalScore
        self.totalPlayTime = player.totalPlayTime
        self.playerLevel = player.playerLevel
        
    end

    function ScoringMixin:OnKill()    
        self.scoreGainedCurrentLife = 0
    end
    
    function ScoringMixin:GetPlayTime()
        return self.playTime
    end
    
    function ScoringMixin:GetMarinePlayTime()
        return self.marineTime
    end
    
    function ScoringMixin:GetAlienPlayTime()
        return self.alienTime
    end
    
    function ScoringMixin:GetCommanderTime()
        return self.commanderTime
    end
    
    function SharedUpdate(self, deltaTime)
    
        if not self.commanderTime then
            self.commanderTime = 0
        end
        
        if not self.playTime then
            self.playTime = 0
        end
        
        if not self.marineTime then
            self.marineTime = 0
        end
        
        if not self.alienTime then
            self.alienTime = 0
        end    
        
        if self:GetIsPlaying() then
        
            if self:isa("Commander") then
                self.commanderTime = self.commanderTime + deltaTime
            end
            
            self.playTime = self.playTime + deltaTime
            
            if self:GetTeamType() == kMarineTeamType then
                self.marineTime = self.marineTime + deltaTime
            end
            
            if self:GetTeamType() == kAlienTeamType then
                self.alienTime = self.alienTime + deltaTime
            end
        
        end
    
    end
    
    function ScoringMixin:OnProcessMove(input)
        SharedUpdate(self, input.time)
    end
    
    function ScoringMixin:OnUpdate(deltaTime)
        SharedUpdate(self, deltaTime)
    end

end

function ScoringMixin:AddKill()

    if not self.kills then
        self.kills = 0
    end    

    self.kills = Clamp(self.kills + 1, 0, kMaxKills)
    self:SetScoreboardChanged(true)
    
end

function ScoringMixin:AddAssistKill()

    if not self.assistkills then
        self.assistkills = 0
    end    

    self.assistkills = Clamp(self.assistkills + 1, 0, kMaxKills)
    self:SetScoreboardChanged(true)
    
end

function ScoringMixin:GetKills()
    return self.kills
end

function ScoringMixin:GetAssistKills()
    return self.assistkills
end

function ScoringMixin:GetDeaths()
    return self.deaths
end

function ScoringMixin:AddDeaths()

    if not self.deaths then
        self.deaths = 0
    end

    self.deaths = Clamp(self.deaths + 1, 0, kMaxDeaths)
    self:SetScoreboardChanged(true)
    
end

function ScoringMixin:ResetScores()

    self.score = 0
    self.kills = 0
    self.assistkills = 0
    self.deaths = 0    
    self:SetScoreboardChanged(true)
    
    self.commanderTime = 0
    self.playTime = 0
    self.marineTime = 0
    self.alienTime = 0

end

// Only award the pointsGivenOnScore once the amountNeededToScore are added into the score
// determined by the passed in name.
// An example, to give points based on health healed:
// AddContinuousScore("Heal", amountHealed, 100, 1)
function ScoringMixin:AddContinuousScore(name, addAmount, amountNeededToScore, pointsGivenOnScore)

    if Server then
    
        self.continuousScores[name] = self.continuousScores[name] or { amount = 0 }
        self.continuousScores[name].amount = self.continuousScores[name].amount + addAmount
        while self.continuousScores[name].amount >= amountNeededToScore do
        
            self:AddScore(pointsGivenOnScore, 0)
            self.continuousScores[name].amount = self.continuousScores[name].amount - amountNeededToScore
            
        end
        
    end
    
end

if Server then

    function ScoringMixin:SetTotalKills(totalKills)
        self.totalKills = math.round(totalKills)
    end
    
    function ScoringMixin:SetTotalAssists(totalAssists)
        self.totalAssists = math.round(totalAssists)
    end
    
    function ScoringMixin:SetTotalDeaths(totalDeaths)
        self.totalDeaths = math.round(totalDeaths)
    end
    
    function ScoringMixin:SetPlayerSkill(playerSkill)
        self.playerSkill = math.round(playerSkill)
    end
    
    function ScoringMixin:SetTotalScore(totalScore)
        self.totalScore = math.round(totalScore)
    end
    
    function ScoringMixin:SetTotalPlayTime(totalPlayTime)
        self.totalPlayTime = math.round(totalPlayTime)
    end
    
    function ScoringMixin:SetPlayerLevel(playerLevel)
        self.playerLevel = math.round(playerLevel)
    end 

end

