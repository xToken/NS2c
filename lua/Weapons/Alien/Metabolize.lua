// Natural Selection 2 'Classic' Mod
// lua\Weapons\Alien\Metabolize.lua
// - Dragon

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
        player.timeMetabolize = Shared.GetTime()
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
    local healed = player:AddHealth(kMetabolizeHealthGain, false, (player:GetMaxHealth() - player:GetHealth() ~= 0))
	if Client and healed > 0 then
		local GUIRegenerationFeedback = ClientUI.GetScript("GUIRegenerationFeedback")
		GUIRegenerationFeedback:TriggerRegenEffect()
		local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
		cinematic:SetCinematic(kRegenerationViewCinematic)
	end
    player:AddEnergy(kMetabolizeEnergyGain)    
end

function Metabolize:OnTag(tagName)

    PROFILE("Metabolize:OnTag")
    
    local player = self:GetParent()
    if player then
        if tagName == "metabolize" and not self:GetHasAttackDelay(player) then
            player:DeductAbilityEnergy(self:GetEnergyCost())
            player:TriggerEffects("metabolize")
            PerformMetabolize(self, player)
            self.lastPrimaryAttackTime = Shared.GetTime()
            self.primaryAttacking = false
        end
    end
    
end

function Metabolize:OnUpdateAnimationInput(modelMixin)

    PROFILE("Metabolize:OnUpdateAnimationInput")

    Blink.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("ability", "vortex")
    
    local player = self:GetParent()
    local activityString = (self.primaryAttacking and "primary") or "none"
    if player and player:GetHasMetabolizeAnimationDelay() then
        activityString = "primary"
    end
    
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("Metabolize", Metabolize.kMapName, networkVars)