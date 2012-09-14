// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PlayerEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

kPlayerEffectData = 
{

    // when hit by emp blast
    emp_blasted =
    {
        empBlastedEffects = 
        {
            {cinematic = "cinematics/alien/emphit.cinematic", class = "Alien", done = true},
        }    
    },

    enzymed =
    {
        enzymedEffects =
        {
            {parented_cinematic = "cinematics/alien/enzymed.cinematic", done = true},
        }
    },

    celerity_start =
    {
        celerityStartEffects =
        {
            {sound = "", silenceupgrade = true, done = true}, 
            {sound = "sound/NS2.fev/alien/common/celerity_start", done = true} 
        }
    },
    
    celerity_end =
    {
        celerityEndEffects =
        {
            {sound = "", silenceupgrade = true, done = true}, 
            {sound = "sound/NS2.fev/alien/common/celerity_end", done = true} 
        }
    },

    flap = 
    {
        flapSoundEffects =
        {
            {sound = "", silenceupgrade = true, done = true}, 
            {sound = "sound/NS2.fev/alien/lerk/flap", classname = "Lerk", done = true} 
        }
    },
    
    jump_best =
    {
        jumpBestSoundEffects =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/jump_best", classname = "Skulk", done = true},
        }
    },   
    
    jump_good =
    {
        jumpGoodSoundEffects =
        {
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/skulk/jump_good", classname = "Skulk", done = true},
        }
    },
        
    jump =
    {
        jumpSoundEffects =
        {
            {sound = "", silenceupgrade = true, done = true},        
            // Use private_sounds (ie, don't send network message) because this is generated on the client 
            // when animation plays and conserves bandwidth
            {sound = "sound/NS2.fev/alien/skulk/jump", classname = "Skulk", done = true},
            {sound = "sound/NS2.fev/alien/gorge/jump", classname = "Gorge", done = true},
            {sound = "sound/NS2.fev/alien/fade/jump", classname = "Fade", done = true},
            {sound = "sound/NS2.fev/alien/onos/jump", classname = "Onos", done = true},
            //{sound = "sound/NS2.fev/marine/heavy/jump", classname = "HeavyArmorMarine", done = true},
            {sound = "sound/NS2.fev/marine/common/jump", classname = "Marine", done = true},
        },
    },
    
    footstep =
    {
        footstepSoundEffects =
        {
            {sound = "", silenceupgrade = true, done = true},
            // Use private_sounds (ie, don't send network message) because this is generated on the client
            // when animation plays and conserves bandwidth
            // TODO: Add looping metal layer ("sound/NS2.fev/materials/metal/skulk_layer")
            
            // Skulk
            {sound = "sound/NS2.fev/materials/metal/skulk_step_for_enemy", classname = "Skulk", surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/skulk_step", classname = "Skulk", surface = "metal", done = true},
            
            {sound = "sound/NS2.fev/materials/thin_metal/skulk_step_for_enemy", classname = "Skulk", surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/skulk_step", classname = "Skulk", surface = "thin_metal", done = true},
            
            {sound = "sound/NS2.fev/materials/organic/skulk_step_for_enemy", classname = "Skulk", surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/skulk_step", classname = "Skulk", surface = "organic", done = true},
            
            {sound = "sound/NS2.fev/materials/rock/skulk_step_for_enemy", classname = "Skulk", surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/skulk_step", classname = "Skulk", surface = "rock", done = true},
            
            // Gorge
            {sound = "sound/NS2.fev/materials/metal/gorge_step_for_enemy", classname = "Gorge", surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/gorge_step", classname = "Gorge", surface = "metal", done = true},
            
            {sound = "sound/NS2.fev/materials/thin_metal/gorge_step_for_enemy", classname = "Gorge", surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/gorge_step", classname = "Gorge", surface = "thin_metal", done = true},
            
            {sound = "sound/NS2.fev/materials/organic/gorge_step_for_enemy", classname = "Gorge", surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/gorge_step", classname = "Gorge", surface = "organic", done = true},
            
            {sound = "sound/NS2.fev/materials/rock/gorge_step_for_enemy", classname = "Gorge", surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/gorge_step", classname = "Gorge", surface = "rock", done = true},
            
            // Lerk
            {sound = "sound/NS2.fev/materials/metal/lerk_step_for_enemy", classname = "Lerk", surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/lerk_step", classname = "Lerk", surface = "metal", done = true},
            
            {sound = "sound/NS2.fev/materials/thin_metal/lerk_step_for_enemy", classname = "Lerk", surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/lerk_step", classname = "Lerk", surface = "thin_metal", done = true},
            
            {sound = "sound/NS2.fev/materials/organic/lerk_step_for_enemy", classname = "Lerk", surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/lerk_step", classname = "Lerk", surface = "organic", done = true},
            
            {sound = "sound/NS2.fev/materials/rock/lerk_step_for_enemy", classname = "Lerk", surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/lerk_step", classname = "Lerk", surface = "rock", done = true},
            
            // Fade
            {sound = "sound/NS2.fev/materials/metal/fade_step_for_enemy", classname = "Fade", surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/fade_step", classname = "Fade", surface = "metal", done = true},
            
            {sound = "sound/NS2.fev/materials/thin_metal/fade_step_for_enemy", classname = "Fade", surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/fade_step", classname = "Fade", surface = "thin_metal", done = true},
            
            {sound = "sound/NS2.fev/materials/organic/fade_step_for_enemy", classname = "Fade", surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/fade_step", classname = "Fade", surface = "organic", done = true},
            
            {sound = "sound/NS2.fev/materials/rock/fade_step_for_enemy", classname = "Fade", surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/fade_step", classname = "Fade", surface = "rock", done = true},
            
            // Onos
            {sound = "sound/NS2.fev/materials/metal/onos_step_for_enemy", classname = "Onos", surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/onos_step", classname = "Onos", surface = "metal", done = true},
            
            {sound = "sound/NS2.fev/materials/thin_metal/onos_step_for_enemy", classname = "Onos", surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/onos_step", classname = "Onos", surface = "thin_metal", done = true},
            
            {sound = "sound/NS2.fev/materials/organic/onos_step_for_enemy", classname = "Onos", surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/onos_step", classname = "Onos", surface = "organic", done = true},
            
            {sound = "sound/NS2.fev/materials/rock/onos_step_for_enemy", classname = "Onos", surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/onos_step", classname = "Onos", surface = "rock", done = true},
            
            {sound = "sound/NS2.fev/alien/onos/onos_step", classname = "Onos", done = true},
            
            // HA
            /*
            {sound = "sound/NS2.fev/marine/heavy/step", classname = "HeavyArmorMarine", surface = "metal", done = true},
            {sound = "sound/NS2.fev/marine/heavy/step", classname = "HeavyArmorMarine", surface = "thin_metal", done = true},
            {sound = "sound/NS2.fev/marine/heavy/step", classname = "HeavyArmorMarine", surface = "organic", done = true},
            {sound = "sound/NS2.fev/marine/heavy/step", classname = "HeavyArmorMarine", surface = "rock", done = true},
            {sound = "sound/NS2.fev/marine/heavy/step", classname = "HeavyArmorMarine", classname = "Onos", done = true},
            */
            // Marine
            
            // Sprint
            //{sound = "sound/NS2.fev/materials/metal/sprint_left_for_enemy", left = true, sprinting = true, surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/sprint_left", left = true, sprinting = true, surface = "metal", done = true},
            //{sound = "sound/NS2.fev/materials/metal/sprint_right_for_enemy", left = false, sprinting = true, surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/sprint_right", left = false, sprinting = true, surface = "metal", done = true},
            
            //{sound = "sound/NS2.fev/materials/thin_metal/sprint_left_for_enemy", left = true, sprinting = true, surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/sprint_left", left = true, sprinting = true, surface = "thin_metal", done = true},
            //{sound = "sound/NS2.fev/materials/thin_metal/sprint_right_for_enemy", left = false, sprinting = true, surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/sprint_right", left = false, sprinting = true, surface = "thin_metal", done = true},
            
            //{sound = "sound/NS2.fev/materials/organic/sprint_left_for_enemy", left = true, sprinting = true, surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/sprint_left", left = true, sprinting = true, surface = "organic", done = true},
            //{sound = "sound/NS2.fev/materials/organic/sprint_right_for_enemy", left = false, sprinting = true, surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/sprint_right", left = false, sprinting = true, surface = "organic", done = true},
            
            //{sound = "sound/NS2.fev/materials/rock/sprint_left_for_enemy", left = true, sprinting = true, surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/sprint_left", left = true, sprinting = true, surface = "rock", done = true},
            //{sound = "sound/NS2.fev/materials/rock/sprint_right_for_enemy", left = false, sprinting = true, surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/sprint_right", left = false, sprinting = true, surface = "rock", done = true},
            
            // Backpedal
            {sound = "sound/NS2.fev/materials/metal/backpedal_left", left = true, forward = false, surface = "metal", done = true},
            {sound = "sound/NS2.fev/materials/metal/backpedal_right", left = false, forward = false, surface = "metal", done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/backpedal_left", left = true, forward = false, surface = "thin_metal", done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/backpedal_right", left = false, forward = false, surface = "thin_metal", done = true},
            {sound = "sound/NS2.fev/materials/organic/backpedal_left", left = true, forward = false, surface = "organic", done = true},
            {sound = "sound/NS2.fev/materials/organic/backpedal_right", left = false, forward = false, surface = "organic", done = true},
            {sound = "sound/NS2.fev/materials/rock/backpedal_left", left = true, forward = false, surface = "rock", done = true},
            {sound = "sound/NS2.fev/materials/rock/backpedal_right", left = false, forward = false, surface = "rock", done = true},

            // Crouch
            {sound = "sound/NS2.fev/materials/metal/crouch_left", left = true, crouch = true, surface = "metal", done = true},
            {sound = "sound/NS2.fev/materials/metal/crouch_right", left = false, crouch = true, surface = "metal", done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/crouch_left", left = true, crouch = true, surface = "thin_metal", done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/crouch_right", left = false, crouch = true, surface = "thin_metal", done = true},
            {sound = "sound/NS2.fev/materials/organic/crouch_left", left = true, crouch = true, surface = "organic", done = true},
            {sound = "sound/NS2.fev/materials/organic/crouch_right", left = false, crouch = true, surface = "organic", done = true},
            {sound = "sound/NS2.fev/materials/rock/crouch_left", left = true, crouch = true, surface = "rock", done = true},
            {sound = "sound/NS2.fev/materials/rock/crouch_right", left = false, crouch = true, surface = "rock", done = true},
            
            // Normal walk
            {sound = "sound/NS2.fev/materials/metal/footstep_left_for_enemy", left = true, surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/footstep_left", left = true, surface = "metal", done = true},
            {sound = "sound/NS2.fev/materials/metal/footstep_right_for_enemy", left = true, surface = "metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/metal/footstep_right", left = false, surface = "metal", done = true},
            
            {sound = "sound/NS2.fev/materials/thin_metal/footstep_left_for_enemy", left = true, surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/footstep_left", left = true, surface = "thin_metal", done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/footstep_right_for_enemy", left = false, surface = "thin_metal", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/footstep_right", left = false, surface = "thin_metal", done = true},
            
            {sound = "sound/NS2.fev/materials/organic/footstep_left_for_enemy", left = true, surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/footstep_left", left = true, surface = "organic", done = true},
            {sound = "sound/NS2.fev/materials/organic/footstep_right_for_enemy", left = false, surface = "organic", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/organic/footstep_right", left = false, surface = "organic", done = true},
            
            {sound = "sound/NS2.fev/materials/rock/footstep_left_for_enemy", left = true, surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/footstep_left", left = true, surface = "rock", done = true},
            {sound = "sound/NS2.fev/materials/rock/footstep_right_for_enemy", left = false, surface = "rock", enemy = true, done = true},
            {sound = "sound/NS2.fev/materials/rock/footstep_right", left = false, surface = "rock", done = true},
            
        },
    },
    
    land = 
    {
        landSoundEffects = 
        {
            {sound = "", silenceupgrade = true, done = true},  
        
            {sound = "sound/NS2.fev/alien/skulk/land", classname = "Skulk", done = true},
            {sound = "sound/NS2.fev/alien/lerk/land", classname = "Lerk", done = true},
            {sound = "sound/NS2.fev/alien/gorge/land", classname = "Gorge", done = true},
            {sound = "sound/NS2.fev/alien/fade/land", classname = "Fade", done = true},
            {sound = "sound/NS2.fev/alien/onos/land", classname = "Onos", done = true},
            //{sound = "sound/NS2.fev/marine/heavy/land", classname = "HeavyArmorMarine", done = true},

            {sound = "sound/NS2.fev/materials/organic/fall", surface = "organic", classname = "Marine", done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/fall", surface = "thin_metal", classname = "Marine", done = true},
            {sound = "sound/NS2.fev/materials/rock/fall", surface = "rock", classname = "Marine", done = true},
            {sound = "sound/NS2.fev/materials/metal/fall", classname = "Marine", done = true},            
            
            {sound = "sound/NS2.fev/materials/organic/fall", surface = "organic", classname = "ReadyRoomPlayer", done = true},
            {sound = "sound/NS2.fev/materials/thin_metal/fall", surface = "thin_metal", classname = "ReadyRoomPlayer", done = true},
            {sound = "sound/NS2.fev/materials/rock/fall", surface = "rock", classname = "ReadyRoomPlayer", done = true},
            {sound = "sound/NS2.fev/materials/metal/fall", classname = "ReadyRoomPlayer", done = true},   
            
        },
        
        landCinematics =
        {
            {cinematic = "cinematics/marine/heavy/land.cinematic", classname = "HeavyArmorMarine", done = true},
        },
    },
    
    momentum_change =
    {
        momentumChangeEffects =
        {
            {cinematic = "cinematics/materials/metal/onos_momentum_change.cinematic",  doer = "Onos", surface = "metal", done = true},
            {cinematic = "cinematics/materials/thin_metal/onos_momentum_change.cinematic",  doer = "Onos", surface = "thin_metal", done = true},
            {cinematic = "cinematics/materials/organic/onos_momentum_change.cinematic",  doer = "Onos", surface = "organic", done = true},
            {cinematic = "cinematics/materials/rock/onos_momentum_change.cinematic",  doer = "Onos", surface = "rock", done = true},
        }
    },

    // Triggered for local player
    disorient_loop =
    {
        disorientFX =
        {
            {looping_sound = "sound/NS2.fev/alien/structures/shade/disorientate", active = true, done = true},
            {stop_sound = "sound/NS2.fev/alien/structures/shade/disorientate", active = false, done = true},
        },
    },
    
    cloak_loop =
    {
        cloakFX =
        {
            {looping_sound = "sound/NS2.fev/alien/structures/shade/cloak_loop", active = true, done = true},
            {stop_sound = "sound/NS2.fev/alien/structures/shade/cloak_loop", active = false, done = true},
        },
    },
    
    taunt = 
    {
        tauntSound =
        {
            {sound = "", silenceupgrade = true, done = true},  
        
            {sound = "sound/NS2.fev/alien/skulk/taunt", classname = "Skulk", done = true},
            {sound = "sound/NS2.fev/alien/gorge/taunt", classname = "Gorge", done = true},
            {sound = "sound/NS2.fev/alien/lerk/taunt", classname = "Lerk", done = true},
            {sound = "sound/NS2.fev/alien/fade/taunt", classname = "Fade", done = true},
            {sound = "sound/NS2.fev/alien/onos/taunt", classname = "Onos", done = true},
            {sound = "sound/NS2.fev/marine/voiceovers/taunt", classname = "Marine", done = true},

        }
    },
    
    teleport =
    {
        teleportSound =
        {
            {private_sound = "sound/NS2.fev/marine/structures/phase_gate_teleport_2D", classname = "Marine"},
        }
    },
    
    player_beacon =
    {
        playerBeaconEffects =
        {
            {parented_cinematic = "cinematics/marine/beacon_big.cinematic", classname = "HeavyArmorMarine", done = true},
            {parented_cinematic = "cinematics/marine/beacon.cinematic"},
        }
    },
    
    regeneration =
    {
        regenerationEffect =
        {
            {parented_cinematic = "cinematics/alien/heal.cinematic"},
            
            {sound = "", silenceupgrade = true, done = true},
            {sound = "sound/NS2.fev/alien/common/regeneration_ability", classname = "Alien", done = true, world_space = true},
        
        }
    },
}

GetEffectManager():AddEffectData("PlayerEffectData", kPlayerEffectData)
