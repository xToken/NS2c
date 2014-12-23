// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Marine.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Changes for movement code overhaul, removal of effects

Script.Load("lua/Player.lua")
Script.Load("lua/OrderSelfMixin.lua")
Script.Load("lua/MarineActionFinderMixin.lua")
Script.Load("lua/StunMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/ScoringMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/ParasiteMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/WebableMixin.lua")
Script.Load("lua/DevouredMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/Weapons/PredictedProjectile.lua")
Script.Load("lua/MarineVariantMixin.lua")
Script.Load("lua/MarineOutlineMixin.lua")

if Client then
    Script.Load("lua/TeamMessageMixin.lua")
end

class 'Marine' (Player)

Marine.kMapName = "marine"

if Server then
    Script.Load("lua/Marine_Server.lua")
elseif Client then
    Script.Load("lua/Marine_Client.lua")
end

PrecacheAsset("models/marine/marine.surface_shader")
PrecacheAsset("models/marine/marine_noemissive.surface_shader")


Marine.kGunPickupSound = PrecacheAsset("sound/ns2c.fev/ns2c/marine/weapon/pickup")
Marine.kMarineAnimationGraph = PrecacheAsset("models/marine/male/male.animation_graph")

-- Generate 3rd person models.
Marine.kModelNames = { male = { }, female = { } }
local kModelTemplates = { green = ".model", special = "_special.model", deluxe = "_special_v1.model" }
for name, suffix in pairs(kModelTemplates) do
    Marine.kModelNames.male[name] = PrecacheAsset("models/marine/male/male" .. suffix)
end
for name, suffix in pairs(kModelTemplates) do
    Marine.kModelNames.female[name] = PrecacheAsset("models/marine/female/female" .. suffix)
end

local kFlashlightSoundName = PrecacheAsset("sound/NS2.fev/common/light")

local kWalkMaxSpeed = 2.2
local kCrouchMaxSpeed = 1.6
local kRunMaxSpeed = 5.2
local kMaxWebbedMoveSpeed = 0.5
local kArmorWeldRate = 25
local kWalkBackwardSpeedScalar = 0.4

PrecacheAsset("models/marine/rifle/rifle_shell_01.dds")
PrecacheAsset("models/marine/rifle/rifle_shell_01_normal.dds")
PrecacheAsset("models/marine/rifle/rifle_shell_01_spec.dds")
PrecacheAsset("models/marine/rifle/rifle_view_shell.model")
PrecacheAsset("models/marine/rifle/rifle_shell.model")
PrecacheAsset("models/marine/arms_lab/arms_lab_holo.model")
PrecacheAsset("models/effects/frag_metal_01.model")
PrecacheAsset("cinematics/vfx_materials/vfx_circuit_01.dds")
PrecacheAsset("materials/effects/nanoclone.dds")
PrecacheAsset("cinematics/vfx_materials/bugs.dds")
PrecacheAsset("cinematics/vfx_materials/refract_water_01_normal.dds")

local networkVars =
{      
    flashlightOn = "boolean",
    
    timeOfLastDrop = "private time",
    timeOfLastPickUpWeapon = "private time",
    
    flashlightLastFrame = "private boolean",
    catpackboost = "boolean",
    
    unitStatusPercentage = "private integer (0 to 100)"
}

AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(StunMixin, networkVars)
AddMixinNetworkVars(OrderSelfMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)
AddMixinNetworkVars(WebableMixin, networkVars)
AddMixinNetworkVars(DevouredMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(MarineVariantMixin, networkVars)

function Marine:OnCreate()

    InitMixin(self, CameraHolderMixin, { kFov = kDefaultFov })
    InitMixin(self, MarineActionFinderMixin)
    InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })
    InitMixin(self, CombatMixin)
    InitMixin(self, SelectableMixin)
    
    Player.OnCreate(self)
    
    InitMixin(self, DissolveMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, ParasiteMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, WebableMixin)
    InitMixin(self, DevouredMixin)
	InitMixin(self, DetectableMixin)
	InitMixin(self, MarineVariantMixin)
	InitMixin(self, PredictedProjectileShooterMixin)
    if Server then

        self.unitStatusPercentage = 0
        self.timeLastUnitPercentageUpdate = 0
        
    elseif Client then
    
        self.flashlight = Client.CreateRenderLight()
        
        self.flashlight:SetType( RenderLight.Type_Spot )
        self.flashlight:SetColor( Color(.8, .8, 1) )
        self.flashlight:SetInnerCone( math.rad(30) )
        self.flashlight:SetOuterCone( math.rad(35) )
        self.flashlight:SetIntensity(10)
        self.flashlight:SetRadius(25)
        self.flashlight:SetGoboTexture("models/marine/male/flashlight.dds")
        
        self.flashlight:SetIsVisible(false)
        
        InitMixin(self, TeamMessageMixin, { kGUIScriptName = "GUIMarineTeamMessage" })

    end

end

function Marine:OnInitialized()

    // work around to prevent the spin effect at the infantry portal spawned from
    // local player should not see the holo marine model
    if Client and Client.GetIsControllingPlayer() then
    
        local ips = GetEntitiesForTeamWithinRange("InfantryPortal", self:GetTeamNumber(), self:GetOrigin(), 1)
        if #ips > 0 then
            Shared.SortEntitiesByDistance(self:GetOrigin(), ips)
            ips[1]:PreventSpinEffect(0.2)
        end
        
    end
    
    // These mixins must be called before SetModel because SetModel eventually
    // calls into OnUpdatePoseParameters() which calls into these mixins.
    // Yay for convoluted class hierarchies!!!
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kPlayerMoveOrderCompleteDistance })
    InitMixin(self, OrderSelfMixin, { kPriorityAttackTargets = { "Harvester" } })
    InitMixin(self, StunMixin)
    InitMixin(self, WeldableMixin)
    
    // SetModel must be called before Player.OnInitialized is called so the attach points in
    // the Marine are valid to attach weapons to. This is far too subtle...
    self:SetModel(self:GetVariantModel(), MarineVariantMixin.kMarineAnimationGraph)
    
    Player.OnInitialized(self)
    
    // Calculate max and starting armor differently
    self.armor = 0
    
    if Server then
    
        self.armor = self:GetArmorAmount()
        self.maxArmor = self.armor
        
        // This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
       
    elseif Client then
    
        InitMixin(self, HiveVisionMixin)
        InitMixin(self, MarineOutlineMixin)
        
        self:AddHelpWidget("GUIMarineHealthRequestHelp", 2)
        self:AddHelpWidget("GUIMarineFlashlightHelp", 2)
        self:AddHelpWidget("GUIMarineWeldHelp", 2)
        self:AddHelpWidget("GUIMapHelp", 1)
        
        self.notifications = { }
        
    end
    
    self.weaponDropTime = 0
    
    local viewAngles = self:GetViewAngles()
    self.lastYaw = viewAngles.yaw
    self.lastPitch = viewAngles.pitch
    
    // -1 = leftmost, +1 = right-most
    self.horizontalSwing = 0
    // -1 = up, +1 = down
    
    self.timeOfLastDrop = 0
    self.timeOfLastPickUpWeapon = 0
    self.catpackboost = false
    self.timeCatpackboost = 0
    
    self.flashlightLastFrame = false
    
end

function Marine:GetJumpMode()
    return kJumpMode.Queued
end

function Marine:GetArmorLevel()

    local armorLevel = 0
    local techTree = GetTechTree(self:GetTeamNumber())

    if techTree and self:GetGameMode() == kGameMode.Classic then
    
        local armor3Node = techTree:GetTechNode(kTechId.Armor3)
        local armor2Node = techTree:GetTechNode(kTechId.Armor2)
        local armor1Node = techTree:GetTechNode(kTechId.Armor1)
    
        if armor3Node and armor3Node:GetResearched() then
            armorLevel = 3
        elseif armor2Node and armor2Node:GetResearched()  then
            armorLevel = 2
        elseif armor1Node and armor1Node:GetResearched()  then
            armorLevel = 1
        end
        
    elseif self:GetGameMode() == kGameMode.Combat then
    
        if self:GetHasUpgrade(kTechId.Armor3) then
            armorLevel = 3
        elseif self:GetHasUpgrade(kTechId.Armor2) then
            armorLevel = 2
        elseif self:GetHasUpgrade(kTechId.Armor1) then
            armorLevel = 1
        end
        
    end

    return armorLevel

