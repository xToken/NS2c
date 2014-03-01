// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\DropStructureAbility.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Added in additional build abilities

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/HydraAbility.lua")
Script.Load("lua/Weapons/Alien/WebsAbility.lua")
Script.Load("lua/Weapons/Alien/BabblerEggAbility.lua")
Script.Load("lua/Weapons/Alien/CragAbility.lua")
Script.Load("lua/Weapons/Alien/ShiftAbility.lua")
Script.Load("lua/Weapons/Alien/ShadeAbility.lua")
Script.Load("lua/Weapons/Alien/WhipAbility.lua")
Script.Load("lua/Weapons/Alien/HarvesterAbility.lua")
Script.Load("lua/Weapons/Alien/HiveAbility.lua")

class 'DropStructureAbility' (Ability)

local kMaxStructuresPerType = 5
local kDropCooldown = 1

DropStructureAbility.kMapName = "drop_structure_ability"

local kCreateFailSound = PrecacheAsset("sound/NS2.fev/alien/gorge/create_fail")
local kAnimationGraph = PrecacheAsset("models/alien/gorge/gorge_view.animation_graph")

DropStructureAbility.kSupportedStructures = { CragStructureAbility, ShiftStructureAbility, ShadeStructureAbility, WhipStructureAbility, HarvesterStructureAbility, HiveStructureAbility, HydraStructureAbility, WebsAbility, BabblerEggAbility }

local networkVars =
{
    numWebsLeft = string.format("private integer (0 to %d)", kMaxStructuresPerType),
    numBabblersLeft = string.format("private integer (0 to %d)", kMaxStructuresPerType),
    lastPrimaryAttackTime = "time"
}

function DropStructureAbility:GetAnimationGraphName()
    return kAnimationGraph
end

function DropStructureAbility:GetActiveStructure()

    if self.activeStructure == nil then
        return nil
    else
        return DropStructureAbility.kSupportedStructures[self.activeStructure]
    end

end

function DropStructureAbility:OnCreate()

    Ability.OnCreate(self)
    
    self.dropping = false
    self.mouseDown = false
    self.activeStructure = nil
	self.lastClickedPosition = nil
    self.lastPrimaryAttackTime = 0
    self.numBabblersLeft = 0
    self.numWebsLeft = 0
    if Server then
        self.lastCreatedId = Entity.invalidId
    end

    
end

function DropStructureAbility:GetDeathIconIndex()
    return kDeathMessageIcon.Consumed
end

function DropStructureAbility:SetActiveStructure(structureNum)
    self.activeStructure = structureNum
	self.lastClickedPosition = nil
end

function DropStructureAbility:GetSecondaryTechId()
    return kTechId.Spray
end

function DropStructureAbility:GetNumStructuresBuilt(techId)
    if techId == kTechId.Web then
        return self.numWebsLeft
    end
    if techId == kTechId.BabblerEgg then
        return self.numBabblersLeft
    end
    return -1
end

function DropStructureAbility:OnPrimaryAttack(player)

    if Client then

        if self.activeStructure ~= nil
        and not self.dropping
        and not self.mouseDown then
        
            self.mouseDown = true
        
            if player:GetEnergy() >= kDropStructureEnergyCost then
            
                if self:PerformPrimaryAttack(player) then
                    self.dropping = true
                end

            else
                player:TriggerInvalidSound()
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
        self.mouseDown = false
        
    end
    
end

function DropStructureAbility:GetIsDropping()
    return self.dropping
end

function DropStructureAbility:GetEnergyCost(player)
    return kDropStructureEnergyCost
end

function DropStructureAbility:GetHUDSlot()
    return 2
end

function DropStructureAbility:GetHasDropCooldown()
    return self.timeLastDrop ~= nil and self.timeLastDrop + kDropCooldown > Shared.GetTime()
end

function DropStructureAbility:GetHasSecondary(player)
    return true
end

