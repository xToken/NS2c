// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander_Buttons.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Added in Fixed HotKey for final panel

Script.Load("lua/Commander_Hotkeys.lua")
Script.Load("lua/TechTreeButtons.lua")

// Maps tech buttons to keys in "grid" system
kGridHotkeys =
{
    Move.Q, Move.W, Move.E, Move.R,
    Move.A, Move.S, Move.D, Move.F,
    Move.Z, Move.X, Move.C, Move.V,
}

/**
 * Called by Flash when the user presses the "Logout" button.
 */
function CommanderUI_Logout()

    local commanderPlayer = Client.GetLocalPlayer()
    commanderPlayer:Logout()
        
end

local kButtonClickedSound =
{
    [kMarineTeamType] = PrecacheAsset("sound/NS2.fev/common/hovar"),
    [kAlienTeamType] = PrecacheAsset("sound/NS2.fev/alien/common/alien_menu/hover"),
}

function CommanderUI_OnButtonClicked()

    local player = Client.GetLocalPlayer()
    if player and HasMixin(player, "Team") then
        
        local soundToPlay = kButtonClickedSound[player:GetTeamType()]
        if soundToPlay then
            StartSoundEffect(soundToPlay)
        end
        
    end

end

function CommanderUI_OnButtonHover()
    CommanderUI_OnButtonClicked()
end

function CommanderUI_MenuButtonWidth()
    return 80
end

function CommanderUI_MenuButtonHeight()
    return 80
end

/*
    Return linear array consisting of:    
    tooltipText (String)
    tooltipHotkey (String)
    tooltipCost (Number)
    tooltipRequires (String) - optional, specify "" or nil if not used
    tooltipEnables (String) - optional, specify "" or nil if not used
    tooltipInfo (String)
    tooltipType (Number) - 0 = team resources, 1 = individual resources, 2 = energy
*/
function CommanderUI_MenuButtonTooltip(index)

    local player = Client.GetLocalPlayer()

    local techId = nil
    local tooltipText = nil
    local hotkey = nil
    local cost = nil
    local requiresText = nil
    local enablesText = nil
    local tooltipInfo = nil
    local resourceType = 0
    
    if(index <= table.count(player.menuTechButtons)) then
    
        local techTree = GetTechTree()
        techId = player.menuTechButtons[index]        
        
        tooltipText = techTree:GetDescriptionText(techId)
        hotkey = kGridHotkeys[index]
        
        if hotkey ~= "" then
            hotkey = gHotkeyDescriptions[hotkey]
        end
        
        cost = LookupTechData(techId, kTechDataCostKey, 0)
        local techNode = techTree:GetTechNode(techId)
        if techNode then
            resourceType = techNode:GetResourceType()
        end
        requiresText = techTree:GetRequiresText(techId)
        enablesText = techTree:GetEnablesText(techId)
        tooltipInfo = GetTooltipInfoText(techId)
        
        if not player.menuTechButtonsAllowed[index] and LookupTechData(techId, kTechDataRequiresMature, false) then
        
            local maturityText = Locale.ResolveString("MATURITY")
            requiresText = ConditionalValue( string.len(requiresText) > 0, requiresText .. ", " .. maturityText,  maturityText)
            
        end
        
    end
    
    return {tooltipText, hotkey, cost, requiresText, enablesText, tooltipInfo, resourceType}    
    
end

/** 
 * Returns the current status of the button. 
 * 0 = button or tech not found, or currently researching, don't display
 * 1 = available and ready, display as pressable
 * 2 = available but not currently, display in red
 * 3 = not available, display grayed out (also for invalid actions, ie Recycle)
 * 4 = normal color but not clickable
 */
function CommanderUI_MenuButtonStatus(index)

    local player = Client.GetLocalPlayer()
    local buttonStatus = 0
    local techId = 0
    
    if(index <= table.count(player.menuTechButtons)) then
    
        techId = player.menuTechButtons[index]
        
        if techId ~= kTechId.None then
        
            local techNode = GetTechTree():GetTechNode(techId)
            
            if techNode then
            
                if techNode:GetResearching() and not techNode:GetIsUpgrade() then
                
                    // Don't display
                    buttonStatus = 0

                elseif techNode:GetIsPassive() then

                    buttonStatus = 4         
                    
                elseif not techNode:GetAvailable() or not player.menuTechButtonsAllowed[index] then
                
                    // Greyed out
                    buttonStatus = 3
                
                elseif not player.menuTechButtonsAffordable[index] then
                
                    // red, can't afford, but allowed
                    buttonStatus = 2
                                       
                else
                    // Available
                    buttonStatus = 1
                end

            else
                // Print("CommanderUI_MenuButtonStatus(%s): Tech node for id %s not found (%s)", tostring(index), EnumToString(kTechId, techId), table.tostring(player.menuTechButtons))
            end
            
        end
        
    end    
    
    return buttonStatus

