// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =====
//
// lua\InputHandler.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

// The ConsoleBindings.lua ConsoleBindingsKeyPressed function is used below.
// It is possible for the OnSendKeyEvent function below to be called
// before ConsoleBindings.lua is loaded so make sure to load it here.
Script.Load("lua/ConsoleBindings.lua")
Script.Load("lua/menu/MouseTracker.lua")

local keyEventBlocker = nil
local moveInputBlocked = false

local _keyBinding =
{
    MoveForward = InputKey.W,
    MoveLeft = InputKey.A,
    MoveBackward = InputKey.S,
    MoveRight = InputKey.D,
    Jump = InputKey.Space,
    MovementModifier = InputKey.LeftShift,
    Crouch = InputKey.LeftControl,
    Scoreboard = InputKey.Tab,
    PrimaryAttack = InputKey.MouseButton0,
    SecondaryAttack = InputKey.MouseButton1,
    Reload = InputKey.R,
    Use = InputKey.E,
    Drop = InputKey.G,
    Buy = InputKey.B,
    Eject = InputKey.I,
    ShowMap = InputKey.C,
    VoiceChat = InputKey.LeftAlt,
    TextChat = InputKey.Y,
    TeamChat = InputKey.Return,
    Weapon1 = InputKey.Num1,
    Weapon2 = InputKey.Num2,
    Weapon3 = InputKey.Num3,
    Weapon4 = InputKey.Num4,
    Weapon5 = InputKey.Num5,
    ToggleConsole = InputKey.Grave,
    ToggleFlashlight = InputKey.F,
    ReadyRoom = InputKey.F4,
    RequestMenu = InputKey.X,
    RequestHealth = InputKey.Q,
    RequestAmmo = InputKey.Z,
    RequestOrder = InputKey.H,
    Taunt = InputKey.T,
    PingLocation = InputKey.MouseButton2,
    VoteYes = InputKey.VoteYes,
    VoteNo = InputKey.VoteNo,
    SelectNextWeapon = InputKey.MouseWheelUp,
    SelectPrevWeapon = InputKey.MouseWheelDown,
    QuickSwitch = InputKey.V,
	LastUpgrades = InputKey.None,
	ToggleMinimapNames = InputKey.None,
    ScrollForward = InputKey.Up,
    ScrollBackward = InputKey.Down,
    ScrollLeft = InputKey.Left,
    ScrollRight = InputKey.Right,
	Grid1 = InputKey.Q,
    Grid2 = InputKey.W,
    Grid3 = InputKey.E,
    Grid4 = InputKey.A,
    Grid5 = InputKey.S,
    Grid6 = InputKey.D,
    Grid7 = InputKey.F,
    Grid8 = InputKey.Z,
    Grid9 = InputKey.X,
    Grid10 = InputKey.C,
    Grid11 = InputKey.V,
    VoiceChatCom = InputKey.LeftAlt,
    TextChatCom = InputKey.Y,
    TeamChatCom = InputKey.Return,
    ShowMapCom = InputKey.C,
    Q = InputKey.Q,
    W = InputKey.W,
    E = InputKey.E,
    R = InputKey.R,
    T = InputKey.T,
    Y = InputKey.Y,
    U = InputKey.U,
    I = InputKey.I,
    O = InputKey.O,
    P = InputKey.P,
    A = InputKey.A,
    S = InputKey.S,
    D = InputKey.D,
    F = InputKey.F,
    G = InputKey.G,
    H = InputKey.H,
    J = InputKey.J,
    K = InputKey.K,
    L = InputKey.L,
    Z = InputKey.Z,
    X = InputKey.X,
    C = InputKey.C,
    B = InputKey.B,
    N = InputKey.N,
    M = InputKey.M,
    V = InputKey.V,
    ESC = InputKey.Escape,
    Space = InputKey.Space
}

local _mouseAccel = 1.0
local _sensitivityScalarX = 1.0
local _sensitivityScalarY = 1.0
local _cameraYaw = 0
local _cameraPitch = 0
local _keyState = { }
local _keyPressed = { }

local _bufferedCommands = 0
local _lastProcessedCommands = 0
local _bufferedMove = Vector(0, 0, 0)
local _bufferedHotKey = 0

// Provide support for these functions that were removed from the API in Build 237
function Client.SetYaw(yaw)
    _cameraYaw = yaw
end

function Client.SetPitch(pitch)
    _cameraPitch = pitch
end

function Client.GetYaw()
    return _cameraYaw
end

function Client.GetPitch()
    return _cameraPitch
end

// Provide support for these functions that were removed from the API in Build 237
function Client.SetMouseSensitivityScalar(sensitivityScalar)

    _sensitivityScalarX = sensitivityScalar
    _sensitivityScalarY = sensitivityScalar
    
