// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Contains all rules regarding damage types. New types behavior can be defined BuildDamageTypeRules().
//
//    Important callbacks for classes:
//
//    ComputeDamageAttackerOverride(attacker, damage, damageType)
//    ComputeDamageAttackerOverrideMixin(attacker, damage, damageType)
//
//    for target:
//    ComputeDamageOverride(attacker, damage, damageType)
//    ComputeDamageOverrideMixin(attacker, damage, damageType)
//    GetArmorUseFractionOverride(damageType, armorFractionUsed)
//    GetReceivesStructuralDamage(damageType)
//    GetReceivesBiologicalDamage(damageType)
//    GetHealthPerArmorOverride(damageType, healthPerArmor)
//
//
//
// Damage types 
// 
// In NS2 - Keep simple and mostly in regard to armor and non-armor. Can't see armor, but players
// and structures spawn with an intuitive amount of armor.
// http://www.unknownworlds.com/ns2/news/2010/6/damage_types_in_ns2
// 
// Normal - Regular damage
// Light - Reduced vs. armor
// Heavy - Extra damage vs. armor
// Puncture - Extra vs. players
// Structural - Double against structures
// Gas - Breathing targets only (Spores, Nerve Gas GL).
// StructuresOnly - Doesn't damage players or AI units (SiegeCannon)
// Falling - Ignores armor for humans, no damage for some creatures or exosuit
// Door - Like Structural but also does damage to Doors. Nothing else damages Doors.
// Flame - Like normal but catches target on fire and plays special flinch animation
// Biological - only organic, biological targets (non mechanical)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Added in alien damage scaling detection

// utility functions

function GetReceivesStructuralDamage(entity)
    return entity.GetReceivesStructuralDamage and entity:GetReceivesStructuralDamage()
end

function GetReceivesBiologicalDamage(entity)
    return entity.GetReceivesBiologicalDamage and entity:GetReceivesBiologicalDamage()
end

// Use this function to change damage according to current upgrades
function GetUpgradedDamage(attacker, target, doer, damage, damageType, hitPoint, blockfocus)

    local damageScalar = 1

    if attacker ~= nil then
    
        // Damage upgrades only affect weapons, not ARCs, Sentries, MACs, Mines, etc.
        if doer:isa("Weapon") or doer:isa("Grenade")  and attacker:isa("Player") and attacker:GetGameMode() == kGameMode.Classic then
            if(GetHasTech(attacker, kTechId.Weapons3, true)) then
                damageScalar = kWeapons3DamageScalar
            elseif(GetHasTech(attacker, kTechId.Weapons2, true)) then
                damageScalar = kWeapons2DamageScalar
            elseif(GetHasTech(attacker, kTechId.Weapons1, true)) then
                damageScalar = kWeapons1DamageScalar
            end
        end
        
        if doer:isa("Weapon") or doer:isa("Grenade")  and attacker:isa("Player") and attacker:GetGameMode() == kGameMode.Combat then
            if attacker:GetHasUpgrade(kTechId.Weapons3) then
                damageScalar = kWeapons3DamageScalar
            elseif attacker:GetHasUpgrade(kTechId.Weapons2) then
                damageScalar = kWeapons2DamageScalar
            elseif attacker:GetHasUpgrade(kTechId.Weapons1) then
                damageScalar = kWeapons1DamageScalar
            end
        end
        
        if attacker.GetHasPrimalScream and attacker:GetHasPrimalScream() then
            damageScalar = kPrimalScreamDamageModifier
        end
        
        if attacker:isa("Alien") then
            if target.GetReceivesStructuralDamage and target:GetReceivesStructuralDamage(damageType) then
                local hasupg, level = GetHasBombardUpgrade(attacker)
                if level > 0 and hasupg then
                    damageScalar = 1 + (((kBombardAttackDamageMultipler - 1)/3) * level)
                end
            elseif not blockfocus then
                local focuslevel = CheckWeaponForFocus(doer, attacker)
                if focuslevel > 0 then
                    damageScalar = 1 + (((kFocusAttackDamageMultipler - 1)/3) * focuslevel)
                end
                
            end
        end
        
    end
        
    return damage * damageScalar
    
end

function GetDamageMultiplier()

    if Server and Shared.GetCheatsEnabled() then
        return GetGamerules():GetDamageMultiplier()
    end

    return 1
    
end

kDamageType = enum( {'Normal', 'Light', 'Heavy', 'Puncture', 'Structural', 'Gas', 'StructuresOnly', 'Falling', 'Flame', 'Biological', 'Corrode' } )

// Describe damage types for tooltips
kDamageTypeDesc = {
    "",
    "Light damage: reduced vs. armor.",
    "Heavy damage: extra vs. armor.",
    "Puncture damage: extra vs. players.",
    "Structural damage: Double vs. structures.",
    "Gas damage: affects breathing targets only.",
    "Structures only: Doesn't damage players or AI units.",
    "Falling damage: Ignores armor for humans, no damage for aliens.",
    "Corrode: Only affects armor."
}

