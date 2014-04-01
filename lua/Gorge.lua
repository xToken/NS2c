// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Gorge.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Utility.lua")
Script.Load("lua/Alien.lua")
Script.Load("lua/Weapons/Alien/SpitSpray.lua")
Script.Load("lua/Weapons/Alien/DropStructureAbility.lua")
Script.Load("lua/Weapons/Alien/BabblerAbility.lua")
Script.Load("lua/Weapons/Alien/BileBomb.lua")
Script.Load("lua/Weapons/Alien/Web.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/BuildingMixin.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")
Script.Load("lua/GorgeVariantMixin.lua")

class 'Gorge' (Alien)

Gorge.kMapName = "gorge"

Gorge.kHealTarget = PrecacheAsset("sound/NS2.fev/alien/voiceovers/need_healing")
Gorge.kModelName = PrecacheAsset("models/alien/gorge/gorge.model")
local kViewModelName = PrecacheAsset("models/alien/gorge/gorge_view.model")
local kGorgeAnimationGraph = PrecacheAsset("models/alien/gorge/gorge.animation_graph")

if Server then    
    Script.Load("lua/Gorge_Server.lua")
end

Gorge.kXZExtents = 0.5
Gorge.kYExtents = 0.475

local kMass = 80
local kStartSlideForce = 1.5
local kSlidingGroundFriction = 0.2
local kSlidingAcceleration = 0
local kStartSlideSpeed = 7
local kViewOffsetHeight = 0.6
local kMaxSpeed = 4.2
local kMaxSlideSpeed = 9
local kMaxWalkSpeed = 2.0
local kBellySlideCost = 30
local kSlidingMoveInputScalar = 0.1
local kSlideCoolDown = 1.5

local kGorgeBellyYaw = "belly_yaw"
local kGorgeLeanSpeed = 2

local networkVars =
{
    bellyYaw = "private float",
    timeSlideEnd = "private time",
    startedSliding = "private boolean",
    sliding = "boolean"
}

AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(GorgeVariantMixin, networkVars)

function Gorge:OnCreate()

    InitMixin(self, CameraHolderMixin, { kFov = kGorgeFov })
    InitMixin(self, BuildingMixin)
	InitMixin(self, GorgeVariantMixin)
    
    Alien.OnCreate(self)
    
    InitMixin(self, DissolveMixin)
	InitMixin(self, PredictedProjectileShooterMixin)
    
    self.bellyYaw = 0
    self.timeSlideEnd = 0
    self.startedSliding = false
    self.sliding = false
    self.verticalVelocity = 0

end

function Gorge:OnInitialized()

    Alien.OnInitialized(self)
    
    self:SetModel(Gorge.kModelName, kGorgeAnimationGraph)
        
    if Client then
    
        self:AddHelpWidget("GUIGorgeHealHelp", 2)
        self:AddHelpWidget("GUIGorgeBellySlideHelp", 2)
        self:AddHelpWidget("GUIGorgeBuildMenuHelp", 2)
        
    end
    
end

if Client then

    function Gorge:GetHealthbarOffset()
        return 0.7
    end  

    function Gorge:OverrideInput(input)

        // Always let the DropStructureAbility override input, since it handles client-side-only build menu

        local buildAbility = self:GetWeapon(DropStructureAbility.kMapName)

        if buildAbility then
            input = buildAbility:OverrideInput(input)
        end
        
        return Player.OverrideInput(self, input)
        
    end
    
end

function Gorge:GetBaseArmor()
    return kGorgeArmor
end

function Gorge:GetBaseHealth()
    return kGorgeHealth
end

function Gorge:GetArmorFullyUpgradedAmount()
    return kGorgeArmorFullyUpgradedAmount
end

function Gorge:GetMaxViewOffsetHeight()
    return kViewOffsetHeight
end

function Gorge:GetCrouchShrinkAmount()
    return 0
end

function Gorge:GetCrouchTime()
    return 0
end

function Gorge:GetExtentsCrouchShrinkAmount()
    return 0
end

function Gorge:GetViewModelName()
    return kViewModelName
end

function Gorge:GetIsBellySliding()
    return self.sliding
