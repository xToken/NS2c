// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\OrdersMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)    
//    
// ========= For more information, visit us at http://www.unknownworlds.com =====================    

Script.Load("lua/FunctionContracts.lua")
Script.Load("lua/TechTreeConstants.lua")
Script.Load("lua/PhysicsGroups.lua")

OrdersMixin = { }
OrdersMixin.type = "Orders"

OrdersMixin.expectedCallbacks =
{
    // GetExtents() is required by GetGroundAt().
    GetExtents = "Returns a Vector describing the extents of this Entity."
}

OrdersMixin.expectedConstants =
{
    kMoveOrderCompleteDistance = "How close to the move location we must be until the order is complete."
}

local kTimeSinceDamageDefendComplete = 10
local kDefendCompleteDistance = 5

OrdersMixin.kMaxOrdersPerUnit = 10
OrdersMixin.kOrderDelay = 0.2

OrdersMixin.networkVars =
{
    // The currentOrderId is needed on the Client for displaying
    // to other players such as the Commander.
    currentOrderId  = "entityid"
}

function OrdersMixin:__initmixin()

    self.ignoreOrders = false
    self.currentOrderId = Entity.invalidId
    
    // Current orders. List of order entity ids.
    self.orders = { }
    
end

local function OrderChanged(self)

    if self:GetHasOrder() then
    
        self.currentOrderId = self.orders[1]
        local order = Shared.GetEntity(self.currentOrderId)
    
    else
        self.currentOrderId = Entity.invalidId
    end
    
    if self.OnOrderChanged then
        self:OnOrderChanged()
    end
    
end
AddFunctionContract(OrderChanged, { Arguments = { "Entity" }, Returns = { } })

function OrdersMixin:TransferOrders(dest)
    
    table.copy(self.orders, dest.orders)
    OrderChanged(dest)
    
    table.clear(self.orders)
    OrderChanged(self)
    
end
AddFunctionContract(OrdersMixin.TransferOrders, { Arguments = { "Entity", "Entity" }, Returns = { } })

function OrdersMixin:CopyOrdersTo(dest)
    
    for index, orderId in ipairs(self.orders) do

        local orderCopy = GetCopyFromOrder(Shared.GetEntity(orderId))
        
        table.insert(dest.orders, orderCopy:GetId())
        
    end

    OrderChanged(dest)
    
end
AddFunctionContract(OrdersMixin.CopyOrdersTo, { Arguments = { "Entity", "Entity" }, Returns = { } })

function OrdersMixin:GetHasOrder()
    return self:GetNumOrders() > 0
end
AddFunctionContract(OrdersMixin.GetHasOrder, { Arguments = { "Entity" }, Returns = { "boolean" } })

function OrdersMixin:GetNumOrders()
    return table.count(self.orders)
end
AddFunctionContract(OrdersMixin.GetNumOrders, { Arguments = { "Entity" }, Returns = { "number" } })

function OrdersMixin:SetIgnoreOrders(setIgnoreOrders)
    self.ignoreOrders = setIgnoreOrders
end
AddFunctionContract(OrdersMixin.SetIgnoreOrders, { Arguments = { "Entity", "boolean" }, Returns = { } })

function OrdersMixin:GetIgnoreOrders()
    return self.ignoreOrders
end
AddFunctionContract(OrdersMixin.GetIgnoreOrders, { Arguments = { "Entity" }, Returns = { "boolean" } })

local function SetOrder(self, order, clearExisting, insertFirst, giver, reusedOrder)

    if self.ignoreOrders or order:GetType() == kTechId.Default then
        return false
    end
    
    if clearExisting and not reusedOrder then
        self:ClearOrders()
    end
    
    // Always snap the location of the order to the ground.
    local location = order:GetLocation()
    if location then
    
        location = GetGroundAt(self, location, PhysicsMask.AIMovement)
        order:SetLocation(location)
        
    end
    
    if giver == nil or not giver:isa("Player") then
    
        giver = self:GetOwner()
        if giver == nil then
            giver = self
        end
        
    end
    
    order:SetOwner(giver)
    
    if not reusedOrder then
    
        if insertFirst then
            table.insert(self.orders, 1, order:GetId())
        else    
            table.insert(self.orders, order:GetId())
        end
        
    end
    
    self.timeLastOrder = Shared.GetTime()
    OrderChanged(self)
    
    return true
    
end
AddFunctionContract(SetOrder, { Arguments = { "Entity", "Order", "boolean", "boolean", { "Entity", "nil" } }, Returns = { "boolean" } })

/**
 * Children can provide a OnOverrideOrder function to issue build, construct, etc. orders on right-click.
 */
local function OverrideOrder(self, order)

    if self.OnOverrideOrder then
        self:OnOverrideOrder(order)
    elseif order:GetType() == kTechId.Default then
        order:SetType(kTechId.Move)
    end
    
