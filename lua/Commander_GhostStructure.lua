-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\Commander_GhostStructure.lua
--
--    Created by:   Brian Cronin (brianc@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

assert(Client)

local ghostTechId = kTechId.None
local ghostStructureEnabled = false
local errorMessage = ""
local ghostStructureValid = false
local ghostStructureCoords = Coords()
local ghostNormalizedPickRay = Vector(0,0,0)
local ghostStructureTargetId = Entity.invalidId
local orientationAngle = 0
local specifyingOrientation = false

function SetCommanderGhostStructureEnabled(enabled)
    ghostStructureEnabled = enabled
end

function GetCommanderGhostStructureEnabled()
    return ghostStructureEnabled
end

function GetCommanderErrorMessage()
    return errorMessage
end

function GetCommanderGhostStructureValid()
    return ghostStructureValid
end

function GetCommanderGhostStructureSpecifyingOrientation()
    return specifyingOrientation
end

local function GetSpecifiedOrientation(commander)

    local xScalar, yScalar = Client.GetCursorPos()
    local x = xScalar * Client.GetScreenWidth()
    local y = yScalar * Client.GetScreenHeight()
    
    local startPoint = Client.WorldToScreen(ghostStructureCoords.origin)
    local endPoint = startPoint + (Vector(x, y, 0) - startPoint)
    
    local vecDiff = startPoint - endPoint
    
    if vecDiff:GetLength() > 1 then
    
        local normToMouse = GetNormalizedVector(vecDiff)
        local z = normToMouse.x
        local x = normToMouse.y
        normToMouse.z = -z
        normToMouse.x = x
        normToMouse.y = 0
        return GetYawFromVector(normToMouse)
        
    end
    
    return 0
    
end

local kIgnoreValidExitCheck = { ValidExit = true }
function GetCommanderGhostStructureCoords()

    if ghostStructureEnabled then
    
        local coords = Coords.GetIdentity()
        local commander = Client.GetLocalPlayer()
        local x, y = Client.GetCursorPosScreen()
        local normalizedPickRay = CreatePickRay(commander, x, y)

        local position, attachEntity
        
        if specifyingOrientation then
        
            orientationAngle = GetSpecifiedOrientation(commander)
            
            ghostStructureValid, position, attachEntity, errorMessage = GetIsBuildLegal(ghostTechId, ghostStructureCoords.origin, orientationAngle, kStructureSnapRadius, commander)
            
            -- Preserve position, but update angle from mouse.
            local angles = Angles(0, orientationAngle, 0)
            return Coords.GetLookIn(ghostStructureCoords.origin, angles:GetCoords().zAxis)
            
        else
        
            orientationAngle = 0

            local trace = GetCommanderPickTarget(commander, normalizedPickRay, false, true, nil, LookupTechData( ghostTechId, kCommanderSelectRadius ), "ray")
            
            if trace.fraction < 1 then
            
                -- We only want to do the "ValidExit" check after picking a location for a structure requiring a valid exit.
                local ignoreChecks = LookupTechData(ghostTechId, kTechDataSpecifyOrientation, false) and kIgnoreValidExitCheck or nil
                
                ghostStructureValid, position, attachEntity, errorMessage = GetIsBuildLegal(ghostTechId, trace.endPoint, 0, kStructureSnapRadius, commander, nil, ignoreChecks)
                
                if trace.entity then
                    ghostStructureTargetId = trace.entity:GetId()
                else
                    ghostStructureTargetId = Entity.invalidId
                end
                
                if attachEntity then
                
                    coords = attachEntity:GetAngles():GetCoords()
                    local spawnHeight = LookupTechData(ghostTechId, kTechDataSpawnHeightOffset, 0)
                    coords.origin = position + Vector(0, spawnHeight, 0)
                    
                else
                    local spawnHeight = LookupTechData(ghostTechId, kTechDataSpawnHeightOffset, 0)
                    coords.origin = position
                end
                
                local coordsMethod = LookupTechData(ghostTechId, kTechDataOverrideCoordsMethod, nil)
                
                if coordsMethod then
                    coords = coordsMethod(coords, ghostTechId, ghostStructureTargetId )
                end
                
                ghostStructureCoords = coords
                
            else
                ghostStructureCoords = nil
            end
            
            ghostNormalizedPickRay = normalizedPickRay
        end
        
    end
    
    return ghostStructureCoords
    
end

function CommanderGhostStructureLeftMouseButtonDown(x, y)

    if ghostStructureValid and ghostStructureCoords ~= nil then
    
        local commander = Client.GetLocalPlayer()
        local orientableGhost = LookupTechData(ghostTechId, kTechDataSpecifyOrientation)
        
        -- See if we have indicated an orientation for the structure yet (sentries only right now)
        if orientableGhost and not specifyingOrientation then
            specifyingOrientation = true
        else
        
            -- If we're in a mode, clear it and handle it.
            local techNode = GetTechNode(ghostTechId)
            if techNode ~= nil and techNode:GetRequiresTarget() and techNode:GetAvailable() then
            
                local angle = specifyingOrientation and orientationAngle or (math.random() * 2 * math.pi)
                local currentPickVec = (ghostStructureCoords.origin - commander:GetOrigin()):GetUnit()
                
                -- Using a stored normalized pick ray
                -- because the player may have moved since dropping the sentry/gates/etc and orienting it.
                pickVec = orientableGhost and currentPickVec or ghostNormalizedPickRay
                commander:SendTargetedAction(ghostTechId, pickVec, angle, Shared.GetEntity(ghostStructureTargetId))
                
            end
            
            commander:SetCurrentTech(kTechId.None)
            
        end
        
    elseif errorMessage and string.len(errorMessage) > 0 and ghostStructureCoords ~= nil then
        local message = Locale.ResolveString(errorMessage)
        local method = LookupTechData(ghostTechId, kTechDataBuildMethodFailedLookup, nil)
        if method then
            message = string.format(message, method())
        end
        Client.AddWorldMessage(kWorldTextMessageType.CommanderError, message, ghostStructureCoords.origin)
    end
    
end

--
-- This function needs to be called when the Commander tech changes.
-- This happens when the Commander clicks on a button for example.
--
function CommanderGhostStructureSetTech(techId)

    assert(techId ~= nil)
    
    local techNode = GetTechNode(techId)
    local showGhost = false
    
    if techNode ~= nil then
    
        showGhost = not techNode:GetIsEnergyManufacture() and not techNode:GetIsManufacture() and not techNode:GetIsPlasmaManufacture() 
                    and not techNode:GetIsResearch() and not techNode:GetIsUpgrade()
        
    end
    
    specifyingOrientation = false
    ghostStructureEnabled = showGhost and techId ~= kTechId.None and (LookupTechData(techId, kTechDataModel) ~= nil)
    ghostTechId = techId
    ghostStructureValid = false

    GetCommanderGhostStructureCoords()
    
end
