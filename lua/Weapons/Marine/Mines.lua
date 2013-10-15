//
// lua\Weapons\Marine\Mines.lua

Script.Load("lua/Weapons/Weapon.lua")
Script.Load("lua/PickupableWeaponMixin.lua")

class 'Mines' (Weapon)

Mines.kMapName = "mines"

local kDropModelName = PrecacheAsset("models/marine/mine/mine_pile.model")
local kHeldModelName = PrecacheAsset("models/marine/mine/mine_3p.model")

local kViewModels = GenerateMarineViewModelPaths("mine")
local kAnimationGraph = PrecacheAsset("models/marine/mine/mine_view.animation_graph")

local kPlacementDistance = 2

local networkVars =
{
    minesLeft = string.format("integer (0 to %d)", kMineCount),
	droppingMine = "boolean"
}

AddMixinNetworkVars(PickupableWeaponMixin, networkVars)

function Mines:OnCreate()

    Weapon.OnCreate(self)
    
    InitMixin(self, PickupableWeaponMixin)
    
    self.minesLeft = kMineCount
	self.droppingMine = false
    
end

function Mines:OnInitialized()

    Weapon.OnInitialized(self)
    
    self:SetModel(kHeldModelName)
    
end

function Mines:GetDropStructureId()
    return kTechId.Mine
end

function Mines:GetMinesLeft()
    return self.minesLeft
end

function Mines:GetViewModelName(sex, variant)
    return kViewModels[sex][variant]
end

function Mines:GetAnimationGraphName()
    return kAnimationGraph
end

function Mines:GetSuffixName()
    return "mine"
end

function Mines:GetWeight()
    return kMinesWeight
end

function Mines:GetDropClassName()
    return "Mine"
end

function Mines:GetDropMapName()
    return Mine.kMapName
end

function Mines:GetHUDSlot()
    return 5
end

function Mines:OnTag(tagName)

    PROFILE("Mines:OnTag")
    
    ClipWeapon.OnTag(self, tagName)
    
    if tagName == "mine" then
    
        local player = self:GetParent()
        if player then
        
            self:PerformPrimaryAttack(player)
            
            if self.minesLeft == 0 then
            
                self:OnHolster(player)
                player:RemoveWeapon(self)
                player:SwitchWeapon(1)
                
                if Server then                
                    DestroyEntity(self)
                end
                
            end
            
        end
        
        self.droppingMine = false
        
    end
    
end

function Mines:OnPrimaryAttackEnd(player)
    self.droppingMine = false
end

function Mines:GetIsDroppable()
    return true
end

function Mines:OnPrimaryAttack(player)

    // Ensure the current location is valid for placement.
    if not player:GetPrimaryAttackLastFrame() then
    
        local showGhost, coords, valid = self:GetPositionForStructure(player)
        if valid then
        
            if self.minesLeft > 0 then
                self.droppingMine = true
            else
            
                self.droppingMine = false
                
                if Client then
                    player:TriggerInvalidSound()
                end
                
            end
            
        else
        
            self.droppingMine = false
            
            if Client then
                player:TriggerInvalidSound()
            end
            
        end
        
    end
    
end

local function DropStructure(self, player)

    if Server then
    
        local showGhost, coords, valid = self:GetPositionForStructure(player)
        if valid then
        
            // Create mine.
            local mine = CreateEntity(self:GetDropMapName(), coords.origin, player:GetTeamNumber())
            if mine then
            
                mine:SetOwner(player)
                
                // Check for space
                if mine:SpaceClearForEntity(coords.origin) then
                
                    local angles = Angles()
                    angles:BuildFromCoords(coords)
                    mine:SetAngles(angles)
                    
                    player:TriggerEffects("create_" .. self:GetSuffixName())
                    
                    // Jackpot.
                    return true
                    
                else
                
                    player:TriggerInvalidSound()
                    DestroyEntity(mine)
                    
                end
                
            else
                player:TriggerInvalidSound()
            end
            
        else
        
            if not valid then
                player:TriggerInvalidSound()
            end
            
        end
        
    elseif Client then
        return true
    end
    
    return false
    
end

function Mines:Refill(amount)
    self.minesLeft = amount
end

function Mines:PerformPrimaryAttack(player)

    local success = true
    
    if self.minesLeft > 0 then
    
        player:TriggerEffects("start_create_" .. self:GetSuffixName())
        
        local viewAngles = player:GetViewAngles()
        local viewCoords = viewAngles:GetCoords()
        
        success = DropStructure(self, player)
        
        if success then
            self.minesLeft = Clamp(self.minesLeft - 1, 0, kMineCount)
        end
        
    end
    
    return success
    
