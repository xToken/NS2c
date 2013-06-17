//
// lua\Weapons\Alien\PrimalScreamMixin.lua

PrimalScreamMixin = CreateMixin( PrimalScreamMixin )
PrimalScreamMixin.type = "PrimalScream"

// GetHasSecondary and GetSecondaryEnergyCost should completely override any existing
// same named function defined in the object.
PrimalScreamMixin.overrideFunctions =
{
    "GetHasSecondary",
    "GetSecondaryEnergyCost",
    "OnSecondaryAttack",
    "OnSecondaryAttackEnd",    
}

PrimalScreamMixin.networkVars =
{
    lastSecondaryAttackTime = "time"
}

local function TriggerPrimal(self, lerk)

    local players = GetEntitiesForTeam("Player", lerk:GetTeamNumber())
    for index, player in ipairs(players) do
        if player:GetIsAlive() and ((player:GetOrigin() - lerk:GetOrigin()):GetLength() < kPrimalScreamRange) then
            if player ~= lerk then
                player:AddEnergy(kPrimalScreamEnergyGain)
            end
            if player.SetPrimalScream then
                player:SetPrimalScream(kPrimalScreamDuration)
                //player:TriggerEffects("enzymed")
            end            
        end
    end
    
end

local function GetHasAttackDelay(self, player)
    
    //Primal scream immune to its own ROF increase
    local attackDelay = kPrimalScreamROF
    return self.lastSecondaryAttackTime + attackDelay > Shared.GetTime()
    
end

function PrimalScreamMixin:OnSecondaryAttack(player)

    if player:GetEnergy() >= self:GetSecondaryEnergyCost(player) and not self.primaryAttacking and not GetHasAttackDelay(self, player) then
        self:TriggerEffects("primal_scream")
        if Server then        
            TriggerPrimal(self, player)
            self:GetParent():DeductAbilityEnergy(self:GetSecondaryEnergyCost())
        end
        self.lastSecondaryAttackTime = Shared.GetTime()
        self.secondaryAttacking = true
    else
        self.secondaryAttacking = false
    end
    
end

function PrimalScreamMixin:OnSecondaryAttackEnd(player)
    Ability.OnSecondaryAttackEnd(self, player)    
    self.secondaryAttacking = false
end

function PrimalScreamMixin:GetHasSecondary(player)
    return player:GetHasThreeHives()
end

function PrimalScreamMixin:GetSecondaryEnergyCost(player)
    return kPrimalScreamEnergyCost
end

function PrimalScreamMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("PrimalScreamMixin:OnUpdateAnimationInput")
    
    local player = self:GetParent()
    if player then
        if self.secondaryAttacking then
            modelMixin:SetAnimationInput("ability", "umbra")
        elseif not GetHasAttackDelay(self, player) then
            modelMixin:SetAnimationInput("ability", "bite")
        end
    end
    
end

function PrimalScreamMixin:GetIsSecondaryBlocking()
    return false
end