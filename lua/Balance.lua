// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Balance.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Auto-generated. Copy and paste from balance spreadsheet.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/BalanceHealth.lua")
Script.Load("lua/BalanceMisc.lua")

// used as fallback
kDefaultBuildTime = 8
// 2 = Hold Space, 1 = Queued Jumping like Quake, 0 = Default NS2
kJumpMode = 2

// Resource Costs/Build/Research Times
kCommandStationCost = 20
kExtractorCost = 15
kInfantryPortalCost = 20
kArmoryCost = 10
kArmsLabCost = 20
kAdvancedArmoryUpgradeCost = 30
kPrototypeLabCost = 40
kSentryCost = 10
kCatPackCost = 3
kRifleDropCost = 1
kWelderDropCost = 5
kMinesDropCost = 10
kShotgunDropCost = 10
kHeavyMachineGunCost = 15
kHeavyMachineGunCost = 15
kGrenadeLauncherDropCost = 15
kJetpackDropCost = 12
kHeavyArmorDropCost = 15
kRoboticsFactoryCost = 10
kARCCost = 15
kPhaseGateCost = 15
kAmmoPackCost = 1
kMedPackCost = 2
kObservatoryScanCost = 20
kObservatoryDistressBeaconCost = 15

kJetpackTechResearchCost = 45
kHeavyArmorTechResearchCost = 40
kWeapons1ResearchCost = 20
kWeapons2ResearchCost = 30
kWeapons3ResearchCost = 40
kArmor1ResearchCost = 20
kArmor2ResearchCost = 30
kArmor3ResearchCost = 40
kCatPackTechResearchCost = 10
kObservatoryCost = 15
kPhaseTechResearchCost = 15
kUpgradeRoboticsFactoryCost = 15
kMotionTrackingResearchCost = 35
kHandGrenadesTechResearchCost = 10
kRecycleTime = 20

kUpgradeRoboticsFactoryTime = 30
kArmoryBuildTime = 15
kAdvancedArmoryResearchTime = 180
kWeaponsModuleAddonTime = 40
kPrototypeLabBuildTime = 20
kArmsLabBuildTime = 19
kExtractorBuildTime = 15
kInfantryPortalBuildTime = 10
kCommandStationBuildTime = 15
kRoboticsFactoryBuildTime = 15
kARCBuildTime = 10
kSentryBuildTime = 7
kArcBuildTime  = 10
kJetpackTechResearchTime = 75
kHeavyArmorTechResearchTime = 110
kCatPackTechResearchTime = 15
kObservatoryBuildTime = 15
kPhaseTechResearchTime = 45
kMotionTrackingResearchTime = 100
kPhaseGateBuildTime = 12
kWeapons1ResearchTime = 60
kWeapons2ResearchTime = 90
kWeapons3ResearchTime = 120
kArmor1ResearchTime = 60
kArmor2ResearchTime = 90
kArmor3ResearchTime = 120
kHandGrenadesTechResearchTime = 45

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
kHarvesterBuildTime = 20
kCragBuildTime = 20
kShiftBuildTime = 12
kShadeBuildTime = 14
kHydraBuildTime = 11
kWhipBuildTime = 13
kSkulkGestateTime = 3
kGorgeGestateTime = 10
kLerkGestateTime = 15
kFadeGestateTime = 25
kOnosGestateTime = 35
kEvolutionGestateTime = 3

kMarineTeamIntialRes = 100
kMaxTeamResources = 999
kAlienTeamInitialRes = 25
kMaxPersonalResources = 100
kResourceTowerResourceInterval = 4
kResourcePerTick = 1
kKillRewardMin = 2
kKillRewardMax = 2
kResourceScalingMinPlayers = 4
kResourceScalingMaxPlayers = 12
kResourceScalingMaxDelta = 1.2
kResourceScalingMinDelta = .75
kResourceScaling = 20

//End Resource/Build Timing Stuff

// MARINE DAMAGE
kRifleDamage = 10
kRifleDamageType = kDamageType.Normal
kRifleClipSize = 50
kRifleWeight = 0.08

kPistolDamage = 20
kPistolDamageType = kDamageType.Normal
kPistolClipSize = 10
kPistolWeight = 0.03

kWelderDamage = 4
kWelderDamageType = kDamageType.Normal
kWelderFireDelay = 0.4
kWelderWeight = 0.035
kWelderRate = 60
kWelderStructureMultipler = 2

kAxeDamage = 30
kAxeDamageType = kDamageType.Normal

kGrenadeLauncherGrenadeDamage = 125
kGrenadeLauncherGrenadeDamageType = kDamageType.Structural
kGrenadeLauncherClipSize = 4
kGrenadeLauncherGrenadeDamageRadius = 8
kGrenadeLifetime = 2.0
kGrenadeLauncherWeight = 0.22

kShotgunDamage = 17
kShotgunDamageType = kDamageType.Normal
kShotgunClipSize = 8
kShotgunBulletsPerShot = 10
kShotgunMaxRange = 18
kShotgunMinSpread = 15
kShotgunMinSpreadBullets = 5
kShotgunMaxSpread = 22
//kShotgunDropOffStartRange = 4
kShotgunWeight = 0.15

