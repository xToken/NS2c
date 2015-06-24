// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\SiegeCannon_Server.lua
// - Dragon

local kSiegeCannonDamageOffset = Vector(0, 0.3, 0)
local kMoveParam = "move_speed"
local kMuzzleNode = "fxnode_arcmuzzle"

function SiegeCannon:SetTargetDirection(targetPosition)
    self.targetDirection = GetNormalizedVector(targetPosition - self:GetOrigin())
end

function SiegeCannon:ClearTargetDirection()
    self.targetDirection = nil
end

function SiegeCannon:ValidateTargetPosition(position)
    return true
end

function SiegeCannon:UpdateOrders(deltaTime)

    if self:GetInAttackMode() then
     
        // Check for new target every so often, but not every frame.
        local time = Shared.GetTime()
        if self.timeOfLastAcquire == nil or (time > self.timeOfLastAcquire + 0.2) then
        
            self:AcquireTarget()
            self.timeOfLastAcquire = time
            
        end
        
    end
    
end

function SiegeCannon:AcquireTarget()
    
    local finaltarget = nil
    
    finaltarget = self.targetSelector:AcquireTarget()
    
    if finaltarget ~= nil and self:ValidateTargetPosition(finaltarget:GetOrigin()) then
        self:GiveOrder(kTechId.Attack, finaltarget:GetId(), nil)
        self:SetMode(SiegeCannon.kMode.Targeting)
        self.targetPosition = finaltarget:GetOrigin()
        self:SetTargetDirection(self.targetPosition)        
    end
    
end

function SiegeCannon:SetMode(mode)
    
    if self.mode ~= mode then        
        self.mode = mode
    end
    
end

function SiegeCannon:OnPowerOn()
    self:SetMode(SiegeCannon.kMode.Active)
    self.targetPosition = nil
    self:TriggerEffects("sc_deploying")
end

function SiegeCannon:OnPowerOff()
    self:SetMode(SiegeCannon.kMode.Inactive)
    self.targetPosition = nil
    self:TriggerEffects("sc_inactive")
end