-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\Hydra_Server.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- Creepy plant turret the Gorge can create.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Removed team tracking of gorge structures

Hydra.kUpdateInterval = .5

function Hydra:OnKill(attacker, doer, point, direction)

    local parent = self:GetOwner()

    ScriptActor.OnKill(self, attacker, doer, point, direction)
    
    if GetServerGameMode() == kGameMode.Combat and parent and parent:isa("Player") then
        -- Refund costs.
        parent:AddResources(LookupTechData(self:GetTechId(), kTechDataCombatCost, 0))
    end
    
    local team = self:GetTeam()
    if team then
        team:UpdateClientOwnedStructures(self:GetId())
    end

end

function Hydra:GetDistanceToTarget(target)
    return (target:GetEngagementPoint() - self:GetModelOrigin()):GetLength()           
end

local function CreateSpikeProjectile(self)

    -- TODO: make hitscan at account for target velocity (more inaccurate at higher speed)
    
    local startPoint = self:GetBarrelPoint()
    local directionToTarget = self.target:GetEngagementPoint() - self:GetEyePos()
    local targetDistanceSquared = directionToTarget:GetLengthSquared()
    local theTimeToReachEnemy = targetDistanceSquared / (Hydra.kSpikeSpeed * Hydra.kSpikeSpeed)
    local engagementPoint = self.target:GetEngagementPoint()
    if self.target.GetVelocity then
    
        local targetVelocity = self.target:GetVelocity()
        engagementPoint = self.target:GetEngagementPoint() - ((targetVelocity:GetLength() * Hydra.kTargetVelocityFactor * theTimeToReachEnemy) * GetNormalizedVector(targetVelocity))
        
    end
    
    local fireDirection = GetNormalizedVector(engagementPoint - startPoint)
    local fireCoords = Coords.GetLookIn(startPoint, fireDirection)    
    local spreadDirection = CalculateSpread(fireCoords, Hydra.kSpread, math.random)
    
    local endPoint = startPoint + spreadDirection * Hydra.kRange
    
    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOneAndIsa(self, "Hydra"))
    
    if trace.fraction < 1 then
    
        local surface

        -- Disable friendly fire.
        trace.entity = (not trace.entity or GetAreEnemies(trace.entity, self)) and trace.entity or nil
        
        if not trace.entity then
            surface = trace.surface
        end
        
        -- local direction = (trace.endPoint - startPoint):GetUnit()
        self:DoDamage(Hydra.kDamage, trace.entity, trace.endPoint, fireDirection, surface, false, true)
        
    end
    
end

function Hydra:AttackTarget()

    self:TriggerUncloak()
    
    CreateSpikeProjectile(self)    
    self:TriggerEffects("hydra_attack")
    
    -- Random rate of fire to prevent players from popping out of cover and shooting regularly
    self.timeOfNextFire = Shared.GetTime() + .5 + math.random()
    
end

function Hydra:OnOwnerChanged(_, newOwner)

    self.hydraParentId = Entity.invalidId
    if newOwner ~= nil then
        self.hydraParentId = newOwner:GetId()
    end
    
end

function Hydra:OnUpdate(deltaTime)

    PROFILE("Hydra:OnUpdate")
    
    ScriptActor.OnUpdate(self, deltaTime)
    
    if not self.timeLastUpdate then
        self.timeLastUpdate = Shared.GetTime()
    end
    
    if self.timeLastUpdate + Hydra.kUpdateInterval < Shared.GetTime() then
    
        if GetIsUnitActive(self) then
            self.target = self.targetSelector:AcquireTarget()

            -- Check for obstacles between the origin and barrel point of the hydra so it doesn't shoot while sticking through walls
            self.attacking = self.target and not GetWallBetween(self:GetBarrelPoint(), self:GetOrigin(), self)

            if self.attacking and (not self.timeOfNextFire or Shared.GetTime() > self.timeOfNextFire) then
                self:AttackTarget()
            elseif not self.target then
                -- Play alert animation if marines nearby and we're not targeting (ARCs?)
                if not self.timeLastAlertCheck or Shared.GetTime() > self.timeLastAlertCheck + Hydra.kAlertCheckInterval then
                
                    self.alerting = false
                    
                    if self:GetIsEnemyNearby() then
                    
                        self.alerting = true
                        self.timeLastAlertCheck = Shared.GetTime()
                        
                    end
                    
                end
            end

        else
            self.attacking = false
        end
        
        self.timeLastUpdate = Shared.GetTime()
        
    end
    
end

function Hydra:GetIsEnemyNearby()

    local enemyActors = GetEntitiesForTeam("ScriptActor", GetEnemyTeamNumber(self:GetTeamNumber()))
    
    for index, actors in ipairs(enemyActors) do
    
        if actors:GetIsVisible() and not actors:isa("Commander") then
        
            local dist = self:GetDistanceToTarget(actors)
            if dist < Hydra.kRange then
                return true
            end
            
        end
        
    end
    
    return false
    
end
