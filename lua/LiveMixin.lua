// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\LiveMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/BalanceHealth.lua")

// forces predicted health/armor to update after 1 second
local kSynchronizeDelay = 1

LiveMixin = CreateMixin(LiveMixin)
LiveMixin.type = "Live"

// These may be optionally implemented.
LiveMixin.optionalCallbacks =
{
    OnTakeDamage = "A callback to alert when the object has taken damage.",
    OnKill = "A callback to alert when the object has been killed.",
    GetCanTakeDamageOverride = "Should return false if the entity cannot take damage. If this function is not provided it will be assumed that the entity can take damage.",
    GetCanDieOverride = "Should return false if the entity cannot die. If this function is not provided it will be assumed that the entity can die.",
    GetCanGiveDamageOverride = "Should return false if the entity cannot give damage to other entities. If this function is not provided it will be assumed that the entity cannot do damage.",
    GetSendDeathMessageOverride = "Should return false if the entity doesn't send a death message on death.",
    GetCanBeHealed = "Optionally prevent or allow healing."
}

LiveMixin.kHealth = 100
LiveMixin.kArmor = 0

LiveMixin.kMaxHealth = 8191 // 2^13-1, Maximum possible value for maxHealth
LiveMixin.kMaxArmor  = 2045 // 2^11-1, Maximum possible value for maxArmor

LiveMixin.kCombatDuration = 6

LiveMixin.networkVars =
{
    alive = "boolean",
    healthIgnored = "boolean",
    
    health = string.format("float (0 to %f by 1)", LiveMixin.kMaxHealth),
    maxHealth = string.format("float (0 to %f by 1)", LiveMixin.kMaxHealth),
    
    armor = string.format("float (0 to %f by 1)", LiveMixin.kMaxArmor),
    maxArmor = string.format("float (0 to %f by 1)", LiveMixin.kMaxArmor),
}

function LiveMixin:__initmixin()

    self.alive = true
    self.healthIgnored = false
    
    if Client then
        self.clientStateAlive = self.alive
    end
    
    self.health = LookupTechData(self:GetTechId(), kTechDataMaxHealth, 100)
    assert(self.health ~= nil)
    self.maxHealth = self.health
    assert(self.maxHealth < LiveMixin.kMaxHealth)

    self.armor = LookupTechData(self:GetTechId(), kTechDataMaxArmor, 0)
    assert(self.armor ~= nil)
    self.maxArmor = self.armor
    assert(self.maxArmor < LiveMixin.kMaxArmor)
    
    self.timeOfLastDamage = nil
    
    if Server then
    
        self.lastDamageAttackerId = Entity.invalidId
        self.timeLastCombatAction = 0
        
    elseif Client then
    
        self.healthClient = self.health
        self.armorClient = self.armor
        self.lastHealth = self.health
        self.lastArmor = self.armor
        
    end
    
    self.overkillHealth = 0
    
end

/**
 * Health is disregarded in all calculations.
 * Only uses armor.
 */
function LiveMixin:SetIgnoreHealth(setIgnoreHealth)
    self.healthIgnored = setIgnoreHealth
end

function LiveMixin:GetIgnoreHealth()
    return self.healthIgnored
end

// Returns text and 0-1 scalar for health bar on commander HUD when selected.
function LiveMixin:GetHealthDescription()

    local armorString = ""
    
    local armor = self:GetArmor()
    local maxArmor = self:GetMaxArmor()
    
    if armor and maxArmor and armor > 0 and maxArmor > 0 then
        armorString = string.format("Armor %s/%s", ToString(math.ceil(armor)), ToString(maxArmor))
    end
    
    if self.healthIgnored then
        return armorString, self:GetArmorScalar()
    else
        return string.format("Health  %s/%s  %s", ToString(math.ceil(self:GetHealth())), ToString(math.ceil(self:GetMaxHealth())), armorString), self:GetHealthScalar()
    end
    
end
AddFunctionContract(LiveMixin.GetHealthDescription, { Arguments = { "Entity" }, Returns = { "string", "number" } })

function LiveMixin:GetHealthFraction()

    local max = self:GetMaxHealth()
    
    if max == 0 or self:GetIgnoreHealth() then
        return 0
    else
        return self:GetHealth() / max
    end    

end

