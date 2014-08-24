// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineStructureEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kMarineStructureEffects = 
{

    scan_abort =
    {
        scanAbortEffects =
        {
            {cinematic = "cinematics/marine/scanabort.cinematic"},
            {sound = "sound/NS2.fev/marine/structures/observatory_scan", done = true},
        }
    },

    ghoststructure_destroy =
    {
        ghostStructureDestroyEffects =
        {
            {sound = "sound/NS2.fev/marine/structures/mac/build"},
            {cinematic = "cinematics/marine/ghoststructure_destroy.cinematic", done = true},
        }
    
    },

    // When players or MACs build a structure
    construct =
    {    
        marineConstructEffects =
        {
            {cinematic = "cinematics/marine/construct_infantryportal.cinematic", classname = "InfantryPortal", isalien = false, done = true},
            {cinematic = "cinematics/marine/construct_big.cinematic", classname = "CommandStation", isalien = false, done = true},
            {cinematic = "cinematics/marine/construct.cinematic", isalien = false},
        },        
    },
    
    // Play when marine welds another marine's armor
    marine_welded = 
    {
        marineWelded =
        {
            {cinematic = "cinematics/marine/mac/build.cinematic", isalien = false},
            {sound = "sound/NS2.fev/marine/structures/mac/build", isalien = false, done = true},
        },
    },

    construction_complete = 
    {
        marineConstructCompleteSounds =
        {
            // TODO: hook up new sounds for builder
            //{sound = "sound/NS2.fev/marine/structures/mac/build", isalien = false, done = true},
        },
    },
    
    recycle_start =
    {
        recycleStartEffects =
        {
            {sound = "sound/NS2.fev/marine/structures/recycle"},
        },        
    },

    recycle_end =
    {
        recycleEndEffects =
        {
            {cinematic = "cinematics/marine/structures/recycle.cinematic"},
        },        
    },
    
    death =
    {
        marineStructureDeathCinematics =
        {
            {cinematic = "cinematics/marine/structures/death_large.cinematic", classname = "TurretFactory", done = true},
            {cinematic = "cinematics/marine/structures/death_large.cinematic", classname = "PhaseGate", done = true},
            {cinematic = "cinematics/marine/structures/death_small.cinematic", classname = "Extractor", done = true},
            {cinematic = "cinematics/marine/structures/death_large.cinematic", classname = "CommandStation", done = true},
            {cinematic = "cinematics/marine/structures/death_large.cinematic", classname = "PrototypeLab", done = true},
            {cinematic = "cinematics/marine/structures/death_large.cinematic", classname = "ArmsLab", done = true},
            {cinematic = "cinematics/marine/structures/death_large.cinematic", classname = "Armory", done = true},
            {cinematic = "cinematics/marine/sentry/death.cinematic", classname = "Sentry", done = true},
            {cinematic = "cinematics/marine/structures/death_small.cinematic", classname = "Observatory", done = true},
            {cinematic = "cinematics/marine/infantryportal/death.cinematic", classname = "InfantryPortal", done = true},
            {cinematic = "cinematics/marine/structures/death_small.cinematic", classname = "SentryBattery", done = true},
        },
        
        marineStructureDeathSounds =
        {
            {sound = "sound/NS2.fev/marine/structures/generic_death", classname = "TurretFactory", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_death", classname = "PhaseGate", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_death", classname = "PrototypeLab", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_death", classname = "ArmsLab", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_death", classname = "Armory", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_death", classname = "Sentry", done = true},
            {sound = "sound/NS2.fev/marine/structures/command_station_death", classname = "CommandStation", done = true},
            {sound = "sound/NS2.fev/marine/structures/extractor_death", classname = "Extractor", done = true},
            {sound = "sound/NS2.fev/marine/power_node/destroyed_powerdown", classname = "PowerPoint", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_death", classname = "InfantryPortal", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_death", classname = "SentryBattery", done = true},
        },
    },
    
    // When players weld power points
    player_weld = 
    {
        macWeldEffects =
        {
            {sound = "sound/NS2.fev/marine/structures/mac/weld"},
            {cinematic = "cinematics/marine/mac/weld.cinematic", attach_point = "fxnode_welder"},
        },
    },

    // Called when SiegeCannon is created out of robotics factory
    sc_built =
    {
        arcDeployEffects =
        {
            {cinematic = "cinematics/marine/structures/spawn_building.cinematic"},
        },
    },            
    
    // Switching into siege mode
    sc_deploying =
    {
        arcDeployEffects =
        {
            {sound = "sound/ns2c.fev/ns2c/marine/siegecannon/deploy"},
        },
    },    
    
    // Switching back to movement mode
    sc_inactive =
    {
        arcUndeployEffects =
        {
            {sound = "sound/NS2.fev/marine/structures/arc/undeploy"},
        },
    },
    
    sc_charge =
    {
        arcChargeEffects = 
        {
            {parented_cinematic = "cinematics/marine/arc/target.cinematic", attach_point = "fxnode_arcmuzzle"},
        },
    },
    
    sc_stop_charge =
    {
        arcStopChargeEffects = 
        {
            {stop_cinematic = "cinematics/marine/arc/target.cinematic"},
        },
    },
    
    sc_firing =
    {
        arcFireEffects =
        {
            // "trail" like a tracer
            //{sound = "sound/NS2.fev/marine/structures/arc/fire"},
            {sound = "sound/ns2c.fev/ns2c/marine/siegecannon/fire"},
            {parented_cinematic = "cinematics/marine/arc/fire.cinematic", attach_point = "fxnode_arcmuzzle"},
        },
    },
    
    // Center of ARC blast
    sc_hit_primary =
    {
        arcHitPrimaryEffects = 
        {
            {sound = "sound/NS2.fev/marine/structures/arc/hit"},
            {cinematic = "cinematics/marine/arc/explosion.cinematic"},
        },
    },
    
    // Played for secondary targets within blast radius
    sc_hit_secondary =
    {
        arcHitSecondaryEffects = 
        {
            {cinematic = "cinematics/marine/arc/hit_small.cinematic", classname = "Egg", done = true},
            {cinematic = "cinematics/marine/arc/hit_small.cinematic", classname = "Hydra", done = true},
            {cinematic = "cinematics/marine/arc/hit_big.cinematic", classname = "Hive", done = true},
            {cinematic = "cinematics/marine/arc/hit_med.cinematic"},      
        },
    },
    
    
    sc_stop_effects =
    {
        arcHitStopEffects = 
        {
            {stop_effects = ""},
        },
    },
    
    // ARC TODO:
    //ARC.kFlybySound = PrecacheAsset("sound/NS2.fev/marine/structures/arc/flyby")
    //ARC.kScanSound = PrecacheAsset("sound/NS2.fev/marine/structures/arc/scan")
    //ARC.kScanEffect = PrecacheAsset("cinematics/marine/arc/scan.cinematic")
    //ARC.kFireEffect = PrecacheAsset("cinematics/marine/arc/fire.cinematic")
    //ARC.kFireShellEffect = PrecacheAsset("cinematics/marine/arc/fire_shell.cinematic")
    //ARC.kDamagedEffect = PrecacheAsset("cinematics/marine/arc/damaged.cinematic")
    
    extractor_collect =
    {
        extractorCollectEffect =
        {
            {sound = "sound/NS2.fev/marine/structures/extractor_harvested"},
        },
    },
    
    armory_health = 
    {
        armoryHealth =
        {
            {sound = "sound/NS2.fev/marine/common/health"},
            {cinematic = "cinematics/marine/spawn_item.cinematic"},
        },
    },

    armory_ammo = 
    {
        armoryAmmo =
        {
            {sound = "sound/NS2.fev/marine/common/pickup_ammo"},
            {cinematic = "cinematics/marine/spawn_item.cinematic"},
        },
    },
    
    // Not hooked up
    armory_buy = 
    {
        armoryBuy =
        {
            {cinematic = "cinematics/marine/armory/buy_item_effect.cinematic"},
        },
    },
    
    armory_open = 
    {
        armoryOpen =
        {
            {sound = "sound/NS2.fev/marine/structures/armory_open"},
        },
    },
    
    armory_close = 
    {
        armoryClose =
        {
            {sound = "sound/NS2.fev/marine/structures/armory_close"},
        },
    },
    
    commandstation_login = 
    {
        commandStationLogin =
        {
            {sound = "sound/NS2.fev/marine/structures/command_station_close"}
        },
    },

    commandstation_logout = 
    {
        commandStationLogout =
        {
            {sound = "sound/NS2.fev/marine/structures/command_station_open"}
        },
    },
    
    infantry_portal_start_spin = 
    {
        ipStartSpinEffect =
        {
            {sound = "sound/NS2.fev/marine/structures/infantry_portal_start_spin"},
        },
    },    

    infantry_portal_stop_spin = 
    {
        ipStartSpinEffect =
        {
            {stop_cinematic = "cinematics/marine/infantryportal/spin.cinematic", done = true},
        },
    },    

    infantry_portal_spawn = 
    {
        ipSpawnEffect =
        {
            {cinematic = "cinematics/marine/infantryportal/player_spawn.cinematic"},
            {sound = "sound/NS2.fev/marine/structures/infantry_portal_player_spawn"},
        },
    },    

    // Played when a player enters a phase gate (at the source)
    phase_gate_player_enter = 
    {
        pgSpawnEffect =
        {
            //{player_sound = "sound/NS2.fev/marine/structures/phase_gate_teleport"},
            {player_cinematic = "cinematics/marine/infantryportal/player_spawn.cinematic"},            
        },
    }, 

    // Played when a player goes through a phase gate (at the destination)
    phase_gate_player_exit = 
    {
        pgSpawnEffect =
        {
            //{player_sound = "sound/NS2.fev/marine/structures/phase_gate_teleport"},
            {player_cinematic = "cinematics/marine/infantryportal/player_spawn.cinematic"},            
        },
    },
    
    // Looping cinematic played when going through phase gate will teleport you somewhere
    phase_gate_linked =
    {
        pgLinkedEffects = 
        {
            // Play spin for spinning infantry portal
            {looping_cinematic = "cinematics/marine/phasegate/phasegate.cinematic"},
        },
    },
    
    phase_gate_unlinked =
    {
        pgLinkedEffects = 
        {
            // Destroy it if not spinning
            {stop_cinematic = "cinematics/marine/phasegate/phasegate.cinematic", done = true},            
        },
    },
    
    distress_beacon_start = 
    {
        distressBeaconEffect =
        {
            {looping_cinematic = "cinematics/marine/observatory/glowing_light_effect.cinematic"},
        },
    },    
    
    distress_beacon_spawn = 
    {
        playerSpawnEffect =
        {
            {private_sound = "sound/NS2.fev/marine/common/mega_teleport_2D"},
            {cinematic = "cinematics/marine/infantryportal/player_spawn.cinematic"},
        },
    },
    
    distress_beacon_end = 
    {
        distressBeaconEffect =
        {
            {stop_cinematic = "cinematics/marine/observatory/glowing_light_effect.cinematic"},
        },
    },
    
    distress_beacon_complete =
    {
        // Play one mega-spawn sound instead of spawn sounds for each player
        distressBeaconComplete =
        {
            {sound = "sound/NS2.fev/marine/common/mega_teleport"},
        },
    },
    
    sentry_single_attack =
    {
        sentrySingleAttackEffects = 
        {
            {sound = "sound/NS2.fev/marine/structures/sentry_fire"}
        }    
    },
    
    sentry_attack =
    {
        sentryAttackEffects = 
        {
            {parented_cinematic = "cinematics/marine/sentry/fire.cinematic", attach_point = "fxnode_sentrymuzzle"},
        }    
    },
    
}

GetEffectManager():AddEffectData("MarineStructureEffects", kMarineStructureEffects)
