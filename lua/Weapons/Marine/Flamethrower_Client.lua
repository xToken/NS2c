// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Flamethrower_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kTrailLength = 9.5
local kImpactEffectRate = 0.3
local kSmokeEffectRate = 1.5
local kPilotEffectRate = 0.3

local kFlameImpactCinematic = PrecacheAsset("cinematics/marine/flamethrower/flame_impact3.cinematic")
local kFlameSmokeCinematic = PrecacheAsset("cinematics/marine/flamethrower/flame_trail_light.cinematic")
local kPilotCinematicName = PrecacheAsset("cinematics/marine/flamethrower/pilot.cinematic")

local kFirstPersonTrailCinematics =
{
    PrecacheAsset("cinematics/marine/flamethrower/flame_trail_1p_part1.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_trail_1p_part2.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_trail_1p_part2.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_trail_1p_part2.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_trail_1p_part3.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_trail_1p_part3.cinematic"),
}

local kTrailCinematics =
{
    PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part1.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part2.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part2.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part2.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part2.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part2.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part3.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part3.cinematic"),
}

local kFadeOutCinematicNames =
{
    PrecacheAsset("cinematics/marine/flamethrower/flame_residue_1p_part1.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_residue_1p_part2.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_residue_1p_part2.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_residue_1p_part3.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_residue_1p_part3.cinematic"),
    PrecacheAsset("cinematics/marine/flamethrower/flame_residue_1p_part3.cinematic"),
}

local function UpdateSound(self)

    // Only update when held in inventory
    if self.loopingSoundEntId ~= Entity.invalidId and self:GetParent() ~= nil then
    
        local player = Client.GetLocalPlayer()
        local viewAngles = player:GetViewAngles()
        local yaw = viewAngles.yaw

        local soundEnt = Shared.GetEntity(self.loopingSoundEntId)
        if soundEnt then

            if soundEnt:GetIsPlaying() and self.lastYaw ~= nil then
            
                // 180 degree rotation = param of 1
                local rotateParam = math.abs((yaw - self.lastYaw) / math.pi)
                
                // Use the maximum rotation we've set in the past short interval
                if not self.maxRotate or (rotateParam > self.maxRotate) then
                
                    self.maxRotate = rotateParam
                    self.timeOfMaxRotate = Shared.GetTime()
                    
                end
                
                if self.timeOfMaxRotate ~= nil and Shared.GetTime() > self.timeOfMaxRotate + .75 then
                
                    self.maxRotate = nil
                    self.timeOfMaxRotate = nil
                    
                end
                
                if self.maxRotate ~= nil then
                    rotateParam = math.max(rotateParam, self.maxRotate)
                end
                
                soundEnt:SetParameter("rotate", rotateParam, 1)
                
            end
            
        else
            Print("Flamethrower:OnUpdate(): Couldn't find sound ent on client")
        end
            
        self.lastYaw = yaw
        
    end
    
end

function Flamethrower:OnUpdate(deltaTime)

    ClipWeapon.OnUpdate(self, deltaTime)
    
    UpdateSound(self)
    
end

function Flamethrower:ProcessMoveOnWeapon(input)

    ClipWeapon.ProcessMoveOnWeapon(self, input)
    
    UpdateSound(self)
    
end

function Flamethrower:OnProcessSpectate(deltaTime)

    ClipWeapon.OnProcessSpectate(self, deltaTime)
    
    UpdateSound(self)

end

function UpdatePilotEffect(self, visible)

    if visible then
    
        if not self.pilotCinematic then
            
            self.pilotCinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
            self.pilotCinematic:SetCinematic(kPilotCinematicName)
            self.pilotCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
            
        end
        
        local viewModelEnt = self:GetParent():GetViewModelEntity()
        local renderModel = viewModelEnt and viewModelEnt:GetRenderModel()
        
        if renderModel then
        
            local attachPointIndex = viewModelEnt:GetAttachPointIndex("fxnode_flamethrowermuzzle")
        
            if attachPointIndex >= 0 then
        
                local attachCoords = viewModelEnt:GetAttachPointCoords("fxnode_flamethrowermuzzle")        
                self.pilotCinematic:SetCoords(attachCoords)
            
            end
            
        end
    
    else
    
        if self.pilotCinematic then
            Client.DestroyCinematic(self.pilotCinematic)
            self.pilotCinematic = nil
        end
    
    end

end


local kEffectType = enum({'FirstPerson', 'ThirdPerson', 'None'})

