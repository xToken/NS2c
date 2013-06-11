// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Jetpack.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/PickupableMixin.lua")
Script.Load("lua/JetpackOnBack.lua")
Script.Load("lua/SelectableMixin.lua")

class 'Jetpack' (ScriptActor)

Jetpack.kMapName = "jetpack"

// TODO: add physic geometry to a seperate "pick up jetpack" model, otherwise the jetpack will not move to the ground (alternatively we can change the comm dropheight for this entity for 0)
Jetpack.kModelName = PrecacheAsset("models/marine/jetpack/jetpack.model")

Jetpack.kAttachPoint = "JetPack"
Jetpack.kPickupSound = PrecacheAsset("sound/ns2c.fev/ns2c/marine/weapon/jetpack_pickup")
Jetpack.kEmptySound = PrecacheAsset("sound/NS2.fev/marine/common/jetpack_empty")

Jetpack.kThinkInterval = .5

Jetpack.kAnimOpen = "jetpack_takeoff"
Jetpack.kAnimClose = "jetpack_land"
Jetpack.kAnimFly = "jetpack"

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

function Jetpack:OnCreate ()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, SelectableMixin)
    
    InitMixin(self, PickupableMixin, { kRecipientType = "Marine" })
    
end

function Jetpack:OnInitialized()

    ScriptActor.OnInitialized(self)    
    self:SetModel(Jetpack.kModelName)
    
    local coords = self:GetCoords()

    self.jetpackBody = Shared.CreatePhysicsSphereBody(false, 0.4, 0, coords)
    self.jetpackBody:SetCollisionEnabled(true)    
    self.jetpackBody:SetGroup(PhysicsGroup.WeaponGroup)    
    self.jetpackBody:SetEntity(self)
    
end

function Jetpack:OnDestroy() 

    ScriptActor.OnDestroy(self)

    if self.jetpackBody then
    
        Shared.DestroyCollisionObject(self.jetpackBody)
        self.jetpackBody = nil
        
    end

end

function Jetpack:OnTouch(recipient)

    if self:GetIsValidRecipient(recipient) then
        Shared.PlayWorldSound(nil, Jetpack.kPickupSound, nil, recipient:GetOrigin())
        recipient:GiveJetpack()
        return true
    end
    
end

function Jetpack:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false
end

// only give jetpacks to standard marines
function Jetpack:GetIsValidRecipient(recipient)
    return not recipient:isa("JetpackMarine") and not recipient:isa("HeavyArmorMarine")
end

function Jetpack:GetIsPermanent()
    return true
end

Shared.LinkClassToMap("Jetpack", Jetpack.kMapName, networkVars)