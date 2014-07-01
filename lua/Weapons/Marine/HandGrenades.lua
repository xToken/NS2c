// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Marine\GrenadeThrower.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Base class for hand grenades. Override GetViewModelName and GetGrenadeMapName in implementation.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Marine/HandGrenade.lua")

local kDefaultVariantData = kMarineVariantData[ kDefaultMarineVariant ]
function GenerateMarineGrenadeViewModelPaths(grenadeType)

    local viewModels = { male = { }, female = { } }
    
    local function MakePath(prefix, suffix)
        return "models/marine/grenades/" .. prefix .. grenadeType .. "_view" .. suffix .. ".model"
    end
    
    for variant, data in pairs(kMarineVariantData) do
        viewModels.male[variant] = PrecacheAssetSafe(MakePath("", data.viewModelFilePart), MakePath("", kDefaultVariantData.viewModelFilePart))
    end
    
    for variant, data in pairs(kMarineVariantData) do
        viewModels.female[variant] = PrecacheAssetSafe(MakePath("female_", data.viewModelFilePart), MakePath("female_", kDefaultVariantData.viewModelFilePart))
    end
    
    return viewModels
    
end

class 'HandGrenades' (Weapon)

HandGrenades.kMapName = "handgrenades"

local kModelName = PrecacheAsset("models/marine/grenades/gr_cluster.model")
local kViewModels = GenerateMarineGrenadeViewModelPaths("gr_cluster")
local kAnimationGraph = PrecacheAsset("models/marine/grenades/grenade_view.animation_graph")

local kGrenadeVelocity = 18

local function ThrowGrenade(self, player)

    if Server or (Client and Client.GetIsControllingPlayer()) then

        local viewCoords = player:GetViewCoords()
        local eyePos = player:GetEyePos()

        local startPointTrace = Shared.TraceCapsule(eyePos, eyePos + viewCoords.zAxis, 0.2, 0, CollisionRep.Move, PhysicsMask.PredictedProjectileGroup, EntityFilterTwo(self, player))
        local startPoint = startPointTrace.endPoint

        local direction = viewCoords.zAxis
        
        if startPointTrace.fraction ~= 1 then
            direction = GetNormalizedVector(direction:GetProjection(startPointTrace.normal))
        end
        
        local grenade = player:CreatePredictedProjectile("HandGrenade", startPoint, direction * kGrenadeVelocity, 0.7, 0.45)
        
    end
    
end

local networkVars =
{
    grenadesLeft = "private integer (0 to ".. kNumHandGrenades ..")",
}

function HandGrenades:OnCreate()

    Weapon.OnCreate(self)
    
    self.grenadesLeft = kNumHandGrenades
    
    self:SetModel(self:GetThirdPersonModelName())
    
end

function HandGrenades:OnDraw(player, previousWeaponMapName)

    Weapon.OnDraw(self, player, previousWeaponMapName)
    
    // Attach weapon to parent's hand.
    self:SetAttachPoint(Weapon.kHumanAttachPoint)
    
end

function HandGrenades:OnPrimaryAttack(player)

    if self.grenadesLeft > 0 then
    
        if not self.primaryAttacking then
            self:TriggerEffects("grenade_pull_pin")
        end
    
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end    

end

function HandGrenades:GetThirdPersonModelName()
    return kModelName
end

function HandGrenades:GetViewModelName(sex, variant)
    return kViewModels[sex][variant]
end

function HandGrenades:GetAnimationGraphName()
    return kAnimationGraph
end

function HandGrenades:OnPrimaryAttackEnd(player)
    self.primaryAttacking = false
end

function HandGrenades:OnTag(tagName)

    local player = self:GetParent()
    
    if tagName == "throw" then
    
        if player then
        
            ThrowGrenade(self, player)
            self.grenadesLeft = math.max(0, self.grenadesLeft - 1)
            self:SetIsVisible(false)
            self:TriggerEffects("grenade_throw")
            
        end
        
    elseif tagName == "attack_end" then
    
        if self.grenadesLeft == 0 then        
            self.readyToDestroy = true    
        else
            self:SetIsVisible(true)
        end
        
    end
    
end

function HandGrenades:GetHUDSlot()
    return 4
end

function HandGrenades:GetWeight()
    return kHandGrenadesWeight
end

function HandGrenades:GetNadesLeft()
    return self.grenadesLeft
end

function HandGrenades:OnUpdateAnimationInput(modelMixin)

    modelMixin:SetAnimationInput("activity", self.primaryAttacking and "primary" or "none")
    modelMixin:SetAnimationInput("grenadesLeft", self.grenadesLeft)
    
end

function HandGrenades:OverrideWeaponName()
    return "grenades"
end

if Server then

    function HandGrenades:OnProcessMove(input)

        Weapon.OnProcessMove(self, input)
        
        local player = self:GetParent()
        if player then

            local activeWeapon = player:GetActiveWeapon()
            local allowDestruction = self.readyToDestroy or (activeWeapon ~= self and self.grenadesLeft == 0)
        
            if allowDestruction then

                if activeWeapon == self then
                
                    self:OnHolster(player)
                    player:SwitchWeapon(1)
                    
                end
                    
                player:RemoveWeapon(self)
                DestroyEntity(self)
            
            end

        end

    end

end

Shared.LinkClassToMap("HandGrenades", HandGrenades.kMapName, networkVars)