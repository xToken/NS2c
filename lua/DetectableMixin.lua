// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\DetectableMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

DetectableMixin = CreateMixin( DetectableMixin )
DetectableMixin.type = "Detectable"

// What entities have become dirty.
// Flushed in the UpdateServer hook by DetectableMixin.OnUpdateServer
local DetectableMixinDirtyTable = { }
//
// Call all dirty sensorblips
//
local gLastUpdate = 0
local kSensorUpdateIntervall = 0
local function DetectableMixinOnUpdateServer()

    PROFILE("DetectableMixin:OnUpdateServer")
    
    if gLastUpdate + kSensorUpdateIntervall > Shared.GetTime() then
        return
    end

    for entityId, doUpdate in pairs(DetectableMixinDirtyTable) do
    
        if doUpdate == true then
        
            local entity = Shared.GetEntity(entityId)
            if entity then
                entity:_UpdateSensorBlip()
            end
            
        end
        
    end
    
    DetectableMixinDirtyTable = { }
    gLastUpdate = Shared.GetTime()
    
end

DetectableMixin.expectedCallbacks =
{
    // Returns integer for team number
    GetTeamNumber = "",
    GetOrigin = "Entity origin (used to determine if near detector)",
    SetOrigin = "Sets the location of an entity",
    SetCoords = "Sets the location/angles of an entity"
}

DetectableMixin.optionalCallbacks =
{
    OnDetectedChange = "Called when self.detected changes."
}

// Should be bigger then DetectorMixin:kUpdateDetectionInterval
DetectableMixin.kResetDetectionInterval = 3
DetectableMixin.kMaxBlips = 4

DetectableMixin.networkVars =
{
    detected = "private boolean",
    decloak = "private boolean"
}

function DetectableMixin:__initmixin()

    self.detected = false
    self.decloak = false
    self.timeSinceDetection = nil
    self.sensorBlipId = { }
    for i = 1, DetectableMixin.kMaxBlips do
        self.sensorBlipId[i] = Entity.invalidId
    end
end

function DetectableMixin:OnDestroy()

    DetectableMixinDirtyTable[self:GetId()] = nil

    for i = 1, DetectableMixin.kMaxBlips do
        if (self.sensorBlipId[i] ~= Entity.invalidId) and Shared.GetEntity(self.sensorBlipId[i]) then
        
            DestroyEntity(Shared.GetEntity(self.sensorBlipId[i]))
            self.sensorBlipId[i] = Entity.invalidId
            
        end
    end
    
end

function DetectableMixin:SetOrigin()
    DetectableMixinDirtyTable[self:GetId()] = true
end

function DetectableMixin:SetCoords()
    DetectableMixinDirtyTable[self:GetId()] = true
end

function DetectableMixin:OnKill()
    DetectableMixinDirtyTable[self:GetId()] = true
end

function DetectableMixin:GetIsDetected()
    return self.detected
end

function DetectableMixin:GetDecloaked()
    return self.decloak
end

function DetectableMixin:SetDetected(state, decloak)

    if state ~= self.detected then
    
        DetectableMixinDirtyTable[self:GetId()] = true
        
        if self.OnDetectedChange then
            self:OnDetectedChange(state)
        end
        
        self.detected = state
        if decloak then
            self.decloak = decloak
        end
        
    end
    
    if state then
        self.timeSinceDetection = 0
    end
    
end

local function SharedUpdate(self, deltaTime)

    if self.timeSinceDetection then
    
        self.timeSinceDetection = self.timeSinceDetection + deltaTime
        
        if self.timeSinceDetection >= DetectableMixin.kResetDetectionInterval then
            self:SetDetected(false, false)
        end
        
    end
    
end

if Server then

    function DetectableMixin:OnUpdate(deltaTime)
        SharedUpdate(self, deltaTime)
    end
    
    function DetectableMixin:OnProcessMove(input)
        SharedUpdate(self, input.time)
    end
    
    function DetectableMixin:_UpdateSensorBlip()
        local MaxBlips = 1
		if self:isa("Player") then
			local hasupg, level = GetHasEchoUpgrade(self)
			if hasupg and level > 0 then
				MaxBlips = level
			end
		end
        for i = 1, MaxBlips do
        
            local blip = nil
            if self.sensorBlipId[i] ~= Entity.invalidId then
                blip = Shared.GetEntity(self.sensorBlipId[i])
            end
            
            // Ignore alive if self doesn't have the Live mixin.
            local alive = true
            if HasMixin(self, "Live") then
                alive = self:GetIsAlive()
            end
            
            if not self:GetIsDetected() or not alive then
            
                if blip then
                
                    DestroyEntity(blip)
                    self.sensorBlipId[i] = Entity.invalidId
                    
                end
                
            else
            
                if not blip then
                
                    blip = CreateEntity(SensorBlip.kMapName)
                    self.sensorBlipId[i] = blip:GetId()
                    
                end
                
                blip:Update(self)
                
            end
        end
    end
    
end

Event.Hook("UpdateServer", DetectableMixinOnUpdateServer)