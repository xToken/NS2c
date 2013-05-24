// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\JetpackMarine.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at
//
//    Thanks to twiliteblue for initial input.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================
Script.Load("lua/Marine.lua")
Script.Load("lua/Jetpack.lua")

class 'JetpackMarine' (Marine)

JetpackMarine.kMapName = "jetpackmarine"
JetpackMarine.kJetpackMode = enum( {'Disabled', 'TakeOff', 'Flying', 'Landing'} )

local kJetpackStart = PrecacheAsset("sound/NS2.fev/marine/common/jetpack_start")
local kJetpackEnd = PrecacheAsset("sound/NS2.fev/marine/common/jetpack_end")
local kJetpackPickupSound = PrecacheAsset("sound/NS2.fev/marine/common/pickup_jetpack")
local kJetpackLoop = PrecacheAsset("sound/NS2.fev/marine/common/jetpack_on")

local kAnimLandSuffix = "_jetpack_land"

if Server then
    Script.Load("lua/JetpackMarine_Server.lua")
elseif Client then
    Script.Load("lua/JetpackMarine_Client.lua")
end

local kJetpackFuelReplenishDelay = .0
local kJetpackMinimumFuelForLaunch = .03
local kVerticalThrustAccelerationMod = 2.1
local kVerticalThrustMaxSpeed = 12.0 // note: changing this impacts kVerticalThrustAccelerationMod
local kJetpackAcceleration = 17.0 // Horizontal acceleration
local kWalkMaxSpeed = 3.5                // Four miles an hour = 6,437 meters/hour = 1.8 meters/second (increase for FPS tastes)
local kRunMaxSpeed = 6.0
local kFlyMaxSpeed = 13.0 // NS1 jetpack is 2.9x running speed (walk: 192, jetpack: 576)
local kJetpackTakeOffTime = .01

local networkVars =
{
    // jetpack fuel is dervived from the three variables jetpacking, timeJetpackingChanged and jetpackFuelOnChange
    // time since change has the kJetpackFuelReplenishDelay subtracted if not jetpacking
    // jpFuel = Clamp(jetpackFuelOnChange + time since change * gain/loss rate, 0, 1)
    // If jetpack is currently active and affecting our movement. If active, use loss rate, if inactive use gain rate
    jetpacking = "boolean",
    // when we last changed state of jetpack
    timeJetpackingChanged = "compensated time",
    // amount of fuel when we last changed jetpacking state
    jetpackFuelOnChange = "float (0 to 1 by 0.01)",
    
    startedFromGround = "boolean",
    
    jetpackFuelRate = "float(0 to 1 by 0.01)",
    
    equipmentId = "entityid",
    jetpackMode = "enum JetpackMarine.kJetpackMode",
    
    jetpackLoopId = "entityid"
}

function JetpackMarine:OnCreate()

    Marine.OnCreate(self)
    
    self.jetpackMode = JetpackMarine.kJetpackMode.Disabled
    
    self.jetpackLoopId = Entity.invalidId
    
end

local function InitEquipment(self)

    assert(Server)
    
    self.jetpackFuelRate = kJetpackUseFuelRate    

    self.jetpackFuelOnChange = 1
    self.timeJetpackingChanged = Shared.GetTime()
    self.jetpacking = false
    
    StartSoundEffectOnEntity(kJetpackPickupSound, self)
    
    self.jetpackLoop = Server.CreateEntity(SoundEffect.kMapName)
    self.jetpackLoop:SetAsset(kJetpackLoop)
    self.jetpackLoop:SetParent(self)
    self.jetpackLoopId = self.jetpackLoop:GetId()
    
    local jetpack = CreateEntity(JetpackOnBack.kMapName, self:GetAttachPointOrigin(Jetpack.kAttachPoint), self:GetTeamNumber())
    jetpack:SetParent(self)
    jetpack:SetAttachPoint(Jetpack.kAttachPoint)
    self.equipmentId = jetpack:GetId()
    
end

