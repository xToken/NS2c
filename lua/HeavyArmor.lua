//
// lua\HeavyArmor.lua

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/PickupableMixin.lua")

class 'HeavyArmor' (ScriptActor)

HeavyArmor.kMapName = "heavyarmor"

//HeavyArmor.kModelName = PrecacheAsset("models/marine/exosuit/exosuit_cm.model")
HeavyArmor.kModelName = PrecacheAsset("models/marine/heavyarmor/heavyarmor_drop.model")
local kAnimationGraph = PrecacheAsset("models/marine/exosuit/exosuit_spawn_only.animation_graph")

HeavyArmor.kPickupSound = PrecacheAsset("sound/NS2.fev/marine/common/pickup_Exosuit")
HeavyArmor.kEmptySound = PrecacheAsset("sound/NS2.fev/marine/common/Exosuit_empty")

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
    
    self:SetModel(HeavyArmor.kModelName, kAnimationGraph)
    
end

function HeavyArmor:OnTouch(recipient)
    if self:GetIsValidRecipient(recipient) then
        StartSoundEffectAtOrigin(HeavyArmor.kPickupSound, recipient:GetOrigin())
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