// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIInsight_OtherHealthbars.lua
//
// Created by: Jon 'Huze' Hughes (jon@jhuze.com)
//
// Commander: Displays structure/AI healthbars
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIInsight_OtherHealthbars' (GUIScript)

local isVisible
local otherList
local reusebackgrounds

local kOtherHealthDrainRate = 0.1 --Percent per ???

local kOtherHealthBarTexture = "ui/healthbarsmall.dds"
local kOtherHealthBarTextureSize = Vector(64, 6, 0)
local kOtherHealthBarSize = GUIScale(Vector(64, 6, 0))
local kHealthDrainColor = Color(1, 0, 0, 1)
local kOtherTypes = {
    "CommandStructure",
    "ResourceTower",
    -- marine
    "Armory",    
    "ArmsLab",
    "Observatory",
    "PhaseGate",
    "RoboticsFactory",
    "PrototypeLab",
    "Sentry",
    "InfantryPortal",
    "ARC",
    -- alien
    "Crag",
    "Shade",
    "Shift",
    "Hydra"
}

function GUIInsight_OtherHealthbars:Initialize()

    isVisible = true

    otherList = table.array(24)
    for index, otherType in ipairs(kOtherTypes) do
        otherList[otherType] = table.array(4)
    end
    
    reusebackgrounds = table.array(32)

end

function GUIInsight_OtherHealthbars:Uninitialize()
   
    -- All healthbars
    for index, otherType in ipairs(kOtherTypes) do
        local currentList = otherList[otherType]
        for i, other in pairs(currentList) do
            GUI.DestroyItem(other.Background)
        end
        otherList[otherType] = nil
    end
    otherList = nil
    
    -- Reuse items
    for index, background in ipairs(reusebackgrounds) do
        GUI.DestroyItem(background["Background"])
    end
    reusebackgrounds = nil
    
end

function GUIInsight_OtherHealthbars:OnResolutionChanged(oldX, oldY, newX, newY)

    self:Uninitialize()
    kOtherHealthBarSize = GUIScale(Vector(64, 6, 0))
    self:Initialize()

end

function GUIInsight_OtherHealthbars:SetisVisible(bool)

    isVisible = bool

end

function GUIInsight_OtherHealthbars:SendKeyEvent(key, down)

    if key == InputKey.LeftControl and down then
    
        self:SetisVisible(not isVisible)
    
    end

end

function GUIInsight_OtherHealthbars:Update(deltaTime)

    local player = Client.GetLocalPlayer()
    if not player then
        return
    end

    self:UpdateOthers(deltaTime)
    
end

function GUIInsight_OtherHealthbars:UpdateOthers(deltaTime)

    local others
    local currentList
    for _, otherType in ipairs(kOtherTypes) do
    
        others = Shared.GetEntitiesWithClassname(otherType)
        currentList = otherList[otherType]
        
        -- Remove old units
            
        for id, other in pairs(currentList) do
        
            local contains = false
            for key, newUnit in ientitylist(others) do
                if id == newUnit:GetId() then
                    contains = true
                end
            end

            if not contains then
            
                -- Store unused healthbars for later
                other.Background:SetIsVisible(false)
                table.insert(reusebackgrounds, other)
                currentList[id] = nil
                
            end
        end
        
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
                if not currentList[otherIndex] then -- Add new GUI for new units
                
                    otherGUI = self:CreateOtherGUIItem()
                    otherGUI.StoredValues.HealthFraction = healthFraction
                    table.insert(currentList, otherIndex, otherGUI)
                    
                else
                
                    otherGUI = currentList[otherIndex]
                    
                end
                
                local barScale = maxHealth/2400 -- Based off ARC health                 
                local backgroundSize = math.max(kOtherHealthBarSize.x, barScale * kOtherHealthBarSize.x)
                local kHealthbarOffset = Vector(-backgroundSize/2, -kOtherHealthBarSize.y - GUIScale(8), 0)
                
                -- Calculate Health Bar Screen position
                local min, max = other:GetModelExtents()
                local nameTagWorldPosition = other:GetOrigin() + Vector(0, max.y, 0)
                local nameTagInScreenspace = Client.WorldToScreen(nameTagWorldPosition) + kHealthbarOffset

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
                
            else -- No longer relevant, remove if necessary
        
                if currentList[otherIndex] then
                    GUI.DestroyItem(currentList[otherIndex].Background)
                    currentList[otherIndex] = nil
                end
        
            end

        end
    
    end

end

function GUIInsight_OtherHealthbars:CreateOtherGUIItem()

    -- Reuse an existing healthbar item if there is one.
    if table.count(reusebackgrounds) > 0 then
        local returnbackground = reusebackgrounds[1]
        table.remove(reusebackgrounds, 1)
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