kHeavyMachineGunDamage = 20
kHeavyMachineGunDamageType = kDamageType.HalfStructure
kHeavyMachineGunClipSize = 125
kHeavyMachineGunWeight = 0.20
kHeavyMachineGunROF = 0.05

kMineDamage = 125
kMineDamageType = kDamageType.Normal
kMineActiveTime = 4
kMineAlertTime = 8
kMineDetonateRange = 3
kMineTriggerRange = 1.0
kMineCount = 3
kMinesWeight = 0.05

kNumHandGrenades = 2
kHandGrenadesRange = 4
kHandGrenadesDamage = 80
kHandGrenadesDamageType = kDamageType.Normal
kHandGrenadesLifetime = 0.75
kHandGrenadesWeight = 0.025

kSentryAttackDamage = 10
kSentryAttackDamageType = kDamageType.Normal
kSentryAttackBaseROF = 0.12
kSentryAttackRandROF = 0.16
kSentryAttackBulletsPerSalvo = 1
kConfusedSentryBaseROF = 1.0

// sentry increases damage when shooting at the same target (resets when switching targets)
kSentryMinAttackDamage = 5
kSentryMaxAttackDamage = 20
kSentryDamageRampUpDuration = 5

kARCDamage = 400
kARCDamageType = kDamageType.StructuresOnly // splash damage hits friendly arcs as well
kARCRange = 26 //1100 NS1

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
kElectrifyEnergyCost = 10
kExtractorInitialEnergy = 25
kExtractorMaxEnergy = 100

// ALIEN DAMAGE
kBiteDamage = 75
kBiteDamageType = kDamageType.Normal
kBiteEnergyCost = 5.0
kBiteDelay = 0.4

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

// Also see kHealsprayHealStructureRate
kHealsprayDamage = 13
kHealPlayerPercent = 4
kHealBuildingScalar = 5
kHealsprayDamageType = kDamageType.Biological
kHealsprayFireDelay = 0.8
kHealsprayEnergyCost = 15
kHealsprayRadius = 3.5

kBileBombDamage = 200
kBileBombDamageType = kDamageType.StructuresOnly
kBileBombEnergyCost = 22
kBileBombSplashRadius = 6  // 200 inches in NS1 = 5 meters           

kWebSpinnerROF = 0.5
kWebSpinnerEnergyCost = 18
kWebImobilizeTime = 3
kWebEngagementRange = 2

kLerkBiteDamage = 60
kLerkBiteEnergyCost = 5
kLerkBiteDamageType = kDamageType.Normal
kLerkBiteDelay = 0.32

kSporeEnergyCost = 20
kSporeDuration = 4
kSporeDamage = 7
kSporeRadius = 5 //225 NS1
kSporeAttackDelay = 1.0
kSporeDamageDelay = .5

kUmbraEnergyCost = 30
kUmbraDuration = 5
kUmbraRadius = 6
kUmbraBlockRate = 3
kUmbraDamageReduction = 0.35
kUmbraRetainTime = 0.1
kUmbraAttackDelay = 1.0

kSpikeMaxDamage = 15
kSpikeMinDamage = 10
kSpikeDamageType = kDamageType.Heavy
kSpikeEnergyCost = 1.8
kSpikesAttackDelay = 0.12
kSpikeMinDamageRange = 15
kSpikeMaxDamageRange = 3
kSpikesPerShot = 1
kSpikesRange = 30 -- As as shotgun range

kPrimalScreamEnergyCost = 45
kPrimalScreamRange = 10
kPrimalScreamDamageModifier = 1.3
kPrimalScreamDuration = 4
kPrimalScreamEnergyGain = 60
kPrimalScreamROF = 5
kPrimalScreamROFIncrease = 1.3

kSwipeDamage = 80
kSwipeDamageType = kDamageType.Normal
kSwipeEnergyCost = 6.5
kSwipeDelay = 0.48

kStartBlinkEnergyCost = 8
kBlinkEnergyCost = 65
kBlinkPulseEnergyCost = 4
kBlinkCooldown = 0.05

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

kDevourInitialDamage = 10
kDevourDamage = 10
kDevourEnergyCost = 35
kDevourDelay = 2
kDevourDamageType = kDamageType.Falling

kStompEnergyCost = 30
kStompRange = 12
kDisruptMarineTime = 2

kSmashDamage = 125
kSmashDamageType = kDamageType.Structural
kSmashEnergyCost = 9

kChargeMaxDamage = 4
kChargeMinDamage = 1

kHydraDamage = 20 // From NS1
kHydraAttackDamageType = kDamageType.Normal

kWhipDamage = 50
kWhipAttackDamageType = kDamageType.Normal

kMelee1DamageScalar = 1.1
kMelee2DamageScalar = 1.2
kMelee3DamageScalar = 1.3

// SPAWN TIMES
kMarineRespawnTime = 10
kEggSpawnTime = 8
kAlienWaveSpawnInterval = 7
kAlienEggsPerHive = 10