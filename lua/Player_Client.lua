--[[
// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Player_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
]]

//NS2c
//Made most vars local, removal most screen effects and tweaked a couple GUI functions.

Script.Load("lua/Chat.lua")
Script.Load("lua/HudTooltips.lua")
Script.Load("lua/tweener/Tweener.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/GUICommunicationStatusIcons.lua")

gPlayingDeadMontage = nil
gHUDMapEnabled = true

local kDefaultPingSound = PrecacheAsset("sound/NS2.fev/common/ping")
local kMarinePingSound = PrecacheAsset("sound/NS2.fev/marine/commander/ping")
local kAlienPingSound = PrecacheAsset("sound/NS2.fev/alien/commander/ping")

local kDefaultFirstPersonEffectName = PrecacheAsset("cinematics/marine/hit_1p.cinematic")
local kFirstPersonDeathEffect = PrecacheAsset("cinematics/death_1p.cinematic")
local kDeadSound = PrecacheAsset("sound/NS2.fev/common/dead")

Client.PrecacheLocalSound(kDefaultPingSound)
Client.PrecacheLocalSound(kMarinePingSound)
Client.PrecacheLocalSound(kAlienPingSound)

local kHealthCircleFadeOutTime = 1
local kDamageIndicatorDrawTime = 1
local kShowGiveDamageTime = 1
local kRangeFinderDistance = 20
local kCtDownLength = kCountDownLength
local kLowHealthWarning = 0.35
local kLowHealthPulseSpeed = 10

// These screen effects are only used on the local player so create them statically.
local screenEffects = { }
screenEffects.darkVision = Client.CreateScreenEffect("shaders/DarkVision.screenfx")
screenEffects.darkVision:SetActive(false)
screenEffects.phase = Client.CreateScreenEffect("shaders/Phase.screenfx")
screenEffects.phase:SetActive(false)
screenEffects.cloaked = Client.CreateScreenEffect("shaders/Cloaked.screenfx")
screenEffects.cloaked:SetActive(false)
screenEffects.disorient = Client.CreateScreenEffect("shaders/Disorient.screenfx")
screenEffects.disorient:SetActive(false)
screenEffects.spectatorTint = Client.CreateScreenEffect("shaders/SpectatorTint.screenfx")
screenEffects.spectatorTint:SetActive(false)
screenEffects.lowHealth = Client.CreateScreenEffect("shaders/LowHealth.screenfx")
screenEffects.lowHealth:SetActive(false)
screenEffects.blur = Client.CreateScreenEffect("shaders/Blur.screenfx")
screenEffects.blur:SetActive(false)

Player.screenEffects = screenEffects

function Player:GetShowUnitStatusForOverride(forEntity)
    return not GetAreEnemies(self, forEntity) or (forEntity:GetOrigin() - self:GetOrigin()):GetLength() < 8
end

function Player:GetScreenEffects()
    return screenEffects
end

function PlayerUI_GetWorldMessages()

    local messageTable = {}
    local player = Client.GetLocalPlayer()
    
    if player then
            
        for _, worldMessage in ipairs(Client.GetWorldMessages()) do
            
            local tableEntry = {}
            
            tableEntry.position = worldMessage.position
            tableEntry.messageType = worldMessage.messageType
            tableEntry.previousNumber = worldMessage.previousNumber
            tableEntry.text = worldMessage.message
            tableEntry.animationFraction = worldMessage.animationFraction
            tableEntry.distance = (worldMessage.position - player:GetOrigin()):GetLength()
            tableEntry.minimumAnimationFraction = worldMessage.minimumAnimationFraction
            tableEntry.entityId = worldMessage.entityId
            
            local direction = GetNormalizedVector(worldMessage.position - player:GetViewCoords().origin)
            tableEntry.inFront = player:GetViewCoords().zAxis:DotProduct(direction) > 0
            
            table.insert(messageTable, tableEntry)
            
        end
    
    end
    
    return messageTable

end

function PlayerUI_GetIsDead()

    local player = Client.GetLocalPlayer()
    local isDead = false
    
    if player then
    
        if HasMixin(player, "Live") then
            isDead = not player:GetIsAlive()
        end
        
    end
    
    return isDead
    
end

local timeWaveSpawnEnds = 0
local function OnSetTimeWaveSpawnEnds(message)
    timeWaveSpawnEnds = message.time
end

Client.HookNetworkMessage("SetTimeWaveSpawnEnds", OnSetTimeWaveSpawnEnds)

function PlayerUI_GetWaveSpawnTime()

    if timeWaveSpawnEnds > 0 then
        return timeWaveSpawnEnds - Shared.GetTime()
    end
    
    return 0
    
end

function PlayerUI_GetIsSpecating()

    local player = Client.GetLocalPlayer()
    return player ~= nil and (player:isa("Spectator") or player:isa("FilmSpectator"))
    
end

function PlayerUI_GetHUDMapEnabled()
    return gHUDMapEnabled
end

function PlayerUI_GetCurrentOrderType()

    local player = Client.GetLocalPlayer()
    
    if player and HasMixin(player, "Orders")  and player:GetCurrentOrder() then
        return player:GetCurrentOrder():GetType()
    end
    
    return kTechId.None
    
end

function GetRelevantOrdersForPlayer(player)

    local orders = {}
    
    if player:isa("Commander") then
    
        for _, selectable in ipairs(player:GetSelection()) do
        
            local order = HasMixin(selectable, "Orders") and selectable:GetCurrentOrder()
            if order then
                table.insert(orders, order)
            end
        
        end

    else
    
        local order = HasMixin(player, "Orders") and player:GetCurrentOrder()
        if order then
            table.insert(orders, player:GetCurrentOrder())
        end
        
    end

    return orders

end

function PlayerUI_GetOrderInfo()

    local orderInfo = { }
    
    -- Hard-coded for testing
    local player = Client.GetLocalPlayer()
    if player then
    
        for index, order in ipairs(GetRelevantOrdersForPlayer(player)) do
        
            //sigh this is really dumb
            if order.orderSource == nil then
                order.orderSource = player:GetOrigin()
            end
            table.insert(orderInfo, order.orderType)
            table.insert(orderInfo, order.orderParam)
            table.insert(orderInfo, order.orderLocation)
            table.insert(orderInfo, order.orderOrientation)
            table.insert(orderInfo, order.orderSource)
            
        end
        
    end
    
    return orderInfo
    
end

local gLastOrderId = 0
local gLastOrderTime = 0
local kNewOrderDuration = 3
function PlayerUI_GetHasNewOrder()

    local hasNewOrder = false
    local player = Client.GetLocalPlayer()
    
    if player then

        local order = player:GetCurrentOrder()
        if order and order:GetId() ~= gLastOrderId then

            gLastOrderId = order:GetId()
            gLastOrderTime = Client.GetTime()
        
        end
        
        hasNewOrder = gLastOrderTime + kNewOrderDuration > Client.GetTime()
        
    end

    return hasNewOrder

end

local function GetMostRelevantPheromone(toOrigin)

    local pheromones = GetEntitiesWithinRange("Pheromone", toOrigin, 100)
    local bestPheromone
    local bestDistSq = math.huge
    for p = 1, #pheromones do
    
        local currentPheromone = pheromones[p]
        local currentDistSq = currentPheromone:GetDistanceSquared(toOrigin)

        if currentDistSq < bestDistSq then
        
            bestDistSq = currentDistSq
            bestPheromone = currentPheromone
            
        end
        
    end
    
    return bestPheromone
    
end

function PlayerUI_GetOrderPath()

    local player = Client.GetLocalPlayer()
    if player then
    
        if player:isa("Alien") then
        
            local playerOrigin = player:GetOrigin()
            local pheromone = GetMostRelevantPheromone(playerOrigin)
            if pheromone then
            
                local points = PointArray()
                local isReachable = Pathing.GetPathPoints(playerOrigin, pheromone:GetOrigin(), points)
                if isReachable then
                    return points
                end
                
            end
            
        elseif HasMixin(player, "Orders") then
        
            local currentOrder = player:GetCurrentOrder()
            if currentOrder then
            
                local targetLocation = currentOrder:GetLocation()
                local points = PointArray()
                local isReachable = Pathing.GetPathPoints(player:GetOrigin(), targetLocation, points)
                if isReachable then
                    return points
                end
                
            end
            
        end
        
    end
    
    return nil
    
end

function PlayerUI_GetCanDisplayRequestMenu()

    local player = Client.GetLocalPlayer()
    return player ~= nil and (player:GetIsAlive() or player:isa("Spectator")) and not player:GetBuyMenuIsDisplaying() and not MainMenu_GetIsOpened()
    
end

function PlayerUI_OnRequestSelected()

    local player = Client.GetLocalPlayer()
    -- Prevent the player from shooting after a request is selected.
    player.timeClosedMenu = Shared.GetTime()
    
end

function Player:GetBuyMenuIsDisplaying()
    return self.buyMenu ~= nil
end

function PlayerUI_GetBuyMenuDisplaying()

    local isDisplaying = false
    
    local player = Client.GetLocalPlayer()
    
    if player then
        isDisplaying = player:GetBuyMenuIsDisplaying()
    end
    
    return isDisplaying
    
end

local function UnitIsSelectedByLocalCommander(player, unit)
    return player:isa("Commander") and ( unit:isa("Player") or (HasMixin(unit, "Selectable") and unit:GetIsSelected(player:GetTeamNumber())) )
end

local kUnitStatusDisplayRange = 13
local kUnitStatusCommanderDisplayRange = 50
local kDefaultHealthOffset = 1.2

function PlayerUI_GetPositionalInfo(player, unit)
    
    local distance = nil
    local healthBarOrigin = nil
    local worldOrigin = nil
    local healthOffsetDirection = player:isa("Commander") and Vector.xAxis or Vector.yAxis
    local eyePos = player:GetEyePos()
    
    local getEngagementPoint = unit.GetEngagementPoint
    local origin = getEngagementPoint and getEngagementPoint(unit) or unit:GetOrigin()

    local normToEntityVec = GetNormalizedVector(origin - eyePos)
    local normViewVec = player:GetViewAngles():GetCoords().zAxis

    local dotProduct = normToEntityVec:DotProduct(normViewVec)

    if dotProduct > 0 then

        distance = (origin - eyePos):GetLength()
            
        local healthBarOffset = kDefaultHealthOffset
        
        local getHealthbarOffset = unit.GetHealthbarOffset
        if getHealthbarOffset then
            healthBarOffset = getHealthbarOffset(unit)
        end
        
        healthBarOrigin = origin + healthOffsetDirection * healthBarOffset
        local worldOrigin = Vector(origin)
        origin = Client.WorldToScreen(origin)
        healthBarOrigin = Client.WorldToScreen(healthBarOrigin)
        if unit == crossHairTarget then
        
            healthBarOrigin.y = math.max(GUIScale(180), healthBarOrigin.y)
            healthBarOrigin.x = Clamp(healthBarOrigin.x, GUIScale(320), Client.GetScreenWidth() - GUIScale(320))
            
        end
        
    end
    
    return dotProduct, origin, worldOrigin, distance, healthBarOrigin

end
      
-- Return true if the unit will show status info to the player
function PlayerUI_ShowsUnitStatusInfo(player, unit)
    return UnitIsSelectedByLocalCommander(player,unit) or unit == player:GetCrossHairTarget()
end