end

function Mines:OnHolster(player, previousWeaponMapName)
    Weapon.OnHolster(self, player, previousWeaponMapName)
	self.droppingMine = false
end

function Mines:OnDraw(player, previousWeaponMapName)

    Weapon.OnDraw(self, player, previousWeaponMapName)
    
    // Attach weapon to parent's hand
    self:SetAttachPoint(Weapon.kHumanAttachPoint)
    
	self.droppingMine = false
    self:SetModel(kHeldModelName)
    
end

function Mines:Dropped(prevOwner)

    Weapon.Dropped(self, prevOwner)
    self.droppedtime = Shared.GetTime()
    self:SetModel(kDropModelName)
    self:RestartPickupScan()

end

function Mines:GetCheckForRecipient()
    return true
end

function Mines:OnTouch(recipient)
    recipient:AddWeapon(self, false)
    StartSoundEffectAtOrigin(Marine.kGunPickupSound, recipient:GetOrigin())
end

// Given a gorge player's position and view angles, return a position and orientation
// for structure. Used to preview placement via a ghost structure and then to create it.
// Also returns bool if it's a valid position or not.
function Mines:GetPositionForStructure(player)

    local isPositionValid = false
    local foundPositionInRange = false
    local structPosition = nil
    
    local origin = player:GetEyePos() + player:GetViewAngles():GetCoords().zAxis * kPlacementDistance
    
    // Trace short distance in front
    local trace = Shared.TraceRay(player:GetEyePos(), origin, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
    
    local displayOrigin = trace.endPoint
    
    // If we hit nothing, trace down to place on ground
    if trace.fraction == 1 then
    
        origin = player:GetEyePos() + player:GetViewAngles():GetCoords().zAxis * kPlacementDistance
        trace = Shared.TraceRay(origin, origin - Vector(0, kPlacementDistance, 0), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
        
    end

    
    // If it hits something, position on this surface (must be the world or another structure)
    if trace.fraction < 1 then
        
        foundPositionInRange = true
    
        if trace.entity == nil then
            isPositionValid = true
        elseif not trace.entity:isa("ScriptActor") and not trace.entity:isa("Clog") then
            isPositionValid = true
        end
        
        displayOrigin = trace.endPoint
    
        // Don't allow dropped structures to go too close to techpoints and resource nozzles
        if GetPointBlocksAttachEntities(displayOrigin) then
            isPositionValid = false
        end
    
        // Don't allow placing above or below us and don't draw either
        local structureFacing = player:GetViewAngles():GetCoords().zAxis
    
        if math.abs(Math.DotProduct(trace.normal, structureFacing)) > 0.9 then
            structureFacing = trace.normal:GetPerpendicular()
        end
    
        // Coords.GetLookIn will prioritize the direction when constructing the coords,
        // so make sure the facing direction is perpendicular to the normal so we get
        // the correct y-axis.
        local perp = Math.CrossProduct(trace.normal, structureFacing)
        structureFacing = Math.CrossProduct(perp, trace.normal)
    
        structPosition = Coords.GetLookIn(displayOrigin, structureFacing, trace.normal)
        
    end
    
    return foundPositionInRange, structPosition, isPositionValid
    
end

function Mines:GetGhostModelName()
    return LookupTechData(self:GetDropStructureId(), kTechDataModel)
end

function Mines:OnUpdateAnimationInput(modelMixin)
    
    PROFILE("Mines:OnUpdateAnimationInput")
    
    modelMixin:SetAnimationInput("activity", ConditionalValue(self.droppingMine, "primary", "none"))
    
end    

if Client then

    function Mines:OnProcessIntermediate(input)
    
        local player = self:GetParent()
        
        if player then
        
            self.showGhost, self.ghostCoords, self.placementValid = self:GetPositionForStructure(player)
            self.showGhost = self.showGhost and self.minesLeft > 0
            
        end
        
    end
    
    function Mines:GetUIDisplaySettings()
        return { xSize = 256, ySize = 417, script = "lua/GUIMineDisplay.lua" }
    end
    
end

function Mines:GetShowGhostModel()
    return self.showGhost
end

function Mines:GetGhostModelCoords()
    return self.ghostCoords
end   

function Mines:GetIsPlacementValid()
    return self.placementValid
end

Shared.LinkClassToMap("Mines", Mines.kMapName, networkVars)