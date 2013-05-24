// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\StructureAbility.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Entity.lua")

class 'StructureAbility' (Entity)

function CheckTeamHasStructure(structure_name)

	local structures = EntityListToTable(Shared.GetEntitiesWithClassname(structure_name))
	local amount = table.count(structures)
	
	// Print("team has (%s) (%s)", tostring(amount), structure_name)
	
	if amount == 0 then
		return false
	else
		return true
	end
	
end

function StructureAbility:GetIsPositionValid(position)
    return true
end

function StructureAbility:GetDropRange()
    return kGorgeCreateDistance
end

function StructureAbility:OnUpdateHelpModel(ability, abilityHelpModel, coords)
    abilityHelpModel:SetIsVisible(false)
end

function StructureAbility:GetStoreBuildId()
    return false
end    

// Child should override
function StructureAbility:GetEnergyCost(player)
    assert(false)
end

// Child should override
function StructureAbility:GetDropStructureId()
    assert(false)
end

// Child should override
function StructureAbility:GetRequiredTechId()
    assert(false)
end

function StructureAbility:GetGhostModelName(ability)
    assert(false)
end

// Child should override ("hydra", "cyst", etc.). 
function StructureAbility:GetSuffixName()
    assert(false)
end

// Child should override ("Hydra")
function StructureAbility:GetDropClassName()
    assert(false)
end

// Child should override 
function StructureAbility:GetDropMapName()
    assert(false)
end

function StructureAbility:CreateStructure()
	return false
end

function StructureAbility:IsAllowed(player)

    local structures = GetEntitiesForTeamWithinRange(self:GetDropClassName(), player:GetTeamNumber(), player:GetEyePos(), kMaxAlienStructureRange)
    return #structures < kMaxAlienStructuresofType
end

