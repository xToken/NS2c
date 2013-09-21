// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\MarineCommander.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Handled Commander movement and actions.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Adjusted techids for classic

Script.Load("lua/Commander.lua")

class 'MarineCommander' (Commander)

MarineCommander.kMapName = "marine_commander"
//MarineCommander.kDropSound = PrecacheAsset("sound/ns2c.fev/ns2c/marine/commander/drop")

if Client then
    Script.Load("lua/MarineCommander_Client.lua")
elseif Server then    
    Script.Load("lua/MarineCommander_Server.lua")
end

MarineCommander.kSentryFiringSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/sentry_firing")
MarineCommander.kSentryTakingDamageSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/sentry_taking_damage")
MarineCommander.kSentryLowAmmoSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/sentry_low_ammo")
MarineCommander.kSentryNoAmmoSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/sentry_no_ammo")
MarineCommander.kSoldierLostSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/soldier_lost")
MarineCommander.kSoldierAcknowledgesSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/ack")
MarineCommander.kSoldierNeedsAmmoSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/soldier_needs_ammo")
MarineCommander.kSoldierNeedsHealthSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/soldier_needs_health")
MarineCommander.kSoldierNeedsOrderSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/soldier_needs_order")
MarineCommander.kUpgradeCompleteSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/upgrade_complete")
MarineCommander.kResearchCompleteSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/research_complete")
MarineCommander.kManufactureCompleteSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/all_clear")
MarineCommander.kObjectiveCompletedSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/complete")
MarineCommander.kMoveToWaypointSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/move")
MarineCommander.kAttackOrderSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/move")
MarineCommander.kStructureUnderAttackSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/base_under_attack")
MarineCommander.kSoldierUnderAttackSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/soldier_under_attack")
MarineCommander.kBuildStructureSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/build")
MarineCommander.kWeldOrderSound = PrecacheAsset("sound/NS2.fev/marine/structures/mac/weld")
MarineCommander.kDefendTargetSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/defend")
MarineCommander.kCommanderEjectedSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/commander_ejected")
MarineCommander.kCommandStationCompletedSoundName = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/online")

MarineCommander.kOrderClickedEffect = PrecacheAsset("cinematics/marine/order.cinematic")
MarineCommander.kSelectSound = PrecacheAsset("sound/NS2.fev/marine/commander/select")

local kHoverSound = PrecacheAsset("sound/NS2.fev/marine/commander/hover")

function MarineCommander:GetSelectionSound()
    return MarineCommander.kSelectSound
end

function MarineCommander:GetHoverSound()
    return kHoverSound
end

function MarineCommander:GetTeamType()
    return kMarineTeamType
end

function MarineCommander:GetOrderConfirmedEffect()
    return MarineCommander.kOrderClickedEffect
end

function MarineCommander:GetIsInQuickMenu(techId)
    return Commander.GetIsInQuickMenu(self, techId)
end

local gMarineMenuButtons =
{

    [kTechId.BuildMenu] = { kTechId.Extractor, kTechId.InfantryPortal, kTechId.Armory, kTechId.CommandStation,
                        kTechId.TurretFactory, kTechId.Sentry, kTechId.ARC, kTechId.None},
                            
    [kTechId.AdvancedMenu] = { kTechId.Observatory, kTechId.ArmsLab, kTechId.PrototypeLab, kTechId.PhaseGate, 
                              kTechId.None, kTechId.None, kTechId.None, kTechId.None},

    [kTechId.AssistMenu] = { kTechId.AmmoPack, kTechId.MedPack, kTechId.CatPack, kTechId.None,
                        kTechId.None, kTechId.None, kTechId.None, kTechId.None},
                          
    [kTechId.WeaponsMenu] = { kTechId.Mines, kTechId.Shotgun, kTechId.HeavyMachineGun, kTechId.GrenadeLauncher,
                        kTechId.Welder, kTechId.Jetpack, kTechId.HeavyArmor, kTechId.None/*kTechId.Exosuit*/}


}

function MarineCommander:GetButtonTable()
    return gMarineMenuButtons
end

// Top row always the same. Alien commander can override to replace. 
function MarineCommander:GetQuickMenuTechButtons(techId)

    // Top row always for quick access
    local marineTechButtons = { kTechId.BuildMenu, kTechId.AdvancedMenu, kTechId.AssistMenu, kTechId.WeaponsMenu}
    local menuButtons = gMarineMenuButtons[techId]    
    
    if not menuButtons then
        menuButtons = {kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None }
    end

    table.copy(menuButtons, marineTechButtons, true)        

    // Return buttons and true/false if we are in a quick-access menu
    return marineTechButtons
    
end

function MarineCommander:GetPlayerStatusDesc()
    return kPlayerStatus.Commander
end

Shared.LinkClassToMap( "MarineCommander", MarineCommander.kMapName, {} )