// ======= Copyright (c) 2003-2012, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\TechTreeButtons.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// Hard-coded data which maps tech tree constants to indices into a texture. Used to display
// icons in the commander build menu and alien buy menu.
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

//NS2c
//Adjusted button references for classic techIds

// These are the icons that appear next to alerts or as hotkey icons.
// Icon size should be 20x20. Also used for the alien buy menu.
function CommanderUI_Icons()

    local player = Client.GetLocalPlayer()
    if(player and (player:isa("Alien") or player:isa("AlienCommander"))) then
        return "alien_upgradeicons"
    end
    
    return "marine_upgradeicons"

end

function CommanderUI_MenuImageSize()

    local player = Client.GetLocalPlayer()
    if(player and player:isa("AlienCommander")) then
        return 640, 1040
    end
    
    return 960, 960
    
end

// Init icon offsets.
local kTechIdToMaterialOffset = {}

kTechIdToMaterialOffset[kTechId.CommandStation] = 0
kTechIdToMaterialOffset[kTechId.Armory] = 1
kTechIdToMaterialOffset[kTechId.AdvancedArmory] = 1
kTechIdToMaterialOffset[kTechId.Hive] = 2
kTechIdToMaterialOffset[kTechId.Extractor] = 3
kTechIdToMaterialOffset[kTechId.InfantryPortal] = 4
kTechIdToMaterialOffset[kTechId.Sentry] = 5
kTechIdToMaterialOffset[kTechId.RoboticsFactory] = 6    

kTechIdToMaterialOffset[kTechId.ARCRoboticsFactory] = 6
kTechIdToMaterialOffset[kTechId.Observatory] = 7
kTechIdToMaterialOffset[kTechId.Mine] = 8
kTechIdToMaterialOffset[kTechId.Mines] = 8
//kTechIdToMaterialOffset[kTechId.SentryBattery] = 9
kTechIdToMaterialOffset[kTechId.ArmsLab] = 10

//kTechIdToMaterialOffset[kTechId.Spur] = 11
kTechIdToMaterialOffset[kTechId.Door] = 12
kTechIdToMaterialOffset[kTechId.ResourcePoint] = 13
kTechIdToMaterialOffset[kTechId.TechPoint] = 14
kTechIdToMaterialOffset[kTechId.PrototypeLab] = 15
kTechIdToMaterialOffset[kTechId.Harvester] = 16
kTechIdToMaterialOffset[kTechId.PhaseGate] = 17
kTechIdToMaterialOffset[kTechId.UpgradeToCragHive] = 18
kTechIdToMaterialOffset[kTechId.UpgradeToWhipHive] = 19
kTechIdToMaterialOffset[kTechId.UpgradeToShadeHive] = 21
kTechIdToMaterialOffset[kTechId.UpgradeToShiftHive] = 20
kTechIdToMaterialOffset[kTechId.CragHive] = 18
kTechIdToMaterialOffset[kTechId.WhipHive] = 19
kTechIdToMaterialOffset[kTechId.ShadeHive] = 21
kTechIdToMaterialOffset[kTechId.ShiftHive] = 20
kTechIdToMaterialOffset[kTechId.Crag] = 18
kTechIdToMaterialOffset[kTechId.Whip] = 19
kTechIdToMaterialOffset[kTechId.Shift] = 20
kTechIdToMaterialOffset[kTechId.Shade] = 21

//kTechIdToMaterialOffset[kTechId.Shell] = 22
//kTechIdToMaterialOffset[kTechId.Veil] = 23
kTechIdToMaterialOffset[kTechId.Marine] = 24
kTechIdToMaterialOffset[kTechId.HeavyArmorMarine] = 25
kTechIdToMaterialOffset[kTechId.HeavyArmor] = 25

kTechIdToMaterialOffset[kTechId.ExosuitTech] = 25
kTechIdToMaterialOffset[kTechId.Exo] = 25
kTechIdToMaterialOffset[kTechId.Exosuit] = 25

