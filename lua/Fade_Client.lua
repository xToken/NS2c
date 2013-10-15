// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Fade_Client.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Modified to remove visual effects of fade while blinking

local kFirstPersonMiniBlinkCinematic = "cinematics/alien/fade/miniblink1p.cinematic"

local kFadeCameraYOffset = 0.6

function Fade:TriggerFirstPersonMiniBlinkEffect(direction)

    local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
    cinematic:SetCinematic(kFirstPersonMiniBlinkCinematic)
    local coords = Coords.GetIdentity()
    coords.zAxis = direction
    coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
    
    cinematic:SetCoords(coords)

end