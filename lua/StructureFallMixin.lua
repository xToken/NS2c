// Natural Selection 2 'Classic' Mod
// Source located at - https://github.com/xToken/NS2c
// lua\StructureFallMixin.lua    
// - Dragon

StructureFallMixin = CreateMixin(StructureFallMixin)
StructureFallMixin.type = "StructureFall"

local kFallSpeed = 5
local kFallStartDelay = 0.1
local kFallRate = 0.03

StructureFallMixin.optionalCallbacks =
{
    OnStructureFall = "Called when structure fall starts.",
    OnStructureFallDone = "Called when we reached the ground, param 'isAttached'."
}

StructureFallMixin.networkVars = { }

function StructureFallMixin:__initmixin()

    assert(Server)
    self.isFalling = false
    self.fallDestinationY = self:GetOrigin().y
    self.attachedIds = { }
    self.parentId = Entity.invalidId
    self.surfaceNormal = Vector(0, 1, 0)
    
end

local function UpdateStructureFall(self, deltaMove)
    
	if deltaMove == nil then
		deltaMove = (Shared.GetTime() - self.lastmove) * kFallSpeed
		deltaMove = math.max(self.fallDestinationY, self:GetOrigin().y - deltaMove)
		deltaMove = deltaMove - self:GetOrigin().y
		self.lastmove = Shared.GetTime()
	end

	local newCoords = self:GetCoords()
    newCoords.origin.y = newCoords.origin.y + deltaMove
    self:SetCoords(newCoords)
    
    for _, attachedId in ipairs(self.attachedIds) do
    
        local entity = Shared.GetEntity(attachedId)
        if entity and HasMixin(entity, "StructureFall") then
            UpdateStructureFall(entity, deltaMove)
        end
        
    end
    
    Shared.Message(string.format("Moved %s down %s", #self.attachedIds, deltaMove))
    
    if deltaMove == 0 then
    
        self.isFalling = false
        
        self:TriggerEffects("structure_land", {effecthostcoords = Coords.GetTranslation(self:GetOrigin())})
        
        if not self.parentId or self.parentId == Entity.invalidId then
        
            // attach us to the structure we landed on
            local attachTo = self.destinationEntityId and Shared.GetEntity(self.destinationEntityId)
            if attachTo and HasMixin(attachTo, "StructureFall") then
            
                attachTo:ConnectToStructure(self)
                self.destinationEntityId = nil
            else
                // Update to face ground
                local coords = self:GetCoords()
                coords.yAxis = self.surfaceNormal
                coords.xAxis = coords.yAxis:CrossProduct( coords.zAxis )
                coords.zAxis = coords.xAxis:CrossProduct( coords.yAxis )
                self:SetCoords(coords)
            end
        
        end
        
        if self.OnStructureFallDone then
            self:OnStructureFallDone(self.parentId and self.parentId ~= Entity.invalidId, self.surfaceNormal)
        end
        
    end
	
	return self.isFalling
    
end

local function TriggerFall(self)

    PROFILE("StructureFallMixin:TriggerFall")
    
    // clear attached
    if self.parentId and self.parentId ~= Entity.invalidId then
    
        local parent = Shared.GetEntity(self.parentId)
        if parent and HasMixin(parent, "StructureFall") then
            parent:RemoveAttachedStructure(self)
        end
        
        self.parentId = Entity.invalidId
        
    end
    
    // trace to ground for destination pos
    local origin = self:GetOrigin()
    local trace = Shared.TraceRay(Vector(origin.x, origin.y + 0.4, origin.z), Vector(origin.x, origin.y - 100, origin.z), CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterOne(self))
    
    if trace.fraction ~= 1 then
    
        self.fallDestinationY = trace.endPoint.y
        self.destinationEntityId = trace.entity ~= nil and trace.entity:GetId()
        self.isFalling = true
        self.surfaceNormal = trace.normal
        
        // TriggerFall for childs which are below us, they will unattach then (otherwise fall through the world)
        for _, attachedId in ipairs(self.attachedIds) do
        
            local entity = Shared.GetEntity(attachedId)
            if entity and HasMixin(entity, "StructureFall") then
            
                local verticalDistance = entity:GetOrigin().y - self:GetOrigin().y
                if verticalDistance < 0.4 then
                    TriggerFall(entity)
                end
                
            end
            
        end
        
        if self.OnStructureFall then
            self:OnStructureFall(self.surfaceNormal)
        end
		
		self.lastmove = Shared.GetTime()
		self:AddTimedCallback(UpdateStructureFall, kFallRate)
        
    else
        Print("StructureFallMixin:TriggerFall: could not find ground")
    end
    
end

function StructureFallMixin:OnDestroy()

    for _, attachedId in ipairs(self.attachedIds) do
    
        local entity = Shared.GetEntity(attachedId)
        if entity and HasMixin(entity, "StructureFall") then
            entity:AddTimedCallback(TriggerFall, kFallStartDelay)
        end
        
    end
    
end

function StructureFallMixin:GetIsFalling()
    return self.isFalling
end

function StructureFallMixin:OnEntityChange(oldId, newId)

    if oldId == self.parentId then
        self.parentId = Entity.invalidId
    elseif oldId == self.destinationEntityId then
        self.destinationEntityId = nil 
    else
        // TODO: check childs
    end
end

function StructureFallMixin:ConnectToStructure(structure)
    table.insert(self.attachedIds, structure:GetId())
    structure.parentId = self:GetId()
end

function StructureFallMixin:RemoveAttachedStructure(structure)
    table.removevalue(self.attachedIds, structure:GetId())
end