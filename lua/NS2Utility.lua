//======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\NS2Utility.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// NS2-specific utility functions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed some unneeded functions and updated some to support classic techids

Script.Load("lua/Table.lua")
Script.Load("lua/Utility.lua")

function GetDirectedExtentsForDiameter(direction, diameter)
    
    // normalize and scale the vector, then extract the extents from it
    local v = GetNormalizedVector(direction)
    v:Scale(diameter)
    
    local x = math.sqrt(v.y * v.y + v.z * v.z)
    local y = math.sqrt(v.x * v.x + v.z * v.z)
    local z = math.sqrt(v.y * v.y + v.x * v.x)
 
    local result = Vector(x,y,z)
    // Log("extents for %s/%s -> %s", direction, v, result)
    return result
    
end

function GetSupplyUsedByTeam(teamNumber)

    assert(teamNumber)

    local supplyUsed = 0
    
    if Server then
        local team = GetGamerules():GetTeam(teamNumber)
        if team and team.GetSupplyUsed then
            supplyUsed = team:GetSupplyUsed() 
        end    
    else
        
        local teamInfoEnt = GetTeamInfoEntity(teamNumber)
        if teamInfoEnt and teamInfoEnt.GetSupplyUsed then
            supplyUsed = teamInfoEnt:GetSupplyUsed()
        end
    
    end    

    return supplyUsed

end

function GetMaxSupplyForTeam(teamNumber)

    return kMaxSupply

    /*
    local maxSupply = 0

    if Server then
    
        local team = GetGamerules():GetTeam(teamNumber)
        if team and team.GetNumCapturedTechPoints then
            maxSupply = team:GetNumCapturedTechPoints() * kSupplyPerTechpoint
        end
        
    else    
        
        local teamInfoEnt = GetTeamInfoEntity(teamNumber)
        if teamInfoEnt and teamInfoEnt.GetNumCapturedTechPoints then
            maxSupply = teamInfoEnt:GetNumCapturedTechPoints() * kSupplyPerTechpoint
        end

    end   

    return maxSupply 
    */

end

if Client then

    function CreateSimpleInfestationDecal(size, coords)
    
        if not size then
            size = 1.5
        end
    
        local decal = Client.CreateRenderDecal()
        local infestationMaterial = Client.CreateRenderMaterial()
        infestationMaterial:SetMaterial("materials/infestation/infestation_decal_simple.material")
        infestationMaterial:SetParameter("scale", size)
        decal:SetMaterial(infestationMaterial)        
        decal:SetExtents(Vector(size, size, size))
        
        if coords then
            decal:SetCoords(coords)
        end
        
        return decal
        
    end

end

function GetIsTechUseable(techId, teamNum)

    local useAble = false
    local techTree = GetTechTree(teamNum)
    if techTree then
    
        local techNode = techTree:GetTechNode(techId)
        if techNode then
        
            useAble = techNode:GetAvailable()

            if techNode:GetIsResearch() then
                useAble = techNode:GetResearched() and techNode:GetHasTech()
            end
        
        end
    
    end
    
    return useAble == true

end

if Server then
    Script.Load("lua/NS2Utility_Server.lua")
end

if Client then
    PrecacheAsset("ui/buildmenu.dds")
end

local function HandleImpactDecal(position, doer, surface, target, showtracer, altMode, damage, direction, decalParams)

    // when we hit a target project some blood on the geometry behind
    //DebugLine(position, position + direction * kBloodDistance, 3, 1, 0, 0, 1)
    if direction then
    
        local trace =  Shared.TraceRay(position, position + direction * kBloodDistance, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(target))
        if trace.fraction ~= 1 then   

            decalParams[kEffectHostCoords] = Coords.GetTranslation(trace.endPoint)
            decalParams[kEffectHostCoords].yAxis = trace.normal
            decalParams[kEffectHostCoords].zAxis = direction
            decalParams[kEffectHostCoords].xAxis = decalParams[kEffectHostCoords].yAxis:CrossProduct(decalParams[kEffectHostCoords].zAxis)
            decalParams[kEffectHostCoords].zAxis = decalParams[kEffectHostCoords].xAxis:CrossProduct(decalParams[kEffectHostCoords].yAxis)

            decalParams[kEffectHostCoords].zAxis:Normalize()
            decalParams[kEffectHostCoords].xAxis:Normalize()
            
            //DrawCoords(decalParams[kEffectHostCoords])
            
            if not target then
                decalParams[kEffectSurface] = trace.surface        
            end
            
            GetEffectManager():TriggerEffects("damage_decal", decalParams)
         
        end
    
    end

end

function HandleHitEffect(position, doer, surface, target, showtracer, altMode, flinchsevere, damage, direction)

    local tableParams = { }
    tableParams[kEffectHostCoords] = Coords.GetTranslation(position)
    if doer then
        tableParams[kEffectFilterDoerName] = doer:GetClassName()
    end
    tableParams[kEffectSurface] = surface
    tableParams[kEffectFilterInAltMode] = altMode
    tableParams[kEffectFilterFlinchSevere] = flinchsevere
    
    if target then
    
        tableParams[kEffectFilterClassName] = target:GetClassName()
        
        if target.GetTeamType then
        
            tableParams[kEffectFilterIsMarine] = target:GetTeamType() == kMarineTeamType
            tableParams[kEffectFilterIsAlien] = target:GetTeamType() == kAlienTeamType
            
        end
        
    else
    
        tableParams[kEffectFilterIsMarine] = false
        tableParams[kEffectFilterIsAlien] = false
        
    end
    
    // Don't play the hit cinematic, those are made for third person.
    if target ~= Client.GetLocalPlayer() then
        GetEffectManager():TriggerEffects("damage", tableParams)
    end
    
    // Always play sound effect.
    GetEffectManager():TriggerEffects("damage_sound", tableParams)
    
    if showtracer == true and doer then
    
        local tracerStart = (doer.GetBarrelPoint and doer:GetBarrelPoint()) or (doer.GetEyePos and doer:GetEyePos()) or doer:GetOrigin()
        
        local tracerVelocity = GetNormalizedVector(position - tracerStart) * kTracerSpeed
        CreateTracer(tracerStart, position, tracerVelocity, doer)
        
    end
    
    if damage > 0 and target and target.OnTakeDamageClient then
        target:OnTakeDamageClient(damage, doer, position)
    end

    
    HandleImpactDecal(position, doer, surface, target, showtracer, altMode, damage, direction, tableParams)

end

function GetCommanderForTeam(teamNumber)

    local commanders = GetEntitiesForTeam("Commander", teamNumber)
    if #commanders > 0 then
        return commanders[1]
    end    

end

function GetPowerPointForLocation(locationName)   
    return nil
end

function UpdateMenuTechId(teamNumber, selected)

    local commander = GetCommanderForTeam(teamNumber)
    local menuTechId = commander:GetMenuTechId()

    if selected then
        menuTechId = kTechId.WeaponsMenu
    elseif menuTechId ~= kTechId.BuildMenu and
           menuTechId ~= kTechId.AdvancedMenu and
           menuTechId ~= kTechId.AssistMenu then
       
        menuTechId = kTechId.BuildMenu
    
    end       

    
    if Client then
        commander:SetCurrentTech(menuTechId)    
    elseif Server then    
        commander.menuTechId = menuTechId    
    end

    return menuTechId

end

// passing true for resetClientMask will cause the client to discard the predict selection and wait for a server update
function DeselectAllUnits(teamNumber, resetClientMask, sendMessage)

    if sendMessage == nil then
        sendMessage = true
    end 

    for _, unit in ipairs(GetEntitiesWithMixin("Selectable")) do
    
        unit:SetSelected(teamNumber, false, false, false)
        if resetClientMask then
            unit:ClearClientSelectionMask()
        end
        
    end

    // inform server to reset the selection
    if Client and sendMessage then
        local selectUnitMessage = BuildSelectUnitMessage(teamNumber, nil, false, false)
        Client.SendNetworkMessage("SelectUnit", selectUnitMessage, true)
    end

end

function GetIsRecycledUnit(unit)
    return unit ~= nil and HasMixin(unit, "Recycle") and unit:GetIsRecycled()
end

function GetGameInfoEntity()

    local entityList = Shared.GetEntitiesWithClassname("GameInfo")
    if entityList:GetSize() > 0 then    
        return entityList:GetEntityAtIndex(0)
    end

end

function GetTeamInfoEntity(teamNumber)

    local teamInfo = GetEntitiesForTeam("TeamInfo", teamNumber)
    if table.count(teamInfo) > 0 then
        return teamInfo[1]
    end
    
end

function GetIsTargetDetected(target)
    return HasMixin(target, "Detectable") and target:GetIsDetected()
end

function GetIsParasited(target)
    return target ~= nil and HasMixin(target, "ParasiteAble") and target:GetIsParasited()
end

function GetTeamHasCommander(teamNumber)

    if Client then
    
        local commTable = ScoreboardUI_GetOrderedCommanderNames(teamNumber)
        return #commTable > 0
        
    elseif Server then
        return #GetEntitiesForTeam("Commander", teamNumber) ~= 0
    end
    
end
function GetCommanderLogoutAllowed()
    return true 
end

function GetPlayerCanUseEntity(player, target)

    local useSuccessTable = { useSuccess = false }

    if target.GetCanBeUsed then
        useSuccessTable.useSuccess = true
        target:GetCanBeUsed(player, useSuccessTable)
    end
    
    //Print("GetPlayerCanUseEntity(%s, %s) returns %s", ToString(player), ToString(target), ToString(useSuccessTable.useSuccess))

    // really need to move this functionality into two mixin (when for user, one for useable)
    return useSuccessTable.useSuccess or (target.GetCanAlwaysBeUsed and target:GetCanAlwaysBeUsed())

end

