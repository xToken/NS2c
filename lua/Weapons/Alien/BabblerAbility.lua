// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\BabblerAbility.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// Spit attack on primary.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Babbler.lua")
Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/BabblerPheromone.lua")
Script.Load("lua/Weapons/Alien/HealSprayMixin.lua")

class 'BabblerAbility' (Ability)

BabblerAbility.kMapName = "babblerability"

local kAnimationGraph = PrecacheAsset("models/alien/gorge/gorge_view.animation_graph")
local kPheromoneTraceWidth = 0.3
local kPlayerVelocityFraction = 0.5
local kProjectileVelocity = 14

local networkVars = { }

AddMixinNetworkVars(HealSprayMixin, networkVars)

function BabblerAbility:OnCreate()

    Ability.OnCreate(self)
    
    self.primaryAttacking = false
    
    InitMixin(self, HealSprayMixin)
    
    if Client then
        self.babblerMoveType = kBabblerMoveType.Move
    elseif Server then
        self.timeLastThrown = 0
    end
    
end

function BabblerAbility:GetAnimationGraphName()
    return kAnimationGraph
end

function BabblerAbility:GetEnergyCost(player)
    return kBabblerPheromoneEnergyCost
end

function BabblerAbility:GetHUDSlot()
    return 4
end

function BabblerAbility:GetSecondaryTechId()
    return kTechId.Spray
end

function BabblerAbility:GetPrimaryEnergyCost()
    return kBabblerPheromoneEnergyCost
end

function BabblerAbility:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() then
        self.primaryAttacking = true
    else
        self.primaryAttacking = false
    end
    
end

function BabblerAbility:OnPrimaryAttackEnd(player)

    Ability.OnPrimaryAttackEnd(self, player)
    
    self.primaryAttacking = false
    
end

function BabblerAbility:OnUpdateAnimationInput(modelMixin)

    PROFILE("BabblerAbility:OnUpdateAnimationInput")

    modelMixin:SetAnimationInput("ability", "spit")
    
    local activityString = "none"
    if self.primaryAttacking then
        activityString = "primary"
    end
    modelMixin:SetAnimationInput("activity", activityString)
    
end

function BabblerAbility:GetRange()
    return 8
end

local function FindTarget(self, player)

    local startPoint = player:GetEyePos()
    local direction = player:GetViewCoords().zAxis
    local extents = GetDirectedExtentsForDiameter(direction, kPheromoneTraceWidth)
    
    local trace = Shared.TraceBox(extents, startPoint, startPoint + direction * self:GetRange(), CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOneAndIsa(player, "Babbler"))
    
    local targetEntity = trace.entity
    local endPoint = trace.fraction < 1 and (trace.endPoint + trace.normal * kPheromoneTraceWidth) or nil
    
    return targetEntity, endPoint

end

local function CreateBabblerPheromone(self, player)
    
    // destroy at first all other pheromones
    if Server then
        for _, pheromone in ientitylist(Shared.GetEntitiesWithClassname("BabblerPheromone")) do
            if pheromone:GetOwner() == player then
                DestroyEntity(pheromone)
            end
        end
    end
    
    if Server or (Client and Client.GetIsControllingPlayer()) then
    
        local viewAngles = player:GetViewAngles()
        local velocity = player:GetVelocity()
        local viewCoords = viewAngles:GetCoords()
        local startPoint = player:GetEyePos() + viewCoords.zAxis * 1.5
        local startVelocity = velocity * kPlayerVelocityFraction + viewCoords.zAxis * kProjectileVelocity

        local babble = player:CreatePredictedProjectile("BabblerPheromone", startPoint, startVelocity, 0.7, nil, 8, true)
        
        local target, endPoint = FindTarget(self, player)
        if target and (not HasMixin(target, "Live") or target:GetIsAlive()) and ( GetAreEnemies(self, target) or    
            (GetAreFriends(self, target) and HasMixin(target, "BabblerCling")) ) then
        
            babble:SetOrigin(endPoint)
            babble:ProcessHit(target)
        
        end
        
    end

end

function BabblerAbility:OnTag(tagName)

    PROFILE("BabblerAbility:OnTag")

    if self.primaryAttacking and tagName == "shoot" then
    
        local player = self:GetParent()
        
        if player then
        
            player:TriggerEffects("babblerability_attack")
            CreateBabblerPheromone(self, player)
            
            if Server then
                self.timeLastThrown = Shared.GetTime()
            end
            
            player:DeductAbilityEnergy(self:GetEnergyCost())
            
        end
        
    end
    
end

function BabblerAbility:GetRecentlyThrown()
    return self.timeLastThrown + 3 > Shared.GetTime()
end

if Client then

    local function CleanUpGUI(self)
    
        if self.babblerMoveGUI then
        
            GetGUIManager():DestroyGUIScript(self.babblerMoveGUI)
            self.babblerMoveGUI = nil
            
        end
        
    end
    
    local function CreateGUI(self)
    
        local player = self:GetParent()
        if not self.babblerMoveGUI and player and player:GetIsLocalPlayer() then        
            self.babblerMoveGUI = GetGUIManager():CreateGUIScript("GUIBabblerMoveIndicator")        
        end
    
    end

    function BabblerAbility:OnProcessIntermediate()
    
        //update babbler move type for GUI
        local player = self:GetParent()
        if player then
        
            local target, endPoint = FindTarget(self, player)
            
            if target and GetAreEnemies(self, target) and HasMixin(target, "Live") and target:GetIsAlive() then
                self.babblerMoveType = kBabblerMoveType.Attack
            
            elseif target and GetAreFriends(self, target) and HasMixin(target, "BabblerCling") and target:GetIsAlive() then
                self.babblerMoveType = kBabblerMoveType.Cling
            
            else
                self.babblerMoveType = kBabblerMoveType.Move
            end  
        
        end
        
    end

    function BabblerAbility:GetBabblerMoveType()
        return self.babblerMoveType
    end
    
    function BabblerAbility:OnDrawClient()
        
        CreateGUI(self)
        Ability.OnDrawClient(self)
        
    end
    
    function BabblerAbility:OnHolsterClient()
    
        CleanUpGUI(self)
        Ability.OnHolsterClient(self)

    end 
    
    function BabblerAbility:OnKillClient()
        CleanUpGUI(self)
    end
    
    function BabblerAbility:OnDestroy()
    
        CleanUpGUI(self)
        Ability.OnDestroy(self)
    
    end

end

Shared.LinkClassToMap("BabblerAbility", BabblerAbility.kMapName, networkVars)