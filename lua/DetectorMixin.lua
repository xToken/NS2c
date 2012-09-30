// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\DetectorMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================

DetectorMixin = { }
DetectorMixin.type = "Detector"

// Should be smaller than DetectableMixin:kResetDetectionInterval
DetectorMixin.kUpdateDetectionInterval = 1.5

DetectorMixin.expectedCallbacks =
{
    // Returns integer for team number
    GetTeamNumber = "",
    
    // Returns 0 if not active currently
    GetDetectionRange = "Return range of the detector.",
    
    GetOrigin = "Detection origin",
}

DetectorMixin.optionalCallbacks =
{
    IsValidDetection = "Used to valid if target should be shown",
    OnCheckDetectorActive = "Called to check if detector is active.",
    DeCloak = "Should decloak on detection",
}

function DetectorMixin:__initmixin()
    self.timeSinceLastDetected = 0
    self.active = true
end

local function PerformDetection(self)

    // Get list of Detectables in range
    local range = self:GetDetectionRange()
    
    if self.OnCheckDetectorActive then
        self.active = self:OnCheckDetectorActive()
    end
    
    if range > 0 and self.active then
        local teamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
        local origin = self:GetOrigin()
        local detectables = GetEntitiesWithMixinForTeamWithinRange("Detectable", teamNumber, origin, range)
        
        for index, detectable in ipairs(detectables) do
            // Mark them as detected
            if not self.IsValidDetection or self:IsValidDetection(detectable) then
                if not self.DeCloak or self:DeCloak() then
                    detectable:SetDetected(true, true)
                else
                    detectable:SetDetected(true, false)
                end
                
            end
        
        end
        
    end
    
end

local function SharedUpdate(self, deltaTime)

    if self.active then
        self.timeSinceLastDetected = self.timeSinceLastDetected + deltaTime      
        if self.timeSinceLastDetected >= DetectorMixin.kUpdateDetectionInterval then   
            PerformDetection(self)    
            self.timeSinceLastDetected = self.timeSinceLastDetected - DetectorMixin.kUpdateDetectionInterval
        end
    else
        self.timeSinceLastDetected = self.timeSinceLastDetected + deltaTime      
        if self.timeSinceLastDetected >= DetectorMixin.kUpdateDetectionInterval then 
            if self.OnCheckDetectorActive then
                self.active = self:OnCheckDetectorActive()
            end
        end
    end
    
end

function DetectorMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end

function DetectorMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end

