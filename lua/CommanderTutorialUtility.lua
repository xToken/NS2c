// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommanderTutorialUtility.lua
//
// Created by: Andreas Urwalek (and@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kTimeOutBetweenTips = 3.5

local gCurrentIndex = nil

local gStepStartTime = 0
local gEntryStartTime = 0

local gHighlightButtonTechId = nil
local gPosition = nil
local gHighlightCinematic = nil
local kHighlightCinematicName = PrecacheAsset("cinematics/hightlightworld.cinematic")

local gTimeNextEntry = 0

local gActiveEntry = nil
local gNextForcedName = nil

local kStartSound = "sound/NS2.fev/common/tooltip_on"
local kStepSound = "sound/NS2.fev/common/tooltip_on"
local kCompleteSound = "sound/NS2.fev/common/tooltip_off"
Client.PrecacheLocalSound(kStepSound)
Client.PrecacheLocalSound(kCompleteSound)

local function CommanderTutorial_OnEntryStart(teamType)
    StartSoundEffect(kStartSound)
end

local function CommanderTutorial_OnStepCompleted(teamType, entryNum, stepNum)
    StartSoundEffect(kStepSound)
end

local function CommanderTutorial_OnEntryCompleted(teamType, entryNum)
    StartSoundEffect(kCompleteSound)
end

function CommanderHelp_GetShowTutorial()

    local commander = Client.GetLocalPlayer()
    local showTutorial = false
    
    if commander and commander:isa("Commander") and commander:GetGameStarted() then    
        showTutorial = Client.GetOptionBoolean( "commanderHelp", true )
    end
    
    return showTutorial 

end

function HighlightButton(techId)
    gHighlightButtonTechId = techId
end

function GetHighlightButtonTechId()
    return gHighlightButtonTechId
end

function GetHighlightPosition()
    return gPosition, gTimePositionChanged
end

function HighlightPosition(position, reuseCurrent)

    if not reuseCurrent and gHighlightCinematic then
    
        Client.DestroyCinematic(gHighlightCinematic)
        gHighlightCinematic = nil
        
    end    

    gPosition = position ~= nil and Vector(position) or nil
    
    if not reuseCurrent then    
        gTimePositionChanged = Shared.GetTime()
    end
    
    if position ~= nil then

        if not gHighlightCinematic then
        
            gHighlightCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
            gHighlightCinematic:SetCinematic(kHighlightCinematicName)
            gHighlightCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
            
        end
        
        gHighlightCinematic:SetCoords(Coords.GetTranslation(gPosition))
        
    end

end

