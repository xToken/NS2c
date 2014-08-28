//Jumping movement code.

local kSlowOnLandScalar = 0.33
local kMaxSpeedClampPerJump = 1.5
local kBunnyJumpMaxSpeedFactor = 1.7
local kAirSpeedMultipler = 3.0

function CoreMoveMixin:PreventMegaBunnyJumping(onJump, velocity)

    PROFILE("CoreMoveMixin:PreventMegaBunnyJumping")

    local maxscaledspeed = kBunnyJumpMaxSpeedFactor * self:GetMaxSpeed()
    
	if not onJump then
		maxscaledspeed = kAirSpeedMultipler * self:GetMaxSpeed()
	end
	
    if maxscaledspeed > 0.0 then
		local velY = velocity.y
		local spd = velocity:GetLengthXZ()
        if spd > maxscaledspeed then
            local fraction = (maxscaledspeed / (maxscaledspeed + Clamp(spd - maxscaledspeed, 0, kMaxSpeedClampPerJump)))
            velocity:Scale(fraction)
        end
		velocity.y = velY
    end
    
end

function CoreMoveMixin:HandleJump(input, velocity)

    PROFILE("CoreMoveMixin:HandleJump")

    if bit.band(input.commands, Move.Jump) ~= 0 and not self:GetIsJumpHandled() then
    
        if self:GetCanJump(self) then
            
            if self:GetUsesGoldSourceMovement() and self:HasAdvancedMovement() then
                self:PreventMegaBunnyJumping(true, velocity)
            end
            
            self:GetJumpVelocity(input, velocity)
            
            self:SetIsOnGround(false)
            self:SetIsJumping(true)
            
            if self.OnJump then
                self:OnJump()
            end
            
            self:UpdateLastJumpTime()
            
            if self:GetJumpMode() == kJumpMode.Repeating then
                self:SetIsJumpHandled(false)
            else
                self:SetIsJumpHandled(true)
            end
            
        elseif self:GetJumpMode() == kJumpMode.Default then
        
            self:SetIsJumpHandled(true)
            
        end
        
    end
    
end

local function UpdateJumpLand(self, impactForce, velocity)

    PROFILE("CoreMoveMixin:UpdateJumpLand")

    // If we landed this frame
    if self.jumping then
        self.jumping = false
        if self.OnJumpLand then
            self:OnJumpLand(impactForce)
        end
        if self:GetSlowOnLand(impactForce) then
            self:AddSlowScalar(kSlowOnLandScalar)
            velocity:Scale(kSlowOnLandScalar)
        end
    end
    
end

local function UpdateFallDamage(self, impactForce)
    
    PROFILE("CoreMoveMixin:UpdateFallDamage")

	if math.abs(impactForce) > kFallDamageMinimumVelocity then
		local damage = math.max(0, math.abs(impactForce * kFallDamageScalar) - kFallDamageMinimumVelocity * kFallDamageScalar)
		self:OnTakeFallDamage(damage)
	end
		
end

function CoreMoveMixin:UpdatePlayerLanding(impactForce, velocity)

	PROFILE("CoreMoveMixin:UpdatePlayerLanding")
	
    // dont transistion for only short in air durations
    if self.timeGroundTouched + self:GetGroundTransistionTime() <= Shared.GetTime() then
        self.timeGroundTouched = Shared.GetTime()
    end

    self.lastimpact = impactForce
    UpdateJumpLand(self, impactForce, velocity)
    UpdateFallDamage(self, impactForce)
	
end