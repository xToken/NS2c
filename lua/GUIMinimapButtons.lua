
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIMinimapButtons.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// Buttons for minimap action (commander ping).
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIScript.lua")

class 'GUIMinimapButtons' (GUIScript)

local kButtonBackgroundTexture =
{
    [kMarineTeamType] = "ui/marine_buildmenu_buttonbg.dds",
    [kAlienTeamType] = "ui/alien_buildmenu_buttonbg.dds",
}

local kBackgroundPos = {}
local kButtonSize

local kIconTexture = "ui/buildmenu.dds"

local function CreateButtonBackground(self, position, child)

    local buttonBackground = GetGUIManager():CreateGraphicItem()
    buttonBackground:SetTexture(kButtonBackgroundTexture[PlayerUI_GetTeamType()])
    buttonBackground:SetPosition(position)
    buttonBackground:SetSize(kButtonSize)
    buttonBackground:AddChild(child)
    
    self.background:AddChild(buttonBackground)
    
    return buttonBackground
    
end

local function UpdateItemsGUIScale(self)
    kBackgroundPos[kMarineTeamType] = GUIScale(Vector(-130, 15, 0))
    kBackgroundPos[kAlienTeamType] = GUIScale(Vector(-80, 160, 0))
    kButtonSize = GUIScale(Vector(60, 60, 0))
end

function GUIMinimapButtons:OnResolutionChanged(oldX, oldY, newX, newY)
    UpdateItemsGUIScale(self)
    self.background:SetPosition(kBackgroundPos[self.teamType])
end

function GUIMinimapButtons:Initialize()
    
    UpdateItemsGUIScale(self)
    self.teamType = PlayerUI_GetTeamType()
    self.background = GetGUIManager():CreateGraphicItem()
    self.background:SetAnchor(GUIItem.Right, GUIItem.Top)
    self.background:SetColor(Color(1,1,1,0))
    self.background:SetPosition(kBackgroundPos[self.teamType])

end

function GUIMinimapButtons:GetBackground()
    return self.background
end

function GUIMinimapButtons:Uninitialize()

    if self.background then
    
        GUI.DestroyItem(self.background)
        self.background = nil
        
    end
    
end

function GUIMinimapButtons:Update(deltaTime)
    
end

function GUIMinimapButtons:ContainsPoint(pointX, pointY)
    return false
end

function GUIMinimapButtons:SendKeyEvent(key, down)
    
end