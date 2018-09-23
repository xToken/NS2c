-- NS2c_Client.lua

Script.Load("lua/NS2c_Shared.lua")
Script.Load("lua/ns2c/Mixins/EEMSupport.lua")
Script.Load("lua/ns2c/NS2cGameStrings.lua")

local kAmbientTrackTime = 180
local lastAmbientUpdate = math.random(30, 60)
local kAmbientMusicTrack = "sound/ns2c.fev/ns2c/ui/ambient_music"

function UpdateAmbientMusic(deltaTime)
    
    PROFILE("Client:UpdateAmbientMusic")
    
    if Client.ambientMusic == nil then
        local listenerOrigin = Vector(0, 0, 0)
        Client.ambientMusic = AmbientSound()
        Client.ambientMusic.eventName = kAmbientMusicTrack
        Client.ambientMusic.minFalloff = 999
        Client.ambientMusic.maxFalloff = 1000
        Client.ambientMusic.falloffType = 2
        Client.ambientMusic.positioning = 2
        Client.ambientMusic.volume = 1
        Client.ambientMusic.pitch = 0
        Client.PrecacheLocalSound(kAmbientMusicTrack)
    else
        if lastAmbientUpdate < Shared.GetTime() then
            Client.ambientMusic:StopPlaying()
            Client.ambientMusic:StartPlaying()
            lastAmbientUpdate = Shared.GetTime() + kAmbientTrackTime
        end
    end
    
end

function UpdatePowerPointLights()
end

function DestroyAmbientMusic()

	if Client.ambientMusic then
        Client.ambientMusic:OnDestroy()
    end
    Client.ambientMusic = nil
	
end

local oldDestroyLevelObjects = DestroyLevelObjects

function DestroyLevelObjects()
	oldDestroyLevelObjects()
	DestroyAmbientMusic()
end

local oldOnUpdateClient = OnUpdateClient

function OnUpdateClient(deltaTime)
	oldOnUpdateClient(deltaTime)
	UpdateAmbientMusic(deltaTime)
end

local function OnNS2cLoadComplete()
	Client.SendNetworkMessage("MovementMode", {movement = Client.GetOptionBoolean("AdvancedMovement", false)}, true)
end

function UpdateMovementMode()
    if Client and Client.GetLocalPlayer() and Client.GetLocalPlayer().movementmode ~= Client.GetOptionBoolean("AdvancedMovement", false) then
        Client.SendNetworkMessage("MovementMode", {movement = Client.GetOptionBoolean("AdvancedMovement", false)}, true)
    end
end

Event.Hook("LoadComplete", OnNS2cLoadComplete)