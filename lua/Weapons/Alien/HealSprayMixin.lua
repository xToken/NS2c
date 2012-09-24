// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\HealSprayMixin.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com) and
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

HealSprayMixin = CreateMixin( HealSprayMixin )
HealSprayMixin.type = "HealSpray"

local kRange = 6
local kHealCylinderWidth = 3

// HealSprayMixin:GetHasSecondary should completely override any existing
// GetHasSecondary function defined in the object.
HealSprayMixin.overrideFunctions =
{
    "GetHasSecondary",
    "GetSecondaryEnergyCost",
    "GetDeathIconIndex"
}

HealSprayMixin.networkVars =
{
    lastSecondaryAttackTime = "float"
}

function HealSprayMixin:__initmixin()

    self.secondaryAttacking = false
    self.lastSecondaryAttackTime = 0
    self.lastSprayAttacked = false

end

function HealSprayMixin:GetHasSecondary(player)
    return true
end

function HealSprayMixin:GetSecondaryAttackDelay()
    return kHealsprayFireDelay
end

function HealSprayMixin:GetSecondaryEnergyCost(player)
    return kHealsprayEnergyCost
end

function HealSprayMixin:GetDeathIconIndex()
    return kDeathMessageIcon.Spray 
end

function HealSprayMixin:OnSecondaryAttack(player)

    local enoughTimePassed = (Shared.GetTime() - self.lastSecondaryAttackTime) > self:GetSecondaryAttackDelay()
    if player:GetSecondaryAttackLastFrame() and enoughTimePassed then
    
        if player:GetEnergy() >= self:GetSecondaryEnergyCost(player) then
        
            self.lastSprayAttacked = true
            self:PerformSecondaryAttack(player)
            
            if self.OnHealSprayTriggered then
                self:OnHealSprayTriggered()
            end
        end

    end
    
end

function HealSprayMixin:PerformSecondaryAttack(player)
    self.secondaryAttacking = true
end

function HealSprayMixin:OnSecondaryAttackEnd(player)

    Ability.OnSecondaryAttackEnd(self, player)
    
    self.secondaryAttacking = false

end

local function GetHealOrigin(self, player)

    // Don't project origin the full radius out in front of Gorge or we have edge-case problems with the Gorge 
    // not being able to hear himself
    local startPos = player:GetEyePos()
    local endPos = startPos + (player:GetViewAngles():GetCoords().zAxis * kHealsprayRadius * .9)
    local trace = Shared.TraceRay(startPos, endPos, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(player))
    return trace.endPoint
    
end

function HealSprayMixin:GetEffectParams(tableParams)

    Ability.GetEffectParams(self, tableParams)
    
    // Override host coords for spray to be where heal origin is
    local player = self:GetParent()
    if player then
    
        local newCoords = Coords.GetLookIn(GetHealOrigin(self, player), player:GetViewCoords().zAxis)
        tableParams[kEffectHostCoords] = newCoords
        
    end
    
end

function HealSprayMixin:GetDamageType()
    return kHealsprayDamageType
end

function HealSprayMixin:OnPrimaryAttack()
    self.lastSprayAttacked = false
end

function HealSprayMixin:GetWasSprayAttack()
    return self.lastSprayAttacked
end

local function DamageEntity(self, player, targetEntity)

    local healthScalar = targetEntity:GetHealthScalar()
    self:DoDamage(kHealsprayDamage, targetEntity, targetEntity:GetEngagementPoint(), GetNormalizedVector(targetEntity:GetOrigin(), player:GetEyePos()), "none")
    
    if Server and healthScalar ~= targetEntity:GetHealthScalar() then
        targetEntity:TriggerEffects("sprayed")
    end

end

