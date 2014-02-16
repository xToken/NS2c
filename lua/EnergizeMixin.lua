// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\EnergizeMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

/**
 * EnergizeMixin drags out parts of an umbra cloud to protect an alien for additional EnergizeMixin.kUmbraDragTime seconds.
 */
EnergizeMixin = CreateMixin(EnergizeMixin)
EnergizeMixin.type = "Energize"

EnergizeMixin.kSegment1Cinematic = PrecacheAsset("cinematics/alien/crag/umbraTrail1.cinematic")
EnergizeMixin.kSegment2Cinematic = PrecacheAsset("cinematics/alien/crag/umbraTrail2.cinematic")
EnergizeMixin.kViewModelCinematic = PrecacheAsset("cinematics/alien/crag/umbra_1p.cinematic")

local kMaxEnergizeLevel = 1

EnergizeMixin.expectedMixins =
{
    GameEffects = "Required to track energize state",
}

EnergizeMixin.networkVars =
{
    energizeLevel = "private integer (0 to " .. kMaxEnergizeLevel .. ")"
}

function EnergizeMixin:__initmixin()

    self.energizeLevel = 0

    if Server then
        self.energizeGivers = {}
        self.energizeGiverTime = {}
        self.timeLastEnergizeUpdate = 0
    end    
end

if Server then

    function EnergizeMixin:Energize(giver)
    
        local energizeAllowed = not self.GetIsEnergizeAllowed or self:GetIsEnergizeAllowed()
        
        if energizeAllowed then
        
            table.insertunique(self.energizeGivers, giver:GetId())
            self.energizeGiverTime[giver:GetId()] = Shared.GetTime()
        
        end
    
    end

end

local function SharedUpdate(self, deltaTime)

    if Server then
    
        local energizeAllowed = not self.GetIsEnergizeAllowed or self:GetIsEnergizeAllowed()
    
        local removeGiver = {}
        for _, giverId in ipairs(self.energizeGivers) do
            
            if not energizeAllowed or self.energizeGiverTime[giverId] + 1 < Shared.GetTime() then
                self.energizeGiverTime[giverId] = nil
                table.insert(removeGiver, giverId)
            end
            
        end
        
        // removed timed out
        for _, removeId in ipairs(removeGiver) do
            table.removevalue(self.energizeGivers, removeId)
        end
        
        self.energizeLevel = Clamp(#self.energizeGivers, 0, kMaxEnergizeLevel)
        self:SetGameEffectMask(kGameEffect.Energize, self.energizeLevel > 0)
        
        if self.energizeLevel > 0 and self.timeLastEnergizeUpdate + kEnergizeUpdateRate < Shared.GetTime() then
        
            local energy = kPlayerEnergyPerEnergize
            energy = energy * self.energizeLevel
            self:AddEnergy(energy)
            self.timeLastEnergizeUpdate = Shared.GetTime()
        
        end
    
    end
    
end

function EnergizeMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end

function EnergizeMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end

/*
function EnergizeMixin:AddEnergy(energy)

    if Server or ( Client and Client.GetLocalPlayer() == self ) then
        if self:GetGameEffectMask(kGameEffect.Energize) then
            self:SetEnergy(self:GetEnergy() + energy * kEnergizeEnergyIncrease * self.energizeLevel)
        end
    end
    
end
*/

function EnergizeMixin:GetEnergizeLevel()
    return self.energizeLevel
end