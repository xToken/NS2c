// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineWeaponEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kMarineWeaponEffects =
{

    burn_spore =
    {
        burnSporeEffects =
        {
            {cinematic = "cinematics/alien/burn_sporecloud.cinematic"},
        } 
    
    },
    
    burn_umbra =
    {
        burnSporeEffects =
        {
            {cinematic = "cinematics/alien/burn_umbra.cinematic"},
        } 
    
    },

    // When marine weapon hits ground
    weapon_dropped =
    {
        weaponDropEffects = 
        {
            {sound = "sound/NS2.fev/marine/common/drop_weapon"},
        },
    },
    
    holster =
    {
        holsterStopEffects =
        {
            {stop_viewmodel_cinematic = "cinematics/marine/flamethrower/pilot.cinematic", classname = "Flamethrower"},
            {stop_viewmodel_cinematic = "cinematics/marine/flamethrower/flame_1p.cinematic", classname = "Flamethrower"},
            {stop_cinematic = "cinematics/marine/flamethrower/flame.cinematic", classname = "Flamethrower"},
            {stop_viewmodel_cinematic = "cinematics/marine/flamethrower/flameout.cinematic", classname = "Flamethrower", done = true},
            {stop_viewmodel_cinematic = "cinematics/marine/builder/builder_scan.cinematic", classname = "Builder", done = true},
        },
    },
    
    draw =
    {
        marineWeaponDrawSounds =
        {
            
            {sound = "sound/NS2.fev/marine/rifle/deploy_grenade", classname = "GrenadeLauncher", done = true},
            {sound = "sound/NS2.fev/marine/rifle/draw", classname = "Rifle", done = true},
            {sound = "sound/NS2.fev/marine/pistol/draw", classname = "Pistol", done = true},
            {sound = "sound/NS2.fev/marine/axe/draw", classname = "Axe", done = true},
            {sound = "sound/NS2.fev/marine/flamethrower/draw", classname = "Flamethrower", done = true},
            {sound = "sound/NS2.fev/marine/shotgun/deploy", classname = "Shotgun", done = true},
            //{sound = "sound/ns1.fev/ns1/weapons/shotgun_draw", classname = "Shotgun", done = true},
            {sound = "sound/NS2.fev/marine/welder/deploy", classname = "Welder", done = true},

        },

    },
    
    exo_login =
    {
        viewModelCinematics =
        {
            {viewmodel_cinematic = "cinematics/marine/heavy/deploy_light.cinematic", attach_point = "exosuit_camBone"},
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
            {sound = "sound/NS2.fev/marine/pistol/reload", classname = "Pistol"},
            {sound = "sound/NS2.fev/marine/flamethrower/reload", classname = "Flamethrower"},
        },
    },
    
    reload_cancel =
    {
        gunReloadCancelEffects =
        {
            {stop_sound = "sound/NS2.fev/marine/rifle/reload", classname = "Rifle"},
            {stop_sound = "sound/NS2.fev/marine/pistol/reload", classname = "Pistol"},
        },
    },
    
    clipweapon_empty =
    {
        emptySounds =
        {
            {sound = "sound/NS2.fev/marine/shotgun/fire_empty", classname = "Shotgun", done = true},
            {sound = "sound/NS2.fev/marine/shotgun/fire_empty", classname = "NadeLauncher", done = true},
            {sound = "sound/NS2.fev/marine/common/empty", classname = "Rifle", done = true},
            {sound = "sound/NS2.fev/marine/common/empty", classname = "Flamethrower", done = true},
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
            {sound = "sound/NS2.fev/marine/pistol/fire"},
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
            {sound = "sound/NS2.fev/marine/shotgun/fire", empty = false},
            
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
    
    flamethrower_attack = 
    {
        flamethrowerAttackCinematics = 
        {
            // If we're out of ammo, play 'flame out' effect
            {viewmodel_cinematic = "cinematics/marine/flamethrower/flameout.cinematic", attach_point = "fxnode_flamethrowermuzzle", empty = true},
            {weapon_cinematic = "cinematics/marine/flamethrower/flameout.cinematic", attach_point = "fxnode_flamethrowermuzzle", empty = true, done = true},
        
            // Otherwise play either first-person or third-person flames
            {viewmodel_cinematic = "cinematics/marine/flamethrower/flame_1p.cinematic", attach_point = "fxnode_flamethrowermuzzle"},
            {weapon_cinematic = "cinematics/marine/flamethrower/flame.cinematic", attach_point = "fxnode_flamethrowermuzzle"},
        },
        
        flamethrowerAttackEffects = 
        {
            // Sound effect
            {looping_sound = "sound/NS2.fev/marine/flamethrower/attack_start"},
        },
    },
    
    flamethrower_attack_end = 
    {
        flamethrowerAttackEndCinematics = 
        {
            {stop_sound = "sound/NS2.fev/marine/flamethrower/attack_start"},
            {sound = "sound/NS2.fev/marine/flamethrower/attack_end"},
        },
    },
    
    flamethrower_pilot =
    {
        flamethrowerPilotEffects =
        {
            {viewmodel_cinematic = "cinematics/marine/flamethrower/pilot.cinematic", attach_point = "fxnode_flamethrowermuzzle", empty = false},
        }
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
            //{sound = "sound/NS2.fev/marine/flamethrower/attack_start"},
        },
    },
    
    welder_end =
    {
        welderEndEffects =
        {   
            {stop_viewmodel_cinematic = "cinematics/marine/welder/welder_muzzle.cinematic" },
            //{sound = "sound/NS2.fev/marine/flamethrower/attack_end"},
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
            {sound = "sound/NS2.fev/marine/structures/mac/build"},
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
    
    builder_nano_construct = 
    {
        builderMuzzleEffects =
        {
            {viewmodel_cinematic = "cinematics/marine/builder/builder_nano_scan.cinematic", attach_point = "fxnode_weldermuzzle"},
            {weapon_cinematic = "cinematics/marine/builder/builder_nano_scan.cinematic", attach_point = "fxnode_weldermuzzle"},
        },
    },
    
    minigun_overheated_left =
    {
        minigunOverheatEffects =
        {
            {viewmodel_cinematic = "cinematics/marine/minigun/overheat.cinematic", attach_point = "fxnode_l_minigun_muzzle"},
        }
    },
    
    
    minigun_overheated_right =
    {
        minigunOverheatEffects =
        {
            {viewmodel_cinematic = "cinematics/marine/minigun/overheat.cinematic", attach_point = "fxnode_r_minigun_muzzle"},
        }
    },
    
    claw_attack =
    {
        sounds =
        {
            {sound = "sound/NS2.fev/marine/heavy/punch", done = true},
        }
    },
    
}

GetEffectManager():AddEffectData("MarineWeaponEffects", kMarineWeaponEffects)
