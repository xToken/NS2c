-- ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\Scan.lua
--
--    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- A Commander ability that gives LOS to marine team for a short time.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/CommAbilities/CommanderAbility.lua")
Script.Load("lua/MapBlipMixin.lua")

class 'Scan' (CommanderAbility)

Scan.kMapName = "scan"

Scan.kScanEffect = PrecacheAsset("cinematics/marine/observatory/scan.cinematic")
Scan.kScanSound = PrecacheAsset("sound/NS2.fev/marine/commander/scan")

Scan.kType = CommanderAbility.kType.Repeat
local kScanInterval = 0.2
Scan.kScanDistance = kScanRadius

local networkVars = { }

function Scan:OnCreate()

    CommanderAbility.OnCreate(self)
    
    if Server then
        StartSoundEffectOnEntity(Scan.kScanSound, self)
    end
    
end

function Scan:OnInitialized()

    CommanderAbility.OnInitialized(self)
    
    if Server then
    
        DestroyEntitiesWithinRange("Scan", self:GetOrigin(), Scan.kScanDistance * 0.5, EntityFilterOne(self)) 
    
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end
        
    end
    
end

function Scan:OverrideCheckVision()
    return true
end

function Scan:GetRepeatCinematic()
    return Scan.kScanEffect
end

function Scan:GetType()
    return Scan.kType
end

function Scan:GetLifeSpan()
    return kScanDuration
end

function Scan:GetUpdateTime()
    return kScanInterval
end

if Server then

    function Scan:Perform(deltaTime)
    
        PROFILE("Scan:Perform")
        
        local enemies = GetEntitiesWithMixinForTeamWithinXZRange("LOS", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Scan.kScanDistance)
        local detectable = GetEntitiesWithMixinForTeamWithinXZRange("Detectable", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Scan.kScanDistance)

        for _, ent in ipairs(detectable) do
            table.insertunique(enemies, ent)
        end

        for _, enemy in ipairs(enemies) do
        
            if HasMixin(enemy, "LOS") then
                enemy:SetIsSighted(true)
            end
            
            if HasMixin(enemy, "Detectable") then
                enemy:SetDetected(true)
            end
            
            -- Allow entities to respond
            if enemy.OnScan then
               enemy:OnScan()
            end
        end   
        
    end
    
    function Scan:OnDestroy()
    
        for _, entity in ipairs( GetEntitiesWithMixinForTeamWithinRange("LOS", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), Scan.kScanDistance)) do
            entity.updateLOS = true
        end
        
        CommanderAbility.OnDestroy(self)
    
    end
    
end

Shared.LinkClassToMap("Scan", Scan.kMapName, networkVars)