end

function Gorge:GetGroundFriction()
    return ConditionalValue(self:GetIsBellySliding(), kSlidingGroundFriction, Player.GetGroundFriction(self))
end

function Gorge:GetAcceleration(OnGround)
    return ConditionalValue(self:GetIsBellySliding() and OnGround, kSlidingAcceleration, Player.GetAcceleration(self, OnGround))
end

local function GetIsSlidingDesired(self, input)

    if bit.band(input.commands, Move.MovementModifier) == 0 then
        return false
    end
    
    if self:GetCrouching() then
        return false
    end
    
    if self:GetVelocity():GetLengthXZ() < 3 or self:GetIsJumping() then
    
        if self:GetIsBellySliding() then    
            return false
        end 
           
    else
        
        local zAxis = self:GetViewCoords().zAxis
        zAxis.y = 0
        zAxis:Normalize()
        
        if GetNormalizedVectorXZ(self:GetVelocity()):DotProduct( zAxis ) < 0.2 then
            return false
        end
    
    end
    
    return true

end

// Handle transitions between starting-sliding, sliding, and ending-sliding
local function UpdateGorgeSliding(self, input)

    PROFILE("Gorge:UpdateGorgeSliding")
    
    local slidingDesired = GetIsSlidingDesired(self, input)
    
    if slidingDesired and not self.sliding and self.timeSlideEnd + kSlideCoolDown < Shared.GetTime() and self:GetIsOnGround() and self:GetEnergy() >= kBellySlideCost then
    
        self.sliding = true
        self.startedSliding = true
        self.prevY = nil
        self:DeductAbilityEnergy(kBellySlideCost)
        self:TriggerUncloak()
        self:PrimaryAttackEnd()
        self:SecondaryAttackEnd()
        
    end
    
    if not slidingDesired and self.sliding then
    
        self.sliding = false
        self.timeSlideEnd = Shared.GetTime()
        self.prevY = nil
    
    end

    // Have Gorge lean into turns depending on input. He leans more at higher rates of speed.
    if self:GetIsBellySliding() then

        local desiredBellyYaw = 2 * (-input.move.x / kSlidingMoveInputScalar) * (self:GetVelocityLength() / self:GetMaxSpeed())
        self.bellyYaw = Slerp(self.bellyYaw, desiredBellyYaw, input.time * kGorgeLeanSpeed)
        
    end
    
end

function Gorge:GetCanRepairOverride(target)
    return true
end

function Gorge:GetCanSeeDamagedIcon(ofEntity)
    return true
end

function Gorge:HandleButtons(input)

    PROFILE("Gorge:HandleButtons")
    
    Alien.HandleButtons(self, input)
    
    UpdateGorgeSliding(self, input)
    
end

function Gorge:OnUpdatePoseParameters(viewModel)

    PROFILE("Gorge:OnUpdatePoseParameters")
    
    Alien.OnUpdatePoseParameters(self, viewModel)
    
    self:SetPoseParam(kGorgeBellyYaw, self.bellyYaw * 45)
    
end

function Gorge:ModifyVelocity(input, velocity, deltaTime)
    
    PROFILE("Gorge:ModifyVelocity")
    
    // Give a little push forward to make sliding useful
    if self.startedSliding then
    
        if self:GetIsOnGround() then
    
            local pushDirection = GetNormalizedVectorXZ(self:GetViewCoords().zAxis)
            
            local currentSpeed = math.max(0, pushDirection:DotProduct(velocity))
            
            local addSpeed = math.max(0, kStartSlideSpeed - currentSpeed)
            local impulse = pushDirection * addSpeed

            velocity:Add(impulse)
        
        end
        
        self.prevY = nil
        self.startedSliding = false

    end
    
    if self:GetIsBellySliding() and self:GetIsOnGround() then
    
        local currentSpeed = velocity:GetLengthXZ()
        local prevY = velocity.y
        velocity.y = 0  
        
        local addVelocity = self:GetViewCoords():TransformVector(input.move)
        addVelocity.y = 0
        addVelocity:Normalize()
        addVelocity:Scale(deltaTime * 10)
        
        velocity:Add(addVelocity) 
        velocity:Normalize()
        velocity:Scale(currentSpeed)
        
        local yTravel = self:GetOrigin().y - (self.prevY or self:GetOrigin().y)
        currentSpeed = velocity:GetLengthXZ() + yTravel * -4
        
        if currentSpeed < kMaxSlideSpeed or yTravel > 0 then
        
            local directionXZ = GetNormalizedVectorXZ(velocity)
            directionXZ:Scale(currentSpeed)

            velocity.x = directionXZ.x
            velocity.z = directionXZ.z
            
        end
        
        velocity.y = prevY
        self.verticalVelocity = yTravel / input.time
        self.prevY = self:GetOrigin().y
    end
    
