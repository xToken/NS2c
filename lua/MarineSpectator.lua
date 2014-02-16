// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineSpectator.lua
//
//    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
//
// Marine spectators
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/TeamSpectator.lua")

if Client then
    Script.Load("lua/TeamMessageMixin.lua")
end

class 'MarineSpectator' (TeamSpectator)

MarineSpectator.kMapName = "marinespectator"

local networkVars ={ }

local function UpdateWaveTime(self)

    if self:GetIsDestroyed() then
        return false
    end
    
    if not self.sentRespawnMessage then
    
        Server.SendNetworkMessage(Server.GetOwner(self), "SetIsRespawning", { isRespawning = true }, true)
        self.sentRespawnMessage = true
        
    end
    
    return true
    
end

function MarineSpectator:OnCreate()

    TeamSpectator.OnCreate(self)
    self:SetTeamNumber(1)

    if Client then
        InitMixin(self, TeamMessageMixin, { kGUIScriptName = "GUIMarineTeamMessage" })
    end
    
end

function MarineSpectator:OnInitialized()

    TeamSpectator.OnInitialized(self)
    
    self:SetTeamNumber(1)
    
    if Server then
        self:AddTimedCallback(UpdateWaveTime, 0.1)
    end
    
end

if Server then

    function MarineSpectator:Replace(mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues)
    
        Server.SendNetworkMessage(Server.GetOwner(self), "SetIsRespawning", { isRespawning = false }, true)    
        return TeamSpectator.Replace(self, mapName, newTeamNumber, preserveWeapons, atOrigin, extraValues)
    
    end

end

/**
 * Prevent the camera from penetrating into the world when waiting to spawn at the IP.
 */
function MarineSpectator:GetPreventCameraPenetration()

    local followTarget = Shared.GetEntity(self:GetFollowTargetId())
    return followTarget and followTarget:isa("InfantryPortal")
    
end

function MarineSpectator:GetFollowMoveCameraDistance()
    return 2.5
end

Shared.LinkClassToMap("MarineSpectator", MarineSpectator.kMapName, networkVars)