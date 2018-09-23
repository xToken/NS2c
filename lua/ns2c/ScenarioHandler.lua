// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ScenarioHandler.lua
//
//    Created by:   Mats Olsson (mats.olsson@matsotech.se)
//
//
// The scenario handler is used to save and load fixed sets of entities. It is intended to be used
// used for various testing purposes (mostly performance, but also balance and bug testing)
//
// The two commands are "scensave" and "scenload name [root]". 
// - scensave dumps all saveable entities to the log, one line per entity. This data is then supposed
// to be copied by the user and put into a <roo>/<mapname>/<scenario-name>.scn file, where root is one
// of the locations specified in kLoadPath, mapname the name of the map (without the ns2_ prefix) and
// the scenario name is the name used for loading it
//
// - scenload <name> [root] is used to load the named scenario. If url is left blank, the kLoadPath
// is checked to see if any of them contain a scenario with the given name. 
// If the url is given, it is used as a root and the file is looked for in that location. 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Adjusted to hopefully work with classic, untested.

Script.Load("lua/ScenarioHandler_Commands.lua")

class "ScenarioHandler"

ScenarioHandler.kStartTag = "--- SCENARIO START ---"
ScenarioHandler.kEndTag = "--- SCENARIO END ---"

ScenarioHandler.kLoadPath = { "config://scenarios/${map}", "config/scenarios/${map}", "http://www.matsotech.se/ns2scenarios/${map}" }

function ScenarioHandler:Init()
    
    // Will go through all entities and the first one to match will use the given entity handler
    // Some specialized entity handlers for those that need extra care when loading.
    // Just in case a player is evolving; we skip embryos. Eggs are also problematic, so we skip them.
    self.handlers = {
        TeamStartHandler():Init("TeamData"),
        //CystHandler():Init("Cyst",kAlienTeamType),
        //OrientedEntityHandler():Init("Clog",kAlienTeamType),
        //PowerPointHandler():Init("PowerPoint", kMarineTeamType),
        //OrientedEntityHandler():Init("MAC", kMarineTeamType),
        //OrientedEntityHandler():Init("Drifter", kAlienTeamType),
        OrientedEntityHandler():Init("SiegeCannon",kMarineTeamType),
        IgnoreEntityHandler():Init("Embryo"),
        IgnoreEntityHandler():Init("Egg", true), 
        
        OrientedEntityHandler():Init("CommandStation",kMarineTeamType),
        OrientedEntityHandler():Init("InfantryPortal",kMarineTeamType),
        OrientedEntityHandler():Init("ArmsLab",kMarineTeamType),
        OrientedEntityHandler():Init("Armory",kMarineTeamType),
        OrientedEntityHandler():Init("Sentry",kMarineTeamType),
        OrientedEntityHandler():Init("PrototypeLab",kMarineTeamType),
        OrientedEntityHandler():Init("TurretFactory",kMarineTeamType),
        OrientedEntityHandler():Init("Observatory",kMarineTeamType),
        OrientedEntityHandler():Init("Extractor",kMarineTeamType),
        OrientedEntityHandler():Init("PhaseGate",kMarineTeamType),
        
        OrientedEntityHandler():Init("Hive",kAlienTeamType),
        OrientedEntityHandler():Init("Whip",kAlienTeamType),
        OrientedEntityHandler():Init("Crag",kAlienTeamType),
        OrientedEntityHandler():Init("Shade",kAlienTeamType),
        OrientedEntityHandler():Init("Shift",kAlienTeamType),
        OrientedEntityHandler():Init("Hydra",kAlienTeamType),
        OrientedEntityHandler():Init("Harvester",kAlienTeamType),
        
    }

    return self
end


function ScenarioHandler:LookupHandler(cname)
    
    for _,handler in ipairs(self.handlers) do
        if handler:Matches(cname) then
            return handler
        end
    end
    
    return nil
    
end


//
// Save the current scenario
// This just dumps formatted strings for all structures and non-building-owned Cysts that allows
// the Load() method to easily reconstruct them
// The data is written to the server log. The user should just cut out the chunk of the log containing the
// scenario and put in on a webserver
//
function ScenarioHandler:Save()
    Shared.Message(ScenarioHandler.kStartTag)
    Shared.Message(string.format("TeamData|1|%s", GetGamerules():GetTeam1():GetInitialTechPoint():GetLocationName()))
    Shared.Message(string.format("TeamData|2|%s", GetGamerules():GetTeam2():GetInitialTechPoint():GetLocationName()))
    for index, entity in ientitylist(Shared.GetEntitiesWithClassname("Entity")) do
        local cname = entity:GetClassName()
        local handler = self:LookupHandler(cname)
        local accepted = handler and handler:Accept(entity)
        if accepted then
            Shared.Message(string.format("%s|%s", cname, handler:Save(entity)))
        end
    end
    Shared.Message(ScenarioHandler.kEndTag)    
end




/**
 * Load the given scenario. If url is non-nil, look for it in that directory
 * otherwise look for it by going through the root-path
 */