function UpgradeBaseHivetoChamberSpecific(player, chambertechId, team)
    local teamnum
    if player then
        teamnum = player:GetTeamNumber()
        techTree = GetTechTree(teamnum)
        if techTree:GetTechNode(chambertechId):GetAvailable() then
            return true
        end
    elseif team then
        teamnum = team:GetTeamNumber()
    end
    if not teamnum then
        return false
    end
    local success = false
    local upghive
    for index, hive in ipairs(GetEntitiesForTeam("Hive", teamnum)) do
        if hive:GetTechId() == kTechId.Hive and hive:GetIsBuilt() then
            upghive = hive
            break
        end
    end
    if upghive ~= nil then
        if chambertechId == kTechId.Crag then
            success = upghive:OnResearchComplete(kTechId.UpgradeToCragHive)  
        elseif chambertechId == kTechId.Shade then
            success = upghive:OnResearchComplete(kTechId.UpgradeToShadeHive)
        elseif chambertechId == kTechId.Shift then
            success = upghive:OnResearchComplete(kTechId.UpgradeToShiftHive)
        elseif chambertechId == kTechId.Whip then
            success = upghive:OnResearchComplete(kTechId.UpgradeToWhipHive)
        end
    end
    return success
end

function GetIsClassHasEnergyFor(className, entity, techId, techNode, commander)

    local hasEnergy = false
    
    if entity:isa(className) and HasMixin(entity, "Energy") and entity:GetTechAllowed(techId, techNode, commander) then
        local cost = LookupTechData(techId, kTechDataCostKey, 0)
        hasEnergy = entity:GetEnergy() >= cost
    end        
    
    return hasEnergy

end

function GetIsUnitActive(unit, debug)

    local alive = not HasMixin(unit, "Live") or unit:GetIsAlive()
    local isBuilt = not HasMixin(unit, "Construct") or unit:GetIsBuilt()
    local isRecycled = not HasMixin(unit, "Recycle") or (not unit:GetIsRecycled() and not unit:GetRecycleActive())
    local powered = not HasMixin(unit, "TurretMixin") or unit:GetIsPowered()
        
    if debug then
        Print("------------ GetIsUnitActive(%s) -----------------", ToString(unit))
        Print("powered: %s", ToString(powered))
        Print("alive: %s", ToString(alive))
        Print("isBuilt: %s", ToString(isBuilt))
        Print("isRecycled: %s", ToString(isRecycled))
        Print("-----------------------------")
    end
    
    return alive and isBuilt and powered and isRecycled
    
end

function GetAnyNearbyUnitsInCombat(origin, radius, teamNumber)

    local nearbyUnits = GetEntitiesWithMixinForTeamWithinRange("Combat", teamNumber, origin, radius)
    for e = 1, #nearbyUnits do
    
        if nearbyUnits[e]:GetIsInCombat() then
            return true
        end
        
    end
    
    return false
    
end

function GetCircleSizeForEntity(entity)

    local size = ConditionalValue(entity:isa("Player"),2.0, 2)
    size = ConditionalValue(entity:isa("Hive"), 6.5, size)
    size = ConditionalValue(entity:isa("Door"), 4.0, size)
    size = ConditionalValue(entity:isa("InfantryPortal"), 3.5, size)
    size = ConditionalValue(entity:isa("Extractor"), 3.0, size)
    size = ConditionalValue(entity:isa("CommandStation"), 3.5, size)
    size = ConditionalValue(entity:isa("Egg"), 2.5, size)
    size = ConditionalValue(entity:isa("Armory"), 4.0, size)
    size = ConditionalValue(entity:isa("Harvester"), 3.7, size)
    size = ConditionalValue(entity:isa("Crag"), 3, size)
    size = ConditionalValue(entity:isa("RoboticsFactory"), 6, size)
    size = ConditionalValue(entity:isa("ARC"), 3.5, size)
    size = ConditionalValue(entity:isa("ArmsLab"), 4.3, size)
    return size
    
end

gMaxHeightOffGround = 0.0

function GetAttachEntity(techId, position, snapRadius, player)

    local attachClass = LookupTechData(techId, kStructureAttachClass)    
    //DUMBBBB
    if player == nil and techId == kTechId.CommandStation then
        attachClass = "TechPoint"
    end

    if attachClass then
    
        for index, currentEnt in ipairs( GetEntitiesWithinRange(attachClass, position, ConditionalValue(snapRadius, snapRadius, .5)) ) do
        
            if not currentEnt:GetAttached() then
            
                return currentEnt
                
            end
            
        end
        
    end
    
    return nil
    
end

function CheckForFlatSurface(origin, boxExtents)

    local valid = true
    
    // Perform trace at center, then at each of the extent corners
    if boxExtents then
    
        local tracePoints = {   origin + Vector(-boxExtents, 0.5, -boxExtents),
                                origin + Vector(-boxExtents, 0.5,  boxExtents),
                                origin + Vector( boxExtents, 0.5, -boxExtents),
                                origin + Vector( boxExtents, 0.5,  boxExtents) }
                                
        for index, point in ipairs(tracePoints) do
        
            local trace = Shared.TraceRay(tracePoints[index], tracePoints[index] - Vector(0, 0.7, 0), CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOne(nil))
            if (trace.fraction == 1) then
            
                valid = false
                break
                
            end
            
        end
        
    end 
    
    return valid

end

/**
 * Returns the spawn point on success, nil on failure.
 */
function ValidateSpawnPoint(spawnPoint, capsuleHeight, capsuleRadius, filter, origin)

    local center = Vector(0, capsuleHeight * 0.5 + capsuleRadius, 0)
    local spawnPointCenter = spawnPoint + center
    
    // Make sure capsule isn't interpenetrating something.
    local spawnPointBlocked = Shared.CollideCapsule(spawnPointCenter, capsuleRadius, capsuleHeight, CollisionRep.Default, PhysicsMask.AllButPCs, nil)
    if not spawnPointBlocked then

        // Trace capsule to ground, making sure we're not on something like a player or structure
        local trace = Shared.TraceCapsule(spawnPointCenter, spawnPoint - Vector(0, 10, 0), capsuleRadius, capsuleHeight, CollisionRep.Move, PhysicsMask.AllButPCs)            
        if trace.fraction < 1 and (trace.entity == nil or not trace.entity:isa("ScriptActor")) then
        
            VectorCopy(trace.endPoint, spawnPoint)
            
            local endPoint = trace.endPoint + Vector(0, capsuleHeight / 2, 0)
            // Trace in both directions to make sure no walls are being ignored.
            trace = Shared.TraceRay(endPoint, origin, CollisionRep.Move, PhysicsMask.AllButPCs, filter)
            local traceOriginToEnd = Shared.TraceRay(origin, endPoint, CollisionRep.Move, PhysicsMask.AllButPCs, filter)
            
            if trace.fraction == 1 and traceOriginToEnd.fraction == 1 then
                return spawnPoint - Vector(0, capsuleHeight / 2, 0)
            end
            
        end
        
    end
    
    return nil
    
end

// Find place for player to spawn, within range of origin. Makes sure that a line can be traced between the two points
// without hitting anything, to make sure you don't spawn on the other side of a wall. Returns nil if it can't find a 
// spawn point after a few tries.
function GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, origin, minRange, maxRange, filter, validationFunc)

    ASSERT(capsuleHeight > 0)
    ASSERT(capsuleRadius > 0)
    ASSERT(origin ~= nil)
    ASSERT(type(minRange) == "number")
    ASSERT(type(maxRange) == "number")
    ASSERT(maxRange > minRange)
    ASSERT(minRange > 0)
    ASSERT(maxRange > 0)
    
    local maxHeight = 10
    
    for i = 0, 10 do
    
        local spawnPoint = nil
        local points = GetRandomPointsWithinRadius(origin, minRange, maxRange, maxHeight, 1, 1, nil, validationFunc)
        if #points == 1 then
            spawnPoint = points[1]
        elseif Server then
            Print("GetRandomPointsWithinRadius() failed inside of GetRandomSpawnForCapsule()")
        end
        
        if spawnPoint then
        
        
            // The spawn point returned by GetRandomPointsWithinRadius() may be too close to the ground.
            // Move it up a bit so there is some "wiggle" room. ValidateSpawnPoint() traces down anyway.
            spawnPoint = spawnPoint + Vector(0, 0.5, 0)
            local validSpawnPoint = ValidateSpawnPoint(spawnPoint, capsuleHeight, capsuleRadius, filter, origin)
            if validSpawnPoint then
                return validSpawnPoint
            end
            
        end
        
    end
    
    return nil
    
end

function GetExtents(techId)

    local extents = LookupTechData(techId, kTechDataMaxExtents)
    if not extents then
        extents = Vector(.5, .5, .5)
    end
    return extents

end

function CreateFilter(entity1, entity2)

    local filter = nil
    if entity1 and entity2 then
        filter = EntityFilterTwo(entity1, entity2)
    elseif entity1 then
        filter = EntityFilterOne(entity1)
    elseif entity2 then
        filter = EntityFilterOne(entity2)
    end
    return filter
    
end

// Make sure point isn't blocking attachment entities
function GetPointBlocksAttachEntities(origin)

    local nozzles = GetEntitiesWithinRange("ResourcePoint", origin, 1.5)
    if table.count(nozzles) == 0 then
    
        local techPoints = GetEntitiesWithinRange("TechPoint", origin, 3.2)
        if table.count(techPoints) == 0 then
        
            return false
            
        end
        
    end
    
    return true
    
end

function GetGroundAtPointWithCapsule(position, extents, physicsGroupMask, filter)

    local kCapsuleSize = 0.1
    
    local topOffset = extents.y + kCapsuleSize
    local startPosition = position + Vector(0, topOffset, 0)
    local endPosition = position - Vector(0, 1000, 0)
    
    local trace
    if filter == nil then
        trace = Shared.TraceCapsule(startPosition, endPosition, kCapsuleSize, 0, CollisionRep.Move, physicsGroupMask)    
    else    
        trace = Shared.TraceCapsule(startPosition, endPosition, kCapsuleSize, 0, CollisionRep.Move, physicsGroupMask, filter)    
    end
    
    // If we didn't hit anything, then use our existing position. This
    // prevents objects from constantly moving downward if they get outside
    // of the bounds of the map.
    if trace.fraction ~= 1 then
        return trace.endPoint - Vector(0, 2 * kCapsuleSize, 0)
    else
        return position
    end