function JetpackMarine:OnInitialized()

    // Using the Jetpack is very important. This is
    // a priority before anything else for the JetpackMarine.
    if Client then
        self:AddHelpWidget("GUIMarineJetpackHelp", 2)
    end
    
    Marine.OnInitialized(self)
    
    if Server then
       InitEquipment(self)
    end
    
end

function JetpackMarine:OnDestroy()

    Marine.OnDestroy(self)
    
    self.equipmentId = Entity.invalidId
    self.jetpackLoopId = Entity.invalidId
    if Server then
    
        // The children have already been destroyed.
        self.jetpackLoop = nil
        
    end
    
end

function JetpackMarine:GetHasEquipment()
    return true
end

function JetpackMarine:GetFuel()

    local dt = Shared.GetTime() - self.timeJetpackingChanged
    local rate = -self.jetpackFuelRate
    if not self.jetpacking then
        rate = kJetpackReplenishFuelRate
        dt = math.max(0, dt - kJetpackFuelReplenishDelay)
    end
    return Clamp(self.jetpackFuelOnChange + rate * dt, 0, 1)
    
end

function JetpackMarine:GetJetpack()

    if Server then
    
        -- There is a case where this function is called after the JetpackMarine has been
        -- destroyed but we don't have reproduction steps.
        if not self:GetIsDestroyed() and self.equipmentId == Entity.invalidId then
            InitEquipment(self)
        end
        
        -- Help us track down this problem.
        if self:GetIsDestroyed() then
        
            DebugPrint("Warning - JetpackMarine:GetJetpack() was called after the JetpackMarine was destroyed")
            DebugPrint(Script.CallStack())
            
        end
        
    end
    
    return Shared.GetEntity(self.equipmentId)
    
end

function JetpackMarine:OnEntityChange(oldId, newId)

    if oldId == self.equipmentId and newId then
        self.equipmentId = newId
    end

end

function JetpackMarine:GetSlowOnLand()
    return not self:GetIsJetpacking()
end

function JetpackMarine:ReceivesFallDamage()
    return false
end



function JetpackMarine:HasJetpackDelay()

    if (Shared.GetTime() - self.timeJetpackingChanged > kJetpackFuelReplenishDelay) then
        return false
    end
    
    return true
    
end

function JetpackMarine:GetIsOnGround()

    //if self:GetIsJetpacking() and self.timeJetpackingChanged ~= Shared.GetTime() then
    //    return false
    //end
    
    return Marine.GetIsOnGround(self)
    
end

function JetpackMarine:HandleJetpackStart()

    self.jetpackFuelOnChange = self:GetFuel()
    self.jetpacking = true
    self.timeJetpackingChanged = Shared.GetTime()
    
    self.startedFromGround = self:GetIsOnGround() or self.timeOfLastJump == Shared.GetTime()
    
    local jetpack = self:GetJetpack()    
    if jetpack then
        self:GetJetpack():SetIsFlying(true)
    end
    
    
end

function JetpackMarine:HandleJetPackEnd()

    StartSoundEffectOnEntity(kJetpackEnd, self)
    
    if Server then
        self.jetpackLoop:Stop()
    end
    self.jetpackFuelOnChange = self:GetFuel()
    self.jetpacking = false
    self.timeJetpackingChanged = Shared.GetTime()
    self.jetpacking = false
    
    local animName = self:GetWeaponName() .. kAnimLandSuffix
    
    local jetpack = self:GetJetpack()
    if jetpack then
        self:GetJetpack():SetIsFlying(false)
    end
    
end

// needed for correct fly pose
function JetpackMarine:GetWeaponName()

    local currentWeapon = self:GetActiveWeaponName()
    
    if currentWeapon then
        return string.lower(currentWeapon)
    else
        return nil
    end
    
end

function JetpackMarine:GetJumpMode()
    return kJumpMode.Default
end

function JetpackMarine:GetMaxBackwardSpeedScalar()
    if not self:GetIsOnGround() then
        return 1
    end

    return Marine.GetMaxBackwardSpeedScalar(self)
end

