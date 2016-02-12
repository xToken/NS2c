// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//    
// lua\BuildUtility.lua
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed infestation refs, adjusted some special case drop issues

local gDebugBuildUtility = false

local function CheckBuildTechAvailable(techId, player)

    local techTree = GetTechTree(player:GetTeamNumber())
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
    
    local techTree = GetTechTree(player:GetTeamNumber())    
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
        
        if not legalBuild then
            errorString = "COMMANDERERROR_CANT_BUILD_ON_TOP" 
        end
        
    end
    
    if techNode and (techNode:GetIsBuild() or techNode:GetIsBuy() or techNode:GetIsEnergyBuild()) and legalBuild then        
    
        local numFriendlyEntitiesInRadius = 0
        local entities = GetEntitiesForTeamWithinXZRange("ScriptActor", player:GetTeamNumber(), position, kMaxEntityRadius)
        local maxEntitiesAllowed = kMaxEntitiesInRadius
        local gameInfo = GetGameInfoEntity()
        if gameInfo then
            maxEntitiesAllowed = gameInfo:GetMaxEntities()
        end
        
        for index, entity in ipairs(entities) do
        
            // Count number of friendly non-player units nearby and don't allow too many units in one area (prevents MAC/Drifter/Sentry spam/abuse)
            if not entity:isa("Player") and (entity:GetTeamNumber() == player:GetTeamNumber()) and entity:GetIsVisible() then
            
                numFriendlyEntitiesInRadius = numFriendlyEntitiesInRadius + 1
                
                if numFriendlyEntitiesInRadius >= (maxEntitiesAllowed - 1) then
                
                    errorString = "COMMANDERERROR_TOO_MANY_ENTITIES"
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
                errorString = "COMMANDERERROR_CANT_BUILD_TOO_CLOSE"            
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

local function BuildUtility_Print(formatString, ...)

    if gDebugBuildUtility then
        Print(formatString, ...)
    end
    
end

local function GetIsStructureExitValid(origin, direction, range)

    local trace = Shared.TraceRay(origin + Vector(0, 0.2, 0), origin + Vector(0, 0.2, 0) + direction * range, CollisionRep.Move, PhysicsMask.CommanderSelect, nil)
    return trace.fraction == 1
    
end

local function CheckValidExit(techId, position, angle)

    //local directionVec = GetNormalizedVector(Vector(math.sin(angle), 0, math.cos(angle)))
    // TODO: Add something to tech data for "ExitDistance".
    local validExit = true
    //if techId == kTechId.TurretFactory then
        //validExit = GetIsStructureExitValid(position, directionVec, 5)
    //elseif techId == kTechId.PhaseGate then
        //validExit = GetIsStructureExitValid(position, directionVec, 1.5)
    //end
    
    BuildUtility_Print("validExit legal: %s", ToString(validExit))
    
    return validExit, not validExit and "COMMANDERERROR_NO_EXIT" or nil
    
end

local function CheckValidIPPlacement(position, extents)

    local trace = Shared.TraceBox(extents, position - Vector(0, 0.3, 0), position - Vector(0, 3, 0), CollisionRep.Default, PhysicsMask.AllButPCs, EntityFilterAll())
    local valid = true
    if trace.fraction == 1 then
        local traceStart = position + Vector(0, 0.3, 0)
        local traceSurface = Shared.TraceRay(traceStart, traceStart - Vector(0, 0.4, 0), CollisionRep.Default, PhysicsMask.AllButPCs, EntityFilterAll())
        valid = traceSurface.surface ~= "no_ip"
    end

    return valid
    
end

/**
 * Returns true or false if build attachments are fulfilled, as well as possible attach entity 
 * to be hooked up to. If snap radius passed, then snap build origin to it when nearby. Otherwise
 * use only a small tolerance to see if entity is close enough to an attach class.
 */
