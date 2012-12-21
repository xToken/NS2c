// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ConsoleCommands_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// NS2 Gamerules specific console commands. 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScenarioHandler_Commands.lua")

local function JoinTeam(player, teamIndex)

    if player ~= nil and player:GetTeamNumber() == kTeamReadyRoom then
    
        // Auto team balance checks.
        local allowed = GetGamerules():GetCanJoinTeamNumber(teamIndex)
                
        if allowed or Shared.GetCheatsEnabled() then
            return GetGamerules():JoinTeam(player, teamIndex)
        else
            Server.SendNetworkMessage(player, "JoinError", BuildJoinErrorMessage(), false)
            return false
        end
        
    end
    
    return false
    
end

local function JoinTeamOne(player)
    return JoinTeam(player, kTeam1Index)
end

local function JoinTeamTwo(player)
    return JoinTeam(player, kTeam2Index)
end

local function ReadyRoom(player)
    player:SetCameraDistance(0)
    return GetGamerules():JoinTeam(player, kTeamReadyRoom)
end

local function Spectate(player)
    return GetGamerules():JoinTeam(player, kSpectatorIndex)
end

local function OnCommandJoinTeamOne(client)
    local player = client:GetControllingPlayer()
    JoinTeamOne(player)
end

local function OnCommandJoinTeamTwo(client)
    local player = client:GetControllingPlayer()
    JoinTeamTwo(player)
end

local function OnCommandReadyRoom(client)
    local player = client:GetControllingPlayer()
    ReadyRoom(player)
end

local function OnCommandSpectate(client)
    local player = client:GetControllingPlayer()
    Spectate(player)
end

local function OnCommandFilm(client)

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() or Shared.GetDevMode() or (player:GetTeamNumber() == kTeamReadyRoom) then

        Shared.Message("Film mode enabled. Hold crouch for dolly, movement modifier for speed or attack to orbit then press movement keys.")

        local success, newPlayer = Spectate(player)
        
        // Transform class into FilmSpectator
        newPlayer:Replace(FilmSpectator.kMapName, newPlayer:GetTeamNumber(), false)
        
    end
    
end

/**
 * Forces the game to end for testing purposes
 */
local function OnCommandEndGame(client)

    local player = client:GetControllingPlayer()

    if Shared.GetCheatsEnabled() and GetGamerules():GetGameStarted() then
        GetGamerules():EndGame(player:GetTeam())
    end
    
end

local function OnCommandTeamResources(client)

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() then
        player:GetTeam():AddTeamResources(100)
    end
    
end

local function OnCommandResources(client)

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() then
        player:AddResources(100)
    end
    
end

local function OnCommandAutobuild(client)

    if Shared.GetCheatsEnabled() then
        GetGamerules():SetAutobuild(not GetGamerules():GetAutobuild())
        Print("Autobuild now %s", ToString(GetGamerules():GetAutobuild()))
        
        // Now build any existing structures that aren't built 
        for index, constructable in ipairs(GetEntitiesWithMixin("Construct")) do
        
            if not constructable:GetIsBuilt() then
                constructable:SetConstructionComplete()
            end
            
        end
        
    end
    
end

local function OnCommandEnergy(client)

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() then
    
        // Give energy to all structures on our team.
        for index, ent in ipairs(GetEntitiesWithMixinForTeam("Energy", player:GetTeamNumber())) do
            ent:SetEnergy(ent:GetMaxEnergy())
        end
        
    end
    
end

local function OnCommandTakeDamage(client, amount, optionalEntId)

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() then
    
        local damage = tonumber(amount)
        if damage == nil then
            damage = 20 + math.random() * 10
        end
        
        local damageEntity = nil
        optionalEntId = optionalEntId and tonumber(optionalEntId)
        if optionalEntId then
            damageEntity = Shared.GetEntity(optionalEntId)
        else
        
            damageEntity = player
            if player:isa("Commander") then
            
                // Find command structure we're in and do damage to that instead.
                local commandStructures = Shared.GetEntitiesWithClassname("CommandStructure")
                for index, commandStructure in ientitylist(commandStructures) do
                
                    local comm = commandStructure:GetCommander()
                    if comm and comm:GetId() == player:GetId() then
                    
                        damageEntity = commandStructure
                        break
                        
                    end
                    
                end
                
            end
            
        end
        
        if not damageEntity:GetCanTakeDamage() then
            damage = 0
        end
        
        Print("Doing %.2f damage to %s", damage, damageEntity:GetClassName())
        damageEntity:DeductHealth(damage, player, player)
        
    end
    
