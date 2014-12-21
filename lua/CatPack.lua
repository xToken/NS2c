// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CatPack.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Adjusted CatPack Balance vars

Script.Load("lua/DropPack.lua")

class 'CatPack' (DropPack)
CatPack.kMapName = "catpack"

CatPack.kModelName = PrecacheAsset("models/marine/catpack/catpack.model")
CatPack.kPickupSound = PrecacheAsset("sound/NS2.fev/marine/common/catalyst")

function CatPack:OnInitialized()

    DropPack.OnInitialized(self)
    
    self:SetModel(CatPack.kModelName)
    	
end

function CatPack:OnTouch(recipient)

    StartSoundEffectAtOrigin(CatPack.kPickupSound, self:GetOrigin())
    recipient:ApplyCatPack()
    
end

/**
 * Any Marine is a valid recipient.
 */
function CatPack:GetIsValidRecipient(recipient)
    return (recipient.GetHasCatpackBoost and not recipient:GetHasCatpackBoost() and recipient:GetIsAlive()) and (not HasMixin(self, "Devourable") or not self:GetIsDevoured())
end

Shared.LinkClassToMap("CatPack", CatPack.kMapName)