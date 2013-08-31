// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\WeaponOwnerMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

WeaponOwnerMixin = CreateMixin(WeaponOwnerMixin)
WeaponOwnerMixin.type = "WeaponOwner"

WeaponOwnerMixin.optionalCallbacks =
{
    OnWeaponAdded = "Will be called right after a weapon is added with the weapon as the only parameter."
}

WeaponOwnerMixin.expectedCallbacks =
{
    Drop = "Called when new weapon takes current weapon's slot."
}

WeaponOwnerMixin.expectedConstants =
{
    kStowedWeaponWeightScalar = "How much a stowed weapon influences the total weight."
}

// lets assume you can't carry more than 20 rifles in weight. Seems reasonable
WeaponOwnerMixin.kMaxWeaponsWeight = 20 * kRifleWeight

WeaponOwnerMixin.networkVars =
{
    processMove = "boolean",
    activeWeaponId = "entityid",
    timeOfLastWeaponSwitch = "time",
    weaponsWeight = "float (0 to " .. WeaponOwnerMixin.kMaxWeaponsWeight .. " by 0.01)",
    quickSwitchSlot = "integer (0 to 10)"
}

function WeaponOwnerMixin:__initmixin()

    self.processMove = true
    self.activeWeaponId = Entity.invalidId
    self.timeOfLastWeaponSwitch = 0
    self.weaponsWeight = 0
    self.quickSwitchSlot = 1
    
end

function WeaponOwnerMixin:GetWeaponsWeight()
    return self.weaponsWeight
end

function WeaponOwnerMixin:GetWeapons()

    local weapons = {}

    for i = 0, self:GetNumChildren() - 1 do
    
        local child = self:GetChildAtIndex(i)
        if child:isa("Weapon") then
        
            table.insert(weapons, child)
            
        end
    
    end
    
    return weapons

end

//NS2c
//Changed to global as weapons will now call this also.
function WeaponOwnerMixin:UpdateWeaponWeights()

    // Loop through all weapons, getting weight of each one
    local totalWeight = 0
    
    local activeWeapon = self:GetActiveWeapon()
    for i = 0, self:GetNumChildren() - 1 do
    
        local child = self:GetChildAtIndex(i)
        if child:isa("Weapon") then
        
            // Active items count full, count less when stowed.
            local weaponIsActive = activeWeapon and (child:GetId() == activeWeapon:GetId())
            local weaponWeight = (weaponIsActive and child:GetWeight()) or (child:GetWeight() * self:GetMixinConstants().kStowedWeaponWeightScalar)
            totalWeight = totalWeight + weaponWeight
            
        end
    
    end
    
    self.weaponsWeight = Clamp(totalWeight, 0, 1)

end

function WeaponOwnerMixin:SetWeaponsProcessMove(processMove)
    self.processMove = processMove
end

function WeaponOwnerMixin:ProcessMoveOnWeapons(input)

    // Don't update weapon if set to false (commander mode).
    if self.processMove then
        
        // Call ProcessMove on only the active weapon.
        local activeWeapon = self:GetActiveWeapon()
        if activeWeapon then
        
            if activeWeapon.ProcessMoveOnWeapon then
                activeWeapon:ProcessMoveOnWeapon(self, input)
            end
            
            activeWeapon:ProcessMoveOnModel(input)
            
        end
        
    end
    
end

/**
 * Sorter used in WeaponOwnerMixin:GetHUDOrderedWeaponList().
 */
local function WeaponSorter(weapon1, weapon2)
    return weapon2:GetHUDSlot() > weapon1:GetHUDSlot()
end

function WeaponOwnerMixin:GetHUDOrderedWeaponList()

    PROFILE("WeaponOwnerMixin:GetHUDOrderedWeaponList")
    
    local hudOrderedWeaponList = { }
    for i = 0, self:GetNumChildren() - 1 do
    
        local child = self:GetChildAtIndex(i)
        if child:isa("Weapon") and child:GetHUDSlot() ~= kNoWeaponSlot then
            table.insert(hudOrderedWeaponList, child)
        end
        
    end
    
    table.sort(hudOrderedWeaponList, WeaponSorter)
    
    return hudOrderedWeaponList
    
end

