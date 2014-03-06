// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\UnitStatusMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

//NS2c
//Modified to add Recycling as a seperate Unit Status from researching.

kUnitStatus = enum({
    'None',
    'Inactive',
    'Unpowered',
    'Dying',
    'Unbuilt',
    'Damaged',
    'Recycling',
    'Researching',
    'Unrepaired'
})

UnitStatusMixin = CreateMixin(UnitStatusMixin)
UnitStatusMixin.type = "UnitStatus"

function UnitStatusMixin:__initmixin()
    self.unitStatus = kUnitStatus.None
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
        
            if HasMixin(self, "Construct") and not self:GetIsBuilt() and (forEntity:isa("Gorge") or forEntity:isa("Marine") or (forEntity.GetCanSeeConstructIcon and forEntity:GetCanSeeConstructIcon(self)) ) then
                unitStatus = kUnitStatus.Unbuilt 

            //elseif HasMixin(self, "PowerConsumer") and self:GetRequiresPower() and not self:GetIsPowered() then
                //unitStatus = kUnitStatus.Unpowered         
            end
        
        else
        
            if HasMixin(self, "Research") and self:GetIsResearching() then
                if self:GetRecycleActive() then
                    unitStatus = kUnitStatus.Recycling
                else
                    unitStatus = kUnitStatus.Researching
                end
            
            elseif HasMixin(self, "Live") and self:GetHealthScalar() < 1 and self:GetIsAlive() and (not forEntity.GetCanSeeDamagedIcon or forEntity:GetCanSeeDamagedIcon(self)) then
            
                if forEntity:isa("Marine") and self:isa("Marine") and self:GetArmor() < self:GetMaxArmor() then            
                    unitStatus = kUnitStatus.Damaged
                elseif forEntity:isa("Marine") and not self:isa("Marine") then
                    unitStatus = kUnitStatus.Damaged
                elseif forEntity:isa("Gorge") then
                    unitStatus = kUnitStatus.Damaged
                end
                
                if unitStatus == kUnitStatus.Damaged and forEntity:isa("Marine") and not forEntity:GetWeapon(Welder.kMapName) then
                    unitStatus = kUnitStatus.Unrepaired
                end
                    
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

        if self.OverrideHintString then
            hintString = self:OverrideHintString(hintString, forEntity)
        end
        
        if hintString ~= "" then            
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
        
        return Locale.ResolveString(displayName)
        
    end
    
    return ""

end

function UnitStatusMixin:GetHasWelder(forEntity)

    return not GetAreEnemies(forEntity, self) and HasMixin(self, "WeaponOwner") and self:GetWeapon(Welder.kMapName) ~= nil

end

function UnitStatusMixin:GetAbilityFraction(forEntity)

    if HasMixin(self, "WeaponOwner") then

        if GetAreEnemies(forEntity, self) then
            return 0
        end

        local primaryWeapon = self:GetWeaponInHUDSlot(1)
        if primaryWeapon and primaryWeapon:isa("ClipWeapon") then
            // always show at least 1% so commander would see a black bar
            return math.max(0.01, primaryWeapon:GetAmmoFraction())
        end
        
    end

    return 0    

end
