-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Armory_Server.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

-- NS2c
-- Adjusted armory healing logic

-- west/east = x/-x
-- north/south = -z/z

local indexToUseOrigin =
{
    -- West
    Vector(Armory.kResupplyUseRange, 0, 0), 
    -- North
    Vector(0, 0, -Armory.kResupplyUseRange),
    -- South
    Vector(0, 0, Armory.kResupplyUseRange),
    -- East
    Vector(-Armory.kResupplyUseRange, 0, 0)
}

function Armory:GetTimeToResupplyPlayer(player)

    assert(player ~= nil)
    
    local timeResupplied = self.resuppliedPlayers[player:GetId()]
    
    if timeResupplied ~= nil then
    
        -- Make sure we haven't done this recently
        if Shared.GetTime() < (timeResupplied + Armory.kResupplyInterval) then
            return false
        end
        
    end
    
    return true
    
end

function Armory:GetShouldResupplyPlayer(player)

    if not player:GetIsAlive() then
        return false
    end
    
    local inNeed = false
    
    -- Don't resupply when already full
    if (player:GetHealth() < player:GetMaxHealth()) then
        inNeed = true
    else

        -- Do any weapons need ammo?
        for i, child in ientitychildren(player, "ClipWeapon") do
        
            if child:GetNeedsAmmo(false) then
                inNeed = true
                break
            end
            
        end
        
    end
    
    if inNeed then
    
        -- Check player facing so players can't fight while getting benefits of armory
        local viewVec = player:GetViewAngles():GetCoords().zAxis

        local toArmoryVec = self:GetOrigin() - player:GetOrigin()
        
        if(GetNormalizedVector(viewVec):DotProduct(GetNormalizedVector(toArmoryVec)) > .75) then
        
            if self:GetTimeToResupplyPlayer(player) then
        
                return true
                
            end
            
        end
        
    end
    
    return false
    
end

function Armory:ResupplyPlayer(player)
    
    local resuppliedPlayer = false
    
    -- Heal player first
    if (player:GetHealth() < player:GetMaxHealth()) then

        -- third param true = ignore armor
        player:AddHealth(kArmoryHealAmount, false, true)

        self:TriggerEffects("armory_health", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
        
        resuppliedPlayer = true
        --[[
        if HasMixin(player, "ParasiteAble") and player:GetIsParasited() then
        
            player:RemoveParasite()
            
        end
        --]]
        
    end

    -- Give ammo to all their weapons, one clip at a time, starting from primary
    local activeWeapon = player:GetActiveWeapon()
    
    if activeWeapon ~= nil and activeWeapon:isa("ClipWeapon") then
        if activeWeapon:GiveAmmo(1, false) then
            self:TriggerEffects("armory_ammo", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
            resuppliedPlayer = true
        end
    end 
    
    if not resuppliedPlayer then
        local weapons = player:GetHUDOrderedWeaponList()
        
        for index, weapon in ipairs(weapons) do
        
            if weapon:isa("ClipWeapon") then
            
                if weapon:GiveAmmo(1, false) then
                
                    self:TriggerEffects("armory_ammo", {effecthostcoords = Coords.GetTranslation(player:GetOrigin())})
                    
                    resuppliedPlayer = true
                    
                    break
                    
                end 
                       
            end
            
        end
        
    end
        
    if resuppliedPlayer then
    
        -- Insert/update entry in table
        self.resuppliedPlayers[player:GetId()] = Shared.GetTime()
        
        -- Play effect
        --self:PlayArmoryScan(player:GetId())

    end

end

function Armory:ResupplyPlayers()

    local playersInRange = GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(), self:GetOrigin(), Armory.kResupplyUseRange)
    for index, player in ipairs(playersInRange) do
    
        if self:GetShouldResupplyPlayer(player) then
            self:ResupplyPlayer(player)
        end
            
    end

end

function Armory:UpdateResearch()

    local researchId = self:GetResearchingId()

    if researchId == kTechId.AdvancedArmoryUpgrade then
    
        local team = self:GetTeam()
        if team then
            local techTree = team:GetTechTree()    
            local researchNode = techTree:GetTechNode(kTechId.AdvancedArmory)    
            researchNode:SetResearchProgress(self.researchProgress)
            techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", self.researchProgress)) 
        end
        
    end

end

local function AddChildModel(self)

    local scriptActor = CreateEntity(ArmoryAddon.kMapName, nil, self:GetTeamNumber())
    scriptActor:SetParent(self)
    scriptActor:SetAttachPoint(Armory.kAttachPoint)
    
    return scriptActor
    
end

function Armory:OnResearch(researchId)

    if researchId == kTechId.AdvancedArmoryUpgrade then

        -- Create visual add-on
        local advancedArmoryModule = AddChildModel(self)
        
    end
    
end

function Armory:OnResearchCancel(researchId)

    if researchId == kTechId.AdvancedArmoryUpgrade then
    
        local team = self:GetTeam()
        
        if team then
        
            local techTree = team:GetTechTree()
            local researchNode = techTree:GetTechNode(kTechId.AdvancedArmory)
            if researchNode then
            
                researchNode:ClearResearching()
                techTree:SetTechNodeChanged(researchNode, string.format("researchProgress = %.2f", 0))   
         
            end
            
            for i = 0, self:GetNumChildren() - 1 do
            
                local child = self:GetChildAtIndex(i)
                if child:isa("ArmoryAddon") then
                    DestroyEntity(child)
                    break
                end
                
            end  

        end  
    
    end

end

-- Called when research or upgrade complete
function Armory:OnResearchComplete(researchId)

    if researchId == kTechId.AdvancedArmoryUpgrade then
    
        self:SetTechId(kTechId.AdvancedArmory)
    end
    
end