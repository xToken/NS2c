// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//    
// lua\TeamMessenger.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Adding messages for Abilities/Chambers lost/gained, and removed Power notifications
//Changed Hive Health messages to only go to aliens, and added Hive in Danger notification.

kTeamMessageTypes = enum({ 'GameStarted', 'PowerLost', 'PowerRestored', 'Eject', 'CannotSpawn',
                           'SpawningWait', 'Spawning', 'ResearchComplete', 'ResearchLost', 'AbilityUnlocked', 'AbilityLost',
                           'HiveConstructed', 'HiveLowHealth', 'HiveKilled',
                           'CommandStationUnderAttack', 'IPUnderAttack', 'HiveUnderAttack', 'HiveInDanger',
                           'PowerPointUnderAttack', 'Beacon', 'NoCommander', 'TeamsUnbalanced',
                           'TeamsBalanced', 'GameStartCommanders', 'WarmUpActive', 'ReturnToBase', 'UnassignedHive', 'CombatDefaultWinner', 'CombatDefaultLoser' })

local kTeamMessages = { }

kTeamMessages[kTeamMessageTypes.GameStarted] = { text = { [kMarineTeamType] = "MARINE_TEAM_GAME_STARTED", [kAlienTeamType] = "ALIEN_TEAM_GAME_STARTED" } }

-- This function will generate the string to display based on a location Id.
local locationStringGen = function(locationId, messageString) return string.format(Locale.ResolveString(messageString), Shared.GetString(locationId)) end

-- Thos function will generate the string to display based on a research Id.
local researchStringGen = function(researchId, messageString) return string.format(Locale.ResolveString(messageString), GetDisplayNameForTechId(researchId)) end

// This function will generate the string to display based on a time.
local timeStringGen =   function(time, messageString)
                            local minutes = math.floor( time / 60 )
                            local seconds = math.floor( time - minutes * 60 )
                            local s = ToString(minutes) .. " Minutes"
                            if minutes == 1 then
                                s = ToString(minutes) .. " Minute"
                            elseif minutes == 0 then
                                s = ToString(seconds) .. " Seconds"
                            end
                            return string.format(Locale.ResolveString(messageString), s) 
                        end

kTeamMessages[kTeamMessageTypes.Eject] = { text = { [kMarineTeamType] = "COMM_EJECT", [kAlienTeamType] = "COMM_EJECT" } }

kTeamMessages[kTeamMessageTypes.CannotSpawn] = { text = { [kMarineTeamType] = "NO_IPS" } }

kTeamMessages[kTeamMessageTypes.SpawningWait] = { text = { [kAlienTeamType] = "WAITING_TO_SPAWN" } }

kTeamMessages[kTeamMessageTypes.Spawning] = { text = { [kMarineTeamType] = "SPAWNING", [kAlienTeamType] = "SPAWNING" } }

kTeamMessages[kTeamMessageTypes.ResearchComplete] = { text = { [kAlienTeamType] = function(data) return researchStringGen(data, "EVOLUTION_AVAILABLE") end } }

kTeamMessages[kTeamMessageTypes.ResearchLost] = { text = { [kAlienTeamType] = function(data) return researchStringGen(data, "EVOLUTION_LOST") end } }

kTeamMessages[kTeamMessageTypes.AbilityUnlocked] = { text = { [kAlienTeamType] = function(data) return researchStringGen(data, "ABILITY_AVAILABLE") end } }

kTeamMessages[kTeamMessageTypes.AbilityLost] = { text = { [kAlienTeamType] = function(data) return researchStringGen(data, "ABILITY_LOST") end } }

kTeamMessages[kTeamMessageTypes.HiveConstructed] = { text = { [kAlienTeamType] = function(data) return locationStringGen(data, "HIVE_CONSTRUCTED") end } }

kTeamMessages[kTeamMessageTypes.HiveLowHealth] = { text = { [kAlienTeamType] = function(data) return locationStringGen(data, "HIVE_LOW_HEALTH") end } }

kTeamMessages[kTeamMessageTypes.HiveKilled] = { text = { [kAlienTeamType] = function(data) return locationStringGen(data, "HIVE_KILLED") end } }

kTeamMessages[kTeamMessageTypes.CommandStationUnderAttack] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "COMM_STATION_UNDER_ATTACK") end } }

kTeamMessages[kTeamMessageTypes.IPUnderAttack] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "IP_UNDER_ATTACK") end } }

kTeamMessages[kTeamMessageTypes.HiveUnderAttack] = { text = { [kAlienTeamType] = function(data) return locationStringGen(data, "HIVE_UNDER_ATTACK") end } }

kTeamMessages[kTeamMessageTypes.HiveInDanger] = { text = { [kAlienTeamType] = function(data) return locationStringGen(data, "HIVE_IN_DANGER") end } }

kTeamMessages[kTeamMessageTypes.Beacon] = { text = { [kMarineTeamType] = function(data) return locationStringGen(data, "BEACON_TO") end } }

