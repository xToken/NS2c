// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\Alien_Client.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Added hive info and chamber counts, moved some vars to local

Script.Load("lua/MaterialUtility.lua")

local kEnzymedViewMaterialName = "cinematics/vfx_materials/enzyme_view.material"
local kEnzymedThirdpersonMaterialName = "cinematics/vfx_materials/enzyme.material"
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/enzyme_view.surface_shader")
Shared.PrecacheSurfaceShader("cinematics/vfx_materials/enzyme.surface_shader")

local kEmpoweredEffectInterval = 2
kRegenerationViewCinematic = PrecacheAsset("cinematics/alien/regeneration_1p.cinematic")

local kFirstPersonDeathEffect = PrecacheAsset("cinematics/alien/death_1p_alien.cinematic")
local kAlienFirstPersonHitEffectName = PrecacheAsset("cinematics/alien/hit_1p.cinematic")

function AlienUI_GetActiveHiveCount()

    for _, ent in ientitylist(Shared.GetEntitiesWithClassname("AlienTeamInfo")) do
        return ent:GetActiveHiveCount()
    end
    
    return 0

end

function AlienUI_GetHiveList()
    local hiveinfo = { }
	
	//Hives always relevant to aliens now, so just look them all up...
	for _, ent in ientitylist(Shared.GetEntitiesWithClassname("Hive")) do
        table.insert(hiveinfo, ent)
    end
    
	return hiveinfo
end

function AlienUI_GetHasMovementSpecial()

    local hasMovementSpecial = false
    
    local player = Client.GetLocalPlayer()
    if player and player.GetHasMovementSpecial then
        hasMovementSpecial = player:GetHasMovementSpecial()
    end
     
    return hasMovementSpecial

end

function AlienUI_GetChamberCount(techId)
    local player = Client.GetLocalPlayer()
    if player ~= nil then
        return GetChambers(techId, player)
     end
     return 0
end

// array of totalPower, minPower, xoff, yoff, visibility (boolean), hud slot
function GetActiveAbilityData(secondary)

    local data = { }
    
    local player = Client.GetLocalPlayer()
    
    if player ~= nil then
    
        local ability = player:GetActiveWeapon()
        
        if ability ~= nil and ability:isa("Ability") then
        
            if not secondary or secondary and ability:GetHasSecondary(player) then
                data = ability:GetInterfaceData(secondary, false)
            end
            
        end
        
    end
    
    return data
    
end

function AlienUI_GetHasAdrenaline()

    local player = Client.GetLocalPlayer()
    local hasAdrenaline = false
    
    if player then
        hasAdrenaline = GetHasAdrenalineUpgrade(player)
    end
    
    return hasAdrenaline == true

end

function AlienUI_GetInUmbra()

    local player = Client.GetLocalPlayer()
    if player ~= nil and HasMixin(player, "Umbra") then
        return player:GetHasUmbra()
    end

    return false

end

function PlayerUI_GetHasMucousShield()

    local player = Client.GetLocalPlayer()
    if player and player.GetHasMucousShield then
        return player:GetHasMucousShield()   
    end
    return false
    
end

function PlayerUI_GetMucousShieldHP()

    local player = Client.GetLocalPlayer()
    if player and player.GetMuscousShieldAmount then
    
        local health = math.ceil(player:GetMuscousShieldAmount())
        return health
        
    end
    
    return 0
    
end

function AlienUI_GetEggCount()

    local eggCount = 0
    
    local teamInfo = GetTeamInfoEntity(kTeam2Index)
    if teamInfo then
        eggCount = teamInfo:GetEggCount()
    end
    
    return eggCount
    
end

/**
 * For current ability, return an array of
 * totalPower, minimumPower, tex x offset, tex y offset, 
 * visibility (boolean), command name
 */
function AlienUI_GetAbilityData()

    local data = {}
    local player = Client.GetLocalPlayer()
    if player ~= nil then
    
        table.addtable(GetActiveAbilityData(false), data)

    end
    
    return data
    
end

/**
 * For secondary ability, return an array of
 * totalPower, minimumPower, tex x offset, tex y offset, 
 * visibility (boolean)
 */
