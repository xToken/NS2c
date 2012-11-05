// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineCommander_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function MarineCommander:TechCausesDelay(techId)
    return false
end

function MarineCommander:OnInitLocalClient()

    Commander.OnInitLocalClient(self)
    
    if self.guiDistressBeacon == nil then
        self.guiDistressBeacon = GetGUIManager():CreateGUIScript("GUIDistressBeacon")
    end
    
    if self.sensorBlips == nil then
        self.sensorBlips = GetGUIManager():CreateGUIScript("GUISensorBlips")
    end 
    
    if self.waypoints == nil then
        self.waypoints = GetGUIManager():CreateGUIScript("GUIWaypoints")
        self.waypoints:InitMarineTexture()
    end
    
end

function MarineCommander:SetSelectionCircleMaterial(entity)
 
    if HasMixin(entity, "Construct") and not entity:GetIsBuilt() then
    
        SetMaterialFrame("marineBuild", entity.buildFraction)

    else

        // Allow entities without health to be selected.
        local healthPercent = 1
        if(entity.health ~= nil and entity.maxHealth ~= nil) then
            healthPercent = entity.health / entity.maxHealth
        end
        
        SetMaterialFrame("marineHealth", healthPercent)

    end
   
end