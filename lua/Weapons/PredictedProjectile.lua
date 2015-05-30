// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\PredictedProjectile.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

PredictedProjectileShooterMixin = CreateMixin(PredictedProjectileShooterMixin)
PredictedProjectileShooterMixin.type = "PredictedProjectile"

local function UpdateRenderCoords(self)

    if not self.renderCoords then
        self.renderCoords = Coords.GetIdentity()
    end
    
    if self.lastOrigin and self.lastOrigin ~= self:GetOrigin() then
        
        local direction = GetNormalizedVector(self:GetOrigin() - self.lastOrigin)
        self.renderCoords.zAxis = direction
        self.renderCoords.xAxis = self.renderCoords.yAxis:CrossProduct(self.renderCoords.zAxis)
        self.renderCoords.xAxis:Normalize()
        self.renderCoords.yAxis = self.renderCoords.zAxis:CrossProduct(self.renderCoords.xAxis)
        self.renderCoords.yAxis:Normalize()
        
    end
    
    self.renderCoords.origin = self:GetOrigin()    
    self.lastOrigin = self:GetOrigin()

end

local kMaxNumProjectiles = 200

function PredictedProjectileShooterMixin:__initmixin()
    self.nextProjectileId = 1
    self.predictedProjectiles = {}
end

function PredictedProjectileShooterMixin:CreatePredictedProjectile(className, startPoint, velocity, bounce, friction, gravity, model)

    if Predict or (not Server and _G[className].kUseServerPosition) then
        return nil
    end
    
    local clearOnImpact = _G[className].kClearOnSurfaceImpact
    local clearOnEntityImpact = _G[className].kClearOnEntityImpact
    local detonateWithTeam = _G[className].kClearOnEnemyImpact and GetEnemyTeamNumber(self:GetTeamNumber()) or -1
    local clearOnSelfImpact = _G[className].kClearOnSelfImpact
    local detonateRadius = _G[className].kDetonateRadius
    
    local minLifeTime = _G[className].kMinLifeTime

    local projectile = nil
    local projectileController = ProjectileController()
    projectileController:Initialize(startPoint, velocity, _G[className].kRadius, self, bounce, friction, gravity, detonateWithTeam, clearOnImpact, clearOnEntityImpact, clearOnSelfImpact, minLifeTime, detonateRadius )
    projectileController.projectileId = self.nextProjectileId
    projectileController.modelName = _G[className].kModelName
    
    local projectileEntId = Entity.invalidId
    
    if Server then
    
        projectile = CreateEntity(_G[className].kMapName, startPoint, self:GetTeamNumber())
        projectile.projectileId = self.nextProjectileId
        
        projectileEntId = projectile:GetId()
        projectile:SetOwner(self)
        
        projectile:SetProjectileController(projectileController, self.isHallucination == true)
        
    end
    
    local projectileModel = nil
    local projectileCinematic = nil
    
    if Client then
    
        local coords = Coords.GetLookIn(startPoint, GetNormalizedVector(velocity))
        
        if _G[className].kModelName then
        
            local modelIndex = nil
            
            if model ~= nil then 
                modelIndex = Shared.GetModelIndex(model)
            else 
                modelIndex = Shared.GetModelIndex(_G[className].kModelName)
            end
            
            if modelIndex then
            
                projectileModel = Client.CreateRenderModel(RenderScene.Zone_Default)
                projectileModel:SetModel(modelIndex)
                projectileModel:SetCoords(coords)
                
            end
        
        end
        
        local cinematicName = _G[className].kProjectileCinematic
        
        if cinematicName then
        
            projectileCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
            projectileCinematic:SetCinematic(cinematicName)          
            projectileCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)                
            projectileCinematic:SetIsVisible(true)
            projectileCinematic:SetCoords(coords)
        
        end
    
    end
    
    self.predictedProjectiles[self.nextProjectileId] = { Controller = projectileController, Model = projectileModel, EntityId = projectileEntId, CreationTime = Shared.GetTime(), Cinematic = projectileCinematic }
    
    if not _G[className].kUseServerPosition then
    
        self.nextProjectileId = self.nextProjectileId + 1
        if self.nextProjectileId > kMaxNumProjectiles then
            self.nextProjectileId = 1
        end
    
    end
    
    return projectile

end