kTeamMessages[kTeamMessageTypes.NoCommander] = { text = { [kMarineTeamType] = "NO_COMM", [kAlienTeamType] = "NO_GORGE" } }

kTeamMessages[kTeamMessageTypes.TeamsUnbalanced] = { text = { [kMarineTeamType] = "TEAMS_UNBALANCED", [kAlienTeamType] = "TEAMS_UNBALANCED" } }

kTeamMessages[kTeamMessageTypes.TeamsBalanced] = { text = { [kMarineTeamType] = "TEAMS_BALANCED", [kAlienTeamType] = "TEAMS_BALANCED" } }

kTeamMessages[kTeamMessageTypes.GameStartCommanders] = { text = { [kMarineTeamType] = "GAME_START_COMMANDERS", [kAlienTeamType] = "GAME_START_COMMANDERS" } }

kTeamMessages[kTeamMessageTypes.UnassignedHive] = { text = { [kAlienTeamType] = "UNASSIGNED_HIVES" } }

local genericStringGen = function(param, messageString) return string.format(Locale.ResolveString(messageString), param) end
kTeamMessages[kTeamMessageTypes.WarmUpActive] = { text = { [kMarineTeamType] = function(data) return genericStringGen(data, "WARMUP_ACTIVE") end ,
                                                            [kAlienTeamType] = function(data) return genericStringGen(data, "WARMUP_ACTIVE") end  } }

kTeamMessages[kTeamMessageTypes.ReturnToBase] = { text = { [kMarineTeamType] = "RETURN_TO_BASE", [kAlienTeamType] = "RETURN_TO_BASE" } }


kTeamMessages[kTeamMessageTypes.CombatDefaultWinner] =  { 
                                                            text = {
                                                                        [kMarineTeamType] = function(data) return timeStringGen(data, "COMBAT_DEFAULT_WINNER") end, 
                                                                        [kAlienTeamType] = function(data) return timeStringGen(data, "COMBAT_DEFAULT_WINNER") end 
                                                                    } 
                                                        }

kTeamMessages[kTeamMessageTypes.CombatDefaultLoser] =   { 
                                                            text = {
                                                                        [kMarineTeamType] = function(data) return timeStringGen(data, "COMBAT_DEFAULT_LOSER") end, 
                                                                        [kAlienTeamType] = function(data) return timeStringGen(data, "COMBAT_DEFAULT_LOSER") end 
                                                                    } 
                                                        }

// Silly name but it fits the convention.
local kTeamMessageMessage =
{
    type = "enum kTeamMessageTypes",
    data = "integer"
}

Shared.RegisterNetworkMessage("TeamMessage", kTeamMessageMessage)

if Server then

    --
    -- Sends every team the passed in message for display.
    --
    function SendGlobalMessage(messageType, optionalData)
    
        if GetGamerules():GetGameStarted() then
        
            local teams = GetGamerules():GetTeams()
            for t = 1, #teams do
                SendTeamMessage(teams[t], messageType, optionalData)
            end
            
        end
        
    end
    
    --
    -- Sends every player on the passed in team the passed in message for display.
    --
    function SendTeamMessage(team, messageType, optionalData)
    
        local function SendToPlayer(player)
            Server.SendNetworkMessage(player, "TeamMessage", { type = messageType, data = optionalData or 0 }, true)
        end
        
        team:ForEachPlayer(SendToPlayer)
        
    end
    
    --
    -- Sends the passed in message to the players passed in.
    --
    function SendPlayersMessage(playerList, messageType, optionalData)
    
        if GetGamerules():GetGameStarted() then
        
            for p = 1, #playerList do
                Server.SendNetworkMessage(playerList[p], "TeamMessage", { type = messageType, data = optionalData or 0 }, true)
            end
            
        end
        
    end
    
    local function TestTeamMessage(client)
    
        local player = client:GetControllingPlayer()
        if player then
            SendPlayersMessage({ player }, kTeamMessageTypes.NoCommander)
        end
        
    end
    
    Event.Hook("Console_ttm", TestTeamMessage)
    
end

if Client then

    local function SetTeamMessage(messageType, messageData)
    
        local player = Client.GetLocalPlayer()
        if player and HasMixin(player, "TeamMessage") then
        
			if Client.GetOptionInteger("hudmode", kHUDMode.Full) == kHUDMode.Full then
	            
				local displayText = kTeamMessages[messageType].text[player:GetTeamType()]
	            
	            if displayText then
	            
	                if type(displayText) == "function" then
	                    displayText = displayText(messageData)
	                else
	                    displayText = Locale.ResolveString(displayText)
	                end
	                if messageType == kTeamMessageTypes.UnassignedHive then
	                    displayText = string.format(displayText, BindingsUI_GetInputValue("RequestMenu"))
	                end
	                
	                assert(type(displayText) == "string")
	                player:SetTeamMessage(string.UTF8Upper(displayText))

	            end
            end
            
        end
        
    end
    
    function OnCommandTeamMessage(message)
        SetTeamMessage(message.type, message.data)
    end
    
    Client.HookNetworkMessage("TeamMessage", OnCommandTeamMessage)
    
end