end

function Marine:GetWeaponLevel()

    local weaponLevel = 0
    local techTree = GetTechTree(self:GetTeamNumber())

    if techTree and self:GetGameMode() == kGameMode.Classic then
        
            local weapon3Node = techTree:GetTechNode(kTechId.Weapons3)
            local weapon2Node = techTree:GetTechNode(kTechId.Weapons2)
            local weapon1Node = techTree:GetTechNode(kTechId.Weapons1)
        
            if weapon3Node and weapon3Node:GetResearched() then
                weaponLevel = 3
            elseif weapon2Node and weapon2Node:GetResearched()  then
                weaponLevel = 2
            elseif weapon1Node and weapon1Node:GetResearched()  then
                weaponLevel = 1
            end
            
    elseif self:GetGameMode() == kGameMode.Combat then
    
        if self:GetHasUpgrade(kTechId.Weapons3) then
            weaponLevel = 3
        elseif self:GetHasUpgrade(kTechId.Weapons2) then
            weaponLevel = 2
        elseif self:GetHasUpgrade(kTechId.Weapons1) then
            weaponLevel = 1
        end
     
    end

    return weaponLevel

end

function Marine:GetIsStunAllowed()
    return not self:GetIsJumping()
end

function Marine:GetCanJump()
    return Player.GetCanJump(self) and not self:GetIsStunned()
end

function Marine:GetDeflectMove()
    return true
end

function Marine:GetCanRepairOverride(target)
    return self:GetWeapon(Welder.kMapName) and HasMixin(target, "Weldable") and ( (target:isa("Marine") and target:GetArmor() < target:GetMaxArmor()) or (not target:isa("Marine") and target:GetHealthScalar() < 0.9) )
end

function Marine:GetCanSeeDamagedIcon(ofEntity)
    return HasMixin(ofEntity, "Weldable")
end

function Marine:GetSlowOnLand(impactForce)
    return math.abs(impactForce) > self:GetMaxSpeed()
end

function Marine:GetControllerPhysicsGroup()
    return PhysicsGroup.BigPlayerControllersGroup
end

// Required by ControllerMixin.
function Marine:GetMovePhysicsMask()
    if self:GetIsStateFrozen() then
        return PhysicsMask.All
    end
    return Player.GetMovePhysicsMask(self)
end

function Marine:GetHasCollisionDetection()
    return not self:GetIsStateFrozen()
end

function Marine:GetShowSensorBlip()
    return not self:GetIsStateFrozen()
end

function Marine:GetArmorAmount(armorLevels)

    if not armorLevels then
        armorLevels = self:GetArmorLevel()
    end
    
    return kMarineArmor + armorLevels * kArmorPerUpgradeLevel
    
end

function Marine:OnDestroy()

    Player.OnDestroy(self)
    
    if Client then
        
        if self.flashlight ~= nil then
            Client.DestroyRenderLight(self.flashlight)
        end

    end
    
end

function Marine:GetCanControl()
    return (not self.isMoveBlocked) and self:GetIsAlive() and not self:GetIsStateFrozen() and not self.countingDown
end

function Marine:GetPhysicsModelAllowedOverride()
    return not self:GetIsDevoured()
end

