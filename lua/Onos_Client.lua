// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Onos_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Onos.kYStoopCameraOffset = 0.3

// Play footstep effects when moving
function Onos:UpdateClientEffects(deltaTime, isLocal)

    Alien.UpdateClientEffects(self, deltaTime, isLocal)

    if self:GetPlayFootsteps() then
        
        local velocityLength = self:GetVelocityLength()
        local footstepInterval = .8 - (velocityLength / self:GetMaxSpeed(true)) * .15
        
        if self.timeOfLastFootstep == nil or (Shared.GetTime() > (self.timeOfLastFootstep + footstepInterval)) then
        
            self:PlayFootstepEffects(velocityLength / 5)
            
            self.timeOfLastFootstep = Shared.GetTime()
            
        end
        
    end 
    
end

function Onos:GetIdleSoundName()
    return Onos.kLocalIdleSound
end

function Onos:PlayFootstepEffects(scalar)

    if not Shared.GetIsRunningPrediction() then

        scalar = ConditionalValue(scalar == nil, 1, scalar)
        
        self:TriggerFootstep()
        
    end
    
end

function Onos:OnJumpLandNonLocalClient()

    self:PlayFootstepEffects(3)
    
end

// Shake camera for nearby players
function Onos:_PlayFootstepShake(player, scalar)
        
end

function Onos:OnLocationChange(locationName)
    
end

function Onos:GetHeadAttachpointName()
    return "Onos_Head"
end
