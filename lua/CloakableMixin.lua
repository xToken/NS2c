// ======= Copyright (c) 2003-2013, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\CloakableMixin.lua    
//    
// Handles both cloaking and camouflage. Effects are identical except cloaking can also hide
// structures (camouflage is only for players).
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

//NS2c
//Added in ghost cloaking logic

CloakableMixin = CreateMixin(CloakableMixin)
CloakableMixin.type = "Cloakable"

// Uncloak faster than cloaking
CloakableMixin.kCloakRate = 2
CloakableMixin.kUncloakRate = 12
CloakableMixin.kTriggerCloakDuration = .6
CloakableMixin.kTriggerUncloakDuration = 2.5

local kPlayerMaxCloak = 0.75

local kEnemyUncloakDistanceSquared = 1.5 ^ 2

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/cloaked.surface_shader")

local Client_GetLocalPlayer

if Client then
    Client_GetLocalPlayer = Client.GetLocalPlayer
end

CloakableMixin.expectedMixins =
{
    EntityChange = "Required to update lastTouchedEntityId."
}

CloakableMixin.optionalCallbacks =
{
    OnCloak = "Called when entity becomes fully cloaked",
    GetSpeedScalar = "Called to figure out how fast we're moving, if we can move",
    GetIsCamouflaged = "Aliens that can evolve camouflage have this",
}

CloakableMixin.networkVars =
{
    // set server side to true when cloaked fraction is 1
    fullyCloaked = "boolean",
    // so client knows in which direction to update the cloakFraction
    cloakingDesired = "boolean",
    cloakRate = "integer (0 to 3)"
}

function CloakableMixin:__initmixin()

    if Server then
        self.cloakingDesired = false
        self.fullyCloaked = false
    end
    
    self.desiredCloakFraction = 0
    self.timeCloaked = 0
    self.timeUncloaked = 0    
    
    // when entity is created on client consider fully cloaked, so units wont show up for a short moment when going through a phasegate for example
    self.cloakFraction = self.fullyCloaked and 1 or 0
    
end

function CloakableMixin:GetCanCloak()

    local canCloak = true
    
    if self.GetCanCloakOverride then
        canCloak = self:GetCanCloakOverride()
    end
    
    return canCloak 

end

function CloakableMixin:GetIsCloaked()
    return self.fullyCloaked
end

function CloakableMixin:TriggerCloak()

    if self:GetCanCloak() then
        self.timeCloaked = Shared.GetTime() + CloakableMixin.kTriggerCloakDuration
    end
    
end

function CloakableMixin:TriggerUncloak()
    self.timeUncloaked = Shared.GetTime() + CloakableMixin.kTriggerUncloakDuration
end

function CloakableMixin:GetCloakFraction()
    return self.cloakFraction
end

local function UpdateDesiredCloakFraction(self, deltaTime)

    if Server then
    
        self.cloakingDesired = false
    
        // Animate towards uncloaked if triggered
        if Shared.GetTime() > self.timeUncloaked and (not HasMixin(self, "Detectable") or not self:GetIsDetected()) then
            
            // Uncloaking takes precedence over cloaking
            if Shared.GetTime() < self.timeCloaked then        
                self.cloakingDesired = true
                self.cloakRate = 3
            elseif self.GetIsCamouflaged and self:GetIsCamouflaged() then
                
                self.cloakingDesired = true
                
                if self:isa("Player") then
                    self.cloakRate = GetShades(self:GetTeamNumber())
                else
                    self.cloakRate = 3
                end
                
            end
            
        end
    
    end
    
    local newDesiredCloakFraction = self.cloakingDesired and 1 or 0
    
    // Update cloaked fraction according to our speed and max speed
    if newDesiredCloakFraction == 1 and self.GetSpeedScalar then
        newDesiredCloakFraction = 1 - self:GetSpeedScalar()
    end
    
    if newDesiredCloakFraction ~= nil then
        self.desiredCloakFraction = Clamp(newDesiredCloakFraction, 0, self:isa("Player") and (kGhostCloakingPerLevel * self.cloakRate) or 1)
    end
    
end

local function UpdateCloakState(self, deltaTime)

    // Account for trigger cloak, uncloak, camouflage speed
    UpdateDesiredCloakFraction(self, deltaTime)
    
    // Animate towards desired/internal cloak fraction (so we never "snap")
    local rate = (self.desiredCloakFraction > self.cloakFraction) and CloakableMixin.kCloakRate * (self.cloakRate / 3) or CloakableMixin.kUncloakRate

    local newCloak = Clamp(Slerp(self.cloakFraction, self.desiredCloakFraction, deltaTime * rate), 0, 1)
    
    if newCloak ~= self.cloakFraction then
    
        local callOnCloak = (newCloak == 1) and (self.cloakFraction ~= 1) and self.OnCloak
        self.cloakFraction = newCloak
        
        if callOnCloak then
            self:OnCloak()
        end
        
    end

    if Server then
    
        self.fullyCloaked = self:GetCloakFraction() >= kPlayerMaxCloak
        
        if self.lastTouchedEntityId then
        
            local enemyEntity = Shared.GetEntity(self.lastTouchedEntityId)
            if enemyEntity and (self:GetOrigin() - enemyEntity:GetOrigin()):GetLengthSquared() < kEnemyUncloakDistanceSquared then
                self:TriggerUncloak()
            else
                self.lastTouchedEntityId = nil
            end
        
        end
        
    end
    
end



function CloakableMixin:OnUpdate(deltaTime)
    UpdateCloakState(self, deltaTime)
end