function AlienUI_GetSecondaryAbilityData()

    local data = {}
    local player = Client.GetLocalPlayer()
    if player ~= nil then
        
        table.addtable(GetActiveAbilityData(true), data)
        
    end
    
    return data
    
end

// Loop through child weapons that aren't active and add all their data into one array
function AlienUI_GetInactiveAbilities()

    local data = {}
    
    local player = Client.GetLocalPlayer()

    if player and player:isa("Alien") then    
    
        local inactiveAbilities = player:GetHUDOrderedWeaponList()
        
        // Don't show selector if we only have one ability
        if table.count(inactiveAbilities) > 1 then
        
            for index, ability in ipairs(inactiveAbilities) do
            
                if ability:isa("Ability") then
                    local abilityData = ability:GetInterfaceData(false, true)
                    if table.count(abilityData) > 0 then
                        table.addtable(abilityData, data)
                    end
                end
                    
            end
            
        end
        
    end
    
    return data
    
end

function AlienUI_GetPlayerEnergy()

    local player = Client.GetLocalPlayer()
    if player and player.GetEnergy then
        return player:GetEnergy()
    end
    return 0
    
end

function AlienUI_GetPlayerMaxEnergy()

    local player = Client.GetLocalPlayer()
    if player and player.GetMaxEnergy then
        return player:GetMaxEnergy()
    end
    return kAbilityMaxEnergy
    
end

function Alien:UpdateEmpoweredEffect(isLocal)

    if self.empoweredClient ~= self.empowered then

        if isLocal then
        
            local viewModel= nil        
            if self:GetViewModelEntity() then
                viewModel = self:GetViewModelEntity():GetRenderModel()  
            end
                
            if viewModel then
   
                if self.empowered then
                    self.enzymedViewMaterial = AddMaterial(viewModel, kEnzymedViewMaterialName)
                else
                
                    if RemoveMaterial(viewModel, self.enzymedViewMaterial) then
                        self.enzymedViewMaterial = nil
                    end
  
                end
            
            end
        
        end
        
        local thirdpersonModel = self:GetRenderModel()
        if thirdpersonModel then
        
            if self.empowered then
                self.enzymedMaterial = AddMaterial(thirdpersonModel, kEnzymedThirdpersonMaterialName)
            else
            
                if RemoveMaterial(thirdpersonModel, self.enzymedMaterial) then
                    self.enzymedMaterial = nil
                end

            end
        
        end
        
        self.empoweredClient = self.empowered
        
    end

    // update cinemtics
    if self.empowered then

        if not self.lastEmpoweredEffect or self.lastEmpoweredEffect + kEmpoweredEffectInterval < Shared.GetTime() then
        
            self:TriggerEffects("empower")
            self.lastEmpoweredEffect = Shared.GetTime()
        
        end

    end 

end

function Alien:GetDarkVisionEnabled()

    if Client.GetIsControllingPlayer() then
        return self.darkVisionOn
    else
        return self.darkVisionSpectatorOn
    end    

end

local alienVisionEnabled = true
local function ToggleAlienVision(enabled)
    alienVisionEnabled = enabled ~= "false"
end
Event.Hook("Console_alienvision", ToggleAlienVision)

function Alien:UpdateClientEffects(deltaTime, isLocal)

    Player.UpdateClientEffects(self, deltaTime, isLocal)
    
    // If we are dead, close the evolve menu.
    if isLocal and not self:GetIsAlive() and self:GetBuyMenuIsDisplaying() then
        self:CloseMenu()
    end
    
    self:UpdateEmpoweredEffect(isLocal)
    
    if isLocal and self:GetIsAlive() then
    
        local darkVisionFadeAmount = 1
        local darkVisionFadeTime = 0.2
        local darkVisionPulseTime = 4
        local darkVisionState = self:GetDarkVisionEnabled()

        if self.lastDarkVisionState ~= darkVisionState then

            if darkVisionState then
            
                self.darkVisionTime = Shared.GetTime()
                self:TriggerEffects("alien_vision_on") 
                
            else
            
                self.darkVisionEndTime = Shared.GetTime()
                self:TriggerEffects("alien_vision_off")
                
            end
            
            self.lastDarkVisionState = darkVisionState
        
        end
        
        if not darkVisionState then
            darkVisionFadeAmount = Clamp(1 - (Shared.GetTime() - self.darkVisionEndTime) / darkVisionFadeTime, 0, 1)
        end
        
        local useShader = self:GetScreenEffects().darkVision 
        
        if useShader then
        
            useShader:SetActive(alienVisionEnabled)            
            useShader:SetParameter("startTime", self.darkVisionTime)
            useShader:SetParameter("time", Shared.GetTime())
            useShader:SetParameter("amount", darkVisionFadeAmount)
            
        end
        
        self:UpdateRegenerationEffect()
        
    end
    
