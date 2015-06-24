// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\Overloads\SensorBlip.lua
// - Dragon

Script.Load("lua/Class.lua")

local origSensorBlipOnCreate
origSensorBlipOnCreate = Class_ReplaceMethod("SensorBlip", "OnCreate", 
	function(self)
		origSensorBlipOnCreate(self)
		self:UpdateRelevancy(0)
	end
)

local origSensorBlipUpdateRelevancy
origSensorBlipUpdateRelevancy = Class_ReplaceMethod("SensorBlip", "UpdateRelevancy", 
	function(self, teamNum)
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
)