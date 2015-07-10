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

MarineTeam.gSandboxMode = false

// How often to send the "No IPs" message to the Marine team in seconds.
local kSendNoIPsMessageRate = 45
local kCannotSpawnSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/need_ip")

function MarineTeam:ResetTeam()

    local commandStructure = PlayingTeam.ResetTeam(self)
    self.usedArmorySpawns = { }
    self.updateMarineArmor = false
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
    self.usedArmorySpawns = { }
    self.updateMarineArmor = false
    
    self.lastTimeNoIPsMessageSent = Shared.GetTime()

end

function MarineTeam:OnInitialized()

    PlayingTeam.OnInitialized(self)
    
    if GetServerGameMode() == kGameMode.Classic then
        self:AddTeamResources(kMarineTeamIntialRes)
    end
     
end

function MarineTeam:GetHasAbilityToRespawn()

    // Any active IPs on team? There could be a case where everyone has died and no active
    // IPs but builder bots are mid-construction so a marine team could theoretically keep
    // playing but ignoring that case for now
    local spawnclassname = ConditionalValue(GetServerGameMode() == kGameMode.Classic, "InfantryPortal", "CommandStation")
    local spawningStructures = GetEntitiesForTeam(spawnclassname, self:GetTeamNumber())
    
    for index, current in ipairs(spawningStructures) do
    
        if current:GetIsBuilt() and current:GetIsAlive() then
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


function MarineTeam:GetTotalInRespawnQueue()
    
    local queueSize = #self.respawnQueue
    local numPlayers = 0
    
    for i = 1, #self.respawnQueue do
        local player = Shared.GetEntity(self.respawnQueue[i])
        if player then
            numPlayers = numPlayers + 1
        end
    
    end
    
    local allIPs = GetEntitiesForTeam( "InfantryPortal", self:GetTeamNumber() )
    if #allIPs > 0 then
        
        for _, ip in ipairs( allIPs ) do
        
            if GetIsUnitActive( ip ) then
                
                if ip.queuedPlayerId ~= nil and ip.queuedPlayerId ~= Entity.invalidId then
                    numPlayers = numPlayers + 1
                end
                
            end
        
        end
        
    end
    
    return numPlayers
    
end


// Clear distress flag for all players on team, unless affected by distress beaconing Observatory. 
// This function is here to make sure case with multiple observatories and distress beacons is
// handled properly.
function MarineTeam:UpdateGameMasks(timePassed)

    PROFILE("MarineTeam:UpdateGameMasks")

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

    PROFILE("MarineTeam:CheckForNoIPs")

    if Shared.GetTime() - self.lastTimeNoIPsMessageSent >= kSendNoIPsMessageRate then
    
        self.lastTimeNoIPsMessageSent = Shared.GetTime()
        if Shared.GetEntitiesWithClassname("InfantryPortal"):GetSize() == 0 then
        
            self:ForEachPlayer(function(player) StartSoundEffectForPlayer(kCannotSpawnSound, player) end)
            SendTeamMessage(self, kTeamMessageTypes.CannotSpawn)
            
        end
        
    end
    
end

local function GetArmorLevel(self)

    local armorLevels = 0
    
    local techTree = self:GetTechTree()
    if techTree then
    
        if techTree:GetHasTech(kTechId.Armor3) then
            armorLevels = 3
        elseif techTree:GetHasTech(kTechId.Armor2) then
            armorLevels = 2
        elseif techTree:GetHasTech(kTechId.Armor1) then
            armorLevels = 1
        end
    
    end
    
    return armorLevels

end

function MarineTeam:Update(timePassed)

    PROFILE("MarineTeam:Update")

    PlayingTeam.Update(self, timePassed)
    
    // Update distress beacon mask
    self:UpdateGameMasks(timePassed)
    
    if GetServerGameMode() == kGameMode.Classic then
        if GetGamerules():GetGameStarted() then
            CheckForNoIPs(self)
        end
        local armorLevel = GetArmorLevel(self)
        for index, player in ipairs(GetEntitiesForTeam("Player", self:GetTeamNumber())) do
            player:UpdateArmorAmount(armorLevel)
        end 
    end
    
