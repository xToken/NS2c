// ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ============
//
// lua\Exo.lua
//
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Marine.lua")
Script.Load("lua/Weapons/Marine/ExoWeaponHolder.lua")

local kExoFirstPersonHitEffectName = PrecacheAsset("cinematics/marine/exo/hit_view.cinematic")

class 'Exo' (Marine)

kExoThrusterMode = enum({'Vertical', 'Horizontal'})

local networkVars =
{
    idleSound2DId = "private entityid",
    thrustersActive = "compensated boolean",
    timeThrustersEnded = "private time",
    timeThrustersStarted = "private time",
    thrusterMode = "enum kExoThrusterMode"
}

Exo.kMapName = "exo"

local kModelName = PrecacheAsset("models/marine/exosuit/exosuit_cm.model")
local kAnimationGraph = PrecacheAsset("models/marine/exosuit/exosuit_cm.animation_graph")

local kRailgunModelName = PrecacheAsset("models/marine/exosuit/exosuit_cr.model")
local kRailgunAnimationGraph = PrecacheAsset("models/marine/exosuit/exosuit_cr.animation_graph")

Shared.PrecacheSurfaceShader("shaders/ExoScreen.surface_shader")

local kIdle2D = PrecacheAsset("sound/NS2.fev/marine/heavy/idle_2D")

if Client then
    Shared.PrecacheSurfaceShader("cinematics/vfx_materials/heal_exo_view.surface_shader")
end

local kExoHealViewMaterialName = "cinematics/vfx_materials/heal_exo_view.material"

local kCrouchShrinkAmount = 0
local kExtentsCrouchShrinkAmount = 0
local kViewOffsetHeight = 2.3
local kExoScale = 0.85

local kThrustersCooldownTime = 0
local kThrusterDuration = 5

local kDeploy2DSound = PrecacheAsset("sound/NS2.fev/marine/heavy/deploy_2D")

local kThrusterCinematic = PrecacheAsset("cinematics/marine/exo/thruster.cinematic")
local kThrusterLeftAttachpoint = "Exosuit_LFoot"
local kThrusterRightAttachpoint = "Exosuit_RFoot"

local kThrusterUpwardsAcceleration = 2
local kThrusterHorizontalAcceleration = 23
// added to max speed when using thrusters
local kHorizontalThrusterAddSpeed = 2.5

Exo.kXZExtents = 0.55
Exo.kYExtents = 1.2

function Exo:OnCreate()

    Marine.OnCreate(self)

    self.deployed = false
    
    self.idleSound2DId = Entity.invalidId
    self.timeThrustersEnded = 0
    self.timeThrustersStarted = 0
    self.thrusterMode = kExoThrusterMode.Vertical
    
    if Server then
    
        self.idleSound2D = Server.CreateEntity(SoundEffect.kMapName)
        self.idleSound2D:SetAsset(kIdle2D)
        self.idleSound2D:SetParent(self)
        self.idleSound2D:Start()
        
        // Only sync 2D sound with this Exo player.
        self.idleSound2D:SetPropagate(Entity.Propagate_Callback)
        function self.idleSound2D.OnGetIsRelevant(_, player)
            return player == self
        end
        
        self.idleSound2DId = self.idleSound2D:GetId()
        
    end
    
end

function Exo:OnInitialized()

    // Only set the model on the Server, the Client
    // will already have the correct model at this point.
    if Server then
    
        local modelName = kModelName
        local graphName = kAnimationGraph
        self.hasDualGuns = false
        
        if self.layout == "Railgun" then
            modelName = kRailgunModelName
            graphName = kRailgunAnimationGraph
        end
        
        // SetModel must be called before Player.OnInitialized is called so the attach points in
        // the Exo are valid to attach weapons to. This is far too subtle...
        self:SetModel(modelName, graphName)
        
    end

    Marine.OnInitialized(self)
    
    if Server then
    
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        self.armor = self:GetArmorAmount()
        self.maxArmor = self.armor
        
        self.thrustersActive = false
        
    elseif Client then
    
        self.clientThrustersActive = self.thrustersActive

        self.thrusterLeftCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        self.thrusterLeftCinematic:SetCinematic(kThrusterCinematic)
        self.thrusterLeftCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.thrusterLeftCinematic:SetParent(self)
        self.thrusterLeftCinematic:SetCoords(Coords.GetIdentity())
        self.thrusterLeftCinematic:SetAttachPoint(self:GetAttachPointIndex(kThrusterLeftAttachpoint))
        self.thrusterLeftCinematic:SetIsVisible(false)
        
        self.thrusterRightCinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        self.thrusterRightCinematic:SetCinematic(kThrusterCinematic)
        self.thrusterRightCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
        self.thrusterRightCinematic:SetParent(self)
        self.thrusterRightCinematic:SetCoords(Coords.GetIdentity())
        self.thrusterRightCinematic:SetAttachPoint(self:GetAttachPointIndex(kThrusterRightAttachpoint))
        self.thrusterRightCinematic:SetIsVisible(false)
        
    end
    
