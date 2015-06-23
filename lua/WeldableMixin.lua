// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\WeldableMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/BalanceHealth.lua")

WeldableMixin = CreateMixin(WeldableMixin)
WeldableMixin.type = "Weldable"

WeldableMixin.optionalCallbacks =
{
    GetCanBeWeldedOverride = "Return true booleans: if we can be welded now and if we can be welded in the future.",
    OnWeldOverride = "When welded (welding entity, elapsed time, player).",
    GetWeldPercentageOverride = "Returns the weld progress, 0-1 scalar."
}

WeldableMixin.expectedMixins =
{
    Live = "Required for AddHealth.",
    Team = "Required for GetTeamNumber"
}

function WeldableMixin:OnWeld(doer, elapsedTime, player)

    if self:GetCanBeWelded(doer) then
    
        if self.OnWeldOverride then
            self:OnWeldOverride(doer, elapsedTime, player)
        elseif doer:isa("Welder") then
            self:AddHealth(doer:GetRepairRate(self) * elapsedTime)
        end
        
        if player and player.OnWeldTarget then
            player:OnWeldTarget(self)
        end
        
    end
    
end

function WeldableMixin:OnWeldCanceled(doer)
    return true
end

// for status display on the welder, or description text
function WeldableMixin:GetWeldPercentage()

    if self.GetWeldPercentageOverride then
        return self:GetWeldPercentageOverride()
    end
    
    return self:GetHealthScalar()
    
end

// If entity is ready to be welded by buildbot right now, and in the future
function WeldableMixin:GetCanBeWelded(doer)

    // Can't weld yourself!
    if doer == self then
        return false
    end
    
    local canBeWelded = true
    // GetCanBeWeldedOverride() will return two booleans.
    // The first will be true if self can be welded and
    // the second will return true if the first should
    // completely override the default behavior below.
    if self.GetCanBeWeldedOverride then
    
        local overrideWelded, overrideDefault = self:GetCanBeWeldedOverride(doer)
        if overrideDefault then
            return overrideWelded
        end
        canBeWelded = overrideWelded
        
    end
    
    canBeWelded = canBeWelded and self:GetIsAlive() and doer:GetTeamNumber() == self:GetTeamNumber() and
                  self:GetWeldPercentage() < 1
    
    return canBeWelded
    
end