local gCommanderTutorialEntries = {}
function AddCommanderTutorialEntry(cost, teamType, text, steps, anchorPoint, allowedFunc, name, forceNextName, minDuration)

    if not gCommanderTutorialEntries[teamType] then
        gCommanderTutorialEntries[teamType] = {}
    end
    
    table.insert(gCommanderTutorialEntries[teamType], {Index = #gCommanderTutorialEntries[teamType] + 1, Cost = cost, Name = name, MinDuration = minDuration, ForceNextName = forceNextName, Text = text, Steps = steps, ActiveStep = 1, AnchorPoint = anchorPoint, Completed = false, AllowedFunc = allowedFunc})

end

local function GetTeamResources()

    local res = 0
    
    local player = Client.GetLocalPlayer()
    if player then
        local teamInfoEnt = GetTeamInfoEntity(player:GetTeamNumber())
        if teamInfoEnt then
            res = teamInfoEnt:GetTeamResources()
        end
    end
    
    return res

end

local function GetEntryAllowed(entry, teamRes)

    if (not gNextForcedName or entry.Name == gNextForcedName) and not entry.Completed and (not entry.Cost or (entry.Cost <= teamRes)) then
           
        if entry.AllowedFunc then
            
            if type(entry.AllowedFunc) == "table" then
            
                for i = 1, #entry.AllowedFunc do
                    if not entry.AllowedFunc[i]() then
                        return false
                    end    
                end
                
                return true
                
            else
                return entry.AllowedFunc()
            end    
            
        else
            return true
        end
    
    end       
     
    return false
    
end

function CommanderTutorial_GetEntry(teamType)

    local entries = gCommanderTutorialEntries[teamType]
    local entry = nil
    local teamRes = GetTeamResources()
    
    if gTimeNextEntry < Shared.GetTime() and entries then
    
        if gCurrentIndex then
        
            local currentEntry = entries[gCurrentIndex]
            if GetEntryAllowed(currentEntry, teamRes) or (currentEntry.MinDuration and gEntryStartTime + currentEntry.MinDuration <= Shared.GetTime()) then
                entry = currentEntry
            else
                gCurrentIndex = nil
            end
            
        end   

        if not entry then 
    
            for i = 1, #entries do

                local checkEntry = entries[i]
                if GetEntryAllowed(checkEntry, teamRes) then
                
                    entry = checkEntry
                    break
                    
                end
                
            end
        
        end
    
    end
    
    if entry then
        gCurrentIndex = entry.Index
    end
    
    gActiveEntry = entry  
    return entry

end

local gLastIndex = 0
function CommanderTutorial_UpdateCurrent(teamType)

    local completed = false
    local entry = gActiveEntry
    
    if entry then

        if gLastIndex ~= entry.Index then

            CommanderTutorial_OnEntryStart(teamType)
            gLastIndex = entry.Index
            gEntryStartTime = Shared.GetTime()
            gStepStartTime = Shared.GetTime()
            entry.ActiveStep = 1
            entry.StoredAnchorPoint = nil
        
        end
        
        if not entry.StoredAnchorPoint then
        
            entry.StoredAnchorPoint = entry.AnchorPoint
            if type(entry.AnchorPoint) == "function" then
                entry.StoredAnchorPoint = entry.AnchorPoint()
            end
            
        end
        
        local step = entry.Steps[entry.ActiveStep]
        
        if step.UpdateHighlightWorld then
        
            local position = step.UpdateHighlightWorld()
            HighlightPosition(position, true)
        
        elseif step.HighlightWorld then
        
            if not step.Highlighted then
        
                local position = step.HighlightWorld()

                if position then  
      
                    HighlightPosition(position)                    
                    step.Highlighted = true
                    
                end
            
            end
            
        else
            HighlightPosition(nil)
        end
        
        if step.HighlightButton then
            HighlightButton(step.HighlightButton)
        else
            HighlightButton(nil)
        end

        if step.CompletionFunc() then
        
            entry.ActiveStep = entry.ActiveStep + 1
            gStepStartTime = Shared.GetTime()

            if entry.ActiveStep > #entry.Steps then
            
                CommanderTutorial_OnEntryCompleted(teamType, entry.Index)
                
                entry.Completed = true
                entry.ActiveStep = 1
                entry.StoredAnchorPoint = nil
                gActiveEntry = nil
                gTimeNextEntry = Shared.GetTime() + kTimeOutBetweenTips
                completed = true
                gCurrentIndex = nil
                
                HighlightButton(nil)
                HighlightPosition(nil)
                
                gNextForcedName = entry.ForceNextName
                if entry.ForceNextName and type(entry.ForceNextName) == "function" then
                    gNextForcedName = entry.ForceNextName()
                end
                
            else
                CommanderTutorial_OnStepCompleted(teamType, entry.Index, entry.ActiveStep - 1)
            end                
        
        end
    
    end
    
    return completed 
    
end

// utility function for defining tutorial entries

function GetHasMenuSelected(techId)
    return function() 

        local player = Client.GetLocalPlayer()
        if player then
            return player.menuTechId == techId
        end
        
        return false
    
    end
end

function GetHasTechUsed(techId)
    return function ()

        local player = Client.GetLocalPlayer()
        if player and player.PollLastUsedTech then
        
            local lastUsedTech = player:PollLastUsedTech()
        
            if type(techId) == "table" then
            
                for i = 1, #techId do
                    if lastUsedTech == techId[i] then
                        return true
                    end    
                end
            
            else        
                return lastUsedTech == techId
            end
            
        end

        return false

    end
end

function GetHasStructureAt(techId, location)

    return function()
    
        local point = location
        if type(location) == "function" then
            point = location()
        end
        
        if point then
        
            local entsNearPoint = GetEntitiesWithMixinWithinRange("Tech", point, 5)
            for i = 1, #entsNearPoint do
            
                local entity = entsNearPoint[i]
                if entity:GetTechId() == techId then
                    return true
                end
                
            end
            
        end
        
        return false
        
    end
    
end

function GetHasPointInfested(location)

    return function()
    
        local point = location
        if type(location) == "function" then
            point = location()
        end
        
        if point then
            return GetIsPointOnInfestation(point)
        end
        
    end
    
end

function GetUnitPosition(techId)

    return function()
    
        local player = Client.GetLocalPlayer()
     
        if player then
        
            local units = GetEntitiesWithMixinForTeam("Tech", player:GetTeamNumber())
            for i = 1, #units do
            
                if units[i]:GetTechId() == techId then
                    return units[i]:GetOrigin()
                end
            
            end
     
        end
    
    end

end

function GetClosestUnbuiltStructurePosition(techId)

    return function ()

        local player = Client.GetLocalPlayer()
        if player then
        
            local entities = GetEntitiesWithMixinForTeamWithinRange("Construct", player:GetTeamNumber(), player:GetOrigin(), 150)
            Shared.SortEntitiesByDistance(player:GetOrigin(), entities)
        
            for i = 1, #entities do
            
                local structure = entities[i]
                if not structure:GetIsBuilt() and ( not techId or (HasMixin(structure, "Tech") and structure:GetTechId() == techId) ) then
                    return structure:GetOrigin()
                end
            
            end
        
        end
    
    end

end

function GetCommandStructureOrigin()

    local startPoint = nil

    local player = Client.GetLocalPlayer()
    if player then
    
        local commStructure = GetEntitiesForTeam("CommandStructure", player:GetTeamNumber())
        if commStructure and #commStructure > 0 then
            startPoint = commStructure[1]:GetOrigin()
        end
        
    end
    
    return startPoint
    
end

function GetClosestFreeTechPoint()

    local player = Client.GetLocalPlayer()
    if player then
    
        local startPoint = nil
    
        local commStructure = GetEntitiesForTeam("CommandStructure", player:GetTeamNumber())
        if commStructure and #commStructure > 0 then
            startPoint = commStructure[1]:GetOrigin() 
        end
        
        local closestDistance = 10000
        local closestPoint = nil 
        
        if startPoint then

            local resourcePoints = GetEntitiesWithinRange("TechPoint", startPoint, 1000)
            Shared.SortEntitiesByDistance(startPoint, resourcePoints)

            for i = 1, #resourcePoints do
            
                local resPoint = resourcePoints[i]
                
                if resPoint.attachedId == Entity.invalidId then
                
                    local distance = GetPathDistance(startPoint, resPoint:GetOrigin())
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPoint = resPoint:GetOrigin()
                    elseif distance > closestDistance + 5 then
                        break
                    end
                
                end
            
            end
        
        end
        
        return closestPoint
    
    end
    
end

function GetClosestFreeResourcePoint()

    local player = Client.GetLocalPlayer()
    if player then
    
        local startPoint = nil
    
        local commStructure = GetEntitiesForTeam("CommandStructure", player:GetTeamNumber())
        if commStructure and #commStructure > 0 then
            startPoint = commStructure[1]:GetOrigin() 
        end
        
        local closestDistance = 10000
        local closestPoint = nil 
        
        if startPoint then

            local resourcePoints = GetEntitiesWithinRange("ResourcePoint", startPoint, 100)
            Shared.SortEntitiesByDistance(startPoint, resourcePoints)   

            for i = 1, #resourcePoints do
            
                local resPoint = resourcePoints[i]
                
                if resPoint.attachedId == Entity.invalidId then
                
                    local distance = GetPathDistance(startPoint, resPoint:GetOrigin())
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPoint = resPoint:GetOrigin()
                    elseif distance > closestDistance + 5 then
                        break
                    end
                
                end
            
            end
        
        end
        
        return closestPoint
    
    end

end

function GetPlaceForUnit(techId, location, filter)

    return function()
    
        local point = location
        
        if type(location) == "function" then
            point = location()
        end
        
        local validPoint = nil
        if point then
        
            local extents = GetExtents(techId)
            validPoint = GetRandomSpawnForCapsule(extents.y, extents.x, point, 5, 25, EntityFilterAll(), filter)
            
        end
        
        return validPoint
        
    end
    
end

function CommanderTutorial_ResetAll()

    for teamNum, entries in pairs(gCommanderTutorialEntries) do
    
        for i = 1, #entries do
    
            local entry = entries[i]
            entry.ActiveStep = 1
            entry.Completed = false
            entry.StoredAnchorPoint = nil
            
            for j = 1, #entry.Steps do            
                entry.Steps[j].Highlighted = false
        
            end
    
        end
    
    end
    
    Print("commander tutorial resetted")

end

function GetPointBetween(startPoint, endPoint)

    return function()
    
        local startPos = startPoint
        if type(startPoint) == "function" then
            startPos = startPoint()
        end
        
        local endPos = endPoint
        if type(endPoint) == "function" then
            endPos = endPoint()
        end
        
        if not startPos or not endPos then
            return nil
        end
        
        local path = PointArray()
        local reachAble = Pathing.GetPathPoints(startPos, endPos, path)
        local centerPoint = nil
        
        if reachAble then
        
            local pathLength = GetPointDistance(path)
            local currentDistance = 0
            local prevPoint = path[1]
            centerPoint = path[#path]
            
            if #path > 2 then
            
                for i = 2, #path do
                
                    currentDistance = currentDistance + (prevPoint - path[i]):GetLength()
                    prevPoint = path[i]
                    
                    if currentDistance >= pathLength * 0.5 then
                    
                        centerPoint = path[i]
                        break
                        
                    end
                    
                end
                
            end
            
        end
        
        return centerPoint
        
    end
    
end

function GetAnchorPoint()

    if gActiveEntry then
        return gActiveEntry.StoredAnchorPoint
    end

end

function GetHasUnitSelected(techId)

    return function()

        local player = Client.GetLocalPlayer()
        if player and player:isa("Commander") then
        
            local selection = player:GetSelection()
            for i = 1, #selection do
                local entity = selection[i]
                if HasMixin(entity, "Tech") and entity:GetTechId() == techId then
                    return true
                end    
            end
        
        end
        
        return false
    
    end

end

function GetHasClassSelected(className)

    return function()

        local player = Client.GetLocalPlayer()
        if player and player:isa("Commander") then
        
            local selection = player:GetSelection()
            for i = 1, #selection do
                local entity = selection[i]
                if entity:isa(className) then
                    return true
                end    
            end
        
        end
        
        return false
    
    end

end

function GetHasClass(className)

    return function()

        local player = Client.GetLocalPlayer()
        if player then
        
            local units = GetEntitiesForTeam(className, player:GetTeamNumber())
            return #units > 0
        
        end
        
        return false
    
    end

end

function GetHasUnit(techId)

    return function()

        local player = Client.GetLocalPlayer()
        if player and player:isa("Commander") then
        
            local units = GetEntitiesWithMixinForTeam("Tech", player:GetTeamNumber())
            for i = 1, #units do
                local entity = units[i]
                if GetIsUnitActive(entity) and entity:GetTechId() == techId then
                    return true
                end    
            end
        
        end
        
        return false
    
    end

end

function GetHasUnitIsNotResearching(techId)

    return function()

        local player = Client.GetLocalPlayer()
        if player and player:isa("Commander") then
        
            local units = GetEntitiesWithMixinForTeam("Tech", player:GetTeamNumber())
            for i = 1, #units do
                local entity = units[i]
                if GetIsUnitActive(entity) and entity:GetTechId() == techId and (not HasMixin(entity, "Research") or not entity:GetIsResearching()) then
                    return true
                end    
            end
        
        end
        
        return false
    
    end

end

function NotHasUnit(techId)

    return function()

        local player = Client.GetLocalPlayer()
        if player and player:isa("Commander") then
        
            local units = GetEntitiesWithMixinForTeam("Tech", self:GetTeamNumber())
            for i = 1, #units do
                local entity = units[i]
                if GetIsUnitActive(entity) and entity:GetTechId() == techId then
                    return false
                end    
            end
        
        end
        
        return true
    
    end
    
end

function GetSelectionHasOrder(techId, targetTechId)
    
    return function()
    
        local player = Client.GetLocalPlayer()
        if player and player:isa("Commander") then
        
            local selection = player:GetSelection()
            for i = 1, #selection do
            
                local entity = selection[i]
                if HasMixin(entity, "Orders") and entity:GetCurrentOrder() and entity:GetCurrentOrder():GetType() == techId then
                
                    if targetTechId then
                        
                        local orderParam = entity:GetCurrentOrder():GetParam()
                        local orderTarget = orderParam ~= nil and Shared.GetEntity(orderParam)
                        
                        if orderTarget and HasMixin(orderTarget, "Tech") and orderTarget:GetTechId() == targetTechId then
                            return true
                        end
                        
                    else                
                        return true
                    end
                    
                end
            
            end
        
        end
        
        return false
    
    end

end

function GetHasUnbuiltStructure(techId)

    return function()

        local player = Client.GetLocalPlayer()

        if player then
        
            local structures = GetEntitiesWithMixinForTeam("Construct", player:GetTeamNumber())
            for i = 1, #structures do
            
                local structure = structures[i]
                if not structure:GetIsBuilt() and ( not techId or (HasMixin(structure, "Tech") and structure:GetTechId() == techId) ) then
                    return true
                end
            
            end
        
        end

        return false
    
    end

end

// returns true when something can be researched
function TutorialGetIsTechAvailable(techId)

    return function()
    
        local player = Client.GetLocalPlayer()
        local techTree = player:GetTechTree()
        if techTree then
        
            local techNode = techTree:GetTechNode(techId)
            if techNode then
                return techNode:GetAvailable() == true
            end 
       
        end
        
        return false
        
    end

end

// returns true when a structure / tech is active
function TutorialGetHasTech(techId)

    return function ()
        return GetHasTech(Client.GetLocalPlayer(), techId)
    end

end

function TutorialNotHasTech(techId)

    return function ()
        return not GetHasTech(Client.GetLocalPlayer(), techId)
    end

end

function NotHasUnitCount(name, count)

    return function()    
        return PlayerUI_GetUnitCount(name) < count    
    end

end

function TutorialAlienChamberBuildSecond(baseTechId, upgradeTechId)

    return function()
        return GetHasTech(Client.GetLocalPlayer(), baseTechId) and not GetHasTech(Client.GetLocalPlayer(), upgradeTechId)
    end

end

function GetHasWoundedMarine()

    local player = Client.GetLocalPlayer()

    if player then
    
        local marines = GetEntitiesForTeam("Marine", player:GetTeamNumber())

        for i = 1, #marines do
            
            local marine = marines[i]
            if marine:GetIsAlive() and marine:GetHealthScalar() < 0.7 then
                return true
            end
            
        end
    
    end
    
    return false

end

function GetWoundedMarinePosition()

    local player = Client.GetLocalPlayer()

    if player then
    
        local marines = GetEntitiesForTeam("Marine", player:GetTeamNumber())

        for i = 1, #marines do
            
            local marine = marines[i]
            if marine:GetIsAlive() and marine:GetHealthScalar() < 0.7 then
                return marine:GetOrigin()
            end
            
        end
    
    end
    
    return nil

end

function GetHasMarineLowOnAmmo()

    local player = Client.GetLocalPlayer()

    if player then
    
        local marines = GetEntitiesForTeam("Marine", player:GetTeamNumber())

        for i = 1, #marines do
            
            local marine = marines[i]
            local activeWeapon = marine:GetActiveWeapon()
            
            if marine:GetIsAlive() and activeWeapon and activeWeapon:isa("ClipWeapon") and activeWeapon:GetAmmoFraction() < 0.5 then
                return true
            end
            
        end
    
    end
    
    return false

end

function GetMarineLowOnAmmoPosition()

    local player = Client.GetLocalPlayer()

    if player then
    
        local marines = GetEntitiesForTeam("Marine", player:GetTeamNumber())

        for i = 1, #marines do
            
            local marine = marines[i]
            local activeWeapon = marine:GetActiveWeapon()
            
            if marine:GetIsAlive() and activeWeapon and activeWeapon:isa("ClipWeapon") and activeWeapon:GetAmmoFraction() < 0.5 then
                return marine:GetOrigin()
            end
            
        end
    
    end
    
    return nil

end


function CommanderTutorialTimeout(seconds)

    return function()
    
        if gStepStartTime + seconds <= Shared.GetTime() then
            return true
        else
            return false
        end
    
    end

end