end

local function OnCommandHeal(client, amount)

    if Shared.GetCheatsEnabled() then
    
        amount = amount and tonumber(amount) or 10
        local player = client:GetControllingPlayer()
        player:AddHealth(amount)
        
    end
    
end

local function OnCommandGiveAmmo(client)

    if client ~= nil and Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        local weapon = player:GetActiveWeapon()

        if weapon ~= nil and weapon:isa("ClipWeapon") then
            weapon:GiveAmmo(1)
        end
    
    end
    
end

local function OnCommandParasite(client)

    if client ~= nil and Shared.GetCheatsEnabled() then

        local player = client:GetControllingPlayer()
        
        if HasMixin(player, "ParasiteAble") then
            player:SetParasited()
        end
        
    end
    
end


local function OnCommandEnts(client, className)

    // Allow it to be run on dedicated server
    if client == nil or Shared.GetCheatsEnabled() then
    
        local entityCount = Shared.GetEntitiesWithClassname("Entity"):GetSize()
        
        local weaponCount = Shared.GetEntitiesWithClassname("Weapon"):GetSize()
        local playerCount = Shared.GetEntitiesWithClassname("Player"):GetSize()
        local structureCount = #GetEntitiesWithMixin("Construct")
        local team1 = GetGamerules():GetTeam1()
        local team2 = GetGamerules():GetTeam2()
        local playersOnPlayingTeams = team1:GetNumPlayers() + team2:GetNumPlayers()
        local commandStationsOnTeams = team1:GetNumCommandStructures() + team2:GetNumCommandStructures()
        local blipCount = Shared.GetEntitiesWithClassname("Blip"):GetSize()
        
        if className then
            local numClassEnts = Shared.GetEntitiesWithClassname(className):GetSize()
            Shared.Message(Pluralize(numClassEnts, className))
        else
        
            local formatString = "%d entities (%s, %d playing, %s, %s, %s, %s, %d command structures on teams)."
            Shared.Message( string.format(formatString, 
                            entityCount, 
                            Pluralize(playerCount, "player"), playersOnPlayingTeams, 
                            Pluralize(weaponCount, "weapon"), 
                            Pluralize(structureCount, "structure"), 
                            Pluralize(blipCount, "blip"), 
                            commandStationsOnTeams))
        end
    end
    
end

local function OnCommandServerEntities(client, entityType)

    if client == nil or Shared.GetCheatsEnabled() then
        DumpEntityCounts(entityType)
    end
    
end

local function OnCommandEntityInfo(client, entityId)

    if client == nil or Shared.GetCheatsEnabled() then
    
        local ent = Shared.GetEntity(tonumber(entityId))
        if not ent then
        
            Shared.Message("No entity matching Id: " .. entityId)
            return
            
        end
        
        local entInfo = GetEntityInfo(ent)
        Shared.Message(entInfo)
        
    end
    
end

local function OnCommandServerEntInfo(client, entityId)

    if client == nil or Shared.GetCheatsEnabled() then
    end
    
end

// Switch player from one team to the other, while staying in the same place
local function OnCommandSwitch(client)

    local player = client:GetControllingPlayer()
    local teamNumber = player:GetTeamNumber()
    if(Shared.GetCheatsEnabled() and (teamNumber == kTeam1Index or teamNumber == kTeam2Index)) and not player:GetIsCommander() then
    
        // Remember position and team for calling player for debugging
        local playerOrigin = player:GetOrigin()
        local playerViewAngles = player:GetViewAngles()
        
        local newTeamNumber = kTeam1Index
        if(teamNumber == kTeam1Index) then
            newTeamNumber = kTeam2Index
        end
        
        local success, newPlayer = GetGamerules():JoinTeam(player, kTeamReadyRoom)
        success, newPlayer = GetGamerules():JoinTeam(newPlayer, newTeamNumber)
        
        newPlayer:SetOrigin(playerOrigin)
        newPlayer:SetViewAngles(playerViewAngles)
        
    end
    
end

local function OnCommandDamage(client,multiplier)

    if(Shared.GetCheatsEnabled()) then
        local m = multiplier and tonumber(multiplier) or 1
        GetGamerules():SetDamageMultiplier(m)
        Shared.Message("Damage multipler set to " .. m)
    end
    