local function UpdateProjectiles(self, input, predict)

    local cleanUp = {}

    for projectileId, entry in pairs(self.predictedProjectiles) do

        local projectile = Shared.GetEntity(entry.EntityId)
        if not predict then
            entry.Controller:Update(input.time, projectile, predict)
        end
        
        if not Server then
 
            UpdateRenderCoords(entry.Controller)

            local renderCoords = entry.Controller.renderCoords

            local isVisible = entry.Controller.stopSimulation ~= true
 
            if entry.Model then
                entry.Model:SetCoords(renderCoords)
                entry.Model:SetIsVisible(isVisible)

            end
            
            if entry.Cinematic then
                entry.Cinematic:SetCoords(renderCoords)
                entry.Cinematic:SetIsVisible(isVisible)
            end
        
        end
        
        if entry.EntityId == Entity.invalidId and Shared.GetTime() - entry.CreationTime > 5 then
            table.insert(cleanUp, projectileId)
        end
    
    end
    
    for i = 1, #cleanUp do    
        self:SetProjectileDestroyed(cleanUp[i])    
    end
    
end    
if Server then
    function PredictedProjectileShooterMixin:OnProcessMove(input)
        UpdateProjectiles(self, input, false)
    end
elseif Client then
    function PredictedProjectileShooterMixin:OnProcessIntermediate(input)
        UpdateProjectiles(self, input, false)
    end
end

function PredictedProjectileShooterMixin:OnEntityChange(oldId)

    for projectileId, entry in pairs(self.predictedProjectiles) do
    
        if entry.EntityId == oldId then
        
            self:SetProjectileDestroyed(projectileId)            
            break
            
        end
    
    end

end

local function DestroyProjectiles(self)

    for projectileId, entry in pairs(self.predictedProjectiles) do
    
        local projectile = Shared.GetEntity(entry.EntityId)
        if projectile then
        
            projectile:SetProjectileController(entry.Controller, true)
            if entry.Model then
                Client.DestroyRenderModel(entry.Model)
            end
            
            if entry.Cinematic then
                Client.DestroyCinematic(entry.Cinematic)
            end
            
        end
    
    end
    
    self.predictedProjectiles = {}

end

if Server then

    function PredictedProjectileShooterMixin:OnUpdate(deltaTime)
        DestroyProjectiles(self)
    end

end

function PredictedProjectileShooterMixin:OnDestroy()
    DestroyProjectiles(self)
end

function PredictedProjectileShooterMixin:SetProjectileEntity(projectile)

    local entry = self.predictedProjectiles[projectile.projectileId]
    if entry then
        entry.EntityId = projectile:GetId()
    end

end

function PredictedProjectileShooterMixin:SetProjectileDestroyed(projectileId)

    local entry = self.predictedProjectiles[projectileId]

    if entry then

        if entry.Model then
            Client.DestroyRenderModel(entry.Model)
        end
        
        if entry.Cinematic then
            Client.DestroyCinematic(entry.Cinematic)
        end

        if entry.Controller then
            entry.Controller:Uninitialize()
        end

        self.predictedProjectiles[projectileId] = nil
    
    end

end

class 'ProjectileController'

function ProjectileController:Initialize(startPoint, velocity, radius, predictor, bounce, friction, gravity, detonateWithTeam, clearOnSurfaceImpact, clearOnEntityImpact, clearOnSelfImpact, minLifeTime, detonateRadius)

    self.creationTime = Shared.GetTime()

    self.controller = Shared.CreateCollisionObject(predictor)
    self.controller:SetPhysicsType(CollisionObject.Kinematic)
    self.controller:SetGroup(PhysicsGroup.ProjectileGroup)
    self.controller:SetupSphere(radius or 0.1, self.controller:GetCoords(), false)
    
    self.velocity = Vector(velocity)
    self.bounce = bounce or 0.5
    self.friction = friction or 0
    self.gravity = gravity or 9.81
    
    self.controller:SetPosition(startPoint, false)
    
    self.minLifeTime = minLifeTime or 0
    self.detonateRadius = detonateRadius or nil
    self.detonateWithTeam = detonateWithTeam
    self.clearOnSurfaceImpact = clearOnSurfaceImpact
    self.clearOnEntityImpact = clearOnEntityImpact
    self.clearOnSelfImpact = clearOnSelfImpact

end

function ProjectileController:SetControllerPhysicsMask(mask)
    self.mask = mask
end

