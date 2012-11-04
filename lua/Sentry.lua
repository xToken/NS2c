// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Sentry.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/RecycleMixin.lua")
Script.Load("lua/TurretMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/AlienDetectableMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/TargetCacheMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/TriggerMixin.lua")
Script.Load("lua/TargettingMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

local kSpinUpSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/sentry_spin_up")
local kSpinDownSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/sentry_spin_down")

local function UpdateMode(self, deltaTime)

    assert(Server)
    
    PROFILE("Sentry:UpdateMode")
    
    if self.desiredMode ~= self.mode then
    
        if self.desiredMode == Sentry.kMode.Attacking and self.mode ~= Sentry.kMode.Attacking then
        
            StartSoundEffectAtOrigin(kSpinUpSoundName, self:GetModelOrigin())
            //self.attackSound:Start()
            self:SetMode(Sentry.kMode.Attacking)
            // match the network field to the calculated one
            self.barrelYawDegrees = self.calculatedBarrelYawDegrees
            
        elseif self.desiredMode ~= Sentry.kMode.Attacking and self.mode == Sentry.kMode.Attacking then
        
            StartSoundEffectAtOrigin(kSpinDownSoundName, self:GetModelOrigin())
            //self.attackSound:Stop()
            self:SetMode(Sentry.kMode.Scanning)

        elseif self.desiredMode == Sentry.kMode.SettingTarget then
            
            self:SetMode(Sentry.kMode.SettingTarget)
            
        end
        
    end

end

local function UpdateAcquireTarget(self, deltaTime)

    PROFILE("Sentry:UpdateAcquireTarget")

    if not self:GetTarget() then
    
        self.target = self.targetSelector:AcquireTarget()
        
        if self.target then    
        
           self:SetDesiredMode(Sentry.kMode.Attacking)
           self:OnTargetChanged()
           
           if not self:GetCurrentOrder() then
               self:GiveOrder(kTechId.Attack, self.target:GetId(), nil)
           end
           
        else
        
            self:SetDesiredMode(Sentry.kMode.Scanning)
            self.lastTargetId = nil
            self:ClearOrders()
            
        end
    
    end
    
end

local function UpdateAttackTarget(self, deltaTime)

    PROFILE("Sentry:UpdateAttackTarget")
    
    local orderLocation = nil
    local order = self:GetCurrentOrder()
    if order then
    
        orderLocation = order:GetLocation()
        
        local target = self:GetTarget()
        local currentTime = Shared.GetTime()
        
        if target and (self.timeNextAttack == nil or (currentTime > self.timeNextAttack)) then
        
            local mode = self:GetSentryMode()
            if mode == Sentry.kMode.Attacking then
            
                local attackEntValid = self.targetSelector:ValidateTarget(target)
                if attackEntValid then
                
                    self:FireBullets()
                    
                    // slower fire rate when confused
                    local confusedTime = ConditionalValue(self.confused, kConfusedSentryBaseROF, 0)
                    
                    // Random rate of fire so it can't be gamed         
                    self.timeNextAttack = confusedTime + currentTime + Sentry.kBaseROF + math.random() * Sentry.kRandROF
                    
                else
                
                    self:ClearOrders()
                    self:SetDesiredMode(Sentry.kMode.Scanning)
                    
                end
                
            else
                self.timeNextAttack = currentTime + .1
            end
            
        end  
        
        if not target then
            self:ClearOrders()
        end
        
    end
    
end

local function UpdateAttack(self, deltaTime)

    assert(Server)
    
    if GetIsUnitActive(self) and self.powered then

        // If we have order
        local order = self:GetCurrentOrder()

        if order ~= nil and order:GetType() == kTechId.SetTarget then
            self:UpdateSetTarget()
        else
        
            if self.timeOfLastTargetAcquisition == nil or self.timeOfLastTargetAcquisition + 0.6 < Shared.GetTime() then
            
                UpdateAcquireTarget(self, deltaTime)
                self.timeOfLastTargetAcquisition = Shared.GetTime()
                
            end
            
            UpdateAttackTarget(self, deltaTime)

        end

        self:UpdateTargetState()
  
    end

end

class 'Sentry' (ScriptActor)

Sentry.kMapName = "sentry"

if Server then
    Script.Load("lua/Sentry_Server.lua")
end

Sentry.kModelName = PrecacheAsset("models/marine/sentry/sentry.model")
local kAnimationGraph = PrecacheAsset("models/marine/sentry/sentry.animation_graph")

local kAttackSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/sentry_fire_loop")

local kSentryScanSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/sentry_scan")
Sentry.kUnderAttackSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/sentry_taking_damage")
Sentry.kFiringAlertSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/sentry_firing")

Sentry.kConfusedSound = PrecacheAsset("sound/NS2.fev/marine/structures/sentry_confused")

Sentry.kFireShellEffect = PrecacheAsset("cinematics/marine/sentry/fire_shell.cinematic")
//Sentry.kTracerEffect = PrecacheAsset("cinematics/marine/tracer.cinematic")

// Balance
Sentry.kPingInterval = 4
Sentry.kFov = 160
Sentry.kMaxPitch = 45
Sentry.kMaxYaw = Sentry.kFov / 2

Sentry.kBaseROF = kSentryAttackBaseROF
Sentry.kRandROF = kSentryAttackRandROF
Sentry.kSpread = Math.Radians(3)
Sentry.kBulletsPerSalvo = kSentryAttackBulletsPerSalvo
Sentry.kDamagePerBullet = kSentryAttackDamage
Sentry.kBarrelScanRate = 60      // Degrees per second to scan back and forth with no target
Sentry.kBarrelMoveRate = 150     // Degrees per second to move sentry orientation towards target or back to flat when targeted
Sentry.kTargetCheckTime = .3
Sentry.kRange = 15
Sentry.kReorientSpeed = .05
// Don't choose new target right away, to make sure multiple attacks can overwhelm sentry
Sentry.kTargetReacquireTime = .5
Sentry.kConfusedTargetReacquireTime = 1.5
Sentry.kConfuseDuration = 3
Sentry.kAttackEffectIntervall = kConfusedSentryBaseROF * .5
Sentry.kConfusedAttackEffectIntervall = kConfusedSentryBaseROF

// Animations
Sentry.kYawPoseParam = "sentry_yaw" // Sentry yaw pose parameter for aiming
Sentry.kPitchPoseParam = "sentry_pitch"
Sentry.kMuzzleNode = "fxnode_sentrymuzzle"
Sentry.kEyeNode = "fxnode_eye"
Sentry.kLaserNode = "fxnode_eye"

// prevents attacking during deploy animation for kDeployTime seconds
Sentry.kDeployTime = 3.5

Sentry.kMode = enum( {'Unbuilt', 'Scanning', 'Attacking', 'SettingTarget'} )

local kDefaultButtons = { kTechId.Attack, kTechId.None, kTechId.SetTarget, kTechId.None,
                          kTechId.None, kTechId.None, kTechId.None, kTechId.None }
local kAttackingButtons = { kTechId.None, kTechId.Stop, kTechId.SetTarget, kTechId.None,
                            kTechId.None, kTechId.None, kTechId.None, kTechId.None }
local kSettingTargetButtons = { kTechId.None, kTechId.None, kTechId.SetTarget, kTechId.None,
                                kTechId.None, kTechId.None, kTechId.None, kTechId.None }
local kPoweredDownButtons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None,
                              kTechId.None, kTechId.None, kTechId.None, kTechId.None }

