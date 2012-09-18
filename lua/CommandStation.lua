// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\CommandStation.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/RecycleMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/CommandStructure.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")

class 'CommandStation' (CommandStructure)

CommandStation.kMapName = "commandstation"

//CommandStation.kModelName = PrecacheAsset("models/marine/command_station/command_station.model")
CommandStation.kModelName = PrecacheAsset("models/marine/commandcenter/commandcenter.model")
local kAnimationGraph = PrecacheAsset("models/marine/command_station/command_station.animation_graph")

CommandStation.kUnderAttackSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/command_station_under_attack")

Shared.PrecacheSurfaceShader("models/marine/command_station/command_station_display.surface_shader")

local kLoginAttachPoint = "login"

if Server then
    Script.Load("lua/CommandStation_Server.lua")
end

local networkVars = 
{
}

AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)

function CommandStation:OnCreate()

    CommandStructure.OnCreate(self)
    
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, ParasiteMixin)
    
end

function CommandStation:OnInitialized()

    CommandStructure.OnInitialized(self)
    
    InitMixin(self, WeldableMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, RecycleMixin)
    
    self:SetModel(CommandStation.kModelName, kAnimationGraph)
    
    if Server then
    
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, StaticTargetMixin)
    
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        
    end

end

function CommandStation:GetIsWallWalkingAllowed()
    return false
end

local kHelpArrowsCinematicName = PrecacheAsset("cinematics/marine/commander_arrow.cinematic")

if Client then

    function CommandStation:GetHelpArrowsCinematicName()
        return kHelpArrowsCinematicName
    end
    
end

function CommandStation:GetUseAttachPoint()
    return kLoginAttachPoint
end

function CommandStation:GetCanRecycleOverride()
    return not self:GetIsOccupied()
end

function CommandStation:GetTechAllowed(techId, techNode, player)

    local allowed, canAfford = CommandStructure.GetTechAllowed(self, techId, techNode, player)

    if techId == kTechId.Recycle then
        allowed = allowed and not self:GetIsOccupied()
    end
    
    return allowed, canAfford
    
end

local kCommandStationState = enum( { "Normal", "Locked", "Welcome" } )
function CommandStation:OnUpdateRender()

    CommandStructure.OnUpdateRender(self)
    
    local model = self:GetRenderModel()
    if model then
    
        local state = kCommandStationState.Normal
        
        if self:GetIsOccupied() then
            state = kCommandStationState.Welcome
        elseif GetTeamHasCommander(self:GetTeamNumber()) then
            state = kCommandStationState.Locked
        end
        
        if not PlayerUI_GetHasGameStarted() then
            state = kCommandStationState.Locked
        end
        
        model:SetMaterialParameter("state", state)
        
    end
    
end

local kCommandStationHealthbarOffset = Vector(0, 2, 0)
function CommandStation:GetHealthbarOffset()
    return kCommandStationHealthbarOffset
end

Shared.LinkClassToMap("CommandStation", CommandStation.kMapName, networkVars)