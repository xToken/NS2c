// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Balance.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Auto-generated. Copy and paste from balance spreadsheet.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Restructured this file heavily, attempted to remove all unused vars

// used as fallback
kDefaultBuildTime = 60

//MARINES

kCommandStationCost = 20
kExtractorCost = 15
kInfantryPortalCost = 20
kArmoryCost = 10
kArmsLabCost = 20
kPrototypeLabCost = 40
kSentryCost = 10
kSiegeCannonCost = 15
kPhaseGateCost = 15
kObservatoryCost = 15

kRifleDropCost = 1
kWelderDropCost = 5
kMinesDropCost = 10
kShotgunDropCost = 10
kHeavyMachineGunCost = 15
kGrenadeLauncherDropCost = 15
kJetpackDropCost = 12
kHeavyArmorDropCost = 15
kExosuitDropCost = 20
kTurretFactoryCost = 10
kAmmoPackCost = 1
kMedPackCost = 2
kCatPackCost = 2
kObservatoryDistressBeaconCost = 15
kObservatoryScanCost = 20 //Energy

kJetpackTechResearchCost = 45
kJetpackTechResearchTime = 135

kHeavyArmorTechResearchCost = 40
kHeavyArmorTechResearchTime = 110

kExosuitTechResearchCost = 35
kExosuitTechResearchTime = 120

kWeapons1ResearchCost = 20
kWeapons1ResearchTime = 60
kWeapons2ResearchCost = 30
kWeapons2ResearchTime = 90
kWeapons3ResearchCost = 40
kWeapons3ResearchTime = 120

kArmor1ResearchCost = 20
kArmor1ResearchTime = 60
kArmor2ResearchCost = 30
kArmor2ResearchTime = 90
kArmor3ResearchCost = 40
kArmor3ResearchTime = 120

kAdvancedArmoryUpgradeCost = 30
kAdvancedArmoryResearchTime = 180

kCatPackTechResearchCost = 10
kCatPackTechResearchTime = 25

kPhaseTechResearchCost = 15
kPhaseTechResearchTime = 45

kUpgradeTurretFactoryCost = 15
kUpgradeTurretFactoryTime = 45

kMotionTrackingResearchCost = 35
kMotionTrackingResearchTime = 100

kHandGrenadesTechResearchCost = 10
kHandGrenadesTechResearchTime = 45

kRecycleTime = 20

kArmoryBuildTime = 15
kPrototypeLabBuildTime = 20
kArmsLabBuildTime = 19
kExtractorBuildTime = 15
kInfantryPortalBuildTime = 10
kCommandStationBuildTime = 15
kTurretFactoryBuildTime = 15
kSentryBuildTime = 9
kSiegeCannonBuildTime  = 11
kObservatoryBuildTime = 15
kPhaseGateBuildTime = 12

//ALIENS

kHiveCost = 40
kHarvesterCost = 15
kCragCost = 10
kShiftCost = 10
kShadeCost = 10
kWhipCost = 10
kSkulkCost = 0
kGorgeCost = 10
kLerkCost = 30
kFadeCost = 50
kOnosCost = 75
kHydraCost = 10

kCarapaceCost = 0
kRegenerationCost = 0
kRedemptionCost = 0

kCamouflageCost = 0
kGhostCost = 0
kAuraCost = 0
kSilenceCost = 0

kAdrenalineCost = 0
kCelerityCost = 0
kRedeploymentCost = 0

kFocusCost = 0
kBombardCost = 0
kFuryCost = 0

kHiveBuildTime = 180
kHarvesterBuildTime = 27
kCragBuildTime = 27
kShiftBuildTime = 16
kShadeBuildTime = 19
kHydraBuildTime = 15
kWhipBuildTime = 22
kSkulkGestateTime = 3
kGorgeGestateTime = 10
kLerkGestateTime = 15
kFadeGestateTime = 25
kOnosGestateTime = 35
kUpgradeGestationTime = 2
kReplaceUpgradeGestationTime = 4

//General