local networkVars =
{
    mode = "enum Sentry.kMode",
    desiredMode = "enum Sentry.kMode",
    
    barrelYawDegrees = "interpolated float",
    barrelPitchDegrees = "interpolated float",
    
    // So we can update angles and pose parameters smoothly on client
    targetDirection = "vector",  
    
    confused = "boolean",
    
    deployed = "boolean"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(RecycleMixin, networkVars)
AddMixinNetworkVars(TurretMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(AlienDetectableMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)

function Sentry:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, RecycleMixin)
    InitMixin(self, TurretMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, AlienDetectableMixin)
    InitMixin(self, ParasiteMixin)
    
    if Client then
        InitMixin(self, CommanderGlowMixin)
    end
    
    self.desiredYawDegrees = 0
    self.desiredPitchDegrees = 0
    self.barrelYawDegrees = 0
    self.barrelPitchDegrees = 0
    self.calculatedBarrelYawDegrees = 0
    
    self.timeOfLastTargetAcquisition = 0
    
    self.timeLastTargetChange = 0
    self.powered = false
    self.confused = false
    
    self.mode = Sentry.kMode.Unbuilt
    self.desiredMode = Sentry.kMode.Unbuilt
    
    if Server then
    
        // Play a "ping" sound effect every Sentry.kPingInterval while scanning.
        local function PlayScanPing(sentry)
        
            if GetIsUnitActive(self) and not self.attacking then
                //local player = Client.GetLocalPlayer()
                //Shared.PlayPrivateSound(player, kSentryScanSoundName, nil, 1, sentry:GetModelOrigin())
            end
            return true
            
        end
        //self:AddTimedCallback(PlayScanPing, Sentry.kPingInterval)
        
        self.attackSound = Server.CreateEntity(SoundEffect.kMapName)
        self.attackSound:SetParent(self)
        self.attackSound:SetAsset(kAttackSoundName)
        
    elseif Client then
        self.timeLastAttackEffect = Shared.GetTime()
    end
    
    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)
    
