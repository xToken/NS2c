// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Commander_Selection.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Shared code that handles selection.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

function Commander:GetEntitiesBetweenVecs(potentialEntities, pickStartVec, pickEndVec, entityList)

    local minX = math.min(pickStartVec.x, pickEndVec.x)
    local minZ = math.min(pickStartVec.z, pickEndVec.z)
    
    local maxX = math.max(pickStartVec.x, pickEndVec.x)
    local maxZ = math.max(pickStartVec.z, pickEndVec.z)

    for index, entity in pairs(potentialEntities) do
    
        // Filter selection
        if( self:GetIsEntityValidForSelection(entity) ) then

            // Get normalized vector to entity
            local toEntity = entity:GetOrigin() - self:GetOrigin()
            toEntity:Normalize()
                       
            // It should be selected if this vector lies between the pick vectors
            if( ( minX < toEntity.x and minZ < toEntity.z ) and
                ( maxX > toEntity.x and maxZ > toEntity.z ) ) then
        
                // Insert entity along with current time for fading
                table.insertunique(entityList, {entity:GetId(), Shared.GetTime()} )
                //DebugLine(self:GetOrigin(), entity:GetOrigin(), 10, 0, 1, 0, 1)
            else
                //DebugLine(self:GetOrigin(), entity:GetOrigin(), 10, 1, 0, 0, 1)                
            end
            
        end
    
    end
    
end

/**
 * If selected entities include structures and non-structures, get rid of the structures (ala modern RTS').
 * In addition, always filter out Commander players.
 */
local function FilterOutMarqueeSelection(selection)

    local foundStructure = false
    local foundNonStructure = false
    local toRemove = { }
    
    for index, entityPair in ipairs(selection) do
    
        local entity = Shared.GetEntity(entityPair[1])
        
        if entity:isa("Commander") then
            table.insertunique(toRemove, entityPair)
        else
        
            if GetReceivesStructuralDamage(entity) then
                foundStructure = true
            else
                foundNonStructure = true
            end
            
        end
        
    end
    
    if foundStructure and foundNonStructure then
    
        for index, entityPair in ipairs(selection) do
        
            local entity = Shared.GetEntity(entityPair[1])
            
            if GetReceivesStructuralDamage(entity) then
                table.insertunique(toRemove, entityPair)
            end
            
        end
        
    end
    
    for index, entityPair in ipairs(toRemove) do
    
        if not table.removevalue(selection, entityPair) then
            Print("FilterOutMarqueeSelection(): Unable to remove entityPair (%s)", entity:GetClassName())
        end
        
    end
    
end

local function SortCommanderSelection(entPair1, entPair2)

    // Sort by tech id
    local ent1 = Shared.GetEntity(entPair1[1])
    local ent2 = Shared.GetEntity(entPair2[1])
    
    if ent1 and ent2 then
    
        if ent1:GetTechId() ~= ent2:GetTechId() then
            return ent1:GetTechId() < ent2:GetTechId()
        else
        
            // Then sort by health
            if HasMixin(ent1, "Live") and HasMixin(ent2, "Live") then
                return ent1:GetHealth() > ent2:GetHealth()
            end
            
        end
        
        // Use entity Id as a last resort.
        return ent1:GetId() < ent2:GetId()
        
    end
    
end

function Commander:SortSelection(newSelection)
    table.sort(newSelection, SortCommanderSelection)
end

// Input vectors are normalized world vectors emanating from player, representing a selection region where the marquee 
// existed (or they were created around the vector where the mouse was clicked for a single selction). 
// Pass 1 as selectone to select only one entity (click select)
function Commander:MarqueeSelectEntities(pickStartVec, pickEndVec)

    local newSelection = {}

    local potentials = GetEntitiesWithMixin("Selectable")
    
    self:GetEntitiesBetweenVecs(potentials, pickStartVec, pickEndVec, newSelection)

    if(table.maxn(newSelection) > 1) then
    
        FilterOutMarqueeSelection(newSelection)
        self:SortSelection(newSelection)
        
    end
    
    if table.count(newSelection) > 0 then
        return self:InternalSetSelection(newSelection)
    else
        return false
    end
        
