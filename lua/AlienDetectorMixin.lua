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
    GetDetectionRange = "Return range of the detector.",
    GetOrigin = "Detection origin",
}

AlienDetectorMixin.optionalCallbacks =
{
    IsValidDetection = "Used to valid if target should be shown",
    OnCheckDetectorActive = "Called to check if detector is active.",
}

function AlienDetectorMixin:__initmixin()
    self.timeSinceLastDetected = 0
    self.active = false
end

local function PerformDetection(self)

    // Get list of Detectables in range
    local range = self:GetDetectionRange(false)
    
    if range > 0 and self.active then

        local teamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
        local origin = self:GetOrigin()    
        local detectables = GetEntitiesWithMixinForTeamWithinRange("ParasiteAble", teamNumber, origin, range)
        
        for index, detectable in ipairs(detectables) do
        
            // Mark them as detected, run seperate detections for aura/recon
            if not self.IsValidDetection or self:IsValidDetection(detectable, false) then
                detectable:SetParasited(self, 1, false)
            end
        
        end
        
    end
    
    range = self:GetDetectionRange(true)
    
    if range > 0 and self.active then

        local teamNumber = GetEnemyTeamNumber(self:GetTeamNumber())
        local origin = self:GetOrigin()    
        local detectables = GetEntitiesWithMixinForTeamWithinRange("ParasiteAble", teamNumber, origin, range)
        
        for index, detectable in ipairs(detectables) do
        
            // Mark them as detected, run seperate detections for aura/recon
            if not self.IsValidDetection or self:IsValidDetection(detectable, true) then
                detectable:SetParasited(self, 1, false)
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
            if self.OnCheckDetectorActive then
                self.active = self:OnCheckDetectorActive(false) or self:OnCheckDetectorActive(true)
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

