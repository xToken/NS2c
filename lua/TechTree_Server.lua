// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechTree_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// Send the entirety of every the tech node on team change or join. Returns true if it sent anything
function TechTree:SendTechTreeBase(player)

    local sent = false
    
    if self.complete then
    
        // Tell client to empty tech tree before adding new nodes. Send reliably
        // so players are always able to buy weapons, use commander mode, etc.
        Server.SendNetworkMessage(player, "ClearTechTree", {}, true)
    
        for index, techNode in pairs(self.nodeList) do
        
            Server.SendNetworkMessage(player, "TechNodeBase", BuildTechNodeBaseMessage(techNode), true)
            
            sent = true
        
        end
        
    end
    
    return sent
    
end

function TechTree:SendTechTreeUpdates(playerList)

    for techNodeIndex, techNode in ipairs(self.techNodesChanged) do
    
        local techNodeUpdateTable = BuildTechNodeUpdateMessage(techNode)
        
        for playerIndex, player in ipairs(playerList) do    
        
            Server.SendNetworkMessage(player, "TechNodeUpdate", techNodeUpdateTable, true)
            
        end
        
    end
    
    table.clear(self.techNodesChanged)
    
end

function TechTree:AddOrder(techId)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Order, kTechId.None, kTechId.None)
    techNode.requiresTarget = true
    
    self:AddNode(techNode)    
    
end

// a child tech can be used a requirement in case there is no parent tech available (mature structures, upgraded robotics factory, etc)
function TechTree:AddTechInheritance(parentTech, childTech)

    if not self.techInheritance then
        self.techInheritance = {}
    end    

    table.insert(self.techInheritance, {parentTech, childTech} )
    
end

// Contains a bunch of tech nodes
function TechTree:AddBuildNode(techId, prereq1, prereq2, isRequired)

    assert(techId)
    
    local techNode = TechNode()

    techNode:Initialize(techId, kTechType.Build, prereq1, prereq2)
    techNode.requiresTarget = true
    techNode.isRequired = isRequired
    
    self:AddNode(techNode)    
    
end

// Contains a bunch of tech nodes
function TechTree:AddEnergyBuildNode(techId, prereq1, prereq2)

    local techNode = TechNode()

    techNode:Initialize(techId, kTechType.EnergyBuild, prereq1, prereq2)
    techNode.requiresTarget = true
    
    self:AddNode(techNode)    
    
end

function TechTree:AddManufactureNode(techId, prereq1, prereq2, isRequired)

    local techNode = TechNode()

    techNode:Initialize(techId, kTechType.Manufacture, prereq1, prereq2)
    
    local buildTime = LookupTechData(techId, kTechDataBuildTime, kDefaultBuildTime)
    techNode.time = ConditionalValue(buildTime ~= nil, buildTime, 0)
    techNode.isRequired = isRequired
    
    self:AddNode(techNode)  

end


function TechTree:AddBuyNode(techId, prereq1, prereq2, addOnTechId)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Buy, prereq1, prereq2)
    
    if addOnTechId ~= nil then
        techNode.addOnTechId = addOnTechId
    end
    
    self:AddNode(techNode)    
    
end

function TechTree:AddTargetedBuyNode(techId, prereq1, prereq2, addOnTechId)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Buy, prereq1, prereq2)
    
    if addOnTechId ~= nil then
        techNode.addOnTechId = addOnTechId
    end
    
    techNode.requiresTarget = true        
    
    self:AddNode(techNode)    

end

function TechTree:AddResearchNode(techId, prereq1, prereq2, addOnTechId)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Research, prereq1, prereq2)
    
    local researchTime = LookupTechData(techId, kTechDataResearchTimeKey)
    techNode.time = ConditionalValue(researchTime ~= nil, researchTime, 0)
    
    if addOnTechId ~= nil then
        techNode.addOnTechId = addOnTechId
    end

    self:AddNode(techNode)    
    
end

// Same as research but can be triggered multiple times and concurrently
function TechTree:AddUpgradeNode(techId, prereq1, prereq2)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Upgrade, prereq1, prereq2)
    
    local researchTime = LookupTechData(techId, kTechDataResearchTimeKey)
    techNode.time = ConditionalValue(researchTime ~= nil, researchTime, 0)

    self:AddNode(techNode)    
    
end

