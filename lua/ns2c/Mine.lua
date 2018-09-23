-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Mine.lua
--
--    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Changed mine to detonate instantly, also can be killed before 'armed'

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/TriggerMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/OwnerMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/MarineOutlineMixin.lua")

class 'Mine' (ScriptActor)

Mine.kMapName = "mine"

Mine.kModelName = PrecacheAsset("models/marine/mine/mine.model")
-- The amount of time until the mine is detonated once armed.
local kTimeArmed = 0.10
-- The amount of time it takes other mines to trigger their detonate sequence when nearby mines explode.
local kTimedDestruction = 0.5

-- range in which other mines are trigger when detonating
local kMineChainDetonateRange = 1.5
local kMineCameraShakeDistance = 15
local kMineMinShakeIntensity = 0.01
local kMineMaxShakeIntensity = 0.13

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)

function Mine:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)

    if Server then
    
        -- init after OwnerMixin since 'OnEntityChange' is expected callback
        InitMixin(self, SleeperMixin)
        
        self:SetUpdates(true)
        
    elseif Client then
        InitMixin(self, MarineOutlineMixin)
    end
    
end

function Mine:GetReceivesStructuralDamage()
    return true
end

function Mine:GetDamageType()
    return kMineDamageType
end

local function SineFalloff(distanceFraction)
    local piFraction = Clamp(distanceFraction, 0, 1) * math.pi / 2
    return math.cos(piFraction + math.pi) + 1 
end

local function Detonate(self, armFunc)

    local hitEntities = GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), kMineDetonateRange)
    RadiusDamage(hitEntities, self:GetOrigin(), kMineDetonateRange, kMineDamage, self, false, SineFalloff)
    
    -- Start the timed destruction sequence for any mine within range of this exploded mine.
    local nearbyMines = GetEntitiesWithinRange("Mine", self:GetOrigin(), kMineChainDetonateRange)
    for _, mine in ipairs(nearbyMines) do
    
        if mine ~= self and not mine.armed then
            mine:AddTimedCallback(function() armFunc(mine) end, (math.random() + math.random()) * kTimedDestruction)
        end
        
    end
    
    local params = {}
    params[kEffectHostCoords] = Coords.GetLookIn( self:GetOrigin(), self:GetCoords().zAxis )
    
    params[kEffectSurface] = "metal"
    
    self:TriggerEffects("mine_explode", params)
    
    --CreateExplosionDecals(self, nil, 2)
    
    --TriggerCameraShake(self, kMineMinShakeIntensity, kMineMaxShakeIntensity, kMineCameraShakeDistance)
    
    DestroyEntity(self)
    
end

local function Arm(self)

    if not self.armed then
        
        self:AddTimedCallback(function() Detonate(self, Arm) end, 0)
        
        self:TriggerEffects("mine_arm")
        
        self.armed = true

    end
    
end

function Mine:GetSendDeathMessageOverride()
    return false
end

local function CheckEntityExplodesMine(self, entity)

    if not self.active then
        return false
    end
    
    if not HasMixin(entity, "Team") or GetEnemyTeamNumber(self:GetTeamNumber()) ~= entity:GetTeamNumber() then
        return false
    end
    
    if not HasMixin(entity, "Live") or not entity:GetIsAlive() or not entity:GetCanTakeDamage() then
        return false
    end
    
    if not (entity:isa("Player") or entity:isa("Whip") or entity:isa("Babbler")) then
        return false
    end
    
    if entity:isa("Commander") then
        return false
    end
    
    local minePos = self:GetEngagementPoint()
    local targetPos = entity:GetEngagementPoint()
    -- Do not trigger through walls. But do trigger through other entities.
    if not GetWallBetween(minePos, targetPos, entity) then
    
        -- If this fails, targets can sit in trigger, no "polling" update performed.
        Arm(self)
        return true
        
    end
    
    return false
    
end

local function CheckAllEntsInTriggerExplodeMine(self)

    local ents = self:GetEntitiesInTrigger()
    for e = 1, #ents do
        CheckEntityExplodesMine(self, ents[e])
    end
    
end

function Mine:OnInitialized()
    
    ScriptActor.OnInitialized(self)
    
    if Server then
    
        self.active = false
        
        local activateFunc = function(self)
                                 self.active = true
                                 CheckAllEntsInTriggerExplodeMine(self)
                             end
        self:AddTimedCallback(activateFunc, kMineActiveTime)
        
        self.armed = false
        self:SetHealth(self:GetMaxHealth())
        self:SetArmor(self:GetMaxArmor())
        self:TriggerEffects("mine_spawn")
        
        InitMixin(self, TriggerMixin)
        self:SetSphere(kMineTriggerRange)
        
    end
    
    self:SetModel(Mine.kModelName)
    
end

if Server then
   
    function Mine:OnStun()
        Arm(self)
    end

    function Mine:OnKill(attacker, doer, point, direction)
    
        if self.active then
            Arm(self)
        end

        ScriptActor.OnKill(self, attacker, doer, point, direction)
        
    end
    
    function Mine:OnTriggerEntered(entity)
        CheckEntityExplodesMine(self, entity)
    end
    
    --
    -- Go to sleep my sweet little mine if there are no entities nearby.
    --
    function Mine:GetCanSleep()
        return self:GetNumberOfEntitiesInTrigger() == 0
    end
    
    --
    -- We need to check when there are entities within the trigger area often.
    --
    function Mine:OnUpdate(dt)
    
        local now = Shared.GetTime()
        self.lastMineUpdateTime = self.lastMineUpdateTime or now
        if now - self.lastMineUpdateTime >= 0.5 then
        
            CheckAllEntsInTriggerExplodeMine(self)
            self.lastMineUpdateTime = now
            
        end
        
    end
    
end

function Mine:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false
end

function Mine:GetTechButtons(techId)

    local techButtons

    if techId == kTechId.RootMenu then
    
        techButtons = { kTechId.None, kTechId.None, kTechId.None, kTechId.None, 
                        kTechId.None, kTechId.None, kTechId.None, kTechId.None }
        
    end
    
    return techButtons
    
end

function Mine:GetAttachPointOriginHardcoded(attachPointName)
    return self:GetOrigin() + self:GetCoords().yAxis * 0.01
end

function Mine:GetDeathIconIndex()
    return kDeathMessageIcon.Mine
end

if Client then

    function Mine:OnInitialized()
    
        InitMixin(self, HiveVisionMixin)
        ScriptActor.OnInitialized(self)
    
    end

    function Mine:OnGetIsVisible(visibleTable, viewerTeamNumber)
    
        local player = Client.GetLocalPlayer()
        
        if player and player:isa("Commander") and viewerTeamNumber == GetEnemyTeamNumber(self:GetTeamNumber()) then
            
            visibleTable.Visible = false
        
        end

    end

end

Shared.LinkClassToMap("Mine", Mine.kMapName, networkVars)
