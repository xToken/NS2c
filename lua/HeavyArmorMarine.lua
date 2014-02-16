//
// lua\HeavyArmorMarine.lua

Script.Load("lua/Marine.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/MarineActionFinderMixin.lua")
Script.Load("lua/OrderSelfMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/ScoringMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/SelectableMixin.lua")

if Client then
    Script.Load("lua/TeamMessageMixin.lua")
end

class 'HeavyArmorMarine' (Marine)

HeavyArmorMarine.kMapName = "heavyarmormarine"

Shared.PrecacheSurfaceShader("models/marine/marine.surface_shader")
Shared.PrecacheSurfaceShader("models/marine/marine_noemissive.surface_shader")
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/heavyarmor.surface_shader")

//HeavyArmorMarine.kModelName = PrecacheAsset("models/marine/heavyarmor/heavyarmor.model")
//HeavyArmorMarine.kAnimationGraph = PrecacheAsset("models/marine/male/male.animation_graph")

local kMass = 200

function HeavyArmorMarine:OnDestroy()
    
    if Client then
        self:_RemoveEffect()
    end
    
    Marine.OnDestroy(self)
end

/*function HeavyArmorMarine:GetIgnoreVariantModels()
    return true
end*/

/*function HeavyArmorMarine:GetVariantModel()
    return HeavyArmorMarine.kModelName
end*/

function HeavyArmorMarine:GetArmorAmount(armorLevels)

    if not armorLevels then
        armorLevels = self:GetArmorLevel()
    end
    
    return kHeavyArmorArmor + armorLevels * kHeavyArmorPerUpgradeLevel
    
end

function HeavyArmorMarine:GetInventorySpeedScalar()
    return 1 - self:GetWeaponsWeight() - kHeavyArmorWeight
end

function HeavyArmorMarine:GetReceivesVaporousDamage()
    return false
end

function HeavyArmorMarine:GetMinFootstepTime()
    //BANGBANGBANGBANGBANGBANG is really annoying btw.
    return 0.4
end

function HeavyArmorMarine:GetMass()
    return kMass
end

if Client then

    function HeavyArmorMarine:OnUpdateRender()
        Player.OnUpdateRender(self)
        
        if not Shared.GetIsRunningPrediction() then
            self:_UpdateEffect()
        end
    end

    /** Adds the material effect to the entity and all child entities (hat have a Model mixin) */
    local function AddEffect(entity, material, viewMaterial, entities)
    
        local numChildren = entity:GetNumChildren()
        
        if HasMixin(entity, "Model") and not table.contains(entities, entity:GetId()) then
            local model = entity._renderModel
            if model ~= nil then
                if model:GetZone() == RenderScene.Zone_ViewModel then
                    //model:AddMaterial(viewMaterial)
                else
                    model:AddMaterial(material)
                end
                table.insert(entities, entity:GetId())
            end
        end
        
        for i = 1, entity:GetNumChildren() do
            local child = entity:GetChildAtIndex(i - 1)
            //AddEffect(child, material, viewMaterial, entities)
        end
    
    end
    
    local function RemoveEffect(entities, material, viewMaterial)
    
        for i =1, #entities do
            local entity = Shared.GetEntity( entities[i] )
            if entity ~= nil and HasMixin(entity, "Model") then
                local model = entity._renderModel
                if model ~= nil then
                    if model:GetZone() == RenderScene.Zone_ViewModel then
                        //model:RemoveMaterial(viewMaterial)
                    else
                        model:RemoveMaterial(material)
                    end
                end                    
            end
        end
        
    end

    function HeavyArmorMarine:_CreateEffect()
   
        if not self.heavyarmormaterial then
        
            local material = Client.CreateRenderMaterial()
            material:SetMaterial("cinematics/vfx_materials/heavyarmor.material")
            
            local viewmaterial = Client.CreateRenderMaterial()
            viewmaterial:SetMaterial("cinematics/vfx_materials/heavyarmor.material")
            
            self.heavyarmorentities = {}
            self.heavyarmormaterial = material
            self.heavyarmorviewmaterial = viewmaterial
            AddEffect(self, material, viewmaterial, self.heavyarmorentities)
            
        end    
        
    end
    
    function HeavyArmorMarine:_UpdateEffect()
   
        if self.heavyarmormaterial then
            AddEffect(self, self.heavyarmormaterial, self.heavyarmorviewmaterial, self.heavyarmorentities)
        else
           self:_CreateEffect()
        end    
        
    end

    function HeavyArmorMarine:_RemoveEffect()

        if self.heavyarmormaterial then
            RemoveEffect(self.heavyarmorentities, self.heavyarmormaterial)
            Client.DestroyRenderMaterial(self.heavyarmormaterial)
            self.heavyarmormaterial = nil
            self.heavyarmorviewmaterial = nil
            self.heavyarmorentities = nil
        end            

    end
    
end

Shared.LinkClassToMap("HeavyArmorMarine", HeavyArmorMarine.kMapName, { })