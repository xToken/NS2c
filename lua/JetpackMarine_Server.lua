// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\JetpackMarine_Server.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Cant buy jetpacks

/**
 * Don't allow purchase of jetpack when the Marine already has a Jetpack.
 */
function JetpackMarine:AttemptToBuy(techIds)

    return false
    
end