// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//    
// lua\BuildUtility.lua
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local function CheckBuildTechAvailable(techId, teamNumber)

    local techTree = GetTechTree(teamNumber)
    local techNode = techTree:GetTechNode(techId)
    assert(techNode)
    return techNode:GetAvailable()
    
end

local function GetPathingRequirementsMet(position, extents)

    local noBuild = Pathing.GetIsFlagSet(position, extents, Pathing.PolyFlag_NoBuild)
    local walk = Pathing.GetIsFlagSet(position, extents, Pathing.PolyFlag_Walk)
    return not noBuild and walk
    
end

local function GetBuildAttachRequirementsMet(techId, position, teamNumber, snapRadius)

    local legalBuild = true
    local attachEntity = nil
    
    local legalPosition = Vector(position)
    
    // Make sure we're within range of something that's required (ie, an infantry portal near a command station)
    local attachRange = LookupTechData(techId, kStructureAttachRange, 0)
    
    local filterFunction = GetEntitiesForTeamWithinRange
    
    local buildNearClass = LookupTechData(techId, kStructureBuildNearClass)
    if buildNearClass then
        
        local ents = {}
        
        // Handle table of class names
        if type(buildNearClass) == "table" then
            for index, className in ipairs(buildNearClass) do
                table.copy(filterFunction(className, teamNumber, position, attachRange), ents, true)
            end
        else
            ents = filterFunction(buildNearClass, teamNumber, position, attachRange)
        end
        
        legalBuild = (table.count(ents) > 0)
        
    end
    
    local attachId = LookupTechData(techId, kStructureAttachId)
    // prevent creation if this techId requires another techId in range
    if attachId then
    
        local supportingTechIds = {}
        
        if type(attachId) == "table" then        
            for index, currentAttachId in ipairs(attachId) do
                table.insert(supportingTechIds, currentAttachId)
            end
        else
            table.insert(supportingTechIds, attachId)
        end
        
        local ents = GetEntsWithTechIdIsActive(supportingTechIds, attachRange, position)           
        legalBuild = (table.count(ents) > 0) 
    
    end
    

    // For build tech that must be attached, find free attachment nearby. Snap position to it.
    local attachClass = LookupTechData(techId, kStructureAttachClass)    
    if legalBuild and attachClass then

        // If attach range specified, then we must be within that range of this entity
        // If not specified, but attach class specified, we attach to entity of that type
        // so one must be very close by (.5)
        
        legalBuild = LookupTechData(techId, kTechDataAttachOptional, false)
        
        attachEntity = GetNearestFreeAttachEntity(techId, position, snapRadius)
        if attachEntity then
        
            if attachEntity.GetIsBuilt and attachEntity:GetIsBuilt() then
            
                legalBuild = true
                VectorCopy(attachEntity:GetOrigin(), legalPosition)
                
            elseif not attachEntity.GetIsBuilt then
            
                legalBuild = true
                VectorCopy(attachEntity:GetOrigin(), legalPosition)
                
            end
            
        end
    
    end
    
    return legalBuild, legalPosition, attachEntity
    
end

local function CheckBuildEntityRequirements(techId, position, player, ignoreEntity)

    local legalBuild = true
    local errorString = ""
    
    local techTree = nil
    if Client then
        techTree = GetTechTree()
    else
        techTree = player:GetTechTree()
    end
    
    local techNode = techTree:GetTechNode(techId)
    local attachClass = LookupTechData(techId, kStructureAttachClass)                
    
    // Build tech can't be built on top of non-attachment entities.
    if techNode and techNode:GetIsBuild() then
    
        local trace = Shared.TraceBox(GetExtents(techId), position + Vector(0, 1, 0), position - Vector(0, 3, 0), CollisionRep.Default, PhysicsMask.AllButPCs, EntityFilterOne(ignoreEntity))
        
        // $AS - We special case Drop Packs you should not be able to build on top of them.
        if trace.entity and HasMixin(trace.entity, "Pathing") then
            legalBuild = false
        end
        
        // Now make sure we're not building on top of something that is used for another purpose (ie, armory blocking use of tech point)
        if trace.entity then
        
            local hitClassName = trace.entity:GetClassName()
            if GetIsAttachment(hitClassName) and (hitClassName ~= attachClass) then
                legalBuild = false
            end
            
        end
        
    end
    
    if techNode and (techNode:GetIsBuild() or techNode:GetIsBuy() or techNode:GetIsEnergyBuild()) and legalBuild then        
    
        local numFriendlyEntitiesInRadius = 0
        local entities = GetEntitiesForTeamWithinXZRange("ScriptActor", player:GetTeamNumber(), position, kMaxEntityRadius)
        
        for index, entity in ipairs(entities) do
        
            // Count number of friendly non-player units nearby and don't allow too many units in one area (prevents MAC/Drifter/Sentry spam/abuse)
            if not entity:isa("Player") and (entity:GetTeamNumber() == player:GetTeamNumber()) and entity:GetIsVisible() then
            
                numFriendlyEntitiesInRadius = numFriendlyEntitiesInRadius + 1
                
                if numFriendlyEntitiesInRadius >= (kMaxEntitiesInRadius - 1) then
                
                    errorString = "TOO_MANY_ENTITES"
                    legalBuild = false
                    break
                    
                end
                
            end
            
        end
        
        // Now check nearby entities to make sure we're not building on top of something that is used for another purpose (ie, armory blocking use of tech point)
        for index, currentEnt in ipairs( GetEntitiesWithinRange( "ScriptActor", position, 1.5) ) do
        
            local nearbyClassName = currentEnt:GetClassName()
            if GetIsAttachment(nearbyClassName) and (nearbyClassName ~= attachClass) then            
                legalBuild = false                
            end
            
        end
        
    end
    
    return legalBuild, errorString
    