kTechIdToMaterialOffset[kTechId.JetpackMarine] = 26
kTechIdToMaterialOffset[kTechId.Skulk] = 27
kTechIdToMaterialOffset[kTechId.Gorge] = 28
kTechIdToMaterialOffset[kTechId.Lerk] = 29

kTechIdToMaterialOffset[kTechId.Fade] = 30
kTechIdToMaterialOffset[kTechId.Onos] = 31
kTechIdToMaterialOffset[kTechId.ARC] = 32
//kTechIdToMaterialOffset[kTechId.ARCUndeploy] = 32
//kTechIdToMaterialOffset[kTechId.ARCDeploy] = 33
kTechIdToMaterialOffset[kTechId.Egg] = 34
kTechIdToMaterialOffset[kTechId.Embryo] = 34
//kTechIdToMaterialOffset[kTechId.Cyst] = 35
//kTechIdToMaterialOffset[kTechId.MAC] = 36
//kTechIdToMaterialOffset[kTechId.Drifter] = 37
//kTechIdToMaterialOffset[kTechId.WhipUnroot] = 38
//kTechIdToMaterialOffset[kTechId.WhipRoot] = 39

//kTechIdToMaterialOffset[kTechId.ShiftEcho] = 40
kTechIdToMaterialOffset[kTechId.Redeployment] = 40
//kTechIdToMaterialOffset[kTechId.WhipBombard] = 41
kTechIdToMaterialOffset[kTechId.Bombard] = 41
//kTechIdToMaterialOffset[kTechId.EnzymeCloud] = 42
kTechIdToMaterialOffset[kTechId.Focus] = 42
//kTechIdToMaterialOffset[kTechId.MACEMPTech] = 43
//kTechIdToMaterialOffset[kTechId.MACEMP] = 43
//kTechIdToMaterialOffset[kTechId.Rupture] = 44
kTechIdToMaterialOffset[kTechId.Fury] = 44
//kTechIdToMaterialOffset[kTechId.ShadeInk] = 45
kTechIdToMaterialOffset[kTechId.Aura] = 45
//kTechIdToMaterialOffset[kTechId.ShiftHatch] = 46
//kTechIdToMaterialOffset[kTechId.ShiftEnergize] = 47
//kTechIdToMaterialOffset[kTechId.HealWave] = 48
//kTechIdToMaterialOffset[kTechId.Infestation] = 49

//kTechIdToMaterialOffset[kTechId.GrenadeWhack] = 50
//kTechIdToMaterialOffset[kTechId.HiveHeal] = 51
//kTechIdToMaterialOffset[kTechId.CragHeal] = 51
kTechIdToMaterialOffset[kTechId.DistressBeacon] = 52
//kTechIdToMaterialOffset[kTechId.BoneWall] = 53
kTechIdToMaterialOffset[kTechId.Scan] = 54
//kTechIdToMaterialOffset[kTechId.NanoShield] = 55
//kTechIdToMaterialOffset[kTechId.NutrientMist] = 56
kTechIdToMaterialOffset[kTechId.Redemption] = 56
//kTechIdToMaterialOffset[kTechId.Welding] = 57
//kTechIdToMaterialOffset[kTechId.EvolveHallucinations] = 58
//kTechIdToMaterialOffset[kTechId.EvolveEcho] = 59

//kTechIdToMaterialOffset[kTechId.EvolveBombard] = 60
kTechIdToMaterialOffset[kTechId.Carapace] = 61
kTechIdToMaterialOffset[kTechId.Regeneration] = 62
kTechIdToMaterialOffset[kTechId.Adrenaline] = 63
kTechIdToMaterialOffset[kTechId.Celerity] = 64
kTechIdToMaterialOffset[kTechId.Silence] = 65
kTechIdToMaterialOffset[kTechId.Ghost] = 66
kTechIdToMaterialOffset[kTechId.Leap] = 67
kTechIdToMaterialOffset[kTechId.BileBomb] = 68
kTechIdToMaterialOffset[kTechId.Web] = 68
kTechIdToMaterialOffset[kTechId.PrimalScream] = 69
kTechIdToMaterialOffset[kTechId.Spikes] = 69

