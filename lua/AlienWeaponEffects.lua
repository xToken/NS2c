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
    shockwave_trail =
    {
        {
            {cinematic = "cinematics/alien/onos/shockwave.cinematic"},
        }
    },
    
    shockwave_hit =
    {
        {
            {decal =  "cinematics/vfx_materials/decals/shockwave_hit.material", scale = 2.0},
            {cinematic = "cinematics/alien/onos/shockwave_hit.cinematic"},
        }
    },
    
    bite_kill =
    {
        biteKillSound =
        {
            {player_sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/NS2.fev/alien/skulk/bite_kill", attach_point = "Bip01_Head", done = true},
        }
    },
    
    bite_structure =
    {
        biteHitSound =
        {
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_structure", world_space = true, isalien = false, done = true},
        },
    },
    
    bite_attack =
    {
        biteAttackSounds =
        {
            {player_sound = "", silenceupgrade = true, done = true},
            
            {player_sound = "sound/NS2.fev/alien/skulk/bite_structure", attach_point = "Bip01_Head", surface = "structure", done = true},
            {player_sound = "sound/NS2.fev/alien/skulk/bite", attach_point = "Bip01_Head"},
        },
    },
    
    lerkbite_attack =
    {
        lerkBiteAttackSounds =
        {
            {player_sound = "", silenceupgrade = true, done = true},
            
            //{player_sound = "sound/ns2c.fev/ns2c/alien/lerk/bite", attach_point = "Bip01_Head", surface = "structure", done = true},
            {player_sound = "sound/ns2c.fev/ns2c/alien/lerk/bite2", attach_point = "Bip01_Head"},
            //{player_sound = "sound/NS2.fev/alien/lerk/bite", attach_point = "Bip01_Head"},
        },
    },
    
    // Leap
    leap =
    {
        biteAltAttackEffects = 
        {
            // TODO: Take volume or hasLeap
            {player_sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/NS2.fev/alien/skulk/bite_alt"},
            
        },
    },
    
    bilebomb_decal =
    {
        bileBombDecal =
        {
            {decal = "cinematics/vfx_materials/decals/bilebomb_decal.material", scale = 3.5, done = true}
        }    
    },

    parasite_attack =
    {
        parasiteAttackEffects = 
        {
            {player_cinematic = "cinematics/alien/skulk/parasite_fire.cinematic"},
            {viewmodel_cinematic = "cinematics/alien/skulk/parasite_view.cinematic", attach_point = "CamBone"},
            
            {player_sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/NS2.fev/alien/skulk/parasite"},
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
            {player_sound = "", silenceupgrade = true, done = true}, 
            {player_sound = "sound/NS2.fev/alien/gorge/spit"},
        },
    },
    
    babblerability_attack =
    {
        babblerabilityAttackEffects = 
        {   
            {player_sound = "", silenceupgrade = true, done = true}, 
            {player_sound = "sound/NS2.fev/alien/gorge/babbler_ball_spit", world_space = true},
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
            {player_sound = "", silenceupgrade = true, done = true}, 
            {player_sound = "sound/NS2.fev/alien/gorge/heal_spray"}
        },
    },
    
    acidrocket_attack =
    {
        acidrocketFireEffects = 
        {   
            {player_sound = "", silenceupgrade = true, done = true}, 
            {player_sound = "sound/ns2c.fev/ns2c/alien/fade/acidrocket_fire"},
            //{player_sound = "sound/NS2.fev/alien/gorge/spit"},
            //{cinematic = "cinematics/alien/gorge/spit_fire.cinematic"},
        },
    },

    bilebomb_attack =
    {
        bilebombFireEffects = 
        {   
            {player_sound = "", silenceupgrade = true, done = true}, 
            {player_sound = "sound/NS2.fev/alien/gorge/bilebomb"},
        },
    },

    bilebomb_hit =
    {
        bilebombHitEffects = 
        {
            
            // TODO: Change to something else
            {cinematic = "cinematics/alien/gorge/bilebomb_impact.cinematic"},
            {parented_sound = "sound/NS2.fev/alien/gorge/bilebomb_hit", done = true},
        },
    },
    
    acidrocket_hit =
    {
        acidrocketHitEffects = 
        {
            
            // TODO: Change to something else
            {cinematic = "cinematics/alien/gorge/bilebomb_impact.cinematic"},
            {parented_sound = "sound/ns2c.fev/ns2c/alien/fade/acidrocket_hit", done = true},
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
    
    web_fire =
    {
        web_fire =
        {
            {sound = "sound/ns2c.fev/ns2c/alien/gorge/webspin"},
        },
    },
    
    web_harden =
    {
        web_fire =
        {
            {sound = "sound/ns2c.fev/ns2c/alien/gorge/web_form"},
        },
    },
    
    web_clear =
    {
        web_fire =
        {
            {sound = "sound/ns2c.fev/ns2c/alien/gorge/web_clear"},
        },
    },
	
	ghost_dodge = 
	{
        dodge =
        {
            {sound = "sound/ns2c.fev/ns2c/alien/gorge/web_clear"},
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
            {player_sound = "", silenceupgrade = true, done = true}, 
            {player_sound = "sound/ns2c.fev/ns2c/alien/lerk/spore_fire"},
        },
    },    

    umbra_attack =
    {
        umbraAttackEffects = 
        {
            {player_sound = "", silenceupgrade = true, done = true}, 
            {viewmodel_cinematic = "cinematics/alien/lerk/umbra_view_fire.cinematic", attach_point = "fxnode_hole_left"},
            {viewmodel_cinematic = "cinematics/alien/lerk/umbra_view_fire.cinematic", attach_point = "fxnode_hole_right"},
            {player_sound = "sound/ns2c.fev/ns2c/alien/lerk/umbra_fire"},
            //{player_sound = "sound/NS2.fev/alien/structures/crag/umbra"},
        },
    },
    
    swipe_attack = 
    {
        swipeAttackSounds =
        {
            {player_sound = "", silenceupgrade = true, done = true}, 
            {player_sound = "sound/NS2.fev/alien/fade/swipe_structure", surface = "structure", done = true},
            {player_sound = "sound/NS2.fev/alien/fade/swipe"},
        },
    },

    metabolize = 
    {
        metabolizeEffects =
        {
            {player_sound = "", silenceupgrade = true, done = true}, 
            {player_sound = "sound/ns2c.fev/ns2c/alien/fade/metabolize"},
            //{player_sound = "sound/NS2.fev/alien/fade/stab"},
        },
    },
    
    blink_in =
    {
        blinkInEffects =
        {        
            {player_sound = "sound/NS2.fev/alien/fade/blink_end"},
            {player_cinematic = "cinematics/alien/fade/blink_in_silent.cinematic", done = true},     
        },
    },  

    blink_out =
    {
        blinkOutEffects =
        {   
            {player_sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/ns2c.fev/ns2c/alien/fade/blink"},
        },
    },
    
    // Sound Effects only
    gore_attack =
    {
        goreAttackEffects =
        {
            {player_sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/NS2.fev/alien/onos/gore"},
        },
    },

    smash_attack =
    {
        smashAttackEffects =
        {
            {player_sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/NS2.fev/alien/onos/gore"},
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
            {player_sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/NS2.fev/alien/onos/stomp"},
        },
    },  

    stomp_hit =
    {
        stompAttackEffects =
        {
            {cinematic = "cinematics/alien/onos/stomp_hit.cinematic"},
            {player_sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/NS2.fev/alien/onos/stomp"},
        },
    },
        
    onos_charge_crash =
    {
        onosChargeCrashEffects =
        {
            {cinematic = "cinematics/alien/onos/stomp_hit.cinematic"},
        },    
    
    },
    
    devour_fire =
    {
        DevourAttack =
        {
            {player_sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/ns2c.fev/ns2c/alien/onos/devour_fire"},
        },
    },
    
    devour_hit =
    {
        DevourHit =
        {
            {player_sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/ns2c.fev/ns2c/alien/onos/devour_hit"},
        },
    },
    
    devour_complete =
    {
        DevourCompleteEffects =
        {
            {player_sound = "sound/ns2c.fev/ns2c/alien/onos/devour_complete"},
        },
    },
    
    primal_scream =
    {
        primalScreamEffects =
        {
            {cinematic = "cinematics/alien/onos/stomp_hit.cinematic"},
            {player_sound = "", silenceupgrade = true, done = true},
            {player_sound = "sound/ns2c.fev/ns2c/alien/lerk/primal_scream"},
        },    
    
    },
    
    primal =
    {
        primalReceieveEffects =
        {
            //{cinematic = "cinematics/alien/onos/stomp_hit.cinematic"},
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