kMarineTeamIntialRes = 100
kMaxTeamResources = 999
kAlienInitialPersonalRes = 25
kMaxPersonalResources = 100
kResourceTowerResourceInterval = 4
kResourcePerTick = 1
kKillReward = 2
kHighLifeformKillReward = 1
kResourceScalingMinPlayers = 4
kResourceScalingMaxPlayers = 12
kResourceScalingMaxDelta = 1.2
kResourceScalingMinDelta = .75
kResourceScaling = 20 //Controls the factoring per player.

//End Resource/Build Timing Stuff

// MARINE DAMAGE
kRifleDamage = 10
kRifleDamageType = kDamageType.Normal
kRifleClipSize = 50
kRifleWeight = 0.01
kRifleClipWeight = 0.005

kPistolDamage = 20
kPistolDamageType = kDamageType.Normal
kPistolClipSize = 10
kPistolWeight = 0.005
kPistolFireDelay = 0.08
kPistolClipWeight = 0.0033

kWelderDamage = 2
kWelderDamageType = kDamageType.Flame
kWelderFireDelay = 0.4
kWelderWeight = 0.005
kWelderRate = 60
kWelderStructureMultipler = 2

kAxeDamage = 30
kAxeDamageType = kDamageType.Normal
kAxeRange = 0.8
kAxeMeleeBaseWidth = 0.5
kAxeMeleeBaseHeight = 0.8

kGrenadeLauncherGrenadeDamage = 125
kGrenadeLauncherGrenadeDamageType = kDamageType.Structural
kGrenadeLauncherClipSize = 4
kGrenadeLauncherGrenadeDamageRadius = 5
kGrenadeLifetime = 2.0
kGrenadeLauncherWeight = 0.05
kGrenadeLauncherShellWeight = 0.0035

kShotgunDamage = 17
kShotgunDamageType = kDamageType.Normal
kShotgunClipSize = 8
kShotgunBulletsPerShot = 10
kShotgunMaxRange = 18
kShotgunMinSpread = 10
kShotgunMinSpreadBullets = 5
kShotgunMaxSpread = 18
//kShotgunDropOffStartRange = 4
kShotgunWeight = 0.03
kShotgunShellWeight = 0.002
kShotgunBaseRateOfFire = 1.5

kHeavyMachineGunDamage = 10
kHeavyMachineGunDamageType = kDamageType.Puncture
kHeavyMachineGunClipSize = 125
kHeavyMachineGunWeight = 0.08
kHeavyMachineGunROF = 0.05
kHeavyMachineGunReloadTime = 6.3
kHeavyMachineGunClipWeight = 0.01

kMinigunDamage = 8
kMinigunDamageType = kDamageType.Puncture
kMinigunClipSize = 100
kMinigunWeight = 0.06

kRailgunDamage = 125
kRailgunDamageType = kDamageType.StructuresOnly
kRailgunClipSize = 25
kRailgunWeight = 0.06

kMineDamage = 125
kMineDamageType = kDamageType.Normal
kMineActiveTime = 4
kMineDetonateRange = 3
kMineTriggerRange = 1.0
kMineCount = 3
kCombatMineCount = 1
kMinesWeight = 0.05

kNumHandGrenades = 2
kHandGrenadesRange = 4
kHandGrenadesDamage = 80
kHandGrenadesDamageType = kDamageType.Structural
kHandGrenadesLifetime = 1
kHandGrenadesWeight = 0.005

kSentryAttackDamage = 10
kSentryAttackDamageType = kDamageType.Light
kSentryAttackBaseROF = 0.33
kSentryAttackRandROF = 0.0
kSentryAttackBulletsPerSalvo = 1
kConfusedSentryBaseROF = 1.0
kSentriesPerFactory = 3

kSiegeCannonDamage = 400
kSiegeCannonDamageType = kDamageType.StructuresOnly
kSiegeCannonRange = 25 //1100 NS1 - Bigger than NS1, dropping to 25
kSiegeCannonSplashRadius = 3
kSiegeCannonsPerFactory = 5

kWeapons1DamageScalar = 1.1
kWeapons2DamageScalar = 1.2
kWeapons3DamageScalar = 1.3

kElectricalDamage = 20
kElectricalMaxTargets = 2
kElectricalRange = 3.25
kElectricalUpgradeResearchCost = 20
kElectricalUpgradeResearchTime = 30
kElectrifyDamageTime = 1
kElectrifyCooldownTime = 10
kElectrifyEnergyRegain = 25
kElectrifyEnergyCost = 12.5
kExtractorInitialEnergy = 25
kExtractorMaxEnergy = 100

