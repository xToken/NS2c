// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\ReadyRoomPlayer.lua
//
//    Created by:   Brian Cronin (brainc@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//RR Player uses player movement mixins, for goldsource movement.

Script.Load("lua/Player.lua")
Script.Load("lua/Mixins/CameraHolderMixin.lua")

/**
 * ReadyRoomPlayer is a simple Player class that adds the required Move type mixin
 * to Player. Player should not be instantiated directly.
 */
class 'ReadyRoomPlayer' (Player)

ReadyRoomPlayer.kMapName = "ready_room_player"

local kAnimationGraph = PrecacheAsset("models/marine/male/male.animation_graph")

local networkVars = { }

AddMixinNetworkVars(CameraHolderMixin, networkVars)

function ReadyRoomPlayer:OnCreate()

    Player.OnCreate(self)
	InitMixin(self, CameraHolderMixin, { kFov = kDefaultFov })
    
end

function ReadyRoomPlayer:OnInitialized()

    Player.OnInitialized(self)
    
    self:SetModel(Marine.kModelName, kAnimationGraph)
    
end

function ReadyRoomPlayer:GetPlayerStatusDesc()
    return kPlayerStatus.Void
end

if Client then

    function ReadyRoomPlayer:OnCountDown()
    end
    
    function ReadyRoomPlayer:OnCountDownEnd()
    end
    
end

local kReadyRoomHealthbarOffset = Vector(0, .8, 0)
function ReadyRoomPlayer:GetHealthbarOffset()
    return kReadyRoomHealthbarOffset
end

function ReadyRoomPlayer:MakeSpecialEdition()
    self:SetModel(Marine.kBlackArmorModelName, Marine.kMarineAnimationGraph)
end

function ReadyRoomPlayer:MakeDeluxeEdition()
    self:SetModel(Marine.kSpecialEditionModelName, Marine.kMarineAnimationGraph)
end


Shared.LinkClassToMap("ReadyRoomPlayer", ReadyRoomPlayer.kMapName, networkVars)