// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Alien.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Moved vars to local and added goldsource movement, removed many outdated functions.

Script.Load("lua/Player.lua")
Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/ScoringMixin.lua")
Script.Load("lua/Alien_Upgrade.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/EnergizeMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/AlienActionFinderMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/BabblerClingMixin.lua")
Script.Load("lua/EmpowerMixin.lua")
Script.Load("lua/PrimalScreamMixin.lua")
Script.Load("lua/RedeployMixin.lua")
Script.Load("lua/RedemptionMixin.lua")
Script.Load("lua/GhostMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/IdleMixin.lua")

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/decals/alien_blood.surface_shader")

if Client then
    Script.Load("lua/TeamMessageMixin.lua")
end

class 'Alien' (Player)

Alien.kMapName = "alien"

if Server then
    Script.Load("lua/Alien_Server.lua")
elseif Client then
    Script.Load("lua/Alien_Client.lua")
end

Shared.PrecacheSurfaceShader("models/alien/alien.surface_shader")

Alien.kNotEnoughResourcesSound = PrecacheAsset("sound/NS2.fev/alien/voiceovers/more")
Alien.kTeleportSound = PrecacheAsset("sound/NS2.fev/alien/structures/generic_spawn_large")
PrecacheAsset("models/alien/infestation/infestation2.model")
PrecacheAsset("cinematics/vfx_materials/vfx_neuron_03.dds")

local networkVars = 
{
    // The alien energy used for all alien weapons and abilities (instead of ammo) are calculated
    // from when it last changed with a constant regen added
    timeAbilityEnergyChanged = "time",
    abilityEnergyOnChange = "float (0 to " .. math.ceil(kAbilityMaxEnergy) .. " by 0.05 [] )",
    
    oneHive = "private boolean",
    twoHives = "private boolean",
    threeHives = "private boolean",
    
	hatched = "private boolean",
    
    darkVisionSpectatorOn = "private boolean"
}

AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(EnergizeMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(BabblerClingMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(EmpowerMixin, networkVars)
AddMixinNetworkVars(PrimalScreamMixin, networkVars)
AddMixinNetworkVars(RedeployMixin, networkVars)
AddMixinNetworkVars(GhostMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)

function Alien:OnCreate()

    Player.OnCreate(self)

    InitMixin(self, EnergizeMixin)
    
    InitMixin(self, CombatMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, AlienActionFinderMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, BabblerClingMixin)
	InitMixin(self, UmbraMixin)
    InitMixin(self, EmpowerMixin)
    InitMixin(self, PrimalScreamMixin)
	InitMixin(self, RedeployMixin)
	InitMixin(self, RedemptionMixin)
	InitMixin(self, GhostMixin)
	
    InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })

    self.timeAbilityEnergyChange = Shared.GetTime()
    self.abilityEnergyOnChange = self:GetMaxEnergy()
    self.lastEnergyRate = self:GetRecuperationRate()
    
    // Only used on the local client.
    self.darkVisionOn = false
    self.lastDarkVisionState = false
    self.darkVisionLastFrame = false
    self.darkVisionTime = 0
    self.darkVisionEndTime = 0
    self.oneHive = false
    self.twoHives = false
    self.threeHives = false
    
    if Server then
        self.timeLastAlienAutoHeal = 0
    elseif Client then
        InitMixin(self, TeamMessageMixin, { kGUIScriptName = "GUIAlienTeamMessage" })
    end
    
end

function Alien:OnJoinTeam()

    self.oneHive = false
    self.twoHives = false
    self.threeHives = false

end

function Alien:OnInitialized()

    Player.OnInitialized(self)
    
    InitMixin(self, CloakableMixin)
    InitMixin(self, IdleMixin)
    self.armor = self:GetArmorAmount()
    self.maxArmor = self.armor
    
    if Server then
  
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        local function UpdateAlienSpecificVariables(self)
            if self:GetTeam().GetActiveHiveCount then
                self:UpdateActiveAbilities(self:GetTeam():GetActiveHiveCount())
                self:UpdateHiveScaledHealthValues()
            end
            return false
        end
        
        self:AddTimedCallback(UpdateAlienSpecificVariables, 0.1)
  
    elseif Client then
    
        InitMixin(self, HiveVisionMixin)
        
        if self:GetIsLocalPlayer() and self.hatched then
            self:TriggerHatchEffects()
        end
        
    end
    
    if Client and Client.GetLocalPlayer() == self then
    
        Client.SetPitch(0.0)
        
    end