function DropStructureAbility:OnSecondaryAttack(player)

    if player and self.previousWeaponMapName and player:GetWeapon(self.previousWeaponMapName) then
        player:SetActiveWeapon(self.previousWeaponMapName)
    end
    
end

function DropStructureAbility:GetSecondaryEnergyCost(player)
    return 0
end

function DropStructureAbility:PerformPrimaryAttack(player)

    if self.activeStructure == nil then
        return false
    end 

    local success = false

    // Ensure the current location is valid for placement.
    local coords, valid = self:GetPositionForStructure(player:GetEyePos(), player:GetViewCoords().zAxis, self:GetActiveStructure(), self.lastClickedPosition)
    local secondClick = true
    
    if LookupTechData(self:GetActiveStructure().GetDropStructureId(), kTechDataSpecifyOrientation, false) then
        secondClick = self.lastClickedPosition ~= nil
    end
    
    if secondClick then
    
        if valid then

            // Ensure they have enough resources.
            local cost = GetCostForTech(self:GetActiveStructure().GetDropStructureId())
            if player:GetResources() >= cost and not self:GetHasDropCooldown() then

                local message = BuildGorgeDropStructureMessage(player:GetEyePos(), player:GetViewCoords().zAxis, self.activeStructure, self.lastClickedPosition)
                Client.SendNetworkMessage("GorgeBuildStructure", message, true)
                self.timeLastDrop = Shared.GetTime()
                success = true

            end
        
        end

        self.lastClickedPosition = nil
        
    end
    
    if not secondClick then
        self:TriggerEffects("web_fire")
        self.lastClickedPosition = Vector(coords.origin)
    elseif not valid then
        player:TriggerInvalidSound()
    end
        
    return success
    
end

local function DropStructure(self, player, origin, direction, structureAbility, lastClickedPosition)

    // If we have enough resources
    if Server then
    
        local coords, valid, onEntity = self:GetPositionForStructure(origin, direction, structureAbility, lastClickedPosition)
        local techId = structureAbility:GetDropStructureId()
        
        local maxStructures = -1
        
        if not LookupTechData(techId, kTechDataAllowConsumeDrop, false) then
            maxStructures = LookupTechData(techId, kTechDataMaxAmount, 0) 
        end
        
        valid = valid and self:GetNumStructuresBuilt(techId) ~= maxStructures // -1 is unlimited
        
        local cost = LookupTechData(structureAbility:GetDropStructureId(), kTechDataCostKey, 0)
        local enoughRes = player:GetResources() >= cost
        local enoughEnergy = player:GetEnergy() >= kDropStructureEnergyCost
        
        if valid and enoughRes and structureAbility:IsAllowed(player) and enoughEnergy and not self:GetHasDropCooldown() then
        
            // Create structure
            local structure = self:CreateStructure(coords, player, structureAbility)
            if structure then
            
                structure:SetOwner(player)
                player:GetTeam():AddGorgeStructure(player, structure)
                
                if onEntity and HasMixin(onEntity, "StructureFall") and HasMixin(structure, "StructureFall") then
                    onEntity:ConnectToStructure(structure)
                end
                
                // Check for space
                if structure:SpaceClearForEntity(coords.origin) then
                
                    local angles = Angles()                    
                    
                    if structure:isa("BabblerEgg") and coords.yAxis.y > 0.8 then
                        angles.yaw = math.random() * math.pi * 2
                    end
                    
                    angles:BuildFromCoords(coords)
                    structure:SetAngles(angles)
                    
                    if structure.OnCreatedByGorge then
                        structure:OnCreatedByGorge(self.lastCreatedId)
                    end
                    
                    player:AddResources(-cost)
                    
                    if structureAbility:GetStoreBuildId() then
                        self.lastCreatedId = structure:GetId()
                    end
                    
                    player:DeductAbilityEnergy(kDropStructureEnergyCost)
                    
                    if structureAbility.OnStructureCreated then
                        structureAbility:OnStructureCreated(structure, lastClickedPosition)
                    else
                        self:TriggerEffects("spit_structure", {effecthostcoords = Coords.GetLookIn(origin, direction)} )
                    end
                    
                    self.timeLastDrop = Shared.GetTime()
                    
                    return true
                    
                else
                
                    player:TriggerInvalidSound()
                    DestroyEntity(structure)
                    
                end
                
            else
                player:TriggerInvalidSound()
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

