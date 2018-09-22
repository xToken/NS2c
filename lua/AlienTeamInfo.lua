-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua/AlienTeamInfo.lua
--
-- AlienTeamInfo is used to sync information about a team to clients.
-- Only alien team players (and spectators) will receive the information about number
-- of shells, spurs or veils.
--
-- Created by Andreas Urwalek (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Added in unassigned hives for tracking

Script.Load("lua/TeamInfo.lua")

class 'AlienTeamInfo' (TeamInfo)

AlienTeamInfo.kMapName = "AlienTeamInfo"

local techIdTable = { [kTechId.Crag] = "crags", [kTechId.Shift] = "shifts", [kTechId.Shade] = "shades", [kTechId.Whip] = "whips" }

local networkVars =
{
    numHives = "integer (0 to 10)",
    numUnassignedHives = "integer (0 to 10)",
    eggCount = "integer (0 to 127)",
	crags = "integer (0 to 3)",
    shifts = "integer (0 to 3)",
    shades = "integer (0 to 3)",
	whips = "integer (0 to 3)"
}

function AlienTeamInfo:OnCreate()

    TeamInfo.OnCreate(self)
    
    self.numHives = 0
    self.eggCount = 0
    self.numUnassignedHives = 0
    self.crags = 0
    self.shifts = 0
    self.shades = 0
	self.whips = 0

end

if Server then

	function AlienTeamInfo:Reset()
    
		TeamInfo.Reset( self ) 
		
        self.numHives = 0
	    self.eggCount = 0
	    self.numUnassignedHives = 0
	    self.crags = 0
	    self.shifts = 0
	    self.shades = 0
		self.whips = 0
        
    end
    
    function AlienTeamInfo:UpdateNumUpgradeStructures(techId, count)
        if self[techIdTable[techId]] then
            self[techIdTable[techId]] = Clamp(count, 0, 3)
        end
    end
    
    function AlienTeamInfo:SetActiveHiveCount(numHives)
        self.numHives = Clamp(numHives, 0, 10)
    end

    function AlienTeamInfo:SetActiveUnassignedHiveCount(numHives)
        self.numUnassignedHives = Clamp(numHives, 0, 10)
    end

    function AlienTeamInfo:SetEggCount(count)
        self.eggCount = Clamp(count, 0, 127)
    end

end

function AlienTeamInfo:GetActiveHiveCount()
    return self.numHives
end

function AlienTeamInfo:GetActiveUnassignedHiveCount()
    return self.numUnassignedHives
end

function AlienTeamInfo:GetEggCount()
    return self.eggCount
end

function AlienTeamInfo:GetNumUpgradeStructures(techId)
    return self[techIdTable[techId]] or 0
end

Shared.LinkClassToMap("AlienTeamInfo", AlienTeamInfo.kMapName, networkVars)