end

function Client.SetMouseSensitivityScalarX(sensitivityScalarX)
    _sensitivityScalarX = sensitivityScalarX
end

function Client.SetMouseSensitivityScalarY(sensitivityScalarY)
    _sensitivityScalarY = sensitivityScalarY
end

function Client.GetMouseSensitivityScalar()
    return _sensitivityScalarX
end

function SetKeyEventBlocker(setKeyEventBlocker)
    keyEventBlocker = setKeyEventBlocker
end

function SetMoveInputBlocked(blocked)
    moveInputBlocked = blocked
end

/**
 * This will update the internal state to match the settings that have been
 * specified in the options. This function should be called when the options
 * have been updated.
 */
function Input_SyncInputOptions()
    
    // Sync the key bindings.
    for action, _ in pairs(_keyBinding) do
        local keyName = Client.GetOptionString( "input/" .. action, "" )

        // The number keys are stored as 1, 2, etc. but the enum name is Num1, Num2, etc.        
        if tonumber(keyName) then
            keyName = "Num" .. keyName
        end
        
        local key = InputKey[keyName]
        if key ~= nil then
            _keyBinding[action] = key
        end
        
    end
    
    // Sync the acceleration and sensitivity.
    _mouseAccel = Client.GetOptionFloat("input/mouse/acceleration-amount", 1.0);
    if not Client.GetOptionBoolean("input/mouse/acceleration", false) then
        _mouseAccel = 1.0
    end

end

/**
 * Adjusts the mouse movement to take into account the sensitivity setting and
 * and any mouse acceleration.
 */
local function ApplyMouseAdjustments(amount, sensitivity)
    
    // This value matches what the GoldSrc/Source engine uses, so that
    // players can use the values they are familiar with.
    local rotateScale = 0.00038397243
    
    local sign = 1.0
    if amount < 0 then
        sign = -1.0
    end
    
    return sign * math.pow(math.abs(amount * rotateScale), _mouseAccel) * sensitivity
    
end

/**
 * Called by the engine whenever a key is pressed or released. Return true if
 * the event should be stopped here.
 */
local function OnSendKeyEvent(key, down, amount, repeated)

    local stop = MouseTracker_SendKeyEvent(key, down, amount, keyEventBlocker ~= nil)
    
    if keyEventBlocker then
        return keyEventBlocker:SendKeyEvent(key, down, amount)
    end
    
    if not stop then
        stop = GetGUIManager():SendKeyEvent(key, down, amount)
    end
    
    if not stop then
    
        local winMan = GetWindowManager()
        if winMan then
            stop = winMan:SendKeyEvent(key, down, amount)
        end
        
    end
    
    if not stop then
    
        if not Client.GetMouseVisible() then
        
            if key == InputKey.MouseX then
                _cameraYaw = _cameraYaw - ApplyMouseAdjustments(amount, _sensitivityScalarX)
            elseif key == InputKey.MouseY then
            
                local limit = math.pi / 2 + 0.0001
                _cameraPitch = Math.Clamp(_cameraPitch + ApplyMouseAdjustments(amount, _sensitivityScalarY), -limit, limit)
                
            end
            
        end

        // need to handle mousewheel actions in another way, those use only key up events        
        if key == InputKey.MouseWheelDown or key == InputKey.MouseWheelUp then
        
            _keyState[key] = true
            _keyPressed[key] = 1
        
        // Filter out the OS key repeat for our general movement (but we'll use it for GUI).
        elseif not repeated then
        
            _keyState[key] = down
            if down and not moveInputBlocked then
                _keyPressed[key] = amount
            end
    
        end    
    
    end
    
    if not stop then
    
        local player = Client.GetLocalPlayer()
        if player then
            stop = player:SendKeyEvent(key, down)
        end
        
    end

    if not stop and down then
        ConsoleBindingsKeyPressed(key)
    end
    
    return stop
    
end

// Return true if the event should be stopped here.
local function OnSendCharacterEvent(character)

    local stop = false
    
    local winMan = GetWindowManager()
    if winMan then
        stop = winMan:SendCharacterEvent(character)
    end
    
    if not stop then
        stop = GetGUIManager():SendCharacterEvent(character)
    end
    
    return stop
    
end

local function AdjustMoveForInversion(move)

    // Invert mouse if specified in options.
    local invertMouse = Client.GetOptionBoolean(kInvertedMouseOptionsKey, false)
    if invertMouse then
        move.pitch = -move.pitch
    end
    
end