end

function Commander:GetUnitUnderCursor(pickVec)

    local origin = self:GetOrigin()
    local trace = Shared.TraceRay(origin, origin + pickVec*1000, CollisionRep.Select, PhysicsMask.CommanderSelect, EntityFilterOne(self))
    local recastCount = 0
    while trace.entity == nil and trace.fraction < 1 and trace.normal:DotProduct(Vector(0, 1, 0)) < 0 and recastCount < 3 do
        // We've hit static geometry with the normal pointing down (ceiling). Re-cast from the point of impact.
        local recastFrom = 1000 * trace.fraction + 0.1
        trace = Shared.TraceRay(origin + pickVec*recastFrom, origin + pickVec*1000, CollisionRep.Select, PhysicsMask.CommanderSelect, EntityFilterOne(self))
        recastCount = recastCount + 1
    end
    
    return trace.entity
    
end

function Commander:InternalClickSelectEntities(pickVec)

    // Trace to the first entity we can select
    local entity = self:GetUnitUnderCursor(pickVec)    
    
    if entity and self:GetIsEntityValidForSelection(entity) then
    
        return {entity}
        
    elseif #self:GetSelection() > 0 then    
        
        //self:ClearSelection()
    
    end
    
    return nil

end

// Compares entities in each list and sees if they look the same to the user. Doesn't check selection times, only entity indices
function Commander:SelectionEntitiesEquivalent(entityList1, entityList2)

    local equivalent = false
    
    if (entityList1 == nil or entityList2 == nil) then
        return (entityList1 == entityList2)
    end
    
    if(table.maxn(entityList1) == table.maxn(entityList2)) then
    
        equivalent = true
    
        for index, entityPair in ipairs(entityList1) do
        
            if(entityPair[1] ~= entityList2[index][1]) then
            
                equivalent = false
                break
                
            end
        
        end
    
    end

    return equivalent
    
end

function Commander:GetUnitIdUnderCursor(pickVec)

    local entity = self:GetUnitUnderCursor(pickVec)
    
    if entity then
        return entity:GetId()
    end
    
    return Entity.invalidId

end

function Commander:SelectEntityId(entitId)
    return self:InternalSetSelection({ {entitId, Shared.GetTime()} } )
end

// TODO: call when selection should be added to current selection
function Commander:AddSelectEntityId(entitId)
    return self:InternalSetSelection({ {entitId, Shared.GetTime()} } )
end

function Commander:ClickSelectEntities(pickVec)

    local newSelection = {}
    local hitEntity = false
    local clickEntities = self:InternalClickSelectEntities(pickVec)
    
    if(clickEntities ~= nil) then
    
        hitEntity = true
        
        for index, entity in ipairs(clickEntities) do  
        
            table.insertunique(newSelection, {entity:GetId(), Shared.GetTime()} )
            
            if Client then
                self:SendSelectIdCommand(entity:GetId())
            end
            
        end
        
    end
        
    if table.count(newSelection) > 0 then
        return self:InternalSetSelection(newSelection), hitEntity
    else
        return false, hitEntity
    end
    
end

// If control/crouch is pressed, select all units of this type on the screen
function Commander:ControlClickSelectEntities(pickVec, minDot)
    
    local newSelection = {}

    local clickEntities = self:InternalClickSelectEntities(pickVec)
    if(clickEntities ~= nil and table.count(clickEntities) > 0) then
    
        local clickEntity = clickEntities[1]
        
        if(clickEntity ~= nil) then

            // Select all units of this type on screen (represented by startVec and endVec).
            local classname = clickEntity:GetClassName()
            if(classname ~= nil) then
            
                local potentials = EntityListToTable(Shared.GetEntitiesWithClassname(classname))
                
                local eyePos = self:GetEyePos()
                local toEntity = nil
                local time = Shared.GetTime()
                
                for _, potential in ipairs(potentials) do
                
                    toEntity = GetNormalizedVector(potential:GetOrigin() - eyePos)
                    if self:GetViewCoords().zAxis:DotProduct(toEntity) >= minDot then
                        table.insertunique(newSelection, {potential:GetId(), time} )
                    end
                
                end

            end
            
        end
        
    end
    
    if table.count(newSelection) > 0 then
        return self:InternalSetSelection(newSelection)
    else
        return false
    end
    