function PlayerUI_GetStatusInfoForUnit(player, unit)
        
    local crossHairTarget = PlayerUI_ShowsUnitStatusInfo(player, unit)
    
    -- checks here if the model was rendered previous frame as well
    local status = unit:GetUnitStatus(player)
    if unit:GetShowUnitStatusFor(player) then

        -- Get direction to blip. If off-screen, don't render. Bad values are generated if
        -- Client.WorldToScreen is called on a point behind the camera.
        local dotProduct, origin, worldOrigin, distance, healthBarOrigin = PlayerUI_GetPositionalInfo(player, unit) 
        
        if dotProduct > 0 then

            local statusFraction = unit:GetUnitStatusFraction(player)
            local description = unit:GetUnitName(player)
            local action = unit:GetActionName(player)
            local hint = unit:GetUnitHint(player)
           
            local health = 0
            local armor = 0

            local visibleToPlayer = true                        
            if HasMixin(unit, "Cloakable") and GetAreEnemies(player, unit) then
            
                if unit:GetIsCloaked() or (unit:isa("Player") and unit:GetCloakFraction() > 0.2) then
                    visibleToPlayer = false
                end
                
            end
            
            -- Don't show tech points or nozzles if they are attached
            if (unit:GetMapName() == TechPoint.kMapName or unit:GetMapName() == ResourcePoint.kPointMapName) and unit.GetAttached and (unit:GetAttached() ~= nil) then
                visibleToPlayer = false
            end
            
            if HasMixin(unit, "Live") and (not unit.GetShowHealthFor or unit:GetShowHealthFor(player)) then
            
                health = unit:GetHealthFraction()
                if unit:GetArmor() == 0 then
                    armor = 0
                else 
                    armor = unit:GetArmorScalar()
                end

            end
            
            local badgeTextures = ""
            
            if HasMixin(unit, "Player") then
                if unit.GetShowBadgeOverride and not unit:GetShowBadgeOverride() then
                    badgeTextures = {}
                else
                    badgeTextures = Badges_GetBadgeTextures(unit:GetClientIndex(), "unitstatus") or {}
                end
            end
            
            local hasWelder = false 
            if distance < 10 then    
                hasWelder = unit:GetHasWelder(player)
            end
            
            local abilityFraction = 0
            if player:isa("Commander") then
                abilityFraction = unit:GetAbilityFraction()
            end
            
            local unitState = {
                UnitId = unit:GetId(),
                Position = origin,
                WorldOrigin = worldOrigin,
                HealthBarPosition = healthBarOrigin,
                Status = status,
                Name = description,
                Action = action,
                Hint = hint,
                StatusFraction = statusFraction,
                HealthFraction = health,
                ArmorFraction = armor,
                IsCrossHairTarget = crossHairTarget and visibleToPlayer,
                TeamType = kNeutralTeamType,
                ForceName = unit:isa("Player") and not GetAreEnemies(player, unit),
                BadgeTextures = badgeTextures,
                HasWelder = hasWelder,
                IsPlayer = unit:isa("Player"),
                IsSteamFriend = unit:isa("Player") and unit:GetIsSteamFriend() or false,
                AbilityFraction = abilityFraction,
                IsParasited = HasMixin(unit, "ParasiteAble") and unit:GetIsParasited()
            }

            
            if unit.GetTeamNumber then
                unitState.IsFriend = (unit:GetTeamNumber() == player:GetTeamNumber())
            end
            
            if unit.GetTeamType then
                unitState.TeamType = unit:GetTeamType()
            end

            if unit:isa("Player") and unit:isa("Marine") and HasMixin(unit, "WeaponOwner") and not GetAreEnemies(player, unit) then
                local primaryWeapon = unit:GetWeaponInHUDSlot(1)
                if primaryWeapon and primaryWeapon:isa("ClipWeapon") then
                    unitState.PrimaryWeapon = primaryWeapon:GetTechId()
                end
            end
            
            if unit:isa("InfantryPortal") and unit.timeSpinStarted then
                if unit.queuedPlayerId ~= Entity.invalidId then
                    local playerName = ""
                    for _, playerInfo in ientitylist(Shared.GetEntitiesWithClassname("PlayerInfoEntity")) do
                        if playerInfo.playerId == unit.queuedPlayerId then
                            playerName = playerInfo.playerName
                            break
                        end
                    end

                    unitState.SpawnerName = playerName
                    unitState.SpawnFraction = Clamp((Shared.GetTime() - unit.timeSpinStarted) / kMarineRespawnTime, 0, 1)
                end
            elseif unit:isa("Embryo") then
                unitState.EvolvePercentage = unit.evolvePercentage / 100
                unitState.EvolveClass = unit:GetEggTypeDisplayName()
            elseif unit:isa("Egg") and unit.researchProgress > 0 and unit.researchProgress < 1 then
                unitState.EvolvePercentage = unit.researchProgress
            elseif unit.GetDestinationLocationName then
                unitState.Destination = unit:GetDestinationLocationName()
            elseif unit:isa("Weapon") then
                -- Make super sure that we're hiding this
                unitState.IsCrossHairTarget = false
                unitState.Name = ""
                unitState.HealthFraction = 0
                unitState.ArmorFraction = 0
                unitState.Hint = ""
                -- Only show the AbilityFraction for Marine Commanders
                if player:isa("MarineCommander") and unit.weaponWorldState == true and unit.GetExpireTimeFraction and not unit:isa("Rifle") and not unit:isa("Pistol") then
                    unitState.IsCrossHairTarget = true
                    unitState.AbilityFraction = unit:GetExpireTimeFraction()
                    unitState.IsWorldWeapon = true
                end
            end
            
            return unitState
        end
    end
    return nil
end
            
            

-- collects unit status info for a single unit
function PlayerUI_GetUnitStatusInfo()

    PROFILE("PlayerUI_GetUnitStatusInfo")
    
    local unitStates = { }
    
    local player = Client.GetLocalPlayer()
    
    if player and not player:GetBuyMenuIsDisplaying() and (not player.GetDisplayUnitStates or player:GetDisplayUnitStates()) then
    
        local eyePos = player:GetEyePos()
        local crossHairTarget = player:GetCrossHairTarget()
        
        local range = kUnitStatusDisplayRange
         
        if player:isa("Commander") then
            range = kUnitStatusCommanderDisplayRange
        end
        
        local healthOffsetDirection = player:isa("Commander") and Vector.xAxis or Vector.yAxis
    
        for index, unit in ipairs(GetEntitiesWithMixinWithinRange("UnitStatus", eyePos, range)) do
  
            local unitState = PlayerUI_GetStatusInfoForUnit(player, unit)
            
            if unitState then
                table.insert(unitStates, unitState)
            end               
         
         end
        
    end
    
    return unitStates

end


function PlayerUI_GetObjectives()
    return { }
end

function PlayerUI_GetWaypointType()

    local player = Client.GetLocalPlayer()
    
    local type = kTechId.Move
    
    if player then
    
        local currentOrder = player:GetCurrentOrder()
        if currentOrder then
            type = currentOrder:GetType()
        end
    
    end
    
    return type

end

local kAnimateFields = { x = true, y = true, scale = true, dist = true }

--[[
 * Gives the UI the screen space coordinates of where to display
 * the final waypoint for when players have an order location.
]]
function PlayerUI_GetFinalWaypointInScreenspace()

    local player = Client.GetLocalPlayer()
    
    if not player then
        return nil
    end
    
    local isCommander = player:isa("Commander")
    local currentOrder
    
    if isCommander then
    
        local orders = GetRelevantOrdersForPlayer(player)
        if #orders == 0 then
            return nil
        end
        
        currentOrder = orders[1]
        
    else
    
        if player:isa("Alien") then
            currentOrder = GetMostRelevantPheromone(player:GetOrigin())
        elseif HasMixin(player, "Orders") then
            currentOrder = player:GetCurrentOrder()
        end
        
    end
    
    if not currentOrder then
        return nil
    end
    
    local orderTypeName = GetDisplayNameForTechId(currentOrder:GetType(), "<no display name>")
    local orderType = currentOrder:GetType()
    local orderId = currentOrder:GetId()
    
    local playerEyePos = Vector(player:GetCameraViewCoords().origin)
    local playerForwardNorm = Vector(player:GetCameraViewCoords().zAxis)
    
    -- This method needs to use the previous updates player info.
    if player.lastPlayerEyePos == nil then
    
        player.lastPlayerEyePos = Vector(playerEyePos)
        player.lastPlayerForwardNorm = Vector(playerForwardNorm)
        
    end
    
    local orderWayPoint
    if currentOrder:isa("Pheromone") then
        orderWayPoint = currentOrder:GetOrigin()
    else
        orderWayPoint = currentOrder:GetLocation()
    end
    
    if not isCommander then
        orderWayPoint = orderWayPoint + Vector(0, 1.5, 0)
    end
    
    local screenPos = Client.WorldToScreen(orderWayPoint)
    
    local isInScreenSpace = false
    local nextWPDir = orderWayPoint - player.lastPlayerEyePos
    local normToEntityVec = GetNormalizedVectorXZ(nextWPDir)
    local normViewVec = GetNormalizedVectorXZ(player.lastPlayerForwardNorm)
    local dotProduct = Math.DotProduct(normToEntityVec, normViewVec)
    
    -- Distance is used for scaling.
    local nextWPDist = nextWPDir:GetLength()
    local nextWPMaxDist = 25
    local nextWPScale = isCommander and 0.3 or math.max(0.5, 1 - (nextWPDist / nextWPMaxDist))

    
    if isCommander then
        nextWPDist = 0
    end
    
    if player.nextWPInScreenSpace == nil then
    
        player.nextWPInScreenSpace = true
        player.nextWPDoingTrans = false
        player.nextWPLastVal = { x = 0, y = 0, scale = 0, dist = 0, id = 0 }

        player.nextWPCurrWP = Vector(orderWayPoint)
        
    end
    
    -- If the waypoint has changed, do a smooth transition.
    if player.nextWPCurrWP ~= orderWayPoint then
    
        player.nextWPDoingTrans = true
        VectorCopy(orderWayPoint, player.nextWPCurrWP)
        
    end
    
    local returnTable
    local spaceToBorder = ConditionalValue(isCommander, 0, 0.18)
    
    -- If offscreen, fallback on compass method.
    local minWidthBuff = Client.GetScreenWidth() * spaceToBorder
    local minHeightBuff = Client.GetScreenHeight() * spaceToBorder
    local maxWidthBuff = Client.GetScreenWidth() * (1 - spaceToBorder)
    local maxHeightBuff = Client.GetScreenHeight() * (1 - spaceToBorder)
    
    if screenPos.x < minWidthBuff or screenPos.x > maxWidthBuff or
       screenPos.y < minHeightBuff or screenPos.y > maxHeightBuff or dotProduct < 0 then
       
        if player.nextWPInScreenSpace then
            player.nextWPDoingTrans = true
        end
        player.nextWPInScreenSpace = false
        
        local eyeForwardPos = player.lastPlayerEyePos + (player.lastPlayerForwardNorm * 5)
        local eyeForwardToWP = orderWayPoint - eyeForwardPos
        eyeForwardToWP:Normalize()
        local eyeForwardToWPScreen = Client.WorldToScreen(eyeForwardPos + eyeForwardToWP)
        local middleOfScreen = Vector(Client.GetScreenWidth() / 2, Client.GetScreenHeight() / 2, 0)
        local screenSpaceDir = eyeForwardToWPScreen - middleOfScreen
        screenSpaceDir:Normalize()
        local finalScreenPos = middleOfScreen + Vector(screenSpaceDir.x * (Client.GetScreenWidth() / 2), screenSpaceDir.y * (Client.GetScreenHeight() / 2), 0)
        
        local showArrow = not isCommander and (finalScreenPos.x < minWidthBuff or finalScreenPos.x > maxWidthBuff or finalScreenPos.y < minHeightBuff or finalScreenPos.y > maxHeightBuff)
        
        -- Clamp to edge of screen with buffer
        finalScreenPos.x = Clamp(finalScreenPos.x, minWidthBuff, maxWidthBuff)
        finalScreenPos.y = Clamp(finalScreenPos.y, minHeightBuff, maxHeightBuff)
        
        returnTable = { x = finalScreenPos.x, y = finalScreenPos.y, scale = nextWPScale, name = orderTypeName, dist = nextWPDist, type = orderType, id = orderId, showArrow = showArrow }
        
    else
    
        isInScreenSpace = true
        
        if not player.nextWPInScreenSpace then
            player.nextWPDoingTrans = true
        end
        player.nextWPInScreenSpace = true
        
        local bounceY = screenPos.y + (math.sin(Shared.GetTime() * 3) * (10 * nextWPScale))
        
        returnTable = { x = screenPos.x, y = bounceY, scale = nextWPScale, name = orderTypeName, dist = nextWPDist, type = orderType, id = orderId }
        
    end
    
    if player.nextWPDoingTrans then
    
        local replaceTable = { }
        local allEqual = true

        for name, field in pairs(returnTable) do

            if kAnimateFields[name] then
            
                replaceTable[name] = Slerp(player.nextWPLastVal[name], returnTable[name], 50)
                allEqual = allEqual and replaceTable[name] == returnTable[name]
                
            else
                replaceTable[name] = returnTable[name]
            end
            
        end
        
        if allEqual then
            player.nextWPDoingTrans = false
        end
        
        returnTable = replaceTable
        
    end

    for name, field in pairs(returnTable) do
        player.nextWPLastVal[name] = field
    end
    
    -- Save current for next update.
    VectorCopy(playerEyePos, player.lastPlayerEyePos)
    VectorCopy(playerForwardNorm, player.lastPlayerForwardNorm)
    
    return returnTable
    
end

--[[
 * Get the X position of the crosshair image in the atlas. 
]]
function PlayerUI_GetCrosshairX()
    return 0
end

--[[
 * Get the Y position of the crosshair image in the atlas.
 * Listed in this order:
 *   Rifle, Pistol, Axe, Shotgun, Minigun, Rifle with GL, Flamethrower
]]
function PlayerUI_GetCrosshairY()

    local player = Client.GetLocalPlayer()

    if(player and not player:GetIsThirdPerson()) then  
      
        local weapon = player:GetActiveWeapon()
        if(weapon ~= nil) then
        
            -- Get class name and use to return index
            local index 
            local mapname = weapon:GetMapName()
            
            if mapname == Rifle.kMapName or mapname == GrenadeLauncher.kMapName or mapname == HeavyMachineGun.kMapName or mapname == HandGrenades.kMapName then 
                index = 0
            elseif mapname == Pistol.kMapName then
                index = 1
            elseif mapname == Shotgun.kMapName then
                index = 3
            -- All alien crosshairs are the same for now
            elseif mapname == Spores.kMapName or mapname == Umbra.kMapName or mapname == Primal.kMapName or mapname == Spikes.kMapName or mapname == Parasite.kMapName or mapname == AcidRocket.kMapName then
                index = 6
            elseif mapname == SpitSpray.kMapName or mapname == BabblerAbility.kMapName then
                index = 7
            -- Blanks (with default damage indicator)
            else
                index = 8
            end
        
            return index * 64
            
        end
        
    end

end

function PlayerUI_GetCrosshairDamageIndicatorY()

    return 8 * 64
    
end

--[[
 * Returns the player name under the crosshair for display (return "" to not display anything).
]]
function PlayerUI_GetCrosshairText()
    
    local player = Client.GetLocalPlayer()
    if player then
        if player.GetCrossHairText then
            return player:GetCrossHairText()
        else
            return player.crossHairText
        end
    end
    return nil
    
end

function Player:GetDisplayUnitStates()
    return self:GetIsAlive()
end

function PlayerUI_GetProgressText()

    local player = Client.GetLocalPlayer()
    if player then
        return player.progressText
    end
    return nil

end

