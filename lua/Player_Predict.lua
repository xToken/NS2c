//
// lua\Player_Predict.lua
//

local kTechTree = TechTree()
kTechTree:Initialize() 

function Player:OnUpdatePlayer(deltaTime)    
end

function Player:UpdateMisc(input)
end

function Player:GetTechTree()   
    return kTechTree
end

function Player:ClearTechTree()
    kTechTree:Initialize()    
end