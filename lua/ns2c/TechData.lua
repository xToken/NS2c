-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\TechData.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- A "database" of attributes for all units, abilities, structures, weapons, etc. in the game.
-- Shared between client and server.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Adjusted techData to match classic requirements

-- Set up structure data for easy use by Server.lua and model classes
-- Store whatever data is necessary here and use LookupTechData to access
-- Store any data that needs to used on both client and server here
-- Lookup by key with LookupTechData()
kTechDataId                             = "id"
-- Localizable string describing tech node
kTechDataDisplayName                    = "displayname"
kTechDataCombatDisplayName              = "combatdisplayname"
-- For alien traits and marine upgrades, these distinct character codes will be stored in sponitor's database
kTechDataSponitorCode                   = "sponitorchar"
-- Include and set to false if not meant to display on commander UI "enables: "
kTechIDShowEnables                      = "showenables"
kTechDataMapName                        = "mapname"
kTechDataModel                          = "model"
-- TeamResources, resources or energy
kTechDataCostKey                        = "costkey"
kTechDataCombatCost                     = "combatcost"
kTechDataBuildTime                      = "buildtime"
-- If an entity has this field, it's treated as a research node instead of a build node
kTechDataResearchTimeKey                = "researchTime"
kTechDataMaxHealth                      = "maxhealth"
kTechDataMaxArmor                       = "maxarmor"
kTechDataDamageType                     = "damagetype"
kCommanderSelectRadius					= "commradius"
-- Class that structure must be placed on top of (resource towers on resource points)
-- If adding more attach classes, add them to GetIsAttachment(). When attaching entities
-- to this attach class, ignore class.
kStructureAttachClass                   = "attachclass"
-- Structure must be placed within kStructureAttachRange of this class, but it isn't actually attached.
-- This can be a table of strings as well. Near class must have the same team number.
kStructureBuildNearClass                = "buildnearclass"
-- Structure attaches to wall/roof
kStructureBuildOnWall                   = "buildonwall"
-- If specified along with attach class, this entity can only be built within this range of an attach class (infantry portal near Command Station)
-- If specified, you must also specify the tech id of the attach class.
-- This can be a table of ids as well.
kStructureAttachRange                   = "attachrange"
-- If specified, draw a range indicator for the commander when selected.
kVisualRange                            = "visualrange"
-- set to true when attach structure is not required but optional
kTechDataAttachOptional                   = "attachoptional"
-- The tech id of the attach class
kStructureAttachId                      = "attachid"
-- If specified, this tech is an alien class that can be gestated into
kTechDataGestateName                    = "gestateclass"
-- If specified, how much time it takes to evolve into this class
kTechDataGestateTime                    = "gestatetime"
-- If specified, object spawns this far off the ground
kTechDataSpawnHeightOffset              = "spawnheight"
-- All player tech ids should have this, nothing else uses it. Pre-computed by looking at the min and max extents of the model,
-- adding their absolute values together and dividing by 2.
kTechDataMaxExtents                     = "maxextents"
-- Radius of a cylinder carved out of the navmesh when a structure with this tech id is placed
kTechDataObstacleRadius                 = "obstacleradius"
-- If specified, is amount of energy structure starts with
kTechDataInitialEnergy                  = "initialenergy"
-- If specified, is max energy structure can have
kTechDataMaxEnergy                      = "maxenergy"
-- Menu priority. If more than one techId is specified for the same spot in a menu, use the one with the higher priority.
-- If a tech doesn't specify a priority, treat as 0. If all priorities are tied, show none of them. This is how Starcraft works (see siege behavior).
kTechDataMenuPriority                   = "menupriority"
-- if an alert with higher priority is trigger the interval should be ignored
kTechDataAlertPriority                  = "alertpriority"
-- Indicates that the tech node is an upgrade of another tech node, so that the previous tech is still active (ie, if you upgrade a hive
-- to an advanced hive, your team still has "hive" technology.
kTechDataUpgradeTech                    = "upgradetech"
-- Set true if entity should be rotated before being placed
kTechDataSpecifyOrientation             = "specifyorientation"
-- manipulate build coords in a custom function
kTechDataOverrideCoordsMethod           = "overridecoordsmethod"
-- Point value for killing structure
kTechDataPointValue                     = "pointvalue"
-- Set to false if not yet implemented, for displaying differently for not enabling
kTechDataImplemented                    = "implemented"
-- Set to localizable string that will be added to end of description indicating date it went in.
kTechDataNew                            = "new"
-- For setting grow parameter on alien structures
kTechDataGrows                          = "grows"
-- Commander hotkey. Not currently used.
kTechDataHotkey                         = "hotkey"
-- Alert sound name
kTechDataAlertSound                     = "alertsound"
-- Alert text for commander HUD
kTechDataAlertText                      = "alerttext"
-- Alert type. These are the types in CommanderUI_GetDynamicMapBlips. "Request" alert types count as player alert requests and show up on the commander HUD as such.
kTechDataAlertType                      = "alerttype"
-- Alert scope
kTechDataAlertTeam                      = "alertteam"
-- Alert should ignore distance for triggering
kTechDataAlertIgnoreDistance            = "alertignoredistance"
-- Alert should also trigger a team message.
kTechDataAlertSendTeamMessage           = "alertsendteammessage"
-- Sound that plays for Comm and ordered players when given this order
kTechDataOrderSound                     = "ordersound"
-- Don't send alert to originator of this alert
kTechDataAlertOthersOnly                = "alertothers"
-- Usage notes, caveats, etc. for use in commander tooltip (localizable)
kTechDataTooltipInfo                    = "tooltipinfo"
-- Quite the same as tooltip, but shorter
kTechDataHint                           = "hintinfo"
-- Indicate tech id that we're replicating
-- Engagement distance - how close can unit get to it before it can repair or build it
kTechDataEngagementDistance             = "engagementdist"
-- Special ghost-guide method. Called with commander as argument, returns a map of entities with ranges to lit up.
kTechDataGhostGuidesMethod               = "ghostguidesmethod"
-- Special requirements for building. Called with techId, the origin and normal for building location and the commander. Returns true if the special requirement is met.
kTechDataBuildRequiresMethod            = "buildrequiresmethod"
-- Allows dropping onto other entities
kTechDataAllowStacking                 = "allowstacking"
-- will ignore other entities when searching for spawn position
kTechDataCollideWithWorldOnly          = "collidewithworldonly"
-- ignore pathing mesh when placing entities
kTechDataIgnorePathingMesh     = "ignorepathing"
-- used for gorgess
kTechDataMaxAmount = "maxstructureamount"
-- requires tf
kTechDataRequiresTF = "requirestf"
-- ghost model scale
kTechDataGhostModelScale = "ghostmodelscale"
-- for drawing ghost model, client
kTechDataGhostModelClass = "ghostmodelclass"
-- for gorge build, can consume when dropping
kTechDataAllowConsumeDrop = "allowconsumedrop"
-- ignore any alert interval
kTechDataAlertIgnoreInterval = "ignorealertinterval"
-- used for alien upgrades
kTechDataCategory = "techcategory"
-- used to track alien upgrade structures
kTechDataKeyStructure = "keystructure"
-- custom message displayed for the commander when build method failed
kTechDataBuildMethodFailedMessage = "commanderbuildmethodfailed"
-- configuration specific modifiers for custom build failure messages
kTechDataBuildMethodFailedLookup = "commanderbuildmethodfailedlookup"

kTechDataAbilityType = "abilitytype"
kTechDataShowOrderLine = "showorderline"

function BuildTechData()
    
    local techData = { 

        // Orders
        {[kTechDataId] = kTechId.Move,
			[kTechDataDisplayName] = "MOVE",
			[kTechDataHotkey] = Move.M,
			[kTechDataTooltipInfo] = "MOVE_TOOLTIP",
			[kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName
		},
		
		{[kTechDataId] = kTechId.Patrol,
			[kTechDataDisplayName] = "PATROL",
			[kTechDataShowOrderLine] = true,
			[kTechDataHotkey] = Move.M,
			[kTechDataTooltipInfo] = "PATROL_TOOLTIP",
			[kTechDataOrderSound] = MarineCommander.kMoveToWaypointSoundName
		},
		
        {[kTechDataId] = kTechId.Attack,
			[kTechDataDisplayName] = "ATTACK",
			[kTechDataHotkey] = Move.A,
			[kTechDataTooltipInfo] = "ATTACK_TOOLTIP",
			[kTechDataOrderSound] = MarineCommander.kAttackOrderSoundName
		},
		
        {[kTechDataId] = kTechId.Build,
			[kTechDataDisplayName] = "BUILD",
			[kTechDataTooltipInfo] = "BUILD_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.Construct,
			[kTechDataDisplayName] = "CONSTRUCT",
			[kTechDataOrderSound] = MarineCommander.kBuildStructureSound
		},
		
		{[kTechDataId] = kTechId.AutoConstruct,
			[kTechDataDisplayName] = "CONSTRUCT",
			[kTechDataOrderSound] = MarineCommander.kBuildStructureSound
		},
		
        {[kTechDataId] = kTechId.Cancel,
			[kTechDataDisplayName] = "CANCEL",
			[kTechDataHotkey] = Move.ESC
		},
		
        {[kTechDataId] = kTechId.Follow,
			[kTechDataDisplayName] = "FOLLOW"
		},
		
        {[kTechDataId] = kTechId.FollowAndWeld,
			[kTechDataDisplayName] = "FOLLOWANDWELD",
			[kTechDataHotkey] = Move.W,
			[kTechDataTooltipInfo] = "FOLLOWANDWELD_TOOLTIP",
			[kTechDataOrderSound] = MarineCommander.kWeldOrderSound
		},
		
        {[kTechDataId] = kTechId.Weld,
			[kTechDataDisplayName] = "WELD",
			[kTechDataHotkey] = Move.W,
			[kTechDataTooltipInfo] = "WELD_TOOLTIP",
			[kTechDataOrderSound] = MarineCommander.kWeldOrderSound
		},
		
        {[kTechDataId] = kTechId.AutoWeld,
			[kTechDataDisplayName] = "WELD",
			[kTechDataHotkey] = Move.W,
			[kTechDataTooltipInfo] = "WELD_TOOLTIP",
			[kTechDataOrderSound] = MarineCommander.kWeldOrderSound
		},
		
        {[kTechDataId] = kTechId.Stop,
			[kTechDataDisplayName] = "STOP",
			[kTechDataHotkey] = Move.S,
			[kTechDataTooltipInfo] = "STOP_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.SetRally,
			[kTechDataDisplayName] = "SET_RALLY_POINT",
			[kTechDataHotkey] = Move.L,
			[kTechDataTooltipInfo] = "RALLY_POINT_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.SetTarget,
			[kTechDataDisplayName] = "SET_TARGET",
			[kTechDataHotkey] = Move.T,
			[kTechDataTooltipInfo] = "SET_TARGET_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.Heal,
			[kTechDataDisplayName] = "HEAL",
			[kTechDataOrderSound] = Gorge.kHealTarget
		},
        
        // Ready room player is the default player, hence the ReadyRoomPlayer.kMapName
        {[kTechDataId] = kTechId.ReadyRoomPlayer,
			[kTechDataDisplayName] = "READY_ROOM_PLAYER",
			[kTechDataMapName] = ReadyRoomPlayer.kMapName,
			[kTechDataModel] = Marine.kModelName,
			[kTechDataMaxExtents] = Vector(Player.kXZExtents, Player.kYExtents, Player.kXZExtents)
		},
		
        {[kTechDataId] = kTechId.Spectator,
			[kTechDataModel] = ""
		},
		
        {[kTechDataId] = kTechId.AlienSpectator,
			[kTechDataModel] = ""
		},
        
        // Marine orders
        {[kTechDataId] = kTechId.Defend,
			[kTechDataDisplayName] = "DEFEND",
			[kTechDataOrderSound] = MarineCommander.kDefendTargetSound
		},

        // Menus
		/*{[kTechDataId] = kTechId.RootMenu,
			[kTechDataDisplayName] = "SELECT",
			[kTechDataHotkey] = Move.B,
			[kTechDataTooltipInfo] = "SELECT_TOOLTIP"
		},*/
		
        {[kTechDataId] = kTechId.BuildMenu,
			[kTechDataDisplayName] = "BUILD",
			[kTechDataHotkey] = Move.W,
			[kTechDataTooltipInfo] = "BUILD_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.AdvancedMenu,
			[kTechDataDisplayName] = "ADVANCED",
			[kTechDataHotkey] = Move.E,
			[kTechDataTooltipInfo] = "ADVANCED_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.AssistMenu,
			[kTechDataDisplayName] = "ASSIST",
			[kTechDataHotkey] = Move.R,
			[kTechDataTooltipInfo] = "ASSIST_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.UpgradesMenu,
			[kTechDataDisplayName] = "UPGRADES",
			[kTechDataHotkey] = Move.U,
			[kTechDataTooltipInfo] = "TEAM_UPGRADES_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.WeaponsMenu,
			[kTechDataDisplayName] = "WEAPONS_MENU",
			[kTechDataTooltipInfo] = "WEAPONS_MENU_TOOLTIP"
		},

        {[kTechDataId] = kTechId.TwoCommandStations,
			[kTechDataDisplayName] = "TWO_COMMAND_STATIONS",
			[kTechDataTooltipInfo] = "TWO_COMMAND_STATIONS"
		}, 
		
        {[kTechDataId] = kTechId.ThreeCommandStations,
			[kTechDataDisplayName] = "TWO_COMMAND_STATIONS",
			[kTechDataTooltipInfo] = "THREE_COMMAND_STATIONS"
		},               

        {[kTechDataId] = kTechId.ResourcePoint,
			[kTechDataHint] = "RESOURCE_POINT_HINT",
			[kTechDataMapName] = ResourcePoint.kPointMapName,
			[kTechDataDisplayName] = "RESOURCE_NOZZLE",
			[kTechDataModel] = ResourcePoint.kModelName
		},
		
        {[kTechDataId] = kTechId.TechPoint,
			[kTechDataHint] = "TECH_POINT_HINT",
			[kTechDataMapName] = TechPoint.kMapName,
			[kTechDataDisplayName] = "TECH_POINT",
			[kTechDataModel] = TechPoint.kModelName
		},
		
        {[kTechDataId] = kTechId.Door,
			[kTechDataDisplayName] = "DOOR",
			[kTechDataMapName] = Door.kMapName,
			[kTechDataMaxHealth] = kDoorHealth,
			[kTechDataMaxArmor] = kDoorArmor,
			[kTechDataPointValue] = kDoorPointValue
		},
		
        {[kTechDataId] = kTechId.DoorOpen,
			[kTechDataDisplayName] = "OPEN_DOOR",
			[kTechDataHotkey] = Move.O,
			[kTechDataTooltipInfo] = "OPEN_DOOR_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.DoorClose,
			[kTechDataDisplayName] = "CLOSE_DOOR",
			[kTechDataHotkey] = Move.C,
			[kTechDataTooltipInfo] = "CLOSE_DOOR_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.DoorLock,
			[kTechDataDisplayName] = "LOCK_DOOR",
			[kTechDataHotkey] = Move.L,
			[kTechDataTooltipInfo] = "LOCKED_DOOR_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.DoorUnlock,
			[kTechDataDisplayName] = "UNLOCK_DOOR",
			[kTechDataHotkey] = Move.U,
			[kTechDataTooltipInfo] = "UNLOCK_DOOR_TOOLTIP"
		},
        
        // Marine Commander abilities    
        {[kTechDataId] = kTechId.AmmoPack,
			[kTechDataIgnorePathingMesh] = true,
			[kTechDataAllowStacking] = true,
			[kTechDataCollideWithWorldOnly] = true,
			[kTechDataMapName] = AmmoPack.kMapName,
			[kTechDataDisplayName] = "AMMO_PACK",
			[kTechDataCostKey] = kAmmoPackCost,
			[kTechDataModel] = AmmoPack.kModelName,
			[kTechDataTooltipInfo] = "AMMO_PACK_TOOLTIP",
			[kTechDataSpawnHeightOffset] = kCommanderDropSpawnHeight
		},
		
        {[kTechDataId] = kTechId.MedPack,
			[kTechDataIgnorePathingMesh] = true,
			[kTechDataAllowStacking] = true,
			[kTechDataCollideWithWorldOnly] = true,
			[kTechDataMapName] = MedPack.kMapName,
			[kTechDataDisplayName] = "MED_PACK",
			[kTechDataCostKey] = kMedPackCost,
			[kTechDataModel] = MedPack.kModelName,
			[kTechDataTooltipInfo] = "MED_PACK_TOOLTIP",
			[kTechDataSpawnHeightOffset] = kCommanderDropSpawnHeight,
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "Resupply"
		},
		
        {[kTechDataId] = kTechId.CatPack,
			[kTechDataIgnorePathingMesh] = true,
			[kTechDataAllowStacking] = true,
			[kTechDataCollideWithWorldOnly] = true,
			[kTechDataMapName] = CatPack.kMapName,
			[kTechDataDisplayName] = "CAT_PACK",
			[kTechDataCostKey] = kCatPackCost,
			[kTechDataModel] = CatPack.kModelName,
			[kTechDataTooltipInfo] = "CAT_PACK_TOOLTIP",
			[kTechDataSpawnHeightOffset] = kCommanderDropSpawnHeight,
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "Catpack"
		},
		
        {[kTechDataId] = kTechId.Scan,
			[kTechDataIgnorePathingMesh] = true,
			[kTechDataAllowStacking] = true,
			[kTechDataCollideWithWorldOnly] = true,
			[kTechDataMapName] = Scan.kMapName,
			[kTechDataDisplayName] = "SCAN",
			[kTechDataHotkey] = Move.S,
			[kTechDataCostKey] = kObservatoryScanCost,
			[kTechDataTooltipInfo] = "SCAN_TOOLTIP",
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "Scan"
		},
		
        {[kTechDataId] = kTechId.DistressBeacon,
			[kTechDataBuildTime] = 0.1,
			[kTechDataDisplayName] = "DISTRESS_BEACON",
			[kTechDataHotkey] = Move.B,
			[kTechDataCostKey] = kObservatoryDistressBeaconCost,
			[kTechDataTooltipInfo] =  "DISTRESS_BEACON_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.Recycle,
			[kTechDataDisplayName] = "RECYCLE",
			[kTechDataCostKey] = 0,
			[kTechDataResearchTimeKey] = kRecycleTime,
			[kTechDataHotkey] = Move.R,
			[kTechDataTooltipInfo] =  "RECYCLE_TOOLTIP"
		},
        
        // Command station and its buildables
        {[kTechDataId] = kTechId.CommandStation,
			[kTechDataHint] = "COMMAND_STATION_HINT",
			[kTechDataGhostModelClass] = "MarineGhostModel",
			[kTechDataMapName] = CommandStation.kMapName,
			[kTechDataDisplayName] = "COMMAND_STATION",
			[kTechDataBuildTime] = kCommandStationBuildTime,
			[kTechDataCostKey] = kCommandStationCost,
			[kTechDataModel] = CommandStation.kModelName,
			[kTechDataMaxHealth] = kCommandStationHealth,
			[kTechDataMaxArmor] = kCommandStationArmor,
			[kTechDataSpawnHeightOffset] = 0,
			[kTechDataEngagementDistance] = kCommandStationEngagementDistance,
			[kTechDataPointValue] = kCommandStationPointValue,
			[kTechDataHotkey] = Move.C,
			[kTechDataMaxExtents] = Vector(0.5, 2.0, 1.5),
			[kTechDataTooltipInfo] = "COMMAND_STATION_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.Extractor,
			[kTechDataIgnorePathingMesh] = true,
			[kTechDataCollideWithWorldOnly] = true,
			[kTechDataAllowStacking] = true,
			[kTechDataHint] = "EXTRACTOR_HINT",
			[kTechDataGhostModelClass] = "MarineGhostModel",
			[kTechDataMapName] = Extractor.kMapName,
			[kTechDataDisplayName] = "EXTRACTOR",
			[kTechDataCostKey] = kExtractorCost,
			[kTechDataBuildTime] = kExtractorBuildTime,
			[kTechDataEngagementDistance] = kExtractorEngagementDistance,
			[kTechDataModel] = Extractor.kModelName,
			[kTechDataMaxHealth] = kExtractorHealth,
			[kTechDataMaxArmor] = kExtractorArmor,
			[kStructureAttachClass] = "ResourcePoint",
			[kTechDataInitialEnergy] = kExtractorInitialEnergy,
			[kTechDataMaxEnergy] = kExtractorMaxEnergy,
			[kTechDataPointValue] = kExtractorPointValue,
			[kTechDataHotkey] = Move.E,
			[kTechDataTooltipInfo] =  "EXTRACTOR_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.InfantryPortal,
			[kTechDataHint] = "INFANTRY_PORTAL_HINT",
			[kTechDataGhostModelClass] = "MarineGhostModel",
			[kTechDataGhostGuidesMethod] = GetInfantryPortalGhostGuides,
			[kTechDataMapName] = InfantryPortal.kMapName,
			[kTechDataDisplayName] = "INFANTRY_PORTAL",
			[kTechDataCostKey] = kInfantryPortalCost,
			[kTechDataPointValue] = kInfantryPortalPointValue,
			[kTechDataBuildTime] = kInfantryPortalBuildTime,
			[kTechDataMaxHealth] = kInfantryPortalHealth,
			[kTechDataMaxArmor] = kInfantryPortalArmor,
			[kTechDataModel] = InfantryPortal.kModelName,
			[kStructureAttachId] = kTechId.CommandStation,
			[kStructureAttachRange] = kInfantryPortalAttachRange,
			[kTechDataEngagementDistance] = kInfantryPortalEngagementDistance,
			[kTechDataHotkey] = Move.P,
			[kTechDataTooltipInfo] = "INFANTRY_PORTAL_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.Armory,
			[kTechDataHint] = "ARMORY_HINT",
			[kTechDataGhostModelClass] = "MarineGhostModel",
			[kTechDataMapName] = Armory.kMapName,
			[kTechDataDisplayName] = "ARMORY",
			[kTechDataCostKey] = kArmoryCost,
			[kTechDataBuildTime] = kArmoryBuildTime,
			[kTechDataMaxHealth] = kArmoryHealth,
			[kTechDataMaxArmor] = kArmoryArmor,
			[kTechDataEngagementDistance] = kArmoryEngagementDistance,
			[kTechDataModel] = Armory.kModelName,
			[kTechDataPointValue] = kArmoryPointValue,
			[kTechDataTooltipInfo] = "ARMORY_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.ArmsLab,
			[kTechDataHint] = "ARMSLAB_HINT",
			[kTechDataGhostModelClass] = "MarineGhostModel",
			[kTechDataMapName] = ArmsLab.kMapName,
			[kTechDataDisplayName] = "ARMS_LAB",
			[kTechDataCostKey] = kArmsLabCost,
			[kTechDataBuildTime] = kArmsLabBuildTime,
			[kTechDataMaxHealth] = kArmsLabHealth,
			[kTechDataMaxArmor] = kArmsLabArmor,
			[kTechDataEngagementDistance] = kArmsLabEngagementDistance,
			[kTechDataModel] = ArmsLab.kModelName,
			[kTechDataPointValue] = kArmsLabPointValue,
			[kTechDataHotkey] = Move.A,
			[kTechDataTooltipInfo] = "ARMS_LAB_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.Sentry,
			[kTechDataHint] = "SENTRY_HINT",
			[kTechDataGhostModelClass] = "MarineGhostModel", 
			[kTechDataRequiresTF] = true,
			[kTechDataMapName] = Sentry.kMapName,
			[kTechDataDisplayName] = "SENTRY_TURRET",
			[kTechDataCostKey] = kSentryCost,
			[kTechDataPointValue] = kSentryPointValue,
			[kTechDataModel] = Sentry.kModelName,
			[kTechDataBuildTime] = kSentryBuildTime,
			[kTechDataMaxHealth] = kSentryHealth,
			[kTechDataMaxArmor] = kSentryArmor,
			[kTechDataDamageType] = kSentryAttackDamageType,
			[kTechDataSpecifyOrientation] = true,
			[kTechDataHotkey] = Move.S,
			[kTechDataEngagementDistance] = kSentryEngagementDistance,
			[kTechDataTooltipInfo] = "SENTRY_TOOLTIP",
			[kStructureAttachId] = { kTechId.TurretFactory, kTechId.AdvancedTurretFactory },
			[kStructureAttachRange] = kTurretFactoryAttachRange,
			[kTechDataBuildMethodFailedMessage] = "COMMANDERERROR_TOO_MANY_SENTRIES",
			[kStructureBuildNearClass] = "TurretFactory",
			[kTechDataBuildRequiresMethod] = GetCheckSentryLimit,
			[kTechDataBuildMethodFailedLookup] = GetSentryLimit,
			[kTechDataGhostGuidesMethod] = GetTurretFactoriesInRange
		},
		
        {[kTechDataId] = kTechId.AdvancedArmory,
			[kTechDataHint] = "ADVANCED_ARMORY_HINT",
			[kTechDataGhostModelClass] = "MarineGhostModel",
			[kTechDataMapName] = AdvancedArmory.kMapName,
			[kTechDataDisplayName] = "ADVANCED_ARMORY",
			[kTechDataCostKey] = kAdvancedArmoryUpgradeCost,
			[kTechDataModel] = Armory.kModelName,
			[kTechDataMaxHealth] = kAdvancedArmoryHealth,
			[kTechDataMaxArmor] = kAdvancedArmoryArmor,
			[kTechDataEngagementDistance] = kArmoryEngagementDistance,
			[kTechDataUpgradeTech] = kTechId.Armory,
			[kTechDataPointValue] = kAdvancedArmoryPointValue
		},
		
        {[kTechDataId] = kTechId.Observatory,
			[kTechDataHint] = "OBSERVATORY_HINT",
			[kTechDataGhostModelClass] = "MarineGhostModel",
			[kTechDataMapName] = Observatory.kMapName,
			[kTechDataDisplayName] = "OBSERVATORY",
			[kVisualRange] = Observatory.kDetectionRange,
			[kTechDataCostKey] = kObservatoryCost,
			[kTechDataModel] = Observatory.kModelName,
			[kTechDataBuildTime] = kObservatoryBuildTime,
			[kTechDataMaxHealth] = kObservatoryHealth,
			[kTechDataEngagementDistance] = kObservatoryEngagementDistance,
			[kTechDataMaxArmor] = kObservatoryArmor,
			[kTechDataInitialEnergy] = kObservatoryInitialEnergy,
			[kTechDataMaxEnergy] = kObservatoryMaxEnergy,
			[kTechDataPointValue] = kObservatoryPointValue,
			[kTechDataHotkey] = Move.O,
			[kTechDataTooltipInfo] = "OBSERVATORY_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.TurretFactory,
			[kTechDataHint] = "TURRET_FACTORY_HINT",
			[kTechDataGhostModelClass] = "MarineGhostModel",
			[kTechDataDisplayName] = "TURRET_FACTORY",
			[kTechDataMapName] = TurretFactory.kMapName,
			[kTechDataCostKey] = kTurretFactoryCost,
			[kTechDataModel] = TurretFactory.kModelName,
			[kTechDataBuildTime] = kTurretFactoryBuildTime,
			[kTechDataMaxHealth] = kTurretFactoryHealth,
			[kTechDataMaxArmor] = kTurretFactoryArmor,
			[kTechDataPointValue] = kTurretFactoryPointValue,
			[kTechDataHotkey] = Move.R,
			[kTechDataTooltipInfo] = "TURRET_FACTORY_TOOLTIP",
			[kTechDataBuildMethodFailedMessage] = "COMMANDERERROR_TOO_MANY_TURRET_FACTORIES",
			[kTechDataBuildMethodFailedLookup] = GetTurretFactoryLimit,
			[kTechDataBuildRequiresMethod] = CheckTurretFactoryLimit
		},
		
        {[kTechDataId] = kTechId.AdvancedTurretFactory,
			[kTechDataHint] = "ADVANCED_TURRET_FACTORY_HINT",
			[kTechDataDisplayName] = "ADVANCED_TURRET_FACTORY",
			[kTechDataMapName] = AdvancedTurretFactory.kMapName,
			[kTechDataModel] = TurretFactory.kModelName,
			[kTechDataBuildTime] = kTurretFactoryBuildTime,
			[kTechDataMaxHealth] = kAdvancedTurretFactory,
			[kTechDataMaxArmor] = kAdvancedTurretFactoryArmor,
			[kTechDataPointValue] = kAdvancedTurretFactoryPointValue,
			[kTechDataHotkey] = Move.R,
			[kTechDataTooltipInfo] = "ADVANCED_TURRET_FACTORY_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.SiegeCannon,
			[kTechDataHint] = "SIEGE_CANNON_HINT",
			[kTechDataGhostModelClass] = "MarineGhostModel",
			[kTechDataBuildTime] = kSiegeCannonBuildTime,
			[kTechDataRequiresTF] = true,
			[kTechDataDisplayName] = "SIEGE_CANNON",
			[kTechDataMapName] = SiegeCannon.kMapName,
			[kTechDataCostKey] = kSiegeCannonCost,
			[kTechDataDamageType] = kSiegeCannonDamageType,
			[kTechDataResearchTimeKey] = kSiegeCannonBuildTime,
			[kTechDataMaxHealth] = kSiegeCannonHealth,
			[kTechDataEngagementDistance] = kSiegeCannonEngagementDistance,
			[kVisualRange] = kSiegeCannonRange,
			[kTechDataMaxArmor] = kSiegeCannonArmor,
			[kTechDataModel] = SiegeCannon.kModelName,
			[kTechDataMaxHealth] = kSiegeCannonHealth,
			[kTechDataPointValue] = kSiegeCannonPointValue,
			[kTechDataHotkey] = Move.T,
			[kStructureAttachId] = { kTechId.AdvancedTurretFactory },
			[kStructureAttachRange] = kTurretFactoryAttachRange,
			[kTechDataBuildMethodFailedMessage] = "COMMANDERERROR_TOO_MANY_SIEGE_CANNONS",
			[kTechDataBuildMethodFailedLookup] = GetSiegeCannonLimit,
			[kTechDataBuildRequiresMethod] = GetCheckSiegeCannonLimit
		},
		
        {[kTechDataId] = kTechId.PhaseGate,
			[kTechDataHint] = "PHASE_GATE_HINT",
			[kTechDataGhostModelClass] = "MarineGhostModel",
			[kTechDataMapName] = PhaseGate.kMapName,
			[kTechDataBuildRequiresMethod] = CheckSpaceForPhaseGate,
			[kTechDataDisplayName] = "PHASE_GATE",
			[kTechDataCostKey] = kPhaseGateCost,
			[kTechDataModel] = PhaseGate.kModelName,
			[kTechDataBuildTime] = kPhaseGateBuildTime,
			[kTechDataMaxHealth] = kPhaseGateHealth,
			[kTechDataEngagementDistance] = kPhaseGateEngagementDistance,
			[kTechDataMaxArmor] = kPhaseGateArmor,
			[kTechDataPointValue] = kPhaseGatePointValue,
			[kTechDataHotkey] = Move.P,
			[kTechDataTooltipInfo] = "PHASE_GATE_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.PrototypeLab,
			[kTechDataHint] = "PROTOTYPE_LAB_HINT",
			[kTechDataGhostModelClass] = "MarineGhostModel",
			[kTechDataMapName] = PrototypeLab.kMapName,
			[kTechDataCostKey] = kPrototypeLabCost,
			[kTechDataBuildTime] = kPrototypeLabBuildTime,
			[kTechDataDisplayName] = "PROTOTYPE_LAB",
			[kTechDataModel] = PrototypeLab.kModelName,
			[kTechDataMaxHealth] = kPrototypeLabHealth,
			[kTechDataPointValue] = kPrototypeLabPointValue,
			[kTechDataTooltipInfo] = "PROTOTYPE_LAB_TOOLTIP"
		},
        
        // Marine classes
        {[kTechDataId] = kTechId.Marine,
			[kTechDataDisplayName] = "MARINE",
			[kTechDataMapName] = Marine.kMapName,
			[kTechDataModel] = MarineVariantMixin.kModelNames["male"]["green"],
			[kTechDataMaxExtents] = Vector(Player.kXZExtents, Player.kYExtents, Player.kXZExtents),
			[kTechDataMaxHealth] = kMarineHealth,
			[kTechDataEngagementDistance] = kPlayerEngagementDistance,
			[kTechDataPointValue] = kMarinePointValue
		},
		
        {[kTechDataId] = kTechId.HeavyArmorMarine,
			[kTechDataDisplayName] = "HEAVY_ARMOR",
			[kTechDataMapName] = HeavyArmorMarine.kMapName,
			[kTechDataModel] = HeavyArmorMarine.kModelName,
			[kTechDataMaxExtents] = Vector(Player.kXZExtents, Player.kYExtents, Player.kXZExtents),
			[kTechDataMaxHealth] = kHeavyArmorHealth,
			[kTechDataEngagementDistance] = kPlayerEngagementDistance,
			[kTechDataPointValue] = kHeavyArmorPointValue
		},
		
        {[kTechDataId] = kTechId.MarineCommander,
			[kTechDataDisplayName] = "MARINE_COMMANDER",
			[kTechDataMapName] = MarineCommander.kMapName,
			[kTechDataModel] = ""
		},
		
        {[kTechDataId] = kTechId.JetpackMarine,
			[kTechDataHint] = "JETPACK_HINT",
			[kTechDataDisplayName] = "JETPACK",
			[kTechDataMapName] = JetpackMarine.kMapName,
			[kTechDataModel] = MarineVariantMixin.kModelNames["male"]["green"],
			[kTechDataMaxExtents] = Vector(Player.kXZExtents, Player.kYExtents, Player.kXZExtents),
			[kTechDataMaxHealth] = kJetpackHealth,
			[kTechDataEngagementDistance] = kPlayerEngagementDistance,
			[kTechDataPointValue] = kMarinePointValue
		},
        
        // Weapons
        {[kTechDataId] = kTechId.Mine,
			[kTechDataMapName] = Mine.kMapName,
			[kTechDataHint] = "MINE_HINT",
			[kTechDataDisplayName] = "MINE",
			[kTechDataEngagementDistance] = kMineDetonateRange,
			[kTechDataMaxHealth] = kMineHealth,
			[kTechDataMaxArmor] = kMineArmor,
			[kTechDataModel] = Mine.kModelName,
			[kTechDataPointValue] = kMinePointValue
		},
		
        {[kTechDataId] = kTechId.Rifle,
			[kTechDataMaxHealth] = kRifleHealth,
			[kTechDataMaxArmor] = kRifleArmor,
			[kTechDataPointValue] = kWeaponPointValue,
			[kTechDataMapName] = Rifle.kMapName,
			[kTechDataDisplayName] = "RIFLE",
			[kTechDataModel] = Rifle.kModelName,
			[kTechDataDamageType] = kRifleDamageType,
			[kTechDataCostKey] = kRifleDropCost
		},
		
        {[kTechDataId] = kTechId.Pistol,
			[kTechDataMaxHealth] = kPistolHealth,
			[kTechDataMaxArmor] = kPistolArmor,
			[kTechDataPointValue] = kWeaponPointValue,
			[kTechDataMapName] = Pistol.kMapName,
			[kTechDataDisplayName] = "PISTOL",
			[kTechDataModel] = Pistol.kModelName,
			[kTechDataDamageType] = kPistolDamageType,
			[kTechDataCostKey] = kPistolCost
		},
		
        {[kTechDataId] = kTechId.Axe,
			[kTechDataMapName] = Axe.kMapName,
			[kTechDataDisplayName] = "SWITCH_AX",
			[kTechDataModel] = Axe.kModelName,
			[kTechDataDamageType] = kAxeDamageType,
			[kTechDataCostKey] = kAxeCost
		},
		
        {[kTechDataId] = kTechId.Shotgun,
			[kTechDataAllowStacking] = true,
			[kTechDataMapName] = Shotgun.kMapName,
			[kTechDataDisplayName] = "SHOTGUN",
			[kTechDataTooltipInfo] =  "SHOTGUN_TOOLTIP",
			[kTechDataModel] = ShotgunVariantMixin.kModelNames.shotgun[ShotgunVariantMixin.kDefaultModelName],
			[kTechDataCostKey] = kShotgunDropCost,
			[kTechDataDamageType] = kShotgunDamageType,
			[kStructureAttachId] = { kTechId.Armory, kTechId.AdvancedArmory },
			[kStructureAttachRange] = kArmoryWeaponAttachRange,
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "SG"
		},
		
        {[kTechDataId] = kTechId.HeavyMachineGun,
			[kTechDataAllowStacking] = true,
			[kTechDataMapName] = HeavyMachineGun.kMapName,
			[kTechDataDisplayName] = "HEAVY_MACHINE_GUN",
			[kTechDataTooltipInfo] =  "HEAVY_MACHINE_GUN_TOOLTIP",
			[kTechDataModel] = HeavyMachineGun.kModelName,
			[kTechDataCostKey] = kHeavyMachineGunCost,
			[kTechDataDamageType] = kHeavyMachineGunDamageType,
			[kStructureAttachId] = { kTechId.AdvancedArmory },
			[kStructureAttachRange] = kArmoryWeaponAttachRange,
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "HMG"
		},
		
        {[kTechDataId] = kTechId.Welder,
			[kTechDataAllowStacking] = true,
			[kTechDataMapName] = Welder.kMapName,
			[kTechDataDisplayName] = "WELDER",
			[kTechDataTooltipInfo] =  "WELDER_TOOLTIP",
			[kTechDataModel] = Welder.kModelName,
			[kTechDataCostKey] = kWelderDropCost,
			[kStructureAttachId] = { kTechId.Armory, kTechId.AdvancedArmory },
			[kStructureAttachRange] = kArmoryWeaponAttachRange,
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "Welder"
		},
		
        {[kTechDataId] = kTechId.Mines,
			[kTechDataAllowStacking] = true,
			[kTechDataMapName] = Mines.kMapName,
			[kTechDataDisplayName] = "MINE",
			[kTechDataTooltipInfo] =  "MINE_TOOLTIP",
			[kTechDataModel] = Mine.kModelName,
			[kTechDataCostKey] = kMinesDropCost,
			[kStructureAttachId] = { kTechId.Armory, kTechId.AdvancedArmory },
			[kStructureAttachRange] = kArmoryWeaponAttachRange,
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "Mines"
		},
		
        {[kTechDataId] = kTechId.HandGrenades,
			[kTechDataMapName] = HandGrenades.kMapName,
			[kTechDataDisplayName] = "HAND_GRENADES",
			[kTechDataTooltipInfo] =  "HAND_GRENADES_TOOLTIP",
			[kTechDataModel] = HandGrenades.kModelName,
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "HG"
		},
		
        {[kTechDataId] = kTechId.GrenadeLauncher,
			[kTechDataAllowStacking] = true,
			[kTechDataMapName] = GrenadeLauncher.kMapName,
			[kTechDataDisplayName] = "GRENADE_LAUNCHER",
			[kTechDataTooltipInfo] =  "GRENADE_LAUNCHER_TOOLTIP",
			[kTechDataModel] = GrenadeLauncher.kModelName,
			[kTechDataCostKey] = kGrenadeLauncherDropCost,
			[kStructureAttachId] = kTechId.AdvancedArmory,
			[kStructureAttachRange] = kArmoryWeaponAttachRange,
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "GL"
		},
		
        {[kTechDataId] = kTechId.Jetpack,
			[kTechDataAllowStacking] = true,
			[kTechDataMapName] = Jetpack.kMapName,
			[kTechDataDisplayName] = "JETPACK",
			[kTechDataTooltipInfo] =  "JETPACK_TOOLTIP",
			[kTechDataModel] = Jetpack.kModelName,
			[kTechDataCostKey] = kJetpackDropCost,
			[kStructureAttachId] = kTechId.PrototypeLab,
			[kStructureAttachRange] = kArmoryWeaponAttachRange,
			[kTechDataCombatCost] = kCombatMarineJetpackCost,
			[kTechDataCombatDisplayName] = "JP"
		},
		
        {[kTechDataId] = kTechId.HeavyArmor,
			[kTechDataAllowStacking] = true,
			[kTechDataMapName] = HeavyArmor.kMapName,
			[kTechDataDisplayName] = "HEAVY_ARMOR",
			[kTechDataTooltipInfo] =  "HEAVY_ARMOR_TOOLTIP",
			[kTechDataModel] = HeavyArmor.kModelName,
			[kTechDataCostKey] = kHeavyArmorDropCost,
			[kStructureAttachId] = kTechId.PrototypeLab,
			[kStructureAttachRange] = kArmoryWeaponAttachRange,
			[kTechDataCombatCost] = kCombatMarineHeavyArmorCost,
			[kTechDataCombatDisplayName] = "HA"
		},
        
        // Armor and upgrades
        {[kTechDataId] = kTechId.JetpackTech,
			[kTechDataCostKey] = kJetpackTechResearchCost,
			[kTechDataResearchTimeKey] = kJetpackTechResearchTime,
			[kTechDataDisplayName] = "JETPACK_TECH"
		},
		
        {[kTechDataId] = kTechId.HeavyArmorTech,
			[kTechDataCostKey] = kHeavyArmorTechResearchCost,
			[kTechDataResearchTimeKey] = kHeavyArmorTechResearchTime,
			[kTechDataDisplayName] = "HEAVY_ARMOR_TECH"
		}, 
		
        {[kTechDataId] = kTechId.Armor1,
			[kTechDataCostKey] = kArmor1ResearchCost,
			[kTechDataResearchTimeKey] = kArmor1ResearchTime,
			[kTechDataDisplayName] = "MARINE_ARMOR1",
			[kTechDataHotkey] = Move.Z,
			[kTechDataTooltipInfo] = "MARINE_ARMOR1_TOOLTIP",
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "A1"
		},
		
        {[kTechDataId] = kTechId.Armor2,
			[kTechDataCostKey] = kArmor2ResearchCost,
			[kTechDataResearchTimeKey] = kArmor2ResearchTime,
			[kTechDataDisplayName] = "MARINE_ARMOR2",
			[kTechDataHotkey] = Move.X,
			[kTechDataTooltipInfo] = "MARINE_ARMOR2_TOOLTIP",
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "A2"
		},
		
        {[kTechDataId] = kTechId.Armor3,
			[kTechDataCostKey] = kArmor3ResearchCost,
			[kTechDataResearchTimeKey] = kArmor3ResearchTime,
			[kTechDataDisplayName] = "MARINE_ARMOR3",
			[kTechDataHotkey] = Move.C,
			[kTechDataTooltipInfo] = "MARINE_ARMOR3_TOOLTIP",
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "A3"
		},
		
        {[kTechDataId] = kTechId.Weapons1,
			[kTechDataCostKey] = kWeapons1ResearchCost,
			[kTechDataResearchTimeKey] = kWeapons1ResearchTime,
			[kTechDataDisplayName] = "MARINE_WEAPONS1",
			[kTechDataHotkey] = Move.Z,
			[kTechDataTooltipInfo] = "MARINE_WEAPONS1_TOOLTIP",
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "W1"
		},
		
        {[kTechDataId] = kTechId.Weapons2,
			[kTechDataCostKey] = kWeapons2ResearchCost,
			[kTechDataResearchTimeKey] = kWeapons2ResearchTime,
			[kTechDataDisplayName] = "MARINE_WEAPONS2",
			[kTechDataHotkey] = Move.Z,
			[kTechDataTooltipInfo] = "MARINE_WEAPONS2_TOOLTIP",
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "W2"
		},
		
        {[kTechDataId] = kTechId.Weapons3,
			[kTechDataCostKey] = kWeapons3ResearchCost,
			[kTechDataResearchTimeKey] = kWeapons3ResearchTime,
			[kTechDataDisplayName] = "MARINE_WEAPONS3",
			[kTechDataHotkey] = Move.Z,
			[kTechDataTooltipInfo] = "MARINE_WEAPONS3_TOOLTIP",
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "W3"
		},
		
        {[kTechDataId] = kTechId.AdvancedArmoryUpgrade,
			[kTechDataCostKey] = kAdvancedArmoryUpgradeCost,
			[kTechDataResearchTimeKey] = kAdvancedArmoryResearchTime,
			[kTechDataDisplayName] = "ADVANCED_ARMORY_UPGRADE",
			[kTechDataHotkey] = Move.U,
			[kTechDataTooltipInfo] =  "ADVANCED_ARMORY_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.PhaseTech,
			[kTechDataCostKey] = kPhaseTechResearchCost,
			[kTechDataResearchTimeKey] = kPhaseTechResearchTime,
			[kTechDataDisplayName] = "PHASE_TECH",
			[kTechDataTooltipInfo] = "PHASE_TECH_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.UpgradeTurretFactory,
			[kTechDataCostKey] = kUpgradeTurretFactoryCost,
			[kTechDataResearchTimeKey] = kUpgradeTurretFactoryTime,
			[kTechDataDisplayName] = "UPGRADE_TURRET_FACTORY",
			[kTechDataTooltipInfo] = "UPGRADE_TURRET_FACTORY_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.CatPackTech,
			[kTechDataCostKey] = kCatPackTechResearchCost,
			[kTechDataResearchTimeKey] = kCatPackTechResearchTime,
			[kTechDataDisplayName] = "CAT_PACKS",
			[kTechDataTooltipInfo] = "CAT_PACK_TECH_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.MotionTracking,
			[kTechDataCostKey] = kMotionTrackingResearchCost,
			[kTechDataResearchTimeKey] = kMotionTrackingResearchTime,
			[kTechDataDisplayName] = "MOTION_TRACKING",
			[kTechDataTooltipInfo] = "MOTION_TRACKING_TOOLTIP",
			[kTechDataCombatCost] = kCombatMarineBaseUpgradeCost,
			[kTechDataCombatDisplayName] = "MT"
		},
		
        {[kTechDataId] = kTechId.HandGrenadesTech,
			[kTechDataCostKey] = kHandGrenadesTechResearchCost,
			[kTechDataResearchTimeKey] = kHandGrenadesTechResearchTime,
			[kTechDataDisplayName] = "HAND_GRENADES_TECH",
			[kTechDataTooltipInfo] = "HAND_GRENADES_TECH_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.Electrify,
			[kTechDataCostKey] = kElectricalUpgradeResearchCost,
			[kTechDataResearchTimeKey] = kElectricalUpgradeResearchTime,
			[kTechDataDisplayName] = "ELECTRIFY",
			[kTechDataTooltipInfo] = "ELECTRIFY_TOOLTIP"
		},
            
        // ALIENS
        // tier 0 abilities
        {[kTechDataId] = kTechId.Bite, 
			[kTechDataMapName] = BiteLeap.kMapName,
			[kTechDataDamageType] = kBiteDamageType,
			[kTechDataDisplayName] = "BITE"
		},
		
        {[kTechDataId] = kTechId.Spit,
			[kTechDataMapName] = SpitSpray.kMapName,
			[kTechDataDamageType] = kSpitDamageType,
			[kTechDataDisplayName] = "SPIT"
		},
		
        {[kTechDataId] = kTechId.BuildAbility,
			[kTechDataMapName] = DropStructureAbility.kMapName,
			[kTechDataDisplayName] = "BUILD_ABILITY"
		},
		
        {[kTechDataId] = kTechId.LerkBite,
			[kTechDataDisplayName] = "LERK_BITE",
			[kTechDataDamageType] = kLerkBiteDamageType
		},
		
		{[kTechDataId] = kTechId.Swipe,
			[kTechDataMapName] = SwipeBlink.kMapName,
			[kTechDataDamageType] = kSwipeDamageType,
			[kTechDataDisplayName] = "SWIPE_BLINK"
		},
		
        {[kTechDataId] = kTechId.Gore,
			[kTechDataMapName] = Gore.kMapName,
			[kTechDataDamageType] = kGoreDamageType,
			[kTechDataDisplayName] = "GORE"
		},
		
        {[kTechDataId] = kTechId.Smash,
			[kTechDataMapName] = Smash.kMapName,
			[kTechDataDamageType] = kSmashDamageType,
			[kTechDataDisplayName] = "SMASH"
		},
        
        // tier 1 abilities
        {[kTechDataId] = kTechId.Parasite,
			[kTechDataMapName] = Parasite.kMapName,
			[kTechDataDamageType] = kParasiteDamageType,
			[kTechDataDisplayName] = "PARASITE"
		},
		
        {[kTechDataId] = kTechId.Spray,
			[kTechDataMapName] = SpitSpray.kMapName,
			[kTechDataDamageType] = kHealsprayDamageType,
			[kTechDataDisplayName] = "SPRAY"
		},
		
        {[kTechDataId] = kTechId.Spores,
			[kTechDataMapName] = Spores.kMapName,
			[kTechDataDamageType] = kSporeDamageType,
			[kTechDataDisplayName] = "SPORES"
		},
		
        {[kTechDataId] = kTechId.Blink,
			[kTechDataDisplayName] = "BLINK"
		},
		
        {[kTechDataId] = kTechId.Charge,
			[kTechDataDisplayName] = "CHARGE"
		},
        
        // tier 2 abilities
        {
			[kTechDataId] = kTechId.Leap,
			[kTechDataDisplayName] = "LEAP"
		},
		
        {[kTechDataId] = kTechId.BileBomb,
			[kTechDataMapName] = BileBomb.kMapName,
			[kTechDataDamageType] = kBileBombDamageType,
			[kTechDataDisplayName] = "BILEBOMB"
		},
		
		{[kTechDataId] = kTechId.Umbra,
			[kTechDataMapName] = Umbra.kMapName,
			[kTechDataDisplayName] = "UMBRA"
		},
		
        {[kTechDataId] = kTechId.Metabolize,
			//[kTechDataMapName] = Metabolize.kMapName,
			[kTechDataDisplayName] = "METABOLIZE"
		},
		
        {[kTechDataId] = kTechId.Stomp,
			[kTechDataDisplayName] = "STOMP"
		}, 

        // tier 3 abilities
        {[kTechDataId] = kTechId.Xenocide,
			[kTechDataMapName] = XenocideLeap.kMapName,
			[kTechDataDamageType] = kXenocideDamageType,
			[kTechDataDisplayName] = "XENOCIDE"
		},
		
        {[kTechDataId] = kTechId.Web,
			[kTechDataDisplayName] = "WEB",
			[kTechDataHint] = "WEB_HINT",
			[kTechDataModel] = Web.kModelName,
			[kTechDataSpecifyOrientation] = true,
			[kTechDataMaxHealth] = kWebHealth,
			[kTechDataMaxArmor] = kWebArmor,
			[kTechDataGhostModelClass] = "WebGhostModel",
			[kTechDataMaxAmount] = kNumWebsPerGorge,
			[kTechDataDisplayName] = "WEB",
			[kTechDataCostKey] = kWebBuildCost,
			[kTechDataTooltipInfo] = "WEB_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.PrimalScream,
			[kTechDataMapName] = Primal.kMapName,
			[kTechDataDisplayName] = "PRIMAL_SCREAM",
			[kTechDataTooltipInfo] = "PRIMAL_SCREAM_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.AcidRocket,
			[kTechDataMapName] = AcidRocket.kMapName,
			[kTechDataDisplayName] = "ACID_ROCKET",
			[kTechDataTooltipInfo] = "ACID_ROCKET_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.Devour,
			[kTechDataMapName] = Devour.kMapName,
			[kTechDataDamageType] = kDevourDamageType,
			[kTechDataDisplayName] = "DEVOUR"
		},
		
        {[kTechDataId] = kTechId.BabblerAbility,
			[kTechDataMapName] = BabblerAbility.kMapName,
			[kTechDataDisplayName] = "BABBLER_ABILITY",
			[kTechDataTooltipInfo] = "BABBLER_ABILITY_TOOLTIP",
			[kTechDataCostKey] = kBabblerAbilityResearchCost,
			[kTechDataResearchTimeKey] = kBabblerAbilityResearchTime
		},
		
        {[kTechDataId] = kTechId.Babbler,
			[kTechDataMapName] = Babbler.kMapName,
			[kTechDataDisplayName] = "BABBLER",
			[kTechDataModel] = Babbler.kModelName,
			[kTechDataMaxHealth] = kBabblerHealth,
			[kTechDataMaxArmor] = kBabblerArmor,
			[kTechDataPointValue] = kBabblerPointValue,
			[kTechDataTooltipInfo] = "BABBLER_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.BabblerEgg,
			[kTechDataAllowConsumeDrop] = true,
			[kTechDataMaxAmount] = kNumBabblerEggsPerGorge,
			[kTechDataCostKey] = kBabblerCost,
			[kTechDataBuildTime] = kBabblerEggBuildTime,
			[kTechDataGrows] = true,
			[kTechDataMapName] = BabblerEgg.kMapName,
			[kTechDataDisplayName] = "BABBLER_EGG",
			[kTechDataModel] = BabblerEgg.kModelName,
			[kTechDataMaxHealth] = kBabblerEggHealth,
			[kTechDataMaxArmor] = kBabblerEggArmor,
			[kTechDataPointValue] = kBabblerEggPointValue,
			[kTechDataTooltipInfo] = "BABBLER_EGG_TOOLTIP"
		},
        
        // Dev Abilities
        {[kTechDataId] = kTechId.Spikes,
			[kTechDataMapName] = Spikes.kMapName,
			[kTechDataDisplayName] = "SPIKES",
			[kTechDataTooltipInfo] = "SPIKES_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.WebStalk,
			[kTechDataDisplayName] = "WEB",
			[kTechDataHint] = "WEB_HINT",
			[kTechDataModel] = Bomb.kModelName,
			[kTechDataSpecifyOrientation] = true,
			[kTechDataGhostModelClass] = "WebGhostModel",
			[kTechDataMaxAmount] = kNumWebsPerGorge,
			[kTechDataDisplayName] = "WEB",
			[kTechDataCostKey] = kWebBuildCost,
			[kTechDataTooltipInfo] = "WEB_TOOLTIP"
		},        
        
        // Alien structures (spawn hive at 110 units off ground = 2.794 meters)
        {[kTechDataId] = kTechId.Hive,
			[kTechDataIgnorePathingMesh] = true,
			[kTechDataHint] = "HIVE_HINT",
			[kTechDataGhostModelClass] = "AlienGhostModel",
			[kTechDataMapName] = Hive.kMapName,
			[kTechDataDisplayName] = "HIVE",
			[kTechDataCostKey] = kHiveCost,
			[kTechDataBuildTime] = kHiveBuildTime,
			[kTechDataModel] = Hive.kModelName,
			[kTechDataHotkey] = Move.V,
			[kTechDataMaxHealth] = kHiveHealth,
			[kTechDataMaxArmor] = kHiveArmor,
			[kStructureAttachClass] = "TechPoint",
			[kTechDataSpawnHeightOffset] = kHiveYOffset,
			[kTechDataPointValue] = kHivePointValue,
			[kTechDataTooltipInfo] = "HIVE_TOOLTIP",
			[kTechDataCombatCost] = 100
		}, 
        
        {[kTechDataId] = kTechId.UpgradeToCragHive,
			[kTechDataMapName] = CragHive.kMapName,
			[kTechDataDisplayName] = "UPGRADE_CRAG_HIVE",
			[kTechDataModel] = Hive.kModelName,
			[kTechDataTooltipInfo] = "UPGRADE_CRAG_HIVE_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.UpgradeToShiftHive,
			[kTechDataMapName] = ShiftHive.kMapName,
			[kTechDataDisplayName] = "UPGRADE_SHIFT_HIVE",
			[kTechDataModel] = Hive.kModelName,
			[kTechDataTooltipInfo] = "UPGRADE_SHIFT_HIVE_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.UpgradeToShadeHive,
			[kTechDataMapName] = ShadeHive.kMapName,
			[kTechDataDisplayName] = "UPGRADE_SHADE_HIVE",
			[kTechDataModel] = Hive.kModelName,
			[kTechDataTooltipInfo] = "UPGRADE_SHADE_HIVE_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.UpgradeToWhipHive,
			[kTechDataMapName] = WhipHive.kMapName,
			[kTechDataDisplayName] = "UPGRADE_WHIP_HIVE",
			[kTechDataModel] = Hive.kModelName,
			[kTechDataTooltipInfo] = "UPGRADE_WHIP_HIVE_TOOLTIP"
		},
        
        {[kTechDataId] = kTechId.CragHive,
			[kTechDataHint] = "CRAG_HIVE_HINT",
			[kTechDataMapName] = CragHive.kMapName,
			[kTechDataBuildTime] = kHiveBuildTime,
			[kTechDataDisplayName] = "CRAG_HIVE",
			[kTechDataModel] = Hive.kModelName,
			[kTechDataHotkey] = Move.V,
			[kTechDataMaxHealth] = kHiveHealth,
			[kTechDataMaxArmor] = kHiveArmor,
			[kStructureAttachClass] = "TechPoint",
			[kTechDataSpawnHeightOffset] = kHiveYOffset,
			[kTechDataPointValue] = kHivePointValue,
			[kTechDataTooltipInfo] = "CRAG_HIVE_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.ShadeHive,
			[kTechDataHint] = "SHADE_HIVE_HINT",
			[kTechDataMapName] = ShadeHive.kMapName,
			[kTechDataBuildTime] = kHiveBuildTime,
			[kTechDataDisplayName] = "SHADE_HIVE",
			[kTechDataModel] = Hive.kModelName,
			[kTechDataHotkey] = Move.V,
			[kTechDataMaxHealth] = kHiveHealth,
			[kTechDataMaxArmor] = kHiveArmor,
			[kStructureAttachClass] = "TechPoint",
			[kTechDataSpawnHeightOffset] = kHiveYOffset,
			[kTechDataPointValue] = kHivePointValue,
			[kTechDataTooltipInfo] = "SHADE_HIVE_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.ShiftHive,
			[kTechDataHint] = "SHIFT_HIVE_HINT",
			[kTechDataMapName] = ShiftHive.kMapName,
			[kTechDataBuildTime] = kHiveBuildTime,
			[kTechDataDisplayName] = "SHIFT_HIVE",
			[kTechDataModel] = Hive.kModelName,
			[kTechDataHotkey] = Move.V,
			[kTechDataMaxHealth] = kHiveHealth,
			[kTechDataMaxArmor] = kHiveArmor,
			[kStructureAttachClass] = "TechPoint",
			[kTechDataSpawnHeightOffset] = kHiveYOffset,
			[kTechDataPointValue] = kHivePointValue,
			[kTechDataTooltipInfo] = "SHIFT_HIVE_TOOLTIP"
		},
		
        {[kTechDataId] = kTechId.WhipHive,
			[kTechDataHint] = "WHIP_HIVE_HINT",
			[kTechDataMapName] = WhipHive.kMapName,
			[kTechDataBuildTime] = kHiveBuildTime,
			[kTechDataDisplayName] = "WHIP_HIVE",
			[kTechDataModel] = Hive.kModelName,
			[kTechDataHotkey] = Move.V,
			[kTechDataMaxHealth] = kHiveHealth,
			[kTechDataMaxArmor] = kHiveArmor,
			[kStructureAttachClass] = "TechPoint",
			[kTechDataSpawnHeightOffset] = kHiveYOffset,
			[kTechDataPointValue] = kHivePointValue,
			[kTechDataTooltipInfo] = "WHIP_HIVE_TOOLTIP"
		},
        
        {[kTechDataId] = kTechId.TwoHives,
			[kTechDataKeyStructure] = kTechId.TwoHives,
			[kTechDataDisplayName] = "TWO_HIVES",
			[kTechDataTooltipInfo] = "TWO_HIVES_TOOLTIP",
			[kTechDataCombatCost] = kCombatAlienTwoHivesCost
		},
		
		{[kTechDataId] = kTechId.ThreeHives,
			[kTechDataKeyStructure] = kTechId.ThreeHives,
			[kTechDataDisplayName] = "THREE_HIVES",
			[kTechDataTooltipInfo] = "THREE_HIVES_TOOLTIP",
			[kTechDataCombatCost] = kCombatAlienThreeHivesCost
		},                
        
        // Alien buildables
        {[kTechDataId] = kTechId.Egg,
			[kTechDataHint] = "EGG_HINT",
			[kTechDataMapName] = Egg.kMapName,
			[kTechDataDisplayName] = "EGG",
			[kTechDataTooltipInfo] = "EGG_DROP_TOOLTIP",
			[kTechDataMaxHealth] = kEggHealth,
			[kTechDataMaxArmor] = kEggArmor,
			[kTechDataModel] = Egg.kModelName,
			[kTechDataPointValue] = kEggPointValue,
			[kTechDataBuildTime] = 1,
			[kTechDataCostKey] = 0,
			[kTechDataMaxExtents] = Vector(1.75/2, .664/2, 1.275/2)
		},

        {[kTechDataId] = kTechId.Harvester,
			[kTechDataIgnorePathingMesh] = true,
			[kTechDataCollideWithWorldOnly] = true,
			[kTechDataAllowStacking] = true,
			[kTechDataHint] = "HARVESTER_HINT",
			[kTechDataGhostModelClass] = "AlienGhostModel",
			[kTechDataMapName] = Harvester.kMapName,
			[kTechDataDisplayName] = "HARVESTER",
			[kTechDataCostKey] = kHarvesterCost,
			[kTechDataBuildTime] = kHarvesterBuildTime,
			[kTechDataHotkey] = Move.H,
			[kTechDataMaxHealth] = kHarvesterHealth,
			[kTechDataMaxArmor] = kHarvesterArmor,
			[kTechDataModel] = Harvester.kModelName,
			[kStructureAttachClass] = "ResourcePoint",
			[kTechDataPointValue] = kHarvesterPointValue,
			[kTechDataTooltipInfo] = "HARVESTER_TOOLTIP",
			[kTechDataCombatCost] = 100
		},
		
        {[kTechDataId] = kTechId.Crag,
			[kTechDataHint] = "CRAG_HINT",
			[kTechDataGhostModelClass] = "AlienGhostModel",
			[kTechDataMapName] = Crag.kMapName,
			[kTechDataDisplayName] = "CRAG",
			[kTechDataCostKey] = kCragCost,
			[kTechDataHotkey] = Move.C,
			[kTechDataBuildTime] = kCragBuildTime,
			[kTechDataModel] = Crag.kModelName,
			[kTechDataMaxHealth] = kCragHealth,
			[kTechDataMaxArmor] = kCragArmor,
			[kTechDataPointValue] = kCragPointValue,
			[kTechDataTooltipInfo] = "CRAG_TOOLTIP",
			[kTechDataGrows] = true,
			[kTechDataCombatCost] = kCombatAlienSupportStructureCost
		},
		
        {[kTechDataId] = kTechId.Shift,
			[kTechDataHint] = "SHIFT_HINT",
			[kTechDataGhostModelClass] = "AlienGhostModel",
			[kTechDataMapName] = Shift.kMapName,
			[kTechDataDisplayName] = "SHIFT",
			[kTechDataCostKey] = kShiftCost,
			[kTechDataHotkey] = Move.S,
			[kTechDataBuildTime] = kShiftBuildTime,
			[kTechDataModel] = Shift.kModelName,
			[kTechDataMaxHealth] = kShiftHealth,
			[kTechDataMaxArmor] = kShiftArmor,
			[kTechDataPointValue] = kShiftPointValue,
			[kTechDataTooltipInfo] = "SHIFT_TOOLTIP",
			[kTechDataGrows] = true,
			[kTechDataCombatCost] = kCombatAlienSupportStructureCost 
		},
		
        {[kTechDataId] = kTechId.Shade,
			[kTechDataHint] = "SHADE_HINT",
			[kTechDataGhostModelClass] = "AlienGhostModel",
			[kTechDataMapName] = Shade.kMapName,
			[kTechDataDisplayName] = "SHADE",
			[kTechDataCostKey] = kShadeCost,
			[kTechDataBuildTime] = kShadeBuildTime,
			[kTechDataHotkey] = Move.D,
			[kTechDataModel] = Shade.kModelName,
			[kTechDataMaxHealth] = kShadeHealth,
			[kTechDataMaxArmor] = kShadeArmor,
			[kTechDataPointValue] = kShadePointValue,
			[kTechDataMaxExtents] = Vector(1.5, 1.5, .4),
			[kTechDataTooltipInfo] = "SHADE_TOOLTIP",
			[kTechDataGrows] = true,
			[kTechDataCombatCost] = kCombatAlienSupportStructureCost
		},
		
        {[kTechDataId] = kTechId.Whip,
			[kTechDataHint] = "WHIP_HINT",
			[kTechDataGhostModelClass] = "AlienGhostModel",
			[kTechDataMapName] = Whip.kMapName,
			[kTechDataDisplayName] = "WHIP",
			[kTechDataCostKey] = kWhipCost,
			[kTechDataBuildTime] = kWhipBuildTime,
			[kTechDataHotkey] = Move.D,
			[kTechDataModel] = Whip.kModelName,
			[kTechDataMaxHealth] = kWhipHealth,
			[kTechDataMaxArmor] = kWhipArmor,
			[kTechDataPointValue] = kWhipPointValue,
			[kTechDataTooltipInfo] = "WHIP_TOOLTIP",
			[kTechDataGrows] = true,
			[kTechDataCombatCost] = kCombatAlienSupportStructureCost
		},
		
        {[kTechDataId] = kTechId.Hydra,
			[kTechDataHint] = "HYDRA_HINT",
			[kTechDataDamageType] = kHydraAttackDamageType,
			[kTechDataGhostModelClass] = "AlienGhostModel",
			[kTechDataMapName] = Hydra.kMapName,
			[kTechDataDisplayName] = "HYDRA",
			[kTechDataCostKey] = kHydraCost,
			[kTechDataBuildTime] = kHydraBuildTime,
			[kTechDataMaxHealth] = kHydraHealth,
			[kTechDataMaxArmor] = kHydraArmor,
			[kTechDataModel] = Hydra.kModelName,
			[kVisualRange] = Hydra.kRange,
			[kTechDataPointValue] = kHydraPointValue,
			[kTechDataGrows] = true,
			[kTechDataGhostModelScale] = kHydraScale,
			[kTechDataCombatCost] = kCombatAlienSupportStructureCost
		},

        // Alien lifeforms
        {[kTechDataId] = kTechId.Skulk,
			[kTechDataMapName] = Skulk.kMapName,
			[kTechDataGestateName] = Skulk.kMapName,
			[kTechDataGestateTime] = kSkulkGestateTime,
			[kTechDataDisplayName] = "SKULK",
			[kTechDataTooltipInfo] = "SKULK_TOOLTIP",
			[kTechDataModel] = Skulk.kModelName,
			[kTechDataCostKey] = kSkulkCost,
			[kTechDataMaxHealth] = kSkulkHealth,
			[kTechDataMaxArmor] = kSkulkArmor,
			[kTechDataEngagementDistance] = kPlayerEngagementDistance,
			[kTechDataMaxExtents] = Vector(Skulk.kXExtents, Skulk.kYExtents, Skulk.kZExtents),
			[kTechDataPointValue] = kSkulkPointValue,
			[kTechDataCombatCost] = 0
		},
		
        {[kTechDataId] = kTechId.Gorge,
			[kTechDataMapName] = Gorge.kMapName,
			[kTechDataGestateName] = Gorge.kMapName,
			[kTechDataGestateTime] = kGorgeGestateTime,
			[kTechDataDisplayName] = "GORGE",
			[kTechDataTooltipInfo] = "GORGE_TOOLTIP",
			[kTechDataModel] = Gorge.kModelName,
			[kTechDataCostKey] = kGorgeCost,
			[kTechDataMaxHealth] = kGorgeHealth,
			[kTechDataMaxArmor] = kGorgeArmor,
			[kTechDataEngagementDistance] = kPlayerEngagementDistance,
			[kTechDataMaxExtents] = Vector(Gorge.kXZExtents, Gorge.kYExtents, Gorge.kXZExtents),
			[kTechDataPointValue] = kGorgePointValue,
			[kTechDataCombatCost] = kCombatAlienGorgeCost
		},
		
        {[kTechDataId] = kTechId.Lerk,
			[kTechDataMapName] = Lerk.kMapName,
			[kTechDataGestateName] = Lerk.kMapName,
			[kTechDataGestateTime] = kLerkGestateTime,
			[kTechDataDisplayName] = "LERK",
			[kTechDataTooltipInfo] = "LERK_TOOLTIP",
			[kTechDataModel] = Lerk.kModelName,
			[kTechDataCostKey] = kLerkCost,
			[kTechDataMaxHealth] = kLerkHealth,
			[kTechDataMaxArmor] = kLerkArmor,
			[kTechDataEngagementDistance] = kPlayerEngagementDistance,
			[kTechDataMaxExtents] = Vector(Lerk.XZExtents, Lerk.YExtents, Lerk.XZExtents),
			[kTechDataPointValue] = kLerkPointValue,
			[kTechDataCombatCost] = kCombatAlienLerkCost
		},
		
        {[kTechDataId] = kTechId.Fade,
			[kTechDataMapName] = Fade.kMapName,
			[kTechDataGestateName] = Fade.kMapName,
			[kTechDataGestateTime] = kFadeGestateTime,
			[kTechDataDisplayName] = "FADE",
			[kTechDataTooltipInfo] = "FADE_TOOLTIP",
			[kTechDataModel] = Fade.kModelName,
			[kTechDataCostKey] = kFadeCost,
			[kTechDataMaxHealth] = kFadeHealth,
			[kTechDataEngagementDistance] = kPlayerEngagementDistance,
			[kTechDataMaxArmor] = kFadeArmor,
			[kTechDataMaxExtents] = Vector(Fade.XZExtents, Fade.YExtents, Fade.XZExtents),
			[kTechDataPointValue] = kFadePointValue,
			[kTechDataCombatCost] = kCombatAlienFadeCost
		},
		
        {[kTechDataId] = kTechId.Onos,
			[kTechDataMapName] = Onos.kMapName,
			[kTechDataGestateName] = Onos.kMapName,
			[kTechDataGestateTime] = kOnosGestateTime,
			[kTechDataDisplayName] = "ONOS",
			[kTechDataTooltipInfo] = "ONOS_TOOLTIP",
			[kTechDataModel] = Onos.kModelName,
			[kTechDataCostKey] = kOnosCost,
			[kTechDataMaxHealth] = kOnosHealth,
			[kTechDataEngagementDistance] = kOnosEngagementDistance,
			[kTechDataMaxArmor] = kOnosArmor,
			[kTechDataMaxExtents] = Vector(Onos.XExtents, Onos.YExtents, Onos.ZExtents),
			[kTechDataPointValue] = kOnosPointValue,
			[kTechDataCombatCost] = kCombatAlienOnosCost
		},
		
        {[kTechDataId] = kTechId.Embryo,
			[kTechDataMapName] = Embryo.kMapName,
			[kTechDataGestateName] = Embryo.kMapName,
			[kTechDataDisplayName] = "EMBRYO",
			[kTechDataModel] = Embryo.kModelName,
			[kTechDataMaxExtents] = Vector(Embryo.kXExtents, Embryo.kYExtents, Embryo.kZExtents)
		},

        // Lifeform purchases
        {[kTechDataId] = kTechId.Carapace,
			[kTechDataCategory] = kTechId.CragHive,
			[kTechDataKeyStructure] = kTechId.Crag,
			[kTechDataDisplayName] = "CARAPACE",
			[kTechDataCostKey] = kCarapaceCost,
			[kTechDataTooltipInfo] = "CARAPACE_TOOLTIP",
			[kTechDataCombatCost] = kCombatAlienUpgradeCost
		},
		
        {[kTechDataId] = kTechId.Regeneration,
			[kTechDataCategory] = kTechId.CragHive,
			[kTechDataKeyStructure] = kTechId.Crag,
			[kTechDataDisplayName] = "REGENERATION",
			[kTechDataCostKey] = kRegenerationCost,
			[kTechDataTooltipInfo] = "REGENERATION_TOOLTIP",
			[kTechDataCombatCost] = kCombatAlienUpgradeCost
		},
		
        {[kTechDataId] = kTechId.Redemption,
			[kTechDataCategory] = kTechId.CragHive,
			[kTechDataKeyStructure] = kTechId.Crag,
			[kTechDataDisplayName] = "REDEMPTION",
			[kTechDataTooltipInfo] = "REDEMPTION_TOOLTIP",
			[kTechDataCostKey] = kRedemptionCost,
			[kTechDataCombatCost] = kCombatAlienUpgradeCost
		},
 
        {[kTechDataId] = kTechId.Celerity,
			[kTechDataCategory] = kTechId.ShiftHive,
			[kTechDataKeyStructure] = kTechId.Shift,
			[kTechDataDisplayName] = "CELERITY",
			[kTechDataTooltipInfo] = "CELERITY_TOOLTIP",
			[kTechDataCostKey] = kCelerityCost,
			[kTechDataCombatCost] = kCombatAlienUpgradeCost
		},
		
        {[kTechDataId] = kTechId.Adrenaline,
			[kTechDataCategory] = kTechId.ShiftHive,
			[kTechDataKeyStructure] = kTechId.Shift,
			[kTechDataDisplayName] = "ADRENALINE",
			[kTechDataTooltipInfo] = "ADRENALINE_TOOLTIP",
			[kTechDataCostKey] = kAdrenalineCost,
			[kTechDataCombatCost] = kCombatAlienUpgradeCost
		},
		
        {[kTechDataId] = kTechId.Redeployment,
			[kTechDataCategory] = kTechId.ShiftHive,
			[kTechDataKeyStructure] = kTechId.Shift,
			[kTechDataDisplayName] = "REDEPLOYMENT",
			[kTechDataTooltipInfo] = "REDEPLOYMENT_TOOLTIP",
			[kTechDataCostKey] = kRedeploymentCost,
			[kTechDataCombatCost] = kCombatAlienUpgradeCost
		},
		
        {[kTechDataId] = kTechId.Silence2,
			[kTechDataImplemented] = false,
			[kTechDataCategory] = kTechId.ShiftHive,
			[kTechDataKeyStructure] = kTechId.Shift,
			[kTechDataDisplayName] = "SILENCE",
			[kTechDataTooltipInfo] = "SILENCE_TOOLTIP",
			[kTechDataCostKey] = kSilenceCost,
			[kTechDataCombatCost] = kCombatAlienUpgradeCost
		},
        
        {[kTechDataId] = kTechId.Silence,
			[kTechDataCategory] = kTechId.ShadeHive,
			[kTechDataKeyStructure] = kTechId.Shade,
			[kTechDataDisplayName] = "SILENCE",
			[kTechDataTooltipInfo] = "SILENCE_TOOLTIP",
			[kTechDataCostKey] = kSilenceCost,
			[kTechDataCombatCost] = kCombatAlienUpgradeCost
		},
		
        {[kTechDataId] = kTechId.Aura,
			[kTechDataCategory] = kTechId.ShadeHive,
			[kTechDataKeyStructure] = kTechId.Shade,
			[kTechDataDisplayName] = "AURA",
			[kTechDataTooltipInfo] = "AURA_TOOLTIP",
			[kTechDataCostKey] = kAuraCost,
			[kTechDataCombatCost] = kCombatAlienUpgradeCost
		},
		
        {[kTechDataId] = kTechId.Ghost,
			[kTechDataCategory] = kTechId.ShadeHive,
			[kTechDataKeyStructure] = kTechId.Shade,
			[kTechDataDisplayName] = "GHOST",
			[kTechDataTooltipInfo] = "GHOST_TOOLTIP",
			[kTechDataCostKey] = kGhostCost,
			[kTechDataCombatCost] = kCombatAlienUpgradeCost
		},
		
        {[kTechDataId] = kTechId.Camouflage,
			[kTechDataImplemented] = false,
			[kTechDataCategory] = kTechId.ShadeHive,
			[kTechDataKeyStructure] = kTechId.Shade,
			[kTechDataDisplayName] = "CAMOUFLAGE",
			[kTechDataTooltipInfo] = "CAMOUFLAGE_TOOLTIP",
			[kTechDataCostKey] = kCamouflageCost,
			[kTechDataCombatCost] = kCombatAlienUpgradeCost
		},
        
        {[kTechDataId] = kTechId.Focus,
			[kTechDataCategory] = kTechId.WhipHive,
			[kTechDataKeyStructure] = kTechId.Whip,
			[kTechDataDisplayName] = "FOCUS",
			[kTechDataTooltipInfo] = "FOCUS_TOOLTIP",
			[kTechDataCostKey] = kFocusCost,
			[kTechDataCombatCost] = kCombatAlienFocusCost
		},
		
        {[kTechDataId] = kTechId.Fury,
			[kTechDataCategory] = kTechId.WhipHive,
			[kTechDataKeyStructure] = kTechId.Whip,
			[kTechDataDisplayName] = "FURY",
			[kTechDataTooltipInfo] = "FURY_TOOLTIP",
			[kTechDataCostKey] = kFuryCost,
			[kTechDataCombatCost] = kCombatAlienUpgradeCost
		},
		
        {[kTechDataId] = kTechId.Bombard,
			[kTechDataCategory] = kTechId.WhipHive,
			[kTechDataKeyStructure] = kTechId.Whip,
			[kTechDataDisplayName] = "BOMBARD",
			[kTechDataTooltipInfo] = "BOMBARD_TOOLTIP",
			[kTechDataCostKey] = kBombardCost,
			[kTechDataCombatCost] = kCombatAlienUpgradeCost
		},
        
        // Alerts
        {[kTechDataId] = kTechId.MarineAlertSentryUnderAttack,
			[kTechDataAlertSound] = Sentry.kUnderAttackSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertPriority] = 0,
			[kTechDataAlertText] = "MARINE_ALERT_SENTRY_UNDERATTACK",
			[kTechDataAlertTeam] = false
		},
		
        {[kTechDataId] = kTechId.MarineAlertSoldierUnderAttack,
			[kTechDataAlertSound] = MarineCommander.kSoldierUnderAttackSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertPriority] = 0,
			[kTechDataAlertText] = "MARINE_ALERT_SOLDIER_UNDERATTACK",
			[kTechDataAlertTeam] = true
		},
		
        {[kTechDataId] = kTechId.MarineAlertStructureUnderAttack,
			[kTechDataAlertSound] = MarineCommander.kStructureUnderAttackSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertPriority] = 1,
			[kTechDataAlertText] = "MARINE_ALERT_STRUCTURE_UNDERATTACK",
			[kTechDataAlertTeam] = true
		},
		
        {[kTechDataId] = kTechId.MarineAlertExtractorUnderAttack,
			[kTechDataAlertSound] = MarineCommander.kStructureUnderAttackSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertPriority] = 1,
			[kTechDataAlertText] = "MARINE_ALERT_EXTRACTOR_UNDERATTACK",
			[kTechDataAlertTeam] = true,
			[kTechDataAlertIgnoreDistance] = true
		},
		
        {[kTechDataId] = kTechId.MarineAlertCommandStationUnderAttack,
			[kTechDataAlertSound] = CommandStation.kUnderAttackSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertPriority] = 2,
			[kTechDataAlertText] = "MARINE_ALERT_COMMANDSTATION_UNDERAT",
			[kTechDataAlertTeam] = true,
			[kTechDataAlertIgnoreDistance] = true,
			[kTechDataAlertSendTeamMessage] = kTeamMessageTypes.CommandStationUnderAttack
		},
		
        {[kTechDataId] = kTechId.MarineAlertInfantryPortalUnderAttack,
			[kTechDataAlertSound] = InfantryPortal.kUnderAttackSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertPriority] = 1,
			[kTechDataAlertText] = "MARINE_ALERT_INFANTRYPORTAL_UNDERAT",
			[kTechDataAlertTeam] = true,
			[kTechDataAlertSendTeamMessage] = kTeamMessageTypes.IPUnderAttack
		},

        {[kTechDataId] = kTechId.MarineAlertCommandStationComplete,
			[kTechDataAlertSound] = MarineCommander.kCommandStationCompletedSoundName,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertText] = "MARINE_ALERT_COMMAND_STATION_COMPLETE",
			[kTechDataAlertTeam] = true
		},
		
        {[kTechDataId] = kTechId.MarineAlertConstructionComplete,
			[kTechDataAlertSound] = MarineCommander.kObjectiveCompletedSoundName,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertText] = "MARINE_ALERT_CONSTRUCTION_COMPLETE",
			[kTechDataAlertTeam] = false
		},
		
        {[kTechDataId] = kTechId.MarineCommanderEjected,
			[kTechDataAlertSound] = MarineCommander.kCommanderEjectedSoundName,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertText] = "MARINE_ALERT_COMMANDER_EJECTED",
			[kTechDataAlertTeam] = true
		},
		
        {[kTechDataId] = kTechId.MarineAlertSentryFiring,
			[kTechDataAlertSound] = MarineCommander.kSentryFiringSoundName,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertText] = "MARINE_ALERT_SENTRY_FIRING"
		},
		
        {[kTechDataId] = kTechId.MarineAlertSoldierLost,
			[kTechDataAlertSound] = MarineCommander.kSoldierLostSoundName,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertText] = "MARINE_ALERT_SOLDIER_LOST",
			[kTechDataAlertOthersOnly] = true
		},
		
        {[kTechDataId] = kTechId.MarineAlertAcknowledge,
			[kTechDataAlertSound] = MarineCommander.kSoldierAcknowledgesSoundName,
			[kTechDataAlertType] = kAlertType.Request,
			[kTechDataAlertText] = "MARINE_ALERT_ACKNOWLEDGE"
		},
		
        {[kTechDataId] = kTechId.MarineAlertNeedAmmo,
			[kTechDataAlertIgnoreInterval] = true,
			[kTechDataAlertSound] = MarineCommander.kSoldierNeedsAmmoSoundName,
			[kTechDataAlertType] = kAlertType.Request,
			[kTechDataAlertText] = "MARINE_ALERT_NEED_AMMO"
		},
		
        {[kTechDataId] = kTechId.MarineAlertNeedMedpack,
			[kTechDataAlertIgnoreInterval] = true,
			[kTechDataAlertSound] = MarineCommander.kSoldierNeedsHealthSoundName,
			[kTechDataAlertType] = kAlertType.Request,
			[kTechDataAlertText] = "MARINE_ALERT_NEED_MEDPACK"
		},
		
        {[kTechDataId] = kTechId.MarineAlertNeedOrder,
			[kTechDataAlertIgnoreInterval] = true,
			[kTechDataAlertSound] = MarineCommander.kSoldierNeedsOrderSoundName,
			[kTechDataAlertType] = kAlertType.Request,
			[kTechDataAlertText] = "MARINE_ALERT_NEED_ORDER"
		},
		
        {[kTechDataId] = kTechId.MarineAlertUpgradeComplete,
			[kTechDataAlertSound] = MarineCommander.kUpgradeCompleteSoundName,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertText] = "MARINE_ALERT_UPGRADE_COMPLETE"
		},
		
        {[kTechDataId] = kTechId.MarineAlertResearchComplete,
			[kTechDataAlertSound] = MarineCommander.kResearchCompleteSoundName,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertText] = "MARINE_ALERT_RESEARCH_COMPLETE"
		},
		
        {[kTechDataId] = kTechId.MarineAlertManufactureComplete,
			[kTechDataAlertSound] = MarineCommander.kManufactureCompleteSoundName,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertText] = "MARINE_ALERT_MANUFACTURE_COMPLETE"
		},
		
        {[kTechDataId] = kTechId.MarineAlertNotEnoughResources,
			[kTechDataAlertSound] = Player.kNotEnoughResourcesSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertText] = "MARINE_ALERT_NOT_ENOUGH_RESOURCES"
		},
		
        {[kTechDataId] = kTechId.MarineAlertOrderComplete,
			[kTechDataAlertSound] = MarineCommander.kObjectiveCompletedSoundName,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertText] = "MARINE_ALERT_ORDER_COMPLETE"
		},
    
        {[kTechDataId] = kTechId.AlienAlertHiveUnderAttack,
			[kTechDataAlertSound] = Hive.kUnderAttackSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertPriority] = 2,
			[kTechDataAlertText] = "ALIEN_ALERT_HIVE_UNDERATTACK",
			[kTechDataAlertTeam] = true,
			[kTechDataAlertIgnoreDistance] = true,
			[kTechDataAlertSendTeamMessage] = kTeamMessageTypes.HiveUnderAttack
		},
		
        {[kTechDataId] = kTechId.AlienAlertEnemyApproaches,
			[kTechDataAlertSound] = Hive.kEnemyApproachesSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertPriority] = 2,
			[kTechDataAlertText] = "ALIEN_ALERT_ENEMY_APPROACHES",
			[kTechDataAlertTeam] = true,
			[kTechDataAlertIgnoreDistance] = true,
			[kTechDataAlertSendTeamMessage] = kTeamMessageTypes.HiveInDanger
		},
		
        {[kTechDataId] = kTechId.AlienAlertStructureUnderAttack,
			[kTechDataAlertSound] = Hive.kStructureUnderAttackSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertPriority] = 0,
			[kTechDataAlertText] = "ALIEN_ALERT_STRUCTURE_UNDERATTACK",
			[kTechDataAlertTeam] = true
		},
		
        {[kTechDataId] = kTechId.AlienAlertHarvesterUnderAttack,
			[kTechDataAlertSound] = Hive.kHarvesterUnderAttackSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertPriority] = 1,
			[kTechDataAlertText] = "ALIEN_ALERT_HARVESTER_UNDERATTACK",
			[kTechDataAlertTeam] = true,
			[kTechDataAlertIgnoreDistance] = true
		},
		
        {[kTechDataId] = kTechId.AlienAlertLifeformUnderAttack,
			[kTechDataAlertSound] = Hive.kLifeformUnderAttackSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertPriority] = 0,
			[kTechDataAlertText] = "ALIEN_ALERT_LIFEFORM_UNDERATTACK",
			[kTechDataAlertTeam] = true
		},

        {[kTechDataId] = kTechId.AlienAlertHiveDying,
			[kTechDataAlertSound] = Hive.kDyingSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertPriority] = 3,
			[kTechDataAlertText] = "ALIEN_ALERT_HIVE_DYING",
			[kTechDataAlertTeam] = true,
			[kTechDataAlertIgnoreDistance] = true
		},
		
        {[kTechDataId] = kTechId.AlienAlertHiveComplete,
			[kTechDataAlertSound] = Hive.kCompleteSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertText] = "ALIEN_ALERT_HIVE_COMPLETE",
			[kTechDataAlertTeam] = true,
			[kTechDataAlertIgnoreDistance] = true
		},
		
        {[kTechDataId] = kTechId.AlienAlertHiveSpecialComplete,
			[kTechDataAlertSound] = Hive.kSpecialCompleteSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertText] = "ALIEN_ALERT_HIVE_COMPLETE",
			[kTechDataAlertTeam] = true,
			[kTechDataAlertIgnoreDistance] = true
		},
		
        {[kTechDataId] = kTechId.AlienAlertGorgeBuiltHarvester,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertText] = "ALIEN_ALERT_GORGEBUILT_HARVESTER"
		},
		
        {[kTechDataId] = kTechId.AlienAlertNotEnoughResources,
			[kTechDataAlertSound] = Alien.kNotEnoughResourcesSound,
			[kTechDataAlertType] = kAlertType.Info,
			[kTechDataAlertText] = "ALIEN_ALERT_NOTENOUGH_RESOURCES"
		},

        {[kTechDataId] = kTechId.DeathTrigger,
			[kTechDataDisplayName] = "DEATH_TRIGGER",
			[kTechDataMapName] = DeathTrigger.kMapName,
			[kTechDataModel] = ""
		}

    }

    return techData

