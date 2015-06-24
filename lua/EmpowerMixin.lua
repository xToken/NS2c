// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\EmpowerMixin.lua
// - Dragon

EmpowerMixin = CreateMixin(EmpowerMixin)
EmpowerMixin.type = "Empower"

EmpowerMixin.expectedMixins =
{
    GameEffects = "Required to track empowered state",
}

EmpowerMixin.networkVars =
{
    empowered = "boolean"
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
    
        if HasMixin(self, "Live") and not self:GetIsAlive() then
            return
        end
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