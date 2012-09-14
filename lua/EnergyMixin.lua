// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\EnergyMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

EnergyMixin = CreateMixin( EnergyMixin )
EnergyMixin.type = "Energy"
local kMaxEnergy = 100

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
    
    assert(self.maxEnergy <= kMaxEnergy)
    
end

function EnergyMixin:GetEnergy()
    return self.energy
end
AddFunctionContract(EnergyMixin.GetEnergy, { Arguments = { "Entity" }, Returns = { "number" } })

function EnergyMixin:SetEnergy(newEnergy)
    self.energy = Clamp(newEnergy, 0, self.maxEnergy)
end
AddFunctionContract(EnergyMixin.SetEnergy, { Arguments = { "Entity", "number" }, Returns = { } })

function EnergyMixin:AddEnergy(amount)
    self.energy = Clamp(self.energy + amount, 0, self.maxEnergy)
end
AddFunctionContract(EnergyMixin.AddEnergy, { Arguments = { "Entity", "number" }, Returns = { } })

function EnergyMixin:SetMaxEnergy(amount)
    self.maxEnergy = Clamp(amount, 0, kMaxEnergy)
end
AddFunctionContract(EnergyMixin.SetMaxEnergy, { Arguments = { "Entity", "number" }, Returns = { } })

function EnergyMixin:GetMaxEnergy()
    return self.maxEnergy
end
AddFunctionContract(EnergyMixin.GetMaxEnergy, { Arguments = { "Entity" }, Returns = { "number" } })

function EnergyMixin:GetEnergyFraction()
    return self:GetEnergy() / self:GetMaxEnergy()
end

if Server then

    local function GetEnergyUpdateRate(self)
    
        if self.OverrideGetEnergyUpdateRate then
            return self:OverrideGetEnergyUpdateRate()
        end
        
        return kEnergyUpdateRate
        
    end

    local function SharedUpdate(self, timePassed)
        
        if GetGamerules():GetGameStarted() and self:GetCanUpdateEnergy() then
        
            local scalar = 1
            
            local energyRate = GetEnergyUpdateRate(self) * scalar            
            self:AddEnergy(timePassed * energyRate)
            
        end    
        
    end

    function EnergyMixin:OnUpdate(deltaTime)
        SharedUpdate(self, deltaTime)
    end
    AddFunctionContract(EnergyMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

    function EnergyMixin:OnProcessMove(input)
        SharedUpdate(self, input.time)
    end
    AddFunctionContract(EnergyMixin.OnProcessMove, { Arguments = { "Entity", "Move" }, Returns = { } })

end