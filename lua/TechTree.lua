// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechTree.lua
//
// Tracks state of a team's technology. Contains tech nodes and functions for building, unlocking 
// and manipulating them.
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
class 'TechTree'

if Server then
    Script.Load("lua/TechTree_Server.lua")
elseif Client then
    Script.Load("lua/TechTree_Client.lua")
elseif Predict then
    // we reuse-the client stuff
    Script.Load("lua/TechTree_Client.lua")
end

// Constructor
function TechTree:Initialize()

    self.nodeList = {}
    
    self.techChanged = false
    self.complete = false
    
    // No need to add to team
    self.teamNumber = kTeamReadyRoom
    
    if Server then
        self.techNodesChanged = {}
        self.upgradedTechIdsSupporting = {}
    end
        
end

function TechTree:AddNode(node)

    local nodeEntityId = node:GetTechId()
    
    assert(self.nodeList[nodeEntityId] == nil)
    
    self.nodeList[nodeEntityId] = node
    
end

function TechTree:GetTechNode(techId)
    return self.nodeList[techId]
end

function TechTree:GetRequiredTechIds()

    local requiredTechIds = {}

    for _, node in pairs(self.nodeList) do
    
        local prereq1 = node:GetPrereq1()
        if prereq1 and prereq1 ~= kTechId.None then
            requiredTechIds[prereq1] = true
        end
        
        local prereq2 = node:GetPrereq2()
        if prereq2 and prereq2 ~= kTechId.None then
            requiredTechIds[prereq2] = true
        end
        
        if node.isRequired then
            requiredTechIds[node:GetTechId()] = true
        end
    
    end

    return requiredTechIds

end

function TechTree:GetTechAvailable(techId)

    if techId == kTechId.None then
        return true
    else
    
        local techNode = self:GetTechNode(techId)
        return techNode and techNode:GetAvailable() or false
        
    end
    
end

// Check if active structures on our team that support this technology. These are
// are computed during ComputeAvailability().
function TechTree:GetHasTech(techId)

    if techId == kTechId.None then
        return true
    else
    
        local hasTech = false
    
        local node = self:GetTechNode(techId)    
        
        if node then
            hasTech = node:GetHasTech()
        end    
            
        if not hasTech and self.techInheritance then
        
            // check inheritance techs
            for _, techInheritance in ipairs(self.techInheritance) do

                if techInheritance[1] == techId then
                
                    local childNode = self:GetTechNode(techInheritance[2])
                    if childNode then
                    
                        hasTech = childNode:GetHasTech()
                        
                        if hasTech then
                            break
                        end
                        
                    end
                    
                end
            
            end
        
        end
        
        return hasTech
        
    end
    
    return false

end

function TechTree:GetIsTechAvailable(techId)
    
    local techNode = self:GetTechNode(techId)
    if techNode then
        return techNode:GetAvailable()
    end 
    
    return false

end

// Returns string describing tech node 
function TechTree:GetDescriptionText(techId)

    local techNode = self:GetTechNode(techId)
    local text = GetDisplayNameForTechId(techId)
    if(techNode == nil or text == nil) then
        return ""
    end
    
    return text

end

function TechTree:GetRequiresText(techId)

    local text = ""

    if techId ~= kTechId.None then    
    
        local techNode = self:GetTechNode(techId)
        if(techNode ~= nil and not techNode.available) then
        
            local addedPrereq1 = false
            local addedPrereq2 = false
            if(techNode.prereq1 ~= kTechId.None) then
                local missing = string.format("<missing display for %s", EnumToString(kTechId, techNode.prereq1))
                text = string.format("%s%s", text, GetDisplayNameForTechId(techNode.prereq1, missing))
                addedPrereq1 = true
            end
            
            if(techNode.prereq2 ~= kTechId.None) then        
                local missing = string.format("<missing display for %s>", EnumToString(kTechId, techNode.prereq2))
                local displayName = GetDisplayNameForTechId(techNode.prereq2, missing)
                text = string.format("%s%s%s", text, ConditionalValue(addedPrereq1, ", ", ""), displayName)
                addedPrereq2 = true
            end
            
        end
        
    end
    
    return text