local function HealEntity(self, player, targetEntity)

    local onEnemyTeam = (GetEnemyTeamNumber(player:GetTeamNumber()) == targetEntity:GetTeamNumber())
    local isEnemyPlayer = onEnemyTeam and targetEntity:isa("Player")
    local toTarget = (player:GetEyePos() - targetEntity:GetOrigin()):GetUnit()

    // Heal players by base amount plus a scaleable amount so it's effective vs. small and large targets            
    local health = kHealsprayDamage + targetEntity:GetMaxHealth() * kHealPlayerPercent / 100.0
    
    // Heal structures by multiple of damage(so it doesn't take forever to heal hives, ala NS1)
    if GetReceivesStructuralDamage(targetEntity) then
        health = kHealsprayDamage * kHealBuildingScalar
    // Don't heal self at full rate - don't want Gorges to be too powerful. Same as NS1.
    elseif targetEntity == player then
        health = health * .5
    end
    
    local amountHealed = targetEntity:AddHealth(health)

    if targetEntity.OnHealSpray then
        targetEntity:OnHealSpray(player)
    end         
    
    if Server and amountHealed > 0 then
        targetEntity:TriggerEffects("sprayed")
    end
    
    player:OnRepair(targetEntity, amountHealed > 0)
        
end

local kConeWidth = 0.6
local function GetEntitiesWithCapsule(self, player)

    local fireDirection = player:GetViewCoords().zAxis
    // move a bit back for more tolerance, healspray does not need to be 100% exact
    local startPoint = player:GetEyePos() + player:GetViewCoords().yAxis * 0.2

    local extents = Vector(kConeWidth, kConeWidth, kConeWidth)
    local remainingRange = kRange
 
    local ents = {}
    
    // always heal self as well
    HealEntity(self, player, player)
    
    for i = 1, 4 do
    
        if remainingRange <= 0 then
            break
        end
        
        local trace = TraceMeleeBox(self, startPoint, fireDirection, extents, remainingRange, PhysicsMask.Melee, EntityFilterOne(player))
        
        if Server then
            Server.dbgTracer:TraceMelee(player, startPoint, trace, extents, player:GetViewAngles():GetCoords())
        end
        
        if trace.fraction ~= 1 then
        
            if trace.entity then
            
                if HasMixin(trace.entity, "Live") then
                    table.insertunique(ents, trace.entity)
                end
        
            else
            
                // Make another trace to see if the shot should get deflected.
                local lineTrace = Shared.TraceRay(startPoint, startPoint + remainingRange * fireDirection, CollisionRep.LOS, PhysicsMask.Melee, EntityFilterOne(player))
                
                if Server then
                    Server.dbgTracer:TraceBullet(player, startPoint, lineTrace)
                end

                if lineTrace.fraction < 0.8 then
                
                    local dotProduct = trace.normal:DotProduct(fireDirection) * -1

                    if dotProduct > 0.6 then
                        self:TriggerEffects("healspray_collide",  {effecthostcoords = Coords.GetTranslation(lineTrace.endPoint)})
                        break
                    else                    
                        fireDirection = fireDirection + trace.normal * dotProduct
                        fireDirection:Normalize()
                    end    
                        
                end
                
            end
            
            remainingRange = remainingRange - (trace.endPoint - startPoint):GetLength() - kConeWidth
            startPoint = trace.endPoint + fireDirection * kConeWidth + trace.normal * 0.05
        
        else
            break
        end

    end
    
    return ents

end


local function GetEntitiesInCylinder(self, player, viewCoords, range, width)

    // gorge always heals itself    
    local ents = { player }
    local startPoint = viewCoords.origin
    local fireDirection = viewCoords.zAxis
    
    local relativePos = nil
    
    for _, entity in ipairs( GetEntitiesWithMixinWithinRange("Live", startPoint, range) ) do
    
        relativePos = entity:GetOrigin() - startPoint
        local yDistance = viewCoords.yAxis:DotProduct(relativePos)
        local xDistance = viewCoords.xAxis:DotProduct(relativePos)
        local zDistance = viewCoords.zAxis:DotProduct(relativePos)

        local xyDistance = math.sqrt(yDistance * yDistance + xDistance * xDistance)

        // could perform a LOS check here or simply keeo the code a bit more tolerant. healspray is kinda gas and it would require complex calculations to make this check be exact
        if xyDistance <= width and zDistance >= 0 then
            table.insert(ents, entity)
        end
    
    end
    
    return ents

