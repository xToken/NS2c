// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Marine_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed some uneeded effects and other functions that were moved to player_client

Marine.kBuyMenuTexture = "ui/marine_buymenu.dds"
Marine.kBuyMenuUpgradesTexture = "ui/marine_buymenu_upgrades.dds"
Marine.kBuyMenuiconsTexture = "ui/marine_buy_icons.dds"

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/marine_highlight.surface_shader")
local kSensorBlipSize = 25

function Marine:GetHealthbarOffset()
    return 1.2
end

function MarineUI_GetHasObservatory()

    local player = Client.GetLocalPlayer()
    
    if player and player:GetGameMode() == kGameMode.Classic then    
        return GetHasTech(player, kTechId.Observatory)
    elseif player and player:GetGameMode() == kGameMode.Combat then    
        return true
    end
    
    return false

end

function MarineUI_GetHasArmsLab()

    local player = Client.GetLocalPlayer()
    
    if player and player:GetGameMode() == kGameMode.Classic then
        return GetHasTech(player, kTechId.ArmsLab)
    elseif player and player:GetGameMode() == kGameMode.Combat then    
        return true
    end
    
    return false
    
end

function MarineUI_GetPersonalUpgrades()

    local upgrades = { }
    local player = Client.GetLocalPlayer()
    local techTree = player:GetTechTree()
    
    if techTree then
    
        for _, upgradeId in ipairs(techTree:GetAddOnsForTechId(kTechId.AllMarines)) do
            table.insert(upgrades, upgradeId)
        end
    
    end
    
    return upgrades

end

function Marine:UnitStatusPercentage()
    return self.unitStatusPercentage
end

function Marine:UpdateClientEffects(deltaTime, isLocal)
    
    Player.UpdateClientEffects(self, deltaTime, isLocal)
    
    if isLocal then
        
        self:UpdateGhostModel()

        local marineHUD = ClientUI.GetScript("Hud/Marine/GUIMarineHUD")
        if marineHUD then
            marineHUD:SetIsVisible(self:GetIsAlive())
        end
        
        if self.buyMenu then
        
            if not self:GetIsAlive() then
                self:CloseMenu()
            end
            
        end  
        
    end
    
    
end

function Marine:OnUpdateRender()

    PROFILE("Marine:OnUpdateRender")
    
    Player.OnUpdateRender(self)
    
    local isLocal = self:GetIsLocalPlayer()
    
    // Synchronize the state of the light representing the flash light.
    self.flashlight:SetIsVisible(self.flashlightOn and (isLocal or self:GetIsVisible()) )
    
    if self.flashlightOn then
    
        local coords = Coords(self:GetViewCoords())
        coords.origin = coords.origin + coords.zAxis * 0.75
        
        self.flashlight:SetCoords(coords)
        
        // Only display atmospherics for third person players.
        local density = 0.2
        if isLocal and not self:GetIsThirdPerson() then
            density = 0
        end
        self.flashlight:SetAtmosphericDensity(density)
        
    end

end

function Marine:AddNotification(locationId, techId)

    local locationName = ""

    if locationId ~= 0 then
        locationName = Shared.GetString(locationId)
    end

    table.insert(self.notifications, { LocationName = locationName, TechId = techId })

end

// this function returns the oldest notification and clears it from the list
function Marine:GetAndClearNotification()

    local notification = nil

    if table.count(self.notifications) > 0 then
    
        notification = { LocationName = self.notifications[1].LocationName, TechId = self.notifications[1].TechId }
        table.remove(self.notifications, 1)
    
    end
    
    return notification

end

// Bring up buy menu
function Marine:Buy()
    
    // Don't allow display in the ready room
    if self:GetTeamNumber() ~= 0 and Client.GetLocalPlayer() == self and self:GetGameMode() == kGameMode.Combat then
    
        if not self.buyMenu then
        
            self.buyMenu = GetGUIManager():CreateGUIScript("GUIMarineBuyMenu")
            MouseTracker_SetIsVisible(true, "ui/Cursor_MenuDefault.dds", true)
            self:TriggerEffects("marine_buy_menu_open")
            
            TEST_EVENT("Marine buy menu displayed")
            
                
        else
            self:CloseMenu()
        end
        
    end
    
end

function Marine:UpdateMisc(input)

    Player.UpdateMisc(self, input)
    
    if not Shared.GetIsRunningPrediction() then

        if input.move.x ~= 0 or input.move.z ~= 0 then

            self:CloseMenu()
            
        end
        
    end
    
end

// Give dynamic camera motion to the player
/*
function Marine:PlayerCameraCoordsAdjustment(cameraCoords) 

    if self:GetIsFirstPerson() then
        
        if self:GetIsStunned() then
            local attachPointOffset = self:GetAttachPointOrigin("Head") - cameraCoords.origin
            attachPointOffset.x = attachPointOffset.x * .5
            attachPointOffset.z = attachPointOffset.z * .5
            cameraCoords.origin = cameraCoords.origin + attachPointOffset
        end
    
    end
    
    return cameraCoords

end*/

function Marine:OnCountDown()

    Player.OnCountDown(self)
    
    local script = ClientUI.GetScript("Hud/Marine/GUIMarineHUD")
    if script then
        script:SetIsVisible(false)
    end
    
end

function Marine:OnCountDownEnd()

    Player.OnCountDownEnd(self)
    
    local script = ClientUI.GetScript("Hud/Marine/GUIMarineHUD")
    if script then
    
        script:SetIsVisible(true)
        script:TriggerInitAnimations()
        
    end
    
end

function Marine:OnOrderSelfComplete(orderType)
    self:TriggerEffects("complete_order")
end

function Marine:UpdateGhostModel()

    self.currentTechId = nil
    self.ghostStructureCoords = nil
    self.ghostStructureValid = false
    self.showGhostModel = false
    
    local weapon = self:GetActiveWeapon()

    if weapon and weapon:isa("Mines") then
    
        self.currentTechId = kTechId.Mine
        self.ghostStructureCoords = weapon:GetGhostModelCoords()
        self.ghostStructureValid = weapon:GetIsPlacementValid()
        self.showGhostModel = weapon:GetShowGhostModel()
    
    end

end

function Marine:GetShowGhostModel()
    return self.showGhostModel
end    

function Marine:GetGhostModelTechId()
    return self.currentTechId
end

function Marine:GetGhostModelCoords()
    return self.ghostStructureCoords
end

function Marine:GetIsPlacementValid()
    return self.ghostStructureValid
end