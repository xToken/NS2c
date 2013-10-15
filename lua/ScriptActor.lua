// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ScriptActor.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Base class for all visible entities in NS2. Players, weapons, structures, etc.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Adjusted to add basic buttons to all ScriptActors to prevent errors.
//Removed maturity check

Script.Load("lua/Globals.lua")
Script.Load("lua/ExtentsMixin.lua")
Script.Load("lua/OwnerMixin.lua")
Script.Load("lua/TechMixin.lua")
Script.Load("lua/TargetMixin.lua")
Script.Load("lua/UsableMixin.lua")
Script.Load("lua/EffectsMixin.lua")
Script.Load("lua/RelevancyMixin.lua")

if Server then
    Script.Load("lua/InvalidOriginMixin.lua")
end

class 'ScriptActor' (Entity)

ScriptActor.kMapName = "scriptactor"

if Server then
    Script.Load("lua/ScriptActor_Server.lua", true)
elseif Client then
    Script.Load("lua/ScriptActor_Client.lua", true)
end

local networkVars =
{
    // Id used to look up precached string representing room location ("Marine Start")
    // not certain about the maximum number of cached strings
    locationId = "resource",
}

AddMixinNetworkVars(TechMixin, networkVars)

local kMass = 100

// Called right after an entity is created on the client or server. This happens through Server.CreateEntity, 
// or when a server-created object is propagated to client. 
function ScriptActor:OnCreate()

    Entity.OnCreate(self)
    
    // This field is not synchronized over the network.
    self.creationTime = Shared.GetTime()
    
    InitMixin(self, EffectsMixin)
    InitMixin(self, TechMixin)
    
    self.attachedId = Entity.invalidId
    
    self.locationId = 0
    
    self.pathingFlags = 0
    
    if Server then
    
        self.locationEntId = Entity.invalidId
        
        InitMixin(self, InvalidOriginMixin)
        InitMixin(self, RelevancyMixin)
        
        // Ownership only exists on the Server.
        InitMixin(self, OwnerMixin)
        
        self.selectedCount = 0
        self.hotgroupedCount = 0
        
    end
    
    InitMixin(self, ExtentsMixin)
    InitMixin(self, TargetMixin)
    InitMixin(self, UsableMixin)
    
    self:SetUpdates(true)
    self:SetPropagate(Entity.Propagate_Mask)
    self:SetRelevancyDistance(kMaxRelevancyDistance)
    
end

// Called when entity is created via CreateEntity(), after OnCreate(). Team number and origin will be set properly before it's called.
// Also called on client each time the entity gets created locally, due to proximity. This won't be called on the server for 
// pre-placed map entities. Generally reset-type functionality will want to be placed in here and then called inside :Reset().
function ScriptActor:OnInitialized()

    Entity.OnInitialized(self)
    self:ComputeLocation()
    
end

/**
 * Returns the time which this ScriptActor was created at.
 */
function ScriptActor:GetCreationTime()
    return self.creationTime
end

if Server then

    function ScriptActor:SetLocationEntity(location)
        self.locationEntId = location and location:GetId() or Entity.invalidId
    end

    function ScriptActor:GetLocationEntity()
        return Shared.GetEntity(self.locationEntId)
    end

end

function ScriptActor:ComputeLocation()

    if Server then
    
        local location = GetLocationForPoint(self:GetOrigin())
        local locationName = location and location:GetName() or ""
        self:SetLocationName(locationName, true)
        
        // dynamic props are possibly not inside a location     
        self:SetLocationEntity(location)
        
    end

end

// Called when the game ends and a new game begins (or when the reset command is typed in console).
function ScriptActor:Reset()
    self:ComputeLocation()
end

function ScriptActor:OnReset()
end

// If false, then MoveToTarget() projects entity down to floor
function ScriptActor:GetIsFlying()
    return false
end

// Return tech ids that represent research or actions for this entity in specified menu. Parameter is kTechId.RootMenu for
// default menu or a entity-defined menu id for a sub-menu. Return nil if this actor doesn't recognize a menu of that type.
// Used for drawing icons in selection menu and also for verifying which actions are valid for entities and when (ie, when
// a SiegeCannon can siege, or when a unit has enough energy to perform an action, etc.)
// Return list of 8 tech ids, represnting the 2nd and 3rd row of the 4x3 build icons.
function ScriptActor:GetTechButtons(techId)
    return nil
end

function ScriptActor:GetCost()
    return LookupTechData(self:GetTechId(), kTechDataCostKey, 0)
end

