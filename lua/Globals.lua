// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Globals.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Utility.lua")

// All the layouts are based around this screen height.
kBaseScreenHeight = 1080

// Team types - corresponds with teamNumber in editor_setup.xml
kNeutralTeamType = 0
kMarineTeamType = 1
kAlienTeamType = 2
kRandomTeamType = 3

// Team colors
kMarineFontName = "fonts/AgencyFB_large.fnt"
kMarineFontColor = Color(0.756, 0.952, 0.988, 1)

kAlienFontName = "fonts/AgencyFB_large.fnt"
kAlienFontColor = Color(0.901, 0.623, 0.215, 1)

kNeutralFontName = "fonts/AgencyFB_large.fnt"
kNeutralFontColor = Color(0.7, 0.7, 0.7, 1)

// Move hit effect slightly off surface we hit so particles don't penetrate. In meters.
kHitEffectOffset = 0.13

kCommanderPingDuration = 12

kCommanderColor = 0xFFFF00
kCommanderColorFloat = Color(1,1,0,1)
kMarineTeamColor = 0x4DB1FF
kMarineTeamColorFloat = Color(0.302, 0.859, 1)
kAlienTeamColor = 0xFFCA3A
kAlienTeamColorFloat = Color(1, 0.792, 0.227)
kNeutralTeamColor = 0xEEEEEE
kChatPrefixTextColor = 0xFFFFFF
kChatTextColor = { [kNeutralTeamType] = kNeutralFontColor,
                   [kMarineTeamType] = kMarineFontColor,
                   [kAlienTeamType] = kAlienFontColor }
kNewPlayerColor = 0x00DC00
kNewPlayerColorFloat = Color(0, 0.862, 0, 1)
kChatTypeTextColor = 0xDD4444
kFriendlyColor = 0xFFFFFF
kNeutralColor = 0xAAAAFF
kEnemyColor = 0xFF0000
kParasitedTextColor = 0xFFEB7F

kParasiteColor = Color(1, 1, 0, 1)
kPoisonedColor = Color(0, 1, 0, 1)

kCountDownLength = 6

// Team numbers and indices
kTeamInvalid = -1
kTeamReadyRoom = 0
kTeam1Index = 1
kTeam2Index = 2
kSpectatorIndex = 3

// Marines vs. Aliens
kTeam1Type = kMarineTeamType
kTeam2Type = kAlienTeamType

// Used for playing team and scoreboard
kTeam1Name = "Frontiersmen"
kTeam2Name = "Kharaa"
kSpectatorTeamName = "Ready room"
kDefaultPlayerName = "NsPlayer"

kDefaultWaypointGroup = "GroundWaypoints"
kAirWaypointsGroup = "AirWaypoints"

kMaxResources = 999

// Max number of entities allowed in radius. Don't allow creating any more entities if this number is rearched.
// Don't include players in count.
kMaxEntitiesInRadius = 25
kMaxEntityRadius = 15

kWorldMessageLifeTime = 1.0
kWorldMessageResourceOffset = Vector(0, 2.5, 0)
kResourceMessageRange = 35
kWorldDamageNumberAnimationSpeed = 150
// Updating messages with new numbers shouldn't reset animation - keep it big and faded-in intead of growing
kWorldDamageRepeatAnimationScalar = .1

// Max player name
kMaxNameLength = 20
kMaxScore = 9999
kMaxKills = 254
kMaxDeaths = 254
kMaxPing = 999

kMaxChatLength = 80
kMaxHiveNameLength = 30
kMaxHotkeyGroups = 5

// Surface list. Add more materials here to precache ricochets, bashes, footsteps, etc
// Used with PrecacheMultipleAssets
kSurfaceList = { "door", "electronic", "metal", "organic", "rock", "thin_metal", "membrane", "armor", "flesh", "glass" }

// a longer surface list, for hiteffects only (used by hiteffects network message, don't remove any values)
kHitEffectSurface = enum( { "metal", "door", "electronic", "organic", "rock", "thin_metal", "membrane", "armor", "flesh", "glass", "ethereal", "umbra" } )
kHitEffectRelevancyDistance = 40
kHitEffectMaxPosition = 1638 // used for precision in hiteffect message
kTracerSpeed = 75
kMaxHitEffectsPerSecond = 200

kMainMenuFlash = "ui/main_menu.swf"

kPlayerStatus = enum( { "Hidden", "Dead", "Evolving", "Embryo", "Commander", "HeavyArmor", "GrenadeLauncher", "Rifle", "Shotgun", "HeavyMachineGun", "Void", "Spectator", "Skulk", "Gorge", "Fade", "Lerk", "Onos" } )
kPlayerCommunicationStatus = enum( {'None', 'Voice', 'Typing', 'Menu'} )