end

/**
 * Return the passed in position casted down to the ground.
 */
function GetGroundAt(entity, position, physicsGroupMask, filter)
    if filter then
        return GetGroundAtPointWithCapsule(position, entity:GetExtents(), physicsGroupMask, filter)
    end

    return GetGroundAtPointWithCapsule(position, entity:GetExtents(), physicsGroupMask, EntityFilterOne(entity))
    
end

/**
 * Return the ground below position, using a TraceBox with the given extents, mask and filter.
 * Returns position if nothing hit.
 *
 * filter defaults to nil
 * extents defaults to a 0.1x0.1x0.1 box (ie, extents 0.05x...)
 * physicGroupsMask defaults to PhysicsMask.Movement
 */
function GetGroundAtPosition(position, filter, physicsGroupMask, extents)

    physicsGroupMask = physicsGroupMask or PhysicsMask.Movement
    extents = extents or Vector(0.05, 0.05, 0.05)
    
    local topOffset = extents.y + 0.1
    local startPosition = position + Vector(0, topOffset, 0)
    local endPosition = position - Vector(0, 1000, 0)
    
    local trace = Shared.TraceBox(extents, startPosition, endPosition, CollisionRep.Move, physicsGroupMask, filter)
    
    // If we didn't hit anything, then use our existing position. This
    // prevents objects from constantly moving downward if they get outside
    // of the bounds of the map.
    if trace.fraction ~= 1 then
        return trace.endPoint - Vector(0, extents.y, 0)
    else
        return position
    end

end

function GetHoverAt(entity, position, filter)

    local ground = GetGroundAt(entity, position, PhysicsMask.Movement, filter)
    local resultY = position.y
    // if we have a hover height, use it to find our minimum height above ground, otherwise use zero
    
    local minHeightAboveGround = 0
    if entity.GetHoverHeight then      
      minHeightAboveGround = entity:GetHoverHeight()
    end

    local heightAboveGround = resultY  - ground.y
    
    // always snap "up", snap "down" only if not flying
    if heightAboveGround <= minHeightAboveGround or not entity:GetIsFlying() then
        resultY = resultY + minHeightAboveGround - heightAboveGround              
    end   

    if resultY ~= position.y then
        return Vector(position.x, resultY, position.z)
    end

    return position

end

function GetWaypointGroupName(entity)
    return ConditionalValue(entity:GetIsFlying(), kAirWaypointsGroup, kDefaultWaypointGroup)
end

function GetTriggerEntity(position, teamNumber)

    local triggerEntity = nil
    local minDist = nil
    local ents = GetEntitiesWithMixinForTeamWithinRange("Live", teamNumber, position, .5)
    
    for index, ent in ipairs(ents) do
    
        local dist = (ent:GetOrigin() - position):GetLength()
        
        if not minDist or (dist < minDist) then
        
            triggerEntity = ent
            minDist = dist
            
        end
    
    end
    
    return triggerEntity
    
end

function GetBlockedByUmbra(entity)
    return entity ~= nil and HasMixin(entity, "Umbra") and entity:GetHasUmbra()
end

// TODO: use what is defined in the material file
function GetSurfaceFromEntity(entity)

    if GetIsAlienUnit(entity) then
        return "organic"
    elseif GetIsMarineUnit(entity) then
        return "thin_metal"
    end

    return "thin_metal"
    
end

function GetSurfaceAndNormalUnderEntity(entity, axis)

    if not axis then
        axis = entity:GetCoords().yAxis
    end

    local trace = Shared.TraceRay(entity:GetOrigin() + axis * 0.2, entity:GetOrigin() - axis * 10, CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll() )
    
    if trace.fraction ~= 1 then
        return trace.surface, trace.normal
    end
    
    return "thin_metal", Vector(0, 1, 0)

end

// Trace line to each target to make sure it's not blocked by a wall. 
// Returns true/false, along with distance traced 
function GetWallBetween(startPoint, endPoint, targetEntity)

    // Filter out all entities except the targetEntity on this trace.
    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Move, PhysicsMask.Bullets, EntityFilterOnly(targetEntity))        
    local dist = (startPoint - endPoint):GetLength()
    local hitWorld = false
    
    // Hit nothing?
    if trace.fraction == 1 then
        hitWorld = false
    // Hit the world?
    elseif not trace.entity then
    
        dist = (startPoint - trace.endPoint):GetLength()
        hitWorld = true
        
    elseif trace.entity == targetEntity then
    
        // Hit target entity, return traced distance to it.
        dist = (startPoint - trace.endPoint):GetLength()
        hitWorld = false
        
    end
    
    return hitWorld, dist
    
end

// Get damage type description text for tooltips
function DamageTypeDesc(damageType)
    if table.count(kDamageTypeDesc) >= damageType then
        if kDamageTypeDesc[damageType] ~= "" then
            return string.format("(%s)", kDamageTypeDesc[damageType])
        end
    end
    return ""
end

function GetHealthColor(scalar)

    local kHurtThreshold = .7
    local kNearDeadThreshold = .4
    local minComponent = 191
    local spreadComponent = 255 - minComponent

    scalar = Clamp(scalar, 0, 1)
    
    if scalar <= kNearDeadThreshold then
    
        // Faded red to bright red
        local r = minComponent + (scalar / kNearDeadThreshold) * spreadComponent
        return {r, 0, 0}
        
    elseif scalar <= kHurtThreshold then
    
        local redGreen = minComponent + ( (scalar - kNearDeadThreshold) / (kHurtThreshold - kNearDeadThreshold) ) * spreadComponent
        return {redGreen, redGreen, 0}
        
    else
    
        local g = minComponent + ( (scalar - kHurtThreshold) / (1 - kHurtThreshold) ) * spreadComponent
        return {0, g, 0}
        
    end
    
end

function GetEntsWithTechId(techIdTable, attachRange, position)

    local ents = {}
    
    local entities = nil
    
    if attachRange and position then        
        entities = GetEntitiesWithMixinWithinRange("Tech", position, attachRange)        
    else
        entities = GetEntitiesWithMixin("Tech")
    end
    
    for index, entity in ipairs(entities) do
    
        if table.find(techIdTable, entity:GetTechId()) then
            table.insert(ents, entity)
        end
        
    end
    
    return ents
    
end

function GetEntsWithTechIdIsActive(techIdTable, attachRange, position)

    local ents = {}
    
    local entities = nil
    
    if attachRange and position then        
        entities = GetEntitiesWithMixinWithinRange("Tech", position, attachRange)        
    else
        entities = GetEntitiesWithMixin("Tech")
    end
    
    for index, entity in ipairs(entities) do
    
        if table.find(techIdTable, entity:GetTechId()) and GetIsUnitActive(entity) then
            table.insert(ents, entity)
        end
        
    end
    
    return ents
    
end

function GetFreeAttachEntsForTechId(techId)

    local freeEnts = {}

    local attachClass = LookupTechData(techId, kStructureAttachClass)

    if attachClass ~= nil then    
    
        for index, ent in ientitylist(Shared.GetEntitiesWithClassname(attachClass)) do
        
            if ent ~= nil and ent:GetAttached() == nil then
                table.insert(freeEnts, ent)
            end
            
        end
        
    end
    
    return freeEnts
    
end

function GetNearestFreeAttachEntity(techId, origin, range)

    local nearest = nil
    local nearestDist = nil
    
    for index, ent in ipairs(GetFreeAttachEntsForTechId(techId)) do
    
        local dist = (ent:GetOrigin() - origin):GetLengthXZ()
        
        if (nearest == nil or dist < nearestDist) and (range == nil or dist <= range) then
        
            nearest = ent
            nearestDist = dist
            
        end
        
    end
    
    return nearest
    
end

// Trace until we hit the "inside" of the level or hit nothing. Returns nil if we hit nothing,
// returns the world point of the surface we hit otherwise. Only hit surfaces that are facing 
// towards us.
// Input pickVec is either a normalized direction away from the commander that represents where
// the mouse was clicked, or if worldCoordsSpecified is true, it's the XZ position of the order
// given to the minimap. In that case, trace from above it straight down to find the target.
// The last parameter is false if target is for selection, true if it's for building
function GetCommanderPickTarget(player, pickVec, worldCoordsSpecified, forBuild, ignoreEntities)

    local done = false
    local startPoint = player:GetOrigin() 

    if worldCoordsSpecified and pickVec then
        startPoint = Vector(pickVec.x, startPoint.y + 20, pickVec.z)
        pickVec = Vector(0, -1, 0)
    end
    
    local trace = nil
    local mask = ConditionalValue(forBuild, PhysicsMask.CommanderBuild, PhysicsMask.CommanderSelect) 
    
    while not done do

        // Use either select or build mask depending what it's for       
        local endPoint = startPoint + pickVec * 1000
        
        if ignoreEntities == true then
            trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Select, mask, EntityFilterAll())
        else
            trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Select, mask, EntityFilterOne(player))
        end
        
        local hitDistance = (startPoint - trace.endPoint):GetLength()
        
        // Try again if we're inside the surface
        if(trace.fraction == 0 or hitDistance < .1) then
        
            startPoint = startPoint + pickVec
        
        elseif(trace.fraction == 1) then
        
            done = true

        // Only hit a target that's facing us (skip surfaces facing away from us)            
        elseif trace.normal.y < 0 then
        
            // Trace again from what we hit
            startPoint = trace.endPoint + pickVec * 0.01
            
        else
                    
            done = true
                
        end
        
    end
    
    return trace
    
end

