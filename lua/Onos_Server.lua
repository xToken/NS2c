// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Onos_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com) and
//                  Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Onos:InitWeapons()

    Alien.InitWeapons(self)
    self:GiveItem(Gore.kMapName)
    //self:GiveItem(Devour.kMapName)
    self:SetActiveWeapon(Gore.kMapName)
    
end

function Onos:GetTierTwoTechId()
    return kTechId.Stomp
end

function Onos:GetTierThreeTechId()
    return kTechId.Smash
end

function Onos:DevourUpdate()
    local devourWeapon = self:GetWeapon("devour")
    if devourWeapon and devourWeapon:IsAlreadyEating() then
        local food = Shared.GetEntity(devourWeapon.devouring)
        if food then
        
            if devourWeapon.timeSinceLastDevourUpdate + Devour.kDigestionSpeed < Shared.GetTime() then   
                //Player still being eaten, damage them
                devourWeapon.timeSinceLastDevourUpdate = Shared.GetTime()
                if devourWeapon:DoDamage(kDevourDamage , food, nil, nil, "none" ) then
                    devourWeapon:OnDevourEnd()
                    return
                end
            end
    
            //Always update players POS relative to the onos
            if Server then
                atOrigin = self:GetOrigin()
                atOrigin.y = atOrigin.y + 0.5
                SpawnPlayerAtPoint(food, atOrigin)
            end
            if food.physicsModel then
                Shared.DestroyCollisionObject(food.physicsModel)
                food.physicsModel = nil
            end
            
        else
            devourWeapon:OnDevourEnd()
        end        
    end

end