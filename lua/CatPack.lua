// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CatPack.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/DropPack.lua")
Script.Load("lua/PickupableMixin.lua")

class 'CatPack' (DropPack)
CatPack.kMapName = "catpack"

CatPack.kModelName = PrecacheAsset("models/marine/catpack/catpack.model")
CatPack.kPickupSound = PrecacheAsset("sound/NS2.fev/marine/common/catalyst")

CatPack.kDuration = 6
CatPack.kAttackSpeedModifier = 1.3
CatPack.kMoveSpeedScalar = 1.2

function CatPack:OnInitialized()

    DropPack.OnInitialized(self)
    
    self:SetModel(CatPack.kModelName)
    
    InitMixin(self, PickupableMixin, { kRecipientType = "Marine" })
    
    if Server then
        self:_CheckForPickup()
    end

end

function CatPack:OnTouch(recipient)

    StartSoundEffectAtOrigin(CatPack.kPickupSound, recipient:GetOrigin())
    recipient:ApplyCatPack()
    
end

/**
 * Any Marine is a valid recipient.
 */
function CatPack:GetIsValidRecipient(recipient)
    return (recipient.GetHasCatpackBoost and not recipient:GetHasCatpackBoost())    
end

Shared.LinkClassToMap("CatPack", CatPack.kMapName)