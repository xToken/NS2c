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
Script.Load("lua/ScoringMixin.lua")

if Client then
    Script.Load("lua/TeamMessageMixin.lua")
end

class 'AlienSpectator' (TeamSpectator)

AlienSpectator.kMapName = "alienspectator"

local networkVars =
{
    eggId = "private entityid",
    queuePosition = "private integer (-1 to 100)",
    timeWaveSpawnEnd = "private time"
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
        
    Server.SendNetworkMessage(Server.GetOwner(self), "SetTimeWaveSpawnEnds", { time = self.timeWaveSpawnEnd }, true)
    
    return true
    
end

function AlienSpectator:OnCreate()

    TeamSpectator.OnCreate(self)
    
    InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })
    
    if Client then
        InitMixin(self, TeamMessageMixin, { kGUIScriptName = "GUIAlienTeamMessage" })
    end
    
    self.timeWaveSpawnEnd = 0
    
end

function AlienSpectator:OnInitialized()

    TeamSpectator.OnInitialized(self)

    self:SetTeamNumber(2)
    
    self.eggId = Entity.invalidId
    self.queuePosition = 0
    self.movedToEgg = false
    
    if Server then
    
        self.evolveTechIds = { kTechId.Skulk }
        self:AddTimedCallback(UpdateQueuePosition, 0.1)
        self:AddTimedCallback(UpdateWaveTime, 0.1)
        UpdateQueuePosition(self)
        
    end
    
end

function AlienSpectator:GetIsValidToSpawn()
    return true
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

function AlienSpectator:GetAutoSpawnTime()
    return self.timeWaveSpawnEnd - Shared.GetTime()
end

function AlienSpectator:OnProcessMove(input)

    TeamSpectator.OnProcessMove(self, input)
    
    if Server then
    
        if self.timeWaveSpawnEnd > 0 and Shared.GetTime() >= self.timeWaveSpawnEnd then
            self:SpawnPlayerOnAttack()
        end
            
        if not self.waitingToSpawnMessageSent then
        
            SendPlayersMessage({ self }, kTeamMessageTypes.SpawningWait)
            self.waitingToSpawnMessageSent = true
            
        end
        
    end
    
end

function AlienSpectator:SpawnPlayerOnAttack()

    local egg = self:GetHostEgg()
    
    if egg ~= nil then
        return egg:SpawnPlayer()
    elseif Shared.GetCheatsEnabled() then
        return self:GetTeam():ReplaceRespawnPlayer(self)
    end
    
    self:TriggerInvalidSound()
    
    return false, nil
    
end

// Same as Skulk so his view height is right when spawning in
function AlienSpectator:GetMaxViewOffsetHeight()
    return Skulk.kViewOffsetHeight
end

function AlienSpectator:SetWaveSpawnEndTime(time)
    self.timeWaveSpawnEnd = time
end

function AlienSpectator:GetWaveSpawnEndTime()
    return self.timeWaveSpawnEnd
end

/**
 * Prevent the camera from penetrating into the world when waiting to spawn at an Egg.
 */
function AlienSpectator:GetPreventCameraPenetration()

    local followTarget = Shared.GetEntity(self:GetFollowTargetId())
    return followTarget and followTarget:isa("Egg")
    
end

Shared.LinkClassToMap("AlienSpectator", AlienSpectator.kMapName, networkVars)