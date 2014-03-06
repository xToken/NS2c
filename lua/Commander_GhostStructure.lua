// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Commander_GhostStructure.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

assert(Client)

local ghostTechId = kTechId.None
local ghostStructureEnabled = false
local errorMessage = ""
local ghostStructureValid = false
local ghostStructureCoords = Coords()
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
        
        if specifyingOrientation then
        
            orientationAngle = GetSpecifiedOrientation(commander)
            
            ghostStructureValid, position, attachEntity, errorMessage = GetIsBuildLegal(ghostTechId, ghostStructureCoords.origin, orientationAngle, kStructureSnapRadius, commander)
            
            // Preserve position, but update angle from mouse.
            local angles = Angles(0, orientationAngle, 0)
            return Coords.GetLookIn(ghostStructureCoords.origin, angles:GetCoords().zAxis)
            
        else
        
            orientationAngle = 0
            
            local x, y = Client.GetCursorPosScreen()
            local trace = GetCommanderPickTarget(commander, CreatePickRay(commander, x, y), false, true)
            
            if trace.fraction < 1 then
            
                // We only want to do the "ValidExit" check after picking a location for a structure requiring a valid exit.
                local ignoreChecks = LookupTechData(ghostTechId, kTechDataSpecifyOrientation, false) and kIgnoreValidExitCheck or nil
                
                ghostStructureValid, position, attachEntity, errorMessage = GetIsBuildLegal(ghostTechId, trace.endPoint, 0, kStructureSnapRadius, commander, nil, ignoreChecks)
                
                if trace.entity then
                    ghostStructureTargetId = trace.entity:GetId()
                else
                    ghostStructureTargetId = Entity.invalidId
                end
                
                if attachEntity then
                
                    coords = attachEntity:GetAngles():GetCoords()
                    coords.origin = position
                    
                else
                    coords.origin = position
                end
                
                local coordsMethod = LookupTechData(ghostTechId, kTechDataOverrideCoordsMethod, nil)
                
                if coordsMethod then
                    coords = coordsMethod(coords)
                end
                
                ghostStructureCoords = coords
                
            else
                ghostStructureCoords = nil
            end
            
        end
        
    end
    
    return ghostStructureCoords
    
end

function CommanderGhostStructureLeftMouseButtonDown(x, y)

    if ghostStructureValid and ghostStructureCoords ~= nil then
    
        local commander = Client.GetLocalPlayer()
        local normalizedPickRay = CreatePickRay(commander, x, y)
        
        // See if we have indicated an orientation for the structure yet (sentries only right now)
        if LookupTechData(ghostTechId, kTechDataSpecifyOrientation, false) and not specifyingOrientation then
            specifyingOrientation = true
        else
        
            // If we're in a mode, clear it and handle it.
            local techNode = GetTechNode(commander, ghostTechId)
            if techNode ~= nil and techNode:GetRequiresTarget() and techNode:GetAvailable() then
            
                local angle = specifyingOrientation and orientationAngle or (math.random() * 2 * math.pi)
                
                // Send world coords of sentry placement instead of normalized pick ray.
                // Because the player may have moved since dropping the sentry and orienting it.
                commander:SendTargetedActionWorld(ghostTechId, ghostStructureCoords.origin, angle, Shared.GetEntity(ghostStructureTargetId))
                
            end
            
            commander:SetCurrentTech(kTechId.None)
            
        end
        
    elseif errorMessage and string.len(errorMessage) > 0 and ghostStructureCoords ~= nil then
        Client.AddWorldMessage(kWorldTextMessageType.CommanderError, Locale.ResolveString(errorMessage), ghostStructureCoords.origin)
    end
    
end

/**
 * This function needs to be called when the Commander tech changes.
 * This happens when the Commander clicks on a button for example.
 */
function CommanderGhostStructureSetTech(techId)

    assert(techId ~= nil)
    local commander = Client.GetLocalPlayer()
    local techNode = GetTechNode(commander, techId)
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