//
// lua\HeavyArmorMarine.lua

Script.Load("lua/Marine.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/MarineActionFinderMixin.lua")
Script.Load("lua/OrderSelfMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/ScoringMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/DisorientableMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/ParasiteMixin.lua")

if Client then
    Script.Load("lua/TeamMessageMixin.lua")
end

class 'HeavyArmorMarine' (Marine)

HeavyArmorMarine.kMapName = "heavyarmormarine"

if Server then
    Script.Load("lua/HeavyArmorMarine_Server.lua")
else
    Script.Load("lua/HeavyArmorMarine_Client.lua")
end

Shared.PrecacheSurfaceShader("models/marine/marine.surface_shader")
Shared.PrecacheSurfaceShader("models/marine/marine_noemissive.surface_shader")

HeavyArmorMarine.kModelName = PrecacheAsset("models/marine/male/male_special.model")
HeavyArmorMarine.kMarineAnimationGraph = PrecacheAsset("models/marine/male/male.animation_graph")

HeavyArmorMarine.kDieSoundName = PrecacheAsset("sound/NS2.fev/marine/common/death")
HeavyArmorMarine.kFlashlightSoundName = PrecacheAsset("sound/NS2.fev/common/light")
HeavyArmorMarine.kGunPickupSound = PrecacheAsset("sound/NS2.fev/marine/common/pickup_gun")
HeavyArmorMarine.kSpendResourcesSoundName = PrecacheAsset("sound/NS2.fev/marine/common/player_spend_nanites")
HeavyArmorMarine.kChatSound = PrecacheAsset("sound/NS2.fev/marine/common/chat")
HeavyArmorMarine.kSoldierLostAlertSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/soldier_lost")

HeavyArmorMarine.kFlinchEffect = PrecacheAsset("cinematics/marine/hit.cinematic")
HeavyArmorMarine.kFlinchBigEffect = PrecacheAsset("cinematics/marine/hit_big.cinematic")

HeavyArmorMarine.kEffectNode = "fxnode_playereffect"
HeavyArmorMarine.kHealth = kHeavyArmorHealth
HeavyArmorMarine.kBaseArmor = kHeavyArmorArmor
HeavyArmorMarine.kArmorPerUpgradeLevel = kHeavyArmorPerUpgradeLevel
// Player phase delay - players can only teleport this often
HeavyArmorMarine.kPlayerPhaseDelay = 2
HeavyArmorMarine.kStunDuration = 2
HeavyArmorMarine.kMass = 200
HeavyArmorMarine.kAcceleration = 45
HeavyArmorMarine.kAirAcceleration = 17
HeavyArmorMarine.kAirStrafeWeight = 4
HeavyArmorMarine.kWalkMaxSpeed = 3.75
HeavyArmorMarine.kRunMaxSpeed = 8
// How fast does our armor get repaired by welders
HeavyArmorMarine.kArmorWeldRate = 25
HeavyArmorMarine.kWeldedEffectsInterval = .5
HeavyArmorMarine.kWalkBackwardSpeedScalar = 0.4

// tracked per techId
HeavyArmorMarine.kMarineAlertTimeout = 4

local kDropWeaponTimeLimit = 1
local kPickupWeaponTimeLimit = 1

function HeavyArmorMarine:OnCreate()

    Marine.OnCreate(self)
    
end

function HeavyArmorMarine:OnInitialized()

    Marine.OnInitialized(self)
    self:SetModel(HeavyArmorMarine.kModelName, HeavyArmorMarine.kMarineAnimationGraph)   
    
end

function HeavyArmorMarine:GetCanRepairOverride(target)
    return self:GetWeapon(Welder.kMapName) and HasMixin(target, "Weldable") and ( (target:isa("Marine") and target:GetArmor() < target:GetMaxArmor()) or (not target:isa("Marine") and target:GetHealthScalar() < 0.9) )
end

function HeavyArmorMarine:GetArmorAmount()

    local armorLevels = 0
    
    if(GetHasTech(self, kTechId.Armor3, true)) then
        armorLevels = 3
    elseif(GetHasTech(self, kTechId.Armor2, true)) then
        armorLevels = 2
    elseif(GetHasTech(self, kTechId.Armor1, true)) then
        armorLevels = 1
    end
    
    return HeavyArmorMarine.kBaseArmor + armorLevels * HeavyArmorMarine.kArmorPerUpgradeLevel
    
