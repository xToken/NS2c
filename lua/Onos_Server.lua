// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Onos_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com) and
//                  Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Changes to weapons

function Onos:InitWeapons()

    Alien.InitWeapons(self)

    self:GiveItem(Gore.kMapName)
    self:SetActiveWeapon(Gore.kMapName)
    
end

function Onos:GetTierTwoTechId()
    return kTechId.Stomp
end

function Onos:GetTierThreeTechId()
    if kDevourEnabled then
        return kTechId.Devour
    else 
        return kTechId.None
    end
end