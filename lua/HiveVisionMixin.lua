// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========    
//    
// lua\HiveVision.lua    
//    
//    Created by:   Max McGuire (max@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

//NS2c
//Removed outline on marines that took damage recently.

HiveVisionMixin = CreateMixin( HiveVisionMixin )
HiveVisionMixin.type = "HiveVision"

HiveVisionMixin.expectedMixins =
{
    Team = "For making friendly players visible",
    Model = "For copying bonecoords and drawing model in view model render zone.",
    Live = "For taking damage (has LiveMixin).",
}

local Shared_GetTime = Shared.GetTime
local kHiveSightDuration = 8

function HiveVisionMixin:__initmixin()

    if Client then
        self.hiveSightVisible = false
        self.hiveSightTime = 0
    end

end

if Client then

    function HiveVisionMixin:OnUpdate(deltaTime)   
            
        local time = Shared_GetTime()
        
        // Determine if the entity should be visible on hive sight
        local visible = false

        if (time - self.hiveSightTime) < kHiveSightDuration then
            visible = true        
        elseif self:isa("Player") then
            // Make friendly players always show up.
            local player = Client.GetLocalPlayer()
            if player ~= self and GetAreFriends(self, player) then
                visible = true
            end
        end
        
        // Update the visibility status.
        if visible ~= self.hiveSightVisible then
            local model = self:GetRenderModel()
            if model ~= nil then
                if visible then
                    HiveVision_AddModel( model )
                else
                    HiveVision_RemoveModel( model )
                end                    
                self.hiveSightVisible = visible    
            end
        end
            
    end

end