//
// lua\Weapons\Alien\AcidRocket.lua
// Created by:   Dragon

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Rocket.lua")
Script.Load("lua/Weapons/Alien/Blink.lua")

class 'AcidRocket' (Blink)

AcidRocket.kMapName = "acidrocket"

local kPlayerVelocityFraction = .5
local kRocketVelocity = 45

local kAnimationGraph = PrecacheAsset("models/alien/fade/fade_view.animation_graph")

AcidRocket.networkVars =
{
    lastPrimaryAttackTime = "time"
}

function AcidRocket:OnCreate()

    Blink.OnCreate(self)
    self.lastPrimaryAttackTime = 0
    
end

function AcidRocket:GetAnimationGraphName()
    return kAnimationGraph
end

function AcidRocket:GetEnergyCost(player)
    return kAcidRocketEnergyCost
end

function AcidRocket:GetIconOffsetY(secondary)
    return kAbilityOffset.BileBomb
end

function AcidRocket:GetPrimaryAttackDelay()
    return kAcidRocketFireDelay
end

function AcidRocket:GetDeathIconIndex()
    return kDeathMessageIcon.BileBomb
end

function AcidRocket:GetHUDSlot()
    return 3
end

function AcidRocket:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() and Shared.GetTime() > (self.lastPrimaryAttackTime + self:GetPrimaryAttackDelay()) then
        if Server or (Client and Client.GetIsControllingPlayer()) then
            self:FireRocketProjectile(player)
        end
        self.lastPrimaryAttackTime = Shared.GetTime()
        self:TriggerEffects("acidrocket_attack")
        player:DeductAbilityEnergy(self:GetEnergyCost())
    end  
    
end

function AcidRocket:GetPrimaryAttackRequiresPress()
    return false
end

function AcidRocket:GetBlinkAllowed()
    return true
end

function AcidRocket:FireRocketProjectile(player)

    if not Predict then
        
        local viewAngles = player:GetViewAngles()
        local velocity = player:GetVelocity()
        local viewCoords = viewAngles:GetCoords()
        local startPoint = player:GetEyePos() + viewCoords.zAxis * 0.3
        local startVelocity = velocity * kPlayerVelocityFraction + viewCoords.zAxis * kRocketVelocity
        
        local rocket = player:CreatePredictedProjectile("Rocket", startPoint, startVelocity, nil, nil, 5, true)
        
    end

end

function AcidRocket:OnUpdateAnimationInput(modelMixin)
    PROFILE("AcidRocket:OnUpdateAnimationInput")    
end

Shared.LinkClassToMap("AcidRocket", AcidRocket.kMapName, AcidRocket.networkVars )
