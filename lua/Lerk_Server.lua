// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Lerk_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Lerk:InitWeapons()

    Alien.InitWeapons(self)

    self:GiveItem(LerkBite.kMapName)    
    self:SetActiveWeapon(LerkBite.kMapName)
    
end

function Lerk:GetTierTwoTechId()
    return kTechId.Umbra
end

function Lerk:GetTierThreeTechId()
    return kTechId.PrimalScream
end