kBaseArmorUseFraction = 0.7
kHeavyDamageArmorUseFraction = 0.5
kLightDamageArmorUseFraction = 0.8
kHeavyArmorUseFraction = 0.95
kExoArmorUseFraction = 0.9
kStructuralDamageScalar = 2
kPuncturePlayerDamageScalar = 2

kLightHealthPerArmor = 4
kHealthPointsPerArmor = 2
kHeavyHealthPerArmor = 1

// deal only 33% of damage to friendlies
kFriendlyFireScalar = 0.33

local function ApplyDefaultArmorUseFraction(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint)
    return damage, kBaseArmorUseFraction, healthPerArmor
end

local function ApplyHighArmorUseFraction(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint)
    if target:isa("HeavyArmorMarine") then
        armorFractionUsed = kHeavyArmorUseFraction
    end
    if target:isa("Exo") then
        armorFractionUsed = kExoArmorUseFraction
    end
    
    return damage, armorFractionUsed, healthPerArmor
    
end

local function ApplyDefaultHealthPerArmor(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint)
    return damage, armorFractionUsed, kHealthPointsPerArmor
end

local function DoubleHealthPerArmor(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint)
    return damage, kLightDamageArmorUseFraction, healthPerArmor * (kLightHealthPerArmor / kHealthPointsPerArmor)
end

local function HalfHealthPerArmor(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint)
    return damage, kHeavyDamageArmorUseFraction, healthPerArmor * (kHeavyHealthPerArmor / kHealthPointsPerArmor)
end

local function ApplyAttackerModifiers(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint, blockfocus)

    damage = GetUpgradedDamage(attacker, target, doer, damage, damageType, hitPoint, blockfocus)
    damage = damage * GetDamageMultiplier()
    
    if attacker and attacker.ComputeDamageAttackerOverride then
        damage = attacker:ComputeDamageAttackerOverride(attacker, damage, damageType, doer, hitPoint)
    end
    
    if doer and doer.ComputeDamageAttackerOverride then
        damage = doer:ComputeDamageAttackerOverride(attacker, damage, damageType)
    end
    
    if attacker and attacker.ComputeDamageAttackerOverrideMixin then
        damage = attacker:ComputeDamageAttackerOverrideMixin(attacker, damage, damageType, doer, hitPoint)
    end
    
    if doer and doer.ComputeDamageAttackerOverrideMixin then
        damage = doer:ComputeDamageAttackerOverrideMixin(attacker, damage, damageType, doer, hitPoint)
    end
    
    return damage, armorFractionUsed, healthPerArmor

end

local function ApplyTargetModifiers(target, attacker, doer, damage, armorFractionUsed, healthPerArmor,  damageType, hitPoint)

    // The host can provide an override for this function.
    if target.ComputeDamageOverride then
        damage = target:ComputeDamageOverride(attacker, damage, damageType, hitPoint)
    end

    // Used by mixins.
    if target.ComputeDamageOverrideMixin then
        damage = target:ComputeDamageOverrideMixin(attacker, damage, damageType, hitPoint)
    end
    
    if target.GetArmorUseFractionOverride then
        armorFractionUsed = target:GetArmorUseFractionOverride(damageType, armorFractionUsed, hitPoint)
    end
    
    if target.GetHealthPerArmorOverride then
        healthPerArmor = target:GetHealthPerArmorOverride(damageType, healthPerArmor, hitPoint)
    end
    
    local damageTable = {}
    damageTable.damage = damage
    damageTable.armorFractionUsed = armorFractionUsed
    damageTable.healthPerArmor = healthPerArmor
    
    if target.ModifyDamageTaken then
        target:ModifyDamageTaken(damageTable, attacker, doer, damageType, hitPoint)
    end
    
    return damageTable.damage, damageTable.armorFractionUsed, damageTable.healthPerArmor

end

local function ApplyFriendlyFireModifier(target, attacker, doer, damage, armorFractionUsed, healthPerArmor,  damageType, hitPoint)

    if target and attacker and target ~= attacker and HasMixin(target, "Team") and HasMixin(attacker, "Team") and target:GetTeamNumber() == attacker:GetTeamNumber() then
        damage = damage * kFriendlyFireScalar
    end
    
    return damage, armorFractionUsed, healthPerArmor
end

local function IgnoreArmor(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint)
    return damage, 0, healthPerArmor
end

local function MultiplyForStructures(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint)
    if target.GetReceivesStructuralDamage and target:GetReceivesStructuralDamage(damageType) then
        damage = damage * kStructuralDamageScalar
    end
    
    return damage, armorFractionUsed, healthPerArmor
end

local function MultiplyForPlayers(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint)
    return ConditionalValue(target:isa("Player"), damage * kPuncturePlayerDamageScalar, damage), armorFractionUsed, healthPerArmor
end

local function DamageStructuresOnly(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint)
    if not target.GetReceivesStructuralDamage or not target:GetReceivesStructuralDamage(damageType) then
        damage = 0
    end
    
    return damage, armorFractionUsed, healthPerArmor
