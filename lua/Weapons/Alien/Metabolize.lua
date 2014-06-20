//
// lua\Weapons\Alien\Metabolize.lua

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Blink.lua")

class 'Metabolize' (Blink)

Metabolize.kMapName = "metabolize"

local networkVars =
{
    lastPrimaryAttackTime = "private time"
}

local kAnimationGraph = PrecacheAsset("models/alien/fade/fade_view.animation_graph")

function Metabolize:OnCreate()

    Blink.OnCreate(self)
    
    self.primaryAttacking = false
    self.lastPrimaryAttackTime = 0
    
end

function Metabolize:GetAnimationGraphName()
    return kAnimationGraph
end

function Metabolize:GetEnergyCost(player)
    return kMetabolizeEnergyCost
end

function Metabolize:GetHUDSlot()
    return 2
end

function Metabolize:GetDeathIconIndex()
    return kDeathMessageIcon.Metabolize
end

function Metabolize:GetBlinkAllowed()
    return true
end

function Metabolize:GetAttackDelay()
    return kMetabolizeDelay
end

function Metabolize:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

function Metabolize:GetSecondaryTechId()
    return kTechId.Blink
end

function Metabolize:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() and not self:GetHasAttackDelay(player) then
        self.primaryAttacking = true    
    else
        self:OnPrimaryAttackEnd()
    end
    
end

function Metabolize:OnPrimaryAttackEnd()
    
    Blink.OnPrimaryAttackEnd(self)
    self.primaryAttacking = false
    
end

function Metabolize:OnHolster(player)

    Blink.OnHolster(self, player)
    self.primaryAttacking = false
    
end

local function PerformMetabolize(self, player)
    player:AddHealth(kMetabolizeHealthGain, false, (player:GetMaxHealth() - player:GetHealth() ~= 0))
    player:AddEnergy(kMetabolizeEnergyGain)    
end

function Metabolize:OnTag(tagName)

    PROFILE("Metabolize:OnTag")

    if tagName == "hit" and self.primaryAttacking then
    
        self.lastPrimaryAttackTime = Shared.GetTime()
        local player = self:GetParent()
        if player then
            player:DeductAbilityEnergy(self:GetEnergyCost())
            player:TriggerEffects("metabolize")
            PerformMetabolize(self, player)
        end
        self.primaryAttacking = false
    end
    
end

function Metabolize:OnUpdateAnimationInput(modelMixin)

    PROFILE("Metabolize:OnUpdateAnimationInput")

    Blink.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("ability", "vortex")
    
    local activityString = (self.primaryAttacking and "primary") or "none"
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("Metabolize", Metabolize.kMapName, networkVars)