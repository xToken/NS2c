-- ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
--
-- lua\DamageMixin.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Added in severe hits, used for >33% damage in a set period of time.
-- Also added flag for not having a weapons attacks 'predicted' client side.

DamageMixin = CreateMixin(DamageMixin)
DamageMixin.type = "Damage"

function DamageMixin:__initmixin()
    PROFILE("DamageMixin:__initmixin")
end

-- damage type, doer and attacker don't need to be passed. that info is going to be fetched here. pass optional surface name
-- pass surface "none" for not hit/flinch effect
function DamageMixin:DoDamage(damage, target, point, direction, surface, altMode, showtracer)

    -- No prediction if the Client is spectating another player.
    if Client and not Client.GetIsControllingPlayer() then
        return false
    end
    
    local killedFromDamage = false
    local flinch_severe = false
    local doer = self

    -- attacker is always a player, doer is 'self'
    local attacker, weapon
    local currentComm
    
    if target and target:isa("Ragdoll") then
        return false
    end
    
    if target and not (target.GetCanTakeDamage and target:GetCanTakeDamage()) then
        return false
    end
        
    if self:isa("Player") then
        attacker = self
    else

        if self:GetParent() and self:GetParent():isa("Player") then
            attacker = self:GetParent()
            parentVortexed = GetIsVortexed(attacker)
            
            if attacker:isa("Alien") and (self.secondaryAttacking or self.shootingSpikes) then
                weapon = attacker:GetActiveWeapon():GetSecondaryTechId()
            else
                weapon = self:GetTechId()
            end
            
        elseif HasMixin(self, "Owner") and self:GetOwner() and self:GetOwner():isa("Player") then
            
            attacker = self:GetOwner()
            
            if self.GetWeaponTechId then
                weapon = self:GetWeaponTechId()
            elseif self.GetTechId then
                weapon = self:GetTechId()
            end
        end

    end

    if not attacker then
        attacker = doer
    end

    if attacker then
    
        -- Get damage type from source
        local damageType = kDamageType.Normal
        if self.GetDamageType then
            damageType = self:GetDamageType()
        elseif HasMixin(self, "Tech") then
            damageType = LookupTechData(self:GetTechId(), kTechDataDamageType, kDamageType.Normal)
        end
        
        local armorUsed = 0
        local healthUsed = 0
        local damageDone = 0
        
        if target and HasMixin(target, "Live") and damage > 0 then  

            damage, armorUsed, healthUsed = GetDamageByType(target, attacker, doer, damage, damageType, point)

            -- check once the damage
            if not direction then
                direction = Vector(0, 0, 1)
            end
            
            killedFromDamage, damageDone = target:TakeDamage(damage, attacker, doer, point, direction, armorUsed, healthUsed, damageType)
            
            if damage > 0 then    
                                
                -- Many types of damage events are server-only, such as grenades.
                -- Send the player a message so they get feedback about what damage they've done.
                -- We use messages to handle multiple-hits per frame, such as splash damage from grenades.
                if Server and attacker:isa("Player") then
                
                    if GetAreEnemies( attacker, target ) then
                        
                        local amount = (target:GetIsAlive() or killedFromDamage) and damageDone or 0 // actual damage done
                        local overkill = healthUsed + armorUsed * 2 // the full amount of potential damage, including overkill
                        
                        if HitSound_IsEnabledForWeapon( weapon ) then
                            -- Damage message will be sent at the end of OnProcessMove by the HitSound system
                            HitSound_RecordHit( attacker, target, amount, point, overkill, weapon )
                        else
                            SendDamageMessage( attacker, target, amount, point, overkill )
                        end
                        
                        SendMarkEnemyMessage( attacker, target, amount, weapon )
                    
                    end
                    
                    -- This makes the cross hair turn red. Show it when hitting enemies only
                    if (not doer.GetShowHitIndicator or doer:GetShowHitIndicator()) and GetAreEnemies(attacker, target) then
                        attacker.giveDamageTime = Shared.GetTime()
                    end
                    
                    -- Apply knockback if weapon causes it
                    if doer.GetKnockbackForce and not killedFromDamage then
                        ApplyPlayerKnockback(attacker, target, doer:GetKnockbackForce())
                    end
                    
                end
                
                if target.damagetable ~= nil and not killedFromDamage then
                    if target.damagetable.dtime ~= nil and target.damagetable.dtime + kFlinchDamageInterval > Shared.GetTime() then
                        if target.damagetable.ddamage ~= nil and target.damagetable.ddamage + damage > ((target:GetMaxHealth() + target:GetMaxArmor()) * kFlinchDamagePercent) then
                            target.damagetable.ddamage = 0
                            target.damagetable.dtime = 0
                            flinch_severe = true
                        else
                            target.damagetable.ddamage = target.damagetable.ddamage + damage
                        end
                    else
                        target.damagetable.dtime = Shared.GetTime()
                        target.damagetable.ddamage = damage
                    end
                elseif target.damagetable == nil then
                    target.damagetable = {ddamage = damage, dtime = 0}
                end
                
                if self.OnDamageDone then
                    self:OnDamageDone(doer, target)
                end

                if attacker and attacker.OnDamageDone then
                    attacker:OnDamageDone(doer, target)
                end
                
            end

        end
        
        -- trigger damage effects (damage, deflect) with correct surface
        if surface ~= "none" then
            local armorMultiplier = ConditionalValue(damageType == kDamageType.Light, 4, 2)
            armorMultiplier = ConditionalValue(damageType == kDamageType.Heavy, 1, armorMultiplier)
        
            local playArmorEffect = armorUsed * armorMultiplier > healthUsed
            
            if not target then
                            
                if not surface or surface == "" then
                    surface = "metal"
                end
            
            elseif not surface or surface == "" then
            
                surface = GetIsAlienUnit(target) and "organic" or "metal"

                -- define metal_thin, rock, or other
                if target.GetSurfaceOverride then
                    
                    surface = target:GetSurfaceOverride(damageDone) or surface
                    
                elseif GetAreEnemies(self, target) then

                    if target:isa("Alien") then
                        surface = "organic"
                    elseif target:isa("Marine") then
                        surface = "flesh"
                    else
                    
                        if HasMixin(target, "Team") then
                        
                            if target:GetTeamType() == kAlienTeamType then
                                surface = "organic"
                            else
                                surface = "metal"
                            end
                            
                        end
                    
                    end

                end

            end
            
            -- send to all players in range, except to attacking player, he will predict the hit effect
            local isPredicted = doer.GetAreAttackEffectsPredicted and doer:GetAreAttackEffectsPredicted()

            if Server then
            
                if GetShouldSendHitEffect() then
                                
                    local directionVectorIndex = 1
                    if direction then
                        directionVectorIndex = GetIndexFromVector(direction)
                    end
                    
                    local message = BuildHitEffectMessage(point, doer, surface, target, showtracer, altMode, flinch_severe, damage, directionVectorIndex)
                    
                    local toPlayers = GetEntitiesWithinRange("Player", point, kHitEffectRelevancyDistance)                    
                    for _, spectator in ientitylist(Shared.GetEntitiesWithClassname("Spectator")) do
                    
                        if table.icontains(toPlayers, Server.GetOwner(spectator):GetSpectatingPlayer()) then
                            table.insertunique(toPlayers, spectator)
                        end
                        
                    end
                    
                    -- No need to send to the attacker if this is a child of the attacker.
                    -- Children such as weapons are simulated on the Client as well so they will
                    -- already see the hit effect.
                    if isPredicted and attacker and self:GetParent() == attacker then
                        table.removevalue(toPlayers, attacker)
                    end
                    
                    for _, player in ipairs(toPlayers) do
                        Server.SendNetworkMessage(player, "HitEffect", message, false) 
                    end
                
                end

            elseif Client and isPredicted then
            
                HandleHitEffect(point, doer, surface, target, showtracer, altMode, flinch_severe, damage, direction)

                -- If we are far away from our target, trigger a private sound so we can hear we hit something
                if target then
                    
                    if attacker.MarkEnemyFromClient then
                        attacker:MarkEnemyFromClient( target, weapon )
                    end
                    
                    if (point - attacker:GetOrigin()):GetLength() > 5 then
                        attacker:TriggerEffects("hit_effect_local")
                    end
                    
                end
                
            end
            
        end
        
    end
    
    return killedFromDamage
    
end