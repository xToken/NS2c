// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUICommanderManager.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages the other commander UIs and input for the commander UI.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUICommanderManager' (GUIScript)

local kSelectorMarineColor = Color(0.0, 0, 0.5, 0.15)
local kSelectorAlienColor = Color(0.8, 0.3, 0, 0.15)

local kLocationTextSize = 22
local kLocationTextOffset = Vector(36, 36, 0)
local kLocationTextFont = "fonts/AgencyFB_small.fnt"
local kLocationTextColor = Color(1, 1, 1, 0.5)

local function CreateSelector(self)

    self.selector = GUIManager:CreateGraphicItem()
    self.selector:SetAnchor(GUIItem.Top, GUIItem.Left)
    self.selector:SetIsVisible(false)
    
end

local function CreateLocationText(self)

    self.locationText = GUIManager:CreateTextItem()
    self.locationText:SetFontName(kLocationTextFont)
    self.locationText:SetFontSize(kLocationTextSize)
    self.locationText:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.locationText:SetTextAlignmentX(GUIItem.Align_Min)
    self.locationText:SetTextAlignmentY(GUIItem.Align_Min)
    self.locationText:SetPosition(kLocationTextOffset)
    self.locationText:SetColor(kLocationTextColor)
    self.locationText:SetText(PlayerUI_GetLocationName())
    
end

function GUICommanderManager:Initialize()

    CreateSelector(self)
    CreateLocationText(self)
    
    self.childScripts = { }
    
end

function GUICommanderManager:Uninitialize()

    self.childScripts = { }

    if self.selector then
    
        GUI.DestroyItem(self.selector)
        self.selector = nil
        
    end
    
    if self.locationText then
    
        GUI.DestroyItem(self.locationText)
        self.locationText = nil
        
    end
    
end

function GUICommanderManager:AddChildScript(childScript)
    table.insert(self.childScripts, childScript)
end

local function UpdateSelector(self)

    if self.selector then
    
        local visible = GetIsCommanderMarqueeSelectorDown()
        self.selector:SetIsVisible(visible)
        
        if visible then
        
            local info = GetCommanderMarqueeSelectorInfo()
            
            self.selector:SetPosition(Vector(info.startX, info.startY, 0))
            self.selector:SetSize(Vector(info.endX - info.startX, info.endY - info.startY, 0))
            
         	self.selector:SetColor(kSelectorMarineColor)
        end
        
    end
    
end

local function UpdateMouseOverUIState(self)

    local mouseX, mouseY = Client.GetCursorPosScreen()
    
    // Check all the clickable commander UI items owned by the manager.
    local mouseOverUI = false
    
    for i, childScript in ipairs(self.childScripts) do
    
        // Can break out if the mouse is already over the UI.
        if mouseOverUI then
            break
        end
        
        mouseOverUI = mouseOverUI or childScript:ContainsPoint(mouseX, mouseY)
        
    end
    
    CommanderUI_SetMouseIsOverUI(mouseOverUI)
    
end

function GUICommanderManager:Update(deltaTime)

    UpdateSelector(self)
    
    local locationName = PlayerUI_GetLocationName()
    if locationName then
        self.locationText:SetText(locationName)
    end
    
    UpdateMouseOverUIState(self)
    
end