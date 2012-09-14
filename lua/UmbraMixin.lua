// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\UmbraMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

/**
 * UmbraMixin drags out parts of an umbra cloud to protect an alien for additional UmbraMixin.kUmbraDragTime seconds.
 */
UmbraMixin = CreateMixin( UmbraMixin )
UmbraMixin.type = "Umbra"

UmbraMixin.kSegment1Cinematic = PrecacheAsset("cinematics/alien/crag/umbraTrail1.cinematic")
UmbraMixin.kSegment2Cinematic = PrecacheAsset("cinematics/alien/crag/umbraTrail2.cinematic")
UmbraMixin.kViewModelCinematic = PrecacheAsset("cinematics/alien/crag/umbra_1p.cinematic")

UmbraMixin.expectedMixins =
{
}

UmbraMixin.networkVars =
{
    // as an override for the gameeffect mask
    dragsUmbra = "boolean",
    umbraBulletCount = string.format("integer (0 to %d)", kUmbraBlockRate)
}

function UmbraMixin:__initmixin()
    self.dragsUmbra = false
    umbraBulletCount = 0
    self.timeUmbraExpires = 0
end

function UmbraMixin:GetHasUmbra()
    return self.dragsUmbra
end

if Server then

    function UmbraMixin:SetOnFire()
        self.dragsUmbra = false
        self.timeUmbraExpires = 0
    end

    function UmbraMixin:SetHasUmbra(state, umbraTime, force)
    
        if HasMixin(self, "Live") and not self:GetIsAlive() then
            return
        end
    
        self.dragsUmbra = state
        
        if not umbraTime then
            umbraTime = 0
        end
        
        if self.dragsUmbra then        
            self.timeUmbraExpires = Shared.GetTime() + umbraTime
        end
        
    end
    
end


local function SharedUpdate(self, deltaTime)

    if Server then
    
        self.dragsUmbra = self.timeUmbraExpires > Shared.GetTime()
        
        if not self.dragsUmbra then
            self.umbraBulletCount = 0
        end

    elseif Client then

        if self:GetHasUmbra() then

            if not self.umbraDragEffect then
                self:CreateUmbraDragEffect()
            end    
    
            self:UpdateUmbraDragEffect(deltaTime)
            
        elseif self.umbraDragEffect then
    
            self:DestroyUmbraDragEffect()
            
        end   
    
    end
    
end

function UmbraMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end
AddFunctionContract(UmbraMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

function UmbraMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end
AddFunctionContract(UmbraMixin.OnProcessMove, { Arguments = { "Entity", "Move" }, Returns = { } })

// creates a table consisting of "lastCoords" and "cinematic", similar to TrailCinematic but without any overhead
function UmbraMixin:CreateUmbraDragEffect()

    // create a view model cinematic for local client
    
    if self == Client.GetLocalPlayer() and not self:GetIsThirdPerson() then
    
        self.umbraDragEffect = Client.CreateCinematic(RenderScene.Zone_ViewModel)
        self.umbraDragEffect:SetCinematic(UmbraMixin.kViewModelCinematic)
        self.umbraDragEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
    
    else
        
        local coords = self:GetCoords()

        self.umbraDragEffect = Client.CreateCinematic(RenderScene.Zone_Default)
        
        self.umbraDragEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.umbraDragEffect:SetCinematic(UmbraMixin.kSegment1Cinematic)
        self.umbraDragEffect:SetCoords(coords)
    
    end

end

function UmbraMixin:UpdateUmbraDragEffect(deltaTime)

    if self ~= Client.GetLocalPlayer() or self:GetIsThirdPerson() then

        self.umbraDragEffect:SetCoords(self:GetCoords())
        self.umbraDragEffect:SetIsVisible(self:GetIsVisible())
    
    end
    
end

function UmbraMixin:DestroyUmbraDragEffect()

    if self.umbraDragEffect then
    
        Client.DestroyCinematic(self.umbraDragEffect)
        self.umbraDragEffect = nil

    end

end

function UmbraMixin:OnKill()
    self:DestroyUmbraDragEffect()
end

function UmbraMixin:OnDestroy()
    self:DestroyUmbraDragEffect()
end

function UmbraMixin:UpdateUmbraBulletCount()

    self.umbraBulletCount = math.min( self.umbraBulletCount + 1, kUmbraBlockRate)
    
    if self.umbraBulletCount == kUmbraBlockRate then
        self.umbraBulletCount = 0
        return true
    end
    
    return false
    
end