end

function CommanderUI_MenuButtonCooldownFraction(index)

    local player = Client.GetLocalPlayer()
    local cooldownFraction = 0
    
    if index <= table.count(player.menuTechButtons) then
    
        techId = player.menuTechButtons[index]
        
        if techId ~= kTechId.None then        
            cooldownFraction = player:GetCooldownFraction(techId)
        end    
            
    end
    
    return cooldownFraction
    
end

local kDeselectUnitsOnTech = { }
kDeselectUnitsOnTech[kTechId.BuildMenu] = true
kDeselectUnitsOnTech[kTechId.AdvancedMenu] = true
kDeselectUnitsOnTech[kTechId.AssistMenu] = true
function CommanderUI_MenuButtonAction(index)

    local player = Client.GetLocalPlayer()
    
    local newTechId = player.menuTechButtons[index]
    
    // Trigger button press (open menu, build tech, etc.)
    if index <= #player.menuTechButtons then
        player:SetCurrentTech(newTechId)
    end
    
    // Deselect all units if a tab was selected that isn't the select tab.
    if kDeselectUnitsOnTech[newTechId] then
        DeselectAllUnits(player:GetTeamNumber())
    end
    
end

local function GetIsMenu(techId)

    local techTree = GetTechTree()
    if techTree then
    
        local techNode = techTree:GetTechNode(techId)
        return techNode ~= nil and techNode:GetIsMenu()
        
    end
    
    return false

end

function CommanderUI_MenuButtonOffset(index)

    local player = Client.GetLocalPlayer()
    if index <= table.count(player.menuTechButtons) then
    
        local techId = player.menuTechButtons[index]
    
        if index == 4 then
            local selectedEnts = player:GetSelection()
            if selectedEnts and selectedEnts[1] then
                techId = selectedEnts[1]:GetTechId()
            end
        end

        return GetMaterialXYOffset(techId, player:isa("MarineCommander"))
        
    end
    
    return -1, -1
    
end

function CommanderUI_MenuButtonXOffset(index)

    local player = Client.GetLocalPlayer()
    if(index <= table.count(player.menuTechButtons)) then
    
        local techId = player.menuTechButtons[index]
    
        if index == 4 then
            local selectedEnts = player:GetSelection()
            if selectedEnts and selectedEnts[1] then
                techId = selectedEnts[1]:GetTechId()
            end
        end
    
        
        local xOffset, yOffset = GetMaterialXYOffset(techId, player:isa("MarineCommander"))
        return xOffset
        
    end
    
    return -1
    
end

function CommanderUI_MenuButtonYOffset(index)

    local player = Client.GetLocalPlayer()
    if(index <= table.count(player.menuTechButtons)) then
    
        local techId = player.menuTechButtons[index]
        if(techId ~= kTechId.None) then
            local xOffset, yOffset = GetMaterialXYOffset(techId, player:isa("MarineCommander"))
            return yOffset
        end
    end
    
    return -1
    
end