function PlayerUI_GetProgressFraction()

    local player = Client.GetLocalPlayer()
    if player then
        return player.progressFraction
    end
    return nil

end

local kEnemyObjectiveRange = 30
function PlayerUI_GetObjectiveInfo()

    local player = Client.GetLocalPlayer()
    
    if player then
    
        if player.crossHairHealth and player.crossHairText then  
        
            player.showingObjective = true
            return player.crossHairHealth / 100, player.crossHairText .. " " .. ToString(player.crossHairHealth) .. "%", player.crossHairTeamType
            
        end
        
        -- check command structures in range (enemy or friend) and return health % and name
        local objectiveInfoEnts = EntityListToTable( Shared.GetEntitiesWithClassname("ObjectiveInfo") )
        local playersTeam = player:GetTeamNumber()
        
        local function SortByHealthAndTeam(ent1, ent2)
            return ent1:GetHealthScalar() < ent2:GetHealthScalar() and ent1.teamNumber == playersTeam
        end
        
        table.sort(objectiveInfoEnts, SortByHealthAndTeam)
        
        for _, objectiveInfoEnt in ipairs(objectiveInfoEnts) do
        
            if objectiveInfoEnt:GetIsInCombat() and ( playersTeam == objectiveInfoEnt:GetTeamNumber() or (player:GetOrigin() - objectiveInfoEnt:GetOrigin()):GetLength() < kEnemyObjectiveRange ) then

                local healthFraction = math.max(0.01, objectiveInfoEnt:GetHealthScalar())

                player.showingObjective = true
                
                local text = StringReformat(Locale.ResolveString("OBJECTIVE_PROGRESS"),
                                            { location = objectiveInfoEnt:GetLocationName(),
                                              name = GetDisplayNameForTechId(objectiveInfoEnt:GetTechId()),
                                              health = math.ceil(healthFraction * 100) })
                
                return healthFraction, text, objectiveInfoEnt:GetTeamType()
                
            end
            
        end
        
        player.showingObjective = false
        
    end
    
end

function PlayerUI_GetShowsObjective()

    local player = Client.GetLocalPlayer()
    if player then
        return player.showingObjective == true
    end
    
    return false

end

function PlayerUI_GetCrosshairHealth()

    local player = Client.GetLocalPlayer()
    if player then
        if player.GetCrossHairHealth then
            return player:GetCrossHairHealth()
        else
            return player.crossHairHealth
        end
    end
    return nil

end

function PlayerUI_GetCrosshairBuildStatus()

    local player = Client.GetLocalPlayer()
    if player then
        if player.GetCrossHairBuildStatus then
            return player:GetCrossHairBuildStatus()
        else
            return player.crossHairBuildStatus
        end
    end
    return nil

end

-- Returns the int color to draw the results of PlayerUI_GetCrosshairText() in.
function PlayerUI_GetCrosshairTextColor()
    local player = Client.GetLocalPlayer()
    if player then
        return player.crossHairTextColor
    end
    return kFriendlyColor
end

--[[
 * Get the width of the crosshair image in the atlas, return 0 to hide
]]
function PlayerUI_GetCrosshairWidth()

    local player = Client.GetLocalPlayer()
    if player and player:GetActiveWeapon() and not player:GetIsThirdPerson() then
        return 64
    end
    
    return 0
    
end

function PlayerUI_GetTooltipDataFromTechId(techId, hotkeyIndex)

    local techTree = GetTechTree()

    if techTree then
    
        local tooltipData = {}
        local techNode = techTree:GetTechNode(techId)

        tooltipData.text = GetDisplayNameForTechId(techId, "TIP")
        tooltipData.info = GetTooltipInfoText(techId)
        tooltipData.costNumber = LookupTechData(techId, kTechDataCostKey, 0)                
        tooltipData.requires = techTree:GetRequiresText(techId)
        tooltipData.enabled = techTree:GetEnablesText(techId)          
        tooltipData.techNode = techTree:GetTechNode(techId)
        
        tooltipData.resourceType = 0
        
        if techNode then
            tooltipData.resourceType = techNode:GetResourceType()
        end

        if hotkeyIndex then
        
            tooltipData.hotKey = kGridHotkeys[hotkeyIndex]
            
            if tooltipData.hotKey ~= "" then
                tooltipData.hotKey = gHotkeyDescriptions[tooltipData.hotKey]
            end
        
        end
        
        tooltipData.hotKey = tooltipData.hotKey or ""
    
        return tooltipData
    
    end

end


--[[
 * Get the height of the crosshair image in the atlas, return 0 to hide
]]
function PlayerUI_GetCrosshairHeight()

    local player = Client.GetLocalPlayer()
    if player and player:GetActiveWeapon() and not player:GetIsThirdPerson() then
        return 64
    end
    
    return 0

end

--[[
 * Returns nil or the commander name.
]]
function PlayerUI_GetCommanderName()

    local player = Client.GetLocalPlayer()
    local commanderName

    if player then
    
        -- we simply use the scoreboard ui here, since it holds all informations required client side
        local commTable = ScoreboardUI_GetOrderedCommanderNames(player:GetTeamNumber())
        
        if table.count(commTable) > 0 then
            commanderName = commTable[1]
        end    
        
    end
    
    return commanderName
    
end

function PlayerUI_GetWeapon()
    -- TODO : Return actual weapon name
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetActiveWeapon()
    end
end

--[[
 * Returns a list of techIds (weapons) the player is carrying.
]]
function PlayerUI_GetInventoryTechIds()

    PROFILE("PlayerUI_GetInventoryTechIds")
    
    local player = Client.GetLocalPlayer()
    if player and HasMixin(player, "WeaponOwner") then
    
        local inventoryTechIds = table.array(5)
        local weaponList = player:GetHUDOrderedWeaponList()
        
        for w = 1, #weaponList do
        
            local weapon = weaponList[w]
            table.insert(inventoryTechIds, { TechId = weapon:GetTechId(), HUDSlot = weapon:GetHUDSlot() })
            
        end
        
        return inventoryTechIds
        
    end
    return { }
    
end

function PlayerUI_IsCameraAnimated()

    local player = Client.GetLocalPlayer()
    if player ~= nil then
        return player:IsAnimated()
    end
    
    return false
    
end

--[[
 * Returns the techId of the active weapon.
]]
function PlayerUI_GetActiveWeaponTechId()

    PROFILE("PlayerUI_GetActiveWeaponTechId")
    
    local player = Client.GetLocalPlayer()
    if player then
    
        local activeWeapon = player:GetActiveWeapon()
        if activeWeapon then
            return activeWeapon:GetTechId()
        end
        
    end
    
end

function PlayerUI_GetPlayerClassName()

    local player = Client.GetLocalPlayer()
    if player then
        return player:GetClassName()
    end

end

function PlayerUI_GetPlayerClass()

    return "Player"

end

function PlayerUI_GetMinimapPlayerDirection()

    local player = Client.GetLocalPlayer()
    
    if player then    
        return player:GetDirectionForMinimap()        
    end
    
    return 0

end

function PlayerUI_GetReadyRoomOrders()

    local readyRoomOrders = { }
    
    for _, teamjoinEnt in ientitylist(Shared.GetEntitiesWithClassname("TeamJoin")) do
    
        if teamjoinEnt.teamNumber == kTeam1Index or teamjoinEnt.teamNumber == kTeam2Index then
        
            local order = { }
            order.TeamNumber = teamjoinEnt.teamNumber
            order.Position = teamjoinEnt:GetOrigin() + Vector(0, 1, 0)
            order.IsFull = teamjoinEnt.teamIsFull
            
            order.PlayerCount = teamjoinEnt.playerCount
            
            table.insert(readyRoomOrders, order)
            
        end
        
    end
    
    return readyRoomOrders
    
end

function PlayerUI_GetWeaponAmmo()

    local player = Client.GetLocalPlayer()
    
    if player then
        return player:GetWeaponAmmo()
    end
    
    return 0
    
end

function PlayerUI_GetWeaponClip()
    local player = Client.GetLocalPlayer()
    
    if player then
        return player:GetWeaponClip()
    end
    return 0
end

function PlayerUI_GetWeaponClipSize()
    local player = Client.GetLocalPlayer()
    
    if player then
        return player:GetWeaponClipSize()
    end
    
    return 0
    
end

function PlayerUI_GetAuxWeaponClip()

    local player = Client.GetLocalPlayer()
    
    if player then
        return player:GetAuxWeaponClip()
    end
    
    return 0
    
end

function PlayerUI_GetWeldPercentage()

    local player = Client.GetLocalPlayer()
    
    if player and player.GetCurrentWeldPercentage then
        return player:GetCurrentWeldPercentage()
    end
    
    return 0
    
end

function PlayerUI_GetUnitStatusPercentage()

    local player = Client.GetLocalPlayer()
    
    if player and player.UnitStatusPercentage then
        return player:UnitStatusPercentage()
    end
    
    return 0
    
end

--[[
 * Returns the amount of team resources.
]]
function PlayerUI_GetTeamResources()

    PROFILE("PlayerUI_GetTeamResources")
    
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetDisplayTeamResources()
    end
    
    return 0
    
end

--TODO:
function PlayerUI_MarineAbilityIconsImage()
end

function PlayerUI_GetGameStartTime()

    local entityList = Shared.GetEntitiesWithClassname("GameInfo")
    if entityList:GetSize() > 0 then
    
        local gameInfo = entityList:GetEntityAtIndex(0)
        local state = gameInfo:GetState()
        
        if state ~= kGameState.NotStarted and
           state ~= kGameState.PreGame and
           state ~= kGameState.Countdown then
            return gameInfo:GetStartTime()
        end
        
    end
    
    return 0
    
end

function PlayerUI_GetGameLengthTime()

    local state
    local entityList = Shared.GetEntitiesWithClassname("GameInfo")

    if entityList:GetSize() > 0 then

        local gameInfo = entityList:GetEntityAtIndex(0)

        state = gameInfo:GetState()

        if state ~= kGameState.PreGame and
        state ~= kGameState.Countdown
        then
            if state ~= kGameState.Started then
                return gameInfo.prevTimeLength or 0, state
            else
                return math.max( 0, math.floor(Shared.GetTime()) - gameInfo:GetStartTime() ), state
            end
        end

    end

    return 0, state

end

function PlayerUI_GetNumConnectingPlayers()
    
    local entityList = Shared.GetEntitiesWithClassname("GameInfo")

    if entityList:GetSize() > 0 then

        local gameInfo = entityList:GetEntityAtIndex(0)
        
        local numPlayersTotal = gameInfo:GetNumPlayersTotal()
        local numPlayersInGame = #Scoreboard_GetPlayerList()
        
        return math.max( 0, numPlayersTotal - numPlayersInGame )
        
    end
    
    return 0
end

function PlayerUI_GetNumCommandStructures()

    local player = Client.GetLocalPlayer()
    if player ~= nil then
    
        local teamInfo = GetEntitiesForTeam("TeamInfo", player:GetTeamNumber())
        if table.count(teamInfo) > 0 then
            return teamInfo[1]:GetNumCapturedTechPoints()
        end
        
    end
    
    return 0
    
end

--[[
 * Called by Flash to get the value to display for the personal resources on
 * the HUD.
]]
function PlayerUI_GetPlayerResources()

    local player = Client.GetLocalPlayer()
    if player then
        return player:GetDisplayResources()
    end
    
    return 0
    
end

--[[
 * Returns a float instead of integer to define a change of the value.
]]
function PlayerUI_GetPersonalResources()

    PROFILE("PlayerUI_GetPersonalResources")
    
    local player = Client.GetLocalPlayer()
    if player then
        return player:GetPersonalResources()
    end
    
    return 0
    
end

function PlayerUI_GetPlayerHealth()

    local player = Client.GetLocalPlayer()
    if player then
    
        local health = math.ceil(player:GetHealth())
        -- When alive, enforce at least 1 health for display.
        if player:GetIsAlive() then
            health = math.max(1, health)
        end
        return health
        
    end
    
    return 0
    
end

function PlayerUI_GetPlayerMaxHealth()

    local player = Client.GetLocalPlayer()
    if player then
        return player:GetMaxHealth()
    end
    
    return 0
    
end

function PlayerUI_GetPlayerArmor()

    local player = Client.GetLocalPlayer()
    if player then
        return player:GetArmor()
    end
    
    return 0
    
end

function PlayerUI_GetPlayerMaxArmor()

    local player = Client.GetLocalPlayer()
    if player then
        return player:GetMaxArmor()
    end
    
    return 0
    
end

function PlayerUI_GetPlayerIsParasited()

    local player = Client.GetLocalPlayer()
    if player and HasMixin(player, "ParasiteAble") then
        return player:GetIsParasited()
    end
    
    return false
    
end

function PlayerUI_GetPlayerJetpackFuel()

    local player = Client.GetLocalPlayer()
    
    if player:isa("JetpackMarine") then
        return player:GetFuel()
    end
    
    return 0
    
end

function PlayerUI_GetHasMinigun()

    local player = Client.GetLocalPlayer()
    local hasMinigun = false
    
    if player and player:isa("Exo") then
    
        local weaponHolder = player:GetActiveWeapon()
        if weaponHolder and (weaponHolder:GetLeftSlotWeapon():isa("Minigun") or weaponHolder:GetRightSlotWeapon():isa("Minigun")) then
            hasMinigun = true
        end
    
    end
    
    return hasMinigun

end

function PlayerUI_GetPlayerParasiteState()

    local playerParasiteState = 1
    if PlayerUI_GetPlayerIsParasited() then
        playerParasiteState = 2
    end
    
    return playerParasiteState

