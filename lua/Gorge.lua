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
Script.Load("lua/Weapons/Alien/DropStructureAbility2.lua")
Script.Load("lua/Weapons/Alien/Web.lua")
Script.Load("lua/Weapons/Alien/BileBomb.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/BuildingMixin.lua")

class 'Gorge' (Alien)

Gorge.kMapName = "gorge"

Gorge.kModelName = PrecacheAsset("models/alien/gorge/gorge.model")
local kViewModelName = PrecacheAsset("models/alien/gorge/gorge_view.model")
local kGorgeAnimationGraph = PrecacheAsset("models/alien/gorge/gorge.animation_graph")

if Server then    
    Script.Load("lua/Gorge_Server.lua")
end

Gorge.kXZExtents = 0.5
Gorge.kYExtents = 0.475

local kMass = 80
local kJumpHeight = 1.2
local kStartSlideForce = 15
local kViewOffsetHeight = 0.6
local kMaxSpeed = 4.6
local kMaxSlideSpeed = 13

local kBellySlideCost = 25
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

function Gorge:OnCreate()

    InitMixin(self, CameraHolderMixin, { kFov = kGorgeFov })
    InitMixin(self, BuildingMixin)
    
    Alien.OnCreate(self)
    
    InitMixin(self, DissolveMixin)
    
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

    local kGorgeHealthbarOffset = Vector(0, 0.7, 0)
    function Gorge:GetHealthbarOffset()
        return kGorgeHealthbarOffset
    end  

    function Gorge:OverrideInput(input)

        // Always let the DropStructureAbility override input, since it handles client-side-only build menu

        local buildAbility = self:GetWeapon(DropStructureAbility.kMapName)
        local buildAbility2 = self:GetWeapon(DropStructureAbility2.kMapName)

        if buildAbility then
            input = buildAbility:OverrideInput(input)
        end
        
        if buildAbility2 then
            input = buildAbility2:OverrideInput(input)
        end        
        
        return Player.OverrideInput(self, input)
        
    end
    
end

function Gorge:GetBaseArmor()
    return kGorgeArmor
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

function Gorge:GetExtentsCrouchShrinkAmount()
    return 0
end

function Gorge:GetCanCrouch()
    return false
end

function Gorge:GetViewModelName()
    return kViewModelName
end

function Gorge:GetJumpHeight()
    return kJumpHeight
end

function Gorge:GetIsBellySliding()
    return self.sliding
end
/*
function Gorge:GetCanJump()
    return not self:GetIsBellySliding()
end
*/
local function GetIsSlidingDesired(self, input)

    if bit.band(input.commands, Move.MovementModifier) == 0 then
        return false
    end
    
    if self.crouching then
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
        self:DeductAbilityEnergy(kBellySlideCost)
        self:TriggerUncloak()
        self:PrimaryAttackEnd()
        self:SecondaryAttackEnd()
        
    end
    
    if not slidingDesired and self.sliding then
    
        self.sliding = false
        
        self.timeSlideEnd = Shared.GetTime()
    
    end

    // Have Gorge lean into turns depending on input. He leans more at higher rates of speed.
    if self:GetIsBellySliding() then

        local desiredBellyYaw = 2 * (-input.move.x / kSlidingMoveInputScalar) * (self:GetVelocity():GetLength() / self:GoldSrc_GetMaxSpeed())
        self.bellyYaw = Slerp(self.bellyYaw, desiredBellyYaw, input.time * kGorgeLeanSpeed)
        
    end
    
end

function Gorge:GetCanRepairOverride(target)
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

function Gorge:SetCrouchState(newCrouchState)
    self.crouching = newCrouchState
end

function Gorge:GoldSrc_GetFriction()
    if self:GetIsBellySliding() then
        return Player.GoldSrc_GetFriction(self) * 0.2
    else
        return Player.GoldSrc_GetFriction(self)
    end
end

function Gorge:GoldSrc_GetMaxSpeed(possible)
    
    if possible then
        return kMaxSpeed
    end
    
    local maxSpeed = kMaxSpeed
    /*
    if self:GetIsBellySliding() then
        maxSpeed = kMaxSlideSpeed
    end
    */
    return maxSpeed * self:GetMovementSpeedModifier()
    
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

