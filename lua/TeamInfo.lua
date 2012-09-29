// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua/TeamInfo.lua
//
// TeamInfo is used to sync information about a team to clients.
// A client on team 1 or 2 will only receive team info regarding their
// own team while a client on the kSpectatorIndex team will receive both
// teams info.
//
// Created by Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TeamMixin.lua")

class 'TeamInfo' (Entity)

TeamInfo.kMapName = "TeamInfo"

TeamInfo.kTechTreeUpdateInterval = 1

// max 100 tres/min, max 1000 minute game; should be enough 
kMaxTotalTeamResources = 100000
kMaxTotalPersonalResources = 100000

local networkVars =
{
    teamResources =  "float (0 to " .. kMaxResources .. " by 0.1 [ 4 ])",
    totalTeamResources = "float (0 to " .. kMaxTotalTeamResources .. " by 1 [ 1 ])",
    personalResources = "float (0 to " .. kMaxTotalPersonalResources .. " by 0.1) [ 4 ]",
    numResourceTowers = "integer (0 to 99)",
    numCapturedResPoints = "integer (0 to 99)",
    latestResearchId = "integer",
    numCapturedTechPoint = "integer (0 to 99)",
    lastCommPingTime = "time",
    lastCommPingPosition       = "vector",
    techResearchingMaskMarine  = "integer",
    techResearchedMaskMarine   = "integer",
    techResearchingMaskAlien   = "integer",
    techResearchedMaskAlien    = "integer",
    armsLabUp                  = "boolean",
    protoLabUp                 = "boolean",
    roboticsUp                 = "boolean",
    observatoryUp              = "boolean",
    playerCount                = "integer (0 to " .. kMaxPlayers - 1 .. ")"
}

AddMixinNetworkVars(TeamMixin, networkVars)

TeamInfo.kRelevantTechIdsMarine =
{

    kTechId.AdvancedArmory,

    kTechId.Weapons1,
    kTechId.Weapons2,
    kTechId.Weapons3,
    kTechId.Armor1,
    kTechId.Armor2,
    kTechId.Armor3,

    kTechId.JetpackTech,
    kTechId.HeavyArmorTech,
    kTechId.MotionTracking,
    kTechId.ARCRoboticsFactory,
    kTechId.PhaseTech
    
}

TeamInfo.kRelevantTechIdsAlien =
{
    
    kTechId.Leap,
    kTechId.BileBomb,
    kTechId.Umbra,
    kTechId.Metabolize,
    kTechId.Stomp,
    
    kTechId.Xenocide,
    kTechId.WebStalk,
    kTechId.PrimalScream,
    kTechId.AcidRocket,
    kTechId.Smash,
    
    kTechId.CragHive,
    
    kTechId.ShadeHive,
    
    kTechId.ShiftHive,
    
    kTechId.WhipHive,

}

function CreateRelevantIdMaskMarine()

    local t = {}

    for i,techId in ipairs(TeamInfo.kRelevantTechIdsMarine) do

        s = EnumToString(kTechId, techId)
        t[i] = s

    end

    
    TeamInfo.kRelevantIdMaskMarine = CreateBitMask(t)

end

function CreateRelevantIdMaskAlien()

    local t = {}

    for i,techId in ipairs(TeamInfo.kRelevantTechIdsAlien) do

        s = EnumToString(kTechId, techId)
        t[i] = s

    end


    TeamInfo.kRelevantIdMaskAlien = CreateBitMask(t)

end

function TeamInfo:OnCreate()

    Entity.OnCreate(self)
    
    CreateRelevantIdMaskMarine()
    CreateRelevantIdMaskAlien()
    
    if Server then
    
        self:SetUpdates(true)
        
        self.teamResources = 0
        self.personalResources = 0
        self.numResourceTowers = 0
        self.latestResearchId = 0
        self.researchDisplayTime = 0
        self.lastTechPriority = 0
        self.lastCommPingTime = 0
        self.lastCommPingPosition = 0
        self.totalTeamResources = 0
        self.techResearchingMaskMarine = 0
        self.techResearchedMaskMarine = 0
        self.techResearchingMaskAlien = 0
        self.techResearchedMaskAlien = 0
        self.armsLabUp = false
        self.protoLabUp = false
        self.roboticsUp = false
        self.observatoryUp = false
        self.playerCount = 0
        
    end
    
    InitMixin(self, TeamMixin)
    
