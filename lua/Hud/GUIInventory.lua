// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIInventory.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// Displays the ability/weapon icons.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GUIInventory'

GUIInventory.kTexture = "ui/marine_messages_icons.dds"
GUIInventory.kFontName = "fonts/AgencyFB_tiny.fnt"

GUIInventory.kBackgroundYOffset = GUIScale(-100)

GUIInventory.kActiveColor = Color(1,1,1,1)
GUIInventory.kInactiveColor = Color(0.6, 0.6, 0.6, 0.6)

GUIInventory.kItemSize = Vector(128, 64, 0)
GUIInventory.kItemPadding = 20

function CreateInventoryDisplay(scriptHandle, hudLayer, frame)

    local inventoryDisplay = GUIInventory()
    inventoryDisplay.script = scriptHandle
    inventoryDisplay.hudLayer = hudLayer
    inventoryDisplay.frame = frame
    inventoryDisplay:Initialize()
    
    return inventoryDisplay

end

local gTechIdPosition = nil
local function GetCoordsForTechId(techId)

    local x1 = 0
    local y1 = 0
    local x2 = 128
    local y2 = 0
    
    if not gTechIdPosition then
    
        gTechIdPosition = {}
        
        // marine weapons
        gTechIdPosition[kTechId.Rifle] = 1
        gTechIdPosition[kTechId.Pistol] = 3
        gTechIdPosition[kTechId.Axe] = 4
        gTechIdPosition[kTechId.Shotgun] = 5
        gTechIdPosition[kTechId.HeavyMachineGun] = 6
        gTechIdPosition[kTechId.GrenadeLauncher] = 8
        gTechIdPosition[kTechId.Welder] = 10
        gTechIdPosition[kTechId.Mines] = 21
        gTechIdPosition[kTechId.HandGrenades] = 8
                
        // alien abilities
        gTechIdPosition[kTechId.Bite] = 11
        gTechIdPosition[kTechId.Parasite] = 12
        gTechIdPosition[kTechId.Xenocide] = 22
        
        gTechIdPosition[kTechId.Spit] = 23
        gTechIdPosition[kTechId.BuildAbility] = 18
        gTechIdPosition[kTechId.BuildAbility2] = 18
        gTechIdPosition[kTechId.BileBomb] = 20
        
        gTechIdPosition[kTechId.LerkBite] = 11
        gTechIdPosition[kTechId.Spores] = 16
        gTechIdPosition[kTechId.Umbra] = 13
        
        gTechIdPosition[kTechId.SwipeBlink] = 17
        gTechIdPosition[kTechId.Metabolize] = 27
        gTechIdPosition[kTechId.AcidRocket] = 26
        
        gTechIdPosition[kTechId.Gore] = 22
        gTechIdPosition[kTechId.Smash] = 22
        
    end
    
    local position = gTechIdPosition[techId]
    
    if position then
    
        y1 = position * 64
        y2 = y1 + 64
    
    end
    
    return x1, y1, x2, y2

end

local function CreateInventoryItem(self, index, alienStyle)

    local item = self.script:CreateAnimatedGraphicItem()
    
    item:SetSize(GUIInventory.kItemSize)
    item:SetTexture(GUIInventory.kTexture)
    item:AddAsChildTo(self.background)
    
    local key, keyText = GUICreateButtonIcon("Weapon1", alienStyle)
    key:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    
    key:SetInheritsParentAlpha(true)
    keyText:SetInheritsParentAlpha(true)
    
    local keySize = key:GetSize()    
    key:SetPosition(Vector(keySize.x * -.5, keySize.y * -.25, 0))
    
    item:AddChild(key)
    
    local result = { Graphic = item, KeyText = keyText }
    
    table.insert(self.inventoryIcons, result)
    
    return result

end

local function LocalAdjustSlot(self, index, hudSlot, techId, isActive, resetAnimations, alienStyle)

    local inventoryItem = nil

    if self.inventoryIcons[index] then
        inventoryItem = self.inventoryIcons[index]
    else
        inventoryItem = CreateInventoryItem(self, index)
        inventoryItem.Graphic:Pause(2, "ANIM_INVENTORY_ITEM_PAUSE", AnimateLinear, function(script, item) item:FadeOut(0.5, "ANIM_INVENTORY_ITEM") end )
    end
    
    inventoryItem.KeyText:SetText(BindingsUI_GetInputValue("Weapon" .. hudSlot))
    inventoryItem.Graphic:SetUniformScale(self.scale)
    inventoryItem.Graphic:SetTexturePixelCoordinates(GetCoordsForTechId(techId))
    inventoryItem.Graphic:SetPosition(Vector( (GUIInventory.kItemPadding + GUIInventory.kItemSize.x) * index , 0, 0) )
    
    if resetAnimations then
        inventoryItem.Graphic:Pause(2, "ANIM_INVENTORY_ITEM_PAUSE", AnimateLinear, function(script, item) item:FadeOut(0.5, "ANIM_INVENTORY_ITEM") end )    
    end
    
    if inventoryItem.Graphic:GetHasAnimation("ANIM_INVENTORY_ITEM_PAUSE") then
        inventoryItem.Graphic:SetColor(ConditionalValue(isActive, GUIInventory.kActiveColor, GUIInventory.kInactiveColor))
    end

end

function GUIInventory:Initialize()

    self.scale = 1
    
    self.lastPersonalResources = 0
    
    self.background = GetGUIManager():CreateGraphicItem()
    self.background:SetColor(Color(0,0,0,0))
    self.background:SetAnchor(GUIItem.Middle, GUIItem.Bottom)
    self.frame:AddChild(self.background)
    
    self.inventoryIcons = {}

end

function GUIInventory:Reset(scale)

    self.scale = scale    
    self.background:SetPosition(Vector(0, GUIInventory.kBackgroundYOffset, 0) * self.scale)

end

function GUIInventory:SetIsVisible(visible)
    self.background:SetIsVisible(visible)
end

function GUIInventory:Update(deltaTime, parameters)

    local activeWeaponTechId, inventoryTechIds = unpack(parameters)
    
    if #self.inventoryIcons > #inventoryTechIds then
    
        self.inventoryIcons[#self.inventoryIcons].Graphic:Destroy()
        table.remove(self.inventoryIcons, #self.inventoryIcons)
        
    end
    
    local resetAnimations = false
    if activeWeaponTechId ~= self.lastActiveWeaponTechId and gTechIdPosition and gTechIdPosition[activeWeaponTechId] then

        self.lastActiveWeaponTechId = activeWeaponTechId
        resetAnimations = true
        
    end
    
    self.background:SetPosition(Vector( (-#inventoryTechIds-1) * (GUIInventory.kItemPadding + GUIInventory.kItemSize.x *.5 ) * self.scale, GUIInventory.kBackgroundYOffset, 0  ) )
    
    local alienStyle = PlayerUI_GetTeamType() == kAlienTeamType
    
    for index, inventoryItem in ipairs(inventoryTechIds) do
        LocalAdjustSlot(self, index, inventoryItem.HUDSlot, inventoryItem.TechId, inventoryItem.TechId == activeWeaponTechId, resetAnimations, alienStyle)
    end
    
end

function GUIInventory:Destroy()

    if self.background then
        GUI.DestroyItem(self.background)
        self.background = nil
    end

end