// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Globals.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/GUIAssets.lua")

kDefaultPlayerSkill = 1000
kMaxPlayerSkill = 3000
kMaxPlayerLevel = 300

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
kMinTimeBeforeConcede = 5 * 60
kMaxTimeBeforeReset = 3 * 60
kPercentNeededForVoteConcede = 0.75
kPercentNeededForUpgradeChamberVote = 0.55

// Team colors
kMarineFontName = Fonts.kAgencyFB_Large
kMarineFontColor = Color(0.756, 0.952, 0.988, 1)

kAlienFontName = Fonts.kAgencyFB_Large
kAlienFontColor = Color(0.901, 0.623, 0.215, 1)

kNeutralFontName = Fonts.kAgencyFB_Large
kNeutralFontColor = Color(0.7, 0.7, 0.7, 1)

kSteamFriendColor = Color(1, 1, 1, 1)

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

kMaxChatLength = 120
kMaxHiveNameLength = 30
kMaxHotkeyGroups = 9

// Surface list. Add more materials here to precache ricochets, bashes, footsteps, etc
// Used with PrecacheMultipleAssets
kSurfaceList = { "door", "electronic", "metal", "organic", "rock", "thin_metal", "membrane", "armor", "flesh", "flame", "infestation", "glass" }
kSurfaces = enum(kSurfaceList)

// a longer surface list, for hiteffects only (used by hiteffects network message, don't remove any values)
kHitEffectSurface = enum( { "metal", "door", "electronic", "organic", "rock", "thin_metal", "membrane", "armor", "flesh", "glass", "ethereal", "umbra" } )
kHitEffectRelevancyDistance = 40
kHitEffectMaxPosition = 1638 // used for precision in hiteffect message
kTracerSpeed = 115
kMaxHitEffectsPerSecond = 25

kMainMenuFlash = "ui/main_menu.swf"

kPlayerStatus = enum( { "Hidden", "Dead", "Evolving", "Embryo", "Commander", "Exo", "GrenadeLauncher", "Rifle", "Shotgun", "Flamethrower", "Void", "Spectator", "Skulk", "Gorge", "Fade", "Lerk", "Onos", "SkulkEgg", "GorgeEgg", "FadeEgg", "LerkEgg", "OnosEgg" } )
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
							'HandGrenade', 'GasGrenade', 'PulseGrenade', 'Stab', 'WhipBomb', 'Metabolize', 'Crush'
                            } )

kMinimapBlipType = enum( { 'Undefined', 'TechPoint', 'ResourcePoint', 'Scan', 'EtherealGate', 'HighlightWorld',
                           'Sentry', 'CommandStation',
                           'Extractor', 'InfantryPortal', 'Armory', 'AdvancedArmory', 'PhaseGate', 'Observatory',
                           'TurretFactory', 'ArmsLab', 'PrototypeLab',
                           'Hive', 'Harvester', 'Hydra', 'Egg', 'Embryo', 'Crag', 'Whip', 'Shade', 'Shift', 'Shell', 'Veil', 'Spur', 'TunnelEntrance', 'BoneWall',
                           'Marine', 'JetpackMarine', 'HeavyArmorMarine', 'Skulk', 'Lerk', 'Onos', 'Fade', 'Gorge',
                           'Door', 'PowerPoint', 'DestroyedPowerPoint', 'UnsocketedPowerPoint', 
                           'BlueprintPowerPoint', 'SiegeCannon', 'Drifter', 'MAC', 'Infestation', 'InfestationDying', 'MoveOrder', 'AttackOrder', 'BuildOrder', 'SensorBlip', 'SentryBattery' } )

// Friendly IDs
// 0 = friendly
// 1 = enemy
// 2 = neutral
// for spectators is used Marine and Alien
kMinimapBlipTeam = enum( {'Friendly', 'Enemy', 'Neutral', 'Alien', 'Marine', 'FriendAlien', 'FriendMarine', 'InactiveAlien', 'InactiveMarine' } )

// How long commander alerts should last (from NS1)
kAlertExpireTime = 20

// Bit mask table for non-stackable game effects.
// Always keep "Max" as last element.
kGameEffect = CreateBitMask( {"InUmbra", "Fury", "Cloaked", "Parasite", "NearDeath", "OnFire", "OnInfestation", "Beacon", "Energize" } )
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
kClassicMoveRate = 60

kEpsilon = 0.0001

// Weapon spawn height (for Commander dropping weapons)
kCommanderDropSpawnHeight = 0.08
kCommanderEquipmentDropSpawnHeight = 0.5

kInventoryIconsTexture = Textures.kInventoryIcons
kInventoryIconTextureWidth = 128
kInventoryIconTextureHeight = 64

// Options keys
kNicknameOptionsKey = "nickname"
kVisualDetailOptionsKey = "visualDetail"
kSoundInputDeviceOptionsKey = "sound/input-device"
kSoundOutputDeviceOptionsKey = "sound/output-device"
kSoundMuteWhenMinized = "sound/minimized-mute"
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

