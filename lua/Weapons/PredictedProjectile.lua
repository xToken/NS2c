// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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

function PredictedProjectileShooterMixin:CreatePredictedProjectile(className, startPoint, velocity, bounce, friction)

    local projectileController = ProjectileController()
    projectileController:Initialize(startPoint, velocity, _G[className].kRadius, self, bounce, friction, GetEnemyTeamNumber(self:GetTeamNumber()))
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
    
    if Client then
        
        local modelIndex = Shared.GetModelIndex(_G[className].kModelName)
        if modelIndex then
        
            //DebugPrint("create render model")
            projectileModel = Client.CreateRenderModel(RenderScene.Zone_Default)
            projectileModel:SetModel(modelIndex)
            projectileModel:SetCoords(Coords.GetTranslation(startPoint))
            
        end
    
    end
    //DebugPrint("self.nextProjectileId %s", ToString(self.nextProjectileId))
    self.predictedProjectiles[self.nextProjectileId] = { Controller = projectileController, Model = projectileModel, EntityId = projectileEntId, CreationTime = Shared.GetTime() }
    
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
        
        //DebugPrint("update entry %s  entId %s", ToString(projectileId), ToString(entry.EntityId))
        
        if entry.Model then
            local coords = Coords.GetLookIn(entry.Controller:GetPosition(), GetNormalizedVector(entry.Controller.velocity))
            entry.Model:SetCoords(coords)
            entry.Model:SetIsVisible(entry.Controller.stopSimulation ~= true)
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
                //DebugPrint("destroy render model")
                Client.DestroyRenderModel(entry.Model)
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

    //DebugPrint("PredictedProjectileShooterMixin:SetProjectileEntity(%s)", ToString(projectile))

    local entry = self.predictedProjectiles[projectile.projectileId]
    if entry then
        entry.EntityId = projectile:GetId()
        //DebugPrint("set entity")
    end

end

function PredictedProjectileShooterMixin:SetProjectileDestroyed(projectileId)

    local entry = self.predictedProjectiles[projectileId]

    if entry then

        if entry.Model then
            //DebugPrint("destroy render model")
            Client.DestroyRenderModel(entry.Model)
        end

        if entry.Controller then
            entry.Controller:Uninitialize()
        end

        self.predictedProjectiles[projectileId] = nil
        
        //DebugPrint("cleaned up %s", ToString(projectileId))
    
    end

end

class 'ProjectileController'

function ProjectileController:Initialize(startPoint, velocity, radius, predictor, bounce, friction, detonateWithTeam)

    self.controller = Shared.CreateCollisionObject(predictor)
    self.controller:SetPhysicsType(CollisionObject.Kinematic)
    self.controller:SetGroup(PhysicsGroup.ProjectileGroup)
    self.controller:SetupSphere(radius or 0.1, self.controller:GetCoords(), false)
    
    self.velocity = Vector(velocity)
    self.bounce = bounce or 0.5
    self.friction = friction or 0
    
    self.controller:SetPosition(startPoint, false)
    
    self.detonateWithTeam = detonateWithTeam

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
        velocity.y = velocity.y - deltaTime * 9.81
    
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
                    projectile:ProcessHit(hitEntity)
                end   
                
            end
            
            self.stopSimulation = hitEntity ~= nil and HasMixin(hitEntity, "Team") and hitEntity:GetTeamNumber() == self.detonateWithTeam
        
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
    
        //DebugPrint("PredictedProjectile:OnInitialized, projectileId %s", ToString(self.projectileId))
        
        local owner = Shared.GetEntity(self.ownerId)
        
        if owner and owner == Client.GetLocalPlayer() then        
            owner:SetProjectileEntity(self)
        else
        
            local modelIndex = Shared.GetModelIndex(self.kModelName)
            if modelIndex then
                //DebugPrint("create render model")
                self.renderModel = Client.CreateRenderModel(RenderScene.Zone_Default)
                self.renderModel:SetModel(modelIndex)
            end
            
        end    
        
    end

end

function PredictedProjectile:OnDestroy()

    //DebugPrint("PredictedProjectile:OnDestroy")

    if self.projectileController then
        
        self.projectileController:Uninitialize()
        self.projectileController = nil
        
    end
    
    if self.renderModel then
    
        Client.DestroyRenderModel(self.renderModel)
        //DebugPrint("destroy render model")
        self.renderModel = nil
    
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

end

Shared.LinkClassToMap("PredictedProjectile", PredictedProjectile.kMapName, networkVars, true)
