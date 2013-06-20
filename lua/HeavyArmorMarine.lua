//
// lua\HeavyArmorMarine.lua

Script.Load("lua/Marine.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/MarineActionFinderMixin.lua")
Script.Load("lua/OrderSelfMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/ScoringMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/SelectableMixin.lua")

if Client then
    Script.Load("lua/TeamMessageMixin.lua")
end

class 'HeavyArmorMarine' (Marine)

HeavyArmorMarine.kMapName = "heavyarmormarine"

if Server then
    Script.Load("lua/HeavyArmorMarine_Server.lua")
end

Shared.PrecacheSurfaceShader("models/marine/marine.surface_shader")
Shared.PrecacheSurfaceShader("models/marine/marine_noemissive.surface_shader")

HeavyArmorMarine.kModelName = PrecacheAsset("models/marine/heavyarmor/heavyarmor.model")
local kHeavyArmorMarineAnimationGraph = PrecacheAsset("models/marine/male/male.animation_graph")

local kMass = 200

function HeavyArmorMarine:OnCreate()
    Marine.OnCreate(self)
end

function HeavyArmorMarine:OnInitialized()

    Marine.OnInitialized(self)
    self:SetModel(HeavyArmorMarine.kModelName, kHeavyArmorMarineAnimationGraph)   
    
end

function HeavyArmorMarine:MakeSpecialEdition()
    self:SetModel(HeavyArmorMarine.kModelName, kHeavyArmorMarineAnimationGraph)
end

function HeavyArmorMarine:MakeDeluxeEdition()
    self:SetModel(HeavyArmorMarine.kModelName, kHeavyArmorMarineAnimationGraph)
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
    
    return kHeavyArmorArmor + armorLevels * kHeavyArmorPerUpgradeLevel
    
end

function HeavyArmorMarine:GetInventorySpeedScalar()
    return 1 - self:GetWeaponsWeight() - kHeavyArmorWeight
end

function HeavyArmorMarine:GetFootstepSpeedScalar()
    return Clamp(self:GetVelocity():GetLength() / (self:GetMaxSpeed() * self:GetSlowSpeedModifier() * self:GetCatalystMoveSpeedModifier()), 0, 1)
end

function HeavyArmorMarine:GetCanBeWeldedOverride()
    return self:GetArmor() < self:GetMaxArmor(), false
end

function HeavyArmorMarine:GetWeldPercentageOverride()
    return self:GetArmor() / self:GetMaxArmor()
end

function HeavyArmorMarine:GetMass()
    return kMass
end

Shared.LinkClassToMap("HeavyArmorMarine", HeavyArmorMarine.kMapName, { })