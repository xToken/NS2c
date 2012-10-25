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
        },
    },
    
    holster =
    {
        holsterStopEffects =
        {
            {stop_viewmodel_cinematic = "cinematics/marine/builder/builder_scan.cinematic", classname = "Builder", done = true},
        },
    },
    
    draw =
    {
        marineWeaponDrawSounds =
        {
            
            {sound = "sound/NS2.fev/marine/rifle/deploy_grenade", classname = "GrenadeLauncher", done = true},
            {sound = "sound/ns2c.fev/ns2c/marine/weapon/lmg_draw", classname = "Rifle", done = true},
            {sound = "sound/ns2c.fev/ns2c/marine/weapon/pistol_draw", classname = "Pistol", done = true},
            {sound = "sound/NS2.fev/marine/axe/draw", classname = "Axe", done = true},
            {sound = "sound/ns2c.fev/ns2c/marine/weapon/hmg_draw", classname = "HeavyMachineGun", done = true},
            {sound = "sound/ns2c.fev/ns2c/marine/weapon/shotgun_draw", classname = "Shotgun", done = true},
            {sound = "sound/NS2.fev/marine/welder/deploy", classname = "Welder", done = true},

        },

    },
    
    idle = 
    {

    },

    reload = 
    {
        gunReloadEffects =
        {
            {sound = "sound/NS2.fev/marine/rifle/reload", classname = "Rifle"},
            {sound = "sound/ns2c.fev/ns2c/marine/weapon/pistol_reload", classname = "Pistol"},
            {sound = "sound/ns2c.fev/ns2c/marine/weapon/hmg_reload", classname = "HeavyMachineGun"},
        },
    },
    
    reload_cancel =
    {
        gunReloadCancelEffects =
        {
            {stop_sound = "sound/ns2c.fev/ns2c/marine/weapon/lmg_reload", classname = "Rifle"},
            {stop_sound = "sound/ns2c.fev/ns2c/marine/weapon/pistol_reload", classname = "Pistol"},
            {stop_sound = "sound/ns2c.fev/ns2c/marine/weapon/hmg_reload", classname = "HeavyMachineGun"},
        },
    },
    
    clipweapon_empty =
    {
        emptySounds =
        {
            {sound = "sound/NS2.fev/marine/shotgun/fire_empty", classname = "Shotgun", done = true},
            {sound = "sound/NS2.fev/marine/shotgun/fire_empty", classname = "NadeLauncher", done = true},
            {sound = "sound/NS2.fev/marine/common/empty", classname = "Rifle", done = true},
            {sound = "sound/NS2.fev/marine/common/empty", classname = "GrenadeLauncher", done = true},
            {sound = "sound/NS2.fev/marine/common/empty", classname = "Pistol", done = true},  
        },
        
    },
    
    rifle_alt_attack = 
    {
        rifleAltAttackEffects = 
        {
            {sound = "sound/NS2.fev/marine/rifle/alt_swing"},
        },
    },
    
    pistol_attack_shell = 
    {
        pistolAttackShell = 
        {
            // First-person and weapon shell casings
            {viewmodel_cinematic = "cinematics/marine/pistol/shell.cinematic", attach_point = "fxnode_pistolcasing"}       
        },
    },
    
    pistol_attack = 
    {
        pistolAttackEffects = 
        {
            {viewmodel_cinematic = "cinematics/marine/pistol/muzzle_flash.cinematic", attach_point = "fxnode_pistolmuzzle"},
            {weapon_cinematic = "cinematics/marine/pistol/muzzle_flash.cinematic", attach_point = "fxnode_pistolmuzzle"},
            // Sound effect
            {sound = "sound/ns2c.fev/ns2c/marine/weapon/pistol_fire"},
        },
    },
    
    axe_attack = 
    {
        axeAttackEffects = 
        {
            {sound = "sound/NS2.fev/marine/axe/attack"},
        },
    },

    shotgun_attack = 
    {
        shotgunAttackEffects = 
        {
            {sound = "sound/ns2c.fev/ns2c/marine/weapon/shotgun_fire", empty = false},
            
            {viewmodel_cinematic = "cinematics/marine/shotgun/muzzle_flash.cinematic", attach_point = "fxnode_shotgunmuzzle"},
            {weapon_cinematic = "cinematics/marine/shotgun/muzzle_flash.cinematic", attach_point = "fxnode_shotgunmuzzle"},
        },

        shotgunAttackEmptyEffects = 
        {
            {sound = "sound/NS2.fev/marine/shotgun/fire_last", empty = true},
        },
    },
    
    // Special shotgun reload effects
    shotgun_reload_start =
    {
        shotgunReloadStartEffects =
        {
            {sound = "sound/NS2.fev/marine/shotgun/start_reload"},
        },
    },

    shotgun_reload_shell =
    {
        shotgunReloadShellEffects =
        {
            {sound = "sound/NS2.fev/marine/shotgun/load_shell"},
        },
    },

    shotgun_reload_end =
    {
        shotgunReloadEndEffects =
        {
            {sound = "sound/NS2.fev/marine/shotgun/end_reload"},
        },
    },
    
    // Special shotgun reload effects
    grenadelauncher_reload_start =
    {
        grenadelauncherReloadStartEffects =
        {
            {sound = "sound/NS2.fev/marine/grenade_launcher/reload_start"},
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
            {sound = "sound/NS2.fev/marine/grenade_launcher/reload_last"},
        },
    },

    grenadelauncher_reload_end =
    {
        grenadelauncherReloadEndEffects =
        {
            {sound = "sound/NS2.fev/marine/grenade_launcher/reload_end"},
        },
    },
    
    grenadelauncher_attack =
    {
        glAttackEffects =
        {
            {viewmodel_cinematic = "cinematics/marine/gl/muzzle_flash.cinematic", attach_point = "fxnode_glmuzzle", empty = false},
            {weapon_cinematic = "cinematics/marine/gl/muzzle_flash.cinematic", attach_point = "fxnode_glmuzzle", empty = false},
            
            {sound = "sound/NS2.fev/marine/rifle/fire_grenade", done = true},
            {sound = "sound/NS2.fev/marine/common/empty", empty = true, done = true},
        },
    },
    
    grenadelauncher_alt_attack =
    {
        glAttackEffects =
        {
            {viewmodel_cinematic = "cinematics/marine/gl/muzzle_flash.cinematic", attach_point = "fxnode_glmuzzle", empty = false},
            
            {sound = "sound/NS2.fev/marine/rifle/fire_grenade", done = true},
            {sound = "sound/NS2.fev/marine/common/empty", empty = true, done = true},
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

    // TODO: Do we need cinematics/marine/gl/muzzle_flash.cinematic" and "cinematics/marine/gl/barrel_smoke.cinematic"?    
    grenadelauncher_reload =
    {
        glReloadEffects = 
        {
            {sound = "sound/NS2.fev/marine/rifle/reload_grenade"},
        },    
    },
    
    grenade_bounce =
    {
        grenadeBounceEffects =
        {
            {sound = "sound/NS2.fev/marine/rifle/grenade_bounce"},
        },
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
