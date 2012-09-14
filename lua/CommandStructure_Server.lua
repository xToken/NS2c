// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommandStructure_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kCheckForLoginTimer = 0.25

function CommandStructure:SetCustomPhysicsGroup()
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
end

function CommandStructure:OnKill(attacker, doer, point, direction)

    self:Logout()
    ScriptActor.OnKill(self, attacker, doer, point, direction)
    
    if self.objectiveInfoEntId and self.objectiveInfoEntId ~= Entity.invalidId then
    
        DestroyEntity(Shared.GetEntity(self.objectiveInfoEntId))
        self.objectiveInfoEntId = Entity.invalidId
        
    end

end

function CommandStructure:OnSighted(sighted)

    local attached = self:GetAttached()
    if attached and sighted then
        attached.showObjective = true
    end

end

// Children should override this
function CommandStructure:GetTeamType()
    return kNeutralTeamType
end

local function CheckForLogin(self)

    self:UpdateCommanderLogin()
    return true
    
end

function CommandStructure:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self.commanderId = Entity.invalidId    
    self.occupied = false    
    self.closedTime = 0    
    self:AddTimedCallback(CheckForLogin, kCheckForLoginTimer)
    
    if Server then
    
        local objectiveInfoEnt = CreateEntity(ObjectiveInfo.kMapName, self:GetOrigin(), self:GetTeamNumber())
        objectiveInfoEnt:SetOwner(self:GetId())
        self.objectiveInfoEntId = objectiveInfoEnt:GetId()
    
    end
    
end

function CommandStructure:OnDestroy()

    if self.occupied then
        self:Logout()
    end
    
    if self.objectiveInfoEntId and self.objectiveInfoEntId ~= Entity.invalidId then
    
        DestroyEntity(Shared.GetEntity(self.objectiveInfoEntId))
        self.objectiveInfoEntId = Entity.invalidId
        
    end

    ScriptActor.OnDestroy(self)                        
            
end

function CommandStructure:GetCommanderClassName()
    return Commander.kMapName   
end

function CommandStructure:GetWaitForCloseToLogin()
    return true
end

function CommandStructure:GetIsPlayerValidForCommander(player)
    local team = self:GetTeam()
    return player ~= nil and not team:GetHasCommander() and player:GetIsAlive() and player:GetTeamNumber() == self:GetTeamNumber() 
end

function CommandStructure:UpdateCommanderLogin(force)

    local allowedToLogin = not self:GetWaitForCloseToLogin() or (Shared.GetTime() - self.closedTime < 1)
    if self.occupied and self.commanderId == Entity.invalidId and allowedToLogin or force then
    
        // Don't turn player into commander until short time later
        local player = Shared.GetEntity(self.playerIdStartedLogin)
        
        if (self:GetIsPlayerValidForCommander(player) and GetIsUnitActive(self)) or force then
            self:LoginPlayer(player)
        // Player was killed, became invalid or left the server somehow
        else
        
            self.occupied = false
            self.commanderId = Entity.invalidId
            // TODO: trigger client side in OnTag
            self:TriggerEffects(self:isa("Hive") and "hive_logout" or "commandstation_logout")
            
        end
        
    end
    
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
    
    // Make this structure the first hotgroup if we don't have any yet
    if commanderPlayer:GetNumHotkeyGroups() == 0 then
        commanderPlayer:CreateHotkeyGroup(1, { self:GetId() })
    end
    
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

// Put player into Commander mode
function CommandStructure:OnUse(player, elapsedTime, useAttachPoint, usePoint, useSuccessTable)

    local teamNum = self:GetTeamNumber()
    local csUseSuccess = false
    
    if teamNum == 0 or teamNum == player:GetTeamNumber() and teamNum == kMarineTeamType then
    
        if self:GetIsBuilt() then
        
            // Make sure player wasn't ejected early in the game from either team's command
            local playerSteamId = Server.GetOwner(player):GetUserId()
            if not GetGamerules():GetPlayerBannedFromCommand(playerSteamId) then
            
                local team = self:GetTeam()
                if not team:GetHasCommander() then
                
                    // Must use attach point if specified (Command Station)            
                    if not self.occupied and (useAttachPoint or (self:GetUseAttachPoint() == "")) then
                        
                        self.playerIdStartedLogin = player:GetId()                        
                        self.occupied = true
                        csUseSuccess = true
                        
                        // TODO: trigger client side in OnTag
                        self:TriggerEffects(self:isa("Hive") and "hive_login" or "commandstation_login")
                        
                    end
                    
                end
                
            end  
            
        elseif not self:GetIsBuilt() and player:isa("Marine") and self:isa("CommandStation") then
            csUseSuccess = true
        end
    elseif teamNum == player:GetTeamNumber() and teamNum == kAlienTeamType then
        if self:GetIsBuilt() then
            player:TeleportToHive(self)
        else
            self:OnTakeDamage(0, player, player:GetActiveWeapon(), player:GetOrigin())
        end
    end
    
    if not csUseSuccess then
        player:TriggerInvalidSound()
    end    
    
    useSuccessTable.useSuccess = useSuccessTable.useSuccess and csUseSuccess
    
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
        
        // Restore previous alien energy, but let us recuperate at the regular rate while we're in the hive
        if previousAlienEnergy and returnPlayer.SetEnergy and timeStartedCommanderMode then
        
            local timePassedSinceStartedComm = Shared.GetTime() - timeStartedCommanderMode
            returnPlayer:SetEnergy(previousAlienEnergy + Alien.kEnergyRecuperationRate * timePassedSinceStartedComm)
            
        end
        
        returnPlayer:UpdateArmorAmount()
        
        returnPlayer.twoHives = commander.twoHives
        returnPlayer.threeHives = commander.threeHives
        
        self.playerIdStartedLogin = nil
        
        self.occupied = false
        self.commanderId = Entity.invalidId
        
        // TODO: trigger client side in OnTag
        self:TriggerEffects(self:isa("Hive") and "hive_logout" or "commandstation_logout")
        
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
    end
    
end