// ALIEN DAMAGE
kBiteDamage = 75
kBiteDamageType = kDamageType.Normal
kBiteEnergyCost = 5.0
kBiteDelay = 0.4
kBiteRange = 1.1
kBiteMeleeBaseWidth = 0.7
kBiteMeleeBaseHeight = 0.9
kBiteKnockbackForce = 3

kLeapEnergyCost = 45

kParasiteDamage = 10
kParasiteDamageType = kDamageType.Normal
kParasiteEnergyCost = 30

kXenocideDamage = 200
kXenocideDamageType = kDamageType.Normal
kXenocideRange = 14
kXenocideEnergyCost = 50

kSpitDamage = 30
kSpitDamageType = kDamageType.Normal
kSpitEnergyCost = 8
kSpitDelay = 0.4

kBabblerPheromoneEnergyCost = 7
kBabblerDamage = 10

kBabblerCost = 0
kBabblerEggBuildTime = 15
kNumBabblerEggsPerGorge = 2
kNumBabblersPerEgg = 5

// Also see kHealsprayHealStructureRate
kHealsprayDamage = 13
kHealPlayerPercent = 4
kHealBuildingScalar = 5
kHealsprayDamageType = kDamageType.Biological
kHealsprayFireDelay = 0.8
kHealsprayEnergyCost = 15
kHealsprayRadius = 3.5

kDropStructureEnergyCost = 10
kGorgeCreateDistance = 6
kGorgeCreateHiveDistance = 3

kBileBombDamage = 200
kBileBombDamageType = kDamageType.StructuresOnly
kBileBombEnergyCost = 22
kBileBombSplashRadius = 6  // 200 inches in NS1 = 5 meters           

kMinWebLength = 2
kMaxWebLength = 12
kMaxWebBuildRange = 10
kWebbedDuration = 2
kNumWebsPerGorge = 15
kWebBuildCost = 0

kLerkFlapEnergyCost = 3

kLerkBiteDamage = 60
kLerkBiteEnergyCost = 5
kLerkBiteDamageType = kDamageType.Normal
kLerkBiteDelay = 0.32
kLerkBiteRange = 1.1
kLerkBiteMeleeBaseWidth = 0.8
kLerkBiteMeleeBaseHeight = 0.9

kSporeEnergyCost = 20
kSporeDuration = 4
kSporeDamage = 7
kSporeRadius = 5 //225 NS1
kSporeAttackDelay = 1.0
kSporeDamageDelay = .5
kSporeDamageType = kDamageType.Normal

kUmbraEnergyCost = 30
kUmbraDuration = 5
kUmbraRadius = 6
kUmbraBlockRate = 3
kUmbraDamageReduction = 0.35
kUmbraRetainTime = 0.1
kUmbraAttackDelay = 1.0

kSpikeMaxDamage = 8
kSpikeMinDamage = 5
kSpikeDamageType = kDamageType.Normal
kSpikeEnergyCost = 1.8
kSpikesAttackDelay = 0.12
kSpikeMinDamageRange = 15
kSpikeMaxDamageRange = 3
kSpikesPerShot = 1
kSpikesRange = 30 -- As as shotgun range
kSpikesSize = 0.03
kSpikesSpread = Math.Radians(4)

kPrimalScreamEnergyCost = 45
kPrimalScreamRange = 10
kPrimalScreamDamageModifier = 1.3
kPrimalScreamDuration = 4
kPrimalScreamEnergyGain = 60
kPrimalScreamROF = 5
kPrimalScreamROFIncrease = .3

kSwipeDamage = 80
kSwipeDamageType = kDamageType.Normal
kSwipeEnergyCost = 6.5
kSwipeDelay = 0.48
kSwipeRange = 1.3
kSwipeMeleeBaseWidth = 0.9
kSwipeMeleeBaseHeight = 1
kSwipeKnockbackForce = 4

kStartBlinkEnergyCost = 6
kBlinkPulseEnergyCost = 2