kMaxAlienAbilities = 3

kNoWeaponSlot = 0
// Weapon slots (marine only). Alien weapons use just regular numbers.
kPrimaryWeaponSlot = 1
kSecondaryWeaponSlot = 2
kTertiaryWeaponSlot = 3

// How long to display weapon picker after selecting weapons
kDisplayWeaponTime = 1.5

// If player bought Special Edition
kSpecialEditionProductId = 4930

// Death message indices 
kDeathMessageIcon = enum( {'None', 'Rifle', 'RifleButt',
                           'Pistol', 'Axe', 'Shotgun',
                           'Flamethrower', 'ARC', 'Grenade',
                           'Sentry', 'Welder', 'Bite',
                           'HydraSpike', 'Spray', 'Spikes',
                           'PoisonDart', 'SporeCloud', 'SwipeBlink',
                           'Consumed', 'Whip', 'BileBomb', 'Mine',
                           'Gore', 'Spit', 'Jetpack', 'Claw', 'HeavyMachineGun' } )

kMinimapBlipType = enum( { 'Undefined', 'TechPoint', 'ResourcePoint', 'Scan',
                           'Sentry', 'CommandStation', 'CommandStationL2', 'CommandStationL3',
						   'Extractor', 'InfantryPortal', 'Armory', 'PhaseGate', 'Observatory',
						   'RoboticsFactory', 'ArmsLab', 'PrototypeLab', 'PowerPack',
                           'Hive', 'Harvester', 'Hydra', 'Egg', 'Crag', 'Whip', 'Shade', 'Shift',
                           'Marine', 'JetpackMarine', 'HeavyArmorMarine', 'Jetpack', 'Skulk', 'Lerk', 'Onos', 'Fade', 'Gorge',
                           'Door', 'PowerPoint', 'DestroyedPowerPoint',
                           'ARC', 'Drifter', 'MAC', 'Infestation', 'InfestationDying', 'MoveOrder', 'AttackOrder', 'BuildOrder', 'SensorBlip' } )

// Friendly IDs
// 0 = friendly
// 1 = enemy
// 2 = neutral
// for spectators is used Marine and Alien
kMinimapBlipTeam = enum( {'Friendly', 'Enemy', 'Neutral', 'Alien', 'Marine' } )

// How long commander alerts should last (from NS1)
kAlertExpireTime = 20

// Bit mask table for non-stackable game effects.
// Always keep "Max" as last element.
kGameEffect = CreateBitMask( {"InUmbra", "Fury", "Cloaked", "Parasite", "NearDeath", "Beacon", "Energize", "Max"} )
kGameEffectMax = bit.rshift(kGameEffect.Max, 1)

// Stackable game effects (more than one can be active, server-side only)
kFuryGameEffect = "fury"
kMaxStackLevel = 10

kMaxEntityStringLength = 32
kMaxAnimationStringLength = 32

// Player modes. When outside the default player mode, input isn't processed from the player
kPlayerMode = enum( {'Default', 'Taunt', 'Knockback', 'StandUp'} )

// Team alert types
kAlertType = enum( {'Attack', 'Info', 'Request'} )

// Dynamic light modes for power grid
kLightMode = enum( {'Normal', 'NoPower', 'LowPower', 'Damaged'} )

// Game state
kGameState = enum( {'NotStarted', 'PreGame', 'Countdown', 'Started', 'Team1Won', 'Team2Won', 'Draw'} )

// Don't allow commander to build structures this close to attach points or other structures
kBlockAttachStructuresRadius = 3

// Marquee while active, to ensure we get mouse release event even if on top of other component
kHighestPriorityZ = 3

// How often to send kills, deaths, nick name changes, etc. for scoreboard
kScoreboardUpdateInterval = 1

// How often to send ping updates to individual players
kUpdatePingsIndividual = 3

// How often to send ping updates to all players.
kUpdatePingsAll = 10

kStructureSnapRadius = 4

// Only send friendly blips down within this range 
kHiveSightMaxRange = 50
kHiveSightMinRange = 3
kHiveSightDamageTime = 8

// Bit masks for relevancy checking
kRelevantToTeam1Unit        = 1
kRelevantToTeam2Unit        = 2
kRelevantToTeam1Commander   = 4
kRelevantToTeam2Commander   = 8
kRelevantToTeam1            = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam1Commander)
kRelevantToTeam2            = bit.bor(kRelevantToTeam2Unit, kRelevantToTeam2Commander)
kRelevantToReadyRoom        = 16

// Hive sight constants
kBlipType = enum( {'Undefined', 'Friendly', 'FriendlyUnderAttack', 'Sighted', 'TechPointStructure', 'NeedHealing', 'FollowMe', 'Chuckle', 'Pheromone', 'Parasited' } )

