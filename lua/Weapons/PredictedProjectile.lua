// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\PredictedProjectile.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

PredictedProjectileShooterMixin = CreateMixin(PredictedProjectileShooterMixin)
PredictedProjectileShooterMixin.type = "PredictedProjectile"

local physicsMask = PhysicsMask.Bullets
local kMaxNumProjectiles = 200

function PredictedProjectileShooterMixin:__initmixin()
    self.nextProjectileId = 1
    self.predictedProjectiles = {}
end

function PredictedProjectileShooterMixin:CreatePredictedProjectile(className, startPoint, velocity, bounce, friction, gravity, clearOnImpact)

    local projectileController = ProjectileController()
    projectileController:Initialize(startPoint, velocity, _G[className].kRadius, self, bounce, friction, gravity, GetEnemyTeamNumber(self:GetTeamNumber()), clearOnImpact)
    projectileController.projectileId = self.nextProjectileId
    projectileController.modelName = _G[className].kModelName
    
    local projectileEntId = Entity.invalidId
    
    if Server then
    
        local projectile = CreateEntity(_G[className].kMapName, startPoint, self:GetTeamNumber())
        projectile.projectileId = self.nextProjectileId
        projectile:SetProjectileController(projectileController)
        projectileEntId = projectile:GetId()
        projectile:SetOwner(self)
        
    end
    
    local projectileModel = nil
    local projectileCinematic = nil
    
    if Client then
    
        local coords = Coords.GetLookIn(startPoint, GetNormalizedVector(velocity))
        
        if _G[className].kModelName then
        
            local modelIndex = Shared.GetModelIndex(_G[className].kModelName)
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
    
    self.nextProjectileId = self.nextProjectileId + 1
    if self.nextProjectileId > kMaxNumProjectiles then
        self.nextProjectileId = 1
    end

end

local function UpdateProjectiles(self, input, predict)

    local cleanUp = {}

    for projectileId, entry in pairs(self.predictedProjectiles) do

        local projectile = Shared.GetEntity(entry.EntityId)
        if not predict then
            entry.Controller:Update(input.time, projectile, predict)
        end
        
        if not Server then
 
            local coords = Coords.GetLookIn(entry.Controller:GetPosition(), GetNormalizedVector(entry.Controller.velocity))
            local isVisible = entry.Controller.stopSimulation ~= true
 
            if entry.Model then
                entry.Model:SetCoords(coords)
                entry.Model:SetIsVisible(isVisible)
            end
            
            if entry.Cinematic then
                entry.Cinematic:SetCoords(coords)
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
        
            projectile:SetProjectileController(entry.Controller)
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

function ProjectileController:Initialize(startPoint, velocity, radius, predictor, bounce, friction, gravity, detonateWithTeam, clearOnImpact)

    self.controller = Shared.CreateCollisionObject(predictor)
    self.controller:SetPhysicsType(CollisionObject.Kinematic)
    self.controller:SetGroup(PhysicsGroup.ProjectileGroup)
    self.controller:SetupSphere(radius or 0.1, self.controller:GetCoords(), false)
    
    self.velocity = Vector(velocity)
    self.bounce = bounce or 0.5
    self.friction = friction or 0
    self.gravity = gravity or 9.81
    
    self.controller:SetPosition(startPoint, false)
    
    self.detonateWithTeam = detonateWithTeam
    self.clearOnImpact = clearOnImpact

end

local function ApplyFriction(velocity, frictionForce, deltaTime)

    if frictionForce > 0 then
    
        local friction = -GetNormalizedVector(velocity) * deltaTime * velocity:GetLength() * frictionForce        
        local newVelocity = SlerpVector(velocity, Vector(0,0,0), friction)
        VectorCopy(newVelocity, velocity)
    
    end

end

function ProjectileController:Move(offset, velocity)

    local hitEntity = nil
    local normal = nil
    local impact = false
    local endPoint = nil
    
    for i = 1, 3 do
    
        if offset:GetLengthSquared() <= 0.0 then
            break
        end    
    
        local trace = self.controller:Move(offset, CollisionRep.Move, CollisionRep.Move, PhysicsMask.Movement)
    
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
            
            if velocity ~= nil then

                local newVelocity = velocity - velocity:GetProjection(trace.normal) * 0.25
                VectorCopy(newVelocity, velocity)
                
            end
            
        else
            break
        end
    
    end
    
    if normal then
        normal:Normalize()
    end

    return impact, hitEntity, normal, endPoint

end

function ProjectileController:Update(deltaTime, projectile, predict)

    if self.controller and not self.stopSimulation then
    
        local velocity = Vector(self.velocity)
        
        // apply gravity
        velocity.y = velocity.y - deltaTime * self.gravity
    
        // apply friction
        ApplyFriction(velocity, self.friction, deltaTime)

        // update position
        local impact, hitEntity, normal, endPoint = self:Move(velocity * deltaTime, velocity)
        if impact then
        
            local clampedSpeed = velocity:GetLength()

            // bounce
            local impactForce = math.max(0, (-normal):DotProduct(velocity))
            velocity:Add(impactForce * normal * self.bounce * 2)
            /*
            local newSpeed = velocity:GetLength()
            
            if newSpeed > clampedSpeed then
                velocity:Scale(clampedSpeed / newSpeed)
            end
            */
            // some projectiles may predict impact
            if projectile then
            
                projectile:SetOrigin(endPoint)
                
                if projectile.ProcessHit then
                    projectile:ProcessHit(hitEntity, nil, normal)
                end   
                
            end
            
            self.stopSimulation = self.clearOnImpact or ( hitEntity ~= nil and HasMixin(hitEntity, "Team") and hitEntity:GetTeamNumber() == self.detonateWithTeam )
        
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
    projectileId = "integer"
}

AddMixinNetworkVars(TechMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function PredictedProjectile:OnCreate()

    Entity.OnCreate(self)

    InitMixin(self, EffectsMixin)
    InitMixin(self, TechMixin)
    
    if Server then
    
        InitMixin(self, InvalidOriginMixin)
        InitMixin(self, RelevancyMixin)
        InitMixin(self, OwnerMixin) 
    
    end
    
    self:SetUpdates(true)

end

function PredictedProjectile:OnInitialized()

    if Client then

        local owner = Shared.GetEntity(self.ownerId)
        
        if owner and owner == Client.GetLocalPlayer() and Client.GetIsControllingPlayer() then        
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

function PredictedProjectile:SetProjectileController(controller)
    self.projectileController = controller
end

function PredictedProjectile:SetModel(model)
    self.renderModel = model
end

if Server then

    function PredictedProjectile:OnUpdate(deltaTime)
    
        if self.projectileController then
        
            local coords = Coords.GetLookIn(self.projectileController:GetPosition(), GetNormalizedVector(self.projectileController.velocity))
            self:SetCoords(coords)
                
        end
    
    end

end

function PredictedProjectile:OnUpdateRender()

    if self.renderModel then
        self.renderModel:SetCoords(self:GetCoords())
    end
    
    if self.projectileCinematic then
        self.projectileCinematic:SetCoords(self:GetCoords())
    end

end

Shared.LinkClassToMap("PredictedProjectile", PredictedProjectile.kMapName, networkVars, true)
