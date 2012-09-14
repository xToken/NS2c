// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ParasiteMixin.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

ParasiteMixin = CreateMixin( ParasiteMixin )
ParasiteMixin.type = "ParasiteAble"

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/parasited.surface_shader")

ParasiteMixin.expectedMixins =
{
    Live = "ParasiteMixin makes only sense if this entity can take damage (has LiveMixin).",
}

ParasiteMixin.optionalCallbacks =
{
    GetCanBeParasitedOverride = "Return true or false if the entity has some specific conditions under which parasite is allowed."
}

ParasiteMixin.networkVars =
{
    parasited = "boolean"
}

function ParasiteMixin:__initmixin()

    if Server then
    
        self.timeParasited = 0
        self.parasited = false
        
    end
    
end

function ParasiteMixin:OnTakeDamage(damage, attacker, doer, point, damageType)

    if doer and doer:isa("Parasite") and GetAreEnemies(self, attacker) then
        self:SetParasited(attacker)
    end

end

function ParasiteMixin:SetParasited(fromPlayer, duration, visible)

    if Server then

        if not self.GetCanBeParasitedOverride or self:GetCanBeParasitedOverride() then
        
            if not self.parasited and self.OnParasited then
            
                self:OnParasited()
                
                if fromPlayer and HasMixin(fromPlayer, "Scoring") and visible then
                    fromPlayer:AddScore(1)
                end
                
            end
        
            self.timeParasited = Shared.GetTime()
            self.parasiteduration = duration
            self.parasited = true
            if visible == nil then
                self.visible = true
            else
                self.visible = visible
            end

        end
    
    end

end

function ParasiteMixin:OnDestroy()

    if Client then
        self:_RemoveParasiteEffect()
    end
    
end

function ParasiteMixin:GetIsParasited()
    return self.parasited
end

function ParasiteMixin:RemoveParasite()
    self.parasited = false
end

local function SharedUpdate(self)

    if Server then
    
        if not self:GetIsParasited() then
            return
        end
        
        // See if parsited time is over
        if self.parasiteduration ~= nil and self.timeParasited + self.parasiteduration < Shared.GetTime() then
            self.parasited = false
        end
       
    elseif not Shared.GetIsRunningPrediction() then
    
        if self:GetIsParasited() and self:GetIsAlive() and self.visible then
            self:_CreateParasiteEffect()
        else
            self:_RemoveParasiteEffect() 
        end
        
    end
    
end

function ParasiteMixin:OnUpdate(deltaTime)   
    SharedUpdate(self)
end

function ParasiteMixin:OnProcessMove(input)   
    SharedUpdate(self)
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

    function ParasiteMixin:_CreateParasiteEffect()
   
        if not self.parasiteMaterial then
        
            local material = Client.CreateRenderMaterial()
            material:SetMaterial("cinematics/vfx_materials/parasited.material")

            local viewMaterial = Client.CreateRenderMaterial()
            viewMaterial:SetMaterial("cinematics/vfx_materials/parasited.material")
            
            self.parasiteEntities = {}
            self.parasiteMaterial = material
            self.parasiteViewMaterial = viewMaterial
            AddEffect(self, material, viewMaterial, self.parasiteEntities)
            
        end    
        
    end

    function ParasiteMixin:_RemoveParasiteEffect()

        if self.parasiteMaterial then
            RemoveEffect(self.parasiteEntities, self.parasiteMaterial, self.parasiteViewMaterial)
            Client.DestroyRenderMaterial(self.parasiteMaterial)
            Client.DestroyRenderMaterial(self.parasiteViewMaterial)
            self.parasiteMaterial = nil
            self.parasiteViewMaterial = nil
            self.parasiteEntities = nil
        end            

    end
    
end