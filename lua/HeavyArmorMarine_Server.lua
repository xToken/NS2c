//
// lua\HeavyArmorMarine_Server.lua

local function GetCanTriggerAlert(self, techId, timeOut)
    if not self.alertTimes then
        self.alertTimes = {}
    end  
    return not self.alertTimes[techId] or self.alertTimes[techId] + timeOut < Shared.GetTime()
end

function HeavyArmorMarine:GetDamagedAlertId()
    return kTechId.MarineAlertSoldierUnderAttack
end