function ScenarioHandler:LoadScenario(name, url)

    ScenarioLoader():Load(self, ScenarioHandler.kLoadPath, name)

end

function ScenarioHandler:Load(data)

    // with random start added, we can't trust that anything already existing can be in the right place,
    // so we destroy all entities that belongs to saveable classes and then recreate the whole scenario. 
    self:DestroySaveableEntities()
    self:LoadSaveableEntities(data)
end

function ScenarioHandler:DestroySaveableEntities()
    local entityList = Shared.GetEntitiesWithClassname("Entity")
    for index, entity in ientitylist(entityList) do
        if entity:isa("Infestation") then
            DestroyEntity(entity)
        else
            handler = self:LookupHandler(entity:GetClassName())
            if handler then
                handler:Destroy(entity)
            end
        end
    end
end

function ScenarioHandler:LoadSaveableEntities(data) 
    local startTagFound, endTagFound = false, false
    data = string.gsub(data, "\r", "") // remove any carrage returns (WINDOOOOOWS!)
    local lines = data:gmatch("[^\n]+")
    // load in two stages; use the second stage to resolve references to other entities
    local createdEntities = {}
    for line in lines do
        if line == ScenarioHandler.kStartTag then
            startTagFound = true
        elseif line == ScenarioHandler.kEndTag then
            endTagFound = true
            break
        else 
            if startTagFound then
                local args = line:gmatch("[^|]+")
                local cname = args()
                local handler = self:LookupHandler(cname)
                if handler then 
                    local created = handler:Load(args, cname)
                    if created then
                        table.insert(createdEntities, created)
                    end
                end
            end
        end
    end
    // Resolve stage
    for _,entity in ipairs(createdEntities) do
        local handler = self:LookupHandler(entity:GetClassName())
        handler:Resolve(entity)
        Log("Loaded %s", entity)
    end
   
    Shared.Message("END LOAD")
end

/**
 * Loading scenarios is a bit complex, as we may try loading from websites in the path, and doing
 * Shared.SendHTTPRequest() is done in its own thread. 
 *
 * So this class takes care of searching through all the roots for the given file
 */
class "ScenarioLoader"

function ScenarioLoader:Load(handler, path, name)
    self.handler = handler
    self.path = path
    self.pathIndex = 0    
    self.name = name 
    self:LoadNext()
end

function ScenarioLoader:LoadNext()
    self.pathIndex = self.pathIndex + 1
    if self.pathIndex > #self.path then
        Log("Unable to find scenario %s", self.name)
    else
        self:LookIn(self.path[self.pathIndex], self.name)
    end
end

/**
 * Look in the given root for the named scenario. Returns a table containing 
 * "path" and "data" if a scenario file is found.
 */
function ScenarioLoader:LookIn(root, name)
    // substitute any "${map}" with the current base mapname (ie, without any ns2_ prefix)
    local mapname = Shared.GetMapName()
    // strip any "ns2_"  from the mapname
    mapname = string.gsub(mapname, "ns2_", "")
    // all scenarios must be in .scn files - strip it away if the user wrote it
    name = string.gsub(name, ".scn", "")
    local path = string.gsub(root, "${map}", mapname) .. "/" .. name .. ".scn"
    if string.find(path, "http:") == 1 then
        // load from the web
        local loadFunction = function(data)
            self:LoadData(path, data)
        end
        Shared.SendHTTPRequest(path, "GET", loadFunction)
    else
        local file = io.open(path)
        local data = nil
        if file then
            data = file:read("*all")
            io.close(file)
        end
        self:LoadData(path,data)
    end
end

function ScenarioLoader:LoadData(path, data)
    if data and string.find(data, ScenarioHandler.kStartTag) then
        Log("LOAD from %s\n", path)
        self.handler:Load(data)
    else
        Log("Unable to load %s", path)
        self:LoadNext()
    end
end

class "ScenarioEntityHandler"

function ScenarioEntityHandler:Init(name, teamType)
    self.handlerClassName = name
    self.teamType = teamType
    return self
end


function ScenarioEntityHandler:Matches(entityClassName)
    return classisa(entityClassName, self.handlerClassName)
end

function ScenarioEntityHandler:GetTeamType(entityClassName)
    if self.teamType then
        return self.teamType
    end
    //otherwise, get the teamType from check GetIsAlienStructure
    local cls = _G[entityClassName]
    if cls.GetIsAlienStructure then
        return cls.GetIsAlienStructure() and kAlienTeamType or kMarineTeamType
    end
    Log("Unable to find team for %s", entityClassName)
    return nil 
end

// return true if this entity should be accepted for saving
function ScenarioEntityHandler:Accept(entity)
    // we need to be able to get a teamtype for it
    return self:GetTeamType(entity:GetClassName()) ~= nil
end

function ScenarioEntityHandler:Resolve(entity)
    // default do nothing
end

function ScenarioEntityHandler:WriteVector(vec)
    return string.format("%f,%f,%f", vec.x, vec.y, vec.z)