function Flamethrower:OnUpdateRender()

    ClipWeapon.OnUpdateRender(self)

    local parent = self:GetParent()
    local localPlayer = Client.GetLocalPlayer()
    
    local effectToLoad = (parent ~= nil and localPlayer ~= nil and parent == localPlayer and localPlayer:GetIsFirstPerson()) and kEffectType.FirstPerson or kEffectType.ThirdPerson
    
    if self.effectLoaded ~= effectToLoad then
        
        if self.trailCinematic then
            Client.DestroyTrailCinematic(self.trailCinematic)
            self.trailCinematic = nil
        end
        
        if effectToLoad ~= kEffectType.None then            
            self:InitTrailCinematic(effectToLoad, parent)
        end
        
        self.effectLoaded = effectToLoad
    
    end
    
    if self.trailCinematic then
    
        self.trailCinematic:SetIsVisible(self.createParticleEffects == true)
        
        if self.createParticleEffects then
            self:CreateImpactEffect(self:GetParent())
        end
    
    end
    
    UpdatePilotEffect(self, effectToLoad == kEffectType.FirstPerson and self.clip > 0 and self:GetIsActive())

end

function Flamethrower:InitTrailCinematic(effectType, player)

    self.trailCinematic = Client.CreateTrailCinematic(RenderScene.Zone_Default)
    
    local minHardeningValue = 0.5
    local numFlameSegments = 6

    if effectType == kEffectType.FirstPerson then
    
        self.trailCinematic:SetCinematicNames(kFirstPersonTrailCinematics)    
        // set an attach function which returns the player view coords if we are the local player 
        self.trailCinematic:AttachToFunc(self, TRAIL_ALIGN_Z, Vector(-0.09, -0.08, 0.5),
            function (attachedEntity, deltaTime)
                local player = attachedEntity:GetParent()        
                return player ~= nil and player:GetViewCoords()
            end
        )

    elseif effectType == kEffectType.ThirdPerson then
    
        self.trailCinematic:SetCinematicNames(kTrailCinematics)
    
        // attach to third person fx node otherwise with an X offset since we align it along the X-Axis (the attackpoint is oriented in the model like that)
        self.trailCinematic:AttachTo(self, TRAIL_ALIGN_X,  Vector(0.3, 0, 0), "fxnode_flamethrowermuzzle")
        minHardeningValue = 0.1
        numFlameSegments = 8
    
    end
    
    self.trailCinematic:SetFadeOutCinematicNames(kFadeOutCinematicNames)
    self.trailCinematic:SetIsVisible(false)
    self.trailCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
    self.trailCinematic:SetOptions( {
            numSegments = numFlameSegments,
            collidesWithWorld = true,
            visibilityChangeDuration = 0.2,
            fadeOutCinematics = true,
            stretchTrail = false,
            trailLength = kTrailLength,
            minHardening = minHardeningValue,
            maxHardening = 2,
            hardeningModifier = 0.8,
            trailWeight = 0.2
        } )

end

function Flamethrower:CreateImpactEffect(player)

    if (not self.timeLastImpactEffect or self.timeLastImpactEffect + kImpactEffectRate < Shared.GetTime()) and player then
    
        self.timeLastImpactEffect = Shared.GetTime()
    
        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()

        viewCoords.origin = self:GetBarrelPoint(player) + viewCoords.zAxis * (-0.4) + viewCoords.xAxis * (-0.2)
        local endPoint = self:GetBarrelPoint(player) + viewCoords.xAxis * (-0.2) + viewCoords.yAxis * (-0.3) + viewCoords.zAxis * self:GetRange()

        local trace = Shared.TraceRay(viewCoords.origin, endPoint, CollisionRep.Default, PhysicsMask.Flame, EntityFilterAll())

        local range = (trace.endPoint - viewCoords.origin):GetLength()
        if range < 0 then
            range = range * (-1)
        end

        if trace.endPoint ~= endPoint and trace.entity == nil then

            local angles = Angles(0,0,0)
            angles.yaw = GetYawFromVector(trace.normal)
            angles.pitch = GetPitchFromVector(trace.normal) + (math.pi/2)
    
            local normalCoords = angles:GetCoords()
            normalCoords.origin = trace.endPoint            
           
            Shared.CreateEffect(nil, kFlameImpactCinematic, nil, normalCoords)
            
        end
        
    end
    
end

/* disabled, causes bad performance
function Flamethrower:CreateSmokeEffect(player)

    if not self.timeLastLightningEffect or self.timeLastLightningEffect + kSmokeEffectRate < Shared.GetTime() then
    
        self.timeLastLightningEffect = Shared.GetTime()
        
        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
        
        viewCoords.origin = self:GetBarrelPoint(player) + viewCoords.zAxis * 1 + viewCoords.xAxis * (-0.4) + viewCoords.yAxis * (-0.3)
        
        local cinematic = kFlameSmokeCinematic
        
        local effect = Client.CreateCinematic(RenderScene.Zone_Default)    
        effect:SetCinematic(cinematic)
        effect:SetCoords(viewCoords)
        
    end

end
*/