function TechTree:AddAction(techId, prereq1, prereq2)

    local techNode = TechNode()

    techNode:Initialize(techId, kTechType.Action, prereq1, prereq2)
    
    self:AddNode(techNode)  

end

function TechTree:AddTargetedAction(techId, prereq1, prereq2)

    local techNode = TechNode()

    techNode:Initialize(techId, kTechType.Action, prereq1, prereq2)
    techNode.requiresTarget = true        
    
    self:AddNode(techNode)
    
end

// If there's a cost, it's energy
function TechTree:AddActivation(techId, prereq1, prereq2)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Activation, prereq1, prereq2)
    
    self:AddNode(techNode)  
    
end

// If there's a cost, it's energy
function TechTree:AddTargetedActivation(techId, prereq1, prereq2)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Activation, prereq1, prereq2)
    techNode.requiresTarget = true        
    
    self:AddNode(techNode)  
    
end

function TechTree:AddMenu(techId, prereq1, prereq2)

    local techNode = TechNode()
    
    if not prereq1 then
        prereq1 = kTechId.None
    end
    
    if not prereq2 then
        prereq2 = kTechId.None
    end
    
    techNode:Initialize(techId, kTechType.Menu, prereq1, prereq1)
    
    self:AddNode(techNode)  

end

//NS2c
//Adding back in Energy for Scans
function TechTree:AddTargetedEnergyActivation(techId, prereq1, prereq2)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.EnergyBuild, prereq1, prereq2)
    techNode.requiresTarget = true        
    
    self:AddNode(techNode)  
    
end

function TechTree:AddEnergyManufactureNode(techId, prereq1, prereq2)

    local techNode = TechNode()

    techNode:Initialize(techId, kTechType.EnergyManufacture, prereq1, prereq2)
    
    local researchTime = LookupTechData(techId, kTechDataResearchTimeKey)
    techNode.time = ConditionalValue(researchTime ~= nil, researchTime, 0)
    
    self:AddNode(techNode)    
    
end

function TechTree:AddPlasmaManufactureNode(techId, prereq1, prereq2)

    local techNode = TechNode()

    techNode:Initialize(techId, kTechType.PlasmaManufacture, prereq1, prereq2)
    
    local researchTime = LookupTechData(techId, kTechDataResearchTimeKey)
    techNode.time = ConditionalValue(researchTime ~= nil, researchTime, 0)
    
    self:AddNode(techNode)    
    
end

function TechTree:AddSpecial(techId, prereq1, prereq2, requiresTarget)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Special, prereq1, prereq2)
    techNode.requiresTarget = ConditionalValue(requiresTarget, true, false)
    
    self:AddNode(techNode)  

end

function TechTree:AddPassive(techId, prereq1, prereq2)

    local techNode = TechNode()
    
    techNode:Initialize(techId, kTechType.Passive, prereq1, prereq2)
    techNode.requiresTarget = false
    
    self:AddNode(techNode)  

end

function TechTree:SetTechChanged()
    self.techChanged = true
end

// Pre-compute stuff
function TechTree:SetComplete(complete)

    if not self.complete then
        
        self:ComputeUpgradedTechIdsSupporting()
        
        self.complete = true
        
    end
    
end

function TechTree:SetTeamNumber(teamNumber)
    self.teamNumber = teamNumber
end

function TechTree:GiveUpgrade(techId)

    local node = self:GetTechNode(techId)
    if(node ~= nil) then
    
        if(node:GetIsResearch()) then
        
            local newResearchState = not node.researched
            node:SetResearched(newResearchState)
            
            self:SetTechNodeChanged(node, string.format("researched: %s", ToString(newResearchState)))

            if(newResearchState) then
            
                self:QueueOnResearchComplete(techId)
                
            end
            
            return true

        end
        
    else
        Print("TechTree:GiveUpgrade(%d): Couldn't lookup tech node.", techId)
    end
    
    return false
    
end

function TechTree:AddSupportingTechId(techId, idList)

    if self.upgradedTechIdsSupporting == nil then
        self.upgradedTechIdsSupporting = {}
    end
    
    if table.maxn(idList) > 0 then    
        table.insert(self.upgradedTechIdsSupporting, {techId, idList})        
    end
    
end