end

function ScenarioEntityHandler:ReadVector(text)
    local p = text:gmatch("[^, ]+")
    local x,y,z = tonumber(p()),tonumber(p()),tonumber(p())
    return Vector(x,y,z)
end

function ScenarioEntityHandler:ReadNumber(text)
    return tonumber(text)
end

function ScenarioEntityHandler:WriteAngles(angles)
    return string.format("%f,%f,%f", angles.pitch, angles.yaw, angles.roll)
end

function ScenarioEntityHandler:ReadAngles(text)
    local p = text:gmatch("[^, ]+")
    local pitch,yaw,roll = tonumber(p()),tonumber(p()),tonumber(p())
    return Angles(pitch,yaw,roll)
end

//
// destroy the given entity before loading other entities in 
// 
// In its own class just in case there is something extra that needs to be
// done for particular classes
//
function ScenarioEntityHandler:Destroy(entity)
    DestroyEntity(entity)
    if entity.ClearAttached then
        // for some reason, ClearAttached is NOT called from OnDestroy, only from OnKill. May be a bug?
        entity:ClearAttached()
    end
end

//
// Oriented entity handlers have an origin and an angles
//
class "OrientedEntityHandler" (ScenarioEntityHandler)

function OrientedEntityHandler:Save(entity)
    // re-offset the extra spawn height added to it... otherwise our hives will stick up in the roof, and all other things will float
    // 5cm off the ground..
    local spawnOffset = LookupTechData(entity:GetTechId(), kTechDataSpawnHeightOffset, .05)
    local origin = entity:GetOrigin() - Vector(0, spawnOffset, 0)
    return self:WriteVector(origin) .. "|" .. self:WriteAngles(entity:GetAngles())
end

function OrientedEntityHandler:Load(args, classname)
    local origin = self:ReadVector(args())
    local angles = self:ReadAngles(args())

    // Log("For %s(%s), team %s at %s, %s", classname, kTechId[classname], self:GetTeamType(classname), origin, angles)
    local entity = self:Create(classname, origin)
    
    if entity then
        entity:SetAngles(angles)
    end
    
    return entity
end

function OrientedEntityHandler:Resolve(entity)
    ScenarioEntityHandler.Resolve(self, entity)

    // if we can complete the construction, do so
    if HasMixin(entity, "Construct") then
        entity:SetConstructionComplete()
    end
    
    if HasMixin(entity, "Infestation") then
        entity:SetInfestationFullyGrown()
    end
    
    // fix to spread out the target acquisition for sentries; randomize lastTargetAcquisitionTime
    if entity:isa("Sentry") then
        // buildtime means that we need to add a hefty offset to timeOLT
        entity.timeOfLastTargetAcquisition = Shared.GetTime() + 5 + math.random()
    end

    if entity:isa("Drifter") or entity:isa("MAC") then
        // *sigh* - positioning an entity in its first OnUpdate? Really?
        entity.justSpawned = false
    end
    
end

function OrientedEntityHandler:Create(entityClassName, position)
    // always nice to have exceptions to the rule...
    local techId = entityClassName == "TunnelEntrance" and kTechId["GorgeTunnel"] or kTechId[entityClassName]
    return CreateEntityForTeam( techId, position, self:GetTeamType(entityClassName), nil )
end

class "IgnoreEntityHandler" (ScenarioEntityHandler) 

function IgnoreEntityHandler:Init(name, destroy)
    self.destroy = destroy
    return ScenarioEntityHandler.Init(self, name)
end

function IgnoreEntityHandler:Accept() 
    return false
end

function IgnoreEntityHandler:Destroy(entity)
    if self.destroy then
        ScenarioEntityHandler.Destroy(self, entity)
    end
end

class "TeamStartHandler" (ScenarioEntityHandler) 

function TeamStartHandler:Init(name)
    return ScenarioEntityHandler.Init(self, name)
end

function TeamStartHandler:Accept() 
    return false
end

function TeamStartHandler:Destroy(entity)
    // ignore
end

function TeamStartHandler:Matches(entityClassName)
    return entityClassName == "TeamData"
end

function TeamStartHandler:Load(args, classname)
    local teamNum = self:ReadNumber(args())
    local locationName = args()
    local techPoint = nil
    for i,entity in ientitylist(Shared.GetEntitiesWithClassname("TechPoint")) do
        local location = GetLocationForPoint(entity:GetOrigin())
        local locationNameEnt = location and location:GetName() or ""
        if locationNameEnt == locationName then
            techPoint = entity 
            break
        end
    end
    
    if not techPoint then
        Log("No techpoint found for location '%s'", locationName) 
    end

    local team =  teamNum == 1 and GetGamerules():GetTeam1() or GetGamerules():GetTeam2()
    team.initialTechPointId = techPoint:GetId()
    return nil // we don't actually create an entity, so return nil
end

// create the singleton instance
ScenarioHandler.instance = ScenarioHandler():Init()