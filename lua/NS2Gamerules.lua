//Dragon
// This file now only exists to support multiple gamerules

Script.Load("lua/Gamerules.lua")
Script.Load("lua/dkjson.lua")
Script.Load("lua/ServerSponitor.lua")
Script.Load("lua/PlayerRanking.lua")
Script.Load("lua/NS2cGamerules.lua")
Script.Load("lua/NS2rGamerules.lua")

local ns2gamerulesmapname = "ns2_gamerules"
local mapMode

if Shared.GetMapName():find("_co_") then
    mapMode = kGameMode.Combat
else
    mapMode = kGameMode.Classic
end

function DefaultNS2GamerulesMapName()
    return ns2gamerulesmapname
end

function IsNS2GamerulesEntity(mapName)
    return mapName == ns2gamerulesmapname
end

function DetermineAndCreateNS2Gamerules(values)
    
    if mapMode == kGameMode.Combat then
        return Server.CreateEntity("ns2c_gamerules", values)
    else
        return Server.CreateEntity("ns2r_gamerules", values)
    end
end

function CheckNS2GameMode()
    return mapMode
end