// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Blink.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Blink - Attacking many times in a row will create a cool visual "chain" of attacks, 
// showing the more flavorful animations in sequence. Base class for swipe and Metabolize, available at tier 2.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Weapons/Alien/Ability.lua")

class 'Blink' (Ability)
Blink.kMapName = "blink"

local kEtherealForce = 8
Blink.kMinEnterEtherealTime = 0.1
Blink.kMinTimeBetweenEffects = 0.2

local networkVars =
{
    lastblinktime = "time"
}

function Blink:OnCreate()

    Ability.OnCreate(self)
    self.lastblinktime = 0

end

function Blink:OnHolster(player)

    Ability.OnHolster(self, player)
    
    self:SetEthereal(player, false)
    
end

function Blink:GetHasSecondary(player)
    return player:GetHasOneHive() 
end

function Blink:GetSecondaryAttackRequiresPress()
    return true
end

function Blink:TriggerBlinkOutEffects(player)
    player:TriggerEffects("blink_out")
end

function Blink:TriggerBlinkInEffects(player)
    player:TriggerEffects("blink_in")
end

function Blink:GetIsBlinking()

    local player = self:GetParent()
    
    if player then
        return player:GetIsBlinking()
    end
    
    return false
    
end

// Cannot attack while blinking.
function Blink:GetPrimaryAttackAllowed()
    return not self:GetIsBlinking()
end

function Blink:GetSecondaryEnergyCost(player)
    return kStartBlinkEnergyCost
end

function Blink:OnSecondaryAttack(player)

    if self:GetBlinkAllowed() then
        self:SetEthereal(player, true)
        self.lastblinktime = Shared.GetTime()
    end
    
    Ability.OnSecondaryAttack(self, player)
    
end

function Blink:OnSecondaryAttackEnd(player)

    if player.ethereal then
        self:SetEthereal(player, false)
    end
    
    Ability.OnSecondaryAttackEnd(self, player)
    
end

function Blink:SetEthereal(player, state)

    if player.ethereal ~= state then
    
        if state then
            player.etherealStartTime = Shared.GetTime()
            self:TriggerBlinkOutEffects(player)            
        else
            self:TriggerBlinkInEffects(player)     
            player.etherealEndTime = Shared.GetTime() 
        end
        
        player.ethereal = state
        
        if player.ethereal then
            player:OnBlink()
        else
            player:OnBlinkEnd()  
        end
        
    end
    
end

function Blink:ProcessMoveOnWeapon(player, input)
    if not player.ethereal then
        return
    end
    
    local time = Shared.GetTime()
    local deltaTime = time - (self.lastBlinkTime or 0)
    // Check time and energy
    if deltaTime > kBlinkCooldown and player:GetEnergy() > kBlinkPulseEnergyCost then
        // Blink.
        player.lastBlinkTime = time
        player:OnBlinking(input)
        player:DeductAbilityEnergy(kBlinkPulseEnergyCost)
        
        if deltaTime > Blink.kMinTimeBetweenEffects then
            // Just pressed blink, play effect
            self:TriggerBlinkInEffects(player)
        end
    end
    
end

function Blink:OnUpdateAnimationInput(modelMixin)

    local player = self:GetParent()
    if self:GetIsBlinking() then
        modelMixin:SetAnimationInput("move", "blink")
    end
    
end

Shared.LinkClassToMap("Blink", Blink.kMapName, networkVars)