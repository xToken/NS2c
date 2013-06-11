// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GeneralEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kGeneralEffectData = 
{

    upgrade_complete =
    {
        upgradeSoundEffects =
        {
            {sound = "sound/NS2.fev/alien/voiceovers/trait_available", classname = "Alien", done = true},
            {sound = "sound/NS2.fev/marine/common/upgrade"},
        },
    },
    
    spawn_weapon =
    {
        spawnWeaponEffects =
        {
            {cinematic = "cinematics/marine/spawn_item.cinematic", done = true},    
        }
    },
    
    spawn =
    {
        spawnEffects =
        {
            // marine
            {cinematic = "", classname = "WeaponAmmoPack", done = true},            
            {cinematic = "cinematics/marine/spawn_item.cinematic", classname = "AmmoPack", done = true},
            {cinematic = "cinematics/marine/spawn_item.cinematic", classname = "MedPack", done = true},
            {cinematic = "cinematics/marine/spawn_item.cinematic", classname = "Mine", done = true},
            
            {cinematic = "cinematics/marine/structures/spawn_building_big.cinematic", classname = "CommandStation", done = true},
            {cinematic = "cinematics/marine/structures/spawn_building_big.cinematic", classname = "RoboticsFactory", done = true},
            {cinematic = "cinematics/marine/structures/spawn_building_big.cinematic", classname = "Extractor", done = true},
            {cinematic = "cinematics/marine/structures/spawn_building.cinematic", classname = "Armory", done = true},
            {cinematic = "cinematics/marine/structures/spawn_building.cinematic", classname = "ArmsLab", done = true},
            {cinematic = "cinematics/marine/structures/spawn_building.cinematic", classname = "InfantryPortal", done = true},
            {cinematic = "cinematics/marine/structures/spawn_building.cinematic", classname = "PrototypeLab", done = true},
            {cinematic = "cinematics/marine/structures/spawn_building.cinematic", classname = "Sentry", done = true},
            {cinematic = "cinematics/marine/structures/spawn_building.cinematic", classname = "PhaseGate", done = true},
            {cinematic = "cinematics/marine/structures/spawn_building.cinematic", classname = "Observatory", done = true},
            
            {cinematic = "cinematics/alien/structures/spawn.cinematic", classname = "Egg", done = true},
            {cinematic = "cinematics/alien/structures/spawn_small.cinematic", classname = "Embryo", done = true},
            
            {cinematic = "cinematics/alien/structures/spawn_large.cinematic", classname = "Hive", done = true},
            {cinematic = "cinematics/alien/structures/spawn_large.cinematic", classname = "Harvester", done = true},
            
            {cinematic = "cinematics/alien/structures/spawn.cinematic", classname = "Crag", done = true},
            {cinematic = "cinematics/alien/structures/spawn.cinematic", classname = "Shade", done = true},
            {cinematic = "cinematics/alien/structures/spawn.cinematic", classname = "Shift", done = true},
            {cinematic = "cinematics/alien/structures/spawn.cinematic", classname = "Whip", done = true},
            
            {cinematic = "cinematics/alien/structures/spawn.cinematic", classname = "Veil", done = true},
            {cinematic = "cinematics/alien/structures/spawn.cinematic", classname = "Shell", done = true},
            {cinematic = "cinematics/alien/structures/spawn.cinematic", classname = "Spur", done = true},
            
            {cinematic = "cinematics/alien/structures/spawn_small.cinematic", classname = "Cyst", done = true},
        
        },
        
        spawnSoundEffects =
        {
            // marine
            {sound = "", classname = "WeaponAmmoPack", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "AmmoPack", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "MedPack", done = true},
            
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "CommandStation", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "RoboticsFactory", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "Extractor", done = true},
            {sound = "sound/NS2.fev/marine/structures/mac/passby_mac", classname = "MAC", done = true},
            {sound = "sound/NS2.fev/marine/structures/arc/deploy", classname = "ARC", done = true},
            
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "Armory", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "ArmsLab", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "InfantryPortal", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "PrototypeLab", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "Sentry", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "PhaseGate", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "Observatory", done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_spawn", classname = "PowerPack", done = true},
        
            // alien
            {sound = "sound/NS2.fev/alien/structures/shade/cloak_triggered", classname = "Hallucination", done = true}, // TODO: replace
            
            {sound = "sound/NS2.fev/alien/structures/egg/spawn", classname = "Egg", done = true},
            {sound = "sound/NS2.fev/alien/structures/egg/spawn", classname = "Embryo", done = true},
            
            {sound = "sound/NS2.fev/alien/skulk/spawn", classname = "Skulk", done = true},
            {sound = "sound/NS2.fev/alien/gorge/spawn", classname = "Gorge", done = true},
            {sound = "sound/NS2.fev/alien/lerk/spawn", classname = "Lerk", done = true},
            {sound = "sound/ns2c.fev/ns2c/alien/fade/spawn", classname = "Fade", done = true},
            {sound = "sound/NS2.fev/alien/onos/spawn", classname = "Onos", done = true},
            
            {sound = "sound/NS2.fev/alien/drifter/spawn", classname = "Drifter", done = true},
            {sound = "sound/NS2.fev/alien/structures/hive_spawn", classname = "Hive", done = true},
            {sound = "sound/NS2.fev/alien/structures/generic_spawn_large", classname = "Harvester", done = true},
            
            {sound = "sound/NS2.fev/alien/structures/generic_spawn_large", classname = "Crag", done = true},
            {sound = "sound/NS2.fev/alien/structures/generic_spawn_large", classname = "Shade", done = true},
            {sound = "sound/NS2.fev/alien/structures/generic_spawn_large", classname = "Shift", done = true},
            {sound = "sound/NS2.fev/alien/structures/generic_spawn_large", classname = "Whip", done = true},
            
            {sound = "sound/NS2.fev/alien/structures/spawn_small", classname = "Veil", done = true},
            {sound = "sound/NS2.fev/alien/structures/spawn_small", classname = "Shell", done = true},
            {sound = "sound/NS2.fev/alien/structures/spawn_small", classname = "Spur", done = true},
            
            {sound = "sound/NS2.fev/alien/structures/spawn_small", classname = "Cyst", done = true},
            
            // common
            {sound = "sound/NS2.fev/common/connect", classname = "ReadyRoomPlayer", done = true},
        }
        
    },

    drifter_shoot_enzyme =
    {
        drifterShootEnzymeEffects =
        {
            //{cinematic = "cinematics/alien/drifter/enzyme_muzzle.cinematic"},
            {sound = "sound/NS2.fev/alien/drifter/parasite", done = true}            
        }
    },
    


    issue_order =
    {
        issueOrderEffects =
        {
            {cinematic = "cinematics/marine/order.cinematic", classname = "MarineCommander", done = true},
            {cinematic = "cinematics/alien/order.cinematic", classname = "AlienCommander", done = true},
        },
        
        issueOrderSounds =
        {
            {private_sound = "sound/NS2.fev/marine/commander/give_order", classname = "MarineCommander", done = true},
            // TODO: use custom sound
            {private_sound = "sound/NS2.fev/alien/common/chat", classname = "AlienCommander", done = true},
        }
    
    },

    join_team =
    {
        joinTeamEffects =
        {
            {sound = "sound/NS2.fev/alien/common/join_team", isalien = true, done = true},
            {sound = "sound/NS2.fev/marine/common/join_team", isalien = false, done = true},
        },
    },
    
    victory =
    {
        victoryEffects =
        {
            {sound = "sound/ns2c.fev/ns2c/ui/you_win", done = true},
        },
    },
    
    loss =
    {
        lossEffects =
        {
            {sound = "sound/ns2c.fev/ns2c/ui/you_lose", done = true},
        },
    },
    
    ayumi =
    {
        ayumiEffects =
        {
            {private_sound = "sound/ns2c.fev/ns2c/ui/nancy_rr", done = true},
        },
    },
    
    end_ayumi =
    {
        ayumiEffects =
        {
            {stop_sound = "sound/ns2c.fev/ns2c/ui/nancy_rr", done = true},
        },
    },
    
    catalyst =
    {
        catalystEffects =
        {
            // TODO: adjust sound effects (those are triggered multiple times during catalyst effect)
            {sound = "sound/NS2.fev/alien/common/frenzy", isalien = true},
            {sound = "sound/NS2.fev/marine/common/catalyst", isalien = false},
            
            {parented_cinematic = "cinematics/alien/nutrientmist_hive.cinematic", classname = "Hive", done = true},
            {parented_cinematic = "cinematics/alien/nutrientmist_onos.cinematic", classname = "Onos", done = true},
            {parented_cinematic = "cinematics/alien/nutrientmist_player.cinematic", classname = "Embryo", done = true},
            {parented_cinematic = "cinematics/alien/nutrientmist_structure.cinematic", classname = "Structure", isalien = true, done = true},
            
            // Cinematic doesn't exist.
            //{cinematic = "cinematics/marine/catalyst.cinematic", isalien = false},
        },
    },
    
    // Structure deploy animations handled in code ("deploy")
    deploy =
    {
        deploySoundEffects =
        {
            {sound = "sound/NS2.fev/alien/structures/hive_deploy", classname = "Hive", done = true},
            {sound = "sound/NS2.fev/marine/structures/extractor_deploy", classname = "Extractor", done = true},
            {sound = "sound/NS2.fev/marine/structures/infantry_portal_deploy", classname = "InfantryPortal", done = true},
            {sound = "sound/NS2.fev/marine/structures/armory_deploy", classname = "Armory", done = true},
            {sound = "sound/NS2.fev/marine/structures/armslab_deploy", classname = "ArmsLab", done = true},
            {sound = "sound/NS2.fev/marine/structures/commandstation_deploy", classname = "CommandStation", done = true},
            {sound = "sound/NS2.fev/marine/structures/observatory_deploy", classname = "Observatory", done = true},
            {sound = "sound/NS2.fev/marine/structures/extractor_deploy", classname = "Extractor", done = true},
            {sound = "sound/NS2.fev/marine/structures/phasegate_deploy", classname = "PhaseGate", done = true},
            {sound = "sound/NS2.fev/marine/structures/roboticsfactory_deploy", classname = "RoboticsFactory", done = true},
            {sound = "sound/NS2.fev/marine/structures/sentry_deploy", classname = "Sentry", done = true},                   
            {sound = "sound/NS2.fev/alien/structures/deploy_small", classname = "Hydra", done = true},
            {sound = "sound/NS2.fev/alien/structures/deploy_large", isalien = true, done = true},
            {sound = "sound/NS2.fev/marine/structures/generic_deploy", isalien = false, done = true},           
        },

    },

    idle =
    {
        idleSounds =
        {
            {parented_sound = "sound/NS2.fev/marine/structures/armory_idle", classname = "Armory", done = true},
            {parented_sound = "sound/NS2.fev/marine/structures/command_station_active", classname = "CommandStation", done = true},
            {parented_sound = "sound/NS2.fev/marine/structures/extractor_active", classname = "Extractor", done = true},
            {parented_sound = "sound/NS2.fev/marine/structures/infantry_portal_active", classname = "InfantryPortal", done = true},
            {parented_sound = "sound/NS2.fev/marine/structures/phase_gate_active", classname = "PhaseGate", done = true},
            {parented_sound = "sound/NS2.fev/marine/structures/arc/idle", classname = "ARC", done = true},
            
            {parented_sound = "sound/NS2.fev/alien/structures/hive_idle", classname = "Hive", done = true},
            {parented_sound = "sound/NS2.fev/alien/structures/hydra/idle", classname = "Hydra", done = true},
            {parented_sound = "sound/NS2.fev/alien/structures/crag/idle", classname = "Crag", done = true},
            {parented_sound = "sound/NS2.fev/alien/structures/shade/idle", classname = "Shade", done = true},
            {parented_sound = "sound/NS2.fev/alien/structures/shift/idle", classname = "Shift", done = true},
            {parented_sound = "sound/NS2.fev/alien/structures/whip/idle", classname = "Whip", done = true},
            {parented_sound = "sound/NS2.fev/alien/structures/harvester_active", classname = "Harvester", done = true},
            
            {parented_sound = "sound/NS2.fev/alien/skulk/idle", classname = "Skulk", done = true},
            {parented_sound = "sound/NS2.fev/alien/gorge/idle", classname = "Gorge", done = true},
            {parented_sound = "sound/NS2.fev/alien/lerk/idle", classname = "Lerk", done = true},
            // No Fade idle sound in FMOD yet.
            //{parented_sound = "sound/NS2.fev/alien/fade/idle", classname = "Fade", done = true},
            {parented_sound = "sound/NS2.fev/alien/onos/idle", classname = "Onos", done = true},
            
        },
    },
    
    idle_stop =
    {
        idleStopSounds =
        {
            
            {stop_sound = "sound/NS2.fev/marine/structures/armory_idle", classname = "Armory", done = true},
            {stop_sound = "sound/NS2.fev/marine/structures/command_station_active", classname = "CommandStation", done = true},
            {stop_sound = "sound/NS2.fev/marine/structures/extractor_active", classname = "Extractor", done = true},
            {stop_sound = "sound/NS2.fev/marine/structures/infantry_portal_active", classname = "InfantryPortal", done = true},
            {stop_sound = "sound/NS2.fev/marine/structures/phase_gate_active", classname = "PhaseGate", done = true},
            {stop_sound = "sound/NS2.fev/marine/structures/arc/idle", classname = "ARC", done = true},
            
            {stop_sound = "sound/NS2.fev/alien/structures/hive_idle", classname = "Hive", done = true},
            {stop_sound = "sound/NS2.fev/alien/structures/hydra/idle", classname = "Hydra", done = true},
            {stop_sound = "sound/NS2.fev/alien/structures/crag/idle", classname = "Crag", done = true},
            {stop_sound = "sound/NS2.fev/alien/structures/shade/idle", classname = "Shade", done = true},
            {stop_sound = "sound/NS2.fev/alien/structures/shift/idle", classname = "Shift", done = true},
            {stop_sound = "sound/NS2.fev/alien/structures/whip/idle", classname = "Whip", done = true},
            {stop_sound = "sound/NS2.fev/alien/structures/harvester_active", classname = "Harvester", done = true},
            
            {stop_sound = "sound/NS2.fev/alien/skulk/idle", classname = "Skulk", done = true},
            {stop_sound = "sound/NS2.fev/alien/gorge/idle", classname = "Gorge", done = true},
            {stop_sound = "sound/NS2.fev/alien/lerk/idle", classname = "Lerk", done = true},
            //{stop_sound = "sound/NS2.fev/alien/fade/idle", classname = "Fade", done = true},
            {stop_sound = "sound/NS2.fev/alien/onos/idle", classname = "Onos", done = true},
            
        }        
    },    
    
    construct =
    {
        constructEffects =
        {
            //{cinematic = "cinematics/alien/structures/build.cinematic", isalien = true},
            
            // Gorge
            {sound = "sound/NS2.fev/alien/gorge/build", classname = "Gorge", done = true},
            
        },
    },
    
    // Called whenever the object is destroyed (this will happen after death, but also when an entity is deleted
    // due to a round reset. Called only on the server.
    on_destroy =
    {
        destroySoundEffects = 
        {
            // Delete all parented or looping sounds and effects associated with this object
            {stop_effects = "", classname = "Actor"},
        },
    },
    
    death =
    {
        // Structure effects in other lua files
        // If death animation isn't played, and ragdoll isn't triggered, entity will be destroyed and removed immediately.
        // Otherwise, effects are responsible for setting ragdoll/death time.
        generalDeathCinematicEffects =
        {
            // TODO: Substitute material properties?
            {cinematic = "cinematics/materials/%s/grenade_explosion.cinematic", classname = "Grenade", done = true},
            {cinematic = "cinematics/marine/arc/destroyed.cinematic", classname = "ARC", done = true},
        },
      
        // Play world sound instead of parented sound as entity is going away?
        deathSoundEffects = 
        {            
            {sound = "sound/NS2.fev/alien/skulk/bite_kill", doer = "BiteLeap"},
                        
            {stop_sound = "sound/NS2.fev/marine/structures/arc/fire", classname = "ARC"},

            {sound = "sound/NS2.fev/alien/skulk/death", classname = "Skulk", done = true},
            {sound = "sound/NS2.fev/alien/gorge/death", classname = "Gorge", done = true},
            {sound = "sound/NS2.fev/alien/lerk/death", classname = "Lerk", done = true},            
            {stop_sound = "sound/NS2.fev/alien/fade/blink_loop", classname = "Fade"},
            {sound = "sound/NS2.fev/alien/fade/death", classname = "Fade", done = true},
            {sound = "sound/NS2.fev/alien/onos/death", classname = "Onos", done = true},
            {sound = "sound/NS2.fev/marine/common/death", classname = "Marine", done = true},
            {sound = "sound/NS2.fev/marine/structures/extractor_death", classname = "Extractor", done = true},
            {sound = "sound/NS2.fev/marine/structures/arc/death", classname = "ARC", done = true},
            
        },
        
    },
    
    // Play private sound for commander for good feedback
    commander_create_local =
    {
        commanderCreateLocalEffects =
        {
            {private_sound = "sound/NS2.fev/alien/commander/spawn_2", isalien = true, done = true},
            {private_sound = "sound/NS2.fev/marine/commander/spawn_2d", ismarine = true, done = true},
        },
    },
    
    res_received =
    {
        resReceivedEffects =
        {
            {private_sound = "sound/NS2.fev/alien/common/res_received", classname = "Alien", done = true},
            {private_sound = "sound/NS2.fev/alien/commander/res_received", classname = "Commander", isalien = true, done = true},
            {private_sound = "sound/NS2.fev/marine/commander/res_received", classname = "Commander", isalien = false,  done = true},            
            // Marine
            {private_sound = "sound/NS2.fev/marine/common/res_received", done = true},

        },
    },
    
    alien_move =
    {
        alienMoveEffects =
        {
            {sound = "", silenceupgrade = true, done = true},
            //{sound = "sound/NS2.fev/alien/skulk/death", classname = "Skulk", done = true},
            //{sound = "sound/NS2.fev/alien/gorge/death", classname = "Gorge", done = true},
            //{sound = "sound/NS2.fev/alien/lerk/death", classname = "Lerk", done = true},            
            {sound = "sound/ns2c.fev/ns2c/alien/fade/move1", classname = "Fade", randsound = 1, done = true},
            {sound = "sound/ns2c.fev/ns2c/alien/fade/move2", classname = "Fade", randsound = 2, done = true},
            //{sound = "sound/NS2.fev/alien/onos/death", classname = "Onos", done = true},
            {sound = "", done = true},
        },
    },
    
    complete_order =
    {
        completeOrderSound =
        {
            {sound = "sound/NS2.fev/marine/voiceovers/complete"},
        }
    },
            
}

GetEffectManager():AddEffectData("GeneralEffectData", kGeneralEffectData)
