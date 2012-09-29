// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\RagdollMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

local kRagdollTime = 8

RagdollMixin = CreateMixin( RagdollMixin )
RagdollMixin.type = "Ragdoll"

RagdollMixin.expectedMixins =
{
    Live = "Needed for SetIsAlive()."
}

RagdollMixin.expectedCallbacks =
{
    SetPhysicsType = "Sets the physics to the passed in type.",
    GetPhysicsType = "Returns the physics type, dynamic, kinematic, etc.",
    SetPhysicsGroup = "Sets the physics group to the passed in value.",
    GetPhysicsGroup = "",
    GetPhysicsModel = "Returns the physics model.",
    TriggerEffects = ""
}

function RagdollMixin:GetIsRagdoll()
    return self:GetPhysicsGroup() == PhysicsGroup.RagdollGroup
end

local function GetDamageImpulse(doer, point)

    if damage and doer and point then
        return GetNormalizedVector(doer:GetOrigin() - point) * 1.5 * .01
    end
    return nil
    
end

function RagdollMixin:OnTakeDamage(damage, attacker, doer, point)

    // Apply directed impulse to physically simulated objects, according to amount of damage.
    if self:GetPhysicsModel() ~= nil and self:GetPhysicsType() == PhysicsType.Dynamic then    
    
        local damageImpulse = GetDamageImpulse(damage, doer, point)
        if damageImpulse then
            self:GetPhysicsModel():AddImpulse(point, damageImpulse)
        end
        
    end
    
end
AddFunctionContract(RagdollMixin.OnTakeDamage, { Arguments = { "Entity", "number", "Entity", { "Entity", "nil" }, "Vector" }, Returns = { } })

if Server then

    function RagdollMixin:OnKill(attacker, doer, point, direction)

        if point then
        
            self.deathImpulse = GetDamageImpulse(doer, point)
            self.deathPoint = Vector(point)
            
            if doer then
                self.doerClassName = doer:GetClassName()
            end
            
        end
        
        local doerClassName = nil 

        if doer ~= nil then
            doerClassName = doer:GetClassName()
        end

        if not self.consumed then
            self:TriggerEffects("death", {classname = self:GetClassName(), effecthostcoords = Coords.GetTranslation(self:GetOrigin()), doer = doerClassName})
        end
       
        // server does not process any tags when the model is client side animated. assume death animation takes 0.5 seconds and switch then to ragdoll mode
        if self.GetHasClientModel and self:GetHasClientModel() and self:GetModelName() ~= nil and self:GetGraphName() ~= nil then
        
            CreateRagdoll(self)
            DestroyEntity(self)
            
        end

    end
    AddFunctionContract(RagdollMixin.OnKill, { Arguments = { "Entity", "number", "Entity", { "Entity", "nil" }, "Vector" }, Returns = { } })
    
end

local function UpdateTimeToDestroy(self, deltaTime)

    if self.timeToDestroy then
    
        self.timeToDestroy = self.timeToDestroy - deltaTime
        
        if self.timeToDestroy <= 0 then
        
            DestroyEntitySafe(self)
            self.timeToDestroy = nil
            
        end
        
    end
    
end
AddFunctionContract(UpdateTimeToDestroy, { Arguments = { "Entity", "number" }, Returns = { } })

local function SharedUpdate(self, deltaTime)

    if Server then
    
        UpdateTimeToDestroy(self, deltaTime)
        
    end
    
end

function RagdollMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end
AddFunctionContract(RagdollMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

function RagdollMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end
AddFunctionContract(RagdollMixin.OnProcessMove, { Arguments = { "Entity", "Move" }, Returns = { } })

local function SetRagdoll(self, deathTime)

    if Server then
    
        if self:GetPhysicsGroup() ~= PhysicsGroup.RagdollGroup then

            self:SetPhysicsType(PhysicsType.Dynamic)
            
            self:SetPhysicsGroup(PhysicsGroup.RagdollGroup)
                        
            // Apply landing blow death impulse to ragdoll (but only if we didn't play death animation).
            if self.deathImpulse and self.deathPoint and self:GetPhysicsModel() and self:GetPhysicsType() == PhysicsType.Dynamic then
            
                self:GetPhysicsModel():AddImpulse(self.deathPoint, self.deathImpulse)
                self.deathImpulse = nil
                self.deathPoint = nil
                self.doerClassName = nil
                
            end
            
            if deathTime then
                self.timeToDestroy = deathTime
            end
            
        end
    end
    
end

function RagdollMixin:SetRagDollDelayed()
    SetRagdoll(self, kRagdollTime)
    return false
end

if Server then

    function RagdollMixin:OnTag(tagName)
    
        PROFILE("RagdollMixin:OnTag")

        if not self.GetHasClientModel or not self:GetHasClientModel() then
        
            if tagName == "death_end" then
                SetRagdoll(self, kRagdollTime)
            elseif tagName == "destroy" then
                DestroyEntitySafe(self)
            end
            
        end
        
    end

end