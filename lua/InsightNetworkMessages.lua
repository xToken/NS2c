// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\InsightNetworkMessages.lua
//
// Created by: Jon Hughes (jon@jhuze.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed EGG counts and powernode status

local kHealthMessage =
{
    clientIndex = "entityid",
    health = "integer",
    maxHealth = "integer",
    armor = "integer",
    maxArmor = "integer"
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
    teamNumber = "integer",
    techId = "integer",
    location = "integer",
    healthFraction = "float",
    powerNodeFraction = "float",
    builtFraction = "float",
    eggCount = "integer"
}

function BuildTechPointsMessage(techPoint)

    local t = {}
    local techPointLocation = techPoint:GetLocationId()
    t.entityIndex = techPoint:GetId()
    t.location = techPointLocation
    t.teamNumber = techPoint.occupiedTeam
    
    local structure = Shared.GetEntity(techPoint.attachedId)
    
    if structure then

        t.teamNumber = structure:GetTeamNumber()
        t.techId = structure:GetTechId()
        if structure:GetIsAlive() then
        
            -- Structure may not have a GetBuiltFraction() function (Hallucinations for example).
            t.builtFraction = structure.GetBuiltFraction and structure:GetBuiltFraction() or -1
            t.healthFraction= structure:GetHealthScalar()
            
        else
        
            t.builtFraction = -1
            t.healthFraction= -1
            
        end
        
        return t
        
    end
    
    return t
    
end

Shared.RegisterNetworkMessage( "TechPoints", kTechPointsMessage )


local kRecycleMessage =
{
    resLost = "float",
    techId = "enum kTechId",
    resGained = "integer"
}

function BuildRecycleMessage(resLost, techId, resGained)

    local t = {}

    t.resLost = resLost
    t.techId = techId
    t.resGained = resGained

    return t

end

Shared.RegisterNetworkMessage( "Recycle", kRecycleMessage )

-- empty network message for game reset
Shared.RegisterNetworkMessage( "Reset" )