// NS2 - Classic
// lua\Weapons\Alien\Spikes.lua
//

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/LerkBiteMixin.lua")
Script.Load("lua/Weapons/ClientWeaponEffectsMixin.lua")

Shared.PrecacheSurfaceShader("materials/effects/mesh_effects/view_blood.surface_shader")

local kStructureHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_structure.cinematic")
local kMarineHitEffect = PrecacheAsset("cinematics/alien/lerk/bite_view_marine.cinematic")

class 'Spikes' (Ability)

SpikesMixin = Spikes

Spikes.kMapName = "spikes"

local kAnimationGraph = PrecacheAsset("models/alien/lerk/lerk_view.animation_graph")
local attackEffectMaterial = nil

if Client then
    attackEffectMaterial = Client.CreateRenderMaterial()
    attackEffectMaterial:SetMaterial("materials/effects/mesh_effects/view_blood.material")
end

local networkVars =
{
    lastPrimaryAttackTime = "private time",
    silenced = "boolean"
}

AddMixinNetworkVars(LerkBiteMixin, networkVars)

local function FireSpikes(self)

    local player = self:GetParent()    
    local viewAngles = player:GetViewAngles()
    viewAngles.roll = NetworkRandom() * math.pi * 2
    local shootCoords = viewAngles:GetCoords()
    
    // Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterOneAndIsa(player, "Babbler")
    local range = kSpikesRange
    
    local numSpikes = kSpikesPerShot
    local startPoint = player:GetEyePos()
    
    local viewCoords = player:GetViewCoords()
    
    self.spiked = true
    local hasupg, level = GetHasSilenceUpgrade(player)
    self.silenced = hasupg and level == 3
    
    for spike = 1, numSpikes do

        // Calculate spread for each shot, in case they differ    
        local spreadDirection = CalculateSpread(viewCoords, kSpikesSpread, NetworkRandom) 

        local endPoint = startPoint + spreadDirection * range
        startPoint = player:GetEyePos()
        
        local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
        if not trace.entity then
        
            -- Limit the box trace to the point where the ray hit as an optimization.
            local boxTraceEndPoint = trace.fraction ~= 1 and trace.endPoint or endPoint
            local extents = GetDirectedExtentsForDiameter(spreadDirection, kSpikesSize)
            trace = Shared.TraceBox(extents, startPoint, boxTraceEndPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
            
        end
        
        local distToTarget = (trace.endPoint - startPoint):GetLength()
        
        if trace.fraction < 1 then

            // Have damage increase to reward close combat
            local damageDistScalar = Clamp(1 - (distToTarget / kSpikeMinDamageRange), 0, 1)
            local damage = kSpikeMinDamage + damageDistScalar * (kSpikeMaxDamage - kSpikeMinDamage)
            local direction = (trace.endPoint - startPoint):GetUnit()
            self:DoDamage(damage, trace.entity, trace.endPoint - direction * kHitEffectOffset, direction, trace.surface, false, true, true)
            
        end
        
    end
    
end

function Spikes:OnCreate()

    Ability.OnCreate(self)
	
	InitMixin(self, LerkBiteMixin)
	
    self.primaryAttacking = false
    self.lastPrimaryAttackTime = 0
	self.silenced = false
		
    if Client then
        InitMixin(self, ClientWeaponEffectsMixin)
    end

end

function Spikes:GetAnimationGraphName()
    return kAnimationGraph
end

function Spikes:GetEnergyCost(player)
    return kSpikeEnergyCost
end

function Spikes:GetHUDSlot()
    return 4
end

function Spikes:GetAttackDelay()
    return kSpikesAttackDelay
end

function Spikes:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

function Spikes:GetDeathIconIndex()
    if self.primaryAttacking then
        return kDeathMessageIcon.Spikes
    else
        return kDeathMessageIcon.Bite
    end
end

function Spikes:GetDamageType()
    if self.primaryAttacking then
        return kSpikeDamageType
    else
        return kLerkBiteDamageType
    end
end

function Spikes:OnPrimaryAttack(player)
    if player:GetEnergy() >= self:GetEnergyCost() and not self:GetHasAttackDelay(player) then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
end

function Spikes:GetBarrelPoint()

    local player = self:GetParent()
    if player then
        local viewCoords = player:GetViewCoords()
        local barrelPoint = viewCoords.origin + viewCoords.zAxis * 2 - viewCoords.yAxis * 0.1
        if self.shootLeft then
            barrelPoint = barrelPoint - viewCoords.xAxis * 0.3
        else
            barrelPoint = barrelPoint + viewCoords.xAxis * 0.3
        end
        self.shootLeft = not self.shootLeft
        return barrelPoint
    end

end

function Spikes:GetTracerEffectName()
    return kSpikeTracerEffectName
end

function Spikes:GetTracerResidueEffectName()

    local parent = self:GetParent()
    if parent and parent:GetIsLocalPlayer() then
        return kSpikeTracerFirstPersonResidueEffectName
    else
        return kSpikeTracerResidueEffectName
    end 
    
end

function Spikes:OnPrimaryAttackEnd()
    
    Ability.OnPrimaryAttackEnd(self)
    self.primaryAttacking = false
    
end

function Spikes:OnTag(tagName)

    PROFILE("Spikes:OnTag")
    
    if self.primaryAttacking and tagName == "shoot" then
    
        local player = self:GetParent()
        if player and player:GetEnergy() > self:GetEnergyCost() then
        
            FireSpikes(self)
            self.lastPrimaryAttackTime = Shared.GetTime()
            self:GetParent():DeductAbilityEnergy(self:GetEnergyCost())

        else
            self.primaryAttacking = false
        end
        
    end
    
end

if Client then

    function Spikes:OnClientPrimaryAttacking()

        if not self.silenced then
            self:TriggerEffects("spikes_attack")
        end
        
    end
    
    function Spikes:GetTriggerPrimaryEffects()

        local parent = self:GetParent()
        return parent ~= nil and parent:GetIsAlive()

    end

    function Spikes:TriggerFirstPersonHitEffects(player, target)

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

    function Spikes:CreateBloodEffect(player)
    
        if not Shared.GetIsRunningPrediction() then

            local model = player:GetViewModelEntity():GetRenderModel()

            model:RemoveMaterial(attackEffectMaterial)
            model:AddMaterial(attackEffectMaterial)
            attackEffectMaterial:SetParameter("attackTime", Shared.GetTime())

        end
        
    end

end

function Spikes:OnUpdateAnimationInput(modelMixin)

    PROFILE("Spikes:OnUpdateAnimationInput")
    
    local player = self:GetParent()
    if player and self.primaryAttacking and player:GetEnergy() >= self:GetEnergyCost(player) then
        modelMixin:SetAnimationInput("activity", "secondary")
    elseif not self.primaryAttacking and not self.secondaryAttacking then
        modelMixin:SetAnimationInput("activity", "none")
    end
    if player and not self:GetHasAttackDelay(player) then
        modelMixin:SetAnimationInput("ability", "bite")
    end
    
end

Shared.LinkClassToMap("Spikes", Spikes.kMapName, networkVars)