end

local function UpdateInfo(self)

    if self.team then
    
        self:SetTeamNumber(self.team:GetTeamNumber())
        self.teamResources = self.team:GetTeamResources()
        self.playerCount = Clamp(self.team:GetNumPlayers(), 0, 31)
        
        self.totalTeamResources = self.team:GetTotalTeamResources()
        self.personalResources = 0
        for index, player in ipairs(self.team:GetPlayers()) do
            self.personalResources = self.personalResources + player:GetResources()
        end
        
        local rtCount = 0
        local rts = GetEntitiesForTeam("ResourceTower", self:GetTeamNumber())
        for index, rt in ipairs(rts) do
        
            if rt:GetIsCollecting() then
                rtCount = rtCount + 1
            end
            
        end
        
        self.numResourceTowers = rtCount
        self.numCapturedResPoints = #rts
        
        if self.lastTechTreeUpdate == nil or (Shared.GetTime() > (self.lastTechTreeUpdate + TeamInfo.kTechTreeUpdateInterval)) then

            self:UpdateTechTreeInfo(self.team:GetTechTree(), self.team:GetTeamNumber())

            if self.team:GetTeamNumber() == kTeam1Index then

                self.armsLabUp = false
               
                for i, entity in ipairs(GetEntitiesForTeam("ArmsLab", kTeam1Index)) do
                
                    if entity:GetIsBuilt() then
                        self.armsLabUp = true
                        break
                    end
                
                end
                
                self.protoLabUp = false

                for i, entity in ipairs(GetEntitiesForTeam("PrototypeLab", kTeam1Index)) do

                    if entity:GetIsBuilt() then
                        self.protoLabUp = true
                        break
                    end

                end
                
                self.roboticsUp = false

                for i, entity in ipairs(GetEntitiesForTeam("RoboticsFactory", kTeam1Index)) do

                    if entity:GetIsBuilt() then
                        self.roboticsUp = true
                        break
                    end

                end
                
                self.observatoryUp = false

                for i, entity in ipairs(GetEntitiesForTeam("Observatory", kTeam1Index)) do

                    if entity:GetIsBuilt() then
                        self.observatoryUp = true
                        break
                    end

                end

            end

        end

        if Server then
        
            if self.latestResearchId ~= 0 and self.researchDisplayTime < Shared.GetTime() then
            
                self.latestResearchId = 0
                self.researchDisplayTime = 0
                self.lastTechPriority = 0
                
            end
            
            local team = self:GetTeam()
            self.numCapturedTechPoint = team:GetNumCapturedTechPoints()
            
            self.lastCommPingTime = team:GetCommanderPingTime()
            self.lastCommPingPosition = team:GetCommanderPingPosition()
            
        end
        
    end
    
end

function TeamInfo:GetPingTime()
    return self.lastCommPingTime
end

function TeamInfo:GetPingPosition()
    return self.lastCommPingPosition
end

function TeamInfo:SetWatchTeam(team)

    self.team = team
    self:SetTeamNumber(team:GetTeamNumber())
    UpdateInfo(self)
    self:SetPropagate(Entity.Propagate_Mask)
    self:UpdateRelevancy()
    
end

function TeamInfo:GetNumCapturedResPoints()
    return self.numCapturedResPoints
end

function TeamInfo:GetTeamResources()
    return self.teamResources
end

function TeamInfo:GetPersonalResources()
    return self.personalResources
end

function TeamInfo:GetNumResourceTowers()
    return self.numResourceTowers
end

function TeamInfo:UpdateRelevancy()

	self:SetRelevancyDistance(Math.infinity)
	
	local mask = 0
	
	if self:GetTeamNumber() == kTeam1Index then
		mask = kRelevantToTeam1
	elseif self:GetTeamNumber() == kTeam2Index then
		mask = kRelevantToTeam2
	end
		
	self:SetExcludeRelevancyMask(mask)

end

function TeamInfo:OnUpdate(deltaTime)
    UpdateInfo(self)
end