function JetpackMarine:UpdateJetpack(input)

    local jumpPressed = (bit.band(input.commands, Move.Jump) ~= 0)
    
    self:UpdateJetpackMode()
    
    // handle jetpack start, ensure minimum wait time to deal with sound errors
    if not self.jetpacking and (Shared.GetTime() - self.timeJetpackingChanged > 0.02) and jumpPressed and self:GetFuel() >= kJetpackMinimumFuelForLaunch then
    
        self:HandleJetpackStart()
        
        if Server then
            self.jetpackLoop:Start()
        end
        
    end
    
    // handle jetpack stop, ensure minimum flight time to deal with sound errors
    if self.jetpacking and (Shared.GetTime() - self.timeJetpackingChanged) > 0.02 and (self:GetFuel() <= 0.01 or not jumpPressed) then
        self:HandleJetPackEnd()
    end
    
    if Client then
    
        local jetpackLoop = Shared.GetEntity(self.jetpackLoopId)
        if jetpackLoop then
            jetpackLoop:SetParameter("fuel", self:GetFuel(), 1)
        end
        
    end

end

function JetpackMarine:HandleButtons(input)

    Marine.HandleButtons(self, input)
    
    self:UpdateJetpack(input)
    
end

function JetpackMarine:GetCrouchSpeedScalar()

    if self:GetIsJetpacking() then
        return 0
    end
    
    return Player.GetCrouchSpeedScalar(self)
    
end

function JetpackMarine:GetInventorySpeedScalar()
    return 1 - self:GetWeaponsWeight() - kJetpackWeight
end

function JetpackMarine:GoldSrc_GetMaxSpeed(possible)

    if possible then
        return kRunMaxSpeed
    end
    
    if self:GetIsStunned() then
        return 0
    end
    
    local maxSpeed = kRunMaxSpeed
    
    if self.movementModiferState and self:GetIsOnSurface() then
        maxSpeed = kWalkMaxSpeed
    end
    
    if self:GetIsJetpacking() or not self:GetIsOnSurface() then
        maxSpeed = kFlyMaxSpeed
    else
        // Take into account our weapon inventory and current weapon. Assumes a vanilla marine has a scalar of around .8.
        local inventorySpeedScalar = self:GetInventorySpeedScalar()
        maxSpeed = maxSpeed * self:GetCatalystMoveSpeedModifier() * self:GetSlowSpeedModifier() * inventorySpeedScalar 
    end
    
    return maxSpeed
    
end

function JetpackMarine:GetIsTakingOffFromGround()
    return self.startedFromGround and (self.timeJetpackingChanged + kJetpackTakeOffTime > Shared.GetTime())
end

function JetpackMarine:GoldSrc_AirAccelerate(velocity, time, wishdir, wishspeed, acceleration)
    if not self:GetIsJetpacking() and wishspeed > Player.GetMaxAirVeer(self) then
        wishspeed = Player.GetMaxAirVeer(self)
    end
    
    self:GoldSrc_Accelerate(velocity, time, wishdir, wishspeed, acceleration)
end

function JetpackMarine:GoldSrc_Accelerate(velocity, time, wishdir, wishspeed, acceleration)
    Marine.GoldSrc_Accelerate(self, velocity, time, wishdir, wishspeed, acceleration)
    
    // From testing in NS1: There is a hard cap on velocity of the jetpack marine,
    // probably to prevent air-strafing into crazy speeds
    local groundspeed = velocity:GetLengthXZ()
    local maxspeed = kFlyMaxSpeed
    if groundspeed > maxspeed then
        // Keep vertical velocity
        local verticalVelocity = velocity.y
        // Scale it back to maxspeed
        velocity:Scale(maxspeed/groundspeed)
        velocity.y = verticalVelocity
    end
    
    // Add thrust from the jetpack
    if self:GetIsJetpacking() then
        Marine.GoldSrc_Accelerate(self, velocity, time, Vector(0,1,0), kVerticalThrustMaxSpeed, kVerticalThrustAccelerationMod)
        // Since the upwards velocity may be very small, manually set onGround to false
        // to avoid having code from sticking the player to the ground
        self.onGround = false
    end
