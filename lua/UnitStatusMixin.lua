// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\UnitStatusMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

kUnitStatus = enum({
    'None',
    'Inactive',
    'Unpowered',
    'Dying',
    'Unbuilt',
    'Damaged',
    'Recycling',
    'Researching'
})

UnitStatusMixin = CreateMixin( UnitStatusMixin )
UnitStatusMixin.type = "UnitStatus"

function UnitStatusMixin:__initmixin()
    self.unitStatus = kUnitStatus.Active
end

function UnitStatusMixin:GetShowUnitStatusFor(forEntity)

    local showUnitStatus = true
    
    if self.GetShowUnitStatusForOverride then
        showUnitStatus = self:GetShowUnitStatusForOverride(forEntity)
    end
    
    if HasMixin(self, "Model") and showUnitStatus then
        showUnitStatus = self:GetWasRenderedLastFrame()
    end
    
    if HasMixin(self, "Live") and showUnitStatus then
        showUnitStatus = self:GetIsAlive()
    end
    
    return showUnitStatus
    
end

function UnitStatusMixin:GetUnitStatus(forEntity)

    local unitStatus = kUnitStatus.None

    // don't show status of opposing team
    if GetAreFriends(forEntity, self) then

        if not GetIsUnitActive(self) then

            if (not HasMixin(self, "Construct") or self:GetIsBuilt()) then
                unitStatus = kUnitStatus.Unpowered                
            end   
        
        else
        
            if HasMixin(self, "Research") and self:GetIsResearching() then
                if self:GetRecycleActive() then
                    unitStatus = kUnitStatus.Recycling
                else
                    unitStatus = kUnitStatus.Researching
                end
            
            elseif HasMixin(self, "Live") and self:GetHealthScalar() < 1 and self:GetIsAlive() and (not forEntity.GetCanRepairOverride or forEntity:GetCanRepairOverride(self)) then
                unitStatus = kUnitStatus.Damaged
            end
        
        end
    
    end

    return unitStatus

end

function UnitStatusMixin:GetUnitStatusFraction(forEntity)

    if GetAreFriends(forEntity, self) and forEntity:isa("Gorge") and HasMixin(self, "Construct") and not self:GetIsBuilt() then
        return self:GetBuiltFraction()
    end
    
    if GetAreFriends(forEntity, self) and HasMixin(self, "Research") and self:GetIsResearching() then
        return self:GetResearchProgress()   
    end
    
    return 0

end

function UnitStatusMixin:GetUnitHint(forEntity)

    if HasMixin(self, "Tech") then
    
        local hintString = LookupTechData(self:GetTechId(), kTechDataHint, "")
        if hintString ~= "" then
            
            if self.OverrideHintString then
                hintString = self:OverrideHintString(hintString)
            end
            
            return Locale.ResolveString(hintString)
        end
        
    end
    
    return ""

end

function UnitStatusMixin:GetUnitName(forEntity)
    
    if HasMixin(self, "Tech") then
    
        if self.GetUnitNameOverride then
            return self:GetUnitNameOverride(forEntity)
        end
    
        if not self:isa("Player") then
        
            local description = GetDisplayName(self)
            if HasMixin(self, "Construct") and not self:GetIsBuilt() then
                description = "Unbuilt " .. description
            end
        
            return description
            
        else            
            return self:GetName(forEntity)            
        end
    
    end

    return ""

end

function UnitStatusMixin:GetActionName(forEntity)

    if GetAreFriends(forEntity, self) and HasMixin(self, "Research") and self:GetIsResearching() then
    
        local researchingId = self:GetResearchingId()
        local displayName = LookupTechData(researchingId, kTechDataDisplayName, "")
    
        /*
        // Override a couple special cases        
        if researchingId == kTechId.AdvancedArmoryUpgrade or researchingId == kTechId.UpgradeRoboticsFactory or researchingId == kTechId.EvolveBombard then
            displayName = "COMM_SEL_UPGRADING"
        end
        */
        
        return Locale.ResolveString(displayName)
        
    end
    
    return ""

end
