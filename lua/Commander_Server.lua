// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed alien comm refs, cooldown refs and added back in energy

Script.Load("lua/Globals.lua")

local function SortByEnergy(ent1, ent2)
    return ent1:GetEnergy() > ent2:GetEnergy()
end

function Commander:GetClassHasEnergy(className, energyAmount)

    local foundEntity = nil
    
    local entities = GetEntitiesForTeam(className, self:GetTeamNumber())    
    table.sort(entities, SortByEnergy)
    
    for index, entity in ipairs(entities) do
    
        if entity:GetEnergy() >= energyAmount and (not entity.GetIsBuilt or entity:GetIsBuilt()) then
            foundEntity = entity
            break
        end    
    
    end

    return foundEntity

end

function Commander:CheckStructureEnergy()
end

function Commander:TriggerNotification(locationId, techId)

    local message = BuildCommanderNotificationMessage(locationId, techId)
    
    // send the message only to Marines (that implies that they are alive and have a hud to display the notification
    
    for index, marine in ipairs(GetEntitiesForTeam("Player", self:GetTeamNumber())) do
        Server.SendNetworkMessage(marine, "CommanderNotification", message, true) 
    end

end

function Commander:OnDestroy()
    
    Player.OnDestroy(self)
    DeselectAllUnits(self:GetTeamNumber())
    
end

function Commander:CopyPlayerDataFrom(player)

    Player.CopyPlayerDataFrom(self, player)
    self:SetIsAlive(player:GetIsAlive())
    
    self.health = player.health
    self.maxHealth = player.maxHealth
    self.maxArmor = player.maxArmor
    
    self.parasited = player.parasited
    self.timeParasited = player.timeParasited

    local commanderStartOrigin = Vector(player:GetOrigin())
    commanderStartOrigin = commanderStartOrigin + player:GetViewOffset()
    self:SetOrigin(commanderStartOrigin)
    
    self:SetVelocity(Vector(0, 0, 0))

    // For knowing how to create the player class when leaving commander mode
    self.previousMapName = player:GetMapName()
    
    // Save previous weapon name so we can switch back to it when we logout
    self.previousWeaponMapName = ""
    local activeWeapon = player:GetActiveWeapon()
    if (activeWeapon ~= nil) then
        self.previousWeaponMapName = activeWeapon:GetMapName()
    end        
    
    self.previousHealth = player:GetHealth()
    self.previousArmor = player:GetArmor()
    
    self.previousAngles = Angles(player:GetAngles())
    
    // Save off alien values
    if player.GetEnergy then
        self.previousAlienEnergy = player:GetEnergy()
    end
    self.timeStartedCommanderMode = Shared.GetTime()
    
    self.twoHives = player.twoHives
    self.threeHives = player.threeHives
    
end

/**
 * Commanders cannot take damage.
 */
function Commander:GetCanTakeDamageOverride()
    return false
end

function Commander:GetCanDieOverride()
    return false
end

function Commander:AttemptToResearchOrUpgrade(techNode, entity)
    
    // research is only allowed for single selection
    if techNode:GetIsResearch() then
    
        local selection = self:GetSelection()
    
        if #selection == 1 then
            entity = selection[1]
        else
            return false
        end
        
    end
    
    // Don't allow it to be researched while researching.
    if entity and HasMixin(entity, "Research") then
    
        if (techNode:GetCanResearch() or techNode:GetIsManufacture()) and entity:GetCanResearch(techNode:GetTechId()) then
        
            if self:GetTechTree():GetNumberOfQueuedResearch() == 0 then
            
                entity:SetResearching(techNode, self)
                
                if not techNode:GetIsEnergyManufacture() and not techNode:GetIsPlasmaManufacture() then
                    techNode:SetResearching()
                end
                
                self:GetTechTree():SetTechNodeChanged(techNode, "researching")
                
                return true
                
            end
            
        end
        
    end
    
    return false
    
end

// TODO: Add parameters for energy or resources
function Commander:TriggerNotEnoughResourcesAlert()

    local team = self:GetTeam()
    local alertType = ConditionalValue(team:GetTeamType() == kMarineTeamType, kTechId.MarineAlertNotEnoughResources, kTechId.AlienAlertNotEnoughResources)
    local commandStructure = Shared.GetEntity(self.commandStationId)
    team:TriggerAlert(alertType, commandStructure)

end

function Commander:GetSpendResourcesSoundName()
    return Commander.kSpendResourcesSoundName
