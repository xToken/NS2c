// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Commander_MouseActions.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

assert(Client)

local function GetSelectionAllowed(commander)
    return true
end

local function ClickSelect(commander, x, y, controlSelect, shiftSelect)

    local success = false
    local hitEntity = false
    shiftSelect = shiftSelect == true
    
    if not GetSelectionAllowed(commander) then
        return false
    end
    
    local pickVec = CreatePickRay(commander, x, y)
    local entity = commander:GetUnitUnderCursor(pickVec) 
    
    if controlSelect then
    
        // select all entities on screen
        local entity = commander:GetUnitUnderCursor(pickVec) 
        if entity and HasMixin(entity, "Selectable") then
        
            local selectables = GetSelectablesOnScreen(commander, entity:GetClassName())
            
            if not shiftSelect then
                DeselectAllUnits(commander:GetTeamNumber())
            end
            
            for _, entity in ipairs(selectables) do
            
                local setSelected = true
                if shiftSelect then
                    setSelected = not entity:GetIsSelected(commander:GetTeamNumber())
                end
            
                entity:SetSelected(commander:GetTeamNumber(), setSelected)    
                
            end
        
        end
        
    else
        
        if entity and HasMixin(entity, "Selectable") then
        
            if shiftSelect then
                local isSelected = entity:GetIsSelected(commander:GetTeamNumber())
                entity:SetSelected(commander:GetTeamNumber(), not isSelected, true)
            else
            
                DeselectAllUnits(commander:GetTeamNumber())
                entity:SetSelected(commander:GetTeamNumber(), true)
            
            end

        end
     
    end
    
    return success, hitEntity
    
end

// The number of pixels that the cursor needs to move in order to enable the marquee selector.
local kEnableSelectorMoveAmount = 5

local mousePressed = { }
local mouseButtonDownAtPoint = { }

// All mouse actions are stored in this table.
// The format is a table of action names and then functions for
// the action that represent specific mouse buttons.
// The function is called with the local player, x mouse coordinate, and y mouse coordinate.
// These coordinates are in screen space.
local kMouseActions = { ButtonDown = { }, ButtonUp = { }, DoubleClick = { }, Move = { } }

kMouseActions.ButtonDown[InputKey.MouseButton0] = function(player, mouseX, mouseY)

    if GetCommanderGhostStructureEnabled() then
        CommanderGhostStructureLeftMouseButtonDown(mouseX, mouseY)
    else
    
        local techNode = GetTechNode(player.currentTechId)
        
        if player.currentTechId == nil or techNode == nil or not techNode:GetRequiresTarget() then
            ClickSelect(player, mouseX, mouseY, player.ctrlDown, player.shiftDown)
        end
        
    end
    
end

kMouseActions.ButtonUp[InputKey.MouseButton0] = function(player, mouseX, mouseY)

    if GetIsCommanderMarqueeSelectorDown() then
        SetCommanderMarqueeeSelectorUp(mouseX, mouseY, player.shiftDown)
    else
        // TODO: Move code into this file.
        CommanderUI_OnMouseRelease(0, mouseX, mouseY)
    end
    
end

kMouseActions.ButtonUp[InputKey.MouseButton1] = function(player, mouseX, mouseY)
    // TODO: Move code into this file.
    CommanderUI_OnMouseRelease(1, mouseX, mouseY)
end

kMouseActions.ButtonUp[InputKey.MouseButton2] = function(player, mouseX, mouseY)
    // TODO: Move code into this file.
    CommanderUI_OnMouseRelease(2, mouseX, mouseY)
end

kMouseActions.DoubleClick[InputKey.MouseButton0] = function(player, mouseX, mouseY)

    // Only allowed when there is not a ghost structure.
    if not GetCommanderGhostStructureEnabled() then
    
        local techNode = GetTechNode(player.currentTechId)
        if player.currentTechId == nil or techNode == nil or not techNode:GetRequiresTarget() then
        
            // Double clicking on an entity will simulate a control click.
            // All entities of the same type will be selected.
            // ToDo: Move ClickSelect code out of Player and into this file.
            ClickSelect(player, mouseX, mouseY, true, player.shiftDown)
            
        end
        
    end
    
end

kMouseActions.Move = function(player, mouseX, mouseY)

    // Check if the selector should be enabled.
    if mousePressed[InputKey.MouseButton0] then
    
        local downX = mouseButtonDownAtPoint[InputKey.MouseButton0].x
        local downY = mouseButtonDownAtPoint[InputKey.MouseButton0].y
        local diffX = math.abs(downX - mouseX)
        local diffY = math.abs(downY - mouseY)
        
        if GetSelectionAllowed(player) and ( diffX > kEnableSelectorMoveAmount or diffY > kEnableSelectorMoveAmount ) then
            SetCommanderMarqueeeSelectorDown(downX, downY)
        end
        
    end
    
end

local function GetLocalPlayerIsACommander()

    local player = Client.GetLocalPlayer()
    if player then
        return player:isa("Commander"), player
    end
    
    return nil, nil
    
end

local function OnMouseDown(_, button, doubleClick)

    local isCommander, player = GetLocalPlayerIsACommander()
    if not isCommander or CommanderUI_GetMouseIsOverUI() then
        return
    end
    
    local mousePos = MouseTracker_GetCursorPos()
    
    mousePressed[button] = true
    mouseButtonDownAtPoint[button] = Vector(mousePos.x, mousePos.y, 0)
    
    local evalButtonDown = kMouseActions.ButtonDown[button]
    if evalButtonDown then
        evalButtonDown(player, mousePos.x, mousePos.y)
    end
    
    // Evaluate if there are any world actions right now for this mouse input.
    if doubleClick then
    
        local evalDoubleClick = kMouseActions.DoubleClick[button]
        if evalDoubleClick then
            evalDoubleClick(player, mousePos.x, mousePos.y)
        end
        
    end
    

    // If there are no world actions, forward along to the Commander UI code.
    
end

local function OnMouseUp(_, button)

    local isCommander, player = GetLocalPlayerIsACommander()
    if not isCommander then
        return
    end
    
    local mousePos = MouseTracker_GetCursorPos()
    
    mousePressed[button] = false
    
    // Evaluate if there are any world actions right now for this mouse input.
    local evalButtonUp = kMouseActions.ButtonUp[button]
    if evalButtonUp then
        evalButtonUp(player, mousePos.x, mousePos.y)
    end
    
    // If there are no world actions, forward along to the Commander UI code.
    
end

local function OnMouseMove()

    local isCommander, player = GetLocalPlayerIsACommander()
    if not isCommander or CommanderUI_GetMouseIsOverUI() then
        return
    end
    
    local mousePos = MouseTracker_GetCursorPos()
    
    // Evaluate if there are any world actions right now for this mouse input.
    kMouseActions.Move(player, mousePos.x, mousePos.y)
    
end

local listener = { OnMouseDown = OnMouseDown, OnMouseUp = OnMouseUp, OnMouseMove = OnMouseMove }
MouseTracker_ListenToButtons(listener)
MouseTracker_ListenToMovement(listener)