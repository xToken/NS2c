// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Weapon.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/Mixins/ModelMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/DamageMixin.lua")

class 'Weapon' (ScriptActor)

Weapon.kMapName = "weapon"

// Attach point for marine weapons
Weapon.kHumanAttachPoint = "RHand_Weapon"
// Super important constant that defines how often a bite or other melee attack will hit
Weapon.kMeleeBaseWidth = .5
Weapon.kMeleeBaseHeight = .8

if Server then
    Script.Load("lua/Weapons/Weapon_Server.lua")
elseif Client then
    Script.Load("lua/Weapons/Weapon_Client.lua")
end

local networkVars =
{
    isHolstered = "boolean",
    primaryAttacking = "boolean",
    secondaryAttacking = "boolean"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ModelMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)

function Weapon:OnCreate()

    ScriptActor.OnCreate(self)
    
    InitMixin(self, BaseModelMixin)
    InitMixin(self, ModelMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, DamageMixin)
    
    self:SetPhysicsGroup(PhysicsGroup.WeaponGroup)
    
    self:SetUpdates(true)
    
    self.reverseX = false
    self.isHolstered = true
    self.primaryAttacking = false
    self.secondaryAttacking = false
    
    // This value is used a lot in this class, cache it off.
    self.mapName = self:GetMapName()
    
    if Client then
        self.activeSince = 0
    end
    
end

function Weapon:OnInitialized()

    ScriptActor.OnInitialized(self)

    self:SetRelevancy(false)

end

function Weapon:OnDestroy()

    ScriptActor.OnDestroy(self)
    
    // Force end events just in case the weapon goes out of relevancy on the client for example.
    self:TriggerEffects(self:GetPrimaryAttackPrefix() .. "_attack_end")
    self:TriggerEffects(self:GetSecondaryAttackPrefix() .. "_alt_attack_end")
    
    if self.ammoDisplayUI then
    
        Client.DestroyGUIView(self.ammoDisplayUI)
        self.ammoDisplayUI = nil
        
    end

end

function Weapon:GetAnimationGraphName()
    return nil
end

function Weapon:GetBarrelPoint()

    local player = self:GetParent()
    return player and player:GetEyePos()

end

function Weapon:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false    
end

function Weapon:OnParentChanged(oldParent, newParent)

    ScriptActor.OnParentChanged(self, oldParent, newParent)
    
    if oldParent then
    
        self:OnPrimaryAttackEnd(oldParent)
        self:OnSecondaryAttackEnd(oldParent)
        
    end

end

function Weapon:OnUpdateWeapon(player)
end

function Weapon:GetViewModelName()
    return ""
end

function Weapon:GetRange()
    return 8012
end

function Weapon:GetHasSecondary(player)
    return false
end

// Return 0-1 scalar approximation for weight. Owner of weapon will determine
// what this means and how to use it.
function Weapon:GetWeight()
    return 0
end

function Weapon:SetCameraShake(amount, speed, time)
    local parent = self:GetParent()
    if(parent ~= nil and Client) then
        parent:SetCameraShake(amount, speed, time)
    end
end

function Weapon:GetIsDroppable()
    return false
end

function Weapon:GetSprintAllowed()
    return true
end

function Weapon:GetTryingToFire(input)
    return (bit.band(input.commands, Move.PrimaryAttack) ~= 0) or ((bit.band(input.commands, Move.SecondaryAttack) ~= 0) and self:GetHasSecondary(self:GetParent()))
end

function Weapon:GetPrimaryAttackRequiresPress()
    return false
end

function Weapon:GetSecondaryAttackRequiresPress()
    return false
end

// So child classes can override names of event names that are triggered (for grenade launcher to use rifle effects block)
function Weapon:GetPrimaryAttackPrefix()
    return self.mapName
end

function Weapon:GetSecondaryAttackPrefix()
    return self.mapName
end

function Weapon:OnPrimaryAttack(player)
end

function Weapon:OnPrimaryAttackEnd(player)
end

function Weapon:OnSecondaryAttack(player)
end

function Weapon:OnSecondaryAttackEnd(player)
end

function Weapon:OnReload(player)
end

function Weapon:GetIsHolstered()
    return self.isHolstered
end

function Weapon:GetCanSkipPhysics()
    return self:GetParent() and self.isHolstered
