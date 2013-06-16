// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\EmpowerMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

/**
 * EmpowerMixin speeds up attack speed on nearby players.
 */
EmpowerMixin = CreateMixin(EmpowerMixin)
EmpowerMixin.type = "Empower"

EmpowerMixin.kSegment1Cinematic = PrecacheAsset("cinematics/alien/crag/umbraTrail1.cinematic")
EmpowerMixin.kSegment2Cinematic = PrecacheAsset("cinematics/alien/crag/umbraTrail2.cinematic")
EmpowerMixin.kViewModelCinematic = PrecacheAsset("cinematics/alien/crag/umbra_1p.cinematic")

EmpowerMixin.expectedMixins =
{
    GameEffects = "Required to track energize state",
}

EmpowerMixin.networkVars =
{
    empowered = "private boolean"
}

function EmpowerMixin:__initmixin()

    self.empowered = false

    if Server then
        self.empowerGiveTime = 0
        self.timeLastEmpowerUpdate = 0
    end    
end

if Server then

    function EmpowerMixin:Empower()
        
        self.empowered = true
        self.empowerGiveTime = Shared.GetTime() + 1
    
    end

end

local function SharedUpdate(self, deltaTime)

    if Server then         
        self.empowered = self.empowerGiveTime - Shared.GetTime() > 0
    elseif Client then

        if self:GetGameEffectMask(kGameEffect.Fury) and (not HasMixin(self, "Cloakable") or not self:GetIsCloaked() ) then
        
            if (not self.timeLastEmpowerEffect or self.timeLastEmpowerEffect + 2 < Shared.GetTime()) then
                self:TriggerEffects("empower")
                self.timeLastEmpowerEffect = Shared.GetTime() 
            end
            
        end
    
    end
    
end

function EmpowerMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end

function EmpowerMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end

function EmpowerMixin:GetIsEmpowered()
    return self.empowered
end