//
// lua\Weapons\Alien\DropStructureAbility2.lua

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/HydraAbility.lua")
Script.Load("lua/Weapons/Alien/WebAbility.lua")
Script.Load("lua/Weapons/Alien/HarvesterAbility.lua")
Script.Load("lua/Weapons/Alien/HiveAbility.lua")

class 'DropStructureAbility2' (Ability)

local kMaxStructuresPerType = 20

DropStructureAbility2.kMapName = "drop_structure_ability2"

DropStructureAbility2.kCircleModelName = PrecacheAsset("models/misc/circle/circle_alien.model")
local kCreateFailSound = PrecacheAsset("sound/NS2.fev/alien/gorge/create_fail")
local kAnimationGraph = PrecacheAsset("models/alien/gorge/gorge_view.animation_graph")

DropStructureAbility2.kSupportedStructures = { HarvesterStructureAbility, HiveStructureAbility, HydraStructureAbility, WebStructureAbility }

local networkVars =
{
    activeStructure = string.format("private integer (1 to %d)", table.count(DropStructureAbility2.kSupportedStructures)),
    dropping = "private boolean",
    showGhost = "private boolean",
    lastSecondaryAttackTime = "float",
    lastCreatedId = "entityid",
    droppedStructure = "boolean"
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

function DropStructureAbility2:GetNumStructuresBuilt(techId)
    return -1
end

function DropStructureAbility2:GetIsDropping()
    return self.dropping
end

function DropStructureAbility2:GetEnergyCost(player)
    return self:GetActiveStructure():GetEnergyCost(player)
end

function DropStructureAbility2:GetIconOffsetY(secondary)
    return self:GetActiveStructure():GetIconOffsetY(secondary)
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
    return 3
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

// Check before energy is spent if a structure can be built in the current location.
function DropStructureAbility2:OnPrimaryAttack(player)

    if not self.dropping and not self.droppedStructure then
    
        // Ensure the current location is valid for placement.
        local coords, valid = self:GetPositionForStructure(player)
        if valid then
        
            // Ensure they have enough resources.
            local cost = GetCostForTech(self:GetActiveStructure():GetDropStructureId())
            if player:GetResources() >= cost then
                Ability.OnPrimaryAttack(self, player)
            else
                StartSoundEffectForPlayer(kCreateFailSound, player)
            end
            
        elseif not player:GetPrimaryAttackLastFrame() then
            StartSoundEffectForPlayer(kCreateFailSound, player)
        end
        
    end
    
end

local function DropStructure(self, player)

    // If we have enough resources
    if Server then
    
        local coords, valid, onEntity = self:GetPositionForStructure(player)
        local techId = self:GetActiveStructure():GetDropStructureId()
        
        valid = valid and self:GetNumStructuresBuilt(techId) ~= maxStructures // -1 is unlimited
        
        local cost = LookupTechData(self:GetActiveStructure():GetDropStructureId(), kTechDataCostKey, 0)
        local enoughRes = player:GetResources() >= cost
        
        if valid and enoughRes and self:GetActiveStructure():IsAllowed(player) then
        
            if techId == kTechId.Hive or techId == kTechId.Harvester then
                local success = false
                if techId == kTechId.Hive then
                    local BuildingHives = 0
                    for index, hive in ipairs(GetEntitiesForTeam("Hive", self:GetTeamNumber())) do
                        if not hive:GetIsBuilt() then
                            BuildingHives = BuildingHives + 1
                        end
                    end
                    if BuildingHives < kMaxBuildingHives then
                        success, entid = player:AttemptToBuild(techId, coords.origin, nil, nil, nil, nil, self, nil, player)
                    end
                else
                    success, entid = player:AttemptToBuild(techId, coords.origin, nil, nil, nil, nil, self, nil, player)
                end

                if success then
                    player:AddResources(-cost)     
                    if entid then
                        self.lastCreatedId = entid
                    end 
                    self.droppedStructure = true
            
                else
                
                    StartSoundEffectForPlayer(kCreateFailSound, player)
                end
            
            else
                // Create structure
                local structure = self:CreateStructure(coords, player)
                if structure then
                
                    structure:SetOwner(player)
                    player:GetTeam():AddGorgeStructure(player, structure)
                    
                    // Check for space
                    if structure:SpaceClearForEntity(coords.origin) then
                    
                        local angles = Angles()
                        angles:BuildFromCoords(coords)
                        structure:SetAngles(angles)
                        
                        if structure.OnCreatedByGorge then
                            structure:OnCreatedByGorge(self.lastCreatedId)
                        end
                        
                        player:AddResources(-cost)
                        
                        if self:GetActiveStructure():GetStoreBuildId() then
                            self.lastCreatedId = structure:GetId()
                        end
                        
                        // Jackpot
                        self.droppedStructure = true
                        return true
                        
                    else
                        StartSoundEffectForPlayer(kCreateFailSound, player)
                        DestroyEntity(structure)     
                    end
                end
            end
            
        else
        
            if not valid then
                StartSoundEffectForPlayer(kCreateFailSound, player)
            elseif not enoughRes then
                StartSoundEffectForPlayer(kCreateFailSound, player)
            end
            
        end
        
    end
    
    StartSoundEffectForPlayer(kCreateFailSound, player)
    
    return false
    
end

function DropStructureAbility2:PerformPrimaryAttack(player)

    local success = true
    
    if self.showGhost then
    
        self.dropping = true
        
        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
        
        // trigger locally and also for other players
        local cost = LookupTechData(self:GetActiveStructure():GetDropStructureId(), kTechDataCostKey)
        if player:GetResources() >= cost then
            self:TriggerEffects("spit_structure", {effecthostcoords = Coords.GetLookIn(player:GetEyePos() + viewCoords.zAxis * 0.4, player:GetViewCoords().zAxis)} )
        end
        
        success = DropStructure(self, player)
        
    end
    
    return success
    
end

function DropStructureAbility2:CreateStructure(coords, player)
	local created_structure = self:GetActiveStructure():CreateStructure(coords, player)
	if created_structure then 
		return created_structure
	else
    	return CreateEntity( self:GetActiveStructure():GetDropMapName(), coords.origin, player:GetTeamNumber() )
    end
end

// Given a gorge player's position and view angles, return a position and orientation
// for structure. Used to preview placement via a ghost structure and then to create it.
// Also returns bool if it's a valid position or not.
function DropStructureAbility2:GetPositionForStructure(player)

    PROFILE("DropStructureAbility2:GetPositionForStructure")

    local validPosition = false
    local range = self:GetActiveStructure():GetDropRange()
    local origin = player:GetEyePos() + player:GetViewAngles():GetCoords().zAxis * range

    // Trace short distance in front
    local trace = Shared.TraceRay(player:GetEyePos(), origin, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
    
    local displayOrigin = trace.endPoint
    
    // If we hit nothing, trace down to place on ground
    if trace.fraction == 1 then
    
        origin = player:GetEyePos() + player:GetViewAngles():GetCoords().zAxis * range
        trace = Shared.TraceRay(origin, origin - Vector(0, range, 0), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
        
    end
    
    // If it hits something, position on this surface (must be the world or another structure)
    if trace.fraction < 1 then
    
        validPosition = true
        
        displayOrigin = trace.endPoint
        
    end
    
    // Don't allow dropped structures to go too close to techpoints and resource nozzles
    if GetPointBlocksAttachEntities(displayOrigin) then
        validPosition = false
    end
    
    if not self:GetActiveStructure():GetIsPositionValid(displayOrigin, player) then
        validPosition = false
    end    
    
    // Don't allow placing above or below us and don't draw either
    local structureFacing = player:GetViewAngles():GetCoords().zAxis
    
    if math.abs(Math.DotProduct(trace.normal, structureFacing)) > 0.9 then
        structureFacing = trace.normal:GetPerpendicular()
    end
    
    // Coords.GetLookIn will prioritize the direction when constructing the coords,
    // so make sure the facing direction is perpendicular to the normal so we get
    // the correct y-axis.
    local perp = Math.CrossProduct( trace.normal, structureFacing )
    structureFacing = Math.CrossProduct( perp, trace.normal )
    
    local coords = Coords.GetLookIn( displayOrigin, structureFacing, trace.normal )
    
    if self:GetActiveStructure():GetDropStructureId() == kTechId.Harvester or self:GetActiveStructure():GetDropStructureId() == kTechId.Hive then
        local valid, position, attachEntity = GetIsBuildLegal(self:GetActiveStructure():GetDropStructureId(), trace.endPoint, Commander.kStructureSnapRadius, player)
        if attachEntity then
            coords = attachEntity:GetAngles():GetCoords()
            coords.origin = position
            validPosition = true
        else
            validPosition = false
        end
    end
    
    if self:GetActiveStructure().ModifyCoords then
        self:GetActiveStructure():ModifyCoords(coords)
    end
    
    return coords, validPosition, trace.entity

end

function DropStructureAbility2:OnDraw(player, previousWeaponMapName)

    Ability.OnDraw(self, player, previousWeaponMapName)

    self.previousWeaponMapName = previousWeaponMapName
    self.dropping = false

end

function DropStructureAbility2:OnTag(tagName)

    PROFILE("DropStructureAbility2:OnTag")

    if self.dropping and tagName == "shoot" then
    
        self.dropping = false
        self.droppedStructure = true
        // switch to previous weapon
        local player = self:GetParent()
        
        //if player and self.previousWeaponMapName and player:GetWeapon(self.previousWeaponMapName) then
            //player:SetActiveWeapon(self.previousWeaponMapName)
        //end
        if player and player:GetWeapon("spitspray") then
            player:SetActiveWeapon("spitspray")
        end
        
    end
    
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
    self.showGhost = not self.dropping and not self.droppedStructure
    local player = self:GetParent()
    
    if Server then
    
    
    elseif Client and not Shared.GetIsRunningPrediction() then

        if player then

            // Update ghost position 
            if self.showGhost then
            
                if not self.abilityHelpModel then
                    
                    // Create build circle to show hydra range
                    self.circle = Client.CreateRenderModel(RenderScene.Zone_Default)
                    self.circle:SetModel( Shared.GetModelIndex(DropStructureAbility2.kCircleModelName) )
                    
                    self.abilityHelpModel = Client.CreateRenderModel(RenderScene.Zone_Default)
                    self.abilityHelpModel:SetCastsShadows(false)
                    
                    
                end
            
                self.ghostCoords, valid = self:GetPositionForStructure(player)
                
                if not valid then
                    self.abilityHelpModel:SetIsVisible(false)
                end
                
                if valid then
                    self:GetActiveStructure():OnUpdateHelpModel(self, self.abilityHelpModel, self.ghostCoords)
                end
                
                if player:GetResources() < LookupTechData(self:GetActiveStructure():GetDropStructureId(), kTechDataCostKey) then
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

function DropStructureAbility2:GetGhostModelCoords()
    return self.ghostCoords
end   

function DropStructureAbility2:GetIsPlacementValid()
    return self.placementValid
end

if Server then

    function DropStructureAbility2:OnSetActive()
        self.dropping = false
        self.droppedStructure = true // prevents ghost model from showing before we select a structure
    end

    function DropStructureAbility2:SetStructureActive(index)
    
        local player = self:GetParent()
        local cost = LookupTechData(DropStructureAbility2.kSupportedStructures[index].GetDropStructureId(), kTechDataCostKey, 0)
        if player and player:GetResources() >= cost and DropStructureAbility2.kSupportedStructures[index]:IsAllowed(self:GetParent()) then
            self.activeStructure = index
            self.droppedStructure = false
        end
    
    end

elseif Client then

    function DropStructureAbility2:OnSetActive()
    
        if not self.buildMenu then
            self.buildMenu = GetGUIManager():CreateGUIScript("GUIGorgeBuildMenu")
            self.buildMenu:SetSupportedStructures(DropStructureAbility2.kSupportedStructures)
            //MouseTracker_SetIsVisible(true, nil, true)
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
        
            //MouseTracker_SetIsVisible(false)
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