kFeedbackURL = "http://getsatisfaction.com/unknownworlds/feedback/topics/new?product=unknownworlds_natural_selection_2&display=layer&style=idea&custom_css=http://www.unknownworlds.com/game_scripts/ns2/styles.css"

// Used for menu on top of class (marine or alien buy menus or out of game menu) 
kMenuFlashIndex = 2

// Fade to black time (then to spectator mode)
kFadeToBlackTime = 3

// Constant to prevent z-fighting 
kZFightingConstant = 0.1

// Any geometry or props with this name won't be drawn or affect commanders
kCommanderInvisibleGroupName    = "CommanderInvisible"
// Any geometry or props with this name will not support being built on top of
kCommanderNoBuildGroupName      = "CommanderNoBuild"
kCommanderBuildGroupName        = "CommanderBuild"

kCollisionGeometryGroupName     = "CollisionGeometry"
kNonCollisionGeometryGroupName  = "NonCollisionGeometry"

// Max players allowed in game
kMaxPlayers = 32

kMaxIdleWorkers = 127
kMaxPlayerAlerts = 127

// Max distance to propagate entities with
kMaxRelevancyDistance = 40

kEpsilon = 0.0001

// Weapon spawn height (for Commander dropping weapons)
kCommanderDropSpawnHeight = 0.08
kCommanderEquipmentDropSpawnHeight = 0.5

// Options keys
kNicknameOptionsKey = "nickname"
kVisualDetailOptionsKey = "visualDetail"
kSoundVolumeOptionsKey = "soundVolume"
kMusicVolumeOptionsKey = "musicVolume"
kVoiceVolumeOptionsKey = "voiceVolume"
kWindowModeOptionsKey = "graphics/display/window-mode"
kDisplayQualityOptionsKey = "graphics/display/quality"
kInvertedMouseOptionsKey = "input/mouse/invert"
kLastServerConnected = "lastConnectedServer"
kLastServerPassword  = "lastServerPassword"

kGraphicsXResolutionOptionsKey = "graphics/display/x-resolution"
kGraphicsYResolutionOptionsKey = "graphics/display/y-resolution"
kAntiAliasingOptionsKey = "graphics/display/anti-aliasing"
kAtmosphericsOptionsKey = "graphics/display/atmospherics"
kShadowsOptionsKey = "graphics/display/shadows"
kShadowFadingOptionsKey = "graphics/display/shadow-fading"
kBloomOptionsKey = "graphics/display/bloom"
kAnisotropicFilteringOptionsKey = "graphics/display/anisotropic-filtering"

kMouseSensitivityScalar         = 50
kAutoPickupWeapons         = "autopickupweapons"

// Player use range
kPlayerUseRange = 2
kMaxPitch = (math.pi / 2) - math.rad(3)

// Pathing flags
kPathingFlags = enum ({'UnBuildable', 'UnPathable', 'Blockable'})

// How far from the order location must units be to complete it.
kAIMoveOrderCompleteDistance = 0.01
kPlayerMoveOrderCompleteDistance = 1.5

// Statistics
kStatisticsURL = "http://strong-ocean-7422.herokuapp.com"

kCatalyzURL = "https://catalyz.herokuapp.com/v1"

kResourceType = enum( {'Team', 'Personal', 'Energy', 'Ammo'} )

kNameTagFontColors = { [kMarineTeamType] = kMarineFontColor,
                       [kAlienTeamType] = kAlienFontColor,
                       [kNeutralTeamType] = kNeutralFontColor }

kNameTagFontNames = { [kMarineTeamType] = kMarineFontName,
                      [kAlienTeamType] = kAlienFontName,
                      [kNeutralTeamType] = kNeutralFontName }

kHealthBarColors = { [kMarineTeamType] = Color(0.725, 0.921, 0.949, 1),
                     [kAlienTeamType] = Color(0.776, 0.364, 0.031, 1),
                     [kNeutralTeamType] = Color(1, 1, 1, 1) }
                     
kArmorBarColors = { [kMarineTeamType] = Color(0.078, 0.878, 0.984, 1),
                    [kAlienTeamType] = Color(0.576, 0.194, 0.011, 1),
                    [kNeutralTeamType] = Color(0.5, 0.5, 0.5, 1) }

// used for specific effects
kUseInterval = 0.1

kPlayerLOSDistance = 20
kStructureLOSDistance = 2.5

kGestateCameraDistance = 1.75

// Rookie mode
kRookieSaveInterval = 30 // seconds
kRookieTimeThreshold = 4 * 60 * 60 // 4 hours
kRookieNetworkCheckInterval = 2
kRookieOptionsKey = "rookieMode"