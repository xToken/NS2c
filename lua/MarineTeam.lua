// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineTeam.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// This class is used for teams that are actually playing the game, e.g. Marines or Aliens.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Added dropped weapon tracking, slowed IP message.

Script.Load("lua/Marine.lua")
Script.Load("lua/PlayingTeam.lua")

class 'MarineTeam' (PlayingTeam)

// How often to send the "No IPs" message to the Marine team in seconds.
local kSendNoIPsMessageRate = 45

local kCannotSpawnSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/need_ip")

function MarineTeam:ResetTeam()

    local commandStructure = PlayingTeam.ResetTeam(self)
    
    self.updateMarineArmor = false
    self.droppedWeapons = {}
    self.droppedWeaponsCache = {}

    if self.brain ~= nil then
        self.brain:Reset()
    end
    return commandStructure

end

function MarineTeam:GetTeamType()
    return kMarineTeamType
end

function MarineTeam:GetIsMarineTeam()
    return true 
end

function MarineTeam:Initialize(teamName, teamNumber)

    PlayingTeam.Initialize(self, teamName, teamNumber)
    
    self.respawnEntity = Marine.kMapName
    
    self.updateMarineArmor = false
    
    self.lastTimeNoIPsMessageSent = Shared.GetTime()
    self.droppedWeapons = {}
    self.droppedWeaponsCache = {}
end

function MarineTeam:OnInitialized()

    PlayingTeam.OnInitialized(self)
    self:AddTeamResources(kMarineTeamIntialRes)
    
end

function MarineTeam:GetHasAbilityToRespawn()

    // Any active IPs on team? There could be a case where everyone has died and no active
    // IPs but builder bots are mid-construction so a marine team could theoretically keep
    // playing but ignoring that case for now
    local spawningStructures = GetEntitiesForTeam("InfantryPortal", self:GetTeamNumber())
    
    for index, current in ipairs(spawningStructures) do
    
        if current:GetIsBuilt() then
            return true
        end
        
    end        
    
    return false
    
end

function MarineTeam:OnRespawnQueueChanged()

    local spawningStructures = GetEntitiesForTeam("InfantryPortal", self:GetTeamNumber())
    
    for index, current in ipairs(spawningStructures) do
    
        if GetIsUnitActive(current) then
            current:FillQueueIfFree()
        end
        
    end        
    
end

// Clear distress flag for all players on team, unless affected by distress beaconing Observatory. 
// This function is here to make sure case with multiple observatories and distress beacons is
// handled properly.
function MarineTeam:UpdateGameMasks(timePassed)

    local beaconState = false
    
    for obsIndex, obs in ipairs(GetEntitiesForTeam("Observatory", self:GetTeamNumber())) do
    
        if obs:GetIsBeaconing() then
        
            beaconState = true
            break
            
        end
        
    end
    
    for playerIndex, player in ipairs(self:GetPlayers()) do
    
        if player:GetGameEffectMask(kGameEffect.Beacon) ~= beaconState then
            player:SetGameEffectMask(kGameEffect.Beacon, beaconState)
        end
        
    end
    
end

local function CheckForNoIPs(self)

    if Shared.GetTime() - self.lastTimeNoIPsMessageSent >= kSendNoIPsMessageRate then
    
        self.lastTimeNoIPsMessageSent = Shared.GetTime()
        if Shared.GetEntitiesWithClassname("InfantryPortal"):GetSize() == 0 then
        
            self:ForEachPlayer(function(player) StartSoundEffectForPlayer(kCannotSpawnSound, player) end)
            SendTeamMessage(self, kTeamMessageTypes.CannotSpawn)
            
        end
        
    end
    
end

function MarineTeam:Update(timePassed)

    PlayingTeam.Update(self, timePassed)
    
    // Update distress beacon mask
    self:UpdateGameMasks(timePassed)
    self:UpdateDroppedWeapons()
    
    if GetGamerules():GetGameStarted() then
        CheckForNoIPs(self)
    end
    
end



function MarineTeam:OnTechTreeUpdated()

    // true when some event occured that could require marine armor values to get updated
    if self.updateMarineArmor then
        
        for index, player in ipairs(GetEntitiesForTeam("Player", self:GetTeamNumber())) do
            player:UpdateArmorAmount()
        end
        
        self.updateMarineArmor = false
        
    end

end

