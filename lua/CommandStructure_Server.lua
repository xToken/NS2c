// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommandStructure_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function CommandStructure:SetCustomPhysicsGroup()
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
end

function CommandStructure:OnKill(attacker, doer, point, direction)

    self:Logout()
    ScriptActor.OnKill(self, attacker, doer, point, direction)

end

function CommandStructure:OnSighted(sighted)
end

// Children should override this
function CommandStructure:GetTeamType()
    return kNeutralTeamType
end

function CommandStructure:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self.commanderId = Entity.invalidId
    self.occupied = false
    self.closedTime = 0
    self.loginAllowed = false

end

function CommandStructure:OnDestroy()

    if self.occupied then
        self:Logout()
    end

    ScriptActor.OnDestroy(self)                        
            
end

function CommandStructure:GetCommanderClassName()
    return Commander.kMapName   
end

function CommandStructure:GetWaitForCloseToLogin()
    return false
end

function CommandStructure:GetIsPlayerValidForCommander(player)
    local team = self:GetTeam()
    return player ~= nil and not team:GetHasCommander() and player:GetIsAlive() and player:GetTeamNumber() == self:GetTeamNumber() 
end

function CommandStructure:OnCommanderLogin()
end

function CommandStructure:LoginPlayer(player)

    local commanderStartOrigin = Vector(player:GetOrigin())
    
    if player.OnCommanderStructureLogin then
        player:OnCommanderStructureLogin(self)
    end
    
    // Create Commander player
    local commanderPlayer = player:Replace(self:GetCommanderClassName(), player:GetTeamNumber(), true, commanderStartOrigin)
    
    // Set all child entities and view model invisible
    function SetInvisible(childEntity) 
        childEntity:SetIsVisible(false)
    end
    commanderPlayer:ForEachChild(SetInvisible)
    
    if commanderPlayer:GetViewModelEntity() then
        commanderPlayer:GetViewModelEntity():SetModel("")
    end
    
    // Clear game effects on player
    commanderPlayer:ClearGameEffects()    
    commanderPlayer:SetCommandStructure(self)
    
    // Save origin so we can restore it on logout
    commanderPlayer.lastGroundOrigin = Vector(commanderStartOrigin)

    self.commanderId = commanderPlayer:GetId()
    
    // Must reset offset angles once player becomes commander
    commanderPlayer:SetOffsetAngles(Angles(0, 0, 0))
    
    self:OnCommanderLogin()
    
    return commanderPlayer
    
end

function CommandStructure:GetCommander()
    return Shared.GetEntity(self.commanderId)
end

function CommandStructure:OnUse(player, elapsedTime, useSuccessTable)
end

function CommandStructure:OnEntityChange(oldEntityId, newEntityId)

    if self.commanderId == oldEntityId then
    
        self.occupied = false
        self.commanderId = Entity.invalidId
        
    end
    
end

/**
 * Returns the logged out player if there is currently one logged in.
 */
function CommandStructure:Logout()

    // Change commander back to player.
    local commander = self:GetCommander()
    local returnPlayer = nil
    
    if commander then
    
        local previousWeaponMapName = commander.previousWeaponMapName
        local previousOrigin = commander.lastGroundOrigin
        local previousAngles = commander.previousAngles
        local previousHealth = commander.previousHealth
        local previousArmor = commander.previousArmor
        local previousMaxArmor = commander.maxArmor
        local previousAlienEnergy = commander.previousAlienEnergy
        local timeStartedCommanderMode = commander.timeStartedCommanderMode
        local parasiteState = commander.parasited
        local parasiteTime = commander.timeParasited
        
        local returnPlayer = commander:Replace(commander.previousMapName, commander:GetTeamNumber(), true, previousOrigin)    
        
        if returnPlayer.OnCommanderStructureLogout then
            returnPlayer:OnCommanderStructureLogout(self)
        end
        
        returnPlayer:SetActiveWeapon(previousWeaponMapName)
        returnPlayer:SetOrigin(previousOrigin)
        returnPlayer:SetAngles(previousAngles)
        returnPlayer:SetHealth(previousHealth)
        returnPlayer:SetMaxArmor(previousMaxArmor)
        returnPlayer:SetArmor(previousArmor)
        returnPlayer.frozen = false
        
        returnPlayer.parasited = parasiteState
        returnPlayer.timeParasited = parasiteTime

        if previousAlienEnergy and returnPlayer.SetEnergy then
            returnPlayer:SetEnergy(previousAlienEnergy)
        end
        
        returnPlayer:UpdateArmorAmount()
        
        returnPlayer.twoHives = commander.twoHives
        returnPlayer.threeHives = commander.threeHives
        
        self.playerIdStartedLogin = nil
        
        self.occupied = false
        self.commanderId = Entity.invalidId
        
        // TODO: trigger client side in OnTag
        self:TriggerEffects("commandstation_logout")
        
    end
    
    return returnPlayer
    
end

function CommandStructure:OnOverrideOrder(order)

    // Convert default to set rally point.
    if order:GetType() == kTechId.Default then
        order:SetType(kTechId.SetRally)
    end
    
end

function CommandStructure:OnTag(tagName)

    PROFILE("CommandStructure:OnTag")
    
    if tagName == "closed" then
        self.closedTime = Shared.GetTime()
    elseif tagName == "opened" then
        self.loginAllowed = true
    elseif tagName == "login_start" then
        self.loginAllowed = false
    end
    
end