local function GenerateMove()

    local move = Move()
    
    move.yaw = _cameraYaw
    move.pitch = _cameraPitch
    
    AdjustMoveForInversion(move)
    
    if not moveInputBlocked then
    
        if _keyPressed[ _keyBinding.Exit ] then
            move.commands = bit.bor(move.commands, Move.Exit)
        end
        if _keyState[ _keyBinding.Buy ] then
            move.commands = bit.bor(move.commands, Move.Buy)
        end
        if _keyState[ _keyBinding.Eject ] then
            move.commands = bit.bor(move.commands, Move.Eject)
        end
        
        if _keyState[ _keyBinding.MoveForward ] then
            move.move.z = move.move.z + 1
        end
        if _keyState[ _keyBinding.MoveBackward ] then
            move.move.z = move.move.z - 1
        end
        if _keyState[ _keyBinding.MoveLeft ] then
            move.move.x = move.move.x + 1
        end
        if _keyState[ _keyBinding.MoveRight ] then
            move.move.x = move.move.x - 1
        end    
        
        if _keyState[ _keyBinding.Jump ] then
            move.commands = bit.bor(move.commands, Move.Jump)
        end    
        if _keyState[ _keyBinding.Crouch ] then
            move.commands = bit.bor(move.commands, Move.Crouch)
        end    
        if _keyState[ _keyBinding.MovementModifier ] then
            move.commands = bit.bor(move.commands, Move.MovementModifier)
        end    
        
        if _keyState[ _keyBinding.ScrollForward ] then
            move.commands = bit.bor(move.commands, Move.ScrollForward)
        end     
        if _keyState[ _keyBinding.ScrollBackward ] then
            move.commands = bit.bor(move.commands, Move.ScrollBackward)
        end     
        if _keyState[ _keyBinding.ScrollLeft ] then
            move.commands = bit.bor(move.commands, Move.ScrollLeft)
        end     
        if _keyState[ _keyBinding.ScrollRight ] then
            move.commands = bit.bor(move.commands, Move.ScrollRight)
        end     
        
        if _keyPressed[ _keyBinding.ToggleRequest ] then
            move.commands = bit.bor(move.commands, Move.ToggleRequest)
        end
        if _keyPressed[ _keyBinding.ToggleSayings ] then
            move.commands = bit.bor(move.commands, Move.ToggleSayings)
        end

        // FPS action relevant to spectator
        if _keyPressed[ _keyBinding.SelectNextWeapon ] then
            move.commands = bit.bor(move.commands, Move.SelectNextWeapon)
        end

        if _keyPressed[ _keyBinding.SelectPrevWeapon ] then    
            move.commands = bit.bor(move.commands, Move.SelectPrevWeapon)
        end    
        
        if _keyPressed[ _keyBinding.Weapon1 ] then
            move.commands = bit.bor(move.commands, Move.Weapon1)
        end
        if _keyPressed[ _keyBinding.Weapon2 ] then
            move.commands = bit.bor(move.commands, Move.Weapon2)
        end
        if _keyPressed[ _keyBinding.Weapon3 ] then
            move.commands = bit.bor(move.commands, Move.Weapon3)
        end
        if _keyPressed[ _keyBinding.Weapon4 ] then
            move.commands = bit.bor(move.commands, Move.Weapon4)
        end
        if _keyPressed[ _keyBinding.Weapon5 ] then
            move.commands = bit.bor(move.commands, Move.Weapon5)
        end
        if _keyPressed[ _keyBinding.QuickSwitch ] then
            move.commands = bit.bor(move.commands, Move.QuickSwitch)
        end

        if _keyState[ _keyBinding.Use ] then
            move.commands = bit.bor(move.commands, Move.Use)
        end
        if _keyPressed[ _keyBinding.ToggleFlashlight ] then
            move.commands = bit.bor(move.commands, Move.ToggleFlashlight)
        end
        if _keyState[ _keyBinding.PrimaryAttack ] then
            move.commands = bit.bor(move.commands, Move.PrimaryAttack)
        end
        if _keyState[ _keyBinding.SecondaryAttack ] then
            move.commands = bit.bor(move.commands, Move.SecondaryAttack)
        end
        if _keyState[ _keyBinding.Reload ] then
            move.commands = bit.bor(move.commands, Move.Reload)
        end
            
        if _keyPressed[ _keyBinding.Drop ] then
            move.commands = bit.bor(move.commands, Move.Drop)
        end
      
        if _keyPressed[ _keyBinding.Taunt ] then
            move.commands = bit.bor(move.commands, Move.Taunt)
        end
        
        // Handle the hot keys used for commander mode.
        
        if _keyPressed[ _keyBinding.Q ] then
            move.hotkey = Move.Q
        end 
        if _keyPressed[ _keyBinding.W ] then
            move.hotkey = Move.W
        end 
        if _keyPressed[ _keyBinding.E ] then
            move.hotkey = Move.E
        end 
        if _keyPressed[ _keyBinding.R ] then
            move.hotkey = Move.R
        end 
        if _keyPressed[ _keyBinding.T ] then
            move.hotkey = Move.T
        end 
        if _keyPressed[ _keyBinding.Y ] then
            move.hotkey = Move.Y
        end         
        if _keyPressed[ _keyBinding.U ] then
            move.hotkey = Move.U
        end 
        if _keyPressed[ _keyBinding.I ] then
            move.hotkey = Move.I
        end 
        if _keyPressed[ _keyBinding.O ] then
            move.hotkey = Move.O
        end 
        if _keyPressed[ _keyBinding.P ] then
            move.hotkey = Move.P
        end  
        if _keyPressed[ _keyBinding.A ] then
            move.hotkey = Move.A
        end   
        if _keyPressed[ _keyBinding.S ] then
            move.hotkey = Move.S
        end     
        if _keyPressed[ _keyBinding.D ] then
            move.hotkey = Move.D
        end     
        if _keyPressed[ _keyBinding.F ] then
            move.hotkey = Move.F
        end       
        if _keyPressed[ _keyBinding.G ] then
            move.hotkey = Move.G
        end       
        if _keyPressed[ _keyBinding.H ] then
            move.hotkey = Move.H
        end   
        if _keyPressed[ _keyBinding.J ] then
            move.hotkey = Move.J
        end         
        if _keyPressed[ _keyBinding.K ] then
            move.hotkey = Move.K
        end         
        if _keyPressed[ _keyBinding.L ] then
            move.hotkey = Move.L
        end         
        if _keyPressed[ _keyBinding.Z ] then
            move.hotkey = Move.Z
        end         
        if _keyPressed[ _keyBinding.X ] then
            move.hotkey = Move.X
        end   
        if _keyPressed[ _keyBinding.C ] then
            move.hotkey = Move.C
        end   
        if _keyPressed[ _keyBinding.V ] then
            move.hotkey = Move.V
        end   
        if _keyPressed[ _keyBinding.B ] then
            move.hotkey = Move.B
        end
        if _keyPressed[ _keyBinding.N ] then
            move.hotkey = Move.N
        end
        if _keyPressed[ _keyBinding.M ] then
            move.hotkey = Move.M
        end
        if _keyPressed[ _keyBinding.Space ] then
            move.hotkey = Move.Space
        end
        if _keyPressed[ _keyBinding.ESC ] then
            move.hotkey = Move.ESC
        end
        
        // Allow the player to override move (needed for Commander)
        local player = Client.GetLocalPlayer()
        if player and Client.GetIsControllingPlayer() then
            move = player:OverrideInput(move)
        end
        
        _keyPressed = { }
        _keyState[InputKey.MouseWheelDown] = false
        _keyState[InputKey.MouseWheelUp] = false
        
    end
    
    return move
    