function Marine:HandleButtons(input)

    PROFILE("Marine:HandleButtons")
    
    Player.HandleButtons(self, input)
    
    if self:GetCanControl() then
    
        local flashlightPressed = bit.band(input.commands, Move.ToggleFlashlight) ~= 0
        if not self.flashlightLastFrame and flashlightPressed then
        
            self:SetFlashlightOn(not self:GetFlashlightOn())
            StartSoundEffectOnEntity(kFlashlightSoundName, self, 1, self)
            
        end
        self.flashlightLastFrame = flashlightPressed
        
        if bit.band(input.commands, Move.Drop) ~= 0 then
        
            if Server then
            
                // First check for a nearby weapon to pickup.
                local nearbyDroppedWeapon = self:GetNearbyPickupableWeapon()
                if nearbyDroppedWeapon then
                
                    if Shared.GetTime() > self.timeOfLastPickUpWeapon + kPickupWeaponTimeLimit then
                    
                        if nearbyDroppedWeapon.GetReplacementWeaponMapName then
                        
                            local replacement = nearbyDroppedWeapon:GetReplacementWeaponMapName()
                            local toReplace = self:GetWeapon(replacement)
                            if toReplace then
                            
                                self:RemoveWeapon(toReplace)
                                DestroyEntity(toReplace)
                                
                            end
                            
                        end
                        
                        self:AddWeapon(nearbyDroppedWeapon, true)
		                StartSoundEffectAtOrigin(Marine.kGunPickupSound, self:GetOrigin())
                        self.timeOfLastPickUpWeapon = Shared.GetTime()
                        
                    end
                    
                else
                
                    // No nearby weapon, drop our current weapon.
                    self:Drop()
                    
                end
                
            end
            
        end
        
    end
    
end

function Marine:SetFlashlightOn(state)
    self.flashlightOn = state
end

function Marine:GetFlashlightOn()
    return self.flashlightOn
end

function Marine:GetInventorySpeedScalar()
    return 1 - self:GetWeaponsWeight()
end

function Marine:GetMaxSpeed(possible)

    if possible then
        return kRunMaxSpeed * self:GetInventorySpeedScalar()
    end
    
    if self:GetIsStunned() or self:GetIsStateFrozen() then
        return 0
    end
    
    if self:GetIsWebbed() then
        return kMaxWebbedMoveSpeed
    end
    
    //Walking
    local maxSpeed = kRunMaxSpeed
    
    if self.movementModiferState and self:GetIsOnGround() then
        maxSpeed = kWalkMaxSpeed
    end
    
    if self:GetCrouching() and self:GetCrouchAmount() == 1 and self:GetIsOnGround() and not self:GetLandedRecently() then
        maxSpeed = kCrouchMaxSpeed
    end

    // Take into account our weapon inventory and current weapon. Assumes a vanilla marine has a scalar of around .8.
    local useModifier = self.isUsing and 0.5 or 1
    local adjustedMaxSpeed = maxSpeed * self:GetCatalystMoveSpeedModifier() * self:GetSlowSpeedModifier() * self:GetInventorySpeedScalar() * useModifier
    //Print("Adjusted max speed => %.2f (without inventory: %.2f)", adjustedMaxSpeed, adjustedMaxSpeed / inventorySpeedScalar )
    
    return adjustedMaxSpeed
end

function Marine:GetAcceleration(OnGround)
    return Player.GetAcceleration(self, OnGround) * self:GetSlowSpeedModifier()
end

function Marine:GetFootstepSpeedScalar()
    return Clamp(self:GetVelocityLength() / (self:GetMaxSpeed(true) * self:GetCatalystMoveSpeedModifier() * self:GetSlowSpeedModifier()), 0, 1)
end

// Maximum speed a player can move backwards
function Marine:GetMaxBackwardSpeedScalar()
    return kWalkBackwardSpeedScalar
end

function Marine:GetCanBeWeldedOverride()
    return self:GetArmor() < self:GetMaxArmor(), false
end

// Returns -1 to 1
function Marine:GetWeaponSwing()
    return self.horizontalSwing
end

function Marine:GetWeaponDropTime()
    return self.weaponDropTime
end

local marineTechButtons = { kTechId.Attack, kTechId.Move, kTechId.Defend, kTechId.Construct }
function Marine:GetTechButtons(techId)

    local techButtons = nil
    
    if techId == kTechId.RootMenu then
        techButtons = marineTechButtons
    end
    
    return techButtons
 
end

