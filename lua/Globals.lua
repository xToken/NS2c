// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Globals.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Utility.lua")

kMaxPlayerSkill = 1000
kMaxPlayerLevel = 100

kDecalMaxLifetime = 60

// All the layouts are based around this screen height.
kBaseScreenHeight = 1080

// Team types - corresponds with teamNumber in editor_setup.xml
kNeutralTeamType = 0
kMarineTeamType = 1
kAlienTeamType = 2
kRandomTeamType = 3

// 2 = Hold Space, 1 = Queued Jumping like Quake, 0 = Default NS2
kJumpMode = { Repeating = 2, Queued = 1, Default = 0 }

// after 5 minutes players are allowed to give up a round
kMinTimeBeforeConcede = 10 * 60
kPercentNeededForVoteConcede = 0.75
kPercentNeededForUpgradeChamberVote = 0.55

// Team colors
kMarineFontName = "fonts/AgencyFB_large.fnt"
kMarineFontColor = Color(0.756, 0.952, 0.988, 1)

kAlienFontName = "fonts/AgencyFB_large.fnt"
kAlienFontColor = Color(0.901, 0.623, 0.215, 1)

kNeutralFontName = "fonts/AgencyFB_large.fnt"
kNeutralFontColor = Color(0.7, 0.7, 0.7, 1)

// Move hit effect slightly off surface we hit so particles don't penetrate. In meters.
kHitEffectOffset = 0.13
// max distance of blood from impact point to nearby geometry
kBloodDistance = 3.5

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
kDefaultPlayerName = "NSPlayer"

kDefaultWaypointGroup = "GroundWaypoints"
kAirWaypointsGroup = "AirWaypoints"

kMaxResources = 200

// Max number of entities allowed in radius. Don't allow creating any more entities if this number is rearched.
// Don't include players in count.
kMaxEntitiesInRadius = 25
kMaxEntityRadius = 15

kWorldMessageLifeTime = 1.0
kCommanderErrorMessageLifeTime = 2.0
kWorldMessageResourceOffset = Vector(0, 2.5, 0)
kResourceMessageRange = 35
kWorldDamageNumberAnimationSpeed = 220
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
kMaxHotkeyGroups = 9

// Surface list. Add more materials here to precache ricochets, bashes, footsteps, etc
// Used with PrecacheMultipleAssets
kSurfaceList = { "door", "electronic", "metal", "organic", "rock", "thin_metal", "membrane", "armor", "flesh", "glass" }

// a longer surface list, for hiteffects only (used by hiteffects network message, don't remove any values)
kHitEffectSurface = enum( { "metal", "door", "electronic", "organic", "rock", "thin_metal", "membrane", "armor", "flesh", "glass", "ethereal", "umbra" } )
kHitEffectRelevancyDistance = 40
kHitEffectMaxPosition = 1638 // used for precision in hiteffect message
kTracerSpeed = 115
kMaxHitEffectsPerSecond = 100

kMainMenuFlash = "ui/main_menu.swf"

kPlayerStatus = enum( { "Hidden", "Dead", "Evolving", "Embryo", "Commander", "Exo", "GrenadeLauncher", "Rifle", "Shotgun", "HeavyMachineGun", "Void", "Spectator", "Skulk", "Gorge", "Fade", "Lerk", "Onos" } )
kPlayerCommunicationStatus = enum( {'None', 'Voice', 'Typing', 'Menu'} )
kSpectatorMode = enum( { 'FreeLook', 'Overhead', 'Following', 'FirstPerson' } )

kMaxAlienAbilities = 3

kNoWeaponSlot = 0
// Weapon slots (marine only). Alien weapons use just regular numbers.
kPrimaryWeaponSlot = 1
kSecondaryWeaponSlot = 2
kTertiaryWeaponSlot = 3

// How long to display weapon picker after selecting weapons
kDisplayWeaponTime = 1.5

// Death message indices 
kDeathMessageIcon = enum( { 'None', 
                            'Rifle', 'RifleButt', 'Pistol', 'Axe', 'Shotgun',
                            'Flamethrower', 'SiegeCannon', 'Grenade', 'Sentry', 'Welder',
                            'Bite', 'HydraSpike', 'Spray', 'Spikes', 'Parasite',
                            'SporeCloud', 'Swipe', 'BuildAbility', 'Whip', 'BileBomb',
                            'Mine', 'Gore', 'Spit', 'Jetpack', 'Claw',
                            'HeavyMachineGun', 'Metabolize', 'LerkBite', 'Umbra', 
                            'Xenocide', 'Blink', 'Leap', 'Stomp',
                            'Consumed', 'GL', 'Recycled', 'Babbler', 'Railgun', 'BabblerAbility', 'GorgeTunnel', 'Devour',
							'HandGrenade', 'GasGrenade', 'PulseGrenade', 'Stab', 'WhipBomb',
                            } )