// Look at current selection and our current menu (self.menuTechId) and build a list of tech
// buttons that represents valid orders for the Commander. Store in self.menuTechButtons.
// Allow nothing to be selected too.
local function UpdateSharedTechButtons(self)

    self.menuTechButtons = { }
    local selection = self:GetSelection()
    if #selection > 0 then
    
        // Loop through all entities and get their tech buttons
        local selectedTechButtons = { }
        local maxTechButtons = 0
        for i = 1, #selection do

            local entity = selection[i]
            if entity then

                local techButtons = self:GetCurrentTechButtons(self.menuTechId, entity)
                
                if techButtons then
                
                    table.insert(selectedTechButtons, techButtons)
                    maxTechButtons = math.max(maxTechButtons, table.count(techButtons))
                    
                end
                
            end
        
        end
        
        // Now loop through tech button lists and use only the tech that doesn't conflict. These will generally be the same
        // tech id, but could also be a techid that not all selected units have, so long as the others don't specify a button
        // in the same position (ie, it is kTechId.None).
        local techButtonIndex = 1
        for techButtonIndex = 1, maxTechButtons do

            local buttonConflicts = false
            local buttonTechId = kTechId.None
            local highestButtonPriority = 0
            
            for index, techButtons in pairs(selectedTechButtons) do
            
                local currentButtonTechId = techButtons[techButtonIndex]
                
                if currentButtonTechId then
                
                    // Lookup tech id priority. If not specified, treat as 0.
                    local currentButtonPriority = LookupTechData(currentButtonTechId, kTechDataMenuPriority, 0)

                    if(buttonTechId == kTechId.None) then
                    
                        buttonTechId = currentButtonTechId
                        highestButtonPriority = currentButtonPriority
                        
                    elseif((currentButtonTechId ~= buttonTechId) and (currentButtonTechId ~= kTechId.None)) then
                        
                        if(currentButtonPriority > highestButtonPriority) then
                            
                            highestButtonPriority = currentButtonPriority
                            buttonTechId = currentButtonTechId
                            buttonConflicts = false                            
                        
                        elseif(currentButtonPriority == highestButtonPriority) then
                        
                            buttonConflicts = true
                            
                        end
                        
                    end
                    
                end
                
            end     
            
            if not buttonConflicts then
                table.insert(self.menuTechButtons, buttonTechId)
            else
                table.insert(self.menuTechButtons, kTechId.None)
            end
            
        end
        
    else
    
        // Populate with regular tech button menu when nothing selected (ie, marine quick menu)
        local techButtons = self:GetCurrentTechButtons(self.menuTechId, nil)                
        if techButtons then
        
            for techButtonIndex = 1, table.count(techButtons) do
            
                local buttonTechId = techButtons[techButtonIndex]
                table.insert(self.menuTechButtons, buttonTechId)
                
            end
            
        end
        
    end

end

local function ComputeMenuTechAvailability(self)

    self.menuTechButtonsAllowed = { }
    self.menuTechButtonsAffordable = { }
    
    local techTree = GetTechTree()
    
    for b = 1, #self.menuTechButtons do
    
        local techId = self.menuTechButtons[b]
        
        local techNode = techTree:GetTechNode(techId)
        
        local menuTechButtonAllowed = false
        local menuTechButtonAffordable = false
        
        local isTab, isSelect = self:IsTabSelected(techId)
        local forceAllow = self:GetForceAllow(techId)
        
        if self:GetCooldownFraction(techId) ~= 0 then
            
            menuTechButtonAllowed = false
            menuTechButtonAffordable = true
            
        else
            
            if isTab or forceAllow then
            
                menuTechButtonAllowed = true
                menuTechButtonAffordable = true
                
            elseif techNode then
            
                local selection = self:GetSelection()
            
                if #selection > 0 then
                
                    for e = 1, #selection do
                    
                        local entity = selection[e]
                        local isTechAllowed = false
                        local canAfford = false
                        
                        local _, isSelectTabSelected = self:IsTabSelected(kTechId.WeaponsMenu)
                        if isSelectTabSelected then
                            isTechAllowed, canAfford = entity:GetTechAllowed(techId, techNode, self)
                        else
                            isTechAllowed, canAfford = self:GetTechAllowed(techId, techNode, self)
                        end
                        
                        menuTechButtonAllowed = isTechAllowed
                        menuTechButtonAffordable = canAfford
                        
                        // If any of the selection entities allows this tech, it is allowed!
                        // For example, if 2 ARCs are selected and one is in deploy mode while the other is not,
                        // The first ARC would allow undeploy and the second would not, so at least one ARC allows it.
                        if menuTechButtonAllowed and menuTechButtonAffordable then
                            break
                        end
                        
                    end
                    
                else
                
                    // Handle the case where nothing is selected.
                    menuTechButtonAllowed, menuTechButtonAffordable = self:GetTechAllowed(techId, techNode, self)
                    
                end
                
            end
            
        end   
        
        table.insert(self.menuTechButtonsAllowed, menuTechButtonAllowed)
        table.insert(self.menuTechButtonsAffordable, menuTechButtonAffordable)
        
    end
    
end

function Commander:InitializeMenuTechButtons()

    self.menuTechButtons = { }
    self.menuTechButtonsAllowed = { }
    self.menuTechButtonsAffordable = { }
    
    UpdateSharedTechButtons(self)
    
end

function Commander:UpdateMenu()

    if self.menuTechId == nil then
        self.menuTechId = kTechId.BuildMenu
    end
    
    UpdateSharedTechButtons(self)
    ComputeMenuTechAvailability(self)
    
end

function Commander:GetForceAllow(techId)
    return false
end

function Commander:IsTabSelected(techId)

    assert(self.buttonsScript)
    return self.buttonsScript:IsTab(techId), self.buttonsScript:IsTabSelected(techId)
    
end