// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\EnergyMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

//NS2c
//Updated to work on timedcallback instead of an update every frame.

EnergyMixin = CreateMixin(EnergyMixin)
EnergyMixin.type = "Energy"
local kMaxEnergy = 100
local kEnergyUpdateTime = 1

EnergyMixin.expectedMixins =
{
    Tech = "Needed for the Tech Id"
}

EnergyMixin.optionalCallbacks =
{
    OverrideGetEnergyUpdateRate = "Return custom updaterate."
}

EnergyMixin.expectedCallbacks =
{
    GetCanUpdateEnergy = "Return true to update the energy."
}

EnergyMixin.networkVars =
{
    // We need to store as floating point to accumulate fractional values correctly, but
    // the client only cares about integer precision.
    energy = string.format("float (0 to %s by 1)", kMaxEnergy),
    maxEnergy = string.format("float (0 to %s by 1)", kMaxEnergy)
}

function EnergyMixin:__initmixin()

    self.energy = LookupTechData(self:GetTechId(), kTechDataInitialEnergy, 0)
    self.maxEnergy = LookupTechData(self:GetTechId(), kTechDataMaxEnergy, 0)
    if Server then
        self:AddTimedCallback(EnergyMixin.Update, kEnergyUpdateTime)
    end
    assert(self.maxEnergy <= kMaxEnergy)
    
end

function EnergyMixin:GetEnergy()
    return self.energy
end

function EnergyMixin:SetEnergy(newEnergy)
    self.energy = Clamp(newEnergy, 0, self.maxEnergy)
end

function EnergyMixin:AddEnergy(amount)
    self.energy = Clamp(self.energy + amount, 0, self.maxEnergy)
end

function EnergyMixin:SetMaxEnergy(amount)
    self.maxEnergy = Clamp(amount, 0, kMaxEnergy)
end

function EnergyMixin:GetMaxEnergy()
    return self.maxEnergy
end

function EnergyMixin:GetEnergyFraction()
    return self:GetEnergy() / self:GetMaxEnergy()
end

local function GetEnergyUpdateRate(self)

    if self.OverrideGetEnergyUpdateRate then
        return self:OverrideGetEnergyUpdateRate()
    end
    
    return kEnergyUpdateRate
    
end

function EnergyMixin:Update()
    if GetGamerules():GetGameStarted() and self:GetCanUpdateEnergy() then      
        self:AddEnergy(GetEnergyUpdateRate(self))
    end
    return self:GetIsAlive()
end