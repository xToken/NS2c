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
    visitedByTeamOne = "boolean",
    visitedByTeamTwo = "boolean"
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
    self.visitedByTeamOne = false
    self.visitedByTeamTwo = false
end    

function Location:OnDestroy()

    Trigger.OnDestroy(self)
   
end

function Location:GetShowOnMinimap()
    return self.showOnMinimap
end

function Location:GetWasVisitedByTeam(teamNum)

    return (teamNum == kMarineTeamType and self.visitedByTeamOne) or (teamNum == kAlienTeamType and self.visitedByTeamTwo)

end

if Server then

    function Location:OnTriggerEntered(enterEnt, triggerEnt)

        if enterEnt.SetLocationName then
            enterEnt:SetLocationName(triggerEnt:GetName())
            enterEnt:SetLocationEntity(self)
        end

        if GetGamerules():GetGameStarted() then
            if not enterEnt:isa("Commander") and HasMixin(enterEnt, "Team") then
                if enterEnt:GetTeamNumber() == kMarineTeamType then
                    self.visitedByTeamOne = true
                elseif enterEnt:GetTeamNumber() == kAlienTeamType then
                    self.visitedByTeamTwo = true
                end    
            end
        end
            
    end

end

Shared.LinkClassToMap("Location", Location.kMapName, networkVars)