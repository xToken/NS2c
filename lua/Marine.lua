// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Marine.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Player.lua")
Script.Load("lua/Mixins/BaseMoveMixin.lua")
Script.Load("lua/Mixins/GroundMoveMixin.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/OrderSelfMixin.lua")
Script.Load("lua/MarineActionFinderMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/ScoringMixin.lua")
Script.Load("lua/DisruptMixin.lua")
Script.Load("lua/Weapons/Marine/Builder.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/HiveVisionMixin.lua")
Script.Load("lua/DisorientableMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/DetectorMixin.lua")
Script.Load("lua/AlienDetectableMixin.lua")
Script.Load("lua/ParasiteMixin.lua")

if Client then
    Script.Load("lua/TeamMessageMixin.lua")
end

class 'Marine' (Player)

Marine.kMapName = "marine"

if Server then
    Script.Load("lua/Marine_Server.lua")
else
    Script.Load("lua/Marine_Client.lua")
end

Shared.PrecacheSurfaceShader("models/marine/marine.surface_shader")
Shared.PrecacheSurfaceShader("models/marine/marine_noemissive.surface_shader")

Marine.kModelName = PrecacheAsset("models/marine/male/male.model")
Marine.kSpecialModelName = PrecacheAsset("models/marine/male/male_special.model")

Marine.kMarineAnimationGraph = PrecacheAsset("models/marine/male/male.animation_graph")

Marine.kDieSoundName = PrecacheAsset("sound/NS2.fev/marine/common/death")
Marine.kFlashlightSoundName = PrecacheAsset("sound/NS2.fev/common/light")
Marine.kGunPickupSound = PrecacheAsset("sound/ns2c.fev/ns2c/marine/weapon/pickup")
Marine.kSpendResourcesSoundName = PrecacheAsset("sound/NS2.fev/marine/common/player_spend_nanites")
Marine.kChatSound = PrecacheAsset("sound/NS2.fev/marine/common/chat")
Marine.kSoldierLostAlertSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/soldier_lost")

Marine.kFlinchEffect = PrecacheAsset("cinematics/marine/hit.cinematic")
Marine.kFlinchBigEffect = PrecacheAsset("cinematics/marine/hit_big.cinematic")

Marine.kEffectNode = "fxnode_playereffect"
Marine.kHealth = kMarineHealth
Marine.kBaseArmor = kMarineArmor
Marine.kArmorPerUpgradeLevel = kArmorPerUpgradeLevel
// Player phase delay - players can only teleport this often
Marine.kPlayerPhaseDelay = 2
Marine.kStunDuration = 2
Marine.kAcceleration = 58
Marine.kAirAcceleration = 28
Marine.kWalkMaxSpeed = 3.75                // Four miles an hour = 6,437 meters/hour = 1.8 meters/second (increase for FPS tastes)
Marine.kRunMaxSpeed = 9
Marine.kDoubleJumpMinHeightChange = 0.4
Marine.kGroundFriction = 8

// How fast does our armor get repaired by welders
Marine.kArmorWeldRate = 25
Marine.kWeldedEffectsInterval = .5
Marine.kWalkBackwardSpeedScalar = 0.4
// tracked per techId
Marine.kMarineAlertTimeout = 4
Marine.kAirStrafeWeight = 2

local networkVars =
{      
    flashlightOn = "boolean",
    timeOfLastPhase = "private time",
    
    timeOfLastDrop = "private time",
    timeOfLastPickUpWeapon = "private time",
    
    flashlightLastFrame = "private boolean",
    devoured = "private boolean",
    lastjumpheight = "private float",
    catpackboost = "private boolean",
    weaponUpgradeLevel = "integer (0 to 3)",
    
    unitStatusPercentage = "private integer (0 to 100)"
}

AddMixinNetworkVars(BaseMoveMixin, networkVars)
AddMixinNetworkVars(GroundMoveMixin, networkVars)
AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(DisruptMixin, networkVars)
AddMixinNetworkVars(OrderSelfMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)
AddMixinNetworkVars(AlienDetectableMixin, networkVars)

