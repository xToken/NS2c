// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\GUIOrders.lua
//
// Created by: Charlie Cleveland (charlie@unknownworlds.com)
//
// Manages the orders that are drawn for selected units for the Commander.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Removed aliencommander logic

Script.Load("lua/DynamicMeshUtility.lua")

class 'GUIOrders' (GUIScript)

GUIOrders.kOrderImageName = "ui/buildmenu.dds"

GUIOrders.kOrderTextureSize = 80
GUIOrders.kDefaultOrderSize = 25
GUIOrders.kMaxOrderSize = 200

GUIOrders.kOrderObstructedColor = Color(1, 1, 1, .75)
GUIOrders.kOrderVisibleColor = Color(1, 1, 1, 0)

function GUIOrders:Initialize()

    self.activeOrderList = { }
    self.currentFrame = 0
    
end

function GUIOrders:Uninitialize()

    for i, orderModel in ipairs(self.activeOrderList) do
        Client.DestroyRenderModel(orderModel.circle)
        Client.DestroyRenderDynamicMesh(orderModel.line)
    end
    self.activeOrderList = { }
    
end

function GUIOrders:Update(deltaTime)

    PROFILE("GUIOrders:Update")

    self:UpdateOrderList(PlayerUI_GetOrderInfo())
    
end

function GUIOrders:UpdateOrderList(orderList)
    
    local numElementsPerOrder = 5
    local numOrders = table.count(orderList) / numElementsPerOrder
    
    while numOrders > table.count(self.activeOrderList) do
        local newOrderItem = self:CreateOrderItem()       
        table.insert(self.activeOrderList, newOrderItem)
    end

    while table.count(self.activeOrderList) > numOrders do
        local orderModel = self.activeOrderList[table.count(self.activeOrderList)]
        Client.DestroyRenderModel(orderModel.circle)
        Client.DestroyRenderDynamicMesh(orderModel.line)
        table.remove(self.activeOrderList, table.count(self.activeOrderList))
    end    
    
    // Update current order state.
    local currentIndex = 1
    local orderIndex = 1
    
    local sin = math.sin(Shared.GetTime())
    local cos = math.cos(Shared.GetTime())
    local xAxis = Vector(sin * sin, 0, cos * cos)
    
    local player = Client.GetLocalPlayer()
    local showLine = false
    
    if player and player:isa("Commander") then
        showLine = true
    end    
    
    while numOrders > 0 do
    
        local updateOrder = self.activeOrderList[orderIndex]        
        
        local radius = 1
        local orderLocation = orderList[currentIndex + 2]
        local orderSource = orderList[currentIndex + 4]
        local coords = Coords.GetLookIn( orderLocation + Vector(0, kZFightingConstant, 0), xAxis )
        coords:Scale( radius * 2 )
        updateOrder.circle:SetCoords(coords)
        numOrders = numOrders - 1
        
        UpdateOrderLine(orderSource, orderLocation, updateOrder.line)
        
        currentIndex = currentIndex + numElementsPerOrder
        orderIndex = orderIndex + 1
        
        // hide the line in case the local player is not a commander
        updateOrder.line:SetIsVisible(showLine and (orderSource ~= Vector(0, 0, 0)))
        
    end

end

function GUIOrders:CreateOrderItem()
    
    local player = Client.GetLocalPlayer()
    local modelName = Commander.kMarineCircleModelName
    local lineMaterial = Commander.kMarineLineMaterialName
    
    local modelIndex = Shared.GetModelIndex(modelName)
    local circleModel = Client.CreateRenderModel(RenderScene.Zone_Default)
    circleModel:SetModel(modelIndex)
    circleModel:SetIsVisible(false)

    local lineModel = Client.CreateRenderDynamicMesh(RenderScene.Zone_Default)
    lineModel:SetMaterial(lineMaterial)
    
    return { circle = circleModel, line = lineModel }
    
end