function GetAreEnemies(entityOne, entityTwo)
    return entityOne and entityTwo and HasMixin(entityOne, "Team") and HasMixin(entityTwo, "Team") and (
            (entityOne:GetTeamNumber() == kMarineTeamType and entityTwo:GetTeamNumber() == kAlienTeamType) or
            (entityOne:GetTeamNumber() == kAlienTeamType and entityTwo:GetTeamNumber() == kMarineTeamType)
           )
end

function GetAreFriends(entityOne, entityTwo)
    return entityOne and entityTwo and HasMixin(entityOne, "Team") and HasMixin(entityTwo, "Team") and
            entityOne:GetTeamNumber() == entityTwo:GetTeamNumber()
end

function GetIsMarineUnit(entity)
    return entity and HasMixin(entity, "Team") and entity:GetTeamType() == kMarineTeamType
end

function GetIsAlienUnit(entity)
    return entity and HasMixin(entity, "Team") and entity:GetTeamType() == kAlienTeamType
end

function GetEnemyTeamNumber(entityTeamNumber)

    if(entityTeamNumber == kTeam1Index) then
        return kTeam2Index
    elseif(entityTeamNumber == kTeam2Index) then
        return kTeam1Index
    else
        return kTeamInvalid
    end    
    
end

function SpawnPlayerAtPoint(player, origin, angles)

    player:SetOrigin(origin)
    
    if angles then
        player:SetViewAngles(angles)
    end        
    
end

/**
 * Returns the passed in point traced down to the ground. Ignores all entities.
 */
function DropToFloor(point)

    local trace = Shared.TraceRay(point, Vector(point.x, point.y - 1000, point.z), CollisionRep.Move, PhysicsMask.All)
    if trace.fraction < 1 then
        return trace.endPoint
    end
    
    return point
    
end

function GetNearestTechPoint(origin, availableOnly)

    // Look for nearest empty tech point to use instead
    local nearestTechPoint = nil
    local nearestTechPointDistance = 0
    
    for index, techPoint in ientitylist(Shared.GetEntitiesWithClassname("TechPoint")) do
    
        // Only use unoccupied tech points that are neutral or marked for use with our team
        local techPointTeamNumber = techPoint:GetTeamNumberAllowed()        
        if not availableOnly or techPoint:GetAttached() == nil then
        
            local distance = (techPoint:GetOrigin() - origin):GetLength()
            if nearestTechPoint == nil or distance < nearestTechPointDistance then
            
                nearestTechPoint = techPoint
                nearestTechPointDistance = distance
                
            end
            
        end
        
    end
    
    return nearestTechPoint
    
end

function GetNearest(origin, className, teamNumber, filterFunc)

    assert(type(className) == "string")
    
    local nearest = nil
    local nearestDistance = 0
    
    for index, ent in ientitylist(Shared.GetEntitiesWithClassname(className)) do
    
        // Filter is optional, pass through if there is no filter function defined.
        if not filterFunc or filterFunc(ent) then
        
            if teamNumber == nil or (teamNumber == ent:GetTeamNumber()) then
            
                local distance = (ent:GetOrigin() - origin):GetLength()
                if nearest == nil or distance < nearestDistance then
                
                    nearest = ent
                    nearestDistance = distance
                    
                end
                
            end
            
        end
        
    end
    
    return nearest
    
end

function GetCanAttackEntity(seeingEntity, targetEntity)
    return GetCanSeeEntity(seeingEntity, targetEntity, true)
end

// Computes line of sight to entity, set considerObstacles to true to check if any other entity is blocking LOS
local toEntity = Vector()
function GetCanSeeEntity(seeingEntity, targetEntity, considerObstacles)

    PROFILE("NS2Utility:GetCanSeeEntity")
    
    local seen = false
    
    // See if line is in our view cone
    if targetEntity:GetIsVisible() then
    
        local targetOrigin = HasMixin(targetEntity, "Target") and targetEntity:GetEngagementPoint() or targetEntity:GetOrigin()
        local eyePos = GetEntityEyePos(seeingEntity)
        
        // Not all seeing entity types have a FOV.
        // So default to within FOV.
        local withinFOV = true
        
        // Anything that has the GetFov method supports FOV checking.
        if seeingEntity.GetFov ~= nil then
        
            // Reuse vector
            toEntity.x = targetOrigin.x - eyePos.x
            toEntity.y = targetOrigin.y - eyePos.y
            toEntity.z = targetOrigin.z - eyePos.z
            
            // Normalize vector        
            local toEntityLength = math.sqrt(toEntity.x * toEntity.x + toEntity.y * toEntity.y + toEntity.z * toEntity.z)
            if toEntityLength > kEpsilon then
            
                toEntity.x = toEntity.x / toEntityLength
                toEntity.y = toEntity.y / toEntityLength
                toEntity.z = toEntity.z / toEntityLength
                
            end
            
            local seeingEntityAngles = GetEntityViewAngles(seeingEntity)
            local normViewVec = seeingEntityAngles:GetCoords().zAxis        
            local dotProduct = Math.DotProduct(toEntity, normViewVec)
            local fov = seeingEntity:GetFov()
            
            // players have separate fov for marking enemies as sighted
            if seeingEntity.GetMinimapFov then
                fov = seeingEntity:GetMinimapFov(targetEntity)
            end
            
            local halfFov = math.rad(fov / 2)
            local s = math.acos(dotProduct)
            withinFOV = s < halfFov
            
        end
        
        if withinFOV then
        
            local filter = EntityFilterAllButIsa("Door") // EntityFilterAll()
            if considerObstacles then
                filter = EntityFilterTwo(seeingEntity, targetEntity)
            end
        
            // See if there's something blocking our view of the entity.
            local trace = Shared.TraceRay(eyePos, targetOrigin, CollisionRep.LOS, PhysicsMask.All, filter)
            
            if trace.fraction == 1 then
                seen = true
            end
            
        end
        
    end
    
    return seen
    
end

function GetLocations()
    return EntityListToTable(Shared.GetEntitiesWithClassname("Location"))
end

function GetLocationForPoint(point, ignoredLocation)

    local ents = GetLocations()
    
    for index, location in ipairs(ents) do
    
        if location ~= ignoredLocation and location:GetIsPointInside(point) then
        
            return location
            
        end    
        
    end
    
    return nil

end

function GetLocationEntitiesNamed(name)

    local locationEntities = {}
    
    if name ~= nil and name ~= "" then
    
        local ents = GetLocations()
        
        for index, location in ipairs(ents) do
        
            if location:GetName() == name then
            
                table.insert(locationEntities, location)
                
            end
            
        end
        
    end

    return locationEntities
    
end

// for performance, cache the lights for each locationName
local lightLocationCache = {}

function GetLightsForLocation(locationName)

    if locationName == nil or locationName == "" then
        return {}
    end
 
    if lightLocationCache[locationName] then
        return lightLocationCache[locationName]   
    end

    local lightList = {}
   
    local locations = GetLocationEntitiesNamed(locationName)
   
    if table.count(locations) > 0 then
   
        for index, location in ipairs(locations) do
           
            for index, renderLight in ipairs(Client.lightList) do

                if renderLight then
               
                    local lightOrigin = renderLight:GetCoords().origin
                   
                    if location:GetIsPointInside(lightOrigin) then
                   
                        table.insert(lightList, renderLight)
           
                    end
                   
                end
               
            end
           
        end
       
    end

    // Log("Total lights %s, lights in %s = %s", #Client.lightList, locationName, #lightList)
    lightLocationCache[locationName] = lightList
  
    return lightList
   
end

// for performance, cache the probes for each locationName
local probeLocationCache = {}

function GetReflectionProbesForLocation(locationName)

    if locationName == nil or locationName == "" then
        return {}
    end
 
    if probeLocationCache[locationName] then
        return probeLocationCache[locationName]   
    end

    local probeList = {}
   
    local locations = GetLocationEntitiesNamed(locationName)
   
    if table.count(locations) > 0 then
   
        for index, location in ipairs(locations) do
           
        // TEMP FIX FOR SCRIPT ERRORS
            if Client.reflectionProbeList then
            for index, probe in ipairs(Client.reflectionProbeList) do

                if probe then
               
                    local probeOrigin = probe:GetOrigin()
                   
                    if location:GetIsPointInside(probeOrigin) then
                   
                        table.insert(probeList, probe)
           
                    end
                   
                end
               
            end
            end
           
        end
       
    end

    // Log("Total lights %s, lights in %s = %s", #Client.lightList, locationName, #lightList)
    probeLocationCache[locationName] = probeList
  
    return probeList
   
end

if Client then

    function ResetLights()
    
        for index, renderLight in ipairs(Client.lightList) do
        
            renderLight:SetColor(renderLight.originalColor)
            renderLight:SetIntensity(renderLight.originalIntensity)
            
        end                    
        
    end
    
end


local kUpVector = Vector(0, 1, 0)