local kNullVector = Vector(0,0,0)
local function ApplyFriction(velocity, frictionForce, deltaTime)

    if frictionForce > 0 then
    
        local appliedFrictionForce = math.max(frictionForce, velocity:GetLength() * frictionForce)   
        local friction = -GetNormalizedVector(velocity) * deltaTime * appliedFrictionForce        
        local newVelocity = SlerpVector(velocity, kNullVector, friction)
        VectorCopy(newVelocity, velocity)
    
    end

end

function ProjectileController:Move(offset, velocity)

    local hitEntity = nil
    local normal = nil
    local impact = false
    local endPoint = nil
    local impactVector = nil
    //local newDirection = GetNormalizedVector(offset)
    //local oldSpeed = velocity:GetLength()
    
    for i = 1, 3 do
    
        if offset:GetLengthSquared() <= 0.0 then
            break
        end
        
        local trace = self.controller:Move(offset, CollisionRep.Damage, CollisionRep.Damage, self.mask or PhysicsMask.PredictedProjectileGroup)
        
        if trace.fraction < 1 then
        
            impact = true
            
            endPoint = Vector(trace.endPoint)

            offset = offset * (1 - trace.fraction)
            offset = offset - offset:GetProjection(trace.normal)
            
            if not normal then
                normal = Vector(trace.normal)
            else
                normal = normal + trace.normal
            end
            
            if trace.entity then
                hitEntity = trace.entity
            end

            //newDirection = GetNormalizedVector(newDirection - newDirection:GetProjection(trace.normal))

        else
            break
        end
    
    end
    
    if normal then

        normal:Normalize()
    
        local impactForce = math.max(0, (-normal):DotProduct(velocity))
        local speed = velocity:Normalize()
        local steepImpact = Clamp((-normal):DotProduct(velocity), 0, 0.6)

        local direction = GetNormalizedVector(velocity * (1 - steepImpact) + normal * steepImpact)
        VectorCopy(direction, velocity)

        velocity:Scale(math.max(0, speed - impactForce * (0.75 + math.max(0, normal.y) * 0.25) ))

    end

    return impact, hitEntity, normal, endPoint

end

function ProjectileController:Update(deltaTime, projectile, predict)

    if self.controller and not self.stopSimulation then
    
        local velocity = Vector(self.velocity)
        
        // apply gravity
        velocity.y = velocity.y - deltaTime * self.gravity
    
        // apply friction
        //ApplyFriction(velocity, self.friction, deltaTime)

        // update position
        local impact, hitEntity, normal, endPoint = self:Move(velocity * deltaTime, velocity)
        if impact then
        
            local oldEnough = self.minLifeTime + self.creationTime <= Shared.GetTime()
        
            // some projectiles may predict impact
            if projectile and oldEnough then
            
                projectile:SetOrigin(endPoint)
                
                if projectile.ProcessHit then
                    projectile:ProcessHit(hitEntity, nil, normal, endPoint)
                end   
                
            end
            
            if hitEntity then
                // We hit something, check entity clears
                if projectile and projectile.GetOwner and hitEntity == projectile:GetOwner() then
                    // We hit ourselves :<
                    self.stopSimulation = self.clearOnSelfImpact
                elseif HasMixin(hitEntity, "Team") and hitEntity:GetTeamNumber() == self.detonateWithTeam then
                    // We hit someone or something on the other team
                    // self.detonateWithTeam is set to enemy team number on create, or -1 if not set.
                    self.stopSimulation = true
                else
                    // We hit a non-teamed entity or something on our team
                    self.stopSimulation = self.clearOnEntityImpact
                end
            else
                // We hit a world surface
                self.stopSimulation = self.clearOnSurfaceImpact
            end
            
            self.stopSimulation = self.stopSimulation and oldEnough
        
        else
            
            local oldEnough = self.minLifeTime + self.creationTime <= Shared.GetTime()
                
            if projectile and oldEnough and self.detonateRadius and projectile.ProcessNearMiss then
                                    
                local startPoint = projectile:GetOrigin()
                local endPoint = self:GetOrigin()
                
                local trace = Shared.TraceCapsule( startPoint, endPoint, self.detonateRadius, 0, CollisionRep.Damage, PhysicsMask.PredictedProjectileGroup, EntityFilterOne(projectile) )            
                
                if trace.fraction ~= 1 then
                    projectile:SetOrigin( trace.endPoint )
                    if projectile:ProcessNearMiss( trace.entity, nil,  trace.endPoint ) then
                        self.stopSimulation = true
                    end
                end
            end
            
        end
        
        if not predict then
            VectorCopy(velocity, self.velocity)
        end

    end

