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
        local viewCoords = viewAngles:GetCoords()
        local startPoint = player:GetOrigin() + viewCoords.zAxis * 1.5
        local endPoint = startPoint + Vector(0, 1.5, 0)
        
        // trace from start to end to make sure the bomb won't wall through the ground
        local trace = Shared.TraceRay(player:GetOrigin(), endPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(player))
         startPoint = trace.endPoint
        if trace.fraction ~= 1 then
            startPoint = startPoint + trace.normal * 0.3
        end
        local startVelocity = player:GetVelocity() * kPlayerVelocityFraction + viewCoords.zAxis * kRocketVelocity
        
        local rocket = CreateEntity(Rocket.kMapName, startPoint, player:GetTeamNumber())
        rocket:Setup(player, startVelocity, true)
        
    end

end

function AcidRocket:OnUpdateAnimationInput(modelMixin)

    PROFILE("AcidRocket:OnUpdateAnimationInput")
    
    //modelMixin:SetAnimationInput("ability", "bomb")
        
    //local activityString = "none"
    //if self.firingPrimary then
        //activityString = "primary"
    //end
    //modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("AcidRocket", AcidRocket.kMapName, AcidRocket.networkVars )
