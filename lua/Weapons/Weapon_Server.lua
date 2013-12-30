// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Weapon_Server.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

local kWeaponUseTimeLimit = 0.5

function Weapon:OnInitialized()

    ScriptActor.OnInitialized(self)
    
    self:SetWeaponWorldState(true, true)
    self:SetRelevancy(false)
    
end

function Weapon:Dropped(prevOwner)

    self.prevOwnerId = prevOwner:GetId()
    
    self:SetWeaponWorldState(true)
    
    // when dropped weapons always need a physic model
    if not self.physicsModel then
        self.physicsModel = Shared.CreatePhysicsModel(self.physicsModelIndex, true, self:GetCoords(), self)
    end
    
    if self.physicsModel then
    
        local viewCoords = prevOwner:GetViewCoords()
        // DL: Temporarily disabled. Currently this is applying way too much impulse. 
        // Even when scaled down, it doesn't look quite right due to the simulation being ran on the server.
        // self.physicsModel:AddImpulse(self:GetOrigin(), viewCoords.zAxis)
        self.physicsModel:SetAngularVelocity(Vector(5,0,0))
        
    end
    
end

// Set to true for being a world weapon, false for when it's carried by a player
function Weapon:SetWeaponWorldState(state, preventExpiration)

    if state ~= self.weaponWorldState then
    
        if state then
        
            self:SetPhysicsType(PhysicsType.DynamicServer)
            
            // So it doesn't affect player movement and so collide callback is called
            self:SetPhysicsGroup(PhysicsGroup.DroppedWeaponGroup)
            self:SetPhysicsGroupFilterMask(PhysicsMask.DroppedWeaponFilter)
            
            if self.physicsModel then
                self.physicsModel:SetCCDEnabled(true)
            end
            
			if not preventExpiration then
			
            	self.weaponWorldStateTime = Shared.GetTime()
            	self.preventExpiration = nil
            	
            	local function DestroyWorldWeapon()
                
                    // We need to make sure this callback is still valid. It is possible
                    // for this weapon to be dropped and picked up before this callback fires off
                    // and then be dropped again, in which case this callback should be ignored and
                    // the next callback will destroy the weapon.
                    
                    // $AU: i would suggest to not use TimedCallbacks here. I noticed sometimes weapons won't disappear (not commander dropped, marine dropped),
                    // and also the callback table gets blown up when you spam drop/pickup constantly.
                    
                    local enoughTimePassed = (Shared.GetTime() - self.weaponWorldStateTime) >= kItemStayTime
                    if self.preventExpiration == nil and self:GetWeaponWorldState() and enoughTimePassed then
                        DestroyEntity(self)
                    end
                    
                end
                
                self:AddTimedCallback(DestroyWorldWeapon, kItemStayTime)

            else
            
                self.preventExpiration = true

			end

            self:SetIsVisible(true)
            
        else
        
            self:SetPhysicsType(PhysicsType.None)
            self:SetPhysicsGroup(PhysicsGroup.WeaponGroup)
            self:SetPhysicsGroupFilterMask(PhysicsMask.None)
            
            if self.physicsModel then
                self.physicsModel:SetCCDEnabled(false)
            end
            
        end
        
        self.hitGround = false
        
        self.weaponWorldState = state
        
    end
    
end

function Weapon:DestroyWeaponPhysics()

    if self.physicsModel then
        Shared.DestroyCollisionObject(self.physicsModel)
        self.physicsModel = nil
    end    

end

function Weapon:GetWeaponWorldState()
    return self.weaponWorldState
end

function Weapon:OnCapsuleTraceHit(entity)

    PROFILE("Weapon:OnCapsuleTraceHit")

    if self.OnCollision then
        self:OnCollision(entity)
    end
    
end

// Should only be called when dropped
function Weapon:OnCollision(targetHit)

    if not targetHit then
    
        // Play weapon drop sound
        if not self.hitGround then
        
            self:TriggerEffects("weapon_dropped")
            self.hitGround = true
            
        end
        
    end
    
end

Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.DroppedWeaponGroup, 0)
Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.DroppedWeaponGroup, PhysicsGroup.CommanderPropsGroup)
Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.DroppedWeaponGroup, PhysicsGroup.AttachClassGroup)
Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.DroppedWeaponGroup, PhysicsGroup.CommanderUnitGroup)
Shared.SetPhysicsCollisionCallbackEnabled(PhysicsGroup.DroppedWeaponGroup, PhysicsGroup.CollisionGeometryGroup)