function GetIsBuildLegal(techId, position, angle, snapRadius, player, ignoreEntity, ignoreChecks)

    local legalBuild = true
    local extents = GetExtents(techId)
    
    local attachEntity = nil
    local errorString = nil
    local ignoreEntities = LookupTechData(techId, kTechDataCollideWithWorldOnly, false)
    local ignorePathing = LookupTechData(techId, kTechDataIgnorePathingMesh, false)
    
    BuildUtility_Print("------------- GetIsBuildLegal(%s) ---------------", EnumToString(kTechId, techId))
    
    local filter = CreateFilter(ignoreEntity)
    
    if ignoreEntities then
        filter = EntityFilterAll()
    end
    
    // Snap to ground
    local legalPosition = GetGroundAtPointWithCapsule(position, extents, PhysicsMask.CommanderBuild, CreateFilter(ignoreEntity))
    
    // Check attach points
    local teamNumber = GetTeamNumber(player, ignoreEntity)
    legalBuild, legalPosition, attachEntity = GetBuildAttachRequirementsMet(techId, legalPosition, teamNumber, snapRadius)
    
    if not legalBuild then
        errorString = "COMMANDERERROR_OUT_OF_RANGE"
    end
    
    BuildUtility_Print("GetBuildAttachRequirementsMet legal: %s", ToString(legalBuild))
    
    // Check collision and make sure there aren't too many entities nearby
    if legalBuild and player and not ignoreEntities then
        legalBuild, errorString = CheckBuildEntityRequirements(techId, legalPosition, player, ignoreEntity)
    end
    
    BuildUtility_Print("CheckBuildEntityRequirements legal: %s", ToString(legalBuild))
    
    if legalBuild and (not ignoreChecks or ignoreChecks["TechAvailable"] ~= true) then
    
        legalBuild = legalBuild and CheckBuildTechAvailable(techId, player)
        
        if not legalBuild then
            errorString = "COMMANDERERROR_TECH_NOT_AVAILABLE"
        end
        
    end
    
    BuildUtility_Print("CheckBuildTechAvailable legal: %s", ToString(legalBuild))
    
    // Ignore entities means ignore pathing as well.
    if not ignorePathing and legalBuild then
    
        legalBuild = GetPathingRequirementsMet(legalPosition, extents)
        if not legalBuild then
            errorString = "COMMANDERERROR_INVALID_PLACEMENT"
        end
        
    end
    
    BuildUtility_Print("GetPathingRequirementsMet legal: %s", ToString(legalBuild))
    if legalBuild then
    
        if not LookupTechData(techId, kTechDataAllowStacking, false) then
        
            legalBuild = CheckClearForStacking(legalPosition, extents, attachEntity, ignoreEntity)
            if not legalBuild then
                errorString = "COMMANDERERROR_CANT_BUILD_ON_TOP"
            end
            
        end
        
    end
    
    BuildUtility_Print("CheckClearForStacking legal: %s", ToString(legalBuild))
    
    // Check special build requirements. We do it here because we have the trace from the building available to find out the normal
    if legalBuild then
    
        local method = LookupTechData(techId, kTechDataBuildRequiresMethod, nil)
        if method then
        
            // DL: As the normal passed in here isn't used to orient the building - don't bother working it out exactly. Up should be good enough.
            legalBuild = method(techId, legalPosition, Vector(0, 1, 0), player)
            
            if not legalBuild then
            
                local customMessage = LookupTechData(techId, kTechDataBuildMethodFailedMessage, nil)
                
                if customMessage then
                    errorString = customMessage
                else
                    errorString = "COMMANDERERROR_BUILD_FAILED"
                end
                
            end
            
            BuildUtility_Print("customMethod legal: %s", ToString(legalBuild))
            
        end
        
    end
    
    if legalBuild and (not ignoreChecks or ignoreChecks["ValidExit"] ~= true) then
        legalBuild, errorString = CheckValidExit(techId, legalPosition, angle)
    end
    
    if legalBuild and techId == kTechId.InfantryPortal then
    
        legalBuild = CheckValidIPPlacement(legalPosition, extents)
        if not legalBuild then
            errorString = "COMMANDERERROR_INVALID_PLACEMENTS"
        end
        
    end
    
    return legalBuild, legalPosition, attachEntity, errorString
    
end

local function FlipDebug()

    gDebugBuildUtility = not gDebugBuildUtility
    Print("Set commander debug to " .. ToString(gDebugBuildUtility))
    
end

function BuildUtility_SetDebug(vm)

    if not vm then
        Print("use: debugcommander client, server or all")
    end
    
    if Shared.GetCheatsEnabled() then
    
        if Client and vm == "client" then
            FlipDebug()
        elseif Server and vm == "server" then
            FlipDebug()
        elseif vm == "all" then
            FlipDebug()
        end
        
    end
    
end