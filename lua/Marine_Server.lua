// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Marine_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kDieSoundName = PrecacheAsset("sound/NS2.fev/marine/common/death")
local kPlayerPhaseDelay = 2

local function UpdateUnitStatusPercentage(self, target)

    if HasMixin(target, "Construct") and not target:GetIsBuilt() then
        self:SetUnitStatusPercentage(target:GetBuiltFraction() * 100)
    elseif HasMixin(target, "Weldable") then
        self:SetUnitStatusPercentage(target:GetWeldPercentage() * 100)
    end

end

function Marine:OnConstructTarget(target)
    UpdateUnitStatusPercentage(self, target)
end

function Marine:OnWeldTarget(target)
    UpdateUnitStatusPercentage(self, target)
end

function Marine:SetUnitStatusPercentage(percentage)
    self.unitStatusPercentage = Clamp(math.round(percentage), 0, 100)
    self.timeLastUnitPercentageUpdate = Shared.GetTime()
end

function Marine:OnTakeDamage(damage, attacker, doer, point)
    
    if damage > 50 and (not self.timeLastDamageKnockback or self.timeLastDamageKnockback + 1 < Shared.GetTime()) then    
    
        self:AddPushImpulse(GetNormalizedVectorXZ(self:GetOrigin() - point) * damage * 0.025 * self:GetSlowSpeedModifier())
        self.timeLastDamageKnockback = Shared.GetTime()
        
    end
    
end

function Marine:GetDamagedAlertId()
    return kTechId.MarineAlertSoldierUnderAttack
end

function Marine:ApplyCatPack()

    self.catpackboost = true
    self.timeCatpackboost = Shared.GetTime()
    
end

function Marine:OnEntityChange(oldId, newId)

    Player.OnEntityChange(self, oldId, newId)
 
end

function Marine:InitWeapons()

    Player.InitWeapons(self)
    
    self:GiveItem(Rifle.kMapName)
    self:GiveItem(Pistol.kMapName)
    self:GiveItem(Axe.kMapName)
    self:GiveItem(Builder.kMapName)
    if GetHasTech(self, kTechId.HandGrenadesTech, true) then
        self:GiveItem(HandGrenades.kMapName)
    end
	self:SetQuickSwitchTarget(Pistol.kMapName)
    self:SetActiveWeapon(Rifle.kMapName)

end

local function GetHostSupportsTechId(host, techId)

    if Shared.GetCheatsEnabled() then
        return true
    end
    
    local techFound = false
    
    if host.GetItemList then
    
        for index, supportedTechId in ipairs(host:GetItemList()) do
        
            if supportedTechId == techId then
            
                techFound = true
                break
                
            end
            
        end
        
    end
    
    return techFound
    
end

local function PlayerIsFacingHostStructure(player, host)
    return true
end

function GetHostStructureFor(entity, techId)

    local hostStructures = {}
    table.copy(GetEntitiesForTeamWithinRange("Armory", entity:GetTeamNumber(), entity:GetOrigin(), Armory.kResupplyUseRange), hostStructures, true)
    table.copy(GetEntitiesForTeamWithinRange("PrototypeLab", entity:GetTeamNumber(), entity:GetOrigin(), PrototypeLab.kResupplyUseRange), hostStructures, true)
    
    if table.count(hostStructures) > 0 then
    
        for index, host in ipairs(hostStructures) do
        
            // check at first if the structure is hostign the techId:
            if GetHostSupportsTechId(host, techId) and PlayerIsFacingHostStructure(player, host) then
                return host
            end    
        
        end
            
    end
    
    return nil

end

