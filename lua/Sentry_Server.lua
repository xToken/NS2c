// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Sentry_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Sentry:OnOverrideOrder(order)
    
    local orderTarget = nil
    if (order:GetParam() ~= nil) then
        orderTarget = Shared.GetEntity(order:GetParam())
    end
    
    // Default orders to enemies => attack
    if order:GetType() == kTechId.Default and orderTarget and HasMixin(orderTarget, "Live") and GetEnemyTeamNumber(orderTarget:GetTeamNumber()) == self:GetTeamNumber() and (not HasMixin(orderTarget, "LOS") or orderTarget:GetIsSighted()) then
    
        order:SetType(kTechId.Attack)
        
    end
    
end

function Sentry:OnConstructionComplete()
    self:SetDesiredMode(Sentry.kMode.Scanning)  
    self:AddTimedCallback(Sentry.OnDeploy, Sentry.kDeployTime)      
end

function Sentry:OnDeploy()
    self.mode = Sentry.kMode.Scanning
    self.deployed = true
    return false
end

function Sentry:OnDisrupt(duration)
    self:Confuse(duration)
end

function Sentry:SetMode(mode)
    self.mode = mode
end

function Sentry:SetDesiredMode(mode)
    self.desiredMode = mode
end

function Sentry:GetDamagedAlertId()
    return kTechId.MarineAlertSentryUnderAttack
end

function Sentry:FireBullets()

    // Use x-axis of muzzle node, so when the model flinches, it becomes less accurate
    local angles = Angles(0,0,0)
    angles.yaw = self.barrelYawDegrees
    angles.pitch = self.barrelPitchDegrees
    local fireCoords = Coords.GetLookIn(Vector(0,0,0), self.targetDirection)
 
    local startPoint = self:GetBarrelPoint()
    local alertToTrigger = kTechId.None
    
    for bullet = 1, Sentry.kBulletsPerSalvo do
    
        local spreadDirection = CalculateSpread(fireCoords, Sentry.kSpread, math.random)
        
        local endPoint = startPoint + spreadDirection * Sentry.kRange
        
        local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(self))

        if trace.fraction < 1 then
        
            local rampUpFraction = Clamp((Shared.GetTime() - self.timeLastTargetChange) / kSentryDamageRampUpDuration, 0, 1)
            local damage = kSentryMinAttackDamage + (kSentryMaxAttackDamage - kSentryMinAttackDamage) * rampUpFraction
            local surface = trace.surface
            
            // Disable friendly fire.
            trace.entity = (not trace.entity or GetAreEnemies(trace.entity, self)) and trace.entity or nil
            
            local blockedByUmbra = trace.entity and GetBlockedByUmbra(trace.entity) or false
            
            if blockedByUmbra then
            
                surface = "umbra"
                damage = 0
                
            end
            
            local direction = (trace.endPoint - startPoint):GetUnit()
            self:DoDamage(damage, trace.entity, trace.endPoint, direction, surface, false, math.random() < 0.2)
            
        end
        
        bulletsFired = true
        
    end
    
    if Server and alertToTrigger ~= kTechId.None then
        self:GetTeam():TriggerAlert(alertToTrigger, self)    
    end
    
end

// Update rotation state when setting target
function Sentry:UpdateSetTarget()

    if self:GetSentryMode() == Sentry.kMode.SettingTarget then
    
        local currentOrder = self:GetCurrentOrder()
        if currentOrder ~= nil then
        
            local target = self:GetTarget()
            
            local vecToTarget = nil
            if currentOrder:GetLocation() ~= nil then
                vecToTarget = currentOrder:GetLocation() - self:GetModelOrigin()
            elseif target ~= nil then
                vecToTarget =  target:GetModelOrigin() - self:GetModelOrigin()
            else
                Print("Sentry:UpdateSetTarget(): sentry has attack order without valid entity id or location.")
                self:CompletedCurrentOrder()
                return 
            end            
            
            // Move sentry to face target point
            local currentYaw = self:GetAngles().yaw
            local desiredYaw = GetYawFromVector(vecToTarget)
            
            // Shortest rotation direction 
            if ((desiredYaw - currentYaw) > math.pi) then
                desiredYaw = desiredYaw - 2 * math.pi
            elseif ((desiredYaw - currentYaw) < -math.pi) then
                desiredYaw = desiredYaw + 2 * math.pi
            end
            
            local newYaw = InterpolateAngle(currentYaw, desiredYaw, Sentry.kReorientSpeed)

            local angles = Angles(self:GetAngles())
            angles.yaw = newYaw
            self:SetAngles(angles)
                        
            // Check if we're close enough to final orientation
            if( (newYaw - desiredYaw) % (2 * math.pi) == 0) then

                self:CompletedCurrentOrder()
                
                // So barrel doesn't "snap" after power-up
                self.barrelYawDegrees = 0
                
            end
            
        end 
       
    end
    