Gorge.kSlideControl = 1

function Gorge:ModifyVelocity(input, velocity)

    Alien.ModifyVelocity(self, input, velocity)
    
    // Give a little push forward to make sliding useful
    if self.startedSliding then
    
        if self:GetIsOnGround() then
    
            local pushDirection = GetNormalizedVectorXZ(self:GetViewCoords().zAxis)
            local force = kStartSlideForce * self:GetMovementSpeedModifier()
            
            local impulse = pushDirection * force

            velocity.x = velocity.x * 0.5 + impulse.x
            velocity.y = velocity.y * 0.5 + impulse.y
            velocity.z = velocity.z * 0.5 + impulse.z
        
        end
        
        self.startedSliding = false

    end
    
end

function Gorge:GetPitchSmoothRate()
    return 1
end

function Gorge:GetPitchRollRate()
    return 3
end

local kMaxSlideRoll = math.rad(20)

function Gorge:GetDesiredAngles()

    local desiredAngles = Alien.GetDesiredAngles(self)
    
    if self:GetIsBellySliding() then
        desiredAngles.pitch = - self.verticalVelocity / 10 
        desiredAngles.roll = GetNormalizedVectorXZ(self:GetVelocity()):DotProduct(self:GetViewCoords().xAxis) * kMaxSlideRoll
    end
    
    return desiredAngles

end

function Gorge:PreUpdateMove(input, runningPrediction)

    self.prevY = self:GetOrigin().y

end

function Gorge:PostUpdateMove(input, runningPrediction)

    if self:GetIsBellySliding() and self:GetIsOnGround() then
    
        local velocity = self:GetVelocity()
    
        local yTravel = self:GetOrigin().y - self.prevY
        local xzSpeed = velocity:GetLengthXZ()
        
        xzSpeed = xzSpeed + yTravel * -4
        
        if xzSpeed < kMaxSpeed or yTravel > 0 then
        
            local directionXZ = GetNormalizedVectorXZ(velocity)
            directionXZ:Scale(xzSpeed)

            velocity.x = directionXZ.x
            velocity.z = directionXZ.z
            
            self:SetVelocity(velocity)
            
        end

        self.verticalVelocity = yTravel / input.time
    
    end

end

if Client then

    function Gorge:GetShowGhostModel()
    
        local weapon = self:GetActiveWeapon()
        if weapon and (weapon:isa("DropStructureAbility") or weapon:isa("DropStructureAbility2")) then
            return weapon:GetShowGhostModel()
        end
        
        return false
        
    end    

    function Gorge:GetGhostModelTechId()
    
        local weapon = self:GetActiveWeapon()
        if weapon and (weapon:isa("DropStructureAbility") or weapon:isa("DropStructureAbility2")) then
            return weapon:GetGhostModelTechId()
        end
        
    end

    function Gorge:GetGhostModelCoords()
    
        local weapon = self:GetActiveWeapon()
        if weapon and (weapon:isa("DropStructureAbility") or weapon:isa("DropStructureAbility2")) then
            return weapon:GetGhostModelCoords()
        end

    end
    
    function Gorge:GetLastClickedPosition()
    
        local weapon = self:GetActiveWeapon()
        if weapon and (weapon:isa("DropStructureAbility") or weapon:isa("DropStructureAbility2")) then
            return weapon.lastClickedPosition
        end
        
    end

    function Gorge:GetIsPlacementValid()
    
        local weapon = self:GetActiveWeapon()
        if weapon and (weapon:isa("DropStructureAbility") or weapon:isa("DropStructureAbility2")) then
            return weapon:GetIsPlacementValid()
        end
    
    end

end

function Gorge:GetCanAttack()
    return Alien.GetCanAttack(self) and not self:GetIsBellySliding()
end

function Gorge:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.28, 0)
end

Shared.LinkClassToMap("Gorge", Gorge.kMapName, networkVars)
