// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Flamethrower.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) 
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Weapon.lua")
Script.Load("lua/PickupableWeaponMixin.lua")
Script.Load("lua/IdleAnimationMixin.lua")

class 'Flamethrower' (ClipWeapon)

if Client then
    Script.Load("lua/Weapons/Marine/Flamethrower_Client.lua")
end

Flamethrower.kMapName = "flamethrower"

Flamethrower.kModelName = PrecacheAsset("models/marine/flamethrower/flamethrower.model")
local kViewModels = GenerateMarineViewModelPaths("flamethrower")
local kAnimationGraph = PrecacheAsset("models/marine/flamethrower/flamethrower_view.animation_graph")

local kFireLoopingSound = PrecacheAsset("sound/NS2.fev/marine/flamethrower/attack_loop")

local kRange = kFlamethrowerRange
local kConeWidth = 0.08
local kIdleAnimations = {"idle", "idle_fingers", "idle_clean"}

local networkVars =
{ 
    createParticleEffects = "boolean",
    loopingSoundEntId = "entityid"
}

function Flamethrower:OnCreate()

    ClipWeapon.OnCreate(self)
    
    self.loopingSoundEntId = Entity.invalidId
    
    if Server then
    
        self.createParticleEffects = false
        
        self.loopingFireSound = Server.CreateEntity(SoundEffect.kMapName)
        self.loopingFireSound:SetAsset(kFireLoopingSound)
        self.loopingFireSound:SetParent(self)
        self.loopingSoundEntId = self.loopingFireSound:GetId()
        
    elseif Client then
    
        self:SetUpdates(true)
        self.lastAttackEffectTime = 0.0
        InitMixin(self, IdleAnimationMixin)
        
    end
    
    InitMixin(self, PickupableWeaponMixin)

end

function Flamethrower:OnDestroy()

    ClipWeapon.OnDestroy(self)
    
    // The loopingFireSound was already destroyed at this point, clear the reference.
    if Server then
        self.loopingFireSound = nil
    elseif Client then
    
        if self.trailCinematic then
            Client.DestroyTrailCinematic(self.trailCinematic)
            self.trailCinematic = nil
        end
        
        if self.pilotCinematic then
            Client.DestroyCinematic(self.pilotCinematic)
            self.pilotCinematic = nil
        end
        
    end
    
end

function Flamethrower:GetAnimationGraphName()
    return kAnimationGraph
end

function Flamethrower:GetWeight()
    return kFlamethrowerWeight + ((math.ceil(self.ammo / self:GetClipSize()) + math.ceil(self.clip / self:GetClipSize())) * kFlamethrowerGunClipWeight)
end

function Flamethrower:OnHolster(player)

    ClipWeapon.OnHolster(self, player)
    
    self.createParticleEffects = false
    
end

function Flamethrower:OnDraw(player, previousWeaponMapName)

    ClipWeapon.OnDraw(self, player, previousWeaponMapName)
    
    self.createParticleEffects = false
    
end

function Flamethrower:GetClipSize()
    return kFlamethrowerClipSize
end

function Flamethrower:CreatePrimaryAttackEffect(player)
    self.timeOfLastPrimaryAttack = Shared.GetTime()
end

function Flamethrower:GetRange()
    return kFlamethrowerRange
end

function Flamethrower:GetViewModelName(sex, variant)
    return kViewModels[sex][variant]
end

local function ApplyConeDamage(self, player)
    
    local eyePos  = player:GetEyePos()    
    local ents = {}

    local fireDirection = player:GetViewCoords().zAxis
    local extents = Vector(kConeWidth, kConeWidth, kConeWidth)
    local remainingRange = self:GetRange()
    
    local startPoint = Vector(eyePos)
    local filterEnts = {self, player}
    
    for i = 1, 20 do
    
        if remainingRange <= 0 then
            break
        end
        
        local trace = TraceMeleeBox(self, startPoint, fireDirection, extents, remainingRange, PhysicsMask.Bullets, EntityFilterList(filterEnts))
        
        //DebugLine(startPoint, trace.endPoint, 0.3, 1, 0, 0, 1)
        
        if trace.fraction ~= 1 then
        
            if trace.entity then
            
                if HasMixin(trace.entity, "Live") then
                    table.insertunique(ents, trace.entity)
                end
                
                table.insertunique(filterEnts, trace.entity)
                
            else
            
                // Make another trace to see if the shot should get deflected.
                local lineTrace = Shared.TraceRay(startPoint, startPoint + remainingRange * fireDirection, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(player))
                
                if lineTrace.fraction < 0.8 then
                
                    fireDirection = fireDirection + trace.normal * 0.55
                    fireDirection:Normalize()
                    
                end
                
                remainingRange = remainingRange - (trace.endPoint - startPoint):GetLength()
                startPoint = trace.endPoint // + fireDirection * kConeWidth * 2
                
            end
        
        else
            break
        end

    end
    
    for index, ent in ipairs(ents) do
    
        if ent ~= player then
        
            local toEnemy = GetNormalizedVector(ent:GetModelOrigin() - eyePos)
            self:DoDamage(kFlamethrowerDamage, ent, ent:GetModelOrigin(), toEnemy)
            
        end
    
    end

