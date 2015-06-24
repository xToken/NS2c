// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\Mixins\CrouchCoreMoveMixin.lua - Crouching movement code.
// - Dragon

function CoreMoveMixin:UpdateCrouchState(input, deltaTime)

    PROFILE("CoreMoveMixin:UpdateCrouchState")

	local crouchDesired = bit.band(input.commands, Move.Crouch) ~= 0	
    if crouchDesired == self.crouching then
		//If enough time has passed, clear time.
		if self.timeOfCrouchChange > 0 and self.timeOfCrouchChange + self:GetCrouchTime() < Shared.GetTime() then
			self.timeOfCrouchChange = 0
		end
        return
    end
   
    if not crouchDesired then
        
        // Check if there is room for us to stand up.
        self.crouching = crouchDesired
        self:UpdateControllerFromEntity()
        
        if self:GetIsColliding() then
            self.crouching = true
            self:UpdateControllerFromEntity()
        else
            self.timeOfCrouchChange = Shared.GetTime()
        end
        
    elseif self:GetCanCrouch() then
        self.crouching = crouchDesired
        self.timeOfCrouchChange = Shared.GetTime()
        self:UpdateControllerFromEntity()
    end
    
end

local function SplineFraction(value, scale)
    value = scale * value
    local valueSq = value * value
    
    // Nice little ease-in, ease-out spline-like curve
    return 3.0 * valueSq - 2.0 * valueSq * value
end

function CoreMoveMixin:GetCrouchAmount()

    PROFILE("CoreMoveMixin:GetCrouchAmount")

    local crouchScalar = ConditionalValue(self.crouching, 1, 0)
	
    if self.lastcrouchamountcalc == Shared.GetTime() then
        return self.lastcrouchamount
    end
	
    if self.timeOfCrouchChange > 0 then
        local crouchspeed = self:GetCrouchTime()
        if crouchspeed > 0 then
            local crouchtime = Shared.GetTime() - self.timeOfCrouchChange
            if(self.crouching) then
                crouchScalar = SplineFraction(crouchtime / crouchspeed, 1.0)
            else
                if crouchtime >= (crouchspeed * 0.5) then
                    crouchScalar = 0
                else
                    crouchScalar = SplineFraction(1.0 - (crouchtime / (crouchspeed * 0.5)), 1.0)
                end
            end
        end
    end
	
    self.lastcrouchamountcalc = Shared.GetTime()
    self.lastcrouchamount = crouchScalar
    return crouchScalar
    
end