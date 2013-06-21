// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ConsoleCommands_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// General purpose console commands (not game rules specific).
//
// ========= For more information, visit us at http://www.unknownworlds.com =======================

//NS2c
//Added timed callback to kill

function OnCommandSay(client, ...)

    if client == nil then
    
        local chatMessage = StringConcatArgs(...)
        chatMessage = string.sub(chatMessage, 1, kMaxChatLength)
        if string.len(chatMessage) > 0 then
        
            Server.SendNetworkMessage("Chat", BuildChatMessage(false, "Admin", -1, kTeamReadyRoom, kNeutralTeamType, chatMessage), true)
            Shared.Message("Chat All - Admin: " .. chatMessage)
            Server.AddChatToHistory(chatMessage, "Admin", 0, kTeamReadyRoom, false)
            
        end
        
    end
    
end

function OnCommandKill(client)

    if client ~= nil then
    
        local player = client:GetControllingPlayer()
        
        if player ~= nil and (not client.timeLastKillCommand or client.timeLastKillCommand + kKillDelay < Shared.GetTime()) then
        
            local function OnKillPlayer(self)
                if HasMixin(self, "Live") and self:GetCanDie() and self:GetCanSuicide() then
                    self:Kill(nil, nil, self:GetOrigin())
                end
            end
			client.timeLastKillCommand = Shared.GetTime()
            player:AddTimedCallback(OnKillPlayer, kKillDelay)
            Server.SendNetworkMessage(client, "Chat", BuildChatMessage(false, "Notification", -1, kTeamReadyRoom, kNeutralTeamType, "You will sucide in 3 seconds."), true)
        end
        
    end
    
end

local function OnCommandKillAll(client, className)

    if Shared.GetCheatsEnabled() then
    
        for _, entity in ientitylist(Shared.GetEntitiesWithClassname(className)) do
        
            if HasMixin(entity, "Live") and entity:GetCanDie() then
                entity:Kill()
            end
            
        end
        
    end
    
end

local function OnCommandKillNearby(client, className, distance)

    if Shared.GetCheatsEnabled() then
    
        distance = distance and tonumber(distance) or 15
        local player = client:GetControllingPlayer()
        for _, entity in ientitylist(Shared.GetEntitiesWithClassname(className)) do
        
            if HasMixin(entity, "Live") and entity:GetCanDie() and player and entity:GetDistance(player) <= distance then
                entity:Kill()
            end
            
        end
        
    end
    
end

function OnCommandClearOrders(client)

    if client ~= nil and Shared.GetCheatsEnabled() then
        local player = client:GetControllingPlayer()
        if player then
            player:ClearOrders()
        end
    end

end

function OnCommandDarwinMode(client)

    if client ~= nil and Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player then
            player:SetDarwinMode(not player:GetDarwinMode())
            Print("Darwin mode on player now %s", ToString(player:GetDarwinMode()))
        end
        
    end
    
end

function OnCommandRoundReset(client)

    if client == nil or Shared.GetCheatsEnabled() then
        GetGamerules():ResetGame()
    end
    
end

function OnCommandEffectDebug(client, className)

    if Shared.GetDevMode() then
    
        local player = client:GetControllingPlayer()
        
        if className and className ~= "" then
        
            gEffectDebugClass = className
            Server.SendCommand(player, string.format("oneffectdebug %s", className))
            Print("effect_debug enabled for \"%s\" objects.", className)
            
        elseif gEffectDebugClass ~= nil then
        
            gEffectDebugClass = nil
            Server.SendCommand(player, "oneffectdebug")
            Print("effect_debug disabled.")
                
        else
        
            // Turn on debug of everything
            gEffectDebugClass = ""
            Server.SendCommand(player, "oneffectdebug")
            Print("effect_debug enabled.")
            
        end                

    else
        Print("effect_debug <class name> (dev mode must be enabled)")
    end
    
end

local function OnCommandWarp(client, x, y, z)

    if client ~= nil and Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        player:SetOrigin(Vector(tonumber(x), tonumber(y), tonumber(z)))
        
    end
    
end

