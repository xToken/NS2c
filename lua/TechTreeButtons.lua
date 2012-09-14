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

// These are the icons that appear next to alerts or as hotkey icons.
// Icon size should be 20x20. Also used for the alien buy menu.
function CommanderUI_Icons()

    local player = Client.GetLocalPlayer()
    if(player and (player:isa("Alien") or player:isa("AlienCommander"))) then
        return "alien_upgradeicons"
    end
    
    return "marine_upgradeicons"

end

function CommanderUI_MenuImage()

    local player = Client.GetLocalPlayer()
    if(player and player:isa("AlienCommander")) then
        return "alien_buildmenu"
    end
    
    return "marine_buildmenu"
    
end

function CommanderUI_MenuImageSize()

    local player = Client.GetLocalPlayer()
    if(player and player:isa("AlienCommander")) then
        return 640, 1040
    end
    
    return 960, 960
    
end

// Init marine offsets
kMarineTechIdToMaterialOffset = {}

// Init alien offsets
kAlienTechIdToMaterialOffset = {}

// Create arrays that convert between tech ids and the offsets within
// the button images used to display their buttons. Look in marine_buildmenu.psd 
// and alien_buildmenu.psd to understand these indices.
function InitTechTreeMaterialOffsets()

    // Init marine offsets
    kMarineTechIdToMaterialOffset = {}

    // Init alien offsets
    kAlienTechIdToMaterialOffset = {}
    
    // Resource Points
    kMarineTechIdToMaterialOffset[kTechId.ResourcePoint] = 89
    kAlienTechIdToMaterialOffset[kTechId.ResourcePoint] = 0

    // First row
    kMarineTechIdToMaterialOffset[kTechId.CommandStation] = 0
    
    kMarineTechIdToMaterialOffset[kTechId.Armory] = 1
    // Change offset in CommanderUI_GetIdleWorkerOffset when changing extractor
    kMarineTechIdToMaterialOffset[kTechId.Extractor] = 3
    kMarineTechIdToMaterialOffset[kTechId.InfantryPortal] = 4
    kMarineTechIdToMaterialOffset[kTechId.Sentry] = 5
    
    kMarineTechIdToMaterialOffset[kTechId.RoboticsFactory] = 6    
    kMarineTechIdToMaterialOffset[kTechId.UpgradeRoboticsFactory] = 6
    kMarineTechIdToMaterialOffset[kTechId.ARCRoboticsFactory] = 6
    
    kMarineTechIdToMaterialOffset[kTechId.Observatory] = 7
    // TODO: Change this
    kMarineTechIdToMaterialOffset[kTechId.ArmsLab] = 11
    
    // Second row - Non-player orders
    kMarineTechIdToMaterialOffset[kTechId.Recycle] = 12
    kMarineTechIdToMaterialOffset[kTechId.Move] = 13
    kMarineTechIdToMaterialOffset[kTechId.Stop] = 14
    kMarineTechIdToMaterialOffset[kTechId.RootMenu] = 15
    kMarineTechIdToMaterialOffset[kTechId.Cancel] = 16
    kMarineTechIdToMaterialOffset[kTechId.Construct] = 22
    
    //kMarineTechIdToMaterialOffset[kTechId.] = 17 // MAC build
    
    kMarineTechIdToMaterialOffset[kTechId.Attack] = 18
    kMarineTechIdToMaterialOffset[kTechId.SetRally] = 19
    kMarineTechIdToMaterialOffset[kTechId.SetTarget] = 28
    kMarineTechIdToMaterialOffset[kTechId.Weld] = 21
    kMarineTechIdToMaterialOffset[kTechId.BuildMenu] = 22
    kMarineTechIdToMaterialOffset[kTechId.AdvancedMenu] = 23    
    
    kMarineTechIdToMaterialOffset[kTechId.MarineAlertOrderComplete] = 60

    kMarineTechIdToMaterialOffset[kTechId.Defend] = 27

    kMarineTechIdToMaterialOffset[kTechId.AssistMenu] = 33
    kMarineTechIdToMaterialOffset[kTechId.WeaponsMenu] = 55
    
    // Fourth row - droppables, research
    kMarineTechIdToMaterialOffset[kTechId.AmmoPack] = 36
    kMarineTechIdToMaterialOffset[kTechId.MedPack] = 37
    kMarineTechIdToMaterialOffset[kTechId.JetpackTech] = 40
    kMarineTechIdToMaterialOffset[kTechId.Jetpack] = 40
    kMarineTechIdToMaterialOffset[kTechId.Scan] = 41
    kMarineTechIdToMaterialOffset[kTechId.ARC] = 44
    kMarineTechIdToMaterialOffset[kTechId.CatPack] = 45
    kMarineTechIdToMaterialOffset[kTechId.CatPackTech] = 45
    
    // Fifth row 
    kMarineTechIdToMaterialOffset[kTechId.Shotgun] = 48
    kMarineTechIdToMaterialOffset[kTechId.Armor1] = 49
    kMarineTechIdToMaterialOffset[kTechId.Armor2] = 50
    kMarineTechIdToMaterialOffset[kTechId.Armor3] = 51
        
    // upgrades
    kMarineTechIdToMaterialOffset[kTechId.Weapons1] = 55
    kMarineTechIdToMaterialOffset[kTechId.Weapons2] = 56
    kMarineTechIdToMaterialOffset[kTechId.Weapons3] = 57
    
    kMarineTechIdToMaterialOffset[kTechId.Marine] = 60
    kMarineTechIdToMaterialOffset[kTechId.JetpackMarine] = 60
    kMarineTechIdToMaterialOffset[kTechId.HeavyArmorMarine] = 61
    kMarineTechIdToMaterialOffset[kTechId.DistressBeacon] = 63
    kMarineTechIdToMaterialOffset[kTechId.AdvancedArmory] = 65
    kMarineTechIdToMaterialOffset[kTechId.AdvancedArmoryUpgrade] = 65
    kMarineTechIdToMaterialOffset[kTechId.PhaseGate] = 67
    kMarineTechIdToMaterialOffset[kTechId.PhaseTech] = 68
    kMarineTechIdToMaterialOffset[kTechId.MotionTracking] = 62

    kMarineTechIdToMaterialOffset[kTechId.GrenadeLauncher] = 72
    kMarineTechIdToMaterialOffset[kTechId.HeavyArmorTech] = 75
    kMarineTechIdToMaterialOffset[kTechId.HeavyArmor] = 61
    kMarineTechIdToMaterialOffset[kTechId.Mine] = 80
    kMarineTechIdToMaterialOffset[kTechId.Mines] = 80
    kMarineTechIdToMaterialOffset[kTechId.Welder] = 21    
    kMarineTechIdToMaterialOffset[kTechId.HeavyMachineGun] = 47
    kMarineTechIdToMaterialOffset[kTechId.HandGrenadesTech] = 72
    kMarineTechIdToMaterialOffset[kTechId.HandGrenades] = 72
    
    // Doors
    kMarineTechIdToMaterialOffset[kTechId.Door] = 84
    kMarineTechIdToMaterialOffset[kTechId.DoorOpen] = 85
    kMarineTechIdToMaterialOffset[kTechId.DoorClose] = 86
    kMarineTechIdToMaterialOffset[kTechId.DoorLock] = 87
    kMarineTechIdToMaterialOffset[kTechId.DoorUnlock] = 88
    // 89 = nozzle
    // 90 = tech point
    
    kMarineTechIdToMaterialOffset[kTechId.PrototypeLab] = 94
    
    // Generic orders 
    kAlienTechIdToMaterialOffset[kTechId.Default] = 0
    kAlienTechIdToMaterialOffset[kTechId.Move] = 1
    kAlienTechIdToMaterialOffset[kTechId.Attack] = 2
    kAlienTechIdToMaterialOffset[kTechId.Build] = 3
    kAlienTechIdToMaterialOffset[kTechId.Construct] = 8
    kAlienTechIdToMaterialOffset[kTechId.Stop] = 5
    kAlienTechIdToMaterialOffset[kTechId.SetRally] = 6
    kAlienTechIdToMaterialOffset[kTechId.SetTarget] = 7
    
    // Menus
    kAlienTechIdToMaterialOffset[kTechId.RootMenu] = 21
    kAlienTechIdToMaterialOffset[kTechId.BuildMenu] = 8
    kAlienTechIdToMaterialOffset[kTechId.AdvancedMenu] = 9
    kAlienTechIdToMaterialOffset[kTechId.AssistMenu] = 10
    kAlienTechIdToMaterialOffset[kTechId.MarkersMenu] = 14
    kAlienTechIdToMaterialOffset[kTechId.UpgradesMenu] = 12
    kAlienTechIdToMaterialOffset[kTechId.Cancel] = 5
           
    // Lifeforms
    kAlienTechIdToMaterialOffset[kTechId.Skulk] = 16
    kAlienTechIdToMaterialOffset[kTechId.Gorge] = 17
    kAlienTechIdToMaterialOffset[kTechId.Lerk] = 18
    kAlienTechIdToMaterialOffset[kTechId.Fade] = 19
    kAlienTechIdToMaterialOffset[kTechId.Onos] = 20
    
    // Structures
    kAlienTechIdToMaterialOffset[kTechId.Hive] = 24
    kAlienTechIdToMaterialOffset[kTechId.CragHive] = 40
    kAlienTechIdToMaterialOffset[kTechId.ShadeHive] = 64
    kAlienTechIdToMaterialOffset[kTechId.ShiftHive] = 56
    kAlienTechIdToMaterialOffset[kTechId.WhipHive] = 48
    
    kAlienTechIdToMaterialOffset[kTechId.UpgradeToCragHive] = 40
    kAlienTechIdToMaterialOffset[kTechId.UpgradeToShadeHive] = 64
    kAlienTechIdToMaterialOffset[kTechId.UpgradeToShiftHive] = 56
    kAlienTechIdToMaterialOffset[kTechId.UpgradeToWhipHive] = 48
    
    // Change offset in CommanderUI_GetIdleWorkerOffset when changing harvester
    kAlienTechIdToMaterialOffset[kTechId.Harvester] = 27
    kAlienTechIdToMaterialOffset[kTechId.Egg] = 30
    
    // Doors
    // $AS - Aliens can select doors if an onos can potential break a door
    // the alien commander should be able to see its health I would think
    // we do not have any art for doors on aliens so we once again use the
    // question mark 
    kAlienTechIdToMaterialOffset[kTechId.Door] = 22
    kAlienTechIdToMaterialOffset[kTechId.DoorOpen] =22
    kAlienTechIdToMaterialOffset[kTechId.DoorClose] = 22
    kAlienTechIdToMaterialOffset[kTechId.DoorLock] = 22
    kAlienTechIdToMaterialOffset[kTechId.DoorUnlock] = 22
    
    // upgradeable alien abilities
    kAlienTechIdToMaterialOffset[kTechId.Leap] = 105
    kAlienTechIdToMaterialOffset[kTechId.BileBomb] = 107
    kAlienTechIdToMaterialOffset[kTechId.Umbra] = 113
    kAlienTechIdToMaterialOffset[kTechId.Metabolize] = 110
    kAlienTechIdToMaterialOffset[kTechId.Stomp] = 111
    
    kAlienTechIdToMaterialOffset[kTechId.Xenocide] = 108
    kAlienTechIdToMaterialOffset[kTechId.Web] = 112
    kAlienTechIdToMaterialOffset[kTechId.PrimalScream] = 20
    kAlienTechIdToMaterialOffset[kTechId.Spikes] = 114
    kAlienTechIdToMaterialOffset[kTechId.AcidRocket] = 113
    kAlienTechIdToMaterialOffset[kTechId.Smash] = 111
    kAlienTechIdToMaterialOffset[kTechId.Charge] = 111
      
    //Chambers
    kAlienTechIdToMaterialOffset[kTechId.Crag] = 40
    kAlienTechIdToMaterialOffset[kTechId.Shift] = 56
    kAlienTechIdToMaterialOffset[kTechId.Shade] = 64
    kAlienTechIdToMaterialOffset[kTechId.Whip] = 48
        
    kAlienTechIdToMaterialOffset[kTechId.Adrenaline] = 83
    kAlienTechIdToMaterialOffset[kTechId.Celerity] = 84
    kAlienTechIdToMaterialOffset[kTechId.Redeployment] = 56
    
    kAlienTechIdToMaterialOffset[kTechId.Silence] = 85
    kAlienTechIdToMaterialOffset[kTechId.Reconnaissance] = 86
    kAlienTechIdToMaterialOffset[kTechId.Aura] = 71
    
    kAlienTechIdToMaterialOffset[kTechId.Carapace] = 81
    kAlienTechIdToMaterialOffset[kTechId.Regeneration] = 82
    kAlienTechIdToMaterialOffset[kTechId.Redemption] = 87
    
    kAlienTechIdToMaterialOffset[kTechId.Focus] = 80
    kAlienTechIdToMaterialOffset[kTechId.Fury] = 114
    kAlienTechIdToMaterialOffset[kTechId.Echo] = 60
    
    //Hydra
    kAlienTechIdToMaterialOffset[kTechId.Hydra] = 88
    
end

function GetMaterialXYOffset(techId, isaMarine)

    local index = nil
    
    local columns = 12
    if isaMarine then
        index = kMarineTechIdToMaterialOffset[techId]
    else
        index = kAlienTechIdToMaterialOffset[techId]
        columns = 8
    end
    
    if index == nil then
        Print("Warning: %s did not define kMarineTechIdToMaterialOffset/kAlienTechIdToMaterialOffset ", EnumToString(kTechId, techId) )
    end

    if(index ~= nil) then
    
        local x = index % columns
        local y = math.floor(index / columns)
        return x, y
        
    end
    
    return nil, nil
    
end

function GetPixelCoordsForIcon(entityId, forMarine)

    local ent = Shared.GetEntity(entityId)
    
    if (ent ~= nil and ent:isa("ScriptActor")) then
    
        local techId = ent:GetTechId()
        
        if (techId ~= kTechId.None) then
            
            local xOffset, yOffset = GetMaterialXYOffset(techId, forMarine)
            
            return {xOffset, yOffset}
            
        end
                    
    end
    
    return nil
    
end