end
AddFunctionContract(OverrideOrder, { Arguments = { "Entity", "Order" }, Returns = { } })

local function OrderTargetInvalid(self, targetId)

    local invalid = false
    
    if targetId and targetId ~= Entity.invalidId  then
    
        local target = Shared.GetEntity(targetId)
        invalid = target and ( target:isa("ResourcePoint") or target:isa("TechPoint") 
                  or (target:isa("CommandStructure") and GetAreEnemies(self, target) and not target:GetIsSighted()) )
    
    end

    return invalid

end

function OrdersMixin:GiveOrder(orderType, targetId, targetOrigin, orientation, clearExisting, insertFirst, giver)

    ASSERT(type(orderType) == "number")
    
    if self.ignoreOrders or OrderTargetInvalid(self, targetId) or ( #self.orders > OrdersMixin.kMaxOrdersPerUnit or (self.timeLastOrder and self.timeLastOrder + OrdersMixin.kOrderDelay > Shared.GetTime()) )  then
        return kTechId.None
    end
    
    // prevent AI units from attack friendly players
    if orderType == kTechId.Attack then
    
        local target = Shared.GetEntity(targetId)
        if target and target:isa("Player") and target:GetTeamNumber() == self:GetTeamNumber() and not GetGamerules():GetFriendlyFire() then
            return
        end
        
    end
    
    if clearExisting == nil then
        clearExisting = true
    end
    
    if insertFirst == nil then
        insertFirst = true
    end
    
    local order = nil
    local reusedOrder = false
    
    if clearExisting and self:GetHasOrder() then
    
        order = self:GetCurrentOrder()
        order:Initialize(orderType, targetId, targetOrigin, tonumber(orientation))
        reusedOrder = true
        
    else
        order = CreateOrder(orderType, targetId, targetOrigin, orientation)
    end
    
    OverrideOrder(self, order)
    
    local success = SetOrder(self, order, clearExisting, insertFirst, giver, reusedOrder)
    
    if success and self.OnOrderGiven then
        self:OnOrderGiven(order)
    end    
    
    return ConditionalValue(success, order:GetType(), kTechId.None)
    
end
AddFunctionContract(OrdersMixin.GiveOrder, { Arguments = { "Entity", "number", "number", { "Vector", "nil" }, { "Vector", "nil" }, { "boolean", "nil" }, { "boolean", "nil" }, { "Entity", "nil" } }, Returns = { "number" } })

function OrdersMixin:GiveSharedOrder(order, clearExisting, insertFirst, giver)

    ASSERT(type(orderType) == "number")
    ASSERT(type(targetId) == "number")
    
    if self.ignoreOrders or ( #self.orders > OrdersMixin.kMaxOrdersPerUnit or (self.timeLastOrder and self.timeLastOrder + OrdersMixin.kOrderDelay > Shared.GetTime()) ) then
        return kTechId.None
    end
    
    // prevent AI units from attack friendly players
    if orderType == kTechId.Attack then
    
        local target = Shared.GetEntity(targetId)
        if target and target:isa("Player") and target:GetTeamNumber() == self:GetTeamNumber() and not GetGamerules():GetFriendlyFire() then
            return
        end
    
    end

    if clearExisting == nil then
        clearExisting = true
    end
    
    if insertFirst == nil then
        insertFirst = true
    end

    //OverrideOrder(self, order)
    
    SetOrder(self, order, clearExisting, insertFirst, giver, reusedOrder)
    
    if self.OnOrderGiven then
        self:OnOrderGiven(order)
    end    
    
    return order:GetType()

end
AddFunctionContract(OrdersMixin.GiveSharedOrder, { Arguments = { "Entity", "Entity", { "boolean", "nil" }, { "boolean", "nil" }, { "Entity", "nil" } }, Returns = { "number" } })


local function DestroyOrders(self)
    
    // Allow ents to hook destruction of current order.
    local first = true
    
    // Delete all order entities.
    for index, orderEntId in ipairs(self.orders) do
    
        local orderEnt = Shared.GetEntity(orderEntId)
        ASSERT(orderEnt ~= nil)
        
        if first then
        
            if self.OnDestroyCurrentOrder and orderEnt ~= nil then
                self:OnDestroyCurrentOrder(orderEnt)
            end
            first = false
            
        end
        
        if orderEnt then
            if orderEnt:isa("SharedOrder") then
                orderEnt:Unregister(self)
            else
                DestroyEntity(orderEnt)  
            end
        end    
        
    end
    
    table.clear(self.orders)

end
AddFunctionContract(DestroyOrders, { Arguments = { "Entity" }, Returns = { } })

function OrdersMixin:ClearOrders()

    if table.count(self.orders) > 0 then
    
        DestroyOrders(self)
        OrderChanged(self)
        
    end
    
end
AddFunctionContract(OrdersMixin.ClearOrders, { Arguments = { "Entity" }, Returns = { } })

function OrdersMixin:Reset()
    self:ClearOrders()
end
AddFunctionContract(OrdersMixin.Reset, { Arguments = { "Entity" }, Returns = { } })

function OrdersMixin:OnKill()
    self:ClearOrders()
end
AddFunctionContract(OrdersMixin.OnKill, { Arguments = { "Entity" }, Returns = { } })

function OrdersMixin:GetHasSpecifiedOrder(orderEnt)

    ASSERT(orderEnt ~= nil and orderEnt.GetId ~= nil)
    
    for index, orderEntId in ipairs(self.orders) do
        if orderEntId == orderEnt:GetId() then
            return true
        end
    end
    
    return false

end
AddFunctionContract(OrdersMixin.GetHasSpecifiedOrder, { Arguments = { "Entity", "Order" }, Returns = { "boolean" } })

function OrdersMixin:GetCurrentOrder()

    if self.currentOrderId ~= Entity.invalidId then
        return Shared.GetEntity(self.currentOrderId)
    end
    return nil
    
end
AddFunctionContract(OrdersMixin.GetCurrentOrder, { Arguments = { "Entity" }, Returns = { { "Order", "nil" } } })

function OrdersMixin:ClearCurrentOrder()

    //Print("%s:ClearCurrentOrder", self:GetClassName())

    local currentOrder = self:GetCurrentOrder()
    if currentOrder then
    
        if currentOrder:isa("SharedOrder") then
            currentOrder:Unregister(self)
        else
            DestroyEntity(currentOrder)
        end
        
        table.remove(self.orders, 1)
        
    end
    
    OrderChanged(self)
    
end
AddFunctionContract(OrdersMixin.ClearCurrentOrder, { Arguments = { "Entity" }, Returns = { } })

function OrdersMixin:CompletedCurrentOrder()

    //Print("%s:CompletedCurrentOrder", self:GetClassName())

    local currentOrder = self:GetCurrentOrder()
    if currentOrder then
    
        if self.OnOrderComplete then
            self:OnOrderComplete(currentOrder)
        end
    
        self:ClearCurrentOrder()
        
    end
    
end
AddFunctionContract(OrdersMixin.CompletedCurrentOrder, { Arguments = { "Entity" }, Returns = { } })

// Convert rally orders to move and we're done.
function OrdersMixin:ProcessRallyOrder(originatingEntity)

    if self.ignoreOrders then
        return
    end
    
    originatingEntity:CopyOrdersTo(self)
    
    for index, orderId in ipairs(self.orders) do
    
        local order = Shared.GetEntity(orderId)
        ASSERT(order ~= nil)
        
        if order:GetType() == kTechId.SetRally then
            order:SetType(kTechId.Move)
        end
        
    end
    
end
AddFunctionContract(OrdersMixin.ProcessRallyOrder, { Arguments = { "Entity", "Entity" }, Returns = { } })

if Server then

    local function TriggerOrderCompletedAlert(self)
    
        if HasMixin(self, "Team") then
                
            local teamType = self:GetTeam():GetTeamType()

            if teamType == kMarineTeamType then
                self:GetTeam():TriggerAlert(kTechId.MarineAlertOrderComplete, self)
            else
                self:GetTeam():TriggerAlert(kTechId.AlienAlertOrderComplete, self)
            end

        end
    
    end

    local function SharedUpdate(self)

        local currentOrder = self:GetCurrentOrder()
        
        if currentOrder ~= nil then
            
            // we update the order source only for units that enable it, otherwise it's hidden
            if self.GetShowOrderLine and self:GetShowOrderLine() then
                currentOrder:SetOrderSource(self:GetOrigin())
            end
            
            local orderType = currentOrder:GetType()
            
            if orderType == kTechId.Move then
            
                if (currentOrder:GetLocation() - self:GetOrigin()):GetLength() < self:GetMixinConstants().kMoveOrderCompleteDistance then
                
                    TriggerOrderCompletedAlert(self)
                    self:CompletedCurrentOrder()
                    
                end
            
            elseif orderType == kTechId.Construct then
            
                local orderTarget = Shared.GetEntity(currentOrder:GetParam())
                
                if orderTarget == nil or not orderTarget:GetIsAlive() then
                    self:ClearOrders()                    
                elseif orderTarget:GetIsBuilt() then
                    self:CompletedCurrentOrder()
                    TriggerOrderCompletedAlert(self)
                end
                
            elseif orderType == kTechId.Weld or orderType == kTechId.Heal or orderType == kTechId.AutoWeld or orderType == kTechId.AutoHeal then

                local orderTarget = Shared.GetEntity(currentOrder:GetParam())
                
                if orderTarget then
                    currentOrder:SetLocation(orderTarget:GetOrigin())
                end
                
                // clear weld targets which are too far away for players
                local tooFarAway = (orderType == kTechId.AutoWeld or orderType == kTechId.AutoHeal) and orderTarget and self:isa("Player") and (orderTarget:GetOrigin() - self:GetOrigin()):GetLength() > 20
                
                if orderTarget == nil or not orderTarget:GetIsAlive() or tooFarAway then
                    self:ClearOrders()
                elseif orderTarget:GetHealthScalar() >= 1 or (orderTarget:isa("Marine") and orderTarget:GetArmor() / orderTarget:GetMaxArmor() >= 1) then
                    self:CompletedCurrentOrder()
                    TriggerOrderCompletedAlert(self)
                end
            
            elseif orderType == kTechId.Attack then
            
                local orderTarget = Shared.GetEntity(currentOrder:GetParam())
                
                if orderTarget and (HasMixin(orderTarget, "LOS") and orderTarget:GetIsSighted()) then
                    currentOrder:SetLocation(orderTarget:GetOrigin())
                end
                
                if not orderTarget or orderTarget:GetId() == Entity.invalidId then
                
                    // AI units needs to be able to attack locations
                    if not currentOrder.allowLocationAttack or not currentOrder:GetLocation() then
                    
                         self:ClearOrders()
                        
                    end
                    
                // If given an order to a Live entity, clear the order when that entity is dead.
                // Do not clear the order for non-live entities as there are cases we need to
                // attack non-live entities.
                elseif HasMixin(orderTarget, "Live") and not orderTarget:GetIsAlive() then
                
                    TriggerOrderCompletedAlert(self)
                    self:CompletedCurrentOrder()
                    
                end
                
            elseif orderType == kTechId.Defend then
            
                local orderTarget = Shared.GetEntity(currentOrder:GetParam())
                local orderTargetIsLive = orderTarget ~= nil and HasMixin(orderTarget, "Live")
                
                // If the orderTarget hasn't taken damage yet, GetTimeOfLastDamage() will return nil.
                // In this case, just use the time the order was issued to decide when to destroy it below.
                local lastDamageTime = (orderTargetIsLive and orderTarget:GetTimeOfLastDamage()) or 0
                if lastDamageTime < currentOrder:GetOrderTime() then
                    lastDamageTime = currentOrder:GetOrderTime()
                end
                
                if not orderTarget or orderTarget:GetId() == Entity.invalidId or
                   not orderTargetIsLive or not orderTarget:GetIsAlive() then
                
                    self:ClearOrders()
                    
                elseif orderTargetIsLive and (Shared.GetTime() - lastDamageTime) > kTimeSinceDamageDefendComplete then
                
                    // Only complete if self is close enough to the target.
                    if (self:GetOrigin() - orderTarget:GetOrigin()):GetLengthSquared() < (kDefendCompleteDistance * kDefendCompleteDistance) then
                    
                        TriggerOrderCompletedAlert(self)
                        self:CompletedCurrentOrder()
                        
                    else
                        self:ClearOrders()
                    end
                    
                end
                
            end
            
        end
        
    end
    
    function OrdersMixin:OnUpdate(deltaTime)

        PROFILE("OrdersMixin:OnUpdate")

        SharedUpdate(self)
        
    end
    AddFunctionContract(OrdersMixin.OnUpdate, { Arguments = { "Entity", "number" }, Returns = { } })

    function OrdersMixin:OnProcessMove(input)

        PROFILE("OrdersMixin:OnProcessMove")

        SharedUpdate(self)
        
    end
    AddFunctionContract(OrdersMixin.OnProcessMove, { Arguments = { "Entity", "Move" }, Returns = { } })

end

// Note: This needs to be tested.
// Get target of attack order, if any.
function OrdersMixin:GetTarget()

    local target = nil

    local order = self:GetCurrentOrder()
    if order ~= nil and (order:GetType() == kTechId.Attack or order:GetType() == kTechId.SetTarget) then
        target = Shared.GetEntity(order:GetParam())
    end
    
    return target
    
end

// Note: This needs to be tested.
function OrdersMixin:PerformAction(techNode, position)
    self:OnPerformAction(techNode, position)
end

/**
 * Other mixins can implement this function to handle more specific actions.
 * Called when tech tree action is performed on the entity.
 * Return true if legal and action handled. Position passed if applicable.
 */
function OrdersMixin:OnPerformAction(techNode, position)

    if techNode:GetTechId() == kTechId.Stop then
        self:ClearOrders()
    end
    
end

function OrdersMixin:CopyPlayerDataFrom(player)

    if HasMixin(player, "Orders") then
        player:TransferOrders(self)
    end
    
end