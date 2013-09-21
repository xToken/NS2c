// ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\VoiceOver.lua
//
// Created by: Andreas Urwalek (andi@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

LEFT_MENU = 1
RIGHT_MENU = 2
kMaxRequestsPerSide = 5

kVoiceId = enum ({

    'None', 'VoteEject', 'VoteConcede', 'Ping',

    'RequestWeld', 'MarineRequestMedpack', 'MarineRequestAmmo', 'MarineRequestOrder', 
    'MarineTaunt', 'MarineTauntExclusive', 'MarineCovering', 'MarineFollowMe', 'MarineHostiles', 'MarineLetsMove',
    
    'AlienRequestHealing', 'AlienVoteCrag', 'AlienVoteShift', 'AlienVoteShade', 'AlienVoteWhip',
    'AlienTaunt', 'AlienFollowMe', 'AlienChuckle', 'EmbryoChuckle',


})

local kAlienTauntSounds =
{
    [kTechId.Skulk] = "sound/NS2.fev/alien/skulk/taunt",
    [kTechId.Gorge] = "sound/NS2.fev/alien/gorge/taunt",
    [kTechId.Lerk] = "sound/NS2.fev/alien/lerk/taunt",
    [kTechId.Fade] = "sound/NS2.fev/alien/fade/taunt",
    [kTechId.Onos] = "sound/NS2.fev/alien/onos/taunt",
    [kTechId.Embryo] = "sound/NS2.fev/alien/common/swarm",
}
for _, tauntSound in pairs(kAlienTauntSounds) do
    PrecacheAsset(tauntSound)
end

local function VoteEjectCommander(player)

    if player then
        GetGamerules():CastVoteByPlayer(kTechId.VoteDownCommander1, player)
    end    
    
end

local function VoteConcedeRound(player)

    if player then
        GetGamerules():CastVoteByPlayer(kTechId.VoteConcedeRound, player)
    end  
    
end

local function VoteChamber(player, techId)

    if player then
        local teamInfo = GetTeamInfoEntity(player:GetTeamNumber())
        if ((teamInfo and teamInfo.GetActiveUnassignedHiveCount) and teamInfo:GetActiveUnassignedHiveCount() or 0) > 0 then
            GetGamerules():CastVoteByPlayer(techId, player)
        end
    end  
    
end

local function VoteCrag(player)
	if not GetHasTech(player, kTechId.CragHive) then
		VoteChamber(player, kTechId.Crag)
	end
end

local function VoteShift(player)
	if not GetHasTech(player, kTechId.ShiftHive) then
		VoteChamber(player, kTechId.Shift)
	end
end

local function VoteShade(player)
	if not GetHasTech(player, kTechId.ShadeHive) then
		VoteChamber(player, kTechId.Shade)
	end
end

local function VoteWhip(player)
	if not GetHasTech(player, kTechId.WhipHive) then
		VoteChamber(player, kTechId.Whip)
	end
end

local function GetLifeFormSound(player)

    if player and player:isa("Alien") then    
        return kAlienTauntSounds[player:GetTechId()] or ""    
    end
    
    return ""

end

local function PingInViewDirection(player)

    if player and (not player.lastTimePinged or player.lastTimePinged + 60 < Shared.GetTime()) then
    
        local startPoint = player:GetEyePos()
        local endPoint = startPoint + player:GetViewCoords().zAxis * 40        
        local trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterOne(player))   
        
        // seems due to changes to team mixin you can be assigned to a team which does not implement SetCommanderPing
        local team = player:GetTeam()
        if team and team.SetCommanderPing then
            player:GetTeam():SetCommanderPing(trace.endPoint)
        end
        
        player.lastTimePinged = Shared.GetTime()
        
    end

end

local function GiveWeldOrder(player)

    if ( player:isa("Marine") or player:isa("Exo") ) and player:GetArmor() < player:GetMaxArmor() then
    
        for _, marine in ipairs(GetEntitiesForTeamWithinRange("Marine", player:GetTeamNumber(), player:GetOrigin(), 8)) do
        
            if player ~= marine and marine:GetWeapon(Welder.kMapName) then
                marine:GiveOrder(kTechId.AutoWeld, player:GetId(), player:GetOrigin(), nil, true, false)
            end
        
        end
    
    end

