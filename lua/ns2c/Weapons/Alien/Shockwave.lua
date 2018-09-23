--=============================================================================
--
-- lua\Weapons\Alien\Shockwave.lua
--
-- Created by Andread Urwalek (andi@unknownworlds.com)
-- Copyright (c) 2011, Unknown Worlds Entertainment, Inc.
--
--=============================================================================

Script.Load("lua/Weapons/Projectile.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/ScriptActor.lua")

class 'Shockwave' (ScriptActor)

Shockwave.kMapName = "Shockwave"
-- Shockwave.kModelName = PrecacheAsset("models/marine/rifle/rifle_grenade.model") // for debugging
Shockwave.kRadius = 0.06
local kShockwaveCrackMaterial = PrecacheAsset("cinematics/vfx_materials/decals/shockwave_crack.material")

local networkVars = { }

AddMixinNetworkVars(networkVars, TeamMixin)
AddMixinNetworkVars(networkVars, LOSMixin)

local kShockwaveLifeTime = 0.7
local kUpdateRate = 0.1
local kShockWaveVelocity = 24

local function CreateCoords(xAxis, yAxis, zAxis)

    local coords = Coords()
    coords.xAxis = xAxis
    coords.yAxis = yAxis
    coords.zAxis = zAxis
    
    return coords

end

local kRotationCoords =
{
    CreateCoords(Vector.xAxis, Vector.yAxis, Vector.zAxis),
    CreateCoords(-Vector.xAxis, Vector.yAxis, -Vector.zAxis),
    CreateCoords(-Vector.xAxis, -Vector.yAxis, Vector.zAxis),
    CreateCoords(Vector.xAxis, -Vector.yAxis, -Vector.zAxis),
}

local function CreateEffect(self)

    local player = Client.GetLocalPlayer()
    local enemies = GetAreEnemies(self, player)
    --Not ideal, but parent sighted will be more up-to-date in most cases
    local showEffect = ( player and not enemies ) or ( enemies and self:GetParent():GetIsSighted() )

    if not showEffect then
        return true
    end

    local coords = self:GetCoords()
    local groundTrace = Shared.TraceRay(coords.origin, coords.origin - Vector.yAxis * 3, CollisionRep.Move, PhysicsMask.Movement, EntityFilterAllButIsa("Tunnel"))

    if groundTrace.fraction ~= 1 then
    
        coords.origin = groundTrace.endPoint
        
        coords.zAxis.y = 0
        coords.zAxis:Normalize()
        
        coords.xAxis.y = 0
        coords.xAxis:Normalize()
        
        coords.yAxis = coords.zAxis:CrossProduct(coords.xAxis)

        --self:TriggerEffects("shockwave_trail", { effecthostcoords = coords })
        Client.CreateTimeLimitedDecal(kShockwaveCrackMaterial, coords * kRotationCoords[math.random(1, #kRotationCoords)], 2.7, 6)
        
    end
    
    return true

end

function Shockwave:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, DamageMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    
    if Server then    
    
        self:AddTimedCallback(Shockwave.TimeUp, kShockwaveLifeTime)    
        self:AddTimedCallback(Shockwave.Detonate, 0.1)   
        self.damagedEntIds = {}
   
    end
    
    if Client then
        self:AddTimedCallback(CreateEffect, 0.1)
    end
    
end

local function DestroyShockwave(self)

    if Server then
    
        local owner = self:GetOwner()
        if owner then
        
            for i = 0, owner:GetNumChildren() - 1 do
            
                local child = owner:GetChildAtIndex(i)
                if HasMixin(child, "Stomp") then
                    child:UnregisterShockwave(self)
                end
                
            end
            
        end
        
        DestroyEntity(self)
        
    end
    
end

function Shockwave:TimeUp()

    DestroyShockwave(self)
    return false
    
end

-- called in on processmove server side by stompmixin
function Shockwave:UpdateShockwave(deltaTime)
 
	local bestEndPoint = nil
	local bestFraction = 0
    
    if self.tFirst == true then
		self.tFirst = false
		self:Detonate()
	end
    
	for i = 1, 4 do
        
		local offset = Vector.yAxis * (i-1) * 0.3
		local trace = Shared.TraceRay(self:GetOrigin() + offset, self:GetOrigin() + self:GetCoords().zAxis * 3.5 + offset, CollisionRep.Move, PhysicsMask.Movement, EntityFilterAllButIsa("Tunnel"))
		if Shared.GetTestsEnabled() then
			DebugLine(self:GetOrigin() + offset, trace.endPoint, 2, 1, 1, 1, 1)
		end
            
        if trace.fraction == 1 then
            
            bestEndPoint = trace.endPoint
            break
                
        elseif trace.fraction > bestFraction then
            
            bestEndPoint = trace.endPoint
            bestFraction = trace.fraction
            
		end
        
	end
        
	self.endPoint = bestEndPoint
	local origin = self:GetOrigin()
	origin.y = self.endPoint.y
	self:SetOrigin(origin)
		
	--DebugLine(origin, self.endPoint, 2, 1, 0, 0, 1)
    

     local newPosition = SlerpVector(self:GetOrigin(), self.endPoint, self:GetCoords().zAxis * kShockWaveVelocity * deltaTime)
	 
     if (newPosition - self.endPoint):GetLength() < 0.1 then
        DestroyShockwave(self)
     else
        self:SetOrigin(newPosition)
     end

end

function Shockwave:Detonate()

    local origin = self:GetOrigin()

    local groundTrace = Shared.TraceRay(origin, origin - Vector.yAxis * 3, CollisionRep.Move, PhysicsMask.Movement, EntityFilterAllButIsa("Tunnel"))
    local enemies = GetEntitiesWithMixinWithinRange("Live", groundTrace.endPoint, 2.2)
    
	if Shared.GetTestsEnabled() then
		DebugLine(origin,groundTrace.endPoint, 2, 1, 0, 1, 1)
    end
    
    -- never damage the owner
    local owner = self:GetOwner()
	local onosViewPos
    if owner then
		onosViewPos = owner:GetEyePos()
        table.removevalue(enemies, owner)
    end
    
    if groundTrace.fraction < 1 then
    
        for _, enemy in ipairs(enemies) do
        
            local enemyId = enemy:GetId()
			local ShouldStun = enemy:GetIsAlive() and not table.contains(self.damagedEntIds, enemyId)	//Sanity checks
			ShouldStun = ShouldStun and math.abs(enemy:GetOrigin().y - groundTrace.endPoint.y) < 0.8	//Ground checks
			if onosViewPos then
				ShouldStun = ShouldStun and not GetWallBetween(onosViewPos, enemy:GetOrigin(), enemy)	//LOS checks
			end
            if ShouldStun then
                
                self:DoDamage(kStompDamage, enemy, enemy:GetOrigin(), GetNormalizedVector(enemy:GetOrigin() - groundTrace.endPoint), "none")
                table.insert(self.damagedEntIds, enemyId)
                
                if not HasMixin(enemy, "GroundMove") or enemy:GetIsOnGround() then
                    self:TriggerEffects("shockwave_hit", { effecthostcoords = enemy:GetCoords() })
                end

                if HasMixin(enemy, "Stun") then
                    enemy:SetStun(kStunMarineTime)
                end  
                
            end
        
        end
    
    else
		DestroyShockwave(self)
	end
    
    return true

end

function Shockwave:GetDamageType()
    return kStompDamageType
end

function Shockwave:GetDeathIconIndex()
    return kDeathMessageIcon.Stomp
end

Shared.LinkClassToMap("Shockwave", Shockwave.kMapName, networkVars)