// Allows entities to specify whether they can perform a specific research, activation, buy action, etc. If entity is
// busy deploying, researching, etc. it can return false. Pass in the player who is would be buying the tech.
// techNode could be nil for activations that aren't added to tech tree.
function ScriptActor:GetTechAllowed(techId, techNode, player)

    local allowed =  GetIsUnitActive(self)
    local canAfford = true
    
    if not player:GetGameStarted() or techNode == nil then
    
        allowed = false
        canAfford = false
        
    elseif techId == kTechId.Recycle and HasMixin(self, "Recycle") then

        allowed = not HasMixin(self, "Live") or self:GetIsAlive()
        canAfford = allowed
        
    elseif techId == kTechId.Cancel then

        allowed = true
        canAfford = true
        
    elseif techNode:GetIsUpgrade() then
    
        canAfford = techNode:GetCost() <= player:GetTeamResources()
        allowed = HasMixin(self, "Research") and not self:GetIsResearching() and allowed
        
    elseif techNode:GetIsEnergyManufacture() or techNode:GetIsEnergyBuild() then
        
        local energy = 0
        if HasMixin(self, "Energy") then
            energy = self:GetEnergy()
        end
        
        local canManufacture = not techNode:GetIsEnergyManufacture() or (HasMixin(self, "Research") and not self:GetIsResearching())
        
        canAfford = techNode:GetCost() <= energy
        allowed = canManufacture and canAfford and allowed
    
    // If tech is research
    elseif techNode:GetIsResearch() then
    
        canAfford = techNode:GetCost() <= player:GetTeamResources()
        allowed = HasMixin(self, "Research") and self:GetResearchTechAllowed(techNode) and not self:GetIsResearching() and allowed

    // If tech is action or buy action
    elseif techNode:GetIsAction() or techNode:GetIsBuy() then
    
        canAfford = player:GetResources() >= techNode:GetCost()
        
    // If tech is activation
    elseif techNode:GetIsActivation() then
        
        canAfford = techNode:GetCost() <= player:GetTeamResources()
        allowed = self:GetActivationTechAllowed(techId) and allowed
        
    // If tech is build
    elseif techNode:GetIsBuild() then
    
        canAfford = player:GetTeamResources() >= techNode:GetCost()
        
    elseif techNode:GetIsManufacture() then
    
        canAfford = player:GetTeamResources() >= techNode:GetCost()
        allowed = HasMixin(self, "Research") and not self:GetIsResearching() and allowed
    
    end
    
    return allowed, canAfford
    
end

function ScriptActor:GetPlayIdleSound()
    return GetIsUnitActive(self)
end

// Children can decide not to allow certain activations at certain times (energy cost already considered)
function ScriptActor:GetActivationTechAllowed(techId)
    return true
end

function ScriptActor:GetMass()
    return kMass
end

// Returns true if entity's build or health circle should be drawn (ie, if it doesn't appear to be at full health or needs building)
function ScriptActor:SetBuildHealthMaterial(entity)
    return false
end

function ScriptActor:GetViewOffset()
    return Vector(0, 0, 0)
end

function ScriptActor:GetDescription()
    return GetDisplayNameForTechId(self:GetTechId(), "<no description>")
end

function ScriptActor:GetVisualRadius()
    return LookupTechData(self:GetTechId(), kVisualRange, nil)
end

// Something isn't working right here - has to do with references to points or vector
function ScriptActor:GetViewCoords()
    
    local viewCoords = self:GetViewAngles():GetCoords()   
    viewCoords.origin = self:GetEyePos()
    return viewCoords

end

function ScriptActor:GetCanBeUsed(player, useSuccessTable)

    if HasMixin(player, "Live") and not player:GetIsAlive() then
        useSuccessTable.useSuccess = false
    end
    
    if GetIsVortexed(self) or GetIsVortexed(player) then
        useSuccessTable.useSuccess = false
    end
    
end

function ScriptActor:GetUsablePoints()
    return nil
end

function ScriptActor:ForEachChild(functor)
    ForEachChildOfType(self, nil, functor)
end

function ScriptActor:GetAttached()

    local attached = nil
    
    if(self.attachedId ~= Entity.invalidId) then
        attached = Shared.GetEntity(self.attachedId)
    end
    
    return attached
    
end

function ScriptActor:GetDeathIconIndex()
    return kDeathMessageIcon.None
end

// Pass entity and proposed location, returns true if entity can go there without colliding with something
function ScriptActor:SpaceClearForEntity(location)
    // TODO: Collide model with world when model collision working
    return true
end

// Called when a player does a trace capsule and hits a script actor. Players don't have physics
// data currently, only hitboxes and trace capsules. If they did have physics data, they would 
// collide with themselves, so we have this instead. 
function ScriptActor:OnCapsuleTraceHit(entity)
end

function ScriptActor:GetLocationId()
    return self.locationId
end

function ScriptActor:GetLocationName()

    local locationName = ""
    
    if self.locationId ~= 0 then
        locationName = Shared.GetString(self.locationId)
    end
    
    return locationName
    
end

function ScriptActor:OnLocationChange(locationName)
end

Shared.LinkClassToMap("ScriptActor", ScriptActor.kMapName, networkVars)