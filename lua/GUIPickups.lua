
// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIPickups.lua
//
// Created by: Brian Cronin (brianc@unknownworlds.com)
//
// Manages displaying icons over entities on the ground the local player can pickup.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Added classic tech ids, tweaks for auto pickup

local kPickupsVisibleRange = 15

local function GetNearbyPickups()

    local localPlayer = Client.GetLocalPlayer()
    
    if localPlayer then
    
        local team = localPlayer:GetTeamNumber()
        local origin = localPlayer:GetOrigin()
        
        local function PickupableFilterFunction(entity)
        
            local sameTeam = entity:GetTeamNumber() == team
            local canPickup = entity:GetIsValidRecipient(localPlayer, false)
            return sameTeam and canPickup
            
        end
        
        return Shared.GetEntitiesWithTagInRange("Pickupable", origin, kPickupsVisibleRange, PickupableFilterFunction)
        
    end
    
    return nil

end

local kPickupTextureYOffsets = { }
kPickupTextureYOffsets["AmmoPack"] = 0
kPickupTextureYOffsets["CatPack"] = 11
kPickupTextureYOffsets["MedPack"] = 1
kPickupTextureYOffsets["Rifle"] = 2
kPickupTextureYOffsets["Shotgun"] = 3
kPickupTextureYOffsets["Pistol"] = 4
kPickupTextureYOffsets["GrenadeLauncher"] = 6
kPickupTextureYOffsets["Welder"] = 7
kPickupTextureYOffsets["Builder"] = 7
kPickupTextureYOffsets["Jetpack"] = 8
kPickupTextureYOffsets["HeavyMachineGun"] = 2
kPickupTextureYOffsets["Mines"] = 9
kPickupTextureYOffsets["HeavyArmor"] = 10
kPickupTextureYOffsets["HandGrenades"] = 6

local kPickupIconHeight = 64
local kPickupIconWidth = 64

local function GetPickupTextureCoordinates(pickup)

    local yOffset = nil
    for pickupType, pickupTextureYOffset in pairs(kPickupTextureYOffsets) do
    
        if pickup:isa(pickupType) then
        
            yOffset = pickupTextureYOffset
            break
            
        end
        
    end
    assert(yOffset)
    
    return 0, yOffset * kPickupIconHeight, kPickupIconWidth, (yOffset + 1) * kPickupIconHeight

end

local kMinPickupSize = 16
local kMaxPickupSize = 48
// Note: This graphic can probably be smaller as we don't need the icons to be so big.
local kIconsTextureName = "ui/drop_icons.dds"
local kExpireBarTextureName = "ui/healthbarsmall.dds"
local kIconWorldOffset = Vector(0, 0.5, 0)
local kBounceSpeed = 2
local kBounceAmount = 0.05

class 'GUIPickups' (GUIScript)

function GUIPickups:Initialize()

    self.updateInterval = 0
    
    self.allPickupGraphics = { }

end

function GUIPickups:Uninitialize()

    for i, pickupGraphic in ipairs(self.allPickupGraphics) do
        GUI.DestroyItem(pickupGraphic.expireBarBg)
        GUI.DestroyItem(pickupGraphic.expireBar)
        GUI.DestroyItem(pickupGraphic)
    end
    self.allPickupGraphics = { }

end

function GUIPickups:GetFreePickupGraphic()

    for i, pickupGraphic in ipairs(self.allPickupGraphics) do
    
        if pickupGraphic:GetIsVisible() == false then
            return pickupGraphic
        end
    
    end

    local newPickupGraphic = GUIManager:CreateGraphicItem()
    newPickupGraphic:SetAnchor(GUIItem.Left, GUIItem.Top)
    newPickupGraphic:SetTexture(kIconsTextureName)
    newPickupGraphic:SetIsVisible(false)
    
    local newPickupGraphicExpireBarBg = GUIManager:CreateGraphicItem()
    newPickupGraphicExpireBarBg:SetAnchor(GUIItem.Left, GUIItem.Top)
    newPickupGraphicExpireBarBg:SetIsVisible(false)
    
    local newPickupGraphicExpireBar = GUIManager:CreateGraphicItem()
    newPickupGraphicExpireBar:SetAnchor(GUIItem.Left, GUIItem.Top)
    newPickupGraphicExpireBar:SetTexture(kExpireBarTextureName)
    newPickupGraphicExpireBar:SetIsVisible(false)
    
    newPickupGraphic.expireBarBg = newPickupGraphicExpireBarBg
    newPickupGraphic.expireBar = newPickupGraphicExpireBar
    
    table.insert(self.allPickupGraphics, newPickupGraphic)
    
    return newPickupGraphic