end

local function CheckClearForStacking(position, extents, attachEntity, ignoreEntity)

    local filter = CreateFilter(ignoreEntity, attachEntity)
    local trace = Shared.TraceBox(extents, position + Vector(0, 1.5, 0), position - Vector(0, 3, 0), CollisionRep.Default, PhysicsMask.CommanderStack, filter)
    return trace.entity == nil
    
end

local function GetTeamNumber(player, ignoreEntity)

    local teamNumber = -1
    
    if player then
        teamNumber = player:GetTeamNumber()
    elseif ignoreEntity then
        teamNumber = ignoreEntity:GetTeamNumber()
    end
    
    return teamNumber
    
end

/**
 * Returns true or false if build attachments are fulfilled, as well as possible attach entity 
 * to be hooked up to. If snap radius passed, then snap build origin to it when nearby. Otherwise
 * use only a small tolerance to see if entity is close enough to an attach class.
 */
function GetIsBuildLegal(techId, position, snapRadius, player, ignoreEntity)

    local legalBuild = true
    local extents = GetExtents(techId)
    
    local attachEntity = nil
    local errorString = ""
    
    // Snap to ground
    local legalPosition = GetGroundAtPointWithCapsule(position, extents, PhysicsMask.CommanderBuild, CreateFilter(ignoreEntity))
    
    // Check attach points
    local teamNumber = GetTeamNumber(player, ignoreEntity)
    legalBuild, legalPosition, attachEntity = GetBuildAttachRequirementsMet(techId, legalPosition, teamNumber, snapRadius)
    
    // Check collision and make sure there aren't too many entities nearby
    if legalBuild and player then
        legalBuild, errorString = CheckBuildEntityRequirements(techId, legalPosition, player, ignoreEntity)
    end
    
    legalBuild = legalBuild and CheckBuildTechAvailable(techId, teamNumber)
    
    local ignoreEntities = LookupTechData(techId, kTechDataCollideWithWorldOnly, false)
    // Ignore entities means ignore pathing as well.
    if not ignoreEntities and legalBuild then
        legalBuild = GetPathingRequirementsMet(legalPosition, extents)        
    end
    
    if legalBuild then
    
        if not LookupTechData(techId, kTechDataAllowStacking, false) then
            legalBuild = CheckClearForStacking(legalPosition, extents, attachEntity, ignoreEntity)
        end
        
    end
    
    // Check special build requirements. We do it here because we have the trace from the building available to find out the normal
    if legalBuild then
    
        local method = LookupTechData(techId, kTechDataBuildRequiresMethod, nil)
        if method then
        
            // DL: As the normal passed in here isn't used to orient the building - don't bother working it out exactly. Up should be good enough.
            legalBuild = method(techId, legalPosition, Vector(0, 1, 0), player)
            
        end
        
    end
    
    // TODO: Also check that we're not building in front of a structure "exit" (robotics factory, phase gate)
    
    // Display tooltip error
    if not legalBuild and errorString ~= "" and player then
        player:TriggerInvalidSound()     
    end
    
    return legalBuild, legalPosition, attachEntity, errorString
    
end