function Marine:GetCatalystFireModifier()
    local weapon = self:GetActiveWeapon()
    local baserof = 1
    if weapon ~= nil then
        baserof = weapon:GetBaseRateofFire()
    end
    return ConditionalValue(self:GetHasCatpackBoost(), kCatPackFireRateScalar * baserof, baserof)
end

function Marine:GetCatalystMoveSpeedModifier()
    return ConditionalValue(self:GetHasCatpackBoost(), kCatPackMoveSpeedScalar, 1)
end

function Marine:GetDeathMapName()
    return MarineSpectator.kMapName
end

// Returns the name of the primary weapon
function Marine:GetPlayerStatusDesc()

    local status = kPlayerStatus.Void
    
    if (self:GetIsAlive() == false) then
        return kPlayerStatus.Dead
    end
    
    local weapon = self:GetWeaponInHUDSlot(1)
    if (weapon) then
        if (weapon:isa("GrenadeLauncher")) then
            return kPlayerStatus.GrenadeLauncher
        elseif (weapon:isa("Rifle")) then
            return kPlayerStatus.Rifle
        elseif (weapon:isa("Shotgun")) then
            return kPlayerStatus.Shotgun
        elseif (weapon:isa("HeavyMachineGun")) then
            return kPlayerStatus.HeavyMachineGun
        end
    end
    
    return status
end

function Marine:GetCanDropWeapon(weapon, ignoreDropTimeLimit)

    if not weapon then
        weapon = self:GetActiveWeapon()
    end
    
    if weapon ~= nil and weapon.GetIsDroppable and weapon:GetIsDroppable() and self:GetGameMode() == kGameMode.Classic then
    
        // Don't drop weapons too fast.
        if ignoreDropTimeLimit or (Shared.GetTime() > (self.timeOfLastDrop + kDropWeaponTimeLimit)) then
            return true
        end
        
    end
    
    return false
    
end

// Do basic prediction of the weapon drop on the client so that any client
// effects for the weapon can be dealt with.
function Marine:Drop(weapon, ignoreDropTimeLimit, ignoreReplacementWeapon)

    local activeWeapon = self:GetActiveWeapon()
    
    if not weapon then
        weapon = activeWeapon
    end
    
    if self:GetCanDropWeapon(weapon, ignoreDropTimeLimit) then
    
        if weapon == activeWeapon then
            self:SelectNextWeapon()
        end
        
        weapon:OnPrimaryAttackEnd(self)
        
        if Server then
        
            self:RemoveWeapon(weapon)
            
            local weaponSpawnCoords = self:GetAttachPointCoords(Weapon.kHumanAttachPoint)
            if weaponSpawnCoords == nil then weaponSpawnCoords = self:GetCoords() end
            weapon:SetCoords(weaponSpawnCoords)
            
        end
        
        // Tell weapon not to be picked up again for a bit
        weapon:Dropped(self)
        
        // Set activity end so we can't drop like crazy
        self.timeOfLastDrop = Shared.GetTime() 
        
        if Server then
        
            //if ignoreReplacementWeapon ~= true and weapon.GetReplacementWeaponMapName then
                //self:GiveItem(weapon:GetReplacementWeaponMapName(), false)
                // the client expects the next weapon is going to be selected (does not know about the replacement).
                //self:SelectNextWeaponInDirection(1)
            //end
        
        end
        
        return true
        
    end
    
    return false

end

function Marine:GetCanBeHealedOverride()
    return not self:GetIsStateFrozen()
end

function Marine:GetWeldPercentageOverride()
    return self:GetArmor() / self:GetMaxArmor()
end

function Marine:UpdateSprintingState()
end

function Marine:OnWeldOverride(doer, elapsedTime)

    if self:GetArmor() < self:GetMaxArmor() then
    
        local addArmor = kArmorWeldRate * elapsedTime
        self:SetArmor(self:GetArmor() + addArmor)
        
    end
    
end

function Marine:GetCanChangeViewAngles()
    return not self:GetIsStunned() and not self:GetIsStateFrozen()
end

function Marine:OnStun()
end

