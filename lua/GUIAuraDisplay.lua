// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/GUIAuraDisplay.lua
//
// Shows how many shells, spurs, veils you have
//
// Created by Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

PrecacheAsset("shaders/GUIAura.surface_shader")

class 'GUIAuraDisplay' (GUIScript)

local kIconSize = Vector(100, 100, 0)
local kHeartOffset = Vector(0, 1.25, 0)
local kExoHeartOffset = Vector(0, 2.25, 0)
local kTexture = "ui/aura.dds"

local function CreateAuaIcon(self)

    local icon = GetGUIManager():CreateGraphicItem()
    icon:SetTexture(kTexture)
    icon:SetShader("shaders/GUIAura.surface_shader")
    icon:SetBlendTechnique(GUIItem.Add)
    self.background:AddChild(icon)
    
    return icon

end

function GUIAuraDisplay:Initialize()

    self.updateInterval = 0
    
    self.background = GetGUIManager():CreateGraphicItem()
    self.background:SetColor(Color(0,0,0,0))
    
    self.icons = {}

end

function GUIAuraDisplay:Uninitialize()
    
    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
    end
    
    self.icons = nil
    
end

function GUIAuraDisplay:Update(deltaTime)

    local players = {}
    
    local player = Client.GetLocalPlayer()
	local hasupg, level = GetHasAuraUpgrade(player)
    if player and hasupg and level > 0 then
    
        local viewDirection = player:GetViewCoords().zAxis
        local eyePos = player:GetEyePos()
        
        local range = (((1 / 3) * level) * kAuraDetectionRange)
        for _, enemyPlayer in ipairs( GetEntitiesForTeamWithinRange("Player", GetEnemyTeamNumber(player:GetTeamNumber()), eyePos, range) ) do
        
            if not enemyPlayer:isa("Spectator") and not enemyPlayer:isa("Commander") then

                if enemyPlayer:GetIsAlive() then                
                    if viewDirection:DotProduct(GetNormalizedVector(enemyPlayer:GetOrigin() - eyePos)) > 0 then
                        table.insert(players, enemyPlayer)    
                    end
                    
                end
                
            end
        
        end
    
    end
    
    local numPlayers = #players
    local numIcons = #self.icons
    
    if numPlayers > numIcons then
    
        for i = 1, numPlayers - numIcons do
            
            local icon = CreateAuaIcon(self)
            table.insert(self.icons, icon)
            
        end
    
    elseif numIcons > numPlayers then
    
        for i = 1, numIcons - numPlayers do
            
            GUI.DestroyItem(self.icons[#self.icons])
            self.icons[#self.icons] = nil
            
        end
    
    end
    
    local eyePos = player:GetEyePos()
    
    for i = 1, numPlayers do
    
        local enemy = players[i]
        local icon = self.icons[i]
     
        local color = Color(1, 1, 0, 1)
        
        local offset = enemy:isa("Exo") and kExoHeartOffset or kHeartOffset
        
        local worldPos = enemy:GetOrigin() + offset
        local screenPos = Client.WorldToScreen(worldPos)
        local distanceFraction = 1 - Clamp((worldPos - eyePos):GetLength() / 20, 0, 0.8)

        local size = Vector(kIconSize.x, kIconSize.y, 0) * distanceFraction
        icon:SetPosition(screenPos - size * 0.5)
        icon:SetSize(size)  
        icon:SetColor(color)
    
    end

end