end

local kSoundData = 
{

    // always part of the menu
    [kVoiceId.VoteEject] = { Function = VoteEjectCommander },
    [kVoiceId.VoteConcede] = { Function = VoteConcedeRound },

    [kVoiceId.Ping] = { Function = PingInViewDirection, Description = "REQUEST_PING", KeyBind = "PingLocation" },

    // marine vote menu
    [kVoiceId.RequestWeld] = { Sound = "sound/NS2.fev/marine/voiceovers/weld", Function = GiveWeldOrder, Description = "REQUEST_MARINE_WELD", KeyBind = "RequestWeld", AlertTechId = kTechId.None },
    [kVoiceId.MarineRequestMedpack] = { Sound = "sound/NS2.fev/marine/voiceovers/medpack", Description = "REQUEST_MARINE_MEDPACK", KeyBind = "RequestHealth", AlertTechId = kTechId.MarineAlertNeedMedpack },
    [kVoiceId.MarineRequestAmmo] = { Sound = "sound/NS2.fev/marine/voiceovers/ammo", Description = "REQUEST_MARINE_AMMO", KeyBind = "RequestAmmo", AlertTechId = kTechId.MarineAlertNeedAmmo },
    [kVoiceId.MarineRequestOrder] = { Sound = "sound/NS2.fev/marine/voiceovers/need_orders", Description = "REQUEST_MARINE_ORDER",  KeyBind = "RequestOrder", AlertTechId = kTechId.MarineAlertNeedOrder },
    
    [kVoiceId.MarineTaunt] = { Sound = "sound/NS2.fev/marine/voiceovers/taunt", Description = "REQUEST_MARINE_TAUNT", KeyBind = "Taunt", AlertTechId = kTechId.None },
    [kVoiceId.MarineTauntExclusive] = { Sound = "sound/NS2.fev/marine/voiceovers/taunt_exclusive", Description = "REQUEST_MARINE_TAUNT", KeyBind = "Taunt", AlertTechId = kTechId.None },
    [kVoiceId.MarineCovering] = { Sound = "sound/NS2.fev/marine/voiceovers/covering", Description = "REQUEST_MARINE_COVERING", AlertTechId = kTechId.None },
    [kVoiceId.MarineFollowMe] = { Sound = "sound/NS2.fev/marine/voiceovers/follow_me", Description = "REQUEST_MARINE_FOLLOWME", AlertTechId = kTechId.None },
    [kVoiceId.MarineHostiles] = { Sound = "sound/NS2.fev/marine/voiceovers/hostiles", Description = "REQUEST_MARINE_HOSTILES", AlertTechId = kTechId.None },
    [kVoiceId.MarineLetsMove] = { Sound = "sound/NS2.fev/marine/voiceovers/lets_move", Description = "REQUEST_MARINE_LETSMOVE", AlertTechId = kTechId.None },
    
    
    // alien vote menu
    [kVoiceId.AlienRequestHealing] = { Sound = "sound/NS2.fev/alien/voiceovers/need_healing", Description = "REQUEST_ALIEN_HEAL", KeyBind = "RequestHealth", AlertTechId = kTechId.None },
    [kVoiceId.AlienTaunt] = { Sound = "", Function = GetLifeFormSound, Description = "REQUEST_ALIEN_TAUNT", KeyBind = "Taunt", AlertTechId = kTechId.None },
    [kVoiceId.AlienFollowMe] = { Sound = "sound/NS2.fev/alien/voiceovers/follow_me", Description = "REQUEST_ALIEN_FOLLOWME", AlertTechId = kTechId.None },
    [kVoiceId.AlienChuckle] = { Sound = "sound/NS2.fev/alien/voiceovers/chuckle", Description = "REQUEST_ALIEN_CHUCKLE", AlertTechId = kTechId.None },  
    [kVoiceId.EmbryoChuckle] = { Sound = "sound/NS2.fev/alien/structures/death_large", Description = "REQUEST_ALIEN_CHUCKLE", AlertTechId = kTechId.None },     
    [kVoiceId.AlienVoteCrag] = { Function = VoteCrag, Description = "Vote for Crag upgrade." },
    [kVoiceId.AlienVoteShift] = { Function = VoteShift, Description = "Vote for Shift upgrade." },
    [kVoiceId.AlienVoteShade] = { Function = VoteShade, Description = "Vote for Shade upgrade." },
    [kVoiceId.AlienVoteWhip] = { Function = VoteWhip, Description = "Vote for Whip upgrade." },

}

