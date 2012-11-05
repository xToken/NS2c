// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\RegenerationMixin.lua    
//    
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)   
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

RegenerationMixin = CreateMixin( RegenerationMixin )
RegenerationMixin.type = "Regeneration"

RegenerationMixin.expectedMixins =
{
    Live = "Needed for GetMaxHealth.",
}

local kRegenEffectInterval = 1

function RegenerationMixin:__initmixin()
    self.timeLastRegenEffect = 0
end

if Server then

    local function GetCanRegenerate(self) 
        if self.timeLastRegenEffect == nil or self.timeLastRegenEffect + kRegenEffectInterval < Shared.GetTime() then   
            return true
        else
            return false
        end
    end

    local function SharedUpdate(self, deltaTime)
        local hasupg, level = GetHasRegenerationUpgrade(self)
        if hasupg then
        
            if GetCanRegenerate(self) then

                local healRate = ((self:GetMaxHealth() + self:GetMaxArmor()) * ((kAlienRegenerationPercentage / 3) * level))
                                
                local prevHealthScalar = self:GetHealthScalar()
                self:AddHealth(healRate, false, false, true)
                
                if prevHealthScalar < self:GetHealthScalar() then
                    self:TriggerEffects("regeneration")
                    self.timeLastRegenEffect = Shared.GetTime()
                end

            end
            
        end
        
    end

    function RegenerationMixin:OnUpdate(deltaTime)   
        SharedUpdate(self, deltaTime)
    end

    function RegenerationMixin:OnProcessMove(input)   
        SharedUpdate(self, input.time)
    end

end