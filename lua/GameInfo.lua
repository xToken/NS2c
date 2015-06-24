// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
//
// lua/GameInfo.lua
//
// GameInfo is used to sync information about the game state to clients.
//
// Created by Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

class 'GameInfo' (Entity)

GameInfo.kMapName = "gameinfo"

local networkVars =
{
    state = "enum kGameState",
    startTime = "time",
    averagePlayerSkill = "integer",
    isGatherReady = "boolean",
    numPlayersTotal = "integer",
    gameMode = "enum kGameMode",
    fallDamage = "boolean",
    classicCommanderRequired = "boolean",
    classicMaxSentriesPerRoom = "integer (1 to " .. kMaxSentriesPerRoom .. ")",
    classicMaxSiegesPerRoom = "integer (1 to " .. kMaxSiegesPerRoom .. ")",
    classicMaxFactoriesPerRoom = "integer (1 to " .. kMaxTurretFactoriesPerRoom .. ")",
    classicMaxAlienStructures = "integer (3 to " .. kMaxAlienStructuresofType .. ")",
    combatMaxLevel = "integer (5 to " .. kCombatMaxAllowedLevel .. ")",
    combatSpawnProtectionLength = "integer (0 to " .. kCombatMaxSpawnProtection .. ")",
    combatRoundLength = "integer (5 to " .. kCombatMaxRoundLength .. ")",
    combatDefaultWinner = "integer (1 to 2)",
}

function GameInfo:OnCreate()

    Entity.OnCreate(self)
    
    if Server then
    
        self:SetPropagate(Entity.Propagate_Always)
        self:SetUpdates(false)
        
        self.state = kGameState.NotStarted
        self.startTime = 0
        self.averagePlayerSkill = kDefaultPlayerSkill
        self.numPlayersTotal = 0
        self.gameMode = kGameMode.Classic
        self.fallDamage = false
        self.classicCommanderRequired = false
        self.classicMaxSentriesPerRoom = 1
        self.classicMaxSiegesPerRoom = 1
        self.classicMaxFactoriesPerRoom = 1
        self.classicMaxAlienStructures = 8
        self.combatMaxLevel = 5
        self.combatSpawnProtectionLength = 0
        self.combatRoundLength = 5
        self.combatDefaultWinner = 2
        UpdateClassicServerSettings()
        
    end
    
end

function GameInfo:GetStartTime()
    return self.startTime
end

function GameInfo:GetGameStarted()
    return self.state == kGameState.Started
end

function GameInfo:GetState()
    return self.state
end

function GameInfo:GetAveragePlayerSkill()
    return self.averagePlayerSkill
end

function GameInfo:GetNumPlayersTotal()
    return self.numPlayersTotal
end
    
function GameInfo:SetIsGatherReady(isGatherReady)
    self.isGatherReady = isGatherReady
end

function GameInfo:GetIsGatherReady()
    return self.isGatherReady
end

function GameInfo:GetGameMode()
    return self.gameMode
end
    
function GameInfo:GetFallDamageEnabled()
    return self.fallDamage
end

function GameInfo:GetClassicCommanderRequired()
    return self.classicCommanderRequired
end

function GameInfo:GetClassicMaxSentriesPerRoom()
    return self.classicMaxSentriesPerRoom
end

function GameInfo:GetClassicMaxSiegesPerRoom()
    return self.classicMaxSiegesPerRoom
end

function GameInfo:GetClassicMaxFactoriesPerRoom()
    return self.classicMaxFactoriesPerRoom
end

function GameInfo:GetClassicMaxAlienStructures()
    return self.classicMaxAlienStructures
end

function GameInfo:GetCombatMaxLevel()
    return self.combatMaxLevel
end

function GameInfo:GetCombatSpawnProtectionLength()
    return self.combatSpawnProtectionLength
end
    
function GameInfo:GetCombatRoundLength()
    return self.combatRoundLength
end

function GameInfo:GetCombatDefaultWinner()
    return self.combatDefaultWinner
end

if Server then

    function GameInfo:SetStartTime(startTime)
        self.startTime = startTime
    end
    
    function GameInfo:SetState(state)
        self.state = state
    end
    
    function GameInfo:SetAveragePlayerSkill(skill)
        self.averagePlayerSkill = skill
    end
    
    function GameInfo:SetNumPlayersTotal( numPlayersTotal )
        self.numPlayersTotal = numPlayersTotal
    end
    
    function GameInfo:SetFallDamage(fDamage)
        self.fallDamage = fDamage
    end
        
    function GameInfo:SetGameMode(gMode)
        self.gameMode = gMode
    end
    
    function GameInfo:SetClassicCommanderRequired(fComm)
        self.classicCommanderRequired = fComm
    end
    
    function GameInfo:SetClassicMaxSentriesPerRoom(mSentries)
        mSentries = Clamp(mSentries, 1 ,kMaxSentriesPerRoom)
        self.classicMaxSentriesPerRoom = mSentries
    end
    
    function GameInfo:SetClassicMaxSiegesPerRoom(mSieges)
        mSieges = Clamp(mSieges, 1 ,kMaxSiegesPerRoom)
        self.classicMaxSiegesPerRoom = mSieges
    end
    
    function GameInfo:SetClassicMaxFactoriesPerRoom(mFactories)
        mFactories = Clamp(mFactories, 1 ,kMaxTurretFactoriesPerRoom)
        self.classicMaxFactoriesPerRoom = mFactories
    end
    
    function GameInfo:SetClassicMaxAlienStructures(mStructures)
        mStructures = Clamp(mStructures, 3 ,kMaxAlienStructuresofType)
        self.classicMaxAlienStructures = mStructures
    end
    
    function GameInfo:SetCombatMaxLevel(mLevel)
        mLevel = Clamp(mLevel, 5 ,kCombatMaxAllowedLevel)
        self.combatMaxLevel = mLevel
    end
    
    function GameInfo:SetCombatSpawnProtectionLength(mLength)
        mLength = Clamp(mLength, 0 ,kCombatMaxSpawnProtection)
        self.combatSpawnProtectionLength = mLength
    end
    
    function GameInfo:SetCombatRoundLength(mLength)
        mLength = Clamp(mLength, 5 ,kCombatMaxRoundLength)
        self.combatRoundLength = mLength
    end
    
    function GameInfo:SetCombatDefaultWinner(mTeam)
        mTeam = Clamp(mTeam, 1 ,2)
        self.combatDefaultWinner = mTeam
    end
    
end

Shared.LinkClassToMap("GameInfo", GameInfo.kMapName, networkVars)