// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\BabblerPheromone.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Attracts babblers.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/Weapons/Projectile.lua")

class 'BabblerPheromone' (Projectile)

BabblerPheromone.kMapName = "babblerpheromone"
BabblerPheromone.kModelName = PrecacheAsset("models/alien/babbler/babbler_ball.model")

Shared.PrecacheSurfaceShader("models/alien/babbler/babbler_ball.surface_shader")

local kBabblerSearchRange = 20
local kBabblerPheromoneDuration = 5
local kPheromoneEffectInterval = 0.15

local networkVars =
{
    destinationEntityId = "entityid",
    impact = "boolean"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function BabblerPheromone:OnCreate()

    Projectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)

    if Server then
    
        self.destinationEntityId = Entity.invalidId
        InitMixin(self, EntityChangeMixin)
        InitMixin(self, TeamMixin)
        
        self:AddTimedCallback(BabblerPheromone.TimeUp, kBabblerPheromoneDuration)
        self.impact = false
        
    end  

    self.radius = 0.1
    self.mass = 1
    self.linearDamping = 0
    self.restitution = 0.95
    self:SetGroupFilterMask(PhysicsMask.NoBabblers)

end

function BabblerPheromone:GetProjectileModel()
    return BabblerPheromone.kModelName
end

function BabblerPheromone:OnDestroy()
    
    Projectile.OnDestroy(self)
    
    if Server and not self.triggeredPuff then
        self:TriggerEffects("babbler_pheromone_puff")  
    end
        
end

function BabblerPheromone:OnUpdateRender()

    if not self.timeLastPheromoneEffect or self.timeLastPheromoneEffect + kPheromoneEffectInterval < Shared.GetTime() then

        if self.destinationEntityId and self.destinationEntityId ~= Entity.invalidId and Shared.GetEntity(self.destinationEntityId) then
            
            local destinationEntity = Shared.GetEntity(self.destinationEntityId)
            destinationEntity:TriggerEffects("babbler_pheromone")
            
        else
            self:TriggerEffects("babbler_pheromone")
        end
        
        self.timeLastPheromoneEffect = Shared.GetTime()
    
    end
    
end

function BabblerPheromone:GetSimulatePhysics()
    return not self.impact
end

function BabblerPheromone:SetAttached(target)
    self.destinationEntityId = target:GetId()
end

if Server then

    function BabblerPheromone:OnUpdate(deltaTime)

        Projectile.OnUpdate(self, deltaTime)

        if not self.firstUpdate then
        
            self.firstUpdate = true
        
            for _, babbler in ipairs(GetEntitiesForTeamWithinRange("Babbler", self:GetTeamNumber(), self:GetOrigin(), kBabblerSearchRange )) do
            
                if babbler:GetOwner() == self:GetOwner() then
                    
                    if babbler:GetIsClinged() then
                        babbler:Detach()
                    end

                end
                    
            end
            
        end
        
    end
    
    function BabblerPheromone:ProcessHit(entity)
    
        if entity and (GetAreEnemies(self, entity) or HasMixin(entity, "BabblerCling")) and HasMixin(entity, "Live") and entity:GetIsAlive() then
        
            -- Ensure the impact flag is set even if the entity can't take damage.
            -- Otherwise there will be errors when attacking a Vortexed Marine for example.
            self.impact = true
            if entity:GetCanTakeDamage() then
            
                self.destinationEntityId = entity:GetId()
                self:SetModel(nil)
                self:TriggerEffects("babbler_pheromone_puff")
                self.triggeredPuff = true
                
                for _, babbler in ipairs(GetEntitiesForTeamWithinRange("Babbler", self:GetTeamNumber(), self:GetOrigin(), kBabblerSearchRange )) do
                
                    if babbler:GetOwner() == self:GetOwner() then
                    
                        // Adjust babblers move type.
                        local moveType = kBabblerMoveType.Move
                        local position = self:GetOrigin()
                        local giveOrder = true
                        
                        if GetAreFriends(self, entity) and HasMixin(entity, "BabblerCling") then
                            moveType = kBabblerMoveType.Cling
                        elseif GetAreEnemies(self, entity) and HasMixin(entity, "Live") and entity:GetIsAlive() and entity:GetCanTakeDamage() then
                            moveType = kBabblerMoveType.Attack
                        end
                        
                        position = HasMixin(entity, "Target") and entity:GetEngagementPoint() or entity:GetOrigin()
                        
                        if giveOrder then
                        
                            if babbler:GetIsClinged() then
                                babbler:Detach()
                            end
                            
                            babbler:SetMoveType(moveType, entity, position, true)
                            
                        end
                        
                    end
                    
                end
                
                DestroyEntity(self)
                
            end
            
        end
        
    end
    
    function BabblerPheromone:OnEntityChange(oldId)

        if oldId == self.destinationEntityId then
            DestroyEntity(self)
        end
         
    end

    function BabblerPheromone:GetIsAttached()
        return self.destinationEntityId ~= Entity.invalidId
    end
    
    function BabblerPheromone:TimeUp()
        DestroyEntity(self)
    end

end

Shared.LinkClassToMap("BabblerPheromone", BabblerPheromone.kMapName, networkVars)