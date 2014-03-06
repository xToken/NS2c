// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======		
//		
// lua\BalanceHealth.lua		
//		
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)		
//		
// Auto-generated. Copy and paste from balance spreadsheet.		
//		
// ========= For more information, visit us at http://www.unknownworlds.com =====================		

//NS2c
//Restructured this file heavily, attempted to remove all unused vars
		
// HEALTH AND ARMOR		
kMarineHealth = 100	     kMarineArmor = 30	    kMarinePointValue = 2
kJetpackHealth = 100	 kJetpackArmor = 30	    kJetpackPointValue = 2
kHeavyArmorHealth = 100  kHeavyArmorArmor = 200 kHeavyArmorPointValue = 2
kExosuitHealth = 100     kExosuitArmor = 70     kExosuitPointValue = 2

kSkulkHealth = 70	    kSkulkArmor = 10	    kSkulkPointValue = 2
kGorgeHealth = 150	    kGorgeArmor = 70	    kGorgePointValue = 2
kLerkHealth = 125	    kLerkArmor = 30	        kLerkPointValue = 2
kFadeHealth = 300	    kFadeArmor = 150	    kFadePointValue = 2
kOnosHealth = 950	    kOnosArmor = 700	    kOnosPointValue = 2

kEmbryoHealth = 200     kEmbryoArmor = 150      kEggPointValue = 0
kEggHealth = 200	    kEggArmor = 0    	    kEggPointValue = 0
kBabblerHealth = 20	    kBabblerArmor = 0	    kBabblerPointValue = 0
kBabblerEggHealth = 200	kBabblerEggArmor = 100	kBabblerEggPointValue = 0

kArmorPerUpgradeLevel = 20
kHeavyArmorPerUpgradeLevel = 30
kExosuitArmorPerUpgradeLevel = 25
kArmorHealScalar = 1 // 0.75

kBuildPointValue = 5
kRecyclePaybackScalar = 0.5
kRepairMarineArmorPointValue = 1

kSkulkArmorFullyUpgradedAmount = 30
kGorgeArmorFullyUpgradedAmount = 120
kLerkArmorFullyUpgradedAmount = 50
kFadeArmorFullyUpgradedAmount = 220
kOnosArmorFullyUpgradedAmount = 900

//This handles old alien armor scaling in a more elegant way, and one that the player can see instantly.
//This is additive, so anything above 0 will add the according amount of the classes base armor to its HP.
kAlienHealthPerArmorHive1 = 0
kAlienHealthPerArmorHive2 = 0
kAlienHealthPerArmorHive3 = 1
kAlienHealthPerArmorHive4 = 2

// used for structures
kStartHealthScalar = 0.3

kExtractorHealth = 5500	kExtractorArmor = 0	kExtractorPointValue = 15
kArmoryHealth = 2400	kArmoryArmor = 0	kArmoryPointValue = 10
kAdvancedArmoryHealth = 4000	kAdvancedArmoryArmor = 0	kAdvancedArmoryPointValue = 40
kCommandStationHealth = 8000	kCommandStationArmor = 1000	kCommandStationPointValue = 25
kObservatoryHealth = 1700	kObservatoryArmor = 0	kObservatoryPointValue = 15
kPhaseGateHealth = 3000	kPhaseGateArmor = 0	kPhaseGatePointValue = 20
kTurretFactoryHealth = 3000	kTurretFactoryArmor = 0	kTurretFactoryPointValue = 20
kAdvancedTurretFactory = 3000	kAdvancedTurretFactoryArmor = 0	kAdvancedTurretFactoryPointValue = 20
kPrototypeLabHealth = 4000	kPrototypeLabArmor = 0	kPrototypeLabPointValue = 20
kInfantryPortalHealth = 2500	kInfantryPortalArmor = 0	kInfantryPortalPointValue = 15
kArmsLabHealth = 2200	kArmsLabArmor = 0	kArmsLabPointValue = 20
kSentryHealth = 1100	kSentryArmor = 0 kSentryPointValue = 10
kSiegeCannonHealth = 2000	kSiegeCannonArmor = 0	kSiegeCannonPointValue = 20
kMineHealth = 70	kMineArmor = 0	kMinePointValue = 2

// 5000/1000 is good average (is like 7,000 health from NS1, but protects somewhat from shotguns)
// Hives start out about -21% and go to +25%
kHiveHealth = 7000	kHiveArmor = 0	kHivePointValue = 30
kHarvesterHealth = 2500	kHarvesterArmor = 0	kHarvesterPointValue = 15
kCragHealth = 1200	kCragArmor = 0	kCragPointValue = 10
kShiftHealth = 1000	kShiftArmor = 0	kShiftPointValue = 10
kShadeHealth = 800	kShadeArmor = 0	kShadePointValue = 10
kWhipHealth  = 1100	kWhipArmor = 0	kWhipPointValue = 10
kHydraHealth = 1000	kHydraArmor = 0	kHydraPointValue = 10
kWebHealth = 1     kWebArmor = 0   kWebPointValue = 0