end
function PlayerUI_GetIsBeaconing()

    local player = Client.GetLocalPlayer()
    if player then
        return player:GetGameEffectMask(kGameEffect.Beacon)
    end
    return false

end

--For drawing health circles
function GameUI_GetHealthStatus(entityId)

    local entity = Shared.GetEntity(entityId)
    if entity ~= nil then
    
        if HasMixin(entity, "Live") then
            return entity:GetHealth() / entity:GetMaxHealth()
        else
            Print("GameUI_GetHealthStatus(%d) - Entity type %s is not alive.", entityId, entity:GetMapName())
        end
        
    end
    
    return 0
    
end

function Player:GetName(forEntity)

    --[[
    -- There are cases where the player name will be nil such as right before
    -- this Player is destroyed on the Client (due to the scoreboard removal message
    -- being received on the Client before the entity removed message). Play it safe.
    ]]

    local clientIndex = self:GetClientIndex()
    
    if self.isHallucination then
        clientIndex = self:GetHallucinatedClientIndex()
    end
    
    return Scoreboard_GetPlayerData(clientIndex, "Name") or "No Name"
    
end

function PlayerUI_GetPlayerName()

    local player = Client.GetLocalPlayer()
    if player then
        return player:GetName()
    end

    return ""    

end

function PlayerUI_GetNumClingedBabblers()

    local numBabblers = 0
    local player = Client.GetLocalPlayer()
    if player and HasMixin(player, "BabblerCling") then
        numBabblers = player:GetNumClingedBabblers()    
    end
    
    return numBabblers

end

function PlayerUI_GetEnergized()

    local energized = false
    
    local player = Client.GetLocalPlayer()
    if player and HasMixin(player, "Energize") then
        energized = player:GetEnergized()
    end
    
    return energized
    
end

function Player:GetIsLocalPlayer()
    return self == Client.GetLocalPlayer()
end

function Player:GetDrawResourceDisplay()
    return false
end

function Player:GetShowHealthFor(player)
    return ( player:isa("Spectator") or ( not GetAreEnemies(self, player) and self:GetIsAlive() ) ) and self:GetTeamType() ~= kNeutralTeamType
end

function Player:GetCrossHairTarget()

    local viewAngles = self:GetViewAngles()    
    local viewCoords = viewAngles:GetCoords()    
    local startPoint = self:GetEyePos()
    local endPoint = startPoint + viewCoords.zAxis * kRangeFinderDistance
    
    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.AllButPCsAndRagdolls, EntityFilterOneAndIsa(self, "Babbler"))
    return trace.entity
    
end

function Player:GetShowCrossHairText()
    return self:GetTeamNumber() == kMarineTeamType or self:GetTeamNumber() == kAlienTeamType
end

function Player:UpdateCrossHairText(entity)

    if self.buyMenu ~= nil then
        self.crossHairText = nil
        self.crossHairHealth = 0
        self.crossHairBuildStatus = 0
        return
    end

    if not entity or ( entity.GetShowCrossHairText and not entity:GetShowCrossHairText(self) ) then
        self.crossHairText = nil
        return
    end    
    
    if HasMixin(entity, "Cloakable") and GetAreEnemies(self, entity) and entity:GetIsCloaked() then
        self.crossHairText = nil
        return
    end
    
    if entity:isa("Player") and GetAreEnemies(self, entity) then
        self.crossHairText = nil
        return
    end    
    
    if HasMixin(entity, "Tech") and HasMixin(entity, "Live") and (entity:GetIsAlive() or (entity.GetShowHealthFor and entity:GetShowHealthFor(self))) then
    
        if self:isa("Marine") and entity:isa("Marine") and self:GetActiveWeapon() and self:GetActiveWeapon():isa("Welder") then
            self.crossHairHealth = math.ceil(math.max(0.00, entity:GetArmor() / entity:GetMaxArmor() ) * 100)
        else
            self.crossHairHealth = math.ceil(math.max(0.00, entity:GetHealthScalar()) * 100)
        end
        
        if entity:isa("Player") then        
            self.crossHairText = entity:GetName()    
        else 
            self.crossHairText = Locale.ResolveString(LookupTechData(entity:GetTechId(), kTechDataDisplayName, ""))
            
            if entity:isa("CommandStructure") then
              self.crossHairText = entity:GetLocationName() .. " " .. self.crossHairText          
            end
            
        end
        
        --add build %
        if HasMixin(entity, "Construct") then
        
            if entity:GetIsBuilt() then
                self.crossHairBuildStatus = 100
            else
                self.crossHairBuildStatus = math.floor(entity:GetBuiltFraction() * 100)
            end
        
        else
            self.crossHairBuildStatus = 0
        end
        
        if HasMixin(entity, "Team") then
            self.crossHairTeamType = entity:GetTeamType()        
        end
        
    else
    
        self.crossHairText = nil
        self.crossHairHealth = 0
        
        if entity:isa("Player") then
            self.crossHairText = entity:GetName()
        end
        
    end
        
    if GetAreEnemies(self, entity) then
        self.crossHairTextColor = kEnemyColor
    elseif HasMixin(entity, "GameEffects") and entity:GetGameEffectMask(kGameEffect.Parasite) then
        self.crossHairTextColor = kParasitedTextColor
    elseif HasMixin(entity, "Team") and self:GetTeamNumber() == entity:GetTeamNumber() then
        self.crossHairTextColor = kFriendlyColor
    else
        self.crossHairTextColor = kNeutralColor
    end

end

--Updates visibilty, status and position of health circle when aiming at an entity with live mixin
function Player:UpdateCrossHairTarget()
 
    --local entity = self:GetCrossHairTarget()
    
    if GetShowHealthRings() == false then
        entity = nil
    end    
    
    self:UpdateCrossHairText(entity)
    
end

function Player:OnShowMap(show)

    self.minimapVisible = show
    self:ShowMap(show, true)
    
end

function Player:GetIsMinimapVisible()
    return self.minimapVisible or false
end

local function Player_CanThrowObject( self )

    if not IsSeasonForThrowing() then
        return false
    end
    
    -- Don't throw object if already using something or if in commander view
    if self:GetIsUsing() or self:GetIsCommander() then
        return false
    end	
        
    -- Only allow in RR and pre-game (not post-game.)
    if self:GetTeamNumber() ~= kTeamReadyRoom then
        local entityList = Shared.GetEntitiesWithClassname("GameInfo")
        if entityList:GetSize() == 0 then
            return false
        end

        local gameInfo = entityList:GetEntityAtIndex(0)
        local state = gameInfo:GetState()
        
        if state ~= kGameState.NotStarted then
            return false
        end
    end
    
    -- Don't let object throwing get in the way of actually using stuff		
    local ent = self:PerformUseTrace()
    local entIsUsable = ent and ( self:GetGameStarted() or ent.GetUseAllowedBeforeGameStart and ent:GetUseAllowedBeforeGameStart() ) 
    if entIsUsable and GetPlayerCanUseEntity(self, ent) then
        return false
    end
    
    return true
end


--[[
 * Use only client side (for bringing up menus for example). Key events, and their consequences, are not sent to the server.
]]
function Player:SendKeyEvent(key, down)

    --When exit hit, bring up menu.
    if down and key == InputKey.Escape and (Shared.GetTime() > (self.timeLastMenu + 0.3) and not ChatUI_EnteringChatMessage()) then
    
        ExitPressed()
        self.timeLastMenu = Shared.GetTime()
        return true
        
    end
    
    if not ChatUI_EnteringChatMessage() and not MainMenu_GetIsOpened() then
    
        if GetIsBinding(key, "RequestHealth") then
            self.timeOfLastHealRequest = Shared.GetTime()
        end
        
        if GetIsBinding(key, "ShowMap") and not self:isa("Commander") then
            self:OnShowMap(down)
        end
        if GetIsBinding(key, "ShowMapCom") and self:isa("Commander") then
            self:OnShowMap(down)
        end
        
        if down then
        
            if GetIsBinding(key, "ReadyRoom") then
                Shared.ConsoleCommand("rr")
            elseif GetIsBinding(key, "TextChat") and not self:isa("Commander") then
                ChatUI_EnterChatMessage(false)
                return true
            elseif GetIsBinding(key, "TextChatCom") and self:isa("Commander") then        
                ChatUI_EnterChatMessage(false)
                return true                   
            elseif GetIsBinding(key, "TeamChat") and not self:isa("Commander") then        
                ChatUI_EnterChatMessage(true) 
                return true
            elseif GetIsBinding(key, "TeamChatCom") and self:isa("Commander") then            
                ChatUI_EnterChatMessage(true)
                return true 
            elseif GetIsBinding(key, "LastUpgrades") then
                Shared.ConsoleCommand("evolvelastupgrades")    
            elseif GetIsBinding(key, "ToggleMinimapNames") then
                local newValue = not Client.GetOptionBoolean("minimapNames", true)
                Client.SetOptionBoolean("minimapNames", newValue)
            elseif GetIsBinding(key, "Use") and Player_CanThrowObject( self ) then
                Shared.ConsoleCommand("throwobject " .. GetSeason())
            end
            
        end
        
        if GetIsBinding(key, "Weapon6") then
            Shared.ConsoleCommand("slot6")
            return true
        end
        
        if GetIsBinding(key, "Weapon7") then
            Shared.ConsoleCommand("slot7")
            return true
        end
        
        if GetIsBinding(key, "Weapon8") then
            Shared.ConsoleCommand("slot8")
            return true
        end
        
        if GetIsBinding(key, "Weapon9") then
            Shared.ConsoleCommand("slot9")
            return true
        end
        
        if GetIsBinding(key, "Weapon0") then
            Shared.ConsoleCommand("slot0")
            return true
        end
        
    end
    
    return false
    
end

--optionally return far plane distance, default value is 400
function Player:GetCameraFarPlane()
end

--For debugging. Cheats only.
function Player:ToggleTraceReticle()
    self.traceReticle = not self.traceReticle
end

function Player:UpdateMisc(input)

    PROFILE("Player:UpdateMisc")

    if not Shared.GetIsRunningPrediction() then
    
        self:UpdateCrossHairTarget()
        self:UpdateDamageIndicators()
        self:UpdateDeadSound()
        
    end
    
end

function Player:SetBlurEnabled(blurEnabled)
    if self:GetIsLocalPlayer() and screenEffects.blur then
        screenEffects.blur:SetActive(blurEnabled)
    end
end

local function CreatePhaseTweener()
end

function Player:UpdateScreenEffects(deltaTime)

    -- Show low health warning if below the threshold and not a spectator and not a commander.
    local isSpectator = self:isa("Spectator") or self:isa("FilmSpectator")
    local isCommander = self:isa("Commander")
    local isEmbryo = self:isa("Embryo")
    local isExo = self:isa("Exo")

    screenEffects.spectatorTint:SetActive(not Client.GetIsControllingPlayer())
    
    -- If we're cloaked, change screen effect
    local cloakScreenEffectState = HasMixin(self, "Cloakable") and self:GetIsCloaked()    
    self:SetCloakShaderState(cloakScreenEffectState)    
    self:UpdateCloakSoundLoop(cloakScreenEffectState)
    
    -- Play disorient screen effect to show we're near a shades ink cloud
    self:UpdateDisorientFX()
    
end

function Player:GetDrawWorld(isLocal)
    return not self:GetIsLocalPlayer() or self:GetIsThirdPerson() or ((self.countingDown and not Shared.GetCheatsEnabled()) and self:GetTeamNumber() ~= kNeutralTeamType)
end

-- Only called when not running prediction
function Player:UpdateClientEffects(deltaTime, isLocal)

    if isLocal then
        self:UpdateCommanderPingSound()
    end
    
end

function Player:UpdateCommanderPingSound()

    local teamInfoEnts = GetEntitiesForTeam("TeamInfo", self:GetTeamNumber())
    local teamInfo = #teamInfoEnts > 0 and teamInfoEnts[1]
    
    if teamInfo then

        local pingTime = teamInfo:GetPingTime()
        if self.timeLastCommanderPing ~= nil and pingTime > self.timeLastCommanderPing then

            local pingSound = kDefaultPingSound
            if self:GetTeamType() == kMarineTeamType then
                pingSound = kMarinePingSound
            elseif self:GetTeamType() == kAlienTeamType then
                pingSound = kAlienPingSound
            end    
         
            Shared.PlaySound(nil, pingSound)
            
        end
        
        self.timeLastCommanderPing = pingTime
        
    end

end

-- extract common stuff from the teamInfo ping
function PlayerUI_GetPingInfo(player, teamInfo, onMiniMap)

    local position = Vector(0,0,0)
    
    local pingPos = teamInfo:GetPingPosition()
    
    local location = GetLocationForPoint(pingPos)
    local locationName = location and location:GetName() or ""

    if not onMiniMap then            
        position = GetClampedScreenPosition(pingPos, 40)                
    else
        position = pingPos
    end
    local pingTime = teamInfo:GetPingTime()
    
    local timeSincePing = Shared.GetTime() - pingTime
    local distance = (player:GetEyePos() - pingPos):GetLength()
    
    return timeSincePing, position, distance, locationName, pingTime

end

function PlayerUI_GetCommanderPingInfo(onMiniMap)

    local player = Client.GetLocalPlayer()

    if player then
    
        for _, teamInfo in ipairs(GetEntitiesForTeam("TeamInfo", player:GetTeamNumber())) do
          
            return PlayerUI_GetPingInfo(player, teamInfo)
          
        end
    
    end
    
    return kCommanderPingDuration, Vector(0,0,0), 0, nil, 0

end

