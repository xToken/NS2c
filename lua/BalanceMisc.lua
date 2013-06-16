// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\BalanceMisc.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kDefaultFov = 90
kEmbryoFov = 100
kSkulkFov = 105
kGorgeFov = 95
kLerkFov = 100
kFadeFov = 90
kOnosFov = 90

kHiveYOffset = 2.494
kHiveUnderAttackTime = 15
kMaxAlienStructureRange = 25
kMaxAlienStructuresofType = 8
kMaxBuildingHives = 1
kChamberLostNotification = 0    // Amount of Upgrade Chambers remaining for alerts to be sent
kPingOfDeathDelay = 2
kPingOfDeathDamagePercent = 12
kResearchMod = 1
kFootstepsThreshold = 3.5

kGhostStructureModifier = .75
kEnergyUpdateRate = 0.25
kDropWeaponTimeLimit = 1
kPickupWeaponTimeLimit = 1
kItemStayTime = 30    // NS1
kRecycleCancelWindow = 0.25
kRecycleRefundScalar = 0.5

// set to -1 for no time limit
kParasiteDuration = -1
kFallDamageMinimumVelocity = 15
kFallDamageScalar = 13
kKnockbackTime = 0.05

kCeleritySpeedModifier = 1.67 //75 Units NS1
kFocusAttackSlowdown = 0.5
kCloakingMaxSpeed = 3.0
kFocusAttackDamageMultipler = 2
kBombardAttackDamageMultipler = 1.3
kRedemptionEHPThreshold = 0.40
kRedemptionChancePerLevel = 0.15
kRedemptionCheckTime = 1
kRedemptionCooldown = 20
kRedploymentCooldownBase = 15
kAuraDetectionRange = 30
kFuryHealthRegained = 10
kFuryHealthPercentageRegained = 0.1
kFuryEnergyRegained = 10
kGhostMotionTrackingDodgePerLevel = 33
kGhostObservatoryDodgePerLevel = 33
kGhostMinimapDodgePerLevel = 33
kGhostScanDodgePerLevel = 33
kAlienBaseMoveNoise = 6
kAlienRandMoveNoise = 12
kAlienMoveNoises = 2

// per second
kAlienVisionCost = 0
kAlienVisionEnergyRegenMod = 1

kDefaultStructureCost = 10
kStructureCircleRange = 4
kInfantryPortalAttachRange = 12
kArmoryWeaponAttachRange = 10
kRoboticsFactoryAttachRange = 12

// Obs stuff
kScanDuration = 10
kScanRadius = 20
kMotionTrackingDetectionRange = 30
kMotionTrackingMinimumSpeed = 2
kObservatoryInitialEnergy = 25  kObservatoryMaxEnergy = 100
kDistressBeaconRange = 15
kDistressBeaconTime = 3

//Shift Energize
kEnergizeRange = 15
kEnergizeEnergyIncrease = 0.25
kStructureEnergyPerEnergize = 0.15
kPlayerEnergyPerEnergize = 6
kEnergizeUpdateRate = 1

// Each upgrade costs this much extra evolution time
kUpgradeGestationTime = 2

// Jetpack
// NS1: 6.5 seconds of fuel
// NS1: 9 seconds for full refuel
kJetpackUseFuelRate = 0.21
kJetpackReplenishFuelRate = 0.11
kJetpackWeight = 0.08

//HA
kHeavyArmorWeight = 0.10

kAlienInnateRegenerationTime = 1
kAlienRegenerationTime = 2
kAlienInnateRegenerationPercentage  = 0.02
kAlienRegenerationPercentage = 0.09

//Severe Flinch Effects
kFlinchDamageInterval = 0.1
kFlinchDamagePercent = 0.30

kKillDelay = 3

kAbilityMaxEnergy = 100