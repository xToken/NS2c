// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\BabblerEgg.lua
//
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    X babblers will hatch out of it when construction is completed.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Babbler.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/MobileTargetMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/OwnerMixin.lua")
Script.Load("lua/ConstructMixin.lua")

class 'BabblerEgg' (ScriptActor)

BabblerEgg.kMapName = "babbleregg"

BabblerEgg.kModelName = PrecacheAsset("models/alien/babbler/babbler_egg.model")
BabblerEgg.kModelNameShadow = PrecacheAsset("models/alien/babbler/babbler_egg_shadow.model")
local kAnimationGraph = PrecacheAsset("models/alien/babbler/babbler_egg.animation_graph")

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)

function BabblerEgg:OnCreate()

    ScriptActor.OnCreate(self)

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    
    InitMixin(self, LiveMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, ConstructMixin)
    
    if Server then
        
        InitMixin(self, EntityChangeMixin)
        
        self.trackingBabblerId = { }
        self.silenced = false
        
    end
    
end

function BabblerEgg:OnInitialized()

    self:SetModel(BabblerEgg.kModelName, kAnimationGraph)
    
    if Server then
        InitMixin(self, MobileTargetMixin)        
    elseif Client then
        InitMixin(self, UnitStatusMixin)
    end
    
end

function BabblerEgg:SetVariant(gorgeVariant)

    if gorgeVariant == kGorgeVariant.shadow then
        self:SetModel(BabblerEgg.kModelNameShadow, kAnimationGraph)
    else
        self:SetModel(BabblerEgg.kModelName, kAnimationGraph)
    end
    
end

if Server then

    local kVerticalOffset = 0.3
    local kBabblerSpawnPoints =
    {
        Vector(0.3, kVerticalOffset, 0.3),
        Vector(-0.3, kVerticalOffset, -0.3),
        Vector(0, kVerticalOffset, 0.3),
        Vector(0, kVerticalOffset, -0.3),
        Vector(0.3, kVerticalOffset, 0),
        Vector(-0.3, kVerticalOffset, 0),    
    }
    
    function BabblerEgg:OnConstructionComplete()
    
        -- Disables also collision.
        self:SetModel(nil)
        self:TriggerEffects("babbler_hatch")
        
        local owner = self:GetOwner()
        
        for i = 1, kNumBabblersPerEgg do
        
            local babbler = CreateEntity(Babbler.kMapName, self:GetOrigin() + kBabblerSpawnPoints[i], self:GetTeamNumber())
            babbler:SetOwner(owner)
            babbler:SetSilenced(self.silenced)
            
            if owner and owner:isa("Gorge") then
                babbler:SetVariant(owner:GetVariant())
            end
            
            table.insert(self.trackingBabblerId, babbler:GetId())
            
        end
        
    end
    
    function BabblerEgg:GetCanTakeDamage()
        return not self:GetIsBuilt()
    end
    
    function BabblerEgg:GetCanDie()
        return not self:GetIsBuilt()
    end
    
    function BabblerEgg:OnKill()
    
        self:TriggerEffects("death")
        DestroyEntity(self)
        
    end
    
    function BabblerEgg:SetOwner(owner)
    
        local hasupg, level = GetHasSilenceUpgrade(owner)
        if hasupg and level == 3 then
            self.silenced = true
        end
    
    end
    
    function BabblerEgg:OnEntityChange(oldId)
    
        if not self.preventEntityChangeCallback and table.removevalue(self.trackingBabblerId, oldId) then
        
            if #self.trackingBabblerId == 0 then
                DestroyEntity(self)
            end
        
        end
    
    end
    
    function BabblerEgg:OnDestroy()
    
        ScriptActor.OnDestroy(self)
        
        self.preventEntityChangeCallback = true
        if self.trackingBabblerId and #self.trackingBabblerId > 0 then
        
            for _, babblerId in ipairs(self.trackingBabblerId) do
            
                local babbler = Shared.GetEntity(babblerId)
                if babbler then
                    babbler:Kill()
                end
                
            end
            
        end
        
    end
    
end

function BabblerEgg:GetEffectParams(tableParams)
    tableParams[kEffectFilterSilenceUpgrade] = self.silenced
end

function BabblerEgg:GetSendDeathMessageOverride()
    return false
end

function BabblerEgg:GetCanBeUsed(player, useSuccessTable)
    if not self:GetCanConstruct(player) then
        useSuccessTable.useSuccess = false
    else
        useSuccessTable.useSuccess = true
    end
end

Shared.LinkClassToMap("BabblerEgg", BabblerEgg.kMapName, networkVars)