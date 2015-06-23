// Natural Selection 2 'Classic' Mod
// lua\UmbraCloud.lua
// - Dragon

Script.Load("lua/TeamMixin.lua")
Script.Load("lua/OwnerMixin.lua")
Script.Load("lua/DamageMixin.lua")

class 'UmbraCloud' (Entity)

UmbraCloud.kMapName = "UmbraCloud"

UmbraCloud.kUmbraCloudEffect = PrecacheAsset("cinematics/alien/Crag/umbra.cinematic")
local kUmbraSound = PrecacheAsset("sound/NS2.fev/alien/structures/crag/umbra")

// duration of cinematic, increase cinematic duration and kUmbraCloudDuration to 12 to match the old value from Crag.lua
UmbraCloud.kMaxRange = 20
local kThinkTime = 0.5
UmbraCloud.kTravelSpeed = 60 // meters per second

local networkVars = { }

function UmbraCloud:OnCreate()

    InitMixin(self, TeamMixin)
    
    if Server then
        InitMixin(self, OwnerMixin)
        self.nextUpdateTime = 0
    end
    
    self:SetUpdates(true)
    self.soundplayed = false
    self.createTime = Shared.GetTime()
    self.endOfUmbraTime = self.createTime + kUmbraDuration
    self.destroyTime = self.endOfUmbraTime + 2

end

if Client then

    function UmbraCloud:OnDestroy()
        Entity.OnDestroy(self)
        if self.umbraEffect then
            Client.DestroyCinematic(self.umbraEffect)
            self.umbraEffect = nil
        end
    end

end

function UmbraCloud:SetTravelDestination(position)
    self.destination = position
end

function UmbraCloud:GetThinkTime()
    return kThinkTime
end

function UmbraCloud:OnUpdate(deltaTime)
    
    if self.destination then
    
        local travelVector = self.destination - self:GetOrigin()
        if travelVector:GetLength() > 0.3 then
            local distanceFraction = (self.destination - self:GetOrigin()):GetLength() / UmbraCloud.kMaxRange
            self:SetOrigin( self:GetOrigin() + GetNormalizedVector(travelVector) * deltaTime * UmbraCloud.kTravelSpeed * distanceFraction )
        end
        if travelVector:GetLength() < 3 and not self.soundplayed then
            StartSoundEffectAtOrigin(kUmbraSound, self:GetOrigin())
            self.soundplayed = true
        end
    
    end
           
    local time = Shared.GetTime()
    if Server then 
        if time > self.nextUpdateTime and time < self.endOfUmbraTime then
            self.nextUpdateTime = time + kThinkTime
            self:UpdateUmbraEntities()
        end
        
        if  time > self.destroyTime then
            DestroyEntity(self)
        end
        
     elseif Client then

        if self.umbraEffect then        
            self.umbraEffect:SetCoords(self:GetCoords())            
        else
        
            self.umbraEffect = Client.CreateCinematic(RenderScene.Zone_Default)
            self.umbraEffect:SetCinematic(UmbraCloud.kUmbraCloudEffect)
            self.umbraEffect:SetRepeatStyle(Cinematic.Repeat_Endless)
            self.umbraEffect:SetCoords(self:GetCoords())
        
        end
    
    end

end

if Server then

   function UmbraCloud:UpdateUmbraEntities()

        local friendlies = GetEntitiesForTeam("Player", self:GetTeamNumber())
        local filterNonDoors = EntityFilterAllButIsa("Door")
        for index, entity in ipairs(friendlies) do

            local attackPoint = entity:GetEyePos()        
            if (attackPoint - self:GetOrigin()):GetLength() < kUmbraRadius then
            
                local trace = Shared.TraceRay(self:GetOrigin(), attackPoint, CollisionRep.Damage, PhysicsMask.Bullets, filterNonDoors)
                if trace.fraction == 1.0 or trace.entity == entity then
                    if HasMixin(entity, "Umbra") then
                        entity:SetHasUmbra()
                    end
                end
                
            end
            
        end
        
    end
    
end
Shared.LinkClassToMap("UmbraCloud", UmbraCloud.kMapName, networkVars)