kHealthBarBgColors = { [kMarineTeamType] = Color(0.725 * 0.5, 0.921 * 0.5, 0.949 * 0.5, 1),
                     [kAlienTeamType] = Color(0.776 * 0.5, 0.364 * 0.5, 0.031 * 0.5, 1),
                     [kNeutralTeamType] = Color(1 * 0.5, 1 * 0.5, 1 * 0.5, 1) }
                     
kArmorBarColors = { [kMarineTeamType] = Color(0.078, 0.878, 0.984, 1),
                    [kAlienTeamType] = Color(0.576, 0.194, 0.011, 1),
                    [kNeutralTeamType] = Color(0.5, 0.5, 0.5, 1) }
                     
kArmorBarBgColors = { [kMarineTeamType] = Color(0.078 * 0.5, 0.878 * 0.5, 0.984 * 0.5, 1),
                    [kAlienTeamType] = Color(0.576 * 0.5, 0.194 * 0.5, 0.011 * 0.5, 1),
                    [kNeutralTeamType] = Color(0.5 * 0.5, 0.5 * 0.5, 0.5 * 0.5, 1) }
                    
kAbilityBarColors = { [kMarineTeamType] = Color(0,1,1,1),
                    [kAlienTeamType] = Color(1,1,0,1),
                    [kNeutralTeamType] = Color(1, 1, 1, 1) }
                     
