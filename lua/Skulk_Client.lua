// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Skulk_Client.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Skulk.kCameraRollSpeedModifier = 0.5
Skulk.kCameraRollTiltModifier = 0.05

local kSkulkHealthbarOffset = Vector(0, 0.7, 0)
function Skulk:GetHealthbarOffset()
    return kSkulkHealthbarOffset
end

function Skulk:OnInitLocalClient()

    Alien.OnInitLocalClient(self)
    
    if gEnableSpeedMeter then
        self:CreateSpeedMeter()
    end    

end

function Skulk:UpdateMisc(input)

    Alien.UpdateMisc(self, input)

end

function Skulk:GetHeadAttachpointName()
    return "Bone_Tongue"
end