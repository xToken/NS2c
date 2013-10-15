// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PhaseGateUserMixin.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

PhaseGateUserMixin = CreateMixin( PhaseGateUserMixin )
PhaseGateUserMixin.type = "PhaseGateUser"

local kPhaseDelay = 2

PhaseGateUserMixin.networkVars =
{
    timeOfLastPhase = "private time"
}

local function SharedUpdate(self)

    if self:GetCanPhase() then

        for _, phaseGate in ipairs(GetEntitiesForTeamWithinRange("PhaseGate", self:GetTeamNumber(), self:GetOrigin(), 0.5)) do
        
            if phaseGate:GetIsDeployed() and GetIsUnitActive(phaseGate) and phaseGate:Phase(self) then

                self.timeOfLastPhase = Shared.GetTime()
                
                if Client then               
                    self.timeOfLastPhaseClient = Shared.GetTime()
                    local viewAngles = self:GetViewAngles()
                    Client.SetYaw(viewAngles.yaw)
                    Client.SetPitch(viewAngles.pitch)     
                end
                
                break
                
            end
        
        end
    
    end

end

function PhaseGateUserMixin:__initmixin()    
    self.timeOfLastPhase = 0    
end

function PhaseGateUserMixin:OnProcessMove(input)
    SharedUpdate(self)
end

// for non players
if Server then

    function PhaseGateUserMixin:OnUpdate(deltaTime)    
        SharedUpdate(self)
    end

end

function PhaseGateUserMixin:GetCanPhase()
    return self:GetIsAlive() and Shared.GetTime() > self.timeOfLastPhase + kPhaseDelay
end
