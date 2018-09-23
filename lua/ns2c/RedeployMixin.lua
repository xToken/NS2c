// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\RedeployMixin.lua
// - Dragon

RedeployMixin = CreateMixin(RedeployMixin)
RedeployMixin.type = "Redeploy"

RedeployMixin.networkVars =
{
    nextredeploy = "private time"
}

local function GetFurthestShift(self, pOrigin)
	local validshifts = { }
	local shifts = GetEntitiesForTeam("Shift", self:GetTeamNumber())
	local success = false

	local function SortByDistance(shift1, shift2)
		return shift1.dist > shift2.dist
	end
	
	for i, shift in ipairs(shifts) do
		local shiftinfo = { shift = shift, dist = 0 }
		local toTarget = shift:GetOrigin() - pOrigin
		local distanceToTarget = toTarget:GetLength()
		shiftinfo.dist = distanceToTarget
		if shift:GetIsBuilt() and self ~= shift and distanceToTarget > 5 then
			table.insert(validshifts, shiftinfo)
		end
	 end
	 
	 table.sort(validshifts, SortByDistance)
	 return validshifts
end

local function GetValidSpawnPoint(self, sOrigin)
	local TechID = kTechId.Skulk
	if self:GetIsAlive() then
		TechID = self:GetTechId()
	end
	local extents = LookupTechData(TechID, kTechDataMaxExtents)
	local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
	local range = 6
	for t = 1, 100 do //Persistance...
		local spawnPoint = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, sOrigin, 2, range, EntityFilterAll())
		if spawnPoint then
			local validForPlayer = GetIsPlacementForTechId(spawnPoint, TechID)
			local notNearResourcePoint = #GetEntitiesWithinRange("ResourcePoint", spawnPoint, 2) == 0
			if notNearResourcePoint then
				return spawnPoint
			end
		end
	end
end

function RedeployMixin:__initmixin()
    self.nextredeploy = 0
end

function RedeployMixin:Redeploy(level)
    if Server then
        if self:GetCanRedeploy() then
            local validshifts = GetFurthestShift(self, self:GetOrigin())
            
            for s = 1, #validshifts do
				local spawnPoint = GetValidSpawnPoint(self, validshifts[s].shift:GetOrigin())
				if spawnPoint then
					StartSoundEffectAtOrigin(Alien.kTeleportSound, self:GetOrigin())
					StartSoundEffectAtOrigin(Alien.kTeleportSound, spawnPoint)
					SpawnPlayerAtPoint(self, spawnPoint)
					self.nextredeploy = Shared.GetTime() + (kRedploymentCooldownBase - (kRedploymentCooldownDecreasePerLevel * level))
					success = true
					break
				end
            end
            
            if not success then
                player:TriggerInvalidSound()
            end
			
        end
    end
end

function RedeployMixin:GetCanRedeploy()
	local hasupg, level = GetHasRedeploymentUpgrade(self)
    return self.nextredeploy < Shared.GetTime() and hasupg and level > 0
end