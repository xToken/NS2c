// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Jetpack.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Changed pickup sound, altered so HA cannot have jp also.

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/PickupableMixin.lua")
Script.Load("lua/JetpackOnBack.lua")
Script.Load("lua/SelectableMixin.lua")

class 'Jetpack' (ScriptActor)

Jetpack.kMapName = "jetpack"

// TODO: add physic geometry to a seperate "pick up jetpack" model, otherwise the jetpack will not move to the ground (alternatively we can change the comm dropheight for this entity for 0)
Jetpack.kModelName = PrecacheAsset("models/marine/jetpack/jetpack.model")

Jetpack.kAttachPoint = "JetPack"
Jetpack.kEmptySound = PrecacheAsset("sound/NS2.fev/marine/common/jetpack_empty")

Jetpack.kThinkInterval = .5

Jetpack.kAnimOpen = "jetpack_takeoff"
Jetpack.kAnimClose = "jetpack_land"
Jetpack.kAnimFly = "jetpack"

local networkVars = { }

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

function Jetpack:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
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
end

// only give jetpacks to standard marines
function Jetpack:GetIsValidRecipient(recipient)
    return not recipient:isa("JetpackMarine") and not recipient:isa("HeavyArmorMarine") and not recipient:isa("Exo")
end

function Jetpack:GetIsPermanent()
    return true
end  

function Jetpack:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = self:GetIsValidRecipient(player)      
end  

function Jetpack:_GetNearbyRecipient()
end

if Server then
    
    function Jetpack:OnUseDeferred()
        
        local player = self.useRecipient 
        self.useRecipient = nil
        
        if player and not player:GetIsDestroyed() and self:GetIsValidRecipient(player) then
            
            player:GiveJetpack()
            self:TriggerEffects("pickup")
            DestroyEntity(self)
            
        end
    
    end

    function Jetpack:OnUse(player, elapsedTime, useSuccessTable)
    
        if self:GetIsValidRecipient( player ) and ( not self.useRecipient or self.useRecipient:GetIsDestroyed() ) then
            
            self.useRecipient = player
            self:AddTimedCallback( self.OnUseDeferred, 0 )
            
        end
        
    end
    
end

Shared.LinkClassToMap("Jetpack", Jetpack.kMapName, networkVars)