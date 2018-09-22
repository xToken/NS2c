-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\TechTreeConstants.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Added in techIds required by classic

local gTechIdToString = {}

local function createTechIdEnum(table)

    for i = 1, #table do
        gTechIdToString[table[i]] = i
    end

    return enum(table)

end

kTechId = createTechIdEnum({
    
    'None', 'PingLocation',
    
    'VoteConcedeRound',
    
    'SpawnMarine', 'SpawnAlien', 'CollectResources', 'Research',
    
    -- General orders and actions ("Default" is right-click)
    'Default', 'Move', 'Patrol', 'Attack', 'Build', 'Construct', 'AutoConstruct', 'Cancel', 'Recycle', 'Weld', 'AutoWeld', 'Stop', 'SetRally', 'SetTarget', 'Follow',
    -- special mac order (follows the target, welds the target as priority and others in range)
    'FollowAndWeld',
    
    -- Alien specific orders
    'AlienMove', 'AlienAttack', 'AlienConstruct', 'Heal', 'AutoHeal',
    
    -- Commander menus for selected units
    'RootMenu', 'BuildMenu', 'AdvancedMenu', 'AssistMenu', 'MarkersMenu', 'UpgradesMenu', 'WeaponsMenu',
    
    --Turret factory menus
    'UpgradeTurretFactory',

    'ReadyRoomPlayer', 'ReadyRoomEmbryo', 'ReadyRoomExo',
    
    -- Doors
    'Door', 'DoorOpen', 'DoorClose', 'DoorLock', 'DoorUnlock',

    --Misc
    'ResourcePoint', 'TechPoint', 'Mine', 'Web',
    
    ------------/
    -- Marines --
    ------------/
    
    --Marine classes + spectators
    'Marine', 'HeavyArmorMarine', 'MarineCommander', 'JetpackMarine', 'Spectator', 'AlienSpectator', 'Exo', "AllMarines",
    
    -- Marine alerts (specified alert sound and text in techdata if any)
    'MarineAlertAcknowledge', 'MarineAlertNeedMedpack', 'MarineAlertNeedAmmo', 'MarineAlertNeedOrder', 'MarineAlertHostiles', 'MarineCommanderEjected', 'MACAlertConstructionComplete',    
    'MarineAlertSentryFiring', 'MarineAlertCommandStationUnderAttack',  'MarineAlertSoldierLost', 'MarineAlertCommandStationComplete',
    
    'MarineAlertInfantryPortalUnderAttack', 'MarineAlertSentryUnderAttack', 'MarineAlertStructureUnderAttack', 'MarineAlertExtractorUnderAttack', 'MarineAlertSoldierUnderAttack',
    
    'MarineAlertResearchComplete', 'MarineAlertManufactureComplete', 'MarineAlertUpgradeComplete', 'MarineAlertOrderComplete', 'MarineAlertWeldingBlocked', 'MarineAlertMACBlocked', 'MarineAlertNotEnoughResources', 'MarineAlertObjectiveCompleted', 'MarineAlertConstructionComplete',
    
    -- Marine orders
    'Defend',
    
    -- Special tech
    'TwoCommandStations', 'ThreeCommandStations',

    -- Marine tech
    'CommandStation', 'Armory', 'InfantryPortal', 'Extractor', 'Sentry', 'SiegeCannon',
    'Scan', 'AmmoPack', 'MedPack', 'CatPack', 'CatPackTech', 'AdvancedArmoryUpgrade', 'Observatory', 'Detector', 'DistressBeacon', 'PhaseGate', 'TurretFactory', 'AdvancedTurretFactory', 'ArmsLab',
    'PrototypeLab', 'AdvancedArmory', 'HandGrenadesTech', 'Electrify', 
    
    -- Research 
    'PhaseTech', 'Jetpack', 'JetpackTech','HeavyArmorTech', 'HeavyArmor', 'ExosuitTech', 'Exosuit', 'ShotgunTech', 'MinesTech', 'GrenadeTech',
    
    -- Weapons 
    'Rifle', 'Pistol', 'Shotgun', 'GrenadeLauncher', 'Axe', 'Mines', 'Minigun', 'Railgun', 'Claw', 'Welder', 'HeavyMachineGun', 'HandGrenades', 'Flamethrower',
    
    -- Marine upgrades
    'Weapons1', 'Weapons2', 'Weapons3', 'Armor1', 'Armor2', 'Armor3', 'MotionTracking', 
    
    ------------
    -- Aliens --
    ------------

    -- Alien lifeforms
    'Skulk', 'Gorge', 'Lerk', 'Fade', 'Onos', "AllAliens",
    
    -- Special tech
    'TwoHives', 'ThreeHives', 'UpgradeToCragHive', 'UpgradeToShadeHive', 'UpgradeToShiftHive', 'UpgradeToWhipHive',
    
    -- Alien abilities (not all are needed, only ones with damage types)
    'Bite', 'LerkBite', 'Parasite',  'Spit', 'BuildAbility', 'Spray', 'Spores', 'HydraSpike', 'Swipe', 'Gore', 'Smash', 'Devour', 'BabblerAbility', 'MetabolizeHealth', 'MetabolizeEnergy', 'BoneShield',

    -- upgradeable alien abilities (need to be unlocked)
    'BileBomb', 'Leap', 'Blink', 'Stomp', 'Spikes', 'Umbra', 'Metabolize', 'Xenocide', 'AcidRocket', 'WebStalk', 'Charge', 'PrimalScream',
    'Babbler', 'BabblerEgg',
    
    -- Alien structures 
    'Hive', 'CragHive', 'ShadeHive', 'ShiftHive', 'WhipHive','Harvester', 'Egg', 'Embryo', 'Hydra',
    'GorgeEgg', 'LerkEgg', 'FadeEgg', 'OnosEgg',
    
    -- Upgrade buildings and abilities (structure, upgraded structure, passive, triggered, targeted)
    'Crag', 'CragHeal', 'Shift', 'ShiftTeleport', 'Shade', 'ShadeDisorient', 'Whip',
  
    -- Alien abilities and upgrades
    'Carapace', 'Regeneration', 'Redemption', 'Silence', 'Celerity', 'Adrenaline', 'Focus', 'Camouflage', 'Aura', 'Silence2', 'Fury', 'Bombard', 'Redeployment', 'Ghost', 
    
    -- Alien alerts
    'AlienAlertNeedHealing', 'AlienAlertStructureUnderAttack', 'AlienAlertHiveUnderAttack', 'AlienAlertHiveDying', 'AlienAlertHarvesterUnderAttack',
    'AlienAlertLifeformUnderAttack', 'AlienAlertGorgeBuiltHarvester', 'AlienCommanderEjected',
    'AlienAlertOrderComplete', 'AlienAlertEnemyApproaches',
    'AlienAlertNotEnoughResources', 'AlienAlertResearchComplete', 'AlienAlertManufactureComplete', 'AlienAlertUpgradeComplete', 'AlienAlertHiveComplete', 'AlienAlertHiveSpecialComplete', 
    
    -- Voting commands
    'VoteDownCommander1', 'VoteDownCommander2', 'VoteDownCommander3',
    
    'GameStarted',
    
    'DeathTrigger',
	-- CRAP
	'Hallucinate', 'ARC', 'MAC', 'GasGrenade', 'WhipBomb', 'EnzymeCloud', 'MucousMembrane', 'NutrientMist', 'Rupture', 'LayMines', 'PulseGrenade', 'ClusterGrenade', 'Stab', 'ClusterGrenadeProjectile', 'GasGrenadeProjectile', 'PulseGrenadeProjectile',
	'BioMassOne', 'BioMassTwo', 'BioMassThree', 'BioMassFour', 'BioMassFive', 'BioMassSix', 'BioMassSeven', 'BioMassEight', 'BioMassNine', 'BioMassTen', 'BioMassEleven', 'BioMassTwelve', 'AdvancedWeaponry', 'DrifterEgg', 'ARCRoboticsFactory',

    -- Maximum index
    'Max'
    
    })
    
function StringToTechId(string)
    return gTechIdToString[string] or kTechId.None
end

-- Increase techNode network precision if more needed
kTechIdMax  = kTechId.Max

-- Tech types
kTechType = enum({ 'Invalid', 'Order', 'Research', 'Upgrade', 'Action', 'Buy', 'Build', 'EnergyBuild', 'Manufacture', 'Activation', 'Menu', 'EnergyManufacture', 'PlasmaManufacture', 'Special', 'Passive' })

-- Button indices
kRecycleCancelButtonIndex   = 12
kMarineUpgradeButtonIndex   = 5
kAlienBackButtonIndex       = 8

