// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\DropStructureAbility.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/CragAbility.lua")
Script.Load("lua/Weapons/Alien/ShiftAbility.lua")
Script.Load("lua/Weapons/Alien/ShadeAbility.lua")
Script.Load("lua/Weapons/Alien/WhipAbility.lua")

class 'DropStructureAbility' (Ability)

local kMaxStructuresPerType = 20

DropStructureAbility.kMapName = "drop_structure_ability"

DropStructureAbility.kCircleModelName = PrecacheAsset("models/misc/circle/circle_alien.model")
local kCreateFailSound = PrecacheAsset("sound/NS2.fev/alien/gorge/create_fail")
local kAnimationGraph = PrecacheAsset("models/alien/gorge/gorge_view.animation_graph")

DropStructureAbility.kSupportedStructures = { CragStructureAbility, ShiftStructureAbility, ShadeStructureAbility, WhipStructureAbility }

local networkVars =
{
    lastSecondaryAttackTime = "float",
    lastCreatedId = "entityid"
}

function DropStructureAbility:GetAnimationGraphName()
    return kAnimationGraph
end

function DropStructureAbility:GetActiveStructure()
	return DropStructureAbility.kSupportedStructures[self.activeStructure]
end

function DropStructureAbility:OnCreate()

    Ability.OnCreate(self)
    
    self.dropping = false
    self.showGhost = false
    self.droppedStructure = false
    self.activeStructure = 1
    self.lastSecondaryAttackTime = 0
    self.lastCreatedId = Entity.invalidId
    
end

function DropStructureAbility:GetDeathIconIndex()
    return kDeathMessageIcon.Consumed
end

function DropStructureAbility:SetActiveStructure(structureNum)

    self.activeStructure = structureNum
    self.showGhost = true
    self.droppedStructure = false
    
end

function DropStructureAbility:GetSecondaryTechId()
    return kTechId.Spray
end

function DropStructureAbility:GetNumStructuresBuilt(techId)
    return -1
end

function DropStructureAbility:OnPrimaryAttack(player)

    if Client then

        if not self.dropping then
        
            if self:PerformPrimaryAttack(player) then
            
                self.dropping = true
                self.showGhost = false
                
            end

        end
    
    end

end

function DropStructureAbility:OnPrimaryAttackEnd(player)

    if not Shared.GetIsRunningPrediction() then
    
        if Client and self.dropping then
            self:OnSetActive()
        end

        self.dropping = false
        
    end
    
end

function DropStructureAbility:GetIsDropping()
    return self.dropping
end

function DropStructureAbility:GetEnergyCost(player)
    return kDropStructureEnergyCost
end

// Child should override
function DropStructureAbility:GetDropStructureId()
    assert(false)
end

function DropStructureAbility:GetDamageType()
    return kHealsprayDamageType
end

// Child should override ("hydra", "crap", etc.). 
function DropStructureAbility:GetSuffixName()
    assert(false)
end

// Child should override ("Hydra")
function DropStructureAbility:GetDropClassName()
    assert(false)
end

function DropStructureAbility:GetHUDSlot()
    return 3
end

function DropStructureAbility:GetHasSecondary(player)
    return true
end

function DropStructureAbility:OnSecondaryAttack(player)

    self.droppedStructure = true
        
    //if player and self.previousWeaponMapName and player:GetWeapon(self.previousWeaponMapName) then
        //player:SetActiveWeapon(self.previousWeaponMapName)
    //end
            
    if player and player:GetWeapon("spitspray") then
        player:SetActiveWeapon("spitspray")
    end
    
end

function DropStructureAbility:GetSecondaryEnergyCost(player)
    return 0
end

function DropStructureAbility:PerformPrimaryAttack(player)

    local success = true

    // Ensure the current location is valid for placement.
    local coords, valid = self:GetPositionForStructure(player:GetEyePos(), player:GetViewCoords().zAxis, self:GetActiveStructure())
    if valid then
    
        // Ensure they have enough resources.
        local cost = GetCostForTech(self:GetActiveStructure().GetDropStructureId())
        if player:GetResources() >= cost then

            local message = BuildGorgeDropStructureMessage(player:GetEyePos(), player:GetViewCoords().zAxis, self.activeStructure)
            Client.SendNetworkMessage("GorgeBuildStructure", message, true)
            
        else
            player:TriggerInvalidSound()
            success = false
        end
        
    else
        player:TriggerInvalidSound()
        success = false
    end
        
    return success
    
