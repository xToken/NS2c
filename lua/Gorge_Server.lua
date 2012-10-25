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
    //self:GiveItem(DropStructureAbility2.kMapName)
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
