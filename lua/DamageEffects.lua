// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//    
// lua\DamageEffects.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Effect defination for all damage sources and targets. Including target entities and world geometry surface.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kDamageEffects =
{

    // Play ricochet sound for player locally for feedback (triggered if target > 5 meters away)
    hit_effect_local =
    {
        hitEffectLocalEffects =
        {
            // marine effects:
            {private_sound = "sound/NS2.fev/marine/rifle/alt_hit_hard", doer = "ClipWeapon", isalien = true, surface = "ethereal", done = true},
            {private_sound = "sound/NS2.fev/marine/rifle/alt_hit_hard", doer = "ClipWeapon", isalien = true, surface = "umbra", done = true},
            {private_sound = "sound/NS2.fev/materials/organic/scrape", doer = "Shotgun", isalien = true, done = true},
            {private_sound = "sound/NS2.fev/marine/common/hit", doer = "ClipWeapon", isalien = true, done = true},
            {private_sound = "sound/NS2.fev/materials/metal/ricochet", doer = "ClipWeapon", done = true},
        
            // alien effects:
            {private_sound = "sound/NS2.fev/alien/gorge/spit_hit", doer = "Spit", done = true},
            {private_sound = "sound/NS2.fev/alien/skulk/parasite_hit", doer = "Parasite", ismarine = true, classname = "Player", done = true},

        },
    },
    
    damage_sound =
    {
        damageSounds =
        {
            {private_sound = "", surface = "nanoshield", done = true},
            {private_sound = "", surface = "flame", done = true},
            
            //Flinch sounds here, because they would otherwise never get triggered :/
            {private_sound = "sound/NS2.fev/marine/common/wound_serious", classname = "Marine", flinch_severe = true, done = true},
            {private_sound = "sound/NS2.fev/marine/common/wound", classname = "Marine", done = true},
            
            // alien flinch effects
            {private_sound = "sound/NS2.fev/alien/skulk/wound_serious", classname = "Skulk", flinch_severe = true, done = true},
            {private_sound = "sound/NS2.fev/alien/skulk/wound", classname = "Skulk", done = true},            
            {private_sound = "sound/NS2.fev/alien/gorge/wound_serious", classname = "Gorge", flinch_severe = true, done = true},
            {private_sound = "sound/NS2.fev/alien/gorge/wound", classname = "Gorge", done = true}, 
            {private_sound = "sound/NS2.fev/alien/lerk/wound_serious", classname = "Lerk", flinch_severe = true, done = true},
            {private_sound = "sound/NS2.fev/alien/lerk/wound", classname = "Lerk", done = true},
            {private_sound = "sound/ns2c.fev/ns2c/alien/fade/wound", classname = "Fade", flinch_severe = true, done = true},
            {private_sound = "sound/NS2.fev/alien/fade/wound", classname = "Fade", done = true},
            {private_sound = "sound/NS2.fev/alien/onos/wound_serious", classname = "Onos", flinch_severe = true, done = true},
            {private_sound = "sound/NS2.fev/alien/onos/wound", classname = "Onos", done = true},           
            {private_sound = "sound/NS2.fev/alien/structures/shade/wound", classname = "Shade", done = true},
            {private_sound = "sound/NS2.fev/alien/structures/hydra/wound", classname = "Hydra", done = true},
            {private_sound = "sound/NS2.fev/alien/structures/crag/wound", classname = "Crag", done = true},
            {private_sound = "sound/NS2.fev/alien/structures/whip/wound", classname = "Whip", done = true},
            {private_sound = "sound/NS2.fev/alien/structures/harvester_wound", classname = "Harvester", done = true},       
            {private_sound = "sound/NS2.fev/marine/common/pickup_ammo", done = true},
            
            // marine effects:
            {private_sound = "sound/NS2.fev/marine/rifle/alt_hit_hard", surface = "umbra", doer = "ClipWeapon", done = true},
            
            {private_sound = "sound/NS2.fev/materials/metal/bash", surface = "metal", doer = "Rifle", alt_mode = true, done = true},
            {private_sound = "sound/NS2.fev/materials/organic/bash", surface = "organic", doer = "Rifle", alt_mode = true, done = true},
            {private_sound = "sound/NS2.fev/materials/rock/bash", surface = "rock", doer = "Rifle", alt_mode = true, done = true},
            {private_sound = "sound/NS2.fev/materials/thin_metal/bash", surface = "thin_metal", doer = "Rifle", alt_mode = true, done = true},
            {private_sound = "sound/NS2.fev/materials/electronic/bash", surface = "electronic", doer = "Rifle", alt_mode = true, done = true},
            {private_sound = "sound/NS2.fev/materials/armor/bash", surface = "armor", doer = "Rifle", alt_mode = true, done = true},
            {private_sound = "sound/NS2.fev/materials/flesh/bash", surface = "flesh", doer = "Rifle", alt_mode = true, done = true},
            {private_sound = "sound/NS2.fev/materials/membrane/bash", surface = "membrane", doer = "Rifle", alt_mode = true, done = true},
            {private_sound = "sound/NS2.fev/materials/organic/bash", doer = "Rifle", alt_mode = true, done = true},
            
            {private_sound = "", doer = "Flamethrower", done = true},

            {private_sound = "sound/NS2.fev/materials/metal/ricochet", surface = "metal", doer = "ClipWeapon", done = true},
            {private_sound = "sound/NS2.fev/materials/organic/ricochet", surface = "organic", doer = "ClipWeapon", done = true},
            {private_sound = "sound/NS2.fev/materials/rock/ricochet", surface = "rock", doer = "ClipWeapon", done = true},
            {private_sound = "sound/NS2.fev/materials/thin_metal/ricochet", surface = "thin_metal", doer = "ClipWeapon", done = true},
            {private_sound = "sound/NS2.fev/materials/door/ricochet", surface = "door", doer = "ClipWeapon", done = true},
            {private_sound = "sound/NS2.fev/materials/electronic/ricochet", surface = "electronic", doer = "ClipWeapon", done = true},
            {private_sound = "sound/NS2.fev/materials/armor/ricochet", surface = "armor", doer = "ClipWeapon", done = true},
            {private_sound = "sound/NS2.fev/materials/flesh/ricochet", surface = "flesh", doer = "ClipWeapon", done = true},
            {private_sound = "sound/NS2.fev/materials/membrane/ricochet", surface = "membrane", doer = "ClipWeapon", done = true},
            {private_sound = "sound/NS2.fev/materials/organic/ricochet", doer = "ClipWeapon", done = true},
            
            {private_sound = "sound/NS2.fev/materials/metal/ricochet", surface = "metal", doer = "Sentry", done = true},
            {private_sound = "sound/NS2.fev/materials/organic/ricochet", surface = "organic", doer = "Sentry", done = true},
            {private_sound = "sound/NS2.fev/materials/rock/ricochet", surface = "rock", doer = "Sentry", done = true},
            {private_sound = "sound/NS2.fev/materials/thin_metal/ricochet", surface = "thin_metal", doer = "Sentry", done = true},
            {private_sound = "sound/NS2.fev/materials/door/ricochet", surface = "door", doer = "Sentry", done = true},
            {private_sound = "sound/NS2.fev/materials/electronic/ricochet", surface = "electronic", doer = "Sentry", done = true},
            {private_sound = "sound/NS2.fev/materials/armor/ricochet", surface = "armor", doer = "Sentry", done = true},
            {private_sound = "sound/NS2.fev/materials/flesh/ricochet", surface = "flesh", doer = "Sentry", done = true},
            {private_sound = "sound/NS2.fev/materials/membrane/ricochet", surface = "membrane", doer = "Sentry", done = true},
            {private_sound = "sound/NS2.fev/materials/organic/ricochet", doer = "Sentry", done = true},
            
            {private_sound = "sound/NS2.fev/materials/metal/axe", surface = "metal", doer = "Axe", done = true},
            {private_sound = "sound/NS2.fev/materials/organic/axe", surface = "organic", doer = "Axe", done = true},
            {private_sound = "sound/NS2.fev/materials/rock/axe", surface = "rock", doer = "Axe", done = true},
            {private_sound = "sound/NS2.fev/materials/thin_metal/axe", surface = "thin_metal", doer = "Axe", done = true},
            {private_sound = "sound/NS2.fev/materials/electronic/axe", surface = "electronic", doer = "Axe", done = true},
            {private_sound = "sound/NS2.fev/materials/armor/axe", surface = "armor", doer = "Axe", done = true},
            {private_sound = "sound/NS2.fev/materials/flesh/axe", surface = "flesh", doer = "Axe", done = true},
            {private_sound = "sound/NS2.fev/materials/membrane/axe", surface = "membrane", doer = "Axe", done = true},
            {private_sound = "sound/NS2.fev/materials/organic/axe", doer = "Axe", done = true},
            
            //{sound = "sound/NS2.fev/marine/heavy/punch_hit_alien", surface = "membrane", doer = "Claw", done = true},
            //{sound = "sound/NS2.fev/marine/heavy/punch_hit_alien", surface = "organic", doer = "Claw", done = true},
            //{sound = "sound/NS2.fev/marine/heavy/punch_hit_alien", surface = "infestation", doer = "Claw", done = true},
            //{sound = "sound/NS2.fev/marine/heavy/punch_hit_geometry", doer = "Claw", done = true},

            // alien effects:
            {private_sound = "sound/NS2.fev/alien/structures/whip/hit", doer = "Whip", done = true},
            
            {private_sound = "sound/NS2.fev/alien/skulk/bite_hit_metal", surface = "metal", doer = "BiteLeap", done = true},
            {private_sound = "sound/NS2.fev/alien/skulk/bite_hit_organic", surface = "organic", doer = "BiteLeap", done = true},
            {private_sound = "sound/NS2.fev/alien/skulk/bite_hit_rock", surface = "rock", doer = "BiteLeap", done = true},
            {private_sound = "sound/NS2.fev/alien/skulk/bite_hit_marine", surface = "armor", doer = "BiteLeap", done = true},
            {private_sound = "sound/NS2.fev/alien/skulk/bite_hit_marine", surface = "flesh", doer = "BiteLeap", done = true},
            {private_sound = "sound/NS2.fev/alien/skulk/bite_hit_organic", surface = "membrane", doer = "BiteLeap", done = true},
            {private_sound = "sound/NS2.fev/alien/skulk/bite_hit_metal", doer = "BiteLeap", done = true},
            
            {private_sound = "sound/NS2.fev/alien/skulk/parasite_hit", doer = "Parasite", classname = "Marine", done = true},
            
            {private_sound = "sound/NS2.fev/alien/gorge/spit_hit", doer = "Spit", classname = "Marine", done = true},        
            

            {private_sound = "sound/NS2.fev/alien/common/spike_hit_marine", surface = "armor", doer = "LerkBite", alt_mode = true, done = true},
            {private_sound = "sound/NS2.fev/alien/lerk/spikes_pierce", surface = "flesh", doer = "LerkBite", alt_mode = true, done = true},
            {private_sound = "sound/NS2.fev/alien/common/spike_hit_marine", surface = "armor", doer = "Spores", alt_mode = true, done = true},
            {private_sound = "sound/NS2.fev/alien/lerk/spikes_pierce", surface = "flesh", doer = "Spores", alt_mode = true, done = true},
            {private_sound = "sound/NS2.fev/alien/common/spike_hit_marine", surface = "armor", doer = "LerkUmbra", alt_mode = true, done = true},
            {private_sound = "sound/NS2.fev/alien/lerk/spikes_pierce", surface = "flesh", doer = "LerkUmbra", alt_mode = true, done = true},
            
            {private_sound = "sound/NS2.fev/alien/skulk/bite_hit_metal", surface = "metal", doer = "LerkBite", done = true},
            {private_sound = "sound/NS2.fev/alien/skulk/bite_hit_organic", surface = "organic", doer = "LerkBite", done = true},
            {private_sound = "sound/NS2.fev/alien/skulk/bite_hit_rock", surface = "rock", doer = "LerkBite", done = true},
            {private_sound = "sound/NS2.fev/alien/skulk/bite_hit_marine", surface = "armor", doer = "LerkBite", done = true},
            {private_sound = "sound/NS2.fev/alien/skulk/bite_hit_marine", surface = "flesh", doer = "LerkBite", done = true},
            {private_sound = "sound/NS2.fev/alien/skulk/bite_hit_organic", surface = "membrane", doer = "LerkBite", done = true},
            {private_sound = "sound/NS2.fev/alien/skulk/bite_hit_metal", doer = "LerkBite", done = true},
            
            {private_sound = "sound/NS2.fev/materials/metal/metal_scrape", surface = "metal", doer = "SwipeBlink", done = true},
            {private_sound = "sound/NS2.fev/materials/thin_metal/scrape", surface = "thin_metal", doer = "SwipeBlink", done = true},
            {private_sound = "sound/NS2.fev/materials/thin_metal/scrape", surface = "electronic", doer = "SwipeBlink", done = true},
            {private_sound = "sound/NS2.fev/materials/organic/scrape", surface = "organic", doer = "SwipeBlink", done = true},
            {private_sound = "sound/NS2.fev/materials/rock/scrape", surface = "rock", doer = "SwipeBlink", done = true},
            {private_sound = "sound/NS2.fev/alien/fade/swipe_hit_marine", surface = "armor", doer = "SwipeBlink", done = true},
            {private_sound = "sound/NS2.fev/alien/fade/swipe_hit_marine", surface = "flesh", doer = "SwipeBlink", done = true},
            {private_sound = "sound/NS2.fev/materials/organic/scrape", surface = "membrane", doer = "SwipeBlink", done = true},
            {private_sound = "sound/NS2.fev/materials/metal/metal_scrape", doer = "SwipeBlink", done = true},
            
            {private_sound = "sound/NS2.fev/alien/lerk/spikes_structure", surface = "metal", doer = "Hydra", done = true},
            {private_sound = "sound/NS2.fev/alien/common/spike_hit_marine", surface = "armor", doer = "Hydra", done = true},
            {private_sound = "sound/NS2.fev/alien/lerk/spikes_pierce", surface = "flesh", doer = "Hydra", done = true},
            {private_sound = "sound/NS2.fev/materials/rock/ricochet", doer = "Hydra", done = true},
            
            {private_sound = "sound/NS2.fev/alien/onos/gore_hit_metal", surface = "metal", doer = "Gore", done = true},
            {private_sound = "sound/NS2.fev/alien/onos/gore_hit_organic", surface = "organic", doer = "Gore", done = true},
            {private_sound = "sound/NS2.fev/alien/onos/gore_hit_thin_metal", surface = "glass", doer = "Gore", done = true},
            {private_sound = "sound/NS2.fev/materials/rock/ricochet", surface = "rock", doer = "Gore", done = true},
            {private_sound = "sound/NS2.fev/alien/onos/gore_hit_thin_metal", surface = "thin_metal", doer = "Gore", done = true},
            {private_sound = "sound/NS2.fev/alien/onos/gore_hit_door", surface = "door", doer = "Gore", done = true},
            {private_sound = "sound/NS2.fev/alien/onos/gore_hit_thin_metal", surface = "electronic", doer = "Gore", done = true},
            {private_sound = "sound/NS2.fev/alien/onos/gore_hit_marine", surface = "armor", doer = "Gore", done = true},
            {private_sound = "sound/NS2.fev/alien/onos/gore_hit_marine", surface = "flesh", doer = "Gore", done = true},
            {private_sound = "sound/NS2.fev/materials/membrane/ricochet", surface = "membrane", doer = "Gore", done = true},
            {private_sound = "sound/NS2.fev/materials/organic/ricochet", doer = "Gore", done = true},
            
        }
    },

    // triggered client side for the shooter, all other players receive a message from the server
    damage =
    {
        damageEffects =
        {
            
            {player_cinematic = "cinematics/materials/%s/bash.cinematic", doer = "Rifle", alt_mode = true, done = true},
            {player_cinematic = "cinematics/materials/%s/ricochetHeavy.cinematic", doer = "Shotgun", done = true},
            {player_cinematic = "cinematics/materials/%s/ricochet.cinematic", doer = "ClipWeapon", done = true},
            {player_cinematic = "cinematics/materials/%s/ricochet.cinematic", doer = "Sentry", done = true},
            {player_cinematic = "cinematics/materials/%s/axe.cinematic", doer = "Axe", done = true},
            
            // alien effects:         
            {player_cinematic = "cinematics/materials/%s/bash.cinematic", doer = "Whip", done = true}, 
            {player_cinematic = "cinematics/materials/%s/bite.cinematic", doer = "BiteLeap", done = true},             
            {player_cinematic = "cinematics/alien/skulk/parasite_hit_marine.cinematic", doer = "Parasite", classname = "Marine", done = true}, // TODO: remove sound from cinematic
            {player_cinematic = "cinematics/alien/skulk/parasite_hit.cinematic", doer = "Parasite", done = true}, // TODO: remove sound from cinematic
            {player_cinematic = "cinematics/alien/gorge/spit_impact.cinematic", doer = "Spit", done = true}, // TODO: remove sound from cinematic
            {player_cinematic = "cinematics/materials/%s/sting.cinematic", doer = "Hydra", done = true},
            {player_cinematic = "cinematics/materials/%s/scrape.cinematic", doer = "SwipeBlink", done = true},
            {player_cinematic = "cinematics/materials/%s/gore.cinematic", doer = "Gore", done = true},
            
            {player_cinematic = "cinematics/materials/%s/sting.cinematic", doer = "LerkBite", alt_mode = true, done = true},
            {player_cinematic = "cinematics/materials/%s/bite.cinematic", doer = "LerkBite", done = true},
            {player_cinematic = "cinematics/materials/%s/sting.cinematic", doer = "Spores", alt_mode = true, done = true},
            {player_cinematic = "cinematics/materials/%s/sting.cinematic", doer = "LerkUmbra", alt_mode = true, done = true},
            
        },        
    },

    // effects are played every 3 seconds, client side only
    damaged =
    {
        damagedEffects =
        {
            // marine damaged effects
            {cinematic = "cinematics/marine/sentry/hurt_severe.cinematic", classname = "Sentry", flinch_severe = true, done = true},
            {cinematic = "cinematics/marine/sentry/hurt.cinematic", classname = "Sentry", done = true},
            {cinematic = "cinematics/marine/commandstation/hurt_severe.cinematic", classname = "CommandStation", flinch_severe = true, done = true},
            {cinematic = "cinematics/marine/commandstation/hurt.cinematic", classname = "CommandStation", done = true},
            {cinematic = "cinematics/marine/infantryportal/hurt_severe.cinematic", classname = "InfantryPortal", flinch_severe = true, done = true},
            {cinematic = "cinematics/marine/infantryportal/hurt.cinematic", classname = "InfantryPortal", done = true},
            {cinematic = "cinematics/marine/roboticsfactory/hurt_severe.cinematic", classname = "RoboticsFactory", flinch_severe = true, done = true},
            {cinematic = "cinematics/marine/roboticsfactory/hurt.cinematic", classname = "RoboticsFactory", done = true},
            {cinematic = "cinematics/marine/phasegate/hurt_severe.cinematic", classname = "PhaseGate", flinch_severe = true, done = true},
            {cinematic = "cinematics/marine/phasegate/hurt.cinematic", classname = "PhaseGate", done = true},
            
            {cinematic = "", classname = "PowerPoint", done = true},
            
            {cinematic = "cinematics/marine/structures/hurt_small_severe.cinematic", classname = "ArmsLab", flinch_severe = true, done = true},
            {cinematic = "cinematics/marine/structures/hurt_small.cinematic", classname = "ArmsLab", done = true},
            {cinematic = "cinematics/marine/structures/hurt_small_severe.cinematic", classname = "Observatory", flinch_severe = true, done = true},
            {cinematic = "cinematics/marine/structures/hurt_small.cinematic", classname = "Observatory", done = true},
            //{cinematic = "cinematics/marine/structures/hurt_small_severe.cinematic", classname = "PowerPack", flinch_severe = true, done = true},
            //{cinematic = "cinematics/marine/structures/hurt_small.cinematic", classname = "SentryBattery", done = true},
            //{parented_cinematic = "cinematics/marine/exo/hurt_severe.cinematic", classname = "HeavyArmorMarine", isalien = false, flinch_severe = true, done = true},
            //{parented_cinematic = "cinematics/marine/exo/hurt.cinematic", classname = "HeavyArmorMarine", isalien = false, done = true},
        
        
            // alien damaged effects
            {cinematic = "cinematics/alien/hive/hurt_severe.cinematic", classname = "Hive", flinch_severe = true, done = true},
            {cinematic = "cinematics/alien/hive/hurt.cinematic", classname = "Hive", done = true},
            {cinematic = "cinematics/alien/harvester/hurt_severe.cinematic", classname = "Harvester", flinch_severe = true, done = true},
            {cinematic = "cinematics/alien/harvester/hurt.cinematic", classname = "Harvester", done = true},
            {cinematic = "cinematics/alien/harvester/hurt_severe.cinematic", classname = "Harvester", flinch_severe = true, done = true},
            {cinematic = "cinematics/alien/harvester/hurt.cinematic", classname = "Harvester", done = true},
            {cinematic = "cinematics/alien/hydra/hurt_severe.cinematic", classname = "Hydra", flinch_severe = true, done = true},
            {cinematic = "cinematics/alien/hydra/hurt.cinematic", classname = "Hydra", done = true},
            {cinematic = "cinematics/alien/shade/hurt_severe.cinematic", classname = "Shade", flinch_severe = true, done = true},
            {cinematic = "cinematics/alien/shade/hurt.cinematic", classname = "Shade", done = true},
            {cinematic = "cinematics/alien/shift/hurt_severe.cinematic", classname = "Shift", flinch_severe = true, done = true},
            {cinematic = "cinematics/alien/shift/hurt.cinematic", classname = "Shift", done = true},
            {cinematic = "cinematics/alien/crag/hurt_severe.cinematic", classname = "Crag", flinch_severe = true, done = true},
            {cinematic = "cinematics/alien/crag/hurt.cinematic", classname = "Crag", done = true},
            {cinematic = "cinematics/alien/whip/hurt_severe.cinematic", classname = "Whip", flinch_severe = true, done = true},
            {cinematic = "cinematics/alien/whip/hurt.cinematic", classname = "Whip", done = true},
      
            {cinematic = "cinematics/alien/structures/hurt_severe.cinematic", classname = "Structure", isalien = true, flinch_severe = true, done = true},   
            {cinematic = "cinematics/alien/structures/hurt.cinematic", classname = "Structure", isalien = true, done = true},   
        }
    },

}

GetEffectManager():AddEffectData("DamageEffects", kDamageEffects)