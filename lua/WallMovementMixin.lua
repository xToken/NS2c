// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\WallMovementMixin.lua    
//    
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
// Contains shared code used by Skulk to walk on walls and Lerks to grip walls.
// 
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

/**
 * WallMovementMixin handles processing attack orders.
 */
WallMovementMixin = CreateMixin(WallMovementMixin)
WallMovementMixin.type = "WallMovement"

WallMovementMixin.expectedMixins =
{
}

if Server then

    WallMovementMixin.expectedCallbacks =
    {
    }

end

WallMovementMixin.expectedConstants =
{
}

WallMovementMixin.networkVars =
{
}

function WallMovementMixin:__initmixin()
    self.smoothedYaw = self.viewYaw
end

/**
 * Smooth the currentNormal towards the goalNormal with the given fraction. 
 * Returns goalNormal if fraction >= 1
 */
function WallMovementMixin:SmoothWallNormal(currentNormal, goalNormal, fraction)
    local result = goalNormal;
    
    if fraction < 1 then
        local diff = goalNormal:DotProduct(currentNormal)
        
        // if we are "close enough", we make them equal - stop float rounding from eating bandwidth
        if diff < 0.98 then
 
            // Smooth out the normal.
            local normalDiff = goalNormal - currentNormal
            
            // Check if the vectors are polar opposites.
            if diff == -1 then
            
                // Prefer spinning around the x axis.
                if self:GetCoords().xAxis:DotProduct(goalNormal) ~= -1 then
                    normalDiff = goalNormal - self:GetCoords().xAxis
                else
                    normalDiff = goalNormal - currentNormal:GetPerpendicular()
                end
                
            end

            result = currentNormal + normalDiff * fraction
        end
    end

    if result:Normalize() < 0.01 then
        result = Vector(0, 1, 0)  
    end
    
    return result
end

function WallMovementMixin:GetAnglesFromWallNormal(normal)

    // Use the wall normal as Y, and try to point Z according to the view
    local c = Coords()
    c.yAxis = normal
    c.zAxis = self:GetViewAngles():GetCoords().zAxis
    c.xAxis = c.yAxis:CrossProduct(c.zAxis)

    if c.xAxis:Normalize() < 0.001 then
        
        // Can't really find a good coords, so just keep the previous one
        return nil

    else

        c.zAxis = c.xAxis:CrossProduct( c.yAxis )

        //DebugDrawAxes( c, self:GetOrigin(), 5.0, 0.5, 0.0 )

        local angles = Angles()
        angles:BuildFromCoords(c)
        return angles

    end

end

function WallMovementMixin:ValidWallTrace(trace)
    if trace.fraction > 0 and trace.fraction < 1 then
        local entity = trace.entity
        return not entity or (not entity.GetIsWallWalkingAllowed or entity:GetIsWallWalkingAllowed(self))
    end
    return false 
end

function WallMovementMixin:TraceWallNormal(startPoint, endPoint, result, feelerSize)
    
    local theTrace = Shared.TraceCapsule(startPoint, endPoint, feelerSize, 0, CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOneAndIsa(self, "Babbler"))
    
    if self:ValidWallTrace(theTrace) then    
        table.insert(result, theTrace.normal)
        /* double-comment to see wall-walk traces
        if Client then
            DebugLine(startPoint, theTrace.endPoint, 5, 0,1,0,1)
        end
        /**/

        return true
        
    end
    
    return false
    
end

/**
 * Returns the average normal within wall-walking range. Perform 8 trace lines in circle around us and 1 above us, but not below.
 * Returns nil if we aren't in range of a valid wall-walking surface.  For any surfaces hit, remember surface normal and average 
 * with others hit so we know if we're wall-walking and the normal to orient our model and the direction to jump away from
 * when jumping off a wall.
 */
function WallMovementMixin:GetAverageWallWalkingNormal(extraRange, feelerSize)
    
    local startPoint = Vector(self:GetOrigin())
    local extents = self:GetExtents()
    startPoint.y = startPoint.y + extents.y

    local numTraces = 8
    local wallNormals = {}
    
    // Trace in a circle around self, looking for walls we hit
    local wallWalkingRange = math.max(extents.x, extents.y) + extraRange
    local endPoint = Vector()
    
    for i = 0, numTraces - 1 do
    
        local angle = ((i * 360/numTraces) / 360) * math.pi * 2
        local directionVector = Vector(math.cos(angle), 0, math.sin(angle))
        
        // Avoid excess vector creation
        endPoint.x = startPoint.x + directionVector.x * wallWalkingRange
        endPoint.y = startPoint.y
        endPoint.z = startPoint.z + directionVector.z * wallWalkingRange
        self:TraceWallNormal(startPoint, endPoint, wallNormals, feelerSize)
        
    end
    
    // Trace above too.
    self:TraceWallNormal(startPoint, startPoint + Vector(0, wallWalkingRange, 0), wallNormals, feelerSize)
    
    // Average results
    local numNormals = table.maxn(wallNormals)
    
    if (numNormals > 0) then
    
        // Check if we are right above a surface we can stand on.
        // Even if we are in "wall walking mode", we want it to look
        // like it is standing on a surface if it is right above it.
        local groundTrace = Shared.TraceRay(startPoint, startPoint + Vector(0, -wallWalkingRange, 0), CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOne(self))
        if (groundTrace.fraction > 0 and groundTrace.fraction < 1 and groundTrace.entity == nil) then
            return groundTrace.normal
        end
        
        local average = Vector(0, 0, 0)
    
        for i,currentNormal in ipairs(wallNormals) do
            average = average + currentNormal
        end
        
        if (average:Normalize() > 0) then
            return average
        end
        
    end
    
    return nil
    
end

function WallMovementMixin:OnAdjustModelCoords(modelCoords)

    local offset = self:GetExtents().y

    // Make the model rotate around the center point rather than the feet
    // when we're walking on walls.

    modelCoords.origin = modelCoords.origin - modelCoords.yAxis * offset
    modelCoords.origin.y = modelCoords.origin.y + offset
            
    return modelCoords
    
end