function SetPlayerPoseParameters(player, viewModel, headAngles)

    local coords = player:GetCoords()
    
    local pitch = -Math.Wrap(Math.Degrees(headAngles.pitch), -180, 180)
    
    local landIntensity = player:GetLastImpactForce() or 0
    
    local bodyYaw = 0
    if player.bodyYaw then
        bodyYaw = Math.Wrap(Math.Degrees(player.bodyYaw), -180, 180)
    end
    
    local bodyYawRun = 0
    if player.bodyYawRun then
        bodyYawRun = Math.Wrap(Math.Degrees(player.bodyYawRun), -180, 180)
    end
    
    local headCoords = headAngles:GetCoords()
    
    local velocity = player:GetVelocityFromPolar()
    // Not all players will contrain their movement to the X/Z plane only.
    if player.PerformsVerticalMove and player:PerformsVerticalMove() then
        velocity.y = 0
    end
    
    local x = Math.DotProduct(headCoords.xAxis, velocity)
    local z = Math.DotProduct(headCoords.zAxis, velocity)
    
    local moveYaw
    
    if player.OverrideGetMoveYaw then
        moveYaw = player:OverrideGetMoveYaw()
    end
    
    if not moveYaw then
        moveYaw = Math.Wrap(Math.Degrees( math.atan2(z,x) ), -180, 180)
    end
    
    local speedScalar = velocity:GetLength() / player:GetMaxSpeed(true)
    
    player:SetPoseParam("move_yaw", moveYaw)
    player:SetPoseParam("move_speed", speedScalar)
    player:SetPoseParam("body_pitch", pitch)
    player:SetPoseParam("body_yaw", bodyYaw)
    player:SetPoseParam("body_yaw_run", bodyYawRun)

    // Some code for debugging help
    //if Client and not Shared.GetIsRunningPrediction() and self:isa("Skulk") then
        //Print('speedScalar,%f,%f', Shared.GetSystemTime(), speedScalar)
    //end

    //player:SetPoseParam("move_yaw", 0)
    //player:SetPoseParam("move_speed", 0)
    //player:SetPoseParam("body_pitch", 0)
    //player:SetPoseParam("body_yaw", 0)
    //player:SetPoseParam("body_yaw_run", 0)

    //Print("body yaw = %f, move_yaw = %f", bodyYaw, moveYaw);
    
    player:SetPoseParam("crouch", player:GetCrouchAmount())
    player:SetPoseParam("land_intensity", landIntensity)
    
    if viewModel then
    
        viewModel:SetPoseParam("body_pitch", pitch)
        viewModel:SetPoseParam("move_yaw", moveYaw)
        viewModel:SetPoseParam("move_speed", speedScalar)
        viewModel:SetPoseParam("crouch", player:GetCrouchAmount())
        viewModel:SetPoseParam("body_yaw", bodyYaw)
        viewModel:SetPoseParam("body_yaw_run", bodyYawRun)
        viewModel:SetPoseParam("land_intensity", landIntensity)
        
    end
    
end

// Pass in position on ground
function GetHasRoomForCapsule(extents, position, collisionRep, physicsMask, ignoreEntity, filter)

    if extents ~= nil then
    
        local filter = filter or ConditionalValue(ignoreEntity, EntityFilterOne(ignoreEntity), nil)
        return not Shared.CollideBox(extents, position, collisionRep, physicsMask, filter)
        
    else
        Print("GetHasRoomForCapsule(): Extents not valid.")
    end
    
    return false

end

function GetEngagementDistance(entIdOrTechId, trueTechId)

    local distance = 2
    local success = true
    
    local techId = entIdOrTechId
    if not trueTechId then
    
        local ent = Shared.GetEntity(entIdOrTechId)    
        if ent and ent.GetTechId then
            techId = ent:GetTechId()
        else
            success = false
        end
        
    end
    
    local desc = nil
    if success then
    
        distance = LookupTechData(techId, kTechDataEngagementDistance, nil)
        
        if distance then
            desc = EnumToString(kTechId, techId)    
        else
            distance = 1
            success = false
        end
        
    end    
        
    //Print("GetEngagementDistance(%s, %s) => %s => %s, %s", ToString(entIdOrTechId), ToString(trueTechId), ToString(desc), ToString(distance), ToString(success))
    
    return distance, success
    
end

function MinimapToWorld(commander, x, y)

    local heightmap = GetHeightmap()
    
    // Translate minimap coords to world position
    return Vector(heightmap:GetWorldX(y), 0, heightmap:GetWorldZ(x))
    
end

function GetMinimapPlayableWidth(map)
    local mapX = map:GetMapX(map:GetOffset().z + map:GetExtents().z)
    return (mapX - .5) * 2
end

function GetMinimapPlayableHeight(map)
    local mapY = map:GetMapY(map:GetOffset().x - map:GetExtents().x)
    return (mapY - .5) * 2
end

function GetMinimapHorizontalScale(map)

    local width = GetMinimapPlayableWidth(map)
    local height = GetMinimapPlayableHeight(map)
    
    return ConditionalValue(height > width, width/height, 1)
    
end

function GetMinimapVerticalScale(map)

    local width = GetMinimapPlayableWidth(map)
    local height = GetMinimapPlayableHeight(map)
    
    return ConditionalValue(width > height, height/width, 1)
    
end

function GetMinimapNormCoordsFromPlayable(map, playableX, playableY)

    local playableWidth = GetMinimapPlayableWidth(map)
    local playableHeight = GetMinimapPlayableHeight(map)
    
    return playableX * (1 / playableWidth), playableY * (1 / playableHeight)
    
end

// If we hit something, create an effect (sparks, blood, etc)
function TriggerHitEffects(doer, target, origin, surface, melee, extraEffectParams)

    local tableParams = {}
    
    if target and target.GetClassName and target.GetTeamType then
        tableParams[kEffectFilterClassName] = target:GetClassName()
        tableParams[kEffectFilterIsMarine] = target:GetTeamType() == kMarineTeamType
        tableParams[kEffectFilterIsAlien] = target:GetTeamType() == kAlienTeamType
    end

    if not surface or surface == "" then
        surface = "metal"
    end
    
    tableParams[kEffectSurface] = surface
    
    if origin then
        tableParams[kEffectHostCoords] = Coords.GetTranslation(origin)
    else
        tableParams[kEffectHostCoords] = Coords.GetIdentity()
    end
    
    if doer then
        tableParams[kEffectFilterDoerName] = doer:GetClassName()
    end
    
    tableParams[kEffectFilterInAltMode] = (melee == true)

    // Add in extraEffectParams if specified    
    if extraEffectParams then
        for key, element in pairs(extraEffectParams) do
            tableParams[key] = element
        end
    end
    
    GetEffectManager():TriggerEffects("damage", tableParams, doer)
    
end

// Get nearest valid target for commander ability activation, of specified team number nearest specified position.
// Returns nil if none exists in range.
function GetActivationTarget(teamNumber, position)

    local nearestTarget = nil
    local nearestDist = nil
    
    local targets = GetEntitiesWithMixinForTeamWithinRange("Live", teamNumber, position, 2)
    for index, target in ipairs(targets) do
    
        if target:GetIsVisible() then
        
            local dist = (target:GetOrigin() - position):GetLength()
            if nearestTarget == nil or dist < nearestDist then
            
                nearestTarget = target
                nearestDist = dist
                
            end
            
        end
        
    end
    
    return nearestTarget
    
end

function GetSelectionText(entity, teamNumber)

    local text = ""
    
    local cloakedText = ""    
    if entity.GetIsCamouflaged and entity:GetIsCamouflaged() then
        cloakedText = " (" .. Locale.ResolveString("CAMOUFLAGED") .. ")"
    elseif HasMixin(entity, "Cloakable") and entity:GetIsCloaked() then
        cloakedText = " (" .. Locale.ResolveString("CLOAKED") .. ")"
    end
        
    if entity:isa("Player") and entity:GetIsAlive() then
    
        local playerName = Scoreboard_GetPlayerData(entity:GetClientIndex(), "Name")
                    
        if playerName ~= nil then
            
            text = string.format("%s%s", playerName, cloakedText)
        end
                    
    else
    
        // Don't show built % for enemies, show health instead
        local enemyTeam = HasMixin(entity, "Team") and GetEnemyTeamNumber(entity:GetTeamNumber()) == teamNumber
        local techId = entity:GetTechId()
        
        local secondaryText = ""
        if HasMixin(entity, "Construct") and not entity:GetIsBuilt() then        
            secondaryText = "Unbuilt "
            
        end
        
        local primaryText = GetDisplayNameForTechId(techId)
        if entity.GetDescription then
            primaryText = entity:GetDescription()
        end

        text = string.format("%s%s%s", secondaryText, primaryText, cloakedText)

    end
    
    return text
    
end

function GetCostForTech(techId)
    return LookupTechData(techId, kTechDataCostKey, 0)
end

/**
 * Adds additional points to the path to ensure that no two points are more than
 * maxDistance apart.
 */
function SubdividePathPoints(points, maxDistance)
    PROFILE("NS2Utility:SubdividePathPoints") 
    local numPoints   = #points    
    
    local i = 1
    while i < numPoints do
        
        local point1 = points[i]
        local point2 = points[i + 1]

        // If the distance between two points is large, add intermediate points
        
        local delta    = point2 - point1
        local distance = delta:GetLength()
        local numNewPoints = math.floor(distance / maxDistance)
        local p = 0
        for j=1,numNewPoints do

            local f = j / numNewPoints
            local newPoint = point1 + delta * f
            if (table.find(points, newPoint) == nil) then
                i = i + 1
                table.insert( points, i, newPoint )
                p = p + 1
            end                     
        end 
        i = i + 1    
        numPoints = numPoints + p        
    end           
end

local function GetTraceEndPoint(src, dst, trace, skinWidth)

    local delta    = dst - src
    local distance = delta:GetLength()
    local fraction = trace.fraction
    fraction = Math.Clamp( fraction + (fraction - 1.0) * skinWidth / distance, 0.0, 1.0 )
    
    return src + delta * fraction

end

function GetFriendlyFire()
    return false
end

// All damage is routed through here.
function CanEntityDoDamageTo(attacker, target, cheats, devMode, friendlyFire, damageType)

    if not GetGameInfoEntity():GetGameStarted() then
        return false
    end
   
    if not HasMixin(target, "Live") then
        return false
    end

    if not target:GetCanTakeDamage() then
        return false
    end
    
    if target == nil or (target.GetDarwinMode and target:GetDarwinMode()) then
        return false
    elseif cheats or devMode then
        return true
    elseif attacker == nil then
        return true
    end
    
    // You can always do damage to yourself.
    if attacker == target then
        return true
    end
    
    // Command stations can kill even friendlies trapped inside.
    if attacker ~= nil and attacker:isa("CommandStation") then
        return true
    end
    
    // Your own grenades can hurt you.
    if attacker:isa("Grenade") then
    
        local owner = attacker:GetOwner()
        if owner and owner:GetId() == target:GetId() then
            return true
        end
        
    end
    
    // Same teams not allowed to hurt each other unless friendly fire enabled.
    local teamsOK = true
    if attacker ~= nil then
        teamsOK = GetAreEnemies(attacker, target) or friendlyFire
    end
    
    // Allow damage of own stuff when testing.
    return teamsOK
    