end

function Exo:GetVariantModel()
    local modelName = kModelName    
    if self.layout == "Railgun" then
        modelName = kRailgunModelName
    end
    return modelName
end

function Exo:GetControllerPhysicsGroup()
    return PhysicsGroup.BigPlayerControllersGroup
end

function Exo:GetCrouchShrinkAmount()
    return kCrouchShrinkAmount
end

function Exo:GetExtentsCrouchShrinkAmount()
    return kExtentsCrouchShrinkAmount
end

// exo has no crouch animations
function Exo:GetCanCrouch()
    return false
end

function Exo:InitWeapons()

    Player.InitWeapons(self)
    
    local weaponHolder = self:GiveItem(ExoWeaponHolder.kMapName, false)
    
    if self.layout == "Minigun" then
        weaponHolder:SetWeapons(Claw.kMapName, Minigun.kMapName)
    elseif self.layout == "Railgun" then
        weaponHolder:SetWeapons(Claw.kMapName, Railgun.kMapName)
    else
    
        Print("Warning: incorrect layout set for exosuit")
        weaponHolder:SetWeapons(Claw.kMapName, Minigun.kMapName)
        
    end
    
    weaponHolder:TriggerEffects("exo_login")
    self.inventoryWeight = weaponHolder:GetInventoryWeight(self)
    self:SetActiveWeapon(ExoWeaponHolder.kMapName)
    StartSoundEffectForPlayer(kDeploy2DSound, self)
    
end

function Exo:OnDestroy()
    
    if self.thrusterLeftCinematic then
    
        Client.DestroyCinematic(self.thrusterLeftCinematic)
        self.thrusterLeftCinematic = nil
    
    end
    
    if self.thrusterRightCinematic then
    
        Client.DestroyCinematic(self.thrusterRightCinematic)
        self.thrusterRightCinematic = nil
    
    end
    
    if self.flares then
    
        Client.DestroyCinematic(self.flares)
        self.flares = nil
        
    end
    
end

function Exo:GetMaxViewOffsetHeight()
    return kViewOffsetHeight
end

function Exo:MakeSpecialEdition()
    // Currently there's no Exo special edition visual difference
end

function Exo:GetHeadAttachpointName()
    return "Exosuit_HoodHinge"
end

function Exo:GetArmorAmount(armorLevels)

    if not armorLevels then
        armorLevels = self:GetArmorLevel()
    end
    
    return kExosuitArmor + armorLevels * kExosuitArmorPerUpgradeLevel
    
end

function Exo:GetFirstPersonHitEffectName()
    return kExoFirstPersonHitEffectName
end 

local kEngageOffset = Vector(0, 1.5, 0)
function Exo:GetEngagementPointOverride()
    return self:GetOrigin() + kEngageOffset
end

function Exo:GetHealthbarOffset()
    return 1.8
end

function Exo:GetPlayerStatusDesc()
    return self:GetIsAlive() and kPlayerStatus.Exo or kPlayerStatus.Dead
end

local function UpdateIdle2DSound(self, yaw, pitch, dt)

    if self.idleSound2DId ~= Entity.invalidId then
    
        local idleSound2D = Shared.GetEntity(self.idleSound2DId)
        
        self.lastExoYaw = self.lastExoYaw or yaw
        self.lastExoPitch = self.lastExoPitch or pitch
        
        local yawDiff = math.abs(GetAnglesDifference(yaw, self.lastExoYaw))
        local pitchDiff = math.abs(GetAnglesDifference(pitch, self.lastExoPitch))
        
        self.lastExoYaw = yaw
        self.lastExoPitch = pitch
        
        local rotateSpeed = math.min(1, ((yawDiff ^ 2) + (pitchDiff ^ 2)) / 0.05)
        //idleSound2D:SetParameter("rotate", rotateSpeed, 1)
        
    end
    
end

local function UpdateThrusterEffects(self)

    if self.clientThrustersActive ~= self.thrustersActive then
    
        self.clientThrustersActive = self.thrustersActive
        
        // TODO: start / end thruster loop sound
        
        if self.thrustersActive then            
            self:TriggerEffects("exo_thruster_start")            
        else            
            self:TriggerEffects("exo_thruster_end")            
        end
    
    end
    
    local showEffect = ( not self:GetIsLocalPlayer() or self:GetIsThirdPerson() ) and self.thrustersActive
    self.thrusterLeftCinematic:SetIsVisible(showEffect)
    self.thrusterRightCinematic:SetIsVisible(showEffect)

end

function Exo:OnProcessMove(input)

    Marine.OnProcessMove(self, input)
    
    if Client and not Shared.GetIsRunningPrediction() then
        UpdateIdle2DSound(self, input.yaw, input.pitch, input.time)
        UpdateThrusterEffects(self)
    end
    
