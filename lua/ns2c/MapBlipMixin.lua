-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\MapBlipMixin.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com)
--    Modified by: Mats Olsson (mats.olsson@matsotech.se)
--
-- Creates a mapblip for an entity that may have one.
--
-- Also marks a mapblip as dirty for later updates if it changes, by
-- listening on SetLocation, SetAngles and SetSighted calls.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Removal of powerpoint and cysts

MapBlipMixin = CreateMixin( MapBlipMixin )
MapBlipMixin.type = "MapBlip"

--
-- Listen on the state that the mapblip depends on
--
MapBlipMixin.expectedCallbacks =
{
    SetOrigin = "Sets the location of an entity",
    SetAngles = "Sets the angles of an entity",
    SetCoords = "Sets both both location and angles"
}

MapBlipMixin.optionalCallbacks =
{
    GetDestroyMapBlipOnKill = "Return true to destroy map blip when units is killed.",
    OnGetMapBlipInfo = "Override for getting the Map Blip Info",
}

-- What entities have become dirty.
-- Flushed in the UpdateServer hook by MapBlipMixin.OnUpdateServer
local mapBlipMixinDirtyTable = { }

--
-- Update all dirty mapblips
--
local function MapBlipMixinOnUpdateServer()

    PROFILE("MapBlipMixin:OnUpdateServer")

    local updated = {} --Keep track of ents we allready updated
    for _, entityId in ipairs(mapBlipMixinDirtyTable) do

        if not updated[entityId] then
            local entity = Shared.GetEntity(entityId)
            local mapBlip = entity and entity.mapBlipId and Shared.GetEntity(entity.mapBlipId)

            if mapBlip then
                mapBlip:Update()
            end

            updated[entityId] = true
        end

    end

    mapBlipMixinDirtyTable = { }

end

local function CreateMapBlip(self, blipType, blipTeam, _)

    local mapName = self:isa("Player") and PlayerMapBlip.kMapName or MapBlip.kMapName

    local mapBlip = Server.CreateEntity(mapName)
    -- This may fail if there are too many entities.
    if mapBlip then

        mapBlip:SetOwner(self:GetId(), blipType, blipTeam)
        self.mapBlipId = mapBlip:GetId()

    end

end

function MapBlipMixin:__initmixin()
    
    PROFILE("MapBlipMixin:__initmixin")
    
    assert(Server)

    -- Check if the new entity should have a map blip to represent it.
    local success, blipType, blipTeam, isInCombat = self:GetMapBlipInfo()
    if success then
        CreateMapBlip(self, blipType, blipTeam, isInCombat)
    end

end

--
-- Intercept the functions that changes the state the mapblip depends on
--
function MapBlipMixin:SetOrigin()
    table.insert(mapBlipMixinDirtyTable, self:GetId())
end

function MapBlipMixin:SetAngles()
    table.insert(mapBlipMixinDirtyTable, self:GetId())
end

function MapBlipMixin:SetCoords()
    table.insert(mapBlipMixinDirtyTable, self:GetId())
end

function MapBlipMixin:OnEnterCombat()
    table.insert(mapBlipMixinDirtyTable, self:GetId())
end

function MapBlipMixin:OnLeaveCombat()
    table.insert(mapBlipMixinDirtyTable, self:GetId())
end

function MapBlipMixin:MarkBlipDirty()
    table.insert(mapBlipMixinDirtyTable, self:GetId())
end

function MapBlipMixin:OnConstructionComplete()
    table.insert(mapBlipMixinDirtyTable, self:GetId())
end

function MapBlipMixin:OnPowerOn()
    table.insert(mapBlipMixinDirtyTable, self:GetId())
end

function MapBlipMixin:OnPowerOff()
    table.insert(mapBlipMixinDirtyTable, self:GetId())
end

function MapBlipMixin:OnPhaseGateEntry(destinationOrigin)
    table.insert(mapBlipMixinDirtyTable, self:GetId())
end

function MapBlipMixin:OnUseGorgeTunnel(destinationOrigin)
    table.insert(mapBlipMixinDirtyTable, self:GetId())
end

function MapBlipMixin:OnPreBeacon()
    table.insert(mapBlipMixinDirtyTable, self:GetId())
end

function MapBlipMixin:OnSighted(sighted)

    -- because sighted is always set during each LOS calc, we need to keep track of
    -- what the previous value was so we don't mark it dirty unnecessarily
    if self.previousSighted ~= sighted then
        self.previousSighted = sighted
        table.insert(mapBlipMixinDirtyTable, self:GetId())
    end

end

function MapBlipMixin:GetMapBlipInfo()

    if self.OnGetMapBlipInfo then
        return self:OnGetMapBlipInfo()
    end

    local success = false
    local blipType = kMinimapBlipType.Undefined
    local blipTeam = -1
    local isAttacked = HasMixin(self, "Combat") and self:GetIsInCombat()
    local isParasited = HasMixin(self, "ParasiteAble") and self:GetIsParasited()

    -- World entities
    if self:isa("Door") then
        blipType = kMinimapBlipType.Door
    elseif self:isa("ResourcePoint") then
        blipType = kMinimapBlipType.ResourcePoint
    elseif self:isa("TechPoint") then
        blipType = kMinimapBlipType.TechPoint
    -- Everything else that is supported by kMinimapBlipType.
    elseif self:isa("HeavyArmorMarine") then
        blipType = kMinimapBlipType.Exo
    elseif self:GetIsVisible() then

        if rawget( kMinimapBlipType, self:GetClassName() ) ~= nil then
            blipType = kMinimapBlipType[self:GetClassName()]
        else
            Shared.Message( "Element '"..tostring(self:GetClassName()).."' doesn't exist in the kMinimapBlipType enum" )
        end

        blipTeam = HasMixin(self, "Team") and self:GetTeamNumber() or kTeamReadyRoom

    end

    if blipType ~= 0 then
        success = true
    end

    return success, blipType, blipTeam, isAttacked, isParasited

end

function MapBlipMixin:DestroyBlip()

    if self.mapBlipId and Shared.GetEntity(self.mapBlipId) then

        DestroyEntity(Shared.GetEntity(self.mapBlipId))
        self.mapBlipId = nil

    end

end

function MapBlipMixin:OnKill()

    if not self.GetDestroyMapBlipOnKill or self:GetDestroyMapBlipOnKill() then
        self:DestroyBlip()
    end

end

function MapBlipMixin:OnDestroy()
    self:DestroyBlip()
end

Event.Hook("UpdateServer", MapBlipMixinOnUpdateServer)