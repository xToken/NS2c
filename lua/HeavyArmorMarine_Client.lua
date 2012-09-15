//
// lua\HeavyArmorMarine_Client.lua

function HeavyArmorMarine:TriggerFootstep()

     Player.TriggerFootstep(self)
    if self == Client.GetLocalPlayer() and not self:GetIsThirdPerson() then
        local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
        cinematic:SetRepeatStyle(Cinematic.Repeat_None)       
    end

end