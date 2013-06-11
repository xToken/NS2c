// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\Weapons\Alien\Ability.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com) and
//                  Max McGuire (max@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Weapon.lua")

class 'Ability' (Weapon)

local networkVars = { }

Ability.kMapName = "alienability"

local kDefaultEnergyCost = 20

// Return 0-100 energy cost (where 100 is full energy bar)
function Ability:GetEnergyCost(player)
    return kDefaultEnergyCost
end

function Ability:GetSecondaryTechId()
    return kTechId.None
end

function Ability:GetSecondaryEnergyCost(player)
    return self:GetEnergyCost(player)
end

function Ability:GetResetViewModelOnDraw()
    return false
end

function Ability:GetAttackDelay()
    return 0
end

function Ability:GetLastAttackTime()
    return 0
end

function Ability:GetHasAttackDelay(self, player)

    local attackDelay = ConditionalValue( player:GetIsPrimaled(), (self:GetAttackDelay() / kPrimalScreamROFIncrease), self:GetAttackDelay())
    if self:GetAbilityUsesFocus() then
        local upg, level = GetHasFocusUpgrade(player)
        if upg and level > 0 then
            attackDelay = attackDelay + (attackDelay * (kFocusAttackSlowdown * level))
        end
    end
    return self:GetLastAttackTime() + attackDelay > Shared.GetTime()
    
end

// return array of player energy (0-1), ability energy cost (0-1), techId, visibility and hud slot
function Ability:GetInterfaceData(secondary, inactive)

    local parent = self:GetParent()
    // It is possible there will be a time when there isn't a parent due to how Entities are destroyed and unparented.
    if parent then
    
        local vis = (inactive and parent:GetInactiveVisible()) or (not inactive)
        local hudSlot = 0
        if self.GetHUDSlot then
            hudSlot = self:GetHUDSlot()
        end
        
        // Handle secondary here
        local techId = self:GetTechId()
        if secondary then
            techId = self:GetSecondaryTechId()
        end
        
        // Inactive abilities return only hud slot, techId
        if inactive then
            return {hudSlot, techId}
        elseif parent.GetEnergy then
        
            if secondary then
                return {parent:GetEnergy() / parent:GetMaxEnergy(), self:GetSecondaryEnergyCost() / parent:GetMaxEnergy(), techId, vis, hudSlot}
            else
                return {parent:GetEnergy() / parent:GetMaxEnergy(), self:GetEnergyCost() / parent:GetMaxEnergy(), techId, vis, hudSlot}
            end
        
        end
        
    end
    
    return { }
    
end

// Abilities don't have world models, they are part of the creature
function Ability:GetWorldModelName()
    return ""
end

// All alien abilities use the view model designated by the alien
function Ability:GetViewModelName()

    local viewModel = ""
    local parent = self:GetParent()
    
    if parent ~= nil and parent:isa("Alien") then
        viewModel = parent:GetViewModelName()
    end
    
    return viewModel
    
end

function Ability:PerformPrimaryAttack(player)
    return false
end

function Ability:PerformSecondaryAttack(player)
    return false
end

function Ability:GetAbilityUsesFocus()
    return false
end

// Child class should override if preventing the primary attack is needed.
function Ability:GetPrimaryAttackAllowed()
    return true
end

// Child class can override
function Ability:OnPrimaryAttack(player)

    if self:GetPrimaryAttackAllowed() and (not self:GetPrimaryAttackRequiresPress() or not player:GetPrimaryAttackLastFrame()) then
    
        local energyCost = self:GetEnergyCost(player)
        
        if player:GetEnergy() >= energyCost then
        
            if self:PerformPrimaryAttack(player) then
            
                player:DeductAbilityEnergy(energyCost)
                
                Weapon.OnPrimaryAttack(self, player)
                
            end
            
        end
        
    end
    
end

function Ability:OnSecondaryAttack(player)

    if not self:GetSecondaryAttackRequiresPress() or not player:GetSecondaryAttackLastFrame() then
    
        local energyCost = self:GetSecondaryEnergyCost(player)
        
        if player:GetEnergy() >= energyCost then

            if self:PerformSecondaryAttack(player) then
            
                player:DeductAbilityEnergy(energyCost)
                
                Weapon.OnSecondaryAttack(self, player)
                
            end

        end

    end
    
end

function Ability:GetEffectParams(tableParams)

    local player = self:GetParent()
    if player then
		//Silence Controls volume levels, dont think this actually works tho.
        local upg, level = GetHasSilenceUpgrade(player)
        if level == 3 then
            tableParams[kEffectFilterSilenceUpgrade] = upg
        end
        //tableParams[kEffectParamVolume] = (1 - (.33 * level))
    end
    
end

Shared.LinkClassToMap("Ability", "alienability", networkVars)