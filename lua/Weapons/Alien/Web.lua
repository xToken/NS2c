// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Web.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// Spit attack on primary.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TeamMixin.lua")
Script.Load("lua/TriggerMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/OwnerMixin.lua")

class 'Web' (Actor)

Web.kMapName = "web"

local networkVars =
{
    endPoint = "vector"
}

AddMixinNetworkVars(TechMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

Shared.PrecacheSurfaceShader("models/alien/gorge/web.surface_shader")
local kWebMaterial = "models/alien/gorge/web.material"
local kWebWidth = 0.1

function EntityFilterNonWebables()
    return function(test) return not HasMixin(test, "Webable") end
end

function Web:SpaceClearForEntity(location)
    return true
end

function Web:OnCreate()

    Entity.OnCreate(self)
    
    InitMixin(self, TechMixin)
    InitMixin(self, TeamMixin)
    
    if Server then
    
        InitMixin(self, EntityChangeMixin)
        InitMixin(self, TriggerMixin, {kPhysicsGroup = PhysicsGroup.TriggerGroup, kFilterMask = PhysicsMask.AllButTriggers} )
        InitMixin(self, OwnerMixin)
        
        self.nearbyWebAbleIds = {}
        self:SetTechId(kTechId.Web)
        
    end
    
    self:SetUpdates(false)
    
end

if Server then
    
    local function CreateTrigger(self)
    
        if self.triggerBody then
        
            Shared.DestroyCollisionObject(self.triggerBody)
            self.triggerBody = nil
            
        end
        
        local coords = Coords.GetTranslation((self:GetOrigin() - self.endPoint) * .5 + self.endPoint)
        local radius = (self:GetOrigin() - self.endPoint):GetLength() * .5

        self.triggerBody = Shared.CreatePhysicsSphereBody(false, radius, 0, coords)
        self.triggerBody:SetTriggerEnabled(true)
        self.triggerBody:SetCollisionEnabled(true)
        
        if self:GetMixinConstants().kPhysicsGroup then
            //Print("set trigger physics group to %s", EnumToString(PhysicsGroup, self:GetMixinConstants().kPhysicsGroup))
            self.triggerBody:SetGroup(self:GetMixinConstants().kPhysicsGroup)
        end
        
        if self:GetMixinConstants().kFilterMask then
            //Print("set trigger filter mask to %s", EnumToString(PhysicsMask, self:GetMixinConstants().kFilterMask))
            self.triggerBody:SetGroupFilterMask(self:GetMixinConstants().kFilterMask)
        end
        
        self.triggerBody:SetEntity(self)
        
    end

    function Web:SetEndPoint(endPoint)
        self.endPoint = Vector(endPoint)
        CreateTrigger(self)
    end

    // OnUpdate is only called when entities are in interest range    
    function Web:OnUpdate(deltaTime)

        local trace = Shared.TraceRay(self:GetOrigin(), self.endPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterNonWebables())
        if trace.entity then
            trace.entity:SetWebbed(kWebbedDuration)
            DestroyEntity(self)
        end
    
    end
    
    function Web:OnTriggerEntered(enterEntity)
    
        if HasMixin(enterEntity, "Webable") then
            table.insertunique(self.nearbyWebAbleIds, enterEntity:GetId())
            self:SetUpdates(true)
        end
        
    end
    
    function Web:OnTriggerExited(exitEntity)
    
        if HasMixin(enterEntity, "Webable") then
        
            table.removevalue(self.nearbyWebAbleIds, exitEntity:GetId())
            
            if #self.nearbyWebAbleIds == 0 then
                self:SetUpdates(false)
            end
            
        end    
    
    end

end

function Web:OnDestroy()

    Entity.OnDestroy(self)
    
    if self.webRenderModel then
    
        DynamicMesh_Destroy(self.webRenderModel)
        self.webRenderModel = nil
        
    end

end

function Web:OnUpdateRender()

    // we are smart and do that only once.
    if not self.webRenderModel then
    
        self.webRenderModel = DynamicMesh_Create()
        self.webRenderModel:SetMaterial(kWebMaterial)
        
        local length = (self.endPoint - self:GetOrigin()):GetLength()
        local coords = Coords.GetIdentity()
        coords.origin = self:GetOrigin()
        coords.zAxis = GetNormalizedVector(self.endPoint - self:GetOrigin())
        coords.xAxis = coords.zAxis:GetPerpendicular()
        coords.yAxis = coords.zAxis:CrossProduct(coords.xAxis)
        
        DynamicMesh_SetTwoSidedLine(self.webRenderModel, coords, kWebWidth, length)
    
    end

end

Shared.LinkClassToMap("Web", Web.kMapName, networkVars)