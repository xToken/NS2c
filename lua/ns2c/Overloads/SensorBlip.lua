// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\Overloads\SensorBlip.lua
// - Dragon

local origSensorBlipOnCreate = SensorBlip.OnCreate
function SensorBlip:OnCreate()
    origSensorBlipOnCreate(self)
    self:UpdateRelevancy(0)
end

function SensorBlip:UpdateRelevancy(teamNum)
    self:SetRelevancyDistance(Math.infinity)
    local includeMask
    if teamNum == 1 then
        includeMask = kRelevantToTeam1
    elseif teamNum == 2 then
        includeMask = kRelevantToTeam2
    else
        includeMask = 0
    end
    self:SetExcludeRelevancyMask(includeMask)
end