end

// Return text description of other unavailable tech nodes that directly depend on this one
function TechTree:GetEnablesText(techId)

    local text = ""

    for index, techNode in pairs(self.nodeList) do

        if not techNode.available and ( (techNode:GetPrereq1() == techId) or (techNode:GetPrereq2() == techId) ) then

            // Only display tech nodes that make sense to show
            local showEnables = LookupTechData(techNode:GetTechId(), kTechIDShowEnables, true)
            if showEnables then
            
                if text ~= "" then
                    text = text .. ", "
                end
                
                local display = string.format("<missing display for %s>", EnumToString(kTechId, techNode:GetTechId()))
                text = string.format("%s%s", text, GetDisplayNameForTechId(techNode:GetTechId(), display))
                
            end
            
        end        
        
    end
    
    return text

end

// Get the 0-1 research progress for a buy node. Assumes that it only has one prerequisite and that the
// prerequisite is research. For instance, check the research process for Shotgun, which has its
// prerequisite1 as ShotgunTech. Used for displaying research in progress at the marine and alien
// buy menus. Returns 1 if tech is available or if there is no prerequisite.
function TechTree:GetResearchProgressForNode(buyTechId)

    local researchAmount = 1
    local techNode = self:GetTechNode(buyTechId)
    if techNode and not techNode:GetAvailable() then

        researchAmount = 0
        
        local prereq1 = techNode:GetPrereq1()
        if prereq1 ~= kTechId.None then
        
            local prereqNode = self:GetTechNode(prereq1)
            if prereqNode ~= nil and prereqNode:GetResearching() then
            
                researchProgress = prereqNode:GetResearchProgress()
                
            end
            
        end
        
    end
    
    return researchAmount
    
end

// Return array of tech ids that are addons for specified tech id
function TechTree:GetAddOnsForTechId(techId)

    local addons = { }

    for index, techNode in pairs(self.nodeList) do
    
        if techNode ~= nil and techNode:isa("TechNode") then
        
            if techNode:GetAddOnTechId() == techId then
                table.insert(addons, techNode:GetTechId())
            end
            
        end
        
    end
    
    return addons
    
end

function TechTree:GetTeamNumber()
    return self.teamNumber
end

function GetTechUpgradesFromTech(upgradeTechId, techId)

    local upgradeTechId = LookupTechData(upgradeTechId, kTechDataUpgradeTech, kTechId.None)
    
    if(upgradeTechId ~= nil and upgradeTechId ~= kTechId.None) then
    
        if(upgradeTechId == techId) then
        
            return true
            
        else
        
            return GetTechUpgradesFromTech(upgradeTechId, techId)
            
        end
        
    end
    
    return false
    
end

function TechTree:ComputeUpgradedTechIdsSupportingId(techId)

    local techIds = {}
    
    // Find all tech that supports techId through an upgrade
    for index, techNode in pairs(self.nodeList) do
    
        local currentTechId = techNode:GetTechId()
        
        if(GetTechUpgradesFromTech(currentTechId, techId)) then
        
            table.insert(techIds, currentTechId)
            
        end
        
    end
    
    return techIds
    
end

function GetIsTechResearching(player, techId)

    local techTree = player:GetTechTree()

    if techTree then
        local techNode = techTree:GetTechNode(techId)
        return techNode ~= nil and techNode:GetResearching()
    end
    
    return false

end

function GetIsTechUnlocked(player, techId)

    local techTree = player:GetTechTree()
    local isUnlocked = false
    
    if techTree then
    
        local techNode = techTree:GetTechNode(techId)
        if techNode then
        
            if techNode:GetIsResearch() then
                return techNode:GetHasTech()
            else
                return techNode:GetAvailable()
            end   
 
        end
    
    end
    
    return isUnlocked    

end
