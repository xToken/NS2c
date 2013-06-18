// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/SensorBlip.lua
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Sensor Blips can be relevant to either team now.

class 'SensorBlip' (Entity)

SensorBlip.kMapName = "sensorblip"

local networkVars =
{
    entId       = "entityid"
}

function SensorBlip:OnCreate()

    Entity.OnCreate(self)
    
    self.entId    = Entity.invalidId
    
    self:SetPropagate(Entity.Propagate_Mask)
    self:UpdateRelevancy(0)
    
end

function SensorBlip:UpdateRelevancy(teamnum)

    self:SetRelevancyDistance(Math.infinity)
    local includeMask
    if teamnum == 1 then
        includeMask = kRelevantToTeam1
    elseif teamnum == 2 then
        includeMask = kRelevantToTeam2
    elseif teamnum == 0 then
        includeMask = 0
    end
    self:SetExcludeRelevancyMask(includeMask)
    
end

function SensorBlip:Update(entity)

    if entity.GetEngagementPoint then
        self:SetOrigin(entity:GetEngagementPoint())
    else
        self:SetOrigin(entity:GetModelOrigin())
    end
    
    self.entId = entity:GetId()
    
end

Shared.LinkClassToMap("SensorBlip", SensorBlip.kMapName, networkVars)