kMinimapBlipType = enum( { 'Undefined', 'TechPoint', 'ResourcePoint', 'Scan', 'EtherealGate', 'HighlightWorld',
                           'Sentry', 'CommandStation',
                           'Extractor', 'InfantryPortal', 'Armory', 'AdvancedArmory', 'PhaseGate', 'Observatory',
                           'TurretFactory', 'ArmsLab', 'PrototypeLab',
                           'Hive', 'Harvester', 'Hydra', 'Egg', 'Embryo', 'Crag', 'Whip', 'Shade', 'Shift', 'Shell', 'Veil', 'Spur', 'TunnelEntrance',
                           'Marine', 'JetpackMarine', 'HeavyArmorMarine', 'Skulk', 'Lerk', 'Onos', 'Fade', 'Gorge',
                           'Door', 'PowerPoint', 'DestroyedPowerPoint',
                           'SiegeCannon', 'Drifter', 'MAC', 'Infestation', 'InfestationDying', 'MoveOrder', 'AttackOrder', 'BuildOrder', 'SensorBlip', 'SentryBattery', 'Exo' } )

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
kGameEffect = CreateBitMask( {"InUmbra", "Fury", "Cloaked", "Parasite", "NearDeath", "OnFire", "OnInfestation", "Beacon", "Energize", "Max"} )
kGameEffectMax = bit.lshift( 1, GetBitMaskNumBits(kGameEffect) )

// Stackable game effects (more than one can be active, server-side only)
kFuryGameEffect = "fury"
kMaxStackLevel = 10

kMaxEntityStringLength = 32
kMaxAnimationStringLength = 32

// Team alert types
kAlertType = enum( {'Attack', 'Info', 'Request'} )

// Dynamic light modes for power grid
kLightMode = enum( {'Normal', 'NoPower', 'LowPower', 'Damaged'} )

// Game state
kGameState = enum( {'NotStarted', 'PreGame', 'Countdown', 'Started', 'Team1Won', 'Team2Won', 'Draw'} )

// Game modes for different ingame goals.
kGameMode = enum( { 'Classic', 'Combat' } )

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
kCommanderInvisibleGroupName = "CommanderInvisible"
kCommanderInvisibleVentsGroupName = "CommanderInvisibleVents"
// Any geometry or props with this name will not support being built on top of
kCommanderNoBuildGroupName = "CommanderNoBuild"
kCommanderBuildGroupName = "CommanderBuild"

// invisible and blocks all movement
kMovementCollisionGroupName = "MovementCollisionGeometry"
// same as 'MovementCollisionGeometry'
kCollisionGeometryGroupName = "CollisionGeometry"
// invisible, blocks anything default geometry would block
kInvisibleCollisionGroupName = "InvisibleGeometry"
// visible and won't block anything
kNonCollisionGeometryGroupName = "NonCollisionGeometry"

kPathingLayerName = "Pathing"

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

kInventoryIconsTexture = "ui/inventory_icons.dds"
kInventoryIconTextureWidth = 128
kInventoryIconTextureHeight = 64

// Options keys
kNicknameOptionsKey = "nickname"
kVisualDetailOptionsKey = "visualDetail"
kSoundInputDeviceOptionsKey = "sound/input-device"
kSoundOutputDeviceOptionsKey = "sound/output-device"
kSoundVolumeOptionsKey = "soundVolume"
kMusicVolumeOptionsKey = "musicVolume"
kVoiceVolumeOptionsKey = "voiceVolume"
kDisplayOptionsKey = "graphics/display/display"
kWindowModeOptionsKey = "graphics/display/window-mode"
kDisplayQualityOptionsKey = "graphics/display/quality"
kInvertedMouseOptionsKey = "input/mouse/invert"
kLastServerConnected = "lastConnectedServer"
kLastServerPassword  = "lastServerPassword"
kLastServerMapName  = "lastServerMapName"

kPhysicsGpuAccelerationKey = "physics/gpu-acceleration"
kGraphicsXResolutionOptionsKey = "graphics/display/x-resolution"
kGraphicsYResolutionOptionsKey = "graphics/display/y-resolution"
kAntiAliasingOptionsKey = "graphics/display/anti-aliasing"
kAtmosphericsOptionsKey = "graphics/display/atmospherics"
kShadowsOptionsKey = "graphics/display/shadows"
kShadowFadingOptionsKey = "graphics/display/shadow-fading"
kBloomOptionsKey = "graphics/display/bloom"
kAnisotropicFilteringOptionsKey = "graphics/display/anisotropic-filtering"

