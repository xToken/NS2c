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

// The number of pixels that the cursor needs to move in order
// to enable the marquee selector.
GUICommanderManager.kEnableSelectorMoveAmount = 5
GUICommanderManager.kSelectorMarineColor = Color(0.0, 0, 0.5, 0.15)
GUICommanderManager.kSelectorAlienColor = Color(0.8, 0.3, 0, 0.15)

GUICommanderManager.kLocationTextOffset = 10

function GUICommanderManager:Initialize()

    self.mouseOverUI = false
    
    self.mousePressed = { false, false }
    self.mouseDownPointX = 0
    self.mouseDownPointY = 0
    
    self.selectorCursorDown = false
    self.selectorStartX = 0
    self.selectorStartY = 0
    
    self:CreateSelector()
    
    self:CreateLocationText()
    
    self.childScripts = { }
    
    self.timeLastMouseOne = 0
    
end

function GUICommanderManager:CreateSelector()

    self.selector = GUIManager:CreateGraphicItem()
    self.selector:SetAnchor(GUIItem.Top, GUIItem.Left)
    self.selector:SetIsVisible(self.selectorCursorDown)
    
end

function GUICommanderManager:CreateLocationText()

    self.locationText = GUIManager:CreateTextItem()
    self.locationText:SetFontSize(40)
    self.locationText:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.locationText:SetTextAlignmentX(GUIItem.Align_Min)
    self.locationText:SetTextAlignmentY(GUIItem.Align_Min)
    self.locationText:SetPosition(Vector(GUICommanderManager.kLocationTextOffset, GUICommanderManager.kLocationTextOffset, 0))
    self.locationText:SetColor(Color(1, 1, 1, 0.5))
    self.locationText:SetText(PlayerUI_GetLocationName())

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

function GUICommanderManager:HandleDoubleClick(mouseX, mouseY)
    
    local timeSinceLastPress = Shared.GetTime() - self.timeLastMouseOne
    
    if timeSinceLastPress < 0.3 then
        CommanderUI_OnDoubleClick(mouseX, mouseY)
    end

end

function GUICommanderManager:SendKeyEvent(key, down)

    // Mouse cannot be down if over the UI.
    if self.mouseOverUI then
        down = false
    end
    
    local player = Client.GetLocalPlayer()
    
    local mouseX, mouseY = Client.GetCursorPosScreen()
    
    if key == InputKey.MouseButton0 and self.mousePressed[1] ~= down then
    
        self.mousePressed[1] = down
        if down then
        
            self.mouseDownPointX = mouseX
            self.mouseDownPointY = mouseY
            
            CommanderUI_OnMousePress(0, mouseX, mouseY)
            
        else
        
            if self.selectorCursorDown == true then
                self:SelectorUp(mouseX, mouseY)
            else
                CommanderUI_OnMouseRelease(0, mouseX, mouseY)
            end

            self:HandleDoubleClick(mouseX, mouseY)
            self.timeLastMouseOne = Shared.GetTime()
            
        end
        
        // Other UI script such as the GUIScoreboard may need to handle MouseButton0.
        return false
        
    elseif key == InputKey.MouseButton1 and self.mousePressed[2] ~= down then
    
        self.mousePressed[2] = down
        
        if down then
            CommanderUI_OnMousePress(1, mouseX, mouseY)
        else
            CommanderUI_OnMouseRelease(1, mouseX, mouseY)
        end
        
        return true
        
    elseif key == InputKey.MouseButton2 and self.mousePressed[3] ~= down then
    
        self.mousePressed[3] = down
        
        if down then
            CommanderUI_OnMousePress(2, mouseX, mouseY)
        else
            CommanderUI_OnMouseRelease(2, mouseX, mouseY)
        end
        
        return true
        
    end
    
    return false
    
end

function GUICommanderManager:Update(deltaTime)

    self:UpdateInput(deltaTime)
    self:UpdateSelector(deltaTime)
    
    local locationName = PlayerUI_GetLocationName()
    
    if self.locationText and locationName then
        self.locationText:SetText(locationName)
    end
    
    self:UpdateMouseOverUIState()
    
end

function GUICommanderManager:UpdateMouseOverUIState()

    local mouseX, mouseY = Client.GetCursorPosScreen()
    
    // Check all the clickable commander UI items owned by the manager.
    self.mouseOverUI = false
    
    for i, childScript in ipairs(self.childScripts) do
        // Can break out if the mouse is already over the UI.
        if self.mouseOverUI then
            break
        end
        self.mouseOverUI = self.mouseOverUI or childScript:ContainsPoint(mouseX, mouseY)
    end
    
    CommanderUI_UpdateMouseOverUIState(self.mouseOverUI)

end

function GUICommanderManager:UpdateInput(deltaTime)

    if not Client.GetIsWindowFocused() then
        return
    end
    
    local mouseX, mouseY = Client.GetCursorPosScreen()
    local scrollX = 0
    local scrollY = 0
    local screenWidth = Client.GetScreenWidth()
    local screenHeight = Client.GetScreenHeight()
    
    if mouseX <= 2 then
        scrollX = -1
    elseif mouseX >= screenWidth - 2 then
        scrollX = 1
    end

    if mouseY <= 2 then
        scrollY = -1
    elseif mouseY >= screenHeight - 2 then
        scrollY = 1
    end
    
    CommanderUI_ScrollView(scrollX, scrollY)
    
    // Check if the selector should be enabled.
    if self.mousePressed[1] == true then
        local mouseX, mouseY = Client.GetCursorPosScreen()
        local diffX = math.abs(self.mouseDownPointX - mouseX)
        local diffY = math.abs(self.mouseDownPointY - mouseY)
        if diffX > GUICommanderManager.kEnableSelectorMoveAmount or diffY > GUICommanderManager.kEnableSelectorMoveAmount then
            self:SelectorDown(self.mouseDownPointX, self.mouseDownPointY)
        end
    end

end

function GUICommanderManager:UpdateSelector(deltaTime)

    if self.selector then
        self.selector:SetIsVisible(self.selectorCursorDown)
    
        if self.selectorCursorDown then
            self.selector:SetPosition(Vector(self.selectorStartX, self.selectorStartY, 0))
            local mouseX, mouseY = Client.GetCursorPosScreen()
            self.selector:SetSize(Vector(mouseX - self.selectorStartX, mouseY - self.selectorStartY, 0))
            self.selector:SetColor(GUICommanderManager.kSelectorMarineColor)
        end
    end

end

function GUICommanderManager:GetIsSelectorDown()
    return self.selectorCursorDown
end

function GUICommanderManager:SelectorDown(mouseX, mouseY)

    if self.selectorCursorDown == true then
        return
    end
    
	self.selectorCursorDown = true
	
	self.selectorStartX = mouseX
	self.selectorStartY = mouseY

end

function GUICommanderManager:SelectorUp(mouseX, mouseY)

	if self.selectorCursorDown ~= true then
	    return
	end
	
	self.selectorCursorDown = false
	
	CommanderUI_SelectMarquee(self.selectorStartX, self.selectorStartY, mouseX, mouseY)
	
end
