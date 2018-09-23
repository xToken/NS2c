-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\MarineCommander_Server.lua
--
--    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Added energy back in, removed some unneeded drop functions

--
-- sends notification to all players (new research complete, structure created, etc)
--
function MarineCommander:ProcessSuccessAction(techId)

    local team = self:GetTeam()
    local cost = GetCostForTech(techId)
    
    if cost and cost ~= 0 then
        team:AddTeamResources(-cost)
    end

end

function MarineCommander:TriggerScan(position, trace, entity)

    if trace.fraction ~= 1 and entity and entity:GetEnergy() >= GetCostForTech(kTechId.Scan) then

        CreateEntity(Scan.kMapName, position, self:GetTeamNumber())
        StartSoundEffectAtOrigin(Observatory.kScanSound, position)
        
        -- create custom sound for marine commander
        StartSoundEffectForPlayer(Observatory.kCommanderScanSound, self)
        local cost = GetCostForTech(kTechId.Scan)
        if cost and cost ~= 0 then
            entity:AddEnergy(-cost)
        end
        return true
    
    else
        self:TriggerInvalidSound()
        return false
    end

end

local function GetDroppackEffectName(techId)

    if techId == kTechId.MedPack then
        return "medpack_commander_drop"
    elseif techId == kTechId.AmmoPack then
        return "ammopack_commander_drop"
    elseif techId == kTechId.CatPack then
        return "catpack_commander_drop"
    end
   
end

function MarineCommander:TriggerDropPack(position, techId)

    local mapName = LookupTechData(techId, kTechDataMapName)

    if mapName then
    
        local droppack = CreateEntity(mapName, position, self:GetTeamNumber())
        self:TriggerEffects( GetDroppackEffectName(techId), { effecthostcoords = Coords.GetTranslation(position) } )
        return true
        
    end

end

local function GetIsEquipment(techId)

    return techId == kTechId.Welder or techId == kTechId.Mines or techId == kTechId.Shotgun or techId == kTechId.GrenadeLauncher or
           techId == kTechId.HeavyMachineGun or techId == kTechId.Jetpack or techId == kTechId.HeavyArmor

end

local function GetIsDroppack(techId)
    return techId == kTechId.MedPack or techId == kTechId.AmmoPack or techId == kTechId.CatPack
end

local function SelectNearest(self, className )

    local nearestEnts = { nil, nil, nil, nil }
    local lowestDistance = { 0, 0, 0, 0 }
    local priority
    
    for _, entity in ipairs(GetEntitiesForTeam(className, self:GetTeamNumber())) do
        
        if entity:GetIsBuilt() then
            if entity:GetIsPowered() then
                if not entity:GetIsRecycling() then
                    priority = 1
                else
                    priority = 2
                end
            else
                priority = 3
            end
        else
            priority = 4
        end
        
        local distance = (entity:GetOrigin() - self:GetOrigin()):GetLengthXZ()
        if not nearestEnts[priority] or distance < lowestDistance[priority] then
            nearestEnts[priority] = entity
            lowestDistance[priority] = distance
        end
    end
    
    local nearestEnt
    for i=1,4 do
        nearestEnt = nearestEnts[i]
        if nearestEnt then
            break
        end
    end
    
    if nearestEnt then

        if Client then
        
            DeselectAllUnits(self:GetTeamNumber())
            nearestEnt:SetSelected(self:GetTeamNumber(), true, false, false)
            
            return true
        
        elseif Server then
        
            DeselectAllUnits(self:GetTeamNumber())
            nearestEnt:SetSelected(self:GetTeamNumber(), true, false, false)
            Server.SendNetworkMessage(self, "ComSelect", BuildSelectAndGotoMessage(nearestEnt:GetId()), true)
            
            return true
            
        end
    
    end
    
    return false

end

function MarineCommander:CopyPlayerDataFrom(player)
    
    Commander.CopyPlayerDataFrom(self, player)
    
    self.parasited = player.parasited
    self.timeParasited = player.timeParasited
    self.parasiteDuration = player.parasiteDuration
    
end

-- check if a notification should be send for successful actions
function MarineCommander:ProcessTechTreeActionForEntity(techNode, position, normal, pickVec, orientation, entity, trace, targetId)

    local techId = techNode:GetTechId()
    local success = false
    local keepProcessing = false
    
    if techId == kTechId.Scan then
        success = self:TriggerScan(position, trace, entity)
        keepProcessing = false
     
    elseif GetIsDroppack(techId) then
    
        -- use the client side trace.entity here
        local clientTargetEnt = Shared.GetEntity(targetId)
        if clientTargetEnt and clientTargetEnt:isa("Marine") then
            position = clientTargetEnt:GetOrigin() + Vector(0, 0.05, 0)
        end
    
        success = self:TriggerDropPack(position, techId)
        keepProcessing = false
        
    elseif GetIsEquipment(techId) then
    
        success = self:AttemptToBuild(techId, position, normal, orientation, pickVec, false, entity)
    
        if success then
            self:TriggerEffects("spawn_weapon", { effecthostcoords = Coords.GetTranslation(position) })
        end    
            
        keepProcessing = false
    else

        return Commander.ProcessTechTreeActionForEntity(self, techNode, position, normal, pickVec, orientation, entity, trace, targetId)

    end

    if success then

        self:ProcessSuccessAction(techId)

        local location = GetLocationForPoint(position)
        local locationName = location and location:GetName() or ""
        self:TriggerNotification(Shared.GetStringIndex(locationName), techId)

    end
    
    return success, keepProcessing

end
