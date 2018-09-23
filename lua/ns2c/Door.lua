-- ======= Copyright (c) 2003-2014, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Door.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/MapBlipMixin.lua")

class 'Door' (ScriptActor)

Door.kMapName = "door"

Door.kInoperableSound = PrecacheAsset("sound/NS2.fev/common/door_inoperable")
Door.kOpenSound = PrecacheAsset("sound/NS2.fev/common/door_open")
Door.kCloseSound = PrecacheAsset("sound/NS2.fev/common/door_close")
Door.kLockSound = PrecacheAsset("sound/NS2.fev/common/door_lock")
Door.kUnlockSound = PrecacheAsset("sound/NS2.fev/common/door_unlock")

Door.kState = enum( {'Open', 'Close', 'Locked', 'DestroyedFront', 'DestroyedBack', 'Welded'} )
Door.kStateSound = { [Door.kState.Open] = Door.kOpenSound, 
                     [Door.kState.Close] = Door.kCloseSound, 
                     [Door.kState.Locked] = Door.kLockSound,
                     [Door.kState.DestroyedFront] = "", 
                     [Door.kState.DestroyedBack] = "", 
                     [Door.kState.Welded] = Door.kLockSound,  }

local kUpdateAutoUnlockRate = 1
local kUpdateAutoOpenRate = 0.3

local kModelNameDefault = PrecacheAsset("models/misc/door/door.model")
local kModelNameClean = PrecacheAsset("models/misc/door/door_clean.model")
local kModelNameDestroyed = PrecacheAsset("models/misc/door/door_destroyed.model")

local kDoorAnimationGraph = PrecacheAsset("models/misc/door/door.animation_graph")

local networkVars =
{
    -- Stores current state (kState )
    state = "enum Door.kState"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)

local kDoorLockTimeout = 6
local kDoorLockDuration = 4

local function UpdateAutoUnlock(self, timePassed)

    -- auto open the door after kDoorLockDuration time has passed
    local state = self:GetState()

    if state == Door.kState.Locked and self.timeLastLockTrigger + kDoorLockDuration < Shared.GetTime() then

        self:SetState(Door.kState.Open)
        self.lockTimeOut = Shared.GetTime() + kDoorLockTimeout
        
    end
    
    return true

end

local function UpdateAutoOpen(self, timePassed)

    -- If any players are around, have door open if possible, otherwise close it
    local state = self:GetState()
    
    if state == Door.kState.Open or state == Door.kState.Close then
    
        local desiredOpenState = false

        local entities = Shared.GetEntitiesWithTagInRange("Door", self:GetOrigin(), DoorMixin.kMaxOpenDistance)
        for index = 1, #entities do
            
            local entity = entities[index]
            local opensForEntity, openDistance = entity:GetCanDoorInteract(self)
			
            if opensForEntity then
            
                local distSquared = self:GetDistanceSquared(entity)
                if (not HasMixin(entity, "Live") or entity:GetIsAlive()) and entity:GetIsVisible() and distSquared < (openDistance * openDistance) then
                
                    desiredOpenState = true
                    break
                
                end
            
            end
            
        end
        
        if desiredOpenState and self:GetState() == Door.kState.Close then
            self:SetState(Door.kState.Open)
        elseif not desiredOpenState and self:GetState() == Door.kState.Open then
            self:SetState(Door.kState.Close)  
        end
        
    end
    
    return true

end

local function InitModel(self)

    local modelName = kModelNameDefault
    if self.clean then
        modelName = kModelNameClean
    end
    
    self:SetModel(modelName, kDoorAnimationGraph)
    
end

function Door:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, PathingMixin)
    
    if Server then
    
        self:AddTimedCallback(UpdateAutoUnlock, kUpdateAutoUnlockRate)
        self:AddTimedCallback(UpdateAutoOpen, kUpdateAutoOpenRate)
        
    end
    
    self.state = Door.kState.Open

    
end



function Door:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    if Server then
        
        InitModel(self)
        
        self:SetPhysicsType(PhysicsType.Kinematic)
        
        self:SetPhysicsGroup(PhysicsGroup.CommanderUnitGroup)
        
        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
    end

    
end

function Door:Reset()
    
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(0)
    
    self:SetState(Door.kState.Close)
    
    InitModel(self)
    
end

function Door:GetShowHealthFor(player)
    return false
end

function Door:GetReceivesStructuralDamage()
    return false
end

function Door:GetIsWeldedShut()
    return self:GetState() == Door.kState.Welded
end

function Door:GetDescription()

    local doorName = GetDisplayNameForTechId(self:GetTechId())
    local doorDescription = doorName
    
    local state = self:GetState()
    
    if state == Door.kState.Welded then
        doorDescription = string.format("Welded %s", doorName)
    end
    
    return doorDescription
    
end

function Door:SetState(state, commander)

    if self.state ~= state then
    
        self.state = state
        
        if Server then
        
            local sound = Door.kStateSound[self.state]
            if sound ~= "" then
            
                self:PlaySound(sound)
                
                if commander ~= nil then
                    Server.PlayPrivateSound(commander, sound, nil, 1.0, commander:GetOrigin())
                end
                
            end
            
        end
        
    end
    
end

function Door:GetState()
    return self.state
end

function Door:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

function Door:OnUpdateAnimationInput(modelMixin)

    PROFILE("Door:OnUpdateAnimationInput")
    
    local open = self.state == Door.kState.Open
    local lock = self.state == Door.kState.Locked or self.state == Door.kState.Welded
    
    modelMixin:SetAnimationInput("open", open)
    modelMixin:SetAnimationInput("lock", lock)
    
end

Shared.LinkClassToMap("Door", Door.kMapName, networkVars)