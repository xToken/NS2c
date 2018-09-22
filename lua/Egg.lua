-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\Egg.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--                  Andreas Urwalek (andi@unknownworlds.com)
--
-- Thing that aliens spawn out of.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Removed concept of pre-evolved eggs

Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/AchievementGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/CloakableMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/DetectableMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/UmbraMixin.lua")
Script.Load("lua/SleeperMixin.lua")

class 'Egg' (ScriptActor)

Egg.kMapName = "egg"

Egg.kModelName = PrecacheAsset("models/alien/egg/egg.model")
Egg.kGlowEffect = PrecacheAsset("cinematics/alien/egg/glow.cinematic")
Egg.kAnimationGraph = PrecacheAsset("models/alien/egg/egg.animation_graph")

Egg.kXExtents = 1
Egg.kYExtents = 1
Egg.kZExtents = 1

Egg.kSkinOffset = Vector(0, 0.12, 0)

Egg.kSpawnAnimLen = 1.5

local networkVars =
{
    empty = "boolean",   -- if player is inside it
    spawned = "boolean" -- Spawn cycle complete
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(CloakableMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(DetectableMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(UmbraMixin, networkVars)

function Egg:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, AchievementGiverMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, CloakableMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, DetectableMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, UmbraMixin)
    
    if Server then

    elseif Client then
        InitMixin(self, CommanderGlowMixin)    
    end
    
    self.spawned = true
    self.empty = true
    
    self:SetLagCompensated(false)
    
end

function Egg:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(Egg.kModelName, Egg.kAnimationGraph)
    self:SetPhysicsCollisionRep(CollisionRep.Move)
    
    self.queuedPlayerId = nil

    
    if Server then
    
        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
        InitMixin(self, StaticTargetMixin)
        InitMixin(self, SleeperMixin)
        
        self:AddTimedCallback( Egg.UpdateSpawnedFlag, Egg.kSpawnAnimLen )
        
    elseif Client then
        InitMixin(self, UnitStatusMixin)
    end
    
end

function Egg:UpdateSpawnedFlag( deltaTime )
    self.spawned = false
    self.built = true
    return false
end

function Egg:GetShowCrossHairText(toPlayer)
    return not GetAreEnemies(self, toPlayer)
end    

function Egg:GetCanSleep()
    return true
end
function Egg:GetIsWallWalkingAllowed()
    return false
end    

function Egg:GetBaseArmor()
    return kEggArmor
end

function Egg:GetBaseHealth()
    return kEggHealth
end

function Egg:GetArmorFullyUpgradedAmount()
    return 0
end

function Egg:GetTechAllowed(techId, techNode, player)

    local allowed, canAfford = ScriptActor.GetTechAllowed(self, techId, techNode, player) 

    if techId == kTechId.Cancel then
        allowed = false
    end
    
    return allowed, canAfford
    
end

function Egg:OnResearchComplete(techId)
    
    local success = false    

    if techId == kTechId.GorgeEgg or techId == kTechId.LerkEgg  or techId == kTechId.FadeEgg  or techId == kTechId.OnosEgg then
        self:UpgradeToTechId(techId)
    end
    
    return success
    
end

function Egg:SetHive(hive)
    self.hiveId = hive:GetId()
end

function Egg:GetHive()
    return Shared.GetEntity(self.hiveId)
end

function Egg:GetReceivesStructuralDamage()
    return true
end
--
-- Takes the queued player from this Egg and placed them back in the
-- respawn queue to be spawned elsewhere.
--
function Egg:RequeuePlayer()

    if self.queuedPlayerId then
    
        local player = Shared.GetEntity(self.queuedPlayerId)
        local team = self:GetTeam()
        -- There are cases when the player or team is no longer valid such as
        -- when Egg:OnDestroy() is called during server shutdown.
        if player and team then
        
            if not player:isa("AlienSpectator") then
                error("AlienSpectator expected, instead " .. player:GetClassName() .. " was in queue")
            end
            
            player:SetEggId(Entity.invalidId)
            team:PutPlayerInRespawnQueue(player, Shared.GetTime() - kAlienMinSpawnInterval)
            Server.SendNetworkMessage(Server.GetOwner(player), "SetTimeWaveSpawnEnds", { time = 3 }, true)
        end
        
    end
    
    -- Don't spawn player
    self:SetEggFree()

end

function Egg:GetCanConstructOverride(player)
    return false
end

if Server then

    function Egg:GetDestroyOnKill()
        return true
    end

    function Egg:OnKill(attacker, doer, point, direction)
    
        self:RequeuePlayer()
        self:TriggerEffects("egg_death")
        
    end
    
end

function Egg:GetSendDeathMessageOverride()
    return false
end

function Egg:GetClassToGestate()
    return LookupTechData(self:GetGestateTechId(), kTechDataMapName, Skulk.kMapName)
end

function Egg:GetGestateTechId()

    local techId = self:GetTechId()
    
    if self:GetIsResearching() then
        techId = self:GetResearchingId()
    end

    if techId == kTechId.Egg then
        return kTechId.Skulk
    elseif techId == kTechId.GorgeEgg then
        return kTechId.Gorge
    elseif techId == kTechId.LerkEgg then
        return kTechId.Lerk
    elseif techId == kTechId.FadeEgg then
        return kTechId.Fade
    elseif techId == kTechId.OnosEgg then
        return kTechId.Onos
    end

end

local function GestatePlayer(self, player, fromTechId)

    player.oneHive = false
    player.twoHives = false
    player.threeHives = false

    local newPlayer = player:Replace(Embryo.kMapName)
    if not newPlayer:IsAnimated() then
        newPlayer:SetDesiredCamera(1.1, { follow = true, tweening = kTweeningFunctions.easeout7 })
    end
    newPlayer:SetCameraDistance(kGestateCameraDistance)
    
    -- Eliminate velocity so that we don't slide or jump as an egg
    newPlayer:SetVelocity(Vector(0, 0, 0))
    
    newPlayer:DropToFloor()
    
    local techIds = { self:GetGestateTechId() }
    newPlayer:SetGestationData(techIds, fromTechId, 1, 1)

end

function Egg:GetUnitNameOverride(viewer)

    if GetAreEnemies(self, viewer) then
        return GetDisplayNameForTechId(kTechId.Egg)
    end

    return GetDisplayName(self)    

end

-- Grab player out of respawn queue unless player passed in (for test framework)
function Egg:SpawnPlayer(player)

    PROFILE("Egg:SpawnPlayer")

    local queuedPlayer = player
    
    if not queuedPlayer or self.queuedPlayerId ~= nil then
        queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
    end
    
    if queuedPlayer ~= nil then
    
        local queuedPlayer = player
        if not queuedPlayer then
            queuedPlayer = Shared.GetEntity(self.queuedPlayerId)
        end
    
        -- Spawn player on top of egg
        local spawnOrigin = Vector(self:GetOrigin())
        -- Move down to the ground.
        local _, normal = GetSurfaceAndNormalUnderEntity(self)
        if normal.y < 1 then
            spawnOrigin.y = spawnOrigin.y - (self:GetExtents().y / 2) + 1
        else
            spawnOrigin.y = spawnOrigin.y - (self:GetExtents().y / 2)
        end

        local gestationClass = self:GetClassToGestate()
        
        -- We must clear out queuedPlayerId BEFORE calling ReplaceRespawnPlayer
        -- as this will trigger OnEntityChange() which would requeue this player.
        self.queuedPlayerId = nil
        
        local team = queuedPlayer:GetTeam()
        local success, player = team:ReplaceRespawnPlayer(queuedPlayer, spawnOrigin, queuedPlayer:GetAngles(), gestationClass)                
        player:SetCameraDistance(0)
        player:SetHatched()
        -- It is important that the player was spawned at the spot we specified.
        assert(player:GetOrigin() == spawnOrigin)
        
        if success then
        
            if self:GetIsResearching() then
                GestatePlayer(self, player, kTechId.Skulk)
            else            
                self:TriggerEffects("egg_death")
            end
            
            DestroyEntity(self) 
            
            return true, player
            
        end
            
    end
    
    return false, nil

end

function Egg:GetQueuedPlayerId()
    return self.queuedPlayerId
end

function Egg:SetQueuedPlayerId(playerId, spawntime)

    self.queuedPlayerId = playerId
    self.empty = false
    
    local playerToSpawn = Shared.GetEntity(playerId)
    assert(playerToSpawn:isa("AlienSpectator"))
    
    playerToSpawn:SetEggId(self:GetId())
    playerToSpawn:SetIsRespawning(true)
    
    if Server then
                
        if playerToSpawn.SetSpectatorMode then
            playerToSpawn:SetSpectatorMode(kSpectatorMode.Following)
        end
        
        playerToSpawn:SetFollowTarget(self)
        
    end
    
end

function Egg:SetEggFree()

    self.queuedPlayerId = nil
    self.empty = true

end

function Egg:GetIsFree()
    return self.queuedPlayerId == nil
end

--
-- Eggs never sight nearby enemy players.
--
function Egg:OverrideCheckVision()
    return false
end

function Egg:GetHealthbarOffset()
    return 0.4
end

function Egg:GetEngagementPointOverride()
    return self:GetOrigin() + Vector(0, 0.3, 0)
end

function Egg:InternalGetCanBeUsed(player)
    return false
end

function Egg:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false
end

if Server then

    -- delete the egg to avoid invalid ID's and reset the player to spawn queue if one is occupying it
    function Egg:OnDestroy()
    
        local team = self:GetTeam()
        if team and team.OnEggDestroyed then
            team:OnEggDestroyed(self)
        end   
        
        -- Just in case there is a player waiting to spawn in this egg.
        self:RequeuePlayer()
        
        ScriptActor.OnDestroy(self)
        
    end
    
    function Egg:OnUse(player, elapsedTime, useSuccessTable)
    
        local useSuccess = false

    end
    
    function Egg:OnEntityChange(entityId, newEntityId)
    
        if self.queuedPlayerId and self.queuedPlayerId == entityId then
            self:RequeuePlayer()
        end
        
    end
    
end

function Egg:OnUpdateAnimationInput(modelMixin)

    PROFILE("Egg:OnUpdateAnimationInput")
    
    modelMixin:SetAnimationInput("empty", self.empty)
    modelMixin:SetAnimationInput("built", true)
    modelMixin:SetAnimationInput("spawned", self.spawned)
    
end

function Egg:OnAdjustModelCoords(coords)
    
    coords.origin = coords.origin - Egg.kSkinOffset
    return coords
    
end

function Egg:GetIsEmpty()
    return self.empty
end

Shared.LinkClassToMap("Egg", Egg.kMapName, networkVars)
