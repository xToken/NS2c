// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\AlienSpectator.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Alien spectators can choose their upgrades and lifeform while dead.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Adjusted logic so that player can be queued to an egg earlier in the spawning process

Script.Load("lua/TeamSpectator.lua")

if Client then
    Script.Load("lua/TeamMessageMixin.lua")
end

class 'AlienSpectator' (TeamSpectator)

AlienSpectator.kMapName = "alienspectator"

local networkVars =
{
    eggId = "private entityid",
    queuePosition = "private integer (-1 to 100)"
}

local function UpdateQueuePosition(self)

    if self:GetIsDestroyed() then
        return false
    end
    
    self.queuePosition = self:GetTeam():GetPlayerPositionInRespawnQueue(self)
    return true
    
end

local function UpdateWaveTime(self)

    if self:GetIsDestroyed() then
        return false
    end
    
    if not self.sentRespawnMessage then
    
        Server.SendNetworkMessage(Server.GetOwner(self), "SetIsRespawning", { isRespawning = true }, true)
        self.sentRespawnMessage = true
        
    end
    
    return true
    
end

local function UpdateWaitingtoSpawn(self)
    if not self.waitingToSpawnMessageSent then
        SendPlayersMessage({ self }, kTeamMessageTypes.SpawningWait)
        self.waitingToSpawnMessageSent = true    
    end
end

function AlienSpectator:OnCreate()

    TeamSpectator.OnCreate(self)

    if Client then
        InitMixin(self, TeamMessageMixin, { kGUIScriptName = "GUIAlienTeamMessage" })
    end
    
end

function AlienSpectator:OnInitialized()

    TeamSpectator.OnInitialized(self)

    self:SetTeamNumber(2)
    
    self.eggId = Entity.invalidId
	self.queuePosition = 0
    self.movedToEgg = false
    
    if Server then
    
        self.evolveTechIds = { kTechId.Skulk }
		self:AddTimedCallback(UpdateQueuePosition, kUpdateIntervalLow)
        self:AddTimedCallback(UpdateWaveTime, kUpdateIntervalLow)
        self:AddTimedCallback(UpdateWaitingtoSpawn, kUpdateIntervalLow)
		UpdateQueuePosition(self)
        
    end
    
end

if Server then

    function AlienSpectator:Replace(mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues)
    
        Server.SendNetworkMessage(Server.GetOwner(self), "SetIsRespawning", { isRespawning = false }, true)    
        return TeamSpectator.Replace(self, mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues)
    
    end

end

// Returns egg we're currently spawning in or nil if none
function AlienSpectator:GetHostEgg()

    if self.eggId ~= Entity.invalidId then
        return Shared.GetEntity(self.eggId)
    end
    
    return nil
    
end

function AlienSpectator:SetEggId(id)
    self.eggId = id    
end

function AlienSpectator:GetEggId()
    return self.eggId
end

function AlienSpectator:GetQueuePosition()
    return self.queuePosition
end
// Same as Skulk so his view height is right when spawning in
function AlienSpectator:GetMaxViewOffsetHeight()
    return Skulk.kViewOffsetHeight
end

/**
 * Prevent the camera from penetrating into the world when waiting to spawn at an Egg.
 */
function AlienSpectator:GetPreventCameraPenetration()

    local followTarget = Shared.GetEntity(self:GetFollowTargetId())
    return followTarget and followTarget:isa("Egg")
    
end

Shared.LinkClassToMap("AlienSpectator", AlienSpectator.kMapName, networkVars)