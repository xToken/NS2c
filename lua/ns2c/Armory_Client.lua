-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Armory_Client.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- A Flash buy menu for marines to purchase weapons and armory from.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Removed armory buy menu

local kHealthIndicatorModelName = PrecacheAsset("models/marine/armory/health_indicator.model")

function GetResearchPercentage(techId)

    local techNode = GetTechTree():GetTechNode(techId)
    
    if(techNode ~= nil) then
    
        if(techNode:GetAvailable()) then
            return 1
        elseif(techNode:GetResearching()) then
            return techNode:GetResearchProgress()
        end    
        
    end
    
    return 0
    
end

function Armory:SetOpacity(amount, identifier)

    for i = 0, self:GetNumChildren() - 1 do
    
        local child = self:GetChildAtIndex(i)
        if HasMixin(child, "Model") then
            child:SetOpacity(amount, identifier)
        end
    
    end
    
end

local kUpVector = Vector(0, 1, 0)

function Armory:OnUpdateRender()

    PROFILE("Armory:OnUpdateRender")

    local player = Client.GetLocalPlayer()
    local showHealthIndicator = false
    
    if player then    
        showHealthIndicator = GetIsUnitActive(self) and GetAreFriends(self, player) and (player:GetHealth()/player:GetMaxHealth()) ~= 1 and player:GetIsAlive() and not player:isa("Commander") 
    end

    if not self.healthIndicator then
    
        self.healthIndicator = Client.CreateRenderModel(RenderScene.Zone_Default)  
        self.healthIndicator:SetModel(kHealthIndicatorModelName)
        
    end
    
    self.healthIndicator:SetIsVisible(showHealthIndicator)
    
    -- rotate model if visible
    if showHealthIndicator then
    
        local time = Shared.GetTime()
        local zAxis = Vector(math.cos(time), 0, math.sin(time))

        local coords = Coords.GetLookIn(self:GetOrigin() + 2.9 * kUpVector, zAxis)
        self.healthIndicator:SetCoords(coords)
    
    end

end

function Armory:OnDestroy()

    if self.healthIndicator then
        Client.DestroyRenderModel(self.healthIndicator)
        self.healthIndicator = nil
    end

    ScriptActor.OnDestroy(self)

end