end

function Alien:SetHatched()
    self.hatched = true
end

function Alien:GetCanRepairOverride(target)
    return false
end

// player for local player
function Alien:TriggerHatchEffects()
    self.clientTimeTunnelUsed = Shared.GetTime()
end

function Alien:GetArmorAmount()

    local hasupg, level = GetHasCarapaceUpgrade(self)
    if hasupg then
        return self:GetBaseArmor() + (((self:GetArmorFullyUpgradedAmount() - self:GetBaseArmor()) / 3) * level)
    end

    return self:GetBaseArmor()
   
end

function Alien:GetCarapaceFraction()

    local maxCarapaceArmor = self:GetMaxArmor() - self:GetBaseArmor()
    local currentCarpaceArmor = math.max(0, self:GetArmor() - self:GetBaseArmor())
    
    if maxCarapaceArmor == 0 then
        return 0
    end

    return currentCarpaceArmor / maxCarapaceArmor

end

function Alien:GetCarapaceMovementScalar()
    return 1
end

function Alien:GetHasOneHive()
    return self.oneHive
end

function Alien:GetHasTwoHives()
    return self.twoHives
end

function Alien:GetHasThreeHives()
    return self.threeHives
end

function Alien:GetPlayIdleSound()
    return self:GetIsAlive() and self:GetVelocityLength() > kIdleThreshold
end

// For special ability, return an array of totalPower, minimumPower, tex x offset, tex y offset, 
// visibility (boolean), command name
function Alien:GetAbilityInterfaceData()
    return { }
end

local function CalcEnergy(self, rate)
    local dt = Shared.GetTime() - self.timeAbilityEnergyChanged
    local result = Clamp(self.abilityEnergyOnChange + dt * rate, 0, self:GetMaxEnergy())
    return result
end

function Alien:GetEnergy()
    local rate = self:GetRecuperationRate()
    if self.lastEnergyRate ~= rate then
        // we assume we ask for energy enough times that the change in energy rate
        // will hit on the same tick they occure (or close enough)
        self.abilityEnergyOnChange = CalcEnergy(self, self.lastEnergyRate)
        self.timeAbilityEnergyChange = Shared.GetTime()
    end
    self.lastEnergyRate = rate
    return CalcEnergy(self, rate)
end

function Alien:AddEnergy(energy)
    assert(energy >= 0)
    self.abilityEnergyOnChange = Clamp(self:GetEnergy() + energy, 0, self:GetMaxEnergy())
    self.timeAbilityEnergyChanged = Shared.GetTime()
end

function Alien:SetEnergy(energy)
    self.abilityEnergyOnChange = Clamp(energy, 0, self:GetMaxEnergy())
    self.timeAbilityEnergyChanged = Shared.GetTime()
end

function Alien:DeductAbilityEnergy(energyCost)

    if not self:GetDarwinMode() then
    
        local maxEnergy = self:GetMaxEnergy()
    
        self.abilityEnergyOnChange = Clamp(self:GetEnergy() - energyCost, 0, maxEnergy)
        self.timeAbilityEnergyChanged = Shared.GetTime()
        
    end
    
end

function Alien:GetRecuperationRate()

    local hasupg, level = GetHasAdrenalineUpgrade(self)
    if hasupg and level > 0 then
        return kEnergyRecuperationRate + ((kEnergyAdrenalineRecuperationRate / 3) * level)
    else    
        return kEnergyRecuperationRate
    end
    
end

function Alien:GetMaxEnergy()
    return kAbilityMaxEnergy
end

function Alien:SetDarkVision(state)
    self.darkVisionOn = state
    self.darkVisionSpectatorOn = state
end

