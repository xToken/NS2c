//    
// lua\RedemptionMixin.lua    
//    
//    Created by:   Dragon

RedemptionMixin = CreateMixin(RedemptionMixin)
RedemptionMixin.type = "Redemption"

function RedemptionMixin:__initmixin()
    self.redemptionallowed = true
end

local function ClearRedemptionCooldown(self)
    self.redemptionallowed = true
end

local function RedemAlienToHive(self)
    if self:GetHealthScalar() <= kRedemptionEHPThreshold then
        self:OnRedemed()
        self:TeleportToHive()
        self.redemptionallowed = false
        self:AddTimedCallback(ClearRedemptionCooldown, kRedemptionCooldown)
    end
    return false
end

function RedemptionMixin:OnTakeDamage(damage, attacker, doer, point, direction, damageType, preventAlert)
    if Server then
        local hasupg, level = GetHasRedemptionUpgrade(self)
        if hasupg and level > 0 and self.redemptionallowed and self:GetHealthScalar() <= kRedemptionEHPThreshold then
            self.redemptionallowed = false
            self:AddTimedCallback(RedemAlienToHive, kRedemptionTimeBase - (level * kRedemptionTimeDecrease))
        end
    end
end