end

function Gorge:GetMaxSpeed(possible)
    
    if possible then
        return kMaxSpeed
    end
    
    local maxSpeed = kMaxSpeed
    
    if self:GetCrouching() and self:GetCrouchAmount() == 1 and self:GetIsOnGround() and not self:GetLandedRecently() then
        maxSpeed = kMaxWalkSpeed
    end
    
    return maxSpeed + self:GetMovementSpeedModifier()
    
end

function Gorge:GetMass()
    return kMass
end

function Gorge:OnUpdateAnimationInput(modelMixin)

    PROFILE("Gorge:OnUpdateAnimationInput")
    
    Alien.OnUpdateAnimationInput(self, modelMixin)
    
    if self:GetIsBellySliding() then
        modelMixin:SetAnimationInput("move", "belly")
    end
    
end

function Gorge:GetCanCloakOverride()
    return not self:GetIsBellySliding()
end

function Gorge:GetPitchSmoothRate()
    return 1
end

function Gorge:GetPitchRollRate()
    return 3
end

//Vanilla NS2
function Gorge:GetSimpleAcceleration(onGround)
    return ConditionalValue(onGround, self:GetIsBellySliding() and 0 or 8, 9)
end

function Gorge:GetAirControl()
    return 5
end

function Gorge:GetSimpleFriction(onGround)
    if onGround then
        if self:GetIsBellySliding() then
            return 0.16
        end
        return 7
    else
        return 0.8
    end
end
//End Vanilla NS2

local kMaxSlideRoll = math.rad(20)

function Gorge:GetDesiredAngles()

    local desiredAngles = Alien.GetDesiredAngles(self)
    
    if self:GetIsBellySliding() then
        desiredAngles.pitch = - self.verticalVelocity / 10 
        desiredAngles.roll = GetNormalizedVectorXZ(self:GetVelocity()):DotProduct(self:GetViewCoords().xAxis) * kMaxSlideRoll
    end
    
    return desiredAngles

end

if Client then

    function Gorge:GetShowGhostModel()
    
        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") then
            return weapon:GetShowGhostModel()
        end
        
        return false
        
    end
    
    function Gorge:GetGhostModelOverride()
    
        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") and weapon.GetGhostModelName then
            return weapon:GetGhostModelName(self)
        end
        
    end
    
    function Gorge:GetGhostModelTechId()
    
        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") then
            return weapon:GetGhostModelTechId()
        end
        
    end
    
    function Gorge:GetGhostModelCoords()
    
        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") then
            return weapon:GetGhostModelCoords()
        end
        
    end
    
    function Gorge:GetLastClickedPosition()
    
        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") then
            return weapon.lastClickedPosition
        end
        
    end

    function Gorge:GetIsPlacementValid()
    
        local weapon = self:GetActiveWeapon()
        if weapon and weapon:isa("DropStructureAbility") then
            return weapon:GetIsPlacementValid()
        end
    
    end

end

function Gorge:GetCanSeeDamagedIcon(ofEntity)
    return not ofEntity:isa("Cyst")
end

function Gorge:GetCanAttack()
    return Alien.GetCanAttack(self) and not self:GetIsBellySliding()
end

local kEngageOffset = Vector(0, 0.28, 0)
function Gorge:GetEngagementPointOverride()
    return self:GetOrigin() + kEngageOffset
end

Shared.LinkClassToMap("Gorge", Gorge.kMapName, networkVars, true)