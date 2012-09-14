// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\PickupableWeaponMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

/*
Script.Load("lua/FunctionContracts.lua")

PickupableWeaponMixin = CreateMixin( PickupableWeaponMixin )
PickupableWeaponMixin.type = "Pickupable"

local kCheckForPickupRate = 0.5
local kPickupRange = 1.5

PickupableWeaponMixin.expectedMixins =
{
    TimedCallback = "Needed for checking for nearby players and self destruction"
}

PickupableWeaponMixin.expectedCallbacks =
{
    GetParent = "Returns the parent entity of this pickupable.",
    OnTouch = "Called when a player is close enough for pick up with the player as the parameter",
    GetOrigin = "Returns the position of this pickupable item",
    GetIsValidRecipient = "Should return true if the passed in Entity can receive this pickup"
}

function PickupableWeaponMixin:__initmixin()

   if Server then
        if not self.GetCheckForRecipient or self:GetCheckForRecipient() then
            self:AddTimedCallback(PickupableMixin._CheckForPickup, kCheckForPickupRate)
        end
   end
   
end

function PickupableWeaponMixin:RestartPickupScan()

   if Server then
        if not self.GetCheckForRecipient or self:GetCheckForRecipient() then
            self:AddTimedCallback(PickupableMixin._CheckForPickup, kCheckForPickupRate)
        end
   end
   
end

function PickupableWeaponMixin:_GetNearbyRecipient()

    local potentialRecipients = GetEntitiesWithinRange(self:GetMixinConstants().kRecipientType, self:GetOrigin(), kPickupRange)
    
    for index, recipient in pairs(potentialRecipients) do
    
        if recipient:GetIsAlive() and self:GetIsValidRecipient(recipient) then
            return recipient
        end
        
    end
    
    return nil
    
end

function PickupableMixin:_CheckForPickup()

    assert(Server)
    
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

function PickupableWeaponMixin:GetIsValidRecipient(recipient)
    return self:GetParent() == nil
end

function PickupableWeaponMixin:OnUpdate(deltaTime)

    if Client then    
        EquipmentOutline_UpdateModel(self)    
    end

end

function PickupableWeaponMixin:OnUpdate(deltaTime)

    if Client then
        EquipmentOutline_UpdateModel(self)
    end
    
end
*/

Script.Load("lua/FunctionContracts.lua")

PickupableWeaponMixin = CreateMixin( PickupableWeaponMixin )
PickupableWeaponMixin.type = "Pickupable"

PickupableWeaponMixin.expectedCallbacks =
{
    GetParent = "Returns the parent entity of this pickupable."
}

function PickupableWeaponMixin:__initmixin()
end

function PickupableWeaponMixin:GetIsValidRecipient(recipient)
    return self:GetParent() == nil
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