// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Marine_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Added HA pickup, fury kill rewards and removed old blinds.  Made some vars local.

local kDieSoundName = PrecacheAsset("sound/NS2.fev/marine/common/death")
local kSpendResourcesSoundName = PrecacheAsset("sound/NS2.fev/marine/common/player_spend_nanites")
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

function Marine:GetDamagedAlertId()
    return kTechId.MarineAlertSoldierUnderAttack
end

function Marine:ApplyCatPack()

    self.catpackboost = true
    self.timeCatpackboost = Shared.GetTime()
    
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

local function DestroyMarineWeaponInSlot(self, slot)
    local hasWeapon = self:GetWeaponInHUDSlot(slot)
    if hasWeapon then
        self:RemoveWeapon(hasWeapon)
        DestroyEntity(hasWeapon)
        return true
    end
    return false
end

function Marine:OnRestoreUpgrades()

    local player = Player.OnRestoreUpgrades(self)
    
    if not player:isa("JetpackMarine") and player:GetHasUpgrade(kTechId.Jetpack) then
        //I believe these trigger a Replace, so want to make sure this doesnt loop, but also doesnt get messy.
        player = self:GiveJetpack()
        player:UpdateArmorAmount()
    elseif not player:isa("HeavyArmorMarine") and player:GetHasUpgrade(kTechId.HeavyArmor) then
        player = self:GiveHeavyArmor()
        player:UpdateArmorAmount()
    end
    
    if player:GetHasUpgrade(kTechId.Mines) then
        player:GiveItem(Mines.kMapName)
    end
    if player:GetHasUpgrade(kTechId.Welder) then
        player:GiveItem(Welder.kMapName)
    elseif player:GetHasUpgrade(kTechId.HandGrenades) then
        player:GiveItem(HandGrenades.kMapName)
    end

    if player:GetHasUpgrade(kTechId.HeavyMachineGun) then
        DestroyMarineWeaponInSlot(player, 1)
        player:GiveItem(HeavyMachineGun.kMapName)
    elseif player:GetHasUpgrade(kTechId.GrenadeLauncher) then
        DestroyMarineWeaponInSlot(player, 1)
        player:GiveItem(GrenadeLauncher.kMapName)
    elseif player:GetHasUpgrade(kTechId.Shotgun) then
        DestroyMarineWeaponInSlot(player, 1)
        player:GiveItem(Shotgun.kMapName)
    end
    
    if player:GetHasUpgrade(kTechId.MedPack) then
        player.hasresupply = true
    elseif player:GetHasUpgrade(kTechId.CatPack) then
        player.hascatpacks = true
    elseif player:GetHasUpgrade(kTechId.Scan) then
        player.hasscan = true
    end
    
    return player
    
end

function Marine:OnGiveUpgrade(upgradeId)

    Player.OnGiveUpgrade(self, upgradeId)
    
    if upgradeId == kTechId.MedPack then
        self.hasresupply = true
    elseif upgradeId == kTechId.CatPack then
        self.hascatpacks = true
    elseif upgradeId == kTechId.Scan then
        self.hasscan = true
    end
    
    if upgradeId == kTechId.Armor1 or upgradeId == kTechId.Armor2 or upgradeId == kTechId.Armor3 then
        self:UpdateArmorAmount()
    end
    
end

function Marine:ProcessBuyAction(techIds)

    ASSERT(type(techIds) == "table")
    ASSERT(table.count(techIds) > 0)
    
    local techTree = GetTechTree(self:GetTeamNumber())
    local buyAllowed = true
    local totalCost = 0
    local validBuyIds = { }
    
    for i, techId in ipairs(techIds) do
    
        local techNode = techTree:GetTechNode(techId)
        if techNode ~= nil then
            local prereq1 = techNode:GetPrereq1()
            local prereq2 = techNode:GetPrereq2()
        
            buyAllowed = (prereq1 == kTechId.None or self:GetHasUpgrade(prereq1)) and (prereq2 == kTechId.None or self:GetHasUpgrade(prereq2))
            local cost = LookupTechData(techId, kTechDataCostKey, 0)
            if cost ~= nil and buyAllowed then
                totalCost = totalCost + cost
                table.insert(validBuyIds, techId)
            else
                buyAllowed = false
                break
            end
        end
        
    end
    
    if totalCost <= self:GetResources() and buyAllowed then
    
        local newPlayer, valid = self:AttemptToBuy(validBuyIds)
        if valid then
            newPlayer:AddResources(-totalCost)
            
            Shared.PlayPrivateSound(self, kSpendResourcesSoundName, nil, 1.0, newPlayer:GetOrigin())
            return true
        end
        
    else
        Server.PlayPrivateSound(self, self:GetNotEnoughResourcesSound(), self, 1.0, self:GetOrigin())        
    end

    return false
    
