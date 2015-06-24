// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\DevourMixin.lua
// - Dragon

DevouredMixin = CreateMixin( DevouredMixin )
DevouredMixin.type = "Devourable"

DevouredMixin.expectedMixins =
{
    Live = "Cant eat whats not alive"
}

DevouredMixin.networkVars =
{
    devoured = "boolean"
}

function DevouredMixin:__initmixin()   
end

function DevouredMixin:OnDevoured(onos)

    self.devourer = onos:GetId()
    self.devoured = true
    self.lastdevoursound = 0
    self:SetPropagate(Entity.Propagate_Never)
    //self:DestroyController()
    
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
        self:SetPropagate(Entity.Propagate_Mask)
        //One day I will get this to work for the cleanest handling :L
        //self:CreateController(self:GetPlayerControllersGroup())
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
            self.lastorigin = onos:GetOrigin()
        end
    end
end

function DevouredMixin:OnUpdate(deltaTime)
    DevouredMixinUpdate(self, deltaTime)
end

function DevouredMixin:OnProcessMove(input)
    DevouredMixinUpdate(self, input.time)
end