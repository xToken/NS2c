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
    GameEffects = "Required to track energize state",
}

EmpowerMixin.networkVars =
{
    empowered = "private boolean"
}

function EmpowerMixin:__initmixin()

    self.empowered = false
    if Server then
        self.empowerGiveTime = 0
    end
end

local function CheckEmpower(self)
	self.empowered = self.empowerGiveTime - Shared.GetTime() > 0
	return self.empowered
end

if Server then

    function EmpowerMixin:Empower()
        if not self.empowered then
			self:AddTimedCallback(CheckEmpower, 2)
		end
        self.empowered = true
        self.empowerGiveTime = Shared.GetTime() + 2
    end

end

function EmpowerMixin:GetIsEmpowered()
    return self.empowered
end