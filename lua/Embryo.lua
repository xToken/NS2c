// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Embryo.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
// 
// Aliens change into this while evolving into a new lifeform. Looks like an egg.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removal of some hypermutation and mist code, adjustments to HP scaling

Script.Load("lua/Mixins/CameraHolderMixin.lua")
Script.Load("lua/Alien.lua")

class 'Embryo' (Alien)

Embryo.kMapName = "embryo"
Embryo.kModelName = PrecacheAsset("models/alien/egg/egg.model")
Embryo.kAnimationGraph = PrecacheAsset("models/alien/egg/egg.animation_graph")
Embryo.kBaseHealth = 200
Embryo.kBaseArmor = 150
local kUpdateGestationTime = 0.1
Embryo.kXExtents = .25
Embryo.kYExtents = .25
Embryo.kZExtents = .25
Embryo.kEvolveSpawnOffset = 0.2

local kMinGestationTime = 1.5

Embryo.kSkinOffset = Vector(0, 0.02, 0)

local kAlienMaxUpgrades = 3

local networkVars =
{
    evolvePercentage = "private float",
    gestationTypeTechId = "enum kTechId"
}

AddMixinNetworkVars(CameraHolderMixin, networkVars)

if Client then

    function Embryo:UpdateCrossHairText(entity)

        local lifeFormDisplayName = GetDisplayNameForTechId(self.gestationTypeTechId, "")
        
        self.crossHairText = string.format(Locale.ResolveString("EVOLVING_TO"), lifeFormDisplayName)
        self.crossHairHealth = math.floor(self.evolvePercentage)
        self.crossHairTeamType = kAlienTeamType

    end

end

function Embryo:OnCreate()

    Alien.OnCreate(self)
        
    self.evolvePercentage = 0
    
    self.evolveTime = 0
    
    self.gestationTime = 0
    
    self.gestationTypeTechId = kTechId.None

end

local function UpdateGestation(self)

    // Cannot spawn unless alive.
    if self:GetIsAlive() and self.gestationClass ~= nil then
    
        if not self.gestateEffectsTriggered then
        
            self:TriggerEffects("player_start_gestate")
            self.gestateEffectsTriggered = true
            
        end
        
        self.evolveTime = self.evolveTime + kUpdateGestationTime
        
        self.evolvePercentage = Clamp((self.evolveTime / self.gestationTime) * 100, 0, 100)
        
        if self.evolveTime >= self.gestationTime then
        
            // Replace player with new player
            local newPlayer = self:Replace(self.gestationClass)
            newPlayer:SetCameraDistance(0)
            
            local capsuleHeight, capsuleRadius = self:GetTraceCapsule()
            local newAlienExtents = LookupTechData(newPlayer:GetTechId(), kTechDataMaxExtents)
            
            if not GetHasRoomForCapsule(newAlienExtents, self:GetOrigin() + Vector(0, newAlienExtents.y + Embryo.kEvolveSpawnOffset, 0), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, nil, EntityFilterTwo(self, newPlayer)) then
            
                local spawnPoint = GetRandomSpawnForCapsule(newAlienExtents.y, capsuleRadius, self:GetModelOrigin(), 0.5, 5, EntityFilterOne(self))

                if spawnPoint then
                    newPlayer:SetOrigin(spawnPoint)
                end
                
            end

            newPlayer:DropToFloor()
            
            self:TriggerEffects("player_end_gestate")
            
            // Now give new player all the upgrades they purchased
            local upgradesGiven = 0
            
            for index, upgradeId in ipairs(self.evolvingUpgrades) do

                if newPlayer:GiveUpgrade(upgradeId) then
                    upgradesGiven = upgradesGiven + 1
                end
                
            end
            
            local healthScalar = self:GetHealth() / self:GetMaxHealth()
            local armorScalar = self:GetMaxArmor() == 0 and 1 or self:GetArmor() / self:GetMaxArmor()

            newPlayer:SetHealth(healthScalar * LookupTechData(self.gestationTypeTechId, kTechDataMaxHealth))
            newPlayer:SetArmor(armorScalar * LookupTechData(self.gestationTypeTechId, kTechDataMaxArmor))
            newPlayer:UpdateArmorAmount()
            
            if self.resOnGestationComplete then
                newPlayer:AddResources(self.resOnGestationComplete)
            end

            // Notify team

            local team = self:GetTeam()

            if team and team.OnEvolved then

                team:OnEvolved(newPlayer:GetTechId())

                for _, upgradeId in ipairs(self.evolvingUpgrades) do

                    if team.OnEvolved then
                        team:OnEvolved(upgradeId)
                    end
                    
                end

            end
            
            // Return false so that we don't get called again if the server time step
            // was larger than the callback interval
            return false
            
        end
        
    end
    
    return true
    
end

function Embryo:OnInitialized()

    InitMixin(self, CameraHolderMixin, { kFov = kEmbryoFov })
    
    Alien.OnInitialized(self)
    
    self:SetModel(Embryo.kModelName, Embryo.kAnimationGraph)
    
    if Server then
        self:AddTimedCallback(UpdateGestation, kUpdateGestationTime)
    end
    
    self.originalAngles = Angles(self:GetAngles())

    if Client and Client.GetLocalPlayer() == self then
    
        if Client.GetOptionBoolean(kInvertedMouseOptionsKey, false) then
            Client.SetPitch(-0.8)
        else
            Client.SetPitch(0.8)
        end

        
    end
    
    // do not animate the camera transition, just teleport instantly.
    self:SetCameraDistance(kGestateCameraDistance)
    self:SetViewOffsetHeight(.5)

