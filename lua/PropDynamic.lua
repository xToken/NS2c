// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PropDynamic.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed concept of 'power'

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/Mixins/SignalEmitterMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/OnShadowOptionMixin.lua")

class 'PropDynamic' (ScriptActor)

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)

function PropDynamic:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, SignalEmitterMixin)
    InitMixin(self, PowerConsumerMixin)
    if Client then
        InitMixin(self, OnShadowOptionMixin)
    end
    
    self.emitChannel = 0
    
end

function PropDynamic:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false
end

if Server then

    function PropDynamic:OnInitialized()

        ScriptActor.OnInitialized(self)
        
        self.modelName = self.model
        self.propScale = self.scale
        self.decalsOn = self.decalsEnabled
        self.avHighlightEnabled = self.avHighlight
        
        if self.modelName ~= nil then
        
            Shared.PrecacheModel(self.modelName)
            
            local graphName = string.gsub(self.modelName, ".model", ".animation_graph")
            Shared.PrecacheAnimationGraph(graphName)
            
            self:SetModel(self.modelName, graphName)
            self:SetAnimationInput("animation", self.animation)
            
        end
        
        // Don't collide when commanding if not full alpha
        self.commAlpha = GetAndCheckValue(self.commAlpha, 0, 1, "commAlpha", 1, true)
        
        // Test against false so that the default is true
        if self.collidable ~= false then
            self:SetPhysicsType(PhysicsType.None)
        else
        
            if self.dynamic then
                self:SetPhysicsType(PhysicsType.DynamicServer)
                self:SetPhysicsGroup(PhysicsGroup.RagdollGroup)
            else
                self:SetPhysicsType(PhysicsType.Kinematic)
            end
        
            // Make it not block selection and structure placement (GetCommanderPickTarget)
            if self.commAlpha < 1 then
                self:SetPhysicsGroup(PhysicsGroup.CommanderPropsGroup)
            end
            
        end
      
        -- Toggle being highlighted in Alien vision
        if self.avHighlightEnabled and self.avHighlightEnabled == false then
            self._renderModel:SetMaterialParameter("highlight", 0.5)
        end
        
        -- Toggle decals being projected onto model
        if self.decalsOn and self.decalsOn == false then
            self._renderModel:SetMaterialParameter("decals", 0)
        end

        self:SetUpdates(true)
      
        self:SetIsVisible(true)
    
        self:UpdateRelevancyMask()
    
    end
    
    function PropDynamic:UpdateRelevancyMask()
    
        local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
        if self.commAlpha == 1 then
            mask = bit.bor(mask, kRelevantToTeam1Commander, kRelevantToTeam2Commander)
        end
        
        self:SetExcludeRelevancyMask( mask )
        self:SetRelevancyDistance( kMaxRelevancyDistance )
        
    end
    
end

if Client then 
    // prop dynamics are commonly associated with dramatic shadows, so
    // they must not be physics culled when shadows are on
    function PropDynamic:OnShadowOptionChanged(shadowOption)
        self:SetPhysicsCullable(not shadowOption)
    end

end

/**
 * Emit all animation tags out as signals to possibly affect other entities.
 */
function PropDynamic:OnTag(tagName)
    PROFILE("PropDynamic:OnTag")
    self:EmitSignal(self.emitChannel, tagName)
end

Shared.LinkClassToMap("PropDynamic", "prop_dynamic", networkVars)