end

function Commander:SelectAllPlayers()

    local selectionIds = {}
    
    local players = GetEntitiesForTeam("Player", self:GetTeamNumber())
    
    for index, player in ipairs(players) do
    
        if player:GetIsAlive() and not player:isa("Commander") then
        
            table.insert(selectionIds, player:GetId())
            
        end
        
    end
    
    if table.count(selectionIds) > 0 then
        self:SetSelection(selectionIds)
    end
    
end

// Convenience function that takes list of entity ids and converts to {entityId, timeSelected} pairs. 
// Tests and external code will want to use this instead of InternalSetSelection(). Can also take
// an entityId by itself.
function Commander:SetSelection(entsOrId)

    local time = Shared.GetTime()
    local pairTable = {}
    
    if (type(entsOrId) == "number") then

        table.insert( pairTable, {entsOrId, time} )
        
    elseif (type(entsOrId) == "table") then
    
        for index, entId in ipairs(entsOrId) do        
            table.insert( pairTable, {entId, time} )
        end
        
    else
        return false
    end

    return self:InternalSetSelection( pairTable )    
    
end

local function PlaySelectionChangedSound(self)

    if Client and self:GetIsLocalPlayer() then
        Shared.PlayPrivateSound(self, self:GetSelectionSound(), nil, 1.0, self:GetOrigin())
    end
    
end

function LeaveSelectionMenu(self)

    // Only execute for the local Commander player.
    if Client and self == Client.GetLocalPlayer() and self:GetSelectedTabIndex() == 4 then
    
        self:SetCurrentTech(kTechId.BuildMenu)
        self:DestroySelectionCircles()
        
    elseif Server then
        // don't switch the menu if in a tap. client pressed the tap button instead of clearing selection / seleciton became invalid
        if self.currentMenu ~= kTechId.BuildMenu and self.currentMenu ~= kTechId.AdvancedMenu and self.currentMenu ~= kTechId.AssistMenu then
            self:ProcessTechTreeAction(kTechId.BuildMenu, nil, nil)
        end    
    end

end

local function GoToRootMenu(self)

    // Only execute for the local Commander player.
    if Client and self == Client.GetLocalPlayer() then
    
        self:TriggerButtonIndex(4)
        self.createSelectionCircles = true
        self:UpdateSelectionCircles()
        
    elseif Server then
        self:ProcessTechTreeAction(kTechId.RootMenu, nil, nil)
    end
    
end

// Takes table of {entityId, timeSelected} pairs. Calls OnSelectionChanged() if it does. Doesn't allow setting
// selection to empty unless allowEmpty is passed. Returns true if selection is different after calling.
function Commander:InternalSetSelection(newSelection, preventMenuChange)

    // Reset sub group
    self.focusGroupIndex = 1
    
    // Clear last hotkey group when we change selection so next time
    // we press the hotkey, we select instead of go to it    
    self.gotoHotKeyGroup = 0
    
    local selectionChanged = false
    if not self:SelectionEntitiesEquivalent(newSelection, self.selectedEntities) then
    
        self:SetEntitiesSelectionState(false)
        self.selectedEntities = newSelection
        self:SetEntitiesSelectionState(true)

        if #newSelection > 0 then
            PlaySelectionChangedSound(self)
        end
        
        selectionChanged = true
        
    end
    
    // Always go back to root menu when selecting something, even if the same thing
    if not preventMenuChange then
    
        if #newSelection ~= 0 then
            GoToRootMenu(self)
        end
        
    end
    
    if #newSelection == 0 then
        LeaveSelectionMenu(self)
    end
    
    return selectionChanged
    
end

