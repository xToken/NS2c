-- ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
--
-- lua\BulletsMixin.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

--NS2c
--Changed umbra to damage reduction

BulletsMixin = CreateMixin( BulletsMixin )
BulletsMixin.type = "Bullets"

BulletsMixin.expectedMixins =
{
    Damage = "Needed for dealing Damage."
}

BulletsMixin.networkVars = { }

function BulletsMixin:__initmixin()
end

-- check for umbra and play local hit effects (bullets only)
function BulletsMixin:ApplyBulletGameplayEffects(player, target, endPoint, direction, damage, surface, showTracer)

    local blockedByUmbra = GetBlockedByUmbra(target)
    
    if blockedByUmbra then
        surface = "umbra"
        damage = damage * math.max((1 - kUmbraDamageReduction), 0)
    end

    -- deals damage or plays surface hit effects
    self:DoDamage(damage, target, endPoint, direction, surface, false, showTracer)
    
end