function Alien:HandleButtons(input)

    PROFILE("Alien:HandleButtons")   
    
    Player.HandleButtons(self, input)

    if self:GetCanControl() and (Client or Server) then
    
        local darkVisionPressed = bit.band(input.commands, Move.ToggleFlashlight) ~= 0
        if not self.darkVisionLastFrame and darkVisionPressed then
            self:SetDarkVision(not self.darkVisionOn)
        end
        
        self.darkVisionLastFrame = darkVisionPressed

    end
    
end

local function GetIsUnderShade(self)
    local shady = false
    for _, shade in ipairs( GetEntitiesForTeamWithinRange("Shade", self:GetTeamNumber(), self:GetOrigin(), Shade.kCloakRadius) ) do
        if shade:GetIsBuilt() and shade:GetIsAlive() then
            shady = true
            break
        end
    end
    return shady
end

function Alien:GetIsCamouflaged()
    //return GetHasGhostUpgrade(self) and not self:GetIsInCombat() and not GetIsUnderShade(self)
    return false
end

function Alien:GetNotEnoughResourcesSound()
    return kNotEnoughResourcesSound
end

// Returns true when players are selecting new abilities. When true, draw small icons
// next to your current weapon and force all abilities to draw.
function Alien:GetInactiveVisible()
    return Shared.GetTime() < self:GetTimeOfLastWeaponSwitch() + kDisplayWeaponTime
end

/**
 * Must override.
 */
function Alien:GetBaseArmor()
    assert(false)
end

function Alien:GetBaseHealth()
    assert(false)
end

/**
 * Must override.
 */
function Alien:GetArmorFullyUpgradedAmount()
    assert(false)
end

function Alien:GetHiveHealthScalar(numHives)
    if numHives <= 1 then
        return kAlienHealthPerArmorHive1
    elseif numHives == 2 then
        return kAlienHealthPerArmorHive2
    elseif numHives == 3 then
        return kAlienHealthPerArmorHive3
    elseif numHives >= 4 then
        return kAlienHealthPerArmorHive4
    end
end

function Alien:GetCanBeHealedOverride()
    return self:GetIsAlive()
end

function Alien:GetDeathMapName()
    return AlienSpectator.kMapName
end

function Alien:UpdateHealthAmount()
    return
end

// Returns the name of the player's lifeform
function Alien:GetPlayerStatusDesc()

    local status = kPlayerStatus.Void
    
    if (self:GetIsAlive() == false) then
        status = kPlayerStatus.Dead
    else
        if (self:isa("Embryo")) then
            status = kPlayerStatus.Embryo
        else
            status = kPlayerStatus[self:GetClassName()]
        end
    end
    
    return status

end

function Alien:OnCatalyst()
end

function Alien:OnCatalystEnd()
end

function Alien:GetCeleritySpeedModifier()
    return kCeleritySpeedModifier
end

function Alien:GetCelerityScalar()
    local hasupg, level = GetHasCelerityUpgrade(self)
    if hasupg then
        return ((self:GetCeleritySpeedModifier() / 3) * level)
    end
    return 0
end

function Alien:GetMovementSpeedModifier()
    return self:GetCelerityScalar()
end

function Alien:GetEffectParams(tableParams)
    if tableParams[kEffectFilterSilenceUpgrade] == nil then
        local hasupg, level = GetHasSilenceUpgrade(self)
        if hasupg then
            if level == 3 then
                tableParams[kEffectFilterSilenceUpgrade] = true
            end
            tableParams[kEffectParamVolume] = 1 - Clamp(level / 3, 0, 1)
        end
    end
end

function Alien:OnHiveTeleport()
end

function Alien:GetBaseAttackSpeed()
    return 1
end

function Alien:GetAttackSpeedModifiers()
    local as = 1
    if self:GetHasPrimalScream() then
        as = as + kPrimalScreamROFIncrease
    end
    if self:GetIsEmpowered() then
        as = as + kEmpoweredROFIncrease
    end
    return as
end

function Alien:GetAttackSpeed()
    return self:GetBaseAttackSpeed() * self:GetAttackSpeedModifiers()
end

function Alien:GetHasMovementSpecial()
    return false
end

function Alien:OnUpdateAnimationInput(modelMixin)

    Player.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("attack_speed", self:GetAttackSpeed())
    
end

Shared.LinkClassToMap("Alien", Alien.kMapName, networkVars, true)
