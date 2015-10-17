// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIInsight_OtherHealthbars.lua
//
// Created by: Jon 'Huze' Hughes (jon@jhuze.com)
//
// Commander: Displays structure/AI healthbars
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed unused structures

class 'GUIInsight_OtherHealthbars' (GUIScript)

local isVisible
local otherList
local reuseItems

local kOtherHealthDrainRate = 0.1 --Percent per ???

local kOtherHealthBarTexture = "ui/healthbarsmall.dds"
local kOtherHealthBarTextureSize = Vector(64, 6, 0)
local kOtherHealthBarSize
local kHealthDrainColor = Color(1, 0, 0, 1)
local kOtherTypes = {
    "CommandStructure",
    "ResourceTower",
    -- marine
    "Armory",
    "ArmsLab",
    "Observatory",
    "PhaseGate",
    "TurretFactory",
    "PrototypeLab",
    "Sentry",
    "InfantryPortal",
    "SiegeCannon",
    -- alien
    "Whip",
    "Crag",
    "Shade",
    "Shift",
    "Hydra"
}

function GUIInsight_OtherHealthbars:Initialize()

    self.updateInterval = 0
    
    isVisible = true
	
	kOtherHealthBarSize = GUIScale(Vector(64, 6, 0))
	
    otherList = table.array(24)
    reuseItems = table.array(32)

end

function GUIInsight_OtherHealthbars:Uninitialize()
   
    -- All healthbars
    for i, other in pairs(otherList) do
        GUI.DestroyItem(other.Background)
    end
    otherList = nil
    
    -- Reuse items
    for index, background in ipairs(reuseItems) do
        GUI.DestroyItem(background["Background"])
    end
    reuseItems = nil
    
end

function GUIInsight_OtherHealthbars:OnResolutionChanged(oldX, oldY, newX, newY)

    self:Uninitialize()
    kOtherHealthBarSize = GUIScale(Vector(64, 6, 0))
    self:Initialize()

end

function GUIInsight_OtherHealthbars:SetisVisible(bool)

    isVisible = bool

end

function GUIInsight_OtherHealthbars:Update(deltaTime)
      
    PROFILE("GUIInsight_OtherHealthbars:Update")
    
    local others
    for i=1, #kOtherTypes do
    
        others = Shared.GetEntitiesWithClassname(kOtherTypes[i])        
        -- Add new and Update all units
        
        for index, other in ientitylist(others) do
        
            local otherIndex = other:GetId()
            local relevant = other:GetIsVisible() and isVisible and other:GetIsAlive()
            if (other:isa("PowerPoint") and not other:GetIsSocketed()) then
                relevant = false
            end
            
            if relevant then
            
                local health = other:GetHealth() + other:GetArmor() * kHealthPointsPerArmor
                local maxHealth = other:GetMaxHealth() + other:GetMaxArmor() * kHealthPointsPerArmor
                local healthFraction = health / maxHealth
                
                -- Get/Create Healthbar
                local otherGUI
                if not otherList[otherIndex] then -- Add new GUI for new units
                
                    otherGUI = self:CreateOtherGUIItem()
                    otherGUI.StoredValues.HealthFraction = healthFraction
                    table.insert(otherList, otherIndex, otherGUI)
                    
                else
                
                    otherGUI = otherList[otherIndex]
                    
                end
                
                otherList[otherIndex].Visited = true
                
                local barScale = maxHealth/2400 -- Based off SiegeCannon health
                local backgroundSize = math.max(kOtherHealthBarSize.x, barScale * kOtherHealthBarSize.x)
                local kHealthbarOffset = Vector(-backgroundSize/2, -kOtherHealthBarSize.y - GUIScale(8), 0)
                
                -- Calculate Health Bar Screen position
                local min, max = other:GetModelExtents()
                local nameTagWorldPosition = other:GetOrigin() + Vector(0, max.y, 0)
                local nameTagInScreenspace = Client.WorldToScreen(nameTagWorldPosition) + kHealthbarOffset

                --local color = kHealthBarColors[other:GetTeamType()]
                local color = ConditionalValue(other:GetTeamType() == kAlienTeamType, kRedColor, kBlueColor)
                otherGUI.Background:SetIsVisible(true)

                -- Set Info
                
                -- background
                local background = otherGUI.Background
                background:SetPosition(nameTagInScreenspace)
                background:SetSize(Vector(backgroundSize,kOtherHealthBarSize.y, 0))
                
                -- healthbar
                local healthBar = otherGUI.HealthBar
                local healthBarSize =  healthFraction * backgroundSize - GUIScale(2)
                local healthBarTextureSize = healthFraction * kOtherHealthBarTextureSize.x
                healthBar:SetTexturePixelCoordinates(unpack({0, 0, healthBarTextureSize, kOtherHealthBarTextureSize.y}))
                healthBar:SetSize(Vector(healthBarSize, kOtherHealthBarSize.y, 0))
                healthBar:SetColor(color)
                
                -- health change bar              
                local healthChangeBar = otherGUI.HealthChangeBar
                local previousHealthFraction = otherGUI.StoredValues.HealthFraction
                if previousHealthFraction > healthFraction then
                
                    healthChangeBar:SetIsVisible(true)
                    local changeBarSize = (previousHealthFraction - healthFraction) * backgroundSize
                    local changeBarTextureSize = (previousHealthFraction - healthFraction) * kOtherHealthBarTextureSize.x
                    healthChangeBar:SetTexturePixelCoordinates(unpack({healthBarTextureSize, 0, healthBarTextureSize + changeBarTextureSize, kOtherHealthBarTextureSize.y}))
                    healthChangeBar:SetSize(Vector(changeBarSize, kOtherHealthBarSize.y, 0))
                    healthChangeBar:SetPosition(Vector(healthBarSize, 0, 0))
                    otherGUI.StoredValues.HealthFraction = math.max(healthFraction, previousHealthFraction - (deltaTime * kOtherHealthDrainRate))
                    
                else

                    healthChangeBar:SetIsVisible(false)
                    otherGUI.StoredValues.HealthFraction = healthFraction
                    
                end        
            end
        end
    end
    
    // Slay any Others that were not visited during the update.
    // dragonglass lol
    for id, other in pairs(otherList) do
        if not other.Visited then
            other.Background:SetIsVisible(false)
            table.insert(reuseItems, other)
            otherList[id] = nil
        end
        other.Visited = false
    end
    
end

function GUIInsight_OtherHealthbars:CreateOtherGUIItem()

    -- Reuse an existing healthbar item if there is one.
    if table.count(reuseItems) > 0 then
        local returnbackground = reuseItems[1]
        table.remove(reuseItems, 1)
        return returnbackground
    end

    local background = GUIManager:CreateGraphicItem()
    background:SetLayer(kGUILayerPlayerNameTags-1)
    background:SetColor(Color(0,0,0,0.75))
    
    local otherHealthBar = GUIManager:CreateGraphicItem()
    otherHealthBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    otherHealthBar:SetTexture(kOtherHealthBarTexture)
    otherHealthBar:SetPosition(Vector(GUIScale(1),0,0))
    background:AddChild(otherHealthBar)
    
    local otherHealthChangeBar = GUIManager:CreateGraphicItem()
    otherHealthChangeBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    otherHealthChangeBar:SetTexture(kOtherHealthBarTexture)
    otherHealthChangeBar:SetColor(kHealthDrainColor)
    otherHealthChangeBar:SetIsVisible(false)
    background:AddChild(otherHealthChangeBar)
    
    return { Background = background, HealthBar = otherHealthBar, HealthChangeBar = otherHealthChangeBar, StoredValues = {HealthFraction = -1} }

end