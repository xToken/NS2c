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
    
    damage_sound_target_local =
    {
        damageLocalSounds =
        {
            {private_sound = "sound/NS2.fev/alien/common/getting_shot", doer = "ClipWeapon", done = true},
            {private_sound = "sound/NS2.fev/alien/common/getting_shot", doer = "Minigun", done = true},
            {private_sound = "sound/NS2.fev/alien/common/getting_shot", doer = "Railgun", done = true},
            {private_sound = "sound/NS2.fev/alien/common/getting_shot", doer = "Sentry", done = true},
        }
    
    },
    
    damage_sound =
    {
        damageSounds =
        {
            {sound = "", surface = "nanoshield", done = true},
            {sound = "", surface = "flame", done = true},
            
            //Flinch sounds here, because they would otherwise never get triggered :/
            {sound = "sound/NS2.fev/marine/common/spore_wound_female", classname = "Marine", sex = "female", damagetype = kDamageType.Gas, world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/common/spore_wound", classname = "Marine", damagetype = kDamageType.Gas, world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/common/wound_serious_female", classname = "Marine", sex = "female", flinch_severe = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/common/wound_serious", classname = "Marine", flinch_severe = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/common/wound_female", classname = "Marine", sex = "female", world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/common/wound", classname = "Marine", world_space = true, done = true},
            
            // alien flinch effects
            {sound = "sound/NS2.fev/alien/skulk/wound_serious", classname = "Skulk", flinch_severe = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/wound", classname = "Skulk", world_space = true, done = true},            
            {sound = "sound/NS2.fev/alien/gorge/wound_serious", classname = "Gorge", flinch_severe = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/gorge/wound", classname = "Gorge", world_space = true, done = true}, 
            {sound = "sound/NS2.fev/alien/lerk/wound_serious", classname = "Lerk", flinch_severe = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/lerk/wound", classname = "Lerk", world_space = true, done = true},
            {sound = "sound/ns2c.fev/ns2c/alien/fade/wound", classname = "Fade", flinch_severe = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/fade/wound", classname = "Fade", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/onos/wound_serious", classname = "Onos", flinch_severe = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/onos/wound", classname = "Onos", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/drifter/wound", classname = "Drifter", world_space = true, done = true},            
            {sound = "sound/NS2.fev/alien/structures/shade/wound", classname = "Shade", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/structures/hydra/wound", classname = "Hydra", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/structures/crag/wound", classname = "Crag", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/structures/whip/wound", classname = "Whip", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/structures/harvester_wound", classname = "Harvester", world_space = true, done = true},    
            
            // marine effects:
            {sound = "sound/NS2.fev/marine/rifle/alt_hit_hard", surface = "ethereal", world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/rifle/alt_hit_hard", surface = "hallucination", world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/rifle/alt_hit_hard", surface = "umbra", doer = "ClipWeapon", world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/rifle/alt_hit_hard", surface = "umbra", doer = "Minigun", world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/rifle/alt_hit_hard", surface = "umbra", doer = "Railgun", world_space = true, done = true},
            
            {sound = "sound/NS2.fev/materials/metal/bash", surface = "metal", doer = "Rifle", alt_mode = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/bash", surface = "organic", doer = "Rifle", alt_mode = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/bash", surface = "infestation", doer = "Rifle", alt_mode = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/bash", surface = "rock", doer = "Rifle", alt_mode = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/bash", surface = "thin_metal", doer = "Rifle", alt_mode = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/electronic/bash", surface = "electronic", doer = "Rifle", alt_mode = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/armor/bash", surface = "armor", doer = "Rifle", alt_mode = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/flesh/bash", surface = "flesh", doer = "Rifle", alt_mode = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/membrane/bash", surface = "membrane", doer = "Rifle", alt_mode = true, world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/bash", doer = "Rifle", alt_mode = true, world_space = true, done = true},
            
            {sound = "", doer = "Flamethrower", world_space = true, done = true},

            {sound = "sound/NS2.fev/materials/metal/ricochet", surface = "metal", doer = "ClipWeapon", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/ricochet", surface = "organic", doer = "ClipWeapon", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/ricochet", surface = "infestation", doer = "ClipWeapon", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/ricochet", surface = "rock", doer = "ClipWeapon", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/ricochet", surface = "thin_metal", doer = "ClipWeapon", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/door/ricochet", surface = "door", doer = "ClipWeapon", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/electronic/ricochet", surface = "electronic", doer = "ClipWeapon", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/armor/ricochet", surface = "armor", doer = "ClipWeapon", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/flesh/ricochet", surface = "flesh", doer = "ClipWeapon", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/membrane/ricochet", surface = "membrane", doer = "ClipWeapon", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/ricochet", doer = "ClipWeapon", world_space = true, done = true},
            
            {sound = "sound/NS2.fev/materials/metal/ricochet", surface = "metal", doer = "Minigun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/ricochet", surface = "organic", doer = "Minigun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/ricochet", surface = "infestation", doer = "Minigun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/ricochet", surface = "rock", doer = "Minigun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/ricochet", surface = "thin_metal", doer = "Minigun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/door/ricochet", surface = "door", doer = "Minigun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/electronic/ricochet", surface = "electronic", doer = "Minigun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/armor/ricochet", surface = "armor", doer = "Minigun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/flesh/ricochet", surface = "flesh", doer = "Minigun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/membrane/ricochet", surface = "membrane", doer = "Minigun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/ricochet", doer = "Minigun", world_space = true, done = true},
            
            {sound = "sound/NS2.fev/materials/metal/ricochet", surface = "metal", doer = "Railgun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/ricochet", surface = "organic", doer = "Railgun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/ricochet", surface = "infestation", doer = "Railgun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/ricochet", surface = "rock", doer = "Railgun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/ricochet", surface = "thin_metal", doer = "Railgun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/door/ricochet", surface = "door", doer = "Railgun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/electronic/ricochet", surface = "electronic", doer = "Railgun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/armor/ricochet", surface = "armor", doer = "Railgun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/flesh/ricochet", surface = "flesh", doer = "Railgun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/membrane/ricochet", surface = "membrane", doer = "Railgun", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/ricochet", doer = "Railgun", world_space = true, done = true},

            {sound = "sound/NS2.fev/materials/metal/ricochet", surface = "metal", doer = "Sentry", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/ricochet", surface = "organic", doer = "Sentry", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/ricochet", surface = "infestation", doer = "Sentry", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/ricochet", surface = "rock", doer = "Sentry", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/ricochet", surface = "thin_metal", doer = "Sentry", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/door/ricochet", surface = "door", doer = "Sentry", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/electronic/ricochet", surface = "electronic", doer = "Sentry", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/armor/ricochet", surface = "armor", doer = "Sentry", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/flesh/ricochet", surface = "flesh", doer = "Sentry", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/membrane/ricochet", surface = "membrane", doer = "Sentry", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/ricochet", doer = "Sentry", world_space = true, done = true},
            
            {sound = "sound/NS2.fev/materials/metal/axe", surface = "metal", doer = "Axe", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/axe", surface = "organic", doer = "Axe", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/axe", surface = "infestation", doer = "Axe", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/axe", surface = "rock", doer = "Axe", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/axe", surface = "thin_metal", doer = "Axe", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/electronic/axe", surface = "electronic", doer = "Axe", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/armor/axe", surface = "armor", doer = "Axe", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/flesh/axe", surface = "flesh", doer = "Axe", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/membrane/axe", surface = "membrane", doer = "Axe", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/axe", doer = "Axe", world_space = true, done = true},
            
            {sound = "sound/NS2.fev/marine/heavy/punch_hit_alien", surface = "membrane", doer = "Claw", world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/heavy/punch_hit_alien", surface = "organic", doer = "Claw", world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/heavy/punch_hit_alien", surface = "infestation", doer = "Claw", world_space = true, done = true},
            {sound = "sound/NS2.fev/marine/heavy/punch_hit_geometry", doer = "Claw", world_space = true, done = true},

            // alien effects:
            {sound = "sound/NS2.fev/alien/structures/whip/hit", doer = "Whip", world_space = true, done = true},
            
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_metal", surface = "metal", doer = "BiteLeap", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_thin_metal", surface = "thin_metal", doer = "BiteLeap", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_organic", surface = "organic", doer = "BiteLeap", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_organic", surface = "infestation", doer = "BiteLeap", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_rock", surface = "rock", doer = "BiteLeap", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_marine", surface = "armor", doer = "BiteLeap", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_marine", surface = "flesh", doer = "BiteLeap", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_organic", surface = "membrane", doer = "BiteLeap", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_metal", doer = "BiteLeap", world_space = true, done = true},
            
            {sound = "sound/NS2.fev/alien/skulk/parasite_hit", doer = "Parasite", classname = "Marine", world_space = true, done = true},

            {sound = "sound/NS2.fev/alien/common/spike_hit_marine", surface = "armor", doer = "LerkBite", alt_mode = true, done = true},
            {sound = "sound/NS2.fev/alien/lerk/spikes_pierce", surface = "flesh", doer = "LerkBite", alt_mode = true, done = true},
            {sound = "sound/NS2.fev/alien/common/spike_hit_marine", surface = "armor", doer = "Spores", alt_mode = true, done = true},
            {sound = "sound/NS2.fev/alien/lerk/spikes_pierce", surface = "flesh", doer = "Spores", alt_mode = true, done = true},
            {sound = "sound/NS2.fev/alien/common/spike_hit_marine", surface = "armor", doer = "LerkUmbra", alt_mode = true, done = true},
            {sound = "sound/NS2.fev/alien/lerk/spikes_pierce", surface = "flesh", doer = "LerkUmbra", alt_mode = true, done = true},
            
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_metal", surface = "metal", doer = "LerkBite", world_space = true, done = true},
			{sound = "sound/NS2.fev/alien/skulk/bite_hit_thin_metal", surface = "thin_metal", doer = "LerkBite", alt_mode = false, world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_organic", surface = "organic", doer = "LerkBite", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_organic", surface = "infestation", doer = "LerkBite", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_rock", surface = "rock", doer = "LerkBite", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_marine", surface = "armor", doer = "LerkBite", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_marine", surface = "flesh", doer = "LerkBite", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_organic", surface = "membrane", doer = "LerkBite", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/bite_hit_metal", doer = "LerkBite", world_space = true, done = true},
            
            {sound = "sound/NS2.fev/materials/metal/metal_scrape", surface = "metal", doer = "SwipeBlink", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/scrape", surface = "thin_metal", doer = "SwipeBlink", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/scrape", surface = "electronic", doer = "SwipeBlink", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/scrape", surface = "organic", doer = "SwipeBlink", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/scrape", surface = "infestation", doer = "SwipeBlink", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/scrape", surface = "rock", doer = "SwipeBlink", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/fade/swipe_hit_marine", surface = "armor", doer = "SwipeBlink", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/fade/swipe_hit_marine", surface = "flesh", doer = "SwipeBlink", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/scrape", surface = "membrane", doer = "SwipeBlink", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/metal_scrape", doer = "SwipeBlink", world_space = true, done = true},
            
            {sound = "sound/NS2.fev/alien/lerk/spikes_structure", surface = "metal", doer = "Hydra", done = true},
            {sound = "sound/NS2.fev/alien/common/spike_hit_marine", surface = "armor", doer = "Hydra", done = true},
            {sound = "sound/NS2.fev/alien/lerk/spikes_pierce", surface = "flesh", doer = "Hydra", done = true},
            {sound = "sound/NS2.fev/materials/rock/ricochet", doer = "Hydra", done = true},
            
            {sound = "sound/NS2.fev/alien/onos/gore_hit_metal", surface = "metal", doer = "Gore", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/onos/gore_hit_thin_metal", surface = "thin_metal", doer = "Gore", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/onos/gore_hit_thin_metal", surface = "electronic", doer = "Gore", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/onos/gore_hit_organic", surface = "organic", doer = "Gore", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/onos/gore_hit_organic", surface = "infestation", doer = "Gore", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/onos/gore_hit_thin_metal", surface = "glass", doer = "Gore", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/ricochet", surface = "rock", doer = "Gore", world_space = true, done = true},

            {sound = "sound/NS2.fev/alien/onos/gore_hit_door", surface = "door", doer = "Gore", world_space = true, done = true},

            {sound = "sound/NS2.fev/alien/onos/gore_hit_marine", surface = "armor", doer = "Gore", world_space = true, done = true},
            {sound = "sound/NS2.fev/alien/onos/gore_hit_marine", surface = "flesh", doer = "Gore", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/membrane/ricochet", surface = "membrane", doer = "Gore", world_space = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/ricochet", doer = "Gore", world_space = true, done = true},
            
        }
    },
    
    alien_blood_ground =
    {
        alienGroundBloodDecal =
        {
            {decal = "cinematics/vfx_materials/decals/alien_blood_ground.material", scale = 2, done = true}
        }
    },
    
    // note: disabled spit decals
    spit_hit =
    {
        effects =
        {
            {sound = "sound/NS2.fev/alien/gorge/spit_hit", world_space = true},
            {cinematic = "cinematics/alien/gorge/spit_impact.cinematic", done = true},
        }    
    },
    
    damage_decal =
    {
        damageDecals = 
        {
                  
            // marine blood 
            {decal = {{.25, "cinematics/vfx_materials/decals/marine_blood_01.material"}, 
                      {.25, "cinematics/vfx_materials/decals/marine_blood_02.material"}, 
                      {.25, "cinematics/vfx_materials/decals/marine_blood_03.material"}, 
                      {.25, "cinematics/vfx_materials/decals/marine_blood_04.material"}}, scale = 2, surface = "flesh", done = true}, 

            // alien blood
            {decal = {{.25, "cinematics/vfx_materials/decals/alien_blood_01.material"}, 
                      {.25, "cinematics/vfx_materials/decals/alien_blood_02.material"},
                      {.25, "cinematics/vfx_materials/decals/alien_blood_03.material"},
                      {.25, "cinematics/vfx_materials/decals/alien_blood_04.material"}}, scale = 0.75, surface = "organic", done = true},   
                      
            {decal = "cinematics/vfx_materials/decals/alien_blood_02.material", scale = 0.75, surface = "membrane", done = true},   
            
            // surface marine weapons
            {decal = "cinematics/vfx_materials/decals/clawmark_01.material", scale = 0.35, doer = "Axe", done = true},
            {decal = "cinematics/vfx_materials/decals/clawmark_01.material", scale = 0.35, doer = "Rifle", alt_mode = true, done = true},            
            {decal = "cinematics/vfx_materials/decals/bullet_hole_01.material", scale = 0.125, doer = "Rifle", alt_mode = false, done = true},        
            {decal = "cinematics/vfx_materials/decals/bullet_hole_01.material", scale = 0.2, doer = "HeavyMachineGun", alt_mode = false, done = true},
            {decal = "cinematics/vfx_materials/decals/bullet_hole_01.material", scale = 0.125, doer = "Shotgun", done = true},        
            {decal = "cinematics/vfx_materials/decals/bullet_hole_01.material", scale = 0.125, doer = "Pistol", done = true}, 
            {decal = "cinematics/vfx_materials/decals/bullet_hole_01.material", scale = 0.3, doer = "Minigun", done = true},
            {decal = "cinematics/vfx_materials/decals/railgun_hole_02.material", scale = 0.3, doer = "Railgun", done = true},
            
            // surface alien weapons
            {decal = "cinematics/vfx_materials/decals/bite_02.material", scale = 0.5, doer = "Spores", alt_mode = true, done = true},
            {decal = "cinematics/vfx_materials/decals/bite_02.material", scale = 0.5, doer = "Umbra", alt_mode = true, done = true},
            {decal = "cinematics/vfx_materials/decals/bite_02.material", scale = 0.5, doer = "Primal", alt_mode = true,  done = true},
            {decal = "cinematics/vfx_materials/decals/bite_02.material", scale = 0.5, doer = "Spikes", alt_mode = true, done = true},
            {decal = "cinematics/vfx_materials/decals/bullet_hole_02.material", scale = 0.25, doer = "Spikes", done = true},
            
            {decal = "cinematics/vfx_materials/decals/clawmark_01.material", scale = 0.5, doer = "BiteLeap", done = true}, 
			{decal = "cinematics/vfx_materials/decals/bite_02.material", scale = 0.5, doer = "LerkBite", done = true}, 
            
            {decal = {{.25, "cinematics/vfx_materials/decals/clawmark_01.material"},
                      {.25, "cinematics/vfx_materials/decals/clawmark_02.material"},
                      {.25, "cinematics/vfx_materials/decals/clawmark_03.material"},
                      {.25, "cinematics/vfx_materials/decals/clawmark_04.material"}}, scale = 0.25, doer = "SwipeBlink", done = true}, 
                      
            {decal = "cinematics/vfx_materials/decals/bash_01.material", scale = 1, doer = "Gore", done = true},
            {decal = "cinematics/vfx_materials/decals/bash_01.material", scale = 1, doer = "Smash", done = true}, 
        },    
    },

    // triggered client side for the shooter, all other players receive a message from the server
    damage =
    {
    
        damageEffects =
        {
            
            {player_cinematic = "cinematics/materials/%s/bash.cinematic", doer = "Rifle", alt_mode = true, done = true},
            {player_cinematic = "cinematics/materials/%s/ricochet.cinematic", doer = "Shotgun", done = true},
            {player_cinematic = "cinematics/materials/%s/ricochetMinigun.cinematic", doer = "Minigun", done = true},
            {player_cinematic = "cinematics/materials/%s/ricochetRailgun.cinematic", doer = "Railgun", done = true},
            {player_cinematic = "cinematics/materials/%s/ricochet.cinematic", doer = "ClipWeapon", done = true},
            {player_cinematic = "cinematics/materials/%s/ricochet.cinematic", doer = "Sentry", done = true},
            {player_cinematic = "cinematics/materials/%s/axe.cinematic", doer = "Axe", done = true},
            
            // alien effects:         
            {player_cinematic = "cinematics/materials/%s/bash.cinematic", doer = "Whip", done = true}, 
            {player_cinematic = "cinematics/materials/%s/bite.cinematic", doer = "BiteLeap", done = true},             
            {player_cinematic = "cinematics/alien/skulk/parasite_hit_marine.cinematic", doer = "Parasite", classname = "Marine", done = true}, // TODO: remove sound from cinematic
            {player_cinematic = "cinematics/alien/skulk/parasite_hit.cinematic", doer = "Parasite", done = true}, // TODO: remove sound from cinematic
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
            {cinematic = "cinematics/marine/roboticsfactory/hurt_severe.cinematic", classname = "TurretFactory", flinch_severe = true, done = true},
            {cinematic = "cinematics/marine/roboticsfactory/hurt.cinematic", classname = "TurretFactory", done = true},
            {cinematic = "cinematics/marine/phasegate/hurt_severe.cinematic", classname = "PhaseGate", flinch_severe = true, done = true},
            {cinematic = "cinematics/marine/phasegate/hurt.cinematic", classname = "PhaseGate", done = true},
            {cinematic = "cinematics/marine/structures/hurt_small_severe.cinematic", classname = "ArmsLab", flinch_severe = true, done = true},
            {cinematic = "cinematics/marine/structures/hurt_small.cinematic", classname = "ArmsLab", done = true},
            {cinematic = "cinematics/marine/structures/hurt_small_severe.cinematic", classname = "Observatory", flinch_severe = true, done = true},
            {cinematic = "cinematics/marine/structures/hurt_small.cinematic", classname = "Observatory", done = true},
            {cinematic = "cinematics/marine/structures/hurt_small.cinematic", classname = "SentryBattery", done = true},
            {parented_cinematic = "cinematics/marine/exo/hurt_severe.cinematic", classname = "Exo", isalien = false, flinch_severe = true, done = true},
            {parented_cinematic = "cinematics/marine/exo/hurt.cinematic", classname = "Exo", isalien = false, done = true},
            
            {cinematic = "", classname = "PowerPoint", done = true},
            {cinematic = "", classname = "Player", done = true},
            {cinematic = "", classname = "MAC", done = true},
            {cinematic = "", classname = "SiegeCannon", done = true},
            {cinematic = "cinematics/marine/structures/hurt_severe.cinematic", classname = "ScriptActor", isalien = false, flinch_severe = true, done = true},
            {cinematic = "cinematics/marine/structures/hurt.cinematic", classname = "ScriptActor", isalien = false, done = true},
            
            
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
            
            {cinematic = "", classname = "Player", done = true},
            {cinematic = "cinematics/alien/structures/hurt_severe.cinematic", classname = "ScriptActor", isalien = true, flinch_severe = true, done = true},   
            {cinematic = "cinematics/alien/structures/hurt.cinematic", classname = "ScriptActor", isalien = true, done = true},   
        }
    },

}

GetEffectManager():AddEffectData("DamageEffects", kDamageEffects)