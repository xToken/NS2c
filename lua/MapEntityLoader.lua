// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MapEntityLoader.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/FunctionContracts.lua")

local function ClientOnly()
    return Client ~= nil
end

local function ServerOnly()
    return Server ~= nil
end

local function ClientAndServerAndPredict()
    return Client or Server or Predict
end

function LoadEntityFromValues(entity, values, initOnly)

    entity:SetOrigin(values.origin)
    entity:SetAngles(values.angles)

    // Copy all of the key values as fields on the entity.
    for key, value in pairs(values) do 
    
        if key ~= "origin" and key ~= "angles" then
            entity[key] = value
        end
        
    end
    
    if not initOnly then
    
        if entity.OnLoad then
            entity:OnLoad()
        end
        
    end
    
    if entity.OnInitialized then
        entity:OnInitialized()
    end
    
end
AddFunctionContract(LoadEntityFromValues, { Arguments = { "userdata", "table", "boolean" }, Returns = { } })

local function LoadLight(className, groupName, values)
            
    local renderLight = Client.CreateRenderLight()
    local coords = values.angles:GetCoords(values.origin)
    
    if values.specular == nil then
        values.specular = true
    end        
    
    if className == "light_spot" then
    
        renderLight:SetType(RenderLight.Type_Spot)
        renderLight:SetOuterCone(values.outerAngle)
        renderLight:SetInnerCone(values.innerAngle)
        renderLight:SetCastsShadows(values.casts_shadows)
        renderLight:SetSpecular(values.specular)
        
        if values.gobo_texture ~= nil then
            renderLight:SetGoboTexture(values.gobo_texture)
        end
        
        if values.shadow_fade_rate ~= nil then
            renderLight:SetShadowFadeRate(values.shadow_fade_rate)
        end
    
    elseif className == "light_point" then
    
        renderLight:SetType(RenderLight.Type_Point)
        renderLight:SetCastsShadows(values.casts_shadows)
        renderLight:SetSpecular(values.specular)

        if values.shadow_fade_rate ~= nil then
            renderLight:SetShadowFadeRate(values.shadow_fade_rate)
        end
        
    elseif className == "light_ambient" then
        
        renderLight:SetType(RenderLight.Type_AmbientVolume)
        
        renderLight:SetDirectionalColor(RenderLight.Direction_Right,    values.color_dir_right)
        renderLight:SetDirectionalColor(RenderLight.Direction_Left,     values.color_dir_left)
        renderLight:SetDirectionalColor(RenderLight.Direction_Up,       values.color_dir_up)
        renderLight:SetDirectionalColor(RenderLight.Direction_Down,     values.color_dir_down)
        renderLight:SetDirectionalColor(RenderLight.Direction_Forward,  values.color_dir_forward)
        renderLight:SetDirectionalColor(RenderLight.Direction_Backward, values.color_dir_backward)
        
    end

    renderLight:SetCoords(coords)
    renderLight:SetRadius(values.distance)
    renderLight:SetIntensity(values.intensity)
    renderLight:SetColor(values.color)
    renderLight:SetGroup(groupName)
    renderLight.ignorePowergrid = values.ignorePowergrid
    
    local atmosphericDensity = tonumber(values.atmospheric_density)
    
    // Backwards compatibility
    if values.atmospheric then
        atmosphericDensity = 1.0
    end
    
    if atmosphericDensity ~= nil then
        renderLight:SetAtmosphericDensity( atmosphericDensity )
    end
    
    // Save original values so we can alter and restore lights
    renderLight.originalIntensity = values.intensity
    renderLight.originalColor = values.color
    renderLight.originalCoords = Coords(coords)
    renderLight.originalAtmosphericDensity = atmosphericDensity
    
    if (className == "light_ambient") then
    
        renderLight.originalRight = values.color_dir_right
        renderLight.originalLeft = values.color_dir_left
        renderLight.originalUp = values.color_dir_up
        renderLight.originalDown = values.color_dir_down
        renderLight.originalForward = values.color_dir_forward
        renderLight.originalBackward = values.color_dir_backward
        
    end
    
    if Client.lightList == nil then
        Client.lightList = { }
    end
    table.insert(Client.lightList, renderLight)
    
    return true
        
end
AddFunctionContract(LoadLight, { Arguments = { "string", "string", "table" }, Returns = { "boolean" } })

local function LoadBillboard(className, groupName, values)

    local renderBillboard = Client.CreateRenderBillboard()

    renderBillboard:SetOrigin(values.origin)
    renderBillboard:SetGroup(groupName)
    renderBillboard:SetMaterial(values.material)
    renderBillboard:SetSize(values.size)
    
    if Client.billboardList == nil then
        Client.billboardList = { }
    end
    table.insert(Client.billboardList, renderBillboard)
    
    return true
        
end
AddFunctionContract(LoadBillboard, { Arguments = { "string", "string", "table" }, Returns = { "boolean" } })

local function LoadDecal(className, groupName, values)

    local renderDecal = Client.CreateRenderDecal()

    local coords = values.angles:GetCoords(values.origin)
    renderDecal:SetCoords(coords)
    //renderDecal:SetGroup(groupName)
    renderDecal:SetMaterial(values.material)
    renderDecal:SetExtents(values.extents)
    
    if Client.decalList == nil then
        Client.decalList = { }
    end
    table.insert(Client.decalList, renderDecal)
    
    return true
        
