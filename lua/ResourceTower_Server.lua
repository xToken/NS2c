// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ResourceTower_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Generic resource structure that marine and alien structures inherit from.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function ResourceTower:CollectResources()

    if self:isa("Extractor") then
       self:TriggerEffects("extractor_collect")
    else
        self:TriggerEffects("harvester_collect")
    end
    
    local attached = self:GetAttached()
    
    if attached and attached.CollectResources then
    
        // reduces the resource count of the node
        attached:CollectResources()
    
    end

end

function ResourceTower:OnSighted(sighted)

    local attached = self:GetAttached()
    if attached and sighted then
        attached.showObjective = true
    end

end

function ResourceTower:GetIsCollecting()
    return GetIsUnitActive(self) and GetGamerules():GetGameStarted()
end