end

function Commander:GetSpendTeamResourcesSoundName()
    return Commander.kSpendTeamResourcesSoundName
end

// Return whether action should continue to be processed for the next selected unit. Position will be nil
// for non-targeted actions and will be the world position target for the action for targeted actions.
// targetId is the entityId which was hit by the client side trace
function Commander:ProcessTechTreeActionForEntity(techNode, position, normal, isCommanderPicked, orientation, entity, trace, isBot)

    local success = false
    local keepProcessing = true
    
    // First make sure tech is allowed for entity
    local techId = techNode:GetTechId()
    
    local techButtons = self:GetCurrentTechButtons(self.currentMenu, entity)
    
    // For bots, do not worry about which menu is active
    if isBot ~= true then
        if techButtons == nil or table.find(techButtons, techId) == nil then
            return success, keepProcessing
        end
    end

    // TODO: check if this really works fine. the entity should check here if something is alloed / can be afforded.
    // if no entity is selected this check is not necessary, the commander already performed the check
    if entity then
        local allowed, canAfford = entity:GetTechAllowed(techId, techNode, self)
        
        if not allowed or not canAfford then
            // no succes, but continue (can afford revers maybe to a unit specific resource type which is maybe affordable at another selected unit)
            return false, true
        end
    end
    
    // Cost is in team resources, energy or individual resources, depending on tech node type        
    local cost = GetCostForTech(techId)
    local team = self:GetTeam()
    local teamResources = team:GetTeamResources()
    
    // Let entities override actions themselves (eg, so buildbots can execute a move-build order instead of building structure immediately)
    if entity then
        success, keepProcessing = entity:OverrideTechTreeAction(techNode, position, orientation, self, trace)
    end
    
    if success then
        return success, keepProcessing
    end   
    
    // Handle tech tree actions that cost team resources    
    if techNode:GetIsResearch() or techNode:GetIsUpgrade() or techNode:GetIsBuild() or techNode:GetIsEnergyBuild() or techNode:GetIsEnergyManufacture() or techNode:GetIsManufacture() then
    
        local costsEnergy = techNode:GetIsEnergyBuild() or techNode:GetIsEnergyManufacture()

        local energy = 0
        if entity and HasMixin(entity, "Energy") then
            energy = entity:GetEnergy()
        end
        
        if (not costsEnergy and cost <= teamResources) or (costsEnergy and cost <= energy) then
        
            if techNode:GetIsResearch() or techNode:GetIsUpgrade() or techNode:GetIsEnergyManufacture() or techNode:GetIsManufacture() then
            
                success = self:AttemptToResearchOrUpgrade(techNode, entity)
                if success and techNode:GetIsResearch() then 
                    keepProcessing = false
                end
                                
            elseif techNode:GetIsBuild() or techNode:GetIsEnergyBuild() then
            
                success = self:AttemptToBuild(techId, position, normal, orientation, isCommanderPicked, false, entity)
                if success then 
                    keepProcessing = false
                end
                
            end

            if success then 
            
                if costsEnergy and entity and HasMixin(entity, "Energy") then            
                    entity:SetEnergy(entity:GetEnergy() - cost)                
                else                
                    team:AddTeamResources(-cost)                    
                end
                
                Shared.PlayPrivateSound(self, self:GetSpendTeamResourcesSoundName(), nil, 1.0, self:GetOrigin())
                
            end
            
        else
        
            self:TriggerNotEnoughResourcesAlert()
            
        end
                        
    // Handle resources-based abilities
    elseif techNode:GetIsAction() or techNode:GetIsBuy() or techNode:GetIsPlasmaManufacture() then

        local playerResources = self:GetResources()
        if(cost == nil or cost <= playerResources) then
        
            if(techNode:GetIsAction()) then            
                success = entity:PerformAction(techNode, position)
            elseif(techNode:GetIsBuy()) then
                success = self:AttemptToBuild(techId, position, normal, orientation, isCommanderPicked, false)
            elseif(techNode:GetIsPlasmaManufacture()) then
                success = self:AttemptToResearchOrUpgrade(techNode, entity)
            end
            
            if(success and cost ~= nil) then
            
                self:AddResources(-cost)
                Shared.PlayPrivateSound(self, self:GetSpendResourcesSoundName(), nil, 1.0, self:GetOrigin())
                
            end
            
        else
            self:TriggerNotEnoughResourcesAlert()
        end

    elseif techNode:GetIsActivation() then
    
        // Deduct energy cost if any
        if cost == 0 or cost <= teamResources then
        
            success, keepProcessing = entity:PerformActivation(techId, position, normal, self)

            if success and cost ~= 0 then
                team:AddTeamResources(-cost)
            end
            
        else
        
            self:TriggerNotEnoughResourcesAlert()
            
        end
        
    end
    
    return success, keepProcessing
    
