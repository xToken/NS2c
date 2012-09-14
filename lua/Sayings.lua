// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Sayings.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Sayings menus and sounds.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

marineRequestSayingsText = {"1. Acknowledged", "2. Need medpack", "3. Need ammo", "4. Need orders"}
marineRequestSayingsSounds = {"sound/NS2.fev/marine/voiceovers/ack", "sound/NS2.fev/marine/voiceovers/medpack", "sound/NS2.fev/marine/voiceovers/ammo", "sound/NS2.fev/marine/voiceovers/need_orders" }
marineRequestActions = {kTechId.MarineAlertAcknowledge, kTechId.MarineAlertNeedMedpack, kTechId.MarineAlertNeedAmmo, kTechId.MarineAlertNeedOrder}

marineGroupSayingsText  = {"1. Follow me", "2. Let's move", "3. Covering you", "4. Hostiles", "5. Taunt"}
marineGroupSayingsSounds = {"sound/NS2.fev/marine/voiceovers/follow_me", "sound/NS2.fev/marine/voiceovers/lets_move", "sound/NS2.fev/marine/voiceovers/covering", "sound/NS2.fev/marine/voiceovers/hostiles", "sound/NS2.fev/marine/voiceovers/taunt"}
marineGroupRequestActions = {kTechId.None, kTechId.None, kTechId.None, kTechId.MarineAlertHostiles, kTechId.None}

alienGroupSayingsText  = {"1. Need healing", "2. Follow me", "3. Chuckle"}
alienGroupSayingsSounds = {"sound/NS2.fev/alien/voiceovers/need_healing", "sound/NS2.fev/alien/voiceovers/follow_me", "sound/NS2.fev/alien/voiceovers/chuckle"}
alienRequestActions = {kTechId.AlienAlertNeedHealing, kTechId.None, kTechId.None}
alienBlipTypes = {kBlipType.NeedHealing, kBlipType.FollowMe, kBlipType.Chuckle}

function GetHUDTextForBlipType(blipType)

    local text = ""
    
    // Custom blip text
    if blipType == kBlipType.NeedHealing then
        text = "needs healing"
    elseif blipType == kBlipType.FollowMe then
        text = "wants you to follow"
    elseif blipType == kBlipType.Chuckle then
        text = "chuckles"
    // Regular blip status
    elseif blipType == kBlipType.FriendlyUnderAttack then
        text = "under attack"
    end
    
    return text
    
end

// Populate dynamically via ScoreboardUI_GetOrderedCommanderNames() (for voting down commander)
voteActionsText = {}
voteActionsSounds = {}
voteActionsActions = {kTechId.VoteDownCommander1, kTechId.VoteDownCommander2, kTechId.VoteDownCommander3}

function GetVoteActionsText(teamNumber)

    voteActionsText = {}
    
    if teamNumber == kTeam2Index then
        local techTree = GetTechTree()
        if Server then
            techTree = player:GetTeam():GetTechTree()
        end
        if player ~= nil or techTree ~= nil then
            local cragNode = techTree:GetTechNode(kTechId.Crag)
            local shiftNode = techTree:GetTechNode(kTechId.Shift)
            local shadeNode = techTree:GetTechNode(kTechId.Shade)
            if cragNode ~= nil then
                if cragNode:GetAvailable() then
                    table.insert(voteActionsText, "Already have Crag.")
                else
                    table.insert(voteActionsText, "Vote for Crag.")
                end
            else
                table.insert(voteActionsText, "Vote for Crag.")
            end
            if shiftNode ~= nil then
                if shiftNode:GetAvailable() then
                    table.insert(voteActionsText, "Already have Shift.")
                else
                    table.insert(voteActionsText, "Vote for Shift.")
                end        
            else
                table.insert(voteActionsText, "Vote for Shift.")
            end
            if shadeNode ~= nil then
                if shadeNode:GetAvailable() then
                    table.insert(voteActionsText, "Already have Shade.")
                else
                    table.insert(voteActionsText, "Vote for Shade.")
                end
            else
                table.insert(voteActionsText, "Vote for Shade.")
            end
        else
            table.insert(voteActionsText, "Vote for Crag.")
            table.insert(voteActionsText, "Vote for Shift.")
            table.insert(voteActionsText, "Vote for Shade.")
        end

    else 
    
        local sortedCommanderNames = ScoreboardUI_GetOrderedCommanderNames(teamNumber)
        
        // Only support three simultaneous commanders (else need to add more VoteDownCommander enums)
        for index, commanderName in ipairs(sortedCommanderNames) do
            if table.count(voteActionsText) < 3 then
                table.insert(voteActionsText, string.format("%d. Eject commander \"%s\"", index, commanderName))
            end
        end
        
        if table.count(voteActionsText) == 0 then
            table.insert(voteActionsText, "Nothing to vote on.")
        end
    end
    
    return voteActionsText
    
end

// Precache all sayings
function precacheSayingsTable(sayings)
    for index, saying in ipairs(sayings) do
        Shared.PrecacheSound(saying)
    end
end

precacheSayingsTable(marineRequestSayingsSounds)
precacheSayingsTable(marineGroupSayingsSounds)
precacheSayingsTable(alienGroupSayingsSounds)