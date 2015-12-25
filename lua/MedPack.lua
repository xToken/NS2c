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
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/TeamMixin.lua")

class 'MedPack' (DropPack)

MedPack.kMapName = "medpack"

MedPack.kModelNameWinter = PrecacheAsset("seasonal/holiday2012/models/gift_medkit_01.model")
MedPack.kModelName = PrecacheAsset("models/marine/medpack/medpack.model")

local function GetModelName()
    return GetSeason() == Seasons.kWinter and MedPack.kModelNameWinter or MedPack.kModelName
end

MedPack.kHealthSound = PrecacheAsset("sound/NS2.fev/marine/common/health")

local networkVars = { }

function MedPack:OnInitialized()

    DropPack.OnInitialized(self)
    
    self:SetModel(GetModelName())
    
end

function MedPack:OnTouch(recipient)

    recipient:AddHealth(kHealthPerMedpack, false, true)

    StartSoundEffectAtOrigin(MedPack.kHealthSound, self:GetOrigin())

end

function MedPack:GetIsValidRecipient(recipient)
    return not GetIsVortexed(recipient) and recipient:GetHealth() < recipient:GetMaxHealth() and recipient:GetIsAlive() and not recipient:GetIsStateFrozen()
end


Shared.LinkClassToMap("MedPack", MedPack.kMapName, networkVars, false)