end

function JetpackMarine:GetJumpVelocity(input, velocity)
    velocity.y = math.sqrt(math.abs(1 * self:GetJumpHeight() * self:GetGravityForce(input)))
end

function JetpackMarine:GoldSrc_GetWishVelocity(input)
    if HasMixin(self, "Stun") and self:GetIsStunned() then
        return Vector(0,0,0)
    end
    
    // goldSrc maxspeed works different than ns2 maxspeed.
    // Here is it used as an acceleration target, in ns2
    // it's seemingly used for clamping the speed
    local maxspeed = self:GoldSrc_GetMaxSpeed()

    // wishdir
    local move = GetNormalizedVector(input.move)
    move:Scale(maxspeed)
    
    // grab view angle (ignoring pitch)
    local angles = self:ConvertToViewAngles(0, input.yaw, 0)
    
    if self:GetIsOnLadder() and not self:GetIsJetpacking() then
        angles = self:ConvertToViewAngles(input.pitch, input.yaw, 0)
    end
    
    local viewCoords = angles:GetCoords() // to matrix?
    local moveVelocity = viewCoords:TransformVector(move) // get world-space move direction
    
    // Scale down velocity if moving backwards
    if input.move.z < 0 then
        moveVelocity:Scale(self:GetMaxBackwardSpeedScalar())
    end
    
    return moveVelocity
end

function JetpackMarine:GoldSrc_GetAcceleration()
    local acceleration = 0

    if self:GetIsJetpacking() then

        acceleration = kJetpackAcceleration * 0.17
        acceleration = acceleration * self:GetInventorySpeedScalar()

    else
        acceleration = Marine.GoldSrc_GetAcceleration(self)
    end
    
    return acceleration
end

function JetpackMarine:GetIsStunAllowed()
    return self:GetIsOnGround()
end

function JetpackMarine:UpdateJetpackMode()

    local newMode = JetpackMarine.kJetpackMode.Disabled

    if self:GetIsJetpacking() then
    
        if ((Shared.GetTime() - self.timeJetpackingChanged) < kJetpackTakeOffTime) and (( Shared.GetTime() - self.timeJetpackingChanged > 1.5 ) or self:GetIsOnGround() ) then

            newMode = JetpackMarine.kJetpackMode.TakeOff

        else

            newMode = JetpackMarine.kJetpackMode.Flying

        end
    end

    if newMode ~= self.jetpackMode then
        self.jetpackMode = newMode
    end

end

function JetpackMarine:GetJetPackMode()

    return self.jetpackMode

end

function JetpackMarine:GetIsJetpacking()
    return self.jetpacking and (self:GetFuel()> 0) and not self:GetIsStunned()
end

/**
 * Since Jetpack is a child of JetpackMarine, we need to manually
 * call ProcessMoveOnModel() on it so animations play properly.
 */
function JetpackMarine:ProcessMoveOnModel(input)

    local jetpack = self:GetJetpack()
    if jetpack then
        jetpack:ProcessMoveOnModel(input)
    end
    
end

function JetpackMarine:OnTag(tagName)

    PROFILE("JetpackMarine:OnTag")

    Marine.OnTag(self, tagName)
    
    if tagName == "fly_start" and self.startedFromGround then
        StartSoundEffectOnEntity(kJetpackStart, self)
    end

end

function JetpackMarine:FallingAfterJetpacking()
    return (self.timeJetpackingChanged + 1.5 > Shared.GetTime()) and not self:GetIsOnGround()
end

function JetpackMarine:OnUpdateAnimationInput(modelMixin)

    Marine.OnUpdateAnimationInput(self, modelMixin)
    
    if self:GetIsJetpacking() or self:FallingAfterJetpacking() then
        modelMixin:SetAnimationInput("move", "jetpack")
    end

end

Shared.LinkClassToMap("JetpackMarine", JetpackMarine.kMapName, networkVars)