end

function GUIPickups:Update(deltaTime)

    PROFILE("GUIPickups:Update")
    
    local localPlayer = Client.GetLocalPlayer()
    
    if localPlayer then
    
        for i, pickupGraphic in ipairs(self.allPickupGraphics) do
            pickupGraphic:SetIsVisible(false)
            pickupGraphic.expireBarBg:SetIsVisible(false)
            pickupGraphic.expireBar:SetIsVisible(false)
        end
        
        local nearbyPickups = GetNearbyPickups()
        for i, pickup in ipairs(nearbyPickups) do
            -- Check if the pickup is in front of the player.
            local playerForward = localPlayer:GetCoords().zAxis
            local playerToPickup = GetNormalizedVector(pickup:GetOrigin() - localPlayer:GetOrigin())
            local dotProduct = Math.DotProduct(playerForward, playerToPickup)
            
            if dotProduct > 0 then
            
                local freePickupGraphic = self:GetFreePickupGraphic()
                freePickupGraphic:SetIsVisible(true)
                
                -- Make it easily moddable, allow access to some of the data we had access to
                freePickupGraphic.expireFraction = pickup.GetExpireTimeFraction and pickup:GetExpireTimeFraction() or 0
                freePickupGraphic.isWeapon = pickup:isa("Weapon")
                
                local timeLeft = freePickupGraphic.expireFraction
                
                freePickupGraphic.expireBarBg:SetIsVisible(timeLeft > 0)
                freePickupGraphic.expireBar:SetIsVisible(timeLeft > 0)
                               
                local distance = pickup:GetDistanceSquared(localPlayer)
                distance = distance / (kPickupsVisibleRange * kPickupsVisibleRange)
                distance = 1 - distance
                
                freePickupGraphic:SetColor(Color(1, 1, 1, distance))
                freePickupGraphic.expireBarBg:SetColor(Color(0, 0, 0, distance*0.75))
                freePickupGraphic.expireBar:SetColor(Color(0, 0.6117, 1, distance))
                
                local pickupSize = kMinPickupSize + ((kMaxPickupSize - kMinPickupSize) * distance)
                freePickupGraphic:SetSize(GUIScale(Vector(pickupSize, pickupSize, 0)))
                freePickupGraphic.expireBarBg:SetSize(GUIScale(Vector(pickupSize, 6, 0)))
                freePickupGraphic.expireBar:SetSize(GUIScale(Vector((pickupSize-1)*timeLeft, 6, 0)))
                freePickupGraphic.expireBar:SetTexturePixelCoordinates(0,0,64*timeLeft,6)
                
                local bounceAmount = math.sin(Shared.GetTime() * kBounceSpeed) * kBounceAmount
                local pickupWorldPosition = pickup:GetOrigin() + kIconWorldOffset + Vector(0, bounceAmount, 0)
                local pickupInScreenspace = Client.WorldToScreen(pickupWorldPosition)
                // Adjust for the size so it is in the middle.
                pickupInScreenspace = pickupInScreenspace + Vector(-pickupSize / 2, -pickupSize / 2, 0)
                freePickupGraphic:SetPosition(Vector(pickupInScreenspace.x, pickupInScreenspace.y-5*distance, 0))
                freePickupGraphic.expireBar:SetPosition(Vector(pickupInScreenspace.x+1, pickupInScreenspace.y+GUIScale(pickupSize), 0))
                freePickupGraphic.expireBarBg:SetPosition(Vector(pickupInScreenspace.x, pickupInScreenspace.y+GUIScale(pickupSize), 0))
                
                freePickupGraphic:SetTexturePixelCoordinates(GetPickupTextureCoordinates(pickup))
                
            end
        
        end
        
    end
    
end