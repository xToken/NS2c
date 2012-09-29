// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//    
// lua\InvalidOriginMixin.lua
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)  
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

/**
 * If an entity is outside the playable area, OnInvalidOrigin will be called
 * by the engine. This mixin destroys the entity.
 */
InvalidOriginMixin = CreateMixin(InvalidOriginMixin)
InvalidOriginMixin.type = "InvalidOrigin"

InvalidOriginMixin.networkVars =
{
}

function InvalidOriginMixin:OnInvalidOrigin()

    Print("Warning: A " .. self:GetClassName() .. " went out of bounds, destroying...")
    
    if HasMixin(self, "Live") and not self.GetReceivesStructuralDamage then
        self:Kill()
    else
        DestroyEntity(self)
    end
    
end