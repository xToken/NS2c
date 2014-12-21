// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\LOSMixin.lua    
//    
//    Created by:   Andrew Spiering (andrew@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

//NS2c
//Addition of Ghost upgrade

LOSMixin = CreateMixin(LOSMixin)

LOSMixin.type = "LOS"

LOSMixin.expectedMixins =
{
    Team = "Needed for calls to GetTeamNumber().",
    EntityChange = "Needed for the OnEntityChange() callback used below."
}

LOSMixin.optionalCallbacks =
{
    OverrideCheckVision = "Return true if this entity can see, false otherwise."
}

local kUnitMaxLOSDistance = kPlayerLOSDistance
local kUnitMinLOSDistance = kStructureLOSDistance

// How often to look for nearby enemies.
local kLookForEnemiesRate = 0.5

local kLOSTimeout = 1

LOSMixin.networkVars =
{
    sighted = "boolean",
    visibleClient = "boolean"
}

local function UpdateLOS(self)

    local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
    
    if self.sighted then
        mask = bit.bor(mask, kRelevantToTeam1Commander, kRelevantToTeam2Commander)
    elseif self:GetTeamNumber() == 1 then
        mask = bit.bor(mask, kRelevantToTeam1Commander)
    elseif self:GetTeamNumber() == 2 then
        mask = bit.bor(mask, kRelevantToTeam2Commander)
    end
    
    self:SetExcludeRelevancyMask(mask)
    self.visibleClient = self.sighted
    
    if self.lastSightedState ~= self.sighted then
    
        if self.OnSighted then
            self:OnSighted(self.sighted)
        end
        
        self.lastSightedState = self.sighted
        
    end
    
end

function LOSMixin:__initmixin()

    if Server then
    
        self.sighted = false
        self.lastTimeLookedForEnemies = 0
        self.updateLOS = true
        self.timeLastLOSUpdate = 0
        self.dirtyLOS = true
        self.timeLastLOSDirty = 0
        self.prevLOSorigin = Vector(0,0,0)
    
        self:SetIsSighted(false)
        UpdateLOS(self)
        self.oldSighted = true
        self.lastViewerId = Entity.invalidId
        
    end
    
end

function LOSMixin:GetIsSighted()
    return self.visibleClient
end