end

// Send techId of action and normalized pick vector. Issues order to selected units to the world position represented by
// the pick vector, or to the entity that it hits.
function Commander:OrderEntities(orderTechId, trace, orientation, targetId)

    local invalid = false
    
    if not targetId then
        targetId = Entity.invalidId
    end
    
    if targetId == Entity.invalidId and trace.entity then
        targetId = trace.entity:GetId()
    end
    
    if trace.fraction < 1 then

        // Give order to selection
        local orderEntities = self:GetSelection()        
        local orderTechIdGiven = orderTechId
        
        for tableIndex, entity in ipairs(orderEntities) do
        
            if HasMixin(entity, "Orders") then
            
                local type = entity:GiveOrder(orderTechId, targetId, trace.endPoint, orientation, not self.queuingOrders, false)                            
            
                if type == kTechId.None then            
                    invalid = true    
                end
                
             else
                invalid = true
             end
            
        end
        
        self:OnOrderEntities(orderTechIdGiven, orderEntities)
        
    end
    
    if invalid then
        self:TriggerInvalidSound()   
    end
    
end

function Commander:OnOrderEntities(orderTechId, orderEntities)

    // Get sound and play it locally for commander and every target player
    local soundName = LookupTechData(orderTechId, kTechDataOrderSound, nil)
    
    if soundName then

        // Play order sounds if we're ordering players only
        local playSound = false
        
        for index, entity in ipairs(orderEntities) do
        
            if entity:isa("Player") then
            
                playSound = true
                break
                
            end
            
        end
    
        if playSound then
        
            /* is now handled client side
            Server.PlayPrivateSound(self, soundName, self, 1.0, Vector(0, 0, 0))
            for index, player in ipairs(orderEntities) do
                Server.PlayPrivateSound(player, soundName, player, 1.0, Vector(0, 0, 0))
            end
            */
            
        end
        
    end
    
end

local function HasEnemiesSelected(self)

    for _, unit in ipairs(self:GetSelection()) do
        if unit:GetTeamNumber() ~= self:GetTeamNumber() then
            return true
        end
    end
    
    return false

end

// Takes a techId as the action type and normalized screen coords for the position. normPickVec will be nil
// for non-targeted actions. 
function Commander:ProcessTechTreeAction(techId, pickVec, orientation, worldCoordsSpecified, targetId)

    local success = false
    
    if HasEnemiesSelected(self) then
        return false
    end
    
    local techNode = self:GetTechTree():GetTechNode(techId)
    
    if techNode == nil then
        return false
    end 
    
    if self:GetIsTechOnCooldown(techId) then
    
        self:TriggerInvalidSound()
        return false
        
    end
    
    local cost = techNode:GetCost()
    local team = self:GetTeam()
    local energystructure
    
    // check resources first. abort here in case we have no resources left to perform this action at all    
    if techNode:GetResourceType() == kResourceType.Team then
    
        if team:GetTeamResources() < cost then
        
            self:TriggerInvalidSound()
            return false
        
        end
        
    elseif techNode:GetResourceType() == kResourceType.Personal then
    
        if self:GetResources() < cost then
        
            self:TriggerInvalidSound()
            return false
        
        end
    
    elseif  techNode:GetResourceType() == kResourceType.Energy then
    
        energystructure = self:GetClassHasEnergy("Observatory", cost)
        if not energystructure then
        
            self:TriggerInvalidSound()
            return false
        
        end
        
    end
    
    // Make sure tech is available
    if techNode ~= nil and techNode.available then
    
        // Trace along pick vector to find world position of action
        local targetPosition = Vector(0, 0, 0)
        local targetNormal = Vector(0, 1, 0)
        local trace = nil
        if pickVec ~= nil then
        
            trace = GetCommanderPickTarget(self, pickVec, worldCoordsSpecified, techNode:GetIsBuild(), LookupTechData(techNode.techId, kTechDataCollideWithWorldOnly, 0))
            if trace ~= nil and trace.fraction < 1 then
            
                VectorCopy(trace.endPoint, targetPosition)
                VectorCopy(trace.normal, targetNormal)
                
            end
            
        end
        
        // If techNode is a menu, remember it so we can validate actions
        if techNode:GetIsMenu() then
            self.currentMenu = techId
        elseif techNode:GetIsOrder() then
            self:OrderEntities(techId, trace, orientation, targetId)
        else        
        
            // Sort the selected group based on distance to the target position.
            // This means the closest entity to the target position will be given
            // the order first and in some cases this will be the only entity to be
            // given the order.
            local sortedList = { }
            for index, entity in ipairs(self:GetSelection()) do
                table.insert(sortedList, entity)
            end
            Shared.SortEntitiesByDistance(targetPosition, sortedList)
            
            if #sortedList > 0 then
            
                // For every selected entity, process this desired action. For some actions (research), only
                // process once, not on every entity.
                for index, selectedEntity in ipairs(sortedList) do
                
                    local actionSuccess = false
                    local keepProcessing = false
                    actionSuccess, keepProcessing = self:ProcessTechTreeActionForEntity(techNode, targetPosition, targetNormal, pickVec ~= nil, orientation, selectedEntity, trace, targetId)
                    
                    // Successful if just one of our entities handled action
                    if actionSuccess then
                        success = true
                    end
                    
                    if not keepProcessing then
                        break
                    end
                    
                end
                
            else
                success = self:ProcessTechTreeActionForEntity(techNode, targetPosition, targetNormal, pickVec ~= nil, orientation, nil, trace, targetId)
            end
            
        end
        
    end
    
    return success
    