function TechTree:ComputeUpgradedTechIdsSupporting()

    self.upgradedTechIdsSupporting = {}
    
    for index, techId in pairs(kTechId) do
    
        local idList = self:ComputeUpgradedTechIdsSupportingId(techId)
        self:AddSupportingTechId(techId, idList)
        
    end
    
end

function TechTree:GetUpgradedTechIdsSupporting(techId)

    for index, idTablePair in ipairs(self.upgradedTechIdsSupporting) do
    
        if idTablePair[1] == techId then
        
            return idTablePair[2]
            
        end
        
    end
    
    return {}
    
end

// Compute if active structures on our team that support this technology.
function TechTree:ComputeHasTech(structureTechIdList, techIdCount)

    // Iterate in order
    for index = 1, table.count(self.nodeList) do

        local node = self.nodeList[index]
        if node ~= nil then
        
            local techId = node:GetTechId()
            
            local hasTech = false
        
            if(self:GetTechSpecial(techId)) then
            
                hasTech = self:GetSpecialTechSupported(techId, structureTechIdList, techIdCount)

            // If it's research, see if it's researched
            elseif node:GetIsResearch() then
            
                // Pre-reqs must be defined already
                local prereq1 = node:GetPrereq1()
                local prereq2 = node:GetPrereq2()
                assert(prereq1 == kTechId.None or (prereq1 < techId), string.format("Prereq %s bigger then %s", EnumToString(kTechId, prereq1), EnumToString(kTechId, techId)))
                assert(prereq2 == kTechId.None or (prereq2 < techId), string.format("Prereq %s bigger then %s", EnumToString(kTechId, prereq2), EnumToString(kTechId, techId)))
                
                hasTech =   node:GetResearched() and 
                            self:GetHasTech(node:GetPrereq1()) and 
                            self:GetHasTech(node:GetPrereq2())

            else
        
                // Also look for tech that replaces this tech but counts towards it (upgraded Armories, Infantry Portals, etc.)        
                local supportingTechIds = self:GetUpgradedTechIdsSupporting(techId)
                
                table.insert(supportingTechIds, techId)
                
                for index, entityTechId in pairs(structureTechIdList) do
                
                    if(table.find(supportingTechIds, entityTechId)) then
                    
                        hasTech = true
                            
                        break
                            
                    end
                   
                end
                
            end 
            
            // Update node
            if node:GetHasTech() ~= hasTech then
                node:SetHasTech(hasTech)
                self:SetTechNodeChanged(node, string.format("hasTech = %s", ToString(hasTech)))
           end
           
        end
       
    end
        
end

function TechTree:GetTechSpecial(techId)

    local techNode = self:GetTechNode(techId)
    return techNode ~= nil and techNode:GetIsSpecial()
    
end

          
function BioMassTechToLevel(techId)
    return -1
end
              
function TechTree:GetSpecialTechSupported(techId, structureTechIdList, techIdCount)

    local supportingIds = nil
    
    if techId == kTechId.TwoCommandStations or techId == kTechId.ThreeCommandStations then    
        supportingIds = { kTechId.CommandStation }
        
    elseif techId == kTechId.TwoHives or techId == kTechId.ThreeHives then
		//NS2c
		//Added WhipHive as supportingID for Hive
        supportingIds = { kTechId.Hive, kTechId.ShadeHive, kTechId.ShiftHive, kTechId.CragHive, kTechId.WhipHive }
    end
    
    if not supportingIds then
        return false
    end    
    
    local numBuiltSpecials = 0
    
    for _, supportingId in ipairs(supportingIds) do
    
        if techIdCount[supportingId] then
            numBuiltSpecials = numBuiltSpecials + techIdCount[supportingId]
        end
    
    end
    
    /*
    local structureTechIdListText = ""
    for _, structureTechId in ipairs(structureTechIdList) do
        structureTechIdListText = structureTechIdListText .. ", " .. EnumToString(kTechId, structureTechId) .. "(" .. ToString(techIdCount[structureTechId]) .. ")"
    end
    
    Print(structureTechIdListText)
    Print("TechTree:GetSpecialTechSupported(%s), numBuiltSpecials: %s", EnumToString(kTechId, techId), ToString(numBuiltSpecials))
    */
    
    if techId == kTechId.TwoCommandStations or techId == kTechId.TwoHives then
        return numBuiltSpecials >= 2
    else
        return numBuiltSpecials >= 3
    end
    
end

