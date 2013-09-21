// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\PointGiverMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com) and
//                  Andreas Urwalek (andi@unknownworlds.com) 
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

//NS2c
//Adjustments made for RFK

/**
 * PointGiverMixin handles awarding points on kills and other events.
 */
PointGiverMixin = CreateMixin(PointGiverMixin)
PointGiverMixin.type = "PointGiver"

local kPointsPerUpgrade = 1

PointGiverMixin.expectedCallbacks =
{
    GetTeamNumber = "Returns the team number this PointGiver is on.",
    GetTechId = "Returns the tech Id of this PointGiver."
}

function PointGiverMixin:__initmixin()

    if Server then
        self.damagePoints = {}
    end
    
end

function PointGiverMixin:GetPointValue()

    local numUpgrades = HasMixin(self, "Upgradable") and #self:GetUpgrades() or 0
    local points = LookupTechData(self:GetTechId(), kTechDataPointValue, 0) + numUpgrades * kPointsPerUpgrade
    
    for i = 0, self:GetNumChildren() - 1 do
    
        local child = self:GetChildAtIndex(i)
        if HasMixin(child, "PointGiver") then
            points = points + child:GetPointValue()
        end
    
    end
    
    // give additional points for enemies which got alot of score in their current life
    // but don't give more than twice the default point value
    if HasMixin(self, "Scoring") then
    
        local scoreGained = self:GetScoreGainedCurrentLife() or 0
        points = points + math.min(points, scoreGained * 0.1)
        
    end
    
    //DebugPrint("%s:GetPointValue() returns %s", self:GetClassName(), ToString(points))

    return points
    
end

function PointGiverMixin:GetResourceValue(killer)
    if killer:GetTechId() == kTechId.Fade or killer:GetTechId() == kTechId.Onos then
        return kHighLifeformKillReward
    end
    if killer:isa("Marine") then
        if killer:GetActiveWeaponName() == "HeavyMachineGun" then
            return kHighLifeformKillReward
        end
    end
    return kKillReward
end

if Server then

    local kNoConstructPoints = { "Cyst", "Clog", "BabblerEgg" }
    local function GetGivesConstructReward(self)    
        return not table.contains(kNoConstructPoints, self:GetClassName())    
    end

    function PointGiverMixin:OnConstruct(builder, newFraction, oldFraction)
    
        if not self.constructPoints then
            self.constructPoints = {}
        end
    
        if builder and builder:isa("Player") and GetAreFriends(self, builder) and GetGivesConstructReward(self) then
        
            local builderId = builder:GetId()
        
            if not self.constructPoints[builderId] then
                self.constructPoints[builderId] = 0
            end

            self.constructPoints[builderId] = self.constructPoints[builderId] + (newFraction - oldFraction)
        
        end
    
    end

    function PointGiverMixin:OnConstructionComplete()
    
        if self.constructPoints then
        
            for builderId, constructionFraction in pairs(self.constructPoints) do
            
                local builder = Shared.GetEntity(builderId)
                if builder and builder:isa("Player") and HasMixin(builder, "Scoring") then
                    builder:AddScore(math.floor(kBuildPointValue * Clamp(constructionFraction, 0, 1)), 0)
                end
            
            end
        
        end
        
        self.constructPoints = nil
    
    end

    function PointGiverMixin:OnEntityChange(oldId, newId)
    
        if self.damagePoints[oldId] then        
            if newId and newId ~= Entity.invalidId then        
                self.damagePoints[newId] = self.damagePoints[oldId]
            end            
            self.damagePoints[oldId] = nil            
        end
        
        if self.constructPoints and self.constructPoints[oldId] then        
            if newId and newId ~= Entity.invalidId then        
                self.constructPoints[newId] = self.constructPoints[oldId]
            end            
            self.constructPoints[oldId] = nil            
        end
    
    end

    function PointGiverMixin:OnTakeDamage(damage, attacker, doer, point, direction, damageType, preventAlert)
    
        if attacker and attacker:isa("Player") and GetAreEnemies(self, attacker) then
        
            local attackerId = attacker:GetId()
            
            if not self.damagePoints[attackerId] then
                self.damagePoints[attackerId] = 0
            end
            
            self.damagePoints[attackerId] = self.damagePoints[attackerId] + damage
            
        end
    
    end

    function PointGiverMixin:PreOnKill(attacker, doer, point, direction)
    
        local totalDamageDone = self:GetMaxHealth() + self:GetMaxArmor() * 2        
        local points = self:GetPointValue()
        local resReward = self:isa("Player") and kPersonalResPerKill or 0
        
        // award partial res and score to players who assisted
        for attackerId, damageDone in pairs(self.damagePoints) do  
        
            local currentAttacker = Shared.GetEntity(attackerId)
            if currentAttacker and HasMixin(currentAttacker, "Scoring") then
                
                local damageFraction = Clamp(damageDone / totalDamageDone, 0, 1)                
                local scoreReward = points >= 1 and math.max(1, math.round(points * damageFraction)) or 0    
         
                currentAttacker:AddScore(scoreReward, resReward * damageFraction)
                
                if self:isa("Player") and currentAttacker ~= attacker then
                    currentAttacker:AddAssistKill()
                end
                
            end
        
        end
        
        if self:isa("Player") and attacker and GetAreEnemies(self, attacker) then
        
            if attacker:isa("Player") then
                attacker:AddKill()
            end

			if Server then
                local awardTeam = attacker:GetTeam()
                if awardTeam.AwardResources and awardTeam ~= self:GetTeam() then
                    awardTeam:AwardResources(self:GetResourceValue(attacker), attacker)
                end
            end
            
        end
        
    end

end