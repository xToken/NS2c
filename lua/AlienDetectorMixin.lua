//    
// lua\AlienDetectorMixin.lua
  
AlienDetectorMixin = { }
AlienDetectorMixin.type = "AlienDetector"

// Should be smaller than DetectableMixin:kResetDetectionInterval
AlienDetectorMixin.kUpdateDetectionInterval = 4

AlienDetectorMixin.expectedCallbacks =
{
    // Returns integer for team number
    GetTeamNumber = "",
    // Returns 0 if not active currently
    GetAlienDetectionRange = "Return range of the detector.",
    GetOrigin = "Detection origin",
}

AlienDetectorMixin.optionalCallbacks =
{
    IsValidAlienDetection = "Used to valid if target should be shown",
    OnCheckAlienDetectorActive = "Called to check if detector is active.",
}

function AlienDetectorMixin:__initmixin()
    self.timeSinceLastDetected = 0
    self.active = false
end

local function PerformDetection(self)

    // Get list of Detectables in range
    local range = self:GetAlienDetectionRange()
    
    if range > 0 and self.active then

        local teamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
        local origin = self:GetOrigin()    
        local detectables = GetEntitiesWithMixinForTeamWithinRange("Detectable", teamNumber, origin, range)
        
        for index, detectable in ipairs(detectables) do
        
            // Mark them as detected, run seperate detections for aura/recon
            if not self.IsValidAlienDetection or self:IsValidAlienDetection(detectable) then
                detectable:SetDetected(true, false)
            end
        
        end
        
    end
    
end

local function SharedUpdate(self, deltaTime)

    self.timeSinceLastDetected = self.timeSinceLastDetected + deltaTime      
    if self.timeSinceLastDetected >= DetectorMixin.kUpdateDetectionInterval then
        if self.active then
            PerformDetection(self)
        else
            if self.OnCheckAlienDetectorActive then
                self.active = self:OnCheckAlienDetectorActive()
            end
        end
        self.timeSinceLastDetected = self.timeSinceLastDetected - DetectorMixin.kUpdateDetectionInterval
    end
    
end

function AlienDetectorMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end

function AlienDetectorMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end

