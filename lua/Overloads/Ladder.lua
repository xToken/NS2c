// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\Overloads\Ladder.lua
// - Dragon

//Predicted Ladders
function Ladder:OnCreate()
    Trigger.OnCreate(self)
    self:SetRelevancyDistance(kMaxRelevancyDistance)
end