function Commander:SetEntitiesSelectionState(state)

    if Server then
    
        for index, entityPair in ipairs(self.selectedEntities) do
        
            local entityIndex = entityPair[1]
            local entity = Shared.GetEntity(entityIndex)
            
            if entity ~= nil then
                entity:SetIsSelected(state)
            end
            
        end
        
    end 
    
end

// Returns table of sorted selected entities 
function Commander:GetSelection()

    local selected = {}
    
    if (self.selectedEntities ~= nil) then
    
        for index, pair in ipairs(self.selectedEntities) do
            table.insert(selected, pair[1])
        end
        
    end
    
    return selected
    
end

function Commander:GetIsSelected(entityId, debug)

    for index, pair in ipairs(self.selectedEntities) do
    
        if(pair[1] == entityId) then
        
            return true
            
        end
        
    end
    
    return false
    
end

function Commander:ClearSelection()

    self:InternalSetSelection({ }, true)
    
    if Client then
    
        self.createSelectionCircles = true
        self:UpdateSelectionCircles()
    
        local message = BuildClearSelectionMessage(true, Entity.invalidId, false)
        Client.SendNetworkMessage("ClearSelection", message, true)
        
    end
    
end

function Commander:GetIsEntityValidForSelection(entity)
    return entity and HasMixin(entity, "Selectable") and entity:GetIsSelectable(self) and HasMixin(entity, "Tech") 
end

function Commander:UpdateSelection(deltaTime)

    local numSelectedBeforeDelete = #self.selectedEntities
    
    local entPairsToDelete = { }
    
    for tableIndex, entityPair in ipairs(self.selectedEntities) do
    
        local entityIndex = entityPair[1]
        local entity = Shared.GetEntity(entityIndex)
        
        if not self:GetIsEntityValidForSelection(entity) then
            table.insert(entPairsToDelete, entityPair)
        end        
    
    end
    
    for index, entityPair in ipairs(entPairsToDelete) do
        
        table.removevalue(self.selectedEntities, entityPair)
        
        if Server then
        
            local entityIndex = entityPair[1]
            local entity = Shared.GetEntity(entityIndex)        
        
            if entity ~= nil then
                entity:SetIsSelected(false)
            end
            
        end
        
    end
    
    if #self.selectedEntities == 0 and numSelectedBeforeDelete > 0 then
        self:InternalSetSelection({ })
    end
    
end

function Commander:GetIsEntitySelected(entity)

    for index, entityPair in pairs(self.selectedEntities) do

        local selectedEntity = Shared.GetEntity(entityPair[1])
        if(selectedEntity ~= nil and entity:GetId() == selectedEntity:GetId()) then
        
            return true
            
        end
        
    end
    
    return false

end

// Returns true if hotkey exists and was selected
function Commander:SelectHotkeyGroup(number)

    if Client then
        self:SendSelectHotkeyGroupMessage(number)
    end    

    if number >= 1 and number <= kMaxHotkeyGroups then
    
        if table.count(self.hotkeyGroups[number]) > 0 then
        
            local selection = {}
            
            for i = 1, table.count(self.hotkeyGroups[number]) do            
                table.insert(selection, self.hotkeyGroups[number][i])                
            end
            
            return self:SetSelection(selection)
            
        end
        
    end  
    
    return false
    
end

function Commander:GotoHotkeyGroup(number, position)

    if (number >= 1 and number <= kMaxHotkeyGroups) then
    
        if table.count(self.hotkeyGroups[number]) > 0 then
        
            // Goto first unit in group
            local entityId = self.hotkeyGroups[number][1]
            local entity = Shared.GetEntity(entityId)
            if entity then
            
                VectorCopy(entity:GetOrigin(), position)

                // Add in extra x offset to center view where we're told, not ourselves            
                position.x = position.x - Commander.kViewOffsetXHeight
                
                // Jump to hotkey group if not nearby, else jump to previous
                // position before we jumped to group
                local dist = (self:GetOrigin() - position):GetLength()
                if dist < 1 then
                    VectorCopy(self.positionBeforeJump, position)
                end
                
                return true
            
            end
            
        end
        
    end 
    
    return false
           
end