// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\WebableMixin.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

WebableMixin = CreateMixin( WebableMixin )
WebableMixin.type = "Webable"

WebableMixin.optionalCallbacks =
{
    OnWebbed = "Called when entity is being webbed.",
    OnWebbedEnd = "Called when entity leaves webbed state."
}

WebableMixin.networkVars =
{
    webbed = "boolean"
}

function WebableMixin:__initmixin()

    if Server then
        self.webbed = false
        self.timeWebEnds = 0
    end
    
end

function WebableMixin:GetIsWebbed()
    return self.webbed
end    

function WebableMixin:SetWebbed(duration)
    
    if Server then
    
        self.timeWebEnds = Shared.GetTime() + duration
        if not self.webbed and self.OnWebbed then
            self:OnWebbed()
        end

        self.webbed = true
        
        if self:isa("Player") then
            self:AddSlowScalar(0.8)
        end
        self:TriggerEffects("web_clear")
        
    end
    
end

if Server then

    local function SharedUpdate(self, deltaTime)
    
        local wasWebbed = self.webbed
        self.webbed = self.timeWebEnds > Shared.GetTime()
        
        if wasWebbed and not self.webbed and self.OnWebbedEnd then
            self:OnWebbedEnd()
        end
        
    end

    function WebableMixin:OnUpdate(deltaTime)
        SharedUpdate(self, deltatime)
    end
    
    function WebableMixin:OnProcessMove(input)
        SharedUpdate(self, input.time)
    end

end

function WebableMixin:OnUpdateAnimationInput(modelMixin)
    modelMixin:SetAnimationInput("webbed", self.webbed)
end

function WebableMixin:OnUpdateRender()

    // TODO: custom material?

end
