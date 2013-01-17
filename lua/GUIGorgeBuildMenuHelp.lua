// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIGorgeBuildMenuHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kBuildMenuTextureName = "ui/gorge_build_selected.dds"

local kIconHeight = 128
local kIconWidth = 128

class 'GUIGorgeBuildMenuHelp' (GUIAnimatedScript)

function GUIGorgeBuildMenuHelp:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.background = GUIManager:CreateGraphicItem()
    self.background:SetColor(Color(0, 0, 0, 0))
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.background:SetSize(Vector(200, 200, 0))
    self.background:SetPosition(Vector(-100, -100 + kHelpBackgroundYOffset, 0))
    
    self.keyBackground = GUICreateButtonIcon("Weapon" .. 3)
    self.keyBackground:SetAnchor(GUIItem.Middle, GUIItem.Center)
    local size = self.keyBackground:GetSize()
    self.keyBackground:SetPosition(Vector(-size.x / 2, -size.y / 2 + 16, 0))
    self.background:AddChild(self.keyBackground)
    
    self.buildmenuImage = self:CreateAnimatedGraphicItem()
    self.buildmenuImage:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.buildmenuImage:SetSize(Vector(kIconWidth, kIconHeight, 0))
    self.buildmenuImage:SetPosition(Vector(-kIconWidth / 2, -kIconHeight, 0))
    self.buildmenuImage:SetTexture(kBuildMenuTextureName)
    self.buildmenuImage:SetIsVisible(false)
    self.buildmenuImage:AddAsChildTo(self.background)
    
end

function GUIGorgeBuildMenuHelp:Update(dt)

    GUIAnimatedScript.Update(self, dt)
    
    self.keyBackground:SetIsVisible(false)
    
    if not self.buildmenuUsed then
    
        local player = Client.GetLocalPlayer()
        if player then
        
            if not self.buildmenuImage:GetIsVisible() then
                HelpWidgetAnimateIn(self.buildmenuImage)
            end
            self.buildmenuImage:SetIsVisible(true)
            
            // Show the switch weapon key until they change to the build menu.
            local BuildMenuEquipped = player:GetActiveWeapon() and player:GetActiveWeapon():isa("DropStructureAbility")
            self.keyBackground:SetIsVisible(BuildMenuEquipped ~= true)
            if BuildMenuEquipped then
            
                self.keyBackground:SetIsVisible(false)
                self.buildmenuImage:SetIsVisible(false)
                self.buildmenuUsed = true
                HelpWidgetIncreaseUse(self, "GUIGorgeBuildMenuHelp")
                
            end
            
        end
        
    end
    
end

function GUIGorgeBuildMenuHelp:Uninitialize()

    GUIAnimatedScript.Uninitialize(self)
    
    GUI.DestroyItem(self.keyBackground)
    self.keyBackground = nil
    
    GUI.DestroyItem(self.buildmenuImage)
    self.buildmenuImage = nil
    
    GUI.DestroyItem(self.background)
    self.background = nil
    
end