function LiveMixin:GetHealthScalar()

    if self.healthIgnored then
        return self:GetArmorScalar()
    end
    
    local max = self:GetMaxHealth() + self:GetMaxArmor() * kHealthPointsPerArmor
    local current = self:GetHealth() + self:GetArmor() * kHealthPointsPerArmor
    
    if max == 0 then
        return 0
    end
    
    return current / max
    
end
AddFunctionContract(LiveMixin.GetHealthScalar, { Arguments = { "Entity" }, Returns = { "number" } })

function LiveMixin:SetHealth(health)
    self.health = Clamp(health, 0, self:GetMaxHealth())
end
AddFunctionContract(LiveMixin.SetHealth, { Arguments = { "Entity", "number" }, Returns = { } })

function LiveMixin:GetMaxHealth()
    return self.maxHealth
end
AddFunctionContract(LiveMixin.GetMaxHealth, { Arguments = { "Entity" }, Returns = { "number" } })

function LiveMixin:SetMaxHealth(setMax)

    assert(setMax <= LiveMixin.kMaxHealth)
    assert(setMax > 0)
    
    self.maxHealth = setMax
    
end
AddFunctionContract(LiveMixin.SetMaxHealth, { Arguments = { "Entity", "number" }, Returns = { } })

// instead of simply setting self.maxHealth the fraction of current health will be stored and health increased (so 100% health remains 100%)
function LiveMixin:AdjustMaxHealth(setMax)

    assert(setMax <= LiveMixin.kMaxHealth)
    assert(setMax > 0)
    
    local healthFraction = self.health / self.maxHealth
    self.maxHealth = setMax
    self.health = self.maxHealth * healthFraction

end
AddFunctionContract(LiveMixin.AdjustMaxHealth, { Arguments = { "Entity", "number" }, Returns = { } })

function LiveMixin:GetArmorScalar()

    if self:GetMaxArmor() == 0 then
        return 1
    end
    
    return self:GetArmor() / self:GetMaxArmor()
    
end
AddFunctionContract(LiveMixin.GetArmorScalar, { Arguments = { "Entity" }, Returns = { "number" } })

function LiveMixin:SetArmor(armor)
    self.armor = Clamp(armor, 0, self:GetMaxArmor())
end
AddFunctionContract(LiveMixin.SetArmor, { Arguments = { "Entity", "number" }, Returns = { } })

function LiveMixin:GetMaxArmor()
    return self.maxArmor
end
AddFunctionContract(LiveMixin.GetMaxArmor, { Arguments = { "Entity" }, Returns = { "number" } })

function LiveMixin:SetMaxArmor(setMax)

    assert(setMax ~= nil)
    assert(setMax <= LiveMixin.kMaxArmor)
    assert(setMax >= 0)
    
    self.maxArmor = setMax
    
end
AddFunctionContract(LiveMixin.SetMaxArmor, { Arguments = { "Entity", "number" }, Returns = { } })

// instead of simply setting self.maxArmor the fraction of current Armor will be stored and Armor increased (so 100% Armor remains 100%)
function LiveMixin:AdjustMaxArmor(setMax)

    assert(setMax <= LiveMixin.kMaxArmor)
    assert(setMax >= 0)
    
    local armorFraction = self:GetArmorScalar()
    self.maxArmor = setMax
    self.armor = self.maxArmor * armorFraction

end
AddFunctionContract(LiveMixin.AdjustMaxArmor, { Arguments = { "Entity", "number" }, Returns = { } })

function LiveMixin:Heal(amount)

    local healed = false
    
    local newHealth = math.min(math.max(0, self.health + amount), self:GetMaxHealth())
    if self.alive and self.health ~= newHealth then
    
        self.health = newHealth
        healed = true
        
    end
    
    return healed
    
end
AddFunctionContract(LiveMixin.Heal, { Arguments = { "Entity", "number" }, Returns = { "boolean" } })

function LiveMixin:GetIsAlive()
    return self.alive
end
AddFunctionContract(LiveMixin.GetIsAlive, { Arguments = { "Entity" }, Returns = { "boolean" } })

function LiveMixin:SetIsAlive(state)
    self.alive = state
end
AddFunctionContract(LiveMixin.SetIsAlive, { Arguments = { "Entity", "boolean" }, Returns = { } })

function LiveMixin:GetTimeOfLastDamage()
    return self.timeOfLastDamage
