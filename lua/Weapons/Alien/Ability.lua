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

// The order of icons in kHUDAbilitiesTexture, used by GetIconOffsetY.
// These are just the rows, the colum is determined by primary or secondary
kAbilityOffset = enum( {'Bite', 'Parasite', 'Spit', 'Hydra', 'Cyst', 'BileBomb', 'Umbra', 'Spores', 'SwipeBlink', 'Vortex', 'Gore', 'Smash', 'Xenocide', 'PoisonBite', 'PrimalScream' } )

// Return 0-100 energy cost (where 100 is full energy bar)
function Ability:GetEnergyCost(player)
    return kDefaultEnergyCost
end

function Ability:GetSecondaryEnergyCost(player)
    return self:GetEnergyCost(player)
end

function Ability:GetIconOffsetX(secondary)
    return ConditionalValue(secondary, 1, 0)
end

function Ability:GetIconOffsetY(secondary)
    return 0
end

// return array of player energy (0-1), ability energy cost (0-1), x offset, y offset, visibility and hud slot
function Ability:GetInterfaceData(secondary, inactive)

    local parent = self:GetParent()
    // It is possible there will be a time when there isn't a parent due to how Entities are destroyed and unparented.
    if parent then
    
        local vis = (inactive and parent:GetInactiveVisible()) or (not inactive)
        local hudSlot = 0
        if self.GetHUDSlot then
            hudSlot = self:GetHUDSlot()
        end
        
        // Inactive abilities return only xoff, yoff, hud slot
        if inactive then
            return {self:GetIconOffsetX(secondary), self:GetIconOffsetY(secondary), hudSlot}
        elseif parent.GetEnergy then
        
            if secondary then
                return {parent:GetEnergy() / kAbilityMaxEnergy, self:GetSecondaryEnergyCost() / kAbilityMaxEnergy, self:GetIconOffsetX(secondary), self:GetIconOffsetY(secondary), vis, hudSlot}
            else
                return {parent:GetEnergy() / kAbilityMaxEnergy, self:GetEnergyCost() / kAbilityMaxEnergy, self:GetIconOffsetX(secondary), self:GetIconOffsetY(secondary), vis, hudSlot}
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

function Ability:GetPrimaryAttackUsesFocus()
    return false
end

function Ability:GetisUsingPrimaryAttack()
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

    Weapon.GetEffectParams(self, tableParams)
    
    local player = self:GetParent()
    if player then
        local upg, level = GetHasSilenceUpgrade(player)
        if level == 3 then
            tableParams[kEffectFilterSilenceUpgrade] = upg
        end
        tableParams[kEffectParamVolume] = (1 - (.33 * level))
    end
    
end

Shared.LinkClassToMap("Ability", "alienability", networkVars)