end

local function OnCommandHighDamage(client)

    if Shared.GetCheatsEnabled() and GetGamerules():GetDamageMultiplier() < 10 then
    
        GetGamerules():SetDamageMultiplier(10)
        Print("highdamage on (10x damage)")
        
    // Toggle off
    elseif not Shared.GetCheatsEnabled() or GetGamerules():GetDamageMultiplier() > 1 then
    
        GetGamerules():SetDamageMultiplier(1)
        Print("highdamage off")
        
    end
    
end

local function OnCommandGive(client, itemName)

    local player = client:GetControllingPlayer()
    if itemName == "hmg" then itemName = "heavymachinegun" end // lol
    if(Shared.GetCheatsEnabled() and itemName ~= nil) then
        player:GiveItem(itemName)
        //player:SetActiveWeapon(itemName)
    end
    
end

local function OnCommandSpawn(client, itemName, teamnum)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled() and itemName ~= nil) then
    
        // trace along players zAxis and spawn the item there
        local startPoint = player:GetEyePos()
        local endPoint = startPoint + player:GetViewCoords().zAxis * 100
        
        local trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())
        
        if not teamnum then
            teamnum = player:GetTeamNumber()
        else
            teamnum = tonumber(teamnum)
        end

        local newItem = CreateEntity(itemName, trace.endPoint, teamnum)
        if newItem:isa("Projectile") then
            newItem:SetVelocity(Vector(0, 1, 0))
        end
        
        
    end
    
end

local function OnCommandGiveUpgrade(client, techIdString)

    if Shared.GetCheatsEnabled() then
    
        local techId = techIdStringToTechId(techIdString)
        
        if techId ~= nil then
        
            local player = client:GetControllingPlayer()
        
            if not player:GetTechTree():GiveUpgrade(techId) then
            
                if not player:GiveUpgrade(techId) then
                    Print("Error: GiveUpgrade(%s) not researched and not an upgraded", EnumToString(kTechId, techId))
                end
                
            end
            
        else
            Shared.Message("Error: " .. techIdString .. " does not match any Tech Id")
        end
        
    end
    
end

local function OnCommandLogout(client)

    local player = client:GetControllingPlayer()
    if(player:GetIsCommander()) then
    
        player:Logout()
    
    end

end

local function OnCommandGotoIdleWorker(client)

    local player = client:GetControllingPlayer()
    if player:GetIsCommander() then
        player:GotoIdleWorker()
    end
    
end

local function OnCommandGotoPlayerAlert(client)

    local player = client:GetControllingPlayer()
    if player:GetIsCommander() then
        player:GotoPlayerAlert()
    end
    
end

local function OnCommandSelectAllPlayers(client)

    local player = client:GetControllingPlayer()
    if player.SelectAllPlayers then
        player:SelectAllPlayers()
    end
    
end

local function OnCommandSetFOV(client, fovValue)

    local player = client:GetControllingPlayer()
    if Shared.GetDevMode() then
        player:SetFov(tonumber(fovValue))
    end
    
end

local function OnCommandChangeClass(className, teamNumber, extraValues)

    return function(client)
    
        local player = client:GetControllingPlayer()
        if Shared.GetCheatsEnabled() and player:GetTeamNumber() == teamNumber then
            player:Replace(className, player:GetTeamNumber(), false, nil, extraValues)
        end
        
    end
    
end

local function OnCommandCommand(client)

    local player = client:GetControllingPlayer()
    if Shared.GetCheatsEnabled() then
    
        // Find hive/command station on our team and use it
        local ents = GetEntitiesForTeam("CommandStructure", player:GetTeamNumber())
        if #ents > 0 then
        
            player:SetOrigin(ents[1]:GetOrigin() + Vector(0, 1, 0))
            player:UseTarget(ents[1], nil, 0)
            ents[1]:UpdateCommanderLogin(true)
            
        end
        
    end
    
end

local function OnCommandCatPack(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled() and player:isa("Marine")) then
        player:ApplyCatPack()
    end
end

local function OnCommandAllTech(client)

    local player = client:GetControllingPlayer()
    if(Shared.GetCheatsEnabled()) then
    
        local newAllTechState = not GetGamerules():GetAllTech()
        GetGamerules():SetAllTech(newAllTechState)
        Print("Setting alltech cheat %s", ConditionalValue(newAllTechState, "on", "off"))
        
    end
    
