// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Armory_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Armory:OnConstructionComplete()

    self:AddTimedCallback(Armory.OnDeploy, Armory.kDeployTime)
    
    if self.startsUpgradet then
        self:OnResearch(kTechId.AdvancedArmoryUpgrade)
        self:OnResearchComplete(kTechId.AdvancedArmoryUpgrade)
    end

end

function Armory:OnDeploy()
    self.deployed = true
    return false
end

// west/east = x/-x
// north/south = -z/z

local indexToUseOrigin =
{
    // West
    Vector(Armory.kResupplyUseRange, 0, 0), 
    // North
    Vector(0, 0, -Armory.kResupplyUseRange),
    // South
    Vector(0, 0, Armory.kResupplyUseRange),
    // East
    Vector(-Armory.kResupplyUseRange, 0, 0)
}

function Armory:GetTimeToResupplyPlayer(player)

    assert(player ~= nil)
    
    local timeResupplied = self.resuppliedPlayers[player:GetId()]
    
    if timeResupplied ~= nil then
    
        // Make sure we haven't done this recently    
        if Shared.GetTime() < (timeResupplied + Armory.kResupplyInterval) then
            return false
        end
        
    end
    
    return true
    
end

function Armory:GetShouldResupplyPlayer(player)

    if not player:GetIsAlive() then
        return false
    end
    
    local inNeed = false
    
    // Don't resupply when already full
    if (player:GetHealth() < player:GetMaxHealth()) or GetIsParasited(player) then
        inNeed = true
    else

        // Do any weapons need ammo?
        for i, child in ientitychildren(player, "ClipWeapon") do
        
            if child:GetNeedsAmmo(false) then
                inNeed = true
                break
            end
            
        end
        
    end
    
    if inNeed then
    
        // Check player facing so players can't fight while getting benefits of armory
        local viewVec = player:GetViewAngles():GetCoords().zAxis

        local toArmoryVec = self:GetOrigin() - player:GetOrigin()
        
        if(GetNormalizedVector(viewVec):DotProduct(GetNormalizedVector(toArmoryVec)) > .75) then
        
            if self:GetTimeToResupplyPlayer(player) then
        
                return true
                
            end
            
        end
        
    end
    
    return false
    
end

function Armory:ResupplyPlayer(player)
    
    local resuppliedPlayer = false
    
    // Heal player first
    if (player:GetHealth() < player:GetMaxHealth()) or GetIsParasited(player) then

        player:AddHealth(Armory.kHealAmount, true, true)

        self:TriggerEffects("armory_health", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
        
        resuppliedPlayer = true
        
        if HasMixin(player, "ParasiteAble") then
            player:RemoveParasite()
        end
        
    end

    // Give ammo to all their weapons, one clip at a time, starting from primary
    local activeWeapon = player:GetActiveWeapon()
    
    if activeWeapon ~= nil then
        if activeWeapon:GiveAmmo(1, false) then
            self:TriggerEffects("armory_ammo", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
            resuppliedPlayer = true
        end
    end 
    
    if not resuppliedPlayer then
        local weapons = player:GetHUDOrderedWeaponList()
        
        for index, weapon in ipairs(weapons) do
        
            if weapon:isa("ClipWeapon") then
            
                if weapon:GiveAmmo(1, false) then
                
                    self:TriggerEffects("armory_ammo", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
                    
                    resuppliedPlayer = true
                    
                    break
                    
                end 
                       
            end
            
        end
    end
    if resuppliedPlayer then
    
        // Insert/update entry in table
        self.resuppliedPlayers[player:GetId()] = Shared.GetTime()
        
        // Play effect
        //self:PlayArmoryScan(player:GetId())

    end

end

// Sort players by last time resupplied so players aren't starved out when Armory low
function Armory:GetSortedResupplyPlayerList()

    local playersInRange = GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(), self:GetOrigin(), Armory.kResupplyUseRange)
    
    local function SortByOldestResupply(player1, player2)
    
        local player1Time = self.resuppliedPlayers[player1:GetId()]
        local player2Time = self.resuppliedPlayers[player2:GetId()]
        if player1Time == nil then
            return false
        elseif player2Time == nil then
            return true
        end
        
        return player1Time < player2Time
        
    end

    table.sort(playersInRange, SortByOldestResupply)
    
    return playersInRange

end

function Armory:ResupplyPlayers()

    for index, player in ipairs(self:GetSortedResupplyPlayerList()) do
     
        // For each, check if they are facing us and if they haven't been resupplied for awhile
        if self:GetShouldResupplyPlayer(player) then
            self:ResupplyPlayer(player)                  
        end
            
    end

end

local function AddChildModel(self)

    local scriptActor = CreateEntity(ArmoryAddon.kMapName, nil, self:GetTeamNumber())
    scriptActor:SetParent(self)
    scriptActor:SetAttachPoint(Armory.kAttachPoint)
    
    return scriptActor
    
end

function Armory:OnResearch(researchId)

    if researchId == kTechId.AdvancedArmoryUpgrade then

        // Create visual add-on
        local advancedArmoryModule = AddChildModel(self)
        
    end
    
end

// Called when research or upgrade complete
function Armory:OnResearchComplete(researchId)

    if researchId == kTechId.AdvancedArmoryUpgrade then
        self:SetTechId(kTechId.AdvancedArmory)
    end  
    
end

// Check if friendly players are nearby and facing armory and heal/resupply them
function Armory:OnThink()

    ScriptActor.OnThink(self)

    self:UpdateLoggedIn()
    
    // Make sure players are still close enough, alive, marines, etc.
    if GetIsUnitActive(self) then
    
        // Give health and ammo to logged in players
        self:ResupplyPlayers()
        
    end    
    
    self:SetNextThink(Armory.kThinkTime)
    
end

function Armory:UpdateLoggedIn()

    local players = GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(), self:GetOrigin(), 2 * Armory.kResupplyUseRange)
    local armoryCoords = self:GetAngles():GetCoords()
    
    for i = 1, 4 do
    
        local newState = false
        
        if GetIsUnitActive(self) then
        
            local worldUseOrigin = self:GetModelOrigin() + armoryCoords:TransformVector(indexToUseOrigin[i])
        
            for playerIndex, player in ipairs(players) do
            
                // See if valid player is nearby
                if player:GetIsAlive() and (player:GetModelOrigin() - worldUseOrigin):GetLength() < Armory.kResupplyUseRange then
                
                    newState = true
                    break
                    
                end
                
            end
            
        end
        
        if newState ~= self.loggedInArray[i] then
        
            if newState then
                self:TriggerEffects("armory_open")
            else
                self:TriggerEffects("armory_close")
            end
            
            self.loggedInArray[i] = newState
            
        end
        
    end
    
    // Copy data to network variables (arrays not supported)    
    self.loggedInWest = self.loggedInArray[1]
    self.loggedInNorth = self.loggedInArray[2]
    self.loggedInSouth = self.loggedInArray[3]
    self.loggedInEast = self.loggedInArray[4]

end

