-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\DetectableMixin.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Added relevancy options for marine detectables

DetectableMixin = CreateMixin(DetectableMixin)
DetectableMixin.type = "Detectable"

-- What entities have become dirty.
-- Flushed in the UpdateServer hook by DetectableMixin.OnUpdateServer
local DetectableMixinDirtyTable = { }

PrecacheAsset("cinematics/vfx_materials/detected.surface_shader")
local kDetectedMaterialName = PrecacheAsset("cinematics/vfx_materials/detected.material")
local kDetectEffectInterval = 3

local function UpdateSensorBlip(self)

    local blip
    if self.sensorBlipId ~= Entity.invalidId then
        blip = Shared.GetEntity(self.sensorBlipId)
    end

    -- Ignore alive if self doesn't have the Live mixin.
    local alive = true
    if HasMixin(self, "Live") then
        alive = self:GetIsAlive()
    end

    if not self:GetIsDetected() or not alive or (self.GetShowSensorBlip and not self:GetShowSensorBlip()) then

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

--
-- Call all dirty sensorblips
--
local gLastUpdate = 0
local kSensorUpdateInterval = 0
local function DetectableMixinOnUpdateServer()

    PROFILE("DetectableMixin:OnUpdateServer")

    if gLastUpdate + kSensorUpdateInterval > Shared.GetTime() then
        return
    end

    for _, entityId in ipairs(DetectableMixinDirtyTable) do

        local entity = Shared.GetEntity(entityId)
        if entity then
            UpdateSensorBlip(entity)
        end

    end

    DetectableMixinDirtyTable = { }
    gLastUpdate = Shared.GetTime()

end
Event.Hook("UpdateServer", DetectableMixinOnUpdateServer)

DetectableMixin.expectedCallbacks =
{
    -- Returns integer for team number
    GetTeamNumber = "",
    GetOrigin = "Entity origin (used to determine if near detector)",
    SetOrigin = "Sets the location of an entity",
    SetCoords = "Sets the location/angles of an entity"
}

DetectableMixin.optionalCallbacks =
{
    OnDetectedChange = "Called when self.detected changes.",
    GetIsDetectedOverride = "Override to allow implementing classes to have contextual override option (Ex: attached babblers)"
}

local kResetDetectionInterval = 1.5

DetectableMixin.networkVars =
{
    detected = "boolean"
}

local function DisableDetected(self)

    if self.timeWasDetected and (Shared.GetTime() - self.timeWasDetected) >= kResetDetectionInterval then
        self:SetDetected(false)
    end

    return true

end

function DetectableMixin:__initmixin()
    
    PROFILE("DetectableMixin:__initmixin")
    
    self.detected = false
    self.timeWasDetected = nil
    self.sensorBlipId = Entity.invalidId

    if Server then
        self:AddTimedCallback(DisableDetected, kResetDetectionInterval)
    elseif Client then

        self.timeLastDetectEffect = 0
        self.clientDetected = false

    end

end

function DetectableMixin:OnDestroy()

    table.removevalue(DetectableMixinDirtyTable, self:GetId())

    if self.sensorBlipId ~= Entity.invalidId and Shared.GetEntity(self.sensorBlipId) then

        DestroyEntity(Shared.GetEntity(self.sensorBlipId))
        self.sensorBlipId = Entity.invalidId

    end

end

function DetectableMixin:SetOrigin()
    table.insertunique(DetectableMixinDirtyTable, self:GetId())
end

function DetectableMixin:SetCoords()
    table.insertunique(DetectableMixinDirtyTable, self:GetId())
end

function DetectableMixin:OnKill()
    table.insertunique(DetectableMixinDirtyTable, self:GetId())
end

function DetectableMixin:GetIsDetected()
    if self.GetIsDetectedOverride then
        return self:GetIsDetectedOverride()
    end

    return self.detected
end

function DetectableMixin:SetDetected(state)

    if state ~= self.detected then

        table.insertunique(DetectableMixinDirtyTable, self:GetId())

        if self.OnDetectedChange then
            self:OnDetectedChange(state)
        end

        self.detected = state

    end

    if state then
        self.timeWasDetected = Shared.GetTime()
    else
        self.timeWasDetected = nil
    end

end

function DetectableMixin:OnUpdateRender()

    PROFILE("DetectableMixin:OnUpdateRender")
    
    if self:isa("Alien") and self:GetIsLocalPlayer() then
    
        local viewModelEnt = self:GetViewModelEntity()
        local viewModel = viewModelEnt and viewModelEnt:GetRenderModel()

        if viewModel then

            if not self.detectedMaterial then
                self.detectedMaterial = AddMaterial(viewModel, kDetectedMaterialName)
            end

            if self.clientDetected ~= self:GetIsDetected() then

                self.clientDetected = self:GetIsDetected()

                if self.clientDetected then
                    self.timeLastDetectEffect = Shared.GetTime()
                end

            end

            if self:GetIsDetected() and self.timeLastDetectEffect + kDetectEffectInterval < Shared.GetTime() then
                self.timeLastDetectEffect = Shared.GetTime()
            end

            self.detectedMaterial:SetParameter("timeDetected", self.timeLastDetectEffect)

        end

    end

end