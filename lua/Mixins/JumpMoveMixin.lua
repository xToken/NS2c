// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Mixins\JumpMoveMixin.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

JumpMoveMixin = CreateMixin( JumpMoveMixin )
JumpMoveMixin.type = "JumpMove"

JumpMoveMixin.optionalCallbacks =
{
    OnJump = "Called when jump is performed",
}

JumpMoveMixin.expectedCallbacks =
{
    GetCanJump = "Allow / prevent jumping."
}

// use 8.42 for gravity -23

local kJumpForce = 8.22

JumpMoveMixin.networkVars =
{
    // Set to true when jump key has been released after jump processed
    // Used to require the key to pressed multiple times
    jumpHandled = "private compensated boolean",
	timeOfLastJump = "private time",
    jumping = "compensated boolean",
}

function JumpMoveMixin:__initmixin()

    self.jumpHandled = false
	self.timeOfLastJump = 0
    self.jumping = false
    self.jumpingClient = false
    
end

function JumpMoveMixin:ModifyJump(input, velocity, jumpVelocity)
end

function JumpMoveMixin:DoJump(input, velocity)

    local jumpVelocity = Vector(0, kJumpForce, 0)    
    self:ModifyJump(input, velocity, jumpVelocity)

    velocity.x = velocity.x + jumpVelocity.x
    velocity.y = jumpVelocity.y
    velocity.z = velocity.z + jumpVelocity.z

end

local function HandleJump(self, input, velocity)

    local success = false
    
    if self:GetCanJump() then
    
        self:DoJump(input, velocity)
        success = true
        
    end
    
    return success
    
end

function JumpMoveMixin:GetRecentlyJumped()
    return self.timeOfLastJump ~= nil and self.timeOfLastJump + .1 > Shared.GetTime()
end

function JumpMoveMixin:ModifyVelocity(input, velocity, deltaTime)

    // Must press jump multiple times to get multiple jumps 
    if bit.band(input.commands, Move.Jump) ~= 0 and not self.jumpHandled then
    
        if self.OnJumpRequest then
            self:OnJumpRequest()
        end
    
        if HandleJump(self, input, velocity) then
        
            if self.OnJump then
                self:OnJump()
            end
            
            self.onGround = false
            self.timeGroundTouched = Shared.GetTime()      
            self.jumping = true
            
            if self:GetJumpMode() == kJumpMode.Repeating then
                sself.jumpHandled = false
            else
                self.jumpHandled = true
            end

			self.timeOfLastJump = Shared.GetTime()
            
        end
           
    end

end
/*
if Client then

    function UpdateEffects(self, deltaTime)
    
        if self.jumpingClient ~= self.jumping and self.jumping and self.OnJump then
            self:OnJump()
        end
        
        self.jumpingClient = self.jumping
    
    end

    function JumpMoveMixin:Update(deltaTime)
        UpdateEffects(self, deltaTime)
    end
    
    function JumpMoveMixin:OnProcessSpectate(deltaTime)
        UpdateEffects(self, deltaTime)
    end

end
*/
function JumpMoveMixin:GetIsJumping()
    return self.jumping
end

function JumpMoveMixin:OnGroundChanged(onGround)
    
    if onGround then
        self.jumping = false
    end
    
end

function JumpMoveMixin:HandleButtons(input)

    // Remember when jump released
    if bit.band(input.commands, Move.Jump) == 0 then
        self.jumpHandled = false
    end
    
end

function JumpMoveMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("JumpMoveMixin:OnUpdateAnimationInput")
    local allowJumpAnim = true

    if self:GetIsJumping() and (not HasMixin(self, "LadderMove") or not self:GetIsOnLadder()) and (not self.GetHasMetabolizeAnimationDelay or not self:GetHasMetabolizeAnimationDelay()) then
        if self:isa("Skulk") then
            if not self:GetIsLeaping() then 
                modelMixin:SetAnimationInput("move", "jump")
            end
        else
            modelMixin:SetAnimationInput("move", "jump")
        end
    end
    
end