// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Marine\Welder.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
//    Weapon used for repairing structures and armor of friendly players (marines,jetpackers).
//    Uses hud slot 3 (replaces axe)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Weapon.lua")
Script.Load("lua/PickupableWeaponMixin.lua")

class 'Welder' (Weapon)

Welder.kMapName = "welder"

Welder.kModelName = PrecacheAsset("models/marine/welder/welder.model")
Welder.kViewModelName = PrecacheAsset("models/marine/welder/welder_view.model")
local kAnimationGraph = PrecacheAsset("models/marine/welder/welder_view.animation_graph")

kWelderHUDSlot = 4

local welderTraceExtents = Vector(0.4, 0.4, 0.4)

local networkVars =
{
    welding = "boolean",
    loopingSoundEntId = "entityid"
}

local kWeldRange = 1.4

local kWelderEffectRate = 1.0

local kFireLoopingSound = PrecacheAsset("sound/NS2.fev/marine/welder/weld")

function Welder:OnCreate() 

    Weapon.OnCreate(self)
    
    self.welding = false
    
    InitMixin(self, PickupableWeaponMixin, { kRecipientType = "Marine" })
    
    self.loopingSoundEntId = Entity.invalidId
    
    if Server then
    
        self.loopingFireSound = Server.CreateEntity(SoundEffect.kMapName)
        self.loopingFireSound:SetAsset(kFireLoopingSound)
        // SoundEffect will automatically be destroyed when the parent is destroyed (the Welder).
        self.loopingFireSound:SetParent(self)
        self.loopingSoundEntId = self.loopingFireSound:GetId()
        
    end
    
end

function Welder:OnInitialized()

    self:SetModel(Welder.kModelName)
    
    Weapon.OnInitialized(self)
    
    self.timeWeldStarted = 0
    self.timeLastWeld = 0
    
end

function Welder:GetViewModelName()
    return Welder.kViewModelName
end

function Welder:GetAnimationGraphName()
    return kAnimationGraph
end

function Welder:GetHUDSlot()
    return kWelderHUDSlot
end

function Welder:GetIsDroppable()
    return true
end

function Welder:GetWeight()
    return kWelderWeight
end

function Welder:OnHolster(player)

    Weapon.OnHolster(self, player)
    
    self.welding = false
    // cancel muzzle effect
    self:TriggerEffects("welder_holster")
    player:SetPoseParam("welder", 0)
    
end
/*
function Welder:OnTouch(recipient)
    recipient:AddWeapon(self, false)
    Shared.PlayWorldSound(nil, Marine.kGunPickupSound, nil, recipient:GetOrigin())
end

function Welder:GetIsValidRecipient(player)
    if player then
        local hasWeapon = player:GetWeaponInHUDSlot(self:GetHUDSlot())
        if (not hasWeapon) and self.droppedtime + kPickupWeaponTimeLimit < Shared.GetTime() then
            return true
        end
    end
    return false
end
*/
function Welder:OnDraw(player, previousWeaponMapName)

    Weapon.OnDraw(self, player, previousWeaponMapName)
    
    self:SetAttachPoint(Weapon.kHumanAttachPoint)
    self.welding = false
    
end

// for marine third person model pose, "builder" fits perfectly for this.
function Welder:OverrideWeaponName()
    return "builder"
end

// don't play 'welder_attack' and 'welder_attack_end' too often, would become annoying with the sound effects and also client fps
function Welder:OnPrimaryAttack(player)
    
    PROFILE("Welder:OnPrimaryAttack")
    
    if not self.welding then
    
        self:TriggerEffects("welder_start")
        self.timeWeldStarted = Shared.GetTime()
        
        if Server then
            self.loopingFireSound:Start()
        end
        
    end
    
    self.welding = true
    local hitPoint = nil
    
    if self.timeLastWeld + kWelderFireDelay < Shared.GetTime () then
    
        hitPoint = self:PerformWeld(player)
        self.timeLastWeld = Shared.GetTime()
        
    end
    
    if not self.timeLastWeldEffect or self.timeLastWeldEffect + kWelderEffectRate < Shared.GetTime() then
    
        self:TriggerEffects("welder_muzzle")
        self.timeLastWeldEffect = Shared.GetTime()
        
    end
    
    if Server then
    
        if (not self.timeLastWeldHitEffect or self.timeLastWeldHitEffect + 0.15 < Shared.GetTime()) and hitPoint then
        
            local coords = Coords.GetTranslation(hitPoint)
            self:TriggerEffects("welder_hit", {effecthostcoords = coords})
            self.timeLastWeldHitEffect = Shared.GetTime()
            
        end
        
    end
    
