// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\WebsAbility.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/StructureAbility.lua")

class 'WebsAbility' (StructureAbility)

local kMaxWebLength = 20
local kMinWebLength = 4

function WebsAbility:GetEnergyCost(player)
    return kDropStructureEnergyCost
end

function WebsAbility:GetGhostModelName(ability)
    return Bomb.kModelName
end

function WebsAbility:GetDropStructureId()
    return kTechId.Web
end

function WebsAbility:GetRequiredTechId()
    return kTechId.ThreeHives
end

function WebsAbility:GetSuffixName()
    return "web"
end

function WebsAbility:GetDropClassName()
    return "Web"
end

function WebsAbility:OnStructureCreated(structure, lastClickedPosition)
    structure:SetEndPoint(lastClickedPosition)
end

function WebsAbility:GetIsPositionValid(displayOrigin, player, normal, lastClickedPosition, entity)

    local mapOrigin = Vector(0,0,0)
    local direction = player:GetViewCoords().zAxis
    local startPoint = displayOrigin + normal * 0.1
    local valid = false

    if lastClickedPosition and displayOrigin and startPoint ~= lastClickedPosition 
       and (lastClickedPosition - startPoint):GetLength() < kMaxWebLength and (lastClickedPosition - startPoint):GetLength() > kMinWebLength then
    
        // check if we can create a web between the 2 point
        local webTrace = Shared.TraceRay(lastClickedPosition, startPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterAll())
        if webTrace.fraction >= 0.99 then
            valid = true
        end
    
    end

    return valid and lastClickedPosition ~= mapOrigin
    
end

function WebsAbility:GetDropMapName()
    return Web.kMapName
end

function WebsAbility:IsAllowed(player)
    local structures = GetEntitiesForTeamWithinRange(self:GetDropClassName(), player:GetTeamNumber(), player:GetEyePos(), kMaxAlienStructureRange)
    return GetHasTech(player, self:GetRequiredTechId()) and #structures < kMaxAlienStructuresofType and kWebEnabled
end