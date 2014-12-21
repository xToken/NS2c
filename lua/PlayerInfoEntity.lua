--[[
    ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======

    lua\PlayerInfoEntity.lua

    Created by:   Andreas Urwalek(andi@unknownworlds.com)

     Stores information of connected players.

     ========= For more information, visit us at http://www.unknownworlds.com =====================
]]

local clientIndexToSteamId = {}
local kPlayerInfoUpdateRate = 0.5

function GetSteamIdForClientIndex(clientIndex)
    return clientIndexToSteamId[clientIndex]
end

class 'PlayerInfoEntity' (Entity)

PlayerInfoEntity.kMapName = "playerinfo"

local networkVars =
{
    -- those are not necessary for this entity
    m_angles = "angles (by 10 [], by 10 [], by 10 [])",
    m_origin = "position (by 2000 [], by 2000 [], by 2000 [])",

    clientId = "entityid",
    steamId = "integer",
    playerId = "entityid",
    playerName = string.format("string (%d)", kMaxNameLength * 4 ),
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
    playerSkill = string.format("integer (0 to %d)", kMaxPlayerSkill),
    currentTech = "integer"
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

--Insight upgrades bitmask table
local techUpgradesTable = { kTechId.Jetpack, kTechId.HeavyArmor, kTechId.Welder, kTechId.HandGrenades, kTechId.Mines, 
    kTechId.Carapace, kTechId.Regeneration, kTechId.Redemption, 
    kTechId.Aura, kTechId.Silence, kTechId.Ghost,
    kTechId.Celerity, kTechId.Adrenaline, kTechId.Redeployment, 
    kTechId.Bombard, kTechId.Focus, kTechId.Fury,
    kTechId.Parasite }

local techUpgradesBitmask = CreateBitMask(techUpgradesTable)

function PlayerInfoEntity:UpdateScore()

    if Server then
    
        local scorePlayer = Shared.GetEntity(self.playerId)

        if scorePlayer then

            self.clientId = scorePlayer:GetClientIndex()
            self.steamId = scorePlayer:GetSteamId()
            self.entityId = scorePlayer:GetId()
            self.playerName = string.UTF8Sub(scorePlayer:GetName(), 0, kMaxNameLength)
            self.teamNumber = scorePlayer:GetTeamNumber()
            
            if HasMixin(scorePlayer, "Scoring") then

                self.score = scorePlayer:GetScore()
                self.kills = scorePlayer:GetKills()
                self.assists = scorePlayer:GetAssistKills()
                self.deaths = scorePlayer:GetDeaths()
                self.playerSkill = Clamp(scorePlayer:GetPlayerSkill(), 0, kMaxPlayerSkill)
                local scoreClient = scorePlayer:GetClient()
                Server.UpdatePlayerInfo( scoreClient, self.playerName, self.score )
                
            end

            self.resources = scorePlayer:GetResources()
            self.isCommander = scorePlayer:isa("Commander")
            self.isRookie = scorePlayer:GetIsRookie()
            self.status = scorePlayer:GetPlayerStatusDesc()
            self.isSpectator = scorePlayer:isa("Spectator")

            self.reinforcedTierNum = scorePlayer.reinforcedTierNum
            
            --Always reset this value so we don't have to check for previous tech to remove it, etc
            self.currentTech = 0
            
            if scorePlayer:isa("Alien") then
                for _, upgrade in pairs (scorePlayer:GetUpgrades()) do
                    if techUpgradesBitmask[upgrade] then
                        self.currentTech = bit.bor(self.currentTech, techUpgradesBitmask[upgrade])
                    end
                end
            elseif scorePlayer:isa("Marine") then
                if scorePlayer:GetIsParasited() then
                    self.currentTech = bit.bor(self.currentTech, techUpgradesBitmask[kTechId.Parasite])
                end
                
                if scorePlayer:isa("JetpackMarine") then
                    self.currentTech = bit.bor(self.currentTech, techUpgradesBitmask[kTechId.Jetpack])
                end

				if scorePlayer:isa("HeavyArmorMarine") then
                    self.currentTech = bit.bor(self.currentTech, techUpgradesBitmask[kTechId.HeavyArmor])
                end
                
                --Mapname to TechId list of displayed weapons
                local displayWeapons = { { Welder.kMapName, kTechId.Welder },
                { HandGrenades.kMapName, kTechId.HandGrenades },
                { Mines.kMapName, kTechId.Mines} }
                
                for _, weapon in pairs(displayWeapons) do
                    if scorePlayer:GetWeapon(weapon[1]) ~= nil then
                        self.currentTech = bit.bor(self.currentTech, techUpgradesBitmask[weapon[2]])
                    end
                end
            end
            
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

function GetTechIdsFromBitMask(techTable)

    local techIds = { }

    if techTable and techTable > 0 then
        for techId, bitmask in pairs(techUpgradesBitmask) do
            if bit.band(techTable, bitmask) > 0 then
                table.insert(techIds, techId)
            end
        end
    end
    
    --Sort the table by bitmask value so it keeps the order established in the original table
    table.sort(techIds, function(a, b) return techUpgradesBitmask[a] < techUpgradesBitmask[b] end)
    
    return techIds
end

Shared.LinkClassToMap("PlayerInfoEntity", PlayerInfoEntity.kMapName, networkVars)