//
// lua\Weapons\Alien\Devour.lua
//

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/StompMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/OwnerMixin.lua")
Script.Load("lua/DamageMixin.lua")

class 'Devour' (Ability)

Devour.kMapName = "devour"

//Digest too fast and youll hurt your stomache
Devour.kDigestionSpeed = 1
local kAttackRadius = 1.5
local kAttackOriginDistance = 2
local kAttackRange = 1.5

local kAnimationGraph = PrecacheAsset("models/alien/onos/onos_view.animation_graph")

local networkVars =
{
    lastPrimaryAttackTime = "time",
    devouring = "private entityid"
}

AddMixinNetworkVars(StompMixin, networkVars)

local function GetHasAttackDelay(self, player)

    local attackDelay = ConditionalValue( player:GetIsPrimaled(), (kDevourDelay / kPrimalScreamROFIncrease), kDevourDelay)
    //local upg, level = GetHasFocusUpgrade(player)
    //if upg and level > 0 then
        //attackDelay = attackDelay * (1 + ((1 / 3) * level))
    //end
    return self.lastPrimaryAttackTime + attackDelay > Shared.GetTime()
    
end
    
// required here to deals different damage depending on if we are goring
function Devour:GetDamageType()
    return kDevourDamageType
end    

function Devour:OnCreate()

    Ability.OnCreate(self)
    
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    if Server then
        InitMixin(self, OwnerMixin)
    end
    self.devouring = 0
    self.timeSinceLastDevourUpdate = 0
    self.lastPrimaryAttackTime = 0
    
end

function Devour:OnDestroy()
    if self:IsAlreadyEating() then
        self:OnDevourEnd()
    end
    ScriptActor.OnDestroy(self)
    
end

function Devour:GetDeathIconIndex()
    return kDeathMessageIcon.Gore
end

function Devour:OnDevourEnd()
    local food = Shared.GetEntity(self.devouring)
    if food then
        if not food.GetIsAlive or food:GetIsAlive() then
            if food.OnDevouredEnd then
                food:OnDevouredEnd()
            end
            if not food.physicsModel then
                food.physicsModel = Shared.CreatePhysicsModel(food.physicsModelIndex, true, food:GetCoords(), food)
            end
        end  
    end
    self.devouring = 0
end

function Devour:GetAnimationGraphName()
    return kAnimationGraph
end

function Devour:GetEnergyCost(player)
    if self:IsAlreadyEating() then
        return 101
    else
        return kDevourEnergyCost
    end
end

function Devour:GetHUDSlot()
    return 2
end

function Devour:OnHolster(player)
    Ability.OnHolster(self, player)  
    self:OnAttackEnd()
end

function Devour:GetIconOffsetY(secondary)
    return kAbilityOffset.Gore
end

function Devour:OnTag(tagName)

    PROFILE("Devour:OnTag")

    if tagName == "hit" then
    
        local player = self:GetParent()
        if player and not GetHasAttackDelay(self, player) then
        
            self.lastPrimaryAttackTime = Shared.GetTime()
            //local didHit, impactPoint, target = self:Attack(player)
            local didHit, target, endPoint = AttackMeleeCapsule(self, player, kDevourInitialDamage, kAttackRange)
            self.lastPrimaryAttackTime = Shared.GetTime()
            self:TriggerEffects("gore_attack")
            player:DeductAbilityEnergy(self:GetEnergyCost())
            if didHit and target and target:isa("Marine") then
                self:Devour(target)
            end
        end
    end    

end

function Devour:Devour(target)
    
    local allowed = true
    
    if target.GetIsDevourAllowed then
        allowed = target:GetIsDevourAllowed()
    end

    if allowed then
        self.devouring = target:GetId()
        if target.OnDevoured then
            target:OnDevoured()
        end
    end
    
end

//Silly onos, you cant eat multiple marines at once
function Devour:IsAlreadyEating()
    return self.devouring ~= 0
end

function Devour:OnPrimaryAttack(player)
    if player:GetEnergy() >= self:GetEnergyCost() and not GetHasAttackDelay(self, player) and not self:IsAlreadyEating() then
        self.primaryAttacking = true
    else
        self:OnAttackEnd()
    end 
end

function Devour:OnPrimaryAttackEnd(player)  
    Ability.OnPrimaryAttackEnd(self, player)
    self:OnAttackEnd()
end

function Devour:GetPrimaryAttackUsesFocus()
    return false
end

function Devour:GetisUsingPrimaryAttack()
    return self.primaryAttacking
end

function Devour:OnAttackEnd()
    self.primaryAttacking = false
end

function Devour:GetEffectParams(tableParams)
    Ability.GetEffectParams(self, tableParams)
end

function Devour:OnUpdateAnimationInput(modelMixin)

    local activityString = "none"
    local abilityString = "gore"
    local attackMarine = false   
    
    if self.primaryAttacking then
        activityString = "primary"        
    end
   
    modelMixin:SetAnimationInput("ability", abilityString) 
    modelMixin:SetAnimationInput("activity", activityString)
    modelMixin:SetAnimationInput("attack_marine", attackMarine)
    
end

Shared.LinkClassToMap("Devour", Devour.kMapName, networkVars)