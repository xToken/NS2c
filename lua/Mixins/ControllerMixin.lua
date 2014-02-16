// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ControllerMixin.lua
//
//    Created by:   Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Vector.lua")

ControllerMixin = CreateMixin( ControllerMixin )
ControllerMixin.type = "Controller"

// The controller uses a 0.1m thick "skin" around it to handle collisions properly
local kSkinOffset = 0.1
        
ControllerMixin.expectedCallbacks =
{
    GetControllerSize = "Should return a height and radius",
    GetMovePhysicsMask = "Should return a mask for the physics groups to collide with",
    GetControllerPhysicsGroup = "Should return physics grouop for controller.",
}

ControllerMixin.optionalCallbacks =
{
    GetHasController = "Creates/destroys controller when returned true/false.",
    GetHasOutterController = "Creates/destroys outter controller when returned true/false."
}

ControllerMixin.networkVars =
{
    timeUntilPlayerCollisionsIgnored = "private time"
}

function ControllerMixin:__initmixin()

    self.controller = nil
    self.timeUntilPlayerCollisionsIgnored = 0
    
end

function ControllerMixin:OnDestroy()
    self:DestroyController()
    self:DestroyOutterController()
end

function ControllerMixin:CreateController()

    local physicsGroup = self:GetControllerPhysicsGroup()    
    
    self.controller = Shared.CreateCollisionObject(self)
    self.controller:SetGroup(physicsGroup)
    self.controller:SetTriggeringEnabled( true )

    // Make the controller kinematic so physically simulated objects will
    // interact/collide with it.
    self.controller:SetPhysicsType(CollisionObject.Kinematic)


end

function ControllerMixin:CreateOutterController()

    local physicsGroup = self:GetControllerPhysicsGroup()  
    
    self.controllerOutter = Shared.CreateCollisionObject(self)
    self.controllerOutter:SetGroup(physicsGroup)
    self.controllerOutter:SetTriggeringEnabled( false )
    self.controllerOutter:SetPhysicsType(CollisionObject.Kinematic) 
    
end

local function SetNearbyPlayerControllers(self, enabled)

    for _, player in ipairs(GetEntitiesWithinRange("Player", self:GetOrigin(), 4)) do
    
        if player ~= self then
        
            if player.controllerOutter then
                player.controllerOutter:SetCollisionEnabled(enabled)
            end
            
            if player.controller then
                player.controller:SetCollisionEnabled(enabled)
            end
        
        end
    
    end

end

function ControllerMixin:DestroyController()

    if self.controller ~= nil then
    
        Shared.DestroyCollisionObject(self.controller)
        self.controller = nil
        
    end
    
end

function ControllerMixin:DestroyOutterController()

    if self.controllerOutter then 

        Shared.DestroyCollisionObject(self.controllerOutter)
        self.controllerOutter = nil
        
    end
    
end

/**
 * Synchronizes the origin and shape of the physics controller with the current
 * state of the entity.
 */