kAbilityBarBgColors = { [kMarineTeamType] = Color(0, 0.5, 0.5, 1),
                    [kAlienTeamType] = Color(0.5, 0.5, 0, 1),
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
// checks if client has the DLC, if a table is passed, the function returns true when the client owns at least one of the productIds
function GetHasDLC(productId, client)

    if productId == nil or productId == 0 then
        return true
    end
    
    local checkIds = {}
    
    if type(productId) == "table" then
        checkIds = productId
    else
        checkIds = { productId }
    end  
    
    for i = 1, #checkIds do
    
        if Client then
        
            assert(client == nil)
            if Client.GetIsDlcAuthorized(checkIds[i]) then
                return true
            end
            
        elseif Server and client then
        
            assert(client ~= nil)
            if Server.GetIsDlcAuthorized(client, checkIds[i]) then
                return true 
            end    

        end
    
    end
    
    return false
    
end

kSpecialEditionProductId = 4930
kDeluxeEditionProductId = 4932
kShoulderPadProductId = 250891
kAssaultMarineProductId = 250892
kShadowProductId = 250893
kKodiakProductId = 296360
kReaperProductId = 310100 //temp for testing 310100
kReinforcementReduxProductId = 333230

kNoShoulerPad = 0

kShoulderPadGlobeProductId = 280763
kShoulderPadGodarProductId = 274150
kShoulderPadSaunaProductId = 280761
kShoulderPadSnailsProductId = 280762
kShoulderPadTitusProductId = 280760

// DLC player variants
// "code" is the key

// TODO we can really just get rid of the enum. use array-of-structures pattern, and use #kMarineVariants to network vars

kMarineVariant = enum({ "green", "special", "deluxe", "assault", "eliteassault", "kodiak" })
kMarineVariantData =
{
    [kMarineVariant.green] = { productId = nil, displayName = "Normal", modelFilePart = "", viewModelFilePart = "" },
    [kMarineVariant.special] = { productId = kSpecialEditionProductId, displayName = "Black", modelFilePart = "_special", viewModelFilePart = "_special" },
    [kMarineVariant.deluxe] = { productId = kDeluxeEditionProductId, displayName = "Deluxe", modelFilePart = "_special_v1", viewModelFilePart = "_deluxe" },
    [kMarineVariant.assault] = { productId = { kAssaultMarineProductId, kReinforcementReduxProductId }, displayName = "Assault", modelFilePart = "_assault", viewModelFilePart = "_assault" },
    [kMarineVariant.eliteassault] = { productId = kShadowProductId, displayName = "Elite Assault", modelFilePart = "_eliteassault", viewModelFilePart = "_eliteassault" },
    [kMarineVariant.kodiak] = { productId = kKodiakProductId, displayName = "Kodiak", modelFilePart = "_kodiak", viewModelFilePart = "_kodiak" },
}
kDefaultMarineVariant = kMarineVariant.green

kSkulkVariant = enum({ "normal", "shadow", "kodiak", "reaper" })
kSkulkVariantData =
{
    [kSkulkVariant.normal] = { productId = nil, displayName = "Normal", modelFilePart = "", viewModelFilePart = "" },
    [kSkulkVariant.shadow] = { productId = { kShadowProductId, kReinforcementReduxProductId }, displayName = "Shadow", modelFilePart = "_shadow", viewModelFilePart = "" },
    [kSkulkVariant.kodiak] = { productId = kKodiakProductId, displayName = "Kodiak", modelFilePart = "_kodiak", viewModelFilePart = "" },
    [kSkulkVariant.reaper] = { productId = kReaperProductId, displayName = "Reaper", modelFilePart = "_albino", viewModelFilePart = "_albino" },
}
kDefaultSkulkVariant = kSkulkVariant.normal

kGorgeVariant = enum({ "normal", "shadow", "reaper" })
kGorgeVariantData =
{
    [kGorgeVariant.normal] = { productId = nil, displayName = "Normal", modelFilePart = "", viewModelFilePart = "" },
    [kGorgeVariant.shadow] = { productId = kShadowProductId, displayName = "Shadow", modelFilePart = "_shadow", viewModelFilePart = "" },
    [kGorgeVariant.reaper] = { productId = kReaperProductId, displayName = "Reaper", modelFilePart = "_albino", viewModelFilePart = "_albino" },
}
kDefaultGorgeVariant = kGorgeVariant.normal

kLerkVariant = enum({ "normal", "shadow", "reaper" })
kLerkVariantData =
{
    [kLerkVariant.normal] = { productId = nil, displayName = "Normal", modelFilePart = "", viewModelFilePart = "" },
    [kLerkVariant.shadow] = { productId = kShadowProductId, displayName = "Shadow", modelFilePart = "_shadow", viewModelFilePart = "" },
    [kLerkVariant.reaper] = { productId = kReaperProductId, displayName = "Reaper", modelFilePart = "_albino", viewModelFilePart = "_albino" },
}
kDefaultLerkVariant = kLerkVariant.normal

kFadeVariant = enum({ "normal", "reaper" })
kFadeVariantData =
{
    [kFadeVariant.normal] = { productId = nil, displayName = "Normal", modelFilePart = "", viewModelFilePart = "" },
    [kFadeVariant.reaper] = { productId = kReaperProductId, displayName = "Reaper", modelFilePart = "_albino", viewModelFilePart = "_albino" },
}
kDefaultFadeVariant = kFadeVariant.normal

kOnosVariant = enum({ "normal", "reaper" })
kOnosVariantData =
{
    [kOnosVariant.normal] = { productId = nil, displayName = "Normal", modelFilePart = "", viewModelFilePart = "" },
    [kOnosVariant.reaper] = { productId = kReaperProductId, displayName = "Reaper", modelFilePart = "_albino", viewModelFilePart = "_albino" },
}
kDefaultOnosVariant = kOnosVariant.normal

kExoVariant = enum({ "normal", "kodiak" })
kExoVariantData =
{
    [kExoVariant.normal] = { productId = nil, displayName = "Normal", modelFilePart = "", viewModelFilePart = "" },
    [kExoVariant.kodiak] = { productId = kKodiakProductId, displayName = "Kodiak", modelFilePart = "", viewModelFilePart = "" }
}
kDefaultExoVariant = kExoVariant.normal

kRifleVariant = enum({ "normal", "kodiak" })
kRifleVariantData =
{
    [kRifleVariant.normal] = { productId = nil, displayName = "Normal", modelFilePart = "", viewModelFilePart = "" },
    [kRifleVariant.kodiak] = { productId = kKodiakProductId, displayName = "Kodiak", modelFilePart = "", viewModelFilePart = "" }
}
kDefaultRifleVariant = kRifleVariant.normal

function FindVariant( data, displayName )

    for var, data in pairs(data) do
        if data.displayName == displayName then
            return var
        end
    end
    return 0

end

function GetVariantName( data, var )
    if data[var] then
        return data[var].displayName
    end
    return ""        
end

function GetVariantModel( data, var )
    if data[var] then
        return data[var].modelFilePart .. ".model"
    end
    return ""        
end

function GetHasVariant(data, var, client)
    return GetHasDLC(data[var].productId, client)
end

kShoulderPad2ProductId =
{
    kNoShoulerPad,
    { kShoulderPadProductId, kReinforcementReduxProductId },
    kShadowProductId,
    kShoulderPadGlobeProductId,
    { kShoulderPadGodarProductId, kShoulderPadGlobeProductId },
    { kShoulderPadSaunaProductId, kShoulderPadGlobeProductId },
    { kShoulderPadSnailsProductId, kShoulderPadGlobeProductId },
    { kShoulderPadTitusProductId, kShoulderPadGlobeProductId },
    kKodiakProductId,
    kReaperProductId,
}
function GetHasShoulderPad(index, client)
    return GetHasDLC( kShoulderPad2ProductId[index], client )
end

kShoulderPadNames =
{
    "None",
    "Reinforced",
    "Shadow",
    "Globe",
    "Godar",
    "Saunamen",
    "Snails",
    "Titus",
    "Kodiak",
    "Reaper",
    
}

function GetShoulderPadIndexByName(padName)

    for index, name in ipairs(kShoulderPadNames) do
        if name == padName then
            return index
        end    
    end
    
    return 1

end

kHUDMode = enum({ "Full", "Minimal" })

// standard update intervals for use with TimedCallback
// The engine spreads out callbacks running at the same update interval to spread out any load. This works best if the number of
// different intervals used is not too high (a hashmap(updateInterval->list of callbacks) is used). 
// The values are just advisory to keep people from choosing 0.45 and 0.55 instead of 0.5
kUpdateIntervalMinimal = 0.5
kUpdateIntervalLow = 0.1
kUpdateIntervalMedium = 0.05
kUpdateIntervalAnimation = 0.02
kUpdateIntervalFull = 0