// Returns true if we switched to weapon or if weapon is already active. Returns false if we 
// don't have that weapon.
function WeaponOwnerMixin:SetActiveWeapon(weaponMapName, keepQuickSwitchSlot)

    local foundWeapon = nil
    for i = 0, self:GetNumChildren() - 1 do
    
        local child = self:GetChildAtIndex(i)
        if child:isa("Weapon") and child:GetMapName() == weaponMapName then
        
            foundWeapon = child
            break
            
        end
        
    end
    
    if foundWeapon then
        
        local newWeapon = foundWeapon
        
        if newWeapon.OnSetActive then
            newWeapon:OnSetActive()
        end
        
        local activeWeapon = self:GetActiveWeapon()
        
        if activeWeapon == nil or activeWeapon:GetMapName() ~= weaponMapName then
        
            local previousWeaponName = ""
            
            if activeWeapon then
            
                activeWeapon:OnHolster(self)
                activeWeapon:SetIsVisible(false)
                previousWeaponName = activeWeapon:GetMapName()
                local hudSlot = activeWeapon:GetHUDSlot()

                if keepQuickSwitchSlot == nil then
                    keepQuickSwitchSlot = false
                end

                if hudSlot > 0 and not keepQuickSwitchSlot then
                    //DebugPrint("setting prev hud slot to %d, %s", hudSlot, Script.CallStack())
                    self.quickSwitchSlot = hudSlot
                end
                
            end
            
            // Set active first so proper anim plays
            self.activeWeaponId = newWeapon:GetId()
            
            newWeapon:OnDraw(self, previousWeaponName)
            
            self.timeOfLastWeaponSwitch = Shared.GetTime()
            
            self:UpdateWeaponWeights()
            
            return true
            
        end
        
    end
    
    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon ~= nil and activeWeapon:GetMapName() == weaponMapName then
    
        self:UpdateWeaponWeights()
        return true
        
    end
    
    Print("%s:SetActiveWeapon(%s) failed", self:GetClassName(), weaponMapName or "No Weapon")
    
    self:UpdateWeaponWeights()
    
    return false

end

function WeaponOwnerMixin:SetQuickSwitchTarget(weaponMapName)

    for i = 0, self:GetNumChildren() - 1 do
    
        local child = self:GetChildAtIndex(i)
        if child:isa("Weapon") and child:GetMapName() == weaponMapName then

            self.quickSwitchSlot = child:GetHUDSlot()
            return
            
        end
        
    end

    Print("ERROR: Could not find weapon %s", weaponMapName)

end

function WeaponOwnerMixin:QuickSwitchWeapon()
    //DebugPrint("switching to hud slot %d", self.quickSwitchSlot)
    self:SwitchWeapon(self.quickSwitchSlot)
end

function WeaponOwnerMixin:GetActiveWeapon()
    return (Shared.GetEntity(self.activeWeaponId))
end

function WeaponOwnerMixin:GetTimeOfLastWeaponSwitch()
    return self.timeOfLastWeaponSwitch
end

function WeaponOwnerMixin:SwitchWeapon(hudSlot)

    local success = false
    
    local foundWeapon = nil
    for i = 0, self:GetNumChildren() - 1 do
    
        local child = self:GetChildAtIndex(i)
    
        if child:isa("Weapon") and child:GetHUDSlot() == hudSlot then
        
            foundWeapon = child
            break
            
        end
        
    end
    
    if foundWeapon then
        success = self:SetActiveWeapon(foundWeapon:GetMapName())
    end
    
    return success
    
end

function WeaponOwnerMixin:SelectNextWeaponInDirection(direction)

    local weaponList = self:GetHUDOrderedWeaponList()
    local activeWeapon = self:GetActiveWeapon()
    local activeIndex = 1
    for i, weapon in ipairs(weaponList) do
    
        if weapon == activeWeapon then
        
            activeIndex = i
            break
            
        end
        
    end
    
    local numWeapons = table.count(weaponList)
    if numWeapons > 0 then
    
        local newIndex = activeIndex + direction
        // Handle wrap around.
        if newIndex > numWeapons then
            newIndex = 1
        elseif newIndex < 1 then
            newIndex = numWeapons
        end
        
        self:SetActiveWeapon(weaponList[newIndex]:GetMapName())
        
    end
    
end

function WeaponOwnerMixin:GetActiveWeaponName()

    local activeWeaponName = ""
    local activeWeapon = self:GetActiveWeapon()
    
    if activeWeapon ~= nil then
        activeWeaponName = activeWeapon:GetClassName()
    end
    
    return activeWeaponName
    
end

function WeaponOwnerMixin:GetActiveWeaponId()
    return self.activeWeaponId
