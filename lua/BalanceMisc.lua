// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\BalanceMisc.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Restructured this file heavily, attempted to remove all unused vars

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
kMaxGorgeOwnedStructures = 24
kChamberLostNotification = 0    // Amount of Upgrade Chambers remaining for alerts to be sent
kPingOfDeathDelay = 2
kPingOfDeathDamagePercent = 12
kResearchMod = 1
kFootstepsThreshold = 3.5
kIdleThreshold = 5

kGhostStructureModifier = .75
kEnergyUpdateRate = 0.25
kDropWeaponTimeLimit = 1
kPickupWeaponTimeLimit = 2
kItemStayTime = 30    // NS1
kRecycleCancelWindow = 0.25
kRecycleRefundScalar = 0.5

// set to -1 for no time limit
kParasiteDuration = -1
kParasitePlayerPointValue = 1
kFallDamageMinimumVelocity = 12
kFallDamageScalar = 11.88
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
kGhostCloakingPerLevel = 0.25

// per second
kAlienVisionCost = 0
kAlienVisionEnergyRegenMod = 1

kDefaultStructureCost = 10
kStructureCircleRange = 4
kInfantryPortalAttachRange = 12
kArmoryWeaponAttachRange = 10
kTurretFactoryAttachRange = 12

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
kJetpackUseFuelRate = 0.22
kJetpackReplenishFuelRate = 0.10
kJetpackWeight = 0.08

//HA
kHeavyArmorWeight = 0.10

kAlienInnateRegenerationTime = 2
kAlienRegenerationTime = 2
kAlienInnateRegenerationPercentage  = 0.02
kAlienRegenerationPercentage = 0.09
kHiveMaxHealAmount = 80

//Severe Flinch Effects
kFlinchDamageInterval = 0.1
kFlinchDamagePercent = 0.30

//Base Alien building infestation generation
kInfestationRadius = 3.5
kInfestationBlobDensity = 2
kInfestationGrowthRate = 0.1
kMinInfestationRadius = 0.5

//DropPacks
kClipsPerAmmoPack = 1
kHealthPerMedpack = 50
kCatPackFireRateScalar = 1.3
kCatPackMoveSpeedScalar = 1.2
kCatPackDuration = 6

//Armory
kArmoryHealAmount = 15

kKillDelay = 3

kAbilityMaxEnergy = 100
kDoorWeldTime = 999