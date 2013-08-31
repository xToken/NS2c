// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\StompMixin.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Shockwave.lua")

StompMixin = CreateMixin( StompMixin  )
StompMixin.type = "Stomp"

local kMaxPlayerVelocityToStomp = 8
local kStompVerticalRange = 1.5

local kStompRadius = 2

// GetHasSecondary and GetSecondaryEnergyCost should completely override any existing
// same named function defined in the object.
StompMixin.overrideFunctions =
{
    "GetHasSecondary",
    "GetSecondaryEnergyCost",
    "GetSecondaryTechId",
    "OnSecondaryAttack",
    "OnSecondaryAttackEnd",
    "PerformSecondaryAttack"
}

StompMixin.networkVars = { }

function StompMixin:__initmixin()

    if Server then    
        self.shockwaveEntIds = {}    
    end

end

function StompMixin:GetIsStomping()
    return self.secondaryAttacking
end

function StompMixin:GetSecondaryTechId()
    return kTechId.Stomp
end

function StompMixin:GetHasSecondary(player)
    return player:GetHasTwoHives()
end

function StompMixin:GetSecondaryEnergyCost(player)
    return kStompEnergyCost
end

function StompMixin:PerformStomp(player)

    local enemyTeamNum = GetEnemyTeamNumber(self:GetTeamNumber())
    local stompOrigin = player:GetOrigin()   
    
    if Server then
    
        local direction = GetNormalizedVectorXZ(player:GetViewCoords().zAxis)
        local shockwaveOrigin = stompOrigin + Vector.yAxis * 0.2 + direction * 0.4
        
        local shockwave = CreateEntity(Shockwave.kMapName, shockwaveOrigin, self:GetTeamNumber())
        shockwave:SetOwner(player)

        local coords = Coords.GetLookIn(shockwaveOrigin, direction) 
        shockwave:SetCoords(coords)
        
        local shockwaveId = shockwave:GetId()
        self.shockwaveEntIds[shockwaveId] = true
        
    end  
    
end

function StompMixin:OnSecondaryAttack(player)

    if player:GetEnergy() >= kStompEnergyCost and player:GetIsOnGround() and not self.primaryAttacking then
        self.secondaryAttacking = true
    end

end

function StompMixin:OnSecondaryAttackEnd(player)
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
        
    elseif tagName == "end" then
        self.secondaryAttacking = false
    end

end

function StompMixin:OnUpdateAnimationInput(modelMixin)

    if self.secondaryAttacking then
        modelMixin:SetAnimationInput("activity", "secondary") 
    end
    
end

function StompMixin:UnregisterShockwave(shockwave)
    self.shockwaveEntIds[shockwave:GetId()] = nil
end

function StompMixin:OnProcessMove(input)

    if Server then

        for shockwaveId, _ in pairs(self.shockwaveEntIds) do
        
            local shockwave = Shared.GetEntity(shockwaveId)
            if shockwave then            
                shockwave:UpdateShockwave(input.time)            
            end
        
        end
    
    end

end

if Server then

    function StompMixin:OnDestroy()

        for shockwaveId, _ in pairs(self.shockwaveEntIds) do
        
            local shockwave = Shared.GetEntity(shockwaveId)
            if shockwave then
                DestroyEntity(shockwave)
            end
            
        end    

    end

end