end

function MarineTeam:InitTechTree(techTree)
   
    PlayingTeam.InitTechTree(self, techTree)
    
    // Misc
    techTree:AddUpgradeNode(kTechId.Recycle, kTechId.None, kTechId.None)
    techTree:AddOrder(kTechId.Defend)
    techTree:AddSpecial(kTechId.TwoCommandStations)
    techTree:AddSpecial(kTechId.ThreeCommandStations)
    
        // Door actions
    techTree:AddBuildNode(kTechId.Door, kTechId.None, kTechId.None)
    techTree:AddActivation(kTechId.DoorOpen)
    techTree:AddActivation(kTechId.DoorClose)
    techTree:AddActivation(kTechId.DoorLock)
    techTree:AddActivation(kTechId.DoorUnlock)
    
    if GetServerGameMode() == kGameMode.Classic then
    
        // Marine builds
        techTree:AddBuildNode(kTechId.CommandStation,            kTechId.None,                kTechId.None)
        techTree:AddBuildNode(kTechId.Extractor,                 kTechId.None,                kTechId.None)
        techTree:AddBuildNode(kTechId.InfantryPortal,            kTechId.None,                kTechId.None)
        techTree:AddBuildNode(kTechId.Sentry,                    kTechId.TurretFactory,       kTechId.None)
        techTree:AddBuildNode(kTechId.Armory,                    kTechId.None,                kTechId.None)  
        techTree:AddBuildNode(kTechId.ArmsLab,                   kTechId.Armory,              kTechId.None)  
        techTree:AddUpgradeNode(kTechId.AdvancedArmory,          kTechId.Armory,              kTechId.None)
        techTree:AddBuildNode(kTechId.Observatory,               kTechId.InfantryPortal,      kTechId.None)      
        techTree:AddBuildNode(kTechId.PhaseGate,                 kTechId.PhaseTech,           kTechId.None)
        techTree:AddBuildNode(kTechId.TurretFactory,             kTechId.Armory,              kTechId.None)  
        techTree:AddBuildNode(kTechId.AdvancedTurretFactory,     kTechId.Armory,              kTechId.TurretFactory)
        techTree:AddTechInheritance(kTechId.TurretFactory,       kTechId.AdvancedTurretFactory)
        techTree:AddBuildNode(kTechId.SiegeCannon,               kTechId.AdvancedTurretFactory,  kTechId.None)       
        techTree:AddBuildNode(kTechId.PrototypeLab,              kTechId.AdvancedArmory,              kTechId.ArmsLab)        
        techTree:AddUpgradeNode(kTechId.Electrify,               kTechId.Extractor,               kTechId.None)
        
        // Marine Upgrades
        techTree:AddResearchNode(kTechId.PhaseTech,                    kTechId.Observatory,        kTechId.None)
        techTree:AddUpgradeNode(kTechId.AdvancedArmoryUpgrade,     kTechId.Armory,        kTechId.InfantryPortal)
        techTree:AddResearchNode(kTechId.HandGrenadesTech,           kTechId.Armory, kTechId.None)
        techTree:AddUpgradeNode(kTechId.UpgradeTurretFactory,           kTechId.Armory,              kTechId.TurretFactory) 
        techTree:AddResearchNode(kTechId.Armor1,                   kTechId.ArmsLab,              kTechId.None)
        techTree:AddResearchNode(kTechId.Weapons1,                 kTechId.ArmsLab,               kTechId.None)
        techTree:AddResearchNode(kTechId.Armor2,                   kTechId.Armor1,              kTechId.None)
        techTree:AddResearchNode(kTechId.Weapons2,                 kTechId.Weapons1,            kTechId.None)
        techTree:AddResearchNode(kTechId.Armor3,                   kTechId.Armor2,              kTechId.None)
        techTree:AddResearchNode(kTechId.Weapons3,                 kTechId.Weapons2,            kTechId.None)
        techTree:AddResearchNode(kTechId.CatPackTech,              kTechId.None,              kTechId.None)
        techTree:AddResearchNode(kTechId.JetpackTech,              kTechId.PrototypeLab, kTechId.AdvancedArmory)
        techTree:AddResearchNode(kTechId.HeavyArmorTech,           kTechId.PrototypeLab, kTechId.AdvancedArmory)
        //techTree:AddResearchNode(kTechId.ExosuitTech,              kTechId.PrototypeLab, kTechId.AdvancedArmory)
        techTree:AddResearchNode(kTechId.MotionTracking,           kTechId.Observatory, kTechId.None)
    
        // Assists
        techTree:AddTargetedActivation(kTechId.MedPack,             kTechId.None,                kTechId.None)
        techTree:AddTargetedActivation(kTechId.AmmoPack,            kTechId.None,                kTechId.None)
        techTree:AddTargetedActivation(kTechId.CatPack,            kTechId.CatPackTech,                kTechId.None)
        techTree:AddActivation(kTechId.DistressBeacon,           kTechId.Observatory)    
        techTree:AddTargetedEnergyActivation(kTechId.Scan,             kTechId.Observatory,         kTechId.None)

        // Weapons
        techTree:AddTargetedActivation(kTechId.Axe,                         kTechId.None,                kTechId.None)
        techTree:AddTargetedActivation(kTechId.Pistol,                      kTechId.None,                kTechId.None)
        techTree:AddTargetedActivation(kTechId.Rifle,                       kTechId.None,                kTechId.None)
        techTree:AddTargetedActivation(kTechId.Shotgun,                    kTechId.Armory,         kTechId.None)
        techTree:AddTargetedActivation(kTechId.GrenadeLauncher,                    kTechId.AdvancedArmory,             kTechId.None)
        techTree:AddTargetedActivation(kTechId.HeavyMachineGun,                    kTechId.AdvancedArmory,             kTechId.None)
        //techTree:AddTargetedActivation(kTechId.Flamethrower,                    kTechId.AdvancedArmory,             kTechId.None)
        techTree:AddTargetedActivation(kTechId.Mines,          kTechId.Armory,        kTechId.None)
        techTree:AddTargetedActivation(kTechId.Welder,         kTechId.Armory,        kTechId.None)
        techTree:AddTargetedActivation(kTechId.Jetpack,        kTechId.JetpackTech, kTechId.PrototypeLab)
        techTree:AddTargetedActivation(kTechId.HeavyArmor,     kTechId.HeavyArmorTech, kTechId.PrototypeLab)
        //techTree:AddTargetedActivation(kTechId.Exosuit,        kTechId.ExosuitTech, kTechId.PrototypeLab)
        
    end
    
    if GetServerGameMode() == kGameMode.Combat then
    
        techTree:AddBuyNode(kTechId.Armor1,                   kTechId.None,               kTechId.None, kTechId.AllMarines)  
        techTree:AddBuyNode(kTechId.Weapons1,                 kTechId.None,               kTechId.None, kTechId.AllMarines)  
        techTree:AddBuyNode(kTechId.Armor2,                   kTechId.Armor1,             kTechId.None, kTechId.AllMarines)  
        techTree:AddBuyNode(kTechId.Weapons2,                 kTechId.Weapons1,           kTechId.None, kTechId.AllMarines)  
        techTree:AddBuyNode(kTechId.Armor3,                   kTechId.Armor2,             kTechId.None, kTechId.AllMarines)  
        techTree:AddBuyNode(kTechId.Weapons3,                 kTechId.Weapons2,           kTechId.None, kTechId.AllMarines)  
        techTree:AddBuyNode(kTechId.MotionTracking,           kTechId.None,               kTechId.None, kTechId.AllMarines)  
    	
    	//Weapons
    	techTree:AddBuyNode(kTechId.Shotgun,                  kTechId.Weapons1,           kTechId.None, kTechId.AllMarines)  
        techTree:AddBuyNode(kTechId.GrenadeLauncher,          kTechId.Shotgun,            kTechId.None, kTechId.AllMarines)  
        techTree:AddBuyNode(kTechId.HeavyMachineGun,          kTechId.Shotgun,            kTechId.None, kTechId.AllMarines)  
        techTree:AddBuyNode(kTechId.Mines,                    kTechId.None,               kTechId.None, kTechId.AllMarines)  
        techTree:AddBuyNode(kTechId.Welder,                   kTechId.None,               kTechId.None, kTechId.AllMarines)  
        techTree:AddBuyNode(kTechId.HandGrenades,             kTechId.None,               kTechId.None, kTechId.AllMarines)  
        techTree:AddBuyNode(kTechId.Jetpack,                  kTechId.Armor2,             kTechId.None, kTechId.AllMarines)  
        techTree:AddBuyNode(kTechId.HeavyArmor,               kTechId.Armor2,             kTechId.None, kTechId.AllMarines)  
        
        techTree:AddBuyNode(kTechId.MedPack,                  kTechId.None,               kTechId.None, kTechId.AllMarines)  
        techTree:AddBuyNode(kTechId.CatPack,                  kTechId.None,               kTechId.None, kTechId.AllMarines)  
        techTree:AddBuyNode(kTechId.Scan,                     kTechId.None,               kTechId.None, kTechId.AllMarines)  
        
    end
    
    techTree:AddMenu(kTechId.WeaponsMenu)
    
        //Add this incase other mods want to modify tech tree
	if self.ModifyTechTree then
		self:ModifyTechTree(techTree)
	end
    
    techTree:SetComplete()