end

function HeavyArmorMarine:GetGroundFrictionForce()
    return Marine.GetGroundFrictionForce(self)
end

function HeavyArmorMarine:GetInventorySpeedScalar()
    return 1 - (self:GetWeaponsWeight() / kHeavyArmorWeightAssist)
end

function HeavyArmorMarine:GetCrouchSpeedScalar()
    return Marine.GetCrouchSpeedScalar(self)
end

function HeavyArmorMarine:GetMaxSpeed(possible)

    if possible then
        return HeavyArmorMarine.kRunMaxSpeed
    end
    
    if self:GetIsDisrupted() then
        return 0
    end
    
    //Walking
    local maxSpeed = ConditionalValue(self.movementModiferState and self:GetIsOnSurface(), HeavyArmorMarine.kWalkMaxSpeed,  HeavyArmorMarine.kRunMaxSpeed)
    
    // Take into account our weapon inventory and current weapon. Assumes a vanilla marine has a scalar of around .8.
    local inventorySpeedScalar = self:GetInventorySpeedScalar()

    // Take into account crouching
    if not self:GetIsJumping() then
        maxSpeed = ( 1 - self:GetCrouchAmount() * self:GetCrouchSpeedScalar() ) * maxSpeed
    end

    local adjustedMaxSpeed = maxSpeed * self:GetCatalystMoveSpeedModifier() * self:GetSlowSpeedModifier() * inventorySpeedScalar 
    //Print("Adjusted max speed => %.2f (without inventory: %.2f)", adjustedMaxSpeed, adjustedMaxSpeed / inventorySpeedScalar )
    return adjustedMaxSpeed
    
end

function HeavyArmorMarine:GetFootstepSpeedScalar()
    return Clamp(self:GetVelocity():GetLength() / (self:GetMaxSpeed() * self:GetCatalystMoveSpeedModifier() * self:GetSlowSpeedModifier()), 0, 1)
end

// Maximum speed a player can move backwards
function HeavyArmorMarine:GetMaxBackwardSpeedScalar()
    return HeavyArmorMarine.kWalkBackwardSpeedScalar
end

function HeavyArmorMarine:GetAirFrictionForce()
    return 0.08 + 2 * self.slowAmount
end

function HeavyArmorMarine:GetCanBeWeldedOverride()
    return self:GetArmor() < self:GetMaxArmor(), false
end

function HeavyArmorMarine:GetWeldPercentageOverride()
    return self:GetArmor() / self:GetMaxArmor()
end

function HeavyArmorMarine:OnWeldOverride(doer, elapsedTime)

    if self:GetArmor() < self:GetMaxArmor() then
        local addArmor = HeavyArmorMarine.kArmorWeldRate * elapsedTime
        self:SetArmor(self:GetArmor() + addArmor)
    end
    
end

function HeavyArmorMarine:GetCanChangeViewAngles()
    return true
end    

function HeavyArmorMarine:GetMass()
    return HeavyArmorMarine.kMass
end

function HeavyArmorMarine:GetAcceleration()
    local acceleration = HeavyArmorMarine.kAcceleration
    if not self:GetIsOnGround() then
        acceleration = HeavyArmorMarine.kAirAcceleration
    end
    acceleration = acceleration * self:GetSlowSpeedModifier() * self:GetInventorySpeedScalar()

    return acceleration * self:GetCatalystMoveSpeedModifier()
end

function HeavyArmorMarine:OnUpdateAnimationInput(modelMixin)

    PROFILE("HeavyArmorMarine:OnUpdateAnimationInput")
    Marine.OnUpdateAnimationInput(self, modelMixin)
    modelMixin:SetAnimationInput("attack_speed", self:GetCatalystFireModifier())
    
end

function HeavyArmorMarine:GetHasCatpackBoost()
    return self.catpackboost
end

Shared.LinkClassToMap("HeavyArmorMarine", HeavyArmorMarine.kMapName, { })