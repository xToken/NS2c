// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\CloakableMixin.lua    
//    
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

CloakableMixin = CreateMixin( CloakableMixin )
CloakableMixin.type = "Cloakable"

CloakableMixin.kCloakRate = 0.5
CloakableMixin.kUnCloakRate = 3

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/cloaked.surface_shader")

local Coords_GetTranslation = Coords.GetTranslation
local Client_GetLocalPlayer

if Client then
    Client_GetLocalPlayer = Client.GetLocalPlayer
end

local kCloakedMaxSpeed = 4

// This is needed so alien structures can be cloaked, but not marine structures
CloakableMixin.expectedCallbacks =
{
    GetTeamNumber = "Gets team number",
}

CloakableMixin.optionalCallbacks =
{
    GetIsCloakable = "Return true/false if this object can be cloaked.",
    OnCloak = "Called when entity becomes fully cloaked",
}

CloakableMixin.networkVars =
{
    cloaked = "boolean",
    fullyCloaked = "boolean",
    cloakedFraction = "interpolated float (0 to 1 by 0.01)"
}

function CloakableMixin:__initmixin()

    self.cloaked = false
    self.cloakedFraction = 0
    self.timeOfCloak = nil
    self.cloakChargeTime = 0
    self.cloakTime = nil
    
end

function CloakableMixin:SetIsCloaked(state, cloakTime, force)

    ASSERT(type(state) == "boolean")
    ASSERT(not state or type(cloakTime) == "number")
    ASSERT(not state or (cloakTime > 0))

    // Can't cloak if we recently attacked, unless forced
    if not state or self:GetChargeTime() == 0 or force then
    
        self.cloaked = state
        
        if self.cloaked then
        
            self.timeOfCloak = Shared.GetTime()
            if cloakTime then
                self.cloakTime = cloakTime
            end
            
        else
        
            self.timeOfCloak = nil
            self.cloakTime = nil
            
        end
        
    end
    
end

function CloakableMixin:GetCanCloak()

    local canCloak = true
    
    if self.GetCanCloakOverride then
        canCloak = self:GetCanCloakOverride()
    end
    
    if HasMixin(self, "Detectable") and self:GetDecloaked() then
        canCloak = false
    end
    
    return canCloak and self:GetChargeTime() == 0

end

function CloakableMixin:GetIsCloaked()
    return self.fullyCloaked
end

function CloakableMixin:GetTimeOfCloak()
    return self.timeOfCloak
end

function CloakableMixin:TriggerUncloak()

    self:SetIsCloaked(false)
    self.fullyCloaked = false
    
    // Whenever we Trigger and Uncloak we are charged a little time
    self:SetCloakChargeTime(0.5)
    
end

function CloakableMixin:GetChargeTime()
    return self.cloakChargeTime
end

function CloakableMixin:SetCloakChargeTime(value)
    if self.cloakChargeTime < value then
        self.cloakChargeTime = value
    end
end

function CloakableMixin:GetCloakedFraction()
    return self.cloakedFraction
end

local function UpdateCloakState(self, deltaTime)

    local currentTime = Shared.GetTime()
    if self.cloaked and (self.cloakTime ~= nil and (currentTime > self.timeOfCloak + self.cloakTime)) then
        self:SetIsCloaked(false)
    end
    
    self.cloakChargeTime = math.max(0, self.cloakChargeTime - deltaTime)
    
    local cloakSpeedFraction = 1
    
    if self.GetSpeedScalar then
        cloakSpeedFraction = 1 - Clamp(self:GetSpeedScalar(), 0, 1)
    end
    
    if (self.cloaked or ( self.GetIsCamouflaged and self:GetIsCamouflaged() )) and self:GetCanCloak() then
        self.cloakedFraction = math.min(1, self.cloakedFraction + deltaTime * CloakableMixin.kCloakRate * cloakSpeedFraction )
    else
        self.cloakedFraction = math.max(0, self.cloakedFraction - deltaTime * CloakableMixin.kUnCloakRate )
    end
    
    // for smoother movement
    if Server then
    
        local newFullyCloaked = self.fullyCloaked
        self.fullyCloaked = self.cloakedFraction == 1
        if self.OnCloak and (newFullyCloaked ~= self.fullyCloaked) then
            self:OnCloak()
        end
        
    end    
    
end

if Server then

    function CloakableMixin:OnUpdate(deltaTime)
        UpdateCloakState(self, deltaTime)
    end

    function CloakableMixin:OnProcessMove(input)
        UpdateCloakState(self, input.time)
    end
    
elseif Client then

    function CloakableMixin:OnUpdateRender()

        PROFILE("CloakableMixin:OnUpdateRender")
        
        local player = Client_GetLocalPlayer()
    
        local newHiddenState = self:GetIsCloaked()
        local areEnemies = GetAreEnemies(self, player)
        if self.clientCloaked ~= newHiddenState then
        
            if self.clientCloaked ~= nil then
                self:TriggerEffects("client_cloak_changed", {cloaked = newHiddenState, enemy = areEnemies})
            end
            self.clientCloaked = newHiddenState

        end
        
        // cloaked aliens off infestation are not 100% hidden
        local speedScalar = 0
        
        if self.GetVelocityLength then
            speedScalar = self:GetVelocityLength() / kCloakedMaxSpeed
        end
             
        self:SetOpacity(1-self.cloakedFraction, "cloak")

        if self == player then
        
            local viewModelEnt = self:GetViewModelEntity()            
            if viewModelEnt then
                viewModelEnt:SetOpacity(1-self.cloakedFraction, "cloak")
            end
        
        end
        
        local showMaterial = not areEnemies
        local model = self:GetRenderModel()
    
        if model then

            if showMaterial then
                
                if not self.cloakedMaterial then
                    self.cloakedMaterial = AddMaterial(model, "cinematics/vfx_materials/cloaked.material")
                end
                
                self.cloakedMaterial:SetParameter("cloakAmount", self.cloakedFraction)   
            
            else
            
                if self.cloakedMaterial then
                    RemoveMaterial(model, self.cloakedMaterial)
                    self.cloakedMaterial = nil
                end
            
            end
            
            if self == player then
                
                local viewModelEnt = self:GetViewModelEntity()
                if viewModelEnt and viewModelEnt:GetRenderModel() then
                
                    if not self.cloakedViewMaterial then
                        self.cloakedViewMaterial = AddMaterial(viewModelEnt:GetRenderModel(), "cinematics/vfx_materials/cloaked.material")
                    end
                    
                    self.cloakedViewMaterial:SetParameter("cloakAmount", self.cloakedFraction)
                    
                end
                
            end
            
        end    
 
    end
    
end

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
        
    end
    
end

function CloakableMixin:OnJump()

    if self.fullyCloaked then
        TEST_EVENT("Uncloaked from jumping")
    end
    
    self:TriggerUncloak()
    
end

function CloakableMixin:OnClampSpeed(input, velocity)

    PROFILE("CloakableMixin:OnClampSpeed")
    
    if self:GetIsCloaked() and bit.band(input.commands, Move.Jump) == 0 and (self.GetIsOnSurface and self:GetIsOnSurface()) then
    
        local moveSpeed = velocity:GetLength()
        if moveSpeed > kCloakedMaxSpeed then
            velocity:Scale(kCloakedMaxSpeed / moveSpeed)
        end
        
    end
    
end

if Client then

    function CloakableMixin:OnGetIsVisible(visibleTable)

        local player = Client.GetLocalPlayer()    

        if self:GetIsCloaked() and GetAreEnemies(self, player) then
            visibleTable.Visible = false
        end    
        
    end

end