// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\ConstructMixin.lua    
//    
//    Created by:   Andreas Urwalek (andi@unknownworlds.com)
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")

Shared.PrecacheSurfaceShader("cinematics/vfx_materials/build.surface_shader")

ConstructMixin = CreateMixin( ConstructMixin )
ConstructMixin.type = "Construct"

local kBuildEffectsInterval = 1

ConstructMixin.networkVars =
{
    // 0-1 scalar representing build completion time. Since we use this to blend
    // animations, it must be interpolated for the animations to appear smooth
    // on the client.
    buildFraction           = "interpolated float (0 to 1 by 0.01)",
    
    // true if structure finished building
    constructionComplete    = "boolean",

    // Show different material when under construction
    underConstruction       = "boolean"
    
}

ConstructMixin.expectedMixins =
{
    Live = "ConstructMixin manipulates the health when construction progresses."
}

ConstructMixin.expectedCallbacks = 
{
}

ConstructMixin.optionalCallbacks = 
{
    OnConstruct = "Called whenever construction progress changes.",
    OnConstructionComplete = "Called whenever construction is completes.",
    GetCanBeUsedConstructed = "Return true when this entity has a use function when constructed."
    
}

function ConstructMixin:__initmixin()

    // used for client side material effect
    self.underConstruction = false
    self.timeLastConstruct = 0
    self.timeOfNextBuildWeldEffects = 0
    self.buildTime = 0
    self.buildFraction = 0

    // Structures start with a percentage of their full health and gain more as they're built.\
    
    if self.startsBuilt then
        self:SetHealth( self:GetMaxHealth() )
        self:SetArmor( self:GetMaxArmor() )
    else
        self:SetHealth( self:GetMaxHealth() * kStartHealthScalar )
        self:SetArmor( self:GetMaxArmor() * kStartHealthScalar )
    end
    
    self.startsBuilt  = false
    
end

local function CreateBuildEffect(self)

    local model = self:GetRenderModel()
    if not self.buildMaterial and model then
    
        local material = Client.CreateRenderMaterial()
        material:SetMaterial("cinematics/vfx_materials/build.material")
        model:AddMaterial(material)
        self.buildMaterial = material
        
    end    
    
end

local function RemoveBuildEffect(self)

    local model = self:GetRenderModel()
    if self.buildMaterial and model then
    
        local material = self.buildMaterial
        model:RemoveMaterial(material)
        Client.DestroyRenderMaterial(material)
        self.buildMaterial = nil
        
    end            

end

local function SharedUpdate(self, deltaTime)

    if Server then
        
        local effectTimeout = Shared.GetTime() - self.timeLastConstruct > 0.3
        self.underConstruction = not self:GetIsBuilt() and not effectTimeout
        
        // Only Alien structures auto build.
        // Update build fraction every tick to be smooth.
        if not self:GetIsBuilt() and GetIsAlienUnit(self) and self:GetIsAlive() then

            if not self.GetCanAutoBuild or self:GetCanAutoBuild() then
                self:Construct(self:ConstructOverride(deltaTime))
            end
        
        end
        
    elseif Client then
    
        if GetIsMarineUnit(self) then
            if self.underConstruction then
                CreateBuildEffect(self)
            else
                RemoveBuildEffect(self)
            end
        end
    
    end
    
end

function ConstructMixin:ResetConstructionStatus()

    self.buildTime = 0
    self.buildFraction = 0
    self.constructionComplete = false
    
end

function ConstructMixin:OnUpdate(deltaTime)
    SharedUpdate(self, deltaTime)
