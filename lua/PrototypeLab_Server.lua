// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PrototypeLab.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// west/east = x/-x
// north/south = -z/z

local indexToUseOrigin = {
    // West
    Vector(PrototypeLab.kResupplyUseRange, 0, 0), 
    // North
    Vector(0, 0, -PrototypeLab.kResupplyUseRange),
    // South
    Vector(0, 0, PrototypeLab.kResupplyUseRange),
    // East
    Vector(-PrototypeLab.kResupplyUseRange, 0, 0)
}

// Check if friendly players are nearby and facing PrototypeLab
function PrototypeLab:OnThink()

    ScriptActor.OnThink(self)
  
    self:SetNextThink(PrototypeLab.kThinkTime)
    
end

function PrototypeLab:UpdateLoggedIn()

    
end    

