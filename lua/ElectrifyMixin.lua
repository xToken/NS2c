//
// lua\ElectrifyMixin.lua    
//

ElectrifyMixin = CreateMixin( ElectrifyMixin )
ElectrifyMixin.type = "Electrify"

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/electrified.surface_shader")
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/electrified_view.surface_shader")
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/electrified_1.surface_shader")
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/electrified_view_1.surface_shader")

local kElectrifiedSounds = {"sound/ns2c.fev/ns2c/marine/weapon/elec_hit1", "sound/ns2c.fev/ns2c/marine/weapon/elec_hit2", "sound/ns2c.fev/ns2c/marine/weapon/elec_hit3"}

for k, s in ipairs(kElectrifiedSounds) do PrecacheAsset(s) end

ElectrifyMixin.expectedMixins =
{
    Live = "ElectrifyMixin makes only sense if this entity can take damage (has LiveMixin).",
    Research = "Required for electrify progress / cancellation.",
    Energy = "Required for visual notification for comm."
}    

ElectrifyMixin.networkVars =
{
    isElectrified = "boolean",
	lastDamagetick = "time"
}

function ElectrifyMixin:__initmixin()
    self.isElectrified = false
    self.lastDamagetick = 0    
    self.lastElectrifiedTime = 0
    self.lastEnergyRegen = 0
    if Client then
        self.lasteffectupdate = 0
    end
end

local function ClearElectrify(self)

    self.isElectrified = false
    self.lastDamagetick = 0    
    self.lastElectrifiedTime = 0
    self.lastEnergyRegen = 0
    if Client then
        self:_RemoveEffect()
    end
    
end

function ElectrifyMixin:OnDestroy() 
    if self:GetIsElectrified() then
        ClearElectrify(self)
    end   
end

function ElectrifyMixin:GetIsElectrified()
	return self.isElectrified
end

function ElectrifyMixin:GetCanRegainEnergy()
	return self.lastDamagetick + kElectrifyCooldownTime < Shared.GetTime()
end

function ElectrifyMixin:OnResearchComplete(researchId)

    if researchId == kTechId.Electrify then
		self.isElectrified = true
		if Server then
		    self:AddTimedCallback(ElectrifyMixin.Update, kElectrifyDamageTime)
		end
	end
	
end

local function UpdateClientElectrifyEffects(self)

    assert(Client)
    
    if self:GetIsElectrified() and self:GetIsAlive() then
        if self:GetEnergy() > kElectrifyEnergyCost then
            if not self.effecton then
                self:_RemoveEffect()
            end
            self:_CreateEffectOn()
            self.effecton = true
        else
            if self.effecton then
                self:_RemoveEffect()
            end
            self:_CreateEffectOff()
            self.effecton = false
        end
    else
        self:_RemoveEffect() 
    end
    
end

local function SharedUpdate(self, deltaTime)
    if Client and not Shared.GetIsRunningPrediction() then
        UpdateClientElectrifyEffects(self)
        if self.lasteffectupdate + 10 < Shared.GetTime() then
            self.lasteffectupdate = Shared.GetTime()
            self:_RemoveEffect() 
        end
    end
end

function ElectrifyMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end

function ElectrifyMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end

function ElectrifyMixin:Update()

    if self:GetIsAlive() and self:GetIsElectrified() then
        local enemies = GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kElectricalRange + 4)
        local damageRadius = kElectricalRange
        local damagedentities = 0
        for index, entity in ipairs(enemies) do
            local attackPoint = entity:GetOrigin()
            if (attackPoint - self:GetOrigin()):GetLength() < damageRadius and damagedentities < kElectricalMaxTargets and self:GetEnergy() >= kElectrifyEnergyCost then
                if not entity:isa("Commander") and HasMixin(entity, "Live") and entity:GetIsAlive() then
                    local trace = Shared.TraceRay(self:GetOrigin(), attackPoint, CollisionRep.Damage, PhysicsMask.Bullets, filterNonDoors)
                    self:SetEnergy(math.max(self:GetEnergy() - kElectrifyEnergyCost, 0))
                    self:DoDamage(kElectricalDamage , entity, trace.endPoint, (attackPoint - trace.endPoint):GetUnit(), "none" )
                    damagedentities = damagedentities + 1
                end
            end
        end
        if damagedentities > 0 then
            self.lastElectrifiedTime = Shared.GetTime()
            Shared.PlayWorldSound(nil, kElectrifiedSounds[math.random(1,3)], nil, self:GetOrigin())
            self.lastDamagetick = Shared.GetTime()
        end
    end
       
    return self:GetIsAlive()
    
end

if Client then

    /** Adds the material effect to the entity and all child entities (hat have a Model mixin) */
    local function AddEffect(entity, material, viewMaterial, entities)
    
        local numChildren = entity:GetNumChildren()
        
        if HasMixin(entity, "Model") then
            local model = entity._renderModel
            if model ~= nil then
                if model:GetZone() == RenderScene.Zone_ViewModel then
                    model:AddMaterial(viewMaterial)
                else
                    model:AddMaterial(material)
                end
                table.insert(entities, entity:GetId())
            end
        end
        
        for i = 1, entity:GetNumChildren() do
            local child = entity:GetChildAtIndex(i - 1)
            AddEffect(child, material, viewMaterial, entities)
        end
    
    end
    
    local function RemoveEffect(entities, material, viewMaterial)
    
        for i =1, #entities do
            local entity = Shared.GetEntity( entities[i] )
            if entity ~= nil and HasMixin(entity, "Model") then
                local model = entity._renderModel
                if model ~= nil then
                    if model:GetZone() == RenderScene.Zone_ViewModel then
                        model:RemoveMaterial(viewMaterial)
                    else
                        model:RemoveMaterial(material)
                    end
                end                    
            end
        end
        
    end

    function ElectrifyMixin:_CreateEffectOn()
   
        if not self.electrifiedMaterial then
        
            local material = Client.CreateRenderMaterial()
            material:SetMaterial("cinematics/vfx_materials/electrified.material")

            local viewMaterial = Client.CreateRenderMaterial()
            viewMaterial:SetMaterial("cinematics/vfx_materials/electrified_view.material")
            
            self.electrifiedEntities = {}
            self.electrifiedMaterial = material
            self.electrifiedViewMaterial = viewMaterial
            AddEffect(self, material, viewMaterial, self.electrifiedEntities)
            
        end    
        
    end
    
    function ElectrifyMixin:_CreateEffectOff()
   
        if not self.electrifiedMaterial then
        
            local material = Client.CreateRenderMaterial()
            material:SetMaterial("cinematics/vfx_materials/electrified_1.material")

            local viewMaterial = Client.CreateRenderMaterial()
            viewMaterial:SetMaterial("cinematics/vfx_materials/electrified_view_1.material")
            
            self.electrifiedEntities = {}
            self.electrifiedMaterial = material
            self.electrifiedViewMaterial = viewMaterial
            AddEffect(self, material, viewMaterial, self.electrifiedEntities)
            
        end    
        
    end

    function ElectrifyMixin:_RemoveEffect()

        if self.electrifiedMaterial then
            RemoveEffect(self.electrifiedEntities, self.electrifiedMaterial, self.electrifiedViewMaterial)
            Client.DestroyRenderMaterial(self.electrifiedMaterial)
            Client.DestroyRenderMaterial(self.electrifiedViewMaterial)
            self.electrifiedMaterial = nil
            self.electrifiedViewMaterial = nil
            self.electrifiedEntities = nil
        end            

    end
    
end