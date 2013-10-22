// NS2 - Classic
// lua\Weapons\Alien\Umbra.lua
//

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/UmbraCloud.lua")
Script.Load("lua/Weapons/Alien/LerkBiteMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

Shared.PrecacheSurfaceShader("materials/effects/mesh_effects/view_blood.surface_shader")

local kStructureHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_structure.cinematic")
local kMarineHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_marine.cinematic")

class 'Umbra' (Ability)

Umbra.kMapName = "umbra"

local kAnimationGraph = PrecacheAsset("models/alien/lerk/lerk_view.animation_graph")
local attackEffectMaterial = nil
local kRange = 20

if Client then
    attackEffectMaterial = Client.CreateRenderMaterial()
    attackEffectMaterial:SetMaterial("materials/effects/mesh_effects/view_blood.material")
end

local networkVars =
{
    lastPrimaryAttackTime = "time"
}

AddMixinNetworkVars(LerkBiteMixin, networkVars)

local function CreateUmbraCloud(self, player)

    local trace = Shared.TraceRay(player:GetEyePos(), player:GetEyePos() + player:GetViewCoords().zAxis * kRange, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterTwo(self, player))
    local destination = trace.endPoint + trace.normal * 2
    
    local umbraCloud = CreateEntity(UmbraCloud.kMapName, player:GetEyePos() + player:GetViewCoords().zAxis, player:GetTeamNumber())
    umbraCloud:SetOwner(player)
    umbraCloud:SetTravelDestination(destination)

end

function Umbra:OnCreate()

    Ability.OnCreate(self)
	
	InitMixin(self, LerkBiteMixin)
	
    self.primaryAttacking = false
    self.lastPrimaryAttackTime = 0
	
    if Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    end

end

function Umbra:GetAnimationGraphName()
    return kAnimationGraph
end

function Umbra:GetEnergyCost(player)
    return kUmbraEnergyCost
end

function Umbra:GetHUDSlot()
    return 2
end

function Umbra:GetAttackDelay()
    return kUmbraAttackDelay
end

function Umbra:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

function Umbra:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost()  and not self:GetHasAttackDelay(player) then
        self:TriggerEffects("umbra_attack")
        if Server then
            CreateUmbraCloud(self, player)
        end
        self:GetParent():DeductAbilityEnergy(self:GetEnergyCost())
        self.lastPrimaryAttackTime = Shared.GetTime()
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end

function Umbra:OnPrimaryAttackEnd()
    
    Ability.OnPrimaryAttackEnd(self)
    self.primaryAttacking = false
    
end

if Client then

    function Umbra:TriggerFirstPersonHitEffects(player, target)

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

    function Umbra:CreateBloodEffect(player)
    
        if not Shared.GetIsRunningPrediction() then

            local model = player:GetViewModelEntity():GetRenderModel()

            model:RemoveMaterial(attackEffectMaterial)
            model:AddMaterial(attackEffectMaterial)
            attackEffectMaterial:SetParameter("attackTime", Shared.GetTime())

        end
        
    end

end

function Umbra:OnUpdateAnimationInput(modelMixin)

    PROFILE("Umbra:OnUpdateAnimationInput")

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

Shared.LinkClassToMap("Umbra", Umbra.kMapName, networkVars)