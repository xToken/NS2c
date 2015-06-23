// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommandStation_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed damage around CC in pregame.

function CommandStation:GetTeamType()
    return kMarineTeamType
end

function CommandStation:GetCommanderClassName()
    return MarineCommander.kMapName
end

function CommandStation:GetIsPlayerValidForCommander(player)
    return player ~= nil and player:isa("Marine") and CommandStructure.GetIsPlayerValidForCommander(self, player)
end

// Put player into Commander mode
function CommandStation:OnUse(player, elapsedTime, useSuccessTable)

    local csUseSuccess = false

    if self:GetIsBuilt() then
    
        // Make sure player wasn't ejected early in the game from either team's command
        local playerSteamId = Server.GetOwner(player):GetUserId()
        if not GetGamerules():GetPlayerBannedFromCommand(playerSteamId) then
        
            local team = self:GetTeam()
            if not team:GetHasCommander() then
            
                // Must use attach point if specified (Command Station)            
                if not self.occupied and self.loginAllowed and self:GetIsPlayerValidForCommander(player) then
                
                    self:LoginPlayer(player)                      
                    self.occupied = true
                    csUseSuccess = true
                    
                    // TODO: trigger client side in OnTag
                    self:TriggerEffects("commandstation_login")
                    
                end
                
            end
            
        end
        
    elseif not self:GetIsBuilt() then
        csUseSuccess = true
    end
    
    if not csUseSuccess then
        player:TriggerInvalidSound()
    end
    
    useSuccessTable.useSuccess = useSuccessTable.useSuccess and csUseSuccess
    
end

function CommandStation:GetKillOrigin()
    return self:GetOrigin() + Vector(0, 1.5, 0)
end

function CommandStation:OnTakeDamage(damage, attacker, doer, point)
    if GetAreEnemies(self, attacker) and damage > 0 and GetServerGameMode() == kGameMode.Combat and attacker and attacker.AddExperience then
        attacker:AddExperience(damage / self:GetMaxHealth() * kCombatObjectiveExperienceScalar)
    end
end

function CommandStation:OnConstructionComplete()
    self:TriggerEffects("deploy")    
end

function CommandStation:OnWeldOverride(doer, elapsedTime, player)
    if doer:isa("Welder") then
        local amountWelded = doer:GetRepairRate(self) * elapsedTime
        self:AddHealth(amountWelded)
        if GetServerGameMode() == kGameMode.Combat and player and player.AddExperience then
            player:AddExperience(amountWelded / self:GetMaxHealth() * kCombatObjectiveExperienceScalar)
        end
    end
end

function CommandStation:GetCompleteAlertId()
    return kTechId.MarineAlertCommandStationComplete
end

function CommandStation:GetDamagedAlertId()
    return kTechId.MarineAlertCommandStationUnderAttack
end