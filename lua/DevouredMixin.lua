// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\DevourMixin.lua    
//    
//    Created by:   Dragon
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

DevouredMixin = CreateMixin( DevouredMixin )
DevouredMixin.type = "Devourable"

local kDevourUpdateTime = 0.1

DevouredMixin.expectedMixins =
{
    Live = "Cant eat whats not alive"
}

DevouredMixin.networkVars =
{
    devoured = "private boolean"
}

function DevouredMixin:__initmixin()

    if Server then
        self:AddTimedCallback(DevouredMixin.Update, kDevourUpdateTime)
    end
    
end

function DevouredMixin:OnDevoured(onos)
    self.devourer = onos:GetId()
    self.prevModelName = self:GetModelName()
    self.prevAnimGraph = self:GetGraphName()
    self.devoured = true
    self:SetModel(nil)
    //self:SetIsThirdPerson(4)

    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon then
        activeWeapon:OnPrimaryAttackEnd(self)
        activeWeapon:OnSecondaryAttackEnd(self)
    end
end
AddFunctionContract(DevouredMixin.OnDevoured, { Arguments = { "Entity", "number" }, Returns = { } })

function DevouredMixin:OnDevouredEnd()
    if self:GetIsAlive() then
        self.devoured = false
        self.devourer = nil
        self:SetModel(self.prevModelName, self.prevAnimGraph)
        //self:SetDesiredCamera(0.3, { move = true })
    end
end
AddFunctionContract(DevouredMixin.OnDevouredEnd, { Arguments = { "Entity" }, Returns = { } })

function DevouredMixin:GetIsDevoured()
    return self.devoured
end
AddFunctionContract(DevouredMixin.GetIsDevoured, { Arguments = { "Entity" }, Returns = { "boolean" } })

function DevouredMixin:Update()
    if self:GetIsDevoured() then
        local onos = self.devourer and Shared.GetEntity(self.devourer)
        if onos and onos:isa("Onos") then
            self:SetOrigin(onos:GetOrigin())
        end
    end
    return self:GetIsDevoured()
end