// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\GorgeStructureMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//
//    GorgeStructureMixin expects as owner a 'Gorge'. If the owner is not valid or not a gorge
//    anymore the structure will die after 60 seconds.
//    Use only server side.
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

GorgeStructureMixin = CreateMixin( GorgeStructureMixin )
GorgeStructureMixin.type = "GorgeStructure"

GorgeStructureMixin.kStarveDelay = 60
GorgeStructureMixin.kDieImmediatelyOnStarve = true

GorgeStructureMixin.networkVars =
{
}

GorgeStructureMixin.expectedMixins =
{
    Owner = "For tracking gorge owner."
}

GorgeStructureMixin.expectedCallbacks = 
{
}

GorgeStructureMixin.optionalCallbacks = 
{
}

function GorgeStructureMixin:__initmixin()

    assert(Server)
    self.timeStarveBegin = 0
    self.hasGorgeOwner = true
    self.isStarving = false
    
end

function GorgeStructureMixin:OnStarve()
end

function GorgeStructureMixin:OnStarveEnd()
end

function GorgeStructureMixin:SetOwner(owner)

    local hasGorgeOwner = owner and ( owner:isa("Gorge") or (owner:isa("Commander") and owner.previousMapName == Gorge.kMapName) )
    
    if hasGorgeOwner ~= self.hasGorgeOwner then
    
        self.hasGorgeOwner = hasGorgeOwner
    
        if self.hasGorgeOwner then
            self:OnStarveEnd()
        else
            self:OnStarve()
            self.timeStarveBegin = Shared.GetTime()
        end
    
    end
    
end

function GorgeStructureMixin:GetIsStarving()
    return self.isStarving
end

local function SharedUpdate(self, deltaTime)
    
end

function GorgeStructureMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end
AddFunctionContract(GorgeStructureMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

function GorgeStructureMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end
AddFunctionContract(GorgeStructureMixin.OnProcessMove, { Arguments = { "Entity", "Move" }, Returns = { } })

function GorgeStructureMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("ConstructMixin:OnUpdateAnimationInput")
    
end