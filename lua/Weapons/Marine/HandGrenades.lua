//
// lua\Weapons\Marine\HandGrenades.lua

Script.Load("lua/Weapons/Weapon.lua")
Script.Load("lua/Weapons/Marine/HandGrenade.lua")
Script.Load("lua/PickupableWeaponMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")

class 'HandGrenades' (Weapon)

HandGrenades.kMapName = "handgrenades"

HandGrenades.kModelName = PrecacheAsset("models/marine/rifle/rifle_grenade.model")

local kViewModelName = PrecacheAsset("models/marine/rifle/rifle_grenade.model")
local kAnimationGraph = PrecacheAsset("models/marine/mine/mine_view.animation_graph")
local kThrowDelay = 1.25

local networkVars =
{
    nadesLeft = string.format("integer (0 to %d)", kNumHandGrenades),
    throwing = "boolean"
}

function HandGrenades:OnCreate()

    Weapon.OnCreate(self)
    InitMixin(self, PickupableWeaponMixin, { kRecipientType = "Marine" })
    self.nadesLeft = kNumHandGrenades
    self.throwing = false
    self.throwntime = 0
    if Server then
        InitMixin(self, EntityChangeMixin)
    end

end

function HandGrenades:OnInitialized()

    Weapon.OnInitialized(self)
    
    self:SetModel(HandGrenades.kModelName)

end

function HandGrenades:GetNadesLeft()
    return self.nadesLeft
end

function HandGrenades:GetViewModelName()
    return kViewModelName
end

function HandGrenades:GetAnimationGraphName()
    return kAnimationGraph
end

function HandGrenades:GetSuffixName()
    return "handgrenades"
end

function HandGrenades:GetDropClassName()
    return "HandGrenades"
end

function HandGrenades:GetDropMapName()
    return HandGrenades.kMapName
end

function HandGrenades:GetHUDSlot()
    return 4
end

function HandGrenades:GetWeight()
    return kHandGrenadesWeight
end

function HandGrenades:OnPrimaryAttackEnd(player)
    self.throwing = false
end

function HandGrenades:GetIsDroppable()
    return true
end

local function ThrowGrenade(self, player)

    self:TriggerEffects("grenadelauncher_attack")

    if Server and player then
        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
        // Make sure start point isn't on the other side of a wall or object
        local startPoint = player:GetEyePos() - (viewCoords.zAxis * 0.2)
        local trace = Shared.TraceRay(startPoint, startPoint + viewCoords.zAxis * 25, CollisionRep.Default, PhysicsMask.Bullets, EntityFilterOne(player))

        // make sure the grenades flies to the crosshairs target
        local grenadeStartPoint = player:GetEyePos() + viewCoords.zAxis * .5 - viewCoords.xAxis * .1 - viewCoords.yAxis * .25

        // if we would hit something use the trace endpoint, otherwise use the players view direction (for long range shots)
        local grenadeDirection = ConditionalValue(trace.fraction ~= 1, trace.endPoint - grenadeStartPoint, viewCoords.zAxis)
        grenadeDirection:Normalize()

        local grenade = CreateEntity(HandGrenade.kMapName, grenadeStartPoint, player:GetTeamNumber())

        // Inherit player velocity?
        local startVelocity = grenadeDirection  

        startVelocity = startVelocity * 10
        startVelocity.y = startVelocity.y + 3

        local angles = Angles(0,0,0)
        angles.yaw = GetYawFromVector(grenadeDirection)
        angles.pitch = GetPitchFromVector(grenadeDirection)
        grenade:SetAngles(angles)

        grenade:Setup(player, startVelocity, true)
        
    end
    
end

function HandGrenades:OnPrimaryAttack(player)
    
    if self.throwntime == nil or self.throwntime + kThrowDelay < Shared.GetTime() then
        self.throwing = true
        self.throwntime = Shared.GetTime()

        player:TriggerEffects("start_create_" .. self:GetSuffixName())

        ThrowGrenade(self, player)

        self.nadesLeft = Clamp(self.nadesLeft - 1, 0, kNumHandGrenades)
        
        if self.nadesLeft == 0 then
            
            self:OnHolster(player)
            player:RemoveWeapon(self)
            player:SwitchWeapon(1)
                
        end
    end
    
end

function HandGrenades:Refill(amount)
    self.nadesLeft = amount
end

function HandGrenades:OnHolster(player, previousWeaponMapName)

    Weapon.OnHolster(self, player, previousWeaponMapName)
    
    self.throwing = false

end

function HandGrenades:OnDraw(player, previousWeaponMapName)

    Weapon.OnDraw(self, player, previousWeaponMapName)
    
    // Attach weapon to parent's hand
    self:SetAttachPoint(Weapon.kHumanAttachPoint)
    
    self.throwing = false

end

function HandGrenades:OnUpdateAnimationInput(modelMixin)
    
    PROFILE("HandGrenades:OnUpdateAnimationInput")
    
    modelMixin:SetAnimationInput("activity", ConditionalValue(self.throwing, "primary", "none") )
    
end    

function HandGrenades:OverrideWeaponName()
    return "mine"
end

Shared.LinkClassToMap("HandGrenades", HandGrenades.kMapName, networkVars)