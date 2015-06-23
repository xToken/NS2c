// Natural Selection 2 'Classic' Mod
// lua\SpawnProtection.lua
// - Dragon

SpawnProtectionMixin = CreateMixin( SpawnProtectionMixin )
SpawnProtectionMixin.type = "SpawnProtection"

//Marine Spawn Protect SFX
PrecacheAsset("cinematics/vfx_materials/nanoshield.surface_shader")
PrecacheAsset("cinematics/vfx_materials/nanoshield_view.surface_shader")
PrecacheAsset("cinematics/vfx_materials/nanoshield_exoview.surface_shader")

//Alien Spawn Protect SFX
PrecacheAsset("cinematics/vfx_materials/umbra.surface_shader")
PrecacheAsset("cinematics/vfx_materials/umbra_view.surface_shader")
PrecacheAsset("cinematics/vfx_materials/2em_1mask_1norm_scroll_refract_tint.surface_shader")

local kMarineMaterial = PrecacheAsset("cinematics/vfx_materials/nanoshield.material")
local kMarineViewMaterial = PrecacheAsset("cinematics/vfx_materials/nanoshield_view.material")
local kAlienMaterialName = PrecacheAsset("cinematics/vfx_materials/umbra.material")
local kAlienViewMaterialName = PrecacheAsset("cinematics/vfx_materials/umbra_view.material")

// These are functions that override existing same-named functions instead
// of the default case of combining with them.
SpawnProtectionMixin.overrideFunctions =
{
    "ComputeDamageOverride"
}

SpawnProtectionMixin.expectedMixins =
{
    Live = "SpawnProtectionMixin makes only sense if this entity can take damage (has LiveMixin).",
}

SpawnProtectionMixin.optionalCallbacks =
{
}

SpawnProtectionMixin.networkVars =
{
    spawnProtection = "boolean"
}

function SpawnProtectionMixin:__initmixin()

    if Server then
        self.spawnProtection = false
	elseif Client then
		self.clientspawnProtection = false
    end
    
end

function SpawnProtectionMixin:ClearSpawnProtection()
    self.spawnProtection = false
end

function SpawnProtectionMixin:OnDestroy()

    if self:GetHasSpawnProtection() then
        self:ClearSpawnProtection()
    end
    
end

function SpawnProtectionMixin:OnTakeDamage(damage, attacker, doer, point)
end

function SpawnProtectionMixin:ActivateSpawnProtection()
	self.spawnProtection = true
	self:AddTimedCallback(SpawnProtectionMixin.ClearSpawnProtection, kNS2cServerSettings.CombatSpawnProtection)
end

function SpawnProtectionMixin:GetHasSpawnProtection()
    return self.spawnProtection
end

function SpawnProtectionMixin:ComputeDamageOverrideMixin(attacker, damage, damageType, time)

    if self.spawnProtection then
        return damage * kCombatSpawnProtectionDamageScalar, damageType
    end
    
    return damage
    
end

if Client then

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

	local function UpdateMarineEffects(self)

		if not self.clientspawnProtection and self:GetHasSpawnProtection() and self:GetIsAlive() then
		
			local material = Client.CreateRenderMaterial()
            material:SetMaterial(kMarineMaterial)

            local viewMaterial = Client.CreateRenderMaterial()
            viewMaterial:SetMaterial(kMarineViewMaterial)

            self.marineEntities = {}
            self.marineMaterial = material
            self.marineViewMaterial = viewMaterial
            AddEffect(self, material, viewMaterial, self.marineEntities)
			
		elseif self.clientspawnProtection and not self:GetHasSpawnProtection() then
		
			RemoveEffect(self.marineEntities, self.marineMaterial, self.marineViewMaterial)
            Client.DestroyRenderMaterial(self.marineMaterial)
            Client.DestroyRenderMaterial(self.marineViewMaterial)
            self.marineMaterial = nil
            self.marineViewMaterial = nil
            self.marineEntities = nil
			
		end
		
	end
	
	local function UpdateAlienEffects(self)
		
		local model = self:GetRenderModel()
		if model then
		
			if not self.alienMaterial then        
				self.alienMaterial = AddMaterial(model, kAlienMaterialName)  
			end
			
			self.alienMaterial:SetParameter("intensity", self:GetHasSpawnProtection() and 1 or 0)
		
		end
		
		local viewModel = self.GetViewModelEntity and self:GetViewModelEntity() and self:GetViewModelEntity():GetRenderModel()
		if viewModel then
		
			if not self.alienViewMaterial then        
				self.alienViewMaterial = AddMaterial(viewModel, kAlienViewMaterialName)        
			end
			
			self.alienViewMaterial:SetParameter("intensity", self:GetHasSpawnProtection() and 1 or 0)
		
		end
	
	end

	function SpawnProtectionMixin:OnUpdateRender()
	
		if self.clientspawnProtection == self.spawnProtection and not self.spawnProtection then
			return
		end
	
		if self:isa("Marine") then
			UpdateMarineEffects(self)
		elseif self:isa("Alien") then
			UpdateAlienEffects(self)
		end
		
		self.clientspawnProtection = self.spawnProtection

	end
    
end