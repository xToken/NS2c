//
// lua\Weapons\Alien\DropStructureAbility2.lua

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/HydraAbility.lua")
Script.Load("lua/Weapons/Alien/WebAbility.lua")
Script.Load("lua/Weapons/Alien/HarvesterAbility.lua")
Script.Load("lua/Weapons/Alien/HiveAbility.lua")

class 'DropStructureAbility2' (Ability)

DropStructureAbility2.kMapName = "drop_structure_ability2"

DropStructureAbility2.kCircleModelName = PrecacheAsset("models/misc/circle/circle_alien.model")
local kCreateFailSound = PrecacheAsset("sound/NS2.fev/alien/gorge/create_fail")
local kAnimationGraph = PrecacheAsset("models/alien/gorge/gorge_view.animation_graph")

DropStructureAbility2.kSupportedStructures = { HarvesterStructureAbility, HiveStructureAbility, HydraStructureAbility, WebStructureAbility }

local networkVars =
{
    lastSecondaryAttackTime = "float",
    lastCreatedId = "entityid"
}

function DropStructureAbility2:GetAnimationGraphName()
    return kAnimationGraph
end

function DropStructureAbility2:GetActiveStructure()
	return DropStructureAbility2.kSupportedStructures[self.activeStructure]
end

function DropStructureAbility2:OnCreate()

    Ability.OnCreate(self)
    
    self.dropping = false
    self.showGhost = false
    self.droppedStructure = false
    self.activeStructure = 1
    self.lastSecondaryAttackTime = 0
    self.lastCreatedId = Entity.invalidId
    
end

function DropStructureAbility2:GetDeathIconIndex()
    return kDeathMessageIcon.Consumed
end

function DropStructureAbility2:SetActiveStructure(structureNum)

    self.activeStructure = structureNum
    self.showGhost = true
    self.droppedStructure = false
    
end

function DropStructureAbility2:GetSecondaryTechId()
    return kTechId.Spray
end

function DropStructureAbility2:GetNumStructuresBuilt(techId)
    return -1
end

function DropStructureAbility2:OnPrimaryAttack(player)

    if Client then

        if not self.dropping then
        
            if self:PerformPrimaryAttack(player) then
            
                self.dropping = true
                self.showGhost = false
                
            end

        end
    
    end

end

function DropStructureAbility2:OnPrimaryAttackEnd(player)

    if not Shared.GetIsRunningPrediction() then
    
        if Client and self.dropping then
            self:OnSetActive()
        end

        self.dropping = false
        
    end
    
end

function DropStructureAbility2:GetIsDropping()
    return self.dropping
end

function DropStructureAbility2:GetEnergyCost(player)
    return kDropStructureEnergyCost
end

// Child should override
function DropStructureAbility2:GetDropStructureId()
    assert(false)
end

function DropStructureAbility2:GetDamageType()
    return kHealsprayDamageType
end

// Child should override ("hydra", "crap", etc.). 
function DropStructureAbility2:GetSuffixName()
    assert(false)
end

// Child should override ("Hydra")
function DropStructureAbility2:GetDropClassName()
    assert(false)
end

function DropStructureAbility2:GetHUDSlot()
    return 4
end

function DropStructureAbility2:GetHasSecondary(player)
    return true
end

function DropStructureAbility2:OnSecondaryAttack(player)

    self.droppedStructure = true
        
    //if player and self.previousWeaponMapName and player:GetWeapon(self.previousWeaponMapName) then
        //player:SetActiveWeapon(self.previousWeaponMapName)
    //end
            
    if player and player:GetWeapon("spitspray") then
        player:SetActiveWeapon("spitspray")
    end
    
end

function DropStructureAbility2:GetSecondaryEnergyCost(player)
    return 0
end

function DropStructureAbility2:PerformPrimaryAttack(player)

    local success = true

    // Ensure the current location is valid for placement.
    local coords, valid = self:GetPositionForStructure(player:GetEyePos(), player:GetViewCoords().zAxis, self:GetActiveStructure())
    if valid then
    
        // Ensure they have enough resources.
        local cost = GetCostForTech(self:GetActiveStructure().GetDropStructureId())
        if player:GetResources() >= cost then

            local message = BuildGorgeDropStructureMessage(player:GetEyePos(), player:GetViewCoords().zAxis, self.activeStructure)
            Client.SendNetworkMessage("GorgeBuildStructure2", message, true)
            
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
        
            if techId == kTechId.Hive or techId == kTechId.Harvester then
                if techId == kTechId.Hive then
                    local BuildingHives = 0
                    for index, hive in ipairs(GetEntitiesForTeam("Hive", self:GetTeamNumber())) do
                        if not hive:GetIsBuilt() then
                            BuildingHives = BuildingHives + 1
                        end
                    end
                    if BuildingHives >= kMaxBuildingHives then
                        player:TriggerInvalidSound()
                        return true
                    end
                end
                
                local success, entid = player:AttemptToBuild(techId, coords.origin, nil, 0, nil, false, self, nil, player)
    
                if success then
                    player:AddResources(-cost)     
                    self:TriggerEffects("spit_structure", {effecthostcoords = Coords.GetLookIn(origin, direction)} )
                    return true
                else
                    player:TriggerInvalidSound()
                end
                
            else
                local structure = self:CreateStructure(coords, player, structureAbility)
                if structure then
                    structure:SetOwner(player)
                    player:GetTeam():AddGorgeStructure(player, structure)
                    if structure:SpaceClearForEntity(coords.origin) then
                        local angles = Angles()
                        angles:BuildFromCoords(coords)
                        structure:SetAngles(angles)
                        player:AddResources(-cost)
                        self:TriggerEffects("spit_structure", {effecthostcoords = Coords.GetLookIn(origin, direction)} )
                        return true
                    else
                        player:TriggerInvalidSound()
                        DestroyEntity(structure)
                    end
                else
                   player:TriggerInvalidSound()
                end
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