function Marine:OnOverrideOrder(order)
    
    local orderTarget = nil
    
    if (order:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(order:GetParam())
    end
    
    // Default orders to unbuilt friendly structures should be construct orders
    if(order:GetType() == kTechId.Default and GetOrderTargetIsConstructTarget(order, self:GetTeamNumber())) then
    
        order:SetType(kTechId.Construct)
        
    elseif(order:GetType() == kTechId.Default and GetOrderTargetIsWeldTarget(order, self:GetTeamNumber())) and self:GetWeapon(Welder.kMapName) then
    
        order:SetType(kTechId.Weld)
        
    elseif order:GetType() == kTechId.Default and GetOrderTargetIsDefendTarget(order, self:GetTeamNumber()) then
    
        order:SetType(kTechId.Defend)

    // If target is enemy, attack it
    elseif (order:GetType() == kTechId.Default) and orderTarget ~= nil and HasMixin(orderTarget, "Live") and GetEnemyTeamNumber(self:GetTeamNumber()) == orderTarget:GetTeamNumber() and orderTarget:GetIsAlive() and (not HasMixin(orderTarget, "LOS") or orderTarget:GetIsSighted()) then
    
        order:SetType(kTechId.Attack)

    elseif order:GetType() == kTechId.Default then
        
        // Convert default order (right-click) to move order
        order:SetType(kTechId.Move)
        
    end
    
end

function Marine:AttemptToBuy(techIds)
    return false 
end

// special threatment for mines and welders
function Marine:GiveItem(itemMapName)

    local newItem = nil

    if itemMapName then
        
        local continue = true
        local setActive = true
        
        if itemMapName == Mines.kMapName then
        
            local mineWeapon = self:GetWeapon(Mines.kMapName)
            
            if mineWeapon then
                mineWeapon:Refill(kMineCount)
                continue = false
                setActive = false
            end
            
        end
        
        if itemMapName == Welder.kMapName then
        
            local hgWeapon = self:GetWeapon(HandGrenades.kMapName)
            
            if hgWeapon then
                self:RemoveWeapon(hgWeapon)
                DestroyEntity(hgWeapon)
                continue = true
            end
            
        end
        
        if continue == true then
            return Player.GiveItem(self, itemMapName, setActive)
        end
        
    end
    
    return newItem
    
end

function Marine:DropAllWeapons()

    local weaponSpawnCoords = self:GetAttachPointCoords(Weapon.kHumanAttachPoint)
    local weaponList = self:GetHUDOrderedWeaponList()
    for w = 1, #weaponList do
    
        local weapon = weaponList[w]
        if weapon:GetIsDroppable() and LookupTechData(weapon:GetTechId(), kTechDataCostKey, 0) > 0 then
            self:Drop(weapon, true, true)
        end
        
    end
    
end

function Marine:OnKill(attacker, doer, point, direction)

    // drop all weapons which cost resources
    self:DropAllWeapons()

    // destroy remaining weapons
    self:DestroyWeapons()
    
    Player.OnKill(self, attacker, doer, point, direction)
    self:PlaySound(kDieSoundName)
    
    // Don't play alert if we suicide
    if attacker ~= self then
        self:GetTeam():TriggerAlert(kTechId.MarineAlertSoldierLost, self)
    end
    
    if attacker and attacker:GetTeamNumber() ~= self:GetTeamNumber() and attacker:GetTeamNumber() == kAlienTeamType and attacker:isa("Alien") then
        local hasupg, level = GetHasFuryUpgrade(attacker)
        if hasupg and level > 0 and attacker:GetIsAlive() then
            attacker:AddHealth((((1 / 3) * level) * kFuryHealthRegained) + ((((1 / 3) * level) * kFuryHealthPercentageRegained) * (attacker:GetMaxHealth() + attacker:GetMaxArmor())))
            attacker:AddEnergy((((1 / 3) * level) * kFuryEnergyRegained))
        end
    end
    
    // Note: Flashlight is powered by Marine's beating heart. Eco friendly.
    self:SetFlashlightOn(false)
    self.originOnDeath = self:GetOrigin()
    
end

function Marine:GetCanPhase()
    return self:GetIsAlive() and (not self.timeOfLastPhase or (Shared.GetTime() > (self.timeOfLastPhase + kPlayerPhaseDelay)))
end

function Marine:SetTimeOfLastPhase(time)
    self.timeOfLastPhase = time
end

function Marine:GetOriginOnDeath()
    return self.originOnDeath
end

function Marine:GiveJetpack()

    local activeWeapon = self:GetActiveWeapon()
    local activeWeaponMapName = nil
    local health = self:GetHealth()
    
    if activeWeapon ~= nil then
        activeWeaponMapName = activeWeapon:GetMapName()
    end
    
    local jetpackMarine = self:Replace(JetpackMarine.kMapName, self:GetTeamNumber(), true, Vector(self:GetOrigin()))
    
    jetpackMarine:SetActiveWeapon(activeWeaponMapName)
    jetpackMarine:SetHealth(health)
    
end

function Marine:GiveHeavyArmor()

    local activeWeapon = self:GetActiveWeapon()
    local activeWeaponMapName = nil
    local health = self:GetHealth()
    
    if activeWeapon ~= nil then
        activeWeaponMapName = activeWeapon:GetMapName()
    end
    
    local HAMarine = self:Replace(HeavyArmorMarine.kMapName, self:GetTeamNumber(), true, Vector(self:GetOrigin()))
        
    HAMarine:SetActiveWeapon(activeWeaponMapName)
    HAMarine:SetHealth(health)
    
end

function Marine:MakeSpecialEdition()
    self:SetModel(Marine.kBlackArmorModelName, Marine.kMarineAnimationGraph)
end

function Marine:MakeDeluxeEdition()
    self:SetModel(Marine.kSpecialEditionModelName, Marine.kMarineAnimationGraph)
end
