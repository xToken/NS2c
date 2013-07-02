//
// lua\Weapons\Alien\SporesMixin.lua

SporesMixin = CreateMixin( SporesMixin )
SporesMixin.type = "Spores"

local kRange = 20

// GetHasSecondary and GetSecondaryEnergyCost should completely override any existing
// same named function defined in the object.
SporesMixin.overrideFunctions =
{
    "GetHasSecondary",
    "GetSecondaryEnergyCost",
    "GetBarrelPoint",
    "OnSecondaryAttack",
    "OnSecondaryAttackEnd",
    "GetTracerEffectName"
}

SporesMixin.networkVars =
{
    lastSecondaryAttackTime = "time"
}

local function CreateSporeCloud(self, player)

    local trace = Shared.TraceRay(player:GetEyePos(), player:GetEyePos() + player:GetViewCoords().zAxis * kRange, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterTwo(self, player))
    local destination = trace.endPoint + trace.normal * 2
    
    local sporeCloud = CreateEntity(SporeCloud.kMapName, player:GetEyePos() + player:GetViewCoords().zAxis, player:GetTeamNumber())
    sporeCloud:SetOwner(player)
    sporeCloud:SetTravelDestination(destination)

end

local function GetHasAttackDelay(self, player)

    local attackDelay = kSporeAttackDelay / player:GetAttackSpeed()
    return self.lastSecondaryAttackTime + attackDelay > Shared.GetTime()
    
end

function SporesMixin:GetTracerEffectName()
    return kSpikeTracerEffectName
end

function SporesMixin:OnSecondaryAttack(player)

    if player:GetEnergy() >= self:GetSecondaryEnergyCost(player) and not self.primaryAttacking and not GetHasAttackDelay(self,player) then
        self:TriggerEffects("spores_attack")
        if Server then
            CreateSporeCloud(self, player)
        end
        self:GetParent():DeductAbilityEnergy(self:GetSecondaryEnergyCost())
        self.lastSecondaryAttackTime = Shared.GetTime()
        self.secondaryAttacking = true
    else
        self.secondaryAttacking = false
    end
    
end

function SporesMixin:OnSecondaryAttackEnd(player)

    Ability.OnSecondaryAttackEnd(self, player)    
    self.secondaryAttacking = false

end

function SporesMixin:GetHasSecondary(player)
    return player:GetHasOneHive() 
end

function SporesMixin:GetSecondaryEnergyCost(player)
    return kSporeEnergyCost
end

function SporesMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("SporesMixin:OnUpdateAnimationInput")

    local player = self:GetParent()
    if player then
        if self.secondaryAttacking then
            modelMixin:SetAnimationInput("ability", "spores")
        elseif not GetHasAttackDelay(self, player) then
            modelMixin:SetAnimationInput("ability", "bite")
        end
    end
    
end

function SporesMixin:GetIsSecondaryBlocking()
    return false
end