function CloakableMixin:OnProcessMove(input)
    UpdateCloakState(self, input.time)
end

function CloakableMixin:OnProcessSpectate(deltaTime)
    UpdateCloakState(self, deltaTime)
end    

if Server then

    function CloakableMixin:OnEntityChange(oldId)
    
        if oldId == self.lastTouchedEntityId then
            self.lastTouchedEntityId = nil
        end

    end
    
elseif Client then

    function CloakableMixin:OnUpdateRender()

        PROFILE("CloakableMixin:OnUpdateRender")

        self:_UpdateOpacity()
        
        local model = self:GetRenderModel()
    
        if model then

            local player = Client_GetLocalPlayer()

            self:_UpdatePlayerModelRender(model)        
            
            // Now process view model            
            if self == player then                
                self:_UpdateViewModelRender()                
            end
            
        end
 
    end

    function CloakableMixin:_UpdateOpacity()
    
        local player = Client_GetLocalPlayer()
    
        // Only draw models when mostly uncloaked
        local albedoVisibility = 1 - Clamp(self.cloakFraction * 5, 0, 1)
        
        if player and ((player.GetDarkVisionEnabled and player:GetDarkVisionEnabled()) or player:isa("AlienCommander") )then
            albedoVisibility = 1
        end
    
        // cloaked aliens off infestation are not 100% hidden             
        local opacity = albedoVisibility
        self:SetOpacity(opacity, "cloak")
        
        if self == player then
        
            local viewModelEnt = self:GetViewModelEntity()            
            if viewModelEnt then
                viewModelEnt:SetOpacity(opacity, "cloak")
            end
        
        end

    end
    
    function CloakableMixin:_UpdatePlayerModelRender(model)
    
        local player = Client_GetLocalPlayer()
        local hideFromEnemy = GetAreEnemies(self, player) and self:GetCloakFraction() == 1
        
        local useMaterial = (self.cloakingDesired or self:GetCloakFraction() ~= 0) and not hideFromEnemy
    
        if not self.cloakedMaterial and useMaterial then
            self.cloakedMaterial = AddMaterial(model, "cinematics/vfx_materials/cloaked.material")
        elseif self.cloakedMaterial and not useMaterial then
        
            RemoveMaterial(model, self.cloakedMaterial)
            self.cloakedMaterial = nil
            
        end

        if self.cloakedMaterial then

            // show it animated for the alien commander. the albedo texture needs to remain visible for outline so we show cloaked in a different way here
            local distortAmount = self.cloakFraction
            if player and player:isa("AlienCommander") then            
                distortAmount = distortAmount * 0.5 + math.sin(Shared.GetTime() * 0.05) * 0.05            
            end
            
            // Main material parameter that affects our appearance
            self.cloakedMaterial:SetParameter("cloakAmount", self.cloakFraction)
            self.cloakedMaterial:SetParameter("distortAmount", distortAmount)         
            
            // Boost emissive for friendly units, so we can see each other
            local friendly = not GetAreEnemies(self, player) and 1 or 0
            // Boost is 0 to 1
            self.cloakedMaterial:SetParameter("friendly", friendly)      

        end          

    end
    
    function CloakableMixin:_UpdateViewModelRender()
    
        local viewModelEnt = self:GetViewModelEntity()
        if viewModelEnt and viewModelEnt:GetRenderModel() then
        
            // Show view model as enemies see us, so we know how cloaked we are
            if not self.cloakedViewMaterial then
                self.cloakedViewMaterial = AddMaterial(viewModelEnt:GetRenderModel(), "cinematics/vfx_materials/cloaked.material")
            end
            
            self.cloakedViewMaterial:SetParameter("cloakAmount", self.cloakFraction)
            self.cloakedViewMaterial:SetParameter("distortAmount", self.cloakFraction)
            
            // Don't boost emissive for view model though, so we can see what it looks like
            self.cloakedViewMaterial:SetParameter("friendly", 0)
            
        end
        
    end
    
end

// Pass negative to uncloak
function CloakableMixin:OnScan()

    if self.fullyCloaked then
        TEST_EVENT("Uncloaked from Scan")
    end
    
    self:TriggerUncloak()
    
end

function CloakableMixin:PrimaryAttack()

    if self.fullyCloaked then
        TEST_EVENT("Uncloaked from Primary Attack")
    end
    
    self:TriggerUncloak()
    
end

function CloakableMixin:OnGetIsSelectable(result, byTeamNumber)
    result.selectable = result.selectable and (byTeamNumber == self:GetTeamNumber() or not self:GetIsCloaked())
end

function CloakableMixin:SecondaryAttack()

    local weapon = self:GetActiveWeapon()
    if weapon and weapon:GetHasSecondary(self) then
    
        if self.fullyCloaked then
            TEST_EVENT("Uncloaked from Secondary Attack")
        end
        
        self:TriggerUncloak()
        
    end
    
end

function CloakableMixin:OnTakeDamage(damage, attacker, doer, point)

    if self.fullyCloaked then
        TEST_EVENT("Uncloaked from taking damage")
    end
    
    self:TriggerUncloak()
    
end

function CloakableMixin:OnCapsuleTraceHit(entity)

    if GetAreEnemies(self, entity) then
    
        if self.fullyCloaked then
            TEST_EVENT("Uncloaked from being touched")
        end
        
        self:TriggerUncloak()
        self.lastTouchedEntityId = entity:GetId()
        
    end
    
end

function CloakableMixin:OnJump()

    if self.fullyCloaked then
        TEST_EVENT("Uncloaked from jumping")
    end
    
    self:TriggerUncloak()
    
end
