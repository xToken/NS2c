// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\PickupableWeaponMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

//NS2c
//Changed to offer automatic pickup of weapons, currently disabled.

PickupableWeaponMixin = CreateMixin( PickupableWeaponMixin )
PickupableWeaponMixin.type = "Pickupable"

local kCheckForPickupRate = 1
local kPickupRange = 2

PickupableWeaponMixin.expectedCallbacks =
{
    GetParent = "Returns the parent entity of this pickupable."
}

PickupableWeaponMixin.networkVars =
{
    droppedtime = "private time"
}

function PickupableWeaponMixin:__initmixin()

   if Server then
        if not self.GetCheckForRecipient or self:GetCheckForRecipient() then
            self:AddTimedCallback(PickupableMixin._CheckForPickup, kCheckForPickupRate)
        end
   end
   self.droppedtime = 0
   
end

function PickupableWeaponMixin:RestartPickupScan()

   if Server then
        if not self.GetCheckForRecipient or self:GetCheckForRecipient() then
            self:AddTimedCallback(PickupableMixin._CheckForPickup, kCheckForPickupRate)
        end
   end
   
end

function PickupableWeaponMixin:_GetNearbyRecipient()

    local potentialRecipients = GetEntitiesWithinRange("Marine", self:GetOrigin(), kPickupRange)
    
    for index, recipient in pairs(potentialRecipients) do
    
        if recipient:GetIsAlive() and self:GetIsValidRecipient(recipient, true) then
            return recipient
        end
        
    end
    
    return nil
    
end

function PickupableMixin:_CheckForPickup()

    assert(Server)
    
    if self:GetParent() ~= nil then
        return false
    end
    
    // Scan for nearby friendly players that need medpacks because we don't have collision detection yet
    local player = self:_GetNearbyRecipient()

    if player ~= nil then
    
        if self:OnTouch(player) then
            DestroyEntity(self)
        end
        return false
        
    end
    
    // Continue the callback.
    return true
    
end

function PickupableWeaponMixin:GetIsValidRecipient(player, autoscan)
    if not autoscan then
        return self:GetParent() == nil  and self.weaponWorldState == true    
    end
    if player then
        local hasWeapon = player:GetWeaponInHUDSlot(self:GetHUDSlot())
        if not hasWeapon and self.weaponWorldState == true and self.droppedtime + kPickupWeaponTimeLimit < Shared.GetTime() then
            return true
        end
    end
    return false
end

function PickupableWeaponMixin:OnUpdate(deltaTime)

    if Client then
        EquipmentOutline_UpdateModel(self)
    end
    
end

function PickupableWeaponMixin:OnProcessMove(input)

    if Client then
        EquipmentOutline_UpdateModel(self)
    end
    
end