local origin = Vector()
function ControllerMixin:UpdateControllerFromEntity(allowTrigger)

    PROFILE("ControllerMixin:UpdateControllerFromEntity")

    if allowTrigger == nil then
        allowTrigger = true
    end

    if self.controller ~= nil then
    
        local controllerHeight, controllerRadius = self:GetControllerSize()
        
        if controllerHeight ~= self.controllerHeight or controllerRadius ~= self.controllerRadius then
        
            self.controllerHeight = controllerHeight
            self.controllerRadius = controllerRadius
        
            local capsuleHeight = controllerHeight - 2*controllerRadius
        
            if capsuleHeight < 0.001 then
                // Use a sphere controller
                self.controller:SetupSphere( controllerRadius, self.controller:GetCoords(), allowTrigger )
            else
                // A flat bottomed cylinder works well for movement since we don't
                // slide down as we walk up stairs or over other lips. The curved
                // edges of the cylinder allows players to slide off when we hit them,
                self.controller:SetupCapsule( controllerRadius, capsuleHeight, self.controller:GetCoords(), allowTrigger )
                //self.controller:SetupCylinder( controllerRadius, controllerHeight, self.controller:GetCoords(), allowTrigger )
            end

            if self.controllerOutter then                
                //self.controllerOutter:SetupBox(Vector(self.controllerRadius * 1.3, self.controllerHeight * 0.5, self.controllerRadius * 1.3), self.controller:GetCoords(), allowTrigger)
                self.controllerOutter:SetupCylinder( controllerRadius * 1.5, controllerHeight, self.controller:GetCoords(), allowTrigger )
            end                
            
            // Remove all collision reps except movement from the controller.
            for value,name in pairs(CollisionRep) do
                if value ~= CollisionRep.Move and type(name) == "string" then
                
                    self.controller:RemoveCollisionRep(value)
                    
                    if self.controllerOutter then
                        self.controllerOutter:RemoveCollisionRep(value)
                    end
                    
                end
            end
            
            self.controller:SetTriggeringCollisionRep(CollisionRep.Move)
            self.controller:SetPhysicsCollisionRep(CollisionRep.Move)
 
        end
        
        // The origin of the controller is at its center and the origin of the
        // player is at their feet, so offset it.
        VectorCopy(self:GetOrigin(), origin)
        origin.y = origin.y + self.controllerHeight * 0.5 + kSkinOffset
        
        self.controller:SetPosition(origin, allowTrigger)
        
        if self.controllerOutter then  
            self.controllerOutter:SetPosition(origin, allowTrigger)
        end    
        
    end
    
end


/**
 * Synchronizes the origin of the entity with the current state of the physics
 * controller.
 */
function ControllerMixin:UpdateOriginFromController()

    // The origin of the controller is at its center and the origin of the
    // player is at their feet, so offset it.
    local origin = Vector(self.controller:GetPosition())
    origin.y = origin.y - self.controllerHeight * 0.5 - kSkinOffset
    
    self:SetOrigin(origin)
    
end

function ControllerMixin:SetIgnorePlayerCollisions(time)
    self.timeUntilPlayerCollisionsIgnored = time + Shared.GetTime()
end

function ControllerMixin:GetPlayerCollisionsIgnored()
    return self.timeUntilPlayerCollisionsIgnored ~= 0 and self.timeUntilPlayerCollisionsIgnored >= Shared.GetTime()
end

function ControllerMixin:OnUpdatePhysics()

    local hasController = not self.GetHasController or self:GetHasController()
    local hasOutterController = not self.GetHasOutterController or self:GetHasOutterController()

    if not self.controller and hasController then
        self:CreateController()
    elseif self.controller and not hasController then
        self:DestroyController()
    end    
    
    if not self.controllerOutter and hasOutterController then
        self:CreateOutterController()
    elseif self.controllerOutter and not hasOutterController then
        self:DestroyOutterController()
    end

    self:UpdateControllerFromEntity()
end

/** 
 * Returns true if the entity is colliding with anything that passes its movement
 * mask at its current position.
 */
function ControllerMixin:GetIsColliding()

    PROFILE("ControllerMixin:GetIsColliding")

    if self.controller then
    
        if self.controllerOutter then
            self.controllerOutter:SetCollisionEnabled(false)
        end
        
        self:UpdateControllerFromEntity()
        
        local result = self.controller:Test(CollisionRep.Move, CollisionRep.Move, self:GetMovePhysicsMask())
        
        if self.controllerOutter then
            self.controllerOutter:SetCollisionEnabled(true)
        end
        
        return result
        
    end
    
    return false

end

/**
 * Moves by the player by the specified offset, colliding and sliding with the world.
 */
