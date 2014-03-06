//    
// lua\PrimalScreamMixin.lua    
//    
//    Created by:   Dragon

/**
 * ParimalScreamMixin speeds up attack speed and damage on nearby players.
 */
PrimalScreamMixin = CreateMixin(PrimalScreamMixin)
PrimalScreamMixin.type = "PrimalScreamMixin"

PrimalScreamMixin.networkVars =
{
    primaled = "private boolean"
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