function TeamInfo:SetLatestResearchedTech(researchId, displayTime, techPriority)
    
    if techPriority >= self.lastTechPriority then
    
        self.latestResearchId = researchId
        self.researchDisplayTime = displayTime
        self.lastTechPriority = techPriority
        
    end
    
end

function TeamInfo:UpdateTechTreeInfo(techTree, teamNumber)

    if not techTree then return end
    
    if teamNumber == kTeam1Index then

        for i,techId in ipairs(TeamInfo.kRelevantTechIdsMarine) do

            local techNode = techTree:GetTechNode(techId)

            if techNode and TeamInfo.kRelevantIdMaskMarine then

                self:UpdateBitmasks(techId, techNode, true)

            end

        end

        self.lastTechTreeUpdate = Shared.GetTime()

    elseif teamNumber == kTeam2Index then
    
        for i,techId in ipairs(TeamInfo.kRelevantTechIdsAlien) do

            local techNode = techTree:GetTechNode(techId)

            if techNode and TeamInfo.kRelevantIdMaskAlien then

                self:UpdateBitmasks(techId, techNode, false)

            end

        end

        self.lastTechTreeUpdate = Shared.GetTime()
    
    end

end

function TeamInfo:GetNumCapturedTechPoints()
    return self.numCapturedTechPoint
end

function TeamInfo:GetLatestResearchedTech()
    return self.latestResearchId
end

function TeamInfo:GetTeamTechTreeInfoMarine()
    return self.techResearchingMaskMarine, self.techResearchedMaskMarine
end

function TeamInfo:GetTeamTechTreeInfoAlien()
    return self.techResearchingMaskAlien, self.techResearchedMaskAlien
end

function TeamInfo:GetTotalTeamResources()
    return self.totalTeamResources
end

function TeamInfo:IsArmsLabUp()
    return self.armsLabUp
end

function TeamInfo:IsProtoLabUp()
    return self.protoLabUp
end

function TeamInfo:IsRoboticsUp()
    return self.roboticsUp
end

function TeamInfo:IsObservatoryUp()
    return self.observatoryUp
end

function TeamInfo:UpdateBitmasks(techId, techNode, isMarine)

    local techIdString = EnumToString(kTechId, techId)

    if isMarine then
    
        if techNode:GetResearching() then
            self.techResearchingMaskMarine = bit.bor(self.techResearchingMaskMarine, TeamInfo.kRelevantIdMaskMarine[techIdString])
        else
            self.techResearchingMaskMarine = bit.band(self.techResearchingMaskMarine, bit.bnot(TeamInfo.kRelevantIdMaskMarine[techIdString]))
        end

        if (techNode:GetResearched() or techNode:GetHasTech()) then
            self.techResearchedMaskMarine = bit.bor(self.techResearchedMaskMarine, TeamInfo.kRelevantIdMaskMarine[techIdString])
            self.techResearchingMaskMarine = bit.band(self.techResearchingMaskMarine, bit.bnot(TeamInfo.kRelevantIdMaskMarine[techIdString]))
        else
            self.techResearchedMaskMarine = bit.band(self.techResearchedMaskMarine, bit.bnot(TeamInfo.kRelevantIdMaskMarine[techIdString]))
        end

    else
    
        if techNode:GetResearching() then
            self.techResearchingMaskAlien = bit.bor(self.techResearchingMaskAlien, TeamInfo.kRelevantIdMaskAlien[techIdString])
        else
            self.techResearchingMaskAlien = bit.band(self.techResearchingMaskAlien, bit.bnot(TeamInfo.kRelevantIdMaskAlien[techIdString]))
        end

        if (techNode:GetResearched() or techNode:GetHasTech()) then
            self.techResearchedMaskAlien = bit.bor(self.techResearchedMaskAlien, TeamInfo.kRelevantIdMaskAlien[techIdString])
            self.techResearchingMaskAlien = bit.band(self.techResearchingMaskAlien, bit.bnot(TeamInfo.kRelevantIdMaskAlien[techIdString]))
        else
            self.techResearchedMaskAlien = bit.band(self.techResearchedMaskAlien, bit.bnot(TeamInfo.kRelevantIdMaskAlien[techIdString]))
        end
        
    end

end

function TeamInfo:GetPlayerCount()
    return self.playerCount
end

Shared.LinkClassToMap("TeamInfo", TeamInfo.kMapName, networkVars)
