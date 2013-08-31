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
    self.devoured = true
    self.lastdevoursound = 0
    self:SetPropagate(Entity.Propagate_Never)
    
    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon then
        activeWeapon:OnPrimaryAttackEnd(self)
        activeWeapon:OnSecondaryAttackEnd(self)
        if activeWeapon.reloading then 
            activeWeapon.reloading = false
            activeWeapon:TriggerEffects("reload_cancel")
        end
    end
end

function DevouredMixin:OnDevouredEnd()
    if self:GetIsAlive() then
        self.devoured = false
        self.devourer = nil
        self:SetPropagate(Entity.Propagate_Mask)
    end
end

function DevouredMixin:GetIsDevoured()
    return self.devoured
end

local function DevouredMixinUpdate(self, deltaTime)
    if self:GetIsDevoured() then
        local onos = self.devourer and Shared.GetEntity(self.devourer)
        if onos and onos:isa("Onos") and onos:GetIsAlive() then
            local coords = onos:GetCoords()
            if coords ~= nil and coords.origin ~= nil then
                self:SetCoords(coords)  
            end
        end
    end
end

function DevouredMixin:OnUpdate(deltaTime)
    DevouredMixinUpdate(self, deltaTime)
end

function DevouredMixin:OnProcessMove(input)
    DevouredMixinUpdate(self, input.time)
end