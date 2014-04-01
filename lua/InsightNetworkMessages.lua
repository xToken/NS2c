// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\InsightNetworkMessages.lua
//
// Created by: Jon Hughes (jon@jhuze.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed EGG counts and powernode status

Script.Load("lua/Globals.lua")
Script.Load("lua/LiveMixin.lua")

local kHealthMessage =
{
    clientIndex = "integer (-1 to 4000)",
    health = string.format("integer (0 to %s)", LiveMixin.kMaxHealth),
    maxHealth = string.format("integer (0 to %s)", LiveMixin.kMaxHealth),
    armor = string.format("integer (0 to %s)", LiveMixin.kMaxArmor),
    maxArmor = string.format("integer (0 to %s)", LiveMixin.kMaxArmor),
}

function BuildHealthMessage(player)

    local t = {}

    t.clientIndex       = player:GetClientIndex()
    t.health            = player:GetHealth()
    t.maxHealth         = player:GetMaxHealth()
    t.armor             = player:GetArmor()
    t.maxArmor          = player:GetMaxArmor()

    return t

end

Shared.RegisterNetworkMessage( "Health", kHealthMessage )

local kTechPointsMessage =
{
    entityIndex = "entityid",
    teamNumber = string.format("integer (-1 to %d)", kSpectatorIndex),
    techId = "enum kTechId",
    location = "resource",
    healthFraction = "float (0 to 1 by 0.01)",
    powerNodeFraction = "float (0 to 1 by 0.01)",
    builtFraction = "float (0 to 1 by 0.01)"
}

function BuildTechPointsMessage(techPoint)

    local t = {}
    local techPointLocation = techPoint:GetLocationId()
    t.entityIndex = techPoint:GetId()
    t.location = techPointLocation
    t.teamNumber = techPoint.occupiedTeam
    t.techId = kTechId.None
    
    local structure = Shared.GetEntity(techPoint.attachedId)
    
    if structure then

        t.teamNumber = structure:GetTeamNumber()
        t.techId = structure:GetTechId()
        if structure:GetIsAlive() then
        
            -- Structure may not have a GetBuiltFraction() function (Hallucinations for example).
            t.builtFraction = structure.GetBuiltFraction and structure:GetBuiltFraction() or 0
            t.healthFraction= structure:GetHealthScalar()
            
        else
        
            t.builtFraction = 0
            t.healthFraction= 0
            
        end
        
        return t
        
    end
    
    return t
    
end

Shared.RegisterNetworkMessage( "TechPoints", kTechPointsMessage )

local kMaxResChange = 50
local kRecycleMessage =
{
    resLost = string.format("integer (0 to %s)", kMaxResChange),
    techId = "enum kTechId",
    resGained = string.format("integer (0 to %s)", kMaxResChange),
}

function BuildRecycleMessage(resLost, techId, resGained)

    local t = {}

    t.resLost = math.floor(resLost)
    t.techId = techId
    t.resGained = resGained

    return t

end

Shared.RegisterNetworkMessage( "Recycle", kRecycleMessage )

-- empty network message for game reset
Shared.RegisterNetworkMessage( "Reset" )