end

kTechData = nil

function LookupTechId(fieldData, fieldName)

    -- Initialize table if necessary
    if(kTechData == nil) then
    
        kTechData = BuildTechData()
        
    end
    
    if fieldName == nil or fieldName == "" then
    
        Print("LookupTechId(%s, %s) called improperly.", tostring(fieldData), tostring(fieldName))
        return kTechId.None
        
    end

    for index,record in ipairs(kTechData) do 
    
        local currentField = record[fieldName]
        
        if(fieldData == currentField) then
        
            return record[kTechDataId]
            
        end

    end
    
    --Print("LookupTechId(%s, %s) returned kTechId.None", fieldData, fieldName)
    
    return kTechId.None

end

-- Table of fieldName tables. Each fieldName table is indexed by techId and returns data.
local cachedTechData = {}

function ClearCachedTechData()
    cachedTechData = {}
end

-- Returns true or false. If true, return output in "data"
function GetCachedTechData(techId, fieldName)
    
    local entry = cachedTechData[fieldName]
    
    if entry ~= nil then
    
        return entry[techId]
        
    end
        
    return nil
    
end

function SetCachedTechData(techId, fieldName, data, force)

    local inserted = false
    
    local entry = cachedTechData[fieldName]
    
    if force or entry == nil then
    
        cachedTechData[fieldName] = {}
        entry = cachedTechData[fieldName]
        
    end
    
    if force or entry[techId] == nil then
    
        entry[techId] = data
        inserted = true
        
    end
    
    return inserted
    
