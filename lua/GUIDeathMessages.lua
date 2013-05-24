// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIDeathMessages.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages messages displayed when something kills something else.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIDeathMessages' (GUIScript)

local kBackgroundHeight = 32
local kBackgroundColor = Color(0, 0, 0, 0)
local kFontNames = { marine = "fonts/AgencyFB_small.fnt", alien = "fonts/AgencyFB_small.fnt" }
local kScreenOffset = 40

local kSustainTime = 4
local kPlayerSustainTime = 4
local kFadeOutTime = 1

function GUIDeathMessages:Initialize()

    self.messages = { }
    self.reuseMessages = { }
    
end

function GUIDeathMessages:Uninitialize()

    for i, message in ipairs(self.messages) do
        GUI.DestroyItem(message["Background"])
    end
    self.messages = nil
    
    for i, message in ipairs(self.reuseMessages) do
        GUI.DestroyItem(message["Background"])
    end
    self.reuseMessages = nil
    
end

function GUIDeathMessages:Update(deltaTime)

    PROFILE("GUIDeathMessages:Update")
    
    local addDeathMessages = DeathMsgUI_GetMessages()
    local numberElementsPerMessage = 6 // FIXME - pretty error prone
    local numberMessages = table.count(addDeathMessages) / numberElementsPerMessage
    local currentIndex = 1
    while numberMessages > 0 do
    
        local killerColor = addDeathMessages[currentIndex]
        local killerName = addDeathMessages[currentIndex + 1]
        local targetColor = addDeathMessages[currentIndex + 2]
        local targetName = addDeathMessages[currentIndex + 3]
        local iconIndex = addDeathMessages[currentIndex + 4]
        local targetIsPlayer = addDeathMessages[currentIndex + 5]
        self:AddMessage(killerColor, killerName, targetColor, targetName, iconIndex, targetIsPlayer)
        currentIndex = currentIndex + numberElementsPerMessage
        numberMessages = numberMessages - 1
        
    end
    
    local removeMessages = { }
    // Update existing messages.
    for i, message in ipairs(self.messages) do
    
        local currentPosition = Vector(message["Background"]:GetPosition())
        currentPosition.y = GUIScale(kScreenOffset + ConditionalValue(PlayerUI_IsOnMarineTeam(), 0, 400)) + (kBackgroundHeight * (i - 1))
        local playerIsCommander = CommanderUI_IsLocalPlayerCommander()
        currentPosition.x = message["BackgroundXOffset"] - ((playerIsCommander and message["BackgroundWidth"]) or 0)
        message["Background"]:SetPosition(currentPosition)
        message["Time"] = message["Time"] + deltaTime
        if message["Time"] >= message.sustainTime then
        
            local fadeFraction = (message["Time"]-message.sustainTime) / kFadeOutTime
            local alpha = Clamp( 1-fadeFraction, 0, 1 )
            local currentColor = message["Killer"]:GetColor()
            currentColor.a = alpha
            message["Killer"]:SetColor(currentColor)
            currentColor = message["Weapon"]:GetColor()
            currentColor.a = alpha
            message["Weapon"]:SetColor(currentColor)
            currentColor = message["Target"]:GetColor()
            currentColor.a = alpha
            message["Target"]:SetColor(currentColor)
            
            if fadeFraction > 1.0 then
                table.insert(removeMessages, message)
            end
            
        end
        
    end
    
    // Remove faded out messages.
    for i, removeMessage in ipairs(removeMessages) do
    
        removeMessage["Background"]:SetIsVisible(false)
        table.insert(self.reuseMessages, removeMessage)
        table.removevalue(self.messages, removeMessage)
        
    end
    
end

