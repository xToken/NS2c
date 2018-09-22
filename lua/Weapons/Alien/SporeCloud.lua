-- Natural Selection 2 'Classic' Mod
-- Source located at - https://github.com/xToken/NS2c
-- lua\SporeCloud.lua
-- - Dragon

Script.Load("lua/TeamMixin.lua")
Script.Load("lua/OwnerMixin.lua")
Script.Load("lua/DamageMixin.lua")

class 'SporeCloud' (Entity)

SporeCloud.kMapName = "SporeCloud"

SporeCloud.kLoopingEffect = PrecacheAsset("cinematics/alien/lerk/spores.cinematic")
local kSporesSound = PrecacheAsset("sound/ns2c.fev/ns2c/alien/lerk/spore_hit")

local gHurtBySpores = { }
-- duration of cinematic, increase cinematic duration and kSporeCloudDuration to 12 to match the old value from Crag.lua
SporeCloud.kMaxRange = 20
SporeCloud.kThinkTime = 0.5
SporeCloud.kTravelSpeed = 60 // meters per second

local networkVars = { }

function SporeCloud:OnCreate()

    Entity.OnCreate(self)
    
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    if Server then
    
        InitMixin(self, OwnerMixin)
        
        self.nextDamageTime = 0
 
    end
    
    self:SetUpdates(true)
    self.soundplayed = false
    self.createTime = Shared.GetTime()
    self.endOfDamageTime = self.createTime + kSporeDuration 
    self.destroyTime = self.endOfDamageTime + 2

end

if Client then

    function SporeCloud:OnDestroy()

        Entity.OnDestroy(self)
        
        if self.sporeEffect then
        
            Client.DestroyCinematic(self.sporeEffect)
            self.sporeEffect = nil
            
        end

    end

end

function SporeCloud:GetRepeatCinematic()
    return SporeCloud.kSporeCloudEffect
end
    
function SporeCloud:GetLifeSpan()
    return kSporeDuration
end

function SporeCloud:SetTravelDestination(position)
    self.destination = position
end

function SporeCloud:GetThinkTime()
    return SporeCloud.kThinkTime
end

function SporeCloud:GetDeathIconIndex()
    return kDeathMessageIcon.SporeCloud
end

function SporeCloud:GetDamageType()
    return kSporeDamageType
end

local function GetEntityRecentlyHurt(entityId, time)

    for index, pair in ipairs(gHurtBySpores) do
        if pair[1] == entityId and pair[2] > time then
            return true
        end
    end
    
    return false
    
end

local function SetEntityRecentlyHurt(entityId)

    for index, pair in ipairs(gHurtBySpores) do
        if pair[1] == entityId then
            table.remove(gHurtBySpores, index)
        end
    end
    
    table.insert(gHurtBySpores, {entityId, Shared.GetTime()})
    
end

-- Have damage radius grow to maximum non-instantly
function SporeCloud:GetDamageRadius()
    
    local scalar = Clamp((Shared.GetTime() - self.createTime) * 4, 0, 1)
    return scalar * kSporeRadius
    
end

function SporeCloud:OnUpdate(deltaTime)

    if self.destination then
    
        local travelVector = self.destination - self:GetOrigin()
        if travelVector:GetLength() > 0.3 then
            local distanceFraction = (self.destination - self:GetOrigin()):GetLength() / SporeCloud.kMaxRange
            self:SetOrigin( self:GetOrigin() + GetNormalizedVector(travelVector) * deltaTime * SporeCloud.kTravelSpeed * distanceFraction )
        end
        if travelVector:GetLength() < 3 and not self.soundplayed then
            StartSoundEffectAtOrigin(kSporesSound, self:GetOrigin())
            self.soundplayed = true
        end
    
    end
    
    local time = Shared.GetTime()
    if Server then 
        -- we do damage until the spores have died away. 
        if time > self.nextDamageTime and time < self.endOfDamageTime then

            self:SporeDamage(time)
            self.nextDamageTime = time + kSporeDamageDelay
        end
        
        if  time > self.destroyTime then
            DestroyEntity(self)
        end
     elseif Client then

        if self.sporeEffect then        
            self.sporeEffect:SetCoords(self:GetCoords())            
        else
        
            self.sporeEffect = Client.CreateCinematic(RenderScene.Zone_Default) 
            self.sporeEffect:SetCinematic(SporeCloud.kLoopingEffect)
            self.sporeEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
            self.sporeEffect:SetCoords(self:GetCoords())
        
        end
    
    end

end 

if Server then

    function SporeCloud:SporeDamage(time)

        local enemies = GetEntitiesForTeam("Player", GetEnemyTeamNumber(self:GetTeamNumber()))
        local damageRadius = self:GetDamageRadius()
        
        local filterNonDoors = EntityFilterAllButIsa("Door")
        for index, entity in ipairs(enemies) do

            local attackPoint = entity:GetEyePos()        
            if (attackPoint - self:GetOrigin()):GetLength() < damageRadius then

                if not entity:isa("Commander") and not entity:isa("HeavyArmorMarine") and not GetEntityRecentlyHurt(entity:GetId(), (time - kSporeDamageDelay)) then

                    -- Make sure spores can "see" target
                    local trace = Shared.TraceRay(self:GetOrigin(), attackPoint, CollisionRep.Damage, PhysicsMask.Bullets, filterNonDoors)
                    if trace.fraction == 1.0 or trace.entity == entity then
                    
                        self:DoDamage(kSporeDamage , entity, trace.endPoint, (attackPoint - trace.endPoint):GetUnit(), "organic" )
                        
                        -- Spores can't hurt this entity for kSporeDamageDelay
                        SetEntityRecentlyHurt(entity:GetId())
                        
                    end
                    
                end
                
            end
            
        end
   end

   function SporeCloud:GetRemainingLifeTime()
        return math.min(0, self.endOfDamageTime - Shared.GetTime())
   end

end

Shared.LinkClassToMap("SporeCloud", SporeCloud.kMapName, networkVars)