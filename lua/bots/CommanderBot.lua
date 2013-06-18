//=============================================================================
//
// lua\bots\CommanderBot.lua
//
// Created by Steven An (steve@unknownworlds.com)
// Copyright (c) 2013, Unknown Worlds Entertainment, Inc.
//
//  Tries to log in to a command structure, then creates the appropriate brain for the team.
//
//=============================================================================

//NS2c
//Removed alien commander concept

Script.Load("lua/bots/PlayerBot.lua")
Script.Load("lua/bots/MarineCommanderBrain.lua")

gCommanderBots = {}

local kCommander2BrainClass =
{
    ["MarineCommander"] = MarineCommanderBrain
}

local kTeam2StationClassName =
{
    "CommandStation"
}

class 'CommanderBot' (PlayerBot)

//----------------------------------------
//  Override
//----------------------------------------
function CommanderBot:GetNamePrefix()
    return "[COMBOT] "
end

//----------------------------------------
//  Override
//----------------------------------------
function CommanderBot:_LazilyInitBrain()

    if self.brain == nil then

        local brainClass = kCommander2BrainClass[ self:GetPlayer():GetClassName() ]

        if brainClass ~= nil then
            self.brain = brainClass()
        else
            // must be spectator - wait until we have joined a team
        end

        if self.brain ~= nil then
            self.brain:Initialize()
            self:GetPlayer().botBrain = self.brain
        end

    end

end

function CommanderBot:GetIsPlayerCommanding()

    return self:GetPlayer():isa("Commander")

end

//----------------------------------------
//  Override
//----------------------------------------
function CommanderBot:GenerateMove()

    if gBotDebug:Get("spam") then
        Print("CommanderBot:GenerateMove")
    end

    local player = self:GetPlayer()
    local playerClass = player:GetClassName()
    local stationClass = kTeam2StationClassName[ player:GetTeamNumber() ]

    local move = Move()

    //----------------------------------------
    //  Take commander chair/hive if we are not
    //----------------------------------------
    if not self:GetIsPlayerCommanding() and stationClass ~= nil then

        Print("trying to log %s into %s", player:GetName(), stationClass)

        // Log into any com station
        for _, station in ientitylist(Shared.GetEntitiesWithClassname( stationClass )) do

            station:LoginPlayer(player)
            break
            
        end

    else

        // Brain will modify move.commands
        self:_LazilyInitBrain()
        if self.brain ~= nil then
            self.brain:Update(self,  move)
        else
            // must be waiting to join a team
        end

    end

    return move

end
