// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\VoteManager.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

class 'VoteManager'

local kMinVotesNeeded = 2

// Seconds that a vote lasts before expiring
local kVoteDuration = 120

// Constructor
function VoteManager:Initialize()

    self.playersVoted = {}
    self.playersTargets = {}
    self.playersvotefor = {}
    self:SetNumPlayers(0)
    self.teamPercentNeeded = 0.5;
    self.duration = kVoteDuration
    self.minvotes = kMinVotesNeeded
    
end

function VoteManager:PlayerVotes(playerId, time)

    if type(playerId) == "number" and type(time) == "number" then
    
        if not table.find(self.playersVoted, playerId) then
        
            table.insert(self.playersVoted, playerId)
            self.target = true
            self.timeVoteStarted = time
            return true
            
        end    
        
    end
    
    return false

end

function VoteManager:PlayerVotesFor(playerId, target, time)

    if type(playerId) == "number" and target ~= nil and type(time) == "number" then
        // Make sure player hasn't voted already
        if table.find(self.playersVoted, playerId) then
            for i = 1, #self.playersTargets do
                if self.playersTargets[i].t == self.playersvotefor[playerId] then
                    self.playersTargets[i].v = self.playersTargets[i].v - 1
                    break
                end
            end
            table.remove(self.playersVoted, playerId)
        end
        if not table.find(self.playersVoted, playerId) then
            local added = false
            table.insert(self.playersVoted, playerId)
            self.playersvotefor[playerId] = target
            for i = 1, #self.playersTargets do
                if self.playersTargets[i].t == target then
                    self.playersTargets[i].v = self.playersTargets[i].v + 1
                    added = true
                    break
                end
            end
            if not added then
                table.insert(self.playersTargets, {t = target, v = 1})
            end
            self.target = target
            self.timeVoteStarted = time
            return true
            
        end

    end
    
    return false
    
end

function VoteManager:GetVotePassed()
	local target, votes
	votes = 0
    for i = 1, #self.playersTargets do
        if votes == nil or votes < self.playersTargets[i].v then
            target = self.playersTargets[i].t
			votes = self.playersTargets[i].v
        end
    end
    return votes >= self:GetNumVotesNeeded()
end

function VoteManager:GetNumVotesNeeded()
    // Round to nearest number of players (3.4 = 3, 3.5 = 4).
    return math.max(self.minvotes, math.floor((self.numPlayers * self.teamPercentNeeded) + 0.5))
end

function VoteManager:GetNumVotesCast()
    return table.count( self.playersVoted )
end

function VoteManager:GetTarget()
    local target, votes
	votes = 0
    for i = 1, #self.playersTargets do
        if votes == nil or votes < self.playersTargets[i].v then
            target = self.playersTargets[i].t
			votes = self.playersTargets[i].v
        end
    end
    return target
end

function VoteManager:GetVoteStarted()
    return self.target ~= nil
end

// Note - doesn't reset number of players.
function VoteManager:Reset()

    self.playersTargets = {}
    self.playersVoted = { }
    self.target = nil
    self.timeVoteStarted = nil
end

function VoteManager:SetNumPlayers(numPlayers)

    ASSERT(type(numPlayers) == "number")
    self.numPlayers = numPlayers
    
end

// Pass current time in, returns true if vote timed out. Typically call Reset() after it returns true.
function VoteManager:GetVoteElapsed(time)

    if self.timeVoteStarted and type(time) == "number" then
    
        if (time - self.timeVoteStarted) >= self.duration then
            return true
        end
        
    end
    
    return false
    
end

function VoteManager:SetTeamPercentNeeded(val)
    self.teamPercentNeeded = val
end

function VoteManager:SetDuration(val)
    self.duration = val
end

function VoteManager:SetMinVotes(val)
    self.minvotes = val
end