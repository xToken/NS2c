// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\AlienActionFinderMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

local kIconUpdateRate = 0.5

AlienActionFinderMixin = CreateMixin( AlienActionFinderMixin )
AlienActionFinderMixin.type = "AlienActionFinder"

AlienActionFinderMixin.expectedCallbacks =
{
    GetIsAlive = "Bool whether alive or not",
    PerformUseTrace = "Called to use",
    GetIsUsing = "Returns bool if using something"
}

function AlienActionFinderMixin:__initmixin()

    if Client and Client.GetLocalPlayer() == self then
    
        self.actionIconGUI = GetGUIManager():CreateGUIScript("GUIActionIcon")
        self.lastAlienActionFindTime = 0
        
    end

end

function AlienActionFinderMixin:OnDestroy()

    if Client and self.actionIconGUI then
    
        GetGUIManager():DestroyGUIScript(self.actionIconGUI)
        self.actionIconGUI = nil
        
    end

end

if Client then

    function AlienActionFinderMixin:OnProcessMove(input)
    
        PROFILE("AlienActionFinderMixin:OnProcessMove")
        
        local gameStarted = self:GetGameStarted()
        local prediction = Shared.GetIsRunningPrediction()
        local now = Shared.GetTime()
        local enoughTimePassed = (now - self.lastAlienActionFindTime) >= kIconUpdateRate
        if gameStarted and not prediction and enoughTimePassed then
        
            self.lastAlienActionFindTime = now
            
            local success = false
            
            if Client.GetOptionBoolean("showHints", true) and self:GetIsAlive() then
            
                local ent = self:PerformUseTrace()
                if ent then
                
                    if GetPlayerCanUseEntity(self, ent) and not self:GetIsUsing() then
                    
                        // Don't show hint for an empty hive if you have a comm
                        if not ent:isa("Hive") or not ScoreboardUI_GetTeamHasCommander(self:GetTeamNumber()) then
                        
                  			local hintText = nil
                            if ent:isa("Hive") and ent:GetIsBuilt() then
                                hintText = "TELEPORT_HIVE"
                            elseif ent:isa("Hive") and not ent:GetIsBuilt() then
                                hintText = "ALERT_DANGER"
							elseif ent:isa("Shift") and ent:GetIsBuilt() then
							    hintText = "REDEPLOYMENT_UPGRADE"
							else
								hintText = "ALIEN_CONSTRUCT"
                            end
                            
                            self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("Use"), nil, hintText)
                            success = true
                            
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