-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\DeathMessage_Client.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Adjusted for classic techids

local kSubImageWidth = 128
local kSubImageHeight = 64

local queuedDeathMessages = { }

local resLostMarine = 0
local resLostAlien = 0
local rtsLostMarine = 0
local rtsLostAlien = 0
local resRecovered = 0

-- Can't have multi-dimensional arrays so return potentially very long array [color, name, color, name, doerid, ....]
function DeathMsgUI_GetMessages()

    local returnArray = {}
    -- local arrayIndex = 1
    
    -- return list of recent death messages
    for _, deathMsg in ipairs(queuedDeathMessages) do
    
        for _, element in ipairs(deathMsg) do
            table.insert(returnArray, element)
        end
        
    end
    
    -- Clear current death messages
    table.clear(queuedDeathMessages)
    
    return returnArray
    
end

function DeathMsgUI_MenuImage()
    return "death_messages"
end

function DeathMsgUI_GetTechOffsetX(_)
    return 0
end

function DeathMsgUI_GetTechOffsetY(iconIndex)

    if not iconIndex then
        iconIndex = 1
    end
    
    return (iconIndex - 1)*kSubImageHeight
    
end

function DeathMsgUI_GetTechWidth(_)
    return kSubImageWidth
end

function DeathMsgUI_GetTechHeight(_)
    return kSubImageHeight
end

-- Pass 1 for isPlayer if coming from a player (look it up from scoreboard data), otherwise it's a tech id
local function GetDeathMessageEntityName(isPlayer, clientIndex)

    local name = ""
    
    if isPlayer then
        name = Scoreboard_GetPlayerData(clientIndex, "Name")
    elseif clientIndex ~= -1 then
        name = GetDisplayNameForTechId(clientIndex)
    end
    
    return name or ""
    
end

-- Stored the name of the last killer.
local gKillerName
local gKillerWeaponIconIndex = kDeathMessageIcon.None

-- The killer name will clear when this is called.
function GetKillerNameAndWeaponIcon()

    local killerName = gKillerName
    gKillerName = nil
    return killerName, gKillerWeaponIconIndex
    
end

function DeathMsgUI_GetResLost(teamNumber)

    if teamNumber == kTeam1Index then

        return resLostMarine

    elseif teamNumber == kTeam2Index then

        return resLostAlien

    end

    return nil

end

function DeathMsgUI_GetRtsLost(teamNumber)

    if teamNumber == kTeam1Index then

        return rtsLostMarine

    elseif teamNumber == kTeam2Index then

        return rtsLostAlien

    end

    return nil

end

function DeathMsgUI_GetResRecovered()

    return resRecovered

end

function DeathMsgUI_ResetStats()

    resLostMarine = 0
    resLostAlien = 0
    rtsLostMarine = 0
    rtsLostAlien = 0
    resRecovered = 0
    
end

function DeathMsgUI_AddResLost(teamNumber, res)

    if teamNumber == kTeam1Index then
        resLostMarine = resLostMarine + res
    elseif teamNumber == kTeam2Index then
        resLostAlien = resLostAlien + res
    end

end

function DeathMsgUI_AddRtsLost(teamNumber, rts)

    if teamNumber == kTeam1Index then
        rtsLostMarine = rtsLostMarine + rts
    elseif teamNumber == kTeam2Index then
        rtsLostAlien = rtsLostAlien + rts
    end

end

function DeathMsgUI_AddResRecovered(amount)

    resRecovered = resRecovered + amount

end

local function AddDeathMessage(killerIsPlayer, killerIndex, killerTeamNumber, iconIndex, targetIsPlayer, targetIndex, targetTeamNumber)

    local killerName = GetDeathMessageEntityName(killerIsPlayer, killerIndex)
    local targetName = GetDeathMessageEntityName(targetIsPlayer, targetIndex)
    
    Print("%s killed %s with %s", killerName, targetName, EnumToString(kDeathMessageIcon, iconIndex))
    
    if targetIsPlayer ~= 1 then
    
        if targetTeamNumber == kTeam1Index then
        
            local techIdString = string.gsub(targetName, "%s+", "")
            local techId = StringToEnum(kTechId, techIdString)
            local resOverride = false
            
            if techIdString == "AdvancedArmory" then
                resOverride = kArmoryCost + kAdvancedArmoryUpgradeCost
            elseif techIdString == "AdvancedTurretFactory" then
                resOverride = kTurretFactoryCost + kUpgradeTurretFactoryCost
            end
            
            local amount = resOverride or LookupTechData(techId, kTechDataCostKey, 0)
            
            DeathMsgUI_AddResLost(kTeam1Index, amount)
            
            if techIdString == "Extractor" then
                DeathMsgUI_AddRtsLost(kTeam1Index, 1)
            end
            
        elseif targetTeamNumber == kTeam2Index then
        
            local techIdString = string.gsub(targetName, "%s+", "")
            local techId = StringToEnum(kTechId, techIdString)
            local resOverride = false

            if techIdString == "Egg" then

                resOverride = 0

            elseif techIdString == "CragHive" or techIdString == "ShadeHive" or techIdString == "ShiftHive" or techIdString == "WhipHive" then
                resOverride = kHiveCost
            end
            
            -- Change to only add cost if TRes, gonna add exceptions manually for now -DGH
            local amount = (resOverride or LookupTechData(techId, kTechDataCostKey, 0))
            
            DeathMsgUI_AddResLost(kTeam2Index, amount)
            
            if techIdString == "Harvester" then
                DeathMsgUI_AddRtsLost(kTeam2Index, 1)
            end
            
        end
        
    end
    
    local killedSelf = killerIsPlayer and targetIsPlayer and killerIndex == targetIndex
    
    local deathMessage = { GetColorForTeamNumber(killerTeamNumber), killerName, GetColorForTeamNumber(targetTeamNumber), killedSelf and "" or targetName, iconIndex, targetIsPlayer }
    table.insert(queuedDeathMessages, deathMessage)
    
    local player = Client.GetLocalPlayer()
    if player and player:GetName() == targetName then
    
        gKillerName = killedSelf and "" or killerName
        gKillerWeaponIconIndex = iconIndex
        
    end
    
end

local function OnDeathMessage(message)
    AddDeathMessage(message.killerIsPlayer, message.killerId, message.killerTeamNumber, message.iconIndex, message.targetIsPlayer, message.targetId, message.targetTeamNumber)
end
Client.HookNetworkMessage("DeathMessage", OnDeathMessage)