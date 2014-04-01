//    
// lua\EnergizeMixin.lua
//

EnergizeMixin = CreateMixin(EnergizeMixin)
EnergizeMixin.type = "Energize"

EnergizeMixin.expectedMixins =
{
    GameEffects = "Required to track energized state",
}

EnergizeMixin.networkVars =
{
    energized = "private boolean"
}

function EnergizeMixin:__initmixin()
    self.energized = false
    self.lastEnergizedTime = 0
end

if Server then

    local function CheckEnergized(self)
        self.energized = self.lastEnergizedTime + kEnergizeUpdateRate > Shared.GetTime()
        return self.energized
    end

    function EnergizeMixin:Energize()
    
        if not self:GetEnergized() then
			self:AddTimedCallback(CheckEnergized, kEnergizeUpdateRate)
            self:AddEnergy(kPlayerEnergyPerEnergize)
            self.energized = true
		end       
        self.lastEnergizedTime = Shared.GetTime()
        
    end

end

function EnergizeMixin:GetEnergized()
    return self.energized
end