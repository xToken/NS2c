// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua\GUIBuyShotgunHelp.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kVisionTextureName = "ui/marine_shotgun_buy.dds"

local kIconWidth = 128
local kIconHeight = 128
local kIconSize = Vector(kIconWidth / 2, kIconHeight / 2, 0)
local kArrowTexture = "ui/marinewaypoint_arrow.dds"
local kArrowSize = Vector(24, 24, 0)

class 'GUIBuyShotgunHelp' (GUIScript)

function GUIBuyShotgunHelp:Initialize()

    self.shotgunImage = GUIManager:CreateGraphicItem()
    self.shotgunImage:SetAnchor(GUIItem.Left, GUIItem.Top)
    self.shotgunImage:SetPosition(Vector(-kIconWidth / 2, -kIconHeight + kHelpBackgroundYOffset, 0))
    self.shotgunImage:SetSize(kIconSize)
    self.shotgunImage:SetTexture(kVisionTextureName)
    self.shotgunImage:SetLayer(kGUILayerPlayerHUD)
    self.shotgunImage:SetIsVisible(false)
    
    self.arrow = GUIManager:CreateGraphicItem()
    self.arrow:SetAnchor(GUIItem.Middle, GUIItem.Top)
    self.arrow:SetTexture(kArrowTexture)
    self.arrow:SetSize(kArrowSize)
    self.arrow:SetPosition(Vector(-kArrowSize.x / 2, -kArrowSize.y, 0))
    self.shotgunImage:AddChild(self.arrow)
    
end

local function FindBestArmory(player)

    local nearbyArmories = GetEntitiesForTeamWithinRange("Armory", player:GetTeamNumber(), player:GetOrigin(), 20)
    for a = 1, #nearbyArmories do
    
        local armory = nearbyArmories[a]
        if armory:GetIsBuilt() then
            return armory
        end
        
    end
    
    return nil
    
end

function GUIBuyShotgunHelp:Update(dt)

    self.shotgunImage:SetIsVisible(false)
    self.arrow:SetIsVisible(false)
    
    if not self.shotgunBought then
    
        local player = Client.GetLocalPlayer()
        local shotgunResearched = MarineBuy_IsResearched(kTechId.Shotgun)
        local enoughResources = PlayerUI_GetPersonalResources() >= kShotgunCost
        
        if player and shotgunResearched and enoughResources then
        
            local armory = FindBestArmory(player)
            if armory then
            
                // We don't want the player trying to buy a shotgun if there are enemies nearby.
                local nearbyUnitsUnderAttack = GetAnyNearbyUnitsInCombat(player:GetOrigin(), 15, player:GetTeamNumber())
                if not nearbyUnitsUnderAttack then
                
                    self.shotgunImage:SetIsVisible(true)
                    local goalPos = Vector(Client.GetScreenWidth() / 2, Client.GetScreenHeight() / 2, 0) - (kIconSize / 2) - Vector(0, kIconSize.y, 0)
                    local armoryTop = armory:GetOrigin() + Vector(0, 3, 0)
                    local displayPoint = Client.WorldToScreen(armoryTop)
                    local dot = player:GetViewCoords().zAxis:DotProduct(GetNormalizedVector(armoryTop - player:GetEyePos()))
                    local inFront = dot > 0.8
                    if inFront then
                        goalPos = displayPoint - kIconSize / 2
                    else
                    
                        self.arrow:SetIsVisible(true)
                        local dot = player:GetViewCoords().xAxis:DotProduct(GetNormalizedVector(armoryTop - player:GetEyePos()))
                        local arrowDirection = (dot > 0) and (-math.pi / 2) or (math.pi / 2)
                        self.arrow:SetRotation(Vector(0, 0, arrowDirection))
                        
                    end
                    
                    if player:GetBuyMenuIsDisplaying() then
                        
                        self.shotgunImage:SetIsVisible(false)
                        self.shotgunBought = true
                        HelpWidgetIncreaseUse("GUIBuyShotgunHelp")
                        
                    end
                    
                    local currentPos = self.shotgunImage:GetPosition()
                    local posDiff = goalPos - currentPos
                    local moveSpeed = dt * 30
                    
                    if posDiff:GetLength() < moveSpeed then
                        currentPos = goalPos
                    else
                        currentPos = currentPos + posDiff * moveSpeed
                    end
                    
                    self.shotgunImage:SetPosition(currentPos)
                    
                end
                
            end
            
        end
        
    end
    
end

function GUIBuyShotgunHelp:Uninitialize()

    GUI.DestroyItem(self.shotgunImage)
    self.shotgunImage = nil
    
end