function Marine:OnCreate()

    InitMixin(self, BaseMoveMixin, { kGravity = Player.kGravity })
    InitMixin(self, GroundMoveMixin)
    InitMixin(self, CameraHolderMixin, { kFov = kDefaultFov })
    InitMixin(self, MarineActionFinderMixin)
    InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })
    InitMixin(self, DisruptMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, SelectableMixin)
    
    Player.OnCreate(self)
    
    InitMixin(self, DetectorMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, ParasiteMixin)
    InitMixin(self, AlienDetectableMixin)
       
    if Server then


        // stores welder / builder progress
        self.unitStatusPercentage = 0
        self.timeLastUnitPercentageUpdate = 0
        
    elseif Client then
    
        self.flashlight = Client.CreateRenderLight()
        
        self.flashlight:SetType( RenderLight.Type_Spot )
        self.flashlight:SetColor( Color(.8, .8, 1) )
        self.flashlight:SetInnerCone( math.rad(30) )
        self.flashlight:SetOuterCone( math.rad(35) )
        self.flashlight:SetIntensity( 10 )
        self.flashlight:SetRadius( 15 ) 
        self.flashlight:SetGoboTexture("models/marine/male/flashlight.dds")
        
        self.flashlight:SetIsVisible(false)
        
        InitMixin(self, TeamMessageMixin, { kGUIScriptName = "GUIMarineTeamMessage" })

        InitMixin(self, DisorientableMixin)
        
    end
    
end

function Marine:OnInitialized()

    // These mixins must be called before SetModel because SetModel eventually
    // calls into OnUpdatePoseParameters() which calls into these mixins.
    // Yay for convoluted class hierarchies!!!
    InitMixin(self, OrderSelfMixin, { kPriorityAttackTargets = { "Harvester" } })
    InitMixin(self, WeldableMixin)
    
    // SetModel must be called before Player.OnInitialized is called so the attach points in
    // the Marine are valid to attach weapons to. This is far too subtle...
    self:SetModel(Marine.kModelName, Marine.kMarineAnimationGraph)
    
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
        
        self:AddHelpWidget("GUIMapHelp", 1)
    end
    
    self.weaponDropTime = 0
    self.timeOfLastPhase = nil
    
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

local blockBlackArmor = false
if Server then
    Event.Hook("Console_blockblackarmor", function() if Shared.GetCheatsEnabled() then blockBlackArmor = not blockBlackArmor end end)
end

function Marine:GetDetectionRange()
    return ConditionalValue(self:OnCheckDetectorActive(), kMotionTrackingDetectionRange, 0)
end

function Marine:OnCheckDetectorActive()
    return GetHasTech(self, kTechId.Observatory) and GetHasTech(self, kTechId.MotionTracking)
end

function Marine:DeCloak()
    return false
end

function Marine:MakeSpecialEdition()

    if not blockBlackArmor then
        self:SetModel(Marine.kSpecialModelName, Marine.kMarineAnimationGraph)
    else
        self:SetModel(Marine.kModelName, Marine.kMarineAnimationGraph)        
    end
    
end

function Marine:IsValidDetection(detectable)
    if detectable.GetReceivesStructuralDamage and detectable:GetReceivesStructuralDamage() then
        return false
    end
    
    //Ghost adds a chance to 'evade' detection
    if detectable:isa("Alien") then
        local hasupg, level = GetHasGhostUpgrade(detectable)
        if hasupg and level > 0 then
            return math.random(1, 100) <= (level * 25)
        end
    end
    
    return true
end

function Marine:GetArmorLevel()

    local armorLevel = 0
    local techTree = self:GetTechTree()

    if techTree then
    
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
        
    end

    return armorLevel

end

function Marine:GetWeaponLevel()

    local weaponLevel = 0
    local techTree = self:GetTechTree()

    if techTree then
        
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
            
    end

    return weaponLevel

end

// Currently there are some issues with a jumping Marine getting disrupted (weapons becoming locked).
// not using now toss, only stun. maybe that already fixed it
function Marine:GetCanBeDisrupted()
    return not self:GetIsJumping()
end

function Marine:OnJump()
    self.lastjumpheight = ConditionalValue(self.crouching, self:GetOrigin().y - 0.5, self:GetOrigin().y)
end

function Marine:GetCanRepairOverride(target)
    return self:GetWeapon(Welder.kMapName) and HasMixin(target, "Weldable") and ( (target:isa("Marine") and target:GetArmor() < target:GetMaxArmor()) or (not target:isa("Marine") and target:GetHealthScalar() < 0.9) )
end

function Marine:GetSlowOnLand()
    return ((self:GetOrigin().y - self.lastjumpheight) <= Marine.kDoubleJumpMinHeightChange)
end