end
AddFunctionContract(LiveMixin.GetTimeOfLastDamage, { Arguments = { "Entity" }, Returns = { { "number", "nil" } } })

function LiveMixin:GetAttackerIdOfLastDamage()
    return self.lastDamageAttackerId
end
AddFunctionContract(LiveMixin.GetAttackerIdOfLastDamage, { Arguments = { "Entity" }, Returns = { { "number", "nil" } } })

local function SetLastDamage(self, time, attacker)

    if attacker and attacker.GetId then
    
        self.timeOfLastDamage = time
        self.lastDamageAttackerId = attacker:GetId()
        
    end
    
    // Track "combat" (for now only take damage, since we don't make a difference between harmful and passive abilities):
    self.timeLastCombatAction = Shared.GetTime()
    
end
AddFunctionContract(SetLastDamage, { Arguments = { "Entity", "number", { "Entity", "nil" } }, Returns = { } })

function LiveMixin:GetCanTakeDamage()

    local canTakeDamage = (not self.GetCanTakeDamageOverride or self:GetCanTakeDamageOverride()) and (not self.GetCanTakeDamageOverrideMixin or self:GetCanTakeDamageOverrideMixin())
    return canTakeDamage
    
end
AddFunctionContract(LiveMixin.GetCanTakeDamage, { Arguments = { "Entity" }, Returns = { "boolean" } })

function LiveMixin:GetCanDie(byDeathTrigger)

    local canDie = (not self.GetCanDieOverride or self:GetCanDieOverride(byDeathTrigger)) and (not self.GetCanDieOverrideMixin or self:GetCanDieOverrideMixin(byDeathTrigger))
    return canDie
    
end
AddFunctionContract(LiveMixin.GetCanDie, { Arguments = { "Entity" }, Returns = { "boolean" } })

function LiveMixin:GetCanGiveDamage()

    if self.GetCanGiveDamageOverride then
        return self:GetCanGiveDamageOverride()
    end
    return false
    
end
AddFunctionContract(LiveMixin.GetCanGiveDamage, { Arguments = { "Entity" }, Returns = { "boolean" } })

/**
 * Returns true if the damage has killed the entity.
 */
function LiveMixin:TakeDamage(damage, attacker, doer, point, direction, armorUsed, healthUsed, damageType)

    // Use AddHealth to give health.
    assert(damage >= 0)
    
    local killedFromDamage = false
    local oldHealth = self:GetHealth()
    local oldArmor = self:GetArmor()
    
    if damage > 0 then
    
        self.armor = math.max(0, self:GetArmor() - armorUsed)
        self.health = math.max(0, self:GetHealth() - healthUsed)
        
        if self.OnTakeDamage then
            self:OnTakeDamage(damage, attacker, doer, point, direction, damageType)
        end
        
        // Remember time we were last hurt to track combat
        SetLastDamage(self, Shared.GetTime(), attacker)
        
        // set time out for synchronize to preventing sudden flipping of numbers, health display / crosshair text
        // don't do this when running prediction (otherwise client predicts* every frame the damage which results in x times (num frames) more damage applied
        if Client and not Shared.GetIsRunningPrediction() then
        
            self.timeLastClientUpdated = Shared.GetTime()
            self.healthClient = math.max(0, self:GetHealth() - healthUsed)
            self.armorClient = math.max(0, self:GetArmor() - armorUsed)
            
        end
        
        if Server then
        
            local killedFromHealth = oldHealth > 0 and self:GetHealth() == 0 and not self.healthIgnored
            local killedFromArmor = oldArmor > 0 and self:GetArmor() == 0 and self.healthIgnored
            if killedFromHealth or killedFromArmor then
            
                if not self.AttemptToKill or self:AttemptToKill(damage, attacker, doer, point) then
                
                    self:Kill(attacker, doer, point, direction)
                    killedFromDamage = true
                    
                end
                
            end
            
        end
        
    end
    
    return killedFromDamage
    
end
AddFunctionContract(LiveMixin.TakeDamage, { Arguments = { "Entity", "number", "Entity", "Entity", { "Vector", "nil" }, { "Vector", "nil" } }, Returns = { "boolean" } })

//
// How damaged this entity is, ie how much healing it can receive.
//
function LiveMixin:AmountDamaged()

    if self.healthIgnored then
        return self:GetMaxArmor() - self:GetArmor()
    end
    
    return (self:GetMaxHealth() - self:GetHealth()) + (self:GetMaxArmor() - self:GetArmor())
    