end
AddFunctionContract(ConstructMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

function ConstructMixin:OnProcessMove(input)
    SharedUpdate(self, input.time)
end
AddFunctionContract(ConstructMixin.OnProcessMove, { Arguments = { "Entity", "Move" }, Returns = { } })

function ConstructMixin:OnUpdateAnimationInput(modelMixin)

    PROFILE("ConstructMixin:OnUpdateAnimationInput")    
    modelMixin:SetAnimationInput("built", self.constructionComplete)
    modelMixin:SetAnimationInput("active", self.constructionComplete) // TODO: remove this and adjust animation graphs
    
end

function ConstructMixin:OnUpdatePoseParameters()

    if HasMixin(self, "Tech") and LookupTechData(self:GetTechId(), kTechDataGrows, false) then
        self:SetPoseParam("grow", 1)
    end
    
end

function GetConstructionTime(self)

    if self.GetConstructionTimeOverride then
        return self:GetConstructionTimeOverride()
    end    
    
    return LookupTechData(self:GetTechId(), kTechDataBuildTime, kDefaultBuildTime)

end    

/**
 * Add health to structure as it builds.
 */
local function AddBuildHealth(self, scalar)

    // Add health according to build time.
    if scalar > 0 then
    
        local maxHealth = self:GetMaxHealth()
        self:AddHealth(scalar * (1 - kStartHealthScalar) * maxHealth, false, false, true)
        
    end
    
end

/**
 * Add health to structure as it builds.
 */
local function AddBuildArmor(self, scalar)

    // Add health according to build time.
    if scalar > 0 then
    
        local maxArmor = self:GetMaxArmor()
        self:SetArmor(self:GetArmor() + scalar * (1 - kStartHealthScalar) * maxArmor, true)
        
    end
    
end

/**
 * Build structure by elapsedTime amount and play construction sounds. Pass custom construction sound if desired, 
 * otherwise use Gorge build sound or Marine sparking build sounds. Returns two values - whether the construct
 * action was successful and if enough time has elapsed so a construction AV effect should be played.
 */
function ConstructMixin:Construct(elapsedTime, builder)

    local success = false
    local playAV = false
    
    if not self.constructionComplete then
        
        if builder and builder.OnConstructTarget then
            builder:OnConstructTarget(self)
        end
        
        if Server then

            local startBuildFraction = self.buildFraction
            local newBuildTime = self.buildTime + elapsedTime
            local timeToComplete = GetConstructionTime(self)
            
            if newBuildTime >= timeToComplete then
            
                self:SetConstructionComplete(builder)
                
                // Give points for building structures
                if self:GetIsBuilt() and not self:isa("Hydra") and builder and HasMixin(builder, "Scoring") then                
                    builder:AddScore(kBuildPointValue)
                end
                
            else
            
                if self.buildTime <= self.timeOfNextBuildWeldEffects and newBuildTime >= self.timeOfNextBuildWeldEffects then
                
                    playAV = true
                    if self:GetTeamNumber() == kAlienTeamType then
                        self.timeOfNextBuildWeldEffects = newBuildTime + (kBuildEffectsInterval / 3)
                    else
                        self.timeOfNextBuildWeldEffects = newBuildTime + kBuildEffectsInterval
                    end
                    
                end
                
                self.buildTime = newBuildTime
                self.buildFraction = math.max(math.min((self.buildTime / timeToComplete), 1), 0)
                
                local scalar = self.buildFraction - startBuildFraction
                AddBuildHealth(self, scalar)
                AddBuildArmor(self, scalar)
                
                if self.oldBuildFraction ~= self.buildFraction then
                
                    if self.OnConstruct then
                        self:OnConstruct(builder, self.buildFraction)
                    end
                    
                    self.oldBuildFraction = self.buildFraction
                    
                end
                
            end
        
        end
        
        success = true
        
    end
    
    return success, playAV
    
end

function ConstructMixin:GetCanBeUsedConstructed()
    return false
end

function ConstructMixin:GetCanBeUsed(player, useSuccessTable)

    if self:GetIsBuilt() and not self:GetCanBeUsedConstructed() then
        useSuccessTable.useSuccess = false
    end
    
end

function ConstructMixin:SetConstructionComplete(builder)

    // Construction cannot resurrect the dead.
    if self:GetIsAlive() then
    
        local wasComplete = self.constructionComplete
        self.constructionComplete = true
        
        AddBuildHealth(self, 1 - self.buildFraction)
        AddBuildArmor(self, 1 - self.buildFraction)
        
        self.buildFraction = 1
        
        if wasComplete ~= self.constructionComplete then
            self:OnConstructionComplete(builder)
        end
        
    end
    
end


function ConstructMixin:GetCanConstruct(constructor)

    if self.GetCanConstructOverride then
        return self:GetCanConstructOverride(constructor)
    end
    
    return not self:GetIsBuilt() and GetAreFriends(self, constructor) and self:GetIsAlive() and
           (not constructor or constructor:isa("Marine") or constructor:isa("Gorge"))
    
end

function ConstructMixin:OnUse(player, elapsedTime, useSuccessTable)

    local used = false

    if self:GetCanConstruct(player) then        

        // Always build by set amount of time, for AV reasons
        // Calling code will put weapon away we return true

        local success, playAV = self:Construct(kUseInterval, player)
        
        if success then

            if playAV then
                self:TriggerEffects("construct", {classname = self:GetClassName(), isalien = GetIsAlienUnit(self)})
            end
            
            self.timeLastConstruct = Shared.GetTime()
            self.underConstruction = true
            
            used = true
        
        end
                
    end
    
    useSuccessTable.useSuccess = useSuccessTable.useSuccess or used
    
end

function ConstructMixin:GetIsBuilt()
    return self.constructionComplete
end

function ConstructMixin:OnConstructionComplete(builder)

    local team = HasMixin(self, "Team") and self:GetTeam()
    
    if team then

        if self.GetCompleteAlertId then
            team:TriggerAlert(self:GetCompleteAlertId(), self)
            
        elseif GetIsMarineUnit(self) then
        
            self:TriggerEffects("deploy")          
            team:TriggerAlert(kTechId.MarineAlertConstructionComplete, self)
            
        end

        team:OnConstructionComplete(self)

    end     

    self:TriggerEffects("construction_complete")
    
end    

function ConstructMixin:GetBuiltFraction()
    return self.buildFraction
end

if Server then

    function ConstructMixin:Reset()

        if self.startsBuilt then
            self:SetConstructionComplete()
        end
        
    end

    function ConstructMixin:OnInitialized()

        self.startsBuilt = GetAndCheckBoolean(self.startsBuilt, "startsBuilt", false)

        if (self.startsBuilt and not self:GetIsBuilt()) or GetGamerules():GetAutobuild() then
            self:SetConstructionComplete()
        end
        
    end

end

function ConstructMixin:GetEffectParams(tableParams)

    tableParams[kEffectFilterBuilt] = self:GetIsBuilt()
        
end
