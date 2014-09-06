// NS2 - Classic
// lua\Weapons\Alien\LerkBiteMixin.lua
//

LerkBiteMixin = CreateMixin( LerkBiteMixin )
LerkBiteMixin.type = "LerkBite"

LerkBiteMixin.overrideFunctions =
{
    "GetHasSecondary",
    "GetSecondaryEnergyCost",
    "GetSecondaryTechId",
    "GetSecondaryAttackDelay",
    "GetLastSecondaryAttackTime",
    "PerformSecondaryAttack",
    "OnSecondaryAttack",
    "OnSecondaryAttackEnd",
    "GetSecondaryAbilityUsesFocus",
    "GeMeleeBase"
}

LerkBiteMixin.networkVars =
{
    lastSecondaryAttackTime = "private time"
}

function LerkBiteMixin:__initmixin()
    self.secondaryAttacking = false
    self.lastSecondaryAttackTime = 0
end

function LerkBiteMixin:GetHasSecondary(player)
    return true
end

function LerkBiteMixin:GetSecondaryEnergyCost(player)
    return kLerkBiteEnergyCost
end

function LerkBiteMixin:GetSecondaryAttackDelay()
    return kLerkBiteDelay
end

function LerkBiteMixin:GetLastSecondaryAttackTime()
    return self.lastSecondaryAttackTime
end

function LerkBiteMixin:GetSecondaryTechId()
    return kTechId.LerkBite
end

function LerkBiteMixin:GetDeathIconIndex()
    return kDeathMessageIcon.LerkBite
end

function LerkBiteMixin:GetDamageType()
    return kLerkBiteDamageType
end

function LerkBiteMixin:OnSecondaryAttack(player)

    if player:GetEnergy() >= self:GetSecondaryEnergyCost(player) and not self.primaryAttacking and not self:GetHasSecondaryAttackDelay(player) then
        self.secondaryAttacking = true
    else
        self.secondaryAttacking = false
    end
    
end

function LerkBiteMixin:OnSecondaryAttackEnd(player)
    Ability.OnSecondaryAttackEnd(self, player)    
    self.secondaryAttacking = false
end

function LerkBiteMixin:GetSecondaryAbilityUsesFocus()
    return true
end

function LerkBiteMixin:GeMeleeBase()
    return kLerkBiteMeleeBaseWidth, kLerkBiteMeleeBaseHeight
end

LerkBite = { }
function LerkBite:OnTag(tagName)
end

function LerkBiteMixin:OnTag(tagName)

    PROFILE("LerkBiteMixin:OnTag")

    if tagName == "hit" then
    
        local player = self:GetParent()
        
        if player and self.secondaryAttacking then  
            
            player:DeductAbilityEnergy(self:GetSecondaryEnergyCost())            
            self:TriggerEffects("lerkbite_attack")
            self.lastSecondaryAttackTime = Shared.GetTime()    
            local didHit, target = AttackMeleeCapsule(self, player, kLerkBiteDamage, kLerkBiteRange, nil, true, EntityFilterOneAndIsa(player, "Babbler"))
            
            if didHit and target then
            
                if Client then
                    //self:TriggerFirstPersonHitEffects(player, target)
                end
            
            end
            
            if target and HasMixin(target, "Live") and not target:GetIsAlive() then
                self:TriggerEffects("bite_kill")
            end
            
        end
        
    end
    
end

function LerkBiteMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("LerkBiteMixin:OnUpdateAnimationInput")

    if self.secondaryAttacking then
        modelMixin:SetAnimationInput("ability", "bite")
        modelMixin:SetAnimationInput("activity", "primary")
    end
    
    
end