function Marine:OnUseTarget(target)

    local activeWeapon = self:GetActiveWeapon()

    if target and HasMixin(target, "Construct") and ( target:GetCanConstruct(self) or (target.CanBeWeldedByBuilder and target:CanBeWeldedByBuilder()) ) then
    
        if activeWeapon and activeWeapon:GetMapName() ~= Builder.kMapName then
            self:SetActiveWeapon(Builder.kMapName, true)
            self.weaponBeforeUse = activeWeapon:GetMapName()
        end
        
    else
        if activeWeapon and activeWeapon:GetMapName() == Builder.kMapName and self.weaponBeforeUse then
            self:SetActiveWeapon(self.weaponBeforeUse, true)
        end    
    end

end

function Marine:OnUseEnd() 

    local activeWeapon = self:GetActiveWeapon()

    if activeWeapon and activeWeapon:GetMapName() == Builder.kMapName and self.weaponBeforeUse then
        self:SetActiveWeapon(self.weaponBeforeUse)
    end

end

function Marine:OnUpdateAnimationInput(modelMixin)

    PROFILE("Marine:OnUpdateAnimationInput")
    
    Player.OnUpdateAnimationInput(self, modelMixin)
    
    modelMixin:SetAnimationInput("attack_speed", self:GetCatalystFireModifier())
	modelMixin:SetAnimationInput("catalyst_speed", self:GetCatalystFireModifier())
    
end

function Marine:UpdateCombatTimers()

    PROFILE("Marine:UpdateCombatTimers")
    
    local time = Shared.GetTime()
    
    if self.lastcombatcheck == nil or self.lastcombatcheck + kMarineCombatPowerUpTime < time then
        //Resupply
        if self.hasresupply and (self.lastcombatresupply == nil or self.lastcombatresupply + kMarineCombatResupplyTime < time) then
            local weapon = self:GetActiveWeapon()
            if self:GetHealth() < self:GetMaxHealth() then
                //Give MedPack
                self:AddHealth(kHealthPerMedpack, false, true)
                StartSoundEffectAtOrigin(MedPack.kHealthSound, self:GetOrigin())
                self.lastcombatresupply = time
            elseif weapon ~= nil and weapon.GetAmmoFraction and weapon:GetAmmoFraction() < 1 then
                //Give Ammo
                if weapon:GiveAmmo(kClipsPerAmmoPack, false) then
                    StartSoundEffectAtOrigin(AmmoPack.kPickupSound, self:GetOrigin())
                end
                self.lastcombatresupply = time
            end
        end
        //Scan
        if self.hasscan and (self.lastcombatscan == nil or self.lastcombatscan + kMarineCombatScanTime < time) then
            // look for cloaked aliens nearby?
            // o wait no cloaking in classic lol.. wtf
            local aliens = GetEntitiesForTeamWithinRange("Player", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kMarineCombatScanCheckRadius)
            if #aliens > 0 then
                //Just trigger on this for now...
                CreateEntity(Scan.kMapName, self:GetOrigin(), self:GetTeamNumber())
                StartSoundEffectForPlayer(Observatory.kCommanderScanSound, self)
            end
            self.lastcombatscan = time
        end
        self.lastcombatcheck = time
    end
    
end

function Marine:OnProcessMove(input)

    if Server and self:GetIsAlive() then
    
    	self.catpackboost = Shared.GetTime() - self.timeCatpackboost < kCatPackDuration
        if self.unitStatusPercentage ~= 0 and self.timeLastUnitPercentageUpdate + 2 < Shared.GetTime() then
            self.unitStatusPercentage = 0
        end
        
        if self:GetGameMode() == kGameMode.Combat then
            self:UpdateCombatTimers()
        end
        
	end

    Player.OnProcessMove(self, input)

end

function Marine:GetCanSeeDamagedIcon(ofEntity)
    return HasMixin(ofEntity, "Weldable")
end

function Marine:GetHasCatpackBoost()
    return self.catpackboost
end

Shared.LinkClassToMap("Marine", Marine.kMapName, networkVars, true)