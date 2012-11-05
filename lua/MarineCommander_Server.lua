// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineCommander_Server.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

/**
 * sends notification to all players (new research complete, structure created, etc)
 */
 
function MarineCommander:ProcessSuccessAction(techId)

    local team = self:GetTeam()
    local cost = GetCostForTech(techId)
    
    if cost and cost ~= 0 then
        team:AddTeamResources(-cost)
    end

end

function MarineCommander:TriggerScan(position, trace, entity)

    if trace.fraction ~= 1 and entity and entity:GetEnergy() > GetCostForTech(kTechId.Scan) then

        CreateEntity(Scan.kMapName, position, self:GetTeamNumber())
        StartSoundEffectAtOrigin(Observatory.kScanSound, position)
        
        // create custom sound for marine commander
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

local function GetDroppackSoundName(techId)

    /*if techId == kTechId.MedPack then
        return MedPack.kHealthSound
    elseif techId == kTechId.AmmoPack then
        return AmmoPack.kPickupSound
    elseif techId == kTechId.CatPack then
        return CatPack.kPickupSound
    end*/
    return MarineCommander.kDropSound
   
end

function MarineCommander:TriggerDropPack(position, techId)

    local mapName = LookupTechData(techId, kTechDataMapName)

    if mapName then
    
        local droppack = CreateEntity(mapName, position, self:GetTeamNumber())
        StartSoundEffectForPlayer(GetDroppackSoundName(techId), self)
        //Shared.PlaySound(nil, GetDroppackSoundName(techId))
        self:ProcessSuccessAction(techId)
        success = true
        
    end

    return success

end

local function GetIsEquipment(techId)

    return techId == kTechId.Welder or techId == kTechId.Mines or techId == kTechId.Shotgun or techId == kTechId.GrenadeLauncher or
           techId == kTechId.HeavyMachineGun or techId == kTechId.Jetpack or techId == kTechId.HeavyArmor

end

local function GetIsDroppack(techId)
    return techId == kTechId.MedPack or techId == kTechId.AmmoPack or techId == kTechId.CatPack
end

// check if a notification should be send for successful actions
function MarineCommander:ProcessTechTreeActionForEntity(techNode, position, normal, pickVec, orientation, entity, trace)

    local techId = techNode:GetTechId()
    local success = false
    local keepProcessing = false
    
    if techId == kTechId.Scan then
        success = self:TriggerScan(position, trace, entity)
        keepProcessing = false
     
    elseif GetIsDroppack(techId) then
        success = self:TriggerDropPack(position, techId)
        keepProcessing = false
        
    elseif GetIsEquipment(techId) then
    
        success = self:AttemptToBuild(techId, position, normal, orientation, pickVec, false, entity)
    
        if success then
            self:ProcessSuccessAction(techId)
            self:TriggerEffects("spawn_weapon", { effecthostcoords = Coords.GetTranslation(position) })
        end    
            
        keepProcessing = false

    else
        success, keepProcessing = Commander.ProcessTechTreeActionForEntity(self, techNode, position, normal, pickVec, orientation, entity, trace)
    end

    if success then

        local location = GetLocationForPoint(position)
        local locationName = location and location:GetName() or ""
        self:TriggerNotification(Shared.GetStringIndex(locationName), techId)
    
    end   
    
    return success, keepProcessing

end