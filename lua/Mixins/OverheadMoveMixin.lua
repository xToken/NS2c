// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======    
//    
// lua\Mixins\OverheadMoveMixin.lua    
//    
//    Created by:   Brian Cronin (brianc@unknownworlds.com)
//
//    Move the player with an overhead. Take care of map, so avoid to go out the map.
//    Set the height according to heightmap
//    
// =========== For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/BaseMoveMixin.lua")

local kZoomVelocity = 60
local kMaxZoomHeight = 50
OverheadMoveMixin = CreateMixin(OverheadMoveMixin)
OverheadMoveMixin.type = "OverheadMove"

OverheadMoveMixin.networkVars =
{
    overheadMoveEnabled = "private boolean",
    --overheadModeHeight = "private float (0 to " .. kMaxZoomHeight .. " by 0.01)"
}

OverheadMoveMixin.expectedMixins =
{
    BaseMove = "Give basic method to handle player or entity movement"
}

OverheadMoveMixin.expectedCallbacks =
{
    SetOrigin     = "Set the position of the player",
    GetViewAngles = "Returns the current view angles"
}

OverheadMoveMixin.defaultConstants =
{
    kScrollVelocity = 40,
    kDefaultHeight  = 11
}

function OverheadMoveMixin:__initmixin()
    self.overheadMoveEnabled = true
    --self.overheadModeHeight = self:GetMixinConstant("kDefaultHeight")
end

function OverheadMoveMixin:SetOverheadMoveEnabled(enabled)
    self.overheadMoveEnabled = enabled
end

local function GetOverheadMove(self, input)

    local move = input.move
    
    if bit.band(input.commands, Move.ScrollForward) ~= 0 then
        move.z = 1
    end
    
    if bit.band(input.commands, Move.ScrollBackward) ~= 0 then
        move.z = -1
    end
    
    if bit.band(input.commands, Move.ScrollLeft) ~= 0 then
        move.x = 1
    end
    
    if bit.band(input.commands, Move.ScrollRight) ~= 0 then
        move.x = -1
    end
    
    return move
    
end

local function UpdateHeight(self, input)

    local velocity = 0
    if bit.band(input.commands, Move.SelectNextWeapon) ~= 0 then
        velocity = -kZoomVelocity
    end
    
    if bit.band(input.commands, Move.SelectPrevWeapon) ~= 0 then
        velocity = kZoomVelocity
    end
    
    --self.overheadModeHeight = Clamp(self.overheadModeHeight + velocity * input.time, 0, kMaxZoomHeight)
    
end

function OverheadMoveMixin:OverrideMove(input)

    if Client.GetIsWindowFocused() and self.overheadMoveEnabled then
    
        local mouseX, mouseY = Client.GetCursorPosScreen()
        local screenWidth = Client.GetScreenWidth()
        local screenHeight = Client.GetScreenHeight()
        
        if mouseX <= 2 then
            input.commands = bit.bor(input.commands, Move.ScrollLeft)
        elseif mouseX >= screenWidth - 2 then
            input.commands = bit.bor(input.commands, Move.ScrollRight)
        end
        
        if mouseY <= 2 then
            input.commands = bit.bor(input.commands, Move.ScrollForward)
        elseif mouseY >= screenHeight - 2 then
            input.commands = bit.bor(input.commands, Move.ScrollBackward)
        end
        
    end
    
    return input
    
end

/**
 * Move the player with an overhead point of view.
 */
function OverheadMoveMixin:UpdateMove(input)

    if not self.overheadMoveEnabled then
        return
    end
    
    local move = GetOverheadMove(self, input)
    --UpdateHeight(self, input)
    local position = Vector()
    
    local angles = self:GetViewAngles()
    local velocity = Angles(0, math.pi / 2, 0):GetCoords():TransformVector(move) * self:GetMixinConstant("kScrollVelocity")
    
    position = self:GetOrigin() + velocity * input.time
    position = self:ConstrainToOverheadPosition(position)
    
    self:SetOrigin(position)
    
end

/**
 * Make sure that the position is not outside of the map
 * and give the correct height according to the heightmap.
 */
function OverheadMoveMixin:ConstrainToOverheadPosition(position)
    
    local heightmap = GetHeightmap()
    // Remove this next line when enabling zoom mode.
    local height = self:GetMixinConstant("kDefaultHeight")
    
    assert(heightmap ~= nil)
    
    position.x = heightmap:ClampXToMapBounds(position.x)
    position.z = heightmap:ClampZToMapBounds(position.z)
    // Remove this next line when enabling zoom mode.
    position.y = height + heightmap:GetElevation(position.x, position.z)
    --local elevation = heightmap:GetElevation(position.x, position.z)
    --position.y = self.overheadModeHeight + elevation
    
    return position
    
end