end

local kWeaponTable = {kTechId.HeavyMachineGun, kTechId.GrenadeLauncher, kTechId.Shotgun, kTechId.Welder, kTechId.Mines, kTechId.HandGrenades }

function Marine:AttemptToBuy(validBuyIds)
    //Marines buy upgrades one at a time.
    
    local player = self
    local success = true
    
    for i, techId in ipairs(validBuyIds) do
    
        if techId == kTechId.Jetpack and not player:isa("JetpackMarine") then
            player = player:GiveJetpack()
            player:UpdateArmorAmount()
        elseif techId == kTechId.HeavyArmor and not player:isa("HeavyArmorMarine") then
            player = player:GiveHeavyArmor()
            player:UpdateArmorAmount()
        elseif table.contains(kWeaponTable, techId) then
            //GUNZ
            if techId == kTechId.HeavyMachineGun or techId == kTechId.GrenadeLauncher or techId == kTechId.Shotgun then
                DestroyMarineWeaponInSlot(player, 1)
            end
            if techId == kTechId.HandGrenades and self:GetHasUpgrade(kTechId.Welder) then
                //Nope
            elseif player:GiveItem(LookupTechData(techId, kTechDataMapName)) then
                StartSoundEffectAtOrigin(Marine.kGunPickupSound, player:GetOrigin())                    
            end
        else
            //Normal upgrade
        end

        player:GiveUpgrade(techId)
    
    end
    
    return player, success
    
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

    // Drop all weapons which cost resources
    if GetServerGameMode() == kGameMode.Classic then
        self:DropAllWeapons()
    end
    
    // Destroy remaining weapons
    self:DestroyWeapons()
    
    Player.OnKill(self, attacker, doer, point, direction)
    
    // Don't play alert if we suicide
    if attacker ~= self then
        self:GetTeam():TriggerAlert(kTechId.MarineAlertSoldierLost, self)
    end
	
	if attacker and attacker:isa("Alien") and attacker:GetTeamNumber() ~= self:GetTeamNumber() then
		local hasupg, level = GetHasFuryUpgrade(attacker)
        if hasupg and level > 0 and attacker:GetIsAlive() then
            attacker:AddHealth((((1 / 3) * level) * kFuryHealthRegained) + ((((1 / 3) * level) * kFuryHealthPercentageRegained) * (attacker:GetMaxHealth())), true, (attacker:GetMaxHealth() - attacker:GetHealth() ~= 0))
            attacker:AddEnergy((((1 / 3) * level) * kFuryEnergyRegained), true, (self:GetMaxHealth() - self:GetHealth() ~= 0))
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

function Marine:OnTakeDamage(damage, attacker, doer, point)
	if damage > 0 then
	    self:CheckCatalyst()
	end	
end

function Marine:CheckCatalyst()
    //hascatpacks
    local time = Shared.GetTime()
    if self.hascatpacks and (self.lastcombatcatpack == nil or self.lastcombatcatpack + kMarineCombatCatalystTime < time) then
        StartSoundEffectAtOrigin(CatPack.kPickupSound, self:GetOrigin())
        self:ApplyCatPack()
        self.lastcombatcatpack = time
    end
end

function Marine:OnPrimaryAttack()
    self:CheckCatalyst()
end

function Marine:OnSecondaryAttack()
    self:CheckCatalyst()
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
    return jetpackMarine
    
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
    return HAMarine
    
end

function Marine:GiveExo(type)

    local health = self:GetHealth()
    self:DropAllWeapons()
    local ExoMarine = self:Replace(Exo.kMapName, self:GetTeamNumber(), false, Vector(self:GetOrigin()), { layout = type })
    ExoMarine:SetHealth(health)
    return ExoMarine
    
end