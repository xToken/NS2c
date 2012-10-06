// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/SensorBlip.lua
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

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
    self:UpdateRelevancy()
    
end

function SensorBlip:UpdateRelevancy()

    self:SetRelevancyDistance(Math.infinity)
    self:SetExcludeRelevancyMask(kRelevantToTeam1)
    
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