end

function MarineTeam:AwardResources(resAward, pointOwner)
     self:AddTeamResources(resAward)
end

function MarineTeam:GetWaveSpawnTime()
    return kMarineCombatMinSpawnInterval + (kMarineCombatSpawnIntervalPerPlayer * self:GetNumPlayersInQueue())
end

function MarineTeam:GetRespawnsPerWave()
    return kMarineRespawnsPerWave
end

local function SpawnArmory(self, techPoint)

    local techPointOrigin = techPoint:GetOrigin() + Vector(0, 2, 0)
    local spawnPoint = nil
    
    for p = 1, #Server.armorySpawnPoints do

		if not self.usedArmorySpawns[p] then 
			local predefinedSpawnPoint = Server.armorySpawnPoints[p]
			if (predefinedSpawnPoint - techPointOrigin):GetLength() <= kArmoryMaxSpawnDistance then
				spawnPoint = predefinedSpawnPoint
				self.usedArmorySpawns[p] = true
				break
			end
		end
        
    end

    if not spawnPoint then
    
        local origin = GetRandomBuildPosition( kTechId.Armory, techPointOrigin, kArmoryMaxSpawnDistance )
        if origin then
            spawnPoint = origin - Vector(0, 0.1, 0)
        end
        
    end
    
    if spawnPoint then
    
        local armory = CreateEntity(Armory.kMapName, spawnPoint, self:GetTeamNumber())
        
        SetRandomOrientation(armory)
        armory:SetConstructionComplete()
        
    end
    
end

function MarineTeam:SpawnInitialStructures(techPoint)

    local tower, commandStation = PlayingTeam.SpawnInitialStructures(self, techPoint)
    
    if GetServerGameMode() == kGameMode.Combat then
        SpawnArmory(self, techPoint)
    end
    
    if Shared.GetCheatsEnabled() and MarineTeam.gSandboxMode then

        // Pretty dumb way of spawning two things..heh
        local origin = techPoint:GetOrigin()
        local right = techPoint:GetCoords().xAxis
        local forward = techPoint:GetCoords().zAxis
        CreateEntity( AdvancedArmory.kMapName, origin+right*3.5+forward*1.5, kMarineTeamType)
        CreateEntity( PrototypeLab.kMapName, origin+right*3.5-forward*1.5, kMarineTeamType)

    end
    
    return tower, commandStation
    
end

function MarineTeam:GetSpectatorMapName()
    return MarineSpectator.kMapName
end

function MarineTeam:OnBought(techId)

    local listeners = self.eventListeners['OnBought']

    if listeners then

        for _, listener in ipairs(listeners) do
            listener(techId)
        end

    end

end
