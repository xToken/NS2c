//
// lua\Weapons\Alien\Metabolize.lua

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/Blink.lua")

class 'Metabolize' (Blink)

Metabolize.kMapName = "metabolize"

local kDefaultAttackSpeed = 1.4

local networkVars =
{
}

local kAnimationGraph = PrecacheAsset("models/alien/fade/fade_view.animation_graph")

local function GetHasAttackDelay(self, player)

    local attackDelay = ConditionalValue( player:GetIsPrimaled(), (kMetabolizeDelay / kPrimalScreamROFIncrease), kMetabolizeDelay)
    return self.lastPrimaryAttackTime + attackDelay > Shared.GetTime()
    
end

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
    return kDeathMessageIcon.SwipeBlink
end

function Metabolize:GetIconOffsetY(secondary)
    return kAbilityOffset.SwipeBlink
end

function Metabolize:GetBlinkAllowed()
    return true
end

function Metabolize:OnPrimaryAttack(player)

    if not self:GetIsBlinking() and player:GetEnergy() >= self:GetEnergyCost() and not GetHasAttackDelay(self, player) then
        self.primaryAttacking = true    
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

local function PerformMetabolize(self)

    local player = self:GetParent()
    if player then
        player:AddHealth(kMetabolizeHealthGain)
        player:AddEnergy(kMetabolizeEnergyGain)
    end
    
end

function Metabolize:OnTag(tagName)

    PROFILE("Metabolize:OnTag")

    if self.primaryAttacking then
    
        if tagName == "start" then
        
            self.lastPrimaryAttackTime = Shared.GetTime()
            local player = self:GetParent()
            if player then
                player:DeductAbilityEnergy(self:GetEnergyCost())
            end
            PerformMetabolize(self)
            self:TriggerEffects("stab_attack")
            
        elseif tagName == "attack_end" then
            self.primaryAttacking = false
        end
        
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