function PlayerUI_GetCrossHairVerticalOffset()

    local vOffset = 0
    local player = Client.GetLocalPlayer()
    
    if player and player.pitchDiff then
    
        vOffset = math.sin(player.pitchDiff) * Client.GetScreenWidth() / 2
    
    end
    
    return vOffset

end

function Player:AddAlert(techId, worldX, worldZ, entityId, entityTechId)
    
    assert(worldX)
    assert(worldZ)
    
    -- Create alert blip
    local alertType = LookupTechData(techId, kTechDataAlertType, kAlertType.Info)

    table.insert(self.alertBlips, worldX)
    table.insert(self.alertBlips, worldZ)
    table.insert(self.alertBlips, alertType - 1)
    
    -- Create alert message => {text, icon x offset, icon y offset, -1, entity id}
    local alertText = GetDisplayNameForAlert(techId, "")
    
    local xOffset, yOffset = GetMaterialXYOffset(entityTechId, GetIsMarineUnit(self))
    if not xOffset or not yOffset then
        Print("Warning: Missing texture offsets for alert: %s techId %s", alertText, EnumToString(kTechId, entityTechId))
        xOffset = 0
        yOffset = 0
    end
    
    table.insert(self.alertMessages, alertText)
    table.insert(self.alertMessages, xOffset)
    table.insert(self.alertMessages, yOffset)
    table.insert(self.alertMessages, entityId)
    table.insert(self.alertMessages, worldX)
    table.insert(self.alertMessages, worldZ)
    
end

function Player:GetAlertBlips()

    local alertBlips = { }
    if self.alertBlips then
    
        table.copy(self.alertBlips, alertBlips)
        table.clear(self.alertBlips)
        
    end
    return alertBlips
    
end

local function DisableScreenEffects(self)

    if self:GetIsLocalPlayer() then
    
        for _, effect in pairs(screenEffects) do
            effect:SetActive(false)
        end
        
    end
    
end

function UpdateMovementMode()

    if Client and Client.GetLocalPlayer() and Client.GetLocalPlayer().movementmode ~= Client.GetOptionBoolean("AdvancedMovement", false) then
        Client.SendNetworkMessage("MovementMode", {movement = Client.GetOptionBoolean("AdvancedMovement", false)}, true)
    end

end

--[[
-- Called on the Client only, after OnInitialized(), for a ScriptActor that is controlled by the local player.
-- Ie, the local player is controlling this Marine and wants to intialize local UI, flash, etc.
 ]]
function Player:OnInitLocalClient()

    self.minimapVisible = false
    
    self.alertBlips = { }
    self.alertMessages = { }
    
    DisableScreenEffects(self)
    
    -- Re-enable skybox rendering after commanding
    SetSkyboxDrawState(true)
    
    -- Show props normally
    SetCommanderPropState(false)
    
    -- Assume not in overhead mode.
    SetLocalPlayerIsOverhead(false)
    
    -- Turn on sound occlusion for non-commanders
    Client.SetSoundGeometryEnabled(true)
    
    self.traceReticle = false
    
    self.damageIndicators = { }
    
    -- Set commander geometry visible
    Client.SetGroupIsVisible(kCommanderInvisibleGroupName, true)
    
    --Client.SetEnableFog(true)
    self.crossHairText = nil
    self.crossHairTextColor = kFriendlyColor
    
    -- reset mouse sens in case it hase been forgotten somewhere else
    Client.SetMouseSensitivityScalar(1)
    
end

function Player:OnVortexClient()
end

function Player:OnVortexEndClient()
end

function Player:SetCloakShaderState(state)
end

function Player:UpdateDisorientSoundLoop(state)
end

function Player:UpdateCloakSoundLoop(state)

    -- Start or stop sound effects
    if state ~= self.playerCloakSoundLoopPlaying then
    
        self:TriggerEffects("cloak_loop", {active = state})
        self.playerCloakSoundLoopPlaying = state
        
    end
    
end

function Player:UpdateDisorientFX()

	local state = false
    if screenEffects.disorient then
    
        local amount = 0
        if HasMixin(self, "Disorientable") then
            amount = self:GetDisorientedAmount()
        end
        
        state = (amount > 0)
        if not self:GetIsThirdPerson() or not state then
            screenEffects.disorient:SetActive(state)
        end
        
        screenEffects.disorient:SetParameter("amount", amount)
        
    end
    
    self:UpdateDisorientSoundLoop(state)
    
end

--[[
 * Clear screen effects on the player immediately upon being killed so
 * they don't have them enabled while spectating. This is required now
 * that the dead player entity exists alongside the new spectator player.
]]
function Player:OnKillClient()

    DisableScreenEffects(self)
    
    if self.unitStatusDisplay then
    
        GetGUIManager():DestroyGUIScriptSingle("GUIUnitStatus")
        self.unitStatusDisplay = nil
        
    end
    
    if self.DestroyGUI then
        self:DestroyGUI()
    end    
    
end

function Player:DrawGameStatusMessage()

    local time = Shared.GetTime()
    local fraction = 1 - (time - math.floor(time))
    Client.DrawSetColor(255, 0, 0, fraction*200)

    if(self.countingDown) then
    
        Client.DrawSetTextPos(.42*Client.GetScreenWidth(), .95*Client.GetScreenHeight())
        Client.DrawString("Game is starting")
        
    else
    
        Client.DrawSetTextPos(.25*Client.GetScreenWidth(), .95*Client.GetScreenHeight())
        Client.DrawString("Game will start when both sides have players")
        
    end

end

function entityIdInList(entityId, entityList, useParentId)

    for index, entity in ipairs(entityList) do
    
        local id = entity:GetId()
        if(useParentId) then id = entity:GetParentId() end
        
        if(id == entityId) then
        
            return true
            
        end
        
    end
    
    return false
    
end

function Player:DebugVisibility()

    -- For each visible entity on other team
    local entities = GetEntitiesMatchAnyTypesForTeam({"Player", "ScriptActor"}, GetEnemyTeamNumber(self:GetTeamNumber()))
    
    for entIndex, entity in ipairs(entities) do
    
        -- If so, remember that it's seen and break
        local seen = GetCanSeeEntity(self, entity)            
        
        -- Draw red or green depending
        DebugLine(self:GetEyePos(), entity:GetOrigin(), 1, ConditionalValue(seen, 0, 1), ConditionalValue(seen, 1, 0), 0, 1)
        
    end

end

function Player:DestroyGUI()

    if Client then
    
        if self.buyMenu then
        
            GetGUIManager():DestroyGUIScript(self.buyMenu)
            MouseTracker_SetIsVisible(false)
            self.buyMenu = nil
            
        end
        
    end
    
end

function Player:CloseMenu()

    if self.buyMenu then
    
        GetGUIManager():DestroyGUIScript(self.buyMenu)
        self.buyMenu = nil
        MouseTracker_SetIsVisible(false)
        
        self:TriggerEffects("marine_buy_menu_close")
        
        -- Quick work-around to not fire weapon when closing menu.
        self.timeClosedMenu = Shared.GetTime()
        
        return true
        
    end
   
    return false
    
end

function Player:ShowMap(showMap, showBig, forceReset)

    self.minimapVisible = showMap and showBig
    
    ClientUI.GetScript("GUIMinimapFrame"):ShowMap(showMap)
    ClientUI.GetScript("GUIMinimapFrame"):SetBackgroundMode((showBig and GUIMinimapFrame.kModeBig) or GUIMinimapFrame.kModeMini, forceReset)
    
end

function Player:GetWeaponAmmo()

    -- We could do some checks to make sure we have a non-nil ClipWeapon,
    -- but this should never be called unless we do.
    local weapon = self:GetActiveWeapon()
    
	if weapon then
	    if weapon:isa("ClipWeapon") then
	        return weapon:GetAmmo()
	    elseif weapon:isa("Mines") then
	        return weapon:GetMinesLeft()
	    elseif weapon:isa("HandGrenades") then
	        return weapon:GetNadesLeft()
	    end
	end
    
    return 0
    
end

function Player:GetWeaponClip()

    -- We could do some checks to make sure we have a non-nil ClipWeapon,
    -- but this should never be called unless we do.
    local weapon = self:GetActiveWeapon()
    
    if weapon then
        if weapon:isa("ClipWeapon") then
            return weapon:GetClip()
        elseif weapon:isa("Mines") or weapon:isa("HandGrenades") then
            return 1
        end
    end
    
    return 0
    
end

function Player:GetWeaponClipSize()

    -- We could do some checks to make sure we have a non-nil ClipWeapon,
    -- but this should never be called unless we do.
    local weapon = self:GetActiveWeapon()
    
    if weapon then
        if weapon:isa("ClipWeapon") then
            return weapon:GetClipSize()
        elseif weapon:isa("Mines") then
            return kMineCount
        elseif weapon:isa("HandGrenades") then
            return kNumHandGrenades
        end
    end
    
    return 0
    
end

function Player:GetAuxWeaponClip()

    // We could do some checks to make sure we have a non-nil ClipWeapon,
    // but this should never be called unless we do.
    local weapon = self:GetActiveWeapon()
    
	if weapon then
	    if weapon:isa("ClipWeapon") then
	        return weapon:GetAuxClip()
	    elseif weapon:isa("Mines") then
	        return weapon:GetMinesLeft()
	    elseif weapon:isa("HandGrenades") then
	        return weapon:GetNadesLeft()
	    end
    end

    return 0
    
end   

function Player:OnConstructTarget(target)

    if self:GetIsLocalPlayer() and HasMixin(target, "Construct") then
        self.timeLastConstructed = Shared.GetTime()
    end

end

function Player:GetHeadAttachpointName()
    return "Head"
end

function Player:GetCameraViewCoordsOverride(cameraCoords)

    local initialAngles = Angles()
    initialAngles:BuildFromCoords(cameraCoords)

    local continue = true

    if not self:GetIsAlive() and self:GetAnimateDeathCamera() and self:GetRenderModel() then

        local attachCoords = self:GetAttachPointCoords(self:GetHeadAttachpointName())

        local animationIntensity = 0.2
        local movementIntensity = 0.5
        
        cameraCoords.yAxis = GetNormalizedVector(cameraCoords.yAxis + attachCoords.yAxis * animationIntensity)
        cameraCoords.xAxis = cameraCoords.yAxis:CrossProduct(cameraCoords.zAxis)
        cameraCoords.zAxis = cameraCoords.xAxis:CrossProduct(cameraCoords.yAxis)        
        
        cameraCoords.origin.x = cameraCoords.origin.x + (attachCoords.origin.x - cameraCoords.origin.x) * movementIntensity
        cameraCoords.origin.y = attachCoords.origin.y
        cameraCoords.origin.z = cameraCoords.origin.z + (attachCoords.origin.z - cameraCoords.origin.z) * movementIntensity
        
        return cameraCoords
    
    end

    if self.countingDown and not Shared.GetCheatsEnabled() then
    
        if HasMixin(self, "Team") and (self:GetTeamNumber() == kMarineTeamType or self:GetTeamNumber() == kAlienTeamType) then
            cameraCoords = self:GetCameraViewCoordsCountdown(cameraCoords)
            Client.SetYaw(self.viewYaw)
            Client.SetPitch(self.viewPitch)
            continue = false
        end
        
        if not self.clientCountingDown then

            self.clientCountingDown = true    
            if self.OnCountDown then
                self:OnCountDown()
            end  
  
        end
        
    end
        
    if continue then
    
         if self.clientCountingDown then
            self.clientCountingDown = false
            
            if self.OnCountDownEnd then
                self:OnCountDownEnd()
            end 
        end
        
        local activeWeapon = self:GetActiveWeapon()
        local animateCamera = activeWeapon and (not activeWeapon.GetPreventCameraAnimation or not activeWeapon:GetPreventCameraAnimation(self))
    
        -- clamp the yaw value to prevent sudden camera flip
        local cameraAngles = Angles()
        cameraAngles:BuildFromCoords(cameraCoords)
        cameraAngles.pitch = Clamp(cameraAngles.pitch, -kMaxPitch, kMaxPitch)

        cameraCoords = cameraAngles:GetCoords(cameraCoords.origin)

        -- Add in camera movement from view model animation
        if self:GetCameraDistance() == 0 then    
        
            local viewModel = self:GetViewModelEntity()
            if viewModel and animateCamera then
            
                local success, viewModelCameraCoords = viewModel:GetCameraCoords()
                if success then
                
                    -- If the view model coords has scaling in it that can affect
                    -- our later calculations, so remove it.
                    viewModelCameraCoords.xAxis:Normalize()
                    viewModelCameraCoords.yAxis:Normalize()
                    viewModelCameraCoords.zAxis:Normalize()

                    cameraCoords = cameraCoords * viewModelCameraCoords
                    
                end
                
            end
        
        end

        -- Allow weapon or ability to override camera (needed for Blink)
        if activeWeapon then
        
            local override, newCoords = activeWeapon:GetCameraCoords()
            
            if override then
                cameraCoords = newCoords
            end
            
        end

        -- Add in camera shake effect if any
        if(Shared.GetTime() < self.cameraShakeTime) then
        
            -- Camera shake knocks view up and down a bit
            local shakeAmount = math.sin( Shared.GetTime() * self.cameraShakeSpeed * 2 * math.pi ) * self.cameraShakeAmount
            local origin = Vector(cameraCoords.origin)
            
            --cameraCoords.origin = cameraCoords.origin + self.shakeVec*shakeAmount
            local yaw = GetYawFromVector(cameraCoords.zAxis)
            local pitch = GetPitchFromVector(cameraCoords.zAxis) + shakeAmount
            
            local angles = Angles(Clamp(pitch, -kMaxPitch, kMaxPitch), yaw, 0)
            cameraCoords = angles:GetCoords(origin)
            
        end
        
        cameraCoords = self:PlayerCameraCoordsAdjustment(cameraCoords)
    
    end

    local resultingAngles = Angles()
    resultingAngles:BuildFromCoords(cameraCoords)
    --[[
    local fovScale = 1
    
    if self:GetNumModelCameras() > 0 then
        local camera = self:GetModelCamera(0)
        fovScale = camera:GetFov() / math.rad(self:GetFov())
    else
        fovScale = 65 / self:GetFov()
    end

    self.pitchDiff = GetAnglesDifference(resultingAngles.pitch, initialAngles.pitch) * fovScale
    ]]
  
    return cameraCoords
    
