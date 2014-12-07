// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\BabblerPheromone.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Attracts babblers.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TeamMixin.lua")
Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")

class 'BabblerPheromone' (PredictedProjectile)

BabblerPheromone.kMapName = "babblerpheromone"
BabblerPheromone.kModelName = PrecacheAsset("models/alien/babbler/babbler_ball.model")

PrecacheAsset("models/alien/babbler/babbler_ball.surface_shader")

local kBabblerSearchRange = 20
local kBabblerPheromoneDuration = 5
local kPheromoneEffectInterval = 0.15

BabblerPheromone.kClearOnImpact = false
BabblerPheromone.kClearOnEnemyImpact = true

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

local function ClearAttachedBabblers(self)
    if self:GetIsDestroyed() then
        return false
    end
    for _, babbler in ipairs(GetEntitiesForTeamWithinRange("Babbler", self:GetTeamNumber(), self:GetOrigin(), kBabblerSearchRange )) do
        if babbler:GetOwner() == self:GetOwner() then
            if babbler:GetIsClinged() then
                babbler:Detach()
            end
        end
    end
    return false
end

function BabblerPheromone:OnCreate()

    PredictedProjectile.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, TeamMixin)

    if Server then
        
        self:AddTimedCallback(BabblerPheromone.TimeUp, kBabblerPheromoneDuration)
        self:AddTimedCallback(ClearAttachedBabblers, 0.01)
        
    end

end

function BabblerPheromone:GetProjectileModel()
    return BabblerPheromone.kModelName
end

function BabblerPheromone:OnDestroy()
    
    PredictedProjectile.OnDestroy(self)
    
    if Server and not self.triggeredPuff then
        self:TriggerEffects("babbler_pheromone_puff")  
    end
        
end

function BabblerPheromone:ProcessHit(entity)

    if Server and entity and (GetAreEnemies(self, entity) or HasMixin(entity, "BabblerCling")) and HasMixin(entity, "Live") and entity:GetIsAlive() then
    
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
    return true
    
end

function BabblerPheromone:TimeUp()
    DestroyEntity(self)
end

Shared.LinkClassToMap("BabblerPheromone", BabblerPheromone.kMapName, networkVars)