end

function Embryo:GetShowUnitStatusForOverride(forEntity)
    return true
end

function Embryo:GetPreventCameraPenetration()
    return true
end

local kEmbryoHealthbarOffset = Vector(0, 0.7, 0)
function Embryo:GetHealthbarOffset()
    return kEmbryoHealthbarOffset
end

function Embryo:GetShowHealthFor(player)
    return true
end

function Embryo:GetName(forEntity)
    
    // show us as standard egg to enemies, so they don't know that we are a gestating alien
    if Client and GetAreEnemies(self, forEntity) then
        return GetDisplayNameForTechId(kTechId.Egg)
    end
    
    return Alien.GetName(self, forEntity)
    
end

function Embryo:SetOriginalAngles(angles)

    self.originalAngles = angles
    self:SetAngles(angles)
    
end

// hide badge when gestating, this would otherwise tell enemy players that we are not a usual egg, but a gestating player
function Embryo:GetShowBadgeOverride()
    return false
end

function Embryo:GetDesiredAngles()
    return self.originalAngles
end

function Embryo:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.3, 0)
end

function Embryo:GetGestationTechId()
    return self.gestationTypeTechId
end

function Embryo:GetShowCrossHairText(toPlayer)
    return not GetAreEnemies(self, toPlayer)
end    

function Embryo:GetAnimateDeathCamera()
    return false
end 

function Embryo:GetBaseArmor()
    return 0
end

function Embryo:GetArmorFullyUpgradedAmount()
    return 0
end

function Embryo:GetMaxViewOffsetHeight()
    return .2
end

function Embryo:GetGestationTime(gestationTypeTechId)
    return LookupTechData(gestationTypeTechId, kTechDataGestateTime)
end

function Embryo:SetGestationData(techIds, previousTechId, healthScalar, armorScalar)

    // Save upgrades so they can be given when spawned
    self.evolvingUpgrades = {}
    table.copy(techIds, self.evolvingUpgrades)

    self.gestationClass = nil
    
    for i, techId in ipairs(techIds) do
        self.gestationClass = LookupTechData(techId, kTechDataGestateName)
        if self.gestationClass then 
            // Remove gestation tech id from "upgrades"
            self.gestationTypeTechId = techId
            table.removevalue(self.evolvingUpgrades, self.gestationTypeTechId)
            break 
        end
    end
    
    // Upgrades don't have a gestate name, we want to gestate back into the
    // current alien type, previousTechId.
    if not self.gestationClass then
        self.gestationTypeTechId = previousTechId
        self.gestationClass = LookupTechData(previousTechId, kTechDataGestateName)
    end
    self.gestationStartTime = Shared.GetTime()
    
    local lifeformTime = ConditionalValue(self.gestationTypeTechId ~= previousTechId, self:GetGestationTime(self.gestationTypeTechId), 0)
    
    local newUpgradesAmount = 0    
    local currentUpgrades = self:GetUpgrades()
    
    for _, upgradeId in ipairs(self.evolvingUpgrades) do
    
        if not table.contains(currentUpgrades, upgradeId) then
            newUpgradesAmount = newUpgradesAmount + 1
        end
        
    end
    
    self.gestationTime = ConditionalValue(Shared.GetDevMode(), 2, lifeformTime + newUpgradesAmount * kUpgradeGestationTime)
    
    self.gestationTime = math.max(kMinGestationTime, self.gestationTime)
    
    self.evolveTime = 0
    self.maxHealth = Embryo.kBaseHealth
	self:SetHealth(self.maxHealth* healthScalar)
    self.maxArmor = Embryo.kBaseArmor
	self:SetArmor(self.maxArmor* armorScalar)
    // Use this amount of health when we're done evolving
    self.healthScalar = healthScalar
    self.armorScalar = armorScalar
    
    // we reset the upgrades entirely and set them again, simplifies the code
    self:ClearUpgrades()
    
end

function Embryo:GetEvolutionTime()
    return self.evolveTime
end

// Allow players to rotate view, chat, etc. but not move
function Embryo:OverrideInput(input)

    ClampInputPitch(input)
    
    // Completely override movement and commands
    input.move.x = 0
    input.move.y = 0
    input.move.z = 0
    
    // Only allow some actions like going to menu (not jump, use, etc.)
    input.commands = bit.band(input.commands, Move.Exit)
    
    return input
    
end

function Embryo:ConstrainMoveVelocity(moveVelocity)

    // Embryos can't move    
    moveVelocity.x = 0
    moveVelocity.y = 0
    moveVelocity.z = 0
    
end

function Embryo:PostUpdateMove(input, runningPrediction)
    self:SetAngles(self.originalAngles)
end

function Embryo:OnAdjustModelCoords(coords)

    coords.origin = coords.origin - Embryo.kSkinOffset
    return coords
    
end

if Server then

    function Embryo:OnKill(attacker, doer, point, direction)
    
        Alien.OnKill(self, attacker, doer, point, direction)
        
        self:TriggerEffects("egg_death")
        
        self:SetModel("")
        
    end
    
end

function Embryo:OnUpdateAnimationInput(modelMixin)

    modelMixin:SetAnimationInput("built", true)
    modelMixin:SetAnimationInput("empty", false)
    
end

Shared.LinkClassToMap("Embryo", Embryo.kMapName, networkVars)
