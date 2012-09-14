// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MedPack.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/DropPack.lua")
Script.Load("lua/PickupableMixin.lua")

class 'MedPack' (DropPack)

MedPack.kMapName = "medpack"

MedPack.kModelName = PrecacheAsset("models/marine/medpack/medpack.model")
MedPack.kHealthSound = PrecacheAsset("sound/NS2.fev/marine/common/health")

MedPack.kHealth = 50

function MedPack:OnInitialized()

    DropPack.OnInitialized(self)
    
    self:SetModel(MedPack.kModelName)
    
    InitMixin(self, PickupableMixin, { kRecipientType = "Marine" })
    
    if Server then
        self:_CheckForPickup()
    end
    
end

function MedPack:OnTouch(recipient)

    recipient:AddHealth(MedPack.kHealth, false, true)

    StartSoundEffectAtOrigin(MedPack.kHealthSound, self:GetOrigin())
    
end

function MedPack:GetIsValidRecipient(recipient)

    return recipient:GetHealth() < recipient:GetMaxHealth()
    
end

function GetAttachToMarineRequiresHealth(entity)

    local valid = false
    
    if entity:isa("Marine") then
        valid = entity:GetHealth() < entity:GetMaxHealth()
    end
    
    return valid

end

Shared.LinkClassToMap("MedPack", MedPack.kMapName)