function MarineTeam:OnArmsLabChanged()
    self.updateMarineArmor = true
end

function MarineTeam:InitTechTree()
   
   PlayingTeam.InitTechTree(self)
    
 // Misc
    self.techTree:AddUpgradeNode(kTechId.Recycle, kTechId.None, kTechId.None)
    self.techTree:AddOrder(kTechId.Defend)
    self.techTree:AddSpecial(kTechId.TwoCommandStations)
    self.techTree:AddSpecial(kTechId.ThreeCommandStations)

    // Marine builds
    self.techTree:AddBuildNode(kTechId.CommandStation,            kTechId.None,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.Extractor,                 kTechId.None,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.InfantryPortal,            kTechId.None,                kTechId.None)
    self.techTree:AddBuildNode(kTechId.Sentry,                    kTechId.RoboticsFactory,     kTechId.None)
    self.techTree:AddBuildNode(kTechId.Armory,                    kTechId.None,                kTechId.None)  
    self.techTree:AddBuildNode(kTechId.ArmsLab,                   kTechId.Armory,              kTechId.None)  
    self.techTree:AddUpgradeNode(kTechId.AdvancedArmory,               kTechId.Armory,        kTechId.None)
    self.techTree:AddBuildNode(kTechId.Observatory,               kTechId.InfantryPortal,       kTechId.None)      
    self.techTree:AddBuildNode(kTechId.PhaseGate,                    kTechId.PhaseTech,        kTechId.None)
    self.techTree:AddBuildNode(kTechId.RoboticsFactory,                    kTechId.Armory,              kTechId.None)  
    self.techTree:AddBuildNode(kTechId.ARCRoboticsFactory,                 kTechId.Armory,              kTechId.RoboticsFactory)
    self.techTree:AddTechInheritance(kTechId.RoboticsFactory, kTechId.ARCRoboticsFactory)
    self.techTree:AddBuildNode(kTechId.ARC,                          kTechId.ARCRoboticsFactory,                kTechId.None)       
    self.techTree:AddBuildNode(kTechId.PrototypeLab,          kTechId.AdvancedArmory,              kTechId.ArmsLab)        
    self.techTree:AddUpgradeNode(kTechId.Electrify,           kTechId.Extractor,               kTechId.None)
    
    // Marine Upgrades
    self.techTree:AddResearchNode(kTechId.PhaseTech,                    kTechId.Observatory,        kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.AdvancedArmoryUpgrade,     kTechId.Armory,        kTechId.InfantryPortal)
    self.techTree:AddResearchNode(kTechId.HandGrenadesTech,           kTechId.Armory, kTechId.None)
    self.techTree:AddUpgradeNode(kTechId.UpgradeRoboticsFactory,           kTechId.Armory,              kTechId.RoboticsFactory) 
    self.techTree:AddResearchNode(kTechId.Armor1,                   kTechId.ArmsLab,              kTechId.None)
    self.techTree:AddResearchNode(kTechId.Weapons1,                 kTechId.ArmsLab,               kTechId.None)
    self.techTree:AddResearchNode(kTechId.Armor2,                   kTechId.Armor1,              kTechId.None)
    self.techTree:AddResearchNode(kTechId.Weapons2,                 kTechId.Weapons1,            kTechId.None)
    self.techTree:AddResearchNode(kTechId.Armor3,                   kTechId.Armor2,              kTechId.None)
    self.techTree:AddResearchNode(kTechId.Weapons3,                 kTechId.Weapons2,            kTechId.None)
    self.techTree:AddResearchNode(kTechId.CatPackTech,              kTechId.None,              kTechId.None)
    self.techTree:AddResearchNode(kTechId.JetpackTech,              kTechId.PrototypeLab, kTechId.AdvancedArmory)
    self.techTree:AddResearchNode(kTechId.HeavyArmorTech,           kTechId.PrototypeLab, kTechId.AdvancedArmory)
    //self.techTree:AddResearchNode(kTechId.ExosuitTech,              kTechId.PrototypeLab, kTechId.AdvancedArmory)
    self.techTree:AddResearchNode(kTechId.MotionTracking,           kTechId.Observatory, kTechId.None)

    // Door actions
    self.techTree:AddBuildNode(kTechId.Door, kTechId.None, kTechId.None)
    self.techTree:AddActivation(kTechId.DoorOpen)
    self.techTree:AddActivation(kTechId.DoorClose)
    self.techTree:AddActivation(kTechId.DoorLock)
    self.techTree:AddActivation(kTechId.DoorUnlock)
    
    // Assists
    self.techTree:AddTargetedActivation(kTechId.MedPack,             kTechId.None,                kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.AmmoPack,            kTechId.None,                kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.CatPack,            kTechId.CatPackTech,                kTechId.None)
    self.techTree:AddActivation(kTechId.DistressBeacon,           kTechId.Observatory)    
    self.techTree:AddTargetedEnergyActivation(kTechId.Scan,             kTechId.Observatory,         kTechId.None)

    // Weapons
    self.techTree:AddTargetedActivation(kTechId.Axe,                         kTechId.None,                kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.Pistol,                      kTechId.None,                kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.Rifle,                       kTechId.None,                kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.Shotgun,                    kTechId.Armory,         kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.GrenadeLauncher,                    kTechId.AdvancedArmory,             kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.HeavyMachineGun,                    kTechId.AdvancedArmory,             kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.Mines,          kTechId.Armory,        kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.Welder,         kTechId.Armory,        kTechId.None)
    self.techTree:AddTargetedActivation(kTechId.Jetpack,        kTechId.JetpackTech, kTechId.PrototypeLab)
    self.techTree:AddTargetedActivation(kTechId.HeavyArmor,     kTechId.HeavyArmorTech, kTechId.PrototypeLab)
    //self.techTree:AddTargetedActivation(kTechId.Exosuit,        kTechId.ExosuitTech, kTechId.PrototypeLab)
    
    self.techTree:AddMenu(kTechId.WeaponsMenu)
    
    self.techTree:SetComplete()