end

function Sentry:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    InitMixin(self, WeldableMixin)
    //InitMixin(self, LaserMixin)
    
    self:SetModel(Sentry.kModelName, kAnimationGraph)
    
    self:SetUpdates(true)
    
    if Server then 
    
        InitMixin(self, SleeperMixin)
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        // TargetSelectors require the TargetCacheMixin for cleanup.
        InitMixin(self, TargetCacheMixin)
        
        // configure how targets are selected and validated
        self.targetSelector = TargetSelector():Init(
            self,
            Sentry.kRange, 
            true,
            { kMarineStaticTargets, kMarineMobileTargets },
            { PitchTargetFilter(self,  -Sentry.kMaxPitch, Sentry.kMaxPitch), CloakTargetFilter() })

        InitMixin(self, StaticTargetMixin)
        
    elseif Client then
    
        InitMixin(self, UnitStatusMixin)   
 
    end
    
end

function Sentry:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    // The attackSound was already destroyed at this point, clear the reference.
    if Server then
        self.attackSound = nil
    end
    
end

function Sentry:GetCanDie(byDeathTrigger)
    return not byDeathTrigger
end

function Sentry:GetSentryMode()
    return self.mode
end

function Sentry:GetCanSleep()
    return self.mode == Sentry.kMode.Scanning or self.mode == Sentry.kMode.Unbuilt
end

function Sentry:GetMinimumAwakeTime()
    return 10
end    

function Sentry:GetFov()
    return Sentry.kFov
end

local kSentryEyeHeight = Vector(0, 0.8, 0)
function Sentry:GetEyePos()
    return self:GetOrigin() + kSentryEyeHeight
    //return self:GetAttachPointOrigin(Sentry.kMuzzleNode)
end

/**
 * Fire out out muzzle attach point.
 */
function Sentry:GetViewOffset()

    // Great idea .. but it doesn't quite work - the eyepos being offset from the
    // center of the scan means that sometimes the sensor will see a target and
    // sometimes not. An alien placing itself at the edge of the fov would be a valid 
    // target when the barrel faces in the middle, but become invalid when it faces
    // the alien. To solve it would reqire the introduction of a field-of-fire for the
    // gun itself, while the field-of-view belonged to the sensor.
    // Too much work, and the simple fix is to move the eye to the center of rotation. 
    // return self:GetAttachPointOrigin(Sentry.kEyeNode)
    // ... and this doesn't work either ... the height of the eyenode drops down when the barrel elevates, thus
    // lowering the sentry eyepos.
    // lets go for a hack: manually measusured; height of muzzle when at zero pitch is at 1.0162.
    // note: the caching here assumes that you don't change the origin of the sentry
    return Vector(0, 1.0162, 0)
    
end

function Sentry:GetDeathIconIndex()
    return kDeathMessageIcon.Sentry
end

function Sentry:GetTechButtons(techId)

    if techId == kTechId.WeaponsMenu then 
        
        if self.mode == Sentry.kMode.Attacking then
            return kAttackingButtons
        elseif self.mode == Sentry.kMode.SettingTarget then
            return kSettingTargetButtons
        end
        return kDefaultButtons
        
    end
    
    return nil
    
end

function Sentry:UpdateAngles(deltaTime)
    
    // Swing barrel yaw towards target        
    if self:GetSentryMode() == Sentry.kMode.Attacking then
    
        if self.targetDirection then
        
            local invSentryCoords = self:GetAngles():GetCoords():GetInverse()
            self.relativeTargetDirection = GetNormalizedVector( invSentryCoords:TransformVector( self.targetDirection ) )
            self.desiredYawDegrees = Clamp(math.asin(-self.relativeTargetDirection.x) * 180 / math.pi, -Sentry.kMaxYaw, Sentry.kMaxYaw)            
            self.desiredPitchDegrees = Clamp(math.asin(self.relativeTargetDirection.y) * 180 / math.pi, -Sentry.kMaxPitch, Sentry.kMaxPitch)       
            
        end
        
    // Else when we have no target, swing it back and forth looking for targets
    else
    
        local sin = math.sin(math.rad((Shared.GetTime() + self:GetId() * .3) * Sentry.kBarrelScanRate))
        self.desiredYawDegrees = sin * self:GetFov() / 2
        
        // Swing barrel pitch back to flat
        self.desiredPitchDegrees = 0
    
    end
    
    // No matter what, swing barrel pitch towards desired pitch
    self.barrelPitchDegrees = Slerp(self.barrelPitchDegrees, self.desiredPitchDegrees, Sentry.kBarrelMoveRate * deltaTime)    
    self.calculatedBarrelYawDegrees = Slerp(self.calculatedBarrelYawDegrees , self.desiredYawDegrees, Sentry.kBarrelMoveRate * deltaTime)

    // the yaw network field is only used when attacking
    if self:GetSentryMode() == Sentry.kMode.Attacking then    
        self.barrelYawDegrees = self.calculatedBarrelYawDegrees
    end
    
