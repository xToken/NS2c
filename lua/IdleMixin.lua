// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\IdleMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Shows idle effects / sounds.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

IdleMixin = CreateMixin(IdleMixin)
IdleMixin.type = "Idle"

local kOneShotSoundInterval = 6

// idle sound definitions

local kIdleSoundNames = {}
kIdleSoundNames["Hive"] = "sound/NS2.fev/alien/structures/hive_idle" 
kIdleSoundNames["Crag"] = "sound/NS2.fev/alien/structures/crag/idle" 
kIdleSoundNames["Shift"] = "sound/NS2.fev/alien/structures/shift/idle"
kIdleSoundNames["Shade"] = "sound/NS2.fev/alien/structures/shade/idle" 
kIdleSoundNames["Whip"] = "sound/NS2.fev/alien/structures/whip/idle"
kIdleSoundNames["Harvester"] = "sound/NS2.fev/alien/structures/harvester_active"
kIdleSoundNames["Hydra"] = "sound/NS2.fev/alien/structures/hydra/idle"
    
//kIdleSoundNames["Skulk"] = "sound/NS2.fev/alien/skulk/idle"
kIdleSoundNames["Gorge"] = "sound/NS2.fev/alien/gorge/idle"
kIdleSoundNames["Lerk"] = "sound/NS2.fev/alien/lerk/idle"
kIdleSoundNames["Fade"] = "sound/NS2.fev/alien/skulk/idle"
kIdleSoundNames["Onos"] = "sound/NS2.fev/alien/onos/idle"

kIdleSoundNames["SiegeCannon"] = "sound/NS2.fev/marine/structures/arc/idle"
kIdleSoundNames["PhaseGate"] = "sound/NS2.fev/marine/structures/phase_gate_active"
kIdleSoundNames["InfantryPortal"] = "sound/NS2.fev/marine/structures/infantry_portal_active"
kIdleSoundNames["Extractor"] = "sound/NS2.fev/marine/structures/extractor_active"
kIdleSoundNames["CommandStation"] = "sound/NS2.fev/marine/structures/command_station_active"
kIdleSoundNames["Armory"] = "sound/NS2.fev/marine/structures/armory_idle"
//kIdleSoundNames["PowerPoint"] = "sound/NS2.fev/marine/power_node/idle"


local kIdleOneShotSoundNames = {}
kIdleOneShotSoundNames["Fade"] = "sound/ns2c.fev/ns2c/alien/fade/move"
kIdleOneShotSoundNames["Observatory"] = "sound/NS2.fev/marine/structures/observatory_scan"

for className, path in pairs(kIdleSoundNames) do
    PrecacheAsset(path)
end

for className, path in pairs(kIdleOneShotSoundNames) do
    PrecacheAsset(path)
end

IdleMixin.expectedCallbacks = 
{
    GetPlayIdleSound = "Return if in idle state."
}

IdleMixin.optionalCallbacks =
{
    GetIdleSoundInterval = "Return optionally a different interval to use."
}

IdleMixin.networkVars =
{
    playIdleSound = "boolean"
}

function IdleMixin:__initmixin()

    if Server then
    
        self.playIdleSound = true
        /*
        local assetPath = kIdleSoundNames[self:GetClassName()]
        if assetPath and Shared.GetSoundIndex(assetPath) ~= 0 then
        
            local assetLength = GetSoundEffectLength(assetPath)
            if assetLength >= 0 then
                Print("Warning: Idle sound %s isn't looping.", assetPath)
            end
            
        end
        */
        
    end
    
    if Client then
    
        self.timeLastIdleOneShotSound = Shared.GetTime()
        self.oneShotSoundName = kIdleOneShotSoundNames[self:GetClassName()]
        
        self.playIdleSoundClient = nil
        
        local assetPath = kIdleSoundNames[self:GetClassName()]        
        if assetPath then
        
            local assetIndex = Shared.GetSoundIndex(assetPath)            
            if assetIndex ~= 0 then
                
                self.idleSoundEffectInstance = Client.CreateSoundEffect(assetIndex)
                self.idleSoundEffectInstance:SetParent(self:GetId())
                self.idleSoundEffectInstance:SetPositional(true)
                
            else
                Print("Warning: Idle effect %s wasn't precached.", assetPath)
            end

        end
        
    end
    
end

if Client then

    function IdleMixin:OnDestroy()

        self.playIdleSoundClient = false

        if self.idleSoundEffectInstance then
        
            Client.DestroySoundEffect(self.idleSoundEffectInstance)
            self.idleSoundEffectInstance = nil
            
        end 

    end

end

local function GetIdleSoundVolume(self)

    local volume = 1
    if self.GetEffectParams then
    
        local tableParams = {}
        self:GetEffectParams(tableParams)
        volume = tableParams[kEffectParamVolume] or 1
        
    end
    
    return volume
    
end

local function SharedUpdate(self, deltaTime)

    if Server then
    
        self.playIdleSound = self:GetPlayIdleSound()

    elseif Client then
    
        if self.oneShotSoundName then
        
            local interval = self.GetIdleSoundInterval ~= nil and self:GetIdleSoundInterval()
            interval = interval or kOneShotSoundInterval
            
            if self.playIdleSound and self.timeLastIdleOneShotSound + interval <= Shared.GetTime() then
            
                StartSoundEffectOnEntity(self.oneShotSoundName, self, GetIdleSoundVolume(self), nil)
                self.timeLastIdleOneShotSound = Shared.GetTime()
                
            end
        
        end

        if self.idleSoundEffectInstance then
    
            if self.playIdleSoundClient ~= self.playIdleSound then
            
                if self.playIdleSound then

                    self.idleSoundEffectInstance:Start()
                    self.idleSoundEffectInstance:SetVolume(GetIdleSoundVolume(self)) 
             
                elseif not self.playIdleSound then
                    self.idleSoundEffectInstance:Stop()  
                end
                
                self.playIdleSoundClient = self.playIdleSound
            
            end
        
        end

    end
    
end

function IdleMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end

function IdleMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end 

function IdleMixin:OnProcessSpectate(deltaTime)
    SharedUpdate(self, deltaTime)
end