end

if Server then
    
    function Exo:OnKill(attacker, doer, point, direction)
    
        Marine.OnKill(self, attacker, doer, point, direction)
        
        local activeWeapon = self:GetActiveWeapon()
        if activeWeapon and activeWeapon.OnParentKilled then
            activeWeapon:OnParentKilled(attacker, doer, point, direction)
        end
        
        self:TriggerEffects("death", { classname = self:GetClassName(), effecthostcoords = Coords.GetTranslation(self:GetOrigin()) })
        
    end
    
end

function Exo:GetDeathMapName()
    return MarineSpectator.kMapName
end

function Exo:OnTag(tagName)

    PROFILE("Exo:OnTag")

    Marine.OnTag(self, tagName)
    
    if tagName == "deploy_end" then
        self.deployed = true
    end
    
end

function Exo:HandleButtons(input)

    Marine.HandleButtons(self, input)
    
    self:UpdateThrusters(input)
    
end

local function HandleThrusterStart(self, thrusterMode)

    self.thrustersActive = true 
    self.timeThrustersStarted = Shared.GetTime()
    self.thrusterMode = thrusterMode

end

local function HandleThrusterEnd(self)

    self.thrustersActive = false
    self.timeThrustersEnded = Shared.GetTime()
    
end

function Exo:UpdateThrusters(input)

    local lastThrustersActive = self.thrustersActive
    local jumpPressed = bit.band(input.commands, Move.Jump) ~= 0
    local movementSpecialPressed = bit.band(input.commands, Move.MovementModifier) ~= 0
    local thrusterDesired = jumpPressed or movementSpecialPressed

    if thrusterDesired ~= lastThrustersActive then
    
        if thrusterDesired then
        
            if self.timeThrustersEnded + kThrustersCooldownTime < Shared.GetTime() then
                HandleThrusterStart(self, jumpPressed and kExoThrusterMode.Vertical or kExoThrusterMode.Horizontal)
            end

        else
            HandleThrusterEnd(self)
        end
        
    end
    
    if self.thrustersActive and self.timeThrustersStarted + kThrusterDuration < Shared.GetTime() then
        HandleThrusterEnd(self)
    end

end

local kUpVector = Vector(0, 1, 0)
function Exo:ModifyVelocity(input, velocity, deltaTime)

    PROFILE("Exo:ModifyVelocity")
    
    if self.thrustersActive then
    
        if self.thrusterMode == kExoThrusterMode.Vertical then   
        
            velocity:Add(kUpVector * kThrusterUpwardsAcceleration * deltaTime)
            velocity.y = math.min(1.5, velocity.y)
            
        elseif self.thrusterMode == kExoThrusterMode.Horizontal then
        
            input.move:Scale(0)
        
            local maxSpeed = self:GetMaxSpeed() + kHorizontalThrusterAddSpeed
            local wishDir = self:GetViewCoords().zAxis
            wishDir.y = 0
            wishDir:Normalize()
            
            local currentSpeed = wishDir:DotProduct(velocity)
            local addSpeed = math.max(0, maxSpeed - currentSpeed)
            
            if addSpeed > 0 then
                    
                local accelSpeed = kThrusterHorizontalAcceleration * deltaTime               
                accelSpeed = math.min(addSpeed, accelSpeed)
                velocity:Add(wishDir * accelSpeed)
            
            end
        
        end
        
    end
    
end

if Client then

    function Exo:OnUpdate(deltaTime)

        Marine.OnUpdate(self, deltaTime)
        UpdateThrusterEffects(self)

    end

end

function Exo:GetAnimateDeathCamera()
    return false
end

function Exo:OverrideHealViewMateral()
    return kExoHealViewMaterialName
end

function  Exo:GetShowDamageArrows()
    return true
end

// for jetpack fuel display
function Exo:GetFuel()

    if self.thrustersActive then
        self.fuelFraction = 1 - Clamp((Shared.GetTime() - self.timeThrustersStarted) / kThrusterDuration, 0, 1)
    else
        self.fuelFraction = Clamp((Shared.GetTime() - self.timeThrustersEnded) / kThrustersCooldownTime, 0, 1)
    end
    
    return self.fuelFraction
        
end

function Exo:OnAdjustModelCoords(modelCoords)
    local coords = modelCoords
    coords.xAxis = coords.xAxis * kExoScale
    coords.yAxis = coords.yAxis * kExoScale
    coords.zAxis = coords.zAxis * kExoScale
    return coords
end

function Exo:OnUpdateAnimationInput(modelMixin)

    PROFILE("Exo:OnUpdateAnimationInput")
    
    Marine.OnUpdateAnimationInput(self, modelMixin)
    
    if self.thrustersActive then    
        modelMixin:SetAnimationInput("move", "jump")
    end
    
end

Shared.LinkClassToMap("Exo", Exo.kMapName, networkVars, true)