end

function Commander:GetSelectionHasOrder(orderEntity)

    for _, entity in ipairs(self:GetSelection()) do
        
        if entity and entity.GetHasSpecifiedOrder and entity:GetHasSpecifiedOrder(orderEntity) then
            return true
        end
        
    end
    
    return false
    
end

function Commander:GiveOrderToSelection(orderType, targetId)

end


function Commander:SetEntitiesHotkeyState(group, state)
        
    if Server then
        
        for index, entity in ipairs(group) do
    
            if entity ~= nil then
                entity:SetIsHotgrouped(state)
            end
            
        end
    
    end 
    
end

// Send data to client because it changed
function Commander:SendHotkeyGroup(number)

    local hotgroupCommand = string.format("hotgroup %d ", number)
    
    for j = 1, table.count(self.hotkeyGroups[number]) do
    
        // Need underscore between numbers so all ids are sent in one string
        hotgroupCommand = hotgroupCommand .. self.hotkeyGroups[number][j] .. "_"
        
    end
    
    Server.SendCommand(self, hotgroupCommand)
    
    return hotgroupCommand
    
end

function Commander:GetIsInterestedInAlert(techId)
    return true
end

function Commander:GotoPlayerAlert()

    for index, triple in ipairs(self.alerts) do
        
        local alertType = LookupTechData(triple[1], kTechDataAlertType, nil)
            
        if alertType == kAlertType.Request then
        
            self.lastTimeUpdatedPlayerAlerts = nil
            
            local playerAlertId = triple[2]
            local player = Shared.GetEntity(playerAlertId)
            
            if player then
            
                table.remove(self.alerts, index)
                
                DeselectAllUnits(self:GetTeamNumber())
                player:SetSelected(self:GetTeamNumber(), true, true)
                Server.SendNetworkMessage(self, "SelectAndGoto", BuildSelectAndGotoMessage(playerAlertId), true)
                
                return true
                
            end
            
        end
            
    end
    
    return false
    
end

function Commander:Logout()

    local commandStructure = Shared.GetEntity(self.commandStationId)
    commandStructure:Logout()
        
end

/**
 * Force player out of command station or hive.
 */
function Commander:Eject()

    // Get data before we create new player.
    local teamNumber = self:GetTeamNumber()
    local userId = Server.GetOwner(self):GetUserId()
    
    self:Logout()
    
    // Tell all players on team about this.
    local team = GetGamerules():GetTeam(teamNumber)
    if team:GetTeamType() == kMarineTeamType then
        team:TriggerAlert(kTechId.MarineCommanderEjected, self)
    end
    
    // Add player to list of players that can no longer command on this server (until brought down).
    GetGamerules():BanPlayerFromCommand(userId)
    
    // Notify the team.
    SendTeamMessage(team, kTeamMessageTypes.Eject)
    
end


function Commander:SetCommandStructure(commandStructure)
    self.commandStationId = commandStructure:GetId()
end

