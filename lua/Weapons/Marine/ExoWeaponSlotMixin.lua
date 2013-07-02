// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Weapons\Marine\ExoWeaponSlotMixin.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

ExoWeaponSlotMixin = CreateMixin(ExoWeaponSlotMixin)
ExoWeaponSlotMixin.type = "ExoWeaponSlot"

ExoWeaponSlotMixin.networkVars =
{
    exoWeaponSlot = "enum ExoWeaponHolder.kSlotNames"
}

ExoWeaponSlotMixin.optionalCallbacks =
{
    OnWeaponSlotAssigned = "Call after SetExoWeaponSlot() is called"
}

function ExoWeaponSlotMixin:__initmixin()
    self.exoWeaponSlot = ExoWeaponHolder.kSlotNames.Left
end

function ExoWeaponSlotMixin:SetExoWeaponSlot(slot)

    assert(Server)
    
    self.exoWeaponSlot = slot
    
    if self.OnWeaponSlotAssigned then
        self:OnWeaponSlotAssigned(slot)
    end
    
end

function ExoWeaponSlotMixin:GetExoWeaponSlotName()
    return string.lower(EnumToString(ExoWeaponHolder.kSlotNames, self.exoWeaponSlot))
end

function ExoWeaponSlotMixin:GetIsLeftSlot()
    return self.exoWeaponSlot == ExoWeaponHolder.kSlotNames.Left
end

function ExoWeaponSlotMixin:GetIsRightSlot()
    return self.exoWeaponSlot == ExoWeaponHolder.kSlotNames.Right
end

function ExoWeaponSlotMixin:GetExoWeaponSlot()
    return self.exoWeaponSlot
end