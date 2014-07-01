//
// lua\Weapons\Alien\Smash.lua

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/StompMixin.lua")

class 'Smash' (Ability)

Smash.kMapName = "Smash"

local kAnimationGraph = PrecacheAsset("models/alien/onos/onos_view.animation_graph")

local networkVars =
{
    lastPrimaryAttackTime = "private time"
}

AddMixinNetworkVars(StompMixin, networkVars)

function Smash:OnCreate()

    Ability.OnCreate(self)
    
    InitMixin(self, StompMixin)
    self.lastPrimaryAttackTime = 0
    
end

function Smash:GetDamageType()
    return kSmashDamageType
end

function Smash:GetDeathIconIndex()
    return kDeathMessageIcon.Gore
end

function Smash:GetAnimationGraphName()
    return kAnimationGraph
end

function Smash:GetEnergyCost(player)
    return kSmashEnergyCost
end

function Smash:GetHUDSlot()
    return 2
end

function Smash:GetRange()
    return kSmashRange
end

function Smash:GetMeleeBase()
    return kSmashMeleeBaseWidth, kSmashMeleeBaseHeight
end

function Smash:OnHolster(player)
    Ability.OnHolster(self, player)
    self.primaryAttacking = false
end

function Smash:OnTag(tagName)

    PROFILE("Smash:OnTag")

    if tagName == "hit" then
    
        local player = self:GetParent()
        if player then
        
            self.lastPrimaryAttackTime = Shared.GetTime()
            //local didHit, impactPoint, target = self:Attack(player)
            local didHit, target, endPoint = AttackMeleeCapsule(self, player, kSmashDamage, self:GetRange(), nil, false, EntityFilterOneAndIsa(player, "Babbler"))
            self.lastPrimaryAttackTime = Shared.GetTime()
            self:TriggerEffects("smash_attack")
            player:DeductAbilityEnergy(self:GetEnergyCost())
            if didHit then
				local effectCoords = player:GetViewCoords()
				effectCoords.origin = endPoint
				self:TriggerEffects("smash_attack_hit", {effecthostcoords = effectCoords} )
            end
        end
    end    

end

function Smash:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() and not self:GetHasAttackDelay(player) then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end 

end

function Smash:OnPrimaryAttackEnd(player)
    
    Ability.OnPrimaryAttackEnd(self, player)
    self.primaryAttacking = false
    
end

function Smash:OnUpdateAnimationInput(modelMixin)

    local activityString = "none"    
    if self.primaryAttacking then
        activityString = "smash"          
    end
    modelMixin:SetAnimationInput("ability", "smash") 
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("Smash", Smash.kMapName, networkVars)