kTechIdToMaterialOffset[kTechId.Metabolize] = 70
kTechIdToMaterialOffset[kTechId.AcidRocket] = 71
kTechIdToMaterialOffset[kTechId.Stomp] = 72
kTechIdToMaterialOffset[kTechId.Smash] = 72
kTechIdToMaterialOffset[kTechId.Devour] = 72
kTechIdToMaterialOffset[kTechId.Charge] = 72
kTechIdToMaterialOffset[kTechId.Stomp] = 72
//kTechIdToMaterialOffset[kTechId.MACSpeedTech] = 73
//kTechIdToMaterialOffset[kTechId.Detector] = 74  
kTechIdToMaterialOffset[kTechId.Umbra] = 75
//kTechIdToMaterialOffset[kTechId.ShadeCloak] = 76
kTechIdToMaterialOffset[kTechId.Armor1] = 77
kTechIdToMaterialOffset[kTechId.Armor2] = 78
kTechIdToMaterialOffset[kTechId.Armor3] = 79

kTechIdToMaterialOffset[kTechId.WeaponsMenu] = 80
kTechIdToMaterialOffset[kTechId.Weapons1] = 80
kTechIdToMaterialOffset[kTechId.Weapons2] = 81
kTechIdToMaterialOffset[kTechId.Weapons3] = 82
kTechIdToMaterialOffset[kTechId.UpgradeRoboticsFactory] = 83
//kTechIdToMaterialOffset[kTechId.DualMinigunTech] = 84
kTechIdToMaterialOffset[kTechId.HeavyArmorTech] = 84
kTechIdToMaterialOffset[kTechId.Shotgun] = 85
//kTechIdToMaterialOffset[kTechId.Flamethrower] = 86
kTechIdToMaterialOffset[kTechId.GrenadeLauncher] = 87
kTechIdToMaterialOffset[kTechId.Welder] = 88

kTechIdToMaterialOffset[kTechId.JetpackTech] = 89
kTechIdToMaterialOffset[kTechId.Jetpack] = 89

kTechIdToMaterialOffset[kTechId.PhaseTech] = 90
kTechIdToMaterialOffset[kTechId.AmmoPack] = 91
kTechIdToMaterialOffset[kTechId.MedPack] = 92
//kTechIdToMaterialOffset[kTechId.PowerPoint] = 93
//kTechIdToMaterialOffset[kTechId.SocketPowerNode] = 94
kTechIdToMaterialOffset[kTechId.Xenocide] = 95
//kTechIdToMaterialOffset[kTechId.SpawnMarine] = 96
//kTechIdToMaterialOffset[kTechId.SpawnAlien] = 97
//kTechIdToMaterialOffset[kTechId.DrifterCamouflage] = 98
kTechIdToMaterialOffset[kTechId.AdvancedArmoryUpgrade] = 99
kTechIdToMaterialOffset[kTechId.Hydra] = 100
kTechIdToMaterialOffset[kTechId.MotionTracking] = 102
kTechIdToMaterialOffset[kTechId.HandGrenadesTech] = 103
kTechIdToMaterialOffset[kTechId.HandGrenades] = 103
kTechIdToMaterialOffset[kTechId.HeavyMachineGun] = 104
kTechIdToMaterialOffset[kTechId.CatPack] = 105
kTechIdToMaterialOffset[kTechId.CatPackTech] = 105
kTechIdToMaterialOffset[kTechId.Electrify] = 106

