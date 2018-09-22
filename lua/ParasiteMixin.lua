-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\ParasiteMixin.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Changes to allow parasite of structures and visibility changes

ParasiteMixin = CreateMixin( ParasiteMixin )
ParasiteMixin.type = "ParasiteAble"

PrecacheAsset("cinematics/vfx_materials/parasited.surface_shader")
local kParasitedMaterial = PrecacheAsset("cinematics/vfx_materials/parasited.material")

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
    
    PROFILE("ParasiteMixin:__initmixin")
    
    self.timeParasited = 0
    self.parasiteDuration = 0
    self.parasited = false
    
end

function ParasiteMixin:OnTakeDamage(_, attacker, doer, _, _)

    if doer and doer:isa("Parasite") and GetAreEnemies(self, attacker) then
        self:SetParasited(attacker)
    end

end

function ParasiteMixin:SetParasited(fromPlayer)

    if Server then

        if not self.GetCanBeParasitedOverride or self:GetCanBeParasitedOverride() then
        
            if not self.parasited and self.OnParasited then
            
                self:OnParasited()
                
                if fromPlayer and HasMixin(fromPlayer, "Scoring") and self:isa("Player") then
                    fromPlayer:AddScore(kParasitePlayerPointValue)
                end
                
            end
            
            if HasMixin(self, "Detectable") and not self:GetIsDetected() then
                self:SetDetected(true)
            end
        
            self.timeParasited = Shared.GetTime()
            self.parasited = true

        end
    
    end

end

function ParasiteMixin:OnDestroy()

    if Client then
        self:_RemoveParasiteEffect()
    end
    
end

if Server then

    function ParasiteMixin:OnKill()
        self:RemoveParasite()
    end

end

function ParasiteMixin:GetIsParasited()
    return self.parasited
end

function ParasiteMixin:RemoveParasite()
    self.parasited = false
end

if Client then

    function ParasiteMixin:OnProcessMove(input)
     
        if Client and not Shared.GetIsRunningPrediction() then
        
            if self:GetIsParasited() and self:GetIsAlive() and self:isa("Player") then
                self:_CreateParasiteEffect()
            else
                self:_RemoveParasiteEffect() 
            end
            
        end
        
    end

    -- Adds the material effect to the entity and all child entities (hat have a Model mixin) */
    local function AddEffect(entity, material, viewMaterial, entities)
    
        -- local numChildren = entity:GetNumChildren()
        
        if HasMixin(entity, "Model") then
            local model = entity._renderModel
            if model ~= nil then
                if model:GetZone() == RenderScene.Zone_ViewModel then
                
                    if viewMaterial then                
                        model:AddMaterial(viewMaterial)
                    end
                    
                else
                    model:AddMaterial(material)
                end
                table.insert(entities, entity:GetId())
            end
        end
        
        for i = 1, entity:GetNumChildren() do
            local child = entity:GetChildAtIndex(i - 1)
            if child ~= nil then
                AddEffect(child, material, viewMaterial, entities)
            end
        end
    
    end
    
    local function RemoveEffect(entities, material, viewMaterial)
    
        for i =1, #entities do
            local entity = Shared.GetEntity( entities[i] )
            if entity ~= nil and HasMixin(entity, "Model") then
                local model = entity._renderModel
                if model ~= nil then
                    if model:GetZone() == RenderScene.Zone_ViewModel then
                        
                        if viewMaterial then                    
                            model:RemoveMaterial(viewMaterial)
                        end
                        
                    else
                        model:RemoveMaterial(material)
                    end
                end                    
            end
        end
        
    end
    
    function ParasiteMixin:OnModelChanged(_)
        self:_RemoveParasiteEffect()
    end

    function ParasiteMixin:_CreateParasiteEffect()
   
        if not self.parasiteMaterial then
        
            local material = Client.CreateRenderMaterial()
            material:SetMaterial(kParasitedMaterial)

            local showViewMaterial = not self.GetShowParasiteView or self:GetShowParasiteView()
            local viewMaterial

            if showViewMaterial then

                viewMaterial = Client.CreateRenderMaterial()
                viewMaterial:SetMaterial(kParasitedMaterial)
            
            end
            
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
            self.parasiteMaterial = nil
            self.parasiteEntities = nil
            
        end

        if self.parasiteViewMaterial then
            
            Client.DestroyRenderMaterial(self.parasiteViewMaterial)
            self.parasiteViewMaterial = nil
            
        end        

    end

end