end

function Sentry:OnOrderChanged()

    if not self:GetHasOrder() then
    
        if self.mode == Sentry.kMode.Attacking or
           self.mode == Sentry.kMode.SettingTarget then
            self:SetDesiredMode(Sentry.kMode.Scanning)
        end
        
    else
    
        local orderType = self:GetCurrentOrder():GetType()
        if orderType == kTechId.Attack and self.mode == Sentry.kMode.Scanning then
            self:SetDesiredMode(Sentry.kMode.Attacking)
        elseif orderType == kTechId.Stop then
            self:SetDesiredMode(Sentry.kMode.Scanning)
        elseif orderType == kTechId.SetTarget then
            self:SetDesiredMode(Sentry.kMode.SettingTarget)
        end
        
    end
    
end

// check for spores in our way every 0.3 seconds
local function UpdateConfusedState(self, target)

    assert(target ~= nil)
    
    if not self.confused then
        
        if not self.timeCheckedForSpores then
            self.timeCheckedForSpores = Shared.GetTime() - 0.3
        end
        
        if self.timeCheckedForSpores + 0.3 < Shared.GetTime() then
        
            self.timeCheckedForSpores = Shared.GetTime()
        
            local eyePos = self:GetEyePos()
            local toTarget = target:GetOrigin() - eyePos
            local distanceToTarget = toTarget:GetLength()
            toTarget:Normalize()
            
            local stepLength = 3
            local numChecks = math.ceil(Sentry.kRange/stepLength)
            
            // check every few meters for a spore in the way, min distance 3 meters, max 12 meters (but also check sentry eyepos)
            for i = 0, numChecks do
            
                // stop when target has reached, any spores would be behind
                if distanceToTarget < (i * stepLength) then
                    break
                end
            
                local checkAtPoint = eyePos + toTarget * i * stepLength
                if self:GetFindsSporesAt(checkAtPoint) then
                    self:Confuse(Sentry.kConfuseDuration)
                    break
                end
            
            end
        
        end
        
    end

end

function Sentry:OnTargetChanged()
    self.timeLastTargetChange = Shared.GetTime()
end

function Sentry:UpdateTargetState()

    local order = self:GetCurrentOrder()
    local target = self:GetTarget()

    // Update hasTarget so model swings towards target entity or location
    local hasTarget = false
    
    if order ~= nil then
    
        // We have a target if we attacking an entity that's still valid or attacking ground
        local orderParam = order:GetParam()
        hasTarget = (order:GetType() == kTechId.Attack or order:GetType() == kTechId.SetTarget) and target ~= nil
    end
    
    if hasTarget then

        if target ~= nil then
        
            self.targetDirection = GetNormalizedVector(target:GetEngagementPoint() - self:GetAttachPointOrigin(Sentry.kMuzzleNode))
            UpdateConfusedState(self, target)
            
        else
            self.targetDirection = GetNormalizedVector(self:GetCurrentOrder():GetLocation() - self:GetAttachPointOrigin(Sentry.kMuzzleNode))
        end

    else
    
        if self:GetSentryMode() == Sentry.kMode.Attacking then
        
            self:CompletedCurrentOrder()

            // Don't choose new target right away, to make sure multiple attacks can overwhelm sentry
            self.timeOfLastTargetAcquisition = Shared.GetTime() + ConditionalValue(self.confused, Sentry.kConfusedTargetReacquireTime, Sentry.kTargetReacquireTime)
            
        end
        
        self.targetDirection = nil
        
    end
    
end

// checking at range 1.8 for overlapping the radius a bit. no LOS check here since i think it would become too expensive with multiple sentries
function Sentry:GetFindsSporesAt(position)
    return #GetEntitiesWithinRange("SporeCloud", position, 1.8) > 0
end

function Sentry:Confuse(duration)

    if not self.confused then
    
        self.confused = true
        self.timeConfused = Shared.GetTime() + duration
        
        StartSoundEffectOnEntity(Sentry.kConfusedSound, self)
        
    end
    
end