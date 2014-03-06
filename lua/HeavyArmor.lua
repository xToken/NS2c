//
// lua\HeavyArmor.lua

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/PickupableMixin.lua")

class 'HeavyArmor' (ScriptActor)

HeavyArmor.kMapName = "heavyarmor"

HeavyArmor.kModelName = PrecacheAsset("models/marine/heavyarmor/heavyarmor_drop.model")

HeavyArmor.kPickupSound = PrecacheAsset("sound/ns2c.fev/ns2c/marine/weapon/heavyarmor_pickup")

HeavyArmor.kThinkInterval = .5

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function HeavyArmor:OnCreate ()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, TeamMixin)
    
    InitMixin(self, PickupableMixin, { kRecipientType = "Marine" })
    
    self:SetPhysicsGroup(PhysicsGroup.WeaponGroup)
    
end


function HeavyArmor:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetModel(HeavyArmor.kModelName)
    
end

/*function HeavyArmor:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false
end

function HeavyArmor:OnTouch(recipient)
    if self:GetIsValidRecipient(recipient) then
        StartSoundEffectAtOrigin(HeavyArmor.kPickupSound, recipient:GetOrigin())
        recipient:GiveHeavyArmor()
        return true
    end
end*/

function HeavyArmor:OnTouch(recipient)
end

function HeavyArmor:_GetNearbyRecipient()
end

// only give HA to standard marines
function HeavyArmor:GetIsValidRecipient(recipient)
    return not recipient:isa("JetpackMarine") and not recipient:isa("HeavyArmorMarine") and not recipient:isa("Exo")
end

function HeavyArmor:GetIsPermanent()
    return true
end

function HeavyArmor:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = self:GetIsValidRecipient(player)      
end  

if Server then

    function HeavyArmor:OnUse(player, elapsedTime, useSuccessTable)
    
        if self:GetIsValidRecipient(player) then
        
            player:GiveHeavyArmor()
            StartSoundEffectAtOrigin(HeavyArmor.kPickupSound, player:GetOrigin())
            DestroyEntity(self)
            
        end
        
    end
    
end

Shared.LinkClassToMap("HeavyArmor", HeavyArmor.kMapName, networkVars)