end

-- Call with techId and fieldname (returns nil if field not found). Pass optional
-- third parameter to use as default if not found.
function LookupTechData(techId, fieldName, default)

    -- Initialize table if necessary
    if(kTechData == nil) then
    
        kTechData = BuildTechData()
        
    end
    
    if techId == nil or techId == 0 or fieldName == nil or fieldName == "" then
    
        --[[
        local techIdString = ""
        if type(tonumber(techId)) == "number" then            
            techIdString = EnumToString(kTechId, techId)
        end
        
        Print("LookupTechData(%s, %s, %s) called improperly.", tostring(techIdString), tostring(fieldName), tostring(default))
        --]]
        
        return default
        
    end
    
    local gameInfo = GetGameInfoEntity()
    
    if fieldName == kTechDataUpgradeCost or fieldName == kTechDataCostKey and gameInfo then
        if gameInfo:GetWarmUpActive() then return 0 end
    end
    
    if fieldName == kTechDataCostKey and gameInfo and gameInfo:GetGameMode() == kGameMode.Combat then
        //In Combat, use combat costs
        fieldName = kTechDataCombatCost
    end

    local data = GetCachedTechData(techId, fieldName)
    
    if data == nil then
    
        for index,record in ipairs(kTechData) do 
        
            local currentid = record[kTechDataId]

            if(techId == currentid and record[fieldName] ~= nil) then
            
                data = record[fieldName]
                
                break
                
            end
            
        end        
        
        if data == nil then
            data = default
        end
        
        if not SetCachedTechData(techId, fieldName, data) then
            --Print("Didn't insert anything when calling SetCachedTechData(%d, %s, %s)", techId, fieldName, tostring(data))
        else
            --Print("Inserted new field with SetCachedTechData(%d, %s, %s)", techId, fieldName, tostring(data))
        end
    
    end
    
    return data

end

-- Returns true if specified class name is used to attach objects to
function GetIsAttachment(className)
    return (className == "TechPoint") or (className == "ResourcePoint")
end

function GetRecycleAmount(techId, upgradeLevel)

    local amount = GetCachedTechData(techId, kTechDataCostKey)
    if techId == kTechId.AdvancedArmory then
        amount = GetCachedTechData(kTechId.Armory, kTechDataCostKey, 0) + GetCachedTechData(kTechId.AdvancedArmoryUpgrade, kTechDataCostKey, 0)
    end

    return amount
    
end

local gTechForCategory
function GetTechForCategory(techId)

    if gTechForCategory == nil then

        gTechForCategory = {}

        for upgradeId = 2, #kTechId do
        
            local category = LookupTechData(upgradeId, kTechDataCategory, nil)
            if category and category ~= kTechId.None then
                
                if not gTechForCategory[category] then
                    gTechForCategory[category] = {}
                end
                
                table.insertunique(gTechForCategory[category], upgradeId)

            end
        
        end
    
    end
    
    return gTechForCategory[techId] or {}

end