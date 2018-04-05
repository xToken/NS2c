-- ======= Copyright (c) 2012, Unknown Worlds Entertainment, Inc. All rights reserved. ==========
--
-- lua\EquipmentOutline.lua
--
--    Created by:   Andreas Urwalek (andi@unknownworlds.com) and
--                  Max McGuire (max@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local _renderMask = 0x04
local _invRenderMask = bit.bnot(_renderMask)

local _maxDistance = 38
local _maxDistance_Commander = 60
local _enabled = true

kEquipmentOutlineColor = enum { [0]='TSFBlue', 'Green', 'Fuchsia', 'Yellow' }
kEquipmentOutlineColorCount = #kEquipmentOutlineColor+1
    
local lookup = 
{ 
	"Shotgun", --kEquipmentOutlineColor.Green
	"GrenadeLauncher", --kEquipmentOutlineColor.Fuchsia
	"HeavyMachineGun", --kEquipmentOutlineColor.Yellow
}

local _camera
local _screenEffect

function EquipmentOutline_Initialize()

    _camera = Client.CreateRenderCamera()
    _camera:SetTargetTexture("*equipment_outline", false)
    _camera:SetRenderMask(_renderMask)
    _camera:SetIsVisible(false)
    _camera:SetCullingMode(RenderCamera.CullingMode_Frustum)
    _camera:SetRenderSetup("shaders/EquipmentOutlineMask.render_setup")
    
    _screenEffect = Client.CreateScreenEffect("shaders/EquipmentOutline.screenfx")
    _screenEffect:SetActive(false)
    
end

function EquipmentOutline_Shudown()

    Client.DestroyRenderCamera( _camera )
    _camera = nil
    
    Client.DestroyScreenEffect( _screenEffect )
    _screenEffect = nil
    
end

-- Enables or disabls the hive vision effect. When the effect is not needed it should
-- be disabled to boost performance.
function EquipmentOutline_SetEnabled(enabled)
    
    _camera:SetIsVisible( enabled and _enabled )
    _screenEffect:SetActive(enabled and _enabled)
    
end

-- Must be called prior to rendering
function EquipmentOutline_SyncCamera(rendercamera, forCommander)

    local distance = ConditionalValue(forCommander, _maxDistance_Commander, _maxDistance)

    _camera:SetCoords(rendercamera:GetCoords())
    _camera:SetFov(rendercamera:GetFov())
    _camera:SetFarPlane(distance + 1)

end

-- Adds a model to the hive vision
function EquipmentOutline_AddModel(model,weaponclass)

    local renderMask = model:GetRenderMask()
    model:SetRenderMask(bit.bor(renderMask, _renderMask ))
    
    local outlineid = Clamp( weaponclass or kEquipmentOutlineColor.TSFBlue, 0, kEquipmentOutlineColorCount )
    model:SetMaterialParameter("outline", outlineid/kEquipmentOutlineColorCount + 0.5/kEquipmentOutlineColorCount )

end

-- Removes a model from the hive vision
function EquipmentOutline_RemoveModel(model)

    local renderMask = model:GetRenderMask()
    model:SetRenderMask(bit.band(renderMask, _invRenderMask))

end

function EquipmentOutline_UpdateModel(forEntity)

    local player = Client.GetLocalPlayer()

    -- Check if player can pickup this item or if player is a spectator
    local highlightDroppedWeapon = player ~= nil and ((player:GetTeamNumber() == kSpectatorIndex and Client.GetOutlinePlayers()) or player:isa("MarineCommander")) and forEntity:isa("Weapon") and forEntity.weaponWorldState == true
    local visible = (player ~= nil and forEntity:GetIsValidRecipient(player)) or highlightDroppedWeapon
    local model = HasMixin(forEntity, "Model") and forEntity:GetRenderModel() or nil

    if forEntity:isa("WeaponAmmoPack") then
        model = forEntity:GetRenderModel() or nil
        visible = player ~= nil and player:GetActiveWeapon() and player:GetActiveWeapon():isa(forEntity:GetWeaponClassName())
    end

    local weaponclass = 0
    for i=1,#lookup do
        if forEntity:isa( lookup[i] ) then
            weaponclass = i
            break
        end
    end

    -- Update the visibility status.
    if model and visible ~= model.equipmentVisible then    
    
        if visible then
            EquipmentOutline_AddModel(model,weaponclass)
        else
            EquipmentOutline_RemoveModel(model)
        end
        model.equipmentVisible = visible

    end

end

-- For debugging.
local function OnCommandOutline(enabled)
    _enabled = enabled ~= "false" and enabled ~= "0"
end

Event.Hook("Console_outline", OnCommandOutline)