// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PowerConsumerMixin.lua
//
//    Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

PowerConsumerMixin = CreateMixin(PowerConsumerMixin)
PowerConsumerMixin.type = "PowerConsumer"

local kPoweredEffectsInterval = 5

PowerConsumerMixin.optionalCallbacks =
{
    GetRequiresPower = "Return true/false if this object requires power"
}

function PowerConsumerMixin:__initmixin()
	self.lastpoweredeffecttime = 0
	self.deployonpower = false
end

function PowerConsumerMixin:GetRequiresPower()
	return false
end

if Server then
    
    local function Deploy(self)
        self:TriggerEffects("deploy")
    end
       
    function PowerConsumerMixin:OnConstructionComplete()
		if self.GetRequiresPower and self:GetRequiresPower() then
			if self:GetIsPowered() then
				Deploy(self)
			else
				self.deployonpower = true
			end
        else
            Deploy(self)
        end
    end
	
	function PowerConsumerMixin:OnPowerOn()
		if self.deployonpower then
			Deploy(self)
			self.deployonpower = false
		end
    end
	
end

function PowerConsumerMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("PowerConsumerMixin:OnUpdateAnimationInput")
	local powered = (self.GetRequiresPower and self:GetRequiresPower() and self:GetIsPowered()) or true
    modelMixin:SetAnimationInput("powered", powered)
    
end