end

local function GetEntitiesInCone(self, player)

    local range = 0
    
    local viewCoords = player:GetViewCoords()
    local fireDirection = viewCoords.zAxis
    
    local startPoint = viewCoords.origin + viewCoords.yAxis * kHealCylinderWidth * 0.2
    local lineTrace1 = Shared.TraceRay(startPoint, startPoint + kRange * fireDirection, CollisionRep.LOS, PhysicsMask.Melee, EntityFilterAll())
    if Server then
        Server.dbgTracer:TraceBullet(player, startPoint, lineTrace1)
    end    
    if (lineTrace1.endPoint - startPoint):GetLength() > range then
        range = (lineTrace1.endPoint - startPoint):GetLength()
    end

    startPoint = viewCoords.origin - viewCoords.yAxis * kHealCylinderWidth * 0.2
    local lineTrace2 = Shared.TraceRay(startPoint, startPoint + kRange * fireDirection, CollisionRep.LOS, PhysicsMask.Melee, EntityFilterAll())    
    if Server then
        Server.dbgTracer:TraceBullet(player, startPoint, lineTrace2)
    end
    if (lineTrace2.endPoint - startPoint):GetLength() > range then
        range = (lineTrace2.endPoint - startPoint):GetLength()
    end
    
    startPoint = viewCoords.origin - viewCoords.xAxis * kHealCylinderWidth * 0.2
    local lineTrace3 = Shared.TraceRay(startPoint, startPoint + kRange * fireDirection, CollisionRep.LOS, PhysicsMask.Melee, EntityFilterAll())    
    if Server then
        Server.dbgTracer:TraceBullet(player, startPoint, lineTrace3)
    end
    if (lineTrace3.endPoint - startPoint):GetLength() > range then
        range = (lineTrace3.endPoint - startPoint):GetLength()
    end
    
    startPoint = viewCoords.origin + viewCoords.xAxis * kHealCylinderWidth * 0.2
    local lineTrace4 = Shared.TraceRay(startPoint, startPoint + kRange * fireDirection, CollisionRep.LOS, PhysicsMask.Melee, EntityFilterAll())
    if Server then
        Server.dbgTracer:TraceBullet(player, startPoint, lineTrace4)
    end
    if (lineTrace4.endPoint - startPoint):GetLength() > range then
        range = (lineTrace4.endPoint - startPoint):GetLength()
    end

    return GetEntitiesInCylinder(self, player, viewCoords, range, kHealCylinderWidth)

end

local function PerformHealSpray(self, player)
 
    for _, entity in ipairs(GetEntitiesInCone(self, player)) do
    
        if HasMixin(entity, "Team") then
        
            if entity:GetTeamNumber() == player:GetTeamNumber() then
                HealEntity(self, player, entity)
            elseif GetAreEnemies(entity, player) then
                DamageEntity(self, player, entity)
            end

        end
                
    end

end

function HealSprayMixin:OnTag(tagName)

    PROFILE("HealSprayMixin:OnTag")

    if self.secondaryAttacking and tagName == "heal" then
        
        local player = self:GetParent()
        if player and player:GetEnergy() >= self:GetSecondaryEnergyCost(player) then
        
            PerformHealSpray(self, player)            
            player:DeductAbilityEnergy(self:GetSecondaryEnergyCost(player))
            self:TriggerEffects("heal_spray")
            self.lastSecondaryAttackTime = Shared.GetTime()
        
        end
    
    end
    
end

function HealSprayMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("HealSprayMixin:OnUpdateAnimationInput")

    local player = self:GetParent()
    if player and self.secondaryAttacking and player:GetEnergy() >= self:GetSecondaryEnergyCost(player) then
        modelMixin:SetAnimationInput("activity", "secondary")
    end
    
end