end

function TraceMeleeBox(weapon, eyePoint, axis, extents, range, mask, filter)

    // We make sure that the given range is actually the start/end of the melee volume by moving forward the
    // starting point with the extents (and some extra to make sure we don't hit anything behind us),
    // as well as moving the endPoint back with the extents as well (making sure we dont trace backwards)
    
    // Make sure we don't hit anything behind us.
    local startPoint = eyePoint + axis * weapon:GetMeleeOffset()
    local endPoint = eyePoint + axis * math.max(0, range) 
    local trace = Shared.TraceBox(extents, startPoint, endPoint, CollisionRep.Damage, mask, filter)
    return trace, startPoint, endPoint
    
end

local function IsPossibleMeleeTarget(player, target, teamNumber)

    if target and HasMixin(target, "Live") and target:GetCanTakeDamage() and target:GetIsAlive() then
    
        if HasMixin(target, "Team") and teamNumber == target:GetTeamNumber() then
            return true
        end
        
    end
    
    return false
    
end

/**
 * Priority function for melee target.
 *
 * Returns newTarget it it is a better target, otherwise target.
 *
 * Default priority: closest enemy player, otherwise closest enemy melee target
 */
local function IsBetterMeleeTarget(weapon, player, newTarget, target)

    local teamNumber = GetEnemyTeamNumber(player:GetTeamNumber())

    if IsPossibleMeleeTarget(player, newTarget, teamNumber) then
    
        if not target or (not target:isa("Player") and newTarget:isa("Player")) then
            return true
        end
        
    end
    
    return false
    
end

// melee targets must be in front of the player
local function IsNotBehind(fromPoint, hitPoint, forwardDirection)

    local startPoint = fromPoint + forwardDirection * 0.1

    local toHitPoint = hitPoint - startPoint
    toHitPoint:Normalize()

    return forwardDirection:DotProduct(toHitPoint) > 0

end

// The order in which we do the traces - middle first, the corners last.
local kTraceOrder = { 4, 1, 3, 5, 7, 0, 2, 6, 8 }
/**
 * Checks if a melee capsule would hit anything. Does not actually carry
 * out any attack or inflict any damage.
 *
 * Target prio algorithm: 
 * First, a small box (the size of a rifle but or a skulks head) is moved along the view-axis, colliding
 * with everything. The endpoint of this trace is the attackEndPoind
 *
 * Second, a new trace to the attackEndPoint using the full size of the melee box is done. This trace
 * is done WITHOUT REGARD FOR GEOMETRY, and uses an entity-filter that tracks targets as they come,
 * and prioritizes them.
 *
 * Basically, inside the range to the attackEndPoint, the attacker chooses the "best" target freely.
 */
 /**
  * Bullets are small and will hit exactly where you looked. 
  * Melee, however, is different. We select targets from a volume, and we expect the melee'er to be able
  * to basically select the "best" target from that volume. 
  * Right now, the Trace methods available is limited (spheres or world-axis aligned boxes), so we have to
  * compensate by doing multiple traces.
  * We specify the size of the width and base height and its range.
  * Then we split the space into 9 parts and trace/select all of them, choose the "best" target. If no good target is found,
  * we use the middle trace for effects.
  */
function CheckMeleeCapsule(weapon, player, damage, range, optionalCoords, traceRealAttack, scale, priorityFunc, filter)

    scale = scale or 1

    local eyePoint = player:GetEyePos()
    
    if not teamNumber then
        teamNumber = GetEnemyTeamNumber( player:GetTeamNumber() )
    end
    
    local coords = optionalCoords or player:GetViewAngles():GetCoords()
    local axis = coords.zAxis
    local forwardDirection = Vector(coords.zAxis)
    forwardDirection.y = 0

    if forwardDirection:GetLength() ~= 0 then
        forwardDirection:Normalize()
    end
    
    local width, height = weapon:GetMeleeBase()
    width = scale * width
    height = scale * height
    
    /*
    if Client then
        Client.DebugCapsule(eyePoint, eyePoint + axis * range, width, 0, 3)
    end
    */
    
    // extents defines a world-axis aligned box, so x and z must be the same. 
    local extents = Vector(width / 6, height / 6, width / 6)
    if not filter then
        filter = EntityFilterOne(player)
    end
    local middleTrace,middleStart
    local target,endPoint,surface,startPoint
    
    if not priorityFunc then
        priorityFunc = IsBetterMeleeTarget
    end
    
    for _, pointIndex in ipairs(kTraceOrder) do
    
        local dx = pointIndex % 3 - 1
        local dy = math.floor(pointIndex / 3) - 1
        local point = eyePoint + coords.xAxis * (dx * width / 3) + coords.yAxis * (dy * height / 3)
        local trace, sp, ep = TraceMeleeBox(weapon, point, axis, extents, range, PhysicsMask.Melee, filter)
        
        if dx == 0 and dy == 0 then
            middleTrace, middleStart = trace, sp
        end
        
        if trace.entity and priorityFunc(weapon, player, trace.entity, target) and IsNotBehind(eyePoint, trace.endPoint, forwardDirection) then
        
            target = trace.entity
            startPoint = sp
            endPoint = trace.endPoint
            surface = trace.surface
            
        end
        
    end
    
    // if we have not found a target, we use the middleTrace to possibly bite a wall (or when cheats are on, teammates)
    target = target or middleTrace.entity
    endPoint = endPoint or middleTrace.endPoint
    surface = surface or middleTrace.surface
    startPoint = startPoint or middleStart
    
    local direction = target and (endPoint - startPoint):GetUnit() or coords.zAxis
    return target ~= nil or middleTrace.fraction < 1, target, endPoint, direction, surface
    
end

local kNumMeleeZones = 3
local kRangeMult = 0 // 0.15
function PerformGradualMeleeAttack(weapon, player, damage, range, optionalCoords, altMode, filter)

    local didHit, target, endPoint, direction, surface
    local didHitNow
    local damageMult = 1
    local stepSize = 1 / kNumMeleeZones
    
    for i = 1, kNumMeleeZones do
    
        local attackRange = range * (1 - (i-1) * kRangeMult)
        didHitNow, target, endPoint, direction, surface = CheckMeleeCapsule(weapon, player, damage, range, optionalCoords, true, i * stepSize, nil, filter)
        didHit = didHit or didHitNow
        if target and didHitNow then
            
            if target:isa("Player") then
                damageMult = 1 - (i - 1) * stepSize
            end

            break
            
        end
        
    end
    
    if didHit then
        weapon:DoDamage(damage * damageMult, target, endPoint, direction, surface, altMode)
    end
    
    return didHit, target, endPoint, direction, surface

end

/**
 * Does an attack with a melee capsule.
 */