kTechIdToMaterialOffset[kTechId.Recycle] = 108
kTechIdToMaterialOffset[kTechId.Babbler] = 115
kTechIdToMaterialOffset[kTechId.BabblerEgg] = 115
kTechIdToMaterialOffset[kTechId.Move] = 121
kTechIdToMaterialOffset[kTechId.Stop] = 122
kTechIdToMaterialOffset[kTechId.Attack] = 123
kTechIdToMaterialOffset[kTechId.SetTarget] = 123
kTechIdToMaterialOffset[kTechId.Cancel] = 124
kTechIdToMaterialOffset[kTechId.Weld] = 127
//kTechIdToMaterialOffset[kTechId.AutoWeld] = 127
kTechIdToMaterialOffset[kTechId.BuildMenu] = 128
kTechIdToMaterialOffset[kTechId.AdvancedMenu] = 129

kTechIdToMaterialOffset[kTechId.AssistMenu] = 130
kTechIdToMaterialOffset[kTechId.Construct] = 131
//kTechIdToMaterialOffset[kTechId.NeedHealingMarker] = 132
kTechIdToMaterialOffset[kTechId.RootMenu] = 133
//kTechIdToMaterialOffset[kTechId.LifeFormMenu] = 136
kTechIdToMaterialOffset[kTechId.SetRally] = 137
//kTechIdToMaterialOffset[kTechId.ThreatMarker] = 138

//kTechIdToMaterialOffset[kTechId.ExpandingMarker] = 141
kTechIdToMaterialOffset[kTechId.Defend] = 142
kTechIdToMaterialOffset[kTechId.MarineAlertSentryUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.MarineAlertSoldierUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.MarineAlertStructureUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.MarineAlertExtractorUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.MarineAlertCommandStationUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.MarineAlertInfantryPortalUnderAttack] = 123

kTechIdToMaterialOffset[kTechId.MarineAlertCommandStationComplete] = 0
kTechIdToMaterialOffset[kTechId.MarineAlertConstructionComplete] = 131
kTechIdToMaterialOffset[kTechId.MarineAlertSentryFiring] = 5
kTechIdToMaterialOffset[kTechId.MarineAlertSoldierLost] = 96
kTechIdToMaterialOffset[kTechId.MarineAlertNeedAmmo] = 91
kTechIdToMaterialOffset[kTechId.MarineAlertNeedMedpack] = 92
kTechIdToMaterialOffset[kTechId.MarineAlertNeedOrder] = 24
kTechIdToMaterialOffset[kTechId.MarineAlertUpgradeComplete] = 101
kTechIdToMaterialOffset[kTechId.MarineAlertResearchComplete] = 101
kTechIdToMaterialOffset[kTechId.MarineAlertManufactureComplete] = 131


//kTechIdToMaterialOffset[kTechId.AlienAlertNeedMist] = 56
//kTechIdToMaterialOffset[kTechId.AlienAlertNeedEnzyme] = 42
kTechIdToMaterialOffset[kTechId.AlienAlertHiveUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.AlienAlertStructureUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.AlienAlertHarvesterUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.AlienAlertLifeformUnderAttack] = 123
kTechIdToMaterialOffset[kTechId.AlienAlertHiveDying] = 123
kTechIdToMaterialOffset[kTechId.AlienAlertHiveComplete] = 2

kTechIdToMaterialOffset[kTechId.AlienAlertUpgradeComplete] = 101
kTechIdToMaterialOffset[kTechId.AlienAlertResearchComplete] = 101
kTechIdToMaterialOffset[kTechId.AlienAlertManufactureComplete] = 131

function GetMaterialXYOffset(techId)

    local index = nil
    
    local columns = 12
    index = kTechIdToMaterialOffset[techId]
    
    if index == nil then
        Print("Warning: %s did not define kTechIdToMaterialOffset ", EnumToString(kTechId, techId) )
    end

    if(index ~= nil) then
    
        local x = index % columns
        local y = math.floor(index / columns)
        return x, y
        
    end
    
    return nil, nil
    
end

function GetPixelCoordsForIcon(ent, forMarine)
    
    if ent and HasMixin(ent, "Tech") then
    
        local techId = ent:GetTechId()        
        if techId ~= kTechId.None then
            
            local xOffset, yOffset = GetMaterialXYOffset(techId, forMarine)
            return {xOffset, yOffset}
            
        end
                    
    end
    
    return nil
    
end
