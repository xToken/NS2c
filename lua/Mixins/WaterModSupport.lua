//    
// lua\WaterModSupport.lua    
// To support watermod

CorrodeMixin = CreateMixin( CorrodeMixin )
CorrodeMixin.type = "Corrode"

CorrodeMixin.networkVars = { }

local kCorrodeShaderDuration = 4
local kInfestationCorrodeDamagePerSecond = 0

function CorrodeMixin:__initmixin()
    self.isCorroded = false
end

function CorrodeMixin:OnDestroy()
end

function CorrodeMixin:OnTakeDamage(damage, attacker, doer, point, direction)
end

GroundMoveMixin = CreateMixin(GroundMoveMixin)
GroundMoveMixin.type = "GroundMove"

GroundMoveMixin.networkVars = { }