// Remainder is server only.
if Server then

    /**
     * Force the relevancy mask to be updated, so that it will be relevant to members of the same team.
     */
    function LOSMixin:OnTeamChange()
    
        UpdateLOS(self)
        self:SetIsSighted(false)
        
    end
    
    local function GetCanSee(viewer, entity)
    
        // SA: We now allow marines to build ghosts anywhere - so make sure they're blind. Otherwise they can sorta scout.
        if HasMixin(viewer, "GhostStructure") then
            return false
        end
    
        // If the other entity is not visible then we cannot see it.
        if not entity:GetIsVisible() then
            return false
        end
        
        // We don't care to sight dead things.
        local dead = HasMixin(entity, "Live") and not entity:GetIsAlive()
        if dead then
            return false
        end
        
        local viewerDead = HasMixin(viewer, "Live") and not viewer:GetIsAlive()
        if viewerDead then
            return false
        end
        
        // Anything cloaked or camoflaged is invisible to us.
        if (HasMixin(entity, "Cloakable") and entity:GetIsCloaked()) or
           (entity.GetIsCamouflaged and entity:GetIsCamouflaged()) then
            return false
        end
        
        // Check if this entity is beyond our vision radius.
        local maxDist = viewer:GetVisionRadius()
        local dist = (entity:GetOrigin() - viewer:GetOrigin()):GetLengthSquared()
        if dist > (maxDist * maxDist) then
            return false
        end
        
        // If close enough to the entity, we see it no matter what.
        if dist < (kUnitMinLOSDistance * kUnitMinLOSDistance) then
            return true
        end
        
        return GetCanSeeEntity(viewer, entity)
        
    end
    
    local function CheckIsAbleToSee(viewer)
    
        if viewer:isa("Structure") and not viewer:GetIsBuilt() then
            return false
        end
        
        if HasMixin(viewer, "Live") and not viewer:GetIsAlive() then
            return false
        end
        
        if viewer.OverrideCheckVision then
            return viewer:OverrideCheckVision()
        end
        
        return true
        
    end
    
    local function LookForEnemies(self)
    
        PROFILE("LOSMixin:LookForEnemies")
        
        if not CheckIsAbleToSee(self) then
            return
        end
        
        local entities = Shared.GetEntitiesWithTagInRange("LOS", self:GetOrigin(), self:GetVisionRadius())
        
        for e = 1, #entities do
        
            local otherEntity = entities[e]
            
            if not otherEntity.sighted then
            
                // Only check sight for enemy entities.
                local areEnemies = otherEntity:GetTeamNumber() == GetEnemyTeamNumber(self:GetTeamNumber())
                if areEnemies and GetCanSee(self, otherEntity) then
                    otherEntity:SetIsSighted(true, self)
                end
                
            end
            
        end
        
    end
    
    local function UpdateSelfSighted(self)
    
        // Marines are seen if parasited or on infestation.
        // Soon make this something other Mixins can hook into instead of hardcoding GameEffects here.
        local seen = false
        
        if HasMixin(self, "GameEffects") then
            seen = GetIsParasited(self)
        end
        
        local lastViewer = self:GetLastViewer()
        
        if not seen and lastViewer then
        
            // prevents flickering, SiegeCannons for example would lose their target
            seen = GetCanSee(lastViewer, self)
            
        end
        
        self:SetIsSighted(seen, lastViewer)
        
    end
    
    local function MarkNearbyDirty(self)
    
        self.updateLOS = true
        
        for _, entity in ipairs(GetEntitiesWithMixinForTeamWithinRange("LOS", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kUnitMaxLOSDistance)) do
            entity.updateLOS = true
        end
        
    end
    
    local function SharedUpdate(self, deltaTime)
    
        PROFILE("LOS:SharedUpdate")
        
        // Prevent entities from being sighted before the game starts.
        if not GetGamerules():GetGameStarted() then
            return
        end
        
        local now = Shared.GetTime()
        if self.dirtyLOS and self.timeLastLOSDirty + 0.2 < now then
        
            MarkNearbyDirty(self)
            self.dirtyLOS = false
            self.timeLastLOSDirty = now
            
        end
        
        if self.updateLOS and self.timeLastLOSUpdate + 0.2 < now then
        
            UpdateSelfSighted(self)
            LookForEnemies(self)
            
            self.updateLOS = false
            self.timeLastLOSUpdate = now
            
        end
        
        if self.oldSighted ~= self.sighted then
        
            if self.sighted then
            
                UpdateLOS(self)
                self.timeUpdateLOS = nil
                
            else
                self.timeUpdateLOS = Shared.GetTime() + kLOSTimeout
            end
            
            self.oldSighted = self.sighted
            
        end
        
        if self.timeUpdateLOS and self.timeUpdateLOS < Shared.GetTime() then
        
            UpdateLOS(self)
            self.timeUpdateLOS = nil
            
        end
        
    end
    
    function LOSMixin:OnUpdate(deltaTime)
        SharedUpdate(self, deltaTime)
    end
    
    function LOSMixin:OnProcessMove(input)
        SharedUpdate(self, input.time)
    end
    
    // this causes an issue: when the distance is too big (going to ready room, moving through phase gate) MarkNearbyDirty(self) will miss previous revealed entities. 
    function LOSMixin:SetOrigin(origin)
    
        // matso: optimization; SetOrigin is called A LOT, so we just add us to an update-los queue when we move enough
        // we'll get flushed now and then
        if not self.dirtyLOS and (self.prevLOSorigin - origin):GetLengthSquared() > 0.3 then
        
            self.dirtyLOS = true
            self.prevLOSorigin = Vector(origin)
            
        end
        
    end
    
    function LOSMixin:SetCoords(coords)
    
        if not self.dirtyLOS and self.prevLOSCoords ~= coords then
        
            self.dirtyLOS = true
            self.prevLOSCoords = Coords(coords)
            
        end
        
    end
    
    function LOSMixin:SetAngles(angles)
    
        local yaw = math.floor(angles.yaw * 100) / 100
        
        if not self.dirtyLOS and self.prevLOSYaw ~= yaw then
        
            self.dirtyLOS = true
            self.prevLOSYaw = yaw
            
        end
        
    end
    
    function LOSMixin:SetViewAngles(angles)
    
        local yaw = math.floor(angles.yaw * 100) / 100
        
        if not self.dirtyLOS and self.prevViewLOSYaw ~= yaw then
        
            self.dirtyLOS = true
            self.prevViewLOSYaw = yaw
            
        end
        
    end
    
    function LOSMixin:OnParasited()
    
         if not self.dirtyLOS and not self.sighted then
            self.updateLOS = true
        end
        
    end
    
    function LOSMixin:OnKill()
        MarkNearbyDirty(self)
    end
    
    function LOSMixin:OnDestroy()
        MarkNearbyDirty(self)
    end
    
    function LOSMixin:GetVisionRadius()
    
        if self.OverrideVisionRadius then
            return self:OverrideVisionRadius()
        end
        
        return kUnitMinLOSDistance
        
    end
    
    function LOSMixin:SetIsSighted(sighted, viewer)
    
        PROFILE("LOSMixin:SetIsSighted")
        
        self.sighted = sighted
        
        if viewer then
        
            if not HasMixin(viewer, "LOS") then
                error(string.format("%s: %s added as a viewer without having LOS mixin", ToString(self), ToString(viewer)))
            end
            
            self.lastViewerId = viewer:GetId()
            
        end
        
    end
    
    function LOSMixin:OnEntityChange(oldId)
    
        if oldId == self.lastViewerId then
            self.lastViewerId = Entity.invalidId
        end
        
    end
    
    function LOSMixin:GetLastViewer()

        if self.lastViewerId and self.lastViewerId ~= Entity.invalidId then
        
            local viewer = Shared.GetEntity(self.lastViewerId)
            
            if viewer and not HasMixin(viewer, "LOS") then
                error(string.format("%s: %s added as a viewer without having LOS mixin", ToString(self), ToString(viewer)))
            end
            
            return viewer
            
        end
        
    end

end