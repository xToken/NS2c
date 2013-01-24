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

local kAnimationGraph = PrecacheAsset("models/alien/onos/onos_view.animation_graph")

local networkVars =
{
    lastPrimaryAttackTime = "time",
    devouring = "private entityid"
}

AddMixinNetworkVars(StompMixin, networkVars)

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
    self.timeSinceLastDevourUpdate = 0
    self.lastPrimaryAttackTime = 0
    self.devouring = 0
    
end

function Devour:GetDeathIconIndex()
    return kDeathMessageIcon.Gore
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
    return 3
end

function Devour:OnHolster(player)
    Ability.OnHolster(self, player)  
    self:OnAttackEnd()
end

function Devour:GetRange()
    return kDevourRange
end

function Devour:GetMeleeBase()
    return kDevourMeleeBaseWidth, kDevourMeleeBaseHeight
end

function Devour:GetIconOffsetY(secondary)
    return kAbilityOffset.Gore
end

function Devour:OnTag(tagName)

    PROFILE("Devour:OnTag")

    if tagName == "hit" then
    
        local player = self:GetParent()
        if player and not self:GetHasAttackDelay(self, player) then
        
            self.lastPrimaryAttackTime = Shared.GetTime()
            local didHit, target, endPoint = AttackMeleeCapsule(self, player, kDevourInitialDamage, self:GetRange())
            self.lastPrimaryAttackTime = Shared.GetTime()
            self:TriggerEffects("gore_attack")
            player:DeductAbilityEnergy(self:GetEnergyCost())
            if didHit and target and target:isa("Marine") then
                self:Devour(player, target)
            end
        end
    end    

end

function Devour:Devour(player, target)
    
    local allowed = true
    
    if target.GetIsDevourAllowed then
        allowed = target:GetIsDevourAllowed()
    end

    if allowed then
        self.devouring = target:GetId()
        if target.OnDevoured then
            target:OnDevoured(player)
        end
    end
    
end

//Silly onos, you cant eat multiple marines at once
function Devour:IsAlreadyEating()
    return self.devouring ~= 0
end

function Devour:GetAttackDelay()
    return kDevourAttackDelay
end

function Devour:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

function Devour:OnPrimaryAttack(player)
    if player:GetEnergy() >= self:GetEnergyCost() and not self:GetHasAttackDelay(self, player) and not self:IsAlreadyEating() then
        self.primaryAttacking = true
    else
        self:OnAttackEnd()
    end 
end

function Devour:OnPrimaryAttackEnd(player)  
    Ability.OnPrimaryAttackEnd(self, player)
    self:OnAttackEnd()
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

if Server then

    function Devour:OnProcessMove(input)
        if self.devouring ~= 0 then
            local food = Shared.GetEntity(self.devouring)
            local player = self:GetParent()
            if food and player and player:GetIsAlive() then
                if self.timeSinceLastDevourUpdate + kDevourDigestionSpeed < Shared.GetTime() then   
                    //Player still being eaten, damage them
                    self.timeSinceLastDevourUpdate = Shared.GetTime()
                    player:AddHealth(kDevourHealthPerSecond)
                    if self:DoDamage(kDevourDamage, food, self:GetOrigin(), 0, "none") then
                        if food.OnDevouredEnd then 
                            food:OnDevouredEnd()
                        end
                        self.devouring = 0
                    end
                end
            else
                self.devouring = 0
            end
        end
    end

    local function EndDevour(self)
        if self.devouring ~= 0 then
            local food = Shared.GetEntity(self.devouring)
            if food and food.OnDevouredEnd then
                food:OnDevouredEnd()
            end
        end
        self.devouring = 0
    end

    function Devour:OnDestroy()
        Ability.OnDestroy(self)        
        EndDevour(self)
    end
    
    function Devour:OnKillPlayer(player, killer, doer, point, direction)   
        EndDevour(self)    
    end
    
    function Devour:OnForceUnDevour()    
        EndDevour(self)
    end
    
end

Shared.LinkClassToMap("Devour", Devour.kMapName, networkVars)