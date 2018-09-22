--=============================================================================
--
-- lua\bots\CommanderBot.lua
--
-- Created by Steven An (steve@unknownworlds.com)
-- Copyright (c) 2013, Unknown Worlds Entertainment, Inc.
--
--  Tries to log in to a command structure, then creates the appropriate brain for the team.
--
--=============================================================================
Script.Load("lua/bots/PlayerBot.lua")
-- Script.Load("lua/bots/AlienCommanderBrain.lua")
Script.Load("lua/bots/MarineCommanderBrain.lua")

gCommanderBots = {}

local kCommander2BrainClass =
{
    ["MarineCommander"] = MarineCommanderBrain
    --["AlienCommander"] = AlienCommanderBrain
}

local kTeam2StationClassName =
{
    "CommandStation"
    --"Hive"
}

class 'CommanderBot' (PlayerBot)

function CommanderBot:Initialize(forceTeam, active)
    if not Bot.Initialize(self, forceTeam, active, 1) then return false end

    table.insert(gCommanderBots, self)

    return true
end

function CommanderBot:OnDestroy()
    for i = #gCommanderBots, 1 , -1 do
        local bot = gCommanderBots[i]
        if bot == self then
            table.remove(gCommanderBots, i)
            break
        end
    end

    Bot.OnDestroy(self)
end

------------------------------------------
--  Override
------------------------------------------
function CommanderBot:GetNamePrefix()
    return "[BOT] "
end

------------------------------------------
--  Override
------------------------------------------
function CommanderBot:_LazilyInitBrain()

    local player = self:GetPlayer()
    if not player then return end

    if self.brain == nil then

        local brainClass = kCommander2BrainClass[ player:GetClassName() ]

        if brainClass ~= nil then
            self.brain = brainClass()
        else
            -- must be spectator - wait until we have joined a team
        end

        if self.brain ~= nil then
            self.brain:Initialize()
            player.botBrain = self.brain
        end

    end

end

function CommanderBot:GetIsPlayerCommanding()

    return self:GetPlayer():isa("Commander")

end

------------------------------------------
--  Override
------------------------------------------
function CommanderBot:GenerateMove()
    PROFILE("CommanderBot:GenerateMove")

    if gBotDebug:Get("spam") then
        Print("CommanderBot:GenerateMove")
    end

    local player = self:GetPlayer()
    local team = player:GetTeam()
    local playerClass = player:GetClassName()
    local stationClass = kTeam2StationClassName[ player:GetTeamNumber() ]

    local move = Move()

    ------------------------------------------
    --  Take commander chair/hive if we are not
    ------------------------------------------
    if stationClass and not self:GetIsPlayerCommanding() and not team:GetHasCommander() then

        Print("trying to log %s into %s", player:GetName(), stationClass)

        -- Log into any com station
        for _, station in ientitylist(Shared.GetEntitiesWithClassname( stationClass )) do

            station:LoginPlayer(player)
            break
            
        end

    else

        -- Brain will modify move.commands
        self:_LazilyInitBrain()
        if self.brain and GetGamerules():GetGameStarted() then
            self.brain:Update(self,  move)
        else
            -- must be waiting to join a team and game to start
        end

    end

    return move

end