end

local function DropStructure(self, player, origin, direction, structureAbility)

    // If we have enough resources
    if Server then
    
        local coords, valid, onEntity = self:GetPositionForStructure(origin, direction, structureAbility)
        local techId = structureAbility:GetDropStructureId() 
        local cost = LookupTechData(structureAbility:GetDropStructureId(), kTechDataCostKey, 0)
        local enoughRes = player:GetResources() >= cost
        
        if valid and enoughRes and structureAbility:IsAllowed(player) then
        
            // Create structure
            // Check for override of Technode availablitiy
            local structure = self:CreateStructure(coords, player, structureAbility)
            if structure and UpgradeBaseHivetoChamberSpecific(player, techId) then
            
                structure:SetOwner(player)
                player:GetTeam():AddGorgeStructure(player, structure)
                // Check for space
                if structure:SpaceClearForEntity(coords.origin) then
                    player:AddResources(-cost)
                    self:TriggerEffects("spit_structure", {effecthostcoords = Coords.GetLookIn(origin, direction)} )
                    return true
                else
                    player:TriggerInvalidSound()
                    DestroyEntity(structure)
                end
                
            else
                player:TriggerInvalidSound()
                DestroyEntity(structure)
            end
            
        else
        
            if not valid then
                player:TriggerInvalidSound()
            elseif not enoughRes then
                player:TriggerInvalidSound()
            end
            
        end
        
    end
    return true
end

function DropStructureAbility:OnDropStructure(origin, direction, structureIndex)

    local player = self:GetParent()
        
    if player then
    
        local structureAbility = DropStructureAbility.kSupportedStructures[structureIndex]        
        if structureAbility then        
             DropStructure(self, player, origin, direction, structureAbility)
        end
        
    end
    
end

function DropStructureAbility:CreateStructure(coords, player, structureAbility)
	local created_structure = structureAbility:CreateStructure(coords, player)
	if created_structure then 
		return created_structure
	else
    	return CreateEntity(structureAbility:GetDropMapName(), coords.origin, player:GetTeamNumber())
    end
end

