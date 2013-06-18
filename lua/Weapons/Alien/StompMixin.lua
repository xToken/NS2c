// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\StompMixin.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

StompMixin = CreateMixin( StompMixin  )
StompMixin.type = "Stomp"

local kMaxPlayerVelocityToStomp = 8
local kStompVerticalRange = 1.5

// GetHasSecondary and GetSecondaryEnergyCost should completely override any existing
// same named function defined in the object.
StompMixin.overrideFunctions =
{
    "GetHasSecondary",
    "GetSecondaryEnergyCost",
    "OnSecondaryAttack",
    "OnSecondaryAttackEnd",
    "PerformSecondaryAttack"
}

StompMixin.networkVars = 
{
    stomping = "boolean"
}

local function StunInCone(self, player, origin, direction, range, stunDuration)

    local ents = GetEntitiesWithMixinWithinRange("Stun", origin, range)
    
    for index, ent in ipairs(ents) do
    
        if ent ~= player then
        
            local toEnemy = GetNormalizedVector(ent:GetModelOrigin() - origin)
            local dotProduct = Math.DotProduct(direction, toEnemy)
            local verticalDistance = math.abs(ent:GetOrigin().y - origin.y)
            
            // Stun everything in a cone in front
            if dotProduct > .8 and verticalDistance < kStompVerticalRange then
                ent:SetStun(stunDuration)
            end
            
        end
        
    end
    
end

function StompMixin:GetIsStomping()
    return self.stomping
end

function StompMixin:GetHasSecondary(player)
    return player:GetHasTwoHives()
end

function StompMixin:GetSecondaryEnergyCost(player)
    return kStompEnergyCost
end

function StompMixin:PerformStomp(player)

    if Server then

        local xZDirection = player:GetViewCoords().zAxis
        xZDirection.y = 0
        xZDirection:Normalize()
        local origin = player:GetOrigin() + Vector(0, 0.4, 0) + player:GetViewCoords().zAxis * 0.9
        
        local endPoint = origin + xZDirection * kStompRange
        
        local trace = Shared.TraceRay(origin, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterAll())
        
        //DebugLine(origin, trace.endPoint, 3, 1, 1, 1, 1)
        
        local range = math.abs( (trace.endPoint - origin):GetLength() )

        StunInCone(self, player, origin, xZDirection, range + 0.3, kStunMarineTime)
        
        
    end    
    
end

function StompMixin:OnSecondaryAttack(player)

    if player:GetEnergy() >= kStompEnergyCost and player:GetIsOnGround() then
        self.stomping = true
        Ability.OnSecondaryAttack(self, player)
    end

end

function StompMixin:OnSecondaryAttackEnd(player)
    
    Ability.OnSecondaryAttackEnd(self, player)    
    self.stomping = false
    
end

function StompMixin:OnTag(tagName)

    PROFILE("StompMixin:OnTag")

    if tagName == "stomp_hit" then
        
        local player = self:GetParent()
        
        if player then
                
            self:PerformStomp(player)

            self:TriggerEffects("stomp_attack", { effecthostcoords = player:GetCoords() })
            player:DeductAbilityEnergy(kStompEnergyCost)
            
        end
        
        if player:GetEnergy() < kStompEnergyCost or player:GetVelocityLength() > kMaxPlayerVelocityToStomp then
            self.stomping = false
        end    
        
    end

end

function StompMixin:OnUpdateAnimationInput(modelMixin)

    if self.stomping then
        modelMixin:SetAnimationInput("activity", "secondary") 
    end
    
end