end

function Player:GetCountDownFraction()

    if not self.clientTimeCountDownStarted then
        self.clientTimeCountDownStarted = Shared.GetTime()
    end
    
    return Clamp((Shared.GetTime() - self.clientTimeCountDownStarted) / kCtDownLength, 0, 1)

end

function Player:GetCountDownTime()

    if self.clientTimeCountDownStarted then
        return kCtDownLength - (Shared.GetTime() - self.clientTimeCountDownStarted)
    end
    
    return kCtDownLength

end

function Player:GetCountDownCamerStartCoords()

    local coords
    
    -- find the closest command structure and a random start position, look at it at start
    local commandStructures = GetEntitiesForTeam("CommandStructure", self:GetTeamNumber())
    
    if #commandStructures > 0 then
    
        local extents = LookupTechData(kTechDataMaxExtents, self:GetTechId(), Vector(Player.kXZExtents, Player.kYExtents, Player.kXZExtents))
        local randomSpawn = GetRandomSpawnForCapsule(extents.y, extents.x, commandStructures[1]:GetOrigin(), 4, 7, EntityFilterAll())
    
        if randomSpawn then
        
            randomSpawn = randomSpawn + Vector(0, 2, 0)
            local directionToPlayer = self:GetEyePos() - randomSpawn  
            directionToPlayer.y = 0
            directionToPlayer:Normalize()  
            coords =  Coords.GetLookIn(randomSpawn, directionToPlayer)
            
        end    

    end
    
    return coords

end  

function Player:OnCountDown()

    if not Shared.GetCheatsEnabled() then
    
        if not self.guiCountDownDisplay and HasMixin(self, "Team") and (self:GetTeamNumber() == kMarineTeamType or self:GetTeamNumber() == kAlienTeamType) then
            self.guiCountDownDisplay = GetGUIManager():CreateGUIScript("GUICountDownDisplay")
        end
        
    end
	
	Client.WindowNeedsAttention() -- the game is starting!

end

function Player:OnCountDownEnd()

    if self.guiCountDownDisplay then
    
        GetGUIManager():DestroyGUIScript(self.guiCountDownDisplay)
        self.guiCountDownDisplay = nil
        
    end
    
    Client.PlayMusic(gRoundStartMusic or "sound/NS2.fev/round_start")
    
end

function Player:GetCameraViewCoordsCountdown(cameraCoords)

    if not Shared.GetCheatsEnabled() then
    
        if not self.countDownStartCameraCoords then
            self.countDownStartCameraCoords = self:GetCountDownCamerStartCoords()
        end
        
        if not self.countDownEndCameraCoords then
            self.countDownEndCameraCoords = self:GetViewCoords()
        end

        if self.countDownStartCameraCoords then
        
            local originDiff = self.countDownEndCameraCoords.origin - self.countDownStartCameraCoords.origin        
            local zAxisDiff = self.countDownEndCameraCoords.zAxis - self.countDownStartCameraCoords.zAxis
            zAxisDiff.y = 0
            local animationFraction = self:GetCountDownFraction()
            
            --local viewDirection = self.countDownStartCameraCoords.zAxis + zAxisDiff * animationFraction
            local viewDirection = self.countDownStartCameraCoords.zAxis + zAxisDiff * ( math.cos((animationFraction * (math.pi / 2)) + math.pi ) + 1)

            viewDirection:Normalize()
            
            cameraCoords = Coords.GetLookIn(self.countDownStartCameraCoords.origin + originDiff * animationFraction, viewDirection)
            
            -- correct the yAxis to prevent camera flipping
            if cameraCoords.yAxis:DotProduct(Vector(0, 1, 0)) < 0 then
                cameraCoords.yAxis = cameraCoords.zAxis:CrossProduct(-cameraCoords.xAxis)
                cameraCoords.xAxis = viewDirection:CrossProduct(cameraCoords.yAxis)
            end
            
        end
        
    end

    return cameraCoords

end

function Player:PlayerCameraCoordsAdjustment(cameraCoords)

    -- No adjustment by default. This function can be overridden to modify the camera
    -- coordinates right before rendering.
    return cameraCoords

end

-- Ignore camera shaking when done quickly in a row
function Player:SetCameraShake(amount, speed, time)

    -- Overrides existing shake if it has elapsed or if new shake amount is larger
    local success = false
    
    local currentTime = Shared.GetTime()
    
    if self.cameraShakeLastTime ~= nil and (currentTime > (self.cameraShakeLastTime + .5)) then
    
        if currentTime > self.cameraShakeTime or amount > self.cameraShakeAmount then
        
            self.cameraShakeAmount = amount

            -- "bumps" per second
            self.cameraShakeSpeed = speed 
            
            self.cameraShakeTime = currentTime + time
            
            self.cameraShakeLastTime = currentTime
            
            success = true
            
        end
        
    end
    
    return success
    
end

local clientIsWaitingForAutoTeamBalance = false
function PlayerUI_GetIsWaitingForTeamBalance()
    return clientIsWaitingForAutoTeamBalance
end

local function OnWaitingForAutoTeamBalance(message)
    clientIsWaitingForAutoTeamBalance = message.waiting
end
Client.HookNetworkMessage("WaitingForAutoTeamBalance", OnWaitingForAutoTeamBalance)

function PlayerUI_GetIsRepairing()

    local player = Client.GetLocalPlayer()
    if player then
        return player.timeLastRepaired ~= nil and player.timeLastRepaired + 1 > Shared.GetTime()
    end    
    
    return false
    
end

function PlayerUI_GetIsConstructing()

    local player = Client.GetLocalPlayer()
    if player then
        return player.timeLastConstructed ~= nil and player.timeLastConstructed + 1 > Shared.GetTime()
    end
    
    return false
    
end

-- fetch the oldest notification
function PlayerUI_GetRecentNotification()

    if gDebugNotifications then
        if math.random() < 0.2 then
            return { LocationName = "Test Location" , TechId = math.random(1, 80) }
        end
    end

    local notification
    
    local player = Client.GetLocalPlayer()
    if player and player.GetAndClearNotification then
        notification = player:GetAndClearNotification()
    end

    return notification
end

function PlayerUI_GetIsTechMapVisible()
    return false
end

function PlayerUI_GetHasItem(techId)

    local hasItem = false

    if techId and techId ~= kTechId.None then
    
        local player = Client.GetLocalPlayer()
        if player then
            return player:GetHasUpgrade(techId)       
        end
    
    end
    
    return hasItem

end

local gPreviousTechId = kTechId.None
function PlayerUI_GetRecentPurchaseable()

    local player = Client.GetLocalPlayer()
    if player ~= nil then
        local teamInfo = GetEntitiesForTeam("TeamInfo", player:GetTeamNumber())
        if table.count(teamInfo) > 0 then
        
            local newTechId = teamInfo[1]:GetLatestResearchedTech()
            local playSound = newTechId ~= gPreviousTechId
            
            gPreviousTechId = newTechId
            return newTechId, playSound
            
        end
    end
    return 0, false

end

// returns true/false
function PlayerUI_GetHasMotionTracking()

    local player = Client.GetLocalPlayer()
    local gameInfo = GetGameInfoEntity()
    
    if player.gameStarted then
    
        if gameInfo and gameInfo:GetGameMode() == kGameMode.Classic then
            local techTree = GetTechTree()
            if techTree then
                local mtracking = techTree:GetTechNode(kTechId.MotionTracking)
                if mtracking and mtracking:GetResearched() then
                    return true
                end
                return false
            end
        end
        
        if gameInfo and gameInfo:GetGameMode() == kGameMode.Combat then
            return player:GetHasUpgrade(kTechId.MotionTracking)
        end
        
    end
    
end

-- returns 0 - 3
function PlayerUI_GetArmorLevel(researched)
    local armorLevel = 0
    local player = Client.GetLocalPlayer()
    local gameInfo = GetGameInfoEntity()
    
    if player.gameStarted then
        
        armorLevel = player:GetArmorLevel()
        
        if gameInfo and gameInfo:GetGameMode() == kGameMode.Classic then
        
            local techTree = GetTechTree()
        
            if techTree then
            
                local armor3Node = techTree:GetTechNode(kTechId.Armor3)
                local armor2Node = techTree:GetTechNode(kTechId.Armor2)
                local armor1Node = techTree:GetTechNode(kTechId.Armor1)
                
                if researched then
            
                    if armor3Node and armor3Node:GetResearched() then
                        armorLevel = 3
                    elseif armor2Node and armor2Node:GetResearched()  then
                        armorLevel = 2
                    elseif armor1Node and armor1Node:GetResearched()  then
                        armorLevel = 1
                    end
                
                else
                
                    if armor3Node and armor3Node:GetHasTech() then
                        armorLevel = 3
                    elseif armor2Node and armor2Node:GetHasTech()  then
                        armorLevel = 2
                    elseif armor1Node and armor1Node:GetHasTech()  then
                        armorLevel = 1
                    end
                
                end
                
            end
            
        end
    
    end

    return armorLevel
end

function PlayerUI_GetWeaponLevel(researched)
    local weaponLevel = 0
    local player = Client.GetLocalPlayer()
    local gameInfo = GetGameInfoEntity()
    
    if player.gameStarted then
    
        weaponLevel = player:GetWeaponLevel()
        
        if gameInfo and gameInfo:GetGameMode() == kGameMode.Classic then
    
            local techTree = GetTechTree()
        
            if techTree then
            
                local weapon3Node = techTree:GetTechNode(kTechId.Weapons3)
                local weapon2Node = techTree:GetTechNode(kTechId.Weapons2)
                local weapon1Node = techTree:GetTechNode(kTechId.Weapons1)
            
                if researched then
            
                    if weapon3Node and weapon3Node:GetResearched() then
                        weaponLevel = 3
                    elseif weapon2Node and weapon2Node:GetResearched()  then
                        weaponLevel = 2
                    elseif weapon1Node and weapon1Node:GetResearched()  then
                        weaponLevel = 1
                    end
                
                else
                
                    if weapon3Node and weapon3Node:GetHasTech() then
                        weaponLevel = 3
                    elseif weapon2Node and weapon2Node:GetHasTech()  then
                        weaponLevel = 2
                    elseif weapon1Node and weapon1Node:GetHasTech()  then
                        weaponLevel = 1
                    end
                    
                end
                
            end  
            
        end
        
    end
    
    return weaponLevel
end

function PlayerUI_GetHasWelder()

    local player = Client.GetLocalPlayer()
    if player then    
        return player:GetWeapon(Welder.kMapName) ~= nil    
    end
    
    return false

end

-- Draw the current location on the HUD ("Marine Start", "Processing", etc.)

function PlayerUI_GetLocationName()

    local locationName = ""

    local player = Client.GetLocalPlayer()

    local playerLocation = GetLocationForPoint(player:GetOrigin())

    if player ~= nil and player:GetIsPlaying() then

        if playerLocation ~= nil then

            locationName = playerLocation.name

        elseif playerLocation == nil and locationName ~= nil then

            locationName = player:GetLocationName()

        elseif locationName == nil then

            locationName = ""

        end

    end

    return locationName

end

function PlayerUI_GetOrigin()

    local player = Client.GetLocalPlayer()    
    if player ~= nil then
        return player:GetOrigin()
    end
    
    return Vector(0, 0, 0)
    
end

function PlayerUI_GetPositionOnMinimap()

    local player = Client.GetLocalPlayer()    
    if player ~= nil then
        return player:GetPositionForMinimap()
    end
    
    return Vector(0, 0, 0)

end

function PlayerUI_GetYaw()

    local player = Client.GetLocalPlayer()    
    if player ~= nil then
        return player:GetAngles().yaw
    end
    
    return 0
    
end

function PlayerUI_GetEyePos()

    local player = Client.GetLocalPlayer()    
    if player ~= nil then
        return player:GetEyePos()
    end
    
    return Vector(0, 0, 0)
    
end

function PlayerUI_GetCountDownFraction()

    local player = Client.GetLocalPlayer()
    
    if player and player.GetCountDownFraction then
        return player:GetCountDownFraction()
    end
    
    return 0
    
end

function PlayerUI_GetRemainingCountdown()

    local player = Client.GetLocalPlayer()
    
    if player and player.GetCountDownFraction then
        return player:GetCountDownTime()
    end
    
    return 0
    
end

function PlayerUI_GetIsThirdperson()

    local player = Client.GetLocalPlayer()
    
    if player then
    
        return player:GetIsThirdPerson()
    
    end
    
    return false

end

function PlayerUI_GetIsPlaying()

    local player = Client.GetLocalPlayer()
    
    if player then
        return player:GetIsPlaying()
    end
    
    return false
    
end

function PlayerUI_GetForwardNormal()

    local player = Client.GetLocalPlayer()
    if player ~= nil then
        return player:GetCameraViewCoords().zAxis
    end
    return Vector(0, 0, 1)
    
end

