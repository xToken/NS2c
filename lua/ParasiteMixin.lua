// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ParasiteMixin.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Changes to allow parasite of structures and visibility changes

ParasiteMixin = CreateMixin( ParasiteMixin )
ParasiteMixin.type = "ParasiteAble"

ParasiteMixin.expectedMixins =
{
    Live = "ParasiteMixin makes only sense if this entity can take damage (has LiveMixin).",
}

ParasiteMixin.optionalCallbacks =
{
    GetCanBeParasitedOverride = "Return true or false if the entity has some specific conditions under which parasite is allowed."
}

ParasiteMixin.networkVars =
{
    parasited = "boolean"
}

local ParasiteMixinDirtyTable = { }

local function UpdateSensorBlip(self)

    local blip = nil
    if self.sensorBlipId ~= Entity.invalidId then
        blip = Shared.GetEntity(self.sensorBlipId)
    end
    
    // Ignore alive if self doesn't have the Live mixin.
    local alive = true
    if HasMixin(self, "Live") then
        alive = self:GetIsAlive()
    end
    
    if not self:GetIsParasited() or not alive then
    
        if blip then
        
            DestroyEntity(blip)
            self.sensorBlipId = Entity.invalidId
            
        end
        
    else
    
        if not blip then
        
            blip = CreateEntity(SensorBlip.kMapName)
            blip:UpdateRelevancy(GetEnemyTeamNumber(self:GetTeamNumber()))
            self.sensorBlipId = blip:GetId()
            
        end
        
        blip:Update(self)
        
    end
    
end

//
// Call all dirty sensorblips
//
local gLastUpdate = 0
local kSensorUpdateInterval = 0
local function DetectableMixinOnUpdateServer()

    PROFILE("DetectableMixin:OnUpdateServer")
    
    if gLastUpdate + kSensorUpdateInterval > Shared.GetTime() then
        return
    end

    for entityId, doUpdate in pairs(ParasiteMixinDirtyTable) do
    
        if doUpdate == true then
        
            local entity = Shared.GetEntity(entityId)
            if entity then
                UpdateSensorBlip(entity)
            end
            
        end
        
    end
    
    ParasiteMixinDirtyTable = { }
    gLastUpdate = Shared.GetTime()
    
end
Event.Hook("UpdateServer", DetectableMixinOnUpdateServer)

function ParasiteMixin:__initmixin()

    if Server then
        self.timeParasited = 0
        self.parasiteduration = 0
        self.parasited = false
    end
    self.sensorBlipId = Entity.invalidId
    
end

function ParasiteMixin:OnTakeDamage(damage, attacker, doer, point, damageType)

    if doer and doer:isa("Parasite") and GetAreEnemies(self, attacker) then
        self:SetParasited(attacker)
    end

end

function ParasiteMixin:SetParasited(fromPlayer, duration, visible)

    if Server then

        if not self.GetCanBeParasitedOverride or self:GetCanBeParasitedOverride() then
        
            if not self.parasited and self.OnParasited then
            
                self:OnParasited()
                
                if fromPlayer and HasMixin(fromPlayer, "Scoring") and visible then
                    fromPlayer:AddScore(1)
                end
                
            end
            
            ParasiteMixinDirtyTable[self:GetId()] = true
        
            self.timeParasited = Shared.GetTime()
            self.parasited = true

        end
    
    end

end

function ParasiteMixin:OnDestroy()

    ParasiteMixinDirtyTable[self:GetId()] = nil
    if self.sensorBlipId ~= Entity.invalidId and Shared.GetEntity(self.sensorBlipId) then
    
        DestroyEntity(Shared.GetEntity(self.sensorBlipId))
        self.sensorBlipId = Entity.invalidId
        
    end
    
end

function ParasiteMixin:GetIsParasited()
    return self.parasited
end

function ParasiteMixin:RemoveParasite()
    self.parasited = false
    ParasiteMixinDirtyTable[self:GetId()] = true
end

function ParasiteMixin:SetOrigin()
    ParasiteMixinDirtyTable[self:GetId()] = true
end

function ParasiteMixin:SetCoords()
    ParasiteMixinDirtyTable[self:GetId()] = true
end

function ParasiteMixin:OnKill()
    ParasiteMixinDirtyTable[self:GetId()] = true
end