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
Script.Load("lua/ScoringMixin.lua")
Script.Load("lua/Marine.lua")
Script.Load("lua/MarineVariantMixin.lua")

/**
 * ReadyRoomPlayer is a simple Player class that adds the required Move type mixin
 * to Player. Player should not be instantiated directly.
 */
class 'ReadyRoomPlayer' (Player)

ReadyRoomPlayer.kMapName = "ready_room_player"

local networkVars = { }

AddMixinNetworkVars(CameraHolderMixin, networkVars)
AddMixinNetworkVars(ScoringMixin, networkVars)
AddMixinNetworkVars(MarineVariantMixin, networkVars)

function ReadyRoomPlayer:OnCreate()

	InitMixin(self, ScoringMixin, { kMaxScore = kMaxScore })
    InitMixin(self, MarineVariantMixin)
    
    Player.OnCreate(self)
	InitMixin(self, CameraHolderMixin, { kFov = kDefaultFov })
    
end

function ReadyRoomPlayer:OnInitialized()

    Player.OnInitialized(self)
    
    self:SetModel(MarineVariantMixin.kDefaultModelName, MarineVariantMixin.kMarineAnimationGraph)
    
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

function ReadyRoomPlayer:GetHealthbarOffset()
    return 0.8
end

Shared.LinkClassToMap("ReadyRoomPlayer", ReadyRoomPlayer.kMapName, networkVars)
