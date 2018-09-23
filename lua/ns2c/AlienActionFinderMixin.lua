-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\AlienActionFinderMixin.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Adjusted for classic use requirements

AlienActionFinderMixin = CreateMixin( AlienActionFinderMixin )
AlienActionFinderMixin.type = "AlienActionFinder"

AlienActionFinderMixin.expectedCallbacks =
{
    GetIsAlive = "Bool whether alive or not",
    PerformUseTrace = "Called to use",
    GetIsUsing = "Returns bool if using something"
}

function AlienActionFinderMixin:__initmixin()
    
    PROFILE("AlienActionFinderMixin:__initmixin")
    
    if Client and Client.GetLocalPlayer() == self then
    
        self.actionIconGUI = GetGUIManager():CreateGUIScript("GUIActionIcon")
        self.actionIconGUI:SetColor(kAlienFontColor)
        
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
        
        local ent = self:PerformUseTrace()
        if ent and (self:GetGameStarted() or (ent.GetUseAllowedBeforeGameStart and ent:GetUseAllowedBeforeGameStart())) then
        
            if GetPlayerCanUseEntity(self, ent) and not self:GetIsUsing() then
            
         		local hintText = nil
                if ent:isa("Hive") and ent:GetIsBuilt() then
                    hintText = "TELEPORT_HIVE"
                elseif ent:isa("Hive") and not ent:GetIsBuilt() then
                    hintText = "ALERT_DANGER"
				elseif ent:isa("Shift") and ent:GetIsBuilt() then
				    hintText = "REDEPLOYMENT_UPGRADE"
				elseif HasMixin(ent, "Construct") and not ent:GetIsBuilt() then
					hintText = "ALIEN_CONSTRUCT"
                end
                
                self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("Use"), nil, hintText)
                success = true
                
            else
                self.actionIconGUI:Hide()
            end
            
        else
            self.actionIconGUI:Hide()
        end
        
    end
    
end