end
AddFunctionContract(LiveMixin.AmountDamaged, { Arguments = { "Entity" }, Returns = { "number" } })

// used for situtations where we don't have an attacker. Always normal damage and normal armor use rate
function LiveMixin:DeductHealth(damage, attacker, doer, healthOnly)

    local armorUsed = 0
    local healthUsed = damage
    
    if self.healthIgnored then
    
        armorUsed = damage
        healthUsed = 0
        
    elseif not healthOnly then
    
        armorUsed = math.min(self:GetArmor() * kHealthPointsPerArmor, (damage * kBaseArmorUseFraction) / kHealthPointsPerArmor )
        healthUsed = healthUsed - armorUsed
        
    end
    
    // TODO: use an override or model origin/engangement point
    local engangePoint = self:GetOrigin()
    
    self:TriggerEffects("flinch_health")
    self:TakeDamage(damage, attacker, doer, engangePoint, nil, armorUsed, healthUsed, kDamageType.Normal)
    
end
AddFunctionContract(LiveMixin.DeductHealth, { Arguments = { "Entity", "number", "Entity" }, Returns = { } })

function LiveMixin:GetCanBeHealed()

    if self.GetCanBeHealedOverride then
        return self:GetCanBeHealedOverride()
    end
    
    return self:GetIsAlive()
    
end

// Return the amount of health we added 
function LiveMixin:AddHealth(health, playSound, noArmor)

    // TakeDamage should be used for negative values.
    assert(health >= 0)
    
    local total = 0
    
    if self.GetCanBeHealed and not self:GetCanBeHealed() then
        return 0
    end    
    
    if self:AmountDamaged() > 0 then
    
        // Add health first, then armor if we're full
        local healthAdded = math.min(health, self:GetMaxHealth() - self:GetHealth())
        self:SetHealth(math.min(math.max(0, self:GetHealth() + healthAdded), self:GetMaxHealth()))

        local healthToAddToArmor = 0
        if not noArmor then
        
            healthToAddToArmor = health - healthAdded
            if healthToAddToArmor > 0 then
                self:SetArmor(math.min(math.max(0, self:GetArmor() + healthToAddToArmor * kArmorHealScalar ), self:GetMaxArmor()))
            end
            
        end
        
        total = healthAdded + healthToAddToArmor
        
        if total > 0 and playSound and (self:GetTeamType() == kAlienTeamType) then
            if HasMixin(self, "Upgradable") and self:GetHasUpgrade(kTechId.Regeneration) then
                self:TriggerEffects("regenerate_ability")
            else
                self:TriggerEffects("regenerate")
            end
        end
        
    end
    
    if total > 0 and self.OnHealed then
        self:OnHealed()
    end
    
    return total
    
end
AddFunctionContract(LiveMixin.AddHealth, { Arguments = { "Entity", "number", "boolean" }, Returns = { "number" } })

function LiveMixin:Kill(attacker, doer, point, direction)

    // Do this first to make sure death message is sent
    if self:GetIsAlive() and self:GetCanDie() then
    
        self.health = 0
        self.alive = false
        
        if Server then
            GetGamerules():OnEntityKilled(self, attacker, doer, point, direction)
        end
        
        if self.OnKill then
            self:OnKill(attacker, doer, point, direction)
        end
        
    end
    
end
AddFunctionContract(LiveMixin.Kill, { Arguments = { "Entity", "Entity", "Entity", { "Vector", "nil" }, { "Vector", "nil" } }, Returns = { } })

// This function needs to be tested.
function LiveMixin:GetSendDeathMessage()

    if self.GetSendDeathMessageOverride then
        return self:GetSendDeathMessageOverride()
    end
    return true
    
end
AddFunctionContract(LiveMixin.GetSendDeathMessage, { Arguments = { "Entity" }, Returns = { "boolean" } })

/**
 * Entities using LiveMixin are only selectable when they are alive.
 */
function LiveMixin:OnGetIsSelectable(result, byPlayer)
    result.selectable = result.selectable and self:GetIsAlive()
end
AddFunctionContract(LiveMixin.OnGetIsSelectable, { Arguments = { "Entity", "table" }, Returns = { } })

