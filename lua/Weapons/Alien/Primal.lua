// Natural Selection 2 'Classic' Mod
// lua\Weapons\Alien\Primal.lua
// - Dragon

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/LerkBiteMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

Shared.PrecacheSurfaceShader("materials/effects/mesh_effects/view_blood.surface_shader")

local kStructureHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_structure.cinematic")
local kMarineHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_marine.cinematic")

class 'Primal' (Ability)

Primal.kMapName = "primal"

local kAnimationGraph = PrecacheAsset("models/alien/lerk/lerk_view.animation_graph")
local attackEffectMaterial = nil
local kRange = 20

if Client then
    attackEffectMaterial = Client.CreateRenderMaterial()
    attackEffectMaterial:SetMaterial("materials/effects/mesh_effects/view_blood.material")
end

local networkVars =
{
    lastPrimaryAttackTime = "private time"
}

AddMixinNetworkVars(LerkBiteMixin, networkVars)

local function TriggerPrimal(self, lerk)

    local players = GetEntitiesForTeam("Player", lerk:GetTeamNumber())
    for index, player in ipairs(players) do
        if player:GetIsAlive() and ((player:GetOrigin() - lerk:GetOrigin()):GetLength() < kPrimalScreamRange) then
            if player ~= lerk then
                player:AddEnergy(kPrimalScreamEnergyGain)
            end
            if player.PrimalScream then
                player:PrimalScream(kPrimalScreamDuration)
                player:TriggerEffects("primal")
            end            
        end
    end
    
end

function Primal:OnCreate()

    Ability.OnCreate(self)
	
	InitMixin(self, LerkBiteMixin)
	
    self.primaryAttacking = false
    self.lastPrimaryAttackTime = 0
	
    if Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    end

end

function Primal:GetAnimationGraphName()
    return kAnimationGraph
end

function Primal:GetEnergyCost(player)
    return kPrimalScreamEnergyCost
end

function Primal:GetHUDSlot()
    return 3
end

function Primal:GetAttackDelay()
    return kPrimalScreamROF
end

function Primal:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

function Primal:GetDeathIconIndex()

    if self.secondaryAttacking then
        return kDeathMessageIcon.LerkBite
    else
        return kDeathMessageIcon.Umbra
    end
    
end

function Primal:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost()  and not self:GetHasAttackDelay(player) then
        self:TriggerEffects("primal_scream")
        if Server then        
            TriggerPrimal(self, player)
        end
        self:GetParent():DeductAbilityEnergy(self:GetEnergyCost())
        self.lastPrimaryAttackTime = Shared.GetTime()
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end

function Primal:OnPrimaryAttackEnd()
    
    Ability.OnPrimaryAttackEnd(self)
    self.primaryAttacking = false
    
end

if Client then

    function Primal:TriggerFirstPersonHitEffects(player, target)

        if player == Client.GetLocalPlayer() and target then
            
            local cinematicName = kStructureHitEffect
            if target:isa("Marine") then
                self:CreateBloodEffect(player)        
                cinematicName = kMarineHitEffect
            end
        
            local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
            cinematic:SetCinematic(cinematicName)
        
        
        end

    end

    function Primal:CreateBloodEffect(player)
    
        if not Shared.GetIsRunningPrediction() then

            local model = player:GetViewModelEntity():GetRenderModel()

            model:RemoveMaterial(attackEffectMaterial)
            model:AddMaterial(attackEffectMaterial)
            attackEffectMaterial:SetParameter("attackTime", Shared.GetTime())

        end
        
    end

end

function Primal:OnUpdateAnimationInput(modelMixin)

    PROFILE("Primal:OnUpdateAnimationInput")

    local player = self:GetParent()
    if self.primaryAttacking then
        modelMixin:SetAnimationInput("ability", "umbra")
        modelMixin:SetAnimationInput("activity", "primary")
    elseif not self.primaryAttacking and not self.secondaryAttacking then
        modelMixin:SetAnimationInput("activity", "none")
    end
    if player and not self:GetHasAttackDelay(player) then
        modelMixin:SetAnimationInput("ability", "bite")
    end
    
end

Shared.LinkClassToMap("Primal", Primal.kMapName, networkVars)