// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUISpeedDebug.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    UI display for console command "debugspeed". Shows a red bar + number indicating the current
//    velocity and white bar indicating any special move/initial timing (like skulk jump, marine
//    sprint, onos momentum)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local gMomentumBarWidth = 200
local gFractionBarHeight = 80

class 'GUISpeedDebug' (GUIScript)

function GUISpeedDebug:Initialize()

    self.momentumBackGround = GetGUIManager():CreateGraphicItem()
    self.momentumBackGround:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.momentumBackGround:SetPosition(Vector(30, -120, 0))
    self.momentumBackGround:SetSize(Vector(gMomentumBarWidth, 30, 0))    
    self.momentumBackGround:SetColor(Color(1, 0.2, 0.2, 0.4))
    
    self.momentumFraction = GetGUIManager():CreateGraphicItem()
    self.momentumFraction:SetSize(Vector(0, 30, 0))
    self.momentumFraction:SetColor(Color(1, 0.2, 0.2, 1))
    
    self.currentFractionBg = GetGUIManager():CreateGraphicItem()
    self.currentFractionBg:SetAnchor(GUIItem.Left, GUIItem.Bottom)
    self.currentFractionBg:SetPosition(Vector(10, -80, 0))
    self.currentFractionBg:SetSize(Vector(19, -gFractionBarHeight, 0))    
    self.currentFractionBg:SetColor(Color(0.2, 0.2, 0.4, 0.7))
    
    self.currentFraction = GetGUIManager():CreateGraphicItem()
    self.currentFraction:SetSize(Vector(15, 0, 0))
    self.currentFraction:SetColor(Color(0.8, 0.8, 1, 1))
    self.currentFractionBg:AddChild(self.currentFraction)
    
    self.xzSpeed = GetGUIManager():CreateTextItem()
    self.xzSpeed:SetFontSize(18)
    self.xzSpeed:SetPosition(Vector(gMomentumBarWidth + 40, 0, 0))
    
    self.debugText = GetGUIManager():CreateTextItem()
    self.debugText:SetFontSize(18)
    self.debugText:SetPosition(Vector(80, -gFractionBarHeight, 0))
    
    self.OnGround = GetGUIManager():CreateTextItem()
    self.OnGround:SetFontSize(18)
    self.OnGround:SetPosition(Vector(40, -80, 0))
    
    self.OnWall = GetGUIManager():CreateTextItem()
    self.OnWall:SetFontSize(18)
    self.OnWall:SetPosition(Vector(40, -60, 0))
    
    self.momentumBackGround:AddChild(self.momentumFraction)
    self.momentumBackGround:AddChild(self.xzSpeed)
    self.momentumBackGround:AddChild(self.currentFractionBg)
    self.momentumBackGround:AddChild(self.debugText)
    self.momentumBackGround:AddChild(self.OnGround)
    self.momentumBackGround:AddChild(self.OnWall)
    
    Print("enabled speed meter")

end

function GUISpeedDebug:Uninitialize()

    if self.momentumBackGround then
        GUI.DestroyItem(self.momentumBackGround)
        self.momentumBackGround = nil
    end
    
    Print("disabled speed meter")

end

function GUISpeedDebug:SetDebugText(text)
    self.debugText:SetText(text)
end

function GUISpeedDebug:Update(deltaTime)

    local player = Client.GetLocalPlayer()
    
    if player then

        local velocity = player:GetVelocity()
        local speed = velocity:GetLengthXZ()
        local bonusSpeedFraction = speed / player:GoldSrc_GetMaxSpeed()
        local currentFraction = player:GetSpeedDebugSpecial() 
        
        local input = ""
        if player:GetLastInput() then
            input = string.format("keys: %s", ToString(player:GetLastInput().move))
        end

        self.momentumFraction:SetSize(Vector(gMomentumBarWidth * bonusSpeedFraction, 30, 0))
        self.xzSpeed:SetText( string.format( "current speed: %s  vertical speed: %s %s", ToString(RoundVelocity(speed)), ToString(RoundVelocity(velocity.y)), input ) )
        self.OnGround:SetText( string.format( "OnGround : %s", ToString(player:GetIsOnGround()) ) )
        self.OnWall:SetText( string.format( "OnWall : %s", ToString(player:GetIsOnSurface()) ) )
        
        if currentFraction then
            self.currentFraction:SetSize(Vector(15, -gFractionBarHeight * currentFraction, 0))
        end
    
    end

end