function Marine:GetArmorAmount()

    local armorLevels = 0
    
    if(GetHasTech(self, kTechId.Armor3, true)) then
        armorLevels = 3
    elseif(GetHasTech(self, kTechId.Armor2, true)) then
        armorLevels = 2
    elseif(GetHasTech(self, kTechId.Armor1, true)) then
        armorLevels = 1
    end
    
    return Marine.kBaseArmor + armorLevels*Marine.kArmorPerUpgradeLevel
    
end

function Marine:OnDestroy()

    Player.OnDestroy(self)
    
    if Server then

    elseif Client then
        
        if self.ruptureMaterial then
        
            Client.DestroyRenderMaterial(self.ruptureMaterial)
            self.ruptureMaterial = nil
            
        end  
        
        if self.flashlight ~= nil then
            Client.DestroyRenderLight(self.flashlight)
        end
        
        if self.marineHUD then
        
            GetGUIManager():DestroyGUIScript(self.marineHUD)
            self.marineHUD = nil
            
        end
        
        if self.waypoints then
            GetGUIManager():DestroyGUIScript(self.waypoints)
            self.waypoints = nil
        end
        
        if self.pickups then
        
            GetGUIManager():DestroyGUIScript(self.pickups)
            self.pickups = nil
            
        end

        if self.hints then
        
            GetGUIManager():DestroyGUIScript(self.hints)
            self.hints = nil
            
        end        
        
        if self.guiOrders then
            GetGUIManager():DestroyGUIScript(self.guiOrders)
            self.guiOrders = nil
        end
        
        if self.sensorBlips then
        
            GetGUIManager():DestroyGUIScript(self.sensorBlips)
            self.sensorBlips = nil
            
        end
        
        if self.objectiveDisplay then
        
            GetGUIManager():DestroyGUIScript(self.objectiveDisplay)
            self.objectiveDisplay = nil
            
        end
        
        if self.progressDisplay then
        
            GetGUIManager():DestroyGUIScript(self.progressDisplay)
            self.progressDisplay = nil
            
        end
        
    end
    
end

function Marine:HandleButtons(input)

    PROFILE("Marine:HandleButtons")
    
    Player.HandleButtons(self, input)
    
    if self:GetCanControl() then
    
        local flashlightPressed = bit.band(input.commands, Move.ToggleFlashlight) ~= 0
        if not self.flashlightLastFrame and flashlightPressed then
        
            self:SetFlashlightOn(not self:GetFlashlightOn())
            Shared.PlaySound(self, Marine.kFlashlightSoundName)
            
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
		                self:SetScoreboardChanged(true)
		                Shared.PlayWorldSound(nil, Marine.kGunPickupSound, nil, self:GetOrigin())
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

function Marine:GetOnGroundRecently()
    return (self.timeLastOnGround ~= nil and Shared.GetTime() < self.timeLastOnGround + 0.4) 
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

function Marine:GetCrouchSpeedScalar()
    return Player.kCrouchSpeedScalar
end

function Marine:GetMaxSpeed(possible)

    if possible then
        return Marine.kRunMaxSpeed
    end
    
    if self:GetIsDisrupted() then
        return 0
    end
    
    //Walking
    local maxSpeed = ConditionalValue(self.movementModiferState and self:GetIsOnSurface(), Marine.kWalkMaxSpeed,  Marine.kRunMaxSpeed)
    
    // Take into account crouching
    if self:GetCrouching() and self:GetIsOnGround() then
        maxSpeed = ( 1 - self:GetCrouchAmount() * self:GetCrouchSpeedScalar() ) * maxSpeed
    end
    
    // Take into account our weapon inventory and current weapon. Assumes a vanilla marine has a scalar of around .8.
    local inventorySpeedScalar = self:GetInventorySpeedScalar()

    local adjustedMaxSpeed = maxSpeed * self:GetCatalystMoveSpeedModifier() * self:GetSlowSpeedModifier() * inventorySpeedScalar 
    //Print("Adjusted max speed => %.2f (without inventory: %.2f)", adjustedMaxSpeed, adjustedMaxSpeed / inventorySpeedScalar )
    
    return adjustedMaxSpeed
    
end

function Marine:GetFootstepSpeedScalar()
    return Clamp(self:GetVelocityLength() / (Marine.kRunMaxSpeed * self:GetCatalystMoveSpeedModifier() * self:GetSlowSpeedModifier()), 0, 1)
end

// Maximum speed a player can move backwards
function Marine:GetMaxBackwardSpeedScalar()
    return Marine.kWalkBackwardSpeedScalar
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