end

local function ShootFlame(self, player)

    local viewAngles = player:GetViewAngles()
    local viewCoords = viewAngles:GetCoords()
    
    viewCoords.origin = self:GetBarrelPoint(player) + viewCoords.zAxis * (-0.4) + viewCoords.xAxis * (-0.2)
    local endPoint = self:GetBarrelPoint(player) + viewCoords.xAxis * (-0.2) + viewCoords.yAxis * (-0.3) + viewCoords.zAxis * self:GetRange()
    
    local trace = Shared.TraceRay(viewCoords.origin, endPoint, CollisionRep.Damage, PhysicsMask.Flame, EntityFilterAll())
    
    local range = (trace.endPoint - viewCoords.origin):GetLength()
    if range < 0 then
        range = range * (-1)
    end
    
    if trace.endPoint ~= endPoint and trace.entity == nil then
    
        local angles = Angles(0,0,0)
        angles.yaw = GetYawFromVector(trace.normal)
        angles.pitch = GetPitchFromVector(trace.normal) + (math.pi/2)
        
        local normalCoords = angles:GetCoords()
        normalCoords.origin = trace.endPoint
        range = range - 3
        
    end
    
    ApplyConeDamage(self, player)
    
    TEST_EVENT("Flamethrower primary attack")
    
end

function Flamethrower:FirePrimary(player, bullets, range, penetration)
    ShootFlame(self, player)
end

function Flamethrower:GetDeathIconIndex()
    return kDeathMessageIcon.HeavyMachineGun 
end

function Flamethrower:GetHUDSlot()
    return kPrimaryWeaponSlot
end

function Flamethrower:GetIsAffectedByWeaponUpgrades()
    return true
end

function Flamethrower:OnPrimaryAttack(player)

    if not self:GetIsReloading() then
    
        ClipWeapon.OnPrimaryAttack(self, player)
        
        if self:GetIsDeployed() and self:GetClip() > 0 and self:GetPrimaryAttacking() then
        
            if not self.createParticleEffects then
                self:TriggerEffects("flamethrower_attack_start")
            end
        
            self.createParticleEffects = true
            
            if Server and not self.loopingFireSound:GetIsPlaying() then
                self.loopingFireSound:Start()
            end
            
        end
        
        if self.createParticleEffects and self:GetClip() == 0 then
        
            self.createParticleEffects = false
            
            if Server then
                self.loopingFireSound:Stop()
            end
            
        end
    
        // Fire the cool flame effect periodically
        // Don't crank the period too low - too many effects slows down the game a lot.
        if Client and self.createParticleEffects and self.lastAttackEffectTime + 0.5 < Shared.GetTime() then
            
            self:TriggerEffects("flamethrower_attack")
            self.lastAttackEffectTime = Shared.GetTime()

        end
        
    end
    
end

function Flamethrower:OnPrimaryAttackEnd(player)

    ClipWeapon.OnPrimaryAttackEnd(self, player)

    self.createParticleEffects = false
        
    if Server then    
        self.loopingFireSound:Stop()        
    end
    
end

function Flamethrower:OnReload(player)

    if self:CanReload() then
    
        if Server then
        
            self.createParticleEffects = false
            self.loopingFireSound:Stop()
        
        end
        
        self:TriggerEffects("reload")
        self.reloading = true
        
    end
    
end

function Flamethrower:GetHasSecondary(player)
    return false
end

function Flamethrower:GetSwingSensitivity()
    return 0.8
end

function Flamethrower:Dropped(prevOwner)

    ClipWeapon.Dropped(self, prevOwner)
    
    if Server then
    
        self.createParticleEffects = false
        self.loopingFireSound:Stop()
        
    end
    
end

function Flamethrower:GetAmmoPackMapName()
    return FlamethrowerAmmo.kMapName
end

function Flamethrower:GetNotifiyTarget()
    return false
end

function Flamethrower:GetIdleAnimations()
    return kIdleAnimations
end

if Server then

    function Flamethrower:OnKill()
        DestroyEntity(self)
    end
    
    function Flamethrower:GetSendDeathMessageOverride()
        return false
    end
    
end

if Client then

    function Flamethrower:GetUIDisplaySettings()
        return { xSize = 128, ySize = 256, script = "lua/GUIFlamethrowerDisplay.lua" }
    end

end

Shared.LinkClassToMap("Flamethrower", Flamethrower.kMapName, networkVars)
