// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineWeaponEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kMarineWeaponEffects =
{

    // When marine weapon hits ground
    weapon_dropped =
    {
        weaponDropEffects = 
        {
            {sound = "sound/ns2c.fev/ns2c/marine/weapon/drop"},
            //{sound = "sound/NS2.fev/marine/common/drop_weapon"},
        },
    },
    
    holster =
    {
        holsterStopEffects =
        {
            {stop_cinematic = "cinematics/marine/flamethrower/flame.cinematic", classname = "Flamethrower"},
        },
    },
    
    draw =
    {
        marineWeaponDrawSounds =
        {
            
            {player_sound = "sound/NS2.fev/marine/rifle/deploy_grenade", classname = "GrenadeLauncher", done = true},
            {player_sound = "sound/ns2c.fev/ns2c/marine/weapon/lmg_draw", classname = "Rifle", done = true},
            {player_sound = "sound/ns2c.fev/ns2c/marine/weapon/pistol_draw", classname = "Pistol", done = true},
            {player_sound = "sound/NS2.fev/marine/axe/draw", classname = "Axe", done = true},
            {player_sound = "sound/ns2c.fev/ns2c/marine/weapon/hmg_draw", classname = "HeavyMachineGun", done = true},
            {player_sound = "sound/ns2c.fev/ns2c/marine/weapon/shotgun_draw", classname = "Shotgun", done = true},
            {player_sound = "sound/NS2.fev/marine/welder/deploy", classname = "Welder", done = true},
            //{player_sound = "sound/NS2.fev/marine/rifle/draw", classname = "Rifle", done = true},
            //{player_sound = "sound/NS2.fev/marine/pistol/draw", classname = "Pistol", done = true},
            //{player_sound = "sound/NS2.fev/marine/flamethrower/draw", classname = "HeavyMachineGun", done = true},
            //{player_sound = "sound/NS2.fev/marine/shotgun/deploy", classname = "Shotgun", done = true},
			{player_sound = "sound/NS2.fev/marine/grenades/draw", classname = "HandGrenades", done = true},
        },

    },
    
    grenade_throw =
    {
        effects = 
        {
            {player_sound = "sound/NS2.fev/marine/grenades/throw"},
        }
    },
    
    grenade_pull_pin =
    {
        effects = 
        {
            {player_sound = "sound/NS2.fev/marine/grenades/pin"},
        }
    },
    
    exo_login =
    {
        viewModelCinematics =
        {
            {viewmodel_cinematic = "cinematics/marine/heavy/deploy_light.cinematic", attach_point = "exosuit_camBone"},
        },
    },

    reload = 
    {
        gunReloadEffects =
        {
            {player_sound = "sound/ns2c.fev/ns2c/marine/weapon/lmg_reload", classname = "Rifle"},
            {player_sound = "sound/ns2c.fev/ns2c/marine/weapon/pistol_reload", classname = "Pistol"},
            {player_sound = "sound/ns2c.fev/ns2c/marine/weapon/hmg_reload", classname = "HeavyMachineGun"},
            //{player_sound = "sound/NS2.fev/marine/rifle/reload", classname = "Rifle"},
            //{player_sound = "sound/NS2.fev/marine/pistol/reload", classname = "Pistol"},
            //{sound = "sound/NS2.fev/marine/flamethrower/reload", classname = "HeavyMachineGun"},
        },
    },
    
    reload_cancel =
    {
        gunReloadCancelEffects =
        {
            {stop_sound = "sound/ns2c.fev/ns2c/marine/weapon/lmg_reload", classname = "Rifle"},
            {stop_sound = "sound/ns2c.fev/ns2c/marine/weapon/pistol_reload", classname = "Pistol"},
            {stop_sound = "sound/ns2c.fev/ns2c/marine/weapon/hmg_reload", classname = "HeavyMachineGun"},
            //{stop_sound = "sound/NS2.fev/marine/rifle/reload", classname = "Rifle"},
            //{stop_sound = "sound/NS2.fev/marine/pistol/reload", classname = "Pistol"},
            //{stop_sound = "sound/NS2.fev/marine/flamethrower/reload", classname = "HeavyMachineGun"},
        },
    },
    
    clipweapon_empty =
    {
        emptySounds =
        {
            {player_sound = "sound/NS2.fev/marine/shotgun/fire_empty", classname = "Shotgun", done = true},
            {player_sound = "sound/NS2.fev/marine/shotgun/fire_empty", classname = "NadeLauncher", done = true},
            {player_sound = "sound/NS2.fev/marine/common/empty", classname = "Rifle", done = true},
            {player_sound = "sound/NS2.fev/marine/common/empty", classname = "GrenadeLauncher", done = true},
            {player_sound = "sound/NS2.fev/marine/common/empty", classname = "Pistol", done = true},  
        },
        
    },
    
    pistol_attack = 
    {
        pistolAttackEffects = 
        {
            {viewmodel_cinematic = "cinematics/marine/pistol/muzzle_flash.cinematic", attach_point = "fxnode_pistolmuzzle"},
            // First-person and weapon shell casings
            {viewmodel_cinematic = "cinematics/marine/pistol/shell.cinematic", attach_point = "fxnode_pistolcasing"},
            
            {weapon_cinematic = "cinematics/marine/pistol/muzzle_flash.cinematic", attach_point = "fxnode_pistolmuzzle"},
            {weapon_cinematic = "cinematics/marine/pistol/shell.cinematic", attach_point = "fxnode_pistolcasing"} ,
            
            // Sound effect
            //{player_sound = "sound/ns2c.fev/ns2c/marine/weapon/pistol_fire"},
            {player_sound = "sound/NS2.fev/marine/pistol/fire"},
        },
    },
    
    axe_attack = 
    {
        axeAttackEffects = 
        {
            { player_sound = "sound/NS2.fev/marine/axe/attack_female", sex = "female", done = true },
            { player_sound = "sound/NS2.fev/marine/axe/attack" },
        },
    },

    shotgun_attack = 
    {
        shotgunAttackEffects = 
        {
            {player_sound = "sound/ns2c.fev/ns2c/marine/weapon/shotgun_fire", empty = false},
            //{player_sound = "sound/NS2.fev/marine/shotgun/fire", empty = false},
            {viewmodel_cinematic = "cinematics/marine/shotgun/muzzle_flash.cinematic", attach_point = "fxnode_shotgunmuzzle"},
            {weapon_cinematic = "cinematics/marine/shotgun/muzzle_flash.cinematic", attach_point = "fxnode_shotgunmuzzle"},
            {weapon_cinematic = "cinematics/marine/shotgun/shell.cinematic", attach_point = "fxnode_shotguncasing"} ,
        },
    },
    
    // Special shotgun reload effects
    shotgun_reload_start =
    {
        shotgunReloadStartEffects =
        {
            {player_sound = "sound/NS2.fev/marine/shotgun/start_reload"},
        },
    },

    shotgun_reload_shell =
    {
        shotgunReloadShellEffects =
        {
            {player_sound = "sound/NS2.fev/marine/shotgun/load_shell"},
        },
    },

    shotgun_reload_end =
    {
        shotgunReloadEndEffects =
        {
            {player_sound = "sound/NS2.fev/marine/shotgun/end_reload"},
        },
    },
    
    // Special shotgun reload effects
    grenadelauncher_reload_start =
    {
        grenadelauncherReloadStartEffects =
        {
            {player_sound = "sound/NS2.fev/marine/grenade_launcher/reload_start"},
        },
    },

    grenadelauncher_reload_shell =
    {
        grenadelauncherReloadShellEffects =
        {
            {sound = "sound/NS2.fev/marine/grenade_launcher/reload"},
        },
    },
    
    grenadelauncher_reload_shell_last =
    {
        grenadelauncherReloadShellEffects =
        {
            {player_sound = "sound/NS2.fev/marine/grenade_launcher/reload_last"},
        },
    },

    grenadelauncher_reload_end =
    {
        grenadelauncherReloadEndEffects =
        {
            {player_sound = "sound/NS2.fev/marine/grenade_launcher/reload_end"},
        },
    },
    
    grenadelauncher_attack =
    {
        glAttackEffects =
        {
            {viewmodel_cinematic = "cinematics/marine/gl/muzzle_flash.cinematic", attach_point = "fxnode_glmuzzle", empty = false},
            {weapon_cinematic = "cinematics/marine/gl/muzzle_flash.cinematic", attach_point = "fxnode_glmuzzle", empty = false},
            
            {player_sound = "sound/NS2.fev/marine/rifle/fire_grenade", done = true},
            {player_sound = "sound/NS2.fev/marine/common/empty", empty = true, done = true},
        },
    },
    
    grenadelauncher_alt_attack =
    {
        glAttackEffects =
        {
            {viewmodel_cinematic = "cinematics/marine/gl/muzzle_flash.cinematic", attach_point = "fxnode_glmuzzle", empty = false},
            
            {player_sound = "sound/NS2.fev/marine/rifle/fire_grenade", done = true},
            {player_sound = "sound/NS2.fev/marine/common/empty", empty = true, done = true},
        },
    },
    
    mine_spawn =
    {
        mineSpawn =
        {
            {sound = "sound/NS2.fev/marine/common/mine_drop"},
            {sound = "sound/NS2.fev/marine/common/mine_warmup"},
        },
    },
    
    mine_arm =
    {
        mineArm =
        {
            {sound = "sound/NS2.fev/marine/common/mine_explode"},
        }
    },
    
    mine_explode =
    {
        mineExplode =
        {
            {cinematic = "cinematics/materials/ethereal/grenade_explosion.cinematic", surface = "ethereal", done = true},  
            {cinematic = "cinematics/materials/%s/grenade_explosion.cinematic"},
        }
            
    },
    
    release_nervegas =
    {
        releaseNerveGasEffects = 
        {
            {parented_cinematic = "cinematics/marine/grenades/nerve_explo.cinematic"},
            {sound = "sound/NS2.fev/marine/grenades/gas/explode"},
        },    
    },

    grenadelauncher_reload =
    {
        glReloadEffects = 
        {
            {player_sound = "sound/NS2.fev/marine/rifle/reload_grenade"},
        },    
    },
    
    grenade_bounce =
    {
        grenadeBounceEffects =
        {
            {sound = "sound/NS2.fev/marine/rifle/grenade_bounce"},
        },
    },
    
    explosion_decal =
    {
        explosionDecal =
        {
            {decal = "cinematics/vfx_materials/decals/blast_01.material", scale = 2, done = true}
        }    
    },
    
    grenade_explode =
    {
        grenadeExplodeEffects =
        {
            // Any asset name with a %s will use the "surface" parameter as the name        
            {cinematic = "cinematics/materials/ethereal/grenade_explosion.cinematic", surface = "ethereal", done = true},   
            {cinematic = "cinematics/materials/%s/grenade_explosion.cinematic"},
        },
        
        grenadeExplodeSounds =
        {
            {sound = "sound/NS2.fev/marine/common/explode", surface = "ethereal", done = true},
            {sound = "sound/NS2.fev/marine/common/explode", done = true},
        },
    },
    
    cluster_grenade_explode =
    {
        grenadeExplodeEffects =
        {  
            {sound = "sound/NS2.fev/marine/grenades/cluster/primary_explode"},
            {cinematic = "cinematics/marine/grenades/cluster_main_explo.cinematic", done = true}
        }
    },
    
    cluster_fragment_explode =
    {
        grenadeExplodeEffects =
        {  
            {sound = "sound/NS2.fev/marine/grenades/cluster/secondary_explode"},
            {cinematic = "cinematics/marine/grenades/cluster_small_explos.cinematic", done = true}
        }
    },
    
    clusterfragment_residue = 
    {
        clusterFragmentResiudeEffect = 
        {
            {cinematic = "cinematics/marine/clusterfragment_residue.cinematic"},
        },
    },
    
    pulse_grenade_explode =
    {
        pulseGrenadeEffects =
        {   
            {sound = "sound/NS2.fev/marine/grenades/pulse/explode"},
            {cinematic = "cinematics/marine/grenades/pulse_explo.cinematic", done = true},
        },
    },
    
    welder_start =
    {
        welderStartEffects =
        {
            {viewmodel_cinematic = "cinematics/marine/welder/welder_start.cinematic", attach_point = "fxnode_weldermuzzle"},
            {weapon_cinematic = "cinematics/marine/welder/welder_start.cinematic", attach_point = "fxnode_weldermuzzle"},
        },
    },
    
    welder_end =
    {
        welderEndEffects =
        {   
            {stop_viewmodel_cinematic = "cinematics/marine/welder/welder_muzzle.cinematic" },
        },
    },

    // using looping sound at Welder class, only cinematic defined here
    welder_muzzle =
    {
        welderMuzzleEffects =
        {
            {viewmodel_cinematic = "cinematics/marine/welder/welder_muzzle.cinematic", attach_point = "fxnode_weldermuzzle"},
            {weapon_cinematic = "cinematics/marine/welder/welder_muzzle.cinematic", attach_point = "fxnode_weldermuzzle"},
        },
    },
    
    welder_hit =
    {
        welderHitEffects =
        {
            {cinematic = "cinematics/marine/welder/welder_hit.cinematic"},
        },
    },
    
    welder_attack_hit =
    {
        welderAttackHitEffects =
        {
            //{cinematic = "cinematics/marine/welder/welder_attack_hit.cinematic"},
            {sound = "sound/NS2.fev/marine/welder/attack"},
        },
    },
    
    builder_construct = 
    {
        builderMuzzleEffects =
        {
            {viewmodel_cinematic = "cinematics/marine/builder/builder_scan.cinematic", attach_point = "fxnode_weldermuzzle"},
            {weapon_cinematic = "cinematics/marine/builder/builder_scan.cinematic", attach_point = "fxnode_weldermuzzle"},
        },
    },
    
}

GetEffectManager():AddEffectData("MarineWeaponEffects", kMarineWeaponEffects)