// Second param is optional
function TechTree:QueueOnResearchComplete(researchId, ent)

    ASSERT(type(researchId) == "number")
    ASSERT(ent == nil or type(ent) == "userdata")

    // Research just finished on this structure. Queue call to OnResearchComplete
    // until after we next update the tech tree
    if not self.queuedOnResearchComplete then
        self.queuedOnResearchComplete = {}
    end
    
    local id = Entity.invalidId
    if ent then
        id = ent:GetId()
    end
    table.insertunique(self.queuedOnResearchComplete, {id, researchId})
    
end

function TechTree:TriggerQueuedResearchComplete()

    if self.queuedOnResearchComplete ~= nil then
    
        for index, pair in ipairs(self.queuedOnResearchComplete) do
        
            local entId = pair[1]
            local researchId = pair[2]
            
            local ent = nil
            if entId ~= Entity.invalidId then
            
                // It's possible that entity has been destroyed before here 
                ent = Shared.GetEntity(entId)
                
            end
            
            local team = GetGamerules():GetTeam(self:GetTeamNumber())
            if ent ~= nil then
                team = ent:GetTeam()
            end                    
            
            assert(team ~= nil)
            assert(team.OnResearchComplete ~= nil)
            
            team:OnResearchComplete(ent, researchId)
            
        end
        
    end
    
    // Clear out table
    self.queuedOnResearchComplete = nil
    
end

function TechTree:GetIsResearchQueued(techId)

    if self.queuedOnResearchComplete then
    
        for r = 1, #self.queuedOnResearchComplete do
        
            local queuedResearch = self.queuedOnResearchComplete[r]
            local entId = queuedResearch[1]
            local researchId = queuedResearch[2]
            if techId == researchId then
                return true
            end
            
        end
        
    end
    
    return false
    
end

function TechTree:GetNumberOfQueuedResearch()
    return self.queuedOnResearchComplete and #self.queuedOnResearchComplete or 0
end

function TechTree:Update(techIdList, techIdCount)

    // Only compute if needed
    if self.techChanged then
    
        self:ComputeHasTech(techIdList, techIdCount)
        
        self:ComputeAvailability()
        
        self.techChanged = false
        
        self:TriggerQueuedResearchComplete()
        
    end
    
end

/**
 * Compute "available" field for all nodes in tech tree. Should be called whenever a structure
 * is added or removed, and whenever global research starts or is canceled.
 */
function TechTree:ComputeAvailability()

    for index, node in pairs(self.nodeList) do
    
        local newAvailableState = false
        
        // Don't allow researching items that are currently being researched (unless multiples allowed)
        if (node:GetIsResearch() or node:GetIsPlasmaManufacture()) and (self:GetHasTech(node:GetPrereq1()) and self:GetHasTech(node:GetPrereq2())) then
            newAvailableState = node:GetCanResearch()
        // Disable anything with this as a prereq if no longer available
        elseif self:GetHasTech(node:GetPrereq1()) and self:GetHasTech(node:GetPrereq2()) then
            newAvailableState = true
        end
        
        // Check for "alltech" cheat
        if GetGamerules():GetAllTech() then
            newAvailableState = true
        end
        
        // Don't allow use of stuff that's unavailable
        if LookupTechData(node.techId, kTechDataImplemented) == false and not Shared.GetDevMode() then
            newAvailableState = false
        end
        
        if node.available ~= newAvailableState then
        
            node.available = newAvailableState
            
            // Queue tech node update to clients
            self:SetTechNodeChanged(node, string.format("available = %s", ToString(newAvailableState)))
            
        end
        
    end
    
end

function TechTree:SetTechNodeChanged(node, logMsg)

    if table.insertunique(self.techNodesChanged, node) then
    
        //Print("TechNode %s changed %s", EnumToString(kTechId, node.techId), ToString(logMsg))
        self.techChanged = true
        
    end
    
end

// Utility functions
function GetHasTech(callingEntity, techId, silenceError)

    if callingEntity ~= nil and HasMixin(callingEntity, "Team") then
    
        local team = GetGamerules():GetTeam(callingEntity:GetTeamNumber())
        
        if team ~= nil and team:isa("PlayingTeam") then
        
            local techTree = team:GetTechTree()
            
            if techTree ~= nil then
                return techTree:GetHasTech(techId, silenceError)
            end
            
        end
        
    end
    
    return false
    
end