end

function Weapon:GetAreAttackEffectsPredicted()
    return true
end

function Weapon:OnHolster(player)

    self:OnPrimaryAttackEnd()
    
    self.isHolstered = true
    self:SetIsVisible(false)
    self.primaryAttacking = false
    self.secondaryAttacking = false
    
end

function Weapon:GetResetViewModelOnDraw()
    return true
end

function Weapon:OnDraw(player, previousWeaponMapName)

    self.isHolstered = false
    self:SetIsVisible(true)
    
    if self:GetResetViewModelOnDraw() then
        player:SetViewModel(nil, nil)
    end
    
    player:SetViewModel(self:GetViewModelName(), self)
    
    self:TriggerEffects("draw")
    
end

/**
 * The melee base is the width and height of the surface that defines the melee volume.
 * This box needs to be wide enough so that if a target is mostly on screen, the bite will hit
 * Because of perspective, this means that the farther away a target gets, the more accurate 
 * we'll need to be (the closer to the center of the screen)
 */
function Weapon:GetMeleeBase()
    // Width of box, height of box
    return Weapon.kMeleeBaseWidth, Weapon.kMeleeBaseHeight
end

/**
 * Extra offset from viewpoint to make sure you don't hit anything to your rear. 
 */
function Weapon:GetMeleeOffset()
    return 0.0
end

function Weapon:ConstrainMoveVelocity(moveVelocity)
end

local function SharedUpdate(self)

    // Handle dropping on the client
    if Client then
        self:UpdateDropped()
    end
    
end

function Weapon:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)
    SharedUpdate(self)
    
end

function Weapon:ProcessMoveOnWeapon(player, input)
    SharedUpdate(self)
end

function Weapon:GetUIDisplaySettings()
    return nil
end

function Weapon:OnUpdateRender()

    local parent = self:GetParent()
    local settings = self:GetUIDisplaySettings()
    if parent and parent:GetIsLocalPlayer() and settings then
    
        local ammoDisplayUI = self.ammoDisplayUI
        if not ammoDisplayUI then
        
            ammoDisplayUI = Client.CreateGUIView(settings.xSize, settings.ySize)
            ammoDisplayUI:Load(settings.script)
            ammoDisplayUI:SetTargetTexture("*ammo_display" .. (settings.textureNameOverride or self:GetMapName()))
            self.ammoDisplayUI = ammoDisplayUI
            
        end
        
        ammoDisplayUI:SetGlobal("weaponClip", parent:GetWeaponClip())
        ammoDisplayUI:SetGlobal("weaponAmmo", parent:GetWeaponAmmo())
        ammoDisplayUI:SetGlobal("weaponAuxClip", parent:GetAuxWeaponClip())
        
    elseif self.ammoDisplayUI then
    
        Client.DestroyGUIView(self.ammoDisplayUI)
        self.ammoDisplayUI = nil
        
    end
    
end

function Weapon:GetIsActive()
    local parent = self:GetParent()
    return (parent ~= nil and (parent.GetActiveWeapon) and (parent:GetActiveWeapon() == self))
end

// Max degrees that weapon can swing left or right
function Weapon:GetSwingAmount()
    return 40
end

function Weapon:GetSwingSensitivity()
    return .5
end

function Weapon:SetRelevancy(sighted)

    local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)
    if true then //sighted then
        mask = bit.bor(mask, kRelevantToTeam1Commander, kRelevantToTeam2Commander)
    else
    
        if self:GetTeamNumber() == 1 then
            mask = bit.bor(mask, kRelevantToTeam1Commander)
        elseif self:GetTeamNumber() == 2 then
            mask = bit.bor(mask, kRelevantToTeam2Commander)
        end
        
    end
    
    self:SetExcludeRelevancyMask(mask)
    
end

// this would cause the use button to appear on the hud, there is a separate functionality for picking up weapons
function Weapon:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = false
end

function Weapon:OnCreateCollisionModel()
    
    // Remove any "move" collision representation for the weapon
    // so that it doesn't interfere with movement.
    local collisionModel = self:GetCollisionModel()
    collisionModel:RemoveCollisionRep(CollisionRep.Move)
    
end

Shared.LinkClassToMap("Weapon", Weapon.kMapName, networkVars)