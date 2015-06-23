// Natural Selection 2 'Classic' Mod
// lua\GhostMixin.lua
// - Dragon

GhostMixin = CreateMixin(GhostMixin)
GhostMixin.type = "Ghost"

GhostMixin.networkVars =
{
    lastghostdodge = "private time"
}

function GhostMixin:__initmixin()
    self.lastghostdodge = 0
    self.dodgeddamage = 0
end

function GhostMixin:ComputeDamageOverrideMixin(attacker, damage, damageType, hitPoint) 
    local hasupg, level = GetHasGhostUpgrade(self)
    if hasupg and level > 0 then
		//Dodge any attacks applied on this same frame, up to the threshold.
		if self.lastghostdodge == Shared.GetTime() and self.dodgeddamage < (kGhostDodgeMaxHPPercent * self:GetMaxHealth())  then
		    self.dodgeddamage = self.dodgeddamage + damage
			damage = 0
		elseif self.lastghostdodge + (kGhostDodgeCooldownBase - (kGhostDodgeCooldownPerLevel * level)) < Shared.GetTime() then
		    self.dodgeddamage = self.dodgeddamage + damage
			damage = 0
			self:TriggerEffects("ghost_dodge")
			self.lastghostdodge = Shared.GetTime()
		else
		    self.dodgeddamage = 0
		end
    end
    return damage
end