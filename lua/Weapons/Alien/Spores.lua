// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\Weapons\Alien\Spores.lua
// - Dragon

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/SporeCloud.lua")
Script.Load("lua/Weapons/Alien/LerkBiteMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

Shared.PrecacheSurfaceShader("materials/effects/mesh_effects/view_blood.surface_shader")

local kStructureHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_structure.cinematic")
local kMarineHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_marine.cinematic")

class 'Spores' (Ability)

Spores.kMapName = "spores"

local kAnimationGraph = PrecacheAsset("models/alien/lerk/lerk_view.animation_graph")
local kRange = 20

local networkVars =
{
    lastPrimaryAttackTime = "private time"
}

AddMixinNetworkVars(LerkBiteMixin, networkVars)

local function CreateSporeCloud(self, player)

    local trace = Shared.TraceRay(player:GetEyePos(), player:GetEyePos() + player:GetViewCoords().zAxis * kRange, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterTwo(self, player))
    local destination = trace.endPoint + trace.normal * 2
    
    local sporeCloud = CreateEntity(SporeCloud.kMapName, player:GetEyePos() + player:GetViewCoords().zAxis, player:GetTeamNumber())
    sporeCloud:SetOwner(player)
    sporeCloud:SetTravelDestination(destination)

end

function Spores:OnCreate()

    Ability.OnCreate(self)
	
	InitMixin(self, LerkBiteMixin)
	
    self.primaryAttacking = false
    self.lastPrimaryAttackTime = 0
	
    if Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    end

end

function Spores:GetAnimationGraphName()
    return kAnimationGraph
end

function Spores:GetEnergyCost(player)
    return kSporeEnergyCost
end

function Spores:GetHUDSlot()
    return 1
end

function Spores:GetAttackDelay()
    return kSporeAttackDelay
end

function Spores:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

function Spores:GetDeathIconIndex()

    if self.secondaryAttacking then
        return kDeathMessageIcon.LerkBite
    else
        return kDeathMessageIcon.SporeCloud
    end
    
end

function Spores:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost()  and not self:GetHasAttackDelay(player) and player:GetHasOneHive() then
        self:TriggerEffects("spores_attack")
        if Server then
            CreateSporeCloud(self, player)
        end
        self:GetParent():DeductAbilityEnergy(self:GetEnergyCost())
        self.lastPrimaryAttackTime = Shared.GetTime()
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end

function Spores:OnPrimaryAttackEnd()
    
    Ability.OnPrimaryAttackEnd(self)
    self.primaryAttacking = false
    
end

function Spores:OnUpdateAnimationInput(modelMixin)

    PROFILE("Spores:OnUpdateAnimationInput")

    local player = self:GetParent()
    if self.primaryAttacking then
        modelMixin:SetAnimationInput("ability", "spores")
        modelMixin:SetAnimationInput("activity", "primary")
    elseif not self.primaryAttacking and not self.secondaryAttacking then
        modelMixin:SetAnimationInput("activity", "none")
    end
    if player and not self:GetHasAttackDelay(player) then
        modelMixin:SetAnimationInput("ability", "bite")
    end
    
end

Shared.LinkClassToMap("Spores", Spores.kMapName, networkVars)