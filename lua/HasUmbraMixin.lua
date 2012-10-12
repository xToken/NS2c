// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\HasUmbraMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * UmbraMixin drags out parts of an umbra cloud to protect an alien for additional UmbraMixin.kUmbraDragTime seconds.
 */
HasUmbraMixin = CreateMixin( HasUmbraMixin )
HasUmbraMixin.type = "HasUmbra"

HasUmbraMixin.expectedMixins =
{
}

HasUmbraMixin.networkVars =
{
    umbratime = "private time"
}

function HasUmbraMixin:__initmixin()
    self.umbratime = 0
end

function HasUmbraMixin:GetHasUmbra()
    return self.umbratime > Shared.GetTime()
end

if Server then

    function HasUmbraMixin:SetHasUmbra(state, umbraTime, force)
    
        if HasMixin(self, "Live") and not self:GetIsAlive() then
            return
        end
        self.umbratime = umbraTime
    end
    
end