end

local function DamageBiologicalOnly(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint)
    if not target.GetReceivesBiologicalDamage or not target:GetReceivesBiologicalDamage(damageType) then
        damage = 0
    end
    
    return damage, armorFractionUsed, healthPerArmor
end

local function DamageBreathingOnly(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint)
    if not target.GetReceivesVaporousDamage or not target:GetReceivesVaporousDamage(damageType) then
        damage = 0
    end
    
    return damage, armorFractionUsed, healthPerArmor
end

kDamageTypeGlobalRules = nil
kDamageTypeRules = nil

/*
 * Define any new damage type behavior in this function
 */
local function BuildDamageTypeRules()

    kDamageTypeGlobalRules = {}
    kDamageTypeRules = {}
    
    // global rules
    table.insert(kDamageTypeGlobalRules, ApplyDefaultArmorUseFraction)
    table.insert(kDamageTypeGlobalRules, ApplyHighArmorUseFraction)
    table.insert(kDamageTypeGlobalRules, ApplyDefaultHealthPerArmor)
    table.insert(kDamageTypeGlobalRules, ApplyAttackerModifiers)
    table.insert(kDamageTypeGlobalRules, ApplyTargetModifiers)
    table.insert(kDamageTypeGlobalRules, ApplyFriendlyFireModifier)
    // ------------------------------
    
    // normal damage rules
    kDamageTypeRules[kDamageType.Normal] = {}
    
    // light damage rules
    kDamageTypeRules[kDamageType.Light] = {}
    table.insert(kDamageTypeRules[kDamageType.Light], DoubleHealthPerArmor)
    // ------------------------------
    
    // heavy damage rules
    kDamageTypeRules[kDamageType.Heavy] = {}
    table.insert(kDamageTypeRules[kDamageType.Heavy], HalfHealthPerArmor)
    // ------------------------------

    // Puncture damage rules
    kDamageTypeRules[kDamageType.Puncture] = {}
    table.insert(kDamageTypeRules[kDamageType.Puncture], MultiplyForPlayers)
    // ------------------------------

    // structural rules
    kDamageTypeRules[kDamageType.Structural] = {}
    table.insert(kDamageTypeRules[kDamageType.Structural], MultiplyForStructures)
    // ------------------------------ 
    
    // gas damage rules
    kDamageTypeRules[kDamageType.Gas] = {}
    table.insert(kDamageTypeRules[kDamageType.Gas], DamageBreathingOnly)
    // ------------------------------
   
    // structures only rules
    kDamageTypeRules[kDamageType.StructuresOnly] = {}
    table.insert(kDamageTypeRules[kDamageType.StructuresOnly], DamageStructuresOnly)
    // ------------------------------
 
    // fall damage rules
    kDamageTypeRules[kDamageType.Falling] = {}
    table.insert(kDamageTypeRules[kDamageType.Falling], IgnoreArmor)
    // ------------------------------
    
    // Flame damage rules
    kDamageTypeRules[kDamageType.Flame] = {}
    // ------------------------------
    
    // Biological damage rules
    kDamageTypeRules[kDamageType.Biological] = {}
    table.insert(kDamageTypeRules[kDamageType.Biological], DamageBiologicalOnly)
    // ------------------------------


end

// applies all rules and returns damage, armorUsed, healthUsed
function GetDamageByType(target, attacker, doer, damage, damageType, hitPoint, blockfocus)

    assert(target)
    
    if not kDamageTypeGlobalRules or not kDamageTypeRules then
        BuildDamageTypeRules()
    end
    
    // at first check if damage is possible, if not we can skip the rest
    if not CanEntityDoDamageTo(attacker, target, Shared.GetCheatsEnabled(), Shared.GetDevMode(), GetFriendlyFire(), damageType) then
        return 0, 0, 0
    end
    
    local armorUsed = 0
    local healthUsed = 0
    
    local armorFractionUsed, healthPerArmor = 0
    
    // apply global rules at first
    for _, rule in ipairs(kDamageTypeGlobalRules) do
        damage, armorFractionUsed, healthPerArmor = rule(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint, blockfocus)
    end
    
    // apply damage type specific rules
    for _, rule in ipairs(kDamageTypeRules[damageType]) do
        damage, armorFractionUsed, healthPerArmor = rule(target, attacker, doer, damage, armorFractionUsed, healthPerArmor, damageType, hitPoint)
    end
    
    if damage > 0 and healthPerArmor > 0 then

        // Each point of armor blocks a point of health but is only destroyed at half that rate (like NS1)
        // Thanks Harimau!
        local healthPointsBlocked = math.min(healthPerArmor * target.armor, armorFractionUsed * damage)
        armorUsed = healthPointsBlocked / healthPerArmor
        
        // Anything left over comes off of health
        healthUsed = damage - healthPointsBlocked

    end
    
    return damage, armorUsed, healthUsed

end