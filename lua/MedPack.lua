// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MedPack.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/DropPack.lua")
Script.Load("lua/TeamMixin.lua")

class 'MedPack' (DropPack)

MedPack.kMapName = "medpack"

MedPack.kModelName = PrecacheAsset("models/marine/medpack/medpack.model")
MedPack.kHealthSound = PrecacheAsset("sound/NS2.fev/marine/common/health")

local networkVars = { }

function MedPack:OnInitialized()

    DropPack.OnInitialized(self)
    
    self:SetModel(MedPack.kModelName)
    
end

function MedPack:OnTouch(recipient)

    recipient:AddHealth(kHealthPerMedpack, false, true)

    StartSoundEffectAtOrigin(MedPack.kHealthSound, self:GetOrigin())
    
    TEST_EVENT("Commander MedPack picked up")
    
end

function MedPack:GetIsValidRecipient(recipient)
    return not GetIsVortexed(recipient) and recipient:GetHealth() < recipient:GetMaxHealth() and recipient:GetIsAlive() and not recipient:GetIsStateFrozen()
end


Shared.LinkClassToMap("MedPack", MedPack.kMapName, networkVars, false)