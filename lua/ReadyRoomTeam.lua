// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ReadyRoomTeam.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// This class is used for the team that is for players that are in the ready room.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed AlienComm references, added resources clear.

Script.Load("lua/Team.lua")
Script.Load("lua/TeamDeathMessageMixin.lua")

class 'ReadyRoomTeam' (Team)

function ReadyRoomTeam:Initialize(teamName, teamNumber)

    InitMixin(self, TeamDeathMessageMixin)
    
    Team.Initialize(self, teamName, teamNumber)
    
end

function ReadyRoomTeam:GetRespawnMapName(player)

    local mapName = player.kMapName    
    
    if mapName == nil then
        mapName = ReadyRoomPlayer.kMapName
    end
    
    // Use previous life form if dead or in commander chair
    if (mapName == MarineCommander.kMapName) 
       or (mapName == Spectator.kMapName) 
       or (mapName == AlienSpectator.kMapName) 
       or (mapName ==  MarineSpectator.kMapName) then 
    
        mapName = player:GetPreviousMapName()
        
    end
    
    // need to set embryos to ready room players, otherwise they wont be able to move
    if mapName == Embryo.kMapName then
        mapName = ReadyRoomPlayer.kMapName
    end
    return mapName
    
end

function ReadyRoomTeam:ResetTeam()
    local players = GetEntitiesForTeam("Player", self:GetTeamNumber())
    for p = 1, #players do
        player:SetResources(0)
    end
end

/**
 * Transform player to appropriate team respawn class and respawn them at an appropriate spot for the team.
 */
function ReadyRoomTeam:ReplaceRespawnPlayer(player, origin, angles)

    local mapName = self:GetRespawnMapName(player)
    
    // We do not support Commanders in the ready room. The ready room is chaos!
    if mapName == MarineCommander.kMapName then
        mapName = ReadyRoomPlayer.kMapName
    end
    
    local isEmbryo = player:isa("Embryo") or (player:isa("Spectator") and player:GetPreviousMapName() == Embryo.kMapName)
    local newPlayer = player:Replace(mapName, self:GetTeamNumber(), false, origin)
    
    // Spawn embryos as ready room players with embryo model, so they can still move.
    if isEmbryo then
        newPlayer:SetModel(Embryo.kModelName)
    end
    
    self:RespawnPlayer(newPlayer, origin, angles)
    
    newPlayer:ClearGameEffects()
    newPlayer:TriggerEffects("tooltip")
    
    return (newPlayer ~= nil), newPlayer
    
end

function ReadyRoomTeam:GetSupportsOrders()
    return false
end

function ReadyRoomTeam:TriggerAlert(techId, entity)
    return false
end