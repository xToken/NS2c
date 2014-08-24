//    
// lua\IdleAnimationMixin.lua    
//

IdleAnimationMixin = CreateMixin(IdleAnimationMixin)
IdleAnimationMixin.type = "IdleAnimation"

IdleAnimationMixin.expectedCallbacks = 
{
    GetIdleAnimations = "Return a list of idle animations."
}

IdleAnimationMixin.networkVars = { }

local kTimetoIdleAnimation = 10

function IdleAnimationMixin:__initmixin()
	self.timeIdle = 0
	self.activeAnimation = nil
end

function IdleAnimationMixin:GetPlayIdleAnimations()
    local player = self:GetParent()
    if player then
        local activeWeapon = player:GetActiveWeapon()
        return player:GetIsIdle() and self == activeWeapon
    end
    return false
end

function IdleAnimationMixin:OnUpdateAnimationInput(modelMixin)
	if self:GetPlayIdleAnimations() then
		if self.timeIdle >= kTimetoIdleAnimation then
			local idleAnimations = self:GetIdleAnimations()
			if idleAnimations and type(idleAnimations) == "table" then
			    self.activeAnimation = idleAnimations[math.random(1, #idleAnimations)]
			end
			self.timeIdle = self.timeIdle - kTimetoIdleAnimation
		end
		if self.activeAnimation ~= nil then
		    modelMixin:SetAnimationInput("idleName", self.activeAnimation)
		end
	else
		modelMixin:SetAnimationInput("idleName", "idle")
		self.timeIdle = 0
		self.activeAnimation = nil
	end
end

function IdleAnimationMixin:ProcessMoveOnWeapon(player, input)
	if self:GetPlayIdleAnimations() then
		self.timeIdle = self.timeIdle + input.time
	end
end