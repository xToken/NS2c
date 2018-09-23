-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUISpeedDebug.lua
--
--    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
--    UI display for console command "debugspeed". Shows a red bar + number indicating the current
--    velocity and white bar indicating any special move/initial timing (like skulk jump, marine
--    sprint, onos momentum)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Added additional debug information

local gMomentumBarWidth = 200
local gFractionBarHeight = 80
local kFontName = Fonts.kArial_17

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
    self.debugText:SetScale(GetScaledVector())
    self.debugText:SetFontName(kFontName)
    GUIMakeFontScale(self.debugText)
    self.debugText:SetPosition(Vector(80, -gFractionBarHeight, 0))
    
    self.OnSurface = GetGUIManager():CreateTextItem()
    self.OnSurface:SetScale(GetScaledVector())
    self.OnSurface:SetFontName(kFontName)
    GUIMakeFontScale(self.OnSurface)
    self.OnSurface:SetPosition(Vector(40, -95, 0))
    
    self.OnGround = GetGUIManager():CreateTextItem()
    self.OnGround:SetScale(GetScaledVector())
    self.OnGround:SetFontName(kFontName)
    GUIMakeFontScale(self.OnGround)
    self.OnGround:SetPosition(Vector(40, -80, 0))
    
    self.Friction = GetGUIManager():CreateTextItem()
    self.Friction:SetScale(GetScaledVector())
    self.Friction:SetFontName(kFontName)
    GUIMakeFontScale(self.Friction)
    self.Friction:SetPosition(Vector(40, -65, 0))
    
    self.MaxSpeed = GetGUIManager():CreateTextItem()
    self.MaxSpeed:SetScale(GetScaledVector())
    self.MaxSpeed:SetFontName(kFontName)
    GUIMakeFontScale(self.MaxSpeed)
    self.MaxSpeed:SetPosition(Vector(40, -50, 0))
    
    self.Jumping = GetGUIManager():CreateTextItem()
    self.Jumping:SetScale(GetScaledVector())
    self.Jumping:SetFontName(kFontName)
    GUIMakeFontScale(self.Jumping)
    self.Jumping:SetPosition(Vector(40, -35, 0))
    
    self.Accel = GetGUIManager():CreateTextItem()
    self.Accel:SetScale(GetScaledVector())
    self.Accel:SetFontName(kFontName)
    GUIMakeFontScale(self.Accel)
    self.Accel:SetPosition(Vector(40, -20, 0))
    
    self.momentumBackGround:AddChild(self.momentumFraction)
    self.momentumBackGround:AddChild(self.xzSpeed)
    self.momentumBackGround:AddChild(self.currentFractionBg)
    self.momentumBackGround:AddChild(self.debugText)
    self.momentumBackGround:AddChild(self.OnSurface)
    self.momentumBackGround:AddChild(self.OnGround)
    self.momentumBackGround:AddChild(self.Friction)
    self.momentumBackGround:AddChild(self.MaxSpeed)
    self.momentumBackGround:AddChild(self.Jumping)
    self.momentumBackGround:AddChild(self.Accel)
    
    Print("enabled speed meter")

end

function GUISpeedDebug:Uninitialize()

    if self.momentumBackGround then
        GUI.DestroyItem(self.momentumBackGround)
        self.momentumBackGround = nil
    end
    
    Print("disabled speed meter")

end

function GUISpeedDebug:SetDebugText(text, text2)
    //self.Landed:SetText(string.format( "Landed This Frame : %s : With force : %s", text, text2))
end

function GUISpeedDebug:Update(deltaTime)

    local player = Client.GetLocalPlayer()
    
    if player then

        local velocity = player:GetVelocity()
        local speed = velocity:GetLengthXZ()
        local bonusSpeedFraction = speed / player:GetMaxSpeed()
        local currentFraction = player:GetSpeedDebugSpecial() 
        local advMovement = player:HasAdvancedMovement()
        local accel = ConditionalValue(player:GetIsOnGround(), player:GetAcceleration(), player:GetAirAcceleration())
        if advMovement then
            accel = player:GetNS1Acceleration(player:GetIsOnGround())
        end
        
        local input = ""
        if player:GetLastInput() then
            input = string.format("keys: %s", ToString(player:GetLastInput().move))
        end
    
        self.momentumFraction:SetSize(Vector(gMomentumBarWidth * bonusSpeedFraction, 30, 0))
        self.xzSpeed:SetText( string.format( "Current Speed: %s  Vertical Speed: %s %s", ToString(RoundVelocity(speed)), ToString(RoundVelocity(velocity.y)), input ) )
        self.OnSurface:SetText( string.format( "Crouching : %s : MovementMode : %s", ToString(player:GetCrouching()), ConditionalValue(advMovement, "Classic", "Vanilla") ) )
        self.OnGround:SetText( string.format( "OnGround : %s : WallWalking-Gripping : %s", ToString(player:GetIsOnGround()), player.GetIsWallWalking and ToString(player:GetIsWallWalking()) or player.GetIsWallGripping and ToString(player:GetIsWallGripping()) or "false" ) )
        //self.Friction:SetText( string.format( "Friction : %s", ToString(player:GetGroundFriction()) ) )
        self.Friction:SetText( string.format( "CanJump : %s : CanWallJump : %s", ToString(player:GetCanJump()), ToString(player.GetCanWallJump and player:GetCanWallJump() or false) ) )
        self.MaxSpeed:SetText( string.format( "MaxSpeed : %s : Weapon weight : %s", ToString(player:GetMaxSpeed()), ToString(player:GetWeaponsWeight() or 0) ) )
        self.Jumping:SetText( string.format( "Jumping : %s : Last landing force : %s", ToString(player:GetIsJumping()), ToString(player.lastImpactForce or 0) ) )
        self.Accel:SetText( string.format( "Accel : %s", ToString(player:GetIsOnGround() and player:GetAcceleration() or player:GetAirAcceleration()) ) )
        
        if currentFraction then
            self.currentFraction:SetSize(Vector(15, -gFractionBarHeight * currentFraction, 0))
        end
    
    end

end

