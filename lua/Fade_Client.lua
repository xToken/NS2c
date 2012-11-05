// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Fade_Client.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Fade.kFirstPersonMiniBlinkCinematic = "cinematics/alien/fade/miniblink1p.cinematic"

local kFadeCameraYOffset = 0.6

function Fade:OnUpdateRender()
    
    PROFILE("Fade:OnUpdateRender")
    Player.OnUpdateRender(self)

end  

function Fade:TriggerFirstPersonMiniBlinkEffect(direction)

    local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
    cinematic:SetCinematic(Fade.kFirstPersonMiniBlinkCinematic)
    local coords = Coords.GetIdentity()
    coords.zAxis = direction
    coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
    
    cinematic:SetCoords(coords)

end