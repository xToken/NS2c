// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienStructureEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
kAlienStructureEffects = 
{
    web_create =
    {
        effects = 
        {
            {cinematic = "cinematics/alien/webs/fallingslime.cinematic"},
        }
    },
    
    web_destroy =
    {
        effects = 
        {
            {cinematic = "cinematics/alien/webs/kill.cinematic"},
        }
    },

	babbler_hatch =
    {
        babblerEggLandEffects =
        {
            {cinematic = "cinematics/alien/babbler/spawn.cinematic" },
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/drifter/attack", world_space = true, done = true},
        },
    },

    construct =
    {
        alienConstruct =
        {
            {sound = "sound/NS2.fev/alien/gorge/build", doer = "Gorge", done = true},
            {sound = "sound/NS2.fev/alien/structures/generic_build", isalien = true, done = true},
        },
    },
    
    hatch =
    {
        recallEffects =
        {
            {sound = "sound/NS2.fev/alien/structures/shift/recall"},
            {cinematic = "cinematics/alien/shift/hatch.cinematic", done = true},
        }    
    },
    
    death =
    {
        alienStructureDeathParticleEffect =
        {        
            // Plays the first effect that evalutes to true
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Web", done = true},
            {cinematic = "cinematics/alien/hive/explode_residue.cinematic", classname = "Hive"},
            {cinematic = "cinematics/alien/hive/explode.cinematic", classname = "Hive", done = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Whip", done = true},
                        
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Crag", done = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Shade", done = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "Shift", done = true},
            
            {cinematic = "cinematics/alien/structures/death_harvester.cinematic", classname = "Harvester", done = true},
            {cinematic = "cinematics/alien/babbler/death.cinematic", classname = "Babbler", done = true},
            {cinematic = "cinematics/alien/structures/death_small.cinematic", classname = "BabblerEgg", done = true},
        },
        
        alienStructureDeathSounds =
        {
            
            {sound = "sound/NS2.fev/alien/structures/harvester_death", classname = "Harvester"},
            {sound = "sound/NS2.fev/alien/structures/hive_death", classname = "Hive"},
            {sound = "sound/NS2.fev/alien/structures/death_grenade", doer = "Grenade", isalien = true, done = true},
            {sound = "sound/NS2.fev/alien/structures/death_axe", doer = "Axe", isalien = true, done = true},            
            {sound = "sound/NS2.fev/alien/structures/death_grenade", classname = "Structure", doer = "Grenade", isalien = true, done = true},
            {sound = "sound/NS2.fev/alien/structures/death_axe", classname = "Structure", doer = "Axe", isalien = true, done = true},            
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Structure", isalien = true, done = true},
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Web", done = true},
            
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Crag", done = true},
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Shade", done = true},
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Shift", done = true},
            
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "Babbler", done = true},
            {sound = "sound/NS2.fev/alien/structures/death_small", classname = "BabblerEgg", done = true},
        },       
    },
    
    harvester_collect =
    {
        harvesterCollectEffect =
        {
            {sound = "sound/NS2.fev/alien/structures/harvester_harvested"},
        },
    },
    
    egg_death =
    {
        eggEggDeathEffects =
        {
            {sound = "sound/NS2.fev/alien/structures/egg/death"},
            {cinematic = "cinematics/alien/egg/burst.cinematic"},
        },
    },

    hydra_attack =
    {
        hydraAttackEffects =
        {
            {sound = "sound/NS2.fev/alien/structures/hydra/attack"},
            //{cinematic = "cinematics/alien/hydra/spike_fire.cinematic"},
        },
    },
    
    player_start_gestate =
    {
        playerStartGestateEffects = 
        {
            {private_sound = "sound/NS2.fev/alien/common/gestate"},
        },
    },
    
    player_end_gestate =
    {
        playerStartGestateEffects = 
        {
            {stop_sound = "sound/NS2.fev/alien/common/gestate"},
        },
    },
    
    // Triggers when crag tries to heal entities
    crag_heal =
    {        
        cragTriggerHealEffects = 
        {
            {cinematic = "cinematics/alien/crag/heal.cinematic"}
        },
    },
    
    whip_attack =
    {
        whipAttackEffects =
        {
            {sound = "sound/NS2.fev/alien/structures/whip/hit"},
        },
    },
    
    whip_attack_start =
    {
        whipAttackEffects =
        {
            {sound = "sound/NS2.fev/alien/structures/whip/swing"},
        },
    },

    babbler_jump =
    {
        babblerJumpEffect =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/babbler/jump" },     
        },
    }, 
    
    babbler_engage =
    {
        babblerEngageEffect =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/babbler/attack_jump" },     
        },
    }, 
    
    babbler_wag_begin =
    {
        babblerWagBeginEffect =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/babbler/fetch" },     
        },
    }, 
    
    babbler_move =
    {
        babblerIdleEffect =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/babbler/idle" },     
        },
    }, 
    
    babbler_attack =
    {
        babblerAttackEffect =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/babbler/attack_jump" },    
        },
    }, 

}

GetEffectManager():AddEffectData("AlienStructureEffects", kAlienStructureEffects)
