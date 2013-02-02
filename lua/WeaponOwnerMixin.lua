// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\WeaponOwnerMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

WeaponOwnerMixin = CreateMixin( WeaponOwnerMixin )
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
    weaponsWeight = "float (0 to " .. WeaponOwnerMixin.kMaxWeaponsWeight .. " by 0.01)"
}

function WeaponOwnerMixin:__initmixin()

    self.processMove = true
    self.activeWeaponId = Entity.invalidId
    self.timeOfLastWeaponSwitch = 0
    self.weaponsWeight = 0
    
end

function WeaponOwnerMixin:GetWeaponsWeight()
    return self.weaponsWeight
end

local function UpdateWeaponsWeight(self)

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

function WeaponOwnerMixin:UpdateWeaponWeights()
    UpdateWeaponsWeight(self)
end
AddFunctionContract(WeaponOwnerMixin.UpdateWeaponWeights, { Arguments = { "Entity" }, Returns = { } })

function WeaponOwnerMixin:SetWeaponsProcessMove(processMove)
    self.processMove = processMove
end
AddFunctionContract(WeaponOwnerMixin.SetWeaponsProcessMove, { Arguments = { "Entity", "boolean" }, Returns = { } })

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
AddFunctionContract(WeaponOwnerMixin.ProcessMoveOnWeapons, { Arguments = { "Entity", "Move" }, Returns = { } })

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
AddFunctionContract(WeaponOwnerMixin.GetHUDOrderedWeaponList, { Arguments = { "Entity" }, Returns = { "table" } })

// Returns true if we switched to weapon or if weapon is already active. Returns false if we 
// don't have that weapon.
function WeaponOwnerMixin:SetActiveWeapon(weaponMapName)

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
                
            end
            
            // Set active first so proper anim plays
            self.activeWeaponId = newWeapon:GetId()
            
            newWeapon:OnDraw(self, previousWeaponName)
            
            self.timeOfLastWeaponSwitch = Shared.GetTime()
            
            UpdateWeaponsWeight(self)
            
            return true
            
        end
        
    end
    
    local activeWeapon = self:GetActiveWeapon()
    if activeWeapon ~= nil and activeWeapon:GetMapName() == weaponMapName then
    
        UpdateWeaponsWeight(self)
        return true
        
    end
    
    Print("%s:SetActiveWeapon(%s) failed", self:GetClassName(), weaponMapName or "No Weapon")
    
    UpdateWeaponsWeight(self)
    
    return false

end
AddFunctionContract(WeaponOwnerMixin.SetActiveWeapon, { Arguments = { "Entity", "string" }, Returns = { "boolean" } })

function WeaponOwnerMixin:GetActiveWeapon()
    return Shared.GetEntity(self.activeWeaponId)
end
AddFunctionContract(WeaponOwnerMixin.GetActiveWeapon, { Arguments = { "Entity" }, Returns = { { "Weapon", "nil" } } })

function WeaponOwnerMixin:GetTimeOfLastWeaponSwitch()
    return self.timeOfLastWeaponSwitch
end
AddFunctionContract(WeaponOwnerMixin.GetTimeOfLastWeaponSwitch, { Arguments = { "Entity" }, Returns = { "number" } })

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
AddFunctionContract(WeaponOwnerMixin.SwitchWeapon, { Arguments = { "Entity", "number" }, Returns = { "boolean" } })

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
AddFunctionContract(WeaponOwnerMixin.SelectNextWeaponInDirection, { Arguments = { "Entity", "number" }, Returns = { } })

function WeaponOwnerMixin:GetActiveWeaponName()

    local activeWeaponName = ""
    local activeWeapon = self:GetActiveWeapon()
    
    if activeWeapon ~= nil then
        activeWeaponName = activeWeapon:GetClassName()
    end
    
    return activeWeaponName
    
end
AddFunctionContract(WeaponOwnerMixin.GetActiveWeaponName, { Arguments = { "Entity" }, Returns = { "string" } })

function WeaponOwnerMixin:GetActiveWeaponId()

    local activeWeaponId = nil
    local activeWeapon = self:GetActiveWeapon()
    
    if activeWeapon ~= nil then
        activeWeaponId = activeWeapon:GetId()
    end
    
    return activeWeaponId
    
end
AddFunctionContract(WeaponOwnerMixin.GetActiveWeaponId, { Arguments = { "Entity" }, Returns = { "number" } })

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
AddFunctionContract(WeaponOwnerMixin.GetWeapon, { Arguments = { "Entity", "string" }, Returns = { { "Weapon", "nil" } } })

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
AddFunctionContract(WeaponOwnerMixin.GetWeaponInHUDSlot, { Arguments = { "Entity", "number" }, Returns = { { "Weapon", "nil" } } })

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
        UpdateWeaponsWeight(self)
        
    end
    
    if self.OnWeaponAdded then
        self:OnWeaponAdded(weapon)
    end
    
end
AddFunctionContract(WeaponOwnerMixin.AddWeapon, { Arguments = { "Entity", "Weapon", "boolean" }, Returns = { } })

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
    
    UpdateWeaponsWeight(self)
    
end
AddFunctionContract(WeaponOwnerMixin.RemoveWeapon, { Arguments = { "Entity", "Weapon" }, Returns = { } })

function WeaponOwnerMixin:DestroyWeapons()

    self.activeWeaponId = Entity.invalidId
    
    local allWeapons = { }
    for i = 0, self:GetNumChildren() - 1 do
    
        local child = self:GetChildAtIndex(i)
        if child:isa("Weapon") then
            table.insert(allWeapons, child)
        end
        
    end
    
    for i, weapon in ipairs(allWeapons) do
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
            
            self:GetActiveWeapon():OnDrawClient()
            
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