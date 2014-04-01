//    
// lua\EmpowerMixin.lua    
//    
//    Created by:   Dragon

/**
 * EmpowerMixin speeds up attack speed on nearby players.
 */
EmpowerMixin = CreateMixin(EmpowerMixin)
EmpowerMixin.type = "Empower"

EmpowerMixin.expectedMixins =
{
    GameEffects = "Required to track empowered state",
}

EmpowerMixin.networkVars =
{
    empowered = "private boolean"
}

function EmpowerMixin:__initmixin()
    self.empowered = false
    self.lastEmpoweredTime = 0
end

if Server then

    local function CheckEmpower(self)
        self.empowered = self.lastEmpoweredTime + kEmpowerUpdateRate > Shared.GetTime()
        return self.empowered
    end

    function EmpowerMixin:Empower()
    
        if not self:GetIsEmpowered() then
			self:AddTimedCallback(CheckEmpower, kEmpowerUpdateRate)
			self.empowered = true
		end
		self.lastEmpoweredTime = Shared.GetTime()
		
    end

end

function EmpowerMixin:GetIsEmpowered()
    return self.empowered
end