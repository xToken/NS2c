// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIDeathScreen.lua
//
// Created by: Andreas Urwalek (andi@unkownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/GUIAnimatedScript.lua")
Script.Load("lua/DeathMessage_Client.lua")

class 'GUIDeathScreen' (GUIAnimatedScript)

local kWeaponIconSize = Vector(256, 128, 0)
local kFontName = "fonts/AgencyFB_medium.fnt"

function GUIDeathScreen:Initialize()

    GUIAnimatedScript.Initialize(self)
    
    self.background = self:CreateAnimatedGraphicItem()
    self.background:SetColor(Color(0,0,0,0))
    self.background:SetIsScaling(false)
    self.background:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(),0))
    self.background:SetLayer(kGUILayerDeathScreen)
    
    self.weaponIcon = self:CreateAnimatedGraphicItem()
    self.weaponIcon:SetColor(Color(1,1,1,0))
    self.weaponIcon:SetIsScaling(true)
    self.weaponIcon:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.weaponIcon:SetSize(kWeaponIconSize)    
    self.weaponIcon:SetPosition(Vector(-kWeaponIconSize.x / 2, -kWeaponIconSize.y / 2, 0))
    self.weaponIcon:SetTexture(kInventoryIconsTexture)
    
    self.killerName = GetGUIManager():CreateTextItem()
    self.killerName:SetText("")
    self.killerName:SetFontName(kFontName)
    self.killerName:SetAnchor(GUIItem.Left, GUIItem.Center)
    self.killerName:SetTextAlignmentX(GUIItem.Align_Max)
    self.killerName:SetTextAlignmentY(GUIItem.Align_Center)
    self.killerName:SetInheritsParentAlpha(true)
    self.weaponIcon:AddChild(self.killerName)
    
    self.playerName = GetGUIManager():CreateTextItem()
    self.playerName:SetText("")
    self.playerName:SetFontName(kFontName)
    self.playerName:SetAnchor(GUIItem.Right, GUIItem.Center)
    self.playerName:SetTextAlignmentX(GUIItem.Align_Min)
    self.playerName:SetTextAlignmentY(GUIItem.Align_Center)
    self.playerName:SetInheritsParentAlpha(true)
    self.weaponIcon:AddChild(self.playerName)    
    
    self.lastIsDead = PlayerUI_GetIsDead()
    
end

function GUIDeathScreen:Reset()

    GUIAnimatedScript.Reset(self)
    
    self.background:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(),0))
    
end

function GUIDeathScreen:Update(deltaTime)

    PROFILE("GUIDeathScreen:Update")
    
    GUIAnimatedScript.Update(self, deltaTime)
    
    local isDead = PlayerUI_GetIsDead() and not PlayerUI_GetIsSpecating()
    
    if isDead ~= self.lastIsDead then
    
        -- Check for the killer name as it will be nil if it hasn't been received yet.
        local killerName = nil
        local weaponIconIndex = nil
        if isDead then
        
            killerName, weaponIconIndex = GetKillerNameAndWeaponIcon()
            if not killerName then
                return
            end
            
        end
        
        self.lastIsDead = isDead
        
        if self.lastIsDead == true then
        
            local playerName = PlayerUI_GetPlayerName()
            local xOffset = DeathMsgUI_GetTechOffsetX(0)
            local yOffset = DeathMsgUI_GetTechOffsetY(weaponIconIndex)
            local iconWidth = DeathMsgUI_GetTechWidth(0)
            local iconHeight = DeathMsgUI_GetTechHeight(0)
            
            self.killerName:SetText(killerName)
            self.playerName:SetText(playerName)
            
            self.weaponIcon:SetTexturePixelCoordinates(xOffset, yOffset, xOffset + iconWidth, yOffset + iconHeight)
            self.weaponIcon:FadeIn(0.5, "FADE_DEATH_ICON")
            
            self.weaponIcon:SetIsVisible(true)
            self.background:FadeIn(2, "FADE_DEATH_SCREEN")
        else
        
            self.background:FadeOut(0.5, "FADE_DEATH_SCREEN")
            self.weaponIcon:FadeOut(1.5, "FADE_DEATH_ICON")
            
        end
        
    end
    
end