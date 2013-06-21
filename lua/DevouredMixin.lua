// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\DevourMixin.lua    
//    
//    Created by:   Dragon
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

DevouredMixin = CreateMixin( DevouredMixin )
DevouredMixin.type = "Devourable"

DevouredMixin.expectedMixins =
{
    Live = "Cant eat whats not alive"
}

DevouredMixin.networkVars =
{
    devoured = "private boolean"
}

function DevouredMixin:__initmixin()   
end

function DevouredMixin:OnDevoured(onos)
    self.devourer = onos:GetId()
    self.prevModelName = self:GetModelName()
    self.prevAnimGraph = self:GetGraphName()
    self.devoured = true
    self:SetModel(nil)
    self:SetIsThirdPerson(4)
    self.lastdevoursound = 0
    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon then
        activeWeapon:OnPrimaryAttackEnd(self)
        activeWeapon:OnSecondaryAttackEnd(self)
    end
end

function DevouredMixin:OnDevouredEnd()
    if self:GetIsAlive() then
        self.devoured = false
        self.devourer = nil
        self:SetModel(self.prevModelName, self.prevAnimGraph)
        self:SetDesiredCamera(0.3, { move = true })
    end
end

function DevouredMixin:GetIsDevoured()
    return self.devoured
end

local function DevouredMixinUpdate(self, deltaTime)
    if self:GetIsDevoured() then
        local onos = self.devourer and Shared.GetEntity(self.devourer)
        if onos and onos:isa("Onos") then
            self:SetOrigin(onos:GetOrigin())
        end
    end
    return self:GetIsDevoured()
end

function DevouredMixin:OnUpdate(deltaTime)
    DevouredMixinUpdate(self, deltaTime)
end

function DevouredMixin:OnProcessMove(input)
    DevouredMixinUpdate(self, input.time)
end