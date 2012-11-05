//
// lua\Weapons\Alien\AcidRocket.lua

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Rocket.lua")
Script.Load("lua/Weapons/Alien/Blink.lua")
Script.Load("lua/DamageMixin.lua")

class 'AcidRocket' (Blink)

AcidRocket.kMapName = "acidrocket"

local kPlayerVelocityFraction = .5
local kRocketVelocity = 45

local kAnimationGraph = PrecacheAsset("models/alien/fade/fade_view.animation_graph")

AcidRocket.networkVars =
{
    firingPrimary = "boolean"
}

function AcidRocket:OnCreate()

    Blink.OnCreate(self)
    InitMixin(self, DamageMixin)
        
    self.firingPrimary = false
    self.timeLastAcidRocket = 0
    
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

    if player:GetEnergy() >= self:GetEnergyCost() and Shared.GetTime() > (self.timeLastAcidRocket + self:GetPrimaryAttackDelay()) then
        if Server then
            self:FireRocketProjectile(player)
            player:DeductAbilityEnergy(self:GetEnergyCost())
        end
        self.firingPrimary = true
        self.timeLastAcidRocket = Shared.GetTime()
        self:TriggerEffects("acidrocket_attack")
    else
        self.firingPrimary = false
    end  
    
end

function AcidRocket:OnPrimaryAttackEnd(player)

    Ability.OnPrimaryAttackEnd(self, player)
    self.firingPrimary = false
    
end

function AcidRocket:GetTimeLastAcidRocket()
    return self.timeLastAcidRocket
end

function AcidRocket:GetPrimaryAttackRequiresPress()
    return false
end

function AcidRocket:GetBlinkAllowed()
    return true
end

function AcidRocket:FireRocketProjectile(player)

    if Server then
        
        local viewAngles = player:GetViewAngles()
        local velocity = player:GetVelocity()
        local viewCoords = viewAngles:GetCoords()
        local startPoint = player:GetEyePos() + viewCoords.zAxis * 0.35 + Vector(0, 0, -0.25)
        
        local startPointTrace = Shared.TraceRay(player:GetEyePos(), startPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(player))
        startPoint = startPointTrace.endPoint
        
        local startVelocity = velocity * kPlayerVelocityFraction + viewCoords.zAxis * kRocketVelocity
        
        local rocket = CreateEntity(Rocket.kMapName, startPoint, player:GetTeamNumber())
        rocket:Setup(player, startVelocity, true, Vector(0.20,0.20,0.20))
        
    end

end

function AcidRocket:OnUpdateAnimationInput(modelMixin)
    PROFILE("AcidRocket:OnUpdateAnimationInput")    
end

Shared.LinkClassToMap("AcidRocket", AcidRocket.kMapName, AcidRocket.networkVars )