kMetabolizeEnergyCost = 25
kMetabolizeEnergyGain = 35
kMetabolizeHealthGain = 20
kMetabolizeDelay = 1.45

kAcidRocketDamage = 25
kAcidRocketDamageType = kDamageType.Heavy
kAcidRocketFireDelay = 0.5
kAcidRocketEnergyCost = 10
kAcidRocketRadius = 6

kGoreDamage = 90
kGoreDamageType = kDamageType.Normal
kGoreEnergyCost = 7
kGoreDelay = 0.45
kGoreRange = 1.7
kGoreMeleeBaseWidth = 1.1
kGoreMeleeBaseHeight = 1.2
kGoreKnockbackForce = 5

kDevourInitialDamage = 10
kDevourDamage = 10
kDevourEnergyCost = 35
kDevourAttackDelay = 2
kDevourDigestionSpeed = 1
kDevourHealthPerSecond = 20
kDevourDamageType = kDamageType.Falling
kDevourRange = 1.4
kDevourMeleeBaseWidth = 0.8
kDevourMeleeBaseHeight = 0.7

kStompEnergyCost = 30
kStompRange = 12
kStunMarineTime = 2.0
kStompDamage = 20
kStompDamageType = kDamageType.Normal
kShockwaveRadius = 2.5

kSmashDamage = 90
kSmashDamageType = kDamageType.Structural
kSmashEnergyCost = 9
kSmashRange = 1.9
kSmashMeleeBaseWidth = 1.1
kSmashMeleeBaseHeight = 1.4

kChargeMaxDamage = 4
kChargeMinDamage = 1
kStartChargeEnergyCost = 8

kHydraDamage = 20 // From NS1
kHydraAttackDamageType = kDamageType.Normal

kEmpoweredROFIncrease = 0.25

// SPAWN TIMES
kMarineRespawnTime = 10
kAlienBaseSpawnInterval = 8
kAlienSpawnIntervalPerPlayer = 0.166
kAlienMinSpawnInterval = 6
kAlienMaxSpawnInterval = 8
kAlienEggSpawnTime = 6
kAlienEggsPerHive = 10



//Combat Stuff
kCombatLevelsToExperience = {0, 100, 225, 375, 525, 675, 825, 1000, 1200, 1500, 1900, 2500, 0 } //0 for last level, to show nothing further.
kCombatBaseExperience = 100
kCombatLevelExperienceModifier = 0.5
kCombatObjectiveExperienceScalar = 600
kCombatExperienceBaseAward = 60
kCombatExperienceCrowdAward = 10
kCombatFriendlyAssistScalar = 0.8
kCombatFriendlyAwardRange = 9.5
kCombatMaxLevel = 12
kCombatResourcesPerLevel = 1
kCombatRoundTimelength = 25
kCombatDefaultWinner = 2

//Marine
kMarineCombatSpawnIntervalPerPlayer = 0.166
kMarineCombatMinSpawnInterval = 8
kMarineCombatMaxSpawnInterval = 10
kMarineRespawnsPerWave = 6
kCombatMarineBaseUpgradeCost = 1
kCombatMarineJetpackCost = 2
kCombatMarineHeavyArmorCost = 2
kArmoryMinSpawnDistance = 4
kArmoryMaxSpawnDistance = 15
kMarineCombatPowerUpTime = 1
kMarineCombatScanTime = 10
kMarineCombatScanCheckRadius = 10
kMarineCombatResupplyTime = 6
kMarineCombatCatalystTime = 12

//Alien Stuff
kAlienCombatSpawnIntervalPerPlayer = 0.166
kAlienCombatMinSpawnInterval = 8
kAlienCombatMaxSpawnInterval = 10
kAlienRespawnsPerWave = 6
kCombatModeGestationTimeScalar = 0.4
kCombatAlienUpgradeCost = 1
kCombatAlienFocusCost = 1 // This was 2 in NS1, but focus is somewhat weaker here.. maybe
kCombatAlienTwoHivesCost = 2
kCombatAlienThreeHivesCost = 2
kCombatAlienGorgeCost = 1
kCombatAlienSupportStructureCost = 1
kCombatAlienLerkCost = 2
kCombatAlienFadeCost = 3
kCombatAlienOnosCost = 4