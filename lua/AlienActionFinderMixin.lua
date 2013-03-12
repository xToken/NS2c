// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\AlienActionFinderMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

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
        if ent and self:GetGameStarted() then
        
            if GetPlayerCanUseEntity(self, ent) and not self:GetIsUsing() then
                if ent:isa("Hive") then
					if ent:GetIsBuilt() then
						self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("Use"), nil, kNS2cLocalizedStrings.TELEPORT_HIVE, nil)
                    else
						self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("Use"), nil, kNS2cLocalizedStrings.ALERT_DANGER, nil)
                    end
                elseif ent:isa("Shift") and ent:GetIsBuilt() then
                    self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("Use"), nil, kNS2cLocalizedStrings.REDEPLOYMENT_UPGRADE, nil)
				else
                    self.actionIconGUI:ShowIcon(BindingsUI_GetInputValue("Use"), nil, kNS2cLocalizedStrings.ALIEN_CONSTRUCT, nil)
                end
                
            else
                self.actionIconGUI:Hide()
            end
            
        else
            self.actionIconGUI:Hide()
        end
        
    end
    
end