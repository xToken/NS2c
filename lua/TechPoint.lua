// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\TechPoint.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removing Infestation Hooks

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

class 'TechPoint' (ScriptActor)

TechPoint.kMapName = "tech_point"

// Note that these need to be changed in editor_setup.xml as well.
TechPoint.kModelName = PrecacheAsset("models/misc/tech_point/tech_point.model")
local kGraphName = PrecacheAsset("models/misc/tech_point/tech_point.animation_graph")

TechPoint.kTechPointEffect = PrecacheAsset("cinematics/common/techpoint.cinematic")
TechPoint.kTechPointLightEffect = PrecacheAsset("cinematics/common/techpoint_light.cinematic")

if Server then
    Script.Load("lua/TechPoint_Server.lua")
end

local networkVars =
{
    smashed = "boolean",
    smashScouted = "boolean",
    occupiedTeam = string.format("integer (-1 to %d)", kSpectatorIndex),
    attachedId = "entityid",
    extendAmount = "float (0 to 1 by 0.01)"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)

function TechPoint:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    // Anything that can be built upon should have this group
    self:SetPhysicsGroup(PhysicsGroup.AttachClassGroup)
    
    // Make the nozzle kinematic so that the player will collide with it.
    self:SetPhysicsType(PhysicsType.Kinematic)
    
    // Defaults to 1 but the mapper can adjust this setting in the editor.
    // The higher the chooseWeight, the more likely this point will be randomly chosen for a team.
    self.chooseWeight = 1
    
    self.extendAmount = 0
    
end

function TechPoint:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false
end

function TechPoint:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(TechPoint.kModelName, kGraphName)
    
    self:SetTechId(kTechId.TechPoint)
    
    self.extendAmount = math.min(1, math.max(0, self.extendAmount))
    
    if Server then
    
        // 0 indicates all teams allowed for random selection process.
        self.allowedTeamNumber = self.teamNumber or 0
        self.smashed = false
        self.smashScouted = false
        self.occupiedTeam = 0
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        self:SetRelevancyDistance(Math.infinity)
        self:SetExcludeRelevancyMask(bit.bor(kRelevantToTeam1, kRelevantToTeam2, kRelevantToReadyRoom))
        
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)
        
        local coords = self:GetCoords()
        self:AttachEffect(TechPoint.kTechPointEffect, coords)
        self:AttachEffect(TechPoint.kTechPointLightEffect, coords, Cinematic.Repeat_Loop)
        
    end
    
end

function TechPoint:GetChooseWeight()
    return self.chooseWeight
end

function TechPoint:SetIsSmashed(setSmashed)

    self.smashed = setSmashed
    self.smashScouted = false
    
end

function TechPoint:SetSmashScouted()

    if Server then
        self.smashScouted = true
    end
    
end

function TechPoint:GetExtendAmount()
    return self.extendAmount
end

if Server then

    function TechPoint:GetTeamNumberAllowed()
        return self.allowedTeamNumber
    end
    
end

if Client then

    function TechPoint:OnUpdateAnimationInput(modelMixin)
    
        PROFILE("TechPoint:OnUpdateAnimationInput")
        
        local player = Client.GetLocalPlayer()
        if player then
        
            local scouted = false
            
            if player:isa("Commander") and player:GetTeamNumber() == GetEnemyTeamNumber(self.occupiedTeam) then
                scouted = self.smashScouted
            else
                scouted = true
            end
            
            modelMixin:SetAnimationInput("hive_deploy", self.smashed and scouted)
            
        end
        
    end
    
end

Shared.LinkClassToMap("TechPoint", TechPoint.kMapName, networkVars)