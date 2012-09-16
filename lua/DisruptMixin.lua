// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\DisruptMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Used in combination with onos "stomp" ability.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

DisruptMixin = CreateMixin( DisruptMixin )
DisruptMixin.type = "Disruptable"

DisruptMixin.expectedCallbacks = {}

DisruptMixin.kDisruptEffectInterval = 1

DisruptMixin.optionalCallbacks =
{
    OnDisrupt = "Called when the entity is hit by stomp and was functional before.",
    OnDisruptEnd = "Called when disruption time is over.",
    GetOverrideMaxDisruptDuration = "Return a maximum disrupt duration",
    GetCanBeDisrupted = "Return false if it is not possible to be disrupted currently.",
    OnDisruptClient = "Called when the entity is hit by stomp and was functional before, client side.",
    OnDisruptEndClient = "Called when disruption time is over.",
}

DisruptMixin.networkVars =
{
    remainingDisruptDuration = "time"
}

function DisruptMixin:__initmixin()
    self.remainingDisruptDuration = 0
    
    if Client then
        self.disruptedClient = false
    end
end

function DisruptMixin:GetIsDisrupted()
    return self.remainingDisruptDuration ~= 0
end

function DisruptMixin:SetDisruptDuration(duration, force)

    if not force then
        if self.GetCanBeDisrupted and not self:GetCanBeDisrupted() then
            return
        end
    end
    if not self:GetIsDisrupted() and self.OnDisrupt then
        self:OnDisrupt(duration)
    end
    
    if self.GetOverrideMaxDisruptDuration and duration > self:GetOverrideMaxDisruptDuration() then
        self.remainingDisruptDuration = self:GetOverrideMaxDisruptDuration()
    else
        self.remainingDisruptDuration = duration
    end
    
end

function DisruptMixin:OnDisrupt()
    self:TriggerEffects("disrupt_start", {classname = self:GetClassName()})
end

function DisruptMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("DisruptMixin:OnUpdateAnimationInput")
    
    //modelMixin:SetAnimationInput("disrupt", self:GetIsDisrupted())
    
end

function DisruptMixin:UpdateDisruptClientEffects(deltaTime)

    if not self.timeLastDisruptEffect then
        self.timeLastDisruptEffect = Shared.GetTime()
    end
    
    if self.timeLastDisruptEffect + DisruptMixin.kDisruptEffectInterval < Shared.GetTime() then
    
        self:TriggerEffects("disrupt", {classname = self:GetClassName()})
        self.timeLastDisruptEffect = Shared.GetTime()
        
    end
    
end

local function SharedUpdate(self, deltaTime)

    if self:GetIsDisrupted() then
    
        self.remainingDisruptDuration = self.remainingDisruptDuration - deltaTime
        
        if self.remainingDisruptDuration < 0 then
        
            self.remainingDisruptDuration = 0
            
            if self.OnDisruptEnd then
                self:OnDisruptEnd()
            end
            
        end
        
        if Client then
            self:UpdateDisruptClientEffects(deltaTime)
            
            if self.disruptedClient ~= self:GetIsDisrupted() then
            
                if self:GetIsDisrupted() then
                    if self.OnDisruptClient then
                        self:OnDisruptClient()
                    end
                else
                    if self.OnDisruptEndClient then
                        self:OnDisruptEndClient()
                    end
                end
                
                self.disruptedClient = self:GetIsDisrupted()
            
            end
            
        end
        
    end
    
end

function DisruptMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end

function DisruptMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end