end

function MarineTeam:AwardResources(min, max, pointOwner)

    local resAwarded = math.random(min, max) 
     self:AddTeamResources(resAwarded)

end

function MarineTeam:SpawnInitialStructures(techPoint)

    local tower, commandStation = PlayingTeam.SpawnInitialStructures(self, techPoint)
    
    return tower, commandStation
    
end

function MarineTeam:GetSpectatorMapName()
    return MarineSpectator.kMapName
end

function MarineTeam:RegisterDroppedWeapon(weaponid)
    if tonumber(weaponid) then
        table.insert(self.droppedWeapons, weaponid)
    end
end

function MarineTeam:UpdateDroppedWeapons()
    if self.lastweaponscan == nil or self.lastweaponscan + 1 < Shared.GetTime() then
        for i = #self.droppedWeapons, 1, -1 do
            if self.droppedWeapons[i] ~= nil then
                local weapon = Shared.GetEntity(self.droppedWeapons[i])
                if weapon then
                    if weapon:GetWeaponWorldState() and (Shared.GetTime() - weapon.weaponWorldStateTime) >= kItemStayTime then
                        DestroyEntity(weapon)
                        self.droppedWeaponsCache[self.droppedWeapons[i]] = nil
                        self.droppedWeapons[i] = nil
                    elseif not weapon:GetWeaponWorldState() then
                        self.droppedWeaponsCache[self.droppedWeapons[i]] = nil
                        self.droppedWeapons[i] = nil
                    end
                else
                    //Thinking theres some wierd instances of weapons picked back up and dropped that dont appear valid right away.
                    if self.droppedWeaponsCache[self.droppedWeapons[i]] then
                        self.droppedWeaponsCache[self.droppedWeapons[i]] = nil
                        self.droppedWeapons[i] = nil
                    else
                        self.droppedWeaponsCache[self.droppedWeapons[i]] = true
                    end
                end
            end
         end
         self.lastweaponscan = Shared.GetTime()
         if self.lastdeepweaponscan == nil or self.lastdeepweaponscan + 60 < Shared.GetTime() then
            for index, weapon in ientitylist(Shared.GetEntitiesWithClassname("Weapon")) do
                if weapon and weapon:GetWeaponWorldState() and (Shared.GetTime() - weapon.weaponWorldStateTime) >= kItemStayTime then
                    DestroyEntity(weapon)
                end
            end
            self.lastdeepweaponscan = Shared.GetTime()
         end
     end
end

function MarineTeam:OnBought(techId)

    local listeners = self.eventListeners['OnBought']

    if listeners then

        for _, listener in ipairs(listeners) do
            listener(techId)
        end

    end

end
