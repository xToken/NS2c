// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Location.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Represents a named location in a map, so players can see where they are.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Trigger.lua")

Shared.PrecacheSurfaceShader("materials/power/powered_decal.surface_shader")

class 'Location' (Trigger)

Location.kMapName = "location"

local networkVars =
{
    showOnMinimap = "boolean",
}

Shared.PrecacheString("")

function Location:OnInitialized()

    Trigger.OnInitialized(self)
    
    // Precache name so we can use string index in entities
    Shared.PrecacheString(self.name)
    
    // Default to show.
    if self.showOnMinimap == nil then
        self.showOnMinimap = true
    end
    
    self:SetTriggerCollisionEnabled(true)
    
    self:SetPropagate(Entity.Propagate_Always)
    
end

function Location:Reset()

end    

function Location:OnDestroy()

    Trigger.OnDestroy(self)
   
end

function Location:GetShowOnMinimap()
    return self.showOnMinimap
end

if Server then

    function Location:OnTriggerEntered(entity, triggerEnt)
        ASSERT(self == triggerEnt)
        if entity.SetLocationName then
            //Log("%s enter loc %s ('%s') from '%s'", entity, self, self:GetName(), entity:GetLocationName())
            // only if we have no location do we set the location here
            // otherwise we wait until we exit the location to set it
            if not entity:GetLocationEntity() then
                entity:SetLocationName(triggerEnt:GetName())
                entity:SetLocationEntity(self)
            end
        end
            
    end
    
    function Location:OnTriggerExited(entity, triggerEnt)
        ASSERT(self == triggerEnt)
        if entity.SetLocationName then
            local enteredLoc = GetLocationForPoint(entity:GetOrigin(), self)
            local name = enteredLoc and enteredLoc:GetName() or ""
            //Log("%s exited location %s('%s'), entered '%s'", entity, self, self:GetName(), name)
            entity:SetLocationName(name)
            entity:SetLocationEntity(enteredLoc)
        end            
    end
end

Shared.LinkClassToMap("Location", Location.kMapName, networkVars)