end

function Alien:GetFirstPersonDeathEffect()
    return kFirstPersonDeathEffect
end

function Alien:UpdateRegenerationEffect()
    
    local GUIRegenerationFeedback = ClientUI.GetScript("GUIRegenerationFeedback")
    if GUIRegenerationFeedback and GetHasRegenerationUpgrade(self) and GUIRegenerationFeedback:GetIsAnimating() then
    
        if self.lastHealth then
        
            if self.lastHealth < self:GetHealth() then
            
                GUIRegenerationFeedback:TriggerRegenEffect()
                local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
                cinematic:SetCinematic(kRegenerationViewCinematic)
                
            end
            
        end
        
        self.lastHealth = self:GetHealth()
        
    end
    
end

function Alien:UpdateMisc(input)

    Player.UpdateMisc(self, input)
    
    if not Shared.GetIsRunningPrediction() then

        // Close the buy menu if it is visible when the Alien moves.
        if input.move.x ~= 0 or input.move.z ~= 0 then
            self:CloseMenu()
        end
        
    end
    
end

// Bring up evolve menu
function Alien:Buy()

    // Don't allow display in the ready room, or as phantom
    if self:GetIsLocalPlayer() then
    
        // The Embryo cannot use the buy menu in any case.
        if self:GetTeamNumber() ~= 0 and not self:isa("Embryo") then
        
            if not self.buyMenu then
            
                self.buyMenu = GetGUIManager():CreateGUIScript("GUIAlienBuyMenu")
                MouseTracker_SetIsVisible(true, "ui/Cursor_MenuDefault.dds", true)
                
            else
                self:CloseMenu()
            end
            
        else
            self:PlayEvolveErrorSound()
        end
        
    end
    
end

function Alien:PlayEvolveErrorSound()

    if not self.timeLastEvolveErrorSound then
        self.timeLastEvolveErrorSound = Shared.GetTime()
    end

    if self.timeLastEvolveErrorSound + 0.5 < Shared.GetTime() then

         self:TriggerInvalidSound()
         self.timeLastEvolveErrorSound = Shared.GetTime()

    end

end

function Alien:OnCountDown()

    Player.OnCountDown(self)
    
    local script = ClientUI.GetScript("GUIAlienHUD")
    if script then
        script:SetIsVisible(false)
    end
    
end

function Alien:OnCountDownEnd()

    Player.OnCountDownEnd(self)
    
    local script = ClientUI.GetScript("GUIAlienHUD")
    if script then
        script:SetIsVisible(true)
    end
    
end

function Alien:GetFirstPersonHitEffectName()
    return kAlienFirstPersonHitEffectName
end

// create some blood on the ground below
local kGroundDistanceBlood = Vector(0, 1, 0)
local kGroundBloodStartOffset = Vector(0, 0.2, 0)
function Alien:OnTakeDamageClient(damage, doer, position)

    if not self.timeLastGroundBloodDecal then
        self.timeLastGroundBloodDecal = 0
    end
    
    if self.timeLastGroundBloodDecal + 0.5 < Shared.GetTime() then
    
        local trace = Shared.TraceRay(self:GetOrigin() + kGroundBloodStartOffset, self:GetOrigin() - kGroundDistanceBlood, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterAll())
        if trace.fraction ~= 1 then
        
            local coords = Coords.GetIdentity()
            coords.origin = trace.endPoint
            coords.yAxis = trace.normal
            coords.zAxis = coords.yAxis:GetPerpendicular()
            coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
        
            self:TriggerEffects("alien_blood_ground", {effecthostcoords = coords})
            
        end
        
        self.timeLastGroundBloodDecal = Shared.GetTime()
        
    end
    
end
