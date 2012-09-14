// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\MarineActionFinderMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

local kFindWeaponRange = 1.5
local kIconUpdateRate = 0.5

local function FindNearbyWeapon(self, toPosition)

    local nearbyWeapons = GetEntitiesWithMixinWithinRange("Pickupable", toPosition, kFindWeaponRange)
    local closestWeapon = nil
    local closestDistance = Math.infinity
    for i, nearbyWeapon in ipairs(nearbyWeapons) do
    
        if nearbyWeapon:isa("Weapon") and nearbyWeapon:GetIsValidRecipient(self) then
        
            local nearbyWeaponDistance = (nearbyWeapon:GetOrigin() - toPosition):GetLengthSquared()
            if nearbyWeaponDistance < closestDistance then
            
                closestWeapon = nearbyWeapon
                closestDistance = nearbyWeaponDistance
            
            end
            
        end
        
    end
    
    return closestWeapon

end

MarineActionFinderMixin = CreateMixin( MarineActionFinderMixin )
MarineActionFinderMixin.type = "MarineActionFinder"

MarineActionFinderMixin.expectedCallbacks =
{
    GetOrigin = "Returns the position of the Entity in world space"
}

function MarineActionFinderMixin:__initmixin()

    if Client and Client.GetLocalPlayer() == self then
    
        self.actionIconGUI = GetGUIManager():CreateGUIScript("GUIActionIcon")
        self.lastMarineActionFindTime = 0
        
    end

end

function MarineActionFinderMixin:OnDestroy()

    if Client and self.actionIconGUI then
    
        GetGUIManager():DestroyGUIScript(self.actionIconGUI)
        self.actionIconGUI = nil
        
    end

end

function MarineActionFinderMixin:GetNearbyPickupableWeapon()
    return FindNearbyWeapon(self, self:GetOrigin())
end

if Client then

    function MarineActionFinderMixin:OnProcessMove(input)
    
        PROFILE("MarineActionFinderMixin:OnProcessMove")
        
        local gameStarted = self:GetGameStarted()
        local prediction = Shared.GetIsRunningPrediction()
        local now = Shared.GetTime()
        local enoughTimePassed = (now - self.lastMarineActionFindTime) >= kIconUpdateRate
        if gameStarted and not prediction and enoughTimePassed then
        
            self.lastMarineActionFindTime = now
            
            local success = false
            
            if Client.GetOptionBoolean("showHints", true) then
            
                if self:GetIsAlive() then
                
                    local foundNearbyWeapon = FindNearbyWeapon(self, self:GetOrigin())
                    
                    if foundNearbyWeapon then
                    
                        self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("Drop"), foundNearbyWeapon:GetClassName())
                        success = true
                        
                    else
                    
                        local ent = self:PerformUseTrace()
                        if ent then
                        
                            if GetPlayerCanUseEntity(self, ent) and not self:GetIsUsing() then
                            
                                local hintText = nil
                                if ent:isa("CommandStation") then
                                    hintText = "START_COMMANDING"
                                end

                                self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("Use"), nil, hintText)
                                success = true
                                
                            end
                        
                        end
                        
                    end
                    
                end
                
            end
            
            if not success then
                self.actionIconGUI:Hide()
            end
            
        end
        
    end
    
end