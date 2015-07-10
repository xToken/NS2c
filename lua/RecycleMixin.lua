// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\RecycleMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    Allows recycling of structures. Use server side only.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

//Adjustments to Recycle refunding.

RecycleMixin = CreateMixin(RecycleMixin)
RecycleMixin.type = "Recycle"

local kRecycleEffectDuration = 2

RecycleMixin.expectedCallback =
{
}

RecycleMixin.optionalCallbacks =
{
    GetCanRecycleOverride = "Return custom restrictions for recycling."
}

RecycleMixin.expectedMixins =
{
    Research = "Required for recycle progress / cancellation."
}    

RecycleMixin.networkVars =
{
    recycled = "boolean"
}

function RecycleMixin:__initmixin()
    self.recycled = false
end

function RecycleMixin:GetRecycleActive()
    return self.researchingId == kTechId.Recycle
end

function RecycleMixin:OnRecycled()
end

function RecycleMixin:GetCanRecycle()

    local canRecycle = true
    
    if self.GetCanRecycleOverride then
        canRecycle = self:GetCanRecycleOverride()
    end

    return canRecycle and not self:GetRecycleActive()    

end

function RecycleMixin:OnResearchComplete(researchId)

    if researchId == kTechId.Recycle then
        
        self:TriggerEffects("recycle_end")
        
        // Amount to get back, accounting for upgraded structures too
        local upgradeLevel = 0
        if self.GetUpgradeLevel then
            upgradeLevel = self:GetUpgradeLevel()
        end
        
        local amount = GetRecycleAmount(self:GetTechId(), upgradeLevel)
        // returns a scalar from 0-1 depending on health the structure has (at the present moment)
        local scalar = kRecycleRefundScalar
        
        // We round it up to the nearest value thus not having weird
        // fracts of costs being returned which is not suppose to be 
        // the case.
        if amount == nil then amount = 1 end
        local finalRecycleAmount = math.round(amount * scalar)
        
        self:GetTeam():AddTeamResources(finalRecycleAmount)
        
        self:GetTeam():PrintWorldTextForTeamInRange(kWorldTextMessageType.Resources, finalRecycleAmount, self:GetOrigin() + kWorldMessageResourceOffset, kResourceMessageRange)
        
        Server.SendNetworkMessage( "Recycle", BuildRecycleMessage(amount - finalRecycleAmount, self:GetTechId(), finalRecycleAmount), true )
        
        local team = self:GetTeam()
        local deathMessageTable = team:GetDeathMessage(team:GetCommander(), kDeathMessageIcon.Recycled, self)
        team:ForEachPlayer(function(player) if player:GetClient() then Server.SendNetworkMessage(player:GetClient(), "DeathMessage", deathMessageTable, true) end end)
        
        self.recycled = true
        self.timeRecycled = Shared.GetTime()

        self:OnRecycled()
        
        self:AddTimedCallback(function(self) DestroyEntity(self) end, kRecycleEffectDuration + 1)
        
    end

end

function RecycleMixin:GetIsRecycled()
    return self.recycled
end

function RecycleMixin:GetRecycleScalar()
    return self:GetHealth() / self:GetMaxHealth()
end

function RecycleMixin:GetIsRecycling()
    return self.researchingId == kTechId.Recycle
end

function RecycleMixin:OnResearch(researchId)

    if researchId == kTechId.Recycle then        
        self:TriggerEffects("recycle_start")        
        if self.MarkBlipDirty then
            self:MarkBlipDirty()
        end
    end
    
end


function RecycleMixin:OnResearchCancel(researchId)

    if researchId == kTechId.Recycle then
        if self.MarkBlipDirty then
            self:MarkBlipDirty()
        end
    end
    
end


function RecycleMixin:OnUpdateRender()

    PROFILE("RecycleMixin:OnUpdateRender")

    if self.recycled ~= self.clientRecycled then
    
        self.clientRecycled = self.recycled
        self:SetOpacity(1, "recycleAmount")
        
        if self.recycled then
            self.clientTimeRecycleStarted = Shared.GetTime()
        else
            self.clientTimeRecycleStarted = nil
        end
    
    end
    
    if self.clientTimeRecycleStarted then
    
        local recycleAmount = 1 - Clamp((Shared.GetTime() - self.clientTimeRecycleStarted) / kRecycleEffectDuration, 0, 1)
        self:SetOpacity(recycleAmount, "recycleAmount")
    
    end

end

function RecycleMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("RecycleMixin:OnUpdateAnimationInput")
    modelMixin:SetAnimationInput("recycling", self:GetRecycleActive())
    
end