function DropStructureAbility:OnDropStructure(origin, direction, structureIndex, lastClickedPosition)

    local player = self:GetParent()
        
    if player then
    
        local structureAbility = DropStructureAbility.kSupportedStructures[structureIndex]        
        if structureAbility then        
             DropStructure(self, player, origin, direction, structureAbility, lastClickedPosition)
        end
        
    end
    
end

function DropStructureAbility:CreateStructure(coords, player, structureAbility, lastClickedPosition)
    local created_structure = structureAbility:CreateStructure(coords, player, lastClickedPosition)
    if created_structure then 
        return created_structure
    else
        return CreateEntity(structureAbility:GetDropMapName(), coords.origin, player:GetTeamNumber())
    end
end

local function FilterBabblersAndTwo(ent1, ent2)
    return function (test) return test == ent1 or test == ent2 or test:isa("Babbler") end
end

// Given a gorge player's position and view angles, return a position and orientation
// for structure. Used to preview placement via a ghost structure and then to create it.
// Also returns bool if it's a valid position or not.
function DropStructureAbility:GetPositionForStructure(startPosition, direction, structureAbility, lastClickedPosition)

    PROFILE("DropStructureAbility:GetPositionForStructure")

    local validPosition = false
    local range = structureAbility.GetDropRange()
    local origin = startPosition + direction * range
    local player = self:GetParent()
    local adjustedcoords

    // Trace short distance in front
    local trace = Shared.TraceRay(player:GetEyePos(), origin, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, FilterBabblersAndTwo(player, self))
    
    local displayOrigin = trace.endPoint
    
    // If we hit nothing, trace down to place on ground
    if trace.fraction == 1 then
    
        origin = startPosition + direction * range
        trace = Shared.TraceRay(origin, origin - Vector(0, range, 0), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, FilterBabblersAndTwo(player, self))
        
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
    
    validPosition, adjustedcoords = structureAbility:GetIsPositionValid(displayOrigin, player, trace.normal, lastClickedPosition, trace.entity)
     
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
    
    if validPosition and adjustedcoords ~= nil then
        coords = adjustedcoords
    end    
    
    if structureAbility.ModifyCoords then
        structureAbility:ModifyCoords(coords, lastClickedPosition)
    end
    
    return coords, validPosition, trace.entity

end

function DropStructureAbility:OnDraw(player, previousWeaponMapName)

    Ability.OnDraw(self, player, previousWeaponMapName)

    self.previousWeaponMapName = previousWeaponMapName
    self.dropping = false
    self.activeStructure = nil

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
    
        if Server then

            local team = player:GetTeam()
            //local hiveCount = team:GetNumHives()
            local numAllowedWebs = LookupTechData(kTechId.Web, kTechDataMaxAmount, -1) 
            local numAllowedBabblers = LookupTechData(kTechId.BabblerEgg, kTechDataMaxAmount, -1) 
            
            if numAllowedWebs >= 0 then     
                self.numWebsLeft = team:GetNumDroppedGorgeStructures(player, kTechId.Web)           
            end
            
            if numAllowedBabblers >= 0 then     
                self.numBabblersLeft = team:GetNumDroppedGorgeStructures(player, kTechId.BabblerEgg)           
            end
            
        end
        
    end    
    
end

function DropStructureAbility:GetShowGhostModel()
    return self.activeStructure ~= nil and not self:GetHasDropCooldown() 
end

function DropStructureAbility:GetGhostModelCoords()
    return self.ghostCoords
