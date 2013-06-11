// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ARC_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// AI controllable "tank" that the Commander can move around, deploy and use for long-distance
// siege attacks.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kARCDamageOffset = Vector(0, 0.3, 0)
local kMoveParam = "move_speed"
local kMuzzleNode = "fxnode_arcmuzzle"

function ARC:SetTargetDirection(target)
    self.targetDirection = GetNormalizedVector(target:GetEngagementPoint() - self:GetAttachPointOrigin(kMuzzleNode))
end

function ARC:ClearTargetDirection()
    self.targetDirection = nil
end

function ARC:UpdateOrders(deltaTime)

    // If deployed, check for targets
    local currentOrder = self:GetCurrentOrder()
    if currentOrder then
    
        if currentOrder:GetType() == kTechId.Attack and self.deployMode == ARC.kDeployMode.Deployed then
            
            local target = self:GetTarget()
            if target ~= nil and self:GetCanFireAtTarget(target, nil) then
                self:SetTargetDirection(target)
            else
            
                self:ClearTargetDirection()
                self:ClearCurrentOrder()
                
            end
            
        end
    
    elseif self:GetInAttackMode() then
    
        // Check for new target every so often, but not every frame
        local time = Shared.GetTime()
        if self.timeOfLastAcquire == nil or (time > self.timeOfLastAcquire + 0.2) then
        
            self:AcquireTarget()
            
            self.timeOfLastAcquire = time
            
        end

    end

end

function ARC:AcquireTarget()
    
    local finalTarget = nil
    
    finalTarget = self.targetSelector:AcquireTarget()
    
    if finalTarget ~= nil then
    
        self:GiveOrder(kTechId.Attack, finalTarget:GetId(), nil)
        self:SetMode(ARC.kMode.Targeting)
        
    else
    
        self:ClearOrders()
        self:SetMode(ARC.kMode.Stationary)
        
    end
    
end

local function PerformAttack(self)

    local target = self:GetTarget()
    if target then
    
        self:TriggerEffects("arc_firing")
    
        // Play big hit sound at origin
        target:TriggerEffects("arc_hit_primary")

        // Do damage to everything in radius. Use upgraded splash radius if researched.
        local damageRadius = ARC.kSplashRadius
        local hitEntities = GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(self:GetTeamNumber()), target:GetOrigin() + kARCDamageOffset, damageRadius)

        // Do damage to every target in range
        RadiusDamage(hitEntities, target:GetOrigin(), damageRadius, ARC.kAttackDamage, self, true)

        // Play hit effect on each
        for index, target in ipairs(hitEntities) do
        
            target:TriggerEffects("arc_hit_secondary")
            
        end
        
        if not self:GetCanFireAtTarget(target, targetPoint) then
            self:ClearOrders()
        end
        
        TEST_EVENT("ARC attacked entity")
        
    end
    
end

function ARC:SetMode(mode)
    if mode ~= 1 and mode ~= 2 and mode ~= 3 then
        assert(false)
    end
    if self.mode ~= mode then
    
        local triggerEffectName = "arc_" .. string.lower(EnumToString(ARC.kMode, mode))        
        self:TriggerEffects(triggerEffectName)
        
        self.mode = mode
        
        // Now process actions per mode
        if self.deployMode == ARC.kDeployMode.Deployed then
            self:AcquireTarget()
        end
        
    end
    
end

function ARC:OnTag(tagName)

    PROFILE("ARC:OnTag")
    
    if tagName == "fire_start" then
        PerformAttack(self)
    elseif tagName == "target_start" then
        self:TriggerEffects("arc_charge")
    elseif tagName == "attack_end" then
        self:SetMode(ARC.kMode.Targeting)
    elseif tagName == "deploy_end" and self.deployMode == ARC.kDeployMode.Deploying then
        // Clear orders when deployed so new ARC attack order will be used
        self.deployMode = ARC.kDeployMode.Deployed
        self:ClearOrders()
        // notify the target selector that we have moved.
		TEST_EVENT("ARC Deployed")
        
    elseif tagName == "undeploy_end" then
    
        self.deployMode = ARC.kDeployMode.Undeployed
        TEST_EVENT("ARC Undeployed")
    end
    
end

function ARC:ForceDeployed()
    if self.deployMode == ARC.kDeployMode.Deploying then
        self.deployMode = ARC.kDeployMode.Deployed
        self:ClearOrders()
    else
        self.deployMode = ARC.kDeployMode.Undeploying
    end
end