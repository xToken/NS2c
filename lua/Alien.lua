// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
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
Script.Load("lua/EmpowerMixin.lua")
Script.Load("lua/RedeployMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/AlienActionFinderMixin.lua")
Script.Load("lua/DetectorMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/BabblerClingMixin.lua")

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

local kEnergyRecuperationRate = 8
local kCustomBlipDuration = 10
local kEnergyAdrenalineRecuperationRate = 16.0

local networkVars = 
{
    // The alien energy used for all alien weapons and abilities (instead of ammo) are calculated
    // from when it last changed with a constant regen added
    timeAbilityEnergyChanged = "time",
    abilityEnergyOnChange = "float (0 to " .. math.ceil(kAbilityMaxEnergy) .. " by 0.05 [] )",
    
    oneHive = "private boolean",
    twoHives = "private boolean",
    threeHives = "private boolean",
    
    crags = string.format("integer (0 to 3)"),
    shifts = string.format("integer (0 to 3)"),
    shades = string.format("integer (0 to 3)"),
	whips = string.format("integer (0 to 3)"),
    movenoise = "private time",
    
    primalScreamBoost = "compensated boolean"
}

AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(EnergizeMixin, networkVars)
AddMixinNetworkVars(EmpowerMixin, networkVars)
AddMixinNetworkVars(RedeployMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(HasUmbraMixin, networkVars)
AddMixinNetworkVars(BabblerClingMixin, networkVars)

function Alien:OnCreate()

    Player.OnCreate(self)
    InitMixin(self, DetectorMixin)
    InitMixin(self, AlienActionFinderMixin)
    InitMixin(self, EnergizeMixin)
    InitMixin(self, EmpowerMixin)
	InitMixin(self, RedeployMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, HasUmbraMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, BabblerClingMixin)
    
    InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })
    
    self.timeLastMomentumEffect = 0
 
    self.timeAbilityEnergyChange = Shared.GetTime()
    self.abilityEnergyOnChange = self:GetMaxEnergy()
    self.lastEnergyRate = self:GetRecuperationRate()
    
    // Only used on the local client.
    self.darkVisionOn = false
    self.darkVisionLastFrame = false
    self.darkVisionTime = 0
    self.darkVisionEndTime = 0
    self.nextredeploy = 0
    self.oneHive = false
    self.twoHives = false
    self.threeHives = false
    self.primalScreamBoost = false
    self.crags = 0
    self.shifts = 0
    self.shades = 0
	self.whips = 0
    self.unassignedhives = 0
    self.redemed = 0
    self.hivesinfo = { }
    
    if Server then
        self.timeWhenPrimalScreamExpires = 0
    elseif Client then
        InitMixin(self, TeamMessageMixin, { kGUIScriptName = "GUIAlienTeamMessage" })
    end
    
end

function Alien:DestroyGUI()

    if Client then
    
        if self.buyMenu then
        
            GetGUIManager():DestroyGUIScript(self.buyMenu)
            MouseTracker_SetIsVisible(false)
            self.buyMenu = nil
            
        end
        
        if self.celerityViewCinematic then
        
            Client.DestroyCinematic(self.celerityViewCinematic)
            self.celerityViewCinematic = nil
            
        end
        
    end
    
end

function Alien:OnDestroy()

    Player.OnDestroy(self)
    
    self.loopingCeleritySound = nil
    
    self:DestroyGUI()
    
end

function Alien:OnInitialized()

    Player.OnInitialized(self)
    
    InitMixin(self, CloakableMixin)

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
                self:ManuallyUpdateNumUpgradeStructures()
            end
            return false
        end
        
        self:AddTimedCallback(UpdateAlienSpecificVariables, 0.1)
        self:AddTimedCallback(Alien.UpdateMoveNoise, math.random(self:GetLowerMoveNoiseTime(), self:GetUpperMoveNoiseTime()))    
    elseif Client then
        InitMixin(self, HiveVisionMixin)
    end
    
    if Client and Client.GetLocalPlayer() == self then
    
        Client.SetPitch(0.0)
        self:AddHelpWidget("GUIAlienVisionHelp", 2)
        
    end

