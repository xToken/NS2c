// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Door.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/PathingMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/WeldableMixin.lua")
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

if Server then
    Script.Load("lua/Door_Server.lua")
end

local networkVars =
{
    weldedPercentage = "float",
    
    // Stores current state (kState )
    state = "enum Door.kState",
    damageFrontPose = "float (0 to 100 by 0.1)",
    damageBackPose = "float (0 to 100 by 0.1)"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)

local kDoorLockTimeout = 6
local kDoorLockDuration = 4

local function UpdateAutoUnlock(self, timePassed)

    // auto open the door after kDoorLockDuration time has passed
    local state = self:GetState()

    if state == Door.kState.Locked and self.timeLastLockTrigger + kDoorLockDuration < Shared.GetTime() then

        self:SetState(Door.kState.Open)
        self.lockTimeOut = Shared.GetTime() + kDoorLockTimeout
        
    end
    
    return true

end

local function UpdateAutoOpen(self, timePassed)

    // If any players are around, have door open if possible, otherwise close it
    local state = self:GetState()
    
    if state == Door.kState.Open or state == Door.kState.Close then

        local desiredOpenState = self:GetHasLockTimeout()
        
        if not desiredOpenState then
        
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
        end
        
        if desiredOpenState and self:GetState() == Door.kState.Close then
            self:SetState(Door.kState.Open)
        elseif not desiredOpenState and self:GetState() == Door.kState.Open then
            self:SetState(Door.kState.Close)  
        end
        
    end
    
    return true

end

function Door:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, PathingMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, LiveMixin)
    
    if Server then
    
        self:AddTimedCallback(UpdateAutoUnlock, kUpdateAutoUnlockRate)
        self:AddTimedCallback(UpdateAutoOpen, kUpdateAutoOpenRate)
        
        self.timeLastLockTrigger = 0
        self.lockTimeOut = 0
        
    end
    
    self:SetPathingFlags(Pathing.PolyFlag_NoBuild)
    self.state = Door.kState.Open
end

local function InitModel(self)

    local modelName = kModelNameDefault
    if self.clean then
        modelName = kModelNameClean
    end
    
    self:SetModel(modelName, kDoorAnimationGraph)
    
end

function Door:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    InitMixin(self, WeldableMixin)
    
    InitModel(self)
    
    if Server then
    
        self:SetPhysicsType(PhysicsType.Kinematic)
        
        self:SetPhysicsGroup(PhysicsGroup.CommanderUnitGroup)
        
        // Doors always belong to the Marine team.
        self:SetTeamNumber(kTeam1Index)
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
    end
    
    self.weldedPercentage = 0
    
    self:SetState(Door.kState.Close)
    
end

function Door:Reset()

    // Restore original origin, angles, etc. as it could have been rag-dolled
    self:SetOrigin(self.savedOrigin)
    self:SetAngles(self.savedAngles)
    
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(0)
    
    self:SetState(Door.kState.Close)
    
    self.damageBackPose = 0
    self.damageFrontPose = 0
    
    self.weldedPercentage = 0
    self:SetHealth(self:GetMaxHealth())
    self:SetArmor(self:GetMaxArmor())
    self.timeToRagdoll = nil
    self.timeToDestroy = nil
    
    InitModel(self)
    
end

function Door:GetShowHealthFor(player)
    return false
end  

function Door:GetReceivesStructuralDamage()
    return true
end

function Door:GetIsWeldedShut()
    return self:GetState() == Door.kState.Welded
end

// Only hackable by marine commander
function Door:PerformActivation(techId, position, normal, commander)

    local success = nil
    local state = self:GetState()
    
    // Set success to false if action specifically not allowed
    if techId == kTechId.DoorClose then
    
        if state == Door.kState.Open then
        
            self:TriggerDoorLock()
            success = true
            
        else
            success = false
        end
        
    end
    
    if success == false then
        self:PlaySound(Door.kInoperableSound)
    end
    
    return success, true
    
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

function Door:GetTechAllowed(techId, techNode, player)

    local state = self:GetState()
    
    local allowed, canAfford = ScriptActor.GetTechAllowed(self, techId, techNode, player)
    
    if techId == kTechId.DoorOpen then
        allowed = state == Door.kState.Close
    elseif techId == kTechId.DoorClose then
        allowed = state == Door.kState.Open
    end

    return allowed, canAfford

end

function Door:GetTechButtons(techId, teamType)

    if(techId == kTechId.WeaponsMenu) then   
        // $AS - Aliens do not get tech on doors they can just select them
        if not (teamType == kAlienTeamType) then
            return  {kTechId.None, kTechId.None, kTechId.None, kTechId.None, // add kTechId.DoorClose to enable closing for commanders
                     kTechId.None, kTechId.None, kTechId.None, kTechId.None }
        else            
            return  {kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                     kTechId.None, kTechId.None, kTechId.None, kTechId.None }
        end
        
    end
    
    return nil
    
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

function Door:GetCanBeWeldedOverride()
    return false
end

function Door:GetWeldPercentageOverride()
    return 0
end

function Door:OnWeldOverride(doer, elapsedTime)
    
end

function Door:TriggerDoorLock()

    self:SetState(Door.kState.Locked)
    self.timeLastLockTrigger = Shared.GetTime()

end

/*
function Door:GetUseAttachPoint()
    return "keypad_front"
end

function Door:GetUseAttachPoint2()
    return "keypad_back"
end
*/

function Door:GetHasLockTimeout()
    return self.lockTimeOut > Shared.GetTime()
end

function Door:OnUse(player, elapsedTime, useAttachPoint, usePoint)

    local state = self:GetState()
    if state ~= Door.kState.DestroyedFront and state ~= Door.kState.DestroyedBack and not self:GetIsWeldedShut() and player:isa("Marine") then
    
        if Server then
        
            if state ~= Door.kState.Locked and not self:GetHasLockTimeout() then
                self:TriggerDoorLock()
            end
            
        end
        
    end
    
end

function Door:OnKill(attacker, doer, point, direction)

    // compute correct direction for animation (back or front)
    direction = self:GetOrigin() - attacker:GetOrigin()
    if direction:DotProduct(self:GetAngles():GetCoords().zAxis) < 0 then
    
        self:SetState(Door.kState.DestroyedBack)
        self:TriggerEffects("destroydoor_back")
        
    else
    
        self:SetState(Door.kState.DestroyedFront)
        self:TriggerEffects("destroydoor_front")
        
    end
    
    self:SetModel(kModelNameDestroyed)
    
end

function Door:OnUpdatePoseParameters()

    PROFILE("Door:OnUpdatePoseParameters")
    
    self:SetPoseParam("damage_f", self.damageFrontPose)
    self:SetPoseParam("damage_b", self.damageBackPose)
    
end

function Door:OnUpdateAnimationInput(modelMixin)

    PROFILE("Door:OnUpdateAnimationInput")
    
    local open = self.state == Door.kState.Open
    local lock = self.state == Door.kState.Locked or self.state == Door.kState.Welded
    local break_f = self.state == Door.kState.DestroyedFront
    local break_b = self.state == Door.kState.DestroyedBack
    
    modelMixin:SetAnimationInput("open", open)
    modelMixin:SetAnimationInput("lock", lock)
    modelMixin:SetAnimationInput("break_f", break_f)
    modelMixin:SetAnimationInput("break_b", break_b)
    
end

Shared.LinkClassToMap("Door", Door.kMapName, networkVars)