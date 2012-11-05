//
// lua\Weapons\Alien\UmbraMixin.lua

UmbraMixin = CreateMixin( UmbraMixin )
UmbraMixin.type = "Umbra"

local kRange = 17

// GetHasSecondary and GetSecondaryEnergyCost should completely override any existing
// same named function defined in the object.
UmbraMixin.overrideFunctions =
{
    "GetHasSecondary",
    "GetSecondaryEnergyCost",
    "GetBarrelPoint",
    "OnSecondaryAttack",
    "OnSecondaryAttackEnd",
    "GetTracerEffectName"
}

UmbraMixin.networkVars =
{
    lastSecondaryAttackTime = "time"
}

local function CreateUmbraCloud(self, player)

    local trace = Shared.TraceRay(player:GetEyePos(), player:GetEyePos() + player:GetViewCoords().zAxis * kRange, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterTwo(self, player))
    local destination = trace.endPoint + trace.normal * 2
    
    local umbraCloud = CreateEntity(UmbraCloud.kMapName, player:GetEyePos() + player:GetViewCoords().zAxis, player:GetTeamNumber())
    umbraCloud:SetOwner(player)
    umbraCloud:SetTravelDestination(destination)

end

local function GetHasAttackDelay(self, player)

    local attackDelay = ConditionalValue( player:GetIsPrimaled(), (kUmbraAttackDelay / kPrimalScreamROFIncrease), kUmbraAttackDelay)
    return self.lastSecondaryAttackTime + attackDelay > Shared.GetTime()
    
end

function UmbraMixin:GetTracerEffectName()
    return kSpikeTracerEffectName
end

function UmbraMixin:OnSecondaryAttack(player)

    if player:GetEnergy() >= self:GetSecondaryEnergyCost(player) and not self.primaryAttacking and not GetHasAttackDelay(self,player) then
        self:TriggerEffects("umbra_attack")
        self:TriggerEffects("spikes_attack")
        if Server then
            CreateUmbraCloud(self, player)
            self:GetParent():DeductAbilityEnergy(self:GetSecondaryEnergyCost())
        end
        self.lastSecondaryAttackTime = Shared.GetTime()
        self.secondaryAttacking = true
    else
        self.secondaryAttacking = false
    end
    
end

function UmbraMixin:OnSecondaryAttackEnd(player)

    Ability.OnSecondaryAttackEnd(self, player)    
    self.secondaryAttacking = false

end

function UmbraMixin:GetHasSecondary(player)
    return player.twoHives 
end

function UmbraMixin:GetSecondaryEnergyCost(player)
    return kUmbraEnergyCost
end

function UmbraMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("UmbraMixin:OnUpdateAnimationInput")
    
    local player = self:GetParent()
    if player then
        if self.secondaryAttacking then
            modelMixin:SetAnimationInput("ability", "umbra")
        elseif not GetHasAttackDelay(self, player) then
            modelMixin:SetAnimationInput("ability", "bite")
        end
    end
    
end

function UmbraMixin:GetIsSecondaryBlocking()
    return false
end

function UmbraMixin:OnClientSecondaryAttacking()
    self:TriggerEffects("spikes_attack")
end