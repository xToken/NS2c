// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\UpgradableMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

/**
 * UpgradableMixin handles two forms of upgrades. There are the upgrades that it owns (upgrade1 - upgrade4).
 * It can also handle upgrading the entire entity to another tech Id independent of the upgrades it owns.
 */
 
local kMaxUpgrades = math.max(kCombatMaxLevel + 2, 8)
 
UpgradableMixin = CreateMixin(UpgradableMixin)
UpgradableMixin.type = "Upgradable"

UpgradableMixin.expectedCallbacks =
{
    SetTechId = "Sets the current tech Id of this entity.",
    GetTechId = "Returns the current tech Id of this entity."
}

UpgradableMixin.optionalCallbacks =
{
    OnPreUpgradeToTechId = "Called right before upgrading to a new tech Id.",
    OnGiveUpgrade = "Called to notify that an upgrade was given with the tech Id as the single parameter."
}

UpgradableMixin.networkVars = { }

for i = 1 , kMaxUpgrades do
    UpgradableMixin.networkVars["upgrade" .. i] = "enum kTechId"
end

function UpgradableMixin:__initmixin()

    for i = 1 , kMaxUpgrades do
        self["upgrade" .. i] = kTechId.None
    end
    
end

function UpgradableMixin:GetHasUpgrade(techId)
    
    if techId == kTechId.None then 
        return false
    end
    
    local hasupgrade
    for i = 1 , kMaxUpgrades do
        if techId == self["upgrade" .. i] then
            hasupgrade = true
            break
        end
    end
    
    return hasupgrade 
    
end

function UpgradableMixin:GetUpgradeList()

    local list = { }
    
    for i = 1 , kMaxUpgrades do
    
        local upgrade = self["upgrade" .. i]
        local techTree = GetTechTree(self:GetTeamNumber())
        
        if self:GetGameMode() == kGameMode.Combat then
            if upgrade ~= kTechId.None and GetUpgradeAvailable(upgrade, self) then
                table.insert(list, upgrade)
            end
        elseif self:GetGameMode() == kGameMode.Classic then
            if upgrade ~= kTechId.None and ( techTree and techTree:GetIsTechAvailable(upgrade) ) then
                table.insert(list, upgrade)
            end
        end
        
    end
    
    return list
    
end

function UpgradableMixin:GetUpgradeListName()

    local list = self:GetUpgradeList()
    local listName = { }
    
    for i, id in ipairs(list) do
        table.insert(listName, kTechId[id])
    end
    
    return listName
    
end

function UpgradableMixin:GetUpgrades()

    local upgrades = { }
    
    for i = 1 , kMaxUpgrades do
        if self["upgrade" .. i] ~= kTechId.None then
            table.insert(upgrades, self["upgrade" .. i])
        end
    end
    
    return upgrades
    
end

function UpgradableMixin:GiveUpgrade(techId) 

    local upgradeGiven = false
    
    if not self:GetHasUpgrade(techId) then
    
        for i = 1 , kMaxUpgrades do
            if self["upgrade" .. i] == kTechId.None then
                self["upgrade" .. i] = techId
                upgradeGiven = true
                break
            end
        end
        
        assert(upgradeGiven, "Entity already has the max of " .. kMaxUpgrades .. " upgrades.")
        
    end
    
    if upgradeGiven and self.OnGiveUpgrade then
        self:OnGiveUpgrade(techId)
    end
    
    return upgradeGiven
    
end

function UpgradableMixin:RemoveUpgrade(techId)

    local removed = false
    
    if self:GetHasUpgrade(techId) then
    
        for i = 1 , kMaxUpgrades do
            if self["upgrade" .. i] == techId then
                self["upgrade" .. i] = kTechId.None
                removed = true
            end
        end
        
    end
    
    return removed
    
end

function UpgradableMixin:Reset()
    self:ClearUpgrades()
end

function UpgradableMixin:OnKill()
    if self:GetGameMode() == kGameMode.Classic then
        self:ClearUpgrades()
    end
end

function UpgradableMixin:CopyUpgradesFromOldPlayer(player)
    for i = 1 , kMaxUpgrades do
        self["upgrade" .. i] = player["upgrade" .. i]
    end
end

function UpgradableMixin:ClearUpgrades()
    for i = 1 , kMaxUpgrades do
        self["upgrade" .. i] = kTechId.None
    end
end

//Moving upgrade logic in here, tired of functions being in 5 different files

function BuyMenus_GetUpgradeCost(techId)
    if techId ~= nil then
        return LookupTechData(techId, kTechDataCostKey, 0)
    else
        return 0
    end
end

function GetUpgradeAvailable(techId, player)
    local techNode = GetTechTree(player:GetTeamNumber()):GetTechNode(techId)
    if techNode ~= nil then
        local prereq1 = techNode:GetPrereq1()
        local prereq2 = techNode:GetPrereq2()
    
        return (prereq1 == kTechId.None or player:GetHasUpgrade(prereq1)) and (prereq2 == kTechId.None or player:GetHasUpgrade(prereq2))
    end
    
    return true
end

function BuyMenus_GetUpgradeAvailable(techId, player)
    return GetUpgradeAvailable(techId, Client.GetLocalPlayer())
end

function BuyMenus_GetUpgradePurchased(techId)
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetHasUpgrade(techId)
    end
end

function GetTechAvailable(techId, player)
    if player:GetGameMode() == kGameMode.Combat then
        return GetUpgradeAvailable(techId, player)
    end
    local techNode = GetTechTree(player:GetTeamNumber()):GetTechNode(techId)
    if techNode ~= nil then
        return techNode:GetAvailable(player, techId, false)
    end
    return true
end

function BuyMenus_GetTechAvailable(techId)
    return GetTechAvailable(techId, Client.GetLocalPlayer())
end

function BuyMenus_GetHasTech(techId)
    return GetHasTech(Client.GetLocalPlayer(), techId)
end

function GetCanAffordUpgrade(player, techId)
    local cost = LookupTechData(techId, kTechDataCostKey, 0)
    if player:GetPersonalResources() >= cost then
        return true
    end
    return false
end

function BuyMenus_GetCanAffordUpgrade(techId)
    return GetCanAffordUpgrade(Client.GetLocalPlayer(), techId)
end