function AttackMeleeCapsule(weapon, player, damage, range, optionalCoords, altMode, filter)

    local targets = {}
    local didHit, target, endPoint, direction, surface
    
    if not filter then
        filter = EntityFilterTwo(player, weapon)
    end

    for i = 1, 20 do
    
        local traceFilter = function(test)
            return EntityFilterList(targets)(test) or filter(test)
        end
    
        // Enable tracing on this capsule check, last argument.
        didHit, target, endPoint, direction, surface = CheckMeleeCapsule(weapon, player, damage, range, optionalCoords, true, 1, nil, traceFilter)
        local alreadyHitTarget = target ~= nil and table.contains(targets, target)

        if didHit and not alreadyHitTarget then
            weapon:DoDamage(damage, target, endPoint, direction, surface, altMode)
        end
        
        if target and not alreadyHitTarget then
            table.insert(targets, target)
        end
        
        if not target or not HasMixin(target, "SoftTarget") then
            break
        end
    
    end
    
    return didHit, targets[#targets], endPoint, surface
    
end

local kExplosionDirections =
{
    Vector(0, 1, 0),
    Vector(0, -1, 0),
    Vector(1, 0, 0),
    Vector(-1, 0, 0),
    Vector(1, 0, 0),
    Vector(0, 0, 1),
    Vector(0, 0, -1),
}

function CreateExplosionDecals(triggeringEntity, effectName)

    effectName = effectName or "explosion_decal"

    local startPoint = triggeringEntity:GetOrigin() + Vector(0, 0.2, 0)
    for i = 1, #kExplosionDirections do
    
        local direction = kExplosionDirections[i]
        local trace = Shared.TraceRay(startPoint, startPoint + direction * 2, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterAll())

        if trace.fraction ~= 1 then
        
            local coords = Coords.GetTranslation(trace.endPoint)
            coords.yAxis = trace.normal
            coords.zAxis = trace.normal:GetPerpendicular()
            coords.xAxis = coords.zAxis:CrossProduct(coords.yAxis)

            triggeringEntity:TriggerEffects(effectName, {effecthostcoords = coords})
        
        end
    
    end

end

function BuildClassToGrid()

    local ClassToGrid = { }
    
    ClassToGrid["Undefined"] = { 5, 8 }

    ClassToGrid["TechPoint"] = { 1, 1 }
    ClassToGrid["ResourcePoint"] = { 2, 1 }
    ClassToGrid["Door"] = { 3, 1 }
    ClassToGrid["DoorLocked"] = { 4, 1 }
    ClassToGrid["DoorWelded"] = { 5, 1 }
    ClassToGrid["Grenade"] = { 6, 1 }
    ClassToGrid["PowerPoint"] = { 7, 1 }
    
    ClassToGrid["Scan"] = { 6, 8 }
    ClassToGrid["HighlightWorld"] = { 4, 6 }

    ClassToGrid["ReadyRoomPlayer"] = { 1, 2 }
    ClassToGrid["Marine"] = { 1, 2 }
    ClassToGrid["Exo"] = { 2, 2 }
    ClassToGrid["JetpackMarine"] = { 3, 2 }
    ClassToGrid["HeavyArmorMarine"] = { 2, 2 }
    ClassToGrid["MAC"] = { 4, 2 }
    ClassToGrid["CommandStationOccupied"] = { 5, 2 }
    ClassToGrid["CommandStationL2Occupied"] = { 6, 2 }
    ClassToGrid["CommandStationL3Occupied"] = { 7, 2 }
    ClassToGrid["Death"] = { 8, 2 }

    ClassToGrid["Skulk"] = { 1, 3 }
    ClassToGrid["Gorge"] = { 2, 3 }
    ClassToGrid["Lerk"] = { 3, 3 }
    ClassToGrid["Fade"] = { 4, 3 }
    ClassToGrid["Onos"] = { 5, 3 }
    ClassToGrid["Drifter"] = { 6, 3 }
    ClassToGrid["HiveOccupied"] = { 7, 3 }
    ClassToGrid["Kill"] = { 8, 3 }

    ClassToGrid["CommandStation"] = { 1, 4 }
    ClassToGrid["Extractor"] = { 4, 4 }
    ClassToGrid["Sentry"] = { 5, 4 }
    ClassToGrid["ARC"] = { 6, 4 }
    ClassToGrid["ARCDeployed"] = { 7, 4 }
    ClassToGrid["SentryBattery"] = { 8, 4 }

    ClassToGrid["InfantryPortal"] = { 1, 5 }
    ClassToGrid["Armory"] = { 2, 5 }
    ClassToGrid["AdvancedArmory"] = { 3, 5 }
    ClassToGrid["AdvancedArmoryModule"] = { 4, 5 }
    ClassToGrid["PhaseGate"] = { 5, 5 }
    ClassToGrid["Observatory"] = { 6, 5 }
    ClassToGrid["RoboticsFactory"] = { 7, 5 }
    ClassToGrid["ArmsLab"] = { 8, 5 }
    ClassToGrid["PrototypeLab"] = { 4, 4 }

    ClassToGrid["HiveBuilding"] = { 1, 6 }
    ClassToGrid["Hive"] = { 2, 6 }
    ClassToGrid["Infestation"] = { 4, 6 }
    ClassToGrid["Harvester"] = { 5, 6 }
    ClassToGrid["Hydra"] = { 6, 6 }
    ClassToGrid["Egg"] = { 7, 6 }
    ClassToGrid["Embryo"] = { 7, 6 }
    
    ClassToGrid["Shell"] = { 8, 6 }
    ClassToGrid["Spur"] = { 7, 7 }
    ClassToGrid["Veil"] = { 8, 7 }

    ClassToGrid["Crag"] = { 1, 7 }
    ClassToGrid["Whip"] = { 3, 7 }
    ClassToGrid["Shade"] = { 5, 7 }
    ClassToGrid["Shift"] = { 6, 7 }

    ClassToGrid["WaypointMove"] = { 1, 8 }
    ClassToGrid["WaypointDefend"] = { 2, 8 }
    ClassToGrid["TunnelEntrance"] = { 3, 8 }
    ClassToGrid["PlayerFOV"] = { 4, 8 }
    
    ClassToGrid["MoveOrder"] = { 1, 8 }
    ClassToGrid["BuildOrder"] = { 2, 8 }
    ClassToGrid["AttackOrder"] = { 2, 8 }
    
    ClassToGrid["SensorBlip"] = { 5, 8 }
    ClassToGrid["EtherealGate"] = { 8, 1 }
    
    ClassToGrid["Player"] = { 7, 8 }
    
    return ClassToGrid
    
end

/**
 * Returns Column and Row to find the minimap icon for the passed in class.
 */
function GetSpriteGridByClass(class, classToGrid)

    // This really shouldn't happen but lets return something just in case.
    if not classToGrid[class] then
        Print("No sprite defined for minimap icon %s", class)
        Print(debug.traceback())
        return 8, 8
    end
    
    return unpack(classToGrid[class])
    
end

/*
 * Non-linear egg spawning. Eggs spawn slower the more of them you have, but speed up with more players. 
 * Pass in the number of players currently on your team, and the number of egg that this will be (ie, with
 * no eggs, pass in 1 to find out how long it will take for the first egg to spawn in).
 */
function CalcEggSpawnTime(numPlayers, eggNumber, numDeadPlayers)
    return kEggSpawnTime

    //local clampedEggNumber = Clamp(eggNumber, 1, kAlienEggsPerHive)
    //local clampedNumPlayers = Clamp(numPlayers, 1, kMaxPlayers/2)
    
    //local calcEggScalar = math.sin(((clampedEggNumber - 1)/kAlienEggsPerHive) * (math.pi / 2)) * kAlienEggSinScalar
    //local calcSpawnTime = kAlienEggMinSpawnTime + (calcEggScalar / clampedNumPlayers) * kAlienEggPlayerScalar
    
    //return Clamp(calcSpawnTime, kAlienEggMinSpawnTime, kAlienEggMaxSpawnTime)
    
end


function CheckWeaponForFocus(doer, player)
    
    local hasupg, level = GetHasFocusUpgrade(player)
    if doer == nil then 
        return 0 
    end
    if doer and hasupg and level > 0 then
        if doer.GetAbilityUsesFocus and doer:GetAbilityUsesFocus() then
            return level    
        end
    end
    return 0
end

gEventTiming = {}
function LogEventTiming()
    if Shared then
        table.insert(gEventTiming, Shared.GetTime())
    end
end

function GetEventTimingString(seconds)

    local logTime = Shared.GetTime() - seconds
    
    local count = 0
    for index, time in ipairs(gEventTiming) do
    
        if time >= logTime then
            count = count + 1
        end
        
    end
    
    return string.format("%d events in past %d seconds (%.3f avg delay).", count, seconds, seconds/count)
    
end

function GetIsVortexed(entity)
    return false
end

function GetIsNanoShielded(entity)
    return false
end

if Client then

    local kMaxPitch = Math.Radians(89.9)
    function ClampInputPitch(input)
        input.pitch = Math.Clamp(input.pitch, -kMaxPitch, kMaxPitch)
    end
    
    // &ol& = order location
    // &ot& = order target entity name
    function TranslateHintText(text)
    
        local translatedText = text
        local player = Client.GetLocalPlayer()
        
        if player and HasMixin(player, "Orders") then
        
            local order = player:GetCurrentOrder()
            if order then
            
                local orderDestination = order:GetLocation()
                local location = GetLocationForPoint(orderDestination)
                local orderLocationName = location and location:GetName() or ""
                translatedText = string.gsub(translatedText, "&ol&", orderLocationName)
                
                local orderTargetEntityName = LookupTechData(order:GetParam(), kTechDataDisplayName, "<entity name>")
                translatedText = string.gsub(translatedText, "&ot&", orderTargetEntityName)
                
            end
            
        end
        
        return translatedText
        
    end
    
end

gSpeedDebug = nil

function SetSpeedDebugText(text, text2)

    if gSpeedDebug then
        gSpeedDebug:SetDebugText(text, text2)
    end
    
end

// returns pairs of impact point, entity
function TraceBullet(player, weapon, startPoint, direction, throughHallucinations, throughUnits)

    local hitInfo = {}
    local lastHitEntity = player
    local endPoint = startPoint + direction * 1000
    
    local maxTraces = 3
    
    for i = 1, maxTraces do
    
        local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterTwo(lastHitEntity, weapon))
        
        if trace.fraction ~= 1 then
        
            table.insertunique(hitInfo, { EndPoint = trace.endPoint, Entity = trace.entity } )

            if trace.entity or throughUnits == true then
                startPoint = Vector(trace.endPoint)
                lastHitEntity = trace.entity
            else
                break
            end    
        
        else
            break
        end    
        
    end

    return hitInfo

end

-- add comma to separate thousands
function CommaValue(amount)

    local formatted = ""
    if amount ~= nil then
        formatted = amount
        while true do  
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
            if (k==0) then
                break
            end
        end
    end
    return formatted
    
end

/**
 * Trim off unnecessary path and extension.
 */
function GetTrimmedMapName(mapName)

    if mapName == nil then
        return ""
    end
    
    for trimmedName in string.gmatch(mapName, [[\/(.+)\.level]]) do
        return trimmedName
    end
    
    return mapName
    
end

// Look for "BIND_" in the string and substitute with key to press
// ie, "Press the BIND_Buy key to evolve to a new lifeform or to gain new upgrades." => "Press the B key to evolve to a new lifeform or to gain new upgrades."
function SubstituteBindStrings(tipString)

    local substitutions = { }
    for word in string.gmatch(tipString, "BIND_(%a+)") do
    
        local bind = GetPrettyInputName(word)
        if type(bind) == "string" then
            tipString = string.gsub(tipString, "BIND_" .. word, bind)
        // If the input name is not found, replace the BIND_InputName with just InputName as a fallback.
        else
            tipString = string.gsub(tipString, "BIND_" .. word, word)
        end
        
    end
    
    return tipString
    
end