kMouseSensitivityScalar         = 50

// Player use range
kPlayerUseRange = 2
kMaxPitch = (math.pi / 2) - math.rad(3)

// Pathing flags
kPathingFlags = enum ({'UnBuildable', 'UnPathable', 'Blockable'})

// How far from the order location must units be to complete it.
kAIMoveOrderCompleteDistance = 0.01
kPlayerMoveOrderCompleteDistance = 1.5

// Statistics
kStatisticsURL = "http://sponitor2.herokuapp.com/api/send"

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

kMinFOVAdjustmentDegrees = -5
kMaxFOVAdjustmentDegrees = 5
kDamageEffectType = enum({ 'Blood', 'AlienBlood', 'Sparks' })

kIconColors = 
{
    [kMarineTeamType] = Color(0.8, 0.96, 1, 1),
    [kAlienTeamType] = Color(1, 0.9, 0.4, 1),
    [kNeutralTeamType] = Color(1, 1, 1, 1),
}

//----------------------------------------
//  DLC stuff
//----------------------------------------

function GetHasDLC(productId, client)

    if productId == nil then
        return true
    end
    
    if Client then
    
        assert(client == nil)
        return Client.GetIsDlcAuthorized(productId)
        
    elseif Server and client then
    
        assert(client ~= nil)
        return Server.GetIsDlcAuthorized(client, productId)
        
    else
        return false
    end
    
end

kSpecialEditionProductId = 4930
kDeluxeEditionProductId = 4932
kShoulderPadProductId = 250891
kAssaultMarineProductId = 250892
kShadowProductId = 250893

// DLC player variants
// "code" is the key

// TODO we can really just get rid of the enum. use array-of-structures pattern, and use #kMarineVariants to network vars

kMarineVariant = enum({ "green", "special", "deluxe", "assault", "eliteassault" })
kMarineVariantData =
{
    [kMarineVariant.green] = { productId = nil, displayName = "Green", modelFilePart = "", viewModelFilePart = "" },
    [kMarineVariant.special] = { productId = kSpecialEditionProductId, displayName = "Black", modelFilePart = "_special", viewModelFilePart = "_special" },
    [kMarineVariant.deluxe] = { productId = kDeluxeEditionProductId, displayName = "Deluxe", modelFilePart = "_special_v1", viewModelFilePart = "_deluxe" },
    [kMarineVariant.assault] = { productId = kAssaultMarineProductId, displayName = "Assault", modelFilePart = "_assault", viewModelFilePart = "_assault" },
    [kMarineVariant.eliteassault] = { productId = kShadowProductId, displayName = "Elite Assault", modelFilePart = "_eliteassault", viewModelFilePart = "_eliteassault" },
}
kDefaultMarineVariant = kMarineVariant.green

kSkulkVariant = enum({ "normal", "shadow" })
kSkulkVariantData =
{
    [kSkulkVariant.normal] = { productId = nil, displayName = "Normal", modelFilePart = "", viewModelFilePart = "" },
    [kSkulkVariant.shadow] = { productId = kShadowProductId, displayName = "Shadow", modelFilePart = "_shadow", viewModelFilePart = "" },
}
kDefaultSkulkVariant = kSkulkVariant.normal

kGorgeVariant = enum({ "normal", "shadow" })
kGorgeVariantData =
{
    [kGorgeVariant.normal] = { productId = nil, displayName = "Normal", modelFilePart = "", viewModelFilePart = "" },
    [kGorgeVariant.shadow] = { productId = kShadowProductId, displayName = "Shadow", modelFilePart = "_shadow", viewModelFilePart = "" }
}
kDefaultGorgeVariant = kGorgeVariant.normal

kLerkVariant = enum({ "normal", "shadow" })
kLerkVariantData =
{
    [kLerkVariant.normal] = { productId = nil, displayName = "Normal", modelFilePart = "", viewModelFilePart = "" },
    [kLerkVariant.shadow] = { productId = kShadowProductId, displayName = "Shadow", modelFilePart = "_shadow", viewModelFilePart = "" }
}
kDefaultLerkVariant = kLerkVariant.normal

function FindVariant( data, displayName )

    for var, data in pairs(data) do
        if data.displayName == displayName then
            return var
        end
    end
    return nil

end

function GetVariantName( data, var )
    return data[var].displayName
end

function GetHasVariant(data, var, client)
    return GetHasDLC(data[var].productId, client)
end

kShoulderPad2ProductId =
{
    kShoulderPadProductId,
    kShadowProductId,
}
function GetHasShoulderPad(index, client)
    return GetHasDLC( kShoulderPad2ProductId[index], client )
end

kHUDMode = enum({ "Full", "Minimal" })

