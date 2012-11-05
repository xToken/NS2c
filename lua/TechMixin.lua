// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechMixin.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com) and
//                  Andreas Urwalek (andi@unknownworlds.com)
//
//    Updates tech availability.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/MixinUtility.lua")

TechMixin = CreateMixin( TechMixin )
TechMixin.type = "Tech"

TechMixin.optionalCallbacks =
{
    OnTechIdSet = "Will be called after the tech id is set inside SetTechId."
}

TechMixin.expectedCallbacks = 
{
    GetMapName = "Map name for looking up tech id"
}

TechMixin.networkVars =
{
    techId = string.format("integer (0 to %d)", kTechIdMax)
}

function TechMixin:__initmixin()
    self.techId = LookupTechId(self:GetMapName(), kTechDataMapName, kTechId.None)
    self.techAdded = false
    self.timeTechIdChanged = 0
    //Print("assigned tech id %s", EnumToString(kTechId, self.techId))
end

function TechMixin:UpdateTechAvailability()

    if Server then
    
        local team = HasMixin(self, "Team") and self:GetTeam()
        if team then
        
            if GetIsUnitActive(self, false) and not self.techAdded and self.techId ~= kTechId.None then
            
                team:TechAdded(self)
                self.techAdded = true
                //Print("added tech: %s", EnumToString(kTechId, self.techId))
            
            elseif not GetIsUnitActive(self, false) and self.techAdded and self.techId ~= kTechId.None then
            
                team:TechRemoved(self)
                self.techAdded = false
                //Print("added removed: %s", EnumToString(kTechId, self.techId))
            
            end
            
        end

    end       

end

function TechMixin:SetTechId(techId)

    if Server then

        if techId ~= self.techId then
        
            if self.UpdateHealthValues then
                self:UpdateHealthValues(techId)
            end
        
            if self.techAdded then
            
                local team = HasMixin(self, "Team") and self:GetTeam()
                if team and self.techId ~= kTechId.None then
                    team:TechRemoved(self)
                end
                
                self.techAdded = false
            
            end
        
            self.timeTechIdChanged = Shared.GetTime()
            self.techId = techId
            self:UpdateTechAvailability()
            
        end
        
    end

end

function TechMixin:UpgradeToTechId(newTechId)

    if self:GetTechId() ~= newTechId then
    
        if self.OnPreUpgradeToTechId then
            self:OnPreUpgradeToTechId(newTechId)
        end

        local healthScalar = 0
        local armorScalar = 0
        local isAlive = HasMixin(self, "Live")
        if isAlive then
            // Preserve health and armor scalars but potentially change maxHealth and maxArmor.
            healthScalar = self:GetHealthScalar()
            armorScalar = self:GetArmorScalar()
        end
        
        self:SetTechId(newTechId)
        
        if isAlive then
        
            self:SetMaxHealth(LookupTechData(newTechId, kTechDataMaxHealth, self:GetMaxHealth()))
            self:SetMaxArmor(LookupTechData(newTechId, kTechDataMaxArmor, self:GetMaxArmor()))
            
            self:SetHealth(healthScalar * self:GetMaxHealth())
            self:SetArmor(armorScalar * self:GetMaxArmor())
            
        end
        
        return true
        
    end
    
    return false
    
end
AddFunctionContract(TechMixin.UpgradeToTechId, { Arguments = { "Entity", "number" }, Returns = { "boolean" } })

// Return techId that is the technology this entity represents. This is used to choose an icon to display to represent
// this entity and also to lookup max health, spawn heights, etc.
function TechMixin:GetTechId()
    return self.techId
end

if Server then

    function TechMixin:GetTimeTechIdChanged()
        return self.timeTechIdChanged
    end
    
    local function SharedUpdate(self)
        PROFILE("TechMixin:SharedUpdate")
        if not self.techAdded and self.techId ~= kTechId.None then
            self:UpdateTechAvailability()
        end
    end
    
    function TechMixin:OnProcessMove()
        SharedUpdate(self)
    end
    
    function TechMixin:OnUpdate(deltaTime)
        SharedUpdate(self)
    end

elseif Client then

    function TechMixin:OnUpdate(deltaTime)
    
        if self.clientTechId ~= self.techId then
        
            self.clientTechId = self.techId
            self.timeTechIdChanged = Shared.GetTime()
        
        end

    end
    
    function TechMixin:GetTimeTechIdChanged()
        return self.timeTechIdChanged
    end
    
end    

if Server then

    function TechMixin:OnConstructionComplete()
        self:UpdateTechAvailability()
    end

    function TechMixin:OnPowerOn()
        self:UpdateTechAvailability()
    end

    function TechMixin:OnPowerOff()
        self:UpdateTechAvailability()
    end

    function TechMixin:OnKill()
        self:UpdateTechAvailability()
    end
    
    function TechMixin:OnRecycled()
        self:UpdateTechAvailability()
    end

    function TechMixin:OnDestroy()
    
        if self.techAdded then
        
            local team = HasMixin(self, "Team") and self:GetTeam()
            if team then
                team:TechRemoved(self)
            end
            
            self.techAdded = false
            
        end
        
    end

end