function GetVoiceSoundData(voiceId)
    return kSoundData[voiceId]
end

for _, soundData in pairs(kSoundData) do

    if soundData.Sound ~= nil and string.len(soundData.Sound) > 0 then
    
        PrecacheAsset(soundData.Sound)
        
        soundData.SoundFemale = soundData.Sound .. "_female"
        PrecacheAsset(soundData.SoundFemale)
        
    end
    
end

function GetVoiceSoundData(voiceId)
    return kSoundData[voiceId]
end

local kMarineMenu =
{
    [LEFT_MENU] = { kVoiceId.RequestWeld, kVoiceId.MarineRequestMedpack, kVoiceId.MarineRequestAmmo, kVoiceId.MarineRequestOrder, kVoiceId.Ping },
    [RIGHT_MENU] = { kVoiceId.MarineTaunt, kVoiceId.MarineCovering, kVoiceId.MarineFollowMe, kVoiceId.MarineHostiles, kVoiceId.MarineLetsMove, }
}

local kAlienMenu =
{
    [LEFT_MENU] = { kVoiceId.AlienRequestHealing, kVoiceId.Ping, kVoiceId.AlienTaunt, kVoiceId.AlienChuckle },
    [RIGHT_MENU] = { kVoiceId.AlienVoteCrag, kVoiceId.AlienVoteShift, kVoiceId.AlienVoteShade, kVoiceId.AlienVoteWhip }    
}

local kRequestMenus = 
{
    ["Spectator"] = { },
    ["AlienSpectator"] = { },
    ["MarineSpectator"] = { },
    
    ["Marine"] = kMarineMenu,
    ["JetpackMarine"] = kMarineMenu,
    ["Exo"] =
    {
        [LEFT_MENU] = { kVoiceId.RequestWeld, kVoiceId.MarineRequestOrder, kVoiceId.Ping },
        [RIGHT_MENU] = { kVoiceId.MarineTaunt, kVoiceId.MarineCovering, kVoiceId.MarineFollowMe, kVoiceId.MarineHostiles, kVoiceId.MarineLetsMove }
    },
    
    ["Skulk"] = kAlienMenu,
    ["Gorge"] = kAlienMenu,
    ["Lerk"] = kAlienMenu,
    ["Fade"] = kAlienMenu,
    ["Onos"] = kAlienMenu,
    ["Embryo"] =
    {
        [LEFT_MENU] = { kVoiceId.AlienTaunt, kVoiceId.EmbryoChuckle },
        [RIGHT_MENU] = { kVoiceId.AlienVoteCrag, kVoiceId.AlienVoteShift, kVoiceId.AlienVoteShade, kVoiceId.AlienVoteWhip }    
    }
    
}    

function GetRequestMenu(side, className)

    local menu = kRequestMenus[className]
    if menu and menu[side] then
        return menu[side]
    end
    
    return { }
    
end

if Client then

    function GetVoiceDescriptionText(voiceId)
    
        local descriptionText = ""
        
        local soundData = kSoundData[voiceId]
        if soundData then
            descriptionText = Locale.ResolveString(soundData.Description)
        end
        
        return descriptionText
        
    end
    
    function GetVoiceKeyBind(voiceId)
    
        local soundData = kSoundData[voiceId]
        if soundData then
            return soundData.KeyBind
        end    
        
    end
    
end


local kAutoMarineVoiceOvers = {}
local kAutoAlienVoiceOvers = {}