local marineTechButtons = { kTechId.Attack, kTechId.Move, kTechId.Defend, kTechId.None, 
                                  kTechId.None, kTechId.None, kTechId.None, kTechId.None }
                                  
function Marine:GetTechButtons(techId)

    local techButtons = nil
    
    if techId == kTechId.WeaponsMenu then
        techButtons = marineTechButtons
    end
    
    return techButtons
 
end

function Marine:GetCatalystFireModifier()
    local weapon = self:GetActiveWeapon()    
    if weapon ~= nil then
        if weapon.kMapName == "shotgun" then
            return ConditionalValue(self:GetHasCatpackBoost(), 1.69, 1.3)
        end
    end
    
    return ConditionalValue(self:GetHasCatpackBoost(), CatPack.kAttackSpeedModifier, 1)
end

function Marine:GetCatalystMoveSpeedModifier()
    return ConditionalValue(self:GetHasCatpackBoost(), CatPack.kMoveSpeedScalar, 1)
end

function Marine:GetHasSayings()
    return true
end

// Other
function Marine:GetSayings()

    if(self.showSayings) then
    
        if(self.showSayingsMenu == 1) then
            return marineRequestSayingsText
        end
        if(self.showSayingsMenu == 2) then
            return marineGroupSayingsText
        end
        if(self.showSayingsMenu == 3) then
            return GetVoteActionsText(self:GetTeamNumber())
        end
        
    end
    
    return nil
    
end

function Marine:GetChatSound()
    return Marine.kChatSound
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
    
    if weapon ~= nil and weapon.GetIsDroppable and weapon:GetIsDroppable() then
    
        // Don't drop weapons too fast.
        if ignoreDropTimeLimit or (Shared.GetTime() > (self.timeOfLastDrop + kDropWeaponTimeLimit)) then
            return true
        end
        
    end
    
    return false
    
end

// Do basic prediction of the weapon drop on the client so that any client
// effects for the weapon can be dealt with
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
    
        // Remove from player's inventory
        if Server then
            self:RemoveWeapon(weapon)
        end
        
        if Server then
        
            local weaponSpawnCoords = self:GetAttachPointCoords(Weapon.kHumanAttachPoint)
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

function Marine:GetIsDevoured()
    return self.devoured
end

function Marine:OnDevoured()
    self.devoured = true
end

function Marine:GetCanSkipPhysics()
    return self.devoured
end

function Marine:OnDevouredEnd()    
    self.devoured = false
    self:SetModel(Marine.kModelName, Marine.kMarineAnimationGraph)
end

function Marine:GetWeldPercentageOverride()
    return self:GetArmor() / self:GetMaxArmor()
end

function Marine:OnWeldOverride(doer, elapsedTime)

    if self:GetArmor() < self:GetMaxArmor() then
    
        local addArmor = Marine.kArmorWeldRate * elapsedTime
        self:SetArmor(self:GetArmor() + addArmor)
        
    end
    
end

function Marine:OnSpitHit(direction)

end

function Marine:GetCanChangeViewAngles()
    return true
end

function Marine:OnDisrupt()
end

function Marine:OnUseTarget(target)

    local activeWeapon = self:GetActiveWeapon()

    if target and HasMixin(target, "Construct") and ( target:GetCanConstruct(self) or (target.CanBeWeldedByBuilder and target:CanBeWeldedByBuilder()) ) then
    
        if activeWeapon and activeWeapon:GetMapName() ~= Builder.kMapName then
            self:SetActiveWeapon(Builder.kMapName)
            self.weaponBeforeUse = activeWeapon:GetMapName()
        end
        
    else
        if activeWeapon and activeWeapon:GetMapName() == Builder.kMapName and self.weaponBeforeUse then
            self:SetActiveWeapon(self.weaponBeforeUse)
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
    
end

function Marine:OnProcessMove(input)

    if Server then
    	self.catpackboost = Shared.GetTime() - self.timeCatpackboost < CatPack.kDuration
        if self.unitStatusPercentage ~= 0 and self.timeLastUnitPercentageUpdate + 2 < Shared.GetTime() then
            self.unitStatusPercentage = 0
        end
	end


    Player.OnProcessMove(self, input)

end

function Marine:OnUpdateCamera(deltaTime)

    if self:GetIsDisrupted() then
        self:SetDesiredCameraYOffset(-0.25)
    else
        Player.OnUpdateCamera(self, deltaTime)
    end

end

function Marine:GetHasCatpackBoost()
    return self.catpackboost
end

Shared.LinkClassToMap("Marine", Marine.kMapName, networkVars)