function PlayerUI_IsACommander()

    local player = Client.GetLocalPlayer()
    if player ~= nil then
        return player:isa("Commander")
    end
    
    return false
    
end

function MarineUI_GetWeaponUpgradeTechId()

    local specialTechId = kTechId.None
    
    local player = Client.GetLocalPlayer()
    if player ~= nil then
    
        local weapon = player:GetActiveWeapon()
        if weapon and weapon.GetUpgradeTechId then
            specialTechId = weapon:GetUpgradeTechId()
        end
    
    end
    
    return specialTechId

end

function PlayerUI_IsASpectator()

    local player = Client.GetLocalPlayer()
    if player ~= nil then
        return player:isa("Spectator")
    end
    
    return false
    
end

function PlayerUI_IsOverhead()

    local player = Client.GetLocalPlayer()
    if player ~= nil then
        return player:isa("Commander") or (player:isa("Spectator") and player:GetIsOverhead())
    end
    
    return false
    
end

function PlayerUI_IsOnMarineTeam()

    local player = Client.GetLocalPlayer()
    if player and HasMixin(player, "Team") then
        return player:GetTeamNumber() == kMarineTeamType
    end
    
    return false    
    
end

function PlayerUI_IsOnAlienTeam()

    local player = Client.GetLocalPlayer()
    if player and HasMixin(player, "Team") then
        return player:GetTeamNumber() == kAlienTeamType
    end
    
    return false  
    
end

function PlayerUI_IsAReadyRoomPlayer()

    local player = Client.GetLocalPlayer()
    if player ~= nil then
        return player:GetTeamNumber() == kTeamReadyRoom
    end
    
    return false
    
end

function PlayerUI_GetTeamNumber()

    local player = Client.GetLocalPlayer()
    
    if player and HasMixin(player, "Team") then    
        return player:GetTeamNumber()    
    end
    
    return 0

end

function PlayerUI_GetRequests()

    local player = Client.GetLocalPlayer()
    local requests = {}
    
    if player and player.GetRequests then

        for _, techId in ipairs() do
        
            local name = GetDisplayNameForTechId(techId)
            
            table.insert(requests, { Name = name, TechId = techId } )
        
        end
 
    end
    
    return requests

end

function PlayerUI_GetTimeDamageTaken()

    local player = Client.GetLocalPlayer()
    if player then
    
        if HasMixin(player, "Combat") then
            return player:GetTimeLastDamageTaken()
        end
    
    end
    
    return 0

end

function PlayerUI_GetTeamType()

    local player = Client.GetLocalPlayer()
    
    if player and HasMixin(player, "Team") then    
        return player:GetTeamType()    
    end
    
    return kNeutralTeamType

end

function PlayerUI_GetTeamNumber()

    local player = Client.GetLocalPlayer()
    
    if player and HasMixin(player, "Team") then    
        return player:GetTeamNumber()    
    end
    
    return kTeamReadyRoom

end

function PlayerUI_GetHasGameStarted()

     local player = Client.GetLocalPlayer()
     return player and player:GetGameStarted()
     
end

function PlayerUI_GetTeamColor(teamNumber)

    if teamNumber then
        return ColorIntToColor(GetColorForTeamNumber(teamNumber))
    else
        local player = Client.GetLocalPlayer()
        return ColorIntToColor(GetColorForPlayer(player))
    end
    
end

--[[
 * Returns all locations as a name and origin.
]]
function PlayerUI_GetLocationData()

    local returnData = { }
    local locationEnts = GetLocations()
    for i, location in ipairs(locationEnts) do
        if location:GetShowOnMinimap() then
            table.insert(returnData, { Name = location:GetName(), Origin = location:GetOrigin() })
        end
    end
    return returnData

end

--[[
 * Converts world coordinates into normalized map coordinates.
]]
function PlayerUI_GetMapXY(worldX, worldZ)

    local player = Client.GetLocalPlayer()
    if player then
        local success, mapX, mapY = player:GetMapXY(worldX, worldZ)
        return mapX, mapY
    end
    return 0, 0

end

local kSensorBlipSize = 25

function PlayerUI_GetSensorBlipInfo()

    PROFILE("PlayerUI_GetSensorBlipInfo")
    
    local player = Client.GetLocalPlayer()
    local teamnum = player:GetTeamNumber()
    local blips = {}
    
    if player then
    
        local eyePos = player:GetEyePos()
        for index, blip in ientitylist(Shared.GetEntitiesWithClassname("SensorBlip")) do
        
            local blipOrigin = blip:GetOrigin()
            local blipEntId = blip.entId
            local blipName = ""
            
            // Lookup more recent position of blip
            local blipEntity = Shared.GetEntity(blipEntId)

            // Do not display a blip for the local player.
            if blipEntity ~= player then

                if blipEntity then
                
                    if blipEntity:isa("Player") then
                        blipName = Scoreboard_GetPlayerData(blipEntity:GetClientIndex(), kScoreboardDataIndexName)
                    elseif blipEntity.GetTechId then
                        blipName = GetDisplayNameForTechId(blipEntity:GetTechId())
                    end
                    
                end
                
                if not blipName then
                    blipName = ""
                end
                
                // Get direction to blip. If off-screen, don't render. Bad values are generated if 
                // Client.WorldToScreen is called on a point behind the camera.
                local normToEntityVec = GetNormalizedVector(blipOrigin - eyePos)
                local normViewVec = player:GetViewAngles():GetCoords().zAxis
               
                local dotProduct = normToEntityVec:DotProduct(normViewVec)
                if dotProduct > 0 then
                
                    // Get distance to blip and determine radius
                    local distance = (eyePos - blipOrigin):GetLength()
                    local drawRadius = kSensorBlipSize/distance
                    
                    // Compute screen xy to draw blip
                    local screenPos = Client.WorldToScreen(blipOrigin)

                    local trace = Shared.TraceRay(eyePos, blipOrigin, CollisionRep.LOS, PhysicsMask.Bullets, EntityFilterTwo(player, entity))                               
                    local obstructed = ((trace.fraction ~= 1) and ((trace.entity == nil) or trace.entity:isa("Door"))) 
                    
                    if not obstructed and entity and not entity:GetIsVisible() then
                        obstructed = true
                    end
                    
                    // Add to array (update numElementsPerBlip in GUISensorBlips:UpdateBlipList)
                    table.insert(blips, screenPos.x)
                    table.insert(blips, screenPos.y)
                    table.insert(blips, drawRadius)
                    table.insert(blips, obstructed)
                    table.insert(blips, blipName)

                end
                
            end
            
        end
    end
    
    return blips
    
end

--[[
 * Returns a linear array of static blip data
 * X position, Y position, rotation, X texture offset, Y texture offset, kMinimapBlipType, kMinimapBlipTeam
 *
 * Eg { 0.5, 0.5, 1.32, 0, 0, 3, 1 }
]]
local kMinimapBlipTeamAlien = kMinimapBlipTeam.Alien
local kMinimapBlipTeamMarine = kMinimapBlipTeam.Marine
local kMinimapBlipTeamFriendAlien = kMinimapBlipTeam.FriendAlien
local kMinimapBlipTeamFriendMarine = kMinimapBlipTeam.FriendMarine
local kMinimapBlipTeamInactiveAlien = kMinimapBlipTeam.InactiveAlien
local kMinimapBlipTeamInactiveMarine = kMinimapBlipTeam.InactiveMarine
local kMinimapBlipTeamFriendly = kMinimapBlipTeam.Friendly
local kMinimapBlipTeamEnemy = kMinimapBlipTeam.Enemy
local kMinimapBlipTeamNeutral = kMinimapBlipTeam.Neutral
function PlayerUI_GetStaticMapBlips()

    PROFILE("PlayerUI_GetStaticMapBlips")
    
    local player = Client.GetLocalPlayer()
    local blipsData = { }
    local numBlips = 0
    
    if player then
    
        local playerTeam = player:GetTeamNumber()
        local playerNoTeam = playerTeam == kRandomTeamType or playerTeam == kNeutralTeamType
        local playerEnemyTeam = GetEnemyTeamNumber(playerTeam)
        local playerId = player:GetId()
        
        local mapBlipList = Shared.GetEntitiesWithClassname("MapBlip")
        local GetEntityAtIndex = mapBlipList.GetEntityAtIndex
        local GetMapBlipTeamNumber = MapBlip.GetTeamNumber
        local GetMapBlipOrigin = MapBlip.GetOrigin
        local GetMapBlipRotation = MapBlip.GetRotation
        local GetMapBlipType = MapBlip.GetType
        local GetMapBlipIsInCombat = MapBlip.GetIsInCombat
        local GetMapBlipIsParasited = MapBlip.GetIsParasited
        local GetIsSteamFriend = Client.GetIsSteamFriend
        local ClientIndexToSteamId = GetSteamIdForClientIndex
        local GetIsMapBlipActive = MapBlip.GetIsActive
        
        for index = 0, mapBlipList:GetSize() - 1 do
        
            local blip = GetEntityAtIndex(mapBlipList, index)
            if blip ~= nil and blip.ownerEntityId ~= playerId then
      
                local blipTeam = kMinimapBlipTeamNeutral
                local blipTeamNumber = GetMapBlipTeamNumber(blip)
                local isSteamFriend = false
                local clientIndex = 0
                
                if blip.clientIndex and blip.clientIndex > 0 and blipTeamNumber ~= GetEnemyTeamNumber(playerTeam) then

                    local steamId = ClientIndexToSteamId(blip.clientIndex)
                    if steamId then
                        isSteamFriend = GetIsSteamFriend(steamId)
                    end
                    
                    clientIndex = blip.clientIndex

                end
                
                if not GetIsMapBlipActive(blip) then

                    if blipTeamNumber == kMarineTeamType then
                        blipTeam = kMinimapBlipTeamInactiveMarine
                    elseif blipTeamNumber== kAlienTeamType then
                        blipTeam = kMinimapBlipTeamInactiveAlien
                    end

                elseif isSteamFriend then
                
                    if blipTeamNumber == kMarineTeamType then
                        blipTeam = kMinimapBlipTeamFriendMarine
                    elseif blipTeamNumber== kAlienTeamType then
                        blipTeam = kMinimapBlipTeamFriendAlien
                    end
                
                else

                    if blipTeamNumber == kMarineTeamType then
                        blipTeam = kMinimapBlipTeamMarine
                    elseif blipTeamNumber== kAlienTeamType then
                        blipTeam = kMinimapBlipTeamAlien
                    end
                    
                end  
                
                local i = numBlips * 10
                local blipOrig = GetMapBlipOrigin(blip)
                blipsData[i + 1] = blipOrig.x
                blipsData[i + 2] = blipOrig.z
                blipsData[i + 3] = GetMapBlipRotation(blip)
                blipsData[i + 4] = clientIndex
                blipsData[i + 5] = GetMapBlipIsParasited(blip)
                blipsData[i + 6] = GetMapBlipType(blip)
                blipsData[i + 7] = blipTeam
                blipsData[i + 8] = GetMapBlipIsInCombat(blip)
                blipsData[i + 9] = isSteamFriend
                blipsData[i + 10] = blip.isHallucination == true
                
                numBlips = numBlips + 1
                
            end
            
        end
        
        for index, blip in ientitylist(Shared.GetEntitiesWithClassname("SensorBlip")) do
        
            local blipOrigin = blip:GetOrigin()
            
            local i = numBlips * 10
            
            blipsData[i + 1] = blipOrigin.x
            blipsData[i + 2] = blipOrigin.z
            blipsData[i + 3] = 0
            blipsData[i + 4] = 0
            blipsData[i + 5] = 0
            blipsData[i + 6] = kMinimapBlipType.SensorBlip
            blipsData[i + 7] = kMinimapBlipTeamEnemy
            blipsData[i + 8] = false
            blipsData[i + 9] = false
            blipsData[i + 10] = false
            
            numBlips = numBlips + 1
            
        end
        
        local orders = GetRelevantOrdersForPlayer(player)
        for o = 1, #orders do
        
            local order = orders[o]
            local blipOrigin = order:GetLocation()
            
            local blipType = kMinimapBlipType.MoveOrder
            local orderType = order:GetType()
            if orderType == kTechId.Construct or orderType == kTechId.AutoConstruct then
                blipType = kMinimapBlipType.BuildOrder
            elseif orderType == kTechId.Attack then
                blipType = kMinimapBlipType.AttackOrder
            end
            
            local i = numBlips * 10
            
            blipsData[i + 1] = blipOrigin.x
            blipsData[i + 2] = blipOrigin.z
            blipsData[i + 3] = 0
            blipsData[i + 4] = 0
            blipsData[i + 5] = 0
            blipsData[i + 6] = blipType
            blipsData[i + 7] = kMinimapBlipTeamFriendly
            blipsData[i + 8] = false
            blipsData[i + 9] = false
            blipsData[i + 10] = false
            
            numBlips = numBlips + 1
            
        end
        
        local highlightPos = GetHighlightPosition()
        if highlightPos then

                local i = numBlips * 10

                blipsData[i + 1] = highlightPos.x
                blipsData[i + 2] = highlightPos.z
                blipsData[i + 3] = 0
                blipsData[i + 4] = 0
                blipsData[i + 5] = 0
                blipsData[i + 6] = kMinimapBlipType.HighlightWorld
                blipsData[i + 7] = kMinimapBlipTeam.Friendly
                blipsData[i + 8] = false
                blipsData[i + 9] = false
                blipsData[i + 10] = false
                
                numBlips = numBlips + 1
            
        end
        
    end

    return blipsData
    
end

