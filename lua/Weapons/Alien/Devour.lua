//
// lua\Weapons\Alien\Devour.lua
//

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/StompMixin.lua")

class 'Devour' (Ability)

Devour.kMapName = "devour"

local kAnimationGraph = PrecacheAsset("models/alien/onos/onos_view.animation_graph")
local kDevourCancelledSound = PrecacheAsset("sound/ns2c.fev/ns2c/alien/onos/devour_cancel")
local kDevourSoundTime = 4

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
    InitMixin(self, StompMixin)
    self.timeSinceLastDevourUpdate = 0
    self.lastPrimaryAttackTime = 0
    self.devouring = 0
    self.lastdevoursound = 0
end

function Devour:GetDeathIconIndex()
    return kDeathMessageIcon.Devour
end

function Devour:GetAnimationGraphName()
    return kAnimationGraph
end

function Devour:GetEnergyCost(player)
    if self:IsDevouringPlayer() then
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

function Devour:OnTag(tagName)

    PROFILE("Devour:OnTag")

    if tagName == "hit" then
    
        local player = self:GetParent()
        if player then
        
            self.lastPrimaryAttackTime = Shared.GetTime()
            local didHit, target, endPoint = AttackMeleeCapsule(self, player, kDevourInitialDamage, self:GetRange(), nil, false, EntityFilterOneAndIsa(player, "Babbler"))
            self.lastPrimaryAttackTime = Shared.GetTime()
            self:TriggerEffects("devour_fire")
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
function Devour:IsDevouringPlayer()
    return self.devouring ~= 0
end

function Devour:GetAttackDelay()
    return kDevourAttackDelay
end

function Devour:GetLastAttackTime()
    return self.lastPrimaryAttackTime
end

function Devour:OnPrimaryAttack(player)
    if player:GetEnergy() >= self:GetEnergyCost() and not self:GetHasAttackDelay(player) and not self:IsDevouringPlayer() then
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

    local function EndDevour(self)
        if self.devouring ~= 0 then
            local devouredplayer = Shared.GetEntity(self.devouring)
            StartSoundEffectAtOrigin(kDevourCancelledSound, self:GetOrigin())
            if devouredplayer and devouredplayer.OnDevouredEnd then
                devouredplayer:OnDevouredEnd()
            end
        end
        self.devouring = 0
    end
	
	local function CompleteDevour(self, devouredplayer)
		if devouredplayer.OnDevouredEnd then 
			devouredplayer:OnDevouredEnd()
		end
		self:TriggerEffects("devour_complete")
		self.devouring = 0
	end

    function Devour:OnProcessMove(input)
        if self.devouring ~= 0 then
            local devouredplayer = Shared.GetEntity(self.devouring)
            local player = self:GetParent()
            if devouredplayer and player and player:GetIsAlive() then
                if self.timeSinceLastDevourUpdate + kDevourDigestionSpeed < Shared.GetTime() then   
                    //Player still being eaten, damage them
                    self.timeSinceLastDevourUpdate = Shared.GetTime()
                    player:AddHealth(kDevourHealthPerSecond, true, (player:GetMaxHealth() - player:GetHealth() ~= 0))
                    if self.lastdevoursound + kDevourSoundTime < Shared.GetTime() then
                        self:TriggerEffects("devour_hit")
                        self.lastdevoursound = Shared.GetTime()
                    end
                    if self:DoDamage(kDevourDamage, devouredplayer, player:GetOrigin(), 0, "none") then
                        CompleteDevour(self, devouredplayer)
                    end
                end
            else
                EndDevour(self)
            end
        end
    end

    function Devour:OnDestroy()
		EndDevour(self)
        Ability.OnDestroy(self)        
    end
    
    function Devour:OnKillPlayer(player, killer, doer, point, direction)   
        EndDevour(self)    
    end
    
    function Devour:OnForceUnDevour()    
        EndDevour(self)
    end
    
end

Shared.LinkClassToMap("Devour", Devour.kMapName, networkVars)