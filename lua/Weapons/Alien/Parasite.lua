// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\Parasite.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
// 
// Parasite attack to mark enemies on hive sight
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/LeapMixin.lua")

class 'Parasite' (Ability)

Parasite.kMapName = "parasite"

local kRange = 1000

local kAnimationGraph = PrecacheAsset("models/alien/skulk/skulk_view.animation_graph")

Parasite.kActivity = enum { 'None', 'Primary' }

kParasiteHUDSlot = 2

local kParasiteSize = 0.10 // size of parasite blob

local networkVars =
{
    blocked = "boolean",
    activity = "enum Parasite.kActivity"
}

function Parasite:OnCreate()

    Ability.OnCreate(self)
    
    self.activity = Parasite.kActivity.None
    
    InitMixin(self, LeapMixin)

end

function Parasite:GetAnimationGraphName()
    return kAnimationGraph
end

function Parasite:GetDeathIconIndex()
    return kDeathMessageIcon.Parasite
end

function Parasite:GetSecondaryTechId()
    return kTechId.Leap
end

function Parasite:GetEnergyCost(player)
    return kParasiteEnergyCost
end

function Parasite:GetHUDSlot()
    return kParasiteHUDSlot
end

function Parasite:GetPrimaryAttackRequiresPress()
    return true
end

function Parasite:OnProcessMove(input)

    Ability.OnProcessMove(self, input)
    
    // We need to clear this out in OnProcessMove (rather than ProcessMoveOnWeapon)
    // since this will get called after the view model has been updated from
    // Player:OnProcessMove. 
    self.activity = Parasite.kActivity.None

end


function Parasite:PerformPrimaryAttack(player)

    self.activity = Parasite.kActivity.Primary
    self.primaryAttacking = true
    
    local success = false

    if not self.blocked then
    
        self.blocked = true
        
        success = true
        
        self:TriggerEffects("parasite_attack")
        
        // Trace ahead to see if hit enemy player or structure

        local viewCoords = player:GetViewAngles():GetCoords()
        local startPoint = player:GetEyePos()
    
        // double trace; first as a ray to allow us to hit through narrow openings, then as a fat box if the first one misses
        local trace = Shared.TraceRay(startPoint, startPoint + viewCoords.zAxis * kRange, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOneAndIsa(player, "Babbler"))
        if not trace.entity then
            local extents = GetDirectedExtentsForDiameter(viewCoords.zAxis, kParasiteSize)
            trace = Shared.TraceBox(extents, startPoint, startPoint + viewCoords.zAxis * kRange, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOneAndIsa(player, "Babbler"))
        end
        
        if trace.fraction < 1 then
        
            local hitObject = trace.entity
            local direction = GetNormalizedVector(trace.endPoint - startPoint)
            local impactPoint = trace.endPoint - direction * kHitEffectOffset
            
            self:DoDamage(kParasiteDamage, hitObject, impactPoint, direction)
            
        end
        
    end
    
    return success
    
end

function Parasite:OnHolster(player)

    Ability.OnHolster(self, player)
    
    self.blocked = false
    
end

function Parasite:OnTag(tagName)

    PROFILE("Parasite:OnTag")

    if tagName == "attack_end" then
        self.blocked = false
        self.primaryAttacking = false
    end

end

function Parasite:OnUpdateAnimationInput(modelMixin)

    PROFILE("Parasite:OnUpdateAnimationInput")

    modelMixin:SetAnimationInput("ability", "parasite")
    
    local activityString = "none"
    if self.activity == Parasite.kActivity.Primary then
        activityString = "primary"
    end
    modelMixin:SetAnimationInput("activity", activityString)
    
end

Shared.LinkClassToMap("Parasite", Parasite.kMapName, networkVars)