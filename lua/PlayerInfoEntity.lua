// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\PlayerInfoEntity.lua    
//    
//    Created by:   Andreas Urwalek(andi@unknownworlds.com)    
//
//    Stores information of connected players.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================  

local clientIndexToSteamId = {}
local kPlayerInfoUpdateRate = 0.5

function GetSteamIdForClientIndex(clientIndex)
    return clientIndexToSteamId[clientIndex]
end

class 'PlayerInfoEntity' (Entity)

PlayerInfoEntity.kMapName = "playerinfo"

local networkVars =
{
    // those are not necessary for this entity
    m_angles = "angles (by 10 [], by 10 [], by 10 [])",
    m_origin = "position (by 2000 [], by 2000 [], by 2000 [])",

    clientId = "integer (-1 to 4000)",
    steamId = "integer",
    playerId = "entityid",
    playerName = string.format("string (%d)", kMaxNameLength),
    teamNumber = string.format("integer (-1 to %d)", kRandomTeamType),
    score = string.format("integer (0 to %d)", kMaxScore),
    kills = string.format("integer (0 to %d)", kMaxKills),
    assists = string.format("integer (0 to %d)", kMaxKills),
    deaths = string.format("integer (0 to %d)", kMaxDeaths),
    resources = string.format("integer (0 to %d)", kMaxPersonalResources),
    isCommander = "boolean",
    isRookie = "boolean",
    status = "enum kPlayerStatus",
    isSpectator = "boolean",
    playerSkill = string.format("integer (0 to %d", kMaxPlayerSkill)
}

function PlayerInfoEntity:OnCreate()

    Entity.OnCreate(self)
    
    self:SetUpdates(true)
    self:SetPropagate(Entity.Propagate_Always)
    
    if Server then
    
        self.clientId = -1
        self.playerId = Entity.invalidId
        self.status = kPlayerStatus.Void
    
    end
    
    self:AddTimedCallback(PlayerInfoEntity.UpdateScore, kPlayerInfoUpdateRate)

end

if Client then
    
    function PlayerInfoEntity:OnDestroy()   

        Scoreboard_OnClientDisconnect(self.clientId)    
        Entity.OnDestroy(self) 
        
    end
    
end

function PlayerInfoEntity:UpdateScore()

    if Server then
    
        local scorePlayer = Shared.GetEntity(self.playerId)

        if scorePlayer then

            self.clientId = scorePlayer:GetClientIndex()
            self.steamId = scorePlayer:GetSteamId()
            self.entityId = scorePlayer:GetId()
            self.playerName = string.sub(scorePlayer:GetName(), 0, kMaxNameLength)
            self.teamNumber = scorePlayer:GetTeamNumber()
            
            if HasMixin(scorePlayer, "Scoring") then

                self.score = scorePlayer:GetScore()
                self.kills = scorePlayer:GetKills()
                self.assists = scorePlayer:GetAssistKills()
                self.deaths = scorePlayer:GetDeaths()
				self.playerSkill = Clamp(scorePlayer:GetPlayerSkill(), 0, kMaxPlayerSkill)
				
            end

            self.resources = scorePlayer:GetResources()
            self.isCommander = scorePlayer:isa("Commander")
            self.isRookie = scorePlayer:GetIsRookie()
            self.status = scorePlayer:GetPlayerStatusDesc()
            self.isSpectator = scorePlayer:isa("Spectator")

            self.reinforcedTierNum = scorePlayer.reinforcedTierNum
            
            
            
        else
            DestroyEntity(self)
        end

    end 
    
    clientIndexToSteamId[self.clientId] = self.steamId  

    return true

end

if Server then

    function PlayerInfoEntity:SetScorePlayer(player)  
  
        self.playerId = player:GetId()
        self:UpdateScore()
        
    end

end


Shared.LinkClassToMap("PlayerInfoEntity", PlayerInfoEntity.kMapName, networkVars)