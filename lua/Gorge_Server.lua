// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Gorge_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Gorge:InitWeapons()

    Alien.InitWeapons(self)

    self:GiveItem(SpitSpray.kMapName)
    self:GiveItem(DropStructureAbility.kMapName)
    self:GiveItem(DropStructureAbility2.kMapName)
    self:SetActiveWeapon(SpitSpray.kMapName)
    
end

function Gorge:GetTierTwoTechId()
    return kTechId.BileBomb
end

/*
function Gorge:GetTierThreeTechId()
    return kTechId.WebStalk
end
*/

// Create hydra from menu
function Gorge:AttemptToBuy(techIds)

    local techId = techIds[1]
    
    // Drop hydra
    if (techId == kTechId.Hydra) then    
    
        // Create hydra in front of us
        local playerViewPoint = self:GetEyePos()
        local hydraEndPoint = playerViewPoint + self:GetViewAngles():GetCoords().zAxis * 2
        local trace = Shared.TraceRay(playerViewPoint, hydraEndPoint, CollisionRep.Default, PhysicsMask.AllButPCs, EntityFilterOne(self))
        local hydraPosition = trace.endPoint
        
        local hydra = CreateEntity(LookupTechData(techId, kTechDataMapName), hydraPosition, self:GetTeamNumber())
        
        // Make sure there's room
        if(hydra:SpaceClearForEntity(hydraPosition)) then
        
            hydra:SetOwner(self)

            self:AddResources(-LookupTechData(techId, kTechDataCostKey))
                    
            self:TriggerEffects("gorge_create")

        else
        
            DestroyEntity(hydra)
            
        end
        
        return true
        
    else
    
        return Alien.AttemptToBuy(self, techIds)
        
    end
    
end

function Gorge:OnCommanderStructureLogin(hive)

    DestroyEntity(self.slideLoopSound)
    self.slideLoopSound = nil

end

function Gorge:OnCommanderStructureLogout(hive)

    self.slideLoopSound = Server.CreateEntity(SoundEffect.kMapName)
    self.slideLoopSound:SetAsset(Gorge.kSlideLoopSound)
    self.slideLoopSound:SetParent(self)

end

function Gorge:OnOverrideOrder(order)
    
    local orderTarget = nil
    
    if (order:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(order:GetParam())
    end
    
    if(order:GetType() == kTechId.Default and GetOrderTargetIsHealTarget(order, self:GetTeamNumber())) then
    
        order:SetType(kTechId.Heal)
        
    end
    
end
