-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Predict.lua
--
--    Created by:   Mats Olsson (mats.olsson@matsotech.se)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- Set the name of the VM for debugging
decoda_name = "Predict"

Script.Load("lua/Mixins/ExtensionsBlocker.lua")
Script.Load("lua/PreLoadMod.lua")

Script.Load("lua/Shared.lua")
Script.Load("lua/NetworkMessages_Predict.lua")
Script.Load("lua/MapEntityLoader.lua")

-- Predict tech tree
local gTechTree = TechTree()
gTechTree:Initialize() 

function GetTechTree()
    return gTechTree
end

function ClearTechTree()
    gTechTree:Initialize()    
end

local function OnMapLoadEntity(className, groupName, values)
    LoadMapEntity(className, groupName, values)
end        

Event.Hook("MapLoadEntity", OnMapLoadEntity)

Script.Load("lua/PostLoadMod.lua")