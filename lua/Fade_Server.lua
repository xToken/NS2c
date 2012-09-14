// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Fade_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Fade:InitWeapons()

    Alien.InitWeapons(self)
    
    self:GiveItem(SwipeBlink.kMapName)
    self:SetActiveWeapon(SwipeBlink.kMapName)
    
end

function Fade:GetTierTwoTechId()
    return kTechId.Metabolize
end

function Fade:GetTierThreeTechId()
    return kTechId.AcidRocket
end