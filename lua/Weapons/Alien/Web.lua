//
// lua\Web.lua

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/TriggerMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/OwnerMixin.lua")
Script.Load("lua/SleeperMixin.lua")

class 'Web' (ScriptActor)

kWebActivateTime = 2

Web.kMapName = "web"

Web.kModelName = PrecacheAsset("models/alien/gorge/goowallnode.model")

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function Web:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)

    if Server then
    
        InitMixin(self, OwnerMixin)
        // init after OwnerMixin since 'OnEntityChange' is expected callback
        InitMixin(self, EntityChangeMixin)
        InitMixin(self, SleeperMixin)
        
        self:SetUpdates(true)
        
    end
    
end

function Web:GetReceivesStructuralDamage()
    return false
end    

local function CheckEntityTriggers(self, entity)

    if not self.active then
        return false
    end
    
    if not HasMixin(entity, "Team") or GetEnemyTeamNumber(self:GetTeamNumber()) ~= entity:GetTeamNumber() then
        return false
    end
    
    if not HasMixin(entity, "Live") or not entity:GetIsAlive() or not entity:GetCanTakeDamage() then
        return false
    end
    
    if not (entity:isa("Player") or entity:isa("Whip")) then
        return false
    end
    
    if entity:isa("Commander") then
        return false
    end
    
    local webPos = self:GetEngagementPoint()
    local targetPos = entity:GetEngagementPoint()
    // Do not trigger through walls. But do trigger through other entities.
    if not GetWallBetween(webPos, targetPos, entity) then
        entity:SetDisruptDuration(kWebImobilizeTime, true)
        self:TriggerEffects("death")
        DestroyEntity(self)
        return true      
    end
    return false
    
end

local function CheckAllEntsInTrigger(self)

    local ents = self:GetEntitiesInTrigger()
    for e = 1, #ents do
        CheckEntityTriggers(self, ents[e])
    end
    
end

function Web:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false
end

function Web:OnInitialized()
    
    ScriptActor.OnInitialized(self)
    
    if Server then
    
        self.active = false
        
        local activateFunc = function(self)
                                 self.active = true
                                 CheckAllEntsInTrigger(self)
                             end
        self:AddTimedCallback(activateFunc, kWebActivateTime)
        
        self:SetHealth(self:GetMaxHealth())
        self:SetArmor(self:GetMaxArmor())
        
        InitMixin(self, TriggerMixin)
        self:SetBox(Vector(2,2,2))
        
    end
    
    self:SetModel(Web.kModelName)
    
end

if Server then

    function Web:OnKill(attacker, doer, point, direction)
        ScriptActor.OnKill(self, attacker, doer, point, direction)
        self:TriggerEffects("death")
        DestroyEntity(self)
    end
    
    function Web:OnTriggerEntered(entity)
        CheckEntityTriggers(self, entity)
    end
    
    /**
     * LOL
     */
    function Web:GetCanSleep()
        return self:GetNumberOfEntitiesInTrigger() == 0
    end
    
    /**
     * We need to check when there are entities within the trigger area often.
     */
    function Web:OnUpdate(dt)
    
        local now = Shared.GetTime()
        self.lastWebUpdateTime = self.lastWebUpdateTime or now
        if now - self.lastWebUpdateTime >= 0.5 then
        
            CheckAllEntsInTrigger(self)
            self.lastWebUpdateTime = now
            
        end
        
    end
    
end

function Web:GetAttachPointOriginHardcoded(attachPointName)
    return self:GetOrigin() + self:GetCoords().yAxis * 0.01
end

function Web:ComputeDamageOverride(attacker, damage, damageType, doer)
    //Print(ToString(doer.kMapName))
    if doer.kMapName ~= "welder" and doer.kMapName ~= "grenade" and doer.kMapName ~= "handgrenade" then
        return 0
    else
        return damage
    end
end

function Web:OnDestroy()

    if self._renderModel ~= nil then
    
        Client.DestroyRenderModel(self._renderModel)
        self._renderModel = nil
        
    end
    
    if self.physicsModel then
    
        Shared.DestroyCollisionObject(self.physicsModel)
        self.physicsModel = nil
        
    end
    
end

if Client then

    function Web:OnGetIsVisible(visibleTable, viewerTeamNumber)
    
        local player = Client.GetLocalPlayer()
        
        if player and player:isa("Commander") and viewerTeamNumber == GetEnemyTeamNumber(self:GetTeamNumber()) then
            
            visibleTable.Visible = false
        
        end

    end

end

Shared.LinkClassToMap("Web", Web.kMapName, networkVars)