// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/AlienTeamInfo.lua
//
// AlienTeamInfo is used to sync information about a team to clients.
// Only alien team players (and spectators) will receive the information about number
// of shells, spurs or veils.
//
// Created by Andreas Urwalek (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TeamInfo.lua")

class 'AlienTeamInfo' (TeamInfo)

AlienTeamInfo.kMapName = "AlienTeamInfo"

local networkVars =
{
    numHives = "integer (0 to 10)",
    eggCount = "integer (0 to 127)"
}

function AlienTeamInfo:OnCreate()

    TeamInfo.OnCreate(self)
    
    self.numHives = 0
    self.eggCount = 0

end

if Server then

    function AlienTeamInfo:OnUpdate(deltaTime)
    
        TeamInfo.OnUpdate(self, deltaTime)
        
        local team = self:GetTeam()
        if team then
            self.numHives = team:GetNumHives()
            self.eggCount = team:GetActiveEggCount()
        end
        
    end

end

function AlienTeamInfo:GetNumHives()
    return self.numHives
end

function AlienTeamInfo:GetEggCount()
    return self.eggCount
end

Shared.LinkClassToMap("AlienTeamInfo", AlienTeamInfo.kMapName, networkVars)