end

local function OnCommandLocation(client)

    local player = client:GetControllingPlayer()
    local locationName = player:GetLocationName()
    if locationName ~= "" then
        Print("You are in \"%s\".", locationName)
    else
        Print("You are nowhere.")
    end
    
end

local function OnCommandCloseMenu(client)
    local player = client:GetControllingPlayer()
    player:CloseMenu()
end

// Weld all doors shut immediately
local function OnCommandWeldDoors(client)

    if Shared.GetCheatsEnabled() then
    
        for index, door in ientitylist(Shared.GetEntitiesWithClassname("Door")) do 
        
            if door:GetIsAlive() then
                door:SetState(Door.kState.Welded)
            end
            
        end
        
    end
    
end

local function OnCommandDisrupt(client)

    local player = client:GetControllingPlayer()
    
    if Shared.GetCheatsEnabled() and player then
        player:SetDisruptDuration(5)
    end
    
end

local function OnCommandPush(client)

    if Shared.GetCheatsEnabled() then
        local player = client:GetControllingPlayer()
        if player then
            player:AddPushImpulse(Vector(50,10,0))
        end
    end
    
end

local function OnCommandPrimal(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and player.SetPrimalScream then
            player:SetPrimalScream(10)
        end
        
    end
    
end

local function OnCommandOrderSelf(client)

    if Shared.GetCheatsEnabled() then
        GetGamerules():SetOrderSelf(not GetGamerules():GetOrderSelf())
        Print("Order self is now %s.", ToString(GetGamerules():GetOrderSelf()))
    end
    
end

local function techIdStringToTechId(techIdString)

    local techId = tonumber(techIdString)
    
    if type(techId) ~= "number" then
        techId = StringToEnum(kTechId, techIdString)
    end        
    
    return techId
    
end

// Create structure, weapon, etc. near player
local function OnCommandCreate(client, techIdString, number)

    if Shared.GetCheatsEnabled() then
    
        local techId = techIdStringToTechId(techIdString)
        local attachClass = LookupTechData(techId, kStructureAttachClass)
        
        number = number or 1
        
        if techId ~= nil then
        
            for i = 1, number do
            
                local success = false
                // Persistence is the path to victory.
                for index = 1, 2000 do
                
                    local player = client:GetControllingPlayer()
                    local teamNumber = player:GetTeamNumber()
                    if techId == kTechId.Scan then
                        teamNumber = GetEnemyTeamNumber(teamNumber)
                    end
                    local position = nil
                    
                    if attachClass then
                    
                        local attachEntity = GetNearestFreeAttachEntity(techId, player:GetOrigin(), 1000)
                        if attachEntity then
                            position = attachEntity:GetOrigin()
                        end
                        
                    else
                    
                        /*local modelName = LookupTechData(techId, kTechDataModel)
                        local modelIndex = Shared.GetModelIndex(modelName)
                        local model = Shared.GetModel(modelIndex)
                        local minExtents, maxExtents = model:GetExtents()
                        Print(modelName .. " bounding box min: " .. ToString(minExtents) .. " max: " .. ToString(maxExtents))
                        local extents = maxExtents
                        DebugBox(player:GetOrigin(), player:GetOrigin(), maxExtents - minExtents, 1000, 1, 0, 0, 1)
                        DebugBox(player:GetOrigin(), player:GetOrigin(), minExtents, 1000, 0, 1, 0, 1)
                        DebugBox(player:GetOrigin(), player:GetOrigin(), maxExtents, 1000, 0, 0, 1, 1)*/
                        //position = GetRandomSpawnForCapsule(extents.y, extents.x, player:GetOrigin() + Vector(0, 0.5, 0), 2, 10)
                        //position = position - Vector(0, extents.y, 0)
                        
                        position = CalculateRandomSpawn(nil, player:GetOrigin() + Vector(0, 0.5, 0), techId, true, 2, 10, 3)
                        
                    end
                    
                    if position then
                    
                        success = true
                        CreateEntityForTeam(techId, position, teamNumber, player)
                        break
                        
                    end
                    
                end
                
                if not success then
                    Print("Create %s: Couldn't find space for entity", EnumToString(kTechId, techId))
                end
                
            end
            
        else
            Print("Usage: create (techId name)")
        end
        
    end
    
end

local function OnCommandRandomDebug(s)

    if Shared.GetCheatsEnabled() then
    
        local newState = not gRandomDebugEnabled
        Print("OnCommandRandomDebug() now %s", ToString(newState))
        gRandomDebugEnabled = newState

    end
    
end

local function OnCommandDistressBeacon(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()  
        local ent = GetNearest(player:GetOrigin(), "Observatory", player:GetTeamNumber())
        if ent and ent.TriggerDistressBeacon then
        
            ent:TriggerDistressBeacon()
            
        end
        
    end

end

local function OnCommandSetGameEffect(client, gameEffectString, trueFalseString)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()          
        local gameEffectBitMask = kGameEffect[gameEffectString]
        if gameEffectBitMask ~= nil then
        
            Print("OnCommandSetGameEffect(%s) => %s", gameEffectString, ToString(gameEffectBitMask))
            
            local state = true
            if trueFalseString and ((trueFalseString == "false") or (trueFalseString == "0")) then
                state = false
            end
            
            player:SetGameEffectMask(gameEffectBitMask, state)
            
        else
            Print("Couldn't find bitmask in %s for %s", ToString(kGameEffect), gameEffectString)
        end        
        
    end
    
end

local function OnCommandChangeGCSettingServer(client, settingName, newValue)

    if Shared.GetCheatsEnabled() then
    
        if settingName == "setpause" or settingName == "setstepmul" then
            Shared.Message("Changing server GC setting " .. settingName .. " to " .. tostring(newValue))
            collectgarbage(settingName, newValue)
        else
            Shared.Message(settingName .. " is not a valid setting")
        end
        
    end
    
end

local function OnCommandEject(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()          
        if player and player.Eject then
        
            player:Eject()        
            
        end
        
    end
    
end

/**
 * Show debug info for the closest entity that has a self.targetSelector
 */
local function OnCommandTarget(client, cmd)

    if client ~= nil and (Shared.GetCheatsEnabled() or Shared.GetDevMode()) then
        local player = client:GetControllingPlayer()
        local origin = player:GetOrigin()
        local structs = GetEntitiesWithinRange("ScriptActor", origin, 5)
        local sel, selRange = nil,nil
        for _, struct in ipairs(structs) do
            if struct.targetSelector or HasMixin(struct, "AiAttacks") then
                local r = (origin - struct:GetOrigin()):GetLength()
                if not sel or r < selRange then
                    sel,selRange = struct,r
                end
            end
        end
        Log("debug %s", sel)
        if sel then   
            if HasMixin(sel, "AiAttacks") then
                sel:AiAttacksDebug(cmd)
            else                 
                sel.targetSelector:Debug(cmd)
            end
        end
    end
end

local function OnCommandHasTech(client, cmd)

    if client ~= nil and Shared.GetCheatsEnabled() then
    
        if type(cmd) == "string" then

            local techId = StringToEnum(kTechId, cmd)
            if techId == nil then
                Print("Couldn't find tech id \"%s\" (should be something like ShotgunTech)", ToString(cmd))
                return
            end
        
            local player = client:GetControllingPlayer()
            if player then
            
                local techTree = player:GetTechTree()                
                if techTree then
                    local hasText = ConditionalValue(techTree:GetHasTech(techId), "has", "doesn't have")
                    Print("Your team %s \"%s\" tech.", hasText, cmd)
                end
                
            end
            
        else
            Print("Pass case-sensitive upgrade name.")
        end
            
    end
    
end

local function OnCommandEggSpawnTimes(client, cmd)

    if Shared.GetCheatsEnabled() then
    
        Print("Printing out egg spawn times:")

        for playerIndex = 1, 16 do
        
            local s = string.format("%d players: ", playerIndex)
            
            for eggIndex = 1, kAlienEggsPerHive do        
                s = s .. string.format("%d eggs = %.2f  ", eggIndex, CalcEggSpawnTime(playerIndex, eggIndex))
            end
            
            Print(s)
            
        end
        
    end
    
end

local function OnCommandTestOrder(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()

        if player and HasMixin(player, "Orders") then

            local eyePos = player:GetEyePos()
            local endPos = eyePos + player:GetViewAngles():GetCoords().zAxis * 50
            local trace = Shared.TraceRay(eyePos, endPos, CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())
            local target = trace.endPoint

            player:GiveOrder(kTechId.Move, 0, target)
        
        end
        
    end    

end

// call for the nearest AI unit to come to your location. Useful when testing pathing/animation
local function OnCommandGoThere(client)
    
    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        // find where player is looking
        local eyePos = player:GetEyePos()
        local endPos = eyePos + player:GetViewAngles():GetCoords().zAxis * 50
        local trace = Shared.TraceRay(eyePos, endPos, CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())
        local target = trace.endPoint
        
        local ents = Shared.GetEntitiesWithClassname("ScriptActor")
        
        local selected = nil
        local selectedRange = 0
        
        for i,entity in ientitylist(ents) do
        
            if entity:isa("Whip") or entity:isa("Drifter") or entity:isa("MAC") or entity:isa("ARC") then
            
                local r = (entity:GetOrigin() - target):GetLength()           
                if not selected or r < selectedRange then
                
                    selected = entity 
                    selectedRange = r
                    
                end
                
            end
            
        end
        
        if selected then
        
            Shared.Message(string.format("Giving order to %s-%s", selected:GetClassName(), selected:GetId()))
            selected:GiveOrder(kTechId.Move, player:GetId(), target)
            // Override the target Id to be invalidId so the AI unit doesn't follow the player.
            selected:GetCurrentOrder():Initialize(kTechId.Move, Entity.invalidId, target, 0)
            
        else
            Shared.Message("No AI entitity available")
        end
        
    end
    
end

local function OnCommandRupture(client, classname)

    if Shared.GetCheatsEnabled() then
        
            local player = client:GetControllingPlayer()
            if player and player:isa("Marine") then            
                player:SetRuptured()            
            end
        
    end
    
end

local function OnCommandCommanderPing(client, classname)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and player:GetTeam() then
        
            // trace along crosshair
            local startPoint = player:GetEyePos()
            local endPoint = startPoint + player:GetViewCoords().zAxis * 100
            
            local trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())
            
            player:GetTeam():SetCommanderPing(trace.endPoint)
            
        end
        
    end
    
end

local function OnCommandDeployARCs()

    if Shared.GetCheatsEnabled() then
    
        for index, arc in ientitylist(Shared.GetEntitiesWithClassname("ARC")) do        
            arc.deployMode = ARC.kDeployMode.Deploying        
        end
        
    end
    
end

local function OnCommandUndeployARCs()

    if Shared.GetCheatsEnabled() then
    
        for index, arc in ientitylist(Shared.GetEntitiesWithClassname("ARC")) do        
            arc.deployMode = ARC.kDeployMode.Undeploying        
        end
        
    end
    
end

local function OnCommandDebugCommander(client, vm)

    if Shared.GetCheatsEnabled() then    
        BuildUtility_SetDebug(vm)        
    end
    
end

local function OnCommandRespawnTeam(client, teamNum)

    if Shared.GetCheatsEnabled() then
    
        teamNum = tonumber(teamNum)
        if teamNum == 1 then
            GetGamerules():GetTeam1():ReplaceRespawnAllPlayers()
        elseif teamNum == 2 then
            GetGamerules():GetTeam2():ReplaceRespawnAllPlayers()
        end
        
    end
    
end

local function OnCommandMakeSpecialEdition(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and player:isa("Marine") then        
            player:SetModel(Marine.kSpecialEditionModelName, Marine.kMarineAnimationGraph)            
        end
        
    end    

end

local function OnCommandGreenEdition(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and player:isa("Marine") then        
            player:SetModel(Marine.kModelName, Marine.kMarineAnimationGraph)            
        end
        
    end    

end

local function OnCommandBlackEdition(client)

    if Shared.GetCheatsEnabled() then
    
        local player = client:GetControllingPlayer()
        if player and player:isa("Marine") then        
            player:SetModel(Marine.kBlackArmorModelName, Marine.kMarineAnimationGraph)            
        end
        
    end    

end

// GC commands
Event.Hook("Console_changegcsettingserver", OnCommandChangeGCSettingServer)

// NS2 game mode console commands
Event.Hook("Console_jointeamone", OnCommandJoinTeamOne)
Event.Hook("Console_jointeamtwo", OnCommandJoinTeamTwo)
Event.Hook("Console_readyroom", OnCommandReadyRoom)
Event.Hook("Console_spectate", OnCommandSpectate)
Event.Hook("Console_film", OnCommandFilm)

// Shortcuts because we type them so much
Event.Hook("Console_j1", OnCommandJoinTeamOne)
Event.Hook("Console_j2", OnCommandJoinTeamTwo)
Event.Hook("Console_rr", OnCommandReadyRoom)

Event.Hook("Console_endgame", OnCommandEndGame)
Event.Hook("Console_logout", OnCommandLogout)
Event.Hook("Console_gotoidleworker", OnCommandGotoIdleWorker)
Event.Hook("Console_gotoplayeralert", OnCommandGotoPlayerAlert)
Event.Hook("Console_selectallplayers", OnCommandSelectAllPlayers)

// Cheats
Event.Hook("Console_tres", OnCommandTeamResources)
Event.Hook("Console_pres", OnCommandResources)
Event.Hook("Console_autobuild", OnCommandAutobuild)
Event.Hook("Console_takedamage", OnCommandTakeDamage)
Event.Hook("Console_heal", OnCommandHeal)
Event.Hook("Console_giveammo", OnCommandGiveAmmo)
Event.Hook("Console_parasite", OnCommandParasite)
Event.Hook("Console_respawn_team", OnCommandRespawnTeam)

Event.Hook("Console_ents", OnCommandEnts)
Event.Hook("Console_sents", OnCommandServerEntities)
Event.Hook("Console_entinfo", OnCommandEntityInfo)

Event.Hook("Console_switch", OnCommandSwitch)
Event.Hook("Console_damage", OnCommandDamage)
Event.Hook("Console_highdamage", OnCommandHighDamage)
Event.Hook("Console_give", OnCommandGive)
Event.Hook("Console_spawn", OnCommandSpawn)
Event.Hook("Console_giveupgrade", OnCommandGiveUpgrade)
Event.Hook("Console_setfov", OnCommandSetFOV)

// For testing lifeforms
Event.Hook("Console_skulk", OnCommandChangeClass("skulk", kTeam2Index))
Event.Hook("Console_gorge", OnCommandChangeClass("gorge", kTeam2Index))
Event.Hook("Console_lerk", OnCommandChangeClass("lerk", kTeam2Index))
Event.Hook("Console_fade", OnCommandChangeClass("fade", kTeam2Index))
Event.Hook("Console_onos", OnCommandChangeClass("onos", kTeam2Index))
Event.Hook("Console_marine", OnCommandChangeClass("marine", kTeam1Index))
Event.Hook("Console_heavyarmor", OnCommandChangeClass("heavyarmormarine", kTeam1Index))
Event.Hook("Console_jetpack", OnCommandChangeClass("jetpackmarine", kTeam1Index))

Event.Hook("Console_command", OnCommandCommand)
Event.Hook("Console_catpack", OnCommandCatPack)
Event.Hook("Console_alltech", OnCommandAllTech)
Event.Hook("Console_location", OnCommandLocation)
Event.Hook("Console_disrupt", OnCommandDisrupt)
Event.Hook("Console_push", OnCommandPush)
Event.Hook("Console_deployarcs", OnCommandDeployARCs)
Event.Hook("Console_undeployarcs", OnCommandUndeployARCs)

Event.Hook("Console_closemenu", OnCommandCloseMenu)
Event.Hook("Console_welddoors", OnCommandWeldDoors)
Event.Hook("Console_orderself", OnCommandOrderSelf)
Event.Hook("Console_primal",OnCommandPrimal)

Event.Hook("Console_create",OnCommandCreate)
Event.Hook("Console_random_debug", OnCommandRandomDebug)
Event.Hook("Console_bacon", OnCommandDistressBeacon)
Event.Hook("Console_setgameeffect", OnCommandSetGameEffect)

Event.Hook("Console_eject", OnCommandEject)
Event.Hook("Console_target", OnCommandTarget)
Event.Hook("Console_hastech", OnCommandHasTech)
Event.Hook("Console_eggspawntimes", OnCommandEggSpawnTimes)
Event.Hook("Console_gothere", OnCommandGoThere)

Event.Hook("Console_rupture", OnCommandRupture)
Event.Hook("Console_makespecial", OnCommandMakeSpecialEdition)
Event.Hook("Console_makegreen", OnCommandGreenEdition)
Event.Hook("Console_makeblack", OnCommandBlackEdition)

Event.Hook("Console_debugcommander", OnCommandDebugCommander)