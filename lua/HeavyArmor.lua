//
// lua\HeavyArmor.lua

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/PickupableMixin.lua")

class 'HeavyArmor' (ScriptActor)

HeavyArmor.kMapName = "heavyarmor"

HeavyArmor.kModelName = PrecacheAsset("models/marine/heavyarmor/heavyarmor_drop.model")

HeavyArmor.kPickupSound = PrecacheAsset("sound/ns2c.fev/ns2c/marine/weapon/heavyarmor_pickup")

HeavyArmor.kThinkInterval = .5

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function HeavyArmor:OnCreate ()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    
    InitMixin(self, PickupableMixin, { kRecipientType = "Marine" })
    
    self:SetPhysicsGroup(PhysicsGroup.WeaponGroup)
    
end


function HeavyArmor:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(HeavyArmor.kModelName)
    
end

function HeavyArmor:OnTouch(recipient)
    if self:GetIsValidRecipient(recipient) then
        Shared.PlayWorldSound(nil, HeavyArmor.kPickupSound, nil, recipient:GetOrigin())
        recipient:GiveHeavyArmor()
        return true
    end
end

// only give HA to standard marines
function HeavyArmor:GetIsValidRecipient(recipient)
    return not recipient:isa("JetpackMarine") and not recipient:isa("HeavyArmorMarine")
end

function HeavyArmor:GetIsPermanent()
    return true
end  

Shared.LinkClassToMap("HeavyArmor", HeavyArmor.kMapName, networkVars)