local function OnCommandFindRef(client, className)

    if client == nil or Shared.GetCheatsEnabled() then
    
        if className ~= nil then
            Debug.FindTypeReferences(className)        
        end
        
    end
    
end

local function OnCommandDebugPathing(client, param)
    if Shared.GetCheatsEnabled() then
        local enable = param == "true"
        
        if enable ~= gDebugPathing then
            gDebugPathing = enable
            if enable then
                Print("debug pathing enabled")
            else
                Print("debug pathing disabled")
            end
        end

    end
end

local function OnCommandListPlayers(client)

    if client == nil or Shared.GetCheatsEnabled() then
    
        Shared.Message("Player List -")
        
        for _, player in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
        
            local playerClient = Server.GetOwner(player)
            local playerAddressString = IPAddressToString(Server.GetClientAddress(playerClient))
            Shared.Message(player:GetName() .. " : " .. playerClient:GetUserId() .. " : " .. playerAddressString)
            
        end
        
    end
    
end

local function OnCommandKick(client, steamId)

    // Only allowed from the dedicated server.
    if client == nil then
    
        local found = nil
        for list, victim in ientitylist(Shared.GetEntitiesWithClassname("Player")) do
        
            if Server.GetOwner(victim):GetUserId() == tonumber(steamId) and Server.GetOwner(victim):GetIsVirtual() == false then
            
                found = victim
                break
                
            end
            
        end
        
        if found ~= nil then
        
            local foundClient = Server.GetOwner(found)
            Shared.Message(string.format("%s kicked from the server", found:GetName()))
            Server.DisconnectClient(foundClient)
            
        else
            Shared.Message("Failed to find client matching Id")
        end
    
    end
    
end

local ToWatch

local function ToWatch_Table(value, indent)

    local spaces = string.rep(" ", indent * 4)
    local result = "{\n"
    for k, v in pairs(value) do
        result = result .. string.rep(" ", (indent + 1) * 4) .. k .. " = " .. ToWatch(v, indent + 1) .. "\n"
    end
    return result .. spaces .. "}"
end

function ToWatch(value, indent)

    indent = indent or 0
    
    local mt = getmetatable(value)
    if mt and type(mt.__towatch) == "function" then
        local class, members = mt.__towatch(value)
        return class .. " " .. ToWatch_Table(members, indent)
    else
        if type(value) == "table" then
            return ToWatch_Table(value, indent)
        else
            return tostring(value)
        end
    end

end

// Executes a line of script code
local function OnCommandBang(client, ...)
    if client == nil or Shared.GetCheatsEnabled() then
        // The command line parser tokenizes the command, so glue the pieces
        // back together
        local command = ""
        for i, p in ipairs({...}) do
            command = command .. " " .. p
        end
        local result, error = loadstring("return " .. command)
        if result then
            local results = { pcall(result) }
            if results[1] == false then
                Shared.Message("error")
            end
            if #results > 1 then
                Shared.Message("! " .. command .. " = ")
                for i = 2, #results do
                    local result = results[i]
                    Shared.Message( ToWatch(result) )
                end
            end
        else
            Shared.Message(error)
        end    
    end

end

// Generic console commands
Event.Hook("Console_say", OnCommandSay)
Event.Hook("Console_kill", OnCommandKill)
Event.Hook("Console_killall", OnCommandKillAll)
Event.Hook("Console_killnearby", OnCommandKillNearby)
Event.Hook("Console_clearorders", OnCommandClearOrders)
Event.Hook("Console_darwinmode", OnCommandDarwinMode)
Event.Hook("Console_reset", OnCommandRoundReset)
Event.Hook("Console_effect_debug", OnCommandEffectDebug)
Event.Hook("Console_warp", OnCommandWarp)
Event.Hook("Console_gotolocation", OnCommandWarp)
Event.Hook("Console_sfindref", OnCommandFindRef)
Event.Hook("Console_debugpath", OnCommandDebugPathing)
Event.Hook("Console_list_players", OnCommandListPlayers)
Event.Hook("Console_status", OnCommandListPlayers)
Event.Hook("Console_kick", OnCommandKick)
Event.Hook("Console_!", OnCommandBang)