function LiveMixin:GetIsHealable()

    if self.GetIsHealableOverride then
        return self:GetIsHealableOverride()
    end
    
    return self:GetIsAlive()
    
end
AddFunctionContract(LiveMixin.GetIsHealable, { Arguments = { "Entity" }, Returns = { } })

function LiveMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("LiveMixin:OnUpdateAnimationInput")
    modelMixin:SetAnimationInput("alive", self:GetIsAlive())
    
end

if Client then

    local function ActualHealthArmorIsLower(self)        
        return self.health < self.healthClient or self.armor < self.armorClient        
    end
    
    local function ActualHealthHighDifference(self)
    
        local healthDiff = math.abs(self.health - self.healthClient)
        return healthDiff > 250
        
    end
    
    local function RecentlyHealed(self)
        return self.timeLastHeal + kSynchronizeDelay > Shared.GetTime()
    end
    
    function LiveMixin:OnPreUpdate()
    
        PROFILE("LiveMixin:OnPreUpdate")
        
        if not Shared.GetIsRunningPrediction() then
            
            if self.alive ~= self.clientStateAlive then
            
                self.clientStateAlive = self.alive
                
                if not self.alive and self.OnKillClient then
                    self:OnKillClient()
                end
                
            end
            
            local recentlyHealed = false
            if self.health > self.lastHealth or self.armor > self.lastArmor then
                recentlyHealed = true
            end
            self.lastHealth = self.health
            self.lastArmor = self.armor
            
            // only update after a specific time out in case the client modified health/armor or when someone else did damage
            if (not self.timeLastClientUpdated or self.timeLastClientUpdated + kSynchronizeDelay < Shared.GetTime()) or ActualHealthArmorIsLower(self) or recentlyHealed then
            
                self.healthClient = self.health
                self.armorClient = self.armor
                
            end
        end
        
    end
    
    function LiveMixin:OnDestroy()
    
        if not Shared.GetIsRunningPrediction() and self.clientStateAlive then
        
            self.clientStateAlive = false
            
            if self.OnKillClient then
                self:OnKillClient()
            end
            
        end
        
    end
    
end

// the client will use custom values for this, which are only updated on OnSynchronize after a defined delay passed, in case the specific client modified those values in processmove
if Server then

    function LiveMixin:GetHealth()
        return self.health
    end
    AddFunctionContract(LiveMixin.GetHealth, { Arguments = { "Entity" }, Returns = { "number" } })
    
    function LiveMixin:GetArmor()
        return self.armor
    end
    AddFunctionContract(LiveMixin.GetArmor, { Arguments = { "Entity" }, Returns = { "number" } })
    
elseif Client then

    function LiveMixin:GetHealth()
        return self.healthClient
    end
    AddFunctionContract(LiveMixin.GetHealth, { Arguments = { "Entity" }, Returns = { "number" } })
    
    function LiveMixin:GetArmor()
        return self.armorClient
    end
    AddFunctionContract(LiveMixin.GetArmor, { Arguments = { "Entity" }, Returns = { "number" } })
    
end

// Change health and max health when changing techIds
function LiveMixin:UpdateHealthValues(newTechId)

    // Change current and max hit points 
    local prevMaxHealth = LookupTechData(self:GetTechId(), kTechDataMaxHealth)
    local newMaxHealth = LookupTechData(newTechId, kTechDataMaxHealth)
    
    if prevMaxHealth == nil or newMaxHealth == nil then
    
        Print("%s:UpdateHealthValues(%d): Couldn't find health for id: %s = %s, %s = %s", self:GetClassName(), tostring(newTechId), tostring(self:GetTechId()), tostring(prevMaxHealth), tostring(newTechId), tostring(newMaxHealth))
        
        return false
        
    elseif prevMaxHealth ~= newMaxHealth and prevMaxHealth > 0 and newMaxHealth > 0 then
    
        // Calculate percentage of max health and preserve it
        local percent = self.health / prevMaxHealth
        self.health = newMaxHealth * percent
        
        // Set new max health
        self.maxHealth = newMaxHealth
        
    end
    
    return true
    
end

function LiveMixin:GetCanBeUsed(player, useSuccessTable)

    if not self:GetIsAlive() and (not self.GetCanBeUsedDead or not self:GetCanBeUsedDead()) then
        useSuccessTable.useSuccess = false
    end
    
end