end

function Sentry:GetReceivesStructuralDamage()
    return true
end

function Sentry:GetBarrelPoint()
    return self:GetAttachPointOrigin(Sentry.kMuzzleNode)    
end

function Sentry:GetLaserAttachCoords()

    local coords = self:GetAttachPointCoords(Sentry.kLaserNode)    
    local xAxis = coords.xAxis
    coords.xAxis = -coords.zAxis
    coords.zAxis = xAxis

    return coords   
end

function Sentry:UpdateAttackSound(play)

    if Server then
    
        if not GetIsUnitActive(self) and not self.powered or self.confused or not play then
        
            if self.attackSound:GetIsPlaying() then
                self.attackSound:Stop()
            end
            
        else
        
            if play and not self.attackSound:GetIsPlaying() then
                self.attackSound:Start()
            end
            
        end
        
    elseif Client and GetIsUnitActive(self) and self.powered then
    
        local intervall = ConditionalValue(self.confused, Sentry.kConfusedAttackEffectIntervall, Sentry.kAttackEffectIntervall)
        if play and (self.timeLastAttackEffect + intervall < Shared.GetTime()) then
        
            if self.confused then
                self:TriggerEffects("sentry_single_attack")
            end
            
            // plays muzzle flash and smoke
            self:TriggerEffects("sentry_attack")

            self.timeLastAttackEffect = Shared.GetTime()
        end
    
    end
    
end

function Sentry:GetPlayInstantRagdoll()
    return true
end    

function Sentry:GetIsLaserActive()
    return GetIsUnitActive(self) and self.deployed and self.powered
end

function Sentry:OnUpdate(deltaTime)

    PROFILE("Sentry:OnUpdate")
    
    ScriptActor.OnUpdate(self, deltaTime)
    
    if GetIsUnitActive(self) and self.powered then
    
        if Server then
        
            if self.confused and self.timeConfused < Shared.GetTime() then
                self.confused = false
            end
            
            // Handle sentry state changes
            UpdateMode(self, deltaTime)
            
            if self.deployed then
                UpdateAttack(self, deltaTime)
            end
            
        end
        
        // Update barrel position    
        local mode = self:GetSentryMode()
        
        if mode == Sentry.kMode.Scanning or mode == Sentry.kMode.Attacking then
            self:UpdateAngles(deltaTime)
        end
        
    end
    
    self:UpdateAttackSound(self.mode == Sentry.kMode.Attacking)
    
end

function Sentry:OnUpdatePoseParameters()

    PROFILE("Sentry:OnUpdatePoseParameters")

    local pitchConfused = 0
    local yawConfused = 0
    
    // alter the yaw and pitch slightly, barrel will swirl around
    if self.confused then
    
        pitchConfused = math.sin(Shared.GetTime() * 6) * 2
        yawConfused = math.cos(Shared.GetTime() * 6) * 2
        
    end
    
    self:SetPoseParam(Sentry.kPitchPoseParam, self.barrelPitchDegrees + pitchConfused)
    self:SetPoseParam(Sentry.kYawPoseParam, self.barrelYawDegrees + yawConfused)
    
    // when the sentry is in scan mode, the network field barrelYawDegrees is not used
    local yaw = self.mode == Sentry.kMode.Scanning and self.calculatedBarrelYawDegrees or self.barrelYawDegrees
    self:SetPoseParam(Sentry.kYawPoseParam, yaw + yawConfused)
    
end

function Sentry:GetCanGiveDamageOverride()
    return true
end

/*
function Sentry:OnTag(tagName)

    // Go into scanning after the deploy animation has completed.
    if self.desiredMode == Sentry.kMode.Scanning and tagName == "end" then
        self.mode = Sentry.kMode.Scanning
    elseif tagName == "deploy_end" then
        self.deployed = true
    end

end
*/

function Sentry:OnPowerOn()
    // 
end

function Sentry:OnPowerOff()
    //
end

function Sentry:OnUpdateAnimationInput(modelMixin)

    PROFILE("Sentry:OnUpdateAnimationInput")    
    modelMixin:SetAnimationInput("attack", self.mode == Sentry.kMode.Attacking)    
end

// used to prevent showing the hit indicator for the commander
function Sentry:GetShowHitIndicator()
    return false
end

local kSentryHealthbarOffset = Vector(0, 0.4, 0)
function Sentry:GetHealthbarOffset()
    return kSentryHealthbarOffset
end 

Shared.LinkClassToMap("Sentry", Sentry.kMapName, networkVars)