// Look up texture coordinates in kInventoryIconsTexture
// Used for death messages, inventory icons, and abilities drawn in the alien "energy ball"
gTechIdPosition = nil
function GetTexCoordsForTechId(techId)

    local x1 = 0
    local y1 = 0
    local x2 = kInventoryIconTextureWidth
    local y2 = kInventoryIconTextureHeight
    
    if not gTechIdPosition then
    
        gTechIdPosition = {}
        
        // marine weapons
        gTechIdPosition[kTechId.Rifle] = kDeathMessageIcon.Rifle
        gTechIdPosition[kTechId.Pistol] = kDeathMessageIcon.Pistol
        gTechIdPosition[kTechId.Axe] = kDeathMessageIcon.Axe
        gTechIdPosition[kTechId.Shotgun] = kDeathMessageIcon.Shotgun
        gTechIdPosition[kTechId.HeavyMachineGun] = kDeathMessageIcon.HeavyMachineGun
        gTechIdPosition[kTechId.HandGrenades] = kDeathMessageIcon.HandGrenade
        gTechIdPosition[kTechId.GrenadeLauncher] = kDeathMessageIcon.Grenade
        gTechIdPosition[kTechId.Welder] = kDeathMessageIcon.Welder
        gTechIdPosition[kTechId.Mines] = kDeathMessageIcon.Mine
        
        // alien abilities
        gTechIdPosition[kTechId.Bite] = kDeathMessageIcon.Bite
        gTechIdPosition[kTechId.Parasite] = kDeathMessageIcon.Parasite
        gTechIdPosition[kTechId.Leap] = kDeathMessageIcon.Leap
        gTechIdPosition[kTechId.Xenocide] = kDeathMessageIcon.Xenocide
        
        gTechIdPosition[kTechId.Spit] = kDeathMessageIcon.Spit
        gTechIdPosition[kTechId.BuildAbility] = kDeathMessageIcon.BuildAbility
        gTechIdPosition[kTechId.Spray] = kDeathMessageIcon.Spray
        gTechIdPosition[kTechId.BileBomb] = kDeathMessageIcon.BileBomb
        gTechIdPosition[kTechId.Web] = kDeathMessageIcon.BileBomb
        gTechIdPosition[kTechId.BabblerAbility] = kDeathMessageIcon.BabblerAbility
        
        gTechIdPosition[kTechId.LerkBite] = kDeathMessageIcon.LerkBite
        gTechIdPosition[kTechId.Spikes] = kDeathMessageIcon.Spikes
        gTechIdPosition[kTechId.Spores] = kDeathMessageIcon.SporeCloud
        gTechIdPosition[kTechId.Umbra] = kDeathMessageIcon.Umbra
        gTechIdPosition[kTechId.PrimalScream] = kDeathMessageIcon.Spikes
        
        gTechIdPosition[kTechId.Swipe] = kDeathMessageIcon.Swipe
        gTechIdPosition[kTechId.Blink] = kDeathMessageIcon.Blink
        gTechIdPosition[kTechId.Metabolize] = kDeathMessageIcon.Metabolize

        gTechIdPosition[kTechId.Gore] = kDeathMessageIcon.Gore
        gTechIdPosition[kTechId.Stomp] = kDeathMessageIcon.Stomp
        
    end
    
    local position = gTechIdPosition[techId]
    
    if position then
    
        y1 = (position - 1) * kInventoryIconTextureHeight
        y2 = y1 + kInventoryIconTextureHeight
    
    end
    
    return x1, y1, x2, y2

end

// Ex: input.commands = RemoveMoveCommand( input.commands, Move.PrimaryAttack )
function RemoveMoveCommand( commands, moveMask )
    local negMask = bit.bxor(0xFFFFFFFF, moveMask)
    return bit.band(commands, negMask)
end

function HasMoveCommand( commands, moveMask )
    return bit.band( commands, moveMask ) ~= 0
end

function AddMoveCommand( commands, moveMask )
    return bit.bor(commands, moveMask)
end

function GetCrags(teamNumber)

    if teamNumber then

        local teamInfo = GetTeamInfoEntity(teamNumber)  
        if teamInfo then
            return teamInfo.crags or 0
        end
        
    end
    
    return 0

end

function GetShifts(teamNumber)

    if teamNumber then

        local teamInfo = GetTeamInfoEntity(teamNumber)  
        if teamInfo then
            return teamInfo.shifts or 0
        end
        
    end
    
    return 0

end

function GetShades(teamNumber)

    if teamNumber then

        local teamInfo = GetTeamInfoEntity(teamNumber)  
        if teamInfo then
            return teamInfo.shades or 0
        end  
        
    end
    
    return 0

end

function GetWhips(teamNumber)

    if teamNumber then

        local teamInfo = GetTeamInfoEntity(teamNumber)  
        if teamInfo then
            return teamInfo.whips or 0
        end  
        
    end
    
    return 0

end

function GetChambers(techId, teamNumber)
    if techId == kTechId.Crag then
        return GetCrags(teamNumber)
    end
    if techId == kTechId.Shift then
        return GetShifts(teamNumber)
    end
    if techId == kTechId.Shade then
        return GetShades(teamNumber)
    end
    if techId == kTechId.Whip then
        return GetWhips(teamNumber)
    end
    return 0
end

function GetSelectablesOnScreen(commander, className, minPos, maxPos)

    assert(Client)

    if not className then
        className = "Entity"
    end
    
    local selectables = {}

    if not minPos then
        minPos = Vector(0,0,0)
    end
    
    if not maxPos then
        maxPos = Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0)
    end

    for _, selectable in ipairs(GetEntitiesWithMixinForTeam("Selectable", commander:GetTeamNumber())) do

        if selectable:isa(className) then

            local screenPos = Client.WorldToScreen(selectable:GetOrigin())
            if screenPos.x >= minPos.x and screenPos.x <= maxPos.x and
               screenPos.y >= minPos.y and screenPos.y <= maxPos.y then
        
                table.insert(selectables, selectable)
        
            end
        
        end

    end
    
    return selectables

end

function GetInstalledMapList()

    local matchingFiles = { }
    Shared.GetMatchingFileNames("maps/*.level", false, matchingFiles)
    
    local mapNames = { }
    local mapFiles = { }
    
    for _, mapFile in pairs(matchingFiles) do
    
        local _, _, filename = string.find(mapFile, "maps/(.*).level")
        local mapname = string.gsub(filename, 'ns2_', '', 1):gsub("^%l", string.upper)
        local tagged,_ = string.match(filename, "ns2_", 1)
        if tagged ~= nil then
        
            table.insert(mapNames, mapname)
            table.insert(mapFiles, {["name"] = mapname, ["fileName"] = filename})
            
        end
        
    end
    
    return mapNames, mapFiles
    
end

// TODO: move to Utility.lua

function EntityFilterList(list)
    return function(test) return table.contains(list, test) end
end

function GetBulletTargets(startPoint, endPoint, spreadDirection, bulletSize, filter)

    local targets = {}
    local hitPoints = {}
    local trace
    
    for i = 1, 20 do
    
        local traceFilter = nil 
        if filter then

            traceFilter = function(test)
                return EntityFilterList(targets)(test) or filter(test)
            end
        
        else        
            traceFilter = EntityFilterList(targets)        
        end
    
        trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, traceFilter)
        if not trace.entity then
            local extents = GetDirectedExtentsForDiameter(spreadDirection, bulletSize)
            trace = Shared.TraceBox(extents, startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, traceFilter)
        end
        
        if trace.entity and not table.contains(targets, trace.entity) then
        
            table.insert(targets, trace.entity)
            table.insert(hitPoints, trace.endPoint)
            
        end
        
        if (not trace.entity or not HasMixin(trace.entity, "SoftTarget")) or trace.fraction == 1 then
            break
        end
    
    end
    
    return targets, trace, hitPoints

end

local kAlienStructureMoveSound = PrecacheAsset("sound/NS2.fev/alien/infestation/build")
function UpdateAlienStructureMove(self, deltaTime)

    if Server then

        local currentOrder = self:GetCurrentOrder()
        if GetIsUnitActive(self) and currentOrder and currentOrder:GetType() == kTechId.Move then
        
            /*
            if not self.timeLastShiftCheck or self.timeLastShiftCheck + 0.5 < Shared.GetTime() then
                
                self.shiftBoost = self:isa("Shift") or #GetEntitiesForTeamWithinRange("Shift", self:GetTeamNumber(), self:GetOrigin(), 8) > 0
                self.timeLastShiftCheck = Shared.GetTime()
            
            end
            */

            local speed = self:GetMaxSpeed()
            if self.shiftBoost then
                speed = speed * kShiftStructurespeedScalar
            end
        
            self:MoveToTarget(PhysicsMask.AIMovement, currentOrder:GetLocation(), speed, deltaTime)
            
            if self:IsTargetReached(currentOrder:GetLocation(), kAIMoveOrderCompleteDistance) then
                self:CompletedCurrentOrder()
                self.moving = false
            else
                self.moving = true            
            end
            
        else
            self.moving = false
        end

        if HasMixin(self, "Obstacle") then

            if currentOrder and currentOrder:GetType() == kTechId.Move then
                self:RemoveFromMesh()
            elseif self.obstacleId == -1 then
                self:AddToMesh()
            end

        end   

    elseif Client then
    
        if self.clientMoving ~= self.moving then
        
            if self.moving then
                Shared.PlaySound(self, kAlienStructureMoveSound, 1)
            else
                Shared.StopSound(self, kAlienStructureMoveSound)
            end
            
            self.clientMoving = self.moving
        
        end
        
        if self.moving and (not self.timeLastDecalCreated or self.timeLastDecalCreated + 1.1 < Shared.GetTime() ) then
        
            self:TriggerEffects("structure_move")
            self.timeLastDecalCreated = Shared.GetTime()
        
        end
    
    end

end

function GetCommanderLogoutAllowed()

    return true
    
    /*

    local gameState = kGameState.PreGame
    local gameStateDuration = 0

    if Server then   

        local gamerules = GetGamerules()
        if gamerules then
        
            gameState = gamerules:GetGameState()
            gameStateDuration = gamerules:GetGameTimeChanged()
        
        end

    else  
    
        local gameInfo = GetGameInfoEntity()
        
        if gameInfo then
        
            gameState = gameInfo:GetState()
            gameStateDuration = math.max(0, Shared.GetTime() - gameInfo:GetStartTime())
            
        end

    end

    return ( gameState ~= kGameState.Countdown and gameState ~= kGameState.Started ) or gameStateDuration >= kCommanderMinTime
    
    */

end
