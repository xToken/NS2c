// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienWeaponEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Debug with: {player_cinematic = "cinematics/locateorigin.cinematic"},

kAlienWeaponEffects =
{
        
    spit_hit =
    {
        spitHitEffects =
        {
            {sound = "sound/NS2.fev/alien/gorge/spit_hit"},
            {cinematic = "cinematics/alien/gorge/spit_impact.cinematic"},
        }
    
    },
    
    bite_kill =
    {
        biteKillSound =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_kill", attach_point = "Bip01_Head", done = true},
        }
    },
    
    bite_structure =
    {
        biteHitSound =
        {
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_structure", world_space = true, done = true},
        },
    },
    
    bite_attack =
    {
        biteAttackSounds =
        {
            {sound = "", silenceupgrade = true, done = true},
            
            {sound = "sound/NS2.fev/alien/skulk/bite_structure", attach_point = "Bip01_Head", surface = "structure", done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite", attach_point = "Bip01_Head"},
        },
    },
    
    lerkbite_attack =
    {
        lerkBiteAttackSounds =
        {
            {sound = "", silenceupgrade = true, done = true},
            
            {sound = "sound/ns2c.fev/ns2c/alien/skulk/bite2", attach_point = "Bip01_Head", surface = "structure", done = true},
            {sound = "sound/ns2c.fev/ns2c/alien/skulk/bite2", attach_point = "Bip01_Head"},
        },
    },
    
    // Leap
    leap =
    {
        biteAltAttackEffects = 
        {
            // TODO: Take volume or hasLeap
            {sound = "", silenceupgrade = true, done = true},
            
            {sound = "sound/NS2.fev/alien/skulk/bite_alt"},
            
        },
    },

    parasite_attack =
    {
        parasiteAttackEffects = 
        {
            {player_cinematic = "cinematics/alien/skulk/parasite_fire.cinematic"},
            {viewmodel_cinematic = "cinematics/alien/skulk/parasite_view.cinematic", attach_point = "CamBone"},
            
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/parasite"},
         },
    },
    
    xenocide = 
    {
        xenocideEffects =
        {
            {sound = "sound/NS2.fev/alien/common/xenocide_end", world_space = true},
            {cinematic = "cinematics/alien/skulk/xenocide.cinematic"}
        }    
    },
    
    spitspray_attack =
    {
        spitFireEffects = 
        {   
            {sound = "", silenceupgrade = true, done = true}, 
            {sound = "sound/NS2.fev/alien/gorge/spit"},
        },
    },
    
    healspray_collide =
    {
        healSpayCollideEffects =
        {   
            {cinematic = "cinematics/alien/heal.cinematic"},
        },
    },

    heal_spray = 
    {
        sprayFireEffects = 
        {
            // Use player_cinematic because at world position, not attach_point
            {player_cinematic = "cinematics/alien/gorge/healthspray.cinematic"},
            {viewmodel_cinematic = "cinematics/alien/gorge/healthspray_view.cinematic", attach_point = "gorge_view_root"},
            {sound = "", silenceupgrade = true, done = true}, 
            {sound = "sound/NS2.fev/alien/gorge/heal_spray"}
        },
    },
    
    bilebomb_attack =
    {
        bilebombFireEffects = 
        {   
            {sound = "", silenceupgrade = true, done = true}, 
            {sound = "sound/NS2.fev/alien/gorge/bilebomb"},
        },
    },
    
    acidrocket_attack =
    {
        acidrocketFireEffects = 
        {   
            {sound = "", silenceupgrade = true, done = true}, 
            {sound = "sound/ns2c.fev/ns2c/alien/fade/acidrocket_fire"},
            //{sound = "sound/NS2.fev/alien/gorge/spit"},
            //{cinematic = "cinematics/alien/gorge/spit_fire.cinematic"},
        },
    },

    bilebomb_hit =
    {
        bilebombHitEffects = 
        {
            
            // TODO: Change to something else
            {cinematic = "cinematics/alien/gorge/bilebomb_impact.cinematic"},
            
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/gorge/bilebomb_hit", done = true},
        },
    },
    
    acidrocket_hit =
    {
        acidrocketHitEffects = 
        {
            
            // TODO: Change to something else
            {cinematic = "cinematics/alien/gorge/bilebomb_impact.cinematic"},
            
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/ns2c.fev/ns2c/alien/fade/acidrocket_hit", done = true},
        },
    },
    
    // When creating a structure
    gorge_create =
    {
        gorgeCreateEffects =
        {
            {sound = "", silenceupgrade = true, done = true}, 
            {sound = "sound/NS2.fev/alien/structures/spawn_small"},
        },
    },

    spit_structure =
    {
        spitStructureEffects = 
        {
            {cinematic = "cinematics/alien/gorge/spit_structure.cinematic"},
            {sound = "", silenceupgrade = true, done = true}, 
            {sound = "sound/NS2.fev/alien/gorge/create_structure_start", world_space = true},
        }
    },

    spikes_attack =
    {   
        spikeAttackSounds =
        {
            {sound = "sound/NS2.fev/alien/lerk/spikes", done = true},
        },
    },
    
    spores_attack =
    {
        sporesAttackEffects = 
        {
            {sound = "", silenceupgrade = true, done = true}, 
            //{viewmodel_cinematic = "cinematics/alien/lerk/spore_view_fire.cinematic", attach_point = "fxnode_hole_left"},
            //{viewmodel_cinematic = "cinematics/alien/lerk/spore_view_fire.cinematic", attach_point = "fxnode_hole_right"},
            {sound = "sound/ns2c.fev/ns2c/alien/lerk/spore_fire"},
        },
    },    

    umbra_attack =
    {
        umbraAttackEffects = 
        {
            {sound = "", silenceupgrade = true, done = true}, 
            {viewmodel_cinematic = "cinematics/alien/lerk/umbra_view_fire.cinematic", attach_point = "fxnode_hole_left"},
            {viewmodel_cinematic = "cinematics/alien/lerk/umbra_view_fire.cinematic", attach_point = "fxnode_hole_right"},
            {sound = "sound/ns2c.fev/ns2c/alien/lerk/umbra_fire"},
        },
    },
    
    swipe_attack = 
    {
        swipeAttackSounds =
        {
            {sound = "", silenceupgrade = true, done = true}, 
            {sound = "sound/NS2.fev/alien/fade/swipe_structure", surface = "structure", done = true},
            {sound = "sound/NS2.fev/alien/fade/swipe"},
        },
    },

    metabolize = 
    {
        metabolizeEffects =
        {
            {sound = "", silenceupgrade = true, done = true}, 
            {sound = "sound/ns2c.fev/ns2c/alien/fade/metabolize"},
        },
    },

    blink_in =
    {
        blinkInEffects =
        {        
            {player_cinematic = "cinematics/alien/fade/blink_in_silent.cinematic", done = true},    
        },
    },

    blink_out =
    {
        blinkOutEffects =
        {   
            {sound = "", silenceupgrade = true, done = true},  
            {sound = "sound/ns2c.fev/ns2c/alien/fade/blink"},  
            {player_cinematic = "cinematics/alien/fade/blink_out_silent.cinematic", done = true},
        },
    },
    
    // Sound Effects only
    gore_attack =
    {
        goreAttackEffects =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/onos/gore"},
        },
    },

    smash_attack =
    {
        smashAttackEffects =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/onos/gore"},
        },
    },    
 
    smash_attack_hit =
    {
        smashAttackHitEffects =
        {
            {cinematic = "cinematics/alien/onos/door_hit.cinematic"}
        },
    },

    stomp_attack =
    {
        stompAttackEffects =
        {
            {cinematic = "cinematics/alien/onos/stomp.cinematic"},
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/onos/stomp"},
        },
    },  

    stomp_hit =
    {
        stompAttackEffects =
        {
            {cinematic = "cinematics/alien/onos/stomp_hit.cinematic"},
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/onos/stomp"},
        },
    },
    
    primal_scream =
    {
        primalScreamEffects =
        {
            {cinematic = "cinematics/alien/onos/stomp_hit.cinematic"},
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/ns2c.fev/ns2c/alien/lerk/primal_scream"},
        },    
    
    }, 
    
    // Alien vision mode effects
    alien_vision_on = 
    {
        visionModeOnEffects = 
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/common/vision_on"},
        },
    },
    
    alien_vision_off = 
    {
        visionModeOnEffects = 
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/common/vision_off"},
        },
    },

}

// "false" means play all effects in each block
GetEffectManager():AddEffectData("AlienWeaponEffects", kAlienWeaponEffects)

