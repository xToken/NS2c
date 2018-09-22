-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Alien\StompMixin.lua
--
--    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Shockwave.lua")

StompMixin = CreateMixin( StompMixin  )
StompMixin.type = "Stomp"

-- GetHasSecondary and GetSecondaryEnergyCost should completely override any existing
-- same named function defined in the object.
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
    
    PROFILE("StompMixin:__initmixin")
    
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

function StompMixin:GetSecondaryEnergyCost()
    return kStompEnergyCost
end

function StompMixin:PerformStomp(player)

    local stompOrigin = player:GetOrigin()

    if Server then

        local direction = GetNormalizedVectorXZ(player:GetViewCoords().zAxis)
        local shockwaveOrigin = stompOrigin + Vector.yAxis * 0.2 + direction * 0.4

        local shockwave = CreateEntity(Shockwave.kMapName, shockwaveOrigin, self:GetTeamNumber())
        shockwave:SetOwner(player)

        local coords = Coords.GetLookIn(shockwaveOrigin, direction)
        shockwave:SetCoords(coords)

        local shockwaveId = shockwave:GetId()
        table.insert(self.shockwaveEntIds, shockwaveId)

    end

    -- discrupt minigun exos in range as well
    --[[
    local enemyTeamNum = GetEnemyTeamNumber(self:GetTeamNumber())
    for index, exo in ipairs(GetEntitiesForTeamWithinRange("Exo", enemyTeamNum, stompOrigin, kStompRadius)) do

        if math.abs(exo:GetOrigin().y - stompOrigin.y) < 1.2 then
            exo:Disrupt()
        end

    end
    --]]

end

function StompMixin:OnSecondaryAttack(player)

    if player:GetEnergy() >= kStompEnergyCost and player:GetIsOnGround() and not self.primaryAttacking then
        self.secondaryAttacking = true
    end

end

function StompMixin:OnSecondaryAttackEnd(_)
end

function StompMixin:OnTag(tagName)

    PROFILE("StompMixin:OnTag")

    if tagName == "stomp_hit" then

        local player = self:GetParent()

        if player then

            self:PerformStomp(player)
            player:TriggerEffects("stomp_attack", { effecthostcoords = player:GetCoords() })
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
    table.removevalue(self.shockwaveEntIds, shockwave:GetId())
end

function StompMixin:OnProcessMove(input)

    if Server then

        for _, shockwaveId in ipairs(self.shockwaveEntIds) do

            local shockwave = Shared.GetEntity(shockwaveId)
            if shockwave then
                shockwave:UpdateShockwave(input.time)
            end

        end

    end

end

if Server then

    function StompMixin:OnDestroy()

        for _, shockwaveId in ipairs(self.shockwaveEntIds) do

            local shockwave = Shared.GetEntity(shockwaveId)
            if shockwave then
                DestroyEntity(shockwave)
            end

        end

    end

end