end

function ProjectileController:GetCoords()

    if self.controller then
        return self.controller:GetCoords()
    end
    
end

function ProjectileController:GetPosition()
    return self.controller:GetPosition()
end    

function ProjectileController:GetOrigin()
    return self.controller:GetPosition()
end
function ProjectileController:Uninitialize()
    
    if self.controller ~= nil then
    
        Shared.DestroyCollisionObject(self.controller)
        self.controller = nil
        
    end
    
end

class 'PredictedProjectile' (Entity)

PredictedProjectile.kMapName = "predictedprojectile"

local networkVars =
{
    ownerId = "entityid",
    projectileId = "integer",
    m_angles = "interpolated angles (by 10 [], by 10 [], by 10 [])",
    m_origin = "compensated interpolated position (by 0.05 [2 3 5], by 0.05 [2 3 5], by 0.05 [2 3 5])",
}

AddMixinNetworkVars(TechMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function PredictedProjectile:OnCreate()

    Entity.OnCreate(self)

    InitMixin(self, EffectsMixin)
    InitMixin(self, TechMixin)
    
    if Server then
    
        InitMixin(self, InvalidOriginMixin)
        InitMixin(self, OwnerMixin) 
    
    end
    
    self:SetUpdates(true)
    self:SetRelevancyDistance(kMaxRelevancyDistance)

end

function PredictedProjectile:OnInitialized()

    if Client then

        local owner = Shared.GetEntity(self.ownerId)
        
        if not self.kUseServerPosition and owner and owner == Client.GetLocalPlayer() and Client.GetIsControllingPlayer() then        
            owner:SetProjectileEntity(self)
        else
        
            if self.kModelName then

                local modelIndex = Shared.GetModelIndex(self.kModelName)
                if modelIndex then
                    self.renderModel = Client.CreateRenderModel(RenderScene.Zone_Default)
                    self.renderModel:SetModel(modelIndex)
                end
            
            end
            
            if self.kProjectileCinematic then
            
                self.projectileCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
                self.projectileCinematic:SetCinematic(self.kProjectileCinematic)          
                self.projectileCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)                
                self.projectileCinematic:SetIsVisible(true)
                self.projectileCinematic:SetCoords(self:GetCoords())
            
            end
            
        end    
        
    end

end

function PredictedProjectile:OnDestroy()

    if self.projectileController then
        
        self.projectileController:Uninitialize()
        self.projectileController = nil
        
    end
    
    if self.renderModel then
    
        Client.DestroyRenderModel(self.renderModel)
        self.renderModel = nil
    
    end
    
    if self.projectileCinematic then
    
        Client.DestroyCinematic(self.projectileCinematic)
        self.projectileCinematic = nil
    
    end
    
    if Client then
    
        local owner = Shared.GetEntity(self.ownerId)
    
        if owner and owner == Client.GetLocalPlayer() then        
            owner:SetProjectileDestroyed(self.projectileId)   
        end

    end    

end

function PredictedProjectile:GetVelocity()

    if self.projectileController then
        return Vector(self.projectileController.velocity)
    end
    
    return Vector(0,0,0)
    
end

function PredictedProjectile:SetProjectileController(controller, selfUpdate)
    self.projectileController = controller
    self.selfUpdate = selfUpdate
end

function PredictedProjectile:SetControllerPhysicsMask(mask)
    if self.projectileController then
        self.projectileController:SetControllerPhysicsMask(mask)
    end
end
if Server then

    function PredictedProjectile:OnUpdate(deltaTime)
    
        if self.projectileController then
        
            if self.selfUpdate then
                self.projectileController:Update(deltaTime, self)
            end
            
            if self.projectileController then
                self:SetOrigin(self.projectileController:GetOrigin())
            end
            
        end
        
    end
    
end

function PredictedProjectile:OnUpdateRender()

    UpdateRenderCoords(self)

    if self.renderModel then
        self.renderModel:SetCoords(self.renderCoords)
    end
    
    if self.projectileCinematic then
        self.projectileCinematic:SetCoords(self.renderCoords)
    end

end

Shared.LinkClassToMap("PredictedProjectile", PredictedProjectile.kMapName, networkVars, true)