function DropStructureAbility2:OnDropStructure(origin, direction, structureIndex)

    local player = self:GetParent()
        
    if player then
    
        local structureAbility = DropStructureAbility2.kSupportedStructures[structureIndex]        
        if structureAbility then        
             DropStructure(self, player, origin, direction, structureAbility)
        end
        
    end
    
end

function DropStructureAbility2:CreateStructure(coords, player, structureAbility)
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
function DropStructureAbility2:GetPositionForStructure(startPosition, direction, structureAbility)
    
    PROFILE("DropStructureAbility2:GetPositionForStructure")

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

	if structureAbility:GetDropStructureId() == kTechId.Harvester or structureAbility:GetDropStructureId() == kTechId.Hive then
    	local techId = structureAbility:GetDropStructureId()
	    local checkBypass = { }
	    checkBypass["ValidExit"] = true
	    local validBuild, legalPosition, attachEntity, errorString = GetIsBuildLegal(techId, displayOrigin, direction, range, player, false, checkBypass)
	    validPosition = validBuild
        if attachEntity then
            coords = attachEntity:GetAngles():GetCoords()
            coords.origin = legalPosition
        end
	end
    
    if structureAbility.ModifyCoords then
        structureAbility:ModifyCoords(coords)
    end
    
    return coords, validPosition, trace.entity

end

function DropStructureAbility2:OnDraw(player, previousWeaponMapName)

    Ability.OnDraw(self, player, previousWeaponMapName)

    self.previousWeaponMapName = previousWeaponMapName
    self.dropping = false

end


function DropStructureAbility2:OnUpdateAnimationInput(modelMixin)

    PROFILE("DropStructureAbility2:OnUpdateAnimationInput")

    modelMixin:SetAnimationInput("ability", "chamber")
    
    local activityString = "none"
    if self.dropping then
        activityString = "primary"
    end
    modelMixin:SetAnimationInput("activity", activityString)
    
end

function DropStructureAbility2:ProcessMoveOnWeapon(input)

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

function DropStructureAbility2:GetShowGhostModel()
    return self.showGhost
end

function DropStructureAbility2:GetUnassignedHives()
    return self.unassignedhives
end

function DropStructureAbility2:GetGhostModelCoords()
    return self.ghostCoords
end   

function DropStructureAbility2:GetIsPlacementValid()
    return self.placementValid
end

if Client then

    function DropStructureAbility2:OnSetActive()
    
        if not Shared.GetIsRunningPrediction() then
    
            if not self.buildMenu then
            
                self.buildMenu = GetGUIManager():CreateGUIScript("GUIGorgeBuildMenu2")
                self.droppedStructure = false
                self.showGhost = false
                
            end
        
        end
    
    end

    function DropStructureAbility2:DestroyStructureGhost()
        
        if self.abilityHelpModel ~= nil then
        
            Client.DestroyRenderModel(self.abilityHelpModel)
            self.abilityHelpModel = nil
            
        end
        
        if self.circle ~= nil then
        
            Client.DestroyRenderModel(self.circle)
            self.circle = nil
            
            
        end
        
    end
    
    function DropStructureAbility2:DestroyBuildMenu()
    
        if self.buildMenu ~= nil then
        
            GetGUIManager():DestroyGUIScript(self.buildMenu)
            self.buildMenu = nil
        
        end
    
    end

    function DropStructureAbility2:OnDestroy()
    
        self:DestroyStructureGhost()
        self:DestroyBuildMenu()
        
        Ability.OnDestroy(self)
        
    end

    function DropStructureAbility2:OnHolster(player)
    
        Ability.OnHolster(self, player)
        
        self:DestroyStructureGhost()
        self:DestroyBuildMenu()
        
    end
    
    function DropStructureAbility2:OverrideInput(input)
    
        if self.buildMenu then
            input = self.buildMenu:OverrideInput(input)
        end
        
        return input
        
    end
    
end

Shared.LinkClassToMap("DropStructureAbility2", DropStructureAbility2.kMapName, networkVars)