function GUIDeathMessages:AddMessage(killerColor, killerName, targetColor, targetName, iconIndex, targetIsPlayer)

    local style = PlayerUI_IsOnMarineTeam() and "marine" or "alien"
    local xOffset = DeathMsgUI_GetTechOffsetX(0)
    local yOffset = DeathMsgUI_GetTechOffsetY(iconIndex)
    local iconWidth = DeathMsgUI_GetTechWidth(0)
    local iconHeight = DeathMsgUI_GetTechHeight(0)
    
    local insertMessage = { Background = nil, Killer = nil, Weapon = nil, Target = nil, Time = 0 }
    
    // Check if we can reuse an existing message.
    if table.count(self.reuseMessages) > 0 then
    
        insertMessage = self.reuseMessages[1]
        insertMessage["Time"] = 0
        insertMessage["Background"]:SetIsVisible(true)
        table.remove(self.reuseMessages, 1)
        
    end
    
    if insertMessage["Killer"] == nil then
        insertMessage["Killer"] = GUIManager:CreateTextItem()
    end
    
    insertMessage["Killer"]:SetFontName(kFontNames[style])
    insertMessage["Killer"]:SetAnchor(GUIItem.Left, GUIItem.Center)
    insertMessage["Killer"]:SetTextAlignmentX(GUIItem.Align_Max)
    insertMessage["Killer"]:SetTextAlignmentY(GUIItem.Align_Center)
    insertMessage["Killer"]:SetColor(ColorIntToColor(killerColor))
    insertMessage["Killer"]:SetText(killerName)
    
    if insertMessage["Weapon"] == nil then
        insertMessage["Weapon"] = GUIManager:CreateGraphicItem()
    end
    
    insertMessage["Weapon"]:SetSize(Vector(GUIScale(iconWidth), GUIScale(iconHeight), 0))
    insertMessage["Weapon"]:SetAnchor(GUIItem.Left, GUIItem.Center)
    insertMessage["Weapon"]:SetTexture(kInventoryIconsTexture)
    insertMessage["Weapon"]:SetTexturePixelCoordinates(xOffset, yOffset, xOffset + iconWidth, yOffset + iconHeight)
    insertMessage["Weapon"]:SetColor(Color(1, 1, 1, 1))
    
    if insertMessage["Target"] == nil then
        insertMessage["Target"] = GUIManager:CreateTextItem()
    end
    
    insertMessage["Target"]:SetFontName(kFontNames[style])
    insertMessage["Target"]:SetAnchor(GUIItem.Right, GUIItem.Center)
    insertMessage["Target"]:SetTextAlignmentX(GUIItem.Align_Min)
    insertMessage["Target"]:SetTextAlignmentY(GUIItem.Align_Center)
    insertMessage["Target"]:SetColor(ColorIntToColor(targetColor))
    insertMessage["Target"]:SetText(targetName)
    
    local killerTextWidth = insertMessage["Killer"]:GetTextWidth(killerName)
    local targetTextWidth = insertMessage["Target"]:GetTextWidth(targetName)
    local textWidth = killerTextWidth + targetTextWidth
    
    insertMessage["Weapon"]:SetPosition(Vector(textWidth / 2 , -GUIScale(iconHeight) / 2, 0))
    
    if insertMessage["Background"] == nil then
    
        insertMessage["Background"] = GUIManager:CreateGraphicItem()
        insertMessage["Weapon"]:AddChild(insertMessage["Killer"])
        insertMessage["Background"]:AddChild(insertMessage["Weapon"])
        insertMessage["Weapon"]:AddChild(insertMessage["Target"])
        
    end
    
    insertMessage["BackgroundWidth"] = textWidth + GUIScale(iconWidth)
    insertMessage["Background"]:SetSize(Vector(insertMessage["BackgroundWidth"], kBackgroundHeight, 0))
    insertMessage["Background"]:SetAnchor(GUIItem.Right, GUIItem.Top)
    insertMessage["BackgroundXOffset"] = -textWidth - iconWidth - GUIScale(kScreenOffset)
    insertMessage["Background"]:SetPosition(Vector(insertMessage["BackgroundXOffset"], 0, 0))
    insertMessage["Background"]:SetColor(kBackgroundColor)
    insertMessage.sustainTime = ConditionalValue( targetIsPlayer==1, kPlayerSustainTime, kSustainTime )
    
    table.insert(self.messages, insertMessage)
    
end