// Given a gorge player's position and view angles, return a position and orientation
// for structure. Used to preview placement via a ghost structure and then to create it.
// Also returns bool if it's a valid position or not.
function DropStructureAbility:GetPositionForStructure(startPosition, direction, structureAbility)

    PROFILE("DropStructureAbility:GetPositionForStructure")

    local validPosition = false
    local range = structureAbility.GetDropRange()
    local origin = startPosition + direction * range
    local player = self:GetParent()

    // Trace short distance in front
    local trace = Shared.TraceRay(player:GetEyePos(), origin, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
    
    local displayOrigin = trace.endPoint
    
    // If we hit nothing, trace down to place on ground
    if trace.fraction == 1 then
    
        origin = startPosition + direction * range
        trace = Shared.TraceRay(origin, origin - Vector(0, range, 0), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
        
    end
    
    // If it hits something, position on this surface (must be the world or another structure)
    if trace.fraction < 1 then
    	if trace.entity == nil then
        	validPosition = true
		end
        
        displayOrigin = trace.endPoint
        
    end
    
    // Don't allow dropped structures to go too close to techpoints and resource nozzles
    if GetPointBlocksAttachEntities(displayOrigin) then
        validPosition = false
    end
    
    if not structureAbility:GetIsPositionValid(displayOrigin, player) then
        validPosition = false
    end    
    
    // Don't allow placing above or below us and don't draw either
    local structureFacing = Vector(direction)
    
    if math.abs(Math.DotProduct(trace.normal, structureFacing)) > 0.9 then
        structureFacing = trace.normal:GetPerpendicular()
    end
    
    // Coords.GetLookIn will prioritize the direction when constructing the coords,
    // so make sure the facing direction is perpendicular to the normal so we get
    // the correct y-axis.
    local perp = Math.CrossProduct( trace.normal, structureFacing )
    structureFacing = Math.CrossProduct( perp, trace.normal )
    
    local coords = Coords.GetLookIn( displayOrigin, structureFacing, trace.normal )
    
    if structureAbility.ModifyCoords then
        structureAbility:ModifyCoords(coords)
    end
    
    return coords, validPosition, trace.entity

end

function DropStructureAbility:OnDraw(player, previousWeaponMapName)

    Ability.OnDraw(self, player, previousWeaponMapName)

    self.previousWeaponMapName = previousWeaponMapName
    self.dropping = false

end


function DropStructureAbility:OnUpdateAnimationInput(modelMixin)

    PROFILE("DropStructureAbility:OnUpdateAnimationInput")

    modelMixin:SetAnimationInput("ability", "chamber")
    
    local activityString = "none"
    if self.dropping then
        activityString = "primary"
    end
    modelMixin:SetAnimationInput("activity", activityString)
    
end

function DropStructureAbility:ProcessMoveOnWeapon(input)

    // Show ghost if we're able to create structure, and if menu is not visible
    local player = self:GetParent()
    if player then
    
        if Client then

            // Update ghost position 
            if self.showGhost then
            
                if not self.abilityHelpModel then
                    
                    // Create build circle to show hydra range
                    self.circle = Client.CreateRenderModel(RenderScene.Zone_Default)
                    self.circle:SetModel( Shared.GetModelIndex(DropStructureAbility.kCircleModelName) )
                    
                    self.abilityHelpModel = Client.CreateRenderModel(RenderScene.Zone_Default)
                    self.abilityHelpModel:SetCastsShadows(false)
                    
                    
                end
            
                self.ghostCoords, valid = self:GetPositionForStructure(player:GetEyePos(), player:GetViewCoords().zAxis, self:GetActiveStructure())
                
                if not valid then
                    self.abilityHelpModel:SetIsVisible(false)
                end
                
                if valid then
                    self:GetActiveStructure():OnUpdateHelpModel(self, self.abilityHelpModel, self.ghostCoords)
                end
                
                if player:GetResources() < LookupTechData(self:GetActiveStructure().GetDropStructureId(), kTechDataCostKey) then
                    valid = false
                end
                
                // Scale and position circle to show range
                if self.circle then
                
                    local coords = Coords.GetLookIn( self.ghostCoords.origin + Vector(0, .01, 0), Vector.xAxis )
                    coords:Scale( 2 * Hydra.kRange )
                    self.circle:SetCoords(coords)
                    self.circle:SetIsVisible(valid)
                    
                end
                
                self.placementValid = valid
                
            end
        end    
    end
    
end

function DropStructureAbility:GetShowGhostModel()
    return self.showGhost
end

function DropStructureAbility:GetUnassignedHives()
    return self.unassignedhives
end

function DropStructureAbility:GetGhostModelCoords()
    return self.ghostCoords
end   

function DropStructureAbility:GetIsPlacementValid()
    return self.placementValid
end

if Client then

    function DropStructureAbility:OnSetActive()
    
        if not Shared.GetIsRunningPrediction() then
    
            if not self.buildMenu then
            
                self.buildMenu = GetGUIManager():CreateGUIScript("GUIGorgeBuildMenu")
                self.droppedStructure = false
                self.showGhost = false
                
            end
        
        end
    
    end

    function DropStructureAbility:DestroyStructureGhost()
        
        if self.abilityHelpModel ~= nil then
        
            Client.DestroyRenderModel(self.abilityHelpModel)
            self.abilityHelpModel = nil
            
        end
        
        if self.circle ~= nil then
        
            Client.DestroyRenderModel(self.circle)
            self.circle = nil
            
            
        end
        
    end
    
    function DropStructureAbility:DestroyBuildMenu()
    
        if self.buildMenu ~= nil then
        
            GetGUIManager():DestroyGUIScript(self.buildMenu)
            self.buildMenu = nil
        
        end
    
    end

    function DropStructureAbility:OnDestroy()
    
        self:DestroyStructureGhost()
        self:DestroyBuildMenu()
        
        Ability.OnDestroy(self)
        
    end

    function DropStructureAbility:OnHolster(player)
    
        Ability.OnHolster(self, player)
        
        self:DestroyStructureGhost()
        self:DestroyBuildMenu()
        
    end
    
    function DropStructureAbility:OverrideInput(input)
    
        if self.buildMenu then
            input = self.buildMenu:OverrideInput(input)
        end
        
        return input
        
    end
    
end

Shared.LinkClassToMap("DropStructureAbility", DropStructureAbility.kMapName, networkVars)