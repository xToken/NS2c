
-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\GUIPickups.lua
--
-- Created by: Brian Cronin (brianc@unknownworlds.com)
--
-- Manages displaying icons over entities on the ground the local player can pickup.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Added classic tech ids, tweaks for auto pickup

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
kPickupTextureYOffsets["HeavyMachineGun"] = 12
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
-- Note: This graphic can probably be smaller as we don't need the icons to be so big.
local kIconsTextureName = "ui/drop_icons.dds"
local kExpireBarTextureName = "ui/healthbarsmall.dds"
local kIconWorldOffset = Vector(0, 0.5, 0)
local kBounceSpeed = 2
local kBounceAmount = 0.05

class 'GUIPickups' (GUIScript)

GUIPickups.kUseColorIndicatorForExpirationBars = true
GUIPickups.kShouldShowExpirationBars = true
GUIPickups.kOnlyShowExpirationBarsForWeapons = false

function GUIPickups:Initialize()

    self.updateInterval = 0

    self.allPickupGraphics = { }
    
    self.visible = true

end

function GUIPickups:SetIsVisible(state)
    
    self.visible = state
    self:Update(0)
    
end

function GUIPickups:GetIsVisible()
    
    return self.visible
    
end

function GUIPickups:Uninitialize()

    for _, pickupGraphic in ipairs(self.allPickupGraphics) do
        GUI.DestroyItem(pickupGraphic.expireBarBg)
        GUI.DestroyItem(pickupGraphic.expireBar)
        GUI.DestroyItem(pickupGraphic)
    end
    self.allPickupGraphics = { }

end

function GUIPickups:GetFreePickupGraphic()

    for _, pickupGraphic in ipairs(self.allPickupGraphics) do

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

function GUIPickups_GetExpirationBarColor( timeLeft, alpha )
    alpha = alpha or 1
    if GUIPickups.kUseColorIndicatorForExpirationBars then
        if timeLeft >= 0.5 and timeLeft < 0.75 then
            return Color(1, 1, 0, alpha)
        elseif timeLeft >= 0.25 and timeLeft < 0.5 then
            return Color(1, 0.5, 0, alpha)
        elseif timeLeft < 0.25 then
            return Color(1, 0, 0, alpha)
        end
    end
    return Color(0, 0.6117, 1, distance)
end

function GUIPickups:Update()

    PROFILE("GUIPickups:Update")

    local localPlayer = Client.GetLocalPlayer()

    if localPlayer then

        for _, pickupGraphic in ipairs(self.allPickupGraphics) do
            pickupGraphic:SetIsVisible(false)
            pickupGraphic.expireBarBg:SetIsVisible(false)
            pickupGraphic.expireBar:SetIsVisible(false)
        end

        local nearbyPickups = GetNearbyPickups()
        for _, pickup in ipairs(nearbyPickups) do
            -- Check if the pickup is in front of the player.
            local playerForward = localPlayer:GetCoords().zAxis
            local playerToPickup = GetNormalizedVector(pickup:GetOrigin() - localPlayer:GetOrigin())
            local dotProduct = Math.DotProduct(playerForward, playerToPickup)

            if dotProduct > 0 then

                local timeLeft = pickup.GetExpireTimeFraction and pickup:GetExpireTimeFraction() or 0

                local isBarVisible = false
                if GUIPickups.kShouldShowExpirationBars then
                    isBarVisible = timeLeft > 0
                elseif GUIPickups.kOnlyShowExpirationBarsForWeapons then
                    isBarVisible = timeLeft > 0 and pickup:isa("Weapon")
                end

                local distance = pickup:GetDistanceSquared(localPlayer)
                distance = distance / (kPickupsVisibleRange * kPickupsVisibleRange)
                distance = 1 - distance
                local pickupSize = kMinPickupSize + ((kMaxPickupSize - kMinPickupSize) * distance)

                local bounceAmount = math.sin(Shared.GetTime() * kBounceSpeed) * kBounceAmount
                local pickupWorldPosition = pickup:GetOrigin() + kIconWorldOffset + Vector(0, bounceAmount, 0)
                local pickupInScreenspace = Client.WorldToScreen(pickupWorldPosition)
                -- Adjust for the size so it is in the middle.
                pickupInScreenspace = pickupInScreenspace + Vector(-pickupSize / 2, -pickupSize / 2, 0)

                local freePickupGraphic = self:GetFreePickupGraphic()
                freePickupGraphic:SetIsVisible(self.visible)		
				freePickupGraphic:SetColor(Color(1, 1, 1, distance))
				freePickupGraphic:SetSize(GUIScale(Vector(pickupSize, pickupSize, 0)))
				freePickupGraphic:SetPosition(Vector(pickupInScreenspace.x, pickupInScreenspace.y-5*distance, 0))					
				freePickupGraphic:SetTexturePixelCoordinates(GetPickupTextureCoordinates(pickup))
									
				freePickupGraphic.expireBarBg:SetIsVisible(self.visible and isBarVisible)
				freePickupGraphic.expireBar:SetIsVisible(self.visible and isBarVisible)
				if isBarVisible then
					
					local barColor = GUIPickups_GetExpirationBarColor( timeLeft, distance )  
				
					freePickupGraphic.expireBarBg:SetColor(Color(0, 0, 0, distance*0.75))                    
					freePickupGraphic.expireBar:SetColor(barColor)
					
					freePickupGraphic.expireBarBg:SetSize(GUIScale(Vector(pickupSize, 6, 0)))
					freePickupGraphic.expireBar:SetSize(GUIScale(Vector((pickupSize-1)*timeLeft, 6, 0)))
					freePickupGraphic.expireBar:SetTexturePixelCoordinates(0,0,64*timeLeft,6)
					
					freePickupGraphic.expireBar:SetPosition(Vector(pickupInScreenspace.x+1, pickupInScreenspace.y+GUIScale(pickupSize), 0))
					freePickupGraphic.expireBarBg:SetPosition(Vector(pickupInScreenspace.x, pickupInScreenspace.y+GUIScale(pickupSize), 0))
					
				end
            
            end

        end

    end

end