end
AddFunctionContract(LoadDecal, { Arguments = { "string", "string", "table" }, Returns = { "boolean" } })

local function LoadStaticProp(className, groupName, values)

    if values.model == "" then
        return
    end

    local coords = values.angles:GetCoords(values.origin)
    
    coords.xAxis = coords.xAxis * values.scale.x
    coords.yAxis = coords.yAxis * values.scale.y
    coords.zAxis = coords.zAxis * values.scale.z
    
    local renderModelCommAlpha = GetAndCheckValue(values.commAlpha, 0, 1, "commAlpha", 1, true)
    local blocksPlacement = groupName == kCommanderInvisibleGroupName or
                            groupName == kCommanderNoBuildGroupName

    // Test against false so that the default is true
    if values.collidable ~= false then
    
        // Create the physical representation of the prop.
        local physicsModel = Shared.CreatePhysicsModel(values.model, false, coords, nil) 
        physicsModel:SetPhysicsType(CollisionObject.Static)
    
        // Make it not block selection and structure placement (GetCommanderPickTarget)
        if renderModelCommAlpha < 1 or blocksPlacement then
            physicsModel:SetGroup(PhysicsGroup.CommanderPropsGroup)
        end

    end
    
    // Only create Pathing objects if we are told too
    if values.pathInclude == true then
        Pathing.CreatePathingObject(values.model, coords)
    end
    
    if Client then
    
        // Create the visual representation of the prop.
        // All static props can be instanced.
        local renderModel = Client.CreateRenderModel(RenderScene.Zone_Default)       
        renderModel:SetModel(values.model)
        
        if values.castsShadows ~= nil then
            renderModel:SetCastsShadows(values.castsShadows)
        end
        
        renderModel:SetCoords(coords)
        renderModel:SetIsStatic(true)
        renderModel:SetIsInstanced(true)
        renderModel:SetGroup(groupName)
        
        renderModel.commAlpha = renderModelCommAlpha
        
        table.insert(Client.propList, {renderModel, physicsModel})
        
    end
    
    return true

end
AddFunctionContract(LoadStaticProp, { Arguments = { "string", "string", "table" }, Returns = { "boolean" } })

local function LoadSoundEffect(className, groupName, values)

    local soundEffect = Server.CreateEntity(className)
    if soundEffect then
    
        soundEffect:SetMapEntity()
        
        soundEffect:SetOrigin(values.origin)
        soundEffect:SetAngles(values.angles)
        
        Shared.PrecacheSound(values.eventName)
        soundEffect:SetAsset(values.eventName)
        
        if values.listenChannel then
            soundEffect:SetListenChannel(values.listenChannel)
        end
        
        if values.startsOnMessage and string.len(values.startsOnMessage) > 0 then
            soundEffect:RegisterSignalListener(function() soundEffect:Start() end, values.startsOnMessage)
        end
        
        return true
        
    end
    
    return false
    
end

local function LoadReflectionProbe(className, groupName, values)

    /*
    local renderReflectionProbe = Client.CreateRenderReflectionProbe()
    
    if values.strength == nil then
        values.strength = 1
    end

    renderReflectionProbe:SetOrigin(values.origin)
    renderReflectionProbe:SetGroup(groupName)
    renderReflectionProbe:SetRadius(values.distance)
    renderReflectionProbe:SetStrength(values.strength)
    
    if Client.reflectionProbeList == nil then
        Client.reflectionProbeList = { }
    end
    table.insert(Client.reflectionProbeList, renderReflectionProbe)
    */
    
    return true
        
end
AddFunctionContract(LoadReflectionProbe, { Arguments = { "string", "string", "table" }, Returns = { "boolean" } })


local loadTypes = { }
loadTypes["light_spot"] = { LoadAllowed = ClientOnly, LoadFunction = LoadLight }
loadTypes["light_point"] = { LoadAllowed = ClientOnly, LoadFunction = LoadLight }
loadTypes["light_ambient"] = { LoadAllowed = ClientOnly, LoadFunction = LoadLight }
loadTypes["prop_static"] = { LoadAllowed = ClientAndServerAndPredict, LoadFunction = LoadStaticProp }
loadTypes["sound_effect"] = { LoadAllowed = ServerOnly, LoadFunction = LoadSoundEffect }
loadTypes["billboard"] = { LoadAllowed = ClientOnly, LoadFunction = LoadBillboard }
loadTypes["decal"] = { LoadAllowed = ClientOnly, LoadFunction = LoadDecal }
loadTypes["reflection_probe"] = { LoadAllowed = ClientOnly, LoadFunction = LoadReflectionProbe }

/**
 * This will load common map entities for the Client, Server, or both.
 * Call LoadMapEntity() with the map name of the entity and the map values
 * and it will be loaded. Returns true on success.
 */
function LoadMapEntity(className, groupName, values)

    local loadData = loadTypes[className]
    if loadData and loadData.LoadAllowed() then
        return loadData.LoadFunction(className, groupName, values)
    end
    return false

end
AddFunctionContract(LoadMapEntity, { Arguments = { "string", "string", "table" }, Returns = { "boolean" } })