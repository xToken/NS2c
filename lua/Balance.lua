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
kDefaultBuildTime = 60

// Resource Costs/Build/Research Times
kCommandStationCost = 20
kExtractorCost = 15
kInfantryPortalCost = 20
kArmoryCost = 10
kArmsLabCost = 20
kPrototypeLabCost = 40
kSentryCost = 10
kARCCost = 15
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
kRoboticsFactoryCost = 10
kAmmoPackCost = 1
kMedPackCost = 2
kCatPackCost = 3
kObservatoryScanCost = 20
kObservatoryDistressBeaconCost = 15

kJetpackTechResearchCost = 45
kJetpackTechResearchTime = 75

kHeavyArmorTechResearchCost = 40
kHeavyArmorTechResearchTime = 110

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
kCatPackTechResearchTime = 15

kPhaseTechResearchCost = 15
kPhaseTechResearchTime = 45

kUpgradeRoboticsFactoryCost = 15
kUpgradeRoboticsFactoryTime = 30

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
kRoboticsFactoryBuildTime = 15
kSentryBuildTime = 7
kArcBuildTime  = 10
kObservatoryBuildTime = 15
kPhaseGateBuildTime = 12










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
kResourceScaling = 20 //Controls the factoring per player.

//End Resource/Build Timing Stuff

// MARINE DAMAGE
kRifleDamage = 10
kRifleDamageType = kDamageType.Normal
kRifleClipSize = 50
kRifleWeight = 0.01
kRifleClipWeight = 0.01

kPistolDamage = 20
kPistolDamageType = kDamageType.Normal
kPistolClipSize = 10
kPistolWeight = 0.005
kPistolFireDelay = 0.08
kPistolClipWeight = 0.01

kWelderDamage = 4
kWelderDamageType = kDamageType.Normal
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
kShotgunShellWeight = 0.0025

kHeavyMachineGunDamage = 20
kHeavyMachineGunDamageType = kDamageType.HalfStructure
kHeavyMachineGunClipSize = 125
kHeavyMachineGunWeight = 0.05
kHeavyMachineGunROF = 0.05
kHeavyMachineGunReloadTime = 6.3
kHeavyMachineGunClipWeight = 0.035

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
kHandGrenadesWeight = 0.005

kSentryAttackDamage = 10
kSentryAttackDamageType = kDamageType.Light
kSentryAttackBaseROF = 0.33
kSentryAttackRandROF = 0.0
kSentryAttackBulletsPerSalvo = 1
kConfusedSentryBaseROF = 1.0
kSentriesPerFactory = 3

kARCDamage = 400
kARCDamageType = kDamageType.StructuresOnly
kARCRange = 25 //1100 NS1 - Bigger than NS1, dropping to 25
kArcsPerFactory = 5

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

kDropStructureEnergyCost = 5
kGorgeCreateDistance = 3

kBileBombDamage = 200
kBileBombDamageType = kDamageType.StructuresOnly
kBileBombEnergyCost = 22
kBileBombSplashRadius = 6  // 200 inches in NS1 = 5 meters           

kWebSpinnerROF = 0.5
kWebSpinnerEnergyCost = 18
kWebImobilizeTime = 3
kWebEngagementRange = 2
kMinWebLength = 2
kMaxWebLength = 20

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
kPrimalScreamROFIncrease = .3

kSwipeDamage = 80
kSwipeDamageType = kDamageType.Normal
kSwipeEnergyCost = 6.5
kSwipeDelay = 0.48
kSwipeRange = 1.3
kSwipeMeleeBaseWidth = 0.9
kSwipeMeleeBaseHeight = 1

kStartBlinkEnergyCost = 8
kBlinkPulseEnergyCost = 5
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
kGoreRange = 1.7
kGoreMeleeBaseWidth = 1.1
kGoreMeleeBaseHeight = 1.2

kDevourInitialDamage = 10
kDevourDamage = 10
kDevourEnergyCost = 35
kDevourAttackDelay = 2
kDevourDigestionSpeed = 1
kDevourHealthPerSecond = 20
kDevourDamageType = kDamageType.Falling
kDevourRange = 1.2
kDevourMeleeBaseWidth = 0.8
kDevourMeleeBaseHeight = 0.7

kStompEnergyCost = 30
kStompRange = 12
kStunMarineTime = 2

kSmashDamage = 125
kSmashDamageType = kDamageType.Structural
kSmashEnergyCost = 9
kSmashRange = 1.9
kSmashMeleeBaseWidth = 1.1
kSmashMeleeBaseHeight = 1.4

kChargeMaxDamage = 4
kChargeMinDamage = 1

kHydraDamage = 20 // From NS1
kHydraAttackDamageType = kDamageType.Normal

kWhipDamage = 50
kWhipAttackDamageType = kDamageType.Normal
kEmpoweredROFIncrease = 0.25

// SPAWN TIMES
kMarineRespawnTime = 10
kEggSpawnTime = 8
kAlienWaveSpawnInterval = 7
kAlienEggsPerHive = 10