function ControllerMixin:PerformMovement(offset, maxTraces, velocity, isMove, slowDownFraction, deflectMove, slowDownFilterFunc)

    PROFILE("ControllerMixin:PerformMovement")
    
    if isMove == nil then
        isMove = true
    end
    
    if deflectMove == nil then
        deflectMove = false
    end
    
    if slowDownFraction == nil then
        slowDownFraction = 1
    end
    
    local hitEntities = nil
    local completedMove = true
    local averageSurfaceNormal = nil
    local oldVelocity = velocity ~= nil and Vector(velocity) or nil
    local prevXZSpeed = velocity ~= nil and velocity:GetLengthXZ()
    local hitVelocity = nil
    
    local ignorePlayerCollisions = self:GetPlayerCollisionsIgnored()

    if self.controller then
        
        if self.controllerOutter then
            self.controllerOutter:SetCollisionEnabled(false)        
        end
        
        if ignorePlayerCollisions then
            SetNearbyPlayerControllers(self, false)        
        end
 
        self:UpdateControllerFromEntity()
        
        local tracesPerformed = 0
        
        while offset:GetLengthSquared() > 0.0 and tracesPerformed < maxTraces do
        
            local trace = self.controller:Move(offset, CollisionRep.Move, CollisionRep.Move, self:GetMovePhysicsMask())
            
            if trace.fraction < 1 then

                // Remove the amount of the offset we've already moved.
                offset = offset * (1 - trace.fraction)
                
                // Make the motion perpendicular to the surface we collided with so we slide.
                offset = offset - offset:GetProjection(trace.normal) // + trace.normal*0.001
                
                // Redirect velocity if specified
                if velocity ~= nil then
                
                    // Scale it according to how much velocity we lost
                    local newVelocity = velocity - velocity:GetProjection(trace.normal) * slowDownFraction // + trace.normal*0.001
                    
                    // Copy it so it's changed for caller
                    VectorCopy(newVelocity, velocity)
                    
                end
                
                if not averageSurfaceNormal then
                    averageSurfaceNormal = Vector(trace.normal)
                else
                
                    averageSurfaceNormal = averageSurfaceNormal + trace.normal
                    if averageSurfaceNormal:GetLength() > 0 then
                        averageSurfaceNormal:Normalize()
                    end
                
                end
                
                // Defer the processing of the callbacks until after we've finished moving,
                // since the callbacks may modify our self an interfere with our loop
                if trace.entity ~= nil and trace.entity.OnCapsuleTraceHit ~= nil then
                
                    if hitEntities == nil then
                        hitEntities = { trace.entity }
                    else
                        table.insert(hitEntities, trace.entity)
                    end

                end
                
                if trace.entity and trace.entity.GetVelocity and trace.entity:GetVelocity() then
                    hitVelocity = trace.entity:GetVelocity()
                end
                
                completedMove = false
                
            else
                offset = Vector(0, 0, 0)
            end
            
            tracesPerformed = tracesPerformed + 1
            
        end
        
        if isMove then
            self:UpdateOriginFromController()
        end
        
        if self.controllerOutter then
            self.controllerOutter:SetCollisionEnabled(true)
        end
        
        if ignorePlayerCollisions then
            SetNearbyPlayerControllers(self, true)        
        end
        
    end
    
    // Do the hit callbacks.
    if hitEntities and isMove then
        
        /*
        if hitVelocity and oldVelocity then
        
            hitVelocity.y = 0
            local addSpeed = Clamp(oldVelocity:DotProduct(hitVelocity), 0, prevXZSpeed)
            if addSpeed > 0 then            
                velocity:Add(addSpeed * GetNormalizedVector(oldVelocity))
            end
        
        end
        */
        for index, entity in ipairs(hitEntities) do
        
            entity:OnCapsuleTraceHit(self)
            self:OnCapsuleTraceHit(entity)
            
        end
        
    end

    if velocity and oldVelocity and not deflectMove then
        
        // edge case when jumping down slopes. we never want that the controller can add speed
        local newXZSpeed = velocity:GetLengthXZ()
        if newXZSpeed > prevXZSpeed then
            
            local ySpeed = velocity.y
            velocity.y = 0
            velocity:Scale(prevXZSpeed / newXZSpeed)
            velocity.y = ySpeed
            
        end
        
    end

    -- TODO: dont compare velocities, use some boolean
    -- averageSurfaceNormal should not normally be nil at this point but there is an edge
    -- case where it is.
    if oldVelocity ~= velocity and isMove and averageSurfaceNormal and self.OnWorldCollision then
    
        local impactForce = math.max(0, (-averageSurfaceNormal):DotProduct(oldVelocity))    
        self:OnWorldCollision(averageSurfaceNormal, impactForce, velocity)
        
    end
    
    return completedMove, hitEntities, averageSurfaceNormal
    
end
