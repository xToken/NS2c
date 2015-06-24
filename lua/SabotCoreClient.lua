// ======= Copyright (c) 2003-2014, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\SabotCoreClient.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================   

Script.Load("lua/Utility.lua")
Script.Load("lua/Sabot.lua")

//Load Classic Main Menu Changes - this file is unlikely to change much
Script.Load("lua/menu/GUIAdjustments.lua")
Script.Load("lua/menu/GUIClassicMenu.lua")
 
local gLastUpdate = 0

local kPollTimeOut = 60
local kPollFrequency = 0.1

local function UpdateGatherQueue()

    if Sabot.GetIsInGather() then
    
        if gLastUpdate + 5 < Shared.GetTime() then

            Sabot.UpdateRoom()
            gLastUpdate = Shared.GetTime()

            if Sabot.GetGatherStatus() == kGatherStatus.Connecting then
                
                local serverAddress = Sabot.GetServerAddress()
                
                if serverAddress then
                
                    Sabot.SetGatherId(-1)
                    Client.Connect(serverAddress, Sabot.GetServerPassword())
                    
                end
            
            end

        end
    
    end

end

Event.Hook("UpdateClient", UpdateGatherQueue)

local kWebViewFunctions = {}

kWebViewFunctions["GetPlayerName"] = function()
    return Client.GetOptionString(kNicknameOptionsKey, Client.GetUserName()) or kDefaultPlayerName
end

kWebViewFunctions["GetSteamId"] = function()
    return Client.GetSteamId()
end

kWebViewFunctions["SetGatherId"] = function(gatherId)
    Sabot.SetGatherId(gatherId)
end

kWebViewFunctions["JoinServer"] = function(serverIp, serverPort, serverPassword)
    Sabot.SetGatherId(-1)
    Client.Connect(ToString(serverIp) .. ":" .. ToString(serverPort), serverPassword)
end

kWebViewFunctions["SetGatherPassword"] = function(password)
    Sabot.SetGatherPassword(password)
end

local function OnWebViewCall(...)

    local functionName = select(1, ...)
    if functionName then
    
        if kWebViewFunctions[functionName] then
    
            local params = {}
            for i = 2, select('#', ...) do
            
                local param = select(i, ...)
                if not param then
                    error(string.format("%s argument nr. %d is not valid", functionName, i-1))
                end
         
                table.insert(params, param)
                
            end
            
            return kWebViewFunctions[functionName](unpack(params))
        
        else
            error(string.format("%s is not implemented.", functionName))
        end
        
    else
        error("Spark.DispatchToClient called without parameters.")
    end
    
end

Event.Hook("WebViewCall", OnWebViewCall)