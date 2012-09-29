// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Weapons\Alien\XenocideLeap.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
// 
//    First primary attack is xenocide, every next attack is bite. Secondary is leap.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Alien/Ability.lua")
Script.Load("lua/Weapons/Alien/BiteLeap.lua")

local kRange = 1.4

class 'XenocideLeap' (BiteLeap)

XenocideLeap.kMapName = "xenocide"

// after kDetonateTime seconds the skulk goes 'boom!'
local kDetonateTime = 2.5
local kXenocideSoundName = PrecacheAsset("sound/NS2.fev/alien/common/xenocide_start")


local networkVars = { }

local function TriggerXenocide(self, player)

    if Server then
    
        StartSoundEffectOnEntity(kXenocideSoundName, player)
        self.xenocideTimeLeft = kDetonateTime
        
    elseif Client and Client.GetLocalPlayer() == player then

        if not self.xenocideGui then
            self.xenocideGui = GetGUIManager():CreateGUIScript("GUIXenocideFeedback")
        end
    
        self.xenocideGui:TriggerFlash(kDetonateTime)
        player:SetCameraShake(.01, 15, kDetonateTime)
        
    end

end

function XenocideLeap:OnDestroy()

    BiteLeap.OnDestroy(self)
    
    if Client then
    
        if self.xenocideGui ~= nil then
        
            GetGUIManager():DestroyGUIScript(self.xenocideGui)
            self.xenocideGui = nil
        
        end
    
    end
end

function XenocideLeap:GetDeathIconIndex()
    return kDeathMessageIcon.Xenocide
end

function XenocideLeap:GetEnergyCost(player)
    if not self.xenociding then
        return kXenocideEnergyCost
    else
        return BiteLeap.GetEnergyCost(self, player)
    end
end

function XenocideLeap:GetHUDSlot()
    return 3
end

function XenocideLeap:GetIconOffsetY(secondary)
    if not self.xenociding then
        return kAbilityOffset.Xenocide
    else
        return kAbilityOffset.Bite
    end
    
end

function XenocideLeap:GetRange()
    return kRange
end

function XenocideLeap:OnPrimaryAttack(player)

    if player:GetEnergy() >= self:GetEnergyCost() then
        
        if not self.xenociding then
            TriggerXenocide(self, player)
            self.xenociding = true
        else
        
            if self.xenocideTimeLeft and self.xenocideTimeLeft < kDetonateTime * 0.4 then        
                BiteLeap.OnPrimaryAttack(self, player)
            end
            
        end
        
    end
    
end

function XenocideLeap:OnHolster(player)

    /*
    if self.xenocideGui ~= nil then
    
        GetGUIManager():DestroyGUIScript(self.xenocideGui)
        self.xenocideGui = nil
    
    end
    
    self.xenociding = false
    */
    
end

function XenocideLeap:OnProcessMove(input)

    BiteLeap.OnProcessMove(self, input)
    
    local player = self:GetParent()
    if self.xenociding then
    
        if Server then
        
            self.xenocideTimeLeft = math.max(self.xenocideTimeLeft - input.time, 0)
            
            if self.xenocideTimeLeft == 0 and player:GetIsAlive() then
            
                player:TriggerEffects("xenocide", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
                
                local hitEntities = GetEntitiesWithMixinForTeamWithinRange("Live", GetEnemyTeamNumber(player:GetTeamNumber()), player:GetOrigin(), kXenocideRange)
                RadiusDamage(hitEntities, player:GetOrigin(), kXenocideRange, kXenocideDamage, self)
                
                player:Kill()
                
            end
            
        elseif Client and not player:GetIsAlive() and self.xenocideGui then
        
            GetGUIManager():DestroyGUIScript(self.xenocideGui)
            self.xenocideGui = nil
            
        end
        
    end
    
end
    
if Server then
    
    function XenocideLeap:GetDamageType()
        if self.xenocideTimeLeft == 0 then
            return kXenocideDamageType
        else
            return kBiteDamageType
        end    
    end

end

Shared.LinkClassToMap("XenocideLeap", XenocideLeap.kMapName, networkVars)