end

/**
 * Checks to see if self already has a weapon with the passed in map name.
 * Returns this weapon if it exists, nil otherwise.
 */
function WeaponOwnerMixin:GetWeapon(weaponMapName)

    local found = nil
    for i = 0, self:GetNumChildren() - 1 do
    
        local child = self:GetChildAtIndex(i)
    
        if child:isa("Weapon") and child:GetMapName() == weaponMapName then
        
            found = child
            break
            
        end
    
    end
    
    return found

end

/**
 * Checks to see if self already has a weapon in the passed in HUD slot.
 * Returns this weapon if it exists, nil otherwise.
 */
function WeaponOwnerMixin:GetWeaponInHUDSlot(slot)

    for i = 0, self:GetNumChildren() - 1 do
    
        local child = self:GetChildAtIndex(i)
        
        if child:isa("Weapon") and child:GetHUDSlot() == slot then
            return child
        end
    
    end
    
    return nil
    
end

function WeaponOwnerMixin:SetHUDSlotActive(slot)

    local weapon = self:GetWeaponInHUDSlot(slot)
    if weapon then
        self:SetActiveWeapon(weapon:GetMapName())
    else
    
        local orderedList = self:GetHUDOrderedWeaponList()
        if #orderedList > 0 then
            self:SetActiveWeapon(orderedList[1]:GetMapName())
        end
        
    end

end

function WeaponOwnerMixin:AddWeapon(weapon, setActive)

    assert(weapon:GetParent() ~= self)

    // Remove any existing weapon that shares the HUD slot to the
    // incoming weapon.
    local hasWeapon = self:GetWeaponInHUDSlot(weapon:GetHUDSlot())
    if hasWeapon then
    
        local success = self:Drop(hasWeapon, true, true)
        assert(success == true)
        
    end
    
    assert(self:GetWeaponInHUDSlot(weapon:GetHUDSlot()) == nil)

    weapon:SetParent(self)
    weapon:SetOrigin(Vector.origin)
    
    // The weapon no longer belongs to the world once a weapon owner has it.
    if Server then
        weapon:SetWeaponWorldState(false)
    end
    
    if setActive then
    
        local oldWeapon = self:GetActiveWeapon()
        if oldWeapon then
            oldWeapon:OnHolster(self)
        end
    
        self:SetActiveWeapon(weapon:GetMapName())
        
    else
    
        // SetActiveWeapon() will update the weight but
        // it must be manually called if SetActiveWeapon is not called.
        self:UpdateWeaponWeights()
        
    end
    
    if self.OnWeaponAdded then
        self:OnWeaponAdded(weapon)
    end
    
    return hasWeapon
    
end

function WeaponOwnerMixin:RemoveWeapon(weapon)

    assert(weapon:GetParent() == self)
    
    // Switch weapons if we're dropping our current weapon
    local activeWeapon = self:GetActiveWeapon()
    local removingActive = weapon == activeWeapon
    
    weapon:SetParent(nil)
    
    if removingActive then
    
        self.activeWeaponId = Entity.invalidId
        self:SelectNextWeaponInDirection(1)
        
    end
    
    self:UpdateWeaponWeights()
    
end

function WeaponOwnerMixin:DestroyWeapons()

    self.activeWeaponId = Entity.invalidId

    for i, weapon in ipairs(self:GetWeapons()) do
        DestroyEntity(weapon)
    end

end

function WeaponOwnerMixin:UpdateClientEffects(deltaTime, isLocal)

    if not self.lastActiveWeaponId then
        self.lastActiveWeaponId =  self:GetActiveWeaponId()
    end
    
    local activeWeaponId = self:GetActiveWeaponId()
    if activeWeaponId ~= self.lastActiveWeaponId then
    
        if activeWeaponId and self.lastActiveWeaponId ~= Entity.invalidId then
        
            local weapon = Shared.GetEntity(self.lastActiveWeaponId)
            if weapon then
                weapon:OnHolsterClient(self)
            end
            
            local activeWeapon = self:GetActiveWeapon()
            if activeWeapon then
                activeWeapon:OnDrawClient()
            end    
            
        end
        
        self.lastActiveWeaponId = activeWeaponId
        
    end
    
end

function WeaponOwnerMixin:OnDestroy()

    if Client then
    
        local activeWeapon = self:GetActiveWeapon()
        if activeWeapon then
            activeWeapon:OnHolsterClient()
        end
    
    end

end
