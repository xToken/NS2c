// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\InsightNetworkMessages_Client.lua
//
// Created by: Jon Hughes (jon@jhuze.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function OnCommandHealth(healthTable)

    Insight_SetPlayerHealth(healthTable.clientIndex, healthTable.health, healthTable.maxHealth, healthTable.armor, healthTable.maxArmor)

end

Client.HookNetworkMessage("Health", OnCommandHealth)

function OnCommandTechPoints(techPointsTable)

    Insight_SetTechPoint(techPointsTable.entityIndex, techPointsTable.teamNumber, techPointsTable.techId,
        techPointsTable.builtFraction, techPointsTable.location,
        techPointsTable.health, techPointsTable.maxHealth, techPointsTable.armor, techPointsTable.maxArmor)

end

Client.HookNetworkMessage("TechPoints", OnCommandTechPoints)


function OnCommandRecycle(recycleTable)

    if recycleTable.techId == kTechId.Extractor then
        DeathMsgUI_AddRtsLost(kTeam1Index, 1)
    end

    DeathMsgUI_AddResLost(kTeam1Index, recycleTable.resLost)
    DeathMsgUI_AddResRecovered(recycleTable.resGained)

end

Client.HookNetworkMessage("Recycle", OnCommandRecycle)


function OnCommandReset()

    DeathMsgUI_ResetStats()
    
    local player = Client.GetLocalPlayer()
    
    if player and player.guiSpectator and player.guiSpectator.guiTech then
    
        for i, techId in ipairs(GUIInsight_Tech.kRelevantTechIdsMarine) do

            local techIdString = EnumToString(kTechId, techId)
            
            player.guiSpectator.guiTech:DestroyResearchBar(techIdString)
            
            player.guiSpectator.guiTech:DestroyFlashIcon(techIdString)
            player.guiSpectator.guiTech.gAlreadyFlashed[techIdString] = nil

        end
        for i, techId in ipairs(GUIInsight_Tech.kRelevantTechIdsAlien) do

            local techIdString = EnumToString(kTechId, techId)
            
            player.guiSpectator.guiTech:DestroyResearchBar(techIdString)
            
            player.guiSpectator.guiTech:DestroyFlashIcon(techId)
            player.guiSpectator.guiTech.gAlreadyFlashed[techIdString] = nil

        end
        
        player.guiSpectator.guiTech.gUpgradeIcons["Armor1"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.Armor1, true)))
        player.guiSpectator.guiTech.gUpgradeIcons["Weapons1"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.Weapons1, true)))
        
        player.guiSpectator.guiTech.gUpgradeIcons["Leap"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.Leap, false)))
        player.guiSpectator.guiTech.gUpgradeIcons["BileBomb"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.BileBomb, false)))
        player.guiSpectator.guiTech.gUpgradeIcons["Umbra"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.Umbra, false)))
        player.guiSpectator.guiTech.gUpgradeIcons["Metabolize"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.Metabolize, false)))
        player.guiSpectator.guiTech.gUpgradeIcons["Stomp"]:SetTexturePixelCoordinates(unpack(GetTextureCoordinatesForIcon(kTechId.Stomp, false)))
        
    end

end

Client.HookNetworkMessage("Reset", OnCommandReset)