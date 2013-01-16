
Script.Load("lua/GUIScript.lua")
local kConsumptionTexture = "ui/digesting.dds"

class 'GUIMarineDevoured' (GUIScript)

function GUIMarineDevoured:Initialize()

    self.consumption = GetGUIManager():CreateGraphicItem()
    self.consumption:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0))
    self.consumption:SetTexture(kConsumptionTexture)
    self.consumption:SetIsVisible(false)

end

function GUIMarineDevoured:OnResolutionChanged()
    self.consumption:SetSize(Vector(Client.GetScreenWidth(), Client.GetScreenHeight(), 0))
end

function GUIMarineDevoured:Uninitialize()

    if self.consumption then
    
        GUI.DestroyItem(self.consumption)
        self.consumption = nil    
    
    end

end

function GUIMarineDevoured:Update(deltaTime)

    local player = Client.GetLocalPlayer()    
    self.consumption:SetIsVisible(player ~= nil and player:isa("Marine") and player:GetIsDevoured())

end