local gLastUnitCountUpdate = 0
local gUnitCount = {}
function PlayerUI_GetUnitCount(name)

    if gLastUnitCountUpdate < Shared.GetTime() then
    
        gUnitCount = {}
        
        for _, mapBlip in ientitylist(Shared.GetEntitiesWithClassname("MapBlip")) do
        
            local mapBlipType = EnumToString(kMinimapBlipType, mapBlip:GetType())
            if not gUnitCount[mapBlipType] then
                gUnitCount[mapBlipType] = 1
            else
                gUnitCount[mapBlipType] = gUnitCount[mapBlipType] + 1
            end
        
        end
    
        gLastUnitCountUpdate = Shared.GetTime()
    
    end
    
    return gUnitCount[name] or 0

end

--[[
 * Damage indicators. Returns a array of damage indicators which are used to draw red arrows pointing towards
 * recent damage. Each damage indicator pair will consist of an alpha and a direction. The alpha is 0-1 and the
 * direction in radians is the angle at which to display it. 0 should face forward (top of the screen), pi 
 * should be behind us (bottom of the screen), pi/2 is to our left, 3*pi/2 is right.
 * 
 * For two damage indicators, perhaps:
 *  {alpha1, directionRadians1, alpha2, directonRadius2}
 *
 * It returns an empty table if the player has taken no damage recently. 
]]
function PlayerUI_GetDamageIndicators()

    local drawIndicators = {}
    
    local player = Client.GetLocalPlayer()
    if player then
    
        for index, indicatorTriple in ipairs(player.damageIndicators) do
            
            local alpha = Clamp(1 - ((Shared.GetTime() - indicatorTriple[3]) / kDamageIndicatorDrawTime), 0, 1)
            table.insert(drawIndicators, alpha)

            local worldX = indicatorTriple[1]
            local worldZ = indicatorTriple[2]
            
            local normDirToDamage = GetNormalizedVector(Vector(player:GetOrigin().x, 0, player:GetOrigin().z) - Vector(worldX, 0, worldZ))
            local worldToView = player:GetViewAngles():GetCoords():GetInverse()
            
            local damageDirInView = worldToView:TransformVector(normDirToDamage)
            
            local directionRadians = math.atan2(damageDirInView.x, damageDirInView.z)
            if directionRadians < 0 then
                directionRadians = directionRadians + 2 * math.pi
            end
            
            table.insert(drawIndicators, directionRadians)
            
        end
        
    end
    
    return drawIndicators
    
end

-- Displays an image around the crosshair when the local player has given damage to something else.
-- Returns true if the indicator should be displayed and the time that has passed as a percentage.
function PlayerUI_GetShowGiveDamageIndicator()

    local player = Client.GetLocalPlayer()
    if player and player.GetDamageIndicatorTime and player:GetIsPlaying() then
    
        local timePassed = Shared.GetTime() - player:GetDamageIndicatorTime()
        return timePassed <= kShowGiveDamageTime, math.min(timePassed / kShowGiveDamageTime, 1)
        
    end
    
    return false, 0
    
end

function PlayerUI_GetGameMode()

    local gameInfo = GetGameInfoEntity()
    if gameInfo then
        return gameInfo:GetGameMode()
    end
    return kGameMode.Classic
    
end

function PlayerUI_GetCurrentLevel()

    local player = Client.GetLocalPlayer()
    if player then
        return player:GetPlayerCombatLevel()
    end
    return 1
    
end

function PlayerUI_GetCurrentXP()

    local player = Client.GetLocalPlayer()
    if player then
        return player:GetPlayerExperience()
    end
    return 0
    
end

function PlayerUI_GetNextLevelXP()

    local player = Client.GetLocalPlayer()
    local gameInfo = GetGameInfoEntity()
    if player and gameInfo then
        local nLevel = player:GetPlayerCombatLevel() + 1
        if nLevel > gameInfo:GetCombatMaxLevel() then
            return 0
        end
        return CalculateLevelXP(nLevel)
    end
    return 0
    
end

function PlayerUI_GetCurrentLevelBaseXP()

    local player = Client.GetLocalPlayer()
    if player then
        return CalculateLevelXP(player:GetPlayerCombatLevel())
    end
    return 0
    
end

local kEggDisplayRange = 30
local kEggDisplayOffset = Vector(0, 0.8, 0)
function PlayerUI_GetEggDisplayInfo()

    local eggDisplay = {}
    
    local player = Client.GetLocalPlayer()
    local animOffset = kEggDisplayOffset + kEggDisplayOffset * math.sin(Shared.GetTime() * 3) * 0.2
    
    if player then
    
        local eyePos = player:GetEyePos()
        for index, egg in ipairs(GetEntitiesWithinRange("Egg", player:GetEyePos(), kEggDisplayRange)) do
        
            local techId = egg:GetGestateTechId()
            
            if techId and (techId == kTechId.Gorge or techId == kTechId.Lerk or techId == kTechId.Fade or techId == kTechId.Onos) then
            
                local normToEntityVec = GetNormalizedVector(egg:GetOrigin() - eyePos)
                local normViewVec = player:GetViewAngles():GetCoords().zAxis
               
                local dotProduct = normToEntityVec:DotProduct(normViewVec)
                
                if dotProduct > 0 then                
                    table.insert(eggDisplay, { Position = Client.WorldToScreen(egg:GetOrigin() + animOffset), TechId = techId } )                
                end
            
            end
        
        end
        
        if PlayerUI_IsOverhead() then
        
            for index, egg in ipairs(GetEntitiesWithinRange("Embryo", player:GetEyePos(), kEggDisplayRange)) do
            
                local techId = egg:GetGestationTechId()

                local normToEntityVec = GetNormalizedVector(egg:GetOrigin() - eyePos)
                local normViewVec = player:GetViewAngles():GetCoords().zAxis
               
                local dotProduct = normToEntityVec:DotProduct(normViewVec)
                
                if dotProduct > 0 then                
                    table.insert(eggDisplay, { Position = Client.WorldToScreen(egg:GetOrigin() + animOffset), TechId = techId } )                
                end
            
            end
        
        end
        
    end
    
    return eggDisplay

end

local function GetDamageEffectType(self)

    if self:isa("Marine") then
        return kDamageEffectType.Blood
    elseif self:isa("Alien") then
        return kDamageEffectType.AlienBlood
    elseif self:isa("Exo") then
        return kDamageEffectType.Sparks
    end

end

function Player:GetShowDamageArrows()
    return true
end

local function TriggerFirstPersonDeathEffects(self)

    local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
    cinematic:SetCinematic(self:GetFirstPersonDeathEffect())
    
end

function Player:AddTakeDamageIndicator(damagePosition)

    if self:GetShowDamageArrows() then
        table.insert(self.damageIndicators, { damagePosition.x, damagePosition.z, Shared.GetTime() })
    end
    
    if not self:GetIsAlive() and not self.deathTriggered then
    
        TriggerFirstPersonDeathEffects(self)
        self.deathTriggered = true
        
    end
    
    local damageIndicatorScript = ClientUI.GetScript("GUIDamageIndicators")
    local hitEffectType = GetDamageEffectType(self)
    
    if damageIndicatorScript and hitEffectType then
    
        local position = Vector(0, 0, 0)
        local viewCoords = self:GetViewCoords()
        
        local hitDirection = GetNormalizedVector( viewCoords.origin - damagePosition )
        position.x = viewCoords.xAxis:DotProduct(hitDirection)
        position.y = viewCoords.zAxis:DotProduct(hitDirection)
        
        if position:GetLength() > 0 then
        
            position:Normalize()
            position:Scale(0.95)
            
            local screenPos = Vector()
            
            screenPos.y = position.y * Client.GetScreenHeight() *.5 + Client.GetScreenHeight() *.5
            screenPos.x = position.x * Client.GetScreenWidth() * .5 + Client.GetScreenWidth() * .5
            
            local rotation = math.atan2(position.x, position.y) + .5 * math.pi
            if rotation < 0 then
                rotation = rotation + 2 * math.pi
            end
            
            damageIndicatorScript:OnTakeDamage(screenPos, rotation, hitEffectType)
        
        end
        
    end
    
end

-- child classes can override this
function Player:GetShowDamageIndicator()

    local weapon = self:GetActiveWeapon()
    if weapon then
        return weapon:GetShowDamageIndicator()
    end    
    return true
    
end

-- child classes should override this
function Player:OnGiveDamage()
end

function Player:UpdateDamageIndicators()

    local indicesToRemove = {}
    
    -- Expire old damage indicators
    for index, indicatorTriple in ipairs(self.damageIndicators) do
    
        if Shared.GetTime() > (indicatorTriple[3] + kDamageIndicatorDrawTime) then
        
            table.insert(indicesToRemove, index)
            
        end
        
    end
    
    for i, index in ipairs(indicesToRemove) do
        table.remove(self.damageIndicators, index)
    end
    
    -- update damage given
    if self.giveDamageTimeClientCheck ~= self.giveDamageTime then
    
        self.giveDamageTimeClientCheck = self.giveDamageTime
        -- Must factor in ping time as this value is delayed.
        self.giveDamageTimeClient = self.giveDamageTime + Client.GetPing()
        self.showDamage = self:GetShowDamageIndicator()
        if self.showDamage then
            self:OnGiveDamage()
        end
        
    end
    
end

    
function Player:UpdateDeadSound()
end

function Player:GetDamageIndicatorTime()

    if self.showDamage then
        return self.giveDamageTimeClient
    end
    
    return 0
    
end

-- Set after hotgroup updated over the network
function Player:SetHotgroup(number, entityList)

    Print("Player:SetHotgroup")
    
end

function Player:OnLocationIdChange()
    PROFILE("Player:OnLocationIdChange")
    self:OnLocationChange(Shared.GetString(self.locationId))     
    return true
end

function Player:OnUpdatePlayer(deltaTime)

    PROFILE("Player:OnUpdatePlayer:UpdateClientEffects")

    self:UpdateClientEffects(deltaTime, self:GetIsLocalPlayer())

    self:UpdateCommunicationStatus()
    
    if self.isHallucination then
        self:DestroyController()
    end    
    
end

function Player:UpdateCommunicationStatus()

    if self:GetIsLocalPlayer() then

        local time = Client.GetTime()
        
        if self.timeLastCommStatusUpdate == nil or (time > self.timeLastCommStatusUpdate + 0.5) then
        
            local newCommStatus = kPlayerCommunicationStatus.None

            -- If voice comm being used
            if Client.GetVoiceChannelForRecording() ~= VoiceChannel.Invalid then
                newCommStatus = kPlayerCommunicationStatus.Voice
            -- If we're typing
            elseif ChatUI_EnteringChatMessage() then
                newCommStatus = kPlayerCommunicationStatus.Typing
            -- In menu
            elseif MainMenu_GetIsOpened() then
                newCommStatus = kPlayerCommunicationStatus.Menu
            end
            
            if newCommStatus ~= self:GetCommunicationStatus() then
            
                Client.SendNetworkMessage("SetCommunicationStatus", BuildCommunicationStatus(newCommStatus), true)
                self:SetCommunicationStatus(newCommStatus)
                
            end
        
            self.timeLastCommStatusUpdate = time
            
        end
        
    end
    
end

function Player:OnGetIsVisible(visibleTable)

    visibleTable.Visible = self:GetDrawWorld()
    
    if not self:GetIsAlive() and not HasMixin(self, "Ragdoll") then
        visibleTable.Visible = false
    end
    
end

function Player:OnUpdateRender()

    PROFILE("Player:OnUpdateRender")
    
    if self:GetIsLocalPlayer() then
    
        local stunned = HasMixin(self, "Stun") and self:GetIsStunned()
        local blurEnabled = self.buyMenu ~= nil or stunned
        self:SetBlurEnabled(blurEnabled)
        
        self.lastOnUpdateRenderTime = self.lastOnUpdateRenderTime or Shared.GetTime()
        local now = Shared.GetTime()
        self:UpdateScreenEffects(now - self.lastOnUpdateRenderTime)
        self.lastOnUpdateRenderTime = now
        
    end
    
end

function Player:GetCustomSelectionText()

    local playerRecord = Scoreboard_GetPlayerRecord(self:GetClientIndex())
    if playerRecord then  
  
        return string.format("%s kills\n%s deaths\n%s score",
                ToString(playerRecord.Kills),
                ToString(playerRecord.Deaths),
                ToString(playerRecord.Score))

    end
            
end

-- Set light shake amount due to nearby roaming Onos
function Player:SetLightShakeAmount(amount, duration, scalar)

    if scalar == nil then
        scalar = 1
    end
    
    -- So lights start moving in time with footsteps
    self:ResetShakingLights()

    self.lightShakeAmount = Clamp(amount, 0, 1)
    
    -- Save off original amount so we can have it fall off nicely
    self.savedLightShakeAmount = self.lightShakeAmount
    
    self.lightShakeEndTime = Shared.GetTime() + duration
    
    self.lightShakeScalar = scalar
    
end

function Player:GetFirstPersonDeathEffect()
    return kFirstPersonDeathEffect
end

local function GetFirstPersonHitEffectName(doer)

    local effectName = kDefaultFirstPersonEffectName
    
    local player = Client.GetLocalPlayer()
    
    if player and player.GetFirstPersonHitEffectName then    
        effectName = player:GetFirstPersonHitEffectName(doer)    
    end
    
    return effectName

end

--[[
 * This is called from BaseModelMixin. This will force all player animations to process so we
 * get animation tags on the Client for other player models. These tags are needed to trigger
 * footstep sound effects.
]]
/*
function Player:GetClientSideAnimationEnabled()
    return true
end
*/

function Player:GetShowAtmosphericLight()
    return true
end