end

function Alien:GetDetectionRange()
    local hasupg, level = GetHasAuraUpgrade(self)
    if hasupg then
        return (((1 / 3) * level) * kAuraDetectionRange)
    end
    return 0
end

function Alien:OnCheckDetectorActive()
    local hasupg, level = GetHasAuraUpgrade(self)
    return hasupg and level > 0
end

function Alien:IsValidDetection(detectable)
    return true
end

function Alien:GetCanRepairOverride(target)
    return false
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

function Alien:GetUpgradeChambers(techId)
    if techId == kTechId.Crag then
        return self.crags
    elseif techId == kTechId.Shift then
        return self.shifts
    elseif techId == kTechId.Shade then
        return self.shades
	elseif techId == kTechId.Whip then
        return self.whips
    else
        return 0
    end
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

    local scalar = 1
    local hasupg, level = GetHasAdrenalineUpgrade(self)
    if hasupg and level > 0 then
        return scalar * (kEnergyAdrenalineRecuperationRate / 3) * level
    else    
        return scalar * kEnergyRecuperationRate
    end
    
end

function Alien:GetMaxEnergy()
    return kAbilityMaxEnergy
end

function Alien:SetDarkVision(state)

    if state ~= self.darkVisionOn then

        if state then
        
            self.darkVisionTime = Shared.GetTime()
            self:TriggerEffects("alien_vision_on") 
            
        else
        
            self.darkVisionEndTime = Shared.GetTime()
            self:TriggerEffects("alien_vision_off")
            
        end
    
    end
    
    self.darkVisionOn = state

end

function Alien:GetLowerMoveNoiseTime()
    return kAlienBaseMoveNoise
end

function Alien:GetUpperMoveNoiseTime()
    return kAlienRandMoveNoise
end

function Alien:ShouldMakeMoveNoises()
    return self:GetIsAlive()
end

function Alien:UpdateMoveNoise()
    if self:ShouldMakeMoveNoises() then
        self:TriggerEffects("alien_move", { randsound = math.random(1, kAlienMoveNoises) })
        self:AddTimedCallback(Alien.UpdateMoveNoise, math.random(self:GetLowerMoveNoiseTime(), self:GetUpperMoveNoiseTime()))
    end
    return false  
end

function Alien:HandleButtons(input)

    PROFILE("Alien:HandleButtons")   
    
    Player.HandleButtons(self, input)

    if Client and self:GetCanControl() and not Shared.GetIsRunningPrediction() then
    
        local darkVisionPressed = bit.band(input.commands, Move.ToggleFlashlight) ~= 0
        if not self.darkVisionLastFrame and darkVisionPressed then
            self:SetDarkVision(not self.darkVisionOn)
        end
        
        self.darkVisionLastFrame = darkVisionPressed

    end
    
end

function Alien:GetIsCamouflaged()
    return GetHasGhostUpgrade(self) and not self:GetIsInCombat()
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

/**
 * Must override.
 */
function Alien:GetArmorFullyUpgradedAmount()
    assert(false)
end

function Alien:GetCanBeHealedOverride()
    return self:GetIsAlive()
end

function Alien:GetDeathMapName()
    return AlienSpectator.kMapName
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

    //Silence Controls volume levels, dont think this actually works tho.
    local upg, level = GetHasSilenceUpgrade(player)
    if level == 3 then
        tableParams[kEffectFilterSilenceUpgrade] = upg
    end
    tableParams[kEffectParamVolume] = (1 - (.33 * level))

end

function Alien:GetIsPrimaled()
    return self.primalScreamBoost
end

function Alien:OnHiveTeleport()
end

function Alien:GetBaseAttackSpeed()
    return 1
end

function Alien:GetAttackSpeedModifiers()
    local as = 1
    if self:GetIsPrimaled() then
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

function Alien:OnUpdateAnimationInput(modelMixin)

    Player.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("attack_speed", self:GetAttackSpeed())
    
end

Shared.LinkClassToMap("Alien", Alien.kMapName, networkVars)