end

local function BufferMove(move)

    _bufferedMove.x = math.max(math.min(_bufferedMove.x + move.move.x, 1), -1)
    _bufferedMove.y = math.max(math.min(_bufferedMove.y + move.move.y, 1), -1)
    _bufferedMove.z = math.max(math.min(_bufferedMove.z + move.move.z, 1), -1)

    // Detect changes in the commands
    local changedCommands = bit.bxor( _lastProcessedCommands, _bufferedCommands )
    _bufferedCommands = bit.bor(
            bit.band( _bufferedCommands, changedCommands ), 
            bit.band( move.commands, bit.bnot(changedCommands) )
        )
        
    if move.hotkey ~= 0 then
        _bufferedHotKey = move.hotkey
    end
    
end

local function OnProcessGameInput()

    local move = GenerateMove()
    BufferMove(move)
    
    // Apply the buffered input.
    
    move.move     = _bufferedMove
    move.commands = _bufferedCommands

    if _bufferedHotKey ~= 0 then
        move.hotkey = _bufferedHotKey
        _bufferedHotKey = 0
    end    
    
    _lastProcessedCommands = _bufferedCommands
    _bufferedMove          = Vector(0, 0, 0)
    
    if Client then
        Client.OnProcessGameInput(move)
    end
    
    return move

end

local function OnProcessMouseInput()
    local move = GenerateMove()
    BufferMove(move)
    return move
end

Event.Hook("ProcessGameInput",      OnProcessGameInput)
Event.Hook("ProcessMouseInput",     OnProcessMouseInput)
Event.Hook("SendKeyEvent",          OnSendKeyEvent)
Event.Hook("SendCharacterEvent",    OnSendCharacterEvent)
