// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\HeavyArmorMarine_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local function GetCanTriggerAlert(self, techId, timeOut)
    if not self.alertTimes then
        self.alertTimes = {}
    end  
    return not self.alertTimes[techId] or self.alertTimes[techId] + timeOut < Shared.GetTime()
end

function HeavyArmorMarine:GetDamagedAlertId()
    return kTechId.MarineAlertSoldierUnderAttack
end