end

function Welder:GetDeathIconIndex()
    return kDeathMessageIcon.Welder
end

function Welder:OnPrimaryAttackEnd(player)

    if self.welding then
        self:TriggerEffects("welder_end")
    end
    
    self.welding = false
    
    if Server then
        self.loopingFireSound:Stop()
    end
    
end

function Welder:Dropped(prevOwner)

    Weapon.Dropped(self, prevOwner)
    
    if Server then
        self.loopingFireSound:Stop()
    end
    
end

function Welder:GetRange()
    return kWeldRange
end

function Welder:GetReplacementWeaponMapName()
    return HandGrenades.kMapName
end

// repair rate increases over time
function Welder:GetRepairRate(repairedEntity)

    local repairRate = kWelderRate
    if repairedEntity.GetReceivesStructuralDamage and repairedEntity:GetReceivesStructuralDamage() then
        repairRate = repairRate * kWelderStructureMultipler
    end
    
    return repairRate
    
end

function Welder:GetMeleeBase()
    return 2, 2
end

function Welder:PerformWeld(player)

    local attackDirection = player:GetViewCoords().zAxis
    local success = false
    local didHit, target, endPoint, direction, surface = CheckMeleeCapsule(self, player, 0, self:GetRange(), nil, true)
    
    local trace = TraceMeleeBox(self, player:GetEyePos(), attackDirection, welderTraceExtents, self:GetRange(), PhysicsMask.Melee, EntityFilterTwo(self, player))
    
    if didHit and target and HasMixin(target, "Live") then
        
        if GetAreEnemies(player, target) then
            self:DoDamage(kWelderDamage, target, endPoint, attackDirection)
            success = true     
        elseif player:GetTeamNumber() == target:GetTeamNumber() and HasMixin(target, "Weldable") then
        
            if target:GetHealthScalar() < 1 then
                
                local prevHealthScalar = target:GetHealthScalar()
                target:OnWeld(self, kWelderFireDelay)
                success = prevHealthScalar ~= target:GetHealthScalar()
            
            end
            
            if HasMixin(target, "Construct") and target:GetCanConstruct(player) then
                target:Construct(kWelderFireDelay, player)
            end

            player:OnRepair(target, target:GetHealthScalar() < 1)
            
        end
        
    end
    
    if success then    
        return endPoint
    end
    
end

function Welder:GetShowDamageIndicator()
    return true
end

// copied from player:PerformUseTrace (exluded attach point check here)
function Welder:PerformWeldTrace(player)

    local trace = TraceMeleeBox(self, player:GetEyePos(), player:GetViewCoords().zAxis, welderTraceExtents, self:GetRange(), PhysicsMask.Melee, EntityFilterTwo(self, player))
    
    if trace.fraction < 1 and trace.entity ~= nil then
    
        if HasMixin(trace.entity, "Weldable") then
            return trace.entity, trace.endPoint, trace.normal
        end
        
    end
    
    return nil, nil
    
end

function Welder:OnUpdateAnimationInput(modelMixin)

    PROFILE("Welder:OnUpdateAnimationInput")
    
    modelMixin:SetAnimationInput("activity", ConditionalValue(self.welding, "primary", "none"))
    modelMixin:SetAnimationInput("welder", true)
    
end

function Welder:UpdateViewModelPoseParameters(viewModel)
    viewModel:SetPoseParam("welder", 1)    
end

function Welder:OnUpdatePoseParameters(viewModel)

    PROFILE("Welder:OnUpdatePoseParameters")
    self:SetPoseParam("welder", 1)
    
end

Shared.LinkClassToMap("Welder", Welder.kMapName, networkVars)