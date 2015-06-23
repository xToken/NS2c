// Natural Selection 2 'Classic' Mod
// lua\PrimalScreamMixin.lua
// - Dragon

PrimalScreamMixin = CreateMixin(PrimalScreamMixin)
PrimalScreamMixin.type = "PrimalScreamMixin"

PrimalScreamMixin.networkVars =
{
    primaled = "boolean"
}

function PrimalScreamMixin:__initmixin()

    self.primaled = false
    if Server then
        self.primalGiveTime = 0
    end
end

local function CheckPrimalScream(self)
	self.primaled = self.primalGiveTime - Shared.GetTime() > 0
	return self.primaled
end

if Server then

    function PrimalScreamMixin:PrimalScream(duration)
        if not self.primaled then
			self:AddTimedCallback(CheckPrimalScream, duration)
		end
        self.primaled = true
        self.primalGiveTime = Shared.GetTime() + duration
    end

end

function PrimalScreamMixin:GetHasPrimalScream()
    return self.primaled
end