end   

function DropStructureAbility:GetIsPlacementValid()
    return self.placementValid
end

function DropStructureAbility:GetTakesSecondary()
    return LookupTechData(self:GetActiveStructure().GetDropStructureId(), kTechDataSpecifyOrientation, false)
end

function DropStructureAbility:GetGhostModelTechId()

    if self.activeStructure == nil then
        return nil
    else
        return self:GetActiveStructure():GetDropStructureId()
    end

end

function DropStructureAbility:GetGhostModelName(player)

    if self.activeStructure ~= nil and self:GetActiveStructure().GetGhostModelName then
        return self:GetActiveStructure():GetGhostModelName(self)
    end
    
    return nil
    
end

if Client then

    function DropStructureAbility:OnProcessIntermediate(input)

        local player = self:GetParent()
        local viewDirection = player:GetViewCoords().zAxis

        if player and self.activeStructure then

            self.ghostCoords, self.placementValid = self:GetPositionForStructure(player:GetEyePos(), viewDirection, self:GetActiveStructure(), self.lastClickedPosition)
            
            if player:GetResources() < LookupTechData(self:GetActiveStructure():GetDropStructureId(), kTechDataCostKey) then
                self.placementValid = false
            end
        
        end
        
    end
    
    function DropStructureAbility:CreateBuildMenu()
    
        if not self.buildMenu then        
            self.buildMenu = GetGUIManager():CreateGUIScript("GUIGorgeBuildMenu")            
        end
        
    end
    
    function DropStructureAbility:DestroyBuildMenu()

        if self.buildMenu ~= nil then
        
            GetGUIManager():DestroyGUIScript(self.buildMenu)
            self.buildMenu = nil
        
        end
    
    end

    function DropStructureAbility:OnDestroy()
    
        self:DestroyBuildMenu()        
        Ability.OnDestroy(self)
        
    end
    
    function DropStructureAbility:OnKillClient()
        self.menuActive = false
    end
    
    function DropStructureAbility:OnDrawClient()
    
        Ability.OnDrawClient(self)
        
        // We need this here in case we switch to it via Prev/NextWeapon keys
        
        // Do not show menu for other players or local spectators.
        local player = self:GetParent()
        if player:GetIsLocalPlayer() and self:GetActiveStructure() == nil and Client.GetIsControllingPlayer() then
            self.menuActive = true
        end
        
    end
    
    local function UpdateGUI(self, player)

        local localPlayer = Client.GetLocalPlayer()
        if localPlayer == player then
            self:CreateBuildMenu()
        end
 
        if self.buildMenu then
            self.buildMenu:SetIsVisible(player and localPlayer == player and player:isa("Gorge") and self.menuActive)
        end
    
    end

    function DropStructureAbility:OnHolsterClient()
    
        self.menuActive = false
        Ability.OnHolsterClient(self)
        
    end
    
    function DropStructureAbility:OnSetActive()
    end
    
    function DropStructureAbility:OverrideInput(input)
    
        if self.buildMenu then

            // Build menu is up, let it handle input
            if self.buildMenu:GetIsVisible() then
            
                local selected = false
                input, selected = self.buildMenu:OverrideInput(input)
                self.menuActive = not selected
                
            else

                // If player wants to switch to this, open build menu immediately
                local weaponSwitchCommands = { Move.Weapon1, Move.Weapon2, Move.Weapon3, Move.Weapon4, Move.Weapon5 }
                local thisCommand = weaponSwitchCommands[ self:GetHUDSlot() ]

                if bit.band( input.commands, thisCommand ) ~= 0 then
                    self.menuActive = true
                end

            end
            
        end    
        
        return input
        
    end
    
    function DropStructureAbility:OnUpdateRender()
        UpdateGUI(self, self:GetParent())    
    end
    
end

Shared.LinkClassToMap("DropStructureAbility", DropStructureAbility.kMapName, networkVars)
