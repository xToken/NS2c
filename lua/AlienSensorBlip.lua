// lua/AlienSensorBlip.lua
//

class 'AlienSensorBlip' (Entity)

AlienSensorBlip.kMapName = "aliensensorblip"

local networkVars =
{
    entId       = "entityid"
}

function AlienSensorBlip:OnCreate()

    Entity.OnCreate(self)
    
    self.entId    = Entity.invalidId
    
    self:SetPropagate(Entity.Propagate_Mask)
    self:UpdateRelevancy()
    
end

function AlienSensorBlip:UpdateRelevancy()

    self:SetRelevancyDistance(Math.infinity)
    self:SetExcludeRelevancyMask(kRelevantToTeam2)
    
end

function AlienSensorBlip:Update(entity)

    if entity.GetEngagementPoint then
        self:SetOrigin(entity:GetEngagementPoint())
    else
        self:SetOrigin(entity:GetModelOrigin())
    end
    
    self.entId = entity:GetId()
    
end

Shared.LinkClassToMap("AlienSensorBlip", AlienSensorBlip.kMapName, networkVars)