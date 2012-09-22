// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommandStation_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function CommandStation:GetTeamType()
    return kMarineTeamType
end

function CommandStation:GetCommanderClassName()
    return MarineCommander.kMapName
end

function CommandStation:GetIsPlayerInside(player)

    local vecDiff = (player:GetModelOrigin() - self:GetModelOrigin())
    return vecDiff:GetLength() < self:GetExtents():GetLength() * 2
    
end

function CommandStation:GetIsPlayerValidForCommander(player)
    return player ~= nil and player:isa("Marine") and self:GetIsPlayerInside(player) and CommandStructure.GetIsPlayerValidForCommander(self, player)
end

local function KillPlayersInside(self)

    // Now kill any other players that are still inside the command station so they're not stuck!
    // Draw debug box if players are players on inside aren't dying or players on the outside are
    //DebugBox(self:GetModelOrigin(), self:GetModelOrigin(), self:GetExtents() * 1.7, 8, 1, 1, 1, 1)
    
    for index, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
    
        if not player:isa("Commander") and not player:isa("Spectator") then
        
            if self:GetIsPlayerInside(player) and player:GetId() ~= self.playerIdStartedLogin then
            
                //player:Kill(self, self, self:GetOrigin())
                
            end
            
        end
    
    end

end

function CommandStation:LoginPlayer(player)

    local commander = CommandStructure.LoginPlayer(self, player)
    
    //KillPlayersInside(self)
    
end

function CommandStation:OnConstructionComplete()
    self:TriggerEffects("deploy")    
end

function CommandStation:GetCompleteAlertId()
    return